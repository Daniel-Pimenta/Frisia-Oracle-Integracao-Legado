create or replace view xxfr_opm_vw_dev_simb_insumos_h as
select distinct
  m.organization_id,         
  m.inventory_item_id,       
  m.segment1,                
  m.description,             
  decode(fmd.line_type,-1,
    'INGREDIENTE',
    'PRODUTO'
  )                         tipo, 
  xxfr_fn_inv_quantity_tree(m.inventory_item_id, m.organization_id) qt_estoque_disponivel,
  m.primary_unit_of_measure                                         un_medida_primaria, 
  ffm.formula_id                                                    id_formula,
  ffm.attribute3                                                    tipo_nf_ri, 
  ffm.attribute4                                                    id_cliente, 
  ffm.attribute5                                                    tp_os_industrializacao,
  ffm.attribute6                                                    lista_precos_om, 
  ffm.attribute7                                                    condicao_pagamento, 
  --
  th.HEADER_ID, 
  th.REFERENCE_DATE, 
  th.QUANTITY, 
  th.UOM_CODE, 
  th.STATUS, 
  th.LAST_UPDATE_DATE, 
  th.LAST_UPDATE_BY, 
  th.CREATION_DATE, 
  th.CREATED_BY
from 
  xxfr_dev_simb_insumos_header  th,
  mtl_system_items_b            m,
  (select (a.organization_id||'.'||a.formula_id||'.'||a.inventory_item_id) segment, a.* from fm_matl_dtl a)  fmd,
  fm_form_mst                   ffm
where 1=1
  and fmd.segment         = th.segment (+)
  --and m.inventory_item_id = th.inventory_item_id (+)
  --and m.organization_id   = th.organization_id (+)
  and m.inventory_item_id = fmd.inventory_item_id
  and m.organization_id   = fmd.organization_id
  and ffm.formula_id      = fmd.formula_id
  and fmd.line_type       = 1
  --
  --and ffm.attribute3 is not null --tipo_nf_ri, 
  and ffm.attribute4 is not null --id_cliente, 
  --and ffm.attribute5             --tp_os_industrializacao,
  --and ffm.attribute6 is not null --lista_precos_om, 
  --and ffm.attribute7 is not null --condicao_pagamento,
  --
ORDER by m.description
;

create or replace view xxfr_opm_vw_dev_simb_insumos_l as
select distinct
  fmd.formula_id,
  decode(fmd.line_type,-1,'INGREDIENTE','PRODUTO') line_type, 
  msi.segment1,
  msi.inventory_item_id,
  msi.description,
  --
  xxfr_fn_inv_quantity_tree(msi.inventory_item_id, msi.organization_id) qt_estoque_disponivel,
  --
  fmd2.inventory_item_id id_item_produto,
  fmd2.qty               qt_formula_produto,
  fmd2.detail_uom        un_produto,
  --
  fmd.qty                qt_formula_ingrediente, 
  fmd.detail_uom         un_ingrediente,
  /*
  case when tl.quantity = 0
      then ''||( nvl(th.quantity,0) * (fmd.qty / fmd2.qty) ) 
      else '(AJ) '|| tl.quantity
  end                    qt_ingrediente_calculado,
  */
  ( nvl(th.quantity,0) * (fmd.qty / fmd2.qty) )  qt_ingrediente_calculado,
  tl.HEADER_ID, 
  LINE_ID,  
  tl.QUANTITY, 
  tl.UOM_CODE, 
  tl.LAST_UPDATE_DATE, 
  tl.LAST_UPDATE_BY, 
  tl.CREATION_DATE, 
  tl.CREATED_BY
from 
  fm_matl_dtl                  fmd, 
  fm_matl_dtl                  fmd2,
  mtl_system_items_b           msi,
  xxfr_dev_simb_insumos_header th,
  xxfr_dev_simb_insumos_lines  tl
where 1=1
  and tl.header_id           = th.header_id
  and msi.inventory_item_id  = tl.inventory_item_id
  and fmd.organization_id    = msi.organization_id
  and fmd.inventory_item_id  = msi.inventory_item_id
  and fmd.line_type          = -1
  and fmd.formula_id         = th.formula_id
  --
  and fmd2.formula_id        = fmd.formula_id 
  and fmd2.organization_id   = fmd.organization_id
  and fmd2.line_type         = 1
  --
  and fmd2.inventory_item_id = th.inventory_item_id
order by msi.description
;

create or replace view xxfr_opm_vw_dev_simb_insumos_r as
select distinct 
  h.header_id,
  h.tipo_nf_ri   invoice_type_code, 
  c.cust_acct_site_id, 
  c.customer_number, 
  c.customer_name, 
  h.quantity, 
  h.uom_code, 
  h.description,
  l.line_id,
  l.inventory_item_id,
  l.quantity     quantity2, 
  l.uom_code     uom_code2, 
  l.description  description2
from
  xxfr_opm_vw_dev_simb_insumos_h h,
  xxfr_opm_vw_dev_simb_insumos_l  l,
  cll_f189_query_customers_v     c
where 1=1
  and h.header_id         = l.header_id
  and c.cust_acct_site_id = h.id_cliente
;
/

select * from 
cll_f189_query_vendors_v

--  ********************************************************************************************************************
/*

SET SERVEROUTPUT ON
declare
begin
  xxfr_pck_variaveis_ambiente.inicializar('GMD','UO_FRISIA'); 
end;
/

SET SERVEROUTPUT ON
BEGIN
  FND_GLOBAL.APPS_INITIALIZE ( 
    user_id      => 1131,
    resp_id      => 51165,
    resp_appl_id => 552 
  );
END;
/

SELECT NAME 
FROM hr_all_organization_units
where Organization_Id = 105;


select * from xxfr_opm_vw_dev_simb_insumos_h
where 1=1
  and header_id = 1
;

select * from xxfr_opm_vw_dev_simb_insumos_l
where 1=1
  and header_id = 1
;

select * from xxfr_opm_vw_dev_simb_insumos_r
where 1=1
  and header_id = 1
;

select 
  distinct h.tipo_nf_ri, h.id_cliente, c.customer_number, c.customer_name, h.quantity, h.uom_code, h.description,
  l.quantity, l.uom_code, l.description
from
  xxfr_dev_simb_insumos_header_v h,
  xxfr_dev_simb_insumos_lines_v  l,
  cll_f189_query_customers_v     c
where 1=1
  and h.header_id         = l.header_id
  and c.cust_acct_site_id = h.id_cliente
  and h.header_id         = 1
;
*/