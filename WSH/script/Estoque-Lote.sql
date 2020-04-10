DECLARE
   x_return_status         VARCHAR2 (50);
   x_msg_count             VARCHAR2 (50);
   x_msg_data              VARCHAR2 (50);
   v_item_id               NUMBER;
   v_org_id                NUMBER;
   v_qoh                   NUMBER;
   v_rqoh                  NUMBER;
   v_atr                   NUMBER;
   v_att                   NUMBER;
   v_qr                    NUMBER;
   v_qs                    NUMBER;
   v_lot_control_code      BOOLEAN;
   v_serial_control_code   BOOLEAN;
BEGIN
  -- Set the variable values
  v_item_id := '27974';
  v_org_id := 162;
  v_qoh := NULL;
  v_rqoh := NULL;
  v_atr := NULL;
  v_lot_control_code := true;
  v_serial_control_code := FALSE;
  
  -- Set the org context
  fnd_client_info.set_org_context (1);
 
  -- Call API
  inv_quantity_tree_pub.query_quantities(
    p_api_version_number       => 1.0,
    p_init_msg_lst             => 'F',
    x_return_status            => x_return_status,
    x_msg_count                => x_msg_count,
    x_msg_data                 => x_msg_data,
    p_organization_id          => v_org_id,
    p_inventory_item_id        => v_item_id,
    p_tree_mode                => apps.inv_quantity_tree_pub.g_transaction_mode, -- or 3
    p_is_revision_control      => FALSE,
    p_is_lot_control           => v_lot_control_code, -- is_lot_control,
    p_is_serial_control        => v_serial_control_code,
    p_revision                 => NULL,      -- p_revision,
    p_lot_number               => null,      --p_lot_number,
    p_lot_expiration_date      => SYSDATE,
    p_subinventory_code        => null, --'EXP',      -- p_subinventory_code,
    p_locator_id               => NULL,      -- p_locator_id,
    --p_cost_group_id            => NULL,      -- cg_id,
    p_onhand_source            => 3,
    x_qoh                      => v_qoh,     -- Quantity on-hand
    x_rqoh                     => v_rqoh,    --reservable quantity on-hand
    x_qr                       => v_qr,
    x_qs                       => v_qs,
    x_att                      => v_att,     -- available to transact
    x_atr                      => v_atr      -- available to reserve
  );
  --
  DBMS_OUTPUT.put_line ('On-Hand Quantity       : ' || v_qoh);
  DBMS_OUTPUT.put_line ('Reserv On-Hand Quantity: ' || v_rqoh);
  DBMS_OUTPUT.put_line ('Available to reserve   : ' || v_atr);
  DBMS_OUTPUT.put_line ('Quantity Reserved      : ' || v_qr);
  DBMS_OUTPUT.put_line ('Quantity Suggested     : ' || v_qs);
  DBMS_OUTPUT.put_line ('Available to Transact  : ' || v_att);
  DBMS_OUTPUT.put_line ('Available to Reserve   : ' || v_atr);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line ('ERROR: ' || SQLERRM);
END;
/

select 
  mmt.organization_id,
  mmt.inventory_item_id,
  --mln.parent_lot_number,
  mln.lot_number,
  --mmt.acct_period_id,
  trunc(mmt.transaction_date) transaction_date,
  mmt.transaction_id,
  --mog.origin_txn_id,
  mog.parent_object_type,
  mog.parent_object_id,
  mog.object_type,
  mog.object_id,
  --trunc(gbh.actual_cmplt_date),
  gbh.batch_no,
  gbh.batch_id,
  --mln.grade_code,
  abs(mtln.primary_quantity) transaction_qty
from 
  mtl_object_genealogy mog,
  mtl_lot_numbers mln,
  mtl_transaction_lot_numbers mtln,
  mtl_material_transactions mmt,
  gme_batch_header gbh
where 1=1
  and mln.gen_object_id      = mog.parent_object_id
  and mtln.inventory_item_id = mln.inventory_item_id
  and mtln.organization_id   = mln.organization_id
  and mtln.lot_number        = mln.lot_number
  and mmt.transaction_id     = mtln.transaction_id
  and mmt.transaction_id     not in (
    select distinct mmt1.source_line_id 
    from mtl_material_transactions mmt1
    where 1=1
      and mmt1.transaction_source_id = mmt.transaction_source_id  
      and mmt1.trx_source_line_id = mmt.trx_source_line_id
      and mmt1.organization_id = mmt.organization_id  
      and mmt1.source_line_id is not null
  )
  and gbh.batch_id           = mmt.transaction_source_id
  and gbh.organization_id    = mmt.organization_id
  and mtln.inventory_item_id = 13630
