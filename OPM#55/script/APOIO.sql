SET SERVEROUTPUT ON
declare
begin
  --FND_GLOBAL.APPS_INITIALIZE ( 2197,	50778,	13015 );
  --xxfr_pck_variaveis_ambiente.inicializar('CLL','UO_FRISIA'); 
  xxfr_ri_pck_devolucao_insumos.main;
  --xxfr_f189_interface_pkg.ar(44,105) ;
  commit; --rollback;
end;
/

SELECT U.USER_ID, R.RESPONSIBILITY_ID, R.APPLICATION_ID, A.APPLICATION_SHORT_NAME, R.RESPONSIBILITY_NAME
FROM 
  FND_USER              U, 
  FND_RESPONSIBILITY_TL R,
  FND_APPLICATION       A
WHERE 1=1
  AND R.LANGUAGE            = 'PTB'
  and U.USER_NAME           = 'DANIEL.PIMENTA'
  AND R.APPLICATION_ID      = A.APPLICATION_ID
  and R.APPLICATION_ID      = 552
  --AND R.RESPONSIBILITY_ID   = 51165
  --AND FRESP.RESPONSIBILITY_NAME LIKE 'FRISIA%SUPER%'
;

select fnd_profile.value('RESP_ID') from dual;

SET SERVEROUTPUT ON
BEGIN
  FND_GLOBAL.APPS_INITIALIZE ( 
    user_id      => 1131,
    resp_id      => 51165,
    resp_appl_id => 552 
  );
END;
/


select *
from cll_f189_invoices 
where OPERATION_ID = 47;

select Organization_Id, Organization_Code, Organization_Name 
from org_organization_definitions
where 1=1 and organization_id = 105;

select *
from cll_f189_invoice_lines 
where invoice_id = 53934;

select distinct ri.invoice_type_id, ri.invoice_type_code, ri.organization_id, ri.ar_transaction_type_id, ri.ar_source_id, ar.name, ar.description 
from 
  cll_f189_invoice_types ri,
  ra_batch_sources_all   ar
where 1=1
  and ar.batch_source_id   = ri.ar_source_id 
  and ri.invoice_type_code = 'DRE003'
  and ri.organization_id   = 105
;

select *
from cll_f189_invoices_interface 
where 1=1
  and source in ('XXFR_DEV_AUTO_INSUMOS','XXFR_NFE_DEV_FORNECEDOR')
order by creation_date desc;

select * from cll_f189_invoice_lines_iface
order by creation_date desc;

select 
  r.interface_line_context, r.batch_source_name, r.description, r.created_by, r.line_gdf_attribute3, f.user_id, f.user_name 
from 
  ra_interface_lines_all r, 
  fnd_user f
where 1=1
  --and r.INTERFACE_LINE_CONTEXT = 'CLL F189 INTEGRATED RCV'
  and f.user_id = r.created_by 
order by r.creation_date desc;

select * from cll_f189_item_utilizations where utilization_id in (42,1036);
select * from cll_f189_invoice_lines where invoice_id in (53934,88929);

select i.classification_id, i.utilization_id, c.classification_code 
from 
  cll_f189_fiscal_items i, 
  cll_f189_fiscal_class c
where 1=1 
  and i.classification_id = c.classification_id
  and i.inventory_item_id = 38724 
  and i.organization_id   = 105
;

select * from fnd_user where user_id in (1358,1477,1231,1142);

select l.batch_source_name, e.message_text, nvl(e.invalid_value,'NA') valor_invalido, L.INTERFACE_LINE_ID, L.REQUEST_ID, L.INTERFACE_LINE_ATTRIBUTE3, L.INTERFACE_LINE_ATTRIBUTE4, L.CREATION_DATE
from 
  ra_interface_lines_all  l,
  ra_interface_errors_all e
where 1=1
  and l.interface_line_id         = e.interface_line_id
  and l.interface_line_context    ='CLL F189 INTEGRATED RCV'
  and l.batch_source_name         = w_batch_source_name
  and l.interface_line_attribute3 = w_invoice_id
;

select * from FM_FORM_MST;
select * --distinct INVENTORY_ITEM_ID, ORGANIZATION_ID 
from FM_MATL_DTL; 


-- RETORNA O ID DA FÓRMULA E DADOS DOS ATRIBUTOS DA FÓRMULA
SELECT 
  FFM.FORMULA_ID ID_FORMULA,
  MSI.ORGANIZATION_ID,
  MSI.SEGMENT1,
  MSI.INVENTORY_ITEM_ID,
  MSI.DESCRIPTION, 
  FFM.ATTRIBUTE3 TIPO_NF_RI, 
  FFM.ATTRIBUTE4 ID_CLIENTE, 
  FFM.ATTRIBUTE5 TIPO_OS_INDUSTRIALIZACAO,
  FFM.ATTRIBUTE6 LISTA_PRECOS_OM, 
  FFM.ATTRIBUTE7 CONDICOES_PAGAMENTO  
FROM 
  FM_FORM_MST FFM, 
  FM_MATL_DTL FMD, 
  MTL_SYSTEM_ITEMS_B MSI
WHERE 1=1
  and FFM.FORMULA_ID        = FMD.FORMULA_ID
  AND FMD.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
  AND FMD.ORGANIZATION_ID   = MSI.ORGANIZATION_ID  
  AND FFM.FORMULA_CLASS     = 'TERCEIRO'
  AND MSI.SEGMENT1          in ('140000','85853')
  --AND MSI.ORGANIZATION_ID   = 105
  --AND FFM.DELETE_MARK       = 0
  --AND FFM.FORMULA_STATUS    = 700 -- APROVADA PARA USO GERAL
;



-- RETORNA COMPONENTES DA FÓRMULA
SELECT
  FMD.FORMULA_ID,
  DECODE(FMD.LINE_TYPE,-1,'INGREDIENTE','PRODUTO') TIPO, 
  MSI.SEGMENT1,
  MSI.INVENTORY_ITEM_ID,
  msi.DESCRIPTION, 
  FMD.QTY QUANT_FORMULA, 
  FMD.DETAIL_UOM
FROM 
  FM_MATL_DTL        FMD, 
  MTL_SYSTEM_ITEMS_B MSI 
WHERE 1=1
  and FMD.FORMULA_ID        = 123
  --and FMD.LINE_TYPE         = -1
  --and MSI.INVENTORY_ITEM_ID = 52015
  AND FMD.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
  AND FMD.ORGANIZATION_ID = MSI.ORGANIZATION_ID
;

select
invoice_id, invoice_line_id, invoice_number, invoice_series, item_number, invoice_date, inventory_item_id, uom_code, received_quantity, remaining_balance
from cll_f513_tpa_receipts_control
where 1=1
  and remaining_balance > 0
;

select *
from ap_invoices_all
where 1=1
  --and ap_invoices_pkg.get_approval_status(aia.invoice_id,aia.invoice_amount,aia.payment_status_flag,aia.invoice_type_lookup_code) not in ('APPROVED','UNPAID')
  and INVOICE_NUM = '10797'
;

select INVOICE_TYPE_ID from cll_f189_invoices where invoice_id in (53934,52928,53958);
select * from cll_f189_invoice_lines where invoice_id in (53934,52928,53958);

select * from ra_customer_trx_all where trx_number = '7';

select invoice_id, invoice_num
from cll_f189_invoices              
where 1=1
  and invoice_num     = r1.trx_number||g_sequencial 
  and entity_id       = w_entity_id 
  and organization_id = w_organization_id 
  and location_id     = w_location_id
;

