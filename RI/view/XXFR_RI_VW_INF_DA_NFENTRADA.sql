--DROP VIEW XXFR_RI_VW_INF_DA_NFENTRADA;
CREATE OR REPLACE VIEW XXFR_RI_VW_INF_DA_NFENTRADA as
  select 
    rct.customer_trx_id, 
    rct.trx_number, 
    rbs.name serie,
    (
    select distinct rbsa.global_attribute3
    from 
      ra_batch_sources_all     rbsa
      ,ra_customer_trx_all     rcta1
      ,jl_br_customer_trx_exts xna 
    where 1=1
      and rbsa.batch_source_id  = rcta1.batch_source_id
      and xna.customer_trx_id   = rcta1.customer_trx_id
      and rcta1.trx_number      = rct.trx_number
      and rcta1.customer_trx_id = rct.customer_trx_id
    )  serie_number,
    rct.trx_date,
    rct.batch_source_id, 
    rctl.warehouse_id,
    --rct.PURCHASE_ORDER,
    ass.vendor_id, 
    ass.vendor_site_id, 
    ass.vendor_site_code, 
    hl.location_id, 
    ass.party_site_id, 
    ass.payment_priority, 
    ass.terms_id,
    rct.term_id, 
    rct.term_due_date,
    hps.party_id, 
    hca.account_number,
    hca.cust_account_id,
    hcas.cust_acct_site_id,
    decode (
      hcas.global_attribute2,
      2,    
      substr (hcas.global_attribute3, 2)|| hcas.global_attribute4|| hcas.global_attribute5,
      hcas.global_attribute3 || hcas.global_attribute5
    ) document_number,
    hcsu.site_use_id, 
    hcsu.site_use_code, 
    hcsu.primary_flag, 
    hcsu.location,
    rct.cust_trx_type_id, 
    --
    rct.bill_to_customer_id,
    rct.ship_to_customer_id,
    rct.sold_to_customer_id, 
    rct.paying_customer_id, 
    --
    rct.bill_to_site_use_id,
    rct.ship_to_site_use_id,
    rct.sold_to_site_use_id,
    rct.paying_site_use_id,
    -- 
    rct.sold_to_contact_id, 
    rct.ship_to_contact_id, 
    --
    --rct.TERM_ID, rct.TERM_DUE_DATE, 
    rct.interface_header_attribute2, 
    rct.interface_header_context,
    --
    --rctl.inventory_item_id,
    --rctl.description,
    --rctl.quantity_invoiced,
    --rctl.unit_selling_price,
    rctl.extended_amount,
    --
    impostos.iss_base,
    impostos.iss,
    impostos.tx_iss,
    --
    impostos.pis_base,
    impostos.pis,
    impostos.tx_pis,
    --
    impostos.ipi_base,
    impostos.ipi,
    impostos.tx_ipi,
    --
    impostos.cofins_base,
    impostos.cofins,
    impostos.tx_cofins,
    --
    impostos.icms_base,
    impostos.icms,
    impostos.tx_icms,
    --
    impostos.icms_st_base,
    impostos.icms_st,
    impostos.tx_icms_st
  from 
    ap_supplier_sites_all     ass,
    hr_locations              hl,
    hz_party_sites            hps,
    hz_cust_accounts          hca,
    hz_cust_acct_sites_all    hcas,
    hz_cust_site_uses_all     hcsu,
    ra_customer_trx_all       rct,
    ra_batch_sources_all      rbs,
    (
      select CUSTOMER_TRX_ID, WAREHOUSE_ID, sum(decode(nvl(gross_extended_amount, 0),0,extended_amount,gross_extended_amount)) EXTENDED_AMOUNT 
      from ra_customer_trx_lines_all
      where line_type = 'LINE' --and customer_trx_id = rct.customer_trx_id
      group by CUSTOMER_TRX_ID, WAREHOUSE_ID
    ) rctl,
    (
      select 
        rctla.customer_trx_id
        --,rctla.link_to_cust_trx_line_id
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
        ,max(decode(substr(avta.tax_code,1,3),'ISS',    rctla.tax_rate,0)) tx_iss
        ,max(decode(substr(avta.tax_code,1,3),'IPI',    rctla.tax_rate,0)) tx_ipi
        ,max(case when substr(avta.tax_code,1,4) = 'ICMS' and substr(avta.tax_code,1,7) <> 'ICMS_ST' 
          then rctla.tax_rate
          else 0
          end
        ) tx_icms
        ,max(decode(substr(avta.tax_code,1,7),'ICMS_ST',rctla.tax_rate,0)) tx_icms_st
        ,max(decode(substr(avta.tax_code,1,4),'IRPJ',   rctla.tax_rate,0)) tx_irpj
        ,max(decode(substr(avta.tax_code,1,3),'PIS',    rctla.tax_rate,0)) tx_pis
        ,max(decode(substr(avta.tax_code,1,6),'COFINS', rctla.tax_rate,0)) tx_cofins
      from 
        ra_customer_trx_lines_all rctla
        ,ar_vat_tax_all           avta
      where 1 = 1
        and rctla.line_type        = 'TAX'
        and avta.global_attribute2 = 'Y'
        and avta.vat_tax_id        = rctla.vat_tax_id
        and (
             substr(avta.tax_code,1,3)  = 'ISS'
          or substr(avta.tax_code,1,3)  = 'PIS'
          or (substr(avta.tax_code,1,4) = 'ICMS' and substr(avta.tax_code,1,7) <> 'ICMS_ST')
          or substr(avta.tax_code,1,7)  = 'ICMS_ST'
          or substr(avta.tax_code,1,6)  = 'COFINS'
          or substr(avta.tax_code,1,4)  = 'IRPJ'
        )
        and rctla.extended_amount > 0
      group by rctla.customer_trx_id --, rctla.link_to_cust_trx_line_id, rctla.customer_trx_line_id
    ) impostos
  where 1=1
    and rct.customer_trx_id    = rctl.customer_trx_id
    and rct.batch_source_id    = rbs.batch_source_id
    and rct.customer_trx_id    = impostos.customer_trx_id (+)
    --
    and hl.inventory_organization_id  = rctl.warehouse_id
    and nvl(hl.inactive_date,sysdate) >= sysdate
    --
    and ass.party_site_id      = hps.party_site_id
    and ass.party_site_id      = hcas.party_site_id
    and hca.party_id           = hps.party_id
    and hcas.cust_account_id   = hca.cust_account_id
    and hcas.cust_acct_site_id = hcsu.cust_acct_site_id
    --
    and hca.status             = 'A'
    and hps.status             = 'A'
    and hcas.status            = 'A'
    and hcsu.status            = 'A'
    --
    and (
      (hcsu.site_use_code = 'BILL_TO' and hcsu.bill_to_site_use_id = rct.bill_to_site_use_id)
      or 
      (hcsu.site_use_code = 'SHIP_TO' and hcsu.site_use_id         = rct.ship_to_site_use_id)
    )
;
/


/*

select * from CLL_F189_ENTRY_OPERATIONS where operation_id = 235;

select entity_id from ra_customer_trx_all;

select * from XXFR_RI_VW_INF_DA_NFENTRADA
where 1=1
  --and Customer_trx_id = 245031
  and trx_number = '49'
  --and document_number = '54043875053'
  --and VENDOR_SITE_CODE = '2243.234525'
;

select * from ra_customer_trx_all where CUSTOMER_TRX_ID = 251031;
select entity_id from ra_customer_trx_lines_all where CUSTOMER_TRX_ID = 144019;

select entity_id, CUST_TRX_TYPE_ID, NAME, DESCRIPTION, TYPE
from ra_cust_trx_types_all
where 1=1
  and END_DATE is null
  and ORG_ID   = 81
;

select po_header_id from po_line_locations_all where line_location_id=148060;
select segment1 from po_headers_all where po_header_id = (
select po_header_id from po_line_locations_all where line_location_id=148060
);
select * from po_lines_all where po_line_id=145046;

select * from PO_DISTRIBUTIONS_ALL where PO_DISTRIBUTION_ID=148060;

select table_name from all_tables where table_name like 'PO_LINE%' order by 1;

*/
