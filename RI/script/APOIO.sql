select * from cll_f189_invoices_interface    where 1=1 and source = 'XXFR_NFE_DEVOL_COOPERADO' 
--and PROCESS_FLAG <> '6'
order by 1 desc;
select * from cll_f189_invoices_interface    where 1=1 and interface_invoice_id in ('53413');
select * from cll_f189_invoice_lines_iface   where 1=1 and interface_invoice_id in ('1154153');
select * from cll_f189_invoice_parents_int   where 1=1 and interface_invoice_id in ('115415');
select * from cll_f189_invoice_line_par_int  where 1=1 and interface_parent_id in ('9002');

select * from cll_f189_freight_inv_interface where 1=1;

select * from cll_f189_interface_errors      where 1=1 and SOURCE = 'NFe Cooperado'; --and creation_date >= sysdate-10;

select * --INVOICE_ID, INVOICE_NUM, ENTITY_ID, ORGANIZATION_ID, LOCATION_ID
from cll_f189_invoices              
where 1=1
  --and interface_invoice_id in ('61926')
  and INVOICE_ID = '44925'
;

select * from cll_f189_invoices_interface    where 1=1 and interface_invoice_id in ('50415');

SELECT * 
FROM cll_f189_invoice_lines_iface 
WHERE interface_invoice_id = 50415


Select * From CLL_F189_INVOICE_LINES_IFACE Where interface_invoice_id in (34413);

select * from cll_f189_invoices_interface where interface_invoice_id in (34413);


select OPERATION_FISCAL_TYPE, DESCRIPTION, UTILIZATION_ID, CFO_ID
from cll_f189_cfo_utilizations
where 1=1
  and INACTIVE_DATE  is null
  and CFO_ID         = '2330' 
  and UTILIZATION_ID = 42
;

select
  r.organization_id, t.invoice_type_id, t.invoice_type_code,
  max(decode(r.VALIDITY_TYPE,'CFO',r.VALIDITY_KEY_1,null))                   as cfop,
  max(decode(r.VALIDITY_TYPE,'CST COFINS',r.VALIDITY_KEY_1,null))            as cst_cofins,
  max(decode(r.VALIDITY_TYPE,'CST ICMS',r.VALIDITY_KEY_1,null))              as cst_icms,
  max(decode(r.VALIDITY_TYPE,'CST IPI',r.VALIDITY_KEY_1,null))               as cst_ipi,
  max(decode(r.VALIDITY_TYPE,'CST PIS',r.VALIDITY_KEY_1,null))               as cst_pis,
  max(decode(r.VALIDITY_TYPE,'FISCAL DOCUMENT MODEL',r.VALIDITY_KEY_1,null)) as fiscal_doc_model,
  max(decode(r.VALIDITY_TYPE,'FISCAL UTILIZATION',r.VALIDITY_KEY_1,null))    as fiscal_utilization,
  max(decode(r.VALIDITY_TYPE,'ICMS TAXABLE FLAG',r.VALIDITY_KEY_1,null))     as icms_tax_flag,
  max(decode(r.VALIDITY_TYPE,'ICMS TYPE',r.VALIDITY_KEY_1,null))             as icms_type,
  max(decode(r.VALIDITY_TYPE,'INVOICE SERIES',r.VALIDITY_KEY_1,null))        as invoice_serie,
  max(decode(r.VALIDITY_TYPE,'IPI TAXABLE FLAG',r.VALIDITY_KEY_1,null))      as ipi_tax_flag,
  --
  max(t.ir_vendor)                 as ir_vendor,
  max(t.invoice_type_lookup_code)  as invoice_type_lookup_code, 
  max(t.requisition_type)          as requisition_type,      
  max(t.description)               as description
from 
  cll_f189_validity_rules   r,
  cll_f189_invoice_types    t
where 1=1
  and r.invoice_type_id = t.invoice_type_id 
  and r.organization_id = t.organization_id
  and t.organization_id = '123'
  and t.invoice_type_code = 'DCO009'
group by r.organization_id, t.invoice_type_id, t.invoice_type_code
;

