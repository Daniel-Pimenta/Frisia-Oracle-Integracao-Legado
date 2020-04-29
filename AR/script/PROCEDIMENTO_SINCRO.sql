set serveroutput on
declare
begin
  XXFR_AR_PCK_INT_SINCRO_NF.main(p_customer_trx_id => 151029);
end ;
/

--select instance_name, to_char(sysdate,'dd-mm-yyyy hh24:mi:ss') as "SYSDATE", a.* from v$instance a;

interface_line_attribute 6

select * from xxfr_integracao_detalhe
WHERE 1=1
  --and ID_INTEGRACAO_CABECALHO = 1278
  and id_integracao_detalhe = 11354
  --and CD_INTERFACE_DETALHE = 'SINCRONIZAR_NOTA_FISCAL'
order by DT_ATUALIZACAO desc
;
69857.11075