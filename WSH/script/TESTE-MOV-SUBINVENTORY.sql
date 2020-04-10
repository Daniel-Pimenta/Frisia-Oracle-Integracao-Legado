set SERVEROUTPUT ON;
DECLARE
  l_ret_sts       number := 0;
  l_ret_srl_val   number;
  x_trx_tmp_id    number;
  l_ser_trx_id    number;
  x_proc_msg      varchar2 (500);
  
  l_inventory_item_id        number       := 13616;
  l_organization_id          number       := 103;
  l_from_locator_code        varchar2(30) := 'MPG.00.105.00';
  --
  l_from_subinventory_code   varchar2(30) := 'MPG';
  L_TO_SUBINVENTORY_CODE     varchar2(30) := null;
  l_from_locator_id          number       := 64;
  
  l_lot_number               varchar2(30) := 'L2';
BEGIN
  xxfr_pck_variaveis_ambiente.inicializar('ONT','UO_FRISIA');  
  --
  select distinct mil.subinventory_code, mil.inventory_location_id
  into l_from_subinventory_code, l_from_locator_id
  from
    mtl_parameters               mt,
    mtl_secondary_inventories    msi,
    mtl_item_locations           mil,
    mtl_system_items_b           msib,
    org_organization_definitions ood         
  where 1=1
    and ood.organization_id    = mt.organization_id
    and ood.organization_id    = mil.organization_id
    and ood.organization_id    = msi.organization_id
    and msib.INVENTORY_ITEM_ID = l_inventory_item_id
    --
    and msi.secondary_inventory_name = mil.segment1
    and (mil.SEGMENT1||'.'||mil.SEGMENT2||'.'||mil.SEGMENT3||'.'||mil.SEGMENT4) = l_from_locator_code
    and ood.organization_id = l_organization_id
  ;
  l_ret_sts := INV_TRX_UTIL_PUB.insert_line_trx (
     p_trx_hdr_id                    => NULL,
     p_item_id                       => l_inventory_item_id,
     --p_revision                      => 'B6',
     p_org_id                        => l_organization_id,
     --
     p_subinv_code                   => l_from_subinventory_code,
     p_tosubinv_code                 => l_to_subinventory_code,
     --
     p_locator_id                    => NULL,
     p_tolocator_id                  => NULL,
     --
     --p_xfr_org_id                    => 103,
     p_trx_action_id                 => 28,
     p_trx_type_id                   => 52,
     p_trx_src_type_id               => 2,
     p_trx_qty                       => 950,
     
     p_pri_qty                       => 1000,
     p_uom                           => 'KG',
     p_date                          => SYSDATE,
     p_reason_id                     => NULL,
     p_user_id                       => fnd_profile.value('USER_ID'),
     p_frt_code                      => NULL,
     p_ship_num                      => NULL,
     p_dist_id                       => NULL,
     p_way_bill                      => NULL,
     p_exp_arr                       => NULL,
     p_cost_group                    => NULL,
     p_from_lpn_id                   => NULL,
     p_cnt_lpn_id                    => NULL,
     p_xfr_lpn_id                    => NULL,
     p_trx_src_id                    => NULL,
     --p_xfr_cost_group                => 1003,
     p_completion_trx_id             => NULL,
     p_flow_schedule                 => NULL,
     p_trx_cost                      => NULL,
     p_project_id                    => NULL,
     p_task_id                       => NULL,
     p_cost_of_transfer              => NULL,
     p_cost_of_transportation        => NULL,
     p_transfer_percentage           => NULL,
     p_transportation_cost_account   => NULL,
     p_planning_org_id               => NULL,
     p_planning_tp_type              => NULL,
     p_owning_org_id                 => NULL,
     p_owning_tp_type                => NULL,
     p_trx_src_line_id               => NULL,
     p_secondary_trx_qty             => NULL,
     p_secondary_uom                 => NULL,
     p_move_order_line_id            => NULL,
     p_posting_flag                  => 'Y',
     p_move_order_header_id          => NULL,
     p_serial_allocated_flag         => NULL,
     p_transaction_status            => NULL,
     p_process_flag                  => 'Y',
     x_trx_tmp_id                    => x_trx_tmp_id,
     x_proc_msg                      => x_proc_msg
  );
  DBMS_OUTPUT.PUT_LINE ('Return Status   :' || l_ret_sts);
  DBMS_OUTPUT.PUT_LINE ('x_trx_tmp_id    :' || x_trx_tmp_id);
  DBMS_OUTPUT.PUT_LINE ('Trx Line Message:' || x_proc_msg);
  DBMS_OUTPUT.PUT_LINE ('');
  
  if nvl(x_trx_tmp_id, 0) > 0 then
    DBMS_OUTPUT.PUT_LINE(    'Chamando INV_TRX_UTIL_PUB.INSERT_LOT_TRX...');
    l_ret_sts := inv_trx_util_pub.insert_lot_trx(
      p_trx_tmp_id => x_trx_tmp_id,
      p_user_id    => fnd_profile.value('USER_ID'),
      p_lot_number => l_lot_number,
      p_trx_qty    => 1000,
      p_pri_qty    => 1000,
      --    
      x_ser_trx_id => l_ser_trx_id,
      x_proc_msg   => l_ret_sts
    );
    DBMS_OUTPUT.PUT_LINE('    ID :'||l_ser_trx_id);
    DBMS_OUTPUT.PUT_LINE('    Msg:'||l_ret_sts);
  end if;
  
  IF (l_ret_sts = 9) THEN
    l_ret_sts := INV_TRX_UTIL_PUB.insert_ser_trx (
      p_trx_tmp_id                  => x_trx_tmp_id,
      p_user_id                     => fnd_profile.value('USER_ID'),
      p_fm_ser_num                  => 'KK506310009',
      p_to_ser_num                  => 'KK506310009',
      p_ven_ser_num                 => NULL,
      p_vet_lot_num                 => NULL,
      p_parent_ser_num              => NULL,
      p_end_item_unit_num           => NULL,
      p_serial_attribute_category   => NULL,
      p_orgination_date             => NULL,
      p_c_attribute1                => NULL,
      p_c_attribute2                => NULL,
      p_c_attribute3                => NULL,
      p_c_attribute4                => NULL,
      p_c_attribute5                => NULL,
      p_c_attribute6                => NULL,
      p_c_attribute7                => NULL,
      p_c_attribute8                => NULL,
      p_c_attribute9                => NULL,
      p_c_attribute10               => NULL,
      p_c_attribute11               => NULL,
      p_c_attribute12               => NULL,
      p_c_attribute13               => NULL,
      p_c_attribute14               => NULL,
      p_c_attribute15               => NULL,
      p_c_attribute16               => NULL,
      p_c_attribute17               => NULL,
      p_c_attribute18               => NULL,
      p_c_attribute19               => NULL,
      p_c_attribute20               => NULL,
      p_d_attribute1                => NULL,
      p_d_attribute2                => NULL,
      p_d_attribute3                => NULL,
      p_d_attribute4                => NULL,
      p_d_attribute5                => NULL,
      p_d_attribute6                => NULL,
      p_d_attribute7                => NULL,
      p_d_attribute8                => NULL,
      p_d_attribute9                => NULL,
      p_d_attribute10               => NULL,
      p_n_attribute1                => NULL,
      p_n_attribute2                => NULL,
      p_n_attribute3                => NULL,
      p_n_attribute4                => NULL,
      p_n_attribute5                => NULL,
      p_n_attribute6                => NULL,
      p_n_attribute7                => NULL,
      p_n_attribute8                => NULL,
      p_n_attribute9                => NULL,
      p_n_attribute10               => NULL,
      p_status_id                   => NULL,
      p_territory_code              => NULL,
      p_time_since_new              => NULL,
      p_cycles_since_new            => NULL,
      p_time_since_overhaul         => NULL,
      p_cycles_since_overhaul       => NULL,
      p_time_since_repair           => NULL,
      p_cycles_since_repair         => NULL,
      p_time_since_visit            => NULL,
      p_cycles_since_visit          => NULL,
      p_time_since_mark             => NULL,
      p_cycles_since_mark           => NULL,
      p_number_of_repairs           => NULL,
      p_validation_level            => NULL,
      p_wms_installed               => NULL,
      p_quantity                    => 1,
      p_attribute_category          => NULL,
      p_attribute1                  => NULL,
      p_attribute2                  => NULL,
      p_attribute3                  => NULL,
      p_attribute4                  => NULL,
      p_attribute5                  => NULL,
      p_attribute6                  => NULL,
      p_attribute7                  => NULL,
      p_attribute8                  => NULL,
      p_attribute9                  => NULL,
      p_attribute10                 => NULL,
      p_attribute11                 => NULL,
      p_attribute12                 => NULL,
      p_attribute13                 => NULL,
      p_attribute14                 => NULL,
      p_attribute15                 => NULL,
      p_dffupdatedflag              => NULL,
      x_proc_msg                    => x_proc_msg
    );
    --
    DBMS_OUTPUT.PUT_LINE ('Return Status from Srl:' || l_ret_sts);
    DBMS_OUTPUT.PUT_LINE ('Srl Line Message      :' || x_proc_msg);
    --
    IF (l_ret_sts = 0) THEN
      UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
      SET TRANSACTION_MODE = 3
      WHERE TRANSACTION_TEMP_ID = x_trx_tmp_id;
      COMMIT;
    END IF;
  END IF;                                           
END;
