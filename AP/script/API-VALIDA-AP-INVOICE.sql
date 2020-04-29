set SERVEROUTPUT ON;
declare

  l_retorno   varchar2(3000);

  procedure valida_invoice(
    p_invoice_id in number,
    pov_err_message out varchar2
  )is
  
    cursor c1 is
      select *
      from ap_invoices_all aia
      where 1=1
        and ap_invoices_pkg.get_approval_status(aia.invoice_id,aia.invoice_amount,aia.payment_status_flag,aia.invoice_type_lookup_code) not in ('APPROVED','UNPAID')
        and invoice_id = p_invoice_id 
    ;
  
    ln_processed_cnt      number default 0;
    ln_failed_cnt         number default 0;
    ln_holds_cnt          number;
    lv_approval_status    varchar2(100);
    lv_funds_return_code  varchar2(100);
    ok                    boolean;
  
  begin
    for r1 in c1 loop
      begin
        lv_approval_status   := null;
        lv_funds_return_code := null;
        ln_holds_cnt         := null;
        ap_pay_invoice_pkg.ap_pay_invoice
        ok := ap_approval_pkg.batch_approval(
          p_run_option          => null,
          p_sob_id              => fnd_profile.value('GL_SET_OF_BKS_ID'),
          p_inv_start_date      => null,
          p_inv_end_date        => null,
          p_inv_batch_id        => null,
          p_vendor_id           => null,
          p_pay_group           => null,
          p_invoice_id          => r1.invoice_id,
          p_entered_by          => null,
          p_debug_switch        => 'N',
          p_conc_request_id     => fnd_profile.value('CONC_REQUEST_ID'),
          p_commit_size         => null,
          p_org_id              => r1.org_id,
          p_report_holds_count  => ln_holds_cnt,
          p_transaction_num     => null
        );      
        if (ok) then
          dbms_output.put_line(r1.invoice_num ||' Invoice Validated ');
          BEGIN
            AP_ACCOUNTING_EVENTS_PKG.Create_Events (
              'PAYMENT'             --(p_event_type)
              ,'M'                  -- manual payments
              ,3                    --(p_doc_id)
              ,trunc(sysdate)       --(p_accounting_date)
              ,l_accounting_event_id--(p_accounting_event_id OUT)
              ,null                 --(p_checkrun_name)
              ,null                 --(p_calling_sequence)
            );
          EXCEPTION WHEN OTHERS THEN
            dbms_output.put_line('The error is -'||SQLERRM);
          END;
        else
          dbms_output.put_line(r1.invoice_num ||' Invoice Validation Failed ');
        end if;
        ln_processed_cnt := ln_processed_cnt+1;
      exception when others then
        dbms_output.put_line(r1.invoice_num||' Invoice Validation failed with unhandled exception.Error:'||sqlerrm);
        ln_failed_cnt := ln_failed_cnt + 1;
      end;
    end loop;
    pov_err_message := 'PROCESSED: '||ln_processed_cnt||' FAILED: '||ln_failed_cnt;
  end;

begin
  valida_invoice(
    p_invoice_id    => 197054,
    pov_err_message => l_retorno
  );
  dbms_output.put_line(l_retorno);
end;
/