create or replace procedure XXFR_AP_CUST_INVOICE_CREATE (
  p_segment1     in    varchar2,
  p_qtd          in    number,
  x_invoice_id   out   number,
  x_retorno      out   varchar2
) is
  
  l_rowid             varchar2(50);
  l_invoice_id        number;
  l_ap_invoice_dis_id number;
  --
  l_qtd               number;
  l_valor             number;
  --
  ok                  boolean := true;
  --
  l_retorno           varchar2(3000);
  --
  l_org_id                number; 
  l_segment1              varchar2(30);
  l_po_header_id          number;
  l_po_line_id            number;
  l_po_line_location_id   number;
  l_po_distribution_id    number;
  l_vendor_id             number;
  l_vendor_site_id        number;
  l_ship_to_location_id   number;
  l_terms_id              number;
  l_set_of_books_id       number;
  l_code_combination_id   number;
  l_item_id               number;
  l_item_description      varchar2(100);
  l_unit_meas_lookup_code varchar2(100);
  l_unit_price            number;
  l_vendor_name           varchar2(100);
  l_party_id              number;
  l_party_site_id         number;
  --
  l_accts_pay_ccid        number;
  l_legal_entity_id       number;
  l_currency_code         varchar2(30);
  l_external_bank_account_id number;
  --
  l_description           varchar2(100);
  
  procedure valida_invoice(
    p_invoice_id in number,
    x_retorno out varchar2
  )is
  
    cursor c1 is
      select 
        ap_invoices_pkg.get_approval_status(
          aia.invoice_id,
          aia.invoice_amount,
          aia.payment_status_flag,
          aia.invoice_type_lookup_code
        ) status,
        aia.*
      from ap_invoices_all aia
      where 1=1
        and INVOICE_CURRENCY_CODE = l_currency_code
        and invoice_id = p_invoice_id 
        and ap_invoices_pkg.get_approval_status(
          aia.invoice_id,
          aia.invoice_amount,
          aia.payment_status_flag,
          aia.invoice_type_lookup_code
        ) not in ('APPROVED','UNPAID')
    ;
  
    ln_processed_cnt      number default 0;
    ln_failed_cnt         number default 0;
    ln_holds_cnt          number;
    lv_approval_status    varchar2(100);
    lv_funds_return_code  varchar2(100);
  
  begin
    for r1 in c1 loop
      begin
        lv_approval_status   := null;
        lv_funds_return_code := null;
        ln_holds_cnt         := null;
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
          x_retorno := 'S';
        else
          x_retorno := r1.invoice_num ||' Invoice Validation Failed ';
          dbms_output.put_line(x_retorno);
        end if;
        ln_processed_cnt := ln_processed_cnt+1;
      exception when others then
        dbms_output.put_line(r1.invoice_num||' Invoice Validation failed with unhandled exception.Error:'||sqlerrm);
        ln_failed_cnt := ln_failed_cnt + 1;
      end;
    end loop;
    dbms_output.put_line('PROCESSED: '||ln_processed_cnt||' FAILED: '||ln_failed_cnt);
  end;
 
