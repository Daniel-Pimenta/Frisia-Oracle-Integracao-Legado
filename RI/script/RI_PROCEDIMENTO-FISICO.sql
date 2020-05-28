set SERVEROUTPUT ON;
declare
  x_retorno      varchar2(3000);
  x_cod_retorno  number;
begin
  xxfr_ri_pck_int_rcvfisico.insert_rcv_tables(
    p_operation_id    => 31,
    p_organization_id => 123,
    p_process_flag    => true,
    p_fase            => null,
    p_group_id        => null,
    x_retorno         => x_retorno
  );
  dbms_output.put_line('Retorno:'||x_retorno);
  if (x_retorno='S') then
    commit;
    dbms_output.put_line('Retorno:'||x_retorno); 
  else
    rollback;
  end if;
  commit;
end;
/
set SERVEROUTPUT ON;
declare
  x_retorno      varchar2(3000);
  x_cod_retorno  number;
begin
  x_retorno:='S';
  XXFR_F189_OPEN_PROCESSES_PUB.APPROVE_INTERFACE( 
    p_organization_id => 123,
    p_operation_id    => 31,
    p_location_id     => 222,
    p_gl_date         => to_date ('30/04/2020','DD/MM/YYYY'),
    p_receive_date    => to_date ('30/04/2020','DD/MM/YYYY'),
    p_created_by      => fnd_profile.value('USER_ID'),
    p_source          => 'XXFR_NFE_FORNECEDOR',
    p_interface       => 'Y',
    p_int_invoice_id  => 54411
  );
  dbms_output.put_line('Retorno:'||x_retorno);
  if (x_retorno='S') then
    commit;
    dbms_output.put_line('Retorno:'||x_retorno); 
  else
    rollback;
  end if;
  commit;
end;
/

SELECT RECEIPT_NUM, SHIPMENT_NUM 
FROM RCV_SHIPMENT_HEADERS 
WHERE 1=1
  --and shipment_header_id = 50006
order by creation_date desc;

--receipt_num ='30' and ship_to_org_id = 123--SHIPMENT_HEADER_ID = 72927

--
select * from rcv_headers_interface 
where 1=1
  --and Header_interface_id in (3018,3019)
order by creation_date desc;

select 
  HEADER_INTERFACE_ID, 
  INTERFACE_TRANSACTION_ID, 
  GROUP_ID, 
  SHIPMENT_NUM, 
  TRANSACTION_TYPE, 
  PROCESSING_STATUS_CODE, 
  PROCESSING_MODE_CODE, 
  DESTINATION_TYPE_CODE,
  TRANSACTION_STATUS_CODE, 
  AUTO_TRANSACT_CODE,
  LOCATION_ID, DELIVER_TO_LOCATION_ID, SUBINVENTORY, LOCATOR_ID
from rcv_transactions_interface
where 1=1
  and AUTO_TRANSACT_CODE = 'DELIVER'
  --and Header_interface_id=3017
order by creation_date desc
;


select
  mwb.organization_id, 
  mwb.organization_code,
  mwb.subinventory_code,
  mwb.locator_id, 
  mwb.locator,
  mwb.inventory_item_id, 
  mwb.item, 
  mwb.item_description,
  mwb.uom, 
  mwb.on_hand
  ,cic.item_cost
from 
  MTL_ONHAND_TOTAL_MWB_V mwb
  ,cst_item_cost_type_v cic
  ,mtl_item_locations_kfv il
where 1=1
  and cic.inventory_item_id      = mwb.inventory_item_id
  and cic.organization_id        = mwb.organization_id
  --and cic.COST_TYPE = 'Average'
  --and il.inventory_location_id = mwb.locator_id(+)
  and cic.inventory_item_id = 38556
;

select distinct 
  ORGANIZATION_ID, ORGANIZATION_CODE, SUBINVENTORY_CODE, INVENTORY_ITEM_ID, ITEM_DESCRIPTION, ITEM, UOM --, ON_HAND
from MTL_ONHAND_TOTAL_MWB_V 
where 1=1
and inventory_item_id = 38556
and ORGANIZATION_ID = 123
;

select * from mtl_item_locations_kfv where inventory_item_id = 38556;

select *
  --batch_id, interface_header_id, interface_line_id, interface_transaction_id, table_name, error_message_name, column_name, error_message
from po_interface_errors 
where 1=1
  and interface_type = 'RCV-856'
  and interface_header_id = 4002
;
select * from rcv_transactions 
where 1=1
  --and INTERFACE_TRANSACTION_ID
;

select * from fnd_user where user_id = 1477;

select * from rcv_receipts_all_v
select * from cll_f189_invoices cfi;

select
  cfi.operation_id, cfi.organization_id,
  cfl.invoice_id, cfl.invoice_line_id, cfl.utilization_id, cfl.organization_id, cfl.item_id, cfl.uom, 
  cfl.description, cfl.shipment_header_id,
  pll.line_location_id, pll.po_header_id, pll.po_line_id,
  cfl.quantity cll_quantity,
  pll.quantity, 
  pll.quantity_received, 
  pll.unit_meas_lookup_code, pll.ship_to_location_id, pll.approved_flag
from 
  cll_f189_invoices      cfi,
  cll_f189_invoice_lines cfl,
  po_lines_all           pl,
  po_line_locations_all  pll
where 1=1
  and cfi.invoice_id       = cfl.invoice_id
  and pl.po_line_id        = pll.po_line_id
  and cfl.line_location_id = pll.line_location_id
  --and pll.closed_code      in ('APPROVED', 'OPEN')
  /*
  and cfi.invoice_id in (
    select invoice_id from cll_f189_invoice_lines 
    group by invoice_id having count(invoice_line_id) > 3
  )
  */
  --and cfi.operation_id    = 15
  --and cfi.organization_id = 137
order by cfi.creation_date desc 
;


