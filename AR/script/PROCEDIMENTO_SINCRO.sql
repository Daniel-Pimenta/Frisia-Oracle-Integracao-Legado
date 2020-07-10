set serveroutput on
declare
begin
  --XXFR_AR_PCK_INT_SINCRO_NF.main(p_customer_trx_id => 128226);
  XXFR_AR_PCK_INT_SINCRO_NF.main(p_customer_trx_id => 128263);
end ;
/


/*

select * from xxfr_integracao_detalhe i where i.id_transacao = 18302229 order by i.dt_atualizacao desc;
SELECT * FROM XXFR_INTEGRACAO_DETALHE I where i.id_integracao_detalhe = 70880;
select * from  XXFR_INTEGRACAO_DETALHE i where i.id_integracao_detalhe = 69628;
*/

select id, DT_CRIACAO, ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log --xxfr_logger_logs_60_min
where 1=1
  and upper(ds_escopo) = 'SINCRONIZAR_NOTA_FISCAL_128263'
  --and DT_CRIACAO >= sysdate -0.125
order by 
  --DT_CRIACAO,
  id
;

