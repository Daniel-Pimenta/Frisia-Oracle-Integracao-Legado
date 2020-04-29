--create or replace view xxfr_ap_vw_pag_eletronico_usd as
select 
  aia.org_id, 
  ipa.payment_instruction_id, 
  aca.payment_id,
  aip.check_id,
  aia.invoice_id, 
  aia.invoice_num,
  aia.amount_paid,
  ipa.creation_date dt_geracao,
  aip.reversal_flag,
  aia.payment_currency_code, 
  aia.payment_method_code,
  aca.payment_method_code payment_method_code2, 
  aia.invoice_amount, 
  --
  aia.exchange_rate       invoice_exchange_rate,
  aia.exchange_rate_type  invoice_exchange_rate_type, 
  --
  aip.exchange_rate       payment_exchange_rate,
  aip.exchange_rate_type  payment_exchange_rate_type, 
  --
  aip.payment_base_amount, 
  aca.bank_account_name, 
  aca.check_number, 
  aca.checkrun_name, 
  ipa.payment_status, 
  ipa.payment_profile_sys_name, 
  (
    select v.request_id
    from apps.fnd_conc_req_summary_v v
    where 1=1
      and v.program_short_name = 'IBY_FD_PAYMENT_FORMAT_TEXT'
      and substr(v.argument_text, 1, length(ipa.payment_instruction_id)) = ipa.payment_instruction_id
      and rownum = 1
  ) request_id,
  (
    select v.status_code
    from apps.fnd_conc_req_summary_v v
    where 1=1
      and v.program_short_name = 'IBY_FD_PAYMENT_FORMAT_TEXT'
      and substr(v.argument_text, 1, length(ipa.payment_instruction_id)) = ipa.payment_instruction_id
      and rownum = 1
  ) request_status,
  itd.trxn_document_id, 
  itd.document
from
  apps.ap_invoices_all         aia,
  apps.ap_invoice_payments_all aip,
  apps.ap_checks_all           aca,
  apps.iby_payments_all        ipa,
  apps.iby_trxn_documents      itd
where 1=1
  and aia.org_id                 = aip.org_id
  and aia.invoice_id             = aip.invoice_id 
  --and aip.reversal_flag          = 'N'
  and aip.check_id               = aca.check_id
  and aca.payment_id             = ipa.payment_id (+)
  and ipa.payment_instruction_id = itd.payment_instruction_id (+)
  --and ipa.payment_instruction_id IN (12028)
  --and aia.INVOICE_NUM = '815'
  --AND BANK_ACCOUNT_NAME    = '3051-1 - BB CORPORATE'
order by ipa.payment_instruction_id desc, aca.payment_id 
;
/

select * from xxfr_ap_vw_pag_eletronico_usd 
where 1=1
  --and payment_instruction_id = 12450
  --AND PAYMENT_METHOD_CODE  = 'ELETRONICO'
  --AND PAYMENT_METHOD_CODE2 = 'ELETRONICO'
  AND BANK_ACCOUNT_NAME    = '3051-1 - BB CORPORATE'
order by payment_instruction_id desc, payment_id 
;

select 
  payment_currency_code,
  payment_exchange_rate, 
  nvl(payment_exchange_rate_type,1),
  sum(amount_paid) amount_paid,
  sum(amount_paid * nvl(payment_exchange_rate,1)) brl_amount_paid
from xxfr_ap_vw_pag_eletronico_usd 
where 1=1
  and payment_id = 119008
  --and payment_instruction_id = 12425
group by 
  payment_currency_code,
  payment_exchange_rate, 
  nvl(payment_exchange_rate_type,1)
;

/*
          cll_f033_iby_extract_ext_pub.get_pmt_ext_agg(p_payment_id),
          xscn_9031_iby_extract_ext_pub.get_pmt_ext_agg(p_payment_id),

select * from dba_objects where OBJECT_NAME LIKE UPPER('xscn_9031_iby_%')
AND OBJECT_TYPE = 'PACKAGE';

IBY_DISBURSE_SUBMIT_PUB_PKG.submit_payment_process_request(
  200, 112, 12000, 182, N, null, null, PAYEE, PAYMENT, N, Y, 3, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]
);



SELECT * FROM IBY_FORMATS_B 
WHERE 1=1
AND FORMAT_TEMPLATE_CODE = 'CLL_F033_BCBF_en_US'
--AND FORMAT_NAME = 'Brazilian Format for Banco do Brasil Bank'
--AND LANGUAGE = 'PTB'
;

SELECT pd.payment_document_id
    , pd.payment_document_name
    , ba.bank_account_name
    , app.payment_profile_id
    , app.payment_profile_name
 FROM ce_payment_documents     pd
    , iby_sys_pmt_profiles_b   spp
    , iby_acct_pmt_profiles_vl app
    , iby_formats_b            fmt
    , ce_bank_accounts         ba
WHERE pd.format_code              = spp.payment_format_code
  AND spp.system_profile_code     = app.system_profile_code
  AND fmt.format_code             = spp.payment_format_code
  AND fmt.format_type_code        = 'OUTBOUND_PAYMENT_INSTRUCTION'
  and pd.payment_document_name    = 'ELETRONICO'
  AND pd.internal_bank_account_id = ba.bank_account_id
ORDER BY 1,4;

*/

