create or replace package body xxfr_wsh_pck_backorder as

  --  Global constant holding the package name
  g_pkg_name  constant varchar2(30) := 'XXFR_WSH_PCK_BACKORDER';
  g_version_printed    boolean      := false;
  g_retain_ato_profile varchar2(1)  := fnd_profile.value('WSH_RETAIN_ATO_RESERVATIONS');

  procedure print_out(msg in varchar2) is
  begin
    xxfr_wsh_pck_int_entrega.print_out(msg);
  end;

  procedure backorder_source(
    x_return_status out nocopy    varchar2,
    x_msg_count     out nocopy    number,
    x_msg_data      out nocopy    varchar2,
    p_move_order_type             number,
    p_mo_line_rec                 inv_move_order_pub.trolin_rec_type
  ) is
  
    l_shipping_attr      wsh_interface.changedattributetabtype;
    l_released_status    varchar2(1);
    l_delivery_detail_id number;
    l_source_header_id   number;
    l_source_line_id     number;
    l_qty_to_backorder   number      := 0;
    l_second_qty_to_backorder   number;           --INVCONV dont default to zero

    cursor c_wsh_info is
      select delivery_detail_id, oe_header_id, oe_line_id, released_status
      from wsh_inv_delivery_details_v
      where 1=1
        and move_order_line_id = p_mo_line_rec.line_id
        and move_order_line_id is not null
        and released_status = 'S';

    l_debug number := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
  begin
    print_out('  XXFR_WSH_PCK_BACKORDER.BACKORDER_SOURCE');
    x_return_status    := fnd_api.g_ret_sts_success;
    l_qty_to_backorder := nvl(p_mo_line_rec.quantity, 0) - nvl(p_mo_line_rec.quantity_delivered, 0);
    print_out('    l_qty_to_backorder:' || l_qty_to_backorder);

    /*Bug#5505709. Added the below If statement to set 'l_qty_to_backorder' to 0 when overpicking has been done.*/
    if (l_qty_to_backorder < 0 ) then
      l_qty_to_backorder := 0;
    end if;
    -- INVCONV BEGIN
    if p_mo_line_rec.secondary_uom is not null and p_mo_line_rec.secondary_uom <> fnd_api.g_miss_char then
      l_second_qty_to_backorder :=
        nvl(p_mo_line_rec.secondary_quantity, 0) - nvl(p_mo_line_rec.secondary_quantity_delivered, 0);
      print_out('    l_second_qty_to_backorder:' || l_second_qty_to_backorder);
   end if;
    -- INVCONV END
    if p_move_order_type = inv_globals.g_move_order_pick_wave then
      --print_out('    in mo type pick wabve' );
      open c_wsh_info;
      fetch c_wsh_info into l_delivery_detail_id, l_source_header_id, l_source_line_id, l_released_status;
      if c_wsh_info%notfound then
        close c_wsh_info;
        print_out('    NOTFOUND c_wsh_info' );
        raise fnd_api.g_exc_error;
      end if;
      close c_wsh_info;
      --print_out('    finished fetching' );
      --Call Update_Shipping_Attributes to backorder detail line
      l_shipping_attr(1).source_header_id      := l_source_header_id;
      l_shipping_attr(1).source_line_id        := l_source_line_id;
      l_shipping_attr(1).ship_from_org_id      := p_mo_line_rec.organization_id;
      l_shipping_attr(1).released_status       := l_released_status;
      l_shipping_attr(1).delivery_detail_id    := l_delivery_detail_id;
      l_shipping_attr(1).action_flag           := 'B';
      l_shipping_attr(1).cycle_count_quantity  := l_qty_to_backorder;
      l_shipping_attr(1).cycle_count_quantity2 := l_second_qty_to_backorder;  -- INVCONV
      l_shipping_attr(1).subinventory          := p_mo_line_rec.from_subinventory_code;
      l_shipping_attr(1).locator_id            := p_mo_line_rec.from_locator_id;

      if (l_debug = 1) then
        print_out('    Calling Update Shipping Attributes');
        print_out('      Source Header ID   = ' || l_shipping_attr(1).source_header_id);
        print_out('      Source Line ID     = ' || l_shipping_attr(1).source_line_id);
        print_out('      Ship From Org ID   = ' || l_shipping_attr(1).ship_from_org_id);
        print_out('      Released Status    = ' || l_shipping_attr(1).released_status);
        print_out('      Delivery Detail ID = ' || l_shipping_attr(1).delivery_detail_id);
        print_out('      Action Flag        = ' || l_shipping_attr(1).action_flag);
        print_out('      Cycle Count Qty    = ' || l_shipping_attr(1).cycle_count_quantity);
        print_out('      Sec Cycle Count Qty= ' || l_shipping_attr(1).cycle_count_quantity2); --INVCONV
        print_out('      Subinventory       = ' || l_shipping_attr(1).subinventory);
        print_out('      Locator ID         = ' || l_shipping_attr(1).locator_id);
      end if;

      wsh_interface.update_shipping_attributes(
        p_source_code        => 'INV'
      , p_changed_attributes => l_shipping_attr
      , x_return_status      => x_return_status
      );

      if (l_debug = 1) then
        print_out('    Updated Shipping Attributes - Return Status = ' || x_return_status);
      end if;

      if (x_return_status = fnd_api.g_ret_sts_error) then
        raise fnd_api.g_exc_error;
      elsif x_return_status = fnd_api.g_ret_sts_unexp_error then
        raise fnd_api.g_exc_unexpected_error;
      end if;

    elsif p_move_order_type = inv_globals.g_move_order_mfg_pick then
      if l_debug = 1 then
        print_out('    Chamando WIP_PICKING_PUB.UNALLOCATE_MATERIAL...');
        print_out('      WIP Entity ID     = ' || p_mo_line_rec.txn_source_id);
        print_out('      Operation Seq Num = ' || p_mo_line_rec.txn_source_line_id);
        print_out('      Inventory Item ID = ' || p_mo_line_rec.inventory_item_id);
        print_out('      Repetitive Sch ID = ' || p_mo_line_rec.reference_id);
        print_out('      Primary Qty       = ' || l_qty_to_backorder);
      end if;
      wip_picking_pub.unallocate_material(
        x_return_status          => x_return_status
      , x_msg_data               => x_msg_data
      , p_wip_entity_id          => p_mo_line_rec.txn_source_id
      , p_operation_seq_num      => p_mo_line_rec.txn_source_line_id
      , p_inventory_item_id      => p_mo_line_rec.inventory_item_id
      , p_repetitive_schedule_id => p_mo_line_rec.reference_id
      , p_primary_quantity       => l_qty_to_backorder
      );
      if (l_debug = 1) then
        print_out('    Unallocated WIP Material  - Return Status = ' || x_return_status);
      end if;

      if (x_return_status = fnd_api.g_ret_sts_error) then
        raise fnd_api.g_exc_error;
      elsif x_return_status = fnd_api.g_ret_sts_unexp_error then
        raise fnd_api.g_exc_unexpected_error;
      end if;
    end if;
    print_out('  FIM XXFR_WSH_PCK_BACKORDER.BACKORDER_SOURCE');
  exception
    when fnd_api.g_exc_error then
      x_return_status  := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
    when fnd_api.g_exc_unexpected_error then
      x_return_status  := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
    when others then
      x_return_status  := fnd_api.g_ret_sts_unexp_error;
      if fnd_msg_pub.check_msg_level(fnd_msg_pub.g_msg_lvl_unexp_error) then
        fnd_msg_pub.add_exc_msg(g_pkg_name);
      end if;
  end backorder_source;

  procedure backorder(
    p_line_id       in            number,
    x_return_status out nocopy    varchar2,
    x_msg_count     out nocopy    number,
    x_msg_data      out nocopy    varchar2
  ) is
  
    l_mo_line_rec        inv_move_order_pub.trolin_rec_type;
    l_mold_tbl           inv_mo_line_detail_util.g_mmtt_tbl_type;
    l_mo_type            number;
    l_allow_backordering varchar2(1) := 'Y';

    cursor c_allow_backordering is
      select 'N' from dual
      where exists( 
        select 1
        from 
          wms_dispatched_tasks wdt, 
          mtl_material_transactions_temp mmtt
        where 1=1
          and mmtt.move_order_line_id = l_mo_line_rec.line_id
          and wdt.transaction_temp_id = nvl(mmtt.parent_line_id, mmtt.transaction_temp_id)
          and (wdt.task_type is null or wdt.task_type <> wms_globals.g_wms_task_type_cycle_count) --ER 17461182
          and wdt.status in (4,9)
      )
    ;

    cursor c_mo_type is
      select mtrh.move_order_type
      from 
        mtl_txn_request_headers mtrh, 
        mtl_txn_request_lines mtrl
      where 1=1 
        and mtrl.line_id = l_mo_line_rec.line_id
        and mtrh.header_id = mtrl.header_id;

    -- INVCONV - Incorporate secondary transaction quantity below
    cursor c_mmtt_info is
      select 
        mmtt.move_order_line_id,
        mmtt.transaction_temp_id,
        abs(mmtt.primary_quantity)               primary_quantity,
        abs(mmtt.transaction_quantity)           transaction_quantity,
        abs(mmtt.secondary_transaction_quantity) secondary_transaction_quantity,
        mmtt.reservation_id
      from 
        mtl_material_transactions_temp mmtt
      where 1=1
        and mmtt.move_order_line_id = p_line_id
        and not exists (
          select 1 from mtl_material_transactions_temp t where t.parent_line_id = mmtt.transaction_temp_id
        )
      for update nowait;

    l_debug number := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
  begin
    print_out('XXFR_WSH_PCK_BACKORDER.BACKORDER');
    x_return_status  := fnd_api.g_ret_sts_success;
    -- Set savepoint
    
    savepoint xxfr_start_proc;
    if (l_debug = 1) then
      print_out('  Backordering for MO Line ID = ' || p_line_id);
    end if;

    l_mo_line_rec := inv_trolin_util.query_row(p_line_id);
    -- Querying the Move Order Type of the Line.
    open c_mo_type;
    fetch c_mo_type into l_mo_type;
    close c_mo_type;

    if (inv_install.adv_inv_installed(l_mo_line_rec.organization_id)) then
      open c_allow_backordering;
      fetch c_allow_backordering into l_allow_backordering;
      close c_allow_backordering;
    end if;

    if (l_debug = 1) then
      print_out('  Allow BackOrdering = ' || l_allow_backordering);
    end if;

    if (l_allow_backordering = 'Y') then
      if nvl(l_mo_line_rec.quantity_detailed, 0) - nvl(l_mo_line_rec.quantity_delivered, 0) > 0 then
        --print_out('    Before for loop.. l_mmtt_info ' );
        for l_mmtt_info in c_mmtt_info loop
          print_out('  l_mmtt_info.transaction_temp_id           :' || l_mmtt_info.transaction_temp_id );
          print_out('  p_line_id                                 :' || p_line_id);
          print_out('  l_mmtt_info.reservation_id                :' || l_mmtt_info.reservation_id);
          print_out('  l_mmtt_info.transaction_quantity          :' || l_mmtt_info.transaction_quantity);
          print_out('  l_mmtt_info.secondary_transaction_quantity:' || l_mmtt_info.secondary_transaction_quantity); -- INVCONV
          print_out('  l_mmtt_info.primary_quantity              :' || l_mmtt_info.primary_quantity);
          -- INVCONV - add a parameter for secondary_quantity
          delete_details(
            x_return_status              => x_return_status,
            x_msg_data                   => x_msg_data,
            x_msg_count                  => x_msg_count,
            p_transaction_temp_id        => l_mmtt_info.transaction_temp_id,
            p_move_order_line_id         => p_line_id,
            p_reservation_id             => l_mmtt_info.reservation_id,
            p_transaction_quantity       => l_mmtt_info.transaction_quantity,
            p_primary_trx_qty            => l_mmtt_info.primary_quantity,
            p_secondary_trx_qty          => l_mmtt_info.secondary_transaction_quantity
          );
          print_out('  x_return_status :' || x_return_status);
          if x_return_status = fnd_api.g_ret_sts_unexp_error then
            raise fnd_api.g_exc_unexpected_error;
          elsif x_return_status = fnd_api.g_ret_sts_error then
            raise fnd_api.g_exc_error;
          end if;
        end loop;
      end if;
      --print_out('    Before calling backorder_source ');
      --print_out('    l_mo_type' || l_mo_type);
      --
      backorder_source(
        x_return_status   => x_return_status,
        x_msg_data        => x_msg_data,
        x_msg_count       => x_msg_count,
        p_move_order_type => l_mo_type,
        p_mo_line_rec     => l_mo_line_rec
      );
      print_out('  x_return_status :' || x_return_status);
      if x_return_status = fnd_api.g_ret_sts_error then
        raise fnd_api.g_exc_error;
      elsif x_return_status = fnd_api.g_ret_sts_unexp_error then
        raise fnd_api.g_exc_unexpected_error;
      end if;

      if l_debug = 1 then
        print_out('  Updating Move Order Line to set Status = 5 and Qty Detailed = ' || l_mo_line_rec.quantity_delivered);
        print_out('  Updating Move Order Line Quantity = ' || l_mo_line_rec.quantity_delivered);
        print_out('  Updating Move Order Line Secondary Qty = ' || l_mo_line_rec.secondary_quantity_delivered); -- INVCONV
      end if;
      -- INVCONV BEGIN
      -- Fork the update statement below according to whether item tracks dual qty or not
      if l_mo_line_rec.secondary_uom is null then
        -- INVCONV Tracking in primary only
        update mtl_txn_request_lines
        set 
          line_status = 5,
          quantity_detailed = nvl(quantity_delivered,0),
          quantity = nvl(quantity_delivered,0)
        where line_id = p_line_id;
      else
        -- INVCONV Tracking in primary and secondary
        update mtl_txn_request_lines
        set 
          line_status = 5,
          quantity_detailed           = nvl(quantity_delivered,0),
          secondary_quantity_detailed = nvl(secondary_quantity_delivered,0),
          quantity                    = nvl(quantity_delivered,0),
          secondary_quantity          = nvl(secondary_quantity_delivered,0),
          status_date                 = sysdate   --BUG 6932648
        where line_id                 = p_line_id;
      end if;
      -- INVCONV END
    end if; -- quantity detailed >= 0
    --print_out('    check MO type ' || l_mo_type);
    if l_mo_type = inv_globals.g_move_order_pick_wave then
      print_out('  Chamando INV_TRANSFER_ORDER_PVT.CLEAN_RESERVATIONS...');
      inv_transfer_order_pvt.clean_reservations(
        p_source_line_id             => l_mo_line_rec.txn_source_line_id,
        x_return_status              => x_return_status,
        x_msg_count                  => x_msg_count,
        x_msg_data                   => x_msg_data
      );
      print_out('  x_return_status :' || x_return_status);
      if x_return_status = fnd_api.g_ret_sts_error then
        if (l_debug = 1) then
          print_out('  Clean Reservations - Expected Error occurred');
        end if;
        raise fnd_api.g_exc_error;
      elsif x_return_status = fnd_api.g_ret_sts_unexp_error then
        if (l_debug = 1) then
          print_out('  Clean Reservations - Unexpected Error occurred');
        end if;
        raise fnd_api.g_exc_unexpected_error;
      end if;
    end if;

    if l_allow_backordering = 'N' then
      fnd_message.set_name('WMS', 'WMS_ACTIVE_LOADED_TASKS_EXIST');
      fnd_message.set_token('LINE_ID', p_line_id);
      fnd_msg_pub.add;
      raise fnd_api.g_exc_error;
    end if;
    --commit;
    print_out('FIM XXFR_WSH_PCK_BACKORDER.BACKORDER');
  exception
    when fnd_api.g_exc_error then
      x_return_status  := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get(
        p_count => x_msg_count, 
        p_data => x_msg_data, 
        p_encoded=> 'F'
      );
      if l_allow_backordering = 'Y' then
        rollback to xxfr_start_proc;
      end if;
    when fnd_api.g_exc_unexpected_error then
      x_return_status  := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data, p_encoded=> 'F');
      rollback to xxfr_start_proc;
    when others then
      x_return_status  := fnd_api.g_ret_sts_unexp_error;
      if fnd_msg_pub.check_msg_level(fnd_msg_pub.g_msg_lvl_unexp_error) then
        fnd_msg_pub.add_exc_msg(g_pkg_name);
      end if;
      rollback to xxfr_start_proc;
  end backorder;

  procedure delete_details(
    p_transaction_temp_id  in            number,
    p_move_order_line_id   in            number,
    p_reservation_id       in            number,
    p_transaction_quantity in            number,
    p_primary_trx_qty      in            number,
    p_secondary_trx_qty    in            number,
    x_return_status        out nocopy    varchar2,
    x_msg_count            out nocopy    number,
    x_msg_data             out nocopy    varchar2
  ) is
  
    l_mtl_reservation_tbl       inv_reservation_global.mtl_reservation_tbl_type;
    l_mtl_reservation_rec       inv_reservation_global.mtl_reservation_rec_type;
    l_mtl_reservation_tbl_count number;
    l_original_serial_number    inv_reservation_global.serial_number_tbl_type;
    l_to_serial_number          inv_reservation_global.serial_number_tbl_type;
    l_error_code                number;
    l_count                     number;
    l_success                   boolean;
    l_umconvert_trans_quantity  number                                          := 0;
    l_mmtt_rec                  inv_mo_line_detail_util.g_mmtt_rec;
    l_primary_uom               varchar2(10);
    l_ato_item                  number                                          := 0;
    l_debug                     number  := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
    l_mo_backorder_flag         varchar2(2)  := 'N';       -- Added for the bug#22263505
    l_quantity_reserved                number;   -- Added for the bug#22263505
    l_secondary_quantity_reserved      number; -- Added for the bug#22263505

    --bugfix 16778046
    cursor c_fullfill_base is
    select nvl(fulfillment_base,'P')
    from mtl_material_transactions_temp
    where   transaction_temp_id = p_transaction_temp_id;

    l_fulfill_base varchar2(1)  :=  'P' ;

    l_rsv_detailed_qty number;
    l_rsv_secondary_detailed_qty number;         -- INVCONV
    l_rsv_reservation_qty number;
    l_rsv_pri_reservation_qty number;
    l_rsv_sec_reservation_qty number;            -- INVCONV

  begin
    print_out('  XXFR_WSH_PCK_BACKORDER.DELETE_DETAILS');
    x_return_status  := fnd_api.g_ret_sts_success;
    if (l_debug = 1) then
      print_out('    Transaction Temp ID = ' || p_transaction_temp_id);
      print_out('    Move Order Line ID  = ' || p_move_order_line_id);
      print_out('    Transaction Qty     = ' || p_transaction_quantity);
      print_out('    Secondary Qty       = ' || p_secondary_trx_qty);
      print_out('    Reservation ID      = ' || p_reservation_id);
    end if;

     --bugfix 16778046
    open  c_fullfill_base;
    fetch c_fullfill_base into l_fulfill_base;
    close c_fullfill_base;

    if p_reservation_id is not null then
      l_mtl_reservation_rec.reservation_id  := p_reservation_id;
      print_out('    Chamando INV_RESERVATION_PUB.QUERY_RESERVATION...');
      inv_reservation_pub.query_reservation(
        p_api_version_number         => 1.0,
        x_return_status              => x_return_status,
        x_msg_count                  => x_msg_count,
        x_msg_data                   => x_msg_data,
        p_query_input                => l_mtl_reservation_rec,
        x_mtl_reservation_tbl        => l_mtl_reservation_tbl,
        x_mtl_reservation_tbl_count  => l_mtl_reservation_tbl_count,
        x_error_code                 => l_error_code
      );

      print_out('    x_return_status             = ' || x_return_status);
      print_out('    l_error_code                = ' || l_error_code);
      print_out('    l_mtl_reservation_tbl_count = ' || l_mtl_reservation_tbl_count);
      if (x_return_status = fnd_api.g_ret_sts_error) then
        raise fnd_api.g_exc_error;
      elsif(x_return_status = fnd_api.g_ret_sts_unexp_error) then
        raise fnd_api.g_exc_unexpected_error;
      end if;

      if l_mtl_reservation_tbl_count > 0 then
        -- Bug#2621481: If reservations exist, check if the item is an ATO Item only if the profile WSH_RETAIN_ATO_RESERVATIONS = 'Y'
        if g_retain_ato_profile = 'Y' then
          print_out('    g_retain_ato_profile = Y');
          begin
            select 1, primary_uom_code
            into l_ato_item, l_primary_uom
            from mtl_system_items
            where 1=1
              and replenish_to_order_flag = 'Y'
              and bom_item_type = 4
              and inventory_item_id = l_mtl_reservation_tbl(1).inventory_item_id
              and organization_id = l_mtl_reservation_tbl(1).organization_id;
          exception when others then
            l_ato_item := 0;
          end;
        end if;
          print_out('    l_ato_item  = ' || l_ato_item);
          /* Bug# 2925113 */
          l_rsv_detailed_qty := nvl(l_mtl_reservation_tbl(1).detailed_quantity,0);
          l_rsv_secondary_detailed_qty := l_mtl_reservation_tbl(1).secondary_detailed_quantity; -- INVCONV - do not use NVL
          l_rsv_reservation_qty := nvl(l_mtl_reservation_tbl(1).reservation_quantity,0);
          l_rsv_pri_reservation_qty := nvl(l_mtl_reservation_tbl(1).primary_reservation_quantity,0);
          l_rsv_sec_reservation_qty := l_mtl_reservation_tbl(1).secondary_reservation_quantity;  -- INVCONV - do not use NVL
          /* End  of 2925113 */
        if l_ato_item = 1 then
          print_out('    l_ato_item = 1');
          -- If item is ato item, reduce the detailed quantity by the transaction
          -- quantity and retain the reservation. Convert to primary uom before
          -- reducing detailed quantity.
          l_mmtt_rec                                  := inv_mo_line_detail_util.query_row(p_transaction_temp_id);
          l_umconvert_trans_quantity                  := p_transaction_quantity;
          if l_mmtt_rec.inventory_item_id is not null and l_mmtt_rec.transaction_uom is not null then
            --print_out('    UOM Convert = ');
            l_umconvert_trans_quantity  := inv_convert.inv_um_convert(
              item_id                      => l_mmtt_rec.inventory_item_id,
              precision                    => null,
              from_quantity                => p_transaction_quantity,
              from_unit                    => l_mmtt_rec.transaction_uom,
              to_unit                      => l_primary_uom,
              from_name                    => null,
              to_name                      => null
            );
          end if;
          l_mtl_reservation_rec  := l_mtl_reservation_tbl(1);
          /* Bug# 2925113 */
          if(l_rsv_detailed_qty > abs(l_umconvert_trans_quantity)) then
            l_mtl_reservation_tbl(1).detailed_quantity  := l_rsv_detailed_qty - abs(l_umconvert_trans_quantity);
            -- INVCONV BEGIN
            -- For dual control items, compute the secondary detailed
            if l_mmtt_rec.secondary_uom_code is not null  and l_mmtt_rec.secondary_uom_code <> fnd_api.g_miss_char then
              l_mtl_reservation_tbl(1).secondary_detailed_quantity  := l_rsv_secondary_detailed_qty - abs(p_secondary_trx_qty);
            end if;
            -- INVCONV END
          else
            l_mtl_reservation_tbl(1).detailed_quantity  := 0;
            -- INVCONV BEGIN
            if l_mmtt_rec.secondary_uom_code is not null then
              l_mtl_reservation_tbl(1).secondary_detailed_quantity  := 0;
            end if;
            -- INVCONV END
          end if;
          /* End of Bug# 2925113 */

           /*Changed the below call for the bug#22263505. For fixing this issue the
            finalized solution is by passing the Deviation check if in case of
            back order. So for safer side instead of adding a new parameter in
            INV_RESERVATION_PUB.UPDATE_RESERVATION,
            adding a new parameter to INV_RESERVATION_PVT.UPDATE_RESERVATION and
            calling private API here */
          /*print_out('    call inv_reservation_pub.update_reservation = ');
          inv_reservation_pub.update_reservation(
            p_api_version_number         => 1.0
          , x_return_status              => x_return_status
          , x_msg_count                  => x_msg_count
          , x_msg_data                   => x_msg_data
          , p_original_rsv_rec           => l_mtl_reservation_rec
          , p_to_rsv_rec                 => l_mtl_reservation_tbl(1)
          , p_original_serial_number     => l_original_serial_number
          , p_to_serial_number           => l_to_serial_number
          );

          print_out('    x_return_status' || x_return_status);
          IF (x_return_status = fnd_api.g_ret_sts_error) THEN
            RAISE fnd_api.g_exc_error;
          ELSIF(x_return_status = fnd_api.g_ret_sts_unexp_error) THEN
            RAISE fnd_api.g_exc_unexpected_error;
          END IF; */
          print_out('    Chamando INV_RESERVATION_PVT.UPDATE_RESERVATION...');
          inv_reservation_pvt.update_reservation(
            p_api_version_number          => 1.0,
            x_return_status               => x_return_status,
            x_msg_count                   => x_msg_count,
            x_msg_data                    => x_msg_data,
            x_quantity_reserved           => l_quantity_reserved,
            x_secondary_quantity_reserved => l_secondary_quantity_reserved,
            p_original_rsv_rec            => l_mtl_reservation_rec,
            p_to_rsv_rec                  => l_mtl_reservation_tbl(1),
            p_original_serial_number      => l_original_serial_number,
            p_to_serial_number            => l_to_serial_number,
            p_mo_backorder_flag           => 'Y'
          );
          print_out('    x_return_status = ' || x_return_status );
          if (x_return_status = fnd_api.g_ret_sts_error) then
            raise fnd_api.g_exc_error;
          elsif(x_return_status = fnd_api.g_ret_sts_unexp_error) then
            raise fnd_api.g_exc_unexpected_error;
          end if;
        else
          l_mtl_reservation_rec := l_mtl_reservation_tbl(1);
          l_mmtt_rec            := inv_mo_line_detail_util.query_row(p_transaction_temp_id);
          print_out('    Allocation UOM  = ' || l_mmtt_rec.transaction_uom);
          print_out('    Reservation UOM = ' || l_mtl_reservation_rec.reservation_uom_code);

          if l_mmtt_rec.transaction_uom <> l_mtl_reservation_rec.reservation_uom_code then
            l_umconvert_trans_quantity  := inv_convert.inv_um_convert(
              item_id                      => l_mmtt_rec.inventory_item_id,
              precision                    => null,
              from_quantity                => abs(p_transaction_quantity),
              from_unit                    => l_mmtt_rec.transaction_uom,
              to_unit                      => l_mtl_reservation_rec.reservation_uom_code,
              from_name                    => null,
              to_name                      => null
            );
            if (x_return_status = fnd_api.g_ret_sts_error) then
              raise fnd_api.g_exc_error;
            elsif(x_return_status = fnd_api.g_ret_sts_unexp_error) then
              raise fnd_api.g_exc_unexpected_error;
            end if;
          else
            l_umconvert_trans_quantity  := abs(p_transaction_quantity);
          end if;
          print_out('    After UOM Conversion TxnQty = ' || l_umconvert_trans_quantity);
          /* Bug# 2925113 */
          if(l_rsv_detailed_qty > abs(p_transaction_quantity)) then
            l_mtl_reservation_tbl(1).detailed_quantity := l_rsv_detailed_qty - abs(p_transaction_quantity);
            -- INVCONV BEGIN
            -- For dual control items, compute the secondary detailed
            if l_mmtt_rec.secondary_uom_code is not null  and l_mmtt_rec.secondary_uom_code <> fnd_api.g_miss_char then
              l_mtl_reservation_tbl(1).secondary_detailed_quantity  := l_rsv_secondary_detailed_qty - abs(p_secondary_trx_qty);
            end if;
            -- INVCONV END
          else
             l_mtl_reservation_tbl(1).detailed_quantity := 0;
            -- INVCONV BEGIN
            -- For dual control items, zero the secondary detailed
            if l_mmtt_rec.secondary_uom_code is not null  and l_mmtt_rec.secondary_uom_code <> fnd_api.g_miss_char then
              l_mtl_reservation_tbl(1).secondary_detailed_quantity  := 0;
            end if;
            -- INVCONV END
          end if;
          --
          if(l_rsv_reservation_qty > abs(l_umconvert_trans_quantity)) then
             l_mtl_reservation_tbl(1).reservation_quantity := l_rsv_reservation_qty - abs(l_umconvert_trans_quantity);
            -- INVCONV BEGIN
            -- For dual control items, compute the secondary reservation qty
            if l_mmtt_rec.secondary_uom_code is not null  and l_mmtt_rec.secondary_uom_code <> fnd_api.g_miss_char then
              l_mtl_reservation_tbl(1).secondary_reservation_quantity := l_rsv_sec_reservation_qty - abs(p_secondary_trx_qty);
            end if;
            -- INVCONV END
          else
            l_mtl_reservation_tbl(1).reservation_quantity := 0;
            -- INVCONV BEGIN
            -- For dual control items, zero the secondary reservation qty
            if l_mmtt_rec.secondary_uom_code is not null  and l_mmtt_rec.secondary_uom_code <> fnd_api.g_miss_char then
              l_mtl_reservation_tbl(1).secondary_reservation_quantity := 0;
            end if;
            -- INVCONV END
          end if;

          if(l_rsv_pri_reservation_qty > abs(p_primary_trx_qty)) and l_fulfill_base <> 'S' then
            l_mtl_reservation_tbl(1).primary_reservation_quantity := l_rsv_pri_reservation_qty - abs(p_primary_trx_qty);
          else
            l_mtl_reservation_tbl(1).primary_reservation_quantity := 0;
            l_mtl_reservation_tbl(1).secondary_reservation_quantity := 0;  --bugfix 16778046
          end if;

       	  --bugfix 16778046
          if l_mmtt_rec.secondary_uom_code is not null and l_fulfill_base = 'S' then
            --
            if(l_rsv_sec_reservation_qty > abs(p_secondary_trx_qty)) then
              l_mtl_reservation_tbl(1).secondary_reservation_quantity :=  l_rsv_sec_reservation_qty - abs(p_secondary_trx_qty);
            else
              l_mtl_reservation_tbl(1).secondary_reservation_quantity := 0;
              l_mtl_reservation_tbl(1).primary_reservation_quantity := 0;
            end if;
            --
          end if ;
          --
          /* End of Bug# 2925113 */
          /*Changed the below call for the bug#22263505. For fixing this issue the
            finalized solution is by passing the Deviation check if in case of
            back order. So for safer side instead of adding a new parameter in
            INV_RESERVATION_PUB.UPDATE_RESERVATION,
            adding a new parameter to INV_RESERVATION_PVT.UPDATE_RESERVATION and
            calling private API here */
          /*inv_reservation_pub.update_reservation(
            p_api_version_number         => 1.0
          , x_return_status              => x_return_status
          , x_msg_count                  => x_msg_count
          , x_msg_data                   => x_msg_data
          , p_original_rsv_rec           => l_mtl_reservation_rec
          , p_to_rsv_rec                 => l_mtl_reservation_tbl(1)
          , p_original_serial_number     => l_original_serial_number
          , p_to_serial_number           => l_to_serial_number
          );
          print_out('    x_return_status from inv_reservation_pub.update_reservation ' || x_return_status );
          IF (x_return_status = fnd_api.g_ret_sts_error) THEN
            RAISE fnd_api.g_exc_error;
          ELSIF(x_return_status = fnd_api.g_ret_sts_unexp_error) THEN
            RAISE fnd_api.g_exc_unexpected_error;
          END IF; */
          print_out('    Chamando INV_RESERVATION_PVT.UPDATE_RESERVATION...');
          inv_reservation_pvt.update_reservation(
            p_api_version_number          => 1.0,
            x_return_status               => x_return_status,
            x_msg_count                   => x_msg_count,
            x_msg_data                    => x_msg_data,
            x_quantity_reserved           => l_quantity_reserved,
            x_secondary_quantity_reserved => l_secondary_quantity_reserved,
            p_original_rsv_rec            => l_mtl_reservation_rec,
            p_to_rsv_rec                  => l_mtl_reservation_tbl(1),
            p_original_serial_number      => l_original_serial_number,
            p_to_serial_number            => l_to_serial_number,
            p_mo_backorder_flag           => 'Y'
          );

          print_out('    x_return_status = ' || x_return_status );
          if (x_return_status = fnd_api.g_ret_sts_error) then
            raise fnd_api.g_exc_error;
          elsif(x_return_status = fnd_api.g_ret_sts_unexp_error) then
            raise fnd_api.g_exc_unexpected_error;
          end if;
        end if; -- reservation count > 0
      end if; -- ato item check
    end if;

    /* Bug 5474441 Commenting out the revert locator capacity as updation of locator          does not happen during pic release  */
    /*
    -- Bug 5361517
        print_out('    l_mmtt_rec.transaction_action_id = ' || l_mmtt_rec.transaction_action_id,'delete_details');
        print_out('    l_mmtt_rec.transaction_status = ' || l_mmtt_rec.transaction_status,'delete_details');

    IF ((l_mmtt_rec.transaction_status = 2)
       AND (l_mmtt_rec.transaction_action_id = INV_GLOBALS.G_ACTION_STGXFR))
    THEN

         inv_loc_wms_utils.revert_loc_suggested_capacity
              (
                 x_return_status              => x_return_status
               , x_msg_count                  => x_msg_count
               , x_msg_data                   => x_msg_data
               , p_organization_id            => l_mmtt_rec.organization_id
               , p_inventory_location_id      => l_mmtt_rec.transfer_to_location
               , p_inventory_item_id          => l_mmtt_rec.inventory_item_id
               , p_primary_uom_flag           => 'Y'
               , p_transaction_uom_code       => NULL
               , p_quantity                   => p_transaction_quantity
               );
        IF (x_return_status = fnd_api.g_ret_sts_error) THEN
            RAISE fnd_api.g_exc_error;
          ELSIF (x_return_status = fnd_api.g_ret_sts_unexp_error) THEN
            RAISE fnd_api.g_exc_unexpected_error;
         END IF;
    END IF;

    -- End  Bug 5361517
      */
      /* End of Bug 5474441 */

    print_out('    Chamando INV_TRX_UTIL_PUB.DELETE_TRANSACTION...' );
    inv_trx_util_pub.delete_transaction(
      x_return_status       => x_return_status,
      x_msg_data            => x_msg_data,
      x_msg_count           => x_msg_count,
      p_transaction_temp_id => p_transaction_temp_id
    );
    print_out('    x_return_status = ' || x_return_status );
    if (x_return_status = fnd_api.g_ret_sts_error) then
      raise fnd_api.g_exc_error;
    elsif(x_return_status = fnd_api.g_ret_sts_unexp_error) then
      raise fnd_api.g_exc_unexpected_error;
    end if;
    print_out('  FIM XXFR_WSH_PCK_BACKORDER.DELETE_DETAILS');
  exception
    when fnd_api.g_exc_error then
      x_return_status  := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
    when fnd_api.g_exc_unexpected_error then
      x_return_status  := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_msg_data);
    when others then
      x_return_status  := fnd_api.g_ret_sts_unexp_error;
      if fnd_msg_pub.check_msg_level(fnd_msg_pub.g_msg_lvl_unexp_error) then
        fnd_msg_pub.add_exc_msg(g_pkg_name);
      end if;
  end delete_details;

end xxfr_wsh_pck_backorder;
/

