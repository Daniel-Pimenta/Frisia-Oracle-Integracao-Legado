set SERVEROUTPUT ON;
declare 

  x_return_status VARCHAR2(10);
  x_msg_count     NUMBER;
  x_msg_data      VARCHAR2(3000);
  
  l_rec_retorno   xxfr_pck_interface_integracao.rec_retorno_integracao;
  
  l_retorno       clob;
  l_msg_retorno   varchar2(3000);
  op              number := 1;    
  p_id_integracao number := 11260;

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

  dbms_output.put_line(l_retorno);
end;
/

--select LOT_CONTROL_CODE,  from mtl_system_items_b where INVENTORY_ITEM_ID = '46002';

/*

begin
  xxfr_pck_variaveis_ambiente.inicializar(
    'GME',
    'UO_FRISIA', 
    'DANIEL.PIMENTA'
  ); 
end;


select * from XXFR_integracao_Detalhe i where i.id_transacao = 373536;


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
  --and x.dt_criacao >= sysdate -1
  AND UPPER(DS_ESCOPO) = 'PROCESSAR_SEPARACAO_SEMENTES_11260'
order by id;


select * from XXFR_WMS_ORDEM_SEPARACAO_HDR;
select * from XXFR_WMS_ORDEM_SEPARACAO_LIN;
XXFR_WMS_PCK_ORDEM_SEPARACAO



*/


