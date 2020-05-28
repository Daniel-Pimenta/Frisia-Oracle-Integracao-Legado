set serveroutput on
declare 
  p_customer_trx_id number;
  x_retorno         varchar2(3000);
begin 
  xxfr_pck_variaveis_ambiente.inicializar('AR','UO_FRISIA','DANIEL.PIMENTA');
  update JL_BR_CUSTOMER_TRX_EXTS
  set 
    ELECTRONIC_INV_STATUS        = '2', 
    ELECTRONIC_INV_ACCESS_KEY_ID = '001'||to_char(sysdate,'YYYYMMDDHH24MISS')
  where CUSTOMER_TRX_ID = 35012
  ;
  commit;
exception
  when others then 
    dbms_output.put_line(sqlerrm);
end ;
/

/*

select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
  and upper(ds_escopo) like 'XXFR_RI_TRG_NFENTRADA_%' 
  and DT_CRIACAO >= sysdate -1
order by 
  --DT_CRIACAO desc,
  id
;



select * from JL_BR_CUSTOMER_TRX_EXTS where CUSTOMER_TRX_ID = 39011;

select * from fnd_lookup_values where lookup_type = 'CLL_F031_ELECT_TRX_STATUS' and language = 'PTB' ORDER BY LOOKUP_CODE;

SELECT CUSTOMER_TRX_ID, ELECTRONIC_INV_STATUS, ELECTRONIC_INV_ACCESS_KEY_ID FROM JL_BR_CUSTOMER_TRX_EXTS;

select 
  RCT.CUSTOMER_TRX_ID, 
  RCT.TRX_NUMBER, 
  RCT.CUST_TRX_TYPE_ID, 
  RCT.ATTRIBUTE_CATEGORY, 
  RCT.ATTRIBUTE15,
  RCTT.NAME, 
  RCTT.GLOBAL_ATTRIBUTE2 TIPO_OPERACAO, 
  RCTT.GLOBAL_ATTRIBUTE3 COD_FISCAL_OPERACAO
from 
  ra_customer_trx_all RCT,
  RA_CUST_TRX_TYPES   RCTT
where 1=1
  AND RCT.CUST_TRX_TYPE_ID = RCTT.CUST_TRX_TYPE_ID
  AND RCTT.GLOBAL_ATTRIBUTE2 = 'ENTRY'
;

select CUST_TRX_TYPE_ID, NAME, GLOBAL_ATTRIBUTE2 TIPO_OPERACAO, GLOBAL_ATTRIBUTE3 COD_FISCAL_OPERACAO 
from RA_CUST_TRX_TYPES 
where 1=1
  and name = 'INS_COMPRA'
  --and CUST_TRX_TYPE_ID = 5550
;

*/