select * from CLL_F189_CFO_UTILIZATIONS;

select distinct invoice_type_code, description from cll_f189_invoice_types 
where invoice_type_code in ('DCO009')
order by 2;


select * from ra_customer_trx_all where trx_number in ('292','23162','48409','9020','9064','113002','820924','302100','8714','73934');
select * from cll_f189_invoices where INVOICE_NUM_AP = '16011339';
select * from ap_invoices_all where INVOICE_NUM = '16011339';


select ri.* --ri.eletronic_invoice_key
from 
  cll_f189_invoices    ri
  ,fnd_lookups         rlc
  --,ra_customer_trx_all rct
where 1=1
  and ri.fiscal_document_model      = rlc.lookup_code
  and rlc.lookup_type               = 'CLL_F189_FISCAL_DOCUMENT_MODEL'
  --and to_char(ri.invoice_id)        = rct.interface_header_attribute3
  and rct.interface_header_context  = 'CLL F189 INTEGRATED RCV'
  and rct.customer_trx_id           = 35001;


select 
  nvl(ooha.global_attribute11,rcta.interface_header_attribute1)
from 
  apps.ra_customer_trx_all  rcta
  ,apps.oe_order_headers_all ooha
where 1 = 1
  and rcta.interface_header_attribute1 = ooha.order_number(+)
  and rcta.customer_trx_id = 35001;

01.0037.110101001.0000.00.000.0.0.0
-- CONTAS CONTABEIS
select 
  OOD.ORGANIZATION_CODE
  ,RIT.INVOICE_TYPE_CODE
  ,RIT.DESCRIPTION
  --contas credoras:
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.CR_CODE_COMBINATION_ID) "Passivo / Transitória"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.DIFF_ICMS_CODE_COMBINATION_ID) "ICMS a Recolher"      
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IPI_LIABILITY_CCID) "IPI a Recolher"      
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.ISS_CODE_COMBINATION_ID) "ISS a Recolher"      
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IR_CODE_COMBINATION_ID) "IR a Recolher"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.INSS_EXPENSE_CCID) "INSS Despesa"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IMPORT_TAX_CCID) "Tributos Importação"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IMPORT_INSURANCE_CCID) "Seguros Importação"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IMPORT_FREIGHT_CCID) "Fretes Importação"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IMPORT_EXPENSE_CCID) "Outras Despesas Importação"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.SYMBOLIC_RETURN_CCID) "Retorno Simbólico"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.CUSTOMER_CCID) "Devol. Clientes (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_IPI_LIABILITY_CCID) "IPI a recolher (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_ICMS_LIABILITY_CCID) "ICMS a recolher (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_ICMS_ST_LIABILITY_CCID)  "ICMS ST a recolher (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.INSS_CODE_COMBINATION_ID) "INSS Substituto"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.SISCOMEX_CCID) "SISCOMEX"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IMPORT_PIS_CCID) "PIS Importação"     
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.FUNRURAL_CCID) "Contribuição Rural"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IMPORT_COFINS_CCID) "COFINS Importação"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.SEST_SENAT_CCID) "SEST/SENAT"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.CUSTOMS_EXPENSE_CCID) "Despesas Alfandegárias"            
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.ICMS_ST_ANT_CCID) "ICMS ST Ant a Recolher"
--contas devedoras
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.ICMS_CODE_COMBINATION_ID) "Recuperação ICMS"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.ICMS_ST_CCID) "ICMS Subst Tributaria"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.IPI_CODE_COMBINATION_ID) "Recuperacao IPI"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.ACCOUNT_RECEIVABLE_CCID) "Ctas a Receber (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_IPI_REDUCTION_CCID) "Redutora IPI (RMA)"            
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_ICMS_REDUCTION_CCID) "Redutora Recolher (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_ICMS_ST_REDUCTION_CCID) "Redutora ICMS ST (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.PIS_CODE_COMBINATION_ID) "Recuperação PIS"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.VARIATION_COST_DEVOLUTION_CCID) "Variação Custo Devolução"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_PIS_REDUCTION_CCID) "Redutora PIS ST (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_COFINS_REDUCTION_CCID) "Redutora COFINS ST (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.COFINS_CODE_COMBINATION_ID) "Recuperacao de COFINS"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_PIS_RED_CCID) "Redutora PIS (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.RMA_COFINS_RED_CCID) "Redutora COFINS (RMA)"
  ,(select concatenated_segments from apps.gl_code_combinations_kfv where code_combination_id = RIT.ICMS_ST_ANT_CCID_RECUP) "Recup ICMS ST Ant"
