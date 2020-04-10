set serveroutput on;
begin
declare
  l_msg_data       varchar2(240);
  l_msg_count      number;
  l_status         varchar2(1);
  l_rsv            inv_reservation_global.mtl_reservation_rec_type;
  l_dummy_sn       inv_reservation_global.serial_number_tbl_type;
  l_qtd            number;
  l_rsv_id         number;
  l_sales_order_id number;
  l_header_id      number := 107769;

  cursor cur is
    select 
      ool.request_date,
      ool.ship_from_org_id,
      ool.inventory_item_id,
      ool.header_id,
      ool.line_id,
      ool.order_quantity_uom,
      ool.ordered_quantity,
      msi.primary_uom_code,
      inv_convert.inv_um_convert(
        msi.inventory_item_id,
        null,
        ool.ordered_quantity,
        ool.order_quantity_uom,
        msi.primary_uom_code,
        null,
        null
      ) prim_qty
    from 
      oe_order_lines_all ool, 
      mtl_system_items_b msi
    where 1=1
      and ool.ship_from_org_id = msi.organization_id
      and ool.inventory_item_id = msi.inventory_item_id
      and ool.header_id = l_header_id
  ;
  
  procedure print_out(msg   in Varchar2) is
  begin
    dbms_output.put_line(msg);
  end;
  
begin
  begin
    select mso.sales_order_id
    into l_sales_order_id
    from 
      mtl_sales_orders        mso,
      oe_order_headers_all    ooh,
      oe_transaction_types_tl ott
    where 1=1
      and mso.segment1 = ooh.order_number
      and ott.transaction_type_id = ooh.order_type_id
      and mso.segment2 = ott.name
      and ott.language = 'PTB'
      and ooh.header_id = l_header_id
      and segment3 = 'ORDER ENTRY';
  exception
    when no_data_found then
      print_out('Erro ao buscar SALES_ORDER_ID');
      return;
  end;

  for c1 in cur loop
    --
    print_out('requirement_date :'||c1.request_date);
    print_out('organization_id  :'||c1.ship_from_org_id);
    print_out('inventory_item_id:'||c1.inventory_item_id);
    --
    l_rsv.reservation_id               := null;
    l_rsv.requirement_date             := c1.request_date;
    l_rsv.organization_id              := c1.ship_from_org_id;
    l_rsv.inventory_item_id            := c1.inventory_item_id;
    l_rsv.demand_source_type_id        := inv_reservation_global.g_source_type_oe;
    l_rsv.demand_source_name           := null;
    l_rsv.demand_source_header_id      := l_sales_order_id;
    l_rsv.demand_source_line_id        := c1.line_id;
    l_rsv.primary_uom_code             := c1.primary_uom_code;
    l_rsv.primary_uom_id               := null;
    l_rsv.reservation_uom_code         := c1.order_quantity_uom;
    l_rsv.reservation_uom_id           := null;
    l_rsv.reservation_quantity         := c1.ordered_quantity;
    l_rsv.primary_reservation_quantity := c1.prim_qty;
    l_rsv.autodetail_group_id          := null;
    l_rsv.external_source_code         := null;
    l_rsv.external_source_line_id      := null;
    l_rsv.supply_source_type_id        := inv_reservation_global.g_source_type_inv;
    l_rsv.supply_source_header_id      := null;
    l_rsv.supply_source_line_id        := null;
    l_rsv.supply_source_name           := null;
    l_rsv.supply_source_line_detail    := null;
    l_rsv.revision                     := null;
    l_rsv.subinventory_code            := 'MPG';
    l_rsv.subinventory_id              := null;
    l_rsv.locator_id                   := 33339;
    l_rsv.lot_number                   := 'L10001PAG';
    l_rsv.lot_number_id                := null;
    l_rsv.pick_slip_number             := null;
    l_rsv.lpn_id                       := null;
    l_rsv.attribute_category           := null;
    l_rsv.attribute1                   := null;
    l_rsv.attribute2                   := null;
    l_rsv.attribute3                   := null;
    l_rsv.attribute4                   := null;
    l_rsv.attribute5                   := null;
    l_rsv.attribute6                   := null;
    l_rsv.attribute7                   := null;
    l_rsv.attribute8                   := null;
    l_rsv.attribute9                   := null;
    l_rsv.attribute10                  := null;
    l_rsv.attribute11                  := null;
    l_rsv.attribute12                  := null;
    l_rsv.attribute13                  := null;
    l_rsv.attribute14                  := null;
    l_rsv.attribute15                  := null;
    l_rsv.ship_ready_flag              := null;
    l_rsv.demand_source_delivery       := null;
  
    inv_reservation_pub.create_reservation(
      p_api_version_number       => 1.0,
      p_init_msg_lst             => fnd_api.g_true,
      x_return_status            => l_status,
      x_msg_count                => l_msg_count,
      x_msg_data                 => l_msg_data,
      p_rsv_rec                  => l_rsv,
      p_serial_number            => l_dummy_sn,
      x_serial_number            => l_dummy_sn,
      p_partial_reservation_flag => fnd_api.g_false -- g_true
      ,
      p_force_reservation_flag   => fnd_api.g_false,
      p_validation_flag          => fnd_api.g_true,
      x_quantity_reserved        => l_qtd,
      x_reservation_id           => l_rsv_id
    );
  
    print_out('RETURN STATUS: ' || l_status);
    if l_status != 'S' then
      for j in 1 .. l_msg_count loop
        l_msg_data := fnd_msg_pub.get(j, 'F');
        print_out('Erro: ' || l_msg_data);
      end loop;
    end if;
  end loop;
end;
end;
/
