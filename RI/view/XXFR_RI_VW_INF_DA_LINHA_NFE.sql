CREATE OR REPLACE VIEW XXFR_RI_VW_INF_DA_LINHA_NFE as
  select 
    rctl.customer_trx_id,
    rctl.customer_trx_line_id,   
    rctl.line_number, 
    rctl.set_of_books_id, 
    rctl.inventory_item_id, 
    rctl.description, 
    rctl.quantity_invoiced, 
    rctl.unit_selling_price, 
    rctl.line_type, 
    rctl.interface_line_context,
    --po.PO_HEADER_ID, 
    --po.PO_LINE_ID,
    rctl.interface_line_attribute3 po_line_location_id,
    rctl.uom_code, 
    rctl.org_id, 
    rctl.warehouse_id,
    rctl.extended_amount,
    --
    impostos.iss_base,
    impostos.iss,
    impostos.iss_tx,
    --
    impostos.pis_base,
    impostos.pis,
    impostos.pis_tx,
    --
    impostos.ipi_base,
    impostos.ipi,
    impostos.ipi_tx,
    --
    impostos.cofins_base,
    impostos.cofins,
    impostos.cofins_tx,
    --
    impostos.icms_base,
    impostos.icms,
    impostos.icms_tx,
    --
    impostos.icms_st_base,
    impostos.icms_st,
    impostos.icms_st_tx
  from 
    ra_customer_trx_lines_all rctl,
    (
      select 
        rctla.customer_trx_id
        ,rctla.link_to_cust_trx_line_id
        --,rctla.customer_trx_line_id
        ,max(decode(substr(avta.tax_code,1,3),'ISS',    rctla.taxable_amount,0)) iss_base
        ,max(decode(substr(avta.tax_code,1,3),'IPI',    rctla.taxable_amount,0)) ipi_base
        ,max(case when substr(avta.tax_code,1,4) = 'ICMS' and substr(avta.tax_code,1,7) <> 'ICMS_ST' 
          then rctla.taxable_amount
          else 0
          end
        ) icms_base
        ,max(decode(substr(avta.tax_code,1,7),'ICMS_ST',rctla.taxable_amount,0)) icms_st_base 
        ,max(decode(substr(avta.tax_code,1,4),'IRPJ',   rctla.taxable_amount,0)) irpj_base
        ,max(decode(substr(avta.tax_code,1,3),'PIS',    rctla.taxable_amount,0)) pis_base
        ,max(decode(substr(avta.tax_code,1,6),'COFINS', rctla.taxable_amount,0)) cofins_base
        --
        ,max(decode(substr(avta.tax_code,1,3),'ISS',    rctla.extended_amount,0)) iss
        ,max(decode(substr(avta.tax_code,1,3),'IPI',    rctla.extended_amount,0)) ipi
        ,max(case when substr(avta.tax_code,1,4) = 'ICMS' and substr(avta.tax_code,1,7) <> 'ICMS_ST'
          then rctla.extended_amount
          else 0
          end
        ) icms
        ,max(decode(substr(avta.tax_code,1,7),'ICMS_ST',rctla.extended_amount,0)) icms_st 
        ,max(decode(substr(avta.tax_code,1,4),'IRPJ',   rctla.extended_amount,0)) irpj
        ,max(decode(substr(avta.tax_code,1,3),'PIS',    rctla.extended_amount,0)) pis
        ,max(decode(substr(avta.tax_code,1,6),'COFINS', rctla.extended_amount,0)) cofins      
        --
        ,max(decode(substr(avta.tax_code,1,3),'ISS',    rctla.tax_rate,0)) iss_tx
        ,max(decode(substr(avta.tax_code,1,3),'IPI',    rctla.tax_rate,0)) ipi_tx
        ,max(case when substr(avta.tax_code,1,4) = 'ICMS' and substr(avta.tax_code,1,7) <> 'ICMS_ST' 
          then rctla.tax_rate
          else 0
          end
        ) icms_tx
        ,max(decode(substr(avta.tax_code,1,7),'ICMS_ST',rctla.tax_rate,0)) icms_st_tx
        ,max(decode(substr(avta.tax_code,1,4),'IRPJ',   rctla.tax_rate,0)) irpj_tx
        ,max(decode(substr(avta.tax_code,1,3),'PIS',    rctla.tax_rate,0)) pis_tx
        ,max(decode(substr(avta.tax_code,1,6),'COFINS', rctla.tax_rate,0)) cofins_tx
      from 
        ra_customer_trx_lines_all rctla
        ,ar_vat_tax_all           avta
      where 1 = 1
        and rctla.line_type        = 'TAX'
        and avta.global_attribute2 = 'Y'
        and avta.vat_tax_id        = rctla.vat_tax_id
        and (
             substr(avta.tax_code,1,3) = 'ISS'
          or substr(avta.tax_code,1,3) = 'PIS'
          or substr(avta.tax_code,1,4) = 'ICMS'
          or substr(avta.tax_code,1,6) = 'COFINS'
          or substr(avta.tax_code,1,4) = 'IRPJ'
        )
        and rctla.extended_amount > 0
      group by rctla.customer_trx_id, rctla.link_to_cust_trx_line_id --, rctla.customer_trx_line_id
    ) impostos
    --,po_line_locations_all    po
  where 1=1
    and rctl.line_type                 = 'LINE' 
    --and rctl.interface_line_attribute3 = po.LINE_LOCATION_ID (+)
    and rctl.customer_trx_line_id      = impostos.link_to_cust_trx_line_id (+)
;
/

select * from XXFR_RI_VW_INF_DA_LINHA_NFE where customer_trx_id = '251031';

select PO_HEADER_ID, PO_LINE_ID from po_line_locations_all where LINE_LOCATION_ID=232092;

select * from ra_customer_trx_lines_all where customer_trx_id = '251031';
