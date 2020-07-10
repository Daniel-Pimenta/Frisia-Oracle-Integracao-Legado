set SERVEROUTPUT ON;
declare 

  x_return_status VARCHAR2(10);
  x_msg_count     NUMBER;
  x_msg_data      VARCHAR2(3000);
  
  l_rec_retorno   xxfr_pck_interface_integracao.rec_retorno_integracao;
  
  l_retorno       clob;
  l_msg_retorno   varchar2(3000);
  op              number := 1;    
  p_id_integracao number := 56601;

  isCommit        boolean := false;
  
begin

  UPDATE xxfr_integracao_detalhe 
  SET IE_STATUS_PROCESSAMENTO = 'PENDENTE' 
  WHERE ID_INTEGRACAO_DETALHE = p_id_integracao
  ; 
  commit;
  --
  if (op = 1) then
    XXFR_WMS_PCK_INT_SEPARACAO.main(
      p_id_integracao_detalhe => p_id_integracao,
      p_commit                => isCommit,
      p_retorno               => l_retorno
    ); 
  end if;
  if (op = 2) then
    XXFR_WMS_PCK_INT_SEPARACAO.cancelar_separacao(
      p_id_integracao_detalhe => p_id_integracao,
      p_commit                => isCommit,
      p_retorno               => l_retorno
    ); 
  end if;

  dbms_output.put_line(l_retorno);
end;
/

/*

      select *

      from xxfr_wms_ordem_separacao_hdr
      where NR_ORDEM_SEPARACAO = 82;



begin
  xxfr_pck_variaveis_ambiente.inicializar(
    'GME',
    'UO_FRISIA', 
    'DANIEL.PIMENTA'
  ); 
end;


select * from XXFR_integracao_Detalhe i where i.id_transacao = 454103;
select * from xxfr_integracao_detalhe x where x.id_transacao = 406908;

select * from xxfr_wms_ordem_separacao_hdr;

select * from xxfr_integracao_detalhe 
WHERE 1=1
  and id_integracao_detalhe = 11221
  and CD_INTERFACE_DETALHE = 'PROCESSAR_ORDEM_SEPARACAO_SEMENTE'
order by DT_ATUALIZACAO desc
;


select DS_ESCOPO, NVL(DS_LOG,' ') LOG
from xxfr_logger_log x
where 1=1
  and x.dt_criacao >= sysdate -0.5
  AND UPPER(DS_ESCOPO) like 'PROCESSAR_SEPARACAO_SEMENTES_%'
order by id;


select * from XXFR_WMS_ORDEM_SEPARACAO_HDR;
select * from XXFR_WMS_ORDEM_SEPARACAO_LIN;
XXFR_WMS_PCK_ORDEM_SEPARACAO

BEGIN
  xxfr_pck_variaveis_ambiente.inicializar('GMD', 'UO_FRISIA', 'GERAL_INTEGRACAO', 'FORMULADOR');
end;

  select 
    rvr.recipe_validity_rule_id,
    rvr.inventory_item_id,
    rvr.organization_id
  from 
    gmd_recipes_b grb, 
    gmd_recipe_validity_rules rvr
  where 1=1
    and grb.recipe_id = rvr.recipe_id
    and rvr.recipe_use = 0
    -- parametros:
    and grb.recipe_no         = '13462'
    and grb.recipe_version    = '1'
    and rvr.inventory_item_id = r1.inventory_item_id
    and rvr.organization_id   = r1.organization_id
  ;

113348
*/