FROM   
  CLL_F189_INVOICE_TYPES              RIT
  ,apps.org_organization_definitions  OOD
where 1=1
  and RIT.ORGANIZATION_ID = OOD.ORGANIZATION_ID
  and RIT.INVOICE_TYPE_CODE in ('CMP014')
  and RIT.ORGANIZATION_ID = '123'
ORDER BY OOD.ORGANIZATION_CODE, RIT.INVOICE_TYPE_CODE
;

SELECT 
  invoice_type_id
  ,invoice_type_code
  ,requisition_type
  ,utilities_flag
  ,payment_flag
  ,inss_additional_tax_1
  ,inss_additional_tax_2
  ,inss_additional_tax_3
  ,inss_substitute_flag
  ,inss_tax
  ,parent_flag
  ,project_flag
  ,cost_adjust_flag
  ,price_adjust_flag
  ,tax_adjust_flag
  ,include_iss_flag
  ,pis_flag
  ,cofins_flag
  ,cofins_code_combination_id
  ,contab_flag
  ,inss_calculation_flag
  ,freight_flag
  ,fixed_assets_flag
  ,fiscal_flag
  ,return_customer_flag 
--select *
FROM cll_f189_invoice_types
WHERE 1=1
  and invoice_type_id   in (22771,22752)
  --AND invoice_type_code = NVL(p_invoice_type_code,invoice_type_code)
  AND organization_id   = 123
  AND NVL(inactive_date,SYSDATE) >= SYSDATE;
;




select 
  r.invoice_type_id,
  max(decode(r.validity_type,'CFO',r.validity_key_1,null))                   as cfop,
  max(decode(r.validity_type,'CST COFINS',r.validity_key_1,null))            as cst_cofins,
  max(decode(r.validity_type,'CST ICMS',r.validity_key_1,null))              as cst_icms,
  max(decode(r.validity_type,'CST IPI',r.validity_key_1,null))               as cst_ipi,
  max(decode(r.validity_type,'CST PIS',r.validity_key_1,null))               as cst_pis,
  max(decode(r.validity_type,'FISCAL DOCUMENT MODEL',r.validity_key_1,null)) as fiscal_doc_model,
  max(decode(r.validity_type,'FISCAL UTILIZATION',r.validity_key_1,null))    as fiscal_utilization,
  max(decode(r.validity_type,'ICMS TAXABLE FLAG',r.validity_key_1,null))     as icms_tax_flag,
  max(decode(r.validity_type,'ICMS TYPE',r.validity_key_1,null))             as icms_type,
  max(decode(r.validity_type,'INVOICE SERIES',r.validity_key_1,null))        as invoice_serie,
  max(decode(r.validity_type,'IPI TAXABLE FLAG',r.validity_key_1,null))      as ipi_tax_flag,
  --
  max(nvl(t.ir_vendor,w_ir_vendor)) as ir_vendor,
  max(t.invoice_type_lookup_code)  as invoice_type_lookup_code, 
  max(t.requisition_type)          as requisition_type,      
  max(t.description)               as description

from 
  cll_f189_validity_rules r,
  cll_f189_invoice_types  t
where 1=1
  and r.invoice_type_id   = t.invoice_type_id 
  and r.organization_id   = t.organization_id
  and t.organization_id   = r1.warehouse_id
  and t.invoice_type_code = p_invoice_type_code
group by r.organization_id, r.invoice_type_id
;


select * from cll_f189_validity_rules where INVOICE_TYPE_ID=22752;
select * from cll_f189_invoice_types where 1=1 and ORGANIZATION_ID=123 and INVOICE_TYPE_CODE='CMP014'