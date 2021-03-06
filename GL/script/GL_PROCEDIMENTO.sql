set SERVEROUTPUT ON;
declare                                                                                                                                                                                                                             
  x_return_status VARCHAR2(10); 
  x_msg_count     NUMBER;
  x_msg_data      VARCHAR2(3000);
  
  l_rec_retorno  xxfr_pck_interface_integracao.rec_retorno_integracao;
  
  l_retorno       clob;
  op              number := 1;    
  p_id_integracao number := 18020;
  isCommit        boolean := false;
  
begin

  UPDATE xxfr_integracao_detalhe 
  SET IE_STATUS_PROCESSAMENTO = 'PENDENTE' 
  WHERE ID_INTEGRACAO_DETALHE = p_id_integracao
  ; 
  delete from gl_interface where user_je_source_name = 'XXFR_VEI';
  --
  commit;
  --
  if (op = 1) then
    XXFR_GL_PCK_INT_LOTE_CONTABIL.processar(
      p_id_integracao_detalhe => p_id_integracao,
      p_retorno               => l_retorno
    ); 
  end if;
  dbms_output.put_line(l_retorno);
end;
/


select * from xxfr_integracao_detalhe
where CD_INTERFACE_DETALHE='PROCESSAR_CONTABILIZACAO'
;

select *
from q_pc_respo_padr_inic_varia_v
where aplicacao='SQLGL';

SELECT je_source_name, user_je_source_name
FROM gl_je_sources
WHERE user_je_source_name = populate_interface_control.user_je_source_name;

select * from GL_INTERFACE_ERRORS;

select DS_ESCOPO, NVL(DS_LOG,' ') LOG
  from xxfr_logger_log --xxfr_vw_logger_logs_60_min
WHERE 1=1
  AND UPPER(DS_ESCOPO) like 'XXFR_GL_PCK_INT_LOTE_CONTABIL_%'
order by id;


select * from gl_interface 
where 1=1
  and user_je_source_name = 'XXFR_VEI';

select status from gl_interface 
where 1=1
  AND user_je_source_name = 'XXFR_UBL'
order by DATE_CREATED desc;
