
select 
  ri.operation_id,
  ri.invoice_num,
  ril.receipt_flag,
  ril.shipment_header_id,
  ri.creation_date
from 
  cll_f189_invoices      ri, 
  cll_f189_invoice_lines ril
where 1=1
  --and ri.operation_id in (235, 236, 238)
  --and ri.organization_id = 123 
  and ri.invoice_id      = ril.invoice_id
  and exists(
    select '1'
    from rcv_transactions rcv
    where 1=1
      and rcv.shipment_header_id = ril.shipment_header_id
      and rcv.transaction_type = 'DELIVER'
  )
order by ri.creation_date desc
;

select * from rcv_transactions where shipment_header_id = 50009;
select * from rcv_headers_interface;
select * from rcv_transactions_interface;
select * from rcv_shipment_headers order by creation_date desc;
select * from rcv_shipment_lines order by creation_date desc;



            l_locator_id    := null;            
            l_subinv_code   := 'GER';
            --l_locator_code  := 'TRT.00.000.00';
            --l_lot_number    := 'L_TESTE';
            l_exp_date      := sysdate + 200;
select *
from mtl_item_locations
where 1=1
  and INVENTORY_ITEM_ID is not null;
  and organization_id       = 123
  and concatenated_segments = l_locator_code
;
