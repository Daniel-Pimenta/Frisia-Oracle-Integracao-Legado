select * from IBY_TRXN_DOCUMENTS 
where TRXNMID = 12026
order by creation_date desc
;

xxfr_pck_variaveis_ambiente.inicializar('CLL',g_cd_unidade_operacional,g_usuario);

select fnd_profile.value('ORG_ID') from dual;

select * from ap_invoices_all where 1=1 and invoice_id=162057 and invoice_num='809';
select * from ap_invoice_payments_all where invoice_id=162057 order by check_id;
SELECT PAYMENT_ID FROM AP_CHECKS_ALL WHERE check_id IN (SELECT check_id FROM AP_INVOICE_PAYMENTS_ALL WHERE invoice_id=162057);
select * from ap_payment_schedules_all where invoice_id=162057;

select * from ap_documents_payable where calling_app_id = 200 and calling_app_doc_unique_ref2=162057;

select * from iby_payments_all where PAYMENT_ID in (99008,99010,99013);

SELECT
  *
FROM
  IBY_PAYMENTS_ALL
WHERE
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
          aps.invoice_id=:P_INVOICE_ID
        UNION
        SELECT
          TO_CHAR(NVL(ac.checkrun_id, ac.check_id)) checkrun_id ,
          TO_CHAR(aip.invoice_id)
        FROM
          ap_invoice_payments_all aip ,
          ap_checks_all ac
        WHERE
          aip.invoice_id =:P_INVOICE_ID
        AND aip.check_id =ac.check_id
      )
  );
  
  
--IBY_PAYMENTS_ALL

SELECT
  *
FROM
  IBY_PAYMENTS_ALL
WHERE
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
          aip.invoice_id =162057
        AND aip.check_id =ac.check_id
      )
  );
  
  
--IBY_PAY_INSTRUCTIONS_ALL

SELECT
  *
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
  