BEGIN
  savepoint XXFR_CRIAR_NF_USD;
  dbms_output.put_line('********************************************************************');
  dbms_output.put_line('INICIO DO PROCESSAMENTO - '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS')||' - CRIA��O NFF - PO:'||p_segment1);
  dbms_output.put_line('********************************************************************');
  --
  l_description := 'TESTE PIMENTA - Pag USD';
  l_qtd := p_qtd;
  --
  select pha.org_id, pha.currency_code,
    pha.segment1, pda.po_header_id, pda.po_line_id, pda.line_location_id, pda.po_distribution_id,
    pha.vendor_id, pha.vendor_site_id, pha.ship_to_location_id, pha.terms_id,
    pda.set_of_books_id, pda.code_combination_id,
    pla.item_id, pla.item_description, pla.unit_meas_lookup_code, pla.unit_price,
    pv.vendor_name, pv.party_id,
    pvsa.party_site_id, pvsa.accts_pay_code_combination_id
  into
    l_org_id,
    l_currency_code,
    l_segment1, 
    l_po_header_id, 
    l_po_line_id, 
    l_po_line_location_id, 
    l_po_distribution_id,
    l_vendor_id, 
    l_vendor_site_id, 
    l_ship_to_location_id, 
    l_terms_id, 
    l_set_of_books_id, 
    l_code_combination_id, 
    l_item_id, 
    l_item_description, 
    l_unit_meas_lookup_code, 
    l_unit_price, 
    l_vendor_name, 
    l_party_id, 
    l_party_site_id, 
    l_accts_pay_ccid
  from 
    po_headers_all       pha,
    po_distributions_all pda,
    po_lines_all         pla,
    po_vendor_sites_all  pvsa,
    po_vendors           pv
  where 1=1
    and pha.po_header_id         = pda.po_header_id
    and pha.authorization_status = 'APPROVED'
    and pda.po_line_id           = pla.po_line_id
    and pvsa.vendor_site_id      = pha.vendor_site_id
    and pha.vendor_id            = pv.vendor_id
    and pha.segment1             = p_segment1
  ;
  
  select distinct legal_entity into l_legal_entity_id
  from org_organization_definitions
  where 1=1
    and set_of_books_id = l_set_of_books_id 
    and operating_unit = l_org_id
  ;
  
  select distinct ieba.ext_bank_account_id into l_external_bank_account_id
    /*
    distinct 
    ieba.ext_bank_account_id,
    aps.vendor_id,
    ass.vendor_site_id,
    aps.vendor_name,
    ieba.bank_account_num,
    ieba.bank_account_name,
    cbv.bank_name,
    cbv.address_line1 bank_address_1,
    cbv.country bank_country,
    cbv.city bank_city,
    cbbv.bank_branch_name,
    cbbv.address_line1 branch_address_1,
    cbbv.city branch_city,
    cbbv.country branch_country,
    cbbv.branch_number,
    cbbv.eft_swift_code bic,
    foreign_payment_use_flag
    */
  from 
    apps.ap_suppliers            aps,
    apps.iby_external_payees_all iepa,
    apps.iby_pmt_instr_uses_all  ipiua,
    apps.iby_ext_bank_accounts   ieba,
    apps.ce_banks_v              cbv,
    apps.ce_bank_branches_v      cbbv,
    apps.ap_supplier_sites_all   ass
  where 1 = 1
    and aps.vendor_id               = ass.vendor_id
    and iepa.payee_party_id         = aps.party_id
    and iepa.party_site_id          is null
    and iepa.supplier_site_id       is null
    and ipiua.ext_pmt_party_id(+)   = iepa.ext_payee_id
    and ieba.ext_bank_account_id(+) = ipiua.instrument_id
    and ieba.bank_id                = cbv.bank_party_id(+)
    and ieba.branch_id              = cbbv.branch_party_id(+)
    and aps.vendor_id               = l_vendor_id 
    and ass.vendor_site_id          = l_vendor_site_id
    and ass.org_id                  = l_org_id
  ;
  
  l_valor := l_qtd * l_unit_price;
  
  if (l_external_bank_account_id is null) then
    dbms_output.put_line('O Fornecedor ['||l_vendor_name||'] n�o tem Conta Bancaria cadastrada !');
    ok:=false;
  end if;
  
  --HEADER
  IF (OK) THEN
    --
    SELECT ap_invoices_s.nextval INTO l_invoice_id FROM dual;
    --
    ap_ai_table_handler_pkg.insert_row(
      p_rowid                       => l_rowid,
      p_invoice_id                  => l_invoice_id,
      p_last_update_date            => SYSDATE,
      p_last_updated_by             => -1,
      
      p_vendor_id                   => l_vendor_id,
      p_vendor_site_id              => l_vendor_site_id,
      p_external_bank_account_id    => l_external_bank_account_id,
      p_party_id                    => l_party_id,
      p_party_site_id               => l_party_site_id,
      --
      p_set_of_books_id             => l_set_of_books_id,
      p_accts_pay_ccid              => l_accts_pay_ccid,
      p_legal_entity_id             => l_legal_entity_id,
      --
      p_terms_id                    => l_terms_id,
      p_terms_date                  => SYSDATE,
      --
      p_invoice_num                 => l_invoice_id||'-X',
      p_invoice_amount              => l_valor,
      p_amount_paid                 => 0,
      p_discount_amount_taken       => 0,
      p_invoice_date                => SYSDATE,
      p_source                      => 'Manual Invoice Entry', --'CLL F189 INTEGRATED RCV',
      p_invoice_type_lookup_code    => 'STANDARD',
      p_description                 => l_description,
      p_batch_id                    => NULL,
      p_amt_applicable_to_discount  => l_valor,
      p_goods_received_date         => SYSDATE,
      p_invoice_received_date       => SYSDATE,
      p_voucher_num                 => NULL,
      p_approved_amount             => NULL,
      p_approval_status             => NULL,
      p_approval_description        => NULL,
      p_pay_group_lookup_code       => 'FORNECEDORES TERCEIROS',
      p_recurring_payment_id        => NULL,
      p_invoice_currency_code       => l_currency_code,
      p_payment_currency_code       => l_currency_code,
      p_exchange_rate               => 5,
      p_exchange_rate_type          => 'User',
      p_exchange_date               => SYSDATE,
      p_payment_amount_total        => NULL,
      p_payment_status_flag         => 'N',
      p_posting_status              => NULL,
      p_authorized_by               => NULL,
      p_attribute_category          => NULL,
      p_attribute1                  => NULL,
      p_attribute2                  => NULL,
      p_attribute3                  => NULL,
      p_attribute4                  => NULL,
      p_attribute5                  => NULL,
      p_creation_date               => SYSDATE,
      p_created_by                  => -1,
      p_vendor_prepay_amount        => NULL,
      p_base_amount                 => NULL,
      p_payment_cross_rate          => 1,
      p_payment_cross_rate_type     => NULL,
      p_payment_cross_rate_date     => SYSDATE,
      p_pay_curr_invoice_amount     => l_valor,
      p_last_update_login           => NULL,
      p_original_prepayment_amount  => NULL,
      p_earliest_settlement_date    => NULL,
      p_attribute11                 => NULL,
      p_attribute12                 => NULL,
      p_attribute13                 => NULL,
      p_attribute14                 => NULL,
      p_attribute6                  => NULL,
      p_attribute7                  => NULL,
      p_attribute8                  => NULL,
      p_attribute9                  => NULL,
      p_attribute10                 => NULL,
      p_attribute15                 => NULL,
      p_cancelled_date              => NULL,
      p_cancelled_by                => NULL,
      p_cancelled_amount            => NULL,
      p_temp_cancelled_amount       => NULL,
      p_exclusive_payment_flag      => NULL,
      p_po_header_id                => NULL,
      p_doc_sequence_id             => NULL,
      p_doc_sequence_value          => NULL,
      p_doc_category_code           => 'STD INV',
      p_expenditure_item_date       => NULL,
      p_expenditure_organization_id => NULL,
      p_expenditure_type            => NULL,
      p_pa_default_dist_ccid        => NULL,
      p_pa_quantity                 => NULL,
      p_project_id                  => NULL,
      p_task_id                     => NULL,
      p_awt_flag                    => NULL,
      p_awt_group_id                => NULL,
      p_pay_awt_group_id            => NULL,
      p_reference_1                 => NULL,
      p_reference_2                 => NULL,
      p_org_id                      => l_org_id,
      p_calling_sequence            => '1',
      p_gl_date                     => SYSDATE,
      p_award_id                    => NULL,
      p_approval_iteration          => NULL,
      p_approval_ready_flag         => 'Y',
      p_wfapproval_status           => 'MANUALLY APPROVED', --'NOT REQUIRED',
      p_payment_method_code         => 'ELETRONICO',
      p_taxation_country            => 'BR',
      p_quick_po_header_id          => null
    );
    dbms_output.put_line('*** HEADER');
    dbms_output.put_line('  ROW ID:'||l_rowid);
    dbms_output.put_line('  NUM NF:'||l_invoice_id||'-X');
  END IF;
  --LINES
  if (ok) then
    BEGIN
      l_rowid := null;
      ap_ail_table_handler_pkg.insert_row(
        p_rowid                         => l_rowid,
        p_invoice_id                    => l_invoice_id,
        p_line_number                   => '1',
        p_line_type_lookup_code         => 'ITEM',
        p_line_group_number             => NULL,
        p_requester_id                  => NULL,
        p_description                   => l_description,
        p_line_source                   => 'IMPORTED',
        p_org_id                        => l_org_id,
        p_inventory_item_id             => NULL,
        p_item_description              => l_item_description,
        p_serial_number                 => NULL,
        p_manufacturer                  => NULL,
        p_model_number                  => NULL,
        p_warranty_number               => NULL,
        p_generate_dists                => 'D',
        p_match_type                    => 'ITEM_TO_PO', --NULL,
        --
        p_set_of_books_id               => l_set_of_books_id,
        p_ship_to_location_id           => l_ship_to_location_id,
        --
        p_po_header_id                  => l_po_header_id, --188009,
        p_po_line_id                    => l_po_line_id, --195033,
        p_po_distribution_id            => l_po_distribution_id, --201022,
        p_po_line_location_id           => l_po_line_location_id, --200044,
        --
        p_distribution_set_id           => NULL,
        p_account_segment               => NULL,
        p_balancing_segment             => NULL,
        p_cost_center_segment           => NULL,
        p_overlay_dist_code_concat      => NULL,
        p_default_dist_ccid             => NULL,
        p_prorate_across_all_items      => NULL,
        p_accounting_date               => SYSDATE,
        p_period_name                   => TO_CHAR(SYSDATE,'MON-YY'),
        p_deferred_acctg_flag           => 'N',
        p_def_acctg_start_date          => NULL,
        p_def_acctg_end_date            => NULL,
        p_def_acctg_number_of_periods   => NULL,
        p_def_acctg_period_type         => NULL,
        p_amount                        => l_valor,
        p_base_amount                   => l_valor,
        p_rounding_amt                  => NULL,
        p_quantity_invoiced             => l_qtd,
        p_unit_meas_lookup_code         => l_unit_meas_lookup_code,
        p_unit_price                    => l_unit_price,
        p_wfapproval_status             => 'NOT REQUIRED',
        p_discarded_flag                => 'N',
        p_original_amount               => NULL,
        p_original_base_amount          => NULL,
        p_original_rounding_amt         => NULL,
        p_cancelled_flag                => 'N',
        p_income_tax_region             => NULL,
        p_type_1099                     => NULL,
        p_stat_amount                   => NULL,
        p_prepay_invoice_id             => NULL,
        p_prepay_line_number            => NULL,
        p_invoice_includes_prepay_flag  => NULL,
        p_corrected_inv_id              => NULL,
        p_corrected_line_number         => NULL,
        p_po_release_id                 => NULL,
        p_rcv_transaction_id            => NULL,
        p_final_match_flag              => NULL,
        p_assets_tracking_flag          => 'N',
        p_asset_book_type_code          => NULL,
        p_asset_category_id             => NULL,
        p_project_id                    => NULL,
        p_task_id                       => NULL,
        p_expenditure_type              => NULL,
        p_expenditure_item_date         => NULL,
        p_expenditure_organization_id   => NULL,
        p_pa_quantity                   => NULL,
        p_pa_cc_ar_invoice_id           => NULL,
        p_pa_cc_ar_invoice_line_num     => NULL,
        p_pa_cc_processed_code          => NULL,
        p_award_id                      => NULL,
        p_awt_group_id                  => NULL,
        p_pay_awt_group_id              => NULL,
        p_reference_1                   => NULL,
        p_reference_2                   => NULL,
        p_receipt_verified_flag         => NULL,
        p_receipt_required_flag         => NULL,
        p_receipt_missing_flag          => NULL,
        p_justification                 => NULL,
        p_expense_group                 => NULL,
        p_start_expense_date            => NULL,
        p_end_expense_date              => NULL,
        p_receipt_currency_code         => NULL,
        p_receipt_conversion_rate       => NULL,
        p_receipt_currency_amount       => NULL,
        p_daily_amount                  => NULL,
        p_web_parameter_id              => NULL,
        p_adjustment_reason             => NULL,
        p_merchant_document_number      => NULL,
        p_merchant_name                 => NULL,
        p_merchant_reference            => NULL,
        p_merchant_tax_reg_number       => NULL,
        p_merchant_taxpayer_id          => NULL,
        p_country_of_supply             => NULL,
        p_credit_card_trx_id            => NULL,
        p_company_prepaid_invoice_id    => NULL,
        p_cc_reversal_flag              => 'N',
        p_creation_date                 => SYSDATE,
        p_created_by                    => -1,
        p_last_updated_by               => -1,
        p_last_update_date              => SYSDATE,
        p_last_update_login             => NULL,
        p_program_application_id        => 200,
        p_program_id                    => NULL,
        p_program_update_date           => NULL,
        p_request_id                    => NULL,
        p_attribute_category            => NULL,
        p_attribute1                    => NULL,
        p_attribute2                    => NULL,
        p_attribute3                    => NULL,
        p_attribute4                    => NULL,
        p_attribute5                    => NULL,
        p_calling_sequence              => '1'
      );
      dbms_output.put_line('*** LINES');
      dbms_output.put_line('  ROW ID:'||l_rowid);
    END;
  end if;
  --DISTRIBUTION
  if (ok) then
    BEGIN 
      SELECT ap_invoice_distributions_s.nextval INTO l_ap_invoice_dis_id FROM dual;
      l_rowid := null;
      dbms_output.put_line('*** DISTRIBUTIONS');
      dbms_output.put_line('  DIST ID:'||l_ap_invoice_dis_id);
      ap_aid_table_handler_pkg.insert_row(
        p_rowid                       => l_rowid,
        p_invoice_id                  => l_invoice_id,
        p_invoice_line_number         => '1',
        p_distribution_class          => 'PERMANENT',
        p_invoice_distribution_id     => l_ap_invoice_dis_id,
        --
        p_dist_code_combination_id    => l_code_combination_id,
        p_set_of_books_id             => l_set_of_books_id,
        p_po_distribution_id          => l_po_distribution_id,
        --
        p_last_update_date            => SYSDATE,
        p_last_updated_by             => -1,
        p_accounting_date             => SYSDATE,
        p_period_name                 => TO_CHAR(SYSDATE,'MON-YY'),

        p_amount                      => l_valor,
        p_description                 => l_description,
        p_type_1099                   => NULL,
        p_posted_flag                 => 'N',
        p_batch_id                    => NULL,
        p_quantity_invoiced           => l_qtd,
        p_unit_price                  => l_unit_price,
        p_match_status_flag           => NULL,
        p_attribute_category          => NULL,
        p_attribute1                  => NULL,
        p_attribute2                  => NULL,
        p_attribute3                  => NULL,
        p_attribute4                  => NULL,
        p_attribute5                  => NULL,
        p_prepay_amount_remaining     => NULL,
        p_assets_addition_flag        => 'U',
        p_assets_tracking_flag        => 'Y',
        p_distribution_line_number    => '1',
        p_line_type_lookup_code       => 'ACCRUAL',
        p_base_amount                 => l_valor,
        p_pa_addition_flag            => 'E',
        p_posted_amount               => NULL,
        p_posted_base_amount          => NULL,
        p_encumbered_flag             => 'N',
        p_accrual_posted_flag         => 'N',
        p_cash_posted_flag            => 'N',
        p_last_update_login           => NULL,
        p_creation_date               => SYSDATE,
        p_created_by                  => -1,
        p_stat_amount                 => NULL,
        p_attribute11                 => NULL,
        p_attribute12                 => NULL,
        p_attribute13                 => NULL,
        p_attribute14                 => NULL,
        p_attribute6                  => NULL,
        p_attribute7                  => NULL,
        p_attribute8                  => NULL,
        p_attribute9                  => NULL,
        p_attribute10                 => NULL,
        p_attribute15                 => NULL,
        p_accts_pay_code_comb_id      => NULL,
        p_reversal_flag               => NULL,
        p_parent_invoice_id           => NULL,
        p_income_tax_region           => NULL,
        p_final_match_flag            => NULL,
        p_expenditure_item_date       => NULL,
        p_expenditure_organization_id => NULL,
        p_expenditure_type            => NULL,
        p_pa_quantity                 => NULL,
        p_project_id                  => NULL,
        p_task_id                     => NULL,
        p_quantity_variance           => NULL,
        p_base_quantity_variance      => NULL,
        p_packet_id                   => NULL,
        p_awt_flag                    => NULL,
        p_awt_group_id                => NULL,
        p_pay_awt_group_id            => NULL,
        p_awt_tax_rate_id             => NULL,
        p_awt_gross_amount            => NULL,
        p_reference_1                 => NULL,
        p_reference_2                 => NULL,
        p_org_id                      => l_org_id,
        p_other_invoice_id            => NULL,
        p_awt_invoice_id              => NULL,
        p_awt_origin_group_id         => NULL,
        p_program_application_id      => NULL,
        p_program_id                  => NULL,
        p_program_update_date         => NULL,
        p_request_id                  => NULL,
        p_tax_recoverable_flag        => NULL,
        p_award_id                    => NULL,
        p_start_expense_date          => NULL,
        p_merchant_document_number    => NULL,
        p_merchant_name               => NULL,
        p_merchant_tax_reg_number     => NULL,
        p_merchant_taxpayer_id        => NULL,
        p_country_of_supply           => NULL,
        p_merchant_reference          => NULL,
        p_parent_reversal_id          => NULL,
        p_rcv_transaction_id          => NULL,
        p_matched_uom_lookup_code     => l_unit_meas_lookup_code,
        p_calling_sequence            => '1',
        p_rcv_charge_addition_flag    => 'N'
      );
      dbms_output.put_line('  ROW ID :'||l_rowid);
    end;
  end if;
  --VALIDA��O
  if (ok and l_rowid is not null) then
    --
    valida_invoice(
      p_invoice_id => l_invoice_id,
      x_retorno    => l_retorno
    );
    dbms_output.put_line('  Retorno:'||l_retorno);
    --
    if (ok and l_retorno='S') then
      update ap_payment_schedules_all 
      set PAYMENT_PRIORITY = '66'
      where invoice_id = l_invoice_id;
    else
      ok:=false;  
    end if;
  else
    ok:=false;
  end if;
  --
  if (not ok) then
    ROLLBACK TO XXFR_CRIAR_NF_USD;
    l_retorno := 'E';
    l_invoice_id := null;
  end if;
  x_retorno    := l_retorno;
  x_invoice_id := l_invoice_id;
  dbms_output.put_line('********************************************************************');
  dbms_output.put_line('FIM DO PROCESSAMENTO - '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS')||' - CRIA��O NFF - PO:'||p_segment1);
  dbms_output.put_line('********************************************************************');
EXCEPTION
  WHEN too_many_rows THEN
    dbms_output.put_line('Err Msg:'||SQLERRM);
    dbms_output.put_line('Err Cod:'||SQLCODE);  
    x_retorno := 'E';
    x_invoice_id := null;
    ROLLBACK TO XXFR_CRIAR_NF_USD;
  WHEN no_data_found THEN
    dbms_output.put_line('Err Msg:'||SQLERRM);
    dbms_output.put_line('Err Cod:'||SQLCODE);  
    x_retorno := 'E';
    x_invoice_id := null;
    ROLLBACK TO XXFR_CRIAR_NF_USD;
  WHEN OTHERS THEN
    dbms_output.put_line('Err Msg:'||SQLERRM);
    dbms_output.put_line('Err Cod:'||SQLCODE); 
    x_retorno := 'E';
    x_invoice_id := null;
    ROLLBACK TO XXFR_CRIAR_NF_USD;
END XXFR_AP_CUST_INVOICE_CREATE;
/

