SET SERVEROUTPUT ON
declare

  l_chave_eletronica      varchar2(300);
  l_linha                 number;
  l_uom                   varchar2(20);
  l_operation_id          number; 
  l_organization_code     varchar2(50);
  --
  l_id_integracao_detalhe number;
  p_retorno               clob;

begin

  select distinct --h.operation_id, 
    eletronic_invoice_key, nvl(item_number, item_id), uom, h.operation_id, h.organization_code
    into l_chave_eletronica, l_linha, l_uom, l_operation_id, l_organization_code
  from 
    xxfr_ri_vw_inf_da_invoice h,
    cll_f189_invoice_lines    l
  where 1=1
    and h.invoice_id        = l.invoice_id
    and h.operation_id      = 306
    and h.organization_code = '011'
  ;
  xxfr_ri_pck_dev_simb_insumos.initialize;
  xxfr_ri_pck_dev_simb_insumos.cria_json(
    p_chave_eletronica      => l_chave_eletronica,
    p_linha                 => l_linha,
    p_quantity              => 1,
    p_uom                   => l_uom,
    p_operation_id          => l_operation_id,
    p_organization_code     => l_organization_code,
    x_id_integracao_detalhe => l_id_integracao_detalhe
  );
  --
  xxfr_ri_pck_int_dev_work.processar_devolucao(
    l_id_integracao_detalhe, 
    p_retorno
  );  
end;
/

/*

begin
    fnd_global.apps_initialize ( 
      user_id      => 1131,
      resp_id      => 51165,
      resp_appl_id => 552 
    );
end;


      select distinct
        i.organization_id, i.organization_code, i.entity_id, i.operation_id, i.invoice_id, i.invoice_num, i.eletronic_invoice_key,
        r.description2,
        ' - '  linha,
        l.item_number, l.item_id, l.quantity, l.uom, l.unit_price, l.creation_date,
        ' - ' devolucao,
        r.line_id, r.quantity2, r.uom_code2,
        m.primary_unit_of_measure,
        'FIM'  trailer
      from 
        xxfr_ri_vw_inf_da_invoice      i,
        cll_f189_invoice_lines         l,
        xxfr_opm_vw_dev_simb_insumos_r r,
        mtl_system_items               m
      where 1=1
        and i.invoice_id        = l.invoice_id
        and i.cust_acct_site_id = r.cust_acct_site_id
        and r.inventory_item_id = l.item_id
        and r.inventory_item_id = m.inventory_item_id
        and i.organization_id   = m.organization_id
        --and i.invoice_type_code NOT LIKE 'D%'
        --and r.header_id = 4 --p_header_id
      order by 4
      ;

select * from xxfr_opm_vw_dev_simb_insumos_r;

SELECT * FROM xxfr_integracao_detalhe 
WHERE 1=1
  and ID_INTEGRACAO_DETALHE = 6019
  --and CD_INTERFACE_DETALHE like '%ENTREGA%'
order by 3 desc;

SELECT * FROM XXFR_DEV_SIMB_INSUMOS_ERRO;

select id, DS_ESCOPO, DS_LOG  
from xxfr_logger_log
where 1=1 
  and dt_criacao >= sysdate -0.25
  and upper(DS_ESCOPO) like 'XXFR%INSUMOS%'
order by id
;

select id, DS_ESCOPO, DS_LOG  
from xxfr_logger_log
where 1=1 
  and dt_criacao >= sysdate -0.5
  and upper(DS_ESCOPO) = 'DEVOLUCAO_NF_FORNECEDOR_-376'
order by id;

*/


