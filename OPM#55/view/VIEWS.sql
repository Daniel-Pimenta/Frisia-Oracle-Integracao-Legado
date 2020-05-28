SET SERVEROUTPUT ON
declare
begin
  xxfr_pck_variaveis_ambiente.inicializar('GMD','UO_FRISIA'); 
end;
/

create or replace view xxfr_dev_simb_insumos_header_v as
select distinct
  m.organization_id         organizacao,
  m.inventory_item_id       id_item,
  m.segment1                item,
  m.description             descricao,
  decode(fmd.line_type,-1,
    'INGREDIENTE',
    'PRODUTO'
  )                         tipo, 
  NVL(TH.REFERENCE_DATE, sysdate)                data_referencia,
  xxfr_fn_inv_quantity_tree(m.inventory_item_id, m.organization_id) estoque_disponivel,
  m.primary_unit_of_measure un_medida_primaria, 
  ffm.formula_id            id_formula,
  ffm.attribute3            tipo_nf_ri, 
  ffm.attribute4            id_cliente, 
  ffm.attribute5            tipo_os_industrializacao,
  ffm.attribute6            lista_precos_om, 
  ffm.attribute7            condicoes_pagamento, 
  th.*
from 
  xxfr_dev_simb_insumos_header  th,
  mtl_system_items_b            m,
  fm_matl_dtl                   fmd,
  fm_form_mst                   ffm
where 1=1
  and m.inventory_item_id = th.inventory_item_id (+)
  and m.organization_id   = th.organization_id (+)
  and m.inventory_item_id = fmd.inventory_item_id
  and m.organization_id   = fmd.organization_id
  and ffm.formula_id      = fmd.formula_id
  and fmd.line_type       = 1
  --and m.organization_id   = 105
  --and m.segment1          = '83950'
order by 1,3
;

create or replace view xxfr_dev_simb_insumos_lines_v as
select distinct
  fmd.formula_id,
  decode(fmd.line_type,-1,'INGREDIENTE','PRODUTO') tipo, 
  msi.segment1          item,
  msi.inventory_item_id id_item,
  msi.description       descricao,
  --
  xxfr_fn_inv_quantity_tree(msi.inventory_item_id, msi.organization_id) estoque_disponivel,
  --
  fmd2.inventory_item_id id_item_produto,
  th.quantity            qtd_produto_dev,
  fmd2.qty               qtd_produto,
  fmd2.detail_uom        uom_produto,
  --
  fmd.qty               qtd_ingrediente, 
  fmd.detail_uom        uom_ingrediente,
  case when tl.quantity = 0
      then ''||( nvl(th.quantity,0) * (fmd.qty / fmd2.qty) ) 
      else '(AJ) '|| tl.quantity
  end qtd_dev,
  tl.*
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
  --
  and fmd2.formula_id        = fmd.formula_id 
  and fmd2.organization_id   = fmd.organization_id
  and fmd2.line_type         = 1
  --
  and fmd2.inventory_item_id = th.inventory_item_id
  --and fmd.formula_id         = 122
  --and MSI.INVENTORY_ITEM_ID = 52015
;


select * from xxfr_dev_simb_insumos_header_v
where id_formula in (933,912,934,932)
;

select * from xxfr_dev_simb_insumos_lines_v 
where 1=1
  and formula_id = 124
  --and id_item_produto = 8003
order by 1;

select * --INVENTORY_ITEM_ID, ORGANIZATION_ID, DETAIL_UOM 
from fm_matl_dtl 
where 1=1
  and INVENTORY_ITEM_ID in(140000,85853)
  and formula_id = 261
  and LINE_TYPE = -1
;