order by 1,2,3,4,5;

SELECT 
  msib.organization_id,
  msib.segment1 "Item Name",
  msib.description,
  ml.meaning,
  --msib.auto_lot_alpha_prefix "Lot Prefix",
  --msib.start_auto_lot_number "Lot Starting Number",
  (mil.segment1||'.'||mil.segment2||'.'||mil.segment3||'.'||mil.segment4) end_estoque,
  mln.lot_number
FROM 
  mtl_system_items_b  msib, 
  mtl_lot_numbers     mln, 
  mfg_lookups         ml,
  mtl_item_locations  mil
WHERE 1=1   
  and msib.organization_id   = mil.organization_id
  and msib.inventory_item_id = mil.inventory_item_id
  and msib.organization_id   = mln.organization_id
  AND msib.inventory_item_id = mln.inventory_item_id
  AND msib.lot_control_code  = ml.lookup_code
  AND ml.lookup_type         = 'MTL_LOT_CONTROL'
  --AND msib.segment1          = '90170'
  and msib.inventory_item_id = 13630
  
;


select distinct 
  --mil.inventory_item_id,
  mil.inventory_location_id,
  --mil.inventory_location_type,
  mil.subinventory_code, 
  --msi.subinventory_type, 
  --mil.description,
  --msi.description description2,
  --msi.default_cost_group_id,
  (mil.segment1||'.'||mil.segment2||'.'||mil.segment3||'.'||mil.segment4) end_estoque,
  moqd.lot_number, 
  trunc(moqd.date_received) date_received,
  msib.lot_control_code
from
  mtl_system_items_b           msib,
  --mtl_secondary_inventories    msi,
  mtl_item_locations           mil,
  mtl_onhand_quantities_detail moqd
where 1=1
  --and msi.organization_id          = mil.organization_id
  --and msi.secondary_inventory_name = mil.segment1
  and msib.organization_id         = mil.organization_id
  and msib.inventory_item_id       = mil.inventory_item_id
  --
  and mil.inventory_location_id    = moqd.locator_id
  and msib.inventory_item_id       = moqd.inventory_item_id 
  --and msib.lot_control_code        = '2'
  --
  --and mil.organization_id          = 105
  and mil.inventory_item_id        = 13630
  --and (mil.segment1||'.'||mil.segment2||'.'||mil.segment3||'.'||mil.segment4) = p_linhas.cd_endereco_estoque
  --and rownum = 1
order by trunc(moqd.date_received)
;


select distinct 
  a.ORGANIZATION_ID, 
  a.INVENTORY_ITEM_ID, 
  msib.segment1,
  a.SUBINVENTORY_CODE,
  a.LOCATOR_ID, 
  a.LOT_NUMBER, 
  a.COST_GROUP_ID,
  --a.PRIMARY_TRANSACTION_QUANTITY, 
  --a.TRANSACTION_UOM_CODE, 
  --a.TRANSACTION_QUANTITY, 
  --a.date_received,
  a.LPN_ID
from 
  mtl_onhand_quantities_detail a,
  mtl_system_items_b           msib    
where 1=1
  and a.INVENTORY_ITEM_ID = 13630
  --and msib.segment1 = '90170'
  and msib.INVENTORY_ITEM_ID = a.INVENTORY_ITEM_ID
--order by trunc(a.date_received)
;
--locator..
xxfr_inv_pck_obter_endereco.id_endereco_estoque('358', 'PAG.00.419.00')	id_endereco_estoque,

select lot.lot_number,  est.transaction_quantity 
from 
  mtl_onhand_quantities est, 
  mtl_lot_numbers lot
where 1=1 
and est.inventory_item_id 	= lot.inventory_item_Id
and est.organization_id 	  = lot.organization_id
and est.lot_number		  	  = lot.lot_number
--and est.locator_id  		  	= pp_locator_id
--and est.subinventory_code 	= pp_subinventory_code
and lot.inventory_item_id		= 13630
--and lot.organization_id		  = pp_organization_id
order by lot.creation_date desc;