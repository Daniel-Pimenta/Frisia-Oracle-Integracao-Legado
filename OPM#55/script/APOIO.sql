SET SERVEROUTPUT ON
declare
  p_retorno                 varchar2(3000);
begin
  --FND_GLOBAL.APPS_INITIALIZE ( 2197,	50778,	13015 );
  --xxfr_pck_variaveis_ambiente.inicializar('CLL','UO_FRISIA'); 
  XXFR_INV_PCK_DEV_SIMB_INSUMOS.processar(3, p_retorno);
end;
/


select * from oe_order_headers_all where header_id = 210828;

select id_integracao_cabecalho,
  id_integracao_detalhe,
  cd_interface_detalhe,
  ie_status_processamento,
  cd_unidade_operacional,
  --
  nr_ordem_venda,
  cd_operacao,
  cd_cliente,
  cd_local_faturamento_cliente,
  cd_local_entrega_cliente,
  nr_propriedade_faturamento,
  nr_propriedade_entrega,
  dt_ordem_venda,
  tp_referencia_origem,
  cd_referencia_origem,
  cd_tipo_ordem,
  cd_lista_preco,
  cd_organizacao_inventario,
  ie_registrar_ordem_venda,
  cd_tipo_frete,
  cd_moeda,
  dt_requisicao,
  cd_vendedor,
  nr_ordem_compra_cliente,
  cd_condicao_pagto,
  cd_tipo_pagto,
  tp_conversao_moeda,
  dt_conversao_moeda,
  --
  xxfr_om_pck_obter_ordem_venda.id_tipo_ordem(p_cd_tipo_ordem => cd_tipo_ordem) id_tipo_ordem,
  ds_observacao,
  ds_instrucao_entrega
from xxfr_om_vw_int_proc_ov_hdr h
where CD_INTERFACE_DETALHE = 'PROCESSAR_ORDEM_VENDA'
;

/*
select * from  xxfr_ri_vw_inf_da_invoice where invoice_id = 52928;

          select status
          from cll_f189_entry_operations 
          where 1=1
            and operation_id    = 22
            and organization_id = 105 
          ;


select * from xxfr_integracao_detalhe
order by DT_CRIACAO desc

select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
  and upper(ds_escopo) like 'XXFR_DEV_SIMB_INSUMOS%'
  and DT_CRIACAO >= sysdate -1
order by 
  --DT_CRIACAO desc
  id
;


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
  AND R.RESPONSIBILITY_NAME LIKE '%Desenvolvedor de Produto%'
;
select fnd_profile.value('RESP_ID') from dual;


2197	51165	552

SET SERVEROUTPUT ON
BEGIN
  FND_GLOBAL.APPS_INITIALIZE ( 
    user_id      => 1131,
    resp_id      => 51165,
    resp_appl_id => 552 
  );
END;
/
select * from xxfr_opm_vw_dev_simb_insumos_r;

select
invoice_id, invoice_line_id, invoice_number, invoice_series, item_number, invoice_date, inventory_item_id, uom_code, received_quantity, remaining_balance
from cll_f513_tpa_receipts_control
where 1=1
  and remaining_balance > 0
;
