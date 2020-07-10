--DROP VIEW XXFR_RI_VW_INF_DA_INVOICE;
CREATE OR REPLACE VIEW XXFR_RI_VW_INF_DA_INVOICE as
select distinct 
  i.operation_id, i.invoice_id, i.invoice_num,  i.series, i.entity_id, i.organization_id, 
  (select ood.organization_code from org_organization_definitions ood where ood.organization_id=i.organization_id) organization_code,
  v.vendor_name,
  i.location_id, i.invoice_amount, i.invoice_date, i.invoice_type_id,
  i.terms_id, i.terms_date, i.fiscal_document_model, i.source_state_id, i.destination_state_id, i.eletronic_invoice_key,
  it.invoice_type_code, it.requisition_type, it.invoice_type_lookup_code, it.description, it.ar_transaction_type_id, it.ar_source_id,
  f.business_vendor_id, f.document_type, f.document_number,
  i.ar_interface_flag, dbms_lob.substr( i.comments, 200, 1 ) comments,
  c.customer_number,
  v.vendor_id, v.vendor_site_id, v.vendor_site_code, v.ir_vendor,
  /*
  q.plan_name, 
  q.EC_ID_TP_NF_AR, q.EC_TP_NF_AR, 
  q.ec_id_tp_nf_dev_ri, q.ec_tp_nf_dev_ri,
  q.ec_cfop_entrada, q.ec_cfop_saida, 
  q.ec_organizacao organization_code,  
  q.ec_tp_doc_fiscal_ri, q.ec_tp_nf_ri, 
  q.ec_id_tp_nf_ri, q.ec_utilizacao_fiscal, q.ec_tp_icms, q.ec_indicador_trib_icms, q.ec_cst_icms, q.ec_cst_ipi, 
  q.ec_indicador_trib_ipi, q.ec_cst_pis, q.ec_cst_cofins, 
  */
  hca.customer_type, hca.account_name,
  --
  hca.cust_account_id, hca.party_id, hca.account_number, 
  --
  hcas.cust_acct_site_id, hcas.party_site_id, 
  --
  hcas.attribute19, hcas.attribute20, 
  --
  hcas.global_attribute2, hcas.global_attribute3, hcas.global_attribute4, hcas.global_attribute5, hcas.global_attribute6, hcas.global_attribute8,
  --
  hcsu.site_use_id, hcsu.site_use_code, hcsu.primary_flag, hcsu.location, hcsu.bill_to_site_use_id, 
  --
  hcsu.orig_system_reference,
  --
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
  hz_cust_site_uses_all         hcsu
  --
  --q_pc_transferencia_ar_ri_v    q
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
    (f.document_type = 'CPF'  and f.document_number = to_number(hcas.global_attribute3||hcas.global_attribute5))
  )
  and v.ENABLED_FLAG = 'Y'
  and c.status = 'A'
  and v.vendor_name = c.customer_name
  --and i.invoice_id = 32939
  --and i.invoice_type_id       = q.ec_id_tp_nf_ri (+)
  --and i.organization_id       = q.ec_id_organizacao (+)
  --
; 
/


select * from cll_f189_query_vendors_v WHERE entity_id = 22868;  --13190609000546
select * from cll_f189_query_customers_v WHERE DOCUMENT_NUMBER = '13190609000546';

select * from cll_f189_query_customers_v;

SELECT * FROM XXFR_RI_VW_INF_DA_INVOICE 
where 1=1
  --and INVOICE_id = 53934
  --and ELETRONIC_INVOICE_KEY = '1582247'
  --and ACCOUNT_NUMBER = '53369435'
  --and comments is null
  and INVOICE_TYPE_CODE = 'CMP014'
  --and ORGANIZATION_CODE = '011'
  --and OPERATION_ID = 316
  --and DESCRIPTION = 'REMESSA P/ INDUSTRIALIZACAO POR ENCOMENDA'
order by 1 desc
;

select * 
from cll_f189_invoice_lines
where 1=1
  and invoice_id  = 32939
  and item_number = 3
order by invoice_id desc
;

select * from q_pc_transferencia_ar_ri_v;