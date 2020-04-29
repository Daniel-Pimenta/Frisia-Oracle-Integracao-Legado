CREATE OR REPLACE PROCEDURE XXFR_AP_CUST_INVOICE_PAYMENTS (
  p_invoice_id   IN    NUMBER,
  p_from_date    IN    DATE,
  p_to_date      IN    DATE,
  x_status       OUT   VARCHAR2,
  x_err_msg      OUT   VARCHAR2
) IS

  v_check_rowid             VARCHAR2(100) := NULL;
  v_internal_bank_acct_id   NUMBER;
  v_bank_account_id         NUMBER;
  v_bank_account_num        VARCHAR2(250);
  v_bank_account_name       VARCHAR2(250);
  v_check_number            NUMBER;
  v_event_id                NUMBER;
  v_check_id                NUMBER;
  v_doc_category_code       VARCHAR2(50);
  v_user_id                 NUMBER := fnd_profile.value('USER_ID');
  v_apcc_id                 NUMBER;
  v_account_nature          VARCHAR2(150);
  v_msg_out                 VARCHAR2(4000);
  v_invoice_payment_id      NUMBER;
  v_payment_document_id     NUMBER;
  v_doc_seq_val             NUMBER;
  v_doc_seq_id              NUMBER;
  v_db_seq_name             VARCHAR2(75);
  v_payment_profile_id      NUMBER := 739; -- Standard Cheque
  v_stmt                    VARCHAR2(250);
  v_ref_cur                 SYS_REFCURSOR;
  ok                        boolean;        
 
  -- for payment of current invoice
  CURSOR c1 IS
  SELECT
    aia.org_id,
    aia.invoice_num,
    aia.gl_date,
    aia.payment_method_lookup_code,
    aia.invoice_id,
    aia.accts_pay_code_combination_id   pay_ccid,
    aia.vendor_id,
    aia.vendor_site_id,
    aia.attribute2,
    aia.attribute3,
    aia.attribute4,
    aia.attribute5,
    aia.attribute6,
    apsa.amount_remaining               invoice_amount,
    aia.invoice_amount                  base_amt,
    aia.doc_category_code,
    pv.vendor_name,
    pv.party_id,
    pvsa.vendor_site_code,
    pvsa.address_line1,
    pvsa.address_line2,
    pvsa.address_line3,
    pvsa.city,
    pvsa.country,
    pvsa.party_site_id,
    apsa.payment_num,
    apsa.due_date,
    apsa.attribute_category             attribute_category_sch,
    apsa.attribute1                     attribute1_sch
  FROM
    ap_invoices_all            aia,
    po_vendors                 pv,
    po_vendor_sites_all        pvsa,
    ap_payment_schedules_all   apsa
  WHERE 1=1
    and aia.invoice_id        = apsa.invoice_id
    AND aia.invoice_id        = p_invoice_id
    AND aia.vendor_id         = pv.vendor_id
    AND aia.vendor_site_id    = pvsa.vendor_site_id
    AND apsa.amount_remaining <> 0
    AND apsa.hold_flag        = 'N'
    AND aia.wfapproval_status LIKE '%APPROVED%'
    --AND apsa.due_date         BETWEEN p_from_date AND p_to_date
  ORDER BY
    apsa.payment_num;

  l_accounting_event_id  number;

