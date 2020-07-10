--DROP VIEW XXFR_RI_VW_INF_DA_NFENTRADA;
CREATE OR REPLACE VIEW XXFR_RI_VW_INF_DA_NFENTRADA as
  select 
    rct.org_id,
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
--select * from XXFR_RI_VW_INF_DA_NFENTRADA;

--DROP VIEW XXFR_RI_VW_INF_DA_INVOICE;
CREATE OR REPLACE VIEW XXFR_RI_VW_INF_DA_INVOICE as
select distinct
  i.invoice_id, i.invoice_num, i.entity_id, i.organization_id, i.location_id, i.operation_id, i.series, i.invoice_amount, i.invoice_date, i.invoice_type_id,
  i.terms_id, i.terms_date, i.fiscal_document_model, i.source_state_id, i.destination_state_id, i.eletronic_invoice_key,
  it.invoice_type_code, it.requisition_type, it.invoice_type_lookup_code, it.description, it.ar_transaction_type_id, it.ar_source_id,
  f.business_vendor_id, f.document_type, f.document_number,
  i.ar_interface_flag, dbms_lob.substr( i.comments, 200, 1 ) comments,
  v.vendor_site_id, v.vendor_site_code,
  q.plan_name, 
  --q.EC_ID_TP_NF_AR, q.EC_TP_NF_AR, 
  q.ec_id_tp_nf_dev_ri, q.ec_tp_nf_dev_ri,
  q.ec_cfop_entrada, q.ec_cfop_saida, 
  q.ec_organizacao organization_code,  
  q.ec_tp_doc_fiscal_ri, q.ec_tp_nf_ri, 
  q.ec_id_tp_nf_ri, q.ec_utilizacao_fiscal, q.ec_tp_icms, q.ec_indicador_trib_icms, q.ec_cst_icms, q.ec_cst_ipi, 
  q.ec_indicador_trib_ipi, q.ec_cst_pis, q.ec_cst_cofins, 
  hca.cust_account_id, hca.party_id, hca.account_number, hca.customer_type, hca.account_name,
  hcas.cust_acct_site_id, hcas.party_site_id, hcas.attribute19, hcas.attribute20, hcas.global_attribute2, hcas.global_attribute3, hcas.global_attribute4, hcas.global_attribute5, hcas.global_attribute6, hcas.global_attribute8,
  hcsu.site_use_id, hcsu.site_use_code, hcsu.primary_flag, hcsu.location, hcsu.bill_to_site_use_id, hcsu.orig_system_reference,
  'FIM' trailer
from 
  cll_f189_invoices             i,
  cll_f189_invoice_types        it,   
  cll_f189_fiscal_entities_all  f,
  --
  cll_f189_query_customers_v    c,
  cll_f189_query_vendors_v      v,
  --
  hz_cust_accounts              hca,
  hz_cust_acct_sites_all        hcas,
  hz_cust_site_uses_all         hcsu,
  --
  q_pc_transferencia_ar_ri_v    q
where 1=1
  and i.entity_id             = f.entity_id
  and i.entity_id             = v.entity_id
  and f.document_number       = v.document_number
  and f.document_number       = c.document_number
  --
  and i.invoice_type_id       = it.invoice_type_id
  and i.organization_id       = it.organization_id
  --
  and hcas.cust_account_id    = hca.cust_account_id
  and hcsu.cust_acct_site_id  = hcas.cust_acct_site_id
  and hcsu.site_use_code      = 'SHIP_TO'
  and hcas.cust_acct_site_id  = c.cust_acct_site_id
  --
  and hcsu.location           = v.vendor_site_code
  --
  and (
    (f.document_type = 'CNPJ' and f.document_number = to_number(hcas.global_attribute3||hcas.global_attribute4||hcas.global_attribute5))
    or 
    (f.document_type = 'CPF' and f.document_number = to_number(hcas.global_attribute3||hcas.global_attribute5))
  )
  and i.invoice_type_id       = q.ec_id_tp_nf_ri (+)
  and i.organization_id       = q.ec_id_organizacao (+)
  --
  --and i.invoice_num           = '596' 
  --and i.series                = '000'
  --and hca.ACCOUNT_NUMBER      = '2532'
  --and hcas.ATTRIBUTE20        = '232232'      15897982953
  --
  --and i.operation_id = 165
; 
/
--
SELECT * FROM XXFR_RI_VW_INF_DA_INVOICE;


select invoice_id, dbms_lob.substr( comments, 200, 1 ) as "COMMENT"
from cll_f189_invoices
where dbms_lob.substr( comments, 4, 1 ) = '[NFE';

select * from cll_f189_invoice_lines;

/*

TRX_NUMBER:33;CUSTOMER_TRX_ID:23018;PO_NUMBER:508

select * from ra_customer_trx_all where CUSTOMER_TRX_ID = 10988;

select * from XXFR_RI_VW_INF_DA_NFENTRADA
where 1=1
  --and CUSTOMER_TRX_ID = 10988
  --and CUST_ACCOUNT_ID = 1041
  and trx_number = '596'
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
