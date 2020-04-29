create or replace view xxfr_ap_vw_pag_eletronico_usd as
select 
  aia.org_id, 
  aia.invoice_id, 
  aia.invoice_num,
  aca.payment_id, 
  ipa.payment_instruction_id, 
  ipa.CREATION_DATE dt_geracao,
  aia.payment_currency_code, 
  aia.payment_method_code,
  aca.payment_method_code payment_method_code2, 
  aia.invoice_amount, 
  aip.exchange_rate, 
  aip.exchange_rate_type, 
  aip.payment_base_amount, 
  aca.bank_account_name, 
  aca.check_number, 
  aca.checkrun_name, 
  ipa.payment_status, 
  ipa.payment_profile_sys_name, 
  (
    select v.request_id
    from fnd_conc_req_summary_v v
    where 1=1
      and v.program_short_name = 'IBY_FD_PAYMENT_FORMAT_TEXT'
      and substr(v.argument_text, 1, length(ipa.payment_instruction_id)) = ipa.payment_instruction_id
  ) request_id,
  (
    select v.status_code
    from fnd_conc_req_summary_v v
    where 1=1
      and v.program_short_name = 'IBY_FD_PAYMENT_FORMAT_TEXT'
      and substr(v.argument_text, 1, length(ipa.payment_instruction_id)) = ipa.payment_instruction_id
  ) request_status,
  itd.trxn_document_id, 
  itd.document
from
  ap_invoices_all         aia,
  ap_invoice_payments_all aip,
  ap_checks_all           aca,
  iby_payments_all        ipa,
  iby_trxn_documents      itd
where 1=1
  and aia.org_id                 = aip.org_id
  and aia.invoice_id             = aip.invoice_id 
  and aip.reversal_flag          = 'N'
  and aip.check_id               = aca.check_id
  and aca.payment_id             = ipa.payment_id
  and ipa.payment_instruction_id = itd.payment_instruction_id (+)
  --and ipa.payment_instruction_id IN (12028)
  --and aia.INVOICE_NUM = '815'
;
/

SELECT * FROM XXFR_AP_VW_PAG_ELETRONICO_USD 
WHERE 1=1
  and payment_currency_code = 'USD'
order by dt_geracao desc
;
--1973874


109009	12226
xxfr_pck_variaveis_ambiente.inicializar('CLL',g_cd_unidade_operacional,g_usuario);
select fnd_profile.value('ORG_ID') from dual;

select * from ap_invoices_all where 1=1 and invoice_num='815';
select * from ap_invoice_payments_all where invoice_id=187054 order by check_id;
SELECT CHECK_ID, CHECK_NUMBER, PAYMENT_TYPE_FLAG, CHECKRUN_NAME, PAYMENT_ID FROM AP_CHECKS_ALL WHERE check_id IN (SELECT check_id FROM AP_INVOICE_PAYMENTS_ALL WHERE invoice_id=187054);
select * from ap_payment_schedules_all where invoice_id=187054;

select * from ap_documents_payable where calling_app_id = 200 and calling_app_doc_unique_ref2=187054;

109009
  
--IBY_PAYMENTS_ALL
SELECT PAYMENT_ID, PAYMENT_INSTRUCTION_ID, PAYMENT_SERVICE_REQUEST_ID, PROCESS_TYPE, PAYMENT_STATUS, PAYMENT_REFERENCE_NUMBER, PAPER_DOCUMENT_NUMBER, COMPLETED_PMTS_GROUP_ID, PAYMENT_PROCESS_REQUEST_NAME
FROM
  IBY_PAYMENTS_ALL
WHERE PAYMENT_INSTRUCTION_ID=12226
  payment_id IN
  (
    SELECT
      idp.payment_id
    FROM
      IBY_DOCS_PAYABLE_ALL idp
    WHERE
      idp.calling_app_id =200
    AND
      (
        calling_app_doc_unique_ref1 , calling_app_doc_unique_ref2
      )
      IN
      (
        SELECT
          TO_CHAR(aps.checkrun_id) checkrun_id ,
          TO_CHAR(aps.invoice_id)
        FROM
          ap_payment_schedules_all aps
        WHERE
          aps.invoice_id=162057
        UNION
        SELECT
          TO_CHAR(NVL(ac.checkrun_id, ac.check_id)) checkrun_id ,
          TO_CHAR(aip.invoice_id)
        FROM
          ap_invoice_payments_all aip ,
          ap_checks_all ac
        WHERE
          aip.invoice_id =187054
        AND aip.check_id =ac.check_id
      )
  );
  
  
--IBY_PAY_INSTRUCTIONS_ALL

SELECT PAYMENT_INSTRUCTION_ID, PROCESS_TYPE, PAYMENT_INSTRUCTION_STATUS, PAYMENT_COUNT, PAY_ADMIN_ASSIGNED_REF_CODE, PAYMENT_DOCUMENT_ID
FROM
  IBY_PAY_INSTRUCTIONS_ALL
WHERE
  payment_instruction_id IN
  (
    SELECT
      ipa.payment_instruction_id
    FROM
      IBY_DOCS_PAYABLE_ALL idp ,
      IBY_PAYMENTS_ALL ipa
    WHERE
      idp.calling_app_id =200
    AND ipa.payment_id   =idp.payment_id
    AND
      (
        calling_app_doc_unique_ref1 , calling_app_doc_unique_ref2
      )
      IN
      (
        SELECT
          TO_CHAR(aps.checkrun_id) checkrun_id ,
          TO_CHAR(aps.invoice_id)
        FROM
          ap_payment_schedules_all aps
        WHERE
          aps.invoice_id=162057
        UNION
        SELECT
          TO_CHAR(NVL(ac.checkrun_id, ac.check_id)) checkrun_id ,
          TO_CHAR(aip.invoice_id)
        FROM
          ap_invoice_payments_all aip ,
          ap_checks_all ac
        WHERE
          aip.invoice_id =162057
        AND aip.check_id =ac.check_id
      )
  );
  