BEGIN
  v_user_id := fnd_profile.value('USER_ID');
  
  FOR r1 IN c1 LOOP
    begin
      SELECT
        bank_account_id,
        bank_account_num,
        bank_account_name,
        attribute1
      INTO
        v_internal_bank_acct_id,
        v_bank_account_num,
        v_bank_account_name,
        v_account_nature
      FROM
        ce_bank_accounts
      WHERE
        bank_account_id = r1.attribute2;
    exception when others then
      x_err_msg   := 'Bank Acount:'||sqlerrm;
      x_status    := 'E';
      ok := false;
      return;
    end;
        
    IF (v_account_nature <> r1.doc_category_code) THEN
      x_err_msg   := 'Invoice Document Category Does not match with Bank Account Nature';
      x_status    := 'E';
      ok := false;
      return;
    end if;
    
    if (ok) then
      begin
        SELECT
          payment_document_id,
          last_issued_document_number + 1,
          payment_doc_category
        INTO
          v_payment_document_id,
          v_check_number,
          v_doc_category_code
        FROM
          ce_payment_documents
        WHERE
          internal_bank_account_id = v_internal_bank_acct_id
          AND payment_instruction_id IS NULL
        ;
      exception when others then
        x_err_msg   := 'Payment Document:'||sqlerrm;
        x_status    := 'E';
        ok := false;
        return;
      end;
      begin
        SELECT
          doc_sequence_id,
          db_sequence_name
        INTO
          v_doc_seq_id,
          v_db_seq_name
        FROM
          fnd_document_sequences
        WHERE
          table_name = 'AP_CHECKS_ALL'
          AND name LIKE '%Payment%Voucher%Auto%'
          AND db_sequence_name IS NOT NULL
          AND end_date IS NULL;
      exception when others then
        x_err_msg   := 'Doc Sequence:'||sqlerrm;
        x_status    := 'E';
        ok := false;
        return;
      end;
      
      SELECT ap_checks_s.NEXTVAL INTO v_check_id FROM dual;

      v_stmt := 'select '|| v_db_seq_name|| '.nextval from dual';
      OPEN v_ref_cur FOR v_stmt;
      FETCH v_ref_cur INTO v_doc_seq_val;
      CLOSE v_ref_cur;
      
      mo_global.set_policy_context('S', r1.org_id);     -- Single Org context for AP_CHECKS_PKG
       
      -- Create check
      ap_checks_pkg.insert_row(
        x_rowid               => v_check_rowid, 
        x_amount              => r1.invoice_amount, 
        x_ce_bank_acct_use_id => v_internal_bank_acct_id, 
        x_bank_account_name   => v_bank_account_name, 
        x_check_date          => r1.due_date,
        x_check_id            => v_check_id, 
        x_check_number        => v_check_number, 
        x_currency_code       => 'USD', 
        x_last_updated_by     => v_user_id, 
        x_last_update_date    => sysdate,
        x_payment_method_code => 'ELETRONICO', 
        x_payment_type_flag   => 'Q', 
        x_address_line1       => r1.address_line1, 
        x_address_line2       => r1.address_line2, 
        x_address_line3       => r1.address_line3,
        x_checkrun_name       => 'Pagamento Rapido: ID=' || v_check_id, 
        x_city                => r1.city, 
        x_country             => r1.country, 
        x_created_by          => v_user_id, 
        x_creation_date       => sysdate,
        x_last_update_login   => -1, 
        x_status_lookup_code  => 'NEGOTIABLE', 
        x_vendor_name         => r1.vendor_name, 
        x_vendor_site_code    => r1.vendor_site_code, 
        x_external_bank_account_id => v_internal_bank_acct_id,
        x_bank_account_num    => v_bank_account_num, 
        x_doc_category_code   => v_doc_category_code, 
        x_payment_profile_id  => v_payment_profile_id, 
        x_payment_document_id => v_payment_document_id, 
        x_doc_sequence_id     => v_doc_seq_id,
        x_doc_sequence_value  => v_doc_seq_val, 
        x_org_id              => r1.org_id, 
        x_vendor_id           => r1.vendor_id, 
        x_vendor_site_id      => r1.vendor_site_id, 
        x_party_id            => r1.party_id,
        x_party_site_id       => r1.party_site_id, 
        x_calling_sequence    => 'PLSQL'
      );

      IF (v_check_rowid IS NOT NULL) THEN
        --ibt_utils.create_payment_event(v_check_id, v_event_id);
        SELECT ap_invoice_payments_s.NEXTVAL INTO v_invoice_payment_id FROM dual;
        -- create payment
        ap_pay_invoice_pkg.ap_pay_invoice(
          p_invoice_id          => r1.invoice_id, 
          p_check_id            => v_check_id, 
          p_payment_num         => r1.payment_num, 
          p_invoice_payment_id  => v_invoice_payment_id, 
          p_org_id              => r1.org_id,
          p_period_name         => to_char(sysdate, 'MON-YY'), 
          p_accounting_date     => r1.due_date, 
          p_accts_pay_ccid      => r1.pay_ccid, 
          p_accounting_event_id => v_event_id, 
          p_amount              => r1.invoice_amount,
          p_discount_taken      => 0, 
          p_accrual_posted_flag => 'N', 
          p_cash_posted_flag    => 'N', 
          p_posted_flag         => 'N', 
          p_set_of_books_id     => 1001,
          p_last_updated_by     => v_user_id, 
          p_currency_code       => 'USD', 
          p_replace_flag        => 'N', 
          p_ce_bank_acct_use_id => v_internal_bank_acct_id, 
          p_bank_account_num    => v_bank_account_num,
          p_payment_mode        => 'PAY', 
          p_attribute_category  => r1.attribute_category_sch, 
          p_attribute1          => r1.attribute1_sch, 
          p_calling_sequence    => 'PLSQL'
        );
        -- create payment history
        ap_reconciliation_pkg.insert_payment_history(
          x_check_id                => v_check_id, 
          x_transaction_type        => 'PAYMENT CREATED', 
          x_accounting_date         => r1.due_date, 
          x_trx_bank_amount         => NULL, x_errors_bank_amount => NULL,
          x_charges_bank_amount     => NULL, 
          x_bank_currency_code      => NULL, 
          x_bank_to_base_xrate_type => NULL, 
          x_bank_to_base_xrate_date => NULL, 
          x_bank_to_base_xrate      => NULL,
          x_trx_pmt_amount          => r1.invoice_amount, 
          x_errors_pmt_amount       => NULL, 
          x_charges_pmt_amount      => NULL, 
          x_pmt_currency_code       => 'USD', 
          x_pmt_to_base_xrate_type  => NULL,
          x_pmt_to_base_xrate_date  => NULL, 
          x_pmt_to_base_xrate       => NULL, 
          x_trx_base_amount         => NULL, 
          x_errors_base_amount      => NULL, 
          x_charges_base_amount     => NULL,
          x_matched_flag            => NULL, 
          x_rev_pmt_hist_id         => NULL, 
          x_org_id                  => r1.org_id, 
          x_creation_date           => sysdate, 
          x_created_by              => v_user_id,
          x_last_update_date        => sysdate, 
          x_last_updated_by         => v_user_id, 
          x_last_update_login       => NULL, 
          x_program_update_date     => NULL, 
          x_program_application_id  => NULL,
          x_program_id              => NULL, 
          x_request_id              => NULL, 
          x_calling_sequence        => 'PLSQL', 
          x_accounting_event_id     => v_event_id, 
          x_invoice_adjustment_event_id => NULL
        );

        BEGIN
          UPDATE ce_payment_documents
          SET
            last_available_document_number = v_check_number,
            last_issued_document_number = v_check_number,
            last_update_date = sysdate,
            last_updated_by = v_user_id
          WHERE
            internal_bank_account_id = v_internal_bank_acct_id
            AND payment_instruction_id IS NULL;
        END;
        x_err_msg := 'Payment Created for Given Invoice : '|| r1.invoice_num|| ', Check Number '|| v_check_number|| ' ,CHECK_ID '|| v_check_id;
        x_status  := 'S';

        BEGIN
          AP_ACCOUNTING_EVENTS_PKG.Create_Events ( 
            p_event_type          => 'PAYMENT',
            p_doc_type            => 'M',
            p_doc_id              => v_check_id,
            p_accounting_date     => trunc(sysdate),
            p_checkrun_name       => v_check_number,
            p_calling_sequence    => null,
            p_accounting_event_id => l_accounting_event_id
          );
          dbms_output.put_line('Retorno:'||l_accounting_event_id);
        EXCEPTION WHEN OTHERS THEN
          x_err_msg   := 'Create Event:'||sqlerrm;
          x_status    := 'E';
          ok := false;
          dbms_output.put_line(x_err_msg);
        END;
        --COMMIT;
      ELSE
        x_err_msg   := 'Check not created';
        x_status    := 'U';
        ROLLBACK;
      END IF;
    END IF;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    x_err_msg   := sqlcode|| ' - '|| sqlerrm;
    x_status    := 'E';
    ROLLBACK;
END XXFR_AP_CUST_INVOICE_PAYMENTS;
/

