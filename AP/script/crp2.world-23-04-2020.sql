select count(*) from ap_checks_all;

select * from ap_checks_all 
where 1=1
  --and customer_trx_id = 204054
  --and payment_instruction_id = 12465
  and payment_id = 121008
order by creation_date desc
;

select * from ap_invoice_payments_all;

--PAYMENT_AMOUNT, PAYMENT_CURRENCY_CODE
select * from iby_payments_all 
where 1=1
  --and payment_id = 121008
  and payment_instruction_id = 12485
;

PAYMENT_PROCESS_REQUEST_NAME

--12465	121008	134003

select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
  and upper(ds_escopo) = 'XXFR_IBY_EXTRACT_EXT_PUB'
  and DT_CRIACAO >= sysdate -1
order by 
  id
;