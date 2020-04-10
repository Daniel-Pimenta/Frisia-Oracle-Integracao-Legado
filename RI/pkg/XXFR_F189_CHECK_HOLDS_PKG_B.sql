create or replace PACKAGE BODY xxfr_F189_CHECK_HOLDS_PKG AS
  /* $Header: CLLVRIHB.pls 120.441 2020/01/29 16:33:44 sasimoes noship $ */
  w_table_associated cll_f189_interface_errors.table_associated%TYPE;
  -- ERancement 4233742 AIrmer 12/08/2005
  FUNCTION func_check_holds(p_organization_id      IN NUMBER,
                            p_location_id          IN NUMBER,
                            p_operation_id         IN NUMBER,
                            p_freight_flag         IN VARCHAR2,
                            p_total_freight_weight IN NUMBER,
                            p_interface            IN VARCHAR2 DEFAULT 'N',
                            p_interface_invoice_id IN NUMBER DEFAULT NULL) -- Bug 5029863 AIRmer 20/02/2006
   RETURN NUMBER IS
    x_invoice_id_selec       NUMBER;
    x_validate_flag          VARCHAR2(1);
    v_count                  NUMBER;
    v_sum_weight             NUMBER;
    v_sum_total_amount       NUMBER;
    v_sum_total_amount_round NUMBER;
    v_sum_total_amount_trunc NUMBER;
    v_sum_total_icms         NUMBER;
    v_sum_total_icms_round   NUMBER;
    v_sum_total_icms_trunc   NUMBER;
    v_sum_base_icms          NUMBER;
    v_sum_base_icms_round    NUMBER;
    v_sum_base_icms_trunc    NUMBER;
    v_sum_ipi_amount         NUMBER;
    v_sum_ipi_amount_round   NUMBER;
    v_sum_ipi_amount_trunc   NUMBER;
    -- 25713076 - Start
    l_sum_fcp_amount          NUMBER;
    l_sum_fcp_amount_round    NUMBER;
    l_sum_fcp_amount_trunc    NUMBER;
    l_sum_fcp_st_amount       NUMBER;
    l_sum_fcp_st_amount_round NUMBER;
    l_sum_fcp_st_amount_trunc NUMBER;
    -- 25713076 - End
    l_sum_discount_net_amount NUMBER := 0; -- 28730612
    l_sum_discount_amount     NUMBER := 0; -- 28730612
    l_sum_discount_percent    NUMBER := 0; -- 28730612
    v_sum_total_amount_nf       NUMBER;
    v_sum_total_amount_nf_r     NUMBER;
    v_sum_total_amount_nf_t     NUMBER;
    v_sum_dol_total_amount      NUMBER;
    v_sum_dol_total_amount_2    NUMBER;
    v_importation_total         NUMBER;
    v_iss_amount                NUMBER;
    v_ir_amount                 NUMBER := 0; -- Bug 9156266
    v_base_ipi_import           NUMBER;
    v_dol_total_amount          NUMBER;
    v_cred_type_inv             VARCHAR2(1);
    v_cred_type_frt             VARCHAR2(1);
    v_po_payment_condition_flag VARCHAR2(1);
    v_balance_seg               VARCHAR2(25);
    v_account_seg               NUMBER;
    v_tolerance_amount          NUMBER;
    v_tolerance_code            VARCHAR2(25);
    v_rcv_tolerance_percent     NUMBER;
    v_divergencia               NUMBER;
    l_total_ri                  NUMBER; -- 25461628
    l_total_po                  NUMBER; -- 25461628
    v_contab_frt                VARCHAR2(1) := '';
    v_contab_nf                 VARCHAR2(1) := '';
    v_triangle_operation        VARCHAR2(1) := '';
    v_uom_son                   VARCHAR2(25);
    v_uom_par                   VARCHAR2(25);
    v_uom_class                 VARCHAR2(10);
    v_conversion_rate           NUMBER;
    v_qtde_par                  NUMBER;
    v_qtde_son                  NUMBER;
    arr                         NUMBER(1);
    w_arr                       NUMBER(1);
    w_icms_base                 NUMBER;
    w_icms_amount               NUMBER;
    w_icms_amount_recover       NUMBER;
    w_ipi_amount                NUMBER;
    w_ipi_amount_recover        NUMBER;
    w_fcp_amount_recover        NUMBER; -- 28269989
    v_p1                        NUMBER;
    v_p2                        NUMBER;
    v_p3                        NUMBER;
    v_p4                        NUMBER;
    v_p5                        NUMBER;
    v_p6                        NUMBER;
    -- ER 26338366/26899224 -- Start (WCarvalho - 30/OCT/2017)
    v_p7 NUMBER;
    -- ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)
    v_currency_conversion_rate     VARCHAR2(15);
    v_enforce_corp_conversion_rate VARCHAR2(1);
    v_quant                        NUMBER;
    v_currency_code                VARCHAR2(15) := NULL;
    v_currency_alt1                VARCHAR2(15) := NULL;
    v_currency_alt2                VARCHAR2(15) := NULL;
    v_conversion_date              DATE;
    v_gl_date                      DATE;
    w_aux_po_header                NUMBER;
    w_aux_currency_code_po         VARCHAR2(15);
    w_aux_currency_code_org        VARCHAR2(15);
    w_aux_ud_conv_rate             NUMBER;
    w_aux_national_state           VARCHAR2(1);
    nsumlinicmsbase                NUMBER;
    x_sum_icms_st_amount           NUMBER;
    ntotnficmsbase                 NUMBER;
    ntotnficmsamount               NUMBER;
    ncountprojects                 NUMBER;
    ncountlin                      NUMBER;
    -- Bug 5668044 AIrmer 05/12/2006
    ncountnoprojects NUMBER;
    -- Bug 5887300 SSimoes 01/03/2007
    cprojecterror VARCHAR2(30) := 'N';
    -- Bug 5905664 SSimoes 06/03/2007
    cprojectflag                   VARCHAR2(1) := 'N';
    v_count_seiban                 NUMBER; -- ER 6788945 AIrmer 15/02/2008
    braiseprojects                 BOOLEAN := FALSE;
    nvallocalentrega               NUMBER;
    ncountempERo                   NUMBER;
    ncountpedidos                  NUMBER;
    ctipopedido                    VARCHAR2(50) := 'NONE';
    ncountnfcompl                  NUMBER;
    nquantdeliver                  NUMBER;
    nquantshiplines                NUMBER;
    nparentoperation               NUMBER;
    cvalidaempERo                  VARCHAR2(1);
    v_nf_other_expenses            NUMBER;
    v_linhas_other_expenses        NUMBER;
    v_fa_exists                    NUMBER;
    v_raise_fa                     BOOLEAN;
    v_raise_nf_complementar        BOOLEAN;
    w_set_of_books_id_alt1         NUMBER;
    w_set_of_books_id_alt2         NUMBER;
    nquantnfpai                    NUMBER;
    x_tipo_nota_custo              NUMBER;
    x_fixed_assets_profile         VARCHAR2(1);
    x_count_lines_fa               NUMBER;
    x_return_quantity              cll_f189_invoice_lines.quantity%TYPE;
    x_parent_quantity              cll_f189_invoice_lines.quantity%TYPE;
    x_insert_pac                   NUMBER;
    x_raise_pac                    BOOLEAN;
    x_period_pac                   NUMBER;
    x_set_of_books_id_alt1         NUMBER;
    x_set_of_books_id_alt2         NUMBER;
    x_set_of_books_id_func         NUMBER;
    x_open_flag                    cst_pac_periods.open_flag%TYPE;
    p_segment                      VARCHAR2(30);
    x_query                        NUMBER := 0;
    x_qtd_invoices                 NUMBER := 0;
    x_qtd_freight_invoices         NUMBER := 0;
    x_prf_setup_iss                VARCHAR2(30);
    x_receive_date                 cll_f189_entry_operations.receive_date%TYPE;
    x_cont                         NUMBER;
    x_hold_currency_different_po   cll_f189_parameters.hold_currency_different_po%TYPE;
    x_moeda_rec                    cll_f189_invoices.po_currency_code%TYPE;
    v_sum_pis_st_amount            NUMBER;
    v_sum_pis_st_amount_round      NUMBER;
    v_sum_pis_st_amount_trunc      NUMBER;
    v_sum_cofins_st_amount         NUMBER;
    v_sum_cofins_st_amount_round   NUMBER;
    v_sum_cofins_st_amount_trunc   NUMBER;
    v_sum_pis_cofins_st_base       NUMBER;
    v_sum_pis_cofins_st_base_round NUMBER;
    v_sum_pis_cofins_st_base_trunc NUMBER;
    n_quantidade                   NUMBER;
    n_debito                       NUMBER;
    n_credito                      NUMBER;
    n_inseriu                      NUMBER := 0;
    x_accrual_supplier_ccid        NUMBER;
    x_reg                          NUMBER := 0;
    x_allow_inv_major_accrual      VARCHAR2(1);
    x_nota_devol                   NUMBER := 0;
    x_cont_lia                     NUMBER;
    p_segment_conta                VARCHAR2(30);
    x_conta_ativo                  VARCHAR(25);
    v_sum_pis_imp_amount           NUMBER;
    v_sum_cofins_imp_amount        NUMBER;
    v_sum_cide_imp_amount          NUMBER; -- 25341463
    v_base_ipi_import_pis_cofins   NUMBER;
    x_utilization_asset_flag       VARCHAR2(1);
    ncountreleases                 NUMBER; -- BUG 4036472
    ncounttemreleases              NUMBER; -- BUG 4036472
    x_quantity_relationship        NUMBER;
    x_qty_rcv_tolerance            NUMBER;
    x_quantity_already_pen_or_apv  NUMBER;
    x_location_quantidy            NUMBER;
    v_importation_number           cll_f189_invoices.importation_number%TYPE; -- Bug 4585347 SSimoes 01/09/2005 --
    v_pis_recover_start_date       cll_f189_parameters.pis_recover_start_date%TYPE; -- ER 4533742 AIrmer 12/08/2005 --
    v_cofins_recover_start_date    cll_f189_parameters.cofins_recover_start_date%TYPE; -- ER 4533742 AIrmer 12/08/2005 --
    l_recover_pis_flag_cnpj        cll_f189_item_utilizations.recover_pis_flag_cnpj%TYPE;
    l_recover_pis_flag_cpf         cll_f189_item_utilizations.recover_pis_flag_cpf%TYPE;
    l_recover_cofins_flag_cnpj     cll_f189_item_utilizations.recover_cofins_flag_cnpj%TYPE;
    l_recover_cofins_flag_cpf      cll_f189_item_utilizations.recover_cofins_flag_cpf%TYPE;
    l_document_type                cll_f189_fiscal_entities_all.document_type%TYPE;
    l_utilization_id               cll_f189_item_utilizations.utilization_id%TYPE;
    l_ok                           BOOLEAN;
    w_free_trade_zone_flag         VARCHAR2(1); -- ER 5089320 --
    v_sum_pres_icms_amount         NUMBER; -- ER 5089320 --
    v_sum_pres_icms_amount_round   NUMBER; -- ER 5089320 --
    v_sum_pres_icms_amount_trunc   NUMBER; -- ER 5089320 --
    ncountrma                      NUMBER; -- Bug 5951443 SSimoes 10/04/2007
    v_gl_date_diff_from_sysdate    cll_f189_parameters.gl_date_diff_from_sysdate%TYPE;      -- Bug 16634319
    l_rec_date_diff_from_sysdate   cll_f189_parameters.receive_date_diff_from_sysdate%TYPE; -- 29559606
    l_invoice_date_less_than       cll_f189_parameters.invoice_date_less_than%TYPE; -- Bug 10367485
    l_invoice_days                 NUMBER; -- Bug 10367485
    V_VENDOR_ID                    NUMBER; --(++) Rantonio, 28/01/2008;BUG 6075440 -- Bug Equal 6771247 - rvicente - 30/01/2008
    V_FUNRURAL                     VARCHAR2(03); --(++) Rantonio, 28/01/2008;BUG 6075440 -- Bug Equal 6771247 - rvicente - 30/01/2008
    l_sum_funrural_tax             NUMBER := 0; -- ER 17551029
    -- ER 17551029 5a Fase - Start
    --l_esocial_start_date             DATE   :=NULL; -- 18762109
    l_esocial_start_date  VARCHAR2(10); -- 18762109
    l_legal_entity_id_f   NUMBER; -- 18762109
    l_esocial_period_code cll_f407_entity_profiles.start_period_code%TYPE := NULL;
    l_reinf_period_code   cll_f407_entity_profiles.start_period_code%TYPE := NULL; -- 25808200 - 25808214
    l_esocial_doc_number  cll_f189_fiscal_entities_all.document_number%TYPE;
    l_validate_caepf_num  NUMBER;
    l_caepf_num           VARCHAR2(15);
    l_registration_id     NUMBER;
    l_worker_category     VARCHAR2(1);
    l_count_doc           NUMBER := 0;
    l_prior_count_err     NUMBER := 0;
    l_validate_doc_num    NUMBER;
    l_doc_num             VARCHAR2(15);
    l_sum_prior_billings  NUMBER := 0;
    l_construction_type   cll_f407_mtl_system_items_ext.attribute1%TYPE;
    -- ER 17551029 5a Fase - End
    l_val_doc_esocial VARCHAR2(20); -- 22285738
    --
    -- ER 6399212 AIrmer 26/12/2007 - Begin
    l_allow_mult_bal_segs VARCHAR2(1);
    -- ER 6399212 AIrmer 26/12/2007 - End
    --
    -- ER 6519914 - SSimoes - 15/05/2008 - Inicio
    v_sum_iss_amount            NUMBER;
    v_sum_iss_amount_round      NUMBER;
    v_sum_iss_amount_trunc      NUMBER;
    v_sum_iss_base_amount       NUMBER;
    v_sum_iss_base_amount_round NUMBER;
    v_sum_iss_base_amount_trunc NUMBER;
    -- ER 6519914 - SSimoes - 15/05/2008 - Fim
    --
    -- ER 7247503 - SPED FISCAL
    x_result_vehicle_seller     NUMBER;
    x_vehicle_seller_doc_number VARCHAR2(15);
    -- ER 7247503 - SPED FISCAL
    --
    -- ER 7530537 - Amaciel - 27/01/2009 - Inicio
    v_utilization_null NUMBER := 0;
    v_utilization_not  NUMBER := 0;
    -- ER 7530537 - Amaciel - 27/01/2009 - Fim
    --
    v_count_invoices NUMBER := 0; -- ER 7540459
    --
    -- ER 7483063
    l_payment_type     VARCHAR2(15);
    l_count_wc         NUMBER;
    l_count_prepayment NUMBER := 0; -- Bug 8591473
    l_total_prepayment NUMBER := 0; -- Bug 8591473
    l_count_standard   NUMBER := 0; -- Bug 8591473
    l_total_standard   NUMBER := 0; -- Bug 8591473
    l_rwc_amount       NUMBER;
    l_rwc_quantity     NUMBER;
    l_invoice_line_id  NUMBER;
    l_shipment_line_id NUMBER;
    l_count_line       NUMBER;
    -- ER 7483063
    v_count_req_int    NUMBER := 0; -- Bug 8585314 - SSimoes - 29/06/2009
    l_freight_amount   NUMBER := 0; -- BUG 8610403
    l_insurance_amount NUMBER := 0; -- BUG 8610403
    l_other_expenses   NUMBER := 0; -- Bug 18096092
    -- ER 8614153
    ncountdistrinv                NUMBER;
    ncountdistrexp                NUMBER;
    v_fed_withholding_tax_flag    cll_f189_parameters.federal_withholding_tax_flag%TYPE; -- ER 8633459 --
    v_allow_upd_payment_term_flag cll_f189_parameters.allow_upd_payment_term_flag%TYPE; -- ER 10091174
    v_validity_payment_term       VARCHAR2(1); -- ER 10091174
    -- Bug 8791684 - SSimoes - 09/09/2009 - Inicio
    v_local_inativo  NUMBER;
    v_operating_unit org_organization_definitions.operating_unit%TYPE;
    -- Bug 8791684 - SSimoes - 09/09/2009 - Fim
    l_org_id             hr_organization_information.org_information3%TYPE; -- ER 8571984
    v_validity_rules     VARCHAR2(1); -- ER 8621766
    l_ipi_tributary_type VARCHAR2(1); -- 22073362
    -- Remessa FA -- 20/11/2009 - SSimoes - Inicio
    v_remessa_atual   NUMBER;
    v_remessa         NUMBER;
    v_faturado_nf_pai NUMBER;
    -- Remessa FA -- 20/11/2009 - SSimoes - Fim
    -- Bug 9343025 - SSimoes - 02/02/2010 - Inicio
    -- v_lcm_flag                         mtl_parameters.lcm_enabled_flag%TYPE; -- Bug 9309213 - SSimoes - 21/01/2010
    v_lcm_flag VARCHAR2(1);
    -- Bug 9343025 - SSimoes - 02/02/2010 - Fim
    v_business_vendors NUMBER; -- Bug 9446918
    v_entity_id        NUMBER; -- Bug 9597256
    v_trib_status_code NUMBER := 0; -- Bug 9592789 - SSimoes - 06/05/2010
    --      v_state_code                     VARCHAR2 (25); -- Bug 7422494 - SSimoes - 10/06/2010
    v_national_state             cll_f189_states.national_state%TYPE; -- Bug 9532625 - SSimoes - 21/05/2010
    v_inventory_destination_flag VARCHAR2(1) := NULL; -- Bug 9745040 - SSimoes - 01/06/2010
    v_length_invoice_num         NUMBER; -- ER 9297043 - GSilva - 02/06/2010
    v_book_type_code             cll_f189_parameters.book_type_code%TYPE; -- Bug 9600580 - SSimoes - 08/06/2010
    v_count_entity_id            NUMBER; -- Bug 9943877
    -- ER 9955304 - GSilva - 30/09/2010 - Inicio
    v_ipi_trib_code_required_flag VARCHAR2(1);
    v_pis_trib_code_required_flag VARCHAR2(1);
    v_cof_trib_code_required_flag VARCHAR2(1);
    -- ER 9955304 - GSilva - 30/09/2010 - Fim
    l_outbound_type            VARCHAR2(1); -- ER: 11817687
    l_ctrc_lin                 NUMBER := 0; -- ER: 11817687
    l_ctrc_Outbound            NUMBER := 0; -- Bug 12432581
    v_ap_period                VARCHAR2(1); -- Bug 11874715 - GSilva - 28/3/2011
    v_payment_flag_frt         VARCHAR2(1); -- Bug 11874715 - GSilva - 28/3/2011
    l_icms_amt_rec_lines       cll_f189_invoice_lines.icms_amount_recover%TYPE; -- ER 9289619
    l_icms_amt_rec_lines_round cll_f189_invoice_lines.icms_amount_recover%TYPE; -- ER 9289619
    l_icms_amt_rec_lines_trunc cll_f189_invoice_lines.icms_amount_recover%TYPE; -- ER 9289619
    -- Bug 11773438 - GSilva - 04/04/2011 - Inicio
    v_fnd_user_id      NUMBER := fnd_global.USER_ID;
    v_fnd_resp_id      NUMBER := fnd_global.RESP_ID;
    v_fnd_resp_appl_id NUMBER := fnd_global.RESP_APPL_ID;
    v_rcv_tp_mode      VARCHAR2(30);
    -- Bug 11773438 - GSilva - 04/04/2011 - Fim
    v_count_awt        NUMBER;    -- ER 9072748
    l_nfe_key          NUMBER;    -- ER 12352413
    l_nfe_key_inv      EXCEPTION; -- ER 12352413
    l_key_out_inv      NUMBER;    -- 27579747
    l_err_key_out_inv  EXCEPTION; -- 27579747
    l_cte_key_exist    NUMBER;    -- 27579747
    l_nfe_key_exist    NUMBER;    -- 27579747
    v_inv_lenght       NUMBER := NULL; -- Bug 13947775
    l_state_code       cll_f189_states.state_code%TYPE; -- ER 14622175
    l_document_number  cll_f189_fiscal_entities_all.document_number%TYPE; -- ER 14622175
    --
    --l_dsp_document_number  cll_f189_fiscal_entities_all.document_number%TYPE; -- Bug 17301893 -- Bug 18043475
    --
    l_quantnfpai_sn          NUMBER; -- ER 9289619
    l_return_customer_flag   cll_f189_invoice_types.return_customer_flag%TYPE; -- ER 10367032
    l_national_state         cll_f189_states.national_state%TYPE; -- ER 10367032
    l_allow_awt_flag         po_vendor_sites_all.allow_awt_flag%TYPE; -- Bug 12835667
    vCountReceipt            NUMBER; -- BUG 12732658 LMEDEIROS
    l_returned_lines         BOOLEAN; -- Bug 14160294
    l_invoice_parent_line_id cll_f189_invoice_line_parents.invoice_parent_line_id%TYPE; -- Bug 14160294
    -- ER 11820206 - Start
    l_raise_conversion BOOLEAN := FALSE;
    l_uom_diff         NUMBER;
    l_dist_uom         NUMBER;
    -- ER 11820206 - End
    --<< Bug 14642712 - Egini - 20/09/2012 Inicio >> --
    x_char_count number;
    x_count_ar   number;
    x_desc_ar    varchar2(4000);
    --<< Bug 14642712 - Egini - 20/09/2012 Fim    >> --
    -- ER 13687710 - Start
    x_efd_type                    cll_f189_fiscal_document_types.efd_type%TYPE;
    x_invoice_key_required_flag   cll_f189_fiscal_document_types.invoice_key_required_flag%TYPE;
    x_invoice_key_validation_flag cll_f189_fiscal_document_types.invoice_key_validation_flag%TYPE;
    x_invoice_number_length_flag  cll_f189_fiscal_document_types.invoice_number_length_flag%TYPE;
    -- ER 13687710 - End
    v_inventory_item_status_code varchar2(1);
    -- Bug 19951540 - Start
    --l_purchasing_item_flag        varchar2(1);         -- Bug 19438526 -- Bug 19951540
    l_inactive_item VARCHAR2(1) := 'Y'; -- Bug 19951540
    --l_purchasing_enabled_flag      VARCHAR2(1); -- 22617088
    l_purchasing_item_flag   VARCHAR2(1); -- 22617088
    l_stock_enabled_flag     VARCHAR2(1);
    l_internal_order_enabled VARCHAR2(1);
    l_invoice_enabled_flag   VARCHAR2(1);
    l_invoiceable_item       VARCHAR2(1);
    l_shippable_item_flag    VARCHAR2(1);
    l_so_transactions_flag   VARCHAR2(1);
    l_returnable_flag        VARCHAR2(1);
    -- Bug 19951540 - End
    -- Bug 18799722 - Start
    l_inss_base_date       NUMBER;
    l_inss_period          VARCHAR2(1);
    l_ir_base_date         NUMBER;
    l_ir_period            VARCHAR2(1);
    l_iss_base_date        NUMBER;
    l_iss_period           VARCHAR2(1);
    l_funrural_base_date   NUMBER;
    l_funrural_period      VARCHAR2(1);
    l_sest_senat_base_date NUMBER;
    l_sest_senat_period    VARCHAR2(1);
    -- Bug 18799722 - End
    l_return_cfo_id         NUMBER; -- Bug 17835378
    l_operation_fiscal_type NUMBER := NULL; -- ER 19597186
    --
    -- Inicio BUG 19722064
    l_org_code          VARCHAR2(100);
    l_organization_id   NUMBER;
    l_invoice_type_code VARCHAR2(100);
    l_invoice_type_id   NUMBER;
    l_cfo_id            NUMBER;
    l_utilization_id_fr NUMBER;
    l_util_id           NUMBER;
    -- Fim BUG 19722064
    l_icms_type              cll_f189_invoices.icms_type%TYPE; -- ER 9028781
    l_icms_count             NUMBER; -- ER 9028781
    l_simplified_br_tax_flag cll_f189_invoices.simplified_br_tax_flag%TYPE; -- ER 9028781
    l_icmstype_line_count    NUMBER; -- ER 9028781
    l_icmstype_header_count  NUMBER; -- ER 9028781
    --
    -- Inicio BUG 20387571
    l_unit_of_measure VARCHAR2(25);
    x_unit_of_measure VARCHAR2(25);
    -- Fim BUG 20387571
    -- Bug 20365208 - Start
    l_inss_min_amount           NUMBER;
    l_cumulative_threshold_type VARCHAR2(30);
    l_inss_error_code           VARCHAR2(30);
    -- Bug 20365208 - End
    -- Bug 20145693 - Start
    l_actual_year      NUMBER(4) := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
    l_actual_monthyear NUMBER(6) := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMM'));
    l_min_year         NUMBER(4) := 2013;
    l_recopi_date      DATE;
    l_time             DATE;
    l_validate_digits  VARCHAR2(2);
    l_invalid_date EXCEPTION;
    -- Bug 20145693 - End
    l_item_number_found      NUMBER; -- 21645107
    l_count_item_number      NUMBER; -- 21645107
    v_sum_included_icms_head NUMBER; -- ER 20450226
    v_sum_included_icms_line NUMBER; -- ER 20450226
    -- Bug 20207037 - Start
    l_pis_flag    cll_f189_invoice_types.pis_flag%TYPE;
    l_cofins_flag cll_f189_invoice_types.cofins_flag%TYPE;
    -- Bug 20207037 - End
    l_pis_amount          cll_f189_invoice_lines.pis_amount%TYPE;          -- 27740002
    l_cofins_amount       cll_f189_invoice_lines.cofins_amount%TYPE;       -- 27740002
    l_collect_pis_ccid    cll_f189_invoice_types.collect_pis_ccid%TYPE;    -- 27740002
    l_collect_cofins_ccid cll_f189_invoice_types.collect_cofins_ccid%TYPE; -- 27740002
    l_contab_flag         cll_f189_invoice_types.contab_flag%TYPE;         -- 27740002
    l_carrier_state_code  cll_f189_states.state_code%TYPE;                 -- ER 20404053
    l_check               NUMBER; -- ER 20404053
    -- ER 20382276 - Start
    l_fob_authorization       NUMBER := 0;
    l_inv_authorization       NUMBER := 0;

-- Bug 27401206 - Start
--    l_inv_usage_authorization VARCHAR2(80);
--    l_frt_usage_authorization VARCHAR2(80);
    l_inv_usage_authorization fnd_lookup_values_vl.meaning%type;
    l_frt_usage_authorization fnd_lookup_values_vl.meaning%type;
-- Bug 27401206 - End

    -- ER 20382276 - End
    -- ER 20608903 - Start
    l_set_of_books_id_alt1 NUMBER := TO_NUMBER(fnd_profile.VALUE('CLL_F189_FIRST_ALTERNATIVE_SET_OF_BOOKS'));
    l_set_of_books_id_alt2 NUMBER := TO_NUMBER(fnd_profile.VALUE('CLL_F189_SECOND_ALTERNATIVE_SET_OF_BOOKS'));
    -- ER 20608903 - End
    -- ER 14124731 - Start
    l_source                  cll_f189_entry_operations.source%TYPE;
    l_model_tag               fnd_lookup_values.tag%TYPE;
    l_model_tag_freight       fnd_lookup_values.tag%TYPE;
    l_usage_authorization_tag fnd_lookup_values.tag%TYPE;
    l_chnfe                   cll_f189_freight_invoices.eletronic_invoice_key%TYPE;
    l_protnfe                 fnd_lookup_values.lookup_code%TYPE;
    l_chcte                   cll_f189_invoices.eletronic_invoice_key%TYPE;
    l_protcte                 fnd_lookup_values.lookup_code%TYPE;
    l_retcode                 NUMBER;
    l_retstatus               VARCHAR2(1000);
    -- ER 14124731 - End
    -- Inicio Bug 21895963
    x_minimum_tax_amount CLL_F189_TAX_SITES.MINIMUM_TAX_AMOUNT%TYPE;
    -- Fim Bug 21895963
    l_csticms_line    fnd_lookup_values.lookup_code%TYPE; -- 22012023
    l_csticms_freight fnd_lookup_values.lookup_code%TYPE; -- 22012023
    --l_prf_access_key_sefaz VARCHAR2(1) := NVL(fnd_profile.VALUE('CLL_F189_VAL_ACCESS_KEY_IN_SEFAZ'),'N'); -- 21909282 -- 23010041
    -- ER 21804594 - Start
    l_icms_fcp_amount            cll_f189_invoices.icms_fcp_amount%TYPE;
    l_icms_sharing_dest_amount   cll_f189_invoices.icms_sharing_dest_amount%TYPE;
    l_icms_sharing_source_amount cll_f189_invoices.icms_sharing_source_amount%TYPE;
    -- ER 21804594 - End
    l_exists_service_type       NUMBER; -- ER 22370431
    l_fundersul_amount          NUMBER; -- BUG 17056156
    l_destination_type_code     po_distributions_all.destination_type_code%type; -- 22984164
    l_project_exists            NUMBER; -- 22984164
    l_close_line_po             NUMBER; -- 23491406
    l_cno_exists                NUMBER; -- 24325307
    l_cno_id_exists             NUMBER; -- 24325307
    l_cno_number_exists         NUMBER; -- 24325307
    l_cno_operating_unit        org_organization_definitions.operating_unit%TYPE; -- 24325307
    l_inss_aut_max_ret          cll_f189_parameters.inss_autonomous_max_retention%TYPE; -- 24758216
    l_inss_max_remuner_contrib  cll_f189_parameters.inss_max_remuner_contrib%TYPE; -- 29526046
    l_lp_inss_rate_max_ret      cll_f189_parameters.lp_inss_rate_max_retention%TYPE; -- 25808200 - 25808214
    l_count_service_class       NUMBER := 0; -- 27859902
    l_item_service_type_count   NUMBER := 0; -- 25808200 - 25808214
    l_inv_total_lines           NUMBER := 0; -- 25808200 - 25808214
    l_null_item_serv_type_count NUMBER := 0; -- 25808200 - 25808214
    l_vendor_site_id            po_vendor_sites_all.vendor_site_id%TYPE; -- 25808200 - 25808214
    --
    l_hold_discrete_job NUMBER := 0; -- 24681121
----l_iss_tax_type      cll_f189_cities.iss_tax_type%TYPE; -- 25028715 ----25591653
    l_city_id           cll_f189_cities.city_id%TYPE; -- 25028715
    l_line_iss_tax_type cll_f189_cities.iss_tax_type%TYPE; -- 25028715
    l_line_city_id      cll_f189_cities.city_id%TYPE; -- 25028715
    --
    l_icms_differed_type VARCHAR2(1); -- BUG 24795936
    --
    l_manifest_status    cll_f369_efd_mfst_hist.manifest_status%TYPE; -- 17972879
    l_manifest_requested cll_f369_efd_mfst_hist.manifest_requested%TYPE; -- 17972879
    --
    v_parent_associated       NUMBER; --Gmonzano ER 25134545
    v_parent_associated_int   NUMBER; --Gmonzano ER 25134545
    v_sum_amount_lines_parent NUMBER; --Gmonzano ER 25134545
    v_sum_amount_lines_amount NUMBER; --Gmonzano ER 25134545
    l_sqlerrm                 VARCHAR2(2000); --Gmonzano ER 25134545
    l_hold                    VARCHAR2(1); -- 25713076
    l_hold_fcp                VARCHAR2(1); -- 25713076
    l_hold_fcp_st             VARCHAR2(1); -- 25713076
    --
    l_cest      fnd_lookup_values.lookup_code%TYPE; -- 25890136

-- Bug 27401206 - Start
--    l_cest_code fnd_lookup_values.lookup_code%TYPE; -- 25890136
    l_cest_code fnd_lookup_values_vl.meaning%type;
-- Bug 27401206 - End

   -- 27463767 - Start
    l_source_city_exist          NUMBER;
    l_source_ibge_city_exist     NUMBER;
    l_dest_city_exist            NUMBER;
    l_dest_ibge_city_exist       NUMBER;
    l_source_corresp_exist       NUMBER;
    l_dest_corresp_exist         NUMBER;
    --
    l_source_city_exist_f        NUMBER;
    l_source_ibge_city_exist_f   NUMBER;
    l_dest_city_exist_f          NUMBER;
    l_dest_ibge_city_exist_f     NUMBER;
    l_source_corresp_exist_f     NUMBER;
    l_dest_corresp_exist_f       NUMBER;
   -- 27463767 - End
   l_iss_city_id                 NUMBER;

    --
    /*ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)*/
    -- Variables
    v_nInvoice_total               cll_f513_tpa_returns_control.invoice_id%TYPE := 0;
    v_nRemaining_balance           cll_f513_tpa_remit_control.remaining_balance%TYPE;
    v_nReturned_quantity           cll_f513_tpa_returns_control.returned_quantity%TYPE;
    v_vhold_reason                 fnd_lookup_values.description%TYPE := 'CLL_F189_HOLD_REASON';
    v_nReturned_qty_total          cll_f513_tpa_returns_control.returned_quantity%TYPE;
    v_nQuantity_invoice_line       cll_f189_invoice_lines.quantity%TYPE;
    v_nReturned_qty_total_iface    cll_f189_invoice_lines_iface.quantity%TYPE;
    -- BUG 28247307 -- Start (WCarvalho - 20/JUL/2018)
    v_nQtd_nf_retorno_assoc_nf_rem NUMBER := 0;
    v_nSource_acct_period_id       org_acct_periods_v.acct_period_id%TYPE;
    v_dGl_date                     cll_f189_entry_operations.gl_date%TYPE;
    v_vSource_period_status        org_acct_periods_v.status%TYPE;
    v_vTransfer_period_status      org_acct_periods_v.status%TYPE;
    v_nTransfer_organization_id    cll_f513_tpa_remit_control.transfer_organization_id%TYPE;
    -- BUG 28247307 -- End (WCarvalho - 20/JUL/2018)
    /*ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)*/
    --
    l_nApproval_receipt_entry NUMBER := 0;                                         -- 28172729
    l_nCust_acct_site_id      cll_f189_fiscal_entities_all.cust_acct_site_id%TYPE; -- 28172729

    l_payment_method_indicator fnd_lookup_values_vl.meaning%TYPE; -- 28592012
    l_payment_method           fnd_lookup_values_vl.meaning%TYPE; -- 28592012

    l_lkp_freight_mode         fnd_lookup_values_vl.meaning%TYPE; -- 29338175
    l_lkp_ref_doc_type         fnd_lookup_values_vl.meaning%TYPE; -- 29480917
    l_lkp_src_doc_type         fnd_lookup_values_vl.meaning%TYPE; -- 29480917

	l_qtd_devolution           NUMBER ;       -- BUG 28496313
	l_insert_hold_dev          VARCHAR2(01) ; -- BUG 28496313
	l_valid_pkg                NUMBER ;       -- BUG 30056823
	l_exist_cfop_err           NUMBER ;       -- BUG 30056823
    l_devol_qtde               NUMBER ;       -- BUG 30056823
    --
	l_count_cfo_err            NUMBER ;       -- BUG 30789077
	l_verify_hold_cfo_tpa      VARCHAR2(01) ; -- BUG 30789077
	l_cfo_id_tpa               NUMBER ;       -- BUG 30789077
	--
    -- Bug 12352184 - GGarcia - 02/06/2011 - Inicio
    CURSOR cx_lines IS
      SELECT cfi.invoice_id, cfil.invoice_line_id, cfil.line_location_id
        FROM cll_f189_invoices cfi, cll_f189_invoice_lines cfil
       WHERE cfi.invoice_id = cfil.invoice_id
         AND cfi.organization_id = cfil.organization_id
         AND cfi.operation_id = p_operation_id
         AND cfi.organization_id = p_organization_id
         AND cfil.line_location_id IS NOT NULL
         AND p_interface = 'N';
    --
    -- Bug 12352184 - GGarcia - 02/06/2011 - Fim
    CURSOR c_freight IS
      SELECT pll.line_location_id         line_location_id,
             ph.fob_lookup_code           fob_lookup_code,
             ri.invoice_id                invoice_id,
             ri.total_fob_amount          total_fob_amount,
             ril.invoice_line_id          invoice_line_id,
             ph.freight_terms_lookup_code freight_terms_lookup_code,
             0                            interface_invoice_id,
             0                            interface_invoice_line_id,
             ri.terms_id                  terms_id_invoices,
             ph.terms_id                  terms_id_headers,
             rit.parent_flag,
             ri.fiscal_document_model, -- ER 8621766
             rit.invoice_type_id, -- ER 8621766
             NULL                         invoice_type_code, -- BUG 19722064
             ril.cfo_id, -- ER 8621766
             NULL                         cfo_code, -- BUG 19722064
             ri.series, -- ER 8621766
             ri.subseries, -- ER 10037887
             NULL                         organization_code -- BUG 19722064
        FROM cll_f189_invoices      ri,
             cll_f189_invoice_lines ril,
             cll_f189_invoice_types rit,
             po_line_locations_all  pll,
             po_headers_all         ph
       WHERE ri.invoice_type_id = rit.invoice_type_id
         AND ri.operation_id = p_operation_id
         AND ri.organization_id = p_organization_id
         AND ri.invoice_id = ril.invoice_id
         AND ril.line_location_id IS NOT NULL
         AND ril.line_location_id = pll.line_location_id
         AND pll.po_header_id = ph.po_header_id
         AND p_interface = 'N'
      UNION
      SELECT pll.line_location_id          line_location_id,
             ph.fob_lookup_code            fob_lookup_code,
             ri.invoice_id                 invoice_id,
             ri.total_fob_amount           total_fob_amount,
             0                             invoice_line_id,
             ph.freight_terms_lookup_code  freight_terms_lookup_code,
             ri.interface_invoice_id,
             ril.interface_invoice_line_id,
             ri.terms_id                   terms_id_invoices,
             ph.terms_id                   terms_id_headers,
             rit.parent_flag,
             ri.fiscal_document_model, -- ER 8621766
             rit.invoice_type_id, -- ER 8621766
             ri.invoice_type_code, -- BUG 19722064
             ril.cfo_id, -- ER 8621766
             ril.cfo_code, -- BUG 19722064
             ri.series, -- ER 8621766
             ri.subseries, -- ER 10037887
             ri.organization_code -- BUG 19722064
        FROM cll_f189_invoices_interface  ri,
             cll_f189_invoice_lines_iface ril,
             cll_f189_invoice_types       rit,
             po_line_locations_all        pll,
             po_headers_all               ph,
             org_organization_definitions ood -- BUG 19722064
       WHERE ood.organization_id = p_organization_id -- BUG 19722064
         AND ri.organization_id = ood.organization_id -- BUG 19722064
         AND (ri.invoice_type_id = rit.invoice_type_id OR -- BUG 19722064
             ri.invoice_type_code = rit.invoice_type_code) -- BUG 19722064
         AND rit.organization_id = ood.organization_id -- BUG 19722064
         AND ri.interface_operation_id = p_operation_id -- BUG 19722064
            --AND ri.organization_id       = p_organization_id       -- BUG 19722064
         AND (ri.organization_id = ood.organization_id OR -- BUG 19722064
             ri.organization_code = ood.organization_code) -- BUG 19722064
         AND ri.interface_invoice_id = ril.interface_invoice_id
         AND ril.line_location_id IS NOT NULL
         AND ril.line_location_id = pll.line_location_id
         AND pll.po_header_id = ph.po_header_id
         AND p_interface = 'Y';
    --
    CURSOR c_freight_invoices IS
      SELECT 0 interface_invoice_id,
             po_header_id,
             invoice_id,
             invoice_type_id,
             utilization_id, -- ER 7530537 - Amaciel 27/01/2009
             NULL utilization_code, -- BUG 19722064
             fiscal_document_model, -- 8621766
             series, -- 8621766
             cfo_id, -- 8621766
             NULL cfo_code, -- BUG 19722064
             tributary_status_code, -- Bug 9592789 - SSimoes - 06/05/2010
             NULL invoice_type_code, -- Bug 11874715 - GSilva - 28/3/2011
             organization_id, -- Bug 11874715 - GSilva - 28/3/2011
             icms_type, -- ER 9289619
             entity_id, -- ER 9289619
             eletronic_invoice_key, -- ER 12352413
             NVL(simplified_br_tax_flag, 'N') simplified_br_tax_flag, -- ER 9289619
             subseries, -- ER 10037887 - Dmontesino
             icms_tax_code, -- ER 13014403
             pis_tributary_code, -- Bug 15929409
             cofins_tributary_code, -- Bug 15929409
             NULL organization_code, -- BUG 19722064
             invoice_date, -- Bug 20207037
             usage_authorization -- ER 20382276
            ,source_city_id             -- 27463767
            ,destination_city_id        -- 27463767
            ,source_ibge_city_code      -- 27463767
            ,destination_ibge_city_code -- 27463767
            ,ship_to_state_id           -- 28487689 - 28597878
            ,source_state_id            -- 28487689 - 28597878
            ,destination_state_id       -- 28487689 - 28597878
            ,NVL(pis_amount_recover,0) pis_amount_recover       -- 27740002
            ,NVL(cofins_amount_recover,0) cofins_amount_recover -- 27740002
        FROM cll_f189_freight_invoices
       WHERE operation_id = p_operation_id
         AND organization_id = p_organization_id
         AND p_interface = 'N'
      UNION
      SELECT cffii.interface_invoice_id,
             cffii.po_header_id,
             0 invoice_id,
             cffii.invoice_type_id,
             cffii.utilization_id, -- ER 7530537 - Amaciel 27/01/2009
             cffii.utilization_code, -- BUG 19722064
             cffii.fiscal_document_model, -- 8621766
             cffii.series, -- 8621766
             cffii.cfo_id, -- 8621766
             cffii.cfo_code, -- BUG 19722064
             cffii.tributary_status_code, -- Bug 9592789 - SSimoes - 06/05/2010
             cffii.invoice_type_code, -- Bug 11874715 - GSilva - 28/3/2011
             cffii.organization_id, -- Bug 11874715 - GSilva - 28/3/2011
             cffii.icms_type, -- ER 9289619
             cffii.entity_id, -- ER 9289619
             cffii.eletronic_invoice_key, -- ER 12352413
             NVL(cffii.simplified_br_tax_flag, 'N') simplified_br_tax_flag, -- ER 9289619
             cffii.subseries, -- ER 10037887 - Dmontesino
             cffii.icms_tax_code, -- ER 13014403
             cffii.pis_tributary_code, -- Bug 15929409
             cffii.cofins_tributary_code, -- Bug 15929409
             cffii.organization_code, -- BUG 19722064
             cffii.invoice_date, -- Bug 20207037
             cffii.usage_authorization -- ER 20382276
            ,cffii.source_city_id             -- 27463767
            ,cffii.destination_city_id        -- 27463767
            ,cffii.source_ibge_city_code      -- 27463767
            ,cffii.destination_ibge_city_code -- 27463767
            ,cffii.ship_to_state_id           -- 28487689 - 28597878
            ,cffii.source_state_id            -- 28487689 - 28597878
            ,cffii.destination_state_id       -- 28487689 - 28597878
            ,NVL(cffii.pis_amount_recover,0) pis_amount_recover       -- 27740002
            ,NVL(cffii.cofins_amount_recover,0) cofins_amount_recover -- 27740002
        FROM cll_f189_freight_inv_interface cffii,
             org_organization_definitions   ood -- BUG 19722064
       WHERE ood.organization_id = p_organization_id -- BUG 19722064
         AND cffii.interface_operation_id = p_operation_id
            --AND cffii.organization_id      = p_organization_id       -- BUG 19722064
         AND (cffii.organization_id = ood.organization_id OR -- BUG 19722064
             cffii.organization_code = ood.organization_code) -- BUG 19722064
         AND p_interface = 'Y';
    --
    CURSOR c_invoices IS
      SELECT ri.invoice_id,
             ri.entity_id,
             NVL(ri.invoice_amount, 0) invoice_amount,
             NVL(ri.dollar_invoice_amount, 0) dollar_invoice_amount,
             ri.invoice_type_id,
             NULL invoice_type_code -- BUG 19722064
            ,
             rit.transfer_type,
             rit.requisition_type,
             NVL(ri.other_expenses, 0) other_expenses,
             NVL(ri.icms_st_amount, 0) icms_st_amount,
             NVL(ri.total_fob_amount, 0) total_fob_amount,
             ri.source_items,
             NVL(ri.freight_international, 0) freight_international,
             NVL(ri.importation_tax_amount, 0) importation_tax_amount,
             NVL(ri.importation_insurance_amount, 0) importation_insurance_amount,
             ri.icms_type,
             NVL(ri.icms_amount, 0) icms_amount,
             NVL(ri.ipi_amount, 0) ipi_amount,
             NVL(ri.ir_amount, 0) ir_amount,
             NVL(ri.icms_base, 0) icms_base,
             NVL(ri.additional_tax, 0) additional_tax,
             NVL(ri.inss_amount, 0) inss_amount,
             NVL(ri.inss_autonomous_amount, 0) inss_autonomous_amount,
             NVL(ri.inss_autonomous_invoiced_total, 0) inss_autonomous_invoiced_total -- ER 17551029 5a Fase
            ,
             NVL(ri.inss_additional_tax_1, 0) inss_additional_tax_1 -- 25808200 - 25808214
            ,
             NVL(ri.inss_additional_tax_2, 0) inss_additional_tax_2 -- 25808200 - 25808214
            ,
             NVL(ri.inss_additional_tax_3, 0) inss_additional_tax_3 -- 25808200 - 25808214
            ,
             NVL(ri.inss_additional_amount_1, 0) inss_additional_amount_1,
             NVL(ri.inss_additional_amount_2, 0) inss_additional_amount_2,
             NVL(ri.inss_additional_amount_3, 0) inss_additional_amount_3,
             ri.ir_vendor,
             ri.invoice_date,
             NVL(ri.alternate_currency_conv_rate, 0) alternate_currency_conv_rate
             -- ER 8633459 - Inicio --
             -- rbv.inss_substitute_flag,
            ,
             DECODE(NVL(v_fed_withholding_tax_flag, 'C'),
                    'I',
                    rit.inss_substitute_flag,
                    rbv.inss_substitute_flag) inss_substitute_flag
             -- ER 8633459 - Fim --
            ,
             NVL(ri.icms_st_base, 0) icms_st_base,
             NVL(rit.project_flag, 'N') project_flag,
             NVL(rit.payment_flag, 'N') payment_flag,
             rfe.document_type document_type
             --rfe.ret_cust_acct_site_id ret_cust_acct_site_id, -- AIrmer 26/05/2008
            ,
             rfe.cust_acct_site_id cust_acct_site_id,
             ri.invoice_id interface_invoice_id --,0 interface_invoice_id   -- Bug 4658115 AIrmer 14/10/2005
            ,
             rit.price_adjust_flag,
             rit.tax_adjust_flag,
             rit.parent_flag,
             NVL(ri.funrural_amount, 0) funrural_amount,
             NVL(ri.funrural_tax, 0) funrural_tax -- ER 17551029
            ,
             NVL(ri.social_security_contrib_tax, 0) social_security_contrib_tax -- ER 17551029
            ,
             NVL(ri.gilrat_tax, 0) gilrat_tax -- ER 17551029
            ,
             NVL(ri.senar_tax, 0) senar_tax -- ER 17551029
            ,
             NVL(ri.sest_senat_tax, 0) sest_senat_tax -- 25808200 - 25808214
            ,
             ri.sest_tax -- 25808200 - 25808214
            ,
             ri.senat_tax -- 25808200 - 25808214
            ,
            -- 27153706 - Start
            ri.social_security_contrib_amount,
            ri.gilrat_amount,
            ri.senar_amount,
            ri.sest_amount,
            ri.senat_amount,
            -- 27153706 - End
             NVL(rit.include_sest_senat_flag, 'N') include_sest_senat_flag, -- 25808200 - 25808214
             NVL(ri.lp_inss_rate, 0) lp_inss_rate,                          -- 25808200 - 25808214
             NVL(ri.lp_inss_base_amount, 0) lp_inss_base_amount,            -- 27859902
             NVL(ri.lp_inss_amount, 0) lp_inss_amount,                      -- 27859902
             NVL(ri.sest_senat_amount, 0) sest_senat_amount,
             rit.funrural_ccid funrural_ccid,
             rit.sest_senat_ccid sest_senat_ccid,
             rit.pis_flag pis_flag,
             rit.pis_code_combination_id pis_ccid,
             rit.collect_pis_ccid,                -- 27206522
             rit.collect_cofins_ccid,             -- 27740002
             rit.contab_flag,                     -- 27740002
             rit.cofins_flag cofins_flag,
             rit.cofins_code_combination_id cofins_ccid,
             rit.import_icms_flag import_icms_flag,
             NVL(rit.cost_adjust_flag, 'N') cost_adjust_flag,
             NVL(rit.fixed_assets_flag, 'N') fixed_assets_flag,
             NVL(rit.return_customer_flag, 'N') return_customer_flag,
             NVL(rit.generate_return_invoice, 'N') generate_return_invoice,
             ri.user_defined_conversion_rate user_defined_conversion_rate,
             rit.variation_cost_devolution_ccid,
             ri.iss_city_id,
             rit.include_iss_flag,
             ri.invoice_num,
             ri.series,
             ri.subseries -- ER 10037887
            ,
             NVL(ri.pis_cofins_st_base, 0) pis_cofins_st_base,
             NVL(ri.pis_st_amount, 0) pis_st_amount,
             NVL(ri.cofins_st_amount, 0) cofins_st_amount,
             rit.exclude_icms_st_flag,
             ri.importation_pis_amount,
             ri.importation_cofins_amount,
             ri.dollar_importation_pis_amount,
             ri.dollar_import_cofins_amount,
             ri.importation_cide_amount -- 25341463
            ,
             ri.dollar_import_cide_amount -- 25341463
            ,
             rit.import_pis_ccid,
             rit.import_cofins_ccid,
             NVL(ri.po_currency_code, '@@@') po_currency_code -- Bug.4491025
            ,
             rit.permanent_active_credit_flag -- ERancement 4378189 AIrmer 27/07/2005
            ,
             ri.importation_number -- Bug 4585347 SSimoes 01/09/2005
            ,
             ri.presumed_icms_tax_amount -- ER 5089320 --
            ,
             NVL(ri.iss_amount, 0) iss_amount -- ER 6519914 - SSimoes - 15/05/2008
            ,
             NVL(ri.iss_base, 0) iss_base -- ER 6519914 - SSimoes - 15/05/2008
            ,
             ri.vehicle_seller_doc_number -- ER 7247503 - SPED FISCAL --
            ,
             ri.vehicle_seller_state_id -- ER 14743184
            ,
             NVL(rit.complex_service_flag, 'N') complex_service_flag -- ER 7483063 AIrmer 16/04/2009
            ,
             ri.freight_amount -- BUG 8610403
            ,
             ri.insurance_amount -- BUG 8610403
            ,
             ri.fiscal_document_model -- ER 8621766
            ,
             rit.inss_calculation_flag -- Bug 9156266 - SSimoes - 26/11/2009
            ,
             rit.inss_tax -- Bug 9156266 - SSimoes - 26/11/2009
            ,
             rbv.inss_tax comp_inss_tax -- ER 14630226
            ,
             ri.inss_tax inv_inss_tax -- ER 14630226
            ,
             rit.inss_autonomous_tax -- Bug 9156266 - SSimoes - 26/11/2009
            ,
             rit.freight_flag -- ER 9289619
            ,
             ri.eletronic_invoice_key -- ER 12352413
            ,
             nvl(ri.simplified_br_tax_flag, 'N') simplified_br_tax_flag -- ER 9289619
            ,
             NVL(ri.max_icms_amount_recover, 0) max_icms_amount_recover -- ER 9289619
            ,
             rit.cr_code_combination_id -- Bug 12898953/Bug 12403264
            ,
             rit.ir_code_combination_id -- Bug 12898953/Bug 12403264
            ,
             rit.icms_code_combination_id -- Bug 12898953/Bug 12403264
            ,
             rit.iss_code_combination_id -- Bug 12898953/Bug 12403264
            ,
             rit.ipi_code_combination_id -- Bug 12898953/Bug 12403264
            ,
             rit.diff_icms_code_combination_id -- Bug 12898953/Bug 12403264
             --,rit.document_type document_type_inv               -- Bug 13947775 -- ER 13687710
            ,
             ri.income_code income_code -- ER 10091174
            ,
             rit.income_code rit_income_code -- ER 10091174
            ,
             rbv.income_code rbv_income_code -- ER 10091174
            ,
             ri.organization_id -- ER 14622175 (2)
            ,
             ri.cei_number -- ER 17551029 5a Fase
            ,
             ri.caepf_number -- ER 17551029 5a Fase
            ,
             ri.worker_category_id -- ER 17551029 5a Fase
            ,
            ri.department_id       -- 27357141
            ,
            ri.sest_senat_income_code sest_senat_income_code -- ER 9923702
            ,
             ri.funrural_income_code funrural_income_code -- ER 9923702
            ,
             ri.return_cfo_id -- Bug 17835378
            ,
             NULL organization_code -- BUG 19722064
            ,
             ri.import_other_val_not_icms -- BUG 20450226
            ,
             ri.import_other_val_included_icms -- BUG 20450226
            ,
             ri.carrier_document_type -- ER 20404053
            ,
             ri.carrier_document_number -- ER 20404053
            ,
             ri.carrier_state_id -- ER 20404053
            ,
             ri.carrier_ie -- ER 20404053
            ,
             UPPER(ri.carrier_vehicle_plate_num) carrier_vehicle_plate_num -- ER 20404053
            ,
             ri.usage_authorization -- ER 20382276
            ,
             ri.dar_payment_date -- ER 20382276
            ,
             ri.first_alternative_rate -- ER 20608903
            ,
             ri.second_alternative_rate -- ER 20608903
             -- ER 21804594 - Start
            ,
             rit.rec_diff_icms_rma_source_ccid,
             rit.rec_diff_icms_rma_dest_ccid,
             rit.diff_icms_rma_source_red_ccid -- 26538915
            ,
             rit.diff_icms_rma_dest_red_ccid -- 26538915
            ,
             rit.rec_fcp_rma_ccid,
             NULL                              destination_state_code -- 23314229
            ,
             ri.destination_state_id,
             ri.icms_fcp_amount,
             ri.icms_sharing_dest_amount,
             ri.icms_sharing_source_amount
             -- ER 21804594 - End
            ,
             rit.rec_fcp_st_rma_ccid -- 25713076
            ,
             rit.fcp_liability_ccid -- 25713076
            ,
             rit.fcp_asset_ccid -- 25713076
            ,
             rit.fcp_st_liability_ccid -- 25713076
            ,
             rit.fcp_st_asset_ccid -- 25713076
            ,
             NVL(ri.total_fcp_amount, 0) total_fcp_amount -- 25713076
            ,
             NVL(ri.total_fcp_st_amount, 0) total_fcp_st_amount -- 25713076
            ,
             ri.ip_inss_net_amount -- 24758216
            ,
             rit.composition_invoice_flag -- Gmonzano ER 5134545
            ,
             rit.red_fcp_rma_ccid         -- bug 26880062 26880945
            ,
             rit.red_fcp_st_rma_ccid      -- bug 26880062 26880945
            ,ri.source_city_id             -- 27463767
            ,ri.destination_city_id        -- 27463767
            ,ri.source_ibge_city_code      -- 27463767
            ,ri.destination_ibge_city_code -- 27463767
            ,ri.ship_to_state_id           -- 28487689 - 28597878
            ,ri.source_state_id            -- 28487689 - 28597878
            ,ri.freight_mode               -- 29338175
            ,rit.import_expense_rma_ccid   -- 29688781
        FROM cll_f189_invoices            ri,
             cll_f189_invoice_types       rit,
             cll_f189_fiscal_entities_all rfe,
             cll_f189_business_vendors    rbv
       WHERE ri.organization_id = p_organization_id
         AND ri.invoice_type_id = rit.invoice_type_id
         AND rit.organization_id = ri.organization_id
         AND ri.operation_id = p_operation_id
         AND ri.organization_id = p_organization_id
         AND ri.entity_id = rfe.entity_id
         AND rfe.business_vendor_id = rbv.business_id
         AND p_interface = 'N'
      UNION
      SELECT ri.interface_invoice_id invoice_id, -- ri.invoice_id    -- Bug 4658115 AIrmer 14/10/2005
             ri.entity_id,
             NVL(ri.invoice_amount, 0) invoice_amount,
             NVL(ri.dollar_invoice_amount, 0) dollar_invoice_amount,
             ri.invoice_type_id,
             ri.invoice_type_code, -- BUG 19722064
             rit.transfer_type,
             rit.requisition_type,
             NVL(ri.other_expenses, 0) other_expenses,
             NVL(ri.icms_st_amount, 0) icms_st_amount,
             NVL(ri.total_fob_amount, 0) total_fob_amount,
             ri.source_items,
             NVL(ri.freight_international, 0) freight_international,
             NVL(ri.importation_tax_amount, 0) importation_tax_amount,
             NVL(ri.importation_insurance_amount, 0) importation_insurance_amount,
             ri.icms_type,
             NVL(ri.icms_amount, 0) icms_amount,
             NVL(ri.ipi_amount, 0) ipi_amount,
             NVL(ri.ir_amount, 0) ir_amount,
             NVL(ri.icms_base, 0) icms_base,
             NVL(ri.additional_tax, 0) additional_tax,
             NVL(ri.inss_amount, 0) inss_amount,
             NVL(ri.inss_autonomous_amount, 0) inss_autonomous_amount,
             NVL(ri.inss_autonomous_invoiced_total, 0) inss_autonomous_invoiced_total, -- ER 17551029 5a Fase
             NVL(ri.inss_additional_tax_1, 0) inss_additional_tax_1, -- 25808200 - 25808214
             NVL(ri.inss_additional_tax_2, 0) inss_additional_tax_2, -- 25808200 - 25808214
             NVL(ri.inss_additional_tax_3, 0) inss_additional_tax_3, -- 25808200 - 25808214
             NVL(ri.inss_additional_amount_1, 0) inss_additional_amount_1,
             NVL(ri.inss_additional_amount_2, 0) inss_additional_amount_2,
             NVL(ri.inss_additional_amount_3, 0) inss_additional_amount_3,
             ri.ir_vendor,
             ri.invoice_date,
             NVL(ri.alternate_currency_conv_rate, 0) alternate_currency_conv_rate,
             -- ER 8633459 - Inicio --
             -- rbv.inss_substitute_flag,
             DECODE(NVL(v_fed_withholding_tax_flag, 'C'),
                    'I',
                    rit.inss_substitute_flag,
                    rbv.inss_substitute_flag) inss_substitute_flag,
             -- ER 8633459 - Fim --
             NVL(ri.icms_st_base, 0) icms_st_base,
             NVL(rit.project_flag, 'N') project_flag,
             NVL(rit.payment_flag, 'N') payment_flag,
             rfe.document_type document_type,
             --rfe.ret_cust_acct_site_id ret_cust_acct_site_id, -- AIrmer 26/05/2008
             rfe.cust_acct_site_id cust_acct_site_id, -- AIrmer 26/05/2008
             ri.interface_invoice_id,
             rit.price_adjust_flag,
             rit.tax_adjust_flag,
             rit.parent_flag,
             NVL(ri.funrural_amount, 0) funrural_amount, -- Bug 4376170
             NVL(ri.funrural_tax, 0) funrural_tax, -- ER 17551029
             NVL(ri.social_security_contrib_tax, 0) social_security_contrib_tax, -- ER 17551029
             NVL(ri.gilrat_tax, 0) gilrat_tax, -- ER 17551029
             NVL(ri.senar_tax, 0) senar_tax, -- ER 17551029
             NVL(ri.sest_senat_tax, 0) sest_senat_tax, -- 25808200 - 25808214
             ri.sest_tax, -- 25808200 - 25808214
             ri.senat_tax, -- 25808200 - 25808214
             -- 27153706 - Start
             ri.social_security_contrib_amount,
             ri.gilrat_amount,
             ri.senar_amount,
             ri.sest_amount,
             ri.senat_amount,
             -- 27153706 - End
             NVL(rit.include_sest_senat_flag, 'N') include_sest_senat_flag, -- 25808200 - 25808214
             NVL(ri.lp_inss_rate, 0) lp_inss_rate,                          -- 25808200 - 25808214
             NVL(ri.lp_inss_base_amount, 0) lp_inss_base_amount,            -- 27859902
             NVL(ri.lp_inss_amount, 0) lp_inss_amount,                      -- 27859902
             NVL(ri.sest_senat_amount, 0) sest_senat_amount, -- Bug 4376170
             rit.funrural_ccid funrural_ccid,
             rit.sest_senat_ccid sest_senat_ccid,
             rit.pis_flag pis_flag,
             rit.pis_code_combination_id pis_ccid,
             rit.collect_pis_ccid,                -- 27206522
             rit.collect_cofins_ccid,             -- 27740002
             rit.contab_flag,                     -- 27740002
             rit.cofins_flag cofins_flag,
             rit.cofins_code_combination_id cofins_ccid,
             rit.import_icms_flag import_icms_flag,
             NVL(rit.cost_adjust_flag, 'N') cost_adjust_flag,
             NVL(rit.fixed_assets_flag, 'N') fixed_assets_flag,
             NVL(rit.return_customer_flag, 'N') return_customer_flag,
             NVL(rit.generate_return_invoice, 'N') generate_return_invoice,
             ri.user_defined_conversion_rate user_defined_conversion_rate,
             rit.variation_cost_devolution_ccid,
             ri.iss_city_id,
             rit.include_iss_flag,
             ri.invoice_num,
             ri.series,
             ri.subseries, -- ER 10037887
             0 pis_cofins_st_base,
             0 pis_st_amount,
             0 cofins_st_amount,
             rit.exclude_icms_st_flag,
             ri.importation_pis_amount,
             ri.importation_cofins_amount,
             dollar_importation_pis_amount,
             dollar_import_cofins_amount,
             ri.importation_cide_amount,   -- 25341463
             ri.dollar_import_cide_amount, -- 25341463
             rit.import_pis_ccid,
             rit.import_cofins_ccid,
             NVL(ri.po_currency_code, '@@@') po_currency_code, -- Bug.4491025
             rit.permanent_active_credit_flag, -- ERancement 4378189 AIrmer 27/07/2005
             ri.importation_number, -- Bug 4585347 SSimoes 01/09/2005
             ri.presumed_icms_tax_amount, -- ER 5089320 --
             NVL(ri.iss_amount, 0) iss_amount, -- ER 6519914 - SSimoes - 15/05/2008
             NVL(ri.iss_base, 0) iss_base, -- ER 6519914 - SSimoes - 15/05/2008
             ri.vehicle_seller_doc_number, -- ER 7247503 - SPED FISCAL --
             ri.vehicle_seller_state_id, -- ER 14743184
             NVL(rit.complex_service_flag, 'N') complex_service_flag, -- ER 7483063 AIrmer 16/04/2009
             ri.freight_amount, -- BUG 8610403
             ri.insurance_amount, -- BUG 8610403
             ri.fiscal_document_model, -- ER 8621766
             rit.inss_calculation_flag, -- Bug 9156266 - SSimoes - 26/11/2009
             rit.inss_tax, -- Bug 9156266 - SSimoes - 26/11/2009
             rbv.inss_tax comp_inss_tax, -- ER 14630226
             ri.inss_tax inv_inss_tax, -- ER 14630226
             rit.inss_autonomous_tax, -- Bug 9156266 - SSimoes - 26/11/2009
             rit.freight_flag, -- ER 9289619
             ri.eletronic_invoice_key, -- ER 12352413
             nvl(ri.simplified_br_tax_flag, 'N') simplified_br_tax_flag, -- ER 9289619
             NVL(ri.max_icms_amount_recover, 0) max_icms_amount_recover, -- ER 9289619
             rit.cr_code_combination_id, -- Bug 12898953/Bug 12403264
             rit.ir_code_combination_id, -- Bug 12898953/Bug 12403264
             rit.icms_code_combination_id, -- Bug 12898953/Bug 12403264
             rit.iss_code_combination_id, -- Bug 12898953/Bug 12403264
             rit.ipi_code_combination_id, -- Bug 12898953/Bug 12403264
             rit.diff_icms_code_combination_id, -- Bug 12898953/Bug 12403264
             -- ,rit.document_type document_type_inv                 -- Bug 13947775 -- ER 13687710
             ri.income_code income_code, -- ER 10091174
             rit.income_code rit_income_code, -- ER 10091174
             rbv.income_code rbv_income_code, -- ER 10091174
             ri.organization_id, -- ER 14622175 (2)
             NULL cei_number, -- ER 17551029 5a Fase
             ri.caepf_number, -- ER 17551029 5a Fase
             ri.worker_category_id, -- ER 17551029 5a Fase
             ri.department_id,       -- 27357141
             ri.sest_senat_income_code sest_senat_income_code, -- ER 9923702
             ri.funrural_income_code funrural_income_code, -- ER 9923702
             ri.return_cfo_id, -- Bug 17835378
             ri.organization_code, -- BUG 19722064
             ri.import_other_val_not_icms, -- BUG 20450226
             ri.import_other_val_included_icms, -- BUG 20450226
             ri.carrier_document_type, -- ER 20404053
             ri.carrier_document_number, -- ER 20404053
             ri.carrier_state_id, -- ER 20404053
             ri.carrier_ie, -- ER 20404053
             UPPER(ri.carrier_vehicle_plate_num) carrier_vehicle_plate_num, -- ER 20404053
             ri.usage_authorization, -- ER 20382276
             ri.dar_payment_date, -- ER 20382276
             ri.first_alternative_rate, -- ER 20608903
             ri.second_alternative_rate, -- ER 20608903
             -- ER 21804594 - Start
             rit.rec_diff_icms_rma_source_ccid,
             rit.rec_diff_icms_rma_dest_ccid,
             rit.diff_icms_rma_source_red_ccid, -- 26538915
             rit.diff_icms_rma_dest_red_ccid, -- 26538915
             rit.rec_fcp_rma_ccid,

             -- 23314229 - Start
             ri.destination_state_code,
             DECODE(ri.destination_state_id,
                    NULL,
                    re.state_id,
                    ri.destination_state_id) destination_state_id,
             -- 23314229 - End
             ri.icms_fcp_amount,
             ri.icms_sharing_dest_amount,
             ri.icms_sharing_source_amount,
             -- ER 21804594 - End
             rit.rec_fcp_st_rma_ccid, -- 25713076
             rit.fcp_liability_ccid, -- 25713076
             rit.fcp_asset_ccid, -- 25713076
             rit.fcp_st_liability_ccid, -- 25713076
             rit.fcp_st_asset_ccid, -- 25713076
             NVL(ri.total_fcp_amount, 0) total_fcp_amount, -- 25713076
             NVL(ri.total_fcp_st_amount, 0) total_fcp_st_amount, -- 25713076
             ri.ip_inss_net_amount,        -- 24758216
             rit.composition_invoice_flag, -- Gmonzano ER 5134545
             rit.red_fcp_rma_ccid,         -- bug 26880062 26880945
             rit.red_fcp_st_rma_ccid       -- bug 26880062 26880945
            ,ri.source_city_id             -- 27463767
            ,ri.destination_city_id        -- 27463767
            ,ri.source_ibge_city_code      -- 27463767
            ,ri.destination_ibge_city_code -- 27463767
            ,ri.ship_to_state_id           -- 28487689 - 28597878
            ,ri.source_state_id            -- 28487689 - 28597878
            ,ri.freight_mode               -- 29338175
            ,rit.import_expense_rma_ccid   -- 29688781
        FROM cll_f189_invoices_interface  ri,
             cll_f189_invoice_types       rit,
             cll_f189_fiscal_entities_all rfe,
             cll_f189_business_vendors    rbv,
             org_organization_definitions ood,
             cll_f189_states              re -- 23314229
       WHERE ood.organization_id = p_organization_id -- BUG 19722064
         AND (ri.invoice_type_id = rit.invoice_type_id OR -- BUG 19722064
             ri.invoice_type_code = rit.invoice_type_code) -- BUG 19722064
         AND (ri.organization_id = ood.organization_id OR -- BUG 19722064
             ri.organization_code = ood.organization_code) -- BUG 19722064
         AND rit.organization_id = ood.organization_id -- BUG 19722064
         AND ri.interface_operation_id = p_operation_id
            -- AND ri.organization_id      = p_organization_id                     -- BUG 19722064
         AND ri.entity_id = rfe.entity_id
         AND rfe.business_vendor_id = rbv.business_id
            --AND re.state_code             = ri.destination_state_code              -- 23314229 -- 23491406
         AND (ri.destination_state_id = re.state_id OR -- 23491406
             ri.destination_state_code = re.state_code) -- 23491406
         AND p_interface = 'Y';
    --
    CURSOR c_invoice_lines IS
      SELECT ri.invoice_id,
             ril.invoice_line_id,
             ril.item_id,
             ril.db_code_combination_id,
             ril.line_location_id,
             ril.requisition_line_id,
             NVL(ril.quantity, 0) quantity,
             NVL(ril.ipi_tax, 0) ipi_tax,
             NVL(ri.invoice_amount, 0) invoice_amount,
             NVL(ri.dollar_invoice_amount, 0) dollar_invoice_amount,
             NVL(ril.dollar_unit_price, 0) dollar_unit_price,
             ri.invoice_type_id,
             NULL invoice_type_code, -- BUG 19722064
             rit.transfer_type,
             ri.invoice_id interface_invoice_id --,0 interface_invoice_id  -- Bug 4658115 AIrmer 14/10/2005
            ,
             ril.invoice_line_id interface_invoice_line_id --0 interface_invoice_line_id -- Bug 4658115 AIrmer 14/10/2005
            ,
             rit.foreign_currency_usage,
             rit.return_customer_flag,
             rfo.cfo_code,
             NVL(ril.ipi_base_amount, 0) ipi_base_amount,
             ri.invoice_num,
             ri.series,
             rit.generate_return_invoice,
             ril.icms_base -- Bug 4115240
            ,
             ril.icms_amount -- Bug 4115240
            ,
             rit.requisition_type -- Bug 4378861
            ,
             rit.tax_adjust_flag -- 22966523
            ,
             rit.parent_flag -- Bug 4378861
            ,
             ril.pis_amount_recover -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ril.cofins_amount_recover -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ril.utilization_id -- ERancement 4533742 AIrmer 12/08/2005
            ,
             NULL utilization_code
             --  ,riu.recover_pis_flag_cnpj    -- ERancement 4533742 AIrmer 12/08/2005   -- 02/09/2005
             --  ,riu.recover_pis_flag_cpf     -- ERancement 4533742 AIrmer 12/08/2005  -- 02/09/2005
             --  ,riu.recover_cofins_flag_cnpj -- ERancement 4533742 AIrmer 12/08/2005  -- 02/09/2005
             --  ,riu.recover_cofins_flag_cpf  -- ERancement 4533742 AIrmer 12/08/2005  -- 02/09/2005
            ,
             rit.pis_flag -- ERancement 4533742 AIrmer 12/08/2005
            ,
             rit.cofins_flag -- ERancement 4533742 AIrmer 12/08/2005
             -- ,rfe.document_type            -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ri.invoice_date -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ri.entity_id,
             ril.presumed_icms_tax_amount -- ER 5089320 --
            ,
             ril.rma_interface_id -- Bug 5951443 SSimoes 10/04/2007
            ,
---          NVL(ril.iss_base_amount, 0) iss_base_amount -- ER 6519914 - SSimoes - 15/05/2008 ---25591653
             ril.iss_base_amount                         -- ER 6519914 - SSimoes - 15/05/2008 ---25591653
            ,
---          NVL(ril.iss_tax_amount, 0) iss_tax_amount -- ER 6519914 - SSimoes - 15/05/2008   ---25591653
             ril.iss_tax_amount                        -- ER 6519914 - SSimoes - 15/05/2008   ---25591653
            ,
---          NVL(ril.iss_tax_rate, 0) iss_tax_rate -- 25028715  ---25591653
             ril.iss_tax_rate                      -- 25028715  ---25591653
            ,
             rit.include_iss_flag -- 25028715
            ,
             NVL(rit.complex_service_flag, 'N') complex_service_flag -- ER 7483063 AIrmer 16/04/2009
            ,
             NVL(ril.total_amount, 0) total_amount -- ER 7483063 AIrmer 16/04/2009
            ,
             ril.ipi_tributary_code -- Bug 8511032 AIrmer 19/05/2009
            ,
             ril.ipi_tributary_type -- 22073362
            ,
             NVL(rit.ipi_tributary_code_flag, 'N') ipi_tributary_code_flag -- Bug 8511032 AIrmer 19/05/2009
            ,
             rfo.cfo_id -- ER 8621766
            ,
             ril.tributary_status_code -- ER 8621766
            ,
             ril.pis_tributary_code -- ER 8621766
            ,
             ril.cofins_tributary_code -- ER 8621766
            ,
             rit.operation_type -- ER 8553947 - SSimoes - 21/10/2009
            ,
             null document_type -- Bug 9597256
            ,
             null document_number -- Bug 9597256
            ,
             null ie -- Bug 9597256
            ,
             rfo.icms_trib_code_required_flag -- ER 9981342 - GSilva - 29/09/2010
            ,
             rit.include_icms_flag -- ER 9981342 - GSilva - 29/09/2010
            ,
             rit.include_ipi_flag -- ER 9955304 - GSilva - 30/09/2010
            ,
             ril.awt_group_id -- ER 9072748
            ,
             ril.pis_qty -- ER 10367032
            ,
             ril.pis_unit_amount -- ER 10367032
            ,
             ril.pis_base_amount -- ER 10367032
            ,
             ril.pis_tax_rate -- ER 10367032
            ,
             ril.cofins_qty -- ER 10367032
            ,
             ril.cofins_unit_amount -- ER 10367032
            ,
             ril.cofins_base_amount -- ER 10367032
            ,
             ril.cofins_tax_rate -- ER 10367032
            ,
             ril.icms_tax_code -- ER 10037887
            ,
             ril.ipi_tax_code -- ER 10037887
            ,
             ril.city_service_type_rel_id -- ER 10037887
            ,
             ril.uom -- ER 1182206
            ,
             ril.vehicle_oper_type -- ER 14743184
            ,
             ril.cest_code -- 25890136
            ,
             ril.customs_total_value -- ER 16755312
            ,
             ril.ci_percent -- ER 16755312
            ,
             ril.total_import_parcel -- ER 16755312
            ,
             ril.fci_number -- ER 16755312
            ,
             ri.cno_id -- 24325307
            ,
             ri.cno_number -- ER 17551029 5a Fase
            ,
             ril.operation_fiscal_type -- ER 19597186
            ,
             NULL organization_code -- BUG 19722064
            ,
             ril.icms_type -- ER 9028781
            ,
             NVL(ril.max_icms_amount_recover, 0) max_icms_amount_recover -- ER 9028781
             -- Bug 20145693 - Start
            ,
             ril.recopi_number recopi_full_number,
             SUBSTR(TO_CHAR(ril.recopi_number), 19, 2) recopi_digits,
             TO_NUMBER(SUBSTR(TO_CHAR(ril.recopi_number), 1, 4)) recopi_year,
             TO_NUMBER(SUBSTR(TO_CHAR(ril.recopi_number), 1, 6)) recopi_monthyear
             --,TO_NUMBER(SUBSTR(TO_CHAR(ril.recopi_number),9,6))  recopi_time -- 22757526
            ,
             TO_CHAR(SUBSTR(TO_CHAR(ril.recopi_number), 9, 6)) recopi_time -- 22757526
            ,
             SUBSTR(TO_CHAR(ril.recopi_number), 1, 18) recopi_number
             -- Bug 20145693 - End
            ,
             ril.item_number -- 21645107
             -- ER 21804594 - Start
            ,
             rit.rec_diff_icms_rma_source_ccid,
             rit.rec_diff_icms_rma_dest_ccid,
             rit.diff_icms_rma_source_red_ccid -- 26538915
            ,
             rit.diff_icms_rma_dest_red_ccid -- 26538915
            ,
             rit.rec_fcp_rma_ccid,
             NULL                              destination_state_code -- 23314229
            ,
             ri.destination_state_id,
             ril.icms_dest_base_amount,
             ril.icms_fcp_dest_perc,
             ril.icms_dest_tax,
             ril.icms_sharing_inter_perc,
             ril.icms_fcp_amount,
             ril.icms_sharing_dest_amount,
             ril.icms_sharing_source_amount,
             ri.icms_type                      invoice_icms_type
             -- ER 21804594 - End
            ,
             rit.rec_fcp_st_rma_ccid -- 25713076
            ,
             rit.fcp_liability_ccid -- 25713076
            ,
             rit.fcp_asset_ccid -- 25713076
            ,
             rit.fcp_st_liability_ccid -- 25713076
            ,
             rit.fcp_st_asset_ccid -- 25713076
            ,
             ril.deferred_icms_amount -- BUG 24795936
             -- BUG 25341463 - Start
            ,
             ril.cide_base_amount,
             ril.cide_rate,
             ril.cide_amount,
             ril.cide_amount_recover,
             rit.cide_code_combination_id
             -- BUG 25341463 - End
             --
             -- 25713076 - Start
            ,
             ril.fcp_base_amount,
             ril.fcp_rate,
             ril.fcp_amount,
             ril.fcp_st_base_amount,
             ril.fcp_st_rate,
             ril.fcp_st_amount,
             ril.significant_scale_prod_ind,
             ril.manufac_goods_doc_number,
             ril.med_maximum_price_consumer,
             ril.anvisa_product_code,
           --ril.lot_number,         -- 26987509 - 26986232
             ril.product_lot_number, -- 26987509 - 26986232
             ril.lot_quantity,
             ril.production_date,
             ril.expiration_date,
             /*ER 26338366/26899224 -- Start (WCarvalho - 30/OCT/2017)*/
             ri.location_id,
            /*BUG 27796521 -- Start (WCarvalho - 18/APR/2018)*/
           --NVL(rfo.tpa_control_flag, 'N') tpa_control_flag,
            /*BUG 27796521 -- End (WCarvalho - 18/APR/2018)*/
            /*ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)*/
            /*BUG 27796521 -- Start (WCarvalho - 18/APR/2018)*/
             rfo.tpa_control_type,
             /*BUG 27796521 -- End (WCarvalho - 18/APR/2018)*/
             -- 25713076 - End
             rit.red_fcp_rma_ccid,      -- bug 26880062 26880945
             rit.red_fcp_st_rma_ccid,   -- bug 26880062 26880945
             nvl(ri.simplified_br_tax_flag, 'N') simplified_br_tax_flag,
             NVL(ril.iss_fo_base_amount,0) iss_fo_base_amount, -- 25591653
             NVL(ril.iss_fo_tax_rate,0)    iss_fo_tax_rate,    -- 25591653
             NVL(ril.iss_fo_amount,0)      iss_fo_amount,      -- 25591653
             ril.iss_city_id,                                  -- 25591653
             NULL iss_city_code,                               -- 25591653
             ril.discount_amount,                              -- 28468398 - 28505834
             ril.discount_percent,                             -- 28468398 - 28505834
             ril.discount_net_amount,                          -- 28468398 - 28505834
             ril.net_amount,                                   -- 28468398 - 28505834
             ril.icms_st_prev_withheld_base,                   -- 28468398 - 28505834
             ril.icms_st_prev_withheld_tx_rate,                -- 28468398 - 28505834
             ril.icms_st_prev_withheld_amount,                 -- 28468398 - 28505834
             ril.fcp_st_prev_withheld_base,                    -- 28468398 - 28505834
             ril.fcp_st_prev_withheld_tx_rate,                 -- 28468398 - 28505834
             ril.fcp_st_prev_withheld_amount,                  -- 28468398 - 28505834
             rit.fundersul_code_combination_id,                -- 27746405
             rit.fundersul_expense_ccid,                       -- 27746405
             rit.fundersul_own_flag,                           -- 27746405
             rit.fundersul_sup_part_flag,                      -- 27746405
             ril.fundersul_amount,                             -- 27746405
             ril.fundersul_additional_amount,                  -- 27746405
             ri.fiscal_document_model          -- ER 29055483
        FROM cll_f189_invoices          ri,
             cll_f189_invoice_types     rit,
             cll_f189_invoice_lines     ril,
             cll_f189_fiscal_operations rfo
      --,cll_f189_item_utilizations riu     -- ERancement 4533742 AIrmer 12/08/2005
      --,cll_f189_fiscal_entities_all rfe   -- ERancement 4533742 AIrmer 12/08/2005
      --,cll_f189_business_vendors rbv      -- ERancement 4533742 AIrmer 12/08/2005
       WHERE ri.invoice_type_id = rit.invoice_type_id
         AND ri.organization_id = rit.organization_id
         AND ri.invoice_id = ril.invoice_id
         AND ri.operation_id = p_operation_id
         AND ri.organization_id = p_organization_id
         AND ril.cfo_id = rfo.cfo_id
            --  AND ril.utilization_id      = riu.utilization_id   -- ERancement 4533742 AIrmer 12/08/2005
            --  AND ri.entity_id            =  rfe.entity_id       -- ERancement 4533742 AIrmer 12/08/2005
            --  AND rfe.business_vendor_id  =  rbv.business_id     -- ERancement 4533742 AIrmer 12/08/2005
         AND p_interface = 'N'
      UNION
      SELECT ri.interface_invoice_id invoice_id --ri.invoice_id  -- Bug 4658115 AIrmer 14/10/2005
            ,
             ril.interface_invoice_line_id invoice_line_id --0 invoice_line_id  -- Bug 4658115 AIrmer 14/10/2005
            ,
             ril.item_id,
             ril.db_code_combination_id,
             ril.line_location_id,
             ril.requisition_line_id,
             NVL(ril.quantity, 0) quantity,
             NVL(ril.ipi_tax, 0) ipi_tax,
             NVL(ri.invoice_amount, 0) invoice_amount,
             NVL(ri.dollar_invoice_amount, 0) dollar_invoice_amount,
             0 dollar_unit_price,
             ri.invoice_type_id,
             ri.invoice_type_code, -- BUG 19722064
             rit.transfer_type,
             ri.interface_invoice_id,
             ril.interface_invoice_line_id,
             rit.foreign_currency_usage,
             rit.return_customer_flag,
             rfo.cfo_code,
             NVL(ril.ipi_base_amount, 0) ipi_base_amount,
             ri.invoice_num,
             ri.series,
             rit.generate_return_invoice,
             ril.icms_base -- Bug 4115240
            ,
             ril.icms_amount -- Bug 4115240
            ,
             rit.requisition_type -- Bug 4378861
            ,
             rit.tax_adjust_flag -- 22966523
            ,
             rit.parent_flag -- Bug 4378861
            ,
             ril.pis_amount_recover -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ril.cofins_amount_recover -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ril.utilization_id -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ril.utilization_code
             --  ,riu.recover_pis_flag_cnpj    -- ERancement 4533742 AIrmer 12/08/2005
             --  ,riu.recover_pis_flag_cpf     -- ERancement 4533742 AIrmer 12/08/2005
             --  ,riu.recover_cofins_flag_cnpj -- ERancement 4533742 AIrmer 12/08/2005
             --  ,riu.recover_cofins_flag_cpf  -- ERancement 4533742 AIrmer 12/08/2005
            ,
             rit.pis_flag -- ERancement 4533742 AIrmer 12/08/2005
            ,
             rit.cofins_flag -- ERancement 4533742 AIrmer 12/08/2005
             --  ,rfe.document_type            -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ri.invoice_date -- ERancement 4533742 AIrmer 12/08/2005
            ,
             ri.entity_id,
             ril.presumed_icms_tax_amount -- ER 5089320 --
            ,
             ril.rma_interface_id -- Bug 5951443 SSimoes 10/04/2007
            ,
---          NVL(ril.iss_base_amount, 0) iss_base_amount -- ER 6519914 - SSimoes - 15/05/2008 ---25591653
             ril.iss_base_amount                         -- ER 6519914 - SSimoes - 15/05/2008 ---25591653
            ,
---          NVL(ril.iss_tax_amount, 0) iss_tax_amount -- ER 6519914 - SSimoes - 15/05/2008   ---25591653
             ril.iss_tax_amount                        -- ER 6519914 - SSimoes - 15/05/2008   ---25591653
            ,
---          NVL(ril.iss_tax_rate, 0) iss_tax_rate -- 25028715  ---25591653
             ril.iss_tax_rate                      -- 25028715  ---25591653
            ,
             rit.include_iss_flag -- 25028715
            ,
             NVL(rit.complex_service_flag, 'N') complex_service_flag -- ER 7483063 AIrmer 16/04/2009
            ,
             NVL(ril.total_amount, 0) total_amount -- ER 7483063 AIrmer 16/04/2009
            ,
             ril.ipi_tributary_code -- Bug 8511032 AIrmer 19/05/2009
            ,
             ril.ipi_tributary_type -- 22073362
            ,
             NVL(rit.ipi_tributary_code_flag, 'N') ipi_tributary_code_flag -- Bug 8511032 AIrmer 19/05/2009
            ,
             rfo.cfo_id -- ER 8621766
            ,
             ril.tributary_status_code -- ER 8621766
            ,
             ril.pis_tributary_code -- ER 8621766
            ,
             ril.cofins_tributary_code -- ER 8621766
            ,
             rit.operation_type -- ER 8553947 - SSimoes - 21/10/2009
            ,
             ri.document_type -- Bug 9597256
            ,
             ri.document_number -- Bug 9597256
            ,
             ri.ie -- Bug 9597256
            ,
             rfo.icms_trib_code_required_flag -- ER 9981342 - GSilva - 29/09/2010
            ,
             rit.include_icms_flag -- ER 9981342 - GSilva - 29/09/2010
            ,
             rit.include_ipi_flag -- ER 9955304 - GSilva - 30/09/2010
            ,
             ril.awt_group_id -- ER 9072748
            ,
             ril.pis_qty -- ER 10367032
            ,
             ril.pis_unit_amount -- ER 10367032
            ,
             ril.pis_base_amount -- ER 10367032
            ,
             ril.pis_tax_rate -- ER 10367032
            ,
             ril.cofins_qty -- ER 10367032
            ,
             ril.cofins_unit_amount -- ER 10367032
            ,
             ril.cofins_base_amount -- ER 10367032
            ,
             ril.cofins_tax_rate -- ER 10367032
            ,
             ril.icms_tax_code -- ER 10037887
            ,
             ril.ipi_tax_code -- ER 10037887
            ,
             ril.city_service_type_rel_id -- ER 10037887
            ,
             ril.uom -- ER 1182206
            ,
             ril.vehicle_oper_type -- ER 14743184
            ,
             ril.cest_code -- 25890136
            ,
             ril.customs_total_value -- ER 16755312
            ,
             ril.ci_percent -- ER 16755312
            ,
             ril.total_import_parcel -- ER 16755312
            ,
             ril.fci_number -- ER 16755312
            ,
             ri.cno_id -- 24325307
            ,
             ri.cno_number -- ER 17551029 5a Fase
            ,
             ril.operation_fiscal_type -- ER 19597186
            ,
             ri.organization_code -- BUG 19722064
            ,
             ril.icms_type -- ER 9028781
            ,
             NVL(ril.max_icms_amount_recover, 0) max_icms_amount_recover -- ER 9028781
             -- Bug 20145693 - Start
            ,
             ril.recopi_number recopi_full_number,
             SUBSTR(TO_CHAR(ril.recopi_number), 19, 2) recopi_digits,
             TO_NUMBER(SUBSTR(TO_CHAR(ril.recopi_number), 1, 4)) recopi_year,
             TO_NUMBER(SUBSTR(TO_CHAR(ril.recopi_number), 1, 6)) recopi_monthyear
             --,TO_NUMBER(SUBSTR(TO_CHAR(ril.recopi_number),9,6))  recopi_time -- 22757526
            ,
             TO_CHAR(SUBSTR(TO_CHAR(ril.recopi_number), 9, 6)) recopi_time -- 22757526
            ,
             SUBSTR(TO_CHAR(ril.recopi_number), 1, 18) recopi_number
             -- Bug 20145693 - End
            ,
             ril.item_number -- 21645107
             -- ER 21804594 - Start
            ,
             rit.rec_diff_icms_rma_source_ccid,
             rit.rec_diff_icms_rma_dest_ccid,
             rit.diff_icms_rma_source_red_ccid -- 26538915
            ,
             rit.diff_icms_rma_dest_red_ccid -- 26538915
            ,
             rit.rec_fcp_rma_ccid
             -- 23314229 - Start
            ,
             ri.destination_state_code,
             DECODE(ri.destination_state_id,
                    NULL,
                    re.state_id,
                    ri.destination_state_id) destination_state_id
             -- 23314229 - End
            ,
             ril.icms_dest_base_amount,
             ril.icms_fcp_dest_perc,
             ril.icms_dest_tax,
             ril.icms_sharing_inter_perc,
             ril.icms_fcp_amount,
             ril.icms_sharing_dest_amount,
             ril.icms_sharing_source_amount,
             ri.icms_type                   invoice_icms_type
             -- ER 21804594 - End
            ,
             rit.rec_fcp_st_rma_ccid -- 25713076
            ,
             rit.fcp_liability_ccid -- 25713076
            ,
             rit.fcp_asset_ccid -- 25713076
            ,
             rit.fcp_st_liability_ccid -- 25713076
            ,
             rit.fcp_st_asset_ccid -- 25713076
            ,
             ril.deferred_icms_amount -- BUG 24795936
             -- BUG 25341463 - Start
            ,
             ril.cide_base_amount,
             ril.cide_rate,
             ril.cide_amount,
             ril.cide_amount_recover,
             rit.cide_code_combination_id
             -- BUG 25341463 - End
             --
             -- 25713076 - Start
            ,
             ril.fcp_base_amount,
             ril.fcp_rate,
             ril.fcp_amount,
             ril.fcp_st_base_amount,
             ril.fcp_st_rate,
             ril.fcp_st_amount,
             ril.significant_scale_prod_ind,
             ril.manufac_goods_doc_number,
             ril.med_maximum_price_consumer,
             ril.anvisa_product_code,
           --ril.lot_number,         -- 26987509 - 26986232
             ril.product_lot_number, -- 26987509 - 26986232
             ril.lot_quantity,
             ril.production_date,
             ril.expiration_date,
             /*ER 26338366/26899224 -- Start (WCarvalho - 30/OCT/2017)*/
             ri.location_id,
             /*BUG 27796521 -- Start (WCarvalho - 18/APR/2018)*/
           --NVL(rfo.tpa_control_flag, 'N') tpa_control_flag,
            /*BUG 27796521 -- End (WCarvalho - 18/APR/2018)*/
            /*ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)*/
            /*BUG 27796521 -- Start (WCarvalho - 18/APR/2018)*/
             rfo.tpa_control_type,
            /*BUG 27796521 -- End (WCarvalho - 18/APR/2018)*/
            -- 25713076 - End
             rit.red_fcp_rma_ccid,      -- bug 26880062 26880945
             rit.red_fcp_st_rma_ccid,   -- bug 26880062 26880945
             nvl(ri.simplified_br_tax_flag, 'N') simplified_br_tax_flag,
             NVL(ril.iss_fo_base_amount,0) iss_fo_base_amount, -- 25591653
             NVL(ril.iss_fo_tax_rate,0)    iss_fo_tax_rate,    -- 25591653
             NVL(ril.iss_fo_amount,0)      iss_fo_amount,      -- 25591653
             ril.iss_city_id,                                  -- 25591653
             ril.iss_city_code ,                               -- 25591653
             ril.discount_amount,                              -- 28468398 - 28505834
             ril.discount_percent,                             -- 28468398 - 28505834
             ril.discount_net_amount,                          -- 28468398 - 28505834
             ril.net_amount,                                   -- 28468398 - 28505834
             ril.icms_st_prev_withheld_base,                   -- 28468398 - 28505834
             ril.icms_st_prev_withheld_tx_rate,                -- 28468398 - 28505834
             ril.icms_st_prev_withheld_amount,                 -- 28468398 - 28505834
             ril.fcp_st_prev_withheld_base,                    -- 28468398 - 28505834
             ril.fcp_st_prev_withheld_tx_rate,                 -- 28468398 - 28505834
             ril.fcp_st_prev_withheld_amount,                  -- 28468398 - 28505834
             NULL fundersul_code_combination_id,                -- 27746405
             NULL fundersul_expense_ccid,                       -- 27746405
             NULL fundersul_own_flag,                           -- 27746405
             NULL fundersul_sup_part_flag,                      -- 27746405
             NULL fundersul_amount,                             -- 27746405
             NULL fundersul_additional_amount,                  -- 27746405
             ri.fiscal_document_model          -- ER 29055483
        FROM cll_f189_invoices_interface  ri,
             cll_f189_invoice_types       rit,
             CLL_F189_INVOICE_LINES_IFACE ril,
             cll_f189_fiscal_operations   rfo,
             org_organization_definitions ood, -- BUG 19722064
             cll_f189_states              re -- 23314229
      --,cll_f189_item_utilizations riu     -- ERancement 4533742 AIrmer 12/08/2005
      --,cll_f189_fiscal_entities_all rfe   -- ERancement 4533742 AIrmer 12/08/2005
      --,cll_f189_business_vendors rbv      -- ERancement 4533742 AIrmer 12/08/2005
       WHERE ood.organization_id = p_organization_id -- BUG 19722064
         AND (ri.invoice_type_id = rit.invoice_type_id OR -- BUG 19722064
             ri.invoice_type_code = rit.invoice_type_code) -- BUG 19722064
            --AND rit.organization_id     = ri.organization_id       -- BUG 19722064
         AND rit.organization_id = ood.organization_id -- BUG 19722064
         AND ri.interface_invoice_id = ril.interface_invoice_id
         AND ri.interface_operation_id = p_operation_id
            --AND ri.organization_id        = p_organization_id        -- BUG 19722064
         AND (ri.organization_id = ood.organization_id OR -- BUG 19722064
             ri.organization_code = ood.organization_code) -- BUG 19722064
         AND (ril.cfo_id = rfo.cfo_id OR -- BUG 19722064
             ril.cfo_code = rfo.cfo_code) -- BUG 19722064
            -- AND ril.utilization_id         = riu.utilization_id -- ERancement 4533742 AIrmer 12/08/2005
            -- AND ri.entity_id               = rfe.entity_id     -- ERancement 4533742 AIrmer 12/08/2005
            -- AND rfe.business_vendor_id     = rbv.business_id   -- ERancement 4533742 AIrmer 12/08/2005
            --AND re.state_code             = ri.destination_state_code              -- 23314229 -- 23491406
         AND (ri.destination_state_id = re.state_id OR -- 23491406
             ri.destination_state_code = re.state_code) -- 23491406
         AND p_interface = 'Y';
    -- ER 17551029 5a Fase - Start
    --
    CURSOR c_prior_billings(p_invoice_id NUMBER) IS
      SELECT pb.prior_billings_id,
             pb.invoice_id,
             0 interface_invoice_id,
             pb.document_type,
             pb.document_number,
             pb.total_remuneration_amount
        FROM cll_f189_prior_billings pb
       WHERE pb.invoice_id = p_invoice_id
         AND p_interface = 'N'
      UNION
      SELECT pbi.prior_billings_id,
             0 invoice_id,
             pbi.interface_invoice_id,
             pbi.document_type,
             pbi.document_number,
             pbi.total_remuneration_amount
        FROM cll_f189_prior_billings_int pbi
       WHERE pbi.interface_invoice_id = p_invoice_id
         AND p_interface = 'Y';
    -- ER 17551029 5a Fase - End
    --

    --
    -- 29480917 begin
    Cursor c_Referenced_Docs(p_invoice_id Number) Is
      Select Cfrd.Invoice_Id
           , Cfrd.Referenced_Documents_Type
           , Cfrd.Source_Document_Type
        From Cll_F189_Referenced_Documents Cfrd
       Where Cfrd.Invoice_Id = p_invoice_id
         And p_interface = 'N'
      Union
      Select Cfrd.Interface_Invoice_Id Invoice_Id
           , Cfrd.Referenced_Documents_Type
           , Cfrd.Source_Document_Type
        From Cll_F189_Ref_Docs_Iface Cfrd
       Where Cfrd.Interface_Invoice_Id = p_invoice_id
         And p_interface = 'Y';
    r_Referenced_Docs c_Referenced_Docs%RowType;
    -- 29480917 end
    --

    -- 28592012 - Start
    CURSOR c_payment_methods(p_invoice_id NUMBER) IS
      SELECT pm.payment_method_id
           , pm.invoice_id
           , 0 interface_invoice_id
           , pm.payment_method_indicator
           , pm.payment_method
           , pm.payment_amount
        FROM cll_f189_payment_methods pm
       WHERE pm.invoice_id = p_invoice_id
         AND p_interface = 'N'
      UNION
      SELECT pmi.payment_method_id
           , 0 invoice_id
           , pmi.interface_invoice_id
           , pmi.payment_method_indicator
           , pmi.payment_method
           , pmi.payment_amount
        FROM cll_f189_payment_methods_iface pmi
       WHERE pmi.interface_invoice_id = p_invoice_id
         AND p_interface = 'Y';
    -- 28592012 - End
    --
    -- ER 10367032 - Inicio
    -- Funcao interna usada para verificar se o imposto pode ser recalculado na linha da NF
    -- de acordo com informacoes retornadas da NF pai
    FUNCTION tax_calc_ref_parent(p_inv_line_id IN NUMBER,
                                 p_tax_code    IN VARCHAR2) RETURN BOOLEAN IS
      --
      l_tax_calc BOOLEAN := TRUE;
      --
      l_pis_unit_amount    cll_f189_invoice_lines.pis_unit_amount%TYPE;
      l_pis_qty            cll_f189_invoice_lines.pis_qty%TYPE;
      l_pis_base_amount    cll_f189_invoice_lines.pis_base_amount%TYPE;
      l_pis_tax_rate       cll_f189_invoice_lines.pis_tax_rate%TYPE;
      l_cofins_unit_amount cll_f189_invoice_lines.cofins_unit_amount%TYPE;
      l_cofins_qty         cll_f189_invoice_lines.cofins_qty%TYPE;
      l_cofins_base_amount cll_f189_invoice_lines.cofins_base_amount%TYPE;
      l_cofins_tax_rate    cll_f189_invoice_lines.cofins_tax_rate%TYPE;
      --
    BEGIN
      --
      BEGIN
        IF p_interface = 'N' THEN
          --
          SELECT cllil.pis_unit_amount,
                 cllil.pis_qty,
                 cllil.pis_base_amount,
                 cllil.pis_tax_rate,
                 cllil.cofins_unit_amount,
                 cllil.cofins_qty,
                 cllil.cofins_base_amount,
                 cllil.cofins_tax_rate
            INTO l_pis_unit_amount,
                 l_pis_qty,
                 l_pis_base_amount,
                 l_pis_tax_rate,
                 l_cofins_unit_amount,
                 l_cofins_qty,
                 l_cofins_base_amount,
                 l_cofins_tax_rate
            FROM cll_f189_invoice_lines        cllil,
                 cll_f189_invoice_line_parents cllilp,
                 cll_f189_invoice_parents      cllip,
                 cll_f189_invoice_types        cllit,
                 cll_f189_invoices             clli
           WHERE cllilp.invoice_line_id = p_inv_line_id
             AND cllil.invoice_line_id = cllilp.invoice_parent_line_id
             AND cllip.parent_id = cllilp.parent_id
             AND clli.invoice_id = cllip.invoice_parent_id
             AND cllit.invoice_type_id = clli.invoice_type_id;
          --
        ELSIF p_interface = 'Y' THEN
          --
          SELECT cllil.pis_unit_amount,
                 cllil.pis_qty,
                 cllil.pis_base_amount,
                 cllil.pis_tax_rate,
                 cllil.cofins_unit_amount,
                 cllil.cofins_qty,
                 cllil.cofins_base_amount,
                 cllil.cofins_tax_rate
            INTO l_pis_unit_amount,
                 l_pis_qty,
                 l_pis_base_amount,
                 l_pis_tax_rate,
                 l_cofins_unit_amount,
                 l_cofins_qty,
                 l_cofins_base_amount,
                 l_cofins_tax_rate
            FROM cll_f189_invoice_lines        cllil,
                 cll_f189_invoice_line_par_int cllilp,
                 cll_f189_invoice_parents_int  cllip,
                 cll_f189_invoice_types        cllit,
                 cll_f189_invoices             clli
           WHERE cllilp.interface_invoice_line_id = p_inv_line_id
             AND cllil.invoice_line_id = cllilp.invoice_parent_line_id
             AND cllip.interface_parent_id = cllilp.interface_parent_id
             AND clli.invoice_id = cllip.invoice_parent_id
             AND cllit.invoice_type_id = clli.invoice_type_id
             AND cllit.organization_id = p_organization_id;
          --
        END IF;
        --
      EXCEPTION
        --
        WHEN OTHERS THEN
          --
          l_pis_unit_amount    := NULL;
          l_pis_qty            := NULL;
          l_pis_base_amount    := NULL;
          l_pis_tax_rate       := NULL;
          l_cofins_unit_amount := NULL;
          l_cofins_qty         := NULL;
          l_cofins_base_amount := NULL;
          l_cofins_tax_rate    := NULL;
          --
        --
      END;
      --
      IF p_tax_code = 'PIS' THEN
        --
        IF l_return_customer_flag = 'F' THEN
          --
          l_tax_calc := TRUE;
          --
        ELSE
          --
          IF l_pis_unit_amount IS NOT NULL AND l_pis_qty IS NOT NULL AND
             l_pis_base_amount IS NULL AND l_pis_tax_rate IS NULL THEN
            --
            l_tax_calc := FALSE;
            --
          END IF;
          --
        END IF;
        --
      ELSIF p_tax_code = 'COFINS' THEN
        --
        IF l_return_customer_flag = 'F' THEN
          --
          l_tax_calc := TRUE;
          --
        ELSE
          --
          IF l_cofins_unit_amount IS NOT NULL AND l_cofins_qty IS NOT NULL AND
             l_cofins_base_amount IS NULL AND l_cofins_tax_rate IS NULL THEN
            --
            l_tax_calc := FALSE;
            --
          END IF;
          --
        END IF;
        --
      END IF;
      --
      RETURN l_tax_calc;
      --
    END tax_calc_ref_parent;
    -- ER 10367032 - Fim
    --
  BEGIN
    -- ER 8571984
    BEGIN
      SELECT TO_NUMBER(hoi.org_information3) operating_unit
        INTO l_org_id
        FROM hr_organization_information hoi
       WHERE hoi.org_information_context = 'Accounting Information'
         AND organization_id = p_organization_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_org_id := NULL;
    END;
    --
    -- Inicio BUG 19722064
    BEGIN
      SELECT organization_code
        INTO l_org_code
        FROM org_organization_definitions
       WHERE organization_id = p_organization_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_org_code := NULL;
    END;
    -- Fim BUG 19722064
    --
    -- Bug 8327237 - SSimoes - 11/03/2009 - Inicio
    --      mo_global.set_policy_context('S', fnd_profile.VALUE('ORG_ID'));
    --mo_global.set_policy_context('S', fnd_global.org_id()); -- ER 8571984
    mo_global.set_policy_context('S', l_org_id); -- ER 8571984
    -- Bug 8327237 - SSimoes - 11/03/2009 - Fim
    w_table_associated := 1; -- ERancement 4533742 AIrmer 12/08/2005
    --
    BEGIN
      DELETE FROM cll_f189_holds
       WHERE operation_id = p_operation_id
         AND organization_id = p_organization_id;
    END;
    -- Verify approval procedures
    BEGIN
      SELECT COUNT(1) ---> 02 Registers (Package and Package Body) <---
        INTO v_p1
        FROM user_objects
       WHERE object_name = 'CLL_F189_APROV_PKG'
         AND status = 'VALID';
      /*---*/
      SELECT COUNT(1) ---> 02 Registers (Package and Package Body) <---
        INTO v_p2
        FROM user_objects
       WHERE object_name = 'CLL_F189_INTERFACE_PKG'
         AND status = 'VALID';
      /*---*/
      SELECT COUNT(1) ---> 02 Registers (Package and Package Body) <---
        INTO v_p3
        FROM user_objects
       WHERE object_name = 'CLL_F189_UPD_COSTS_PKG'
         AND status = 'VALID';
      /*---*/
      SELECT COUNT(1) ---> 02 Registers (Package and Package Body) <---
        INTO v_p4
        FROM user_objects
       WHERE object_name = 'CLL_F189_INTERFACE_OPM_PKG'
         AND status = 'VALID';
      /*---*/
      SELECT COUNT(1) ---> 01 Registers (Trigger)                 <---
        INTO v_p5
        FROM user_triggers
       WHERE trigger_name = 'CLL_F189_HIST_ENTRY_OPER_T1'
         AND status = 'ENABLED';
      /*---*/
      /* --revisar
      SELECT COUNT (1)     ---> 01 Registers (Trigger)                 <---
        INTO v_p6
        FROM user_triggers
       WHERE trigger_name = 'CLL_F189_UPD_COST' AND status = 'ENABLED'; */
      /*---*/
      -- ER 26338366/26899224 -- Start (WCarvalho - 30/OCT/2017)
      SELECT COUNT(1) ---> 02 Registers (Package and Package Body) <---
        INTO v_p7
        FROM user_objects
       WHERE object_name = 'CLL_F513_UPD_TPA_RETURNS_PKG'
         AND status      = 'VALID';
      -- ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)
      /*---*/
    EXCEPTION
      WHEN OTHERS THEN
        v_p1 := 0;
        v_p2 := 0;
        v_p3 := 0;
        v_p4 := 0;
        v_p5 := 0;
        v_p6 := 0;
        -- ER 26338366/26899224 -- Start (WCarvalho - 30/OCT/2017)
        v_p7 := 0;
        -- ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)
    END;
    --
    IF (v_p1 + v_p2 + v_p3 + v_p4 + v_p5 + v_p6
       -- ER 26338366/26899224 -- Start (WCarvalho - 30/OCT/2017)
       + v_p7)
      -- ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)
       <> 10 THEN
      IF p_interface = 'N' THEN
        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                   p_organization_id,
                                                   p_location_id,
                                                   'PROCEDURE INVALID',
                                                   NULL,
                                                   NULL);
      ELSE
        -- Bug 5029863 AIrmer 21/02/2006
        raise_application_error(-20553,
                                SQLERRM ||
                                '**************************************' ||
                                ' Procedure invalid ' ||
                                '**************************************');
        /* Bug 5029863 AIrmer 21/02/2006
        BEGIN
          cll_f189_check_holds_pkg.incluir_erro (NULL
                                          ,p_operation_id
                                          ,'PROCEDURE INVALID');
        EXCEPTION
          WHEN OTHERS THEN NULL;
        END;
        */
      END IF;
    END IF; -->> (v_p1 + v_p2 + v_p3 + v_p4 + v_p5 /*+ v_p6*/ + v_p7) <> 10
    --
    -- Recovers the balance segment value
    BEGIN
      SELECT fnd.application_column_name
        INTO p_segment
        FROM fnd_segment_attribute_values fnd
       WHERE fnd.application_id = 101
         AND fnd.id_flex_num =
             (SELECT chart_of_accounts_id
                FROM org_organization_definitions
               WHERE organization_id = p_organization_id)
         AND fnd.segment_attribute_type = 'GL_BALANCING'
         AND fnd.attribute_value = 'Y'
         AND fnd.id_flex_code = 'GL#'; --revisar
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_segment := NULL;
      WHEN OTHERS THEN
        raise_application_error(-20553,
                                SQLERRM ||
                                '**************************************' ||
                                ' Select FND_SEGMENT_ATTRIBUTE_VALUES ' ||
                                '**************************************');
    END;
    --
    BEGIN
      EXECUTE IMMEDIATE 'SELECT ' || p_segment ||
                        ' FROM mtl_parameters mp, gl_code_combinations gcc ' ||
                        'WHERE  mp.material_account = gcc.code_combination_id ' ||
                        'AND    mp.organization_id = :b1'
        INTO v_balance_seg
        USING p_organization_id;
    EXCEPTION
      WHEN OTHERS THEN
        raise_application_error(-20550,
                                SQLERRM || '*******************' ||
                                ' EXECUTE IMMEDIATE ' ||
                                '*******************');
    END;
    --  Recovers the account segment value
    BEGIN
      SELECT fnd.application_column_name
        INTO p_segment_conta
        FROM fnd_segment_attribute_values fnd
       WHERE fnd.application_id = 101
         AND fnd.id_flex_num =
             (SELECT chart_of_accounts_id
                FROM org_organization_definitions
               WHERE organization_id = p_organization_id)
         AND fnd.segment_attribute_type = 'GL_ACCOUNT'
         AND fnd.attribute_value = 'Y'
         AND fnd.id_flex_code = 'GL#'; --revisar
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_segment_conta := NULL;
      WHEN OTHERS THEN
        raise_application_error(-20554,
                                SQLERRM ||
                                '**************************************' ||
                                ' Select FND_SEGMENT_ATTRIBUTE_VALUES ' ||
                                '**************************************');
    END;
    -- Recovers GL DATE
    IF p_interface = 'N' THEN
      BEGIN
         -- 29559606 - Start
         --SELECT reo.gl_date, reo.receive_date, reo.source -- ER 14124731
         SELECT TRUNC(reo.gl_date) gl_date
              , TRUNC(reo.receive_date) receive_date
              , reo.source
         -- 29559606 - End
           INTO v_gl_date
              , x_receive_date
              , l_source -- ER 14124731
           FROM cll_f189_entry_operations reo
          WHERE reo.operation_id = p_operation_id
            AND reo.organization_id = p_organization_id;
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20800,
                                  SQLERRM ||
                                  '****************************************' ||
                                  ' Select GL_DATE - cll_f189_entry_operations ' ||
                                  '****************************************');
      END;
    ELSE
      BEGIN
         -- 29559606 - Start
         --SELECT rii.gl_date, rii.source -- ER 14124731
          SELECT TRUNC(rii.gl_date) gl_date
               , rii.source
          -- 29559606 - End
          INTO v_gl_date, l_source -- ER 14124731
          FROM cll_f189_invoices_interface rii
         WHERE rii.interface_operation_id = p_operation_id
           AND (rii.organization_id = p_organization_id OR -- BUG 19722064
               rii.organization_code = l_org_code) -- BUG 19722064
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20800,
                                  SQLERRM || '**********************' ||
                                  ' Select GL_DATE - cll_f189_entry_operations ' ||
                                  '**********************');
      END;
    END IF;
    -- Recovers Organization Parameters
    BEGIN
      SELECT rcv_tolerance_amount,
             rcv_tolerance_code,
             rounding_precision,
             NVL(rcv_tolerance_percentual, 0),
             currency_conversion_rate,
             enforce_corp_conversion_rate,
             po_payment_condition_flag,
             accrual_supplier_ccid,
             NVL(allow_inv_major_accrual, 'N'),
             NVL(hold_currency_different_po, 'N'),
             pis_recover_start_date, -- ERancement 4533742 AIrmer 12/08/2005
             cofins_recover_start_date, -- ERancement 4533742 AIrmer 12/08/2005
             NVL(allow_mult_bal_segs, 'N'), -- ER 6399212 AIrmer 26/12/2007
             NVL(federal_withholding_tax_flag, 'C'), -- ER 8633459 --
             book_type_code, -- Bug 9600580 - SSimoes - 08/06/2010
             -- ER 9955304 - GSilva - 30/09/2010 - Inicio
             ipi_trib_code_required_flag,
             pis_trib_code_required_flag,
             cofins_trib_code_required_flag,
             -- ER 9955304 - GSilva - 30/09/2010 - Fim
             allow_upd_payment_term_flag, -- ER 10091174
             NVL(gl_date_diff_from_sysdate, 'N'),      -- Bug 16634319
             NVL(receive_date_diff_from_sysdate, 'N'), -- 29559606
             invoice_date_less_than, -- Bug 10367485
             inss_autonomous_max_retention, -- 24758216
             NVL(lp_inss_rate_max_retention, 0), -- 25808200 - 25808214
             inss_max_remuner_contrib -- 29526046
        INTO v_tolerance_amount,
             v_tolerance_code,
             arr,
             v_rcv_tolerance_percent,
             v_currency_conversion_rate,
             v_enforce_corp_conversion_rate,
             v_po_payment_condition_flag,
             x_accrual_supplier_ccid,
             x_allow_inv_major_accrual,
             x_hold_currency_different_po,
             v_pis_recover_start_date, -- ERancement 4533742 AIrmer 12/08/2005
             v_cofins_recover_start_date, -- ERancement 4533742 AIrmer 12/08/2005
             l_allow_mult_bal_segs, -- ER 6399212 AIrmer 26/12/2007
             v_fed_withholding_tax_flag, -- ER 8633459 --
             v_book_type_code, -- Bug 9600580 - SSimoes - 08/06/2010
             -- ER 9955304 - GSilva - 30/09/2010 - Inicio
             v_ipi_trib_code_required_flag,
             v_pis_trib_code_required_flag,
             v_cof_trib_code_required_flag,
             -- ER 9955304 - GSilva - 30/09/2010 - Fim
             v_allow_upd_payment_term_flag, -- ER 10091174
             v_gl_date_diff_from_sysdate,  -- Bug 16634319
             l_rec_date_diff_from_sysdate, -- 29559606
             l_invoice_date_less_than, -- Bug 10367485
             l_inss_aut_max_ret, -- 24758216
             l_lp_inss_rate_max_ret, -- 25808200 - 25808214
             l_inss_max_remuner_contrib -- 29526046
        FROM cll_f189_parameters
       WHERE organization_id = p_organization_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_tolerance_amount      := 0;
        v_tolerance_code        := 'NONE';
        arr                     := 2;
        v_rcv_tolerance_percent := 0;
      WHEN OTHERS THEN
        raise_application_error(-20551,
                                SQLERRM || '**********************' ||
                                ' Select cll_f189_parameters ' ||
                                '**********************');
    END;

    l_esocial_period_code := CLL_F407_UTILITY_PKG.GET_START_DATE_ORG_F(p_organization_id);       -- 25808200 - 25808214
    l_reinf_period_code   := CLL_F407_UTILITY_PKG.GET_START_DATE_ORG_REINF_F(p_organization_id); -- 25808200 - 25808214

    -- Bug 9309213 - SSimoes - 21/01/2010 - Inicio
    BEGIN
      EXECUTE IMMEDIATE 'SELECT lcm_enabled_flag' ||
                        '  FROM mtl_parameters' ||
                        ' WHERE organization_id = :b1'
        INTO v_lcm_flag
        USING p_organization_id;
      --
      IF NVL(v_lcm_flag, 'N') = 'Y' THEN
        IF p_interface = 'N' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'ERROR LCM ORGANIZATION',
                                                     NULL,
                                                     NULL);
        ELSE
          cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                p_operation_id,
                                                'ERROR LCM ORGANIZATION');
        END IF;
      END IF; -->> NVL(v_lcm_flag,'N')
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- Bug 9309213 - SSimoes - 21/01/2010 - Fim
    -- Bug 16634319 - Start
    IF v_gl_date_diff_from_sysdate = 'N' THEN
      IF v_gl_date <> trunc(SYSDATE) THEN
        IF p_interface = 'N' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'GL DATE DIFF SYSDATE',
                                                     NULL,
                                                     NULL);
        END IF;
      END IF;
    END IF; -->> v_gl_date_diff_from_sysdate = 'N'
    --
    -- 29559606 - Start
    IF v_gl_date_diff_from_sysdate = 'Y' THEN
      IF v_gl_date > trunc(SYSDATE) THEN
        IF p_interface = 'N' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'GL AFTER DATE',
                                                     NULL,
                                                     NULL);
        END IF;
      END IF;
    END IF;
    --
    IF l_rec_date_diff_from_sysdate = 'N' THEN
      IF x_receive_date <> trunc(SYSDATE) THEN
        IF p_interface = 'N' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'RECEIPT DATE DIFF SYSDATE',
                                                     NULL,
                                                     NULL);
        END IF;
      END IF;
    END IF;
    --
    IF l_rec_date_diff_from_sysdate = 'Y' THEN
      IF x_receive_date > trunc(SYSDATE) THEN
        IF p_interface = 'N' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'REC AFTER DATE',
                                                     NULL,
                                                     NULL);
        END IF;
      END IF;
    END IF;
    -- 29559606 - End
    --
    -- Bug 16634319 - End
    --
    -- Delete Freight Invoices
    --IF p_freight_flag IN ('C', 'N')
    --THEN
    -- ER 10234658 - Tratamento de novos tipos de frete (Fob sem CTRC, CIF ou Sem Frete)
    IF p_freight_flag <> 'F' THEN
      --
      DELETE cll_f189_freight_invoices
       WHERE operation_id = p_operation_id
         AND organization_id = p_organization_id
         AND p_interface = 'N';
      --
      DELETE cll_f189_freight_inv_interface
       WHERE interface_operation_id = p_operation_id
         AND (organization_id = p_organization_id OR -- BUG 19722064
             organization_code = l_org_code) -- BUG 19722064
         AND p_interface = 'Y';
    END IF; -->> p_freight_flag <> 'F
    -- Freight Invoices
    IF p_freight_flag = 'F' THEN
      BEGIN
        IF p_interface = 'N' THEN
          SELECT COUNT(1)
            INTO v_count
            FROM cll_f189_freight_invoices
           WHERE operation_id = p_operation_id
             AND organization_id = p_organization_id;
        ELSE
          SELECT COUNT(1)
            INTO v_count
            FROM cll_f189_freight_inv_interface
           WHERE interface_operation_id = p_operation_id
             AND (organization_id = p_organization_id OR -- BUG 19722064
                 organization_code = l_org_code); -- BUG 19722064
        END IF;
      END;
      --
      IF v_count = 0 THEN
        IF p_interface = 'N' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'NONE FREIGHT',
                                                     NULL,
                                                     NULL);
        ELSE
          cll_f189_check_holds_pkg.incluir_erro( --NULL  -- Bug 5029863 AIrmer 21/02/2006
                                                p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                p_operation_id,
                                                'NONE FREIGHT');
        END IF;
      ELSE
        BEGIN
          IF p_interface = 'N' THEN
            SELECT COUNT(DISTINCT rfi.invoice_type_id),
                   MIN(rit.credit_debit_flag),
                   MIN(rit.contab_flag)
              INTO v_count, v_cred_type_frt, v_contab_frt
              FROM cll_f189_freight_invoices rfi,
                   cll_f189_invoice_types    rit
             WHERE rfi.operation_id = p_operation_id
               AND rfi.organization_id = p_organization_id
               AND rfi.invoice_type_id = rit.invoice_type_id;
          ELSE
            SELECT COUNT(DISTINCT rfi.invoice_type_id),
                   MIN(rit.credit_debit_flag),
                   MIN(rit.contab_flag)
              INTO v_count, v_cred_type_frt, v_contab_frt
              FROM cll_f189_freight_inv_interface rfi,
                   cll_f189_invoice_types         rit
             WHERE rfi.interface_operation_id = p_operation_id
               AND (rfi.organization_id = p_organization_id OR -- BUG 19722064
                   rfi.organization_code = l_org_code) -- BUG 19722064
               AND (rfi.invoice_type_id = rit.invoice_type_id OR -- BUG 19722064
                   rfi.invoice_type_code = rit.invoice_type_code) -- BUG 19722064
               AND rit.organization_id = p_organization_id; -- BUG 19722064
          END IF;
        END;
        --
        IF v_count > 1 THEN
          -- Exists more than a note type in the operation
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DIFF FR INVOICE TYPE',
                                                       NULL,
                                                       NULL);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro( --NULL   -- Bug 5029863 AIrmer 21/02/2006
                                                  p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                  p_operation_id,
                                                  'DIFF FR INVOICE TYPE');
          END IF;
        END IF; -->> v_count > 1
        --
        IF p_interface = 'N' THEN
          -- Check accounting freight and invoice
          BEGIN
            SELECT t.contab_flag
              INTO v_contab_nf
              FROM cll_f189_invoice_types t, cll_f189_invoices i
             WHERE i.operation_id = p_operation_id
               AND i.organization_id = p_organization_id
               AND t.invoice_type_id = i.invoice_type_id
               AND ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_contab_nf := 'X';
            WHEN OTHERS THEN
              raise_application_error(-20521,
                                      SQLERRM || '*******************' ||
                                      ' Select accounting type invoice' ||
                                      '********************');
          END;
        ELSE
          BEGIN
            -- Check accounting freight and invoice
            SELECT t.contab_flag
              INTO v_contab_nf
              FROM cll_f189_invoice_types t, cll_f189_invoices_interface i
             WHERE i.interface_operation_id = p_operation_id
               AND (i.organization_id = p_organization_id OR -- BUG 19722064
                   i.organization_code = l_org_code) -- BUG 19722064
               AND (t.invoice_type_id = i.invoice_type_id OR -- BUG 19722064
                   t.invoice_type_code = i.invoice_type_code) -- BUG 19722064
               AND t.organization_id = p_organization_id -- BUG 19722064
               AND ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_contab_nf := 'X';
            WHEN OTHERS THEN
              raise_application_error(-20521,
                                      SQLERRM || '*******************' ||
                                      ' Select accounting type invoice (interface)' ||
                                      '********************');
          END;
        END IF;
        --
        IF v_contab_frt <> v_contab_nf THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DIFF CONTAB TYPE',
                                                       NULL,
                                                       NULL);
          ELSE
            BEGIN
              cll_f189_check_holds_pkg.incluir_erro( -- NULL  -- Bug 5029863 AIrmer 21/02/2006
                                                    p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                    p_operation_id,
                                                    'DIFF CONTAB TYPE');
            END;
          END IF;
        END IF; -->> v_contab_frt <> v_contab_nf
        --
        BEGIN
          IF p_interface = 'N' THEN
            SELECT COUNT(1)
              INTO v_count
              FROM cll_f189_freight_invoices
             WHERE operation_id = p_operation_id
               AND organization_id = p_organization_id
               AND NVL(total_freight_weight, 0) <>
                   NVL(p_total_freight_weight, 0); -- Bug 20371808
          ELSE
            SELECT COUNT(1)
              INTO v_count
              FROM cll_f189_freight_inv_interface
             WHERE interface_operation_id = p_operation_id
               AND (organization_id = p_organization_id OR -- BUG 19722064
                   organization_code = l_org_code) -- BUG 19722064
               AND NVL(total_freight_weight, 0) <>
                   NVL(p_total_freight_weight, 0); -- Bug 20371808
          END IF;
        END;
        --
        IF v_count > 0 THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DIFF WEIGHT FR',
                                                       NULL,
                                                       NULL);
          ELSE
            BEGIN
              cll_f189_check_holds_pkg.incluir_erro( -- NULL  -- Bug 5029863 AIrmer 21/02/2006
                                                    p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                    p_operation_id,
                                                    'DIFF WEIGHT FR');
            END;
          END IF;
        END IF; -->> v_count > 0
      END IF; -->> v_count = 0
      --
      BEGIN
        IF p_interface = 'N' THEN
          SELECT SUM(NVL(invoice_weight, 0))
            INTO v_sum_weight
            FROM cll_f189_invoices
           WHERE operation_id = p_operation_id
             AND organization_id = p_organization_id;
        ELSE
          SELECT SUM(NVL(invoice_weight, 0))
            INTO v_sum_weight
            FROM cll_f189_invoices_interface
           WHERE interface_operation_id = p_operation_id
             AND (organization_id = p_organization_id OR -- BUG 19722064
                 organization_code = l_org_code); -- BUG 19722064
        END IF;
      END;
      --
      IF NVL(v_sum_weight, 0) <> NVL(p_total_freight_weight, 0) THEN
        -- Bug 20371808
        IF p_interface = 'N' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'DIFF WEIGHT INV',
                                                     NULL,
                                                     NULL);
        ELSE
          BEGIN
            cll_f189_check_holds_pkg.incluir_erro( -- Bug 5029863 AIrmer 21/02/2006
                                                  p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                  p_operation_id,
                                                  'DIFF WEIGHT INV');
          END;
        END IF;
      END IF; -->> NVL(v_sum_weight,0) <> NVL(p_total_freight_weight,0)
      --
      -- ER 20382276 - Start
      IF p_freight_flag = 'F' THEN
        --
        IF p_interface = 'N' THEN
          --
          SELECT count(*)
            INTO l_fob_authorization
            FROM cll_f189_freight_invoices
           WHERE operation_id = p_operation_id
             AND organization_id = p_organization_id
             AND usage_authorization IS NOT NULL;
          --
        ELSE
          --
          SELECT count(*)
            INTO l_fob_authorization
            FROM cll_f189_freight_inv_interface
           WHERE operation_id = p_operation_id
             AND organization_id = p_organization_id
             AND usage_authorization IS NOT NULL;
          --
        END IF;
        --
        IF p_interface = 'N' THEN
          --
          SELECT count(*)
            INTO l_inv_authorization
            FROM cll_f189_invoices
           WHERE operation_id = p_operation_id
             AND organization_id = p_organization_id
             AND usage_authorization IS NOT NULL;
          --
        ELSE
          --
          SELECT count(*)
            INTO l_inv_authorization
            FROM cll_f189_invoices_interface
           WHERE operation_id = p_operation_id
             AND organization_id = p_organization_id
             AND usage_authorization IS NOT NULL;
          --
        END IF;
        --
        IF l_fob_authorization <> 0 AND l_inv_authorization = 0 THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'INV USAGE AUTHORIZ NOT NULL',
                                                       NULL,
                                                       NULL);
            --
          ELSE
            --
            BEGIN
              --
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'INV USAGE AUTHORIZ NOT NULL');
              --
            END;
            --
          END IF;
          --
        ELSIF l_fob_authorization = 0 AND l_inv_authorization <> 0 THEN
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'FRT USAGE AUTHORIZ NOT NULL',
                                                       NULL,
                                                       NULL);
            --
          ELSE
            --
            BEGIN
              --
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'FRT USAGE AUTHORIZ NOT NULL');
              --
            END;
          END IF;
        END IF; -->> l_fob_authorization = 0 AND l_inv_authorization
      END IF; -->> p_freight_flag = 'F'
      -- ER 20382276 - End
      --
      --  Freigth Type
      FOR r_freight_invoices IN c_freight_invoices LOOP
        w_table_associated := 3; -- ERancement 4533742 AIrmer 12/08/2005
        v_account_seg      := 0;
        --
        -- Incio BUG 19722064
        BEGIN
          SELECT invoice_type_id
            INTO l_invoice_type_id
            FROM cll_f189_invoice_types
           WHERE invoice_type_code = r_freight_invoices.invoice_type_code
             AND organization_id = p_organization_id;
        EXCEPTION
          WHEN no_data_found THEN
            l_invoice_type_id := 0;
        END;
        --
        BEGIN
          SELECT cfo_id
            INTO l_cfo_id
            FROM cll_f189_fiscal_operations
           WHERE cfo_code = r_freight_invoices.cfo_code;
        EXCEPTION
          WHEN no_data_found THEN
            l_cfo_id := 0;
        END;
        --
        BEGIN
          SELECT utilization_id
            INTO l_utilization_id_fr
            FROM cll_f189_item_utilizations
           WHERE utilization_code = r_freight_invoices.utilization_code;
        EXCEPTION
          WHEN no_data_found THEN
            l_utilization_id_fr := 0;
        END;
        -- Fim BUG 19722064
        --
        -- Inicio Bug 23018594 -- validacao da obrigatoriedade do frete
        cll_f189_fiscal_doc_type_pkg.get_fiscal_doc_type_setup(UPPER(r_freight_invoices.fiscal_document_model),
                                                               x_efd_type,
                                                               x_invoice_key_required_flag,
                                                               x_invoice_key_validation_flag,
                                                               x_invoice_number_length_flag);

        IF NVL(x_invoice_key_validation_flag, 'N') = 'Y' THEN
          -- Bug 23018594
          -- ER 12352413 - Inicio
          IF r_freight_invoices.eletronic_invoice_key IS NOT NULL THEN
            --
            BEGIN
              BEGIN
                l_nfe_key := TO_NUMBER(r_freight_invoices.eletronic_invoice_key);
              EXCEPTION
                WHEN OTHERS THEN
                  RAISE l_nfe_key_inv;
              END;
              --
              IF LENGTH(r_freight_invoices.eletronic_invoice_key) <> 44 THEN
                RAISE l_nfe_key_inv;
              END IF;
              --
            EXCEPTION
              WHEN l_nfe_key_inv THEN
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'CTE ACCESS KEY INVALID',
                                                             r_freight_invoices.invoice_id,
                                                             NULL);
                  --
                ELSE
                  --
                  cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                        p_operation_id,
                                                        'CTE ACCESS KEY INVALID');
                  --
                END IF;
                --
            END;
            --
            IF NOT
                cll_f189_digit_calc_pkg.func_access_key(r_freight_invoices.eletronic_invoice_key) THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV ACCESS KEY CTE',
                                                           r_freight_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'INV ACCESS KEY CTE');
                --
              END IF;
              --
            END IF;
            --
          END IF; -->> r_freight_invoices.eletronic_invoice_key IS NOT NULL
          -- ER 12352413 - Fim

        END IF; --Bug 23018594 -->> NVL(x_invoice_key_validation_flag,'N') = 'Y'
        --
-- 28180196 Start
/*
        -- 27579747 - Start
        IF r_freight_invoices.eletronic_invoice_key IS NOT NULL THEN

           SELECT count(*)
             INTO l_cte_key_exist
           FROM CLL_F189_ENTRY_OPERATIONS rco
               ,CLL_F189_FREIGHT_INVOICES rif
           WHERE rco.organization_id = p_organization_id
             AND rco.status = 'COMPLETE'
             AND rco.operation_id = rif.operation_id
             AND rif.eletronic_invoice_key = r_freight_invoices.eletronic_invoice_key
             AND nvl(rco.reversion_flag, 'N') NOT IN ('R','S'); -- 27869341

           IF l_cte_key_exist > 0 THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DUPLICATED ACCESS KEY CTE',
                                                           r_freight_invoices.invoice_id,
                                                         NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'DUPLICATED ACCESS KEY CTE');
                --
              END IF;

           END IF;

        END IF;
        -- 27579747 - End
*/
-- 28180196 End
        --
        -- Bug 11874715 - GSilva - 28/3/2011 - Inicio
        IF (p_interface = 'N') THEN
          --
          BEGIN
            SELECT payment_flag
              INTO v_payment_flag_frt
              FROM cll_f189_invoice_types
             WHERE invoice_type_id = r_freight_invoices.invoice_type_id
               AND organization_id = p_organization_id;
          END;
          --
        ELSE
          --
          BEGIN
            SELECT payment_flag
              INTO v_payment_flag_frt
              FROM cll_f189_invoice_types
             WHERE (invoice_type_id = r_freight_invoices.invoice_type_id OR
                   invoice_type_code =
                   r_freight_invoices.invoice_type_code)
               AND organization_id = p_organization_id -- BUG 19722064
               AND NVL(inactive_date, SYSDATE + 1) > SYSDATE
               AND ROWNUM < 2;
          END;
          --
        END IF;
        --
        IF NVL(v_payment_flag_frt, 'N') = 'Y' THEN
          --
          BEGIN
            SELECT '1'
              INTO v_ap_period
              FROM GL_PERIOD_STATUSES
             WHERE APPLICATION_ID = 200
               AND v_gl_date BETWEEN START_DATE AND END_DATE
               AND SET_OF_BOOKS_ID = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
               AND CLOSING_STATUS IN ('O', 'F')
               AND (ADJUSTMENT_PERIOD_FLAG IS NULL OR
                   ADJUSTMENT_PERIOD_FLAG = 'N');
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --
              IF (p_interface = 'N') THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID FRT AP_DATE',
                                                           r_freight_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID FRT AP_DATE');
                --
              END IF;
              --
          END;
          --
        END IF;
        -- Bug 11874715 - GSilva - 28/3/2011 - Fim
        --
        BEGIN
          EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM cll_f189_invoice_types,gl_code_combinations' ||
                            ' WHERE invoice_type_id = :b1' ||
                            ' AND cr_code_combination_id = code_combination_id' ||
                            ' AND ' || p_segment || '<> :b2'
            INTO v_account_seg
            USING NVL(r_freight_invoices.invoice_type_id, l_invoice_type_id), v_balance_seg;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          WHEN OTHERS THEN
            raise_application_error(-20552,
                                    SQLERRM || '**********************' ||
                                    ' Select cll_f189_invoice_types/GL_CODE_COMBINATIONS ' ||
                                    '**********************');
        END;
        --
        IF v_account_seg > 0 THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'ERROR BALANCE FRTTYPE',
                                                       r_freight_invoices.invoice_id,
                                                       NULL);
          ELSE
            BEGIN
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'ERROR BALANCE FRTTYPE');
            END;
          END IF;
        END IF;
        -- ER 14124731 - Start
      --IF l_source = 'CLL_F369 EFD LOADER' AND  p_interface = 'N' THEN       -- 27579747
        IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
        AND p_interface = 'N' THEN                                            -- 27579747

           IF r_freight_invoices.fiscal_document_model = '57'
           AND r_freight_invoices.eletronic_invoice_key IS NOT NULL THEN

              l_chnfe   := NULL;
              l_protnfe := NULL;

           --IF l_prf_access_key_sefaz = 'Y' THEN -- 21909282 -- 23010041

              cll_f369_access_key_val_pvt.main(r_freight_invoices.fiscal_document_model,
                                               l_chnfe,
                                               r_freight_invoices.eletronic_invoice_key,
                                               l_protnfe,
                                               l_protcte,
                                               l_retcode,
                                               l_retstatus);

              IF l_retcode = 1 THEN

                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                           'ERROR ACCESSKEYVAL',
                                                            r_freight_invoices.invoice_id,
                                                            NULL);
              ELSE

                 BEGIN
                    SELECT tag
                    INTO l_usage_authorization_tag
                    FROM fnd_lookup_values_vl
                    WHERE lookup_type = 'CLL_F369_USAGE_AUTHORIZATION'
                      AND lookup_code = l_protcte
                      AND NVL(end_date_active, SYSDATE + 1) > SYSDATE;
                 EXCEPTION
                    WHEN OTHERS THEN
                       l_usage_authorization_tag := NULL;
                 END;
                 --
                 IF NVL(l_usage_authorization_tag, 'N') = 'N' THEN

                     cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                p_organization_id,
                                                                p_location_id,
                                                               'UNAUTHORIZED FISCAL DOC',
                                                                r_freight_invoices.invoice_id,
                                                                NULL);
                 END IF;

              END IF;
           --END IF; -- 21909282 -- 23010041

           END IF;

        END IF;

        -- 27579747 - Start
        IF l_source = 'CLL_F369 EFD LOADER SHIPPER' THEN

           IF r_freight_invoices.fiscal_document_model NOT IN ('57','RPA') THEN

              IF (p_interface = 'N') THEN
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'INVALID DOC MODEL',
                                                            r_freight_invoices.invoice_id,
                                                            NULL);
              ELSE
                 cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                       p_operation_id,
                                                       'INVALID DOC MODEL');
              END IF;



           END IF;

        END IF;
       -- 27579747 - End
       --
        BEGIN
          SELECT tag
            INTO l_model_tag_freight
            FROM fnd_lookup_values_vl
           WHERE lookup_type = 'CLL_F189_FISCAL_DOCUMENT_MODEL'
             AND lookup_code = r_freight_invoices.fiscal_document_model
             AND NVL(end_date_active, SYSDATE + 1) > SYSDATE;
        EXCEPTION
          WHEN OTHERS THEN
            l_model_tag_freight := '*%';
        END;
        --
        IF l_model_tag_freight IS NOT NULL THEN
          IF l_model_tag_freight <> 'F' THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID FRTELECDOCMODEL',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID FRTELECDOCMODEL');
            END IF;
          END IF;
        END IF;
        -- ER 14124731 - End
        -- ER 8621766
        BEGIN
          SELECT '1'
            INTO v_validity_rules
            FROM fnd_lookup_values_vl
           WHERE lookup_type = 'CLL_F189_FISCAL_DOCUMENT_MODEL'
             AND lookup_code = r_freight_invoices.fiscal_document_model
             AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'FISCAL DOCUMENT MODEL') OR
                  lookup_code IN
                  (SELECT cfvr.validity_key_1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'FISCAL DOCUMENT MODEL'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID FRTDOCMODEL',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID FRTDOCMODEL');
            END IF;
        END;
        --
        BEGIN
          SELECT '1'
            INTO v_validity_rules
            FROM cll_f189_fiscal_operations
           WHERE cfo_id = NVL(r_freight_invoices.cfo_id, l_cfo_id)
             AND NVL(inactive_date, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'CFO') OR
                  cfo_id IN (SELECT cfvr.validity_key_1
                               FROM cll_f189_validity_rules cfvr
                              WHERE cfvr.invoice_type_id =
                                    NVL(r_freight_invoices.invoice_type_id,
                                        l_invoice_type_id) -- BUG 19722064
                                AND cfvr.validity_type = 'CFO'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID FRTCFO',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID FRTCFO');
            END IF;
        END;
        --
        BEGIN
          SELECT '1'
            INTO v_validity_rules
            FROM fnd_lookup_values_vl
           WHERE lookup_type = 'CLL_F189_INVOICE_SERIES'
             AND lookup_code = r_freight_invoices.series
             AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'INVOICE SERIES') OR
                  lookup_code IN
                  (SELECT cfvr.validity_key_1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'INVOICE SERIES'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID FRTSERIES',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID FRTSERIES');
            END IF;
        END;
        -- ER 10037887 - Dmontesino - 04/06/2012 Start
        IF r_freight_invoices.subseries IS NOT NULL THEN
          --
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_INVOICE_SUBSERIES'
               AND lookup_code = r_freight_invoices.subseries
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_freight_invoices.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'INVOICE SUBSERIES') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_freight_invoices.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'INVOICE SUBSERIES'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID FRTSUBSERIES',
                                                           r_freight_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID FRTSUBSERIES');
              END IF;
          END;
          --
        END IF;
        -- ER 10037887 - Dmontesino - 04/06/2012 End
        --
        -- ER 10037887 - Dmontesino - 04/06/2012 Start
        BEGIN
          SELECT '1'
            INTO v_validity_rules
            FROM fnd_lookup_values_vl
           WHERE lookup_type = 'CLL_F189_ICMS_TYPE'
             AND lookup_code = r_freight_invoices.icms_type
             AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'ICMS TYPE') OR
                  lookup_code IN
                  (SELECT cfvr.validity_key_1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'ICMS TYPE'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID FRTICMSTYPE',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID FRTICMSTYPE');
            END IF;
        END;
        -- ER 10037887 - Dmontesino - 04/06/2012 End
        --
        -- ER 13014403 - Start
        BEGIN
          SELECT 1
            INTO v_validity_rules
            FROM fnd_lookup_values_vl
           WHERE lookup_type = 'CLL_F189_STATE_TRIBUT_CODE'
             AND lookup_code = r_freight_invoices.icms_tax_code
             AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'ICMS TAXABLE FLAG') OR
                  lookup_code IN
                  (SELECT cfvr.validity_key_1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_freight_invoices.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'ICMS TAXABLE FLAG'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID FRTICMSTAXCODE',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID FRTICMSTAXCODE');
            END IF;
        END;
        -- ER 13014403 - End
        --
        -- Bug 9592789 - SSimoes - 06/05/2010 - Inicio
        IF r_freight_invoices.tributary_status_code IS NOT NULL THEN
          -- 22012023 - Start
          BEGIN
            SELECT lookup_code
              INTO l_csticms_freight
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_ICMS_TRIB_SIT_VAL'
               AND r_freight_invoices.invoice_date between
                   start_date_active AND
                   NVL(end_date_active, r_freight_invoices.invoice_date + 1)
               AND enabled_flag = 'Y'; -- BUG 21804594
          EXCEPTION
            WHEN OTHERS THEN
              l_csticms_freight := NULL;
          END;
          --
          IF l_csticms_freight = 'CSTICMSAB' THEN
            -- 22012023 - End
            BEGIN
              SELECT COUNT(1)
                INTO v_trib_status_code
                FROM cll_f189_tributary_situation
              -- 22012023 - Start
               WHERE tributary_source_code || tributary_complement_code =
                     r_freight_invoices.tributary_status_code
                 AND tributary_receiver_code IS NULL
                 AND r_freight_invoices.invoice_date BETWEEN start_date AND
                     NVL(end_date, r_freight_invoices.invoice_date + 1)
                    --WHERE tributary_source_code     = SUBSTR (r_freight_invoices.tributary_status_code, 1, 1)
                    --AND tributary_complement_code = SUBSTR (r_freight_invoices.tributary_status_code, 2, 2)
                    --AND (NVL (inactive_date, SYSDATE + 1) > SYSDATE)
                    -- 22012023 - End
                 AND (NOT EXISTS
                      (SELECT 1
                         FROM cll_f189_validity_rules cfvr
                        WHERE cfvr.invoice_type_id =
                              NVL(r_freight_invoices.invoice_type_id,
                                  l_invoice_type_id) -- BUG 19722064
                          AND cfvr.validity_type = 'CST ICMS') OR
                      tributary_source_code || tributary_complement_code IN
                      (SELECT cfvr.validity_key_1
                         FROM cll_f189_validity_rules cfvr
                        WHERE cfvr.invoice_type_id =
                              NVL(r_freight_invoices.invoice_type_id,
                                  l_invoice_type_id) -- BUG 19722064
                          AND cfvr.validity_type = 'CST ICMS'));
              --
              IF v_trib_status_code = 0 THEN
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID FRTTRIB STATUS CODE' -- Bug 10218611 - SSimoes - 18/Nov/2010
                                                            ,
                                                             r_freight_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID FRTTRIB STATUS CODE' -- Bug 10218611 - SSimoes - 18/Nov/2010
                                                        );
                END IF;
              END IF;
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20559,
                                        SQLERRM ||
                                        '**************************************' ||
                                        ' Select Freight Tributary Status Code ' -- Bug 10218611 - SSimoes - 18/Nov/2010
                                        ||
                                        '**************************************');
            END;
            -- 22012023 - Start
          ELSIF l_csticms_freight = 'CSTICMSABC' THEN
            BEGIN
              SELECT COUNT(1)
                INTO v_trib_status_code
                FROM cll_f189_tributary_situation
               WHERE tributary_source_code || tributary_complement_code ||
                     tributary_receiver_code =
                     r_freight_invoices.tributary_status_code
                 AND tributary_receiver_code IS NOT NULL
                 AND r_freight_invoices.invoice_date BETWEEN start_date AND
                     NVL(end_date, r_freight_invoices.invoice_date + 1)
                 AND (NOT EXISTS
                      (SELECT 1
                         FROM cll_f189_validity_rules cfvr
                        WHERE cfvr.invoice_type_id =
                              NVL(r_freight_invoices.invoice_type_id,
                                  l_invoice_type_id) -- BUG 19722064
                          AND cfvr.validity_type = 'CST ICMS') OR
                      tributary_source_code || tributary_complement_code ||
                      tributary_receiver_code IN
                      (SELECT cfvr.validity_key_1
                         FROM cll_f189_validity_rules cfvr
                        WHERE cfvr.invoice_type_id =
                              NVL(r_freight_invoices.invoice_type_id,
                                  l_invoice_type_id) -- BUG 19722064
                          AND cfvr.validity_type = 'CST ICMS'));
              --
              IF v_trib_status_code = 0 THEN
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID FRTTRIB STATUS CODE' -- Bug 10218611 - SSimoes - 18/Nov/2010
                                                            ,
                                                             r_freight_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID FRTTRIB STATUS CODE' -- Bug 10218611 - SSimoes - 18/Nov/2010
                                                        );
                END IF;
              END IF;
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20559,
                                        SQLERRM ||
                                        '**************************************' ||
                                        ' Select Freight Tributary Status Code ' -- Bug 10218611 - SSimoes - 18/Nov/2010
                                        ||
                                        '**************************************');
            END;
          END IF;
          -- 22012023 - End
        END IF;
        --
        -- Bug 20207037 - Start
        BEGIN
          SELECT NVL(pis_flag, 'N')
               , NVL(cofins_flag, 'N')
               , NVL(contab_flag, 'N') -- 27740002
               , collect_pis_ccid      -- 27740002
               , collect_cofins_ccid   -- 27740002
            INTO l_pis_flag
               , l_cofins_flag
               , l_contab_flag         -- 27740002
               , l_collect_pis_ccid    -- 27740002
               , l_collect_cofins_ccid -- 27740002
            FROM cll_f189_invoice_types
           WHERE invoice_type_id =
                 NVL(r_freight_invoices.invoice_type_id, l_invoice_type_id)
             AND organization_id = p_organization_id;
        EXCEPTION
          WHEN no_data_found THEN
            l_pis_flag            := 'N';
            l_cofins_flag         := 'N';
            l_contab_flag         := 'N';  -- 27740002
            l_collect_pis_ccid    := NULL; -- 27740002
            l_collect_cofins_ccid := NULL; -- 27740002
        END;
        --
        IF r_freight_invoices.pis_tributary_code IS NULL THEN
          IF l_pis_flag = 'Y' AND v_pis_trib_code_required_flag = 'Y' AND
             v_pis_recover_start_date IS NOT NULL AND
             v_pis_recover_start_date <= r_freight_invoices.invoice_date THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'CST PIS FRT REQUIRED',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'CST PIS FRT REQUIRED');
            END IF;
          END IF;
        END IF;
        --
        IF r_freight_invoices.cofins_tributary_code IS NULL THEN
          IF l_cofins_flag = 'Y' AND v_cof_trib_code_required_flag = 'Y' AND
             v_cofins_recover_start_date IS NOT NULL AND
             v_cofins_recover_start_date <= r_freight_invoices.invoice_date THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'CST COFINS FRT REQUIRED',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'CST COFINS FRT REQUIRED');
            END IF;
          END IF;
        END IF;
        -- Bug 20207037 - End
        --
        IF r_freight_invoices.pis_tributary_code IS NOT NULL THEN
          -- Bug 20207037
          -- Bug 15929409 - Start
          BEGIN
            SELECT 1
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_PIS_TRIBUTARY_CODE'
               AND lookup_code = r_freight_invoices.pis_tributary_code
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_freight_invoices.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST PIS') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_freight_invoices.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST PIS'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID FRTCSTPISTAXCODE',
                                                           r_freight_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID FRTCSTPISTAXCODE');
              END IF;
          END;
          --
        END IF; -- Bug 20207037
        --
        IF r_freight_invoices.cofins_tributary_code IS NOT NULL THEN
          -- Bug 20207037
          BEGIN
            SELECT 1
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_COFINS_TRIBUTARY_CODE'
               AND lookup_code = r_freight_invoices.cofins_tributary_code
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_freight_invoices.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST COFINS') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_freight_invoices.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST COFINS'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID FRTCSTCOFINSTAXCODE',
                                                           r_freight_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID FRTCSTCOFINSTAXCODE');
              END IF;
          END;
          -- Bug 15929409 - End
        END IF; -- Bug 20207037
        -- Bug 9592789 - SSimoes - 06/05/2010 - Fim

        -- 27740002 - Start
        IF l_pis_flag = 'Y' THEN

           IF l_contab_flag = 'I' AND r_freight_invoices.pis_amount_recover >= 0 THEN

              IF l_collect_pis_ccid IS NULL THEN

                 IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'NONE PIS TO COLLECT CCID',
                                                               r_freight_invoices.invoice_id,
                                                              '');
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'NONE PIS TO COLLECT CCID');
                 END IF;

              END IF;

           END IF;

        END IF;

        IF l_cofins_flag = 'Y' THEN

           IF l_contab_flag = 'I' AND r_freight_invoices.cofins_amount_recover >= 0 THEN

              IF l_collect_cofins_ccid IS NULL THEN

                 IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'NONE COFINS TO COLLECT CCID',
                                                               r_freight_invoices.invoice_id,
                                                              '');
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'NONE COFINS TO COLLECT CCID');
                 END IF;

              END IF;

           END IF;

        END IF;
        -- 27740002 - End

        IF r_freight_invoices.utilization_id IS NOT NULL OR -- Bug 10414906
           l_utilization_id IS NOT NULL THEN
          -- Bug 19722064
          -- Bug 10218611 - SSimoes - 18/Nov/2010 - Inicio
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM cll_f189_item_utilizations
             WHERE utilization_id =
                   NVL(r_freight_invoices.utilization_id, l_utilization_id) -- Bug 19722064
               AND NVL(inactive_date, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_freight_invoices.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'FISCAL UTILIZATION') OR
                    utilization_id IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_freight_invoices.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'FISCAL UTILIZATION'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID FRTUTILIZATION',
                                                           r_freight_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID FRTUTILIZATION');
              END IF;
          END;
          -- Bug 10218611 - SSimoes - 18/Nov/2010 - Fim
        END IF; -- Bug 10414906
        --
        -- ER 20382276 - Start
        IF r_freight_invoices.usage_authorization IS NOT NULL THEN
          --
          l_frt_usage_authorization := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES(p_lookup_type => 'CLL_F369_USAGE_AUTHORIZATION',
                                                                             p_lookup_code => to_char(r_freight_invoices.usage_authorization));
          --
          IF l_frt_usage_authorization IS NULL THEN
            --
            IF p_interface = 'N' THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'USAGE AUTHORIZATION INVALID',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
              --
            ELSE
              --
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'USAGE AUTHORIZATION INVALID');
              --
            END IF;
            --
          END IF;
          --
        END IF;
        --
        -- ER 20382276 - End
        --
        -- 28487689 - 28597878 - Start
      --IF r_freight_invoices.fiscal_document_model = '57' THEN                                               -- 29655872
        IF CLL_F189_INVOICES_UTIL_PKG.GET_FISCAL_DOC_MODEL_FRT(r_freight_invoices.fiscal_document_model) THEN -- 29655872

           IF ( ( r_freight_invoices.source_city_id IS NULL )
           OR ( r_freight_invoices.source_ibge_city_code IS NULL )
           OR ( r_freight_invoices.source_state_id IS NULL )
           OR ( r_freight_invoices.destination_city_id IS NULL )
           OR ( r_freight_invoices.destination_ibge_city_code IS NULL )
           OR ( r_freight_invoices.destination_state_id IS NULL ) ) THEN  -- 28978447
         --OR ( r_freight_invoices.ship_to_state_id IS NULL ) ) THEN      -- 28978447
              --
              IF p_interface = 'N' THEN
                 --
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'SHIP FROM TO IBGE REQ',
                                                            r_freight_invoices.invoice_id,
                                                            NULL);
                 --
              ELSE
                 --
                 cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                       p_operation_id,
                                                       'SHIP FROM TO IBGE REQ');
                 --
              END IF;
              --
           END IF;

        END IF;
        -- 28487689 - 28597878 - End
        --
        -- 27463767 - Start
        IF r_freight_invoices.source_city_id IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_source_city_exist_f
              FROM CLL_F189_CITIES cllci
              WHERE cllci.city_id = r_freight_invoices.source_city_id;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY NOT FOUND',
                                                              r_freight_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY NOT FOUND');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_freight_invoices.source_ibge_city_code IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_source_ibge_city_exist_f
              FROM CLL_F189_CITIES cllci
              WHERE cllci.ibge_code = r_freight_invoices.source_ibge_city_code;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY NOT FOUND',
                                                              r_freight_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY NOT FOUND');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_freight_invoices.destination_city_id IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_dest_city_exist_f
              FROM CLL_F189_CITIES cllci
              WHERE cllci.city_id = r_freight_invoices.destination_city_id;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY NOT FOUND',
                                                              r_freight_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY NOT FOUND');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_freight_invoices.destination_ibge_city_code IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_dest_ibge_city_exist_f
              FROM CLL_F189_CITIES cllci
              WHERE cllci.ibge_code = r_freight_invoices.destination_ibge_city_code;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY NOT FOUND',
                                                              r_freight_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY NOT FOUND');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_freight_invoices.source_city_id IS NOT NULL
        AND r_freight_invoices.source_ibge_city_code IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_source_corresp_exist_f
              FROM CLL_F189_CITIES cllci
              WHERE cllci.city_id   = r_freight_invoices.source_city_id
                AND cllci.ibge_code = r_freight_invoices.source_ibge_city_code;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY INVALID',
                                                              r_freight_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY INVALID');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_freight_invoices.destination_city_id IS NOT NULL
        AND r_freight_invoices.destination_ibge_city_code IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_dest_corresp_exist_f
              FROM CLL_F189_CITIES cllci
              WHERE cllci.city_id   = r_freight_invoices.destination_city_id
                AND cllci.ibge_code = r_freight_invoices.destination_ibge_city_code;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY INVALID',
                                                              r_freight_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY INVALID');
                    --
                 END IF;

           END;

        END IF;
        --
        -- 27463767 - End
        --
      --
      END LOOP;
      --
      -- ER 7530537 - Amaciel - 27/01/2009 - Inicio
      -- ===================== Consistencia da Utilizacao no Conhecimento de Frete =====================
      FOR r_freight_invoices IN c_freight_invoices LOOP
        BEGIN
          --
          -- ER 9289619: Start
          IF r_freight_invoices.simplified_br_tax_flag = 'Y' THEN
            --
            IF r_freight_invoices.icms_type <> 'EXEMPT' THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'ICMS TYPE NOT ALLOWED',
                                                           r_freight_invoices.invoice_id,
                                                           NULL);
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'ICMS TYPE NOT ALLOWED',
                                                      NULL);
              END IF;
              --
            END IF;
            --
          END IF;
          -- ER 9289619: End
          --
          IF NVL(r_freight_invoices.utilization_id, 0) = 0 THEN
            v_utilization_null := v_utilization_null + 1;
          ELSE
            v_utilization_not := v_utilization_not + 1;
          END IF;
          --
          IF v_utilization_null > 0 AND v_utilization_not > 0 THEN
            --
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'DIFF FRT UTILIZATION',
                                                         r_freight_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF FRT UTILIZATION',
                                                    NULL);
            END IF;
            EXIT;
          END IF;
          --
        END;
      END LOOP;
      --
      -- ER 7530527 - Amaciel - 27/01/2009 - Fim
      FOR r_freight IN c_freight LOOP
        IF r_freight.freight_terms_lookup_code = 'PAGO' AND
           NVL(r_freight.total_fob_amount, 0) = 0 THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DIFF FOB TYPE',
                                                       r_freight.invoice_id,
                                                       r_freight.invoice_line_id);
          ELSE
            BEGIN
              cll_f189_check_holds_pkg.incluir_erro(r_freight.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF FOB TYPE',
                                                    r_freight.interface_invoice_line_id);
            END;
          END IF;
          EXIT;
        END IF;
      END LOOP;
    ELSIF p_freight_flag = 'C' THEN
      -->> IF p_freight_flag
      -- Freigth type
      FOR r_freight IN c_freight LOOP
        IF r_freight.freight_terms_lookup_code = 'NO PAGO' AND
           NVL(r_freight.total_fob_amount, 0) = 0 THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DIFF FOB TYPE',
                                                       r_freight.invoice_id,
                                                       r_freight.invoice_line_id);
          ELSE
            BEGIN
              cll_f189_check_holds_pkg.incluir_erro(r_freight.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF FOB TYPE',
                                                    r_freight.interface_invoice_line_id);
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20517,
                                        SQLERRM || '*********************' ||
                                        ' Insert Hold DIFF FOB TYPE ' ||
                                        '**********************');
            END;
          END IF;
          EXIT;
        END IF;
      END LOOP;
    END IF;
    -- Payment terms
    BEGIN
      IF v_po_payment_condition_flag = 'Y' THEN
        FOR r_freight IN c_freight LOOP
          -- Partial devolution invoice
          IF NVL(r_freight.parent_flag, 'X') <> 'Y' THEN
            IF r_freight.terms_id_headers <> r_freight.terms_id_invoices THEN
              IF p_interface = 'N' THEN
                -- Bug.4063693
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF PAY COND PO',
                                                           r_freight.invoice_id,
                                                           r_freight.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_freight.interface_invoice_id, -- Bug.4063693
                                                      p_operation_id, -- Bug.4063693
                                                      'DIFF PAY COND PO', -- Bug.4063693
                                                      r_freight.interface_invoice_line_id); -- Bug.4063693
              END IF; -- Bug.4063693
            END IF;
          END IF;
        END LOOP;
      END IF;
    END;
    -- Invoice
    BEGIN
      IF p_interface = 'N' THEN
        SELECT COUNT(1)
          INTO v_count
          FROM cll_f189_invoices
         WHERE operation_id = p_operation_id
           AND organization_id = p_organization_id;
      ELSE
        SELECT COUNT(1)
          INTO v_count
          FROM cll_f189_invoices_interface  cfii,
               org_organization_definitions ood -- BUG 19722064
         WHERE interface_operation_id = p_operation_id
           AND ood.organization_id =
               NVL(p_organization_id, l_organization_id) -- BUG 19722064
           AND (cfii.organization_id = ood.organization_id OR -- BUG 19722064
               cfii.organization_code = ood.organization_code); -- BUG 19722064
      END IF;
    END;
    --
    IF v_count = 0 THEN
      IF p_interface = 'N' THEN
        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                   p_organization_id,
                                                   p_location_id,
                                                   'NONE INVOICE',
                                                   NULL,
                                                   NULL);
      ELSE
        BEGIN
          cll_f189_check_holds_pkg.incluir_erro( -- NULL  -- Bug 5029863 AIrmer 21/02/2006
                                                p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                p_operation_id,
                                                'NONE INVOICE');
        END;
      END IF;
    ELSE
      IF p_interface = 'N' THEN
        SELECT COUNT(DISTINCT ri.invoice_type_id),
               MIN(rit.credit_debit_flag),
               MIN(rit.triangle_operation)
          INTO v_count, v_cred_type_inv, v_triangle_operation
          FROM cll_f189_invoices ri, cll_f189_invoice_types rit
         WHERE ri.operation_id = p_operation_id
           AND ri.organization_id = p_organization_id
           AND ri.invoice_type_id = rit.invoice_type_id;
        --
        -- ER 7540459 - Start
        BEGIN
          --
          SELECT COUNT(DISTINCT entity_id)
            INTO v_count_invoices
            FROM cll_f189_invoices cfi, mtl_parameters mp
           WHERE cfi.operation_id = p_operation_id
             AND cfi.organization_id = p_organization_id
             AND cfi.organization_id = mp.organization_id
             AND mp.wms_enabled_flag = 'Y';
          --
        END;
        -- ER 7540459 - End
        --
      ELSE
        SELECT COUNT(DISTINCT ri.invoice_type_id),
               MIN(rit.credit_debit_flag),
               MIN(rit.triangle_operation)
          INTO v_count, v_cred_type_inv, v_triangle_operation
          FROM cll_f189_invoices_interface ri, cll_f189_invoice_types rit
         WHERE ri.interface_operation_id = p_operation_id
           AND (ri.organization_id = p_organization_id OR -- BUG 19722064
               ri.organization_code = l_org_code) -- BUG 19722064
           AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
               rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
           AND rit.organization_id = p_organization_id; -- BUG 19722064
        --
        -- ER 7540459 - Start
        BEGIN
          --
          SELECT COUNT(DISTINCT entity_id)
            INTO v_count_invoices
            FROM cll_f189_invoices_interface cfi, mtl_parameters mp
           WHERE cfi.operation_id = p_operation_id
             AND (cfi.organization_id = p_organization_id OR -- BUG 19722064
                 cfi.organization_code = l_org_code) -- BUG 19722064
             AND cfi.organization_id = mp.organization_id
             AND mp.wms_enabled_flag = 'Y';
          --
        END;
        -- ER 7540459 - End
        --
      END IF;
      -- ER 7540459 - Start
      IF v_count_invoices > 1 THEN
        --
        IF p_interface = 'N' THEN
          --
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'MORE ONE ENTITY IN OPER',
                                                     NULL,
                                                     NULL);
        ELSE
          --
          cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                p_operation_id,
                                                'MORE ONE ENTITY IN OPER');
        END IF;
        --
      END IF;
      -- ER 7540459 - End
      --
      IF v_count > 1 THEN
        IF p_interface = 'N' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     --'DIFF FR INVOICE TYPE',  -- Bug 12326869
                                                     'DIFF INVOICE TYPE', -- Bug 12326869
                                                     NULL,
                                                     NULL);
        ELSE
          BEGIN
            cll_f189_check_holds_pkg.incluir_erro( --NULL  -- Bug 5029863 AIrmer 21/02/2006
                                                  p_interface_invoice_id -- Bug 5029863 AIrmer 21/02/2006
                                                 ,
                                                  p_operation_id,
                                                  --'DIFF FR INVOICE TYPE',  -- Bug 12326869
                                                  'DIFF INVOICE TYPE' -- Bug 12326869
                                                  );
          END;
        END IF;
      ELSE
        IF v_triangle_operation = 'Y' THEN
          BEGIN
            IF p_interface = 'N' THEN
              SELECT DECODE(COUNT(DISTINCT ril.uom),
                            1,
                            MIN(ril.uom),
                            '~uom~son~')
                INTO v_uom_son
                FROM cll_f189_invoices ri, cll_f189_invoice_lines ril
               WHERE ri.operation_id = p_operation_id
                 AND ri.organization_id = p_organization_id
                 AND ri.invoice_id = ril.invoice_id;
            ELSE
              SELECT DECODE(COUNT(DISTINCT ril.uom),
                            1,
                            MIN(ril.uom),
                            '~uom~son~')
                INTO v_uom_son
                FROM cll_f189_invoices_interface  ri,
                     CLL_F189_INVOICE_LINES_IFACE ril
               WHERE ri.interface_operation_id = p_operation_id
                 AND (ri.organization_id = p_organization_id OR -- BUG 19722064
                     ri.organization_code = l_org_code) -- BUG 19722064
                 AND ri.interface_invoice_id = ril.interface_invoice_id;
            END IF;
          END;
          --
          BEGIN
            IF p_interface = 'N' THEN
              SELECT DECODE(COUNT(DISTINCT ril.uom),
                            1,
                            MIN(ril.uom),
                            '~uom~par~'),
                     DECODE(COUNT(DISTINCT ril.uom),
                            1,
                            MIN(muom.uom_class),
                            '~uom~clas~')
                INTO v_uom_par, v_uom_class
                FROM cll_f189_invoices      ri,
                     cll_f189_invoice_lines ril,
                     mtl_units_of_measure   muom
               WHERE ri.operation_id = p_operation_id
                 AND ri.organization_id = p_organization_id
                 AND ri.invoice_parent_id = ril.invoice_id
                 AND ril.uom = muom.unit_of_measure;
            END IF;
          END;
          --
          BEGIN
            SELECT conversion_rate
              INTO v_conversion_rate
              FROM mtl_uom_conversions
             WHERE unit_of_measure = v_uom_par
               AND default_conversion_flag = 'N'
               AND inventory_item_id = 0
               AND uom_class = v_uom_class
               AND ROWNUM = 1;

            SELECT DECODE(conversion_rate,
                          0,
                          0,
                          v_conversion_rate / conversion_rate)
              INTO v_conversion_rate
              FROM mtl_uom_conversions
             WHERE unit_of_measure = v_uom_son
               AND default_conversion_flag = 'N'
               AND inventory_item_id = 0
               AND uom_class = v_uom_class
               AND ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_conversion_rate := 0;
          END;
          --
          IF v_conversion_rate > 0 THEN
            BEGIN
              IF p_interface = 'N' THEN
                SELECT NVL(SUM(ril.quantity * v_conversion_rate), 0)
                  INTO v_qtde_par
                  FROM cll_f189_invoices ri, cll_f189_invoice_lines ril
                 WHERE ri.operation_id = p_operation_id
                   AND ri.organization_id = p_organization_id
                   AND ri.invoice_parent_id = ril.invoice_id;
                --
                SELECT NVL(SUM(ril.quantity), 0)
                  INTO v_qtde_son
                  FROM cll_f189_invoices      ri_1,
                       cll_f189_invoices      ri_2,
                       cll_f189_invoice_lines ril
                 WHERE ri_1.operation_id = p_operation_id
                   AND ri_1.organization_id = p_organization_id
                   AND ri_1.invoice_parent_id = ri_2.invoice_parent_id
                   AND ri_2.invoice_id = ril.invoice_id
                   AND ri_2.operation_id <> p_operation_id
                   AND ri_2.organization_id <> p_organization_id;
              END IF;
            END;
            --
            IF v_qtde_par > 0 AND v_qtde_son >= 0 AND
               v_qtde_son <= v_qtde_par THEN
              BEGIN
                IF p_interface = 'N' THEN
                  SELECT COUNT(1)
                    INTO v_count
                    FROM cll_f189_invoices ri, cll_f189_invoice_lines ril
                   WHERE ri.operation_id = p_operation_id
                     AND ri.organization_id = p_organization_id
                     AND ri.invoice_id = ril.invoice_id;
                ELSE
                  SELECT COUNT(1)
                    INTO v_count
                    FROM cll_f189_invoices_interface  ri,
                         CLL_F189_INVOICE_LINES_IFACE ril
                   WHERE ri.interface_operation_id = p_operation_id
                     AND (ri.organization_id = p_organization_id OR -- BUG 19722064
                         ri.organization_code = l_org_code) -- BUG 19722064
                     AND ri.interface_invoice_id = ril.interface_invoice_id;
                END IF;
              END;
              --
              IF v_count <> 1 THEN
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'TRIANGLE INVALID',
                                                             NULL,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro( --NULL  -- Bug 5029863 AIrmer 21/02/2006
                                                        p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                        p_operation_id,
                                                        'TRIANGLE INVALID');
                END IF;
              END IF;
            ELSE
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'TRIANGLE ON HAND',
                                                           NULL,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro( --NULL  -- Bug 5029863 AIrmer 21/02/2006
                                                      p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                      p_operation_id,
                                                      'TRIANGLE ON HAND');
              END IF;
            END IF;
          ELSE
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'TRIANGLE UNIT CONV',
                                                         NULL,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro( --NULL  -- Bug 5029863 AIrmer 21/02/2006
                                                    p_interface_invoice_id, -- Bug 5029863 AIrmer 21/02/2006
                                                    p_operation_id,
                                                    'TRIANGLE UNIT CONV');
            END IF;
          END IF;
        END IF;
      END IF;
      --
      -- ER 9028781 - Start
      BEGIN
        IF p_interface = 'N' THEN
          BEGIN
            SELECT COUNT(DISTINCT ri.icms_type)
              INTO l_icmstype_line_count
              FROM cll_f189_invoices ri
             WHERE ri.operation_id = p_operation_id
               AND ri.organization_id = p_organization_id
               AND ri.icms_type = 'INV LINES INF';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_icmstype_line_count := 0;
          END;
          --
          BEGIN
            SELECT COUNT(DISTINCT ri.icms_type)
              INTO l_icmstype_header_count
              FROM cll_f189_invoices ri
             WHERE ri.operation_id = p_operation_id
               AND ri.organization_id = p_organization_id
               AND ri.icms_type <> 'INV LINES INF';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_icmstype_header_count := 0;
          END;
        ELSE
          BEGIN
            SELECT COUNT(DISTINCT ri.icms_type)
              INTO l_icmstype_line_count
              FROM cll_f189_invoices_interface ri
             WHERE ri.interface_operation_id = p_operation_id
               AND ri.organization_id = p_organization_id
               AND ri.icms_type = 'INV LINES INF';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_icmstype_line_count := 0;
          END;
          --
          BEGIN
            SELECT COUNT(DISTINCT ri.icms_type)
              INTO l_icmstype_header_count
              FROM cll_f189_invoices_interface ri
             WHERE ri.interface_operation_id = p_operation_id
               AND ri.organization_id = p_organization_id
               AND ri.icms_type <> 'INV LINES INF';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_icmstype_header_count := 0;
          END;
        END IF;
        --
        IF l_icmstype_line_count > 0 AND l_icmstype_header_count > 0 THEN

          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DIFF ICMS TYPE',
                                                       NULL,
                                                       NULL);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                  p_operation_id,
                                                  'DIFF ICMS TYPE');
          END IF;
        END IF;
      END;
      -- ER 9028781 - End
      -- Invoice Lines
	  l_count_cfo_err       := NULL ; -- BUG 30789077
	  l_verify_hold_cfo_tpa := NULL ; -- BUG 30789077
	  --
      FOR r_invoice_lines IN c_invoice_lines LOOP
        w_table_associated := 2; -- ERancement 4533742 AIrmer 12/08/2005
        -- Incio BUG 19722064
        BEGIN
          SELECT invoice_type_id
            INTO l_invoice_type_id
            FROM cll_f189_invoice_types
           WHERE invoice_type_code = r_invoice_lines.invoice_type_code
             AND organization_id = p_organization_id;
        EXCEPTION
          WHEN no_data_found THEN
            l_invoice_type_id := 0;
        END;
        --
        BEGIN
          SELECT cfo_id
            INTO l_cfo_id
            FROM cll_f189_fiscal_operations
           WHERE cfo_code = r_invoice_lines.cfo_code;
        EXCEPTION
          WHEN no_data_found THEN
            l_cfo_id := 0;
        END;
        --
        BEGIN
          SELECT utilization_id
            INTO l_util_id
            FROM cll_f189_item_utilizations
           WHERE utilization_code = r_invoice_lines.utilization_code;
        EXCEPTION
          WHEN no_data_found THEN
            l_util_id := 0;
        END;
        -- Fim BUG 19722064
        --
        -- ER 10367032 - Inicio
        BEGIN
          --
          SELECT NVL(clls.national_state, 'N')
            INTO l_national_state
            FROM cll_f189_states clls, cll_f189_fiscal_entities_all cllfea
           WHERE cllfea.entity_id = r_invoice_lines.entity_id
             AND cllfea.state_id = clls.state_id;
          --
        EXCEPTION
          WHEN OTHERS THEN
            l_national_state := NULL;
        END;
        --
        l_return_customer_flag := r_invoice_lines.return_customer_flag;
        -- ER 10367032 - Fim
        --
        --
        -- ER 9072748 - Inicio
        IF r_invoice_lines.awt_group_id IS NOT NULL THEN
          --
          -- Bug 12835667 - Inicio
          l_allow_awt_flag := 'N';
          --
          BEGIN
            --
            SELECT DECODE(pv.allow_awt_flag,
                          'Y',
                          NVL(pvsa.allow_awt_flag, 'N'),
                          NVL(pv.allow_awt_flag, 'N'))
              INTO l_allow_awt_flag
              FROM po_vendors                   pv,
                   po_vendor_sites_all          pvsa,
                   cll_f189_fiscal_entities_all cffea
             WHERE cffea.entity_id = r_invoice_lines.entity_id
               AND cffea.vendor_site_id = pvsa.vendor_site_id
               AND cffea.org_id = pvsa.org_id
               AND pvsa.vendor_id = pv.vendor_id;
            --
          EXCEPTION
            --
            WHEN OTHERS THEN
              --
              l_allow_awt_flag := 'N';
              --
          END;
          --
          IF l_allow_awt_flag = 'N' THEN
            --
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'WITHHOLDING TAX NOT ALLOWED',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'WITHHOLDING TAX NOT ALLOWED',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
            --
          END IF;
          -- Bug 12835667 - Fim
          --
          BEGIN
            --
            SELECT count(aag.group_id)
              INTO v_count_awt
              FROM ap_awt_groups aag, ap_awt_group_taxes_all aagta
             WHERE aag.group_id = r_invoice_lines.awt_group_id
               AND aag.inactive_date IS NULL
               AND aag.group_id = aagta.group_id
               AND aagta.org_id =
                   (SELECT operating_unit
                      FROM org_organization_definitions
                     WHERE organization_id = p_organization_id);
            --
          END;
          --
          IF v_count_awt < 1 THEN
            --
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID AWT GROUP ID',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID AWT GROUP ID',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
            --
          END IF;
          --
        END IF;
        -- ER 9072748 - Fim
        --
        -- Bug 9745040 - SSimoes - 01/06/2010 - Inicio
        IF r_invoice_lines.line_location_id IS NOT NULL THEN
          BEGIN
            FOR c_Dest_SubInv IN (SELECT pd.destination_subinventory,
                                         pd.destination_organization_id,
                                         pll.ship_to_organization_id
                                    FROM po_line_locations_all pll,
                                         po_distributions_all  pd
                                   WHERE pll.line_location_id =
                                         r_invoice_lines.line_location_id
                                     AND pll.line_location_id =
                                         pd.line_location_id) LOOP
              -- c_Dest_SubInv
              BEGIN
                SELECT 'Y'
                  INTO v_inventory_destination_flag
                  FROM mtl_secondary_inventories msi
                 WHERE (c_Dest_SubInv.destination_subinventory IS NULL OR
                       (NVL(c_Dest_SubInv.destination_organization_id,
                             c_Dest_SubInv.ship_to_organization_id) =
                       msi.organization_id AND
                       c_Dest_SubInv.destination_subinventory =
                       msi.secondary_inventory_name))
                   AND ROWNUM = 1;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  v_inventory_destination_flag := 'N';
                WHEN OTHERS THEN
                  v_inventory_destination_flag := NULL;
                  raise_application_error(-20624,
                                          SQLERRM || '*******************' ||
                                          ' Destination Subinventory not found' ||
                                          '*******************');
              END;
              --
              IF v_inventory_destination_flag = 'N' THEN
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID SUBINVENTORY',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID SUBINVENTORY',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;
            END LOOP; -- c_Dest_SubInv
          END;
        END IF;
        -- Bug 9745040 - SSimoes - 01/06/2010 - Fim
        -- Inicio BUG 18276107
        IF r_invoice_lines.item_id IS NOT NULL THEN

          BEGIN
            -- Bug 19951540 - Start
            SELECT --PURCHASING_ENABLED_FLAG -- 22617088
             PURCHASING_ITEM_FLAG -- 22617088
            ,
             STOCK_ENABLED_FLAG,
             INTERNAL_ORDER_ENABLED_FLAG,
             INVOICE_ENABLED_FLAG,
             INVOICEABLE_ITEM_FLAG,
             SHIPPABLE_ITEM_FLAG,
             SO_TRANSACTIONS_FLAG,
             RETURNABLE_FLAG
              INTO --l_purchasing_enabled_flag -- 22617088
                   l_purchasing_item_flag -- 22617088
                  ,
                   l_stock_enabled_flag,
                   l_internal_order_enabled,
                   l_invoice_enabled_flag,
                   l_invoiceable_item,
                   l_shippable_item_flag,
                   l_so_transactions_flag,
                   l_returnable_flag
              FROM mtl_system_items_b msib
             WHERE msib.organization_id = p_organization_id
               AND msib.inventory_item_id = r_invoice_lines.item_id;
          EXCEPTION
            WHEN others THEN
              l_inactive_item := 'Y';
          END;
          --
          BEGIN
            -- Start Bug 25064971 - ER:F189:ALLOW ENTRY OPERATIONS WITHOUT PO DOCUMENT TO UPDATE INVENTORY AND COSTS  20/04/2017 NTeles
            --IF (r_invoice_lines.requisition_type = 'PO' OR r_invoice_lines.requisition_type = 'NA') AND
            IF (r_invoice_lines.requisition_type = 'PO' OR
               r_invoice_lines.requisition_type = 'NA' OR
               r_invoice_lines.requisition_type = 'IN') AND
              -- End Bug 25064971 - ER:F189:ALLOW ENTRY OPERATIONS WITHOUT PO DOCUMENT TO UPDATE INVENTORY AND COSTS  20/04/2017 NTeles
              --l_purchasing_enabled_flag = 'Y'  THEN -- 22617088
               l_purchasing_item_flag = 'Y' THEN
              -- 22617088
              --
              l_inactive_item := 'N';
              --
            ElSIF r_invoice_lines.requisition_type = 'OE' AND
                  (l_internal_order_enabled = 'Y' AND
                  l_invoice_enabled_flag = 'Y' AND
                  l_invoiceable_item = 'Y' AND l_shippable_item_flag = 'Y' AND
                  l_so_transactions_flag = 'Y') THEN
              --
              l_inactive_item := 'N';
              --
            ELSIF r_invoice_lines.requisition_type = 'RM' AND
                  l_returnable_flag = 'Y' THEN
              --
              l_inactive_item := 'N';
              --
              -- Bug 20423374 - Start
            ELSIF r_invoice_lines.requisition_type = 'CT' THEN
              --
              l_inactive_item := 'N';
              --
              -- Bug 20423374 - End
            END IF;

          END;
        ELSIF r_invoice_lines.item_id IS NULL THEN
          l_inactive_item := 'N';
        END IF;
        --
        IF l_inactive_item = 'Y' THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'INACTIVE ITEM',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);

          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'INACTIVE ITEM',
                                                  r_invoice_lines.interface_invoice_line_id);
          END IF;
        END IF;
        /*
           SELECT 'Y'
           --INTO v_inventory_item_status_code -- Bug 19438526
             INTO l_purchasing_item_flag       -- Bug 19438526
             FROM mtl_system_items_tl msitl
                , mtl_system_items_b msib
                , mtl_system_items_b_kfv   msikfv
            WHERE msitl.inventory_item_id  = msib.inventory_item_id
              AND msitl.organization_id    = msib.organization_id
              AND msikfv.inventory_item_id = msib.inventory_item_id
              AND msikfv.organization_id   = msib.organization_id
              AND msitl.language = USERENV ('LANG')
              AND msitl.organization_id    = p_organization_id
              AND msitl.inventory_item_id  = r_invoice_lines.item_id
            --and msib.inventory_item_status_code = 'Active'; -- Bug 19438526
              AND msib.purchasing_item_flag = 'Y';            -- Bug 19438526
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
               --v_inventory_item_status_code := 'N'; -- Bug 19438526
                 l_purchasing_item_flag := 'N';       -- Bug 19438526
            WHEN OTHERS THEN
               --v_inventory_item_status_code := NULL; -- Bug 19438526
                 l_purchasing_item_flag := NULL;       -- Bug 19438526
                         raise_application_error
                         (-20624,
                          SQLERRM
                          || '*******************'
                          || ' Inventory Item Status Code - Inactive'
                          || '*******************'
                          );
          END;
          --
          --IF v_inventory_item_status_code = 'N' THEN -- Bug 19438526
          IF l_purchasing_item_flag = 'N' THEN       -- Bug 19438526
             IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold
                                             (p_operation_id
                                             ,p_organization_id
                                             ,p_location_id
                                             ,'INACTIVE ITEM'
                                             ,r_invoice_lines.invoice_id
                                             ,r_invoice_lines.invoice_line_id
                                             );
             ELSE
                cll_f189_check_holds_pkg.incluir_erro
                                             (r_invoice_lines.interface_invoice_id
                                             ,p_operation_id
                                             ,'INACTIVE ITEM'
                                             ,r_invoice_lines.interface_invoice_line_id
                                             );
             END IF;
          END IF;
        END IF;
        */
        -- Fim BUG 18276107
        -- Bug 19951540 - End
        --
        -- 30463328 - Start
        /*
        -- Inicio BUG 20204403
        IF r_invoice_lines.requisition_type = 'OE' THEN
          DECLARE
            l_unit_price po_requisition_lines_all.unit_price%TYPE;
          BEGIN
            --
            IF p_interface = 'N' THEN
              BEGIN
                SELECT unit_price
                  INTO l_unit_price
                  FROM cll_f189_invoice_lines
                 WHERE requisition_line_id =
                       r_invoice_lines.requisition_line_id
                   AND invoice_line_id = r_invoice_lines.invoice_line_id;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  l_unit_price := 0;
              END;
            ELSE
              BEGIN
                SELECT unit_price
                  INTO l_unit_price
                  FROM cll_f189_invoice_lines_iface
                 WHERE requisition_line_id =
                       r_invoice_lines.requisition_line_id
                   AND interface_invoice_line_id =
                       r_invoice_lines.invoice_line_id;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  l_unit_price := 0;
              END;
            END IF;
            --
            IF NVL(r_invoice_lines.tax_adjust_flag, 'N') <> 'Y' THEN
              -- 22966523

              IF l_unit_price = 0 THEN
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'REQUISITION UNIT PRICE',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'REQUISITION UNIT PRICE',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;

            END IF; -- 22966523

          END;
        END IF;
        -- Fim BUG 20204403
        */
        -- 30463328 - End

        -- Inicio BUG 20387571
        BEGIN
          SELECT unit_of_measure
            INTO l_unit_of_measure
            FROM mtl_units_of_measure_vl
           WHERE unit_of_measure = r_invoice_lines.uom;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_unit_of_measure := null;
        END;
        --
        IF l_unit_of_measure is null THEN
          BEGIN
            SELECT unit_of_measure
              INTO x_unit_of_measure
              FROM MTL_UNITS_OF_MEASURE_TL
             WHERE unit_of_measure_tl = r_invoice_lines.uom;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              x_unit_of_measure := NULL;
          END;
        ELSE
          x_unit_of_measure := l_unit_of_measure;
        END IF;
        --
        -- Fim BUG 20387571
        -- ER 11820206 - Start
        DECLARE
          l_status                       VARCHAR2(30);
          l_permanent_active_credit_flag cll_f189_invoice_types.permanent_active_credit_flag%TYPE;
          l_complex_service              cll_f189_invoice_types.complex_service_flag%TYPE; --<<BUG 16596220 - Egini - 15/07/2013 >>--
        BEGIN
          IF p_interface = 'N' THEN
            SELECT rit.permanent_active_credit_flag,
                   rit.complex_service_flag --<<BUG 16596220 - Egini - 15/07/2013 >>--
              INTO l_permanent_active_credit_flag, l_complex_service --<<BUG 16596220 - Egini - 15/07/2013 >>--
              FROM cll_f189_invoices ri, cll_f189_invoice_types rit
             WHERE ri.invoice_type_id = rit.invoice_type_id
               AND rit.organization_id = ri.organization_id
               AND ri.invoice_id = r_invoice_lines.invoice_id;
          ELSE
            SELECT rit.permanent_active_credit_flag
              INTO l_permanent_active_credit_flag
              FROM cll_f189_invoices_interface  ri,
                   cll_f189_invoice_types       rit,
                   org_organization_definitions ood -- BUG 19722064
             WHERE ood.organization_id = p_organization_id -- BUG 19722064
               AND (ri.invoice_type_id = rit.invoice_type_id OR -- BUG 19722064
                   ri.invoice_type_code = rit.invoice_type_code) -- BUG 19722064
               AND (ri.organization_id = ood.organization_id OR -- BUG 19722064
                   ri.organization_code = ood.organization_code) -- BUG 19722064
               AND rit.organization_id = ood.organization_id -- BUG 19722064
               AND ri.interface_invoice_id =
                   r_invoice_lines.interface_invoice_id;
          END IF;
          --
          IF NVL(l_permanent_active_credit_flag, 'N') = 'N' AND
             NVL(l_complex_service, 'N') <> 'Y' THEN
            --<<BUG 16596220 - Egini - 15/07/2013 >>--THEN
            --
            l_status := NULL;
            --
            cll_f189_uom_pkg.val_uom(p_unit_of_measure => x_unit_of_measure --r_invoice_lines.uom -- BUG 20387571
                                    ,
                                     p_status          => l_status);
            --
            IF l_status = 'INVALID UOM' OR l_status = 'UOM ERROR' THEN
              --
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NO UOM',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'NO UOM',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
            --
            l_status := NULL;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            raise_application_error(-20654,
                                    SQLERRM || '*******************' ||
                                    ' Permanent active credit flag not found' ||
                                    '*******************');
        END;
        -- ER 11820206 - End

        -- 29311393 - Start
        IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') AND p_interface = 'Y' THEN
        -- Neste momento ainda nao foram prenchidos os valores default para os CSTs quando obrigatorios e por isso se estiverem nulos nao devem deixar os recebimentos retidos.
           NULL;
        ELSIF r_invoice_lines.fiscal_document_model = 'RPA' THEN -- ER 29055483
              NULL;
        ELSE
        -- Entrara aqui quando:
        -- Outras origens ou
        -- Quando origem Loader mas ja estiver dentro do RI, neste caso devera passar pela validacao pois os CSTs default ja estarao preenchidos quando obrigatorios.
        -- 29311393 - End
           -- ER 9981342 - GSilva - 29/09/2010 - Inicio
           IF r_invoice_lines.tributary_status_code IS NULL THEN
             IF r_invoice_lines.icms_trib_code_required_flag = 'Y' THEN
               -- Bug 13458810
               --  r_invoice_lines.include_icms_flag = 'Y' THEN -- Bug 13458810
               IF (p_interface = 'N') THEN
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'CST ICMS REQUIRED',
                                                            r_invoice_lines.invoice_id,
                                                            r_invoice_lines.invoice_line_id);
               ELSE
                 cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                       p_operation_id,
                                                       'CST ICMS REQUIRED',
                                                       r_invoice_lines.interface_invoice_line_id);
               END IF;
             END IF;
           END IF;
           -- ER 9981342 - GSilva - 29/09/2010 - Fim
           -- ER 9955304 - GSilva - 30/09/2010 - Inicio
           IF r_invoice_lines.ipi_tributary_code IS NULL THEN
             IF v_ipi_trib_code_required_flag = 'Y' AND
                r_invoice_lines.include_ipi_flag = 'Y' THEN
               IF (p_interface = 'N') THEN
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'CST IPI REQUIRED',
                                                            r_invoice_lines.invoice_id,
                                                            r_invoice_lines.invoice_line_id);
               ELSE
                 cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                       p_operation_id,
                                                       'CST IPI REQUIRED',
                                                       r_invoice_lines.interface_invoice_line_id);
               END IF;
             END IF;
           END IF;
           --
           IF r_invoice_lines.pis_tributary_code IS NULL THEN
             IF r_invoice_lines.pis_flag = 'Y' AND
                v_pis_trib_code_required_flag = 'Y' AND
                v_pis_recover_start_date IS NOT NULL AND
                v_pis_recover_start_date <= r_invoice_lines.invoice_date THEN
               IF (p_interface = 'N') THEN
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'CST PIS REQUIRED',
                                                            r_invoice_lines.invoice_id,
                                                            r_invoice_lines.invoice_line_id);
               ELSE
                 cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                       p_operation_id,
                                                       'CST PIS REQUIRED',
                                                       r_invoice_lines.interface_invoice_line_id);
               END IF;
             END IF;
           END IF;
           --
           IF r_invoice_lines.cofins_tributary_code IS NULL THEN
             IF r_invoice_lines.cofins_flag = 'Y' AND
                v_cof_trib_code_required_flag = 'Y' AND
                v_cofins_recover_start_date IS NOT NULL AND
                v_cofins_recover_start_date <= r_invoice_lines.invoice_date THEN
               IF (p_interface = 'N') THEN
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'CST COFINS REQUIRED',
                                                            r_invoice_lines.invoice_id,
                                                            r_invoice_lines.invoice_line_id);
               ELSE
                 cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                       p_operation_id,
                                                       'CST COFINS REQUIRED',
                                                        r_invoice_lines.interface_invoice_line_id);
               END IF;
             END IF;
           END IF;
           -- ER 9955304 - GSilva - 30/09/2010 - Fim
        END IF;
        -- 29311393 - End

        -- Bug 10218611 - SSimoes - 18/Nov/2010 - Inicio
        -- ER 8621766
        BEGIN
          SELECT '1'
            INTO v_validity_rules
            FROM cll_f189_fiscal_operations
           WHERE cfo_id = nvl(r_invoice_lines.cfo_id, l_cfo_id) -- BUG 19722064
             AND NVL(inactive_date, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_invoice_lines.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'CFO') OR
                  cfo_id IN (SELECT cfvr.validity_key_1
                               FROM cll_f189_validity_rules cfvr
                              WHERE cfvr.invoice_type_id =
                                    NVL(r_invoice_lines.invoice_type_id,
                                        l_invoice_type_id) -- BUG 19722064
                                AND cfvr.validity_type = 'CFO'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID INVLINECFO',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID INVLINECFO',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
        END;
        --
        BEGIN
          SELECT '1'
            INTO v_validity_rules
            FROM cll_f189_item_utilizations
           WHERE utilization_id =
                 nvl(r_invoice_lines.utilization_id, l_util_id) -- BUG 19722064
             AND NVL(inactive_date, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_invoice_lines.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'FISCAL UTILIZATION') OR
                  utilization_id IN
                  (SELECT cfvr.validity_key_1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_invoice_lines.invoice_type_id,
                              l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'FISCAL UTILIZATION'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID UTILIZATION',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID UTILIZATION',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
        END;
        --
        IF (r_invoice_lines.tributary_status_code) IS NOT NULL THEN
          -- 22012023 - Start
          BEGIN
            SELECT lookup_code
              INTO l_csticms_line
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_ICMS_TRIB_SIT_VAL'
               AND r_invoice_lines.invoice_date between start_date_active AND
                   NVL(end_date_active, r_invoice_lines.invoice_date + 1)
               AND enabled_flag = 'Y'; -- BUG 21804594
          EXCEPTION
            WHEN OTHERS THEN
              l_csticms_line := NULL;
          END;

          IF l_csticms_line = 'CSTICMSAB' THEN
            -- 22012023 - End

            BEGIN
              SELECT '1'
                INTO v_validity_rules
                FROM cll_f189_tributary_situation
              -- 22012023 - Start
               WHERE tributary_source_code || tributary_complement_code =
                     r_invoice_lines.tributary_status_code
                 AND tributary_receiver_code IS NULL
                 AND r_invoice_lines.invoice_date BETWEEN start_date AND
                     NVL(end_date, r_invoice_lines.invoice_date + 1)
                 AND NVL(inactive_flag, 'N') = 'N' -- BUG 21909282
                    --WHERE tributary_source_code   = SUBSTR (r_invoice_lines.tributary_status_code, 1, 1)
                    --AND tributary_complement_code = SUBSTR (r_invoice_lines.tributary_status_code, 2, 2)
                    --AND (NVL (inactive_date, SYSDATE + 1) > SYSDATE)
                    -- 22012023 - End
                 AND (NOT EXISTS
                      (SELECT 1
                         FROM cll_f189_validity_rules cfvr
                        WHERE cfvr.invoice_type_id =
                              NVL(r_invoice_lines.invoice_type_id,
                                  l_invoice_type_id) -- BUG 19722064
                          AND cfvr.validity_type = 'CST ICMS') OR
                      tributary_source_code || tributary_complement_code IN
                      (SELECT cfvr.validity_key_1
                         FROM cll_f189_validity_rules cfvr
                        WHERE cfvr.invoice_type_id =
                              NVL(r_invoice_lines.invoice_type_id,
                                  l_invoice_type_id) -- BUG 19722064
                          AND cfvr.validity_type = 'CST ICMS'));
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID TRIB STATUS CODE',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID TRIB STATUS CODE',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
            END;

            -- 22012023 - Start
            /* -- REVOGADO
                          ELSIF l_csticms_line = 'CSTICMSABC' THEN

                             BEGIN
                                SELECT '1'
                                INTO v_validity_rules
                                FROM cll_f189_tributary_situation
                                WHERE tributary_source_code||tributary_complement_code||tributary_receiver_code = r_invoice_lines.tributary_status_code
                                  AND tributary_receiver_code  IS NOT NULL
                                  AND r_invoice_lines.invoice_date BETWEEN start_date AND NVL(end_date,r_invoice_lines.invoice_date+1)
                                  AND NVL(inactive_flag, 'N') = 'N'  -- BUG 21909282
                                  AND (   NOT EXISTS (
                                         SELECT 1
                                         FROM cll_f189_validity_rules cfvr
                                         WHERE cfvr.invoice_type_id = NVL(r_invoice_lines.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                                           AND cfvr.validity_type = 'CST ICMS')
                                     OR tributary_source_code||
                                        tributary_complement_code||
                                        tributary_receiver_code IN (
                                         SELECT cfvr.validity_key_1
                                         FROM cll_f189_validity_rules cfvr
                                         WHERE cfvr.invoice_type_id = NVL(r_invoice_lines.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                                           AND cfvr.validity_type = 'CST ICMS'));
                             EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                   IF (p_interface = 'N') THEN
                                      cll_f189_check_holds_pkg.incluir_erro_hold
                                                                        (p_operation_id
                                                                        ,p_organization_id
                                                                        ,p_location_id
                                                                        ,'INVALID TRIB STATUS CODE'
                                                                        ,r_invoice_lines.invoice_id
                                                                        ,r_invoice_lines.invoice_line_id);
                                   ELSE
                                      cll_f189_check_holds_pkg.incluir_erro
                                                              (r_invoice_lines.interface_invoice_id
                                                              ,p_operation_id
                                                              ,'INVALID TRIB STATUS CODE'
                                                              ,r_invoice_lines.interface_invoice_line_id);
                                   END IF;
                             END;
            */ -- REVOGADO
          END IF;
          -- 22012023 - End
        END IF;

        -- 28730612 - Start
        /*-- 28468398 - 28505834 - Start
        IF NVL(r_invoice_lines.discount_net_amount,0) > 0
        AND ( NVL(r_invoice_lines.discount_amount,0) > 0
             OR NVL(r_invoice_lines.discount_percent,0) > 0) THEN

           IF (p_interface = 'N') THEN
             cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                        p_organization_id,
                                                        p_location_id,
                                                        'DISCOUNT CONFLICT',
                                                        r_invoice_lines.invoice_id,
                                                        r_invoice_lines.invoice_line_id);
           ELSE
             cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                   p_operation_id,
                                                   'DISCOUNT CONFLICT',
                                                   r_invoice_lines.interface_invoice_line_id);
           END IF;

        END IF;*/
        -- 28730612 - End

        --
        /*Withdrawn because the value of this discount may be greater than the total value of the line.
        IF NVL(r_invoice_lines.discount_net_amount,0) > NVL(r_invoice_lines.net_amount,0) THEN

           IF (p_interface = 'N') THEN
             cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                        p_organization_id,
                                                        p_location_id,
                                                        'DISCOUNT INVALID',
                                                        r_invoice_lines.invoice_id,
                                                        r_invoice_lines.invoice_line_id);
           ELSE
             cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                   p_operation_id,
                                                   'DISCOUNT INVALID',
                                                   r_invoice_lines.interface_invoice_line_id);
           END IF;

        END IF;*/
        -- 28468398 - 28505834 - End
        --
        -- 25890136 - Start
        IF r_invoice_lines.cest_code IS NOT NULL THEN

          -- 27323822 - Start
         /*IF LENGTH(r_invoice_lines.cest_code) = 1 THEN

            l_cest := '0' || to_char(r_invoice_lines.cest_code);

           ELSE

            l_cest := to_char(r_invoice_lines.cest_code);*/

           IF LENGTH(r_invoice_lines.cest_code) < 7 THEN

              l_cest := LPAD(to_char(r_invoice_lines.cest_code), 7, '0');

           ELSE

              l_cest := to_char(r_invoice_lines.cest_code);

           END IF;
          -- 27323822 - End

          l_cest_code := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES(p_lookup_type => 'JLBR_CEST_CODES',
                                                               p_lookup_code => l_cest);

          IF l_cest_code IS NULL THEN

            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'CEST CODE INVALID',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'CEST CODE INVALID',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;

          END IF;

        END IF;
        -- 25890136 - End

        -- ER 21804594 - Start
        IF cll_f189_fiscal_util_pkg.get_icms_inter_no_taxpayer(p_organization_id,
                                                               r_invoice_lines.invoice_type_id,
                                                               r_invoice_lines.entity_id,
                                                               r_invoice_lines.destination_state_id,
                                                               NVL(r_invoice_lines.icms_type,
                                                                   r_invoice_lines.invoice_icms_type)) THEN
          IF (NVL(r_invoice_lines.icms_fcp_amount, 0) > 0 AND
             NVL(r_invoice_lines.icms_sharing_dest_amount, 0) > 0 AND
             NVL(r_invoice_lines.icms_sharing_source_amount, 0) > 0 AND
             NVL(r_invoice_lines.icms_dest_base_amount, 0) > 0 AND
             NVL(r_invoice_lines.icms_fcp_dest_perc, 0) > 0 AND
             NVL(r_invoice_lines.icms_dest_tax, 0) > 0 AND
             NVL(r_invoice_lines.icms_sharing_inter_perc, 0) > 0) OR
             (NVL(r_invoice_lines.icms_fcp_amount, 0) = 0 AND
             NVL(r_invoice_lines.icms_sharing_dest_amount, 0) > 0 AND
             NVL(r_invoice_lines.icms_sharing_source_amount, 0) > 0 AND
             NVL(r_invoice_lines.icms_dest_base_amount, 0) > 0 AND
             NVL(r_invoice_lines.icms_fcp_dest_perc, 0) = 0 AND
             NVL(r_invoice_lines.icms_dest_tax, 0) > 0 AND
             NVL(r_invoice_lines.icms_sharing_inter_perc, 0) > 0) THEN

            IF r_invoice_lines.rec_diff_icms_rma_source_ccid IS NULL THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE RCDF ICMS RMA SOURCE CCID',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE RCDF ICMS RMA SOURCE CCID',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;

            IF r_invoice_lines.rec_diff_icms_rma_dest_ccid IS NULL THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE RCDF ICMS RMA DEST CCID',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE RCDF ICMS RMA DEST CCID',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;

            -- 26538915 - Start
            IF r_invoice_lines.diff_icms_rma_source_red_ccid IS NULL THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE ICMS RMA SOURCE RED CCID',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE ICMS RMA SOURCE RED CCID',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
            --
            IF r_invoice_lines.diff_icms_rma_dest_red_ccid IS NULL THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE ICMS RMA DEST RED CCID',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE ICMS RMA DEST RED CCID',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
            -- 26538915 - End

            IF r_invoice_lines.rec_fcp_rma_ccid IS NULL AND
               NVL(r_invoice_lines.icms_fcp_amount, 0) > 0 THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE REC FCP RMA CCID',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE REC FCP RMA CCID',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;

            -- BUG 26880062 26880945 Begin
            IF r_invoice_lines.red_fcp_rma_ccid IS NULL AND
               NVL(r_invoice_lines.icms_fcp_amount, 0) > 0 THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE RED FCP RMA CCID',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE RED FCP RMA CCID',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
            -- BUG 26880062 26880945 End


          ELSE
            -- 23278226 - Start
            -- Todos estao nulos
            IF (r_invoice_lines.ICMS_DEST_BASE_AMOUNT IS NULL AND
               r_invoice_lines.ICMS_FCP_DEST_PERC IS NULL AND
               r_invoice_lines.ICMS_DEST_TAX IS NULL AND
               r_invoice_lines.ICMS_SHARING_INTER_PERC IS NULL AND
               r_invoice_lines.ICMS_FCP_AMOUNT IS NULL AND
               r_invoice_lines.ICMS_SHARING_DEST_AMOUNT IS NULL AND
               r_invoice_lines.ICMS_SHARING_SOURCE_AMOUNT IS NULL) OR
              -- Todos estao com zeros
               (r_invoice_lines.ICMS_DEST_BASE_AMOUNT = 0 AND
               r_invoice_lines.ICMS_FCP_DEST_PERC = 0 AND
               r_invoice_lines.ICMS_DEST_TAX = 0 AND
               r_invoice_lines.ICMS_SHARING_INTER_PERC = 0 AND
               r_invoice_lines.ICMS_FCP_AMOUNT = 0 AND
               r_invoice_lines.ICMS_SHARING_DEST_AMOUNT = 0 AND
               r_invoice_lines.ICMS_SHARING_SOURCE_AMOUNT = 0) OR
              -- Begin BUG 23754818
              /*
                            -- Todos estao preenchidos com valores maiores que zero
                                             (NVL(r_invoice_lines.ICMS_DEST_BASE_AMOUNT,0)      > 0  AND
                                              NVL(r_invoice_lines.ICMS_FCP_DEST_PERC,0)         > 0  AND
                                              NVL(r_invoice_lines.ICMS_DEST_TAX,0)              > 0  AND
                                              NVL(r_invoice_lines.ICMS_SHARING_INTER_PERC,0)    > 0  AND
                                              NVL(r_invoice_lines.ICMS_FCP_AMOUNT,0)            > 0  AND
                                              NVL(r_invoice_lines.ICMS_SHARING_DEST_AMOUNT,0)   > 0  AND
                                              NVL(r_invoice_lines.ICMS_SHARING_SOURCE_AMOUNT,0) > 0) OR*/
              -- Todos estao preenchidos com valores maiores ou igual que zero
               (NVL(r_invoice_lines.ICMS_DEST_BASE_AMOUNT, 0) >= 0 AND
               NVL(r_invoice_lines.ICMS_FCP_DEST_PERC, 0) >= 0 AND
               NVL(r_invoice_lines.ICMS_DEST_TAX, 0) >= 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_INTER_PERC, 0) >= 0 AND
               NVL(r_invoice_lines.ICMS_FCP_AMOUNT, 0) >= 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_DEST_AMOUNT, 0) >= 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_SOURCE_AMOUNT, 0) >= 0) OR
              -- End BUG 23754818
              -- Campos do fundo de combate a pobreza sao zero e os outos preenchidos
               (r_invoice_lines.ICMS_DEST_BASE_AMOUNT = 0 AND
               r_invoice_lines.ICMS_FCP_DEST_PERC = 0 AND
               NVL(r_invoice_lines.ICMS_DEST_TAX, 0) > 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_INTER_PERC, 0) > 0 AND
               NVL(r_invoice_lines.ICMS_FCP_AMOUNT, 0) > 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_DEST_AMOUNT, 0) > 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_SOURCE_AMOUNT, 0) > 0) OR
              -- Campos do fundo de combate a pobreza sao nulos e os outos preenchidos
               (NVL(r_invoice_lines.ICMS_DEST_BASE_AMOUNT, 0) IS NULL AND
               NVL(r_invoice_lines.ICMS_FCP_DEST_PERC, 0) IS NULL AND
               NVL(r_invoice_lines.ICMS_DEST_TAX, 0) > 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_INTER_PERC, 0) > 0 AND
               NVL(r_invoice_lines.ICMS_FCP_AMOUNT, 0) > 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_DEST_AMOUNT, 0) > 0 AND
               NVL(r_invoice_lines.ICMS_SHARING_SOURCE_AMOUNT, 0) > 0) OR
              -- Begin BUG 23754818
              -- Campos estao nulos menos ICMS_SHARING_DEST_AMOUNT e ICMS_SHARING_SOURCE_AMOUNT
               (r_invoice_lines.ICMS_DEST_BASE_AMOUNT IS NULL AND
               r_invoice_lines.ICMS_FCP_DEST_PERC IS NULL AND
               r_invoice_lines.ICMS_DEST_TAX IS NULL AND
               r_invoice_lines.ICMS_SHARING_INTER_PERC IS NULL AND
               r_invoice_lines.ICMS_FCP_AMOUNT IS NULL AND
               r_invoice_lines.ICMS_SHARING_DEST_AMOUNT IS NOT NULL AND
               r_invoice_lines.ICMS_SHARING_SOURCE_AMOUNT IS NOT NULL) THEN
              -- End BUG 23754818
              NULL;
            ELSE
              -- Qualquer situacao diferente gerar retencao
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'ICMS INT NO TAX REQ',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ICMS INT NO TAX REQ',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
            -- 23278226 - End
          END IF;
        ELSIF (NVL(r_invoice_lines.icms_fcp_amount, 0) +
              NVL(r_invoice_lines.icms_sharing_dest_amount, 0) +
              NVL(r_invoice_lines.icms_sharing_source_amount, 0) +
              NVL(r_invoice_lines.icms_dest_base_amount, 0) +
              NVL(r_invoice_lines.icms_fcp_dest_perc, 0) +
              NVL(r_invoice_lines.icms_dest_tax, 0) +
              NVL(r_invoice_lines.icms_sharing_inter_perc, 0)) > 0 THEN

          IF (p_interface = 'N') THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'ICMS INT NO TAX INV',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'ICMS INT NO TAX INV',
                                                  r_invoice_lines.interface_invoice_line_id);
          END IF;
        END IF;
        -- ER 21804594 - End

        -- 25713076 - Start
        IF r_invoice_lines.requisition_type = 'RM' THEN

          IF r_invoice_lines.rec_fcp_st_rma_ccid IS NULL AND
             NVL(r_invoice_lines.fcp_st_amount, 0) > 0 THEN

            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE REC FCP ST RMA CCID',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE REC FCP ST RMA CCID',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;

          END IF;

          -- BUG 26880062 26880945 Begin
          IF r_invoice_lines.red_fcp_st_rma_ccid IS NULL AND
             NVL(r_invoice_lines.fcp_st_amount, 0) > 0 THEN

            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE RED FCP ST RMA CCID',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE RED FCP ST RMA CCID',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;

          END IF;
          -- BUG 26880062 26880945 End

        ELSE

          IF ((r_invoice_lines.fcp_liability_ccid IS NULL) OR
             (r_invoice_lines.fcp_asset_ccid IS NULL)) AND
             NVL(r_invoice_lines.fcp_amount, 0) > 0 THEN

            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE FCP CCID',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE FCP CCID',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;

          END IF;

          IF ((r_invoice_lines.fcp_st_liability_ccid IS NULL) OR
             (r_invoice_lines.fcp_st_asset_ccid IS NULL)) AND
             NVL(r_invoice_lines.fcp_st_amount, 0) > 0 THEN

            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE FCP ST CCID',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE FCP ST CCID',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;

          END IF;

        END IF;
        -- 25713076 - End

        -- ER 19597186 - Start
        IF r_invoice_lines.operation_fiscal_type IS NULL THEN
          l_operation_fiscal_type := '0';
        ELSE
          BEGIN
            SELECT '1'
              INTO l_operation_fiscal_type
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_OPERATION_FISCAL_TYPE'
               AND lookup_code = r_invoice_lines.operation_fiscal_type
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND NVL(enabled_flag, 'N') = 'Y';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_operation_fiscal_type := '0';
            WHEN OTHERS THEN
              l_operation_fiscal_type := '0';
          END;
        END IF;
        --
        IF p_interface = 'N' AND l_operation_fiscal_type = '0' THEN
          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                     p_organization_id,
                                                     p_location_id,
                                                     'INVALID OPFISCALTYPE',
                                                     r_invoice_lines.invoice_id,
                                                     r_invoice_lines.invoice_line_id);
        END IF;
        -- ER 19597186 - End
        --
        IF (r_invoice_lines.pis_tributary_code IS NOT NULL) THEN
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_PIS_TRIBUTARY_CODE'
               AND lookup_code = r_invoice_lines.pis_tributary_code
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST PIS') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST PIS'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV PIS TRIBUT CODE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INV PIS TRIBUT CODE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
          END;
        END IF;
        --
        IF (r_invoice_lines.cofins_tributary_code IS NOT NULL) THEN
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_COFINS_TRIBUTARY_CODE'
               AND lookup_code = r_invoice_lines.cofins_tributary_code
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST COFINS') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST COFINS'));

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV COFINS TRIBUT CODE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INV COFINS TRIBUT CODE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
          END;
        END IF;
        --
        IF (r_invoice_lines.ipi_tributary_code IS NOT NULL) THEN
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_IPI_TRIBUTARY_CODE'
               AND lookup_code = r_invoice_lines.ipi_tributary_code
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST IPI') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'CST IPI'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV IPI TRIBUT CODE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INV IPI TRIBUT CODE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
          END;
        END IF;
        --
        -- 22073362 - Start
        --IF NVL(l_return_customer_flag,'*') <> 'F' THEN -- 22533348

        IF (r_invoice_lines.ipi_tributary_type IS NOT NULL) THEN
          BEGIN
            SELECT '1'
              INTO l_ipi_tributary_type
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_IPI_TRIBUTARY_TYPE'
               AND lookup_code = r_invoice_lines.ipi_tributary_type
               AND sysdate < nvl(end_date_active, sysdate + 1)
               AND nvl(enabled_flag, 'N') = 'Y';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'IPI TRIBUTARY TYPE INVALID',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'IPI TRIBUTARY TYPE INVALID',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
          END;
        END IF;

        --END IF; -- 22533348
        -- 22073362 - End
        --
        -- ER 10037887 - Dmontesino - 04/06/2012 Start
        IF (r_invoice_lines.icms_tax_code IS NOT NULL) THEN
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_STATE_TRIBUT_CODE'
               AND lookup_code = r_invoice_lines.icms_tax_code
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'ICMS TAXABLE FLAG') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'ICMS TAXABLE FLAG'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID LINEICMSTAXCODE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID LINEICMSTAXCODE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
          END;
        END IF;
        -- ER 10037887 - Dmontesino - 04/06/2012 End
        --
        -- ER 9028781 - Start
        IF p_interface = 'N' THEN
          BEGIN
            SELECT UPPER(ri.icms_type), NVL(simplified_br_tax_flag, 'N')
              INTO l_icms_type, l_simplified_br_tax_flag
              FROM cll_f189_invoices ri
             WHERE ri.invoice_id = r_invoice_lines.invoice_id;
          EXCEPTION
            WHEN OTHERS THEN
              l_icms_type := NULL;
          END;
        ELSE
          BEGIN
            SELECT UPPER(ri.icms_type), NVL(simplified_br_tax_flag, 'N')
              INTO l_icms_type, l_simplified_br_tax_flag
              FROM cll_f189_invoice_iface_tmp ri
             WHERE ri.interface_invoice_id = r_invoice_lines.invoice_id;
          EXCEPTION
            WHEN OTHERS THEN
              l_icms_type := NULL;
          END;
        END IF;
        --
        IF p_interface = 'N' THEN
          IF l_icms_type = 'INV LINES INF' AND
             r_invoice_lines.icms_type IS NULL THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'ICMS TYPE INCORRECT',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          ELSIF l_icms_type <> 'INV LINES INF' AND
                r_invoice_lines.icms_type IS NOT NULL THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'ICMS TYPE INCORRECT',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          END IF;
        END IF;
        --
        IF l_icms_type = 'INV LINES INF' THEN
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_ICMS_TYPE'
               AND lookup_code = r_invoice_lines.icms_type
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id)
                        AND cfvr.validity_type = 'ICMS TYPE') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id)
                        AND cfvr.validity_type = 'ICMS TYPE'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID ICMSTYPE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);

              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID ICMSTYPE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
          END;
        END IF;
        -- ER 9028781 - End
        --
        -- ER 10037887 - Dmontesino - 04/06/2012 Start
        IF (r_invoice_lines.ipi_tax_code IS NOT NULL) THEN
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_FEDERAL_TRIBUT_CODE'
               AND lookup_code = r_invoice_lines.ipi_tax_code
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'IPI TAXABLE FLAG') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoice_lines.invoice_type_id,
                                l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'IPI TAXABLE FLAG'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID LINEIPITAXCODE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID LINEIPITAXCODE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
          END;
        END IF;
        -- ER 10037887 - Dmontesino - 04/06/2012 End
        --
        --
        -- 25591653 - Start
        BEGIN
          SELECT cllci.city_id
            INTO l_iss_city_id
            FROM cll_f189_cities cllci
           WHERE cllci.city_code = r_invoice_lines.iss_city_code;
        EXCEPTION
          WHEN no_data_found THEN
            l_iss_city_id := 0;
        END;
        -- 25591653 - End

        -- ER 10037887 - Dmontesino - 04/06/2012 Start
        IF (r_invoice_lines.city_service_type_rel_id IS NOT NULL) THEN
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM cll_f189_city_srv_type_rels rcstr,
                   cll_f189_service_types      rstm,
                   cll_f189_service_types      rstf
             WHERE rcstr.city_service_type_rel_id =
                   r_invoice_lines.city_service_type_rel_id
               AND rcstr.city_id = NVL(r_invoice_lines.iss_city_id,l_iss_city_id) -- 25591653
               AND rcstr.federal_service_type_id = rstf.service_type_id(+)
               AND rcstr.municipal_service_type_id =
                   rstm.service_type_id(+)
               AND (NOT EXISTS
                    (SELECT 'Y'
                       FROM cll_f189_validity_rules
                      WHERE invoice_type_id = r_invoice_lines.invoice_type_id
                        AND validity_type = 'SERVICE TYPE') OR
                    (to_char(rcstr.federal_service_type_id) IN
                    (SELECT validity_key_1
                        FROM cll_f189_validity_rules
                       WHERE invoice_type_id =
                             NVL(r_invoice_lines.invoice_type_id,
                                 l_invoice_type_id) -- BUG 19722064
                         AND validity_type = 'SERVICE TYPE') OR
                    to_char(rcstr.municipal_service_type_id) IN
                    (SELECT validity_key_1
                        FROM cll_f189_validity_rules
                       WHERE invoice_type_id =
                             NVL(r_invoice_lines.invoice_type_id,
                                 l_invoice_type_id) -- BUG 19722064
                         AND validity_type = 'SERVICE TYPE')));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID SERVTYPE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID SERVTYPE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
          END;


        END IF;
        -- ER 10037887 - Dmontesino - 04/06/2012 End
        --
        -- Bug 10218611 - SSimoes - 18/Nov/2010 - Fim


          -- ER 6519914 - SSimoes - 15/05/2008 - Inicio
          -- Consistencia do Valor da Base do ISS - Negativo
          IF NVL(r_invoice_lines.iss_base_amount,0) < 0 THEN -- 25591653
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ISS BASE NEGATIVE',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              BEGIN
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ISS BASE NEGATIVE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END;
            END IF;
          END IF;
          -- Consistencia do Valor do ISS - Negativo
          IF NVL(r_invoice_lines.iss_tax_amount,0) < 0 THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ISS AMOUNT NEGATIVE',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              BEGIN
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ISS AMOUNT NEGATIVE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END;
            END IF;
          END IF;

          -- 25028715 - Start
          IF r_invoice_lines.include_iss_flag = 'Y' THEN

             -- 25494912 - Start
             BEGIN
                SELECT rc.iss_tax_type
                  INTO l_line_iss_tax_type
                  FROM cll_f189_city_srv_type_rels rc                                          ---- 25591653
                  ---- FROM CLL_F189_CITIES rc, CLL_F189_fiscal_entities_all rfea              ---- 25591653
                 WHERE rc.city_service_type_rel_id = r_invoice_lines.city_service_type_rel_id; ---- 25591653
                  ---- WHERE rfea.location_id = p_location_id                                  ---- 25591653
                  ----   AND rfea.city_id = rc.city_id;                                        ---- 25591653
             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   l_line_iss_tax_type := NULL;
                WHEN OTHERS THEN
                   l_line_iss_tax_type := NULL;
             END;
             -- 25494912 - End

--- 25591653 begin
             l_line_city_id := NVL(r_invoice_lines.iss_city_id,l_iss_city_id);
---             BEGIN
---                -- 26143868
---                SELECT rc.city_id
---                   --,rc.iss_tax_type  -- 25494912
---                  INTO l_line_city_id
---                   --,l_line_iss_tax_type -- 25494912
---                FROM cll_f189_fiscal_entities_all rfea, cll_f189_cities rc
---                WHERE rfea.entity_id = r_invoice_lines.entity_id
---                   AND rfea.city_id = rc.city_id;
---                -- 26143868 - Start
---             EXCEPTION
---                WHEN NO_DATA_FOUND THEN
---                   l_line_city_id := NULL;
---                WHEN OTHERS THEN
---                   l_line_city_id := NULL;
---             END;
---             -- 26143868 - End
--- 25591653 end

           IF l_line_iss_tax_type IN ('NORMAL', 'EXEMPT') THEN

              -- 25591653 - Start
              --IF CLL_F189_FISCAL_UTIL_PKG.GET_FISCAL_OBLIGATION_ISS(p_location_id,
              --                                                      l_line_city_id) THEN

              IF CLL_F189_ISS_TAX_PKG.GET_FISCAL_OBLIGATION_ISS( p_location_id
                                                               ,l_line_city_id ) THEN

                /*IF r_invoice_lines.iss_fo_base_amount > 0 AND NVL(r_invoice_lines.iss_base_amount,0) > 0 THEN

                      IF p_interface = 'N' THEN
                         cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                    p_organization_id,
                                                                    p_location_id,
                                                                    'DIVERG ISS AMOUNT FO',
                                                                    r_invoice_lines.invoice_id,
                                                                    r_invoice_lines.invoice_line_id);
                      ELSE
                         cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                               p_operation_id,
                                                               'DIVERG ISS AMOUNT FO',
                                                               r_invoice_lines.interface_invoice_line_id);
                      END IF;

                END IF; */
                -- 25591653 - End

                 IF NVL(r_invoice_lines.iss_base_amount,0) > 0
                 OR NVL(r_invoice_lines.iss_tax_rate,0) > 0
                 OR NVL(r_invoice_lines.iss_tax_amount,0) > 0 THEN

                    IF p_interface = 'N' THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                  'DIVERG ISS INFORMATION',
                                                                  r_invoice_lines.invoice_id,
                                                                  r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                             'DIVERG ISS INFORMATION',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;

                 END IF;

                 --IF (NVL(r_invoice_lines.iss_tax_amount,0) = 0 OR
                 --    NVL(r_invoice_lines.iss_base_amount,0) = 0 OR
                 --    NVL(r_invoice_lines.iss_tax_rate,0) = 0) THEN

                 IF (NVL(r_invoice_lines.iss_fo_base_amount,0) = 0 OR
                     NVL(r_invoice_lines.iss_fo_tax_rate,0) = 0 OR
                     NVL(r_invoice_lines.iss_fo_amount,0) = 0) THEN
                -- 25591653 - End

                    IF p_interface = 'N' THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                  'FISCAL OBLIGATION ISS',
                                                                  r_invoice_lines.invoice_id,
                                                                  r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                             'FISCAL OBLIGATION ISS',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;

                 END IF;

              -- 25591653 - Start
              ELSE

                 IF NVL(r_invoice_lines.iss_fo_base_amount,0) > 0
                 OR NVL(r_invoice_lines.iss_fo_tax_rate,0) > 0
                 OR NVL(r_invoice_lines.iss_fo_amount,0) > 0
                 OR NVL(r_invoice_lines.iss_base_amount,0) > 0
                 OR NVL(r_invoice_lines.iss_tax_rate,0) > 0
                 OR NVL(r_invoice_lines.iss_tax_amount,0) > 0 THEN

                    IF p_interface = 'N' THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                  'DIVERG ISS INFORMATION',
                                                                  r_invoice_lines.invoice_id,
                                                                  r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                             'DIVERG ISS INFORMATION',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;

                 END IF;
                 -- 25591653 - End

              END IF;

           -- 25591653 begin
           ELSIF l_line_iss_tax_type = 'SUBSTITUTE' THEN

              IF NVL(r_invoice_lines.iss_fo_base_amount,0) > 0
                 OR NVL(r_invoice_lines.iss_fo_tax_rate,0) > 0
                 OR NVL(r_invoice_lines.iss_fo_amount,0) > 0 THEN

                 IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'DIVERG ISS INFORMATION',
                                                               r_invoice_lines.invoice_id,
                                                               r_invoice_lines.invoice_line_id);
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                          p_operation_id,
                                                          'DIVERG ISS INFORMATION',
                                                          r_invoice_lines.interface_invoice_line_id);
                 END IF;

              END IF;


             IF r_invoice_lines.iss_base_amount IS NULL THEN
                 IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'NULL LINEISSBASE',
                                                               r_invoice_lines.invoice_id,
                                                               r_invoice_lines.invoice_line_id);
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                          p_operation_id,
                                                          'NULL LINEISSBASE',
                                                          r_invoice_lines.interface_invoice_line_id);
                 END IF;
              END IF;
              --
              IF r_invoice_lines.iss_tax_rate IS NULL THEN
                 IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'NULL LINEISSTAX',
                                                               r_invoice_lines.invoice_id,
                                                               r_invoice_lines.invoice_line_id);
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                          p_operation_id,
                                                          'NULL LINEISSTAX',
                                                          r_invoice_lines.interface_invoice_line_id);
                 END IF;
              END IF;
              --
              IF r_invoice_lines.iss_tax_amount IS NULL THEN
                 IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'NULL LINEISSAMT',
                                                               r_invoice_lines.invoice_id,
                                                               r_invoice_lines.invoice_line_id);
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                          p_operation_id,
                                                          'NULL LINEISSAMT',
                                                          r_invoice_lines.interface_invoice_line_id);
                 END IF;
           END IF; --IF l_line_iss_tax_type = 'SUBSTITUTE' THEN
             --- 25591653 end

           END IF;

          END IF;
          -- 25028715 - End

          -- ER 6519914 - SSimoes - 15/05/2008 - Fim
          --
          -- 27746405 - Start
          IF ( NVL(r_invoice_lines.fundersul_own_flag,'N') = 'N'
          AND NVL(r_invoice_lines.fundersul_sup_part_flag,'N') = 'N' ) THEN


             IF NVL(r_invoice_lines.fundersul_amount,0) > 0 THEN

                IF p_interface = 'N' THEN
                   cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                              p_organization_id,
                                                              p_location_id,
                                                              'INVALID FUNDERSUL AMOUNT',
                                                              r_invoice_lines.invoice_id,
                                                              r_invoice_lines.invoice_line_id);
                ELSE
                   cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                         p_operation_id,
                                                         'INVALID FUNDERSUL AMOUNT',
                                                         r_invoice_lines.interface_invoice_line_id);
                END IF;

             END IF;

             IF NVL(r_invoice_lines.fundersul_additional_amount,0) > 0 THEN

                IF p_interface = 'N' THEN
                   cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                              p_organization_id,
                                                              p_location_id,
                                                              'INVALID FUNDERSUL ADDIT AMOUNT',
                                                              r_invoice_lines.invoice_id,
                                                              r_invoice_lines.invoice_line_id);
                ELSE
                   cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                         p_operation_id,
                                                         'INVALID FUNDERSUL ADDIT AMOUNT',
                                                         r_invoice_lines.interface_invoice_line_id);
                END IF;

             END IF;

          ELSE

             IF NVL(r_invoice_lines.fundersul_amount,0) > 0 THEN

                IF r_invoice_lines.fundersul_code_combination_id IS NULL THEN

                   IF p_interface = 'N' THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                 'NONE FUNDERSUL TO COLLECT CCID',
                                                                 r_invoice_lines.invoice_id,
                                                                 r_invoice_lines.invoice_line_id);
                   END IF;

                END IF;

             END IF;

             IF NVL(r_invoice_lines.fundersul_additional_amount,0) > 0 THEN

                IF r_invoice_lines.fundersul_expense_ccid IS NULL THEN

                   IF p_interface = 'N' THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                 'NONE FUNDERSUL EXPENSE CCID',
                                                                 r_invoice_lines.invoice_id,
                                                                 r_invoice_lines.invoice_line_id);
                   END IF;

                END IF;

             END IF;

          END IF;
          -- 27746405 - End
          --
          -- Bug 4115240 - Start
          IF r_invoice_lines.icms_base < 0 THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ICMS BASE NEGATIVE',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              BEGIN
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ICMS BASE NEGATIVE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END;
            END IF;
          END IF;
          --
          IF r_invoice_lines.icms_amount < 0 THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ICMS AMOUNT NEGATIVE',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              BEGIN
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ICMS AMOUNT NEGATIVE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END;
            END IF;
          END IF;
          -- Bug 4115240 - End


          --
          -- ER 9028781 - Start
          IF l_icms_type = 'INV LINES INF' THEN
            BEGIN
              IF p_interface = 'N' THEN

                IF NVL(r_invoice_lines.presumed_icms_tax_amount, 0) = 0 THEN
                  SELECT COUNT(1)
                    INTO l_icms_count
                    FROM cll_f189_invoices a, cll_f189_invoice_lines b
                   WHERE a.invoice_id = b.invoice_id
                        -- QA Issue 7053 - Start
                        --AND a.invoice_id = r_invoice_lines.invoice_id
                     AND b.invoice_id = r_invoice_lines.invoice_id
                     AND b.invoice_line_id = r_invoice_lines.invoice_line_id
                        -- QA Issue 7053 - End
                     AND b.icms_type IN ('EXEMPT', 'NOT APPLIED')
                     AND b.icms_tax_code <> '2';

                  IF l_icms_count > 0 AND l_simplified_br_tax_flag = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'DIFF INDICAD TRIBUTARIO',
                                                               r_invoice_lines.invoice_id,
                                                               r_invoice_lines.invoice_line_id);
                  END IF;
                END IF;
              ELSE
                IF NVL(r_invoice_lines.presumed_icms_tax_amount, 0) = 0 THEN
                  SELECT COUNT(1)
                    INTO l_icms_count
                    FROM cll_f189_invoices_interface  a,
                         CLL_F189_INVOICE_LINES_IFACE b
                   WHERE a.interface_invoice_id = b.interface_invoice_id
                        -- QA Issue 7053 - Start
                        -- AND a.interface_invoice_id = r_invoice_lines.invoice_id
                     AND b.interface_invoice_id =
                         r_invoice_lines.invoice_id
                     AND b.interface_invoice_line_id =
                         r_invoice_lines.invoice_line_id
                        -- QA Issue 7053 - End
                     AND b.icms_type IN ('EXEMPT', 'NOT APPLIED')
                     AND b.icms_tax_code <> '2';
                  --
                  IF l_icms_count > 0 AND l_simplified_br_tax_flag = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                          p_operation_id,
                                                          'DIFF INDICAD TRIBUTARIO',
                                                          r_invoice_lines.invoice_line_id);
                  END IF;
                END IF;
              END IF;
            END;
          END IF;
          -- ER 9028781 - End
          --


        IF r_invoice_lines.line_location_id IS NOT NULL THEN
          BEGIN
            SELECT pll.po_header_id, NVL(ph.currency_code, '@@@')
              INTO w_aux_po_header, w_aux_currency_code_po
              FROM po_line_locations_all pll, po_headers_all ph
             WHERE pll.line_location_id = r_invoice_lines.line_location_id
               AND pll.po_header_id = ph.po_header_id;
          END;
          --
          BEGIN
            SELECT gsb.currency_code
              INTO w_aux_currency_code_org
              FROM org_organization_definitions ood, gl_sets_of_books gsb
             WHERE ood.organization_id = p_organization_id
               AND ood.set_of_books_id = gsb.set_of_books_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              w_aux_currency_code_org := NULL;
          END;
          IF (p_interface = 'N') THEN
            -- Bug 4655961 AIrmer 14/10/2005
            BEGIN
              SELECT ri.user_defined_conversion_rate,
                     rs.national_state,
                     NVL(ri.po_currency_code, w_aux_currency_code_org)
                INTO w_aux_ud_conv_rate, w_aux_national_state, x_moeda_rec
                FROM cll_f189_states              rs,
                     cll_f189_fiscal_entities_all rfea,
                     cll_f189_invoices            ri
               WHERE ri.invoice_id = r_invoice_lines.invoice_id
                 AND ri.entity_id = rfea.entity_id
                 AND rfea.state_id = rs.state_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                w_aux_ud_conv_rate := NULL;
            END;
            -- Bug 4655961 AIrmer 14/10/2005
          ELSE
            BEGIN
              SELECT rii.user_defined_conversion_rate,
                     rs.national_state,
                     NVL(rii.po_currency_code, w_aux_currency_code_org)
                INTO w_aux_ud_conv_rate, w_aux_national_state, x_moeda_rec
                FROM cll_f189_states              rs,
                     cll_f189_fiscal_entities_all rfea,
                     cll_f189_invoices_interface  rii
               WHERE rii.interface_invoice_id =
                     r_invoice_lines.interface_invoice_id
                 AND rii.entity_id = rfea.entity_id
                 AND rfea.state_id = rs.state_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                w_aux_ud_conv_rate := NULL;
            END;
          END IF;
          -- Bug 10218611 - SSimoes - 18/Nov/2010 - Inicio
          /*
           Mover essa validacao (-- ER 8621766) fora do if de linhas com pedido.
          */
          -- Bug 10218611 - SSimoes - 18/Nov/2010 - Fim
          -- ER 7483063 AIrmer 16/04/2009
          --
          BEGIN
            --
            IF (r_invoice_lines.complex_service_flag = 'Y') THEN
              BEGIN
                SELECT pll.payment_type
                  INTO l_payment_type
                  FROM po_line_locations_all pll
                 WHERE pll.line_location_id =
                       r_invoice_lines.line_location_id
                   AND pll.payment_type IN ('MILESTONE', 'LUMPSUM', 'RATE');
              EXCEPTION
                WHEN OTHERS THEN
                  l_payment_type := NULL;
              END;
              --
              IF (l_payment_type IS NULL) THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'DOCUMENT STYLE NOT FOUND', -- PO Document Style not found
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSIF (p_interface = 'Y') THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'DOCUMENT STYLE NOT FOUND', -- PO Document Style not found
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;
              --
              -- VERIFY IF THERE WC LINKED TO THE LINE THAT'S BEING RECEIVED
              --
              BEGIN
                SELECT COUNT(*)
                  INTO l_count_wc
                  FROM cll_f189_work_confs rwc
                 WHERE rwc.organization_id = p_organization_id
                   AND rwc.invoice_id = r_invoice_lines.invoice_id
                   AND rwc.invoice_line_id =
                       r_invoice_lines.invoice_line_id;
              END;
              --
              IF (l_count_wc <= 0) THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE WORK CONFIRM RELATED',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSIF (p_interface = 'Y') THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE WORK CONFIRM RELATED',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;
              --
              -- Bug 8591473 12/06/09 rvicente - BEGIN
              -- VERIFY IF THERE MORE THAN ONE SHIPMENT TYPE FOR THE INVOICE
              --
              BEGIN
                SELECT COUNT(*)
                  INTO l_count_standard
                  FROM po_line_locations_all pll
                 WHERE pll.line_location_id =
                       r_invoice_lines.line_location_id
                   AND pll.shipment_type = 'STANDARD';
              EXCEPTION
                WHEN OTHERS THEN
                  l_count_standard := 0;
              END;
              l_total_standard := l_total_standard + l_count_standard;
              --
              BEGIN
                SELECT COUNT(*)
                  INTO l_count_prepayment
                  FROM po_line_locations_all pll
                 WHERE pll.line_location_id =
                       r_invoice_lines.line_location_id
                   AND pll.shipment_type = 'PREPAYMENT';
              EXCEPTION
                WHEN OTHERS THEN
                  l_count_prepayment := 0;
              END;
              l_total_prepayment := l_total_prepayment + l_count_prepayment;
              --
              IF (l_total_standard <> 0 AND l_total_prepayment <> 0) THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'MORE THAN ONE SHIPMENT TYPE',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSIF (p_interface = 'Y') THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'MORE THAN ONE SHIPMENT TYPE',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;
              -- Bug 8591473 12/06/09 rvicente - END
              --
              -- VERIFY IF SUM OF VALUES IN WCs LINKED IS EQUAL TO THE LINE THAT'S BEING RECEIVED
              --
              BEGIN
                SELECT NVL(SUM(rwc.amount), 0), NVL(SUM(rwc.quantity), 0)
                  INTO l_rwc_amount, l_rwc_quantity
                  FROM cll_f189_work_confs rwc
                 WHERE rwc.organization_id = p_organization_id
                   AND rwc.invoice_id = r_invoice_lines.invoice_id
                   AND rwc.invoice_line_id =
                       r_invoice_lines.invoice_line_id;
              EXCEPTION
                WHEN OTHERS THEN
                  l_rwc_amount   := 0;
                  l_rwc_quantity := 0;
              END;
              --
              IF (l_payment_type IN ('MILESTONE', 'LUMPSUM'))
                -- Patch 8808223 BEGIN
                --AND (r_invoice_lines.total_amount <> l_rwc_amount) THEN
                 AND ROUND(r_invoice_lines.total_amount, arr) <>
                 ROUND(l_rwc_amount, arr) AND
                 TRUNC(r_invoice_lines.total_amount, arr) <>
                 TRUNC(l_rwc_amount, arr) THEN
                -- Patch 8808223 BEGIN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'DIFF WORK CONF AMT', -- Diff Work Confirmation Amount
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSIF (p_interface = 'Y') THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'DIFF WORK CONF AMT', -- Diff Work Confirmation Amount
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
                --
              ELSIF (l_payment_type = 'RATE') AND
                    (r_invoice_lines.quantity <> l_rwc_quantity) THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'DIFF WORK CONF QTY', -- Diff Work Confirmation Quantity
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSIF (p_interface = 'Y') THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'DIFF WORK CONF QTY', -- Diff Work Confirmation Quantity
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;
              --
              -- VERIFY IF THERE SAME WC LINKED MORE THAN ONE TIME TO THE SAME RI LINE
              --
              BEGIN
                SELECT cfwc.invoice_line_id,
                       cfwc.shipment_line_id,
                       count('1')
                  INTO l_invoice_line_id, l_shipment_line_id, l_count_line
                  FROM cll_f189_work_confs cfwc
                 WHERE cfwc.organization_id = p_organization_id
                   AND cfwc.operation_id = p_operation_id
                 GROUP BY cfwc.invoice_line_id, cfwc.shipment_line_id
                HAVING count('1') > 1;
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'SAME WORK CONFIRM RELATED', -- Same Work Confirmation linked more than once
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSIF (p_interface = 'Y') THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'SAME WORK CONFIRM RELATED', -- Same Work Confirmation linked twice
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
                WHEN TOO_MANY_ROWS THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'SAME WORK CONFIRM RELATED', -- Same Work Confirmation linked more than once
                                                               r_invoice_lines.invoice_id,
                                                               r_invoice_lines.invoice_line_id);
                  ELSIF (p_interface = 'Y') THEN
                    cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                          p_operation_id,
                                                          'SAME WORK CONFIRM RELATED', -- Same Work Confirmation linked twice
                                                          r_invoice_lines.interface_invoice_line_id);
                  END IF;
                WHEN OTHERS THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'SAME WORK CONFIRM RELATED', -- Same Work Confirmation linked twice
                                                               r_invoice_lines.invoice_id,
                                                               r_invoice_lines.invoice_line_id);
                  ELSIF (p_interface = 'Y') THEN
                    cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                          p_operation_id,
                                                          'SAME WORK CONFIRM RELATED', -- Same Work Confirmation linked twice
                                                          r_invoice_lines.interface_invoice_line_id);
                  END IF;
              END;
              --
              -- START BUG 12732658 LMEDEIROS
              -- VERIFY IF THERE IS OTHERS RECEIPTS LINKED TO SAME WC
              --
              BEGIN
                SELECT COUNT(1)
                  INTO vCountReceipt
                  FROM cll_f189_work_confs       c1,
                       cll_f189_work_confs       c2,
                       cll_f189_entry_operations reo
                 WHERE c1.shipment_line_id = c2.shipment_line_id
                   AND c1.shipment_header_id = c2.shipment_header_id
                   AND c2.organization_id = c1.organization_id
                   AND c2.operation_id <> c1.operation_id
                   AND c1.operation_id = p_operation_id
                   AND c1.organization_id = p_organization_id
                   AND reo.organization_id = c2.organization_id -- >> BUG 17751758 - Egini - 28/01/2014 << --
                   AND NVL(c2.return_flag, '0') <> 'S'
                   AND reo.operation_id = c2.operation_id
                   AND reo.status IN ('COMPLETE', 'IN PROCESS')
                   AND nvl(reo.reversion_flag, 'N') <> 'R'; -- >> BUG 17751758 - Egini - 28/01/2014 << --
              END;
              --
              IF (vCountReceipt > 0) THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'MORE THAN ONE RECEIPT',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSIF (p_interface = 'Y') THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'MORE THAN ONE RECEIPT',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;
              -- END BUG 12732658 LMEDEIROS
            END IF;
            -- End r_invoice_lines.complex_service_flag = 'Y'
          END;
          --
          w_table_associated := 1; -- Bug 5018577 AIrmer 13/02/2006
          IF x_hold_currency_different_po = 'Y' AND
             x_moeda_rec <> w_aux_currency_code_po AND
             w_aux_ud_conv_rate > 0 THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'CURRENCY PO <> REC',
                                                         NULL,
                                                         NULL);
            ELSE
              -- Bug.4063693
              cll_f189_check_holds_pkg.incluir_erro(
                                                    --NULL                                  -- Bug.4063693 -- Bug 5018577 AIrmer 13/02/2006
                                                    r_invoice_lines.interface_invoice_id, -- Bug 5018577 AIrmer 13/02/2006
                                                    p_operation_id, -- Bug.4063693
                                                    'CURRENCY PO <> REC', -- Bug.4063693
                                                    NULL); -- Bug.4063693
            END IF;
          END IF;
          --
          IF r_invoice_lines.return_customer_flag <> 'F' THEN
            -- Bug 8511032 AIrmer 19/05/2009
            IF (r_invoice_lines.ipi_tributary_code IS NOT NULL) AND
               (r_invoice_lines.ipi_tributary_code_flag = 'Y') AND
               (SUBSTR(r_invoice_lines.ipi_tributary_code, 1, 1) NOT IN
               ('0', '1', '2', '3', '4')) THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID IPI TRIB CODE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSIF (p_interface = 'Y') THEN
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID IPI TRIB CODE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
            --
            IF w_aux_currency_code_po <> w_aux_currency_code_org THEN
              IF w_aux_ud_conv_rate IS NULL OR w_aux_ud_conv_rate = 0 THEN
                IF w_aux_national_state = 'Y' THEN
                  IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'UD CONV RATE INVALID',
                                                               NULL,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro( --NULL  -- Bug 5018577 AIrmer 13/02/2006
                                                          r_invoice_lines.interface_invoice_id, -- Bug 5018577 AIrmer 13/02/2006
                                                          p_operation_id,
                                                          'UD CONV RATE INVALID',
                                                          NULL);
                  END IF;
                END IF;
              ELSE
                IF r_invoice_lines.foreign_currency_usage = 'N' THEN
                  IF p_interface = 'Y' THEN
                    cll_f189_check_holds_pkg.incluir_erro( --NULL   -- Bug 5018577 AIrmer 13/02/2006
                                                          r_invoice_lines.interface_invoice_id, -- Bug 5018577 AIrmer 13/02/2006
                                                          p_operation_id,
                                                          'UD CONV RATE INVALID',
                                                          NULL);
                  END IF;
                END IF;
              END IF;
            END IF;
            -- Bug 5018577 AIrmer 13/02/2006
            IF w_aux_currency_code_po = w_aux_currency_code_org THEN
              IF w_aux_ud_conv_rate IS NOT NULL AND w_aux_ud_conv_rate <> 0 THEN
                IF w_aux_national_state = 'Y' THEN
                  IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'UD CONV RATE INVALID',
                                                               NULL,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro( --NULL   -- Bug 5018577 AIrmer 13/02/2006
                                                          r_invoice_lines.interface_invoice_id, -- Bug 5018577 AIrmer 13/02/2006
                                                          p_operation_id,
                                                          'UD CONV RATE INVALID',
                                                          NULL);
                  END IF;
                END IF;
              END IF;
            END IF;
            --
          END IF;
          w_table_associated := 2; -- Bug 5018577 AIrmer 13/02/2006

          --24681121 - Start
          SELECT count(1)
            INTO l_hold_discrete_job
            FROM po_distributions_all pod, wip_discrete_jobs wdj
           WHERE pod.po_header_id = w_aux_po_header
             AND pod.wip_entity_id = wdj.wip_entity_id
             AND wdj.status_type = 6 -- 6 = On Hold
             AND wdj.organization_id = p_organization_id;

          IF l_hold_discrete_job > 0 THEN

            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'WORKER ORDER HOLD',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'WORKER ORDER HOLD',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;

          END IF;
          --24681121 - End
          --
          BEGIN
            -- MRC 11.0.3  03/08/1999
            UPDATE po_distributions_all dist
               SET rate = 1
             WHERE po_header_id = w_aux_po_header
               AND rate IS NULL
               AND EXISTS
             (SELECT 'x'
                      FROM po_headers_all head
                     WHERE dist.po_header_id = head.po_header_id
                       AND head.rate_type IS NOT NULL
                       AND head.po_header_id = w_aux_po_header);
          END;
        END IF;
        --
        BEGIN
          x_query := 1;
          --
          EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM gl_code_combinations' ||
                            ' WHERE code_combination_id = :b1' || ' AND ' ||
                            p_segment || ' <> :b2'
            INTO v_count
            USING r_invoice_lines.db_code_combination_id, v_balance_seg;
          --
          IF (l_allow_mult_bal_segs = 'N') THEN
            -- ER 6399212 AIrmer 26/12/2007
            IF v_count > 0 THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'ERROR COMB INVOICE',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ERROR COMB INVOICE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
          END IF; -- ER 6399212 AIrmer 26/12/2007
          x_query := 2;
          --
          EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM po_distributions_all pd,gl_code_combinations gcc' ||
                            ' WHERE pd.line_location_id = :b1' ||
                            ' AND pd.code_combination_id = gcc.code_combination_id' ||
                            ' AND gcc.' || p_segment || ' <> :b2'
            INTO v_count
            USING r_invoice_lines.line_location_id, v_balance_seg;
          IF (l_allow_mult_bal_segs = 'N') THEN
            -- ER 6399212 AIrmer 26/12/2007
            IF v_count > 0 THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'ERROR COMB PO',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ERROR COMB PO',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
          END IF; -- ER 6399212 AIrmer 26/12/2007
          x_query := 3;
          --
          EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM po_req_distributions prd,gl_code_combinations gcc' ||
                            ' WHERE prd.requisition_line_id = :b1' ||
                            ' AND prd.code_combination_id = gcc.code_combination_id' ||
                            ' AND gcc.' || p_segment || ' <> :b2'
            INTO v_count
            USING r_invoice_lines.requisition_line_id, v_balance_seg;

          IF (l_allow_mult_bal_segs = 'N') THEN
            -- ER 6399212 AIrmer 26/12/2007
            IF v_count > 0 THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'ERROR COMB REQ',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ERROR COMB REQ',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
          END IF; -- ER 6399212 AIrmer 26/12/2007
        EXCEPTION
          WHEN OTHERS THEN
            raise_application_error(-20524,
                                    SQLERRM || '***********************' ||
                                    ' EXECUTE IMMEDIATE, QUERY -> ' ||
                                    TO_CHAR(x_query) ||
                                    '***********************');
        END;
        --
        IF p_interface = 'N' THEN
          BEGIN
            SELECT NVL(dollar_invoice_amount, 0)
              INTO v_dol_total_amount
              FROM cll_f189_invoices
             WHERE invoice_id = r_invoice_lines.invoice_id;
          EXCEPTION
            WHEN OTHERS THEN
              raise_application_error(-20523,
                                      SQLERRM || '***********************' ||
                                      ' Select invoice total amount US ' ||
                                      '***********************');
          END;
          --
          BEGIN
            SELECT NVL(SUM(ROUND((quantity * NVL(dollar_unit_price, 0)) *
                                 (1 + (NVL(ipi_tax, 0) / 100)),
                                 2)),
                       0),
                   NVL(SUM((quantity * NVL(dollar_unit_price, 0)) *
                           (1 + (NVL(ipi_tax, 0) / 100))),
                       0)
              INTO v_sum_dol_total_amount, v_sum_dol_total_amount_2
              FROM cll_f189_invoice_lines
             WHERE invoice_id = r_invoice_lines.invoice_id;
          END;
        END IF;
        -- ER 8553947 - SSimoes - 21/10/2009 - Inicio
        IF (r_invoice_lines.return_customer_flag = 'F' OR
           r_invoice_lines.operation_type = 'S') AND
           SUBSTR(r_invoice_lines.cfo_code, 1, 1) IN ('1', '2', '3') THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'INVALID CFOP',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'INVALID CFOP',
                                                  r_invoice_lines.interface_invoice_line_id);
          END IF;
        END IF;
        -- ER 8553947 - SSimoes - 21/10/2009 - Fim
        --
        -- Bug 14160294 - Start
        IF r_invoice_lines.return_customer_flag = 'F' THEN
          --
          BEGIN
            SELECT DISTINCT invoice_parent_line_id
              INTO l_invoice_parent_line_id
              FROM cll_f189_invoice_line_parents
             WHERE invoice_line_id = r_invoice_lines.invoice_line_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_invoice_parent_line_id := NULL;
            WHEN OTHERS THEN
              raise_application_error(-20998,
                                      SQLERRM || '***********************' ||
                                      ' Select Invoice line parents' ||
                                      '***********************');
          END;
          --
          l_returned_lines := cll_f189_vendor_return_pkg.completely_returned_lines(l_invoice_parent_line_id,
                                                                                   r_invoice_lines.invoice_line_id);
          --
          IF l_returned_lines THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'QTY ALREADY RETURNED',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
            --
          END IF;
          --
        END IF;
        --
        -- Bug 14160294 - End
        --
        IF r_invoice_lines.return_customer_flag = 'F' THEN
          IF r_invoice_lines.item_id IS NULL AND
             r_invoice_lines.generate_return_invoice = 'Y' THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ITEM NOT REGISTERED',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            END IF;
          END IF;
          --
          BEGIN
            SELECT ril.quantity
              INTO x_parent_quantity
              FROM cll_f189_invoice_lines    ril,
                   cll_f189_invoices         ri,
                   cll_f189_entry_operations reo
             WHERE reo.status IN ('COMPLETE', 'PROCESSING')
               AND reo.operation_id = ri.operation_id
               AND reo.organization_id = ri.organization_id
               AND ril.invoice_id = ri.invoice_id
               AND ril.invoice_line_id =
                   (SELECT DISTINCT invoice_parent_line_id
                      FROM cll_f189_invoice_line_parents
                     WHERE invoice_line_id = r_invoice_lines.invoice_line_id);
          EXCEPTION
            WHEN OTHERS THEN
              raise_application_error(-20998,
                                      SQLERRM || '***********************' ||
                                      ' Select quantity - Invoice parents' ||
                                      '***********************');
          END;
          --
          BEGIN
            SELECT SUM(ril.quantity)
              INTO x_return_quantity
              FROM cll_f189_invoice_lines    ril,
                   cll_f189_invoices         ri,
                   cll_f189_entry_operations reo,
                   cll_f189_invoice_types    cfit -- BUG: 8411951
             WHERE reo.status IN ('COMPLETE', 'PROCESSING')
               AND reo.operation_id = ri.operation_id
               AND reo.organization_id = ri.organization_id
               AND ril.invoice_id = ri.invoice_id
               AND ril.invoice_line_id IN
                   (SELECT DISTINCT rilp1.invoice_line_id
                      FROM cll_f189_invoice_line_parents rilp1,
                           cll_f189_invoice_line_parents rilp2
                     WHERE rilp1.invoice_parent_line_id =
                           rilp2.invoice_parent_line_id
                       AND rilp2.invoice_line_id =
                           r_invoice_lines.invoice_line_id)
               AND ri.invoice_type_id = cfit.invoice_type_id -- BUG: 8411951
               AND cfit.return_customer_flag = 'F'; -- BUG: 8411951
          EXCEPTION
            WHEN OTHERS THEN
              raise_application_error(-20999,
                                      SQLERRM || '***********************' ||
                                      ' Select quantity - Invoice line parents' ||
                                      '***********************');
          END;
          --
          IF r_invoice_lines.quantity >
             x_parent_quantity - x_return_quantity THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'QTY RET INV > QTY PAR INV',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          END IF;

          -- Bug 8511032 AIrmer 19/05/2009
          IF (r_invoice_lines.ipi_tributary_code IS NOT NULL) AND
             (r_invoice_lines.ipi_tributary_code_flag = 'Y') AND
             (SUBSTR(r_invoice_lines.ipi_tributary_code, 1, 1) IN
             ('0', '1', '2', '3', '4')) THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID IPI TRIB CODE',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSIF (p_interface = 'Y') THEN
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID IPI TRIB CODE',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
          END IF;
          --
        END IF;
        -- ER 17551029 5a Fase - Start
        IF r_invoice_lines.item_id IS NOT NULL THEN
          BEGIN
            SELECT attribute1
              INTO l_construction_type
              FROM cll_f407_mtl_system_items_ext
             WHERE inventory_item_id = r_invoice_lines.item_id
               AND organization_id = p_organization_id;
          EXCEPTION
            WHEN OTHERS THEN
              l_construction_type := NULL;
          END;
          --
          IF l_construction_type IS NOT NULL THEN
            IF l_construction_type = '3' AND
               r_invoice_lines.cno_number IS NULL THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE CNO NUMBER',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE CNO NUMBER',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
          END IF;
        END IF;
        -- ER 17551029 5a Fase - End
        --

/* -- 28049021 Begin  -  Trecho movido para baixo, apos alimentar a variavel "l_document_type"
        IF l_document_type = 'CPF' THEN -- 27357141


           IF l_esocial_period_code <= NVL(TO_CHAR(r_invoice_lines.invoice_date, 'YYYY-MM'),TO_CHAR(SYSDATE, 'YYYY-MM')) THEN  -- Active Esocial -- 25808200 - 25808214

              -- 24325307 - Start
              BEGIN
                 SELECT operating_unit
                 INTO l_cno_operating_unit
                 FROM org_organization_definitions
                 WHERE organization_id = p_organization_id;
              END;

              IF r_invoice_lines.cno_id IS NOT NULL AND
                 r_invoice_lines.cno_number IS NOT NULL THEN

                -- 25808200 - 25808214 - Inicio

                \*SELECT count(1)
                  INTO l_cno_exists
                  FROM cll_f407_cno cfc
                      ,fnd_lookup_values_vl flv
                  WHERE cfc.org_id = l_cno_operating_unit
                   AND cfc.construction_type = flv.lookup_code
                   AND flv.lookup_type       = 'CLL_F407_CONSTRUCTION_TYPES'
                   AND cfc.cno_id            = r_invoice_lines.cno_id
                   AND cfc.cno_number        = r_invoice_lines.cno_number;*\

                 BEGIN
                    SELECT pvsa.vendor_site_id
                    INTO l_vendor_site_id
                    FROM po_vendor_sites_all          pvsa,
                         cll_f189_fiscal_entities_all cffea
                    WHERE cffea.entity_id = r_invoice_lines.entity_id
                      AND cffea.vendor_site_id = pvsa.vendor_site_id
                      AND cffea.org_id = pvsa.org_id;

                 EXCEPTION
                    WHEN OTHERS THEN
                       l_vendor_site_id := NULL;
                 END;

                 SELECT count(1)
                  INTO l_cno_exists
                 FROM cll_f407_departments           cfd,
                      cll_f407_suppl_depart          cfsd,
                      ap_supplier_sites_all          assa,
                      cll_f407_etb_ri_associations_v cferav,
                      cll_f407_cno_profiles          cfcp
                 WHERE cfd.department_id = cfsd.department_id
                   AND cfsd.vendor_site_id = assa.vendor_site_id
                   AND assa.org_id = cferav.ou_id
                   AND cferav.organization_id = p_organization_id
                   AND cfsd.vendor_site_id = l_vendor_site_id
                   AND cfsd.active_flag = 'Y'
                   AND cfd.source_type = 'CNO'
                   AND cfd.source_id = cfcp.cno_id
                   AND cfcp.org_id = cferav.ou_id
                   AND cfcp.active_flag = 'Y'
                   AND cfcp.cno_number = r_invoice_lines.cno_number
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfcp.start_date) AND
                       TRUNC(NVL(cfcp.end_date, SYSDATE))
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfd.start_date) AND
                       TRUNC(NVL(cfd.end_date, SYSDATE))
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfsd.start_date) AND
                       TRUNC(NVL(cfsd.end_date, SYSDATE));
                 -- 25808200 - 25808214 - Fim

                 IF l_cno_exists = 0 THEN
                    IF (p_interface = 'N') THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                 'CLL_F189_CNO_EXISTS',
                                                                  r_invoice_lines.invoice_id,
                                                                 r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                             'CLL_F189_CNO_EXISTS',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;
                 END IF;

              END IF;

              IF r_invoice_lines.cno_id IS NOT NULL AND
                 r_invoice_lines.cno_number IS NULL THEN

                 -- 25808200 - 25808214 - Inicio

                 \*SELECT count(1)
                   INTO l_cno_id_exists
                   FROM cll_f407_cno cfc
                      ,fnd_lookup_values_vl flv
                   WHERE cfc.org_id = l_cno_operating_unit
                    AND cfc.construction_type = flv.lookup_code
                    AND flv.lookup_type       = 'CLL_F407_CONSTRUCTION_TYPES'
                    AND cfc.cno_id            = r_invoice_lines.cno_id;*\

                 BEGIN
                    SELECT pvsa.vendor_site_id
                    INTO l_vendor_site_id
                    FROM po_vendor_sites_all          pvsa,
                         cll_f189_fiscal_entities_all cffea
                    WHERE cffea.entity_id = r_invoice_lines.entity_id
                      AND cffea.vendor_site_id = pvsa.vendor_site_id
                      AND cffea.org_id = pvsa.org_id;

                 EXCEPTION
                    WHEN OTHERS THEN
                       l_vendor_site_id := NULL;
                 END;

                 SELECT count(1)
                 INTO l_cno_id_exists
                 FROM cll_f407_departments           cfd,
                      cll_f407_suppl_depart          cfsd,
                      ap_supplier_sites_all          assa,
                      cll_f407_etb_ri_associations_v cferav,
                      cll_f407_cno_profiles          cfcp
                WHERE cfd.department_id = cfsd.department_id
                  AND cfsd.vendor_site_id = assa.vendor_site_id
                  AND assa.org_id = cferav.ou_id
                  AND cferav.organization_id = p_organization_id
                  AND cfsd.vendor_site_id = l_vendor_site_id
                  AND cfsd.active_flag = 'Y'
                  AND cfd.source_type = 'CNO'
                  AND cfd.source_id = cfcp.cno_id
                  AND cfcp.org_id = cferav.ou_id
                  AND cfcp.active_flag = 'Y'
                  AND cfcp.cno_id = r_invoice_lines.cno_id
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(cfcp.start_date) AND
                      TRUNC(NVL(cfcp.end_date, SYSDATE))
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(cfd.start_date) AND
                      TRUNC(NVL(cfd.end_date, SYSDATE))
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(cfsd.start_date) AND
                      TRUNC(NVL(cfsd.end_date, SYSDATE));
                 -- 25808200 - 25808214 - Fim

                 IF l_cno_id_exists = 0 THEN

                    IF (p_interface = 'N') THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                 'CLL_F189_NO_CNO',
                                                                  r_invoice_lines.invoice_id,
                                                                  r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                            'CLL_F189_NO_CNO',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;

                 END IF;

              ELSIF r_invoice_lines.cno_id IS NULL AND
                    r_invoice_lines.cno_number IS NOT NULL THEN

                 -- 25808200 - 25808214 - Inicio
                 \*SELECT count(1)
                    INTO l_cno_number_exists
                   FROM cll_f407_cno cfc
                       ,fnd_lookup_values_vl flv
                   WHERE cfc.org_id = l_cno_operating_unit
                     AND cfc.construction_type = flv.lookup_code
                     AND flv.lookup_type       = 'CLL_F407_CONSTRUCTION_TYPES'
                     AND cfc.cno_number        = r_invoice_lines.cno_number;*\

                 BEGIN
                    SELECT pvsa.vendor_site_id
                    INTO l_vendor_site_id
                    FROM po_vendor_sites_all          pvsa,
                         cll_f189_fiscal_entities_all cffea
                    WHERE cffea.entity_id = r_invoice_lines.entity_id
                      AND cffea.vendor_site_id = pvsa.vendor_site_id
                      AND cffea.org_id = pvsa.org_id;

                 EXCEPTION
                    WHEN OTHERS THEN
                       l_vendor_site_id := NULL;
                 END;

                 SELECT count(1)
                 INTO l_cno_id_exists
                 FROM cll_f407_departments           cfd,
                      cll_f407_suppl_depart          cfsd,
                      ap_supplier_sites_all          assa,
                      cll_f407_etb_ri_associations_v cferav,
                      cll_f407_cno_profiles          cfcp
                 WHERE cfd.department_id = cfsd.department_id
                   AND cfsd.vendor_site_id = assa.vendor_site_id
                   AND assa.org_id = cferav.ou_id
                   AND cferav.organization_id = p_organization_id
                   AND cfsd.vendor_site_id = l_vendor_site_id
                   AND cfsd.active_flag = 'Y'
                   AND cfd.source_type = 'CNO'
                   AND cfd.source_id = cfcp.cno_id
                   AND cfcp.org_id = cferav.ou_id
                   AND cfcp.active_flag = 'Y'
                   AND cfcp.cno_number = r_invoice_lines.cno_number
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfcp.start_date) AND
                       TRUNC(NVL(cfcp.end_date, SYSDATE))
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfd.start_date) AND
                       TRUNC(NVL(cfd.end_date, SYSDATE))
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfsd.start_date) AND
                       TRUNC(NVL(cfsd.end_date, SYSDATE));
                 -- 25808200 - 25808214 - Fim

                 IF l_cno_number_exists = 0 THEN
                    IF (p_interface = 'N') THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                 'CLL_F189_NO_CNO',
                                                                  r_invoice_lines.invoice_id,
                                                                  r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                            'CLL_F189_NO_CNO',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;
                 END IF;

              END IF;
              -- 24325307 - End

           END IF;-- Active Esocial -- 25808200 - 25808214

        -- 27357141 - Start
        ELSE -- CNPJ

           IF l_reinf_period_code <= NVL(TO_CHAR(r_invoice_lines.invoice_date, 'YYYY-MM'),TO_CHAR(SYSDATE, 'YYYY-MM')) THEN  -- Active Reinf -- 25808200 - 25808214

              BEGIN
                 SELECT pvsa.vendor_site_id
                 INTO l_vendor_site_id
                 FROM po_vendor_sites_all          pvsa,
                      cll_f189_fiscal_entities_all cffea
                 WHERE cffea.entity_id = r_invoice_lines.entity_id
                   AND cffea.vendor_site_id = pvsa.vendor_site_id
                   AND cffea.org_id = pvsa.org_id;

              EXCEPTION
                 WHEN OTHERS THEN
                    l_vendor_site_id := NULL;
              END;

              IF r_invoice_lines.cno_number IS NOT NULL THEN

                 SELECT count(1)
                   INTO l_cno_exists
                 FROM ( SELECT cfcp.cno_id
                        FROM cll_f407_cno_profiles            cfcp
                           , cll_f407_etb_ri_associations_v   cferav
                        WHERE cferav.ou_id           = cfcp.org_id
                          AND cfcp.source_table      = 'AP_SUPPLIER_SITES_ALL'
                          AND cfcp.source_id         = l_vendor_site_id
                          AND cfcp.cno_number        = r_invoice_lines.cno_number
                          AND cferav.organization_id = p_organization_id
                          AND cferav.active_flag     = 'Y'
                        --
                        UNION ALL
                        --
                        SELECT cfcp.cno_id
                        FROM cll_f407_cno_profiles            cfcp
                           , cll_f407_etb_ri_associations_v   cferav
                        WHERE cferav.establishment_id = cfcp.source_id
                          AND cferav.ou_id            = cfcp.org_id
                          AND cfcp.source_table       = 'XLE_ESTABLISHMENT_V'
                          AND cfcp.cno_number         = r_invoice_lines.cno_number
                          AND cferav.organization_id  = p_organization_id
                          AND cferav.active_flag      = 'Y');

                   IF l_cno_exists = 0 THEN
                      IF (p_interface = 'N') THEN
                         cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                    p_organization_id,
                                                                    p_location_id,
                                                                   'CLL_F189_CNO_EXISTS',
                                                                    r_invoice_lines.invoice_id,
                                                                   r_invoice_lines.invoice_line_id);
                      ELSE
                         cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                               p_operation_id,
                                                               'CLL_F189_CNO_EXISTS',
                                                               r_invoice_lines.interface_invoice_line_id);
                      END IF;
                   END IF;

              END IF;

           END IF; -- Active Reinf -- 25808200 - 25808214

        END IF;
        -- 27357141 - End
-- 28049021 End */
        --
        -- ERancement 4533742 AIrmer 12/08/2005
        l_recover_pis_flag_cnpj    := NULL;
        l_recover_pis_flag_cpf     := NULL;
        l_recover_cofins_flag_cnpj := NULL;
        l_recover_cofins_flag_cpf  := NULL;
        l_document_type            := NULL;
        l_utilization_id           := NULL;
        l_ok                       := TRUE;
        IF (r_invoice_lines.utilization_id IS NULL) AND
           (r_invoice_lines.utilization_code IS NULL) THEN
          l_ok := FALSE;
        ELSIF (r_invoice_lines.utilization_id IS NULL) AND
              (r_invoice_lines.utilization_code IS NOT NULL) THEN
          BEGIN
            SELECT riu.utilization_id
              INTO l_utilization_id
              FROM cll_f189_item_utilizations riu
             WHERE riu.utilization_code = r_invoice_lines.utilization_code;
          EXCEPTION
            WHEN OTHERS THEN
              l_utilization_id := NULL;
              l_ok             := FALSE;
          END;
        END IF;
        --
        BEGIN
          SELECT riu.recover_pis_flag_cnpj,
                 riu.recover_pis_flag_cpf,
                 riu.recover_cofins_flag_cnpj,
                 riu.recover_cofins_flag_cpf,
                 riu.icms_differed_type -- BUG 24795936
            INTO l_recover_pis_flag_cnpj,
                 l_recover_pis_flag_cpf,
                 l_recover_cofins_flag_cnpj,
                 l_recover_cofins_flag_cpf,
                 l_icms_differed_type -- BUG 24795936
            FROM cll_f189_item_utilizations riu
           WHERE riu.utilization_id =
                 NVL(r_invoice_lines.utilization_id, l_utilization_id);
        EXCEPTION
          WHEN OTHERS THEN
            l_recover_pis_flag_cnpj    := NULL;
            l_recover_pis_flag_cpf     := NULL;
            l_recover_cofins_flag_cnpj := NULL;
            l_recover_cofins_flag_cpf  := NULL;
            l_icms_differed_type       := NULL; -- BUG 24795936
            l_ok                       := FALSE;
        END;
        -- Begin BUG 26875233
      --IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'Y' AND                   -- 27579747
         IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
         AND p_interface = 'Y'                                                          -- 27579747
         AND NVL(r_invoice_lines.deferred_icms_amount, 0) = 0 THEN
          NULL;
        ELSE
          -- End BUG 26875233
          -- Begin BUG 24795936
          IF nvl(l_icms_differed_type, 'N') = 'F' THEN
            IF NVL(r_invoice_lines.deferred_icms_amount, 0) = 0 THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'ICMS DIFERRED SIMPLE CALC',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'ICMS DIFERRED SIMPLE CALC',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            END IF;
          END IF;
          -- End BUG 24795936
        END IF; -- End BUG 26875233
        --
        -- ER 14124731 - Start
      --IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'Y' THEN                 -- 27579747
        IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
        AND p_interface = 'Y' THEN                                                     -- 27579747
          NULL;
        ELSE
          -- ER 14124731 - End
          -- ER 10367032 - Inicio
          IF tax_calc_ref_parent(r_invoice_lines.invoice_line_id, 'PIS') AND
             l_national_state = 'Y' AND r_invoice_lines.pis_flag = 'Y' AND
             (l_recover_pis_flag_cnpj = 'Y' OR l_recover_pis_flag_cpf = 'Y') AND
             v_pis_recover_start_date IS NOT NULL AND
             v_pis_recover_start_date <= r_invoice_lines.invoice_date THEN
            --
            IF (r_invoice_lines.pis_qty IS NOT NULL AND
               r_invoice_lines.pis_unit_amount IS NOT NULL AND
               r_invoice_lines.pis_base_amount IS NULL AND
               r_invoice_lines.pis_tax_rate IS NULL) OR
               (r_invoice_lines.pis_base_amount IS NOT NULL AND
               r_invoice_lines.pis_tax_rate IS NOT NULL AND
               r_invoice_lines.pis_qty IS NULL AND
               r_invoice_lines.pis_unit_amount IS NULL) THEN
              --
              NULL;
              --
            ELSE
              --
              IF (p_interface = 'N') THEN
              --IF l_source <> 'CLL_F369 EFD LOADER' THEN                                               -- 27579747
                IF l_source NOT IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') THEN -- 27579747
                  -- BUG 21909282
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INCONSISTENT PIS INFO',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                END IF; -- BUG 21909282
              ELSE
              --IF l_source <> 'CLL_F369 EFD LOADER' THEN                                               -- 27579747
                IF l_source NOT IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') THEN -- 27579747
                  -- BUG 21909282
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'INCONSISTENT PIS INFO',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF; -- BUG 21909282
              END IF;
              --
            END IF;
            --
          END IF;
          --
          IF tax_calc_ref_parent(r_invoice_lines.invoice_line_id, 'COFINS') AND
             l_national_state = 'Y' AND r_invoice_lines.cofins_flag = 'Y' AND
             (l_recover_cofins_flag_cnpj = 'Y' OR
              l_recover_cofins_flag_cpf = 'Y') AND
             v_cofins_recover_start_date IS NOT NULL AND
             v_cofins_recover_start_date <= r_invoice_lines.invoice_date THEN
            --
            IF (r_invoice_lines.cofins_qty IS NOT NULL AND
               r_invoice_lines.cofins_unit_amount IS NOT NULL AND
               r_invoice_lines.cofins_base_amount IS NULL AND
               r_invoice_lines.cofins_tax_rate IS NULL) OR
               (r_invoice_lines.cofins_base_amount IS NOT NULL AND
               r_invoice_lines.cofins_tax_rate IS NOT NULL AND
               r_invoice_lines.cofins_qty IS NULL AND
               r_invoice_lines.cofins_unit_amount IS NULL) THEN
              --
              NULL;
              --
            ELSE
              --
              IF (p_interface = 'N') THEN
              --IF l_source <> 'CLL_F369 EFD LOADER' THEN                                               -- 27579747
                IF l_source NOT IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') THEN -- 27579747
                  -- BUG 21909282
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INCONSISTENT COFINS INFO',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                END IF; -- BUG 21909282
              ELSE
              --IF l_source <> 'CLL_F369 EFD LOADER' THEN                                               -- 27579747
                IF l_source NOT IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') THEN -- 27579747
                  -- BUG 21909282
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'INCONSISTENT COFINS INFO',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF; -- BUG 21909282
              END IF;
              --
            END IF;
            --
          END IF;
          -- ER 10367032 - Fim
        END IF; -- ER 14124731
        --
        -- Bug 9597256 - rvicente - 26/04/2010 BEGIN
        IF r_invoice_lines.entity_id IS NULL THEN
          -- RECOVER OPERATING_UNIT
          BEGIN
            SELECT operating_unit
              INTO v_operating_unit
              FROM org_organization_definitions
             WHERE organization_id = p_organization_id;
          END;
          --
          -- RECOVER ENTITY_ID
          BEGIN
            SELECT entity_id
              INTO v_entity_id
              FROM cll_f189_fiscal_entities_all refi,
                   po_vendor_sites_all          pove
             WHERE pove.vendor_site_id = refi.vendor_site_id
               AND refi.entity_type_lookup_code = 'VENDOR_SITE'
               AND refi.org_id = v_operating_unit
               AND pove.org_id = v_operating_unit
               AND refi.document_type = r_invoice_lines.document_type
               AND refi.document_number = r_invoice_lines.document_number
               AND NVL(pove.inactive_date, SYSDATE + 1) > SYSDATE;
          EXCEPTION
            WHEN no_data_found THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID VENDOR SITE',
                                                           r_invoice_lines.invoice_id,
                                                           NULL);
              ELSIF (p_interface = 'Y') THEN
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID VENDOR SITE',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF;
            WHEN too_many_rows THEN
              IF r_invoice_lines.ie IS NULL THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID VENDOR SITE',
                                                             r_invoice_lines.invoice_id,
                                                             NULL);
                ELSIF (p_interface = 'Y') THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID VENDOR SITE',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              ELSE
                BEGIN
                  SELECT entity_id
                    INTO v_entity_id
                    FROM cll_f189_fiscal_entities_all refi,
                         po_vendor_sites_all          pove
                   WHERE pove.vendor_site_id = refi.vendor_site_id
                     AND refi.entity_type_lookup_code = 'VENDOR_SITE'
                     AND refi.org_id = v_operating_unit
                     AND pove.org_id = v_operating_unit
                     AND refi.document_type = r_invoice_lines.document_type
                     AND refi.document_number =
                         r_invoice_lines.document_number
                     AND refi.ie = r_invoice_lines.ie
                     AND NVL(pove.inactive_date, SYSDATE + 1) > SYSDATE;
                EXCEPTION
                  WHEN others THEN
                    IF (p_interface = 'N') THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                 'INVALID VENDOR SITE',
                                                                 r_invoice_lines.invoice_id,
                                                                 NULL);
                    ELSIF (p_interface = 'Y') THEN
                      cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                            p_operation_id,
                                                            'INVALID VENDOR SITE',
                                                            r_invoice_lines.interface_invoice_line_id);
                    END IF;
                END;
              END IF;
          END;
        ELSE
          -- r_invoice_lines.entity_id is null
          v_entity_id := r_invoice_lines.entity_id;
        END IF;
        -- Bug 9597256 - rvicente - 26/04/2010 BEGIN
        BEGIN
          SELECT rfe.document_type, business_vendor_id --(++) Rantonio, 28/01/2008;BUG 6075440 -- Bug Equal 6771247 - rvicente - 30/01/2008
            INTO l_document_type, v_vendor_id --(++) Rantonio, 28/01/2008;BUG 6075440 -- Bug Equal 6771247 - rvicente - 30/01/2008
            FROM cll_f189_fiscal_entities_all rfe
          -- WHERE rfe.entity_id = r_invoice_lines.entity_id;  -- Bug 9597256
           WHERE rfe.entity_id = v_entity_id; -- Bug 9597256
        EXCEPTION
          WHEN OTHERS THEN
            l_document_type := NULL;
            l_ok            := FALSE;
        END;
        -- Bug 9446918 - Inicio
        BEGIN
          SELECT count(1)
            INTO v_business_vendors
            FROM cll_f189_business_vendors
           WHERE business_id = V_VENDOR_ID;
        EXCEPTION
          WHEN OTHERS THEN
            v_business_vendors := 0;
        END;
        --
        IF NVL(v_business_vendors, 0) = 0 THEN
          IF (p_interface = 'N') THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'NONE COMPANY TYPES',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'NONE COMPANY TYPES',
                                                  r_invoice_lines.interface_invoice_line_id);
          END IF;
        END IF;
        -- Bug 9446918 - Fim

--
-- 28049021 Begin
        IF l_document_type = 'CPF' THEN -- 27357141

           IF l_esocial_period_code <= NVL(TO_CHAR(r_invoice_lines.invoice_date, 'YYYY-MM'),TO_CHAR(SYSDATE, 'YYYY-MM')) THEN  -- Active Esocial -- 25808200 - 25808214

              -- 24325307 - Start
              BEGIN
                 SELECT operating_unit
                 INTO l_cno_operating_unit
                 FROM org_organization_definitions
                 WHERE organization_id = p_organization_id;
              END;

              IF r_invoice_lines.cno_id IS NOT NULL AND
                 r_invoice_lines.cno_number IS NOT NULL THEN

                -- 25808200 - 25808214 - Inicio

                /*SELECT count(1)
                  INTO l_cno_exists
                  FROM cll_f407_cno cfc
                      ,fnd_lookup_values_vl flv
                  WHERE cfc.org_id = l_cno_operating_unit
                   AND cfc.construction_type = flv.lookup_code
                   AND flv.lookup_type       = 'CLL_F407_CONSTRUCTION_TYPES'
                   AND cfc.cno_id            = r_invoice_lines.cno_id
                   AND cfc.cno_number        = r_invoice_lines.cno_number;*/

                 BEGIN
                    SELECT pvsa.vendor_site_id
                    INTO l_vendor_site_id
                    FROM po_vendor_sites_all          pvsa,
                         cll_f189_fiscal_entities_all cffea
                    WHERE cffea.entity_id = r_invoice_lines.entity_id
                      AND cffea.vendor_site_id = pvsa.vendor_site_id
                      AND cffea.org_id = pvsa.org_id;

                 EXCEPTION
                    WHEN OTHERS THEN
                       l_vendor_site_id := NULL;
                 END;

                 SELECT count(1)
                  INTO l_cno_exists
                 FROM cll_f407_departments           cfd,
                      cll_f407_suppl_depart          cfsd,
                      ap_supplier_sites_all          assa,
                      cll_f407_etb_ri_associations_v cferav,
                      cll_f407_cno_profiles          cfcp
                 WHERE cfd.department_id = cfsd.department_id
                   AND cfsd.vendor_site_id = assa.vendor_site_id
                   AND assa.org_id = cferav.ou_id
                   AND cferav.organization_id = p_organization_id
                   AND cfsd.vendor_site_id = l_vendor_site_id
                   AND cfsd.active_flag = 'Y'
                   AND cfd.source_type = 'CNO'
                   AND cfd.source_id = cfcp.cno_id
                   AND cfcp.org_id = cferav.ou_id
                   AND cfcp.active_flag = 'Y'
                   AND cfcp.cno_number = r_invoice_lines.cno_number
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfcp.start_date) AND
                       TRUNC(NVL(cfcp.end_date, SYSDATE))
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfd.start_date) AND
                       TRUNC(NVL(cfd.end_date, SYSDATE))
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfsd.start_date) AND
                       TRUNC(NVL(cfsd.end_date, SYSDATE));
                 -- 25808200 - 25808214 - Fim

                 IF l_cno_exists = 0 THEN
                    IF (p_interface = 'N') THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                 'CLL_F189_CNO_EXISTS',
                                                                  r_invoice_lines.invoice_id,
                                                                 r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                             'CLL_F189_CNO_EXISTS',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;
                 END IF;

              END IF;

              IF r_invoice_lines.cno_id IS NOT NULL AND
                 r_invoice_lines.cno_number IS NULL THEN

                 -- 25808200 - 25808214 - Inicio

                 /*SELECT count(1)
                   INTO l_cno_id_exists
                   FROM cll_f407_cno cfc
                      ,fnd_lookup_values_vl flv
                   WHERE cfc.org_id = l_cno_operating_unit
                    AND cfc.construction_type = flv.lookup_code
                    AND flv.lookup_type       = 'CLL_F407_CONSTRUCTION_TYPES'
                    AND cfc.cno_id            = r_invoice_lines.cno_id;*/

                 BEGIN
                    SELECT pvsa.vendor_site_id
                    INTO l_vendor_site_id
                    FROM po_vendor_sites_all          pvsa,
                         cll_f189_fiscal_entities_all cffea
                    WHERE cffea.entity_id = r_invoice_lines.entity_id
                      AND cffea.vendor_site_id = pvsa.vendor_site_id
                      AND cffea.org_id = pvsa.org_id;

                 EXCEPTION
                    WHEN OTHERS THEN
                       l_vendor_site_id := NULL;
                 END;

                 SELECT count(1)
                 INTO l_cno_id_exists
                 FROM cll_f407_departments           cfd,
                      cll_f407_suppl_depart          cfsd,
                      ap_supplier_sites_all          assa,
                      cll_f407_etb_ri_associations_v cferav,
                      cll_f407_cno_profiles          cfcp
                WHERE cfd.department_id = cfsd.department_id
                  AND cfsd.vendor_site_id = assa.vendor_site_id
                  AND assa.org_id = cferav.ou_id
                  AND cferav.organization_id = p_organization_id
                  AND cfsd.vendor_site_id = l_vendor_site_id
                  AND cfsd.active_flag = 'Y'
                  AND cfd.source_type = 'CNO'
                  AND cfd.source_id = cfcp.cno_id
                  AND cfcp.org_id = cferav.ou_id
                  AND cfcp.active_flag = 'Y'
                  AND cfcp.cno_id = r_invoice_lines.cno_id
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(cfcp.start_date) AND
                      TRUNC(NVL(cfcp.end_date, SYSDATE))
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(cfd.start_date) AND
                      TRUNC(NVL(cfd.end_date, SYSDATE))
                  AND TRUNC(SYSDATE) BETWEEN TRUNC(cfsd.start_date) AND
                      TRUNC(NVL(cfsd.end_date, SYSDATE));
                 -- 25808200 - 25808214 - Fim

                 IF l_cno_id_exists = 0 THEN

                    IF (p_interface = 'N') THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                 'CLL_F189_NO_CNO',
                                                                  r_invoice_lines.invoice_id,
                                                                  r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                            'CLL_F189_NO_CNO',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;

                 END IF;

              ELSIF r_invoice_lines.cno_id IS NULL AND
                    r_invoice_lines.cno_number IS NOT NULL THEN

                 -- 25808200 - 25808214 - Inicio
                 /*SELECT count(1)
                    INTO l_cno_number_exists
                   FROM cll_f407_cno cfc
                       ,fnd_lookup_values_vl flv
                   WHERE cfc.org_id = l_cno_operating_unit
                     AND cfc.construction_type = flv.lookup_code
                     AND flv.lookup_type       = 'CLL_F407_CONSTRUCTION_TYPES'
                     AND cfc.cno_number        = r_invoice_lines.cno_number;*/

                 BEGIN
                    SELECT pvsa.vendor_site_id
                    INTO l_vendor_site_id
                    FROM po_vendor_sites_all          pvsa,
                         cll_f189_fiscal_entities_all cffea
                    WHERE cffea.entity_id = r_invoice_lines.entity_id
                      AND cffea.vendor_site_id = pvsa.vendor_site_id
                      AND cffea.org_id = pvsa.org_id;

                 EXCEPTION
                    WHEN OTHERS THEN
                       l_vendor_site_id := NULL;
                 END;

                 SELECT count(1)
                 INTO l_cno_id_exists
                 FROM cll_f407_departments           cfd,
                      cll_f407_suppl_depart          cfsd,
                      ap_supplier_sites_all          assa,
                      cll_f407_etb_ri_associations_v cferav,
                      cll_f407_cno_profiles          cfcp
                 WHERE cfd.department_id = cfsd.department_id
                   AND cfsd.vendor_site_id = assa.vendor_site_id
                   AND assa.org_id = cferav.ou_id
                   AND cferav.organization_id = p_organization_id
                   AND cfsd.vendor_site_id = l_vendor_site_id
                   AND cfsd.active_flag = 'Y'
                   AND cfd.source_type = 'CNO'
                   AND cfd.source_id = cfcp.cno_id
                   AND cfcp.org_id = cferav.ou_id
                   AND cfcp.active_flag = 'Y'
                   AND cfcp.cno_number = r_invoice_lines.cno_number
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfcp.start_date) AND
                       TRUNC(NVL(cfcp.end_date, SYSDATE))
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfd.start_date) AND
                       TRUNC(NVL(cfd.end_date, SYSDATE))
                   AND TRUNC(SYSDATE) BETWEEN TRUNC(cfsd.start_date) AND
                       TRUNC(NVL(cfsd.end_date, SYSDATE));
                 -- 25808200 - 25808214 - Fim

                 IF l_cno_number_exists = 0 THEN
                    IF (p_interface = 'N') THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                 'CLL_F189_NO_CNO',
                                                                  r_invoice_lines.invoice_id,
                                                                  r_invoice_lines.invoice_line_id);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                            'CLL_F189_NO_CNO',
                                                             r_invoice_lines.interface_invoice_line_id);
                    END IF;
                 END IF;

              END IF;
              -- 24325307 - End

           END IF;-- Active Esocial -- 25808200 - 25808214

        -- 27357141 - Start
        ELSE -- CNPJ

           IF l_reinf_period_code <= NVL(TO_CHAR(r_invoice_lines.invoice_date, 'YYYY-MM'),TO_CHAR(SYSDATE, 'YYYY-MM')) THEN  -- Active Reinf -- 25808200 - 25808214

              BEGIN
                 SELECT pvsa.vendor_site_id
                 INTO l_vendor_site_id
                 FROM po_vendor_sites_all          pvsa,
                      cll_f189_fiscal_entities_all cffea
                 WHERE cffea.entity_id = r_invoice_lines.entity_id
                   AND cffea.vendor_site_id = pvsa.vendor_site_id
                   AND cffea.org_id = pvsa.org_id;

              EXCEPTION
                 WHEN OTHERS THEN
                    l_vendor_site_id := NULL;
              END;

              IF r_invoice_lines.cno_number IS NOT NULL THEN

                 SELECT count(1)
                   INTO l_cno_exists
                 FROM ( SELECT cfcp.cno_id
                        FROM cll_f407_cno_profiles            cfcp
                           , cll_f407_etb_ri_associations_v   cferav
                        WHERE cferav.ou_id           = cfcp.org_id
                          AND cfcp.source_table      = 'AP_SUPPLIER_SITES_ALL'
                          AND cfcp.source_id         = l_vendor_site_id
                          AND cfcp.cno_number        = r_invoice_lines.cno_number
                          AND cferav.organization_id = p_organization_id
                          AND cferav.active_flag     = 'Y'
                        --
                        UNION ALL
                        --
                        SELECT cfcp.cno_id
                        FROM cll_f407_cno_profiles            cfcp
                           , cll_f407_etb_ri_associations_v   cferav
                        WHERE cferav.establishment_id = cfcp.source_id
                          AND cferav.ou_id            = cfcp.org_id
                          AND cfcp.source_table       = 'XLE_ESTABLISHMENT_V'
                          AND cfcp.cno_number         = r_invoice_lines.cno_number
                          AND cferav.organization_id  = p_organization_id
                          AND cferav.active_flag      = 'Y');

                   IF l_cno_exists = 0 THEN
                      IF (p_interface = 'N') THEN
                         cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                    p_organization_id,
                                                                    p_location_id,
                                                                   'CLL_F189_CNO_EXISTS',
                                                                    r_invoice_lines.invoice_id,
                                                                   r_invoice_lines.invoice_line_id);
                      ELSE
                         cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                               p_operation_id,
                                                               'CLL_F189_CNO_EXISTS',
                                                               r_invoice_lines.interface_invoice_line_id);
                      END IF;
                   END IF;

              END IF;

           END IF; -- Active Reinf -- 25808200 - 25808214

        END IF;
        -- 27357141 - End
        --
-- 28049021 End
--

        --(++) Rantonio, 28/01/2008;BUG 6075440 (INICIO) -- Bug Equal 6771247 - rvicente - 30/01/2008
        BEGIN
          SELECT funrural_contributor_flag
            INTO V_FUNRURAL
            FROM cll_f189_business_vendors
           WHERE business_id = V_VENDOR_ID;
        EXCEPTION
          WHEN OTHERS THEN
            V_FUNRURAL := NULL;
        END;
        --
        IF nvl(V_FUNRURAL, 'N') <> 'N' THEN
          l_document_type := 'CPF';
        END IF;
        --(++) Rantonio, 128/01/2008;BUG 6075440 (FIM) -- Bug Equal 6771247 - rvicente - 30/01/2008
        IF l_ok THEN

          -- ER 14124731 - Start
        --IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'Y' THEN                 -- 27579747
          IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
          AND p_interface = 'Y' THEN                                                     -- 27579747
            NULL;
          ELSE
            -- ER 14124731 - End
            IF (r_invoice_lines.pis_flag = 'Y') AND
               (v_pis_recover_start_date IS NOT NULL) AND
               (v_pis_recover_start_date <= r_invoice_lines.invoice_date) THEN
              IF ((l_document_type = 'CNPJ') AND
                 (l_recover_pis_flag_cnpj = 'Y') AND
                 (r_invoice_lines.pis_amount_recover IS NULL) OR
                 (l_document_type = 'CPF') AND
                 (l_recover_pis_flag_cpf = 'Y') AND
                 (r_invoice_lines.pis_amount_recover IS NULL) OR
                 (l_document_type = 'OTHERS') AND
                 ((l_recover_pis_flag_cnpj = 'Y') OR
                 (l_recover_pis_flag_cpf = 'Y')) AND
                 (r_invoice_lines.pis_amount_recover IS NULL)) THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE PIS RECOVER',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE PIS RECOVER',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;
            END IF;
            --
            IF (r_invoice_lines.cofins_flag = 'Y') AND
               (v_cofins_recover_start_date IS NOT NULL) AND
               (v_cofins_recover_start_date <= r_invoice_lines.invoice_date) THEN
              IF ((l_document_type = 'CNPJ') AND
                 (l_recover_cofins_flag_cnpj = 'Y') AND
                 (r_invoice_lines.cofins_amount_recover IS NULL) OR
                 (l_document_type = 'CPF') AND
                 (l_recover_cofins_flag_cpf = 'Y') AND
                 (r_invoice_lines.cofins_amount_recover IS NULL) OR
                 (l_document_type = 'OTHERS') AND
                 ((l_recover_cofins_flag_cnpj = 'Y') OR
                 (l_recover_cofins_flag_cpf = 'Y')) AND
                 (r_invoice_lines.cofins_amount_recover IS NULL)) THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE COFINS RECOVER',
                                                             r_invoice_lines.invoice_id,
                                                             r_invoice_lines.invoice_line_id);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE COFINS RECOVER',
                                                        r_invoice_lines.interface_invoice_line_id);
                END IF;
              END IF;
            END IF;
          END IF;
          --
        END IF; -- ER 14124731

        -- ER 16755312 - Start
        IF r_invoice_lines.customs_total_value IS NOT NULL THEN
          IF NVL(substr(r_invoice_lines.tributary_status_code, 1, 1), '*') <> '1' THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID CUSTOMS TOTAL VALUE',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID CUSTOMS TOTAL VALUE',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
          END IF;
        END IF;
        --
        IF r_invoice_lines.ci_percent IS NOT NULL THEN
          --IF NVL(substr(r_invoice_lines.tributary_status_code,1,1),'*') NOT IN ('3','5') THEN       --<<BUG 17249120 - Egini - 01/08/2013 >>--
          IF NVL(substr(r_invoice_lines.tributary_status_code, 1, 1), '*') NOT IN
             ('3', '5', '8') THEN
            --<<BUG 17249120 - Egini - 01/08/2013 >>--
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID CI PERCENT',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID CI PERCENT',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
          END IF;
        END IF;
        --
        IF r_invoice_lines.total_import_parcel IS NOT NULL THEN
          --IF NVL(substr(r_invoice_lines.tributary_status_code,1,1),'*') NOT IN ('2','3') THEN   --<<BUG 17249120 - Egini - 01/08/2013 >>--
          IF NVL(substr(r_invoice_lines.tributary_status_code, 1, 1), '*') NOT IN
             ('2', '3', '8') THEN
            --<<BUG 17249120 - Egini - 01/08/2013 >>--
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID TOTAL VALUE IMP PARCEL',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID TOTAL VALUE IMP PARCEL',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
          END IF;
        END IF;
        --
        IF r_invoice_lines.fci_number IS NOT NULL THEN
          IF NVL(substr(r_invoice_lines.tributary_status_code, 1, 1), '*') NOT IN
             ('3', '5', '8') THEN
            --<<BUG 17249120 - Egini - 16/10/2013 - Inclusao do CST 8 >>--
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID FCI NUMBER',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
            --IF l_source <> 'CLL_F369 EFD LOADER' THEN                                               -- 27579747
              IF l_source NOT IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') THEN -- 27579747
                -- BUG 21909282 (ex-21280233)
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID FCI NUMBER',
                                                      r_invoice_lines.interface_invoice_line_id);
              END IF; -- BUG 21909282 (ex-21280233)
            END IF;
          END IF;
        END IF;
        -- ER 16755312 - End
        --
        -- 28468398 - 28505834 - Start
        IF NVL(r_invoice_lines.tributary_status_code,'***') <> '060'
        AND (   NVL(r_invoice_lines.icms_st_prev_withheld_base,0)    > 0
             OR NVL(r_invoice_lines.icms_st_prev_withheld_tx_rate,0) > 0
             OR NVL(r_invoice_lines.icms_st_prev_withheld_amount,0)  > 0
             OR NVL(r_invoice_lines.fcp_st_prev_withheld_base,0)     > 0
             OR NVL(r_invoice_lines.fcp_st_prev_withheld_tx_rate,0)  > 0
             OR NVL(r_invoice_lines.fcp_st_prev_withheld_amount,0)   > 0 ) THEN

           IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ST WITHHELD PREV CST INVALID',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
           ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'ST WITHHELD PREV CST INVALID',
                                                    r_invoice_lines.interface_invoice_line_id);
           END IF;

        END IF;
        -- 28468398 - 28505834 - End
        --
        -- Bug 20145693 - Start
        IF LENGTH(r_invoice_lines.recopi_full_number) <> 20 THEN
          IF (p_interface = 'N') THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'RECOPI INVALID',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'RECOPI INVALID',
                                                  r_invoice_lines.interface_invoice_line_id);
          END IF;
        END IF;
        --
        ----------------------------
        -- RECOPI Date Validation --
        ----------------------------
        BEGIN
          BEGIN
            l_recopi_date := TO_DATE(SUBSTR(TO_CHAR(r_invoice_lines.recopi_full_number),
                                            1,
                                            8),
                                     'YYYYMMDD');
          EXCEPTION
            WHEN OTHERS THEN
              RAISE l_invalid_date;
          END;
          --
          IF (r_invoice_lines.recopi_year < l_min_year) OR
             (r_invoice_lines.recopi_year > l_actual_year) THEN
            RAISE l_invalid_date;
          END IF;
          --
          IF (r_invoice_lines.recopi_monthyear > l_actual_monthyear) THEN
            RAISE l_invalid_date;
          END IF;
        EXCEPTION
          WHEN l_invalid_date THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'RECOPI INVALID DATE',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'RECOPI INVALID DATE',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
        END;
        --
        ----------------------------
        -- RECOPI Time Validation --
        ----------------------------
        BEGIN
          l_time := TO_DATE(r_invoice_lines.recopi_time, 'HH24:MI:SS');
        EXCEPTION
          WHEN OTHERS THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'RECOPI INVALID TIME',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'RECOPI INVALID TIME',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
        END;
        --
        ---------------------------------------
        -- RECOPI verifiers digit Validation --
        ---------------------------------------
        --
        l_validate_digits := cll_f189_digit_calc_pkg.func_digit_calc('RECOPI',
                                                                     r_invoice_lines.recopi_number);

        IF l_validate_digits <> r_invoice_lines.recopi_digits THEN
          IF (p_interface = 'N') THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'RECOPI NUM DIG WRONG',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'RECOPI NUM DIG WRONG',
                                                  r_invoice_lines.interface_invoice_line_id);
          END IF;
        END IF;
        -- Bug 20145693 - End
        --
        -- 21645107 - Start
        IF p_interface = 'N' THEN

          SELECT count(ril.item_number)
            INTO l_item_number_found
            FROM cll_f189_invoice_lines ril
           WHERE ril.invoice_id = r_invoice_lines.invoice_id;

        ELSE

          SELECT count(ril.item_number)
            INTO l_item_number_found
            FROM cll_f189_invoice_lines_iface ril
           WHERE ril.interface_invoice_id =
                 r_invoice_lines.interface_invoice_id;

        END IF;
        --
        IF r_invoice_lines.item_number IS NULL AND l_item_number_found > 0 THEN

          IF p_interface = 'N' THEN

            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'NULL ITEM NUMBER',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);

          ELSE

            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'NULL ITEM NUMBER',
                                                  r_invoice_lines.interface_invoice_line_id);

          END IF;

        END IF;
        --
        IF p_interface = 'N' THEN

          SELECT count(*)
            INTO l_count_item_number
            FROM (SELECT distinct ril.item_id
                    FROM cll_f189_invoice_lines ril
                   WHERE ril.invoice_id = r_invoice_lines.invoice_id
                     AND ril.item_number = r_invoice_lines.item_number);

          IF l_count_item_number > 1 THEN

            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'ITEM NUMBER INVALID',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
          END IF;

        ELSE

          SELECT count(*)
            INTO l_count_item_number
            FROM (SELECT distinct ril.item_id
                    FROM cll_f189_invoice_lines_iface ril
                   WHERE ril.interface_invoice_id =
                         r_invoice_lines.interface_invoice_id
                     AND ril.item_number = r_invoice_lines.item_number);

          IF l_count_item_number > 1 THEN

            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'ITEM NUMBER INVALID',
                                                  r_invoice_lines.interface_invoice_line_id);

          END IF;

        END IF;
        -- 21645107 - End
        --
        -- 22984164 - Start
        CLL_F189_OPEN_VALIDATE_PUB.GET_DISTRIBUTIONS(p_line_location_id => r_invoice_lines.line_location_id
                                                     -- out
                                                    ,
                                                     p_destination_type_code => l_destination_type_code,
                                                     p_project_exists        => l_project_exists);

        IF l_destination_type_code = 'SHOP FLOOR' THEN

          IF (x_receive_date <> TRUNC(SYSDATE)) OR
             (v_gl_date <> TRUNC(SYSDATE)) THEN

            IF p_interface = 'N' THEN

              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID INV DATE SHOP FLOOR',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);

            ELSE

              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID INV DATE SHOP FLOOR',
                                                    r_invoice_lines.interface_invoice_line_id);

            END IF;

          END IF;

        END IF;
        -- 22984164 - End
        --          BUG 25341463 - CLL_F189: NEW SOLUTION TO ATTEND CIDE - Start
        --
        IF NVL(r_invoice_lines.cide_amount, 0) > 0 OR
           NVL(r_invoice_lines.cide_base_amount, 0) > 0 OR
           NVL(r_invoice_lines.cide_rate, 0) > 0 OR
           NVL(r_invoice_lines.cide_amount_recover, 0) > 0 THEN
          --
          IF NVL(r_invoice_lines.cide_amount, 0) = 0 OR
             NVL(r_invoice_lines.cide_base_amount, 0) = 0 OR
             NVL(r_invoice_lines.cide_rate, 0) = 0
          --OR              NVL(r_invoice_lines.cide_amount_recover, 0) = 0
           THEN
            --
            IF p_interface = 'N' THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'CIDE_REQUIRED',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
              --
            ELSE
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'CIDE_REQUIRED',
                                                    r_invoice_lines.interface_invoice_line_id);
              --
            END IF;
            --
          ELSE
            --
            IF r_invoice_lines.cide_amount_recover >
               r_invoice_lines.cide_amount THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'CIDE_AMT_REC_INV',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'CIDE_AMT_REC_INV',
                                                      r_invoice_lines.interface_invoice_line_id);
                --
              END IF;
              --
            END IF;
            --
          END IF;
          --
        END IF;
        --
        IF NVL(r_invoice_lines.cide_amount_recover, 0) > 0 AND
           NVL(r_invoice_lines.cide_code_combination_id, 0) = 0 THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'CIDE_ACCT_REQUIRED',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'CIDE_ACCT_REQUIRED',
                                                  r_invoice_lines.interface_invoice_line_id);
            --
          END IF;
          --
        END IF;
        --
        --BUG 25341463 - CLL_F189: NEW SOLUTION TO ATTEND CIDE - End
        --
        -- 25713076 - Start
        IF r_invoice_lines.significant_scale_prod_ind = 'N' AND
           r_invoice_lines.manufac_goods_doc_number IS NULL THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'MANUF GOODS REQ',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'MANUF GOODS REQ',
                                                  r_invoice_lines.interface_invoice_line_id);
            --
          END IF;
          --
        END IF;

        IF (r_invoice_lines.med_maximum_price_consumer IS NOT NULL) OR
           (r_invoice_lines.anvisa_product_code IS NOT NULL) THEN

        --IF ((r_invoice_lines.lot_number IS NULL) OR         -- 26987509 - 26986232
          IF ((r_invoice_lines.product_lot_number IS NULL) OR -- 26987509 - 26986232
             (r_invoice_lines.lot_quantity IS NULL) OR
             (r_invoice_lines.production_date IS NULL) OR
             (r_invoice_lines.expiration_date IS NULL)) THEN
            --
            l_hold := 'Y';
            --
          END IF;

        END IF;

        IF l_hold = 'Y' THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'PROD TRAIL REQ',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'PROD TRAIL REQ',
                                                  r_invoice_lines.interface_invoice_line_id);
            --
          END IF;

        END IF;
        --
        IF (r_invoice_lines.fcp_base_amount IS NOT NULL AND
           (r_invoice_lines.fcp_rate IS NULL OR
           r_invoice_lines.fcp_amount IS NULL)) THEN
          --
          l_hold_fcp := 'Y';
          --
        ELSIF (r_invoice_lines.fcp_rate IS NOT NULL AND
              (r_invoice_lines.fcp_base_amount IS NULL OR
              r_invoice_lines.fcp_amount IS NULL)) THEN
          --
          l_hold_fcp := 'Y';
          --
        ELSIF (r_invoice_lines.fcp_amount IS NOT NULL AND
              (r_invoice_lines.fcp_base_amount IS NULL OR
              r_invoice_lines.fcp_rate IS NULL)) THEN
          --
          l_hold_fcp := 'Y';
          --
        END IF;
        --
        IF l_hold_fcp = 'Y' THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'FCP ICMS REQ',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'FCP ICMS REQ',
                                                  r_invoice_lines.interface_invoice_line_id);
            --
          END IF;
        END IF;
        --
        IF (r_invoice_lines.fcp_st_base_amount IS NOT NULL AND
           (r_invoice_lines.fcp_st_rate IS NULL OR
           r_invoice_lines.fcp_st_amount IS NULL)) THEN
          --
          l_hold_fcp_st := 'Y';
          --
        ELSIF (r_invoice_lines.fcp_st_rate IS NOT NULL AND
              (r_invoice_lines.fcp_st_base_amount IS NULL OR
              r_invoice_lines.fcp_st_amount IS NULL)) THEN
          --
          l_hold_fcp_st := 'Y';
          --
        ELSIF (r_invoice_lines.fcp_st_amount IS NOT NULL AND
              (r_invoice_lines.fcp_st_base_amount IS NULL OR
              r_invoice_lines.fcp_st_rate IS NULL)) THEN
          --
          l_hold_fcp_st := 'Y';
          --
        END IF;
        --
        IF l_hold_fcp_st = 'Y' THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'FCP ICMS ST REQ',
                                                       r_invoice_lines.invoice_id,
                                                       r_invoice_lines.invoice_line_id);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                  p_operation_id,
                                                  'FCP ICMS ST REQ',
                                                  r_invoice_lines.interface_invoice_line_id);
            --
          END IF;
        END IF;
        --
        -- 25713076 - End
        --
        /*ER 26338366/26899224 -- Start (WCarvalho - 30/OCT/2017)*/
        IF r_invoice_lines.requisition_type = 'NA' THEN
          --
          -- 28172729 - Start
          IF p_interface = 'N' THEN

             BEGIN

                -- Setup validation to approval Receitp Entry for Third Party only
                l_nApproval_receipt_entry := 0;
                l_nCust_acct_site_id      := NULL;

                SELECT COUNT(*), cfea.cust_acct_site_id
                  INTO l_nApproval_receipt_entry, l_nCust_acct_site_id
                FROM cll_f189_invoices            ci,
                     cll_f189_invoice_lines       cil,
                     cll_f189_fiscal_entities_all cfea,
                     cll_f189_item_utilizations   ciu,
                     cll_f189_cfo_utilizations    ccu,
                     cll_f189_fiscal_operations   cfo,
                     cll_f189_cfo_util_analog     ccua,
                     cll_f513_cust_network        cfcn
                WHERE ccua.corresponding_cfo_id    = cfo.cfo_id(+)
                  AND ccu.cfo_id                   = ccua.cfo_id(+)
                  AND ccu.utilization_id           = ciu.utilization_id
                  AND cil.cfo_id                   = ccu.cfo_id
                  AND cil.utilization_id           = ccu.utilization_id
                  AND ci.entity_id                 = cfea.entity_id
                  AND cil.invoice_id               = ci.invoice_id
                  AND ccu.utilization_id           = cfcn.utilization_id
                  AND (ccu.cfo_id                  = cfcn.in_state_cfop_id OR
                      ccu.cfo_id                   = cfcn.out_state_cfop_id)
                  AND cfcn.source_type             = 'RI'
                  AND NVL(cfcn.inactive_flag, 'N') <> 'Y'
                  AND cfea.entity_type_lookup_code = 'VENDOR_SITE'
                  AND ci.organization_id           = p_organization_id
                  AND ci.operation_id              = p_operation_id
                  AND cil.invoice_line_id          = r_invoice_lines.invoice_line_id
                  AND ccu.cfo_id                   = r_invoice_lines.cfo_id
                GROUP BY cfea.cust_acct_site_id;

             EXCEPTION
                WHEN OTHERS THEN
                   l_nApproval_receipt_entry := 0;
             END;

             -- Condition validation
             IF l_nApproval_receipt_entry > 0 AND l_nCust_acct_site_id IS NULL THEN

                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'SUPPLIER UNDEFINED AS CUSTOMER',
                                                           r_invoice_lines.invoice_id,
                                                           r_invoice_lines.invoice_line_id);

             END IF;

          ELSE

             BEGIN

                -- Setup validation to approval Receitp Entry for Third Party only
                l_nApproval_receipt_entry := 0;
                l_nCust_acct_site_id      := NULL;

                SELECT COUNT(*), cfea.cust_acct_site_id
                  INTO l_nApproval_receipt_entry, l_nCust_acct_site_id
                FROM cll_f189_invoices_interface  ci,
                     cll_f189_invoice_lines_iface cil,
                     cll_f189_fiscal_entities_all cfea,
                     cll_f189_item_utilizations   ciu,
                     cll_f189_cfo_utilizations    ccu,
                     cll_f189_fiscal_operations   cfo,
                     cll_f189_cfo_util_analog     ccua,
                     cll_f513_cust_network        cfcn
                WHERE ccua.corresponding_cfo_id     = cfo.cfo_id(+)
                  AND ccu.cfo_id                    = ccua.cfo_id(+)
                  AND ccu.utilization_id            = ciu.utilization_id
                  AND cil.cfo_id                    = ccu.cfo_id
                  AND cil.utilization_id            = ccu.utilization_id
                  AND ci.entity_id                  = cfea.entity_id
                  AND cil.interface_invoice_id      = ci.interface_invoice_id
                  AND ccu.utilization_id            = cfcn.utilization_id
                  AND (ccu.cfo_id                   = cfcn.in_state_cfop_id OR
                      ccu.cfo_id                    = cfcn.out_state_cfop_id)
                  AND cfcn.source_type              = 'RI'
                  AND NVL(cfcn.inactive_flag, 'N')  <> 'Y'
                  AND cfea.entity_type_lookup_code  = 'VENDOR_SITE'
                  AND ci.organization_id            = p_organization_id
                  AND ci.interface_operation_id     = p_operation_id
                  AND cil.interface_invoice_line_id = r_invoice_lines.invoice_line_id
                  AND ccu.cfo_id                    = r_invoice_lines.cfo_id
                GROUP BY cfea.cust_acct_site_id;

             EXCEPTION
                WHEN OTHERS THEN
                   l_nApproval_receipt_entry := 0;
             END;

             -- Condition validation
             IF l_nApproval_receipt_entry > 0 AND l_nCust_acct_site_id IS NULL THEN

                cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                      p_operation_id,
                                                      'SUPPLIER UNDEFINED AS CUSTOMER',
                                                      r_invoice_lines.interface_invoice_line_id);
             END IF;

          END IF ;
          -- 28172729 - End
          --
		  -- BUG 28496313 - Start
		  --
		  IF NVL(r_invoice_lines.tpa_control_type, 'X') = 'DEVOLUTION_OF' AND NVL(l_insert_hold_dev, 'Y') = 'Y' THEN
            --
		    FOR r_devolutions IN ( SELECT cftd.tpa_receipts_control_id
                                        , SUM(cftd.devolution_quantity) devolution_quantity
                                        , SUM(cftrc.remaining_balance)  remaining_balance
                                     FROM cll_f513_tpa_devolutions_ctrl cftd
                                        , cll_f189_invoice_lines        cfil
                                        , cll_f513_tpa_receipts_control cftrc
                                    WHERE cftd.devolution_invoice_line_id = cfil.invoice_line_id
                                      AND cftrc.tpa_receipts_control_id   = cftd.tpa_receipts_control_id
                                      AND cfil.invoice_id                 = r_invoice_lines.invoice_id
                                    GROUP BY cftd.tpa_receipts_control_id ) LOOP
               --
			   BEGIN
			     --
			     SELECT SUM(devolution_quantity)
				   INTO l_qtd_devolution
                   FROM cll_f513_tpa_devolutions_ctrl cftdc
                      , cll_f189_entry_operations cfeo
                  WHERE cfeo.operation_id             = cftdc.devolution_operation_id
                    AND cfeo.organization_id          = cftdc.organization_id
                    AND cfeo.status                   = 'COMPLETE'
                    AND cftdc.devolution_status       = 'INVOICE PENDING'
                    AND NVL(cftdc.cancel_flag, 'N')   = 'N'
                    AND cftdc.tpa_receipts_control_id = r_devolutions.tpa_receipts_control_id ;
			     --
			   EXCEPTION
			     WHEN OTHERS THEN
				   l_qtd_devolution := NULL ;
               END ;
			   --
			   IF r_devolutions.remaining_balance < (r_devolutions.devolution_quantity + NVL(l_qtd_devolution, 0)) THEN
			     --
				 l_insert_hold_dev := 'N' ;
				 --
                 incluir_erro_hold ( p_operation_id    => p_operation_id
                                   , p_organization_id => p_organization_id
                                   , p_location_id     => r_invoice_lines.location_id
                                   , p_hold_code       => 'QUANTITY DEVOLVED INV'
                                   , p_invoice_id      => r_invoice_lines.Invoice_id
                                   , p_invoice_line_id => r_invoice_lines.invoice_line_id
                                   ) ;
			     EXIT ;
                 --
               END IF ;
			   --
		    END LOOP ;
			--
		  END IF ;
		  --
		  IF NVL(r_invoice_lines.tpa_control_type, 'X') = 'RETURN_FROM' AND NVL(l_insert_hold_dev, 'Y') = 'Y' THEN
            --
		    FOR r_returns IN ( SELECT cftd.tpa_remit_control_id
                                    , SUM(cftd.returned_quantity)  devolution_quantity
                                    , SUM(cftrc.remaining_balance) remaining_balance
                                 FROM cll_f513_tpa_returns_control cftd
                                    , cll_f189_invoice_lines       cfil
                                    , cll_f513_tpa_remit_control   cftrc
                                WHERE cftd.invoice_line_id         = cfil.invoice_line_id
                                  AND cftrc.tpa_remit_control_id   = cftd.tpa_remit_control_id
                                  AND cfil.invoice_id              = r_invoice_lines.invoice_id
                                GROUP BY cftd.tpa_remit_control_id
                               HAVING SUM(cftd.returned_quantity)  > SUM(cftrc.remaining_balance) ) LOOP
               --
			   l_insert_hold_dev := 'N' ;
			   --
               incluir_erro_hold ( p_operation_id    => p_operation_id
                                 , p_organization_id => p_organization_id
                                 , p_location_id     => r_invoice_lines.location_id
                                 , p_hold_code       => 'TPA ASSOCIATION QTD ERROR'
                                 , p_invoice_id      => r_invoice_lines.Invoice_id
                                 , p_invoice_line_id => r_invoice_lines.invoice_line_id
                                 ) ;
			   EXIT ;
			   --
		    END LOOP ;
		    --
		  END IF ;
		  --
		  -- BUG 28496313 - End
		  --
          BEGIN
            v_nReturned_qty_total := 0;
            SELECT SUM(NVL(tpr.returned_quantity, 0)) returned_quantity_total
              INTO v_nReturned_qty_total
              FROM cll_f513_tpa_returns_control tpr
              WHERE tpr.organization_id = p_organization_id
                AND tpr.operation_id    = p_operation_id
                AND tpr.invoice_line_id = r_invoice_lines.invoice_line_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_nReturned_qty_total := 0;
            WHEN OTHERS THEN
              v_nReturned_qty_total := 0;
          END;
          --
          IF p_interface = 'N' THEN
            --
            BEGIN
              v_nInvoice_total := 0;
              SELECT NVL(COUNT(*), 0)
                INTO v_nInvoice_total
                FROM cll_f513_tpa_returns_control
               WHERE invoice_id      = r_invoice_lines.Invoice_id
                 AND invoice_line_id = r_invoice_lines.invoice_line_id
                 AND operation_id    = p_operation_id
                 AND organization_id = p_organization_id;
            END;
            --
            /*BUG 27796521 -- Start (WCarvalho - 18/APR/2018)*/
          --IF NVL(r_invoice_lines.tpa_control_flag, 'Y') = 'N' THEN
            IF NVL(r_invoice_lines.tpa_control_type, 'X') <> 'RETURN_FROM' THEN
            /*BUG 27796521 -- End (WCarvalho - 18/APR/2018)*/
              IF NVL(v_nInvoice_total, 0) <> 0 THEN
                -- Call the procedure
                  incluir_erro_hold(p_operation_id    => p_operation_id,
                                    p_organization_id => p_organization_id,
                                    p_location_id     => r_invoice_lines.location_id,
                                    p_hold_code       => 'INV CFO THIRD PARTY ASSOC',
                                    p_invoice_id      => r_invoice_lines.Invoice_id,
                                    p_invoice_line_id => r_invoice_lines.invoice_line_id);
              END IF;
          /*BUG 27796521 -- Start (WCarvalho - 18/APR/2018)*/
          --ELSE -- NVL(r_invoice_lines.tpa_control_flag, 'Y') = 'Y'
            ELSIF NVL(r_invoice_lines.tpa_control_type, 'X') = 'RETURN_FROM' THEN
            /*BUG 27796521 -- End (WCarvalho - 18/APR/2018)*/
              IF NVL(v_nInvoice_total, 0) = 0 THEN
                -- Call the procedure
                  incluir_erro_hold(p_operation_id    => p_operation_id,
                                    p_organization_id => p_organization_id,
                                    p_location_id     => r_invoice_lines.location_id,
                                    p_hold_code       => 'NO INVOICES RETURN',
                                    p_invoice_id      => r_invoice_lines.Invoice_id,
                                    p_invoice_line_id => r_invoice_lines.invoice_line_id);
              ELSE -- NVL(v_nInvoice_total, 0) <>
                -- BUG 28247307 -- Start (WCarvalho - 20/JUL/2018)
                BEGIN
                  v_nQtd_nf_retorno_assoc_nf_rem := 0;
                  v_nTransfer_organization_id    := NULL;
                  SELECT NVL(COUNT(*), 0) QTD,
                         ctrc.transfer_organization_id
                    INTO v_nQtd_nf_retorno_assoc_nf_rem,
                         v_nTransfer_organization_id
                    FROM cll_f513_tpa_remit_control   ctrc,
                         cll_f513_tpa_returns_control cftrc,
                         cll_f189_invoice_lines       cil,
                         cll_f189_invoices            ci,
                         cll_f189_entry_operations    ceo
                   WHERE cftrc.operation_status      <> 'COMPLETE'
                     AND cftrc.tpa_remit_control_id   = ctrc.tpa_remit_control_id
                     AND cftrc.invoice_line_id        = cil.invoice_line_id
                     AND cil.invoice_id               = ci.invoice_id
                     AND ci.organization_id           = ceo.organization_id
                     AND ci.operation_id              = ceo.operation_id
                     AND cftrc.organization_id        = p_organization_id -- For example: 7409
                     AND cftrc.operation_id           = p_operation_id -- For exammple: 182
                   GROUP BY ctrc.transfer_organization_id;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      v_nQtd_nf_retorno_assoc_nf_rem := 0;
                    WHEN OTHERS THEN
                      v_nQtd_nf_retorno_assoc_nf_rem := 0;
                END;
                --
                IF NVL(v_nQtd_nf_retorno_assoc_nf_rem, 0) = 0 THEN
                  v_nQtd_nf_retorno_assoc_nf_rem := 0;
                  v_nTransfer_organization_id    := NULL;
                  BEGIN
                  SELECT NVL(COUNT(*), 0) QTD,
                         ctrc.transfer_organization_id
                    INTO v_nQtd_nf_retorno_assoc_nf_rem,
                         v_nTransfer_organization_id
                    FROM cll_f513_tpa_remit_control   ctrc,
                         cll_f513_tpa_returns_control cftrc
                   WHERE cftrc.operation_status          = 'COMPLETE'
                     AND NVL(cftrc.reversion_flag, 'N') <> 'Y'
                     AND cftrc.tpa_remit_control_id      = ctrc.tpa_remit_control_id
                     AND cftrc.organization_id           = p_organization_id -- For example: 7409
                     AND cftrc.operation_id              =
                         (SELECT operation_id
                            FROM cll_f189_invoices
                           WHERE invoice_id =
                                 (SELECT ri2.invoice_parent_id
                                    FROM cll_f189_invoices         ri2,
                                         cll_f189_entry_operations reo2
                                   WHERE ri2.operation_id    = p_operation_id -- For exammple: 182
                                     AND ri2.organization_id = p_organization_id -- For example: 7409
                                     AND ri2.operation_id    = reo2.operation_id
                                     AND ri2.organization_id = reo2.organization_id
                                     AND reo2.reversion_flag = 'S'
                                     AND ROWNUM              = 1))
                     GROUP BY ctrc.transfer_organization_id;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      v_nQtd_nf_retorno_assoc_nf_rem := 0;
                    WHEN OTHERS THEN
                      v_nQtd_nf_retorno_assoc_nf_rem := 0;
                  END;
                END IF;
                --
                IF NVL(v_nQtd_nf_retorno_assoc_nf_rem, 0) <> 0 THEN
                  --
                  BEGIN
                    v_nSource_acct_period_id := NULL;
                    v_dgl_date               := NULL;
                    v_vSource_period_status  := NULL;
                    BEGIN
                      SELECT oap.acct_period_id,
                             ceo.gl_date,
                             UPPER(oap.status) status
                        INTO v_nSource_acct_period_id,
                             v_dgl_date,
                             v_vSource_period_status
                        FROM cll_f189_entry_operations ceo, org_acct_periods_v oap
                       WHERE ceo.operation_id    = p_operation_id -- For example: 185
                         AND ceo.organization_id = p_organization_id -- For example: 7409
                         AND oap.rec_type        = 'ORG_PERIOD' -- Default value
                         AND ceo.gl_date         BETWEEN oap.start_date AND oap.end_date
                         AND ceo.organization_id = oap.organization_id;
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        v_nSource_acct_period_id := NULL;
                        v_dgl_date               := NULL;
                        v_vSource_period_status  := NULL;
                      WHEN OTHERS THEN
                        v_nSource_acct_period_id := NULL;
                        v_dgl_date               := NULL;
                        v_vSource_period_status  := NULL;
                    END;
                    v_vTransfer_period_status := v_vSource_period_status;
                  END;
                  --
                  IF NVL(v_vSource_period_status, 'X') NOT IN ('ABERTO', 'OPEN', 'ABIERTO') THEN
                  -- Call the procedure
                  incluir_erro_hold(p_operation_id    => p_operation_id,
                                    p_organization_id => p_organization_id,
                                    p_location_id     => r_invoice_lines.location_id,
                                    p_hold_code       => 'NO OPEN PERIOD FOUND ORGANIZAT',
                                    p_invoice_id      => r_invoice_lines.Invoice_id,
                                    p_invoice_line_id => r_invoice_lines.invoice_line_id);
                  END IF;
                  --
                  IF p_organization_id <> v_nTransfer_organization_id THEN
                    BEGIN
                      v_vTransfer_period_status := 'X';
                      BEGIN
                        SELECT UPPER(oap.status) status
                          INTO v_vTransfer_period_status
                          FROM org_acct_periods_v oap
                         WHERE oap.organization_id = v_nTransfer_organization_id
                           AND oap.rec_type        = 'ORG_PERIOD' -- Default value
                           AND oap.start_date     <= v_dgl_date
                           AND oap.end_date       >= v_dgl_date;
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          v_vTransfer_period_status := 'X';
                        WHEN OTHERS THEN
                          v_vTransfer_period_status := 'X';
                      END;
                    END;
                  END IF;
                  --
                  IF NVL(v_vTransfer_period_status, 'X') NOT IN ('ABERTO', 'OPEN', 'ABIERTO') THEN
                  -- Call the procedure
                  incluir_erro_hold(p_operation_id    => p_operation_id,
                                    p_organization_id => p_organization_id,
                                    p_location_id     => r_invoice_lines.location_id,
                                    p_hold_code       => 'NO OPEN PERIOD FOUND TRANS ORG',
                                    p_invoice_id      => r_invoice_lines.Invoice_id,
                                    p_invoice_line_id => r_invoice_lines.invoice_line_id);
                  END IF;
                END IF;
                -- BUG 28247307 -- End (WCarvalho - 20/JUL/2018)
                --
/*              ja tratado no BUG 28496313
                BEGIN
                  v_nRemaining_balance := 0;
                  v_nReturned_quantity := 0;
                  SELECT NVL(tpa.remaining_balance, 0), NVL(tpr.returned_quantity, 0)
                    INTO v_nRemaining_balance, v_nReturned_quantity
                    FROM cll_f513_tpa_remit_control   tpa,
                         cll_f513_tpa_returns_control tpr,
                         cll_f189_invoice_lines       cil
                   WHERE tpr.tpa_remit_control_id = tpa.tpa_remit_control_id
                     AND tpr.organization_id      = tpa.organization_id
                     AND tpr.invoice_line_id      = cil.invoice_line_id
                     AND tpa.organization_id      = cil.organization_id
                     AND tpa.organization_id      = p_organization_id
                     AND tpr.invoice_id           = r_invoice_lines.Invoice_id
                     AND cil.invoice_line_id      = r_invoice_lines.invoice_line_id;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    v_nRemaining_balance := 0;
                    v_nReturned_quantity := 0;
                  WHEN OTHERS THEN
                    v_nRemaining_balance := 0;
                    v_nReturned_quantity := 0;
                END;
                --
                IF NVL(v_nReturned_quantity, 0) > NVL(v_nRemaining_balance, 0) THEN
                  -- Call the procedure
                  incluir_erro_hold(p_operation_id    => p_operation_id,
                                    p_organization_id => p_organization_id,
                                    p_location_id     => r_invoice_lines.location_id,
                                    p_hold_code       => 'GREATER QUANTITY RETURNED',
                                    p_invoice_id      => r_invoice_lines.Invoice_id,
                                    p_invoice_line_id => r_invoice_lines.invoice_line_id);
                END IF; */
                --
               /*BUG 27796521 -- Start (WCarvalho - 18/APR/2018)*/
              /*BEGIN
                  v_nQuantity_invoice_line := 0;
                  SELECT NVL(cil.quantity, 0) quantity_invoice_line
                    INTO v_nQuantity_invoice_line
                    FROM cll_f189_invoice_lines cil, cll_f189_invoices ci
                   WHERE cil.invoice_id = ci.invoice_id
                     AND cil.organization_id = p_organization_id
                     AND cil.invoice_line_id = r_invoice_lines.invoice_line_id;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    v_nQuantity_invoice_line := 0;
                  WHEN OTHERS THEN
                    v_nQuantity_invoice_line := 0;
                END;*/
                --
                 BEGIN
                  v_nReturned_qty_total := 0;
                  SELECT SUM(NVL(returned_quantity, 0)) returned_quantity
                    INTO v_nReturned_qty_total
                    FROM cll_f513_tpa_ret_trans_assoc_v
                   WHERE operation_id      = p_operation_id
                     AND organization_id   = p_organization_id
                     AND invoice_id        = r_invoice_lines.invoice_id
                     AND invoice_line_id   = r_invoice_lines.invoice_line_id
                     AND inventory_item_id = r_invoice_lines.item_id
                     AND query_only        = 'NO';
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    v_nReturned_qty_total := 0;
                  WHEN OTHERS THEN
                    v_nReturned_qty_total := 0;
                END;
                /*BUG 27796521 -- End (WCarvalho - 18/APR/2018)*/
                --
                IF v_nReturned_qty_total    > 0 AND
                   v_nQuantity_invoice_line > 0 AND
                   v_nReturned_qty_total   <> v_nQuantity_invoice_line THEN
                  -- Call the procedure
                  incluir_erro_hold(p_operation_id    => p_operation_id,
                                    p_organization_id => p_organization_id,
                                    p_location_id     => r_invoice_lines.location_id,
                                    p_hold_code       => 'DIVERGENT QUANTITY RETURNED',
                                    p_invoice_id      => r_invoice_lines.Invoice_id,
                                    p_invoice_line_id => r_invoice_lines.invoice_line_id);
                END IF;
              END IF;
            END IF;
          /*ER 26338366/26899224 -- Start (WCarvalho - 13/DEC/2017)*/
          ELSE -- p_interface = 'N'
            BEGIN
              v_nReturned_qty_total_iface := 0;
              SELECT SUM(NVL(cftri.quantity, 0)) returned_qty_total_iface
                INTO v_nReturned_qty_total_iface
                FROM cll_f513_tpa_ret_iface cftri
               WHERE cftri.interface_invoice_id      = p_interface_invoice_id
                 AND cftri.interface_invoice_line_id = r_invoice_lines.interface_invoice_line_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_nReturned_qty_total_iface := 0;
              WHEN OTHERS THEN
                v_nReturned_qty_total_iface := 0;
            END;
            --
            IF NVL(v_nReturned_qty_total_iface, 0)  > 0 AND
               NVL(r_invoice_lines.quantity, 0)     > 0 AND
               NVL(v_nReturned_qty_total_iface, 0) <> NVL(r_invoice_lines.quantity, 0) THEN
              -- Call the procedure
              incluir_erro(r_invoice_lines.Invoice_id,
                           p_operation_id,
                           'DIVERGENT QUANTITY RETURNED',
                           r_invoice_lines.interface_invoice_line_id);
            END IF;
          END IF;
          /*ER 26338366/26899224 -- End (WCarvalho - 13/DEC/2017)*/
        END IF;
        /*ER 26338366/26899224 -- End (WCarvalho - 30/OCT/2017)*/


          IF r_invoice_lines.include_iss_flag = 'Y' THEN
            x_prf_setup_iss := fnd_profile.VALUE('CLL_F189_SETUP_ISS');
            --               IF x_prf_setup_iss = 'LOCAL DE ENTREGA' -- Bug 8831579 - SSimoes - 03/09/2009
            IF x_prf_setup_iss = 'LOCATION' THEN
              -- Bug 8831579 - SSimoes - 03/09/2009
              IF p_interface = 'N' THEN
                -- ER 12394705 - Inicio
                IF r_invoice_lines.simplified_br_tax_flag = 'Y' AND
                   r_invoice_lines.iss_city_id IS NULL AND
                   NVL(r_invoice_lines.iss_base_amount,0) = 0 AND
                   NVL(r_invoice_lines.iss_tax_amount,0) = 0 THEN
                  NULL;
                ELSE
                  -- ER 12394705 - Fim
                  BEGIN
                    SELECT COUNT(1)
                      INTO x_cont
                      FROM cll_f189_fiscal_entities_all rfea,
                           cll_f189_tax_sites           rts
                     WHERE rts.organization_id = p_organization_id
                       AND rts.tax_type = 'ISS'
                       AND rfea.city_id = r_invoice_lines.iss_city_id
                       AND rfea.entity_id = rts.tax_bureau_site_id;
                    --
                    IF x_cont = 0 THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                 'NONE ISS CITY BUREAU', -- sasasa
                                                                 NULL,
                                                                 NULL);
                    END IF;
                  EXCEPTION
                    WHEN OTHERS THEN
                      raise_application_error(-20555,
                                              SQLERRM ||
                                              '**********************' ||
                                              ' Select ISS city bureau ' ||
                                              '**********************');
                  END;
                  --
                  BEGIN
                    SELECT COUNT(1)
                      INTO x_cont
                      FROM cll_f189_calendar_tax_cities rctc
                     WHERE TRUNC(x_receive_date) BETWEEN
                           TRUNC(rctc.START_DATE) AND TRUNC(rctc.end_date)
                       AND rctc.city_id = r_invoice_lines.iss_city_id
                       ;
                    --
                    IF x_cont = 0 THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                 'NONE ISS CITY CALENDAR',
                                                                 NULL,
                                                                 NULL);
                    END IF;
                  EXCEPTION
                    WHEN OTHERS THEN
                      raise_application_error(-20555,
                                              SQLERRM ||
                                              '**********************' ||
                                              ' Select ISS city calendar ' ||
                                              '**********************');
                  END;
                END IF; -- ER 12394705
              END IF;
              -- Bug 8791684 - SSimoes - 09/09/2009 - Inicio
              IF p_interface = 'N' THEN
                -- ER 12394705 - Inicio
                IF r_invoice_lines.simplified_br_tax_flag = 'Y' AND
                   r_invoice_lines.iss_city_id IS NULL AND
                   NVL(r_invoice_lines.iss_base_amount,0) = 0 AND
                   NVL(r_invoice_lines.iss_tax_amount,0) = 0 THEN
                  NULL;
                ELSE
                  -- ER 12394705 - Fim
                  BEGIN
                    SELECT operating_unit
                      INTO v_operating_unit
                      FROM org_organization_definitions
                     WHERE organization_id = p_organization_id;
                    -- Bug 8791684 - SSimoes - 17/11/2009 - Inicio
                    /*
                    SELECT COUNT(1)
                    INTO v_local_inativo
                    FROM po_vendor_sites_all pvsa
                       , po_vendors pv
                       , cll_f189_cities rc
                       , cll_f189_states rs
                       , cll_f189_fiscal_entities_all rfea
                   WHERE pvsa.vendor_site_id = rfea.vendor_site_id
                     AND pv.vendor_id = pvsa.vendor_id
                     AND UPPER(pv.vendor_type_lookup_code) IN ('TAX AUTHORITY','AGENTE ARRECADADOR')
                     AND (pvsa.inactive_date IS NULL OR pvsa.inactive_date > SYSDATE)
                     AND (pv.start_date_active IS NULL OR pv.start_date_active < SYSDATE)
                     AND (pv.end_date_active IS NULL OR pv.end_date_active > SYSDATE)
                     AND (v_operating_unit IS NULL OR rfea.org_id = v_operating_unit)
                     AND (v_operating_unit IS NULL OR pvsa.org_id = v_operating_unit)
                     AND rfea.city_id = rc.city_id
                     AND rc.state_id = rs.state_id
                     AND rc.city_id = r_invoices.iss_city_id;
                  */
                  SELECT COUNT(1)
                    INTO v_local_inativo
                    FROM po_vendor_sites_all          pvsa,
                         po_vendors                   pv,
                         cll_f189_cities              rc,
                         cll_f189_states              rs,
                         cll_f189_fiscal_entities_all rfea,
                         cll_f189_tax_sites           rts
                   WHERE pvsa.vendor_site_id = rfea.vendor_site_id
                     AND pv.vendor_id = pvsa.vendor_id
                     AND UPPER(pv.vendor_type_lookup_code) IN
                         ('TAX AUTHORITY', 'AGENTE ARRECADADOR')
                     AND (pvsa.inactive_date IS NULL OR
                         pvsa.inactive_date > SYSDATE)
                     AND (pv.start_date_active IS NULL OR
                         pv.start_date_active < SYSDATE)
                     AND (pv.end_date_active IS NULL OR
                         pv.end_date_active > SYSDATE)
                     AND (v_operating_unit IS NULL OR
                         rfea.org_id = v_operating_unit)
                     AND (v_operating_unit IS NULL OR
                         pvsa.org_id = v_operating_unit)
                     AND rfea.city_id = rc.city_id
                     AND rc.state_id = rs.state_id
                     AND rc.city_id = r_invoice_lines.iss_city_id --- r_invoices.iss_city_id --- 25591653
                     AND rts.organization_id = p_organization_id
                     AND rts.tax_type = 'ISS'
                     AND rfea.entity_id = rts.tax_bureau_site_id
                     AND rfea.city_id = rc.city_id;
                  -- Bug 8791684 - SSimoes - 17/11/2009 - Fim
                  IF v_local_inativo = 0 THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'INV ISS CITY BUREAU',
                                                               NULL,
                                                               NULL);
                  END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20558,
                                            SQLERRM ||
                                            '*******************************' ||
                                            ' Select ISS city active bureau ' ||
                                            '*******************************');
                END;
              END IF; -- ER 12394705
            END IF;
            -- Bug 8791684 - SSimoes - 09/09/2009 - Fim
          END IF;

          -- 25494912 - Start
----          BEGIN
----            SELECT rc.iss_tax_type
----              INTO l_iss_tax_type
----              FROM CLL_F189_CITIES rc, CLL_F189_fiscal_entities_all rfea
----             WHERE rfea.location_id = p_location_id
----               AND rfea.city_id = rc.city_id;
----          EXCEPTION
----            WHEN NO_DATA_FOUND THEN
----              l_iss_tax_type := NULL;
----            WHEN OTHERS THEN
----              l_iss_tax_type := NULL;
----          END;
          -- 25494912 - End

----          BEGIN
----            -- 26143868
----            SELECT rc.city_id
----            --,rc.iss_tax_type -- 25494912
----              INTO l_city_id
----            --,l_iss_tax_type  -- 25494912
----              FROM cll_f189_fiscal_entities_all rfea, cll_f189_cities rc
----             WHERE rfea.entity_id = r_invoices.entity_id
----               AND rfea.city_id = rc.city_id;
----            -- 26143868 - Start
----          EXCEPTION
----            WHEN NO_DATA_FOUND THEN
----              l_city_id := NULL;
----            WHEN OTHERS THEN
----              l_city_id := NULL;
----          END;
          -- 26143868 - End

          -- 25591653 - Start
          /*
          -- 25028715 - Start
          IF l_line_iss_tax_type IN ('NORMAL', 'EXEMPT') THEN --25591653
----      IF l_iss_tax_type IN ('NORMAL', 'EXEMPT') THEN      --25591653

          --IF CLL_F189_FISCAL_UTIL_PKG.GET_FISCAL_OBLIGATION_ISS(p_location_id,     -- 25591653
          --                                                      l_city_id) THEN    -- 25591653


              IF CLL_F189_ISS_TAX_PKG.GET_FISCAL_OBLIGATION_ISS( p_location_id         -- 25591653
                                                                ,l_line_city_id ) THEN -- 25591653

                 IF (NVL(r_invoice_lines.iss_base_amount,0) = 0 OR NVL(r_invoice_lines.iss_tax_amount,0) = 0) THEN

                    IF p_interface = 'N' THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                  'FISCAL OBLIGATION ISS',
                                                                  r_invoice_lines.invoice_id,
                                                                  NULL);
                    ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                             p_operation_id,
                                                             'FISCAL OBLIGATION ISS');
                    END IF;

                 END IF;


              END IF;
          END IF;
          -- 25028715 - End
          */
          -- 25591653 - End
        END IF;
        --
		-- BUG 30789077 - Start
		--
        IF NVL(r_invoice_lines.tpa_control_type, 'x') = 'MATERIAL_OF' AND l_verify_hold_cfo_tpa IS NULL THEN
		  --
		  BEGIN
		    --
			l_cfo_id_tpa := r_invoice_lines.cfo_id ;
			--
			IF l_cfo_id_tpa IS NULL THEN
			  --
			  BEGIN
			    --
				SELECT cfo_id
				  INTO l_cfo_id_tpa
				  FROM cll_f189_fiscal_operations
                 WHERE cfo_code = r_invoice_lines.cfo_code ;
			    --
			  EXCEPTION
                WHEN OTHERS THEN
	              l_cfo_id_tpa := NULL ;
              END ;
              --
            END IF ;
            --
            BEGIN
			  --
			  SELECT COUNT(*)
			    INTO l_count_cfo_err
                FROM cll_f513_cust_network ccn
               WHERE NVL(ccn.inactive_flag, 'N') <> 'Y'
                 AND ( l_cfo_id_tpa = ccn.in_state_cfop_id
                  OR   l_cfo_id_tpa = ccn.out_state_cfop_id )
                 AND ccn.utilization_id = ( SELECT cfiu.utilization_id
				                              FROM cll_f189_item_utilizations cfiu
                                             WHERE cfiu.utilization_id   = r_invoice_lines.utilization_id
                                                OR cfiu.utilization_code = r_invoice_lines.utilization_code )
                 AND ccn.operating_unit  IN ( SELECT operating_unit
                                                FROM org_organization_definitions
                                               WHERE organization_id = p_organization_id ) ;
			  --
            EXCEPTION
              WHEN OTHERS THEN
	            l_count_cfo_err := NULL ;
            END ;
            --
		    l_verify_hold_cfo_tpa := 'Y' ;
		    --
		    IF NVL(l_count_cfo_err, 0) = 0 THEN
		      --
              IF p_interface = 'N' THEN
		        --
                cll_f189_check_holds_pkg.incluir_erro_hold ( p_operation_id
                                                           , p_organization_id
                                                           , p_location_id
                                                           , 'TPA CFO INV SETUP'
                                                           , r_invoice_lines.invoice_id
                                                           , r_invoice_lines.invoice_line_id ) ;
              ELSE
		        --
                cll_f189_check_holds_pkg.incluir_erro ( r_invoice_lines.interface_invoice_id
                                                      , p_operation_id
                                                      , 'TPA CFO INV SETUP'
                                                      , r_invoice_lines.interface_invoice_line_id ) ;
              END IF ;
		      --
		    END IF ;
			--
		  END ;
		  --
		END IF ;
        --
		-- BUG 30789077 - End
		--
      END LOOP ;
      --
      FOR r_invoices IN c_invoices LOOP
        --
        w_table_associated := 1; -- ERancement 4533742 AIrmer 12/08/2005
        --
        -- Incio BUG 19722064
        BEGIN
          SELECT invoice_type_id
            INTO l_invoice_type_id
            FROM cll_f189_invoice_types
           WHERE invoice_type_code = r_invoices.invoice_type_code
             AND organization_id = p_organization_id;
        EXCEPTION
          WHEN no_data_found THEN
            l_invoice_type_id := 0;
        END;
        --
        -- Fim BUG 19722064
        -- ER 9289619: Start
        IF r_invoices.return_customer_flag = 'F' OR
           r_invoices.price_adjust_flag = 'Y' OR
           r_invoices.tax_adjust_flag = 'Y' THEN
          --
          IF p_interface = 'N' THEN
            --
            BEGIN
              --
              SELECT COUNT(1)
                INTO nquantnfpai
                FROM cll_f189_invoice_parents rip
               WHERE rip.invoice_id = r_invoices.invoice_id;
              --
            EXCEPTION
              WHEN OTHERS THEN
                --
                raise_application_error(-20611,
                                        SQLERRM || '****************' ||
                                        ' Invoice parent not found ' ||
                                        '******************');
                --
            END;
            --
            IF (nquantnfpai > 0) THEN
              --
              BEGIN
                --
                SELECT COUNT(1)
                  INTO l_quantnfpai_sn
                  FROM cll_f189_invoices cfi, cll_f189_invoice_parents cfip
                 WHERE cfip.invoice_id = r_invoices.invoice_id
                   AND cfi.invoice_id = cfip.invoice_parent_id
                   AND NVL(simplified_br_tax_flag, 'N') = 'Y';
                --
              EXCEPTION
                WHEN OTHERS THEN
                  --
                  raise_application_error(-20611,
                                          SQLERRM || '****************' ||
                                          ' Invoice parent not found ' ||
                                          '******************');
                  --
              END;
              --
              IF l_quantnfpai_sn <> nquantnfpai THEN
                --
                IF l_quantnfpai_sn > 0 THEN
                  --
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'PARENT INV DIVERG',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  --
                  IF r_invoices.simplified_br_tax_flag = 'Y' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'SUPPLIER_REGIME_DIVERG',
                                                               r_invoices.invoice_id,
                                                               NULL);
                    --
                  END IF;
                  --
                END IF;
                --
              ELSE
                --
                IF r_invoices.simplified_br_tax_flag = 'N' THEN
                  --
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'SUPPLIER_REGIME_DIVERG',
                                                             r_invoices.invoice_id,
                                                             NULL);
                  --
                END IF;
                --
              END IF;
              --
            END IF;
            --
          ELSE
            --
            BEGIN
              --
              SELECT COUNT(1)
                INTO nquantnfpai
                FROM cll_f189_invoice_parents_int rip
               WHERE rip.interface_invoice_id =
                     r_invoices.interface_invoice_id;
              --
            EXCEPTION
              WHEN OTHERS THEN
                --
                raise_application_error(-20612,
                                        SQLERRM || '****************' ||
                                        ' Invoice parent not found ' ||
                                        '******************');
                --
            END;
            --
            IF (nquantnfpai > 0) THEN
              --
              BEGIN
                --
                SELECT COUNT(1)
                  INTO l_quantnfpai_sn
                  FROM cll_f189_invoices            cfi,
                       cll_f189_invoice_parents_int cfipi
                 WHERE cfipi.interface_invoice_id =
                       r_invoices.interface_invoice_id
                   AND cfi.invoice_id = cfipi.invoice_parent_id
                   AND NVL(simplified_br_tax_flag, 'N') = 'Y';
                --
              EXCEPTION
                WHEN OTHERS THEN
                  --
                  raise_application_error(-20611,
                                          SQLERRM || '****************' ||
                                          ' Invoice parent not found ' ||
                                          '******************');
                  --
              END;
              --
              IF l_quantnfpai_sn <> nquantnfpai THEN
                --
                IF l_quantnfpai_sn > 0 THEN
                  --
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'PARENT INV DIVERG',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  --
                  IF r_invoices.simplified_br_tax_flag = 'Y' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'SUPPLIER_REGIME_DIVERG',
                                                               r_invoices.invoice_id,
                                                               NULL);
                    --
                  END IF;
                  --
                END IF;
                --
              ELSE
                --
                IF r_invoices.simplified_br_tax_flag = 'N' THEN
                  --
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'SUPPLIER_REGIME_DIVERG',
                                                             r_invoices.invoice_id,
                                                             NULL);
                  --
                END IF;
                --
              END IF;
              --
            END IF;
            --
          END IF;
          --
        END IF;
        -- ER 9289619: End
        -- ER 9289619: Start
        IF r_invoices.simplified_br_tax_flag = 'Y' THEN
          --
          BEGIN
            --
            SELECT arr
              INTO w_arr
              FROM cll_f189_parameters
             WHERE organization_id = p_organization_id;
            --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              w_arr := 0;
          END;
          --
          -- ER 14124731 - Start
        --IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'Y' THEN                 -- 27579747
          IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
          AND p_interface = 'Y' THEN                                                     -- 27579747
            NULL;
          ELSE
            -- ER 14124731 - End

            IF p_interface = 'N' THEN
              --
              BEGIN
                --
                SELECT sum(nvl(icms_amount_recover, 0)),
                       sum(nvl(round(icms_amount_recover, 2), 0)),
                       sum(nvl(trunc(icms_amount_recover, 2), 0))
                  INTO l_icms_amt_rec_lines,
                       l_icms_amt_rec_lines_round,
                       l_icms_amt_rec_lines_trunc
                  FROM cll_f189_invoice_lines
                 WHERE invoice_id = r_invoices.invoice_id;
                --
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  l_icms_amt_rec_lines       := 0;
                  l_icms_amt_rec_lines_round := 0;
                  l_icms_amt_rec_lines_trunc := 0;
              END;
              --
              IF ROUND(l_icms_amt_rec_lines, w_arr) >
                 ROUND(r_invoices.max_icms_amount_recover, w_arr) AND
                 TRUNC(l_icms_amt_rec_lines, w_arr) >
                 TRUNC(r_invoices.max_icms_amount_recover, w_arr) AND
                 l_icms_amt_rec_lines_round >
                 ROUND(r_invoices.max_icms_amount_recover, w_arr) AND
                 l_icms_amt_rec_lines_trunc >
                 TRUNC(r_invoices.max_icms_amount_recover, w_arr) THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'ICMS REC AMT GT MAX',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              END IF;
              --
            ELSE
              --
              BEGIN
                --
                SELECT sum(nvl(icms_amount_recover, 0)),
                       sum(nvl(round(icms_amount_recover, 2), 0)),
                       sum(nvl(trunc(icms_amount_recover, 2), 0))
                  INTO l_icms_amt_rec_lines,
                       l_icms_amt_rec_lines_round,
                       l_icms_amt_rec_lines_trunc
                  FROM cll_f189_invoice_lines_iface
                 WHERE interface_invoice_id = r_invoices.invoice_id;
                --
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  l_icms_amt_rec_lines       := 0;
                  l_icms_amt_rec_lines_round := 0;
                  l_icms_amt_rec_lines_trunc := 0;
              END;
              --
              IF ROUND(l_icms_amt_rec_lines, w_arr) >
                 ROUND(r_invoices.max_icms_amount_recover, w_arr) AND
                 TRUNC(l_icms_amt_rec_lines, w_arr) >
                 TRUNC(r_invoices.max_icms_amount_recover, w_arr) AND
                 l_icms_amt_rec_lines_round >
                 ROUND(r_invoices.max_icms_amount_recover, w_arr) AND
                 l_icms_amt_rec_lines_trunc >
                 TRUNC(r_invoices.max_icms_amount_recover, w_arr) THEN
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'ICMS REC AMT GT MAX',
                                                      NULL);
                --
              END IF;
              --
            END IF;
            --
          END IF;
          --
        END IF;
        --
        -- Bug 10367485 - Start
        l_invoice_days := to_number(trunc(trunc(SYSDATE) -
                                          r_invoices.invoice_date));
        --
        IF l_invoice_date_less_than < l_invoice_days THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'INVOICE DATE LESS THAN',
                                                       r_invoices.invoice_id,
                                                       NULL);

          END IF;
        END IF;
        -- Bug 10367485 - End
        --

        -- 17972879 - Start
        IF r_invoices.eletronic_invoice_key IS NOT NULL THEN

          CLL_F189_MDFE_PKG.GET_STATUS(r_invoices.eletronic_invoice_key,
                                       l_manifest_requested,
                                       l_manifest_status);

          IF l_manifest_requested = '210220' -- 210220 -> Ownership rejection
             AND l_manifest_status = '0' THEN

            IF p_interface = 'N' THEN

              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'OWNERSHIP REJECTION',
                                                         r_invoices.invoice_id,
                                                         '');

            END IF;

          ELSIF l_manifest_requested = '210240' -- 210240 -> Transaction rejection
                AND l_manifest_status = '0' THEN

            IF p_interface = 'N' THEN

              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'TRANSACTION REJECTION',
                                                         r_invoices.invoice_id,
                                                         '');

            END IF;

          ELSIF l_manifest_requested = '210200' -- 210200 -> Trasaction Confirmation
                AND l_manifest_status = '0' THEN

            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'CONFIRMATION ERROR',
                                                       r_invoices.invoice_id,
                                                       '');

          END IF;

        END IF;
        -- 17972879 - End
        --
        -- Bug 13947775 - Start
        -- ER 13687710 - Start
        cll_f189_fiscal_doc_type_pkg.get_fiscal_doc_type_setup(UPPER(r_invoices.fiscal_document_model),
                                                               x_efd_type,
                                                               x_invoice_key_required_flag,
                                                               x_invoice_key_validation_flag,
                                                               x_invoice_number_length_flag);

        --IF r_invoices.document_type_inv IN ('NFE','CTE') THEN
        IF NVL(x_invoice_key_validation_flag, 'N') = 'Y' THEN
          -- ER 13687710 - End
          -- ER 9289619: Start
          --
          -- ER 12352413 - Inicio
          IF r_invoices.eletronic_invoice_key IS NOT NULL THEN
            --
            BEGIN
              --
              BEGIN
                --
                l_nfe_key := TO_NUMBER(r_invoices.eletronic_invoice_key);
                --
              EXCEPTION
                WHEN OTHERS THEN
                  RAISE l_nfe_key_inv;
                  --
              END;
              --
              IF LENGTH(r_invoices.eletronic_invoice_key) <> 44 THEN
                --
                RAISE l_nfe_key_inv;
                --
              END IF;
              --
            EXCEPTION
              WHEN l_nfe_key_inv THEN
                --
                IF p_interface = 'N' THEN
                  --
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NFE ACCESS KEY INVALID',
                                                             r_invoices.invoice_id,
                                                             NULL);
                  --
                ELSE
                  --
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                        p_operation_id,
                                                        'NFE ACCESS KEY INVALID');
                  --
                END IF;
                --
            END;
            --
            IF NOT
                cll_f189_digit_calc_pkg.func_access_key(r_invoices.eletronic_invoice_key) THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV ACCESS KEY NFE',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INV ACCESS KEY NFE');
                --
              END IF;
              --
            END IF;
            --
            -- ER 14622175 - Start
            BEGIN
              SELECT cs.state_code, cfea.document_number
                INTO l_state_code, l_document_number
                FROM cll_f189_states cs, cll_f189_fiscal_entities_all cfea
               WHERE cfea.entity_id = r_invoices.entity_id
                 AND cfea.state_id = cs.state_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                l_state_code      := NULL;
                l_document_number := NULL;
            END;
            --
            IF NOT
                cll_f189_validate_number_pkg.invoice_key(p_uf              => l_state_code,
                                                         p_invoice_date    => r_invoices.invoice_date,
                                                         p_document_number => l_document_number,
                                                         p_model           => r_invoices.fiscal_document_model,
                                                         p_serie           => r_invoices.series
                                                         --, p_invoice_num     => r_invoices.invoice_num -- Bug 16781933
                                                        ,
                                                         p_invoice_num     => TRUNC(r_invoices.invoice_num) -- Bug 16781933
                                                        ,
                                                         p_access_key      => r_invoices.eletronic_invoice_key,
                                                         p_organization_id => r_invoices.organization_id) THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INCONSISTENT INVOICE KEY',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INCONSISTENT INVOICE KEY');
                --
              END IF;
              --
            END IF;
            -- ER 14622175 - End
            --
          END IF;
          -- ER 12352413 - Fim
          --
          --
        END IF;
        -- Bug 13947775 - End
        --
-- 28180196 Start
/*
        -- 27579747 - Start
        IF r_invoices.eletronic_invoice_key IS NOT NULL THEN

           SELECT count(*)
             INTO l_nfe_key_exist
           FROM CLL_F189_ENTRY_OPERATIONS rco
               ,CLL_F189_INVOICES         ri
           WHERE rco.organization_id = p_organization_id
             AND rco.status = 'COMPLETE'
             AND rco.operation_id = ri.operation_id
             AND ri.eletronic_invoice_key = r_invoices.eletronic_invoice_key
             AND nvl(rco.reversion_flag, 'N') NOT IN ('R','S'); -- 27869341

           IF l_nfe_key_exist > 0 THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DUPLICATED ACCESS KEY NFE',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'DUPLICATED ACCESS KEY NFE');
                --
              END IF;

           END IF;

        END IF;
        -- 27579747 - End
*/
-- 28180196 End
        --
        -- Bug 20404053 - Start
        IF ((r_invoices.carrier_document_type IS NOT NULL AND
           r_invoices.carrier_document_number IS NULL) OR
           (r_invoices.carrier_document_type IS NULL AND
           r_invoices.carrier_document_number IS NOT NULL)) THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DOC TYPE NUMBER REQUIRED',
                                                       r_invoices.invoice_id,
                                                       NULL);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                  p_operation_id,
                                                  'DOC TYPE NUMBER REQUIRED');
            --
          END IF;
          --
        END IF;
        --
        IF r_invoices.carrier_document_type IN ('CPF', 'CNPJ') THEN
          l_doc_num          := lpad(substr(to_char(r_invoices.carrier_document_number),
                                            1,
                                            15),
                                     15,
                                     '0');
          l_validate_doc_num := CLL_F189_DIGIT_CALC_PKG.FUNC_DOC_VALIDATION(r_invoices.carrier_document_type,
                                                                            l_doc_num);
          --
          IF l_validate_doc_num = 0 THEN
            IF p_interface = 'N' THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INV CARRIER DOC NUM',
                                                         r_invoices.invoice_id,
                                                         NULL);
              --
            ELSE
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'INV CARRIER DOC NUM');
              --
            END IF;
          END IF;
        END IF;
        --
        IF r_invoices.carrier_state_id IS NOT NULL THEN
          --
          BEGIN
            SELECT cst.state_code
              INTO l_carrier_state_code
              FROM cll_f189_states cst
             WHERE cst.state_id = r_invoices.carrier_state_id
               AND cst.national_state = 'Y'
               AND (cst.inactive_date IS NULL OR
                   TRUNC(cst.inactive_date) >= TRUNC(sysdate));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'STATE INVALID',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'STATE INVALID');
                --
              END IF;
              --
            WHEN OTHERS THEN
              --
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'STATE INVALID',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'STATE INVALID');
                --
              END IF;
              --
          END;
          --
        END IF;
        --
        IF l_carrier_state_code IS NOT NULL AND
           l_carrier_state_code NOT IN ('AC',
                                        'AL',
                                        'AM',
                                        'AP',
                                        'BA',
                                        'CE',
                                        'DF',
                                        'ES',
                                        'GO',
                                        'MA',
                                        'MG',
                                        'MS',
                                        'MT',
                                        'PA',
                                        'PB',
                                        'PR',
                                        'PE',
                                        'PI',
                                        'RJ',
                                        'RN',
                                        'RS',
                                        'RO',
                                        'RR',
                                        'SC',
                                        'SP',
                                        'SE',
                                        'TO') THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'STATE IE INVALID',
                                                       r_invoices.invoice_id,
                                                       NULL);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                  p_operation_id,
                                                  'STATE IE INVALID');
            --
          END IF;
          --
        END IF;
        --
        /*
        IF ( (r_invoices.carrier_state_id IS NOT NULL AND r_invoices.carrier_ie IS NULL)
        OR (r_invoices.carrier_state_id IS NULL AND r_invoices.carrier_ie IS NOT NULL) ) THEN
        */
        IF r_invoices.carrier_ie IS NOT NULL AND
           r_invoices.carrier_state_id IS NULL THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'STATE IE REQUIRED',
                                                       r_invoices.invoice_id,
                                                       NULL);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                  p_operation_id,
                                                  'STATE IE REQUIRED');
            --
          END IF;
          --
        ELSE
          --
          -- Begin BUG 26913706
          IF r_invoices.carrier_ie = 'ISENTO' THEN
            NULL;
          ELSE
            -- End BUG 26913706
            IF r_invoices.carrier_ie IS NOT NULL AND
               l_carrier_state_code IS NOT NULL THEN
              --
              IF NOT
                  CLL_F189_IE_VALIDATE_PKG.func_ie(l_carrier_state_code,
                                                   r_invoices.carrier_ie) THEN
                --
                IF p_interface = 'N' THEN
                  --
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'IE INVALID',
                                                             r_invoices.invoice_id,
                                                             NULL);
                  --
                ELSE
                  --
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                        p_operation_id,
                                                        'IE INVALID');
                  --
                END IF;
                --
              END IF;
              --
            END IF;
          END IF; -- End BUG 26913706
          --
        END IF;
        --
        IF r_invoices.carrier_vehicle_plate_num IS NOT NULL THEN
          BEGIN
            SELECT NVL(REGEXP_INSTR(r_invoices.carrier_vehicle_plate_num,
                                    '[0-9][A-Z]'),
                       0) + NVL(REGEXP_INSTR(r_invoices.carrier_vehicle_plate_num,
                                             '[A-Z][0-9]'),
                                0)
              INTO l_check
              FROM dual;

            IF l_check = 0 THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'VEIC PLATE NUM INV',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'VEIC PLATE NUM INV');
              END IF;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
              l_check := NULL;
          END;
        END IF;
        -- Bug 20404053 - End

        -- Bug 13947775 - Start
        -- ER 13687710 - Start
        --IF r_invoices.document_type_inv IN ('NFSE') THEN --(++) Rantonio, BUG 13947775, 16/07/2012
        IF NVL(x_invoice_number_length_flag, 'N') = 'Y' THEN
          -- ER 13687710 - End
          --
          BEGIN
            SELECT NVL(cllci.invoice_number_length, 9)
              INTO v_inv_lenght
              FROM Cll_F189_Cities              cllci,
                   Cll_F189_Fiscal_Entities_All cllfe
             WHERE cllci.City_Id = cllfe.City_Id
               AND cllfe.Entity_Id = r_invoices.ENTITY_ID;
          EXCEPTION
            WHEN OTHERS THEN
              v_inv_lenght := NULL;
          END;
          --
          IF v_inv_lenght < LENGTH(TRUNC(r_invoices.invoice_num)) AND --(++) Rantonio, BUG 13947775
            -- ER 13687710 - Start
            --r_invoices.document_type_inv IN ('NFSE')THEN
             NVL(x_invoice_number_length_flag, 'N') = 'Y' AND
             --r_invoices.return_customer_flag <> 'F' THEN         -- 28329321
             r_invoices.return_customer_flag NOT IN ('F','T') THEN -- 28329321
            -- Bug 20381289
            -- ER 13687710 - End
            --
            IF p_interface = 'N' THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID NFSE INVOICENUM',
                                                         r_invoices.invoice_id,
                                                         NULL);
              --
            ELSE
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'INVALID NFSE INVOICENUM');
              --
            END IF;
            --
          END IF;
          --
        ELSE
          --
          IF length(TRUNC(r_invoices.invoice_num)) > 9 AND
           --r_invoices.return_customer_flag <> 'F' THEN           -- 28329321
             r_invoices.return_customer_flag NOT IN ('F','T') THEN -- 28329321
            --(++) Rantonio, BUG 13947775
            --
            IF p_interface = 'N' THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID INVOICENUM',
                                                         r_invoices.invoice_id,
                                                         NULL);
              --
            ELSE
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID INVOICENUM');
              --
            END IF;
            --
          END IF;
          --
        END IF;
        --
        -- Bug 13947775 - End
        --
        -- ER 20382276 - Start
        IF r_invoices.usage_authorization IS NOT NULL THEN
          --
          l_inv_usage_authorization := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES(p_lookup_type => 'CLL_F369_USAGE_AUTHORIZATION',
                                                                             p_lookup_code => to_char(r_invoices.usage_authorization));
          --
          IF l_inv_usage_authorization IS NULL THEN
            --
            IF p_interface = 'N' THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'USAGE AUTHORIZATION INVALID',
                                                         r_invoices.invoice_id,
                                                         NULL);
              --
            ELSE
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'USAGE AUTHORIZATION INVALID');
              --
            END IF;
            --
          END IF;
          --
        END IF;
        --
        IF r_invoices.dar_payment_date > r_invoices.invoice_date THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DAR PAY INV DATE',
                                                       r_invoices.invoice_id,
                                                       NULL);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                  p_operation_id,
                                                  'DAR PAY INV DATE');
            --
          END IF;
          --
        END IF;
        -- ER 20382276 - End
        --
        -- ER 20608903 - Start
        IF l_set_of_books_id_alt1 IS NOT NULL AND
           r_invoices.first_alternative_rate IS NULL THEN

          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'ALTERNATIVE SET OF BOOKS NULL',
                                                       r_invoices.invoice_id,
                                                       NULL);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                  p_operation_id,
                                                  'ALTERNATIVE SET OF BOOKS NULL');
            --
          END IF;

        ELSIF l_set_of_books_id_alt2 IS NOT NULL AND
              r_invoices.second_alternative_rate IS NULL THEN

          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'ALTERNATIVE SET OF BOOKS NULL',
                                                       r_invoices.invoice_id,
                                                       NULL);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                  p_operation_id,
                                                  'ALTERNATIVE SET OF BOOKS NULL');
            --
          END IF;

        END IF;

        IF l_set_of_books_id_alt1 IS NULL AND
           l_set_of_books_id_alt2 IS NULL THEN

          IF (r_invoices.first_alternative_rate IS NOT NULL) OR
             (r_invoices.second_alternative_rate IS NOT NULL) THEN

            IF p_interface = 'Y' THEN
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'INVALID ALTERN SET OF BOOKS');
              --
            END IF;

          END IF;

        END IF;
        -- ER 20608903 - End

        -- Bug 11773438 - GSilva - 04/04/2011 - Inicio
        --
        BEGIN
          fnd_global.APPS_INITIALIZE(v_fnd_user_id,
                                     v_fnd_resp_id,
                                     v_fnd_resp_appl_id);
        END;
        --
        v_rcv_tp_mode := fnd_profile.VALUE('RCV_TP_MODE');
        --
        IF NVL(v_rcv_tp_mode, 'XXXXXX') <> 'ONLINE' THEN
          --
          IF p_interface = 'N' THEN
            --
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'RCV MODE NOT ONLINE',
                                                       r_invoices.invoice_id,
                                                       NULL);
            --
          ELSE
            --
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                  p_operation_id,
                                                  'RCV MODE NOT ONLINE');
            --
          END IF;
          --
        END IF;
        --
        -- Bug 11773438 - GSilva - 04/04/2011 - Fim
        -- ER 9289619: Start
        --
        IF r_invoices.simplified_br_tax_flag = 'Y' THEN

          IF r_invoices.icms_type <> 'INV LINES INF' THEN
            -- ER 9028781
            --
            IF ((r_invoices.freight_flag = 'N' AND
               r_invoices.icms_type NOT IN
               ('EXEMPT', 'SUBSTITUTE', 'EARLY SUBSTITUTE', 'NOT APPLIED')) OR
               (r_invoices.freight_flag = 'Y' AND
               r_invoices.icms_type <> 'EXEMPT')) THEN
              --
              IF (p_interface = 'N') THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'ICMS TYPE NOT ALLOWED',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'ICMS TYPE NOT ALLOWED');
                --
              END IF;
              --
            END IF;
            --
          END IF; -- ER 9028781

        END IF;
        -- ER 9289619: End
        -- Bug 11874715 - GSilva - 28/3/2011 - Inicio
        IF r_invoices.payment_flag = 'Y' THEN
          --
          BEGIN
            --
            SELECT '1'
              INTO v_ap_period
              FROM GL_PERIOD_STATUSES
             WHERE APPLICATION_ID = 200
               AND v_gl_date BETWEEN START_DATE AND END_DATE
               AND SET_OF_BOOKS_ID = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
               AND CLOSING_STATUS IN ('O', 'F')
               AND (ADJUSTMENT_PERIOD_FLAG IS NULL OR
                   ADJUSTMENT_PERIOD_FLAG = 'N');
            --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --
              IF (p_interface = 'N') THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID AP_DATE',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INVALID AP_DATE');
                --
              END IF;
              --
          END;
          --
          -- 24758216 - Start
          IF l_document_type = 'CPF' AND
             r_invoices.inss_substitute_flag = 'A' THEN
            --Substitute/Expenses
            IF NVL(r_invoices.ip_inss_net_amount, 0) > l_inss_aut_max_ret THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INSS NET AMT EXCEED MAX VALUE',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INSS NET AMT EXCEED MAX VALUE');
              END IF;
            END IF;
          END IF;
          -- 24758216 - End
          --
          -- 29526046 - Start
          IF l_document_type = 'CPF' AND
             r_invoices.inss_substitute_flag = 'A' THEN
            --Substitute/Expenses
            IF NVL(r_invoices.inss_autonomous_invoiced_total, 0) >= l_inss_max_remuner_contrib AND
               NVL(r_invoices.ip_inss_net_amount, 0) > 0 THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INSS REMUNERAT EXCEED MAX VAL',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INSS REMUNERAT EXCEED MAX VAL');
              END IF;
            END IF;
          END IF;
          -- 29526046 - End
          --
          -- Bug 18799722/Bug 19646769 - Start
          IF r_invoices.inss_amount > 0 THEN

            -- Bug 20365208 - Start
            cll_f189_open_validate_pub.get_tax_sites(p_organization_id           => p_organization_id,
                                                     p_tax_type                  => 'INSS',
                                                     p_minimum_tax_amount        => l_inss_min_amount,
                                                     p_cumulative_threshold_type => l_cumulative_threshold_type,
                                                     p_error_code                => l_inss_error_code);

            IF (nvl(r_invoices.inss_amount, 0) < nvl(l_inss_min_amount, 0)) AND
               l_document_type = 'CNPJ' -- 21531757
               AND l_cumulative_threshold_type = 3 THEN
              -- Bug 21895963

              IF (p_interface = 'N') THEN

                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID INSSAMOUNT',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE

                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INVALID INSSAMOUNT');
              END IF;

            END IF;
            -- Bug 20365258 - End

            SELECT COUNT(1)
              INTO l_inss_base_date
              FROM cll_f189_tax_sites
             WHERE tax_type = 'INSS'
               AND tax_base_date_code = 'INVOICE DATE'
               AND organization_id = p_organization_id;

            IF l_inss_base_date <> 0 THEN
              BEGIN
                SELECT '1'
                  INTO l_inss_period
                  FROM cll_f189_calendar_taxes
                 WHERE tax_type = 'INSS'
                   AND TRUNC(r_invoices.invoice_date) BETWEEN
                       TRUNC(start_date) AND TRUNC(end_date)
                   AND organization_id = p_organization_id;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'INSS INV TAX BASE DATE',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                          p_operation_id,
                                                          'INSS INV TAX BASE DATE');
                  END IF;
              END;
            END IF;
          END IF;
          --

          --
          IF r_invoices.ir_amount > 0 THEN
            SELECT COUNT(1)
              INTO l_ir_base_date
              FROM cll_f189_tax_sites
             WHERE tax_type = 'IRRF'
               AND tax_base_date_code = 'INVOICE DATE'
               AND organization_id = p_organization_id;

            IF l_ir_base_date <> 0 THEN
              BEGIN
                SELECT '1'
                  INTO l_ir_period
                  FROM cll_f189_calendar_taxes
                 WHERE tax_type = 'IRRF'
                   AND TRUNC(r_invoices.invoice_date) BETWEEN
                       TRUNC(start_date) AND TRUNC(end_date)
                   AND organization_id = p_organization_id;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'IRRF INV TAX BASE DATE',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                          p_operation_id,
                                                          'IRRF INV TAX BASE DATE');
                  END IF;
              END;
            END IF;
          END IF;

          IF r_invoices.iss_amount > 0 THEN
            SELECT COUNT(1)
              INTO l_iss_base_date
              FROM cll_f189_tax_sites
             WHERE tax_type = 'ISS'
               AND tax_base_date_code = 'INVOICE DATE'
               AND organization_id = p_organization_id;

            IF l_iss_base_date <> 0 THEN
              BEGIN
                SELECT '1'
                  INTO l_iss_period
                  FROM cll_f189_calendar_taxes
                 WHERE tax_type = 'ISS'
                   AND TRUNC(r_invoices.invoice_date) BETWEEN
                       TRUNC(start_date) AND TRUNC(end_date)
                   AND organization_id = p_organization_id;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'ISS INV TAX BASE DATE',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                          p_operation_id,
                                                          'ISS INV TAX BASE DATE');
                  END IF;
              END;
            END IF;
          END IF;

          IF r_invoices.funrural_amount > 0 THEN
            SELECT COUNT(1)
              INTO l_funrural_base_date
              FROM cll_f189_tax_sites
             WHERE tax_type = 'RURAL INSS'
               AND tax_base_date_code = 'INVOICE DATE'
               AND organization_id = p_organization_id;

            IF l_funrural_base_date <> 0 THEN
              BEGIN
                SELECT '1'
                  INTO l_funrural_period
                  FROM cll_f189_calendar_taxes
                 WHERE tax_type = 'RURAL INSS'
                   AND TRUNC(r_invoices.invoice_date) BETWEEN
                       TRUNC(start_date) AND TRUNC(end_date)
                   AND organization_id = p_organization_id;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'RURAL INSS INV TAX BASE DATE',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                          p_operation_id,
                                                          'RURAL INSS INV TAX BASE DATE');
                  END IF;
              END;
            END IF;
          END IF;

          IF r_invoices.sest_senat_amount > 0 THEN
            SELECT COUNT(1)
              INTO l_sest_senat_base_date
              FROM cll_f189_tax_sites
             WHERE tax_type = 'SEST/SENAT'
               AND tax_base_date_code = 'INVOICE DATE'
               AND organization_id = p_organization_id;

            IF l_sest_senat_base_date <> 0 THEN
              BEGIN
                SELECT '1'
                  INTO l_sest_senat_period
                  FROM cll_f189_calendar_taxes
                 WHERE tax_type = 'SEST/SENAT'
                   AND TRUNC(r_invoices.invoice_date) BETWEEN
                       TRUNC(start_date) AND TRUNC(end_date)
                   AND organization_id = p_organization_id;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'SEST SENAT INV TAX BASE DATE',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                          p_operation_id,
                                                          'SEST SENAT INV TAX BASE DATE');
                  END IF;
              END;
            END IF;
          END IF;
          -- Bug 18799722/Bug 19646769 - End
          --
        END IF;
        -- Bug 11874715 - GSilva - 28/3/2011 - Fim
        --
        -- 28487689 - 28597878 - Start
      --IF r_invoices.fiscal_document_model = '57'                                               -- 29655872
        IF CLL_F189_INVOICES_UTIL_PKG.GET_FISCAL_DOC_MODEL_FRT(r_invoices.fiscal_document_model) -- 29655872
        AND NVL(r_invoices.freight_flag,'N') = 'Y' THEN

           IF ( ( r_invoices.source_city_id IS NULL )
           OR ( r_invoices.source_ibge_city_code IS NULL )
           OR ( r_invoices.source_state_id IS NULL )
           OR ( r_invoices.destination_city_id IS NULL )
           OR ( r_invoices.destination_ibge_city_code IS NULL )
           OR ( r_invoices.destination_state_id IS NULL ) ) THEN -- 28978447
         --OR ( r_invoices.ship_to_state_id IS NULL ) ) THEN     -- 28978447
              --
              IF p_interface = 'N' THEN
                 --
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                           'SHIP FROM TO IBGE REQ',
                                                           r_invoices.invoice_id,
                                                           NULL);
                 --
              ELSE
                 --
                 cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                       p_operation_id,
                                                      'SHIP FROM TO IBGE REQ');
                    --
              END IF;
              --
           END IF;

        END IF;
        -- 28487689 - 28597878 - End
        --
        -- 27463767 - Start
        IF r_invoices.source_city_id IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_source_city_exist
              FROM CLL_F189_CITIES cllci
              WHERE cllci.city_id = r_invoices.source_city_id;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY NOT FOUND',
                                                              r_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY NOT FOUND');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_invoices.source_ibge_city_code IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_source_ibge_city_exist
              FROM CLL_F189_CITIES cllci
              WHERE cllci.ibge_code = r_invoices.source_ibge_city_code;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY NOT FOUND',
                                                              r_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY NOT FOUND');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_invoices.destination_city_id IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_dest_city_exist
              FROM CLL_F189_CITIES cllci
              WHERE cllci.city_id = r_invoices.destination_city_id;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY NOT FOUND',
                                                              r_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY NOT FOUND');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_invoices.destination_ibge_city_code IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_dest_ibge_city_exist
              FROM CLL_F189_CITIES cllci
              WHERE cllci.ibge_code = r_invoices.destination_ibge_city_code;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY NOT FOUND',
                                                              r_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY NOT FOUND');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_invoices.source_city_id IS NOT NULL
        AND r_invoices.source_ibge_city_code IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_source_corresp_exist
              FROM CLL_F189_CITIES cllci
              WHERE cllci.city_id   = r_invoices.source_city_id
                AND cllci.ibge_code = r_invoices.source_ibge_city_code;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY INVALID',
                                                              r_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY INVALID');
                    --
                 END IF;

           END;

        END IF;
        --
        IF r_invoices.destination_city_id IS NOT NULL
        AND r_invoices.destination_ibge_city_code IS NOT NULL THEN

           BEGIN
              SELECT 1
                INTO l_dest_corresp_exist
              FROM CLL_F189_CITIES cllci
              WHERE cllci.city_id   = r_invoices.destination_city_id
                AND cllci.ibge_code = r_invoices.destination_ibge_city_code;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'IBGE CITY INVALID',
                                                              r_invoices.invoice_id,
                                                              NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                          p_operation_id,
                                                         'IBGE CITY INVALID');
                    --
                 END IF;

           END;

        END IF;
        --
        -- 27463767 - End
        --
        -- 27579747 - Start
        FOR r_cust_trx IN (SELECT 0 interface_invoice_id,
                                  cfrct.eletronic_invoice_key
                           FROM cll_f189_ra_cust_trx cfrct
                           WHERE cfrct.invoice_id = r_invoices.invoice_id
                             AND p_interface = 'N'
                           UNION
                           SELECT cfrct.interface_invoice_id,
                                  cfrct.eletronic_invoice_key
                           FROM cll_f189_ra_cust_trx_int cfrct
                           WHERE cfrct.interface_invoice_id = r_invoices.invoice_id
                             AND p_interface = 'Y') LOOP

           IF r_cust_trx.eletronic_invoice_key IS NOT NULL THEN
              --
              BEGIN
                 --
                 BEGIN
                    --
                    l_key_out_inv := TO_NUMBER(r_cust_trx.eletronic_invoice_key);
                    --
                 EXCEPTION
                    WHEN OTHERS THEN
                       --
                       RAISE l_err_key_out_inv;
                       --
                 END;
                 --
                 IF LENGTH(r_cust_trx.eletronic_invoice_key) <> 44 THEN
                    --
                    RAISE l_err_key_out_inv;
                    --
                 END IF;
                 --
              EXCEPTION
                 WHEN l_err_key_out_inv THEN
                    --
                    IF p_interface = 'N' THEN
                       --
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'OUTBOUND ACCESS KEY INVALID',
                                                             r_invoices.invoice_id,
                                                             NULL);
                       --
                    ELSE
                       --
                       cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                             p_operation_id,
                                                            'OUTBOUND ACCESS KEY INVALID');
                       --
                    END IF;
                    --
              END;

           END IF;


        END LOOP;
        -- 27579747 - End
        --
        -- ER: 11817687: Start
        -- ER 28156575 - Start
        IF NVL(r_invoices.fiscal_document_model,'XXX') <> 'RPA' THEN -- Para RPA com nota referenciada nao validar o CFOP
        -- ER 28156575 - End
           FOR r_cust_trx_lines IN (SELECT DISTINCT rctla.global_attribute1 cfo_code
                                   FROM cll_f189_ra_cust_trx      cfrct,
                                        ra_customer_trx_all       rcta,
                                        ra_customer_trx_lines_all rctla
                                  WHERE cfrct.invoice_id =
                                        r_invoices.invoice_id
                                    AND cfrct.customer_trx_id =
                                        rcta.customer_trx_id
                                    AND rcta.customer_trx_id =
                                        rctla.customer_trx_id
                                    AND rctla.line_type = 'LINE') LOOP
           BEGIN
            --
             SELECT outbound_type
               INTO l_outbound_type
               FROM cll_f189_fiscal_operations
              WHERE cfo_code = r_cust_trx_lines.cfo_code
                AND NVL(inactive_date, SYSDATE + 1) > SYSDATE;
            --
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               IF p_interface = 'N' THEN
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'DIV UTL OUTBOUND',
                                                            r_invoices.invoice_id,
                                                            NULL);
               ELSE
                 BEGIN
                   cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                         p_operation_id,
                                                         'DIV UTL OUTBOUND');
                 END;
               END IF;
             WHEN OTHERS THEN
               l_outbound_type := NULL;
           END;
          --
           END LOOP;
        END IF;
        -- ER 28156575 - End
        --
        BEGIN
          --
          IF p_interface = 'N' THEN
            --
            SELECT count(1)
              INTO l_ctrc_lin
              FROM cll_f189_invoice_lines    cfil,
                   cll_f189_invoices         cfi,
                   cll_f189_invoice_types    cfit,
                   cll_f189_entry_operations cfeo
             WHERE cfi.invoice_id = r_invoices.invoice_id
               AND cfi.operation_id = cfeo.operation_id
               AND cfi.organization_id = cfeo.organization_id
               AND cfeo.organization_id = p_organization_id
               AND cfeo.operation_id = p_operation_id
               AND cfil.invoice_id = cfi.invoice_id
               AND cfi.invoice_type_id = cfit.invoice_type_id
               AND cfit.organization_id = p_organization_id
               AND cfit.freight_flag = 'Y'
               AND cfeo.freight_flag <> 'F';
            --
          ELSE
            --
            SELECT count(1)
              INTO l_ctrc_lin
              FROM cll_f189_invoice_lines_iface cfili,
                   cll_f189_invoices_interface  cfii,
                   cll_f189_invoice_types       cfit
             WHERE cfii.interface_invoice_id = r_invoices.invoice_id
                  -- AND    cfili.invoice_id          = cfii.invoice_id            -- Bug 12432581
               AND cfili.interface_invoice_id = cfii.interface_invoice_id -- Bug 12432581
               AND cfit.invoice_type_id =
                   NVL(cfii.invoice_type_id, l_invoice_type_id)
               AND cfit.organization_id = p_organization_id
               AND cfit.freight_flag = 'Y'
               AND cfii.freight_flag <> 'F';
            --
          END IF;
          --
          IF l_ctrc_lin > 1 THEN
            --
            IF p_interface = 'N' THEN
              --
              -- Bug 12432581 - GGarcia - 23/05/2011 - Inicio
              begin
                SELECT count(1)
                  INTO l_ctrc_Outbound
                  FROM cll_f189_invoices cfi, cll_f189_ra_cust_trx cfra
                 WHERE cfi.invoice_id = cfra.invoice_id
                   and cfi.invoice_id = r_invoices.invoice_id;
              Exception
                When others then
                  l_ctrc_Outbound := 0;
              End;
              --
              If l_ctrc_Outbound > 0 then
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'MORE INVOICE LINE FRT',
                                                           r_invoices.invoice_id,
                                                           NULL);
              End if;
              -- Bug 12432581 - GGarcia - 23/05/2011 - Final
              --
            ELSE
              --
              -- Bug 12432581 - GGarcia - 23/05/2011 - Inicio
              begin
                SELECT count(1)
                  INTO l_ctrc_Outbound
                  from CLL_F189_RA_CUST_TRX_INT    cfra,
                       cll_f189_invoices_interface cfii
                 where cfii.interface_invoice_id =
                       cfra.interface_invoice_id
                   and cfii.interface_invoice_id = r_invoices.invoice_id;
              Exception
                When others then
                  l_ctrc_Outbound := 0;
              End;
              --
              If l_ctrc_Outbound > 0 then
                BEGIN
                  --
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                        p_operation_id,
                                                        'MORE INVOICE LINE FRT');
                  --
                END;
                --
              End if;
              -- Bug 12432581 - GGarcia - 23/05/2011 - Final
            END IF;
            --
          END IF;
          --
        EXCEPTION
          WHEN OTHERS THEN
            l_ctrc_lin := 0;
        END;
        --
        -- ER: 11817687: End
        -- ER 17551029 5a Fase - Start
        FOR r_prior_billings IN c_prior_billings(r_invoices.invoice_id) LOOP
          IF p_interface = 'N' THEN
            SELECT COUNT(*)
              INTO l_count_doc
              FROM cll_f189_prior_billings pb
             WHERE pb.invoice_id = r_prior_billings.invoice_id
               AND pb.document_number = r_prior_billings.document_number;
          ELSE
            SELECT COUNT(*)
              INTO l_count_doc
              FROM cll_f189_prior_billings_int pbi
             WHERE pbi.interface_invoice_id =
                   r_prior_billings.interface_invoice_id
               AND pbi.document_number = r_prior_billings.document_number;
          END IF;
          --
          IF l_count_doc > 1 AND l_prior_count_err = 0 THEN
            IF p_interface = 'N' THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ONLY DOCUMENT',
                                                         r_invoices.invoice_id,
                                                         NULL);
              --
            ELSE
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'ONLY DOCUMENT');
              --
            END IF;
          END IF;
          --
          IF r_prior_billings.document_type IN ('CPF', 'CNPJ') THEN
            l_doc_num          := lpad(substr(to_char(r_prior_billings.document_number),
                                              1,
                                              15),
                                       15,
                                       '0');
            l_validate_doc_num := CLL_F189_DIGIT_CALC_PKG.FUNC_DOC_VALIDATION(r_prior_billings.document_type,
                                                                              l_doc_num);
            --
            IF l_validate_doc_num = 0 THEN
              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV PRIOR BILLING DOC NUM',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INV PRIOR BILLING DOC NUM');
                --
              END IF;
            END IF;
          END IF;
          --
          -- 23153025 - Start
          IF NVL(r_prior_billings.total_remuneration_amount, 0) = 0 THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'REMUN PRIOR NOT NULL',
                                                         r_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'REMUN PRIOR NOT NULL');
            END IF;
          END IF;
          -- 23153025 - End
          --
          -- 25808200 - 25808214 - Start
          IF l_esocial_period_code <= TO_CHAR(r_invoices.invoice_date, 'YYYY-MM') THEN

             IF p_interface = 'N' THEN

                CLL_F189_INSS_TAX_PKG.GET_PRIOR_BILLING( p_organization_id
                                                       , r_invoices.entity_id
                                                       , r_invoices.invoice_id
                                                       , l_sum_prior_billings);
             ELSE

                CLL_F189_INSS_TAX_PKG.GET_PRIOR_BILLING( p_organization_id
                                                       , r_invoices.entity_id
                                                       , r_invoices.interface_invoice_id
                                                       , l_sum_prior_billings);

             END IF;

          ELSE
          -- 25808200 - 25808214 - End

             IF p_interface = 'N' THEN
                SELECT SUM(total_remuneration_amount)
                INTO l_sum_prior_billings
                FROM cll_f189_prior_billings pb
                WHERE pb.invoice_id = r_prior_billings.invoice_id;
             ELSE
                SELECT SUM(total_remuneration_amount)
                INTO l_sum_prior_billings
                FROM cll_f189_prior_billings_int pbi
                WHERE pbi.interface_invoice_id =
                   r_prior_billings.interface_invoice_id;
             END IF;

          END IF; -- 25808200 - 25808214

          --
          IF l_sum_prior_billings <>
             r_invoices.inss_autonomous_invoiced_total AND
             l_prior_count_err = 0 THEN

             IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INV INSS SERVICE SUM',
                                                         r_invoices.invoice_id,
                                                         NULL);
                --
             ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                         p_operation_id,
                                                        'INV INSS SERVICE SUM');
                --
             END IF;

          END IF;

          -- 22285738 - Start
          IF r_prior_billings.document_type IS NOT NULL AND
             r_prior_billings.document_number IS NOT NULL THEN

            IF p_interface = 'N' THEN

              l_val_doc_esocial := CLL_F189_FISCAL_UTIL_PKG.VAL_DOC_ESOCIAL(p_organization_id,
                                                                            r_prior_billings.document_type,
                                                                            r_prior_billings.document_number,
                                                                            r_invoices.invoice_id,
                                                                            'N');

            ELSE

              l_val_doc_esocial := CLL_F189_FISCAL_UTIL_PKG.VAL_DOC_ESOCIAL(p_organization_id,
                                                                            r_prior_billings.document_type,
                                                                            r_prior_billings.document_number,
                                                                            r_prior_billings.interface_invoice_id,
                                                                            'Y');

            END IF;

            IF l_val_doc_esocial = 'CNPJ_EQUAL_LE' THEN

              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DOC_EQUAL_LE',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'DOC_EQUAL_LE');
                --
              END IF;

            ELSIF l_val_doc_esocial = 'CNPJ_EQUAL_ETB' THEN

              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DOC_EQUAL_ETB',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'DOC_EQUAL_ETB');
                --
              END IF;

            ELSIF l_val_doc_esocial = 'CNPJ_EQUAL_LE_ETB' THEN

              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DOC_EQUAL_LE_ETB',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'DOC_EQUAL_LE_ETB');
                --
              END IF;

            ELSIF l_val_doc_esocial = 'CPF_EQUAL_IT' THEN

              IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DOC_EQUAL_IT',
                                                           r_invoices.invoice_id,
                                                           NULL);
                --
              ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'DOC_EQUAL_IT');
                --
              END IF;

            END IF;

          END IF;
          -- 22285738 - End

          l_prior_count_err := l_prior_count_err + 1;
        END LOOP;
        -- ER 17551029 5a Fase - End
        --

        -- 29480917 begin
        Open c_Referenced_Docs(r_invoices.invoice_id);
        Loop
           Fetch c_Referenced_Docs Into r_Referenced_Docs;
           Exit When c_Referenced_Docs%NotFound;
           --
           If r_Referenced_Docs.Referenced_Documents_Type Is Not Null Then
              --
              BEGIN
                SELECT meaning
                  INTO l_lkp_ref_doc_type
                  FROM fnd_lookup_values_vl
                 WHERE lookup_type = 'CLL_F189_REF_DOCUMENTS_TYPE'
                   AND lookup_code = r_Referenced_Docs.Referenced_Documents_Type
                   AND NVL(end_date_active, SYSDATE + 1) > SYSDATE;
              EXCEPTION
                WHEN OTHERS THEN
                  l_lkp_ref_doc_type := NULL;
              END;
              --
              IF l_lkp_ref_doc_type IS NULL THEN
                 IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'INV REF DOC TYPE',
                                                               r_Referenced_Docs.invoice_id,
                                                               NULL);
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_Referenced_Docs.invoice_id,
                                                          p_operation_id,
                                                          'INV REF DOC TYPE');
                 END IF;
              END IF;
              --
           End If;
           If r_Referenced_Docs.Source_Document_Type Is Not Null Then
              --
              BEGIN
                SELECT meaning
                  INTO l_lkp_src_doc_type
                  FROM fnd_lookup_values_vl
                 WHERE lookup_type = 'CLL_F189_SOURCE_DOCUMENTS_TYPE'
                   AND lookup_code = r_Referenced_Docs.Source_Document_Type
                   AND NVL(end_date_active, SYSDATE + 1) > SYSDATE;
              EXCEPTION
                WHEN OTHERS THEN
                  l_lkp_src_doc_type := NULL;
              END;
              --
              IF l_lkp_src_doc_type IS NULL THEN
                 IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'INV SOURCE DOC TYPE',
                                                               r_Referenced_Docs.invoice_id,
                                                               NULL);
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_Referenced_Docs.invoice_id,
                                                          p_operation_id,
                                                          'INV SOURCE DOC TYPE');
                 END IF;
              END IF;
              --
           End If;
           --
        End Loop;
        Close c_Referenced_Docs;
        -- 29480917 end


        --
        -- 28592012 - Start
        FOR r_payment_methods IN c_payment_methods(r_invoices.invoice_id) LOOP
           --
           IF r_payment_methods.payment_method_indicator IS NOT NULL THEN
              --
              l_payment_method_indicator := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES(p_lookup_type => 'CLL_F189_PAYMENT_INDICATOR',
                                                                                  p_lookup_code => to_char(r_payment_methods.payment_method_indicator));
              --
              IF l_payment_method_indicator IS NULL THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'PAYMENT INDICATOR INVALID',
                                                               r_invoices.invoice_id,
                                                               NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                          p_operation_id,
                                                         'PAYMENT INDICATOR INVALID');
                    --
                 END IF;
                --
              END IF;
             --
           END IF;
           --
           IF r_payment_methods.payment_method IS NOT NULL THEN
              --
              l_payment_method := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES(p_lookup_type => 'CLL_F189_PAYMENT_METHODS',
                                                                        p_lookup_code => to_char(r_payment_methods.payment_method));
              --
              IF l_payment_method IS NULL THEN
                 --
                 IF p_interface = 'N' THEN
                    --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                              'PAYMENT METHODS INVALID',
                                                               r_invoices.invoice_id,
                                                               NULL);
                    --
                 ELSE
                    --
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                          p_operation_id,
                                                         'PAYMENT METHODS INVALID');
                    --
                 END IF;
                --
              END IF;
             --
           END IF;
        END LOOP;
        -- 28592012 - End
        --
        -- ER 9297043 - GSilva - 02/06/2010 - Begin
        /* --(++) Rantonio, BUG 13947775 (BEGIN)
           v_length_invoice_num := length(r_invoices.invoice_num);

           IF v_length_invoice_num > 9 THEN
             IF p_interface <> 'N' THEN
               cll_f189_check_holds_pkg.incluir_erro (  r_invoices.interface_invoice_id
                                                      , p_operation_id
                                                      , 'INVALID INVOICENUM');
             END IF;
           END IF;
        */ --(++) Rantonio, BUG 13947775 (END)
        -- ER 9297043 - GSilva - 02/06/2010 - End

        -- Bug 8610403: Start ( Consistency freight amount and insurance amount between nff and lines )
        BEGIN
          --
          IF p_interface = 'N' THEN
            --
            BEGIN
              --
              SELECT SUM(nvl(freight_amount, 0)) freight_amount,
                     SUM(nvl(insurance_amount, 0)) insurance_amount,
                     SUM(nvl(other_expenses, 0)) other_expenses -- Bug 18096092
                INTO l_freight_amount,
                     l_insurance_amount -- Bug 18096092
                    ,
                     l_other_expenses
                FROM cll_f189_invoice_lines
               WHERE invoice_id = r_invoices.invoice_id;
              --
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                l_freight_amount   := 0;
                l_insurance_amount := 0;
                l_other_expenses   := 0; -- Bug 18096092
            END;
            --
            IF nvl(r_invoices.freight_amount, 0) <> l_freight_amount THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'DIFF FREIGHT AMOUNT',
                                                         r_invoices.invoice_id,
                                                         NULL);
              --
            END IF;
            --
            IF nvl(r_invoices.insurance_amount, 0) <> l_insurance_amount THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'DIFF INSURANCE AMOUNT',
                                                         r_invoices.invoice_id,
                                                         NULL);
              --
            END IF;
            --
            -- Bug 18096092 - Start
            IF nvl(r_invoices.other_expenses, 0) <> l_other_expenses THEN
              --
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'DIFF OTHER EXPENSES AMOUNT',
                                                         r_invoices.invoice_id,
                                                         NULL);
              --
            END IF;
            -- Bug 18096092 - End
            --
          ELSE
            --
            BEGIN
              --
              SELECT SUM(nvl(freight_amount, 0)) freight_amount,
                     SUM(nvl(insurance_amount, 0)) insurance_amount,
                     SUM(nvl(other_expenses, 0)) other_expenses -- Bug 18096092
                INTO l_freight_amount, l_insurance_amount, l_other_expenses -- Bug 18096092
                FROM cll_f189_invoice_lines_iface
               WHERE interface_invoice_id = r_invoices.invoice_id;
              --
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                l_freight_amount   := 0;
                l_insurance_amount := 0;
                l_other_expenses   := 0; -- Bug 18096092
            END;
            --
            IF nvl(r_invoices.freight_amount, 0) <> l_freight_amount THEN
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF FREIGHT AMOUNT');
              --
            END IF;
            --
            IF nvl(r_invoices.insurance_amount, 0) <> l_insurance_amount THEN
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF INSURANCE AMOUNT');
              --
            END IF;
            --
            -- Bug 18096092 - Start
            IF nvl(r_invoices.other_expenses, 0) <> l_other_expenses THEN
              --
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF OTHER EXPENSES AMOUNT');
              --
            END IF;
            -- Bug 18096092 - End
          END IF;
          --
        END;
        --
        -- Bug 8610403: End
        -- Bug 9532625 - SSimoes - 21/05/2010 - Inicio
        -- Buscar informacoes do fornecedor:
        -- national_state
        --
        BEGIN
          SELECT NVL(rs.national_state, 'N') -- Bug 7422494 - SSimoes - 10/06/2010
            INTO v_national_state
            FROM cll_f189_states rs, cll_f189_fiscal_entities_all rfea
           WHERE rfea.entity_id = r_invoices.entity_id
             AND rfea.state_id = rs.state_id;

        EXCEPTION
          WHEN OTHERS THEN
            v_national_state := NULL;
        END;
        -- Bug 9532625 - SSimoes - 21/05/2010 - Fim

        -- ER 14124731 - Start
        IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'N' THEN

           IF r_invoices.fiscal_document_model = '55' AND
              r_invoices.eletronic_invoice_key IS NOT NULL THEN

              l_chcte   := NULL;
              l_protcte := NULL;

           --IF l_prf_access_key_sefaz = 'Y' THEN -- 21909282 -- 23010041

              cll_f369_access_key_val_pvt.main(r_invoices.fiscal_document_model,
                                               r_invoices.eletronic_invoice_key,
                                               l_chcte,
                                               l_protnfe,
                                               l_protcte,
                                               l_retcode,
                                               l_retstatus);

              IF l_retcode = 1 THEN

                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'ERROR ACCESSKEYVAL',
                                                            r_invoices.invoice_id,
                                                            NULL);

              ELSE

                 BEGIN
                    SELECT tag
                    INTO l_usage_authorization_tag
                    FROM fnd_lookup_values_vl
                    WHERE lookup_type = 'CLL_F369_USAGE_AUTHORIZATION'
                      AND lookup_code = l_protnfe
                      AND NVL(end_date_active, SYSDATE + 1) > SYSDATE;
                 EXCEPTION
                    WHEN OTHERS THEN
                       l_usage_authorization_tag := NULL;
                 END;

                 IF NVL(l_usage_authorization_tag, 'N') = 'N' THEN

                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'UNAUTHORIZED FISCAL DOC',
                                                               r_invoices.invoice_id,
                                                               NULL);

                 END IF;

              END IF;
            --END IF; -- 21909282 -- 23010041

           END IF;

        END IF;
        -- 29055800 - Start
        IF NVL(r_invoices.fiscal_document_model,'XXX') = 'RPA'
        AND l_document_type <> 'CPF' THEN

           IF p_interface = 'N' THEN

              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INCONSISTENT MODEL VENDORTYPE',
                                                         r_invoices.invoice_id,
                                                         NULL);
           ELSE

              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'INCONSISTENT MODEL VENDORTYPE');
           END IF;

        END IF;
        -- 29055800 - End
        --
        -- 27579747 - Start
        IF l_source = 'CLL_F369 EFD LOADER SHIPPER' THEN

           IF r_invoices.fiscal_document_model NOT IN ('57','RPA') THEN

              IF (p_interface = 'N') THEN

                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'INVALID DOC MODEL',
                                                            r_invoices.invoice_id,
                                                            NULL);
              ELSE

                 cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                       p_operation_id,
                                                       'INVALID DOC MODEL');
              END IF;

           END IF;

        END IF;
        -- 27579747 - End
        --
        --
        -- 29338175 Begin
        IF r_invoices.freight_mode IS NOT NULL THEN
           BEGIN
             SELECT meaning
               INTO l_lkp_freight_mode
               FROM fnd_lookup_values_vl
              WHERE lookup_type = 'CLL_F189_FREIGHT_MODE'
                AND lookup_code = r_invoices.freight_mode
                AND NVL(end_date_active, SYSDATE + 1) > SYSDATE;
           EXCEPTION
             WHEN OTHERS THEN
               l_lkp_freight_mode := NULL;
           END;
           --
           IF l_lkp_freight_mode IS NULL THEN
              IF p_interface = 'N' THEN
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                            p_organization_id,
                                                            p_location_id,
                                                            'INV FREIGHT MODE',
                                                            r_invoices.invoice_id,
                                                            NULL);
              ELSE
                 cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                       p_operation_id,
                                                       'INV FREIGHT MODE');
              END IF;
           END IF;
        END IF;
        -- 29338175 End
        --


        IF p_freight_flag = 'F' THEN
          --
          BEGIN
            SELECT tag
              INTO l_model_tag
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_FISCAL_DOCUMENT_MODEL'
               AND lookup_code = r_invoices.fiscal_document_model
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE;
          EXCEPTION
            WHEN OTHERS THEN
              l_model_tag := '*%';
          END;

          IF l_model_tag IS NOT NULL THEN

            IF l_model_tag <> 'N' THEN
              -- Bug 23018594
              --IF l_model_tag <> 'F' THEN -- Bug 23018594

              IF (p_interface = 'N') THEN

                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID FRTELECDOCMODEL',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE

                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID FRTELECDOCMODEL');
              END IF;

            END IF;

          END IF;

        END IF;
        -- ER 14124731 - End
        --
        -- ER 8621766
        BEGIN
          SELECT '1'
            INTO v_validity_rules
            FROM fnd_lookup_values_vl
           WHERE lookup_type = 'CLL_F189_FISCAL_DOCUMENT_MODEL'
             AND lookup_code = r_invoices.fiscal_document_model
             AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'FISCAL DOCUMENT MODEL') OR
                  lookup_code IN
                  (SELECT cfvr.validity_key_1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'FISCAL DOCUMENT MODEL'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID DOCMODEL',
                                                         r_invoices.invoice_id,
                                                         NULL);

            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'INVALID DOCMODEL');
            END IF;
        END;
        --
        BEGIN
          SELECT '1'
            INTO v_validity_rules
            FROM fnd_lookup_values_vl
           WHERE lookup_type = 'CLL_F189_INVOICE_SERIES'
             AND lookup_code = r_invoices.series
             AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
             AND (NOT EXISTS
                  (SELECT 1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'INVOICE SERIES') OR
                  lookup_code IN
                  (SELECT cfvr.validity_key_1
                     FROM cll_f189_validity_rules cfvr
                    WHERE cfvr.invoice_type_id =
                          NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                      AND cfvr.validity_type = 'INVOICE SERIES'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID INVSERIES',
                                                         r_invoices.invoice_id,
                                                         NULL);

            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'INVALID INVSERIES');
            END IF;
        END;
        --
        -- ER 10037887 - Dmontesino - 04/06/2012 Start
        IF r_invoices.subseries IS NOT NULL THEN
          --
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_INVOICE_SUBSERIES'
               AND lookup_code = r_invoices.subseries
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'INVOICE SUBSERIES') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'INVOICE SUBSERIES'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID INVSUBSERIES',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INVALID INVSUBSERIES');
              END IF;
          END;
          --
        END IF;
        -- ER 10037887 - Dmontesino - 04/06/2012 End
        --
        -- ER 10037887 - Dmontesino - 04/06/2012 Start
        IF UPPER(r_invoices.icms_type) <> 'INV LINES INF' THEN
          -- ER 9028781
          BEGIN
            SELECT '1'
              INTO v_validity_rules
              FROM fnd_lookup_values_vl
             WHERE lookup_type = 'CLL_F189_ICMS_TYPE'
               AND lookup_code = r_invoices.icms_type
               AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
               AND (NOT EXISTS
                    (SELECT 1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'ICMS TYPE') OR
                    lookup_code IN
                    (SELECT cfvr.validity_key_1
                       FROM cll_f189_validity_rules cfvr
                      WHERE cfvr.invoice_type_id =
                            NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                        AND cfvr.validity_type = 'ICMS TYPE'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID ICMSTYPE',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'INVALID ICMSTYPE');
              END IF;
          END;
        END IF; -- ER 9028781
        -- ER 10037887 - Dmontesino - 04/06/2012 End
        --
        -- Bug 9943877 - SSimoes - 23/Aug/2010 - Inicio
      --IF r_invoices.requisition_type <> 'NA' THEN -- 27180211
          BEGIN
            IF p_interface = 'N' THEN
              SELECT DISTINCT ri.entity_id
                INTO v_count_entity_id
                FROM cll_f189_invoices ri
               WHERE ri.operation_id = p_operation_id
                 AND ri.organization_id = p_organization_id;
            ELSE
              SELECT DISTINCT ri.entity_id
                INTO v_count_entity_id
                FROM cll_f189_invoices_interface ri
               WHERE ri.interface_operation_id = p_operation_id
                 AND (ri.organization_id = p_organization_id OR -- BUG 19722064
                     ri.organization_code = l_org_code) -- BUG 19722064
                 AND p_interface = 'Y';
            END IF;
          EXCEPTION
            WHEN TOO_MANY_ROWS THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF INVOICE COMPANIES',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'DIFF INVOICE COMPANIES');
              END IF;
            WHEN OTHERS THEN
              NULL;
          END;
      --END IF; -- 27180211
        -- Bug 9943877 - SSimoes - 23/Aug/2010 - Fim
        --
        -- Bug 4585347 SSimoes 01/09/2005 - Start
        BEGIN
          SELECT TO_NUMBER(r_invoices.importation_number)
            INTO v_importation_number
            FROM DUAL;
        EXCEPTION
          WHEN INVALID_NUMBER THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'IMPORTATION NUMB INVALID',
                                                         NULL,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'IMPORTATION NUMB INVALID');
            END IF;
        END;
        -- Bug 4585347 SSimoes 01/09/2005 - End
        IF UPPER(r_invoices.icms_type) <> 'INV LINES INF' THEN
          -- ER 9028781
          BEGIN
            IF p_interface = 'N' THEN

              IF NVL(r_invoices.presumed_icms_tax_amount, 0) = 0 THEN
                -- ER 5089320 --
                SELECT COUNT(1)
                  INTO v_count
                  FROM cll_f189_invoices a, cll_f189_invoice_lines b
                 WHERE a.invoice_id = b.invoice_id
                   AND a.invoice_id = r_invoices.invoice_id
                   AND a.icms_type IN ('EXEMPT', 'NOT APPLIED')
                   AND b.icms_tax_code <> '2';
                --                     IF v_count > 0 -- ER 9289619
                IF v_count > 0 AND r_invoices.simplified_br_tax_flag = 'N' -- ER 9289619: Regime Simples icms_type capa pode ser EXEMPT e linha nao
                 THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'DIFF INDICAD TRIBUTARIO',
                                                             NULL,
                                                             NULL);
                END IF;
              END IF; -- ER 5089320 --

            ELSE

              IF NVL(r_invoices.presumed_icms_tax_amount, 0) = 0 THEN
                -- ER 5089320 --
                SELECT COUNT(1)
                  INTO v_count
                  FROM cll_f189_invoices_interface  a,
                       CLL_F189_INVOICE_LINES_IFACE b
                 WHERE a.interface_invoice_id = b.interface_invoice_id
                   AND a.interface_invoice_id =
                       r_invoices.interface_invoice_id
                   AND a.icms_type IN ('EXEMPT', 'NOT APPLIED')
                   AND b.icms_tax_code <> '2';
                --
                --                     IF v_count > 0 -- ER 9289619
                IF v_count > 0 AND r_invoices.simplified_br_tax_flag = 'N' -- ER 9289619: Regime Simples icms_type capa pode ser EXEMPT e linha nao
                 THEN
                  cll_f189_check_holds_pkg.incluir_erro(
                                                        -- r_invoices.invoice_id, -- Bug 4658115 AIrmer 14/10/2005
                                                        r_invoices.interface_invoice_id,
                                                        -- Bug 4658115 AIrmer 14/10/2005
                                                        p_operation_id,
                                                        'DIFF INDICAD TRIBUTARIO');
                END IF;
              END IF; -- ER 5089320 --

            END IF;
          END;
        END IF; -- ER 9028781
        --
        ----------------------------------------------------------------------------
        -- Check CNPJ SELLER - SPED FISCAL - BEGIN --
        ----------------------------------------------------------------------------
        IF r_invoices.vehicle_seller_doc_number IS NOT NULL THEN
          BEGIN
            --
            x_vehicle_seller_doc_number := lpad(substr(to_char(r_invoices.vehicle_seller_doc_number),
                                                       1,
                                                       15),
                                                15,
                                                '0');
            x_result_vehicle_seller     := CLL_F189_DIGIT_CALC_PKG.FUNC_DOC_VALIDATION('CNPJ',
                                                                                       x_vehicle_seller_doc_number);
            --
            IF x_result_vehicle_seller = 0 THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV VEHICLE SEL DOC NUM',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE

                cll_f189_check_holds_pkg.incluir_erro(p_interface_invoice_id,
                                                      p_operation_id,
                                                      'INV VEHICLE SEL DOC NUM');
              END IF;
            END IF;
          END;
        END IF;
        --
        ----------------------------------------------------------------------------
        -- Check CNPJ SELLER - SPED FISCAL - END --
        ----------------------------------------------------------------------------
        --
	    -- Bug 30056823 - Start
	    --
	    IF r_invoices.return_customer_flag = 'T'
              AND p_interface = 'N' -- Enh 29907995
               THEN
		  --
	      BEGIN
	         --
             SELECT COUNT(*)
               INTO l_valid_pkg
               FROM user_objects
              WHERE object_name = 'CLL_F513_TPA_DEV_PROCESS_PKG'
                AND status      <> 'VALID' ;
	         --
	      EXCEPTION
	        WHEN OTHERS THEN
	          l_valid_pkg := NULL ;
	      END ;
	      --
	      IF NVL(l_valid_pkg, 0) > 0 THEN
	        --
            incluir_erro_hold ( p_operation_id    => p_operation_id
                              , p_organization_id => p_organization_id
                              , p_location_id     => p_location_id
                              , p_hold_code       => 'PROCEDURE INVALID'
                              , p_invoice_id      => r_invoices.invoice_id
                              , p_invoice_line_id => NULL
                              ) ;
	        --
	      END IF ;
	      --
		  BEGIN
		    --
			SELECT COUNT(*)
			  INTO l_exist_cfop_err
			  FROM cll_f189_invoice_lines     ril
                 , cll_f189_fiscal_operations rfo
			 WHERE ril.cfo_id                     = rfo.cfo_id
			   AND ril.invoice_id                 = r_invoices.invoice_id
               AND NVL(rfo.tpa_control_type, 'x') <> 'DEVOLUTION_OF' ;
			--
		  EXCEPTION
		    WHEN OTHERS THEN
			  l_exist_cfop_err := NULL ;
		  END ;
		  --
		  IF NVL(l_exist_cfop_err, 0) > 0 THEN
		    --
            incluir_erro_hold ( p_operation_id    => p_operation_id
                              , p_organization_id => p_organization_id
                              , p_location_id     => p_location_id
                              , p_hold_code       => 'INV CFO THIRD PARTY ASSOC'
                              , p_invoice_id      => r_invoices.invoice_id
                              , p_invoice_line_id => NULL
                              ) ;
			--
		  END IF ;
		  --
		  BEGIN
		    --
			SELECT COUNT(*)
			  INTO l_devol_qtde
              FROM ( SELECT cfil.invoice_line_id,SUM(cftd.devolution_quantity) devolution_quantity
                          , SUM(cfil.quantity)            quantity
                       FROM cll_f189_invoice_lines        cfil
                          , cll_f513_tpa_devolutions_ctrl cftd
                      WHERE cftd.devolution_invoice_id      (+) = cfil.invoice_id
                        AND cftd.devolution_invoice_line_id (+) = cfil.invoice_line_id
                        AND cfil.invoice_id                     = r_invoices.invoice_id
                      GROUP BY cfil.invoice_line_id )
             WHERE NVL(devolution_quantity, 0) = 0 ;
		    --
          EXCEPTION
            WHEN OTHERS THEN
              l_devol_qtde := NULL ;
	      END ;
	      --
		  IF NVL(l_devol_qtde, 0) > 0 THEN
		    --
            incluir_erro_hold ( p_operation_id    => p_operation_id
                              , p_organization_id => p_organization_id
                              , p_location_id     => p_location_id
                              , p_hold_code       => 'NO INVOICES DEVOLUTION'
                              , p_invoice_id      => r_invoices.invoice_id
                              , p_invoice_line_id => NULL
                              ) ;
			--
		  ELSE
		    --
		    -- Bug 30056823 v2 - Start
 		    --
            FOR r_lines IN ( SELECT cfil.invoice_line_id
                                  , cfil.quantity
                               FROM cll_f189_invoice_lines cfil
                              WHERE cfil.invoice_id = r_invoices.invoice_id ) LOOP
              --
	          BEGIN
	            --
	     	    SELECT SUM(cftd.devolution_quantity)
	     	      INTO l_devol_qtde
                  FROM cll_f513_tpa_devolutions_ctrl cftd
				 WHERE cftd.devolution_invoice_line_id = r_lines.invoice_line_id ;
	            --
              EXCEPTION
                WHEN OTHERS THEN
                  l_devol_qtde := NULL ;
	          END ;
              --
			  IF NVL(l_devol_qtde, 0) <> NVL(r_lines.quantity, 0) THEN
                --
                incluir_erro_hold ( p_operation_id    => p_operation_id
                                  , p_organization_id => p_organization_id
                                  , p_location_id     => p_location_id
                                  , p_hold_code       => 'DIVERGENT QUANTITY RETURNED'
                                  , p_invoice_id      => r_invoices.invoice_id
                                  , p_invoice_line_id => NULL
                                  ) ;
	     	    --
				EXIT ;
				--
	          END IF ;
			  --
            END LOOP ;
			--
			-- Bug 30056823 v2 - End
			--
		  END IF ;
          --
          v_nSource_acct_period_id := NULL ;
          v_dgl_date               := NULL ;
          v_vSource_period_status  := NULL ;
          --
          BEGIN
			--
            SELECT oap.acct_period_id
                 , ceo.gl_date
                 , UPPER(oap.status) status
              INTO v_nSource_acct_period_id
                 , v_dgl_date
                 , v_vSource_period_status
              FROM cll_f189_entry_operations ceo
			     , org_acct_periods_v        oap
             WHERE ceo.operation_id          = p_operation_id
               AND ceo.organization_id       = p_organization_id
               AND oap.rec_type              = 'ORG_PERIOD'
               AND ceo.gl_date         BETWEEN oap.start_date AND oap.end_date
               AND ceo.organization_id       = oap.organization_id ;
			--
          EXCEPTION
            WHEN OTHERS THEN
              v_nSource_acct_period_id := NULL ;
              v_dgl_date               := NULL ;
              v_vSource_period_status  := NULL ;
          END ;
          --
          IF NVL(v_vSource_period_status, 'x') NOT IN ('ABERTO', 'OPEN', 'ABIERTO') THEN
		    --
            incluir_erro_hold ( p_operation_id    => p_operation_id
                              , p_organization_id => p_organization_id
                              , p_location_id     => p_location_id
                              , p_hold_code       => 'NO OPEN PERIOD FOUND ORGANIZAT'
                              , p_invoice_id      => r_invoices.invoice_id
                              , p_invoice_line_id => NULL
                              ) ;
			--
          END IF ;
          --
		END IF ;
	    --
	    -- Bug 30056823 - End
		--
        -- ER 14743184 - Start
        -- Invoice Lines
        FOR r_invoice_lines IN c_invoice_lines LOOP
          IF r_invoices.vehicle_seller_doc_number IS NULL AND
             r_invoice_lines.vehicle_oper_type = '1' THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'VEHICLE CNPJ REQUIRED',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);

            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'VEHICLE CNPJ REQUIRED',
                                                    r_invoice_lines.interface_invoice_line_id);

            END IF;
          END IF;
          --
          IF r_invoices.vehicle_seller_state_id IS NULL AND
             r_invoice_lines.vehicle_oper_type = '1' THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'VEHICLE UF REQUIRED',
                                                         r_invoice_lines.invoice_id,
                                                         r_invoice_lines.invoice_line_id);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                    p_operation_id,
                                                    'VEHICLE UF REQUIRED',
                                                    r_invoice_lines.interface_invoice_line_id);
            END IF;
          END IF;
          --
        END LOOP;
        -- ER 14743184 - End
        --
        x_validate_flag := NVL(fnd_profile.VALUE('CLL_F189_INVOICE_NUMBER_VALIDATE'),
                               'N');
        --
        BEGIN
          IF p_interface = 'N' THEN
            IF x_validate_flag = 'Y' THEN
              BEGIN
                SELECT COUNT(*)
                  INTO x_qtd_freight_invoices
                  FROM cll_f189_freight_invoices rfi
                 WHERE rfi.entity_id =
                       NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                   AND rfi.series = r_invoices.series
                   AND rfi.invoice_num = r_invoices.invoice_num
                   AND TRUNC(rfi.invoice_date) =
                       TRUNC(r_invoices.invoice_date);
              EXCEPTION
                WHEN OTHERS THEN
                  x_qtd_freight_invoices := 0;
              END;
              --
              IF NVL(x_qtd_freight_invoices, 0) = 1 THEN
                BEGIN
                  SELECT invoice_id
                    INTO x_invoice_id_selec
                    FROM cll_f189_freight_invoices rfi
                   WHERE rfi.entity_id =
                         NVL(r_invoices.invoice_type_id, l_invoice_type_id) -- BUG 19722064
                     AND rfi.series = r_invoices.series
                     AND rfi.invoice_num = r_invoices.invoice_num
                     AND TRUNC(rfi.invoice_date) =
                         TRUNC(r_invoices.invoice_date);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    x_invoice_id_selec := NULL;
                  WHEN OTHERS THEN
                    x_invoice_id_selec := NULL;
                END;
                --
                IF NVL(x_invoice_id_selec, 0) =
                   NVL(r_invoices.invoice_id, 0) THEN
                  x_qtd_freight_invoices := 0;
                END IF;
              END IF;
              --
              BEGIN
                SELECT COUNT(*)
                  INTO x_qtd_invoices
                  FROM cll_f189_invoices ri
                 WHERE ri.entity_id = r_invoices.entity_id
                   AND ri.series = r_invoices.series
                   AND ri.invoice_num = r_invoices.invoice_num
                   AND TRUNC(ri.invoice_date) =
                       TRUNC(r_invoices.invoice_date);
              EXCEPTION
                WHEN OTHERS THEN
                  x_qtd_invoices := 0;
              END;
              --
              IF NVL(x_qtd_invoices, 0) = 1 THEN
                BEGIN
                  SELECT invoice_id
                    INTO x_invoice_id_selec
                    FROM cll_f189_invoices ri
                   WHERE ri.entity_id = r_invoices.entity_id
                     AND ri.series = r_invoices.series
                     AND ri.invoice_num = r_invoices.invoice_num
                     AND TRUNC(ri.invoice_date) =
                         TRUNC(r_invoices.invoice_date);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    x_invoice_id_selec := NULL;
                  WHEN OTHERS THEN
                    x_invoice_id_selec := NULL;
                END;
                --
                IF NVL(x_invoice_id_selec, 0) =
                   NVL(r_invoices.invoice_id, 0) THEN
                  x_qtd_invoices := 0;
                END IF;
              END IF;
              --
              IF ((x_qtd_invoices + x_qtd_freight_invoices) > 0) THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DUPLICATED INVOICE',
                                                           NULL,
                                                           NULL);
              END IF;
            ELSE
              BEGIN
                SELECT COUNT(*)
                  INTO x_qtd_freight_invoices
                  FROM cll_f189_freight_invoices rfi
                 WHERE rfi.entity_id = r_invoices.entity_id
                   AND rfi.series = r_invoices.series
                   AND rfi.invoice_num = r_invoices.invoice_num;
              EXCEPTION
                WHEN OTHERS THEN
                  x_qtd_freight_invoices := 0;
              END;
              --
              IF NVL(x_qtd_freight_invoices, 0) = 1 THEN
                BEGIN
                  SELECT invoice_id
                    INTO x_invoice_id_selec
                    FROM cll_f189_freight_invoices rfi
                   WHERE rfi.entity_id = r_invoices.entity_id
                     AND rfi.series = r_invoices.series
                     AND rfi.invoice_num = r_invoices.invoice_num;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    x_invoice_id_selec := NULL;
                  WHEN OTHERS THEN
                    x_invoice_id_selec := NULL;
                END;
                --
                IF NVL(x_invoice_id_selec, 0) =
                   NVL(r_invoices.invoice_id, 0) THEN
                  x_qtd_freight_invoices := 0;
                END IF;
              END IF;
              --
              BEGIN
                SELECT COUNT(*)
                  INTO x_qtd_invoices
                  FROM cll_f189_invoices ri
                 WHERE ri.entity_id = r_invoices.entity_id
                   AND ri.series = r_invoices.series
                   AND ri.invoice_num = r_invoices.invoice_num;
              EXCEPTION
                WHEN OTHERS THEN
                  x_qtd_invoices := 0;
              END;
              --
              IF NVL(x_qtd_invoices, 0) = 1 THEN
                BEGIN
                  SELECT invoice_id
                    INTO x_invoice_id_selec
                    FROM cll_f189_invoices ri
                   WHERE ri.entity_id = r_invoices.entity_id
                     AND ri.series = r_invoices.series
                     AND ri.invoice_num = r_invoices.invoice_num;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    x_invoice_id_selec := NULL;
                  WHEN OTHERS THEN
                    x_invoice_id_selec := NULL;
                END;
                --
                IF NVL(x_invoice_id_selec, 0) =
                   NVL(r_invoices.invoice_id, 0) THEN
                  x_qtd_invoices := 0;
                END IF;
              END IF;
              --
              IF ((x_qtd_invoices + x_qtd_freight_invoices) > 0) THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DUPLICATED INVOICE',
                                                           NULL,
                                                           NULL);
              END IF;
            END IF;
          ELSE
            IF x_validate_flag = 'Y' THEN
              BEGIN
                SELECT COUNT(*)
                  INTO x_qtd_freight_invoices
                  FROM cll_f189_freight_inv_interface rfi
                 WHERE rfi.entity_id = r_invoices.entity_id
                   AND rfi.series = r_invoices.series
                   AND rfi.invoice_num = r_invoices.invoice_num
                   AND TRUNC(rfi.invoice_date) =
                       TRUNC(r_invoices.invoice_date);
              EXCEPTION
                WHEN OTHERS THEN
                  x_qtd_freight_invoices := 0;
              END;
              --
              IF NVL(x_qtd_freight_invoices, 0) = 1 THEN
                BEGIN
                  SELECT interface_invoice_id
                    INTO x_invoice_id_selec
                    FROM cll_f189_freight_inv_interface rfi
                   WHERE rfi.entity_id = r_invoices.entity_id
                     AND rfi.series = r_invoices.series
                     AND rfi.invoice_num = r_invoices.invoice_num
                     AND TRUNC(rfi.invoice_date) =
                         TRUNC(r_invoices.invoice_date);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    x_invoice_id_selec := NULL;
                  WHEN OTHERS THEN
                    x_invoice_id_selec := NULL;
                END;
                --
                IF NVL(x_invoice_id_selec, 0) =
                   NVL(r_invoices.invoice_id, 0) THEN
                  x_qtd_freight_invoices := 0;
                END IF;
              END IF;
              --
              BEGIN
                SELECT COUNT(*)
                  INTO x_qtd_invoices
                  FROM cll_f189_invoices_interface ri
                 WHERE ri.entity_id = r_invoices.entity_id
                   AND ri.series = r_invoices.series
                   AND ri.invoice_num = r_invoices.invoice_num
                   AND TRUNC(ri.invoice_date) =
                       TRUNC(r_invoices.invoice_date);
              EXCEPTION
                WHEN OTHERS THEN
                  x_qtd_invoices := 0;
              END;
              --
              IF NVL(x_qtd_invoices, 0) = 1 THEN
                BEGIN
                  SELECT interface_invoice_id
                  --invoice_id  -- AIrmer 09/03/2003
                    INTO x_invoice_id_selec
                    FROM cll_f189_invoices_interface ri
                   WHERE ri.entity_id = r_invoices.entity_id
                     AND ri.series = r_invoices.series
                     AND ri.invoice_num = r_invoices.invoice_num
                     AND TRUNC(ri.invoice_date) =
                         TRUNC(r_invoices.invoice_date);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    x_invoice_id_selec := NULL;
                  WHEN OTHERS THEN
                    x_invoice_id_selec := NULL;
                END;
                --
                IF NVL(x_invoice_id_selec, 0) =
                   NVL(r_invoices.invoice_id, 0) THEN
                  x_qtd_invoices := 0;
                END IF;
              END IF;
              --
              IF ((x_qtd_invoices + x_qtd_freight_invoices) > 0) THEN
                cll_f189_check_holds_pkg.incluir_erro( --NULL,  -- Bug 5029863 AIRmer 21/02/2006
                                                      r_invoices.interface_invoice_id,
                                                      -- Bug 5029863 AIRmer 21/02/2006
                                                      p_operation_id,
                                                      'DUPLICATED INVOICE');
              END IF;
            ELSE
              BEGIN
                SELECT COUNT(*)
                  INTO x_qtd_freight_invoices
                  FROM cll_f189_freight_inv_interface rfi
                 WHERE rfi.entity_id = r_invoices.entity_id
                   AND rfi.series = r_invoices.series
                   AND rfi.invoice_num = r_invoices.invoice_num;
              EXCEPTION
                WHEN OTHERS THEN
                  x_qtd_freight_invoices := 0;
              END;
              --
              IF NVL(x_qtd_freight_invoices, 0) = 1 THEN
                BEGIN
                  SELECT interface_invoice_id
                    INTO x_invoice_id_selec
                    FROM cll_f189_freight_inv_interface rfi
                   WHERE rfi.entity_id = r_invoices.entity_id
                     AND rfi.series = r_invoices.series
                     AND rfi.invoice_num = r_invoices.invoice_num;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    x_invoice_id_selec := NULL;
                  WHEN OTHERS THEN
                    x_invoice_id_selec := NULL;
                END;
                --
                IF NVL(x_invoice_id_selec, 0) =
                   NVL(r_invoices.invoice_id, 0) THEN
                  x_qtd_freight_invoices := 0;
                END IF;
              END IF;
              --
              BEGIN
                SELECT COUNT(*)
                  INTO x_qtd_invoices
                  FROM cll_f189_invoices_interface ri
                 WHERE ri.entity_id = r_invoices.entity_id
                   AND ri.series = r_invoices.series
                   AND ri.invoice_num = r_invoices.invoice_num;
              EXCEPTION
                WHEN OTHERS THEN
                  x_qtd_invoices := 0;
              END;
              --
              IF NVL(x_qtd_invoices, 0) = 1 THEN
                BEGIN
                  SELECT interface_invoice_id
                  --invoice_id --AIrmer 09/03/2006
                    INTO x_invoice_id_selec
                    FROM cll_f189_invoices_interface ri
                   WHERE ri.entity_id = r_invoices.entity_id
                     AND ri.series = r_invoices.series
                     AND ri.invoice_num = r_invoices.invoice_num;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    x_invoice_id_selec := NULL;
                  WHEN OTHERS THEN
                    x_invoice_id_selec := NULL;
                END;
                --
                IF NVL(x_invoice_id_selec, 0) =
                   NVL(r_invoices.invoice_id, 0) THEN
                  x_qtd_invoices := 0;
                END IF;
              END IF;
              --
              IF ((x_qtd_invoices + x_qtd_freight_invoices) > 0) THEN
                cll_f189_check_holds_pkg.incluir_erro( --NULL,  -- Bug 5029863 AIRmer 21/02/2006
                                                      r_invoices.interface_invoice_id,
                                                      -- Bug 5029863 AIRmer 21/02/2006
                                                      p_operation_id,
                                                      'DUPLICATED INVOICE');
              END IF;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        --
        /* -- Bug 18043475 - Start

        -- Bug 17301893 - Start
         BEGIN
            SELECT cfea.document_number
            INTO l_dsp_document_number
            FROM   cll_f189_fiscal_entities_all cfea
            WHERE cfea.entity_id = r_invoices.entity_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_dsp_document_number := NULL;
         END;
         IF CLL_F189_INVOICES_UTIL_PKG.get_duplicated_invoices( x_validate_flag
                                                              , l_dsp_document_number
                                                              , r_invoices.invoice_num
                                                              , r_invoices.series
                                                              , r_invoices.invoice_date) THEN

            IF p_interface = 'Y' THEN -- Only Open Interface

               cll_f189_check_holds_pkg.incluir_erro
                                (r_invoices.interface_invoice_id,
                                 p_operation_id,
                                 'DUPLICATED INVOICE'
                                 );
            END IF;
         END IF;
         -- Bug 17301893 - End

         */ -- Bug 18043475 - End
        --
        -- Bug 9600580 - SSimoes - 08/06/2010 - Inicio
        IF r_invoices.fixed_assets_flag = 'S' AND v_book_type_code IS NULL THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'NULL ASSETS BOOK TYPE',
                                                       r_invoices.invoice_id,
                                                       NULL);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                  p_operation_id,
                                                  'NULL ASSETS BOOK TYPE');
          END IF;
        END IF;
        -- Bug 9600580 - SSimoes - 08/06/2010 - Fim
        IF (r_invoices.fixed_assets_flag = 'S') THEN
          x_fixed_assets_profile := fnd_profile.VALUE('CLL_F189_FIXED_ASSETS_INPUT');
          IF (x_fixed_assets_profile = 'Y') THEN
            FOR x_invoice_lines IN (SELECT ril.invoice_line_id, ril.quantity
                                      FROM cll_f189_invoice_lines ril
                                     WHERE ril.invoice_id =
                                           r_invoices.invoice_id) LOOP
              SELECT COUNT(1)
                INTO x_count_lines_fa
                FROM cll_f189_fixed_assets rfa
               WHERE rfa.invoice_line_id = x_invoice_lines.invoice_line_id;
              IF (x_count_lines_fa <> TRUNC(x_invoice_lines.quantity)) THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'DIV FIXED ASSETS INV',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'DIV FIXED ASSETS INV');
                END IF;
              END IF;
            END LOOP;
          END IF;
        ELSIF (r_invoices.fixed_assets_flag = 'O') THEN
          x_fixed_assets_profile := fnd_profile.VALUE('CLL_F189_FIXED_ASSETS_INPUT');
          IF (x_fixed_assets_profile = 'Y') THEN
            FOR x_invoice_lines IN (SELECT ril.invoice_line_id,
                                           ril.utilization_id
                                      FROM cll_f189_invoice_lines ril
                                     WHERE ril.invoice_id =
                                           r_invoices.invoice_id) LOOP
              --
              SELECT COUNT(1)
                INTO x_count_lines_fa
                FROM cll_f189_fixed_assets rfa
               WHERE rfa.invoice_line_id = x_invoice_lines.invoice_line_id;
              IF x_count_lines_fa = 0 THEN
                SELECT fixed_assets_flag
                  INTO x_utilization_asset_flag
                  FROM cll_f189_item_utilizations riu
                 WHERE x_invoice_lines.utilization_id = riu.utilization_id;
                IF NVL(x_utilization_asset_flag, 'N') = 'Y' THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'NONE FIXED ASSETS',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    -- Bug.4063693
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id
                                                          -- Bug.4063693
                                                         ,
                                                          p_operation_id -- Bug.4063693
                                                         ,
                                                          'NONE FIXED ASSETS'); -- Bug.4063693
                  END IF;
                END IF;
              END IF;
              --
            END LOOP;
          END IF;
        END IF;
        --
        IF r_invoices.return_customer_flag = 'F' AND
           r_invoices.generate_return_invoice = 'Y' THEN
          -- (0004)
          BEGIN
            --IF r_invoices.ret_cust_acct_site_id IS NULL -- AIrmer 26/08/2008
            IF r_invoices.cust_acct_site_id IS NULL THEN
              -- AIrmer 26/08/2008
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NO REL ENTITY CUSTOMER',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NO REL ENTITY CUSTOMER');
              END IF;
            ELSE
              SELECT COUNT('1')
                INTO v_count
                FROM hz_cust_acct_sites_all
               WHERE cust_acct_site_id = r_invoices.cust_acct_site_id; --r_invoices.ret_cust_acct_site_id; -- AIrmer 26/05/2008
              --
              IF v_count = 0 THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE AR CUSTOMER',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE AR CUSTOMER');
                END IF;
              END IF;
            END IF;
          END;
          ------------------------------------------------------------------------------------------
          -- << Bug 16269265 - Egini - 01/02/2013 - inicio
          -- Verificar se as informacoes referente a Devolucao do AR possuem mais de 450 Caracteres
          ------------------------------------------------------------------------------------------
          BEGIN
            cll_f189_interface_pkg.count_insert_desc_ar(p_invoice_id => r_invoices.invoice_id,
                                                        p_count      => x_count_ar,
                                                        p_desc       => x_desc_ar);
            x_char_count := x_count_ar;
            BEGIN
              IF x_char_count > 450 THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'CHARACTER EXCEED LIMIT',
                                                           r_invoices.invoice_id,
                                                           NULL);
              END IF;
            END;
          END;
          --  <<------------------------------------------------->>
          --  << Bug 16269265 - Egini - 20/09/2012 - Fim         >>
          --  <<------------------------------------------------->>
        END IF;
        /*BUG 16269265 - 01/02/2013 - Egini - Inicio
        ------------------------------------------------------------------------------------------
        -- << Bug 14642712 - Egini - 20/09/2012 - inicio
        -- Verificar se as informacoes referente a Devolucao do AR possuem mais de 450 Caracteres
        ------------------------------------------------------------------------------------------
        BEGIN
           cll_f189_interface_pkg.count_insert_desc_ar(p_invoice_id => r_invoices.invoice_id
                                                     , p_count      => x_count_ar
                                                     , p_desc       => x_desc_ar);

           x_char_count := x_count_ar;
           BEGIN
              IF x_char_count > 450 THEN
                 cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id
                                                          , p_organization_id
                                                          , p_location_id
                                                          , 'CHARACTER EXCEED LIMIT'
                                                          , r_invoices.invoice_id
                                                          , NULL);
              END IF;
           END;
        END;
        --  <<------------------------------------------------->>
        --  << Bug 14642712 - Egini - 20/09/2012 - Fim         >>
        --  <<------------------------------------------------->>
         */ --BUG 16269265 - 01/02/2013 - Egini - Fim
        IF r_invoices.cost_adjust_flag = 'Y' THEN
          BEGIN
            SELECT COUNT(1)
              INTO x_tipo_nota_custo
              FROM cll_f189_invoices        ri,
                   cll_f189_invoice_parents rip,
                   cll_f189_invoice_types   rit
             WHERE rip.invoice_id = r_invoices.invoice_id
               AND ri.invoice_id = rip.invoice_parent_id
               AND rit.invoice_type_id = ri.invoice_type_id
               AND rit.requisition_type <> 'PO';
          EXCEPTION
            WHEN OTHERS THEN
              raise_application_error(-20700,
                                      SQLERRM || '********************' ||
                                      ' Invoices cost adjust ' ||
                                      '********************');
          END;
          --
          IF (x_tipo_nota_custo > 0) THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'DIV REQ COST',
                                                         r_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIV REQ COST');
            END IF;
          END IF;
        END IF;
        -- PA
        cprojectflag := r_invoices.project_flag;
        --
        IF r_invoices.requisition_type IN ('PO', 'OE') THEN
          IF p_interface = 'N' THEN
            BEGIN
              SELECT COUNT(1)
                INTO ncountprojects
                FROM cll_f189_invoices      ri,
                     cll_f189_invoice_lines ril,
                     po_distributions_all   pda
               WHERE ri.invoice_id = r_invoices.invoice_id
                 AND ril.invoice_id = ri.invoice_id
                 AND pda.line_location_id = ril.line_location_id
                 AND pda.project_id IS NOT NULL;
              -- Bug 5668044 AIrmer 04/12/2006
              SELECT COUNT(1)
                INTO ncountlin
                FROM cll_f189_invoices ri, cll_f189_invoice_lines ril
               WHERE ri.invoice_id = r_invoices.invoice_id
                 AND ril.invoice_id = ri.invoice_id;
              -- Bug 5887300 SSimoes 01/03/2007 - Start
              SELECT COUNT(1)
                INTO ncountnoprojects
                FROM cll_f189_invoices      ri,
                     cll_f189_invoice_lines ril,
                     po_distributions_all   pda
               WHERE ri.invoice_id = r_invoices.invoice_id
                 AND ril.invoice_id = ri.invoice_id
                 AND pda.line_location_id = ril.line_location_id
                 AND pda.project_id IS NULL;
              -- Bug 5887300 SSimoes 01/03/2007 - End
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20607,
                                        SQLERRM || '*******************' ||
                                        ' PA not found ' ||
                                        '*******************');
            END;
          ELSE
            BEGIN
              SELECT COUNT(1)
                INTO ncountprojects
                FROM cll_f189_invoices_interface  ri,
                     cll_f189_invoice_lines_iface ril,
                     po_distributions_all         pda
               WHERE ri.interface_invoice_id =
                     r_invoices.interface_invoice_id
                 AND ril.interface_invoice_id = ri.interface_invoice_id
                 AND pda.line_location_id = ril.line_location_id
                 AND pda.project_id IS NOT NULL;
              -- Bug 5668044 AIrmer 04/12/2006
              SELECT COUNT(1)
                INTO ncountlin
                FROM cll_f189_invoices_interface  ri,
                     CLL_F189_INVOICE_LINES_IFACE ril
               WHERE ri.interface_invoice_id =
                     r_invoices.interface_invoice_id
                 AND ril.interface_invoice_id = ri.interface_invoice_id;
              -- Bug 5887300 SSimoes 01/03/2007 - Start
              SELECT COUNT(1)
                INTO ncountnoprojects
                FROM cll_f189_invoices_interface  ri,
                     cll_f189_invoice_lines_iface ril,
                     po_distributions_all         pda
               WHERE ri.interface_invoice_id =
                     r_invoices.interface_invoice_id
                 AND ril.interface_invoice_id = ri.interface_invoice_id
                 AND pda.line_location_id = ril.line_location_id
                 AND pda.project_id IS NULL;
              -- Bug 5887300 SSimoes 01/03/2007 - End
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20607,
                                        SQLERRM || '*******************' ||
                                        ' PA not found (interface)' ||
                                        '*******************');
            END;
          END IF;
          --
          IF -- cprojectflag = 'N' AND  -- ER 8614153
           NVL(ncountprojects, 0) > 0 THEN
            /* -- ER 8614153
               cprojecterror := 'INF PROJ INVALID';
               -- Bug 5905664 SSimoes 06/03/2007
               braiseprojects := TRUE;
            ELSIF cprojectflag IN ('S','B') -- ER 6788945 AIrmer 15/02/2008
                  AND NVL (ncountprojects, 0) = 0
            THEN
               cprojecterror := 'INF PROJ INVALID';
               -- Bug 5905664 SSimoes 06/03/2007
               braiseprojects := TRUE;
            -- Bug 5668044 AIrmer 04/12/2006
            */
            -- ER 8614153
            IF (p_interface = 'N') THEN
              SELECT COUNT(*)
                INTO ncountdistrinv
                FROM cll_f189_invoices      ri,
                     cll_f189_invoice_lines ril,
                     po_distributions_all   pda
               WHERE ri.invoice_id = r_invoices.invoice_id
                 AND ril.invoice_id = ri.invoice_id
                 AND pda.line_location_id = ril.line_location_id
                 AND (pda.destination_type_code IN
                     ('INVENTORY', 'SHOP FLOOR') OR
                     (pda.destination_type_code = 'EXPENSE' AND
                     pda.project_id IS NULL));
              SELECT COUNT(*)
                INTO ncountdistrexp
                FROM cll_f189_invoices      ri,
                     cll_f189_invoice_lines ril,
                     po_distributions_all   pda
               WHERE ri.invoice_id = r_invoices.invoice_id
                 AND ril.invoice_id = ri.invoice_id
                 AND pda.line_location_id = ril.line_location_id
                 AND pda.destination_type_code = 'EXPENSE'
                 AND pda.project_id IS NOT NULL;
            ELSE
              -- p_interface = Y
              SELECT COUNT(*)
                INTO ncountdistrinv
                FROM cll_f189_invoices_interface  ri,
                     cll_f189_invoice_lines_iface ril,
                     po_distributions_all         pda
               WHERE ri.interface_invoice_id =
                     r_invoices.interface_invoice_id
                 AND ril.interface_invoice_id = ri.interface_invoice_id
                 AND pda.line_location_id = ril.line_location_id
                 AND (pda.destination_type_code IN
                     ('INVENTORY', 'SHOP FLOOR') OR
                     (pda.destination_type_code = 'EXPENSE' AND
                     pda.project_id IS NULL));
              SELECT COUNT(*)
                INTO ncountdistrexp
                FROM cll_f189_invoices_interface  ri,
                     cll_f189_invoice_lines_iface ril,
                     po_distributions_all         pda
               WHERE ri.interface_invoice_id =
                     r_invoices.interface_invoice_id
                 AND ril.interface_invoice_id = ri.interface_invoice_id
                 AND pda.line_location_id = ril.line_location_id
                 AND pda.destination_type_code = 'EXPENSE'
                 AND pda.project_id IS NOT NULL;
            END IF;
            --
            IF (ncountdistrinv > 0) AND (ncountdistrexp > 0) AND
               (cprojectflag = 'N') THEN
              -- existe expense com projeto
              cprojecterror  := 'INVALID EXP DISTR PROJ';
              braiseprojects := TRUE;
            ELSIF (ncountdistrinv > 0) AND (ncountdistrexp > 0) AND
                  (cprojectflag IN ('S', 'B')) THEN
              -- existe inventory/shop floor ou expense sem projeto
              cprojecterror  := 'INVALID INV DISTR';
              braiseprojects := TRUE;

            ELSIF (ncountdistrexp > 0) AND (cprojectflag = 'N') THEN
              -- existe expense com projeto para a entrega (Tipo de NF sem integracao PA)
              cprojecterror := 'INF PROJ INVALID';
              -- Bug 5905664 SSimoes 06/03/2007
              braiseprojects := TRUE;
              --
              -- Bug 11902118 - Inicio
              /*
              ELSIF (ncountdistrinv > 0) AND (cprojectflag IN ('S','B')) -- existe inventory  para a entrega (Tipo de NF com integracao PA)
              THEN
              */
              --
            ELSIF (ncountdistrinv > 0) AND (cprojectflag IN ('S', 'I')) THEN
              -- existe inventory  para a entrega (Tipo de NF com integracao PA)
              -- Bug 11902118 - Fim
              cprojecterror := 'INF PROJ INVALID';
              -- Bug 5905664 SSimoes 06/03/2007
              braiseprojects := TRUE;
            END IF;
            -- ER 8614153 - END
          END IF; -- ER 8614153
          --ELSE  -- ER 8614153
          --               IF cprojectflag IN ('S','B') AND -- ER 6788945 AIrmer 15/02/2008 -- ER 9069838
          IF cprojectflag IN ('I', 'S', 'B') AND -- ER 6788945 AIrmer 15/02/2008 -- ER 9069838
             NVL(ncountprojects, 0) <> NVL(ncountlin, 0) AND
             NVL(ncountnoprojects, 0) > 0 AND -- Bug 5887300 SSimoes 01/03/2007
             cprojecterror = 'N' THEN
            -- ER 8614153
            cprojecterror  := 'ITEM PROJ INVALID'; -- Bug 5905664 SSimoes 06/03/2007
            braiseprojects := TRUE;
            --               ELSIF cprojectflag IN ('S','B') AND -- ER 6788945 AIrmer 15/02/2008 -- ER 9069838
          ELSIF cprojectflag IN ('I', 'S', 'B') AND -- ER 6788945 AIrmer 15/02/2008 -- ER 9069838
                NVL(ncountnoprojects, 0) > 0 AND -- Bug 5887300 SSimoes 01/03/2007
                cprojecterror = 'N' THEN
            -- ER 8614153
            cprojecterror  := 'ITEM PROJ INVALID'; -- Bug 5905664 SSimoes 06/03/2007
            braiseprojects := TRUE;
            -- Bug 5887300 SSimoes 01/03/2007 - End
            --END IF;
            -- ER 6788945 AIrmer 15/02/2008 - Begin
          ELSIF NVL(nCountProjects, 0) > 0 AND cProjectFlag = 'B' THEN
            -- Seiban --1
            IF (p_interface = 'N') THEN
              -- 2
              -- for each distribution line, verifying if the project have a Seiban Number
              FOR x_distributions IN (SELECT pda.project_id
                                        FROM cll_f189_invoices      ri,
                                             cll_f189_invoice_lines ril,
                                             po_distributions_all   pda
                                       WHERE ri.invoice_id =
                                             r_invoices.invoice_id
                                         AND ril.invoice_id = ri.invoice_id
                                         AND pda.line_location_id =
                                             ril.line_location_id
                                         AND pda.project_id IS NOT NULL) LOOP
                SELECT count(project_id)
                  INTO v_count_seiban
                  FROM pjm_seiban_numbers psn
                 WHERE psn.project_id = x_distributions.project_id;

                IF v_count_seiban = 0 THEN
                  cProjectError  := 'SEIBAN NOT FND';
                  bRaiseProjects := TRUE;
                END IF;
              END LOOP;
            ELSE
              -- (p_interface = 'N') -- 2
              -- for each distribution line, verifying if the project have a Seiban Number
              FOR x_distributions IN (SELECT pda.project_id
                                        FROM cll_f189_invoices_interface  ri,
                                             cll_f189_invoice_lines_iface ril,
                                             po_distributions_all         pda
                                       WHERE ri.interface_invoice_id =
                                             r_invoices.interface_invoice_id
                                         AND ril.interface_invoice_id =
                                             ri.interface_invoice_id
                                         AND pda.line_location_id =
                                             ril.line_location_id) LOOP
                IF (x_distributions.project_id IS NOT NULL) THEN
                  SELECT count(project_id)
                    INTO v_count_seiban
                    FROM pjm_seiban_numbers psn
                   WHERE psn.project_id = x_distributions.project_id;
                  IF v_count_seiban = 0 THEN
                    cProjectError  := 'SEIBAN NOT FND';
                    bRaiseProjects := TRUE;
                  END IF;
                END IF;
              END LOOP;
            END IF; -- 2
            -- ER 6788945 AIrmer 15/02/2008 - End
          END IF;

        ELSE
          --IF r_invoices.requisition_type IN ('PO', 'OE')
          IF p_interface = 'N' THEN
            IF cprojectflag = 'N' THEN
              SELECT COUNT(1)
                INTO ncountprojects
                FROM cll_f189_invoice_lines
               WHERE invoice_id = r_invoices.invoice_id
                 AND project_id IS NOT NULL;
              IF ncountprojects > 0 THEN
                braiseprojects := TRUE;
              END IF;
            ELSE
              SELECT COUNT(1)
                INTO ncountprojects
                FROM cll_f189_invoice_lines
               WHERE invoice_id = r_invoices.invoice_id
                 AND project_id IS NULL;
              IF ncountprojects > 0 THEN
                cprojecterror  := 'INF PROJ INVALID'; -- Bug 17243833
                braiseprojects := TRUE;
              END IF;
            END IF;
          ELSE
            -- p_interface = 'Y'
            IF cprojectflag = 'N' THEN
              SELECT COUNT(1)
                INTO ncountprojects
                FROM CLL_F189_INVOICE_LINES_IFACE
               WHERE interface_invoice_id = r_invoices.interface_invoice_id
                 AND project_id IS NOT NULL;
              IF ncountprojects > 0 THEN
                braiseprojects := TRUE;
              END IF;
            ELSE
              SELECT COUNT(1)
                INTO ncountprojects
                FROM CLL_F189_INVOICE_LINES_IFACE
               WHERE interface_invoice_id = r_invoices.interface_invoice_id
                 AND project_id IS NULL;
              IF ncountprojects > 0 THEN
                cprojecterror  := 'INF PROJ INVALID'; -- Bug 17243833
                braiseprojects := TRUE;
              END IF;
            END IF;
          END IF;
        END IF;
        --
        IF (braiseprojects) THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       cprojecterror -- Bug 5905664 SSimoes 06/03/2007
                                                       --                                                 ,'INF PROJ INVALID'  -- Bug 5905664 SSimoes 06/03/2007
                                                      ,
                                                       r_invoices.invoice_id,
                                                       NULL);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                  p_operation_id,
                                                  cprojecterror);
            -- Bug 5905664 SSimoes 06/03/2007
            -- ,'INF PROJ INVALID'); -- Bug 5905664 SSimoes 06/03/2007
          END IF;
        END IF;
        --
        IF r_invoices.requisition_type = 'OE' THEN
          -- Bug 8585314 - SSimoes - 29/06/2009 - Inicio
          BEGIN
            SELECT distinct rsh.shipment_header_id
              INTO v_count_req_int
              FROM cll_f189_invoices      ri,
                   cll_f189_invoice_lines ril,
                   rcv_shipment_headers   rsh,
                   rcv_shipment_lines     rsl
             WHERE ri.organization_id = p_organization_id
               AND ri.operation_id = p_operation_id
               AND ril.invoice_id = ri.invoice_id
               AND ril.organization_id = ri.organization_id
               AND rsl.shipment_line_id = ril.shipment_line_id
               AND rsh.shipment_header_id = rsl.shipment_header_id;
          EXCEPTION
            WHEN TOO_MANY_ROWS THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF INTERNAL ORDERS',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                      p_operation_id,
                                                      'DIFF INTERNAL ORDERS');
              END IF;
            WHEN OTHERS THEN
              NULL;
          END;
          -- Bug 8585314 - SSimoes - 29/06/2009 - Fim
          -- Bug 9532625 - SSimoes - 21/05/2010 - Inicio
          IF v_national_state = 'Y' THEN
            NULL;
          ELSE
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVALID STATE INTERNAL ORDERS',
                                                         r_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.invoice_id,
                                                    p_operation_id,
                                                    'INVALID STATE INTERNAL ORDERS');
            END IF;
          END IF;
          -- Bug 9532625 - SSimoes - 21/05/2010 - Fim
        END IF; --IF r_invoices.requisition_type = 'OE' THEN
        -- Bug 4491025 - Start
        -- Bug 4707637
        IF r_invoices.requisition_type = 'PO' THEN
          IF p_interface = 'N' THEN
            IF r_invoices.return_customer_flag = 'F' THEN
              -- Bug 4707637 --
              FOR x_currency IN (SELECT NVL(ri.po_currency_code, '@@@') po_currency_code
                                   FROM cll_f189_invoice_parents rip,
                                        cll_f189_invoices        ri
                                  WHERE rip.invoice_id =
                                        r_invoices.invoice_id
                                    AND ri.invoice_id =
                                        rip.invoice_parent_id) LOOP
                IF r_invoices.po_currency_code <>
                   x_currency.po_currency_code THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'CURRENCY DEVOL <> PARENT',
                                                             r_invoices.invoice_id,
                                                             NULL);
                END IF;
              END LOOP;
            END IF;
          ELSE
            -- P_INTERFACE = Y
            IF r_invoices.return_customer_flag = 'F' THEN
              -- Bug 4707637 --
              FOR x_currency IN (SELECT NVL(ri.po_currency_code, '@@@') po_currency_code
                                   FROM cll_f189_invoice_parents_int rip,
                                        cll_f189_invoices            ri
                                  WHERE rip.interface_invoice_id =
                                        r_invoices.interface_invoice_id
                                    AND ri.invoice_id =
                                        rip.invoice_parent_id) LOOP
                IF r_invoices.po_currency_code <>
                   x_currency.po_currency_code THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'CURRENCY DEVOL <> PARENT',
                                                             r_invoices.interface_invoice_id
                                                             -- Bug 4658115 AIrmer 14/10/2005
                                                            ,
                                                             NULL);
                END IF;
              END LOOP;
            END IF;
          END IF;
        END IF; --IF r_invoices.requisition_type = 'PO'
        -- Bug 4491025 - End
        IF (r_invoices.parent_flag = 'Y' AND
           (r_invoices.tax_adjust_flag = 'Y' OR
           r_invoices.price_adjust_flag = 'Y' OR
           r_invoices.cost_adjust_flag = 'Y')) THEN
          -- PAC
          BEGIN
            SELECT cost_group_id
              INTO x_insert_pac
              FROM cst_cost_group_assignments
             WHERE organization_id = p_organization_id;
          EXCEPTION
            WHEN OTHERS THEN
              x_insert_pac := NULL;
          END;
          -- PAC period
          IF x_insert_pac IS NOT NULL THEN
            -- Functional Currency
            BEGIN
              SELECT gsob.set_of_books_id
                INTO x_set_of_books_id_func
                FROM org_organization_definitions ood,
                     gl_sets_of_books             gsob
               WHERE ood.organization_id = p_organization_id
                 AND ood.set_of_books_id = gsob.set_of_books_id;
            EXCEPTION
              WHEN OTHERS THEN
                x_set_of_books_id_func := NULL;
            END;
            -- Alternative Currency
            x_set_of_books_id_alt1 := TO_NUMBER(fnd_profile.VALUE('CLL_F189_FIRST_ALTERNATIVE_SET_OF_BOOKS'));
            x_set_of_books_id_alt2 := TO_NUMBER(fnd_profile.VALUE('CLL_F189_SECOND_ALTERNATIVE_SET_OF_BOOKS'));

            -- Periods
            FOR x_pac_period IN (SELECT legal_entity, cost_type_id
                                   FROM CLL_F032_c_groups_c_types_v
                                  WHERE organization_id = p_organization_id
                                    AND set_of_books_id IN
                                        (x_set_of_books_id_func,
                                         NVL(x_set_of_books_id_alt1, 0),
                                         NVL(x_set_of_books_id_alt2, 0))) LOOP
              BEGIN
                SELECT open_flag
                  INTO x_open_flag
                  FROM cst_pac_periods
                 WHERE legal_entity = x_pac_period.legal_entity
                   AND cost_type_id = x_pac_period.cost_type_id
                   AND v_gl_date BETWEEN TRUNC(period_start_date) AND
                       TRUNC(period_end_date) + .99999;
                IF x_open_flag = 'N' THEN
                  x_raise_pac := TRUE;
                ELSE
                  x_raise_pac := FALSE;
                END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  x_raise_pac := FALSE;
              END;
            END LOOP;
            --
            IF x_raise_pac THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INV PAC PER',
                                                         r_invoices.invoice_id,
                                                         NULL);
            END IF;
          END IF; -- => IF x_insert_pac IS NOT NULL THEN <=
          v_raise_nf_complementar := FALSE;
          IF p_interface = 'N' THEN
            BEGIN
              SELECT COUNT(1)
                INTO nquantnfpai
                FROM cll_f189_invoice_parents      rip,
                     cll_f189_invoice_line_parents rilp
               WHERE rip.invoice_id = r_invoices.invoice_id
                 AND rilp.parent_id = rip.parent_id;
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20611,
                                        SQLERRM || '****************' ||
                                        ' Invoice parent not found ' ||
                                        '******************');
            END;
            IF (nquantnfpai > 0) THEN
              -- ER 6788945 AIrmer 15/02/2008 - Begin
              -- Verifying is the PO in the Parent Invoice have a Seiban Number (p_interface = 'N')
              IF (cProjectFlag = 'B') THEN
                -- 1
                FOR x_invoice_parents IN (SELECT rip.invoice_parent_id
                                            FROM cll_f189_invoice_parents rip
                                           WHERE rip.invoice_id =
                                                 r_invoices.invoice_id) LOOP
                  FOR x_distributions IN (SELECT pda.project_id
                                            FROM cll_f189_invoices      ri,
                                                 cll_f189_invoice_lines ril,
                                                 po_distributions_all   pda
                                           WHERE ri.invoice_id =
                                                 x_invoice_parents.invoice_parent_id
                                             AND ril.invoice_id =
                                                 ri.invoice_id
                                             AND pda.line_location_id =
                                                 ril.line_location_id
                                             AND pda.project_id IS NOT NULL) LOOP
                    SELECT count(project_id)
                      INTO v_count_seiban
                      FROM pjm_seiban_numbers psn
                     WHERE psn.project_id = x_distributions.project_id;
                    IF v_count_seiban = 0 THEN
                      -- 3
                      cProjectError  := 'SEIBAN NOT FND COMPL';
                      bRaiseProjects := TRUE;
                    END IF; -- 3
                  END LOOP; -- x_distributions
                END LOOP; -- x_invoice_parents
                IF bRaiseProjects THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             cProjectError,
                                                             r_invoices.invoice_id,
                                                             NULL);
                END IF;
              END IF; -- 1
              -- ER 6788945 AIrmer 15/02/2008 - End
              IF (r_invoices.requisition_type = 'PO' OR
                 r_invoices.cost_adjust_flag = 'Y') THEN
                FOR x_compl IN (SELECT ri.operation_id,
                                       NVL(ri.po_currency_code, '@@@') po_currency_code -- Bug.4491025
                                  FROM cll_f189_invoice_parents rip,
                                       cll_f189_invoices        ri
                                 WHERE rip.invoice_id =
                                       r_invoices.invoice_id
                                   AND ri.invoice_id = rip.invoice_parent_id) LOOP
                  IF NOT
                      (CLL_F189_check_deliver_pkg.func_check_deliver(x_compl.operation_id,
                                                                     p_organization_id)) THEN
                    v_raise_nf_complementar := TRUE;
                  END IF;
                  -- Bug 4491025 - Start
                  IF r_invoices.po_currency_code <>
                     x_compl.po_currency_code AND
                     r_invoices.return_customer_flag = 'F' THEN
                    -- Bug 4707637 --
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'CURRENCY DEVOL <> PARENT',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  END IF;
                  -- Bug 4491025 - End
                END LOOP;
                --
                IF (v_raise_nf_complementar) THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'PARENT INV NOT DELIVERED',
                                                             r_invoices.invoice_id,
                                                             NULL);
                END IF;
              END IF;
            ELSE
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NO PARENT INV',
                                                         r_invoices.invoice_id,
                                                         NULL);
            END IF;
          ELSE
            -- p_interface = 'Y'
            -- Invoice parent - Open Interface
            BEGIN
              SELECT COUNT(1)
                INTO nquantnfpai
                FROM cll_f189_invoice_parents_int  rip,
                     CLL_F189_INVOICE_LINE_PAR_INT rilp
               WHERE rip.interface_invoice_id =
                     r_invoices.interface_invoice_id
                 AND rilp.interface_parent_id = rip.interface_parent_id;
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20612,
                                        SQLERRM || '****************' ||
                                        ' Invoice parent not found ' ||
                                        '******************');
            END;
            --
            IF (nquantnfpai > 0) THEN
              -- ER 6788945 AIrmer 15/02/2008 - Begin
              -- Verifying is the PO in the Parent Invoice have a Seiban Number (p_interface = 'Y')
              IF cProjectFlag = 'B' THEN
                -- 1
                FOR x_invoice_parents IN (SELECT rip.invoice_parent_id
                                            FROM cll_f189_invoice_parents rip
                                           WHERE rip.invoice_id =
                                                 r_invoices.invoice_id) LOOP
                  FOR x_distributions IN (SELECT pda.project_id
                                            FROM cll_f189_invoices_interface  ri,
                                                 cll_f189_invoice_lines_iface ril,
                                                 po_distributions_all         pda
                                           WHERE ri.interface_invoice_id =
                                                 x_invoice_parents.invoice_parent_id
                                             AND ril.interface_invoice_id =
                                                 ri.interface_invoice_id
                                             AND pda.line_location_id =
                                                 ril.line_location_id
                                             AND pda.project_id IS NOT NULL) LOOP
                    SELECT count(project_id)
                      INTO v_count_seiban
                      FROM pjm_seiban_numbers psn
                     WHERE psn.project_id = x_distributions.project_id;
                    IF v_count_seiban = 0 THEN
                      cProjectError  := 'SEIBAN NOT FND COMPL';
                      bRaiseProjects := TRUE;
                    END IF;
                  END LOOP; -- x_distributions
                END LOOP; -- x_invoice_parents
                --
                IF bRaiseProjects THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        cProjectError);
                END IF;
                --
              END IF; -- 1
              -- ER 6788945 AIrmer 15/02/2008 - Begin
              IF (r_invoices.requisition_type = 'PO') THEN
                FOR x_compl IN (SELECT ri.operation_id,
                                       NVL(ri.po_currency_code, '@@@') po_currency_code -- Bug.4491025
                                  FROM cll_f189_invoice_parents_int rip,
                                       cll_f189_invoices            ri
                                 WHERE rip.interface_invoice_id =
                                       r_invoices.interface_invoice_id
                                   AND ri.invoice_id = rip.invoice_parent_id) LOOP
                  IF NOT
                      (cll_f189_check_deliver_pkg.func_check_deliver(x_compl.operation_id,
                                                                     p_organization_id)) THEN
                    v_raise_nf_complementar := TRUE;
                  END IF;
                  -- Bug 4491025 - Start
                  IF r_invoices.po_currency_code <>
                     x_compl.po_currency_code AND
                     r_invoices.return_customer_flag = 'F' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'CURRENCY DEVOL <> PARENT'
                                                               -- ,r_invoices.invoice_id   -- Bug 4658115 AIrmer 14/10/2005
                                                              ,
                                                               r_invoices.interface_invoice_id
                                                               -- Bug 4658115 AIrmer 14/10/2005
                                                              ,
                                                               NULL);
                  END IF;
                  -- Bug 4491025 - End
                END LOOP;
                --
                IF (v_raise_nf_complementar) THEN
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'PARENT INV NOT DELIVERED');
                END IF;
              END IF;
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'NO PARENT INV');
            END IF;
          END IF;
        END IF;
        --
        IF p_interface = 'N' THEN
          BEGIN
            SELECT rit.requisition_type
              INTO ctipopedido
              FROM cll_f189_invoices ri, cll_f189_invoice_types rit
             WHERE ri.invoice_id = r_invoices.invoice_id
               AND rit.invoice_type_id = ri.invoice_type_id
               AND NVL(rit.price_adjust_flag, 'N') <> 'Y'
               AND NVL(rit.tax_adjust_flag, 'N') <> 'Y';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ctipopedido := NULL;
            WHEN OTHERS THEN
              raise_application_error(-20607,
                                      SQLERRM || '*******************' ||
                                      ' Purchase Order not found ' ||
                                      '*******************');
          END;
        ELSE
          BEGIN
            SELECT rit.requisition_type
              INTO ctipopedido
              FROM cll_f189_invoices_interface ri,
                   cll_f189_invoice_types      rit
             WHERE ri.interface_invoice_id =
                   r_invoices.interface_invoice_id
               and rit.organization_id = p_organization_id -- BUG 19722064
               AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                   rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
               AND NVL(rit.price_adjust_flag, 'N') <> 'Y'
               AND NVL(rit.tax_adjust_flag, 'N') <> 'Y';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ctipopedido := NULL;
            WHEN OTHERS THEN
              raise_application_error(-20607,
                                      SQLERRM || '*******************' ||
                                      ' Purchase Order not found (interface)' ||
                                      '*******************');
          END;
        END IF;
        -- Bug 5951443 SSimoes 10/04/2007 - Start
        IF r_invoices.requisition_type = 'RM' AND
           r_invoices.price_adjust_flag = 'N' AND
           r_invoices.tax_adjust_flag = 'N' AND
           r_invoices.cost_adjust_flag = 'N' THEN
          -- BUG 24482800
          IF p_interface = 'N' THEN
            BEGIN
              SELECT COUNT(1)
                INTO ncountrma
                FROM cll_f189_rma_receipts_v rrrv,
                     cll_f189_invoice_lines  ril
               WHERE ril.invoice_id = r_invoices.invoice_id
                 AND NVL(ril.receipt_flag, 'N') <> 'Y'
                 AND NVL(rrrv.closed_flag, 'N') = 'N'
                 AND rrrv.organization_id + 0 = p_organization_id
                 AND rrrv.activity_name || '' = 'RMA_WAIT_FOR_RECEIVING'
                 AND rrrv.activity_status || '' = 'NOTIFIED'
                 AND rrrv.rma_interface_id = ril.rma_interface_id
                 AND rrrv.available_quantity > 0;
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20608,
                                        SQLERRM || '*******************' ||
                                        ' View CLL_F189_rma_receipts_v (RMA) not found' ||
                                        '*******************');
            END;
          ELSE
            BEGIN
              SELECT COUNT(1)
                INTO ncountrma
                FROM cll_f189_rma_receipts_v      rrrv,
                     CLL_F189_INVOICE_LINES_IFACE ril
               WHERE ril.interface_invoice_id =
                     r_invoices.interface_invoice_id -- Bug 6405962 - rvicente - 16/01/08
                 AND NVL(ril.receipt_flag, 'N') <> 'Y'
                 AND NVL(rrrv.closed_flag, 'N') = 'N'
                 AND rrrv.organization_id + 0 = p_organization_id
                 AND rrrv.activity_name || '' = 'RMA_WAIT_FOR_RECEIVING'
                 AND rrrv.activity_status || '' = 'NOTIFIED'
                 AND rrrv.rma_interface_id = ril.rma_interface_id
                 AND rrrv.available_quantity > 0;
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20608,
                                        SQLERRM || '*******************' ||
                                        ' View CLL_F189_rma_receipts_v (RMA) not found' ||
                                        '*******************');
            END;
          END IF;
          --
          IF ncountrma = 0 THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'STATUS PURCH INVALID',
                                                         r_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'STATUS PURCH INVALID');
            END IF;
          END IF;
        END IF;
        -- Bug 5951443 SSimoes 10/04/2007 - End
        IF (r_invoices.requisition_type = 'PO' AND
           r_invoices.price_adjust_flag = 'N' AND
           r_invoices.tax_adjust_flag = 'N') AND
           r_invoices.cost_adjust_flag = 'N' THEN
          -- BUG 24482800
          -- Bug 9017036 - SSimoes - 20/11/2009 - Inicio
          IF r_invoices.fixed_assets_flag IN ('S', 'O') AND
             r_invoices.parent_flag = 'Y' THEN
            -- Invoice Lines
            FOR r_invoice_lines IN c_invoice_lines LOOP
              -- Bug 9745040 - SSimoes - 01/06/2010 - Inicio
              IF r_invoice_lines.line_location_id IS NOT NULL THEN
                BEGIN
                  FOR c_Dest_SubInv IN (SELECT pd.destination_subinventory,
                                               pd.destination_organization_id,
                                               pll.ship_to_organization_id
                                          FROM po_line_locations_all pll,
                                               po_distributions_all  pd
                                         WHERE pll.line_location_id =
                                               r_invoice_lines.line_location_id
                                           AND pll.line_location_id =
                                               pd.line_location_id) LOOP
                    -- c_Dest_SubInv
                    BEGIN
                      SELECT 'Y'
                        INTO v_inventory_destination_flag
                        FROM mtl_secondary_inventories msi
                       WHERE (c_Dest_SubInv.destination_subinventory IS NULL OR
                             (NVL(c_Dest_SubInv.destination_organization_id,
                                   c_Dest_SubInv.ship_to_organization_id) =
                             msi.organization_id AND
                             c_Dest_SubInv.destination_subinventory =
                             msi.secondary_inventory_name AND
                             msi.asset_inventory = '1'))
                         AND ROWNUM = 1;
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        v_inventory_destination_flag := 'N';
                      WHEN OTHERS THEN
                        v_inventory_destination_flag := NULL;
                        raise_application_error(-20625,
                                                SQLERRM ||
                                                '*******************' ||
                                                ' Destination Subinventory not found' ||
                                                '*******************');
                    END;
                    --
                    IF v_inventory_destination_flag = 'N' THEN
                      IF p_interface = 'N' THEN
                        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                   p_organization_id,
                                                                   p_location_id,
                                                                   'INVALID SUBINVENTORY',
                                                                   r_invoice_lines.invoice_id,
                                                                   r_invoice_lines.invoice_line_id);
                      ELSE
                        cll_f189_check_holds_pkg.incluir_erro(r_invoice_lines.interface_invoice_id,
                                                              p_operation_id,
                                                              'INVALID SUBINVENTORY',
                                                              r_invoice_lines.interface_invoice_line_id);
                      END IF;
                    END IF;
                  END LOOP; -- c_Dest_SubInv
                END;
              END IF;
              -- Bug 9745040 - SSimoes - 01/06/2010 - Fim
              IF r_invoice_lines.line_location_id IS NOT NULL THEN
                BEGIN
                  -- Trazer total de faturamento para o mesmo po_line_location
                  SELECT NVL(SUM(DECODE(rit.credit_debit_flag,
                                        'D',
                                        NVL(ril.quantity, 0),
                                        NVL(ril.quantity, 0) * -1)),
                             0)
                    INTO v_faturado_nf_pai
                    FROM cll_f189_invoice_types    rit,
                         cll_f189_invoice_lines    ril,
                         cll_f189_invoices         ri,
                         cll_f189_entry_operations reo
                   WHERE ril.line_location_id =
                         r_invoice_lines.line_location_id
                     AND ri.invoice_id = ril.invoice_id
                     AND rit.invoice_type_id = ri.invoice_type_id
                     AND rit.price_adjust_flag = 'N'
                     AND rit.tax_adjust_flag = 'N'
                     AND reo.organization_id = ri.organization_id
                     AND reo.operation_id = ri.operation_id
                     AND reo.status = 'COMPLETE'
                     AND rit.invoice_type_id NOT IN
                         (SELECT rit2.invoice_type_id
                            FROM cll_f189_invoice_types rit2
                           WHERE rit2.fixed_assets_flag IN ('S', 'O')
                             AND rit2.parent_flag = 'Y'
                             AND rit2.credit_debit_flag = 'D')
                        -- Nao considerar reversao de remessa
                     AND ri.invoice_parent_id NOT IN
                         (SELECT invoice_id
                            FROM cll_f189_invoices cfi2
                           WHERE cfi2.invoice_type_id IN
                                 (select rit3.invoice_type_id
                                    from cll_f189_invoice_types rit3
                                   where rit3.fixed_assets_flag IN ('S', 'O')
                                     and rit3.parent_flag = 'Y'
                                     and rit3.credit_debit_flag = 'D')
                             AND cfi2.invoice_id = ri.invoice_parent_id);
                  --
                  -- Trazer total de outras remessas para o mesmo po_line_location
                  SELECT NVL(SUM(DECODE(rit.credit_debit_flag,
                                        'D',
                                        NVL(ril.quantity, 0),
                                        NVL(ril.quantity, 0) * -1)),
                             0)
                    INTO v_remessa
                    FROM cll_f189_invoice_types    rit,
                         cll_f189_invoice_lines    ril,
                         cll_f189_invoices         ri,
                         cll_f189_entry_operations reo
                   WHERE ril.line_location_id =
                         r_invoice_lines.line_location_id
                     AND ri.invoice_id = ril.invoice_id
                     AND rit.invoice_type_id = ri.invoice_type_id
                     AND rit.price_adjust_flag = 'N'
                     AND rit.tax_adjust_flag = 'N'
                     AND reo.organization_id = ri.organization_id
                     AND reo.operation_id = ri.operation_id
                     AND reo.status = 'COMPLETE'
                     AND (rit.invoice_type_id IN
                         (SELECT rit2.invoice_type_id
                             FROM cll_f189_invoice_types rit2
                            WHERE rit2.fixed_assets_flag IN ('S', 'O')
                              AND rit2.parent_flag = 'Y'
                              AND rit2.credit_debit_flag = 'D')
                         -- Considerar reversao ou devolucao de remessa
                         OR
                         ri.invoice_parent_id IN
                         (SELECT invoice_id
                             FROM cll_f189_invoices cfi2
                            WHERE cfi2.invoice_type_id IN
                                  (select rit3.invoice_type_id
                                     from cll_f189_invoice_types rit3
                                    where rit3.fixed_assets_flag IN
                                          ('S', 'O')
                                      and rit3.parent_flag = 'Y'
                                      and rit3.credit_debit_flag = 'D')
                              AND cfi2.invoice_id = ri.invoice_parent_id));
                  --
                  -- Trazer total da remessa atual para o mesmo po_line_location
                  SELECT NVL(SUM(DECODE(rit.credit_debit_flag,
                                        'D',
                                        NVL(ril.quantity, 0),
                                        NVL(ril.quantity, 0) * -1)),
                             0)
                    INTO v_remessa_atual
                    FROM cll_f189_invoice_types rit,
                         cll_f189_invoice_lines ril,
                         cll_f189_invoices      ri
                   WHERE ril.line_location_id =
                         r_invoice_lines.line_location_id
                     AND ri.operation_id = p_operation_id
                     AND ri.organization_id = p_organization_id
                     AND ri.invoice_id = ril.invoice_id
                     AND rit.invoice_type_id = ri.invoice_type_id
                     AND rit.price_adjust_flag = 'N'
                     AND rit.tax_adjust_flag = 'N'
                     AND rit.invoice_type_id IN
                         (SELECT rit2.invoice_type_id
                            FROM cll_f189_invoice_types rit2
                           WHERE rit2.fixed_assets_flag IN ('S', 'O')
                             AND rit2.parent_flag = 'Y'
                             AND rit2.credit_debit_flag = 'D');
                  --
                  v_remessa := v_remessa + v_remessa_atual;
                  -- Valor Total das Remessas nao pode ser maior que o Valor Total Faturado
                  IF v_remessa > v_faturado_nf_pai THEN
                    IF p_interface = 'N' THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                 'FA QUANTITY EXCEEDS',
                                                                 r_invoices.invoice_id,
                                                                 NULL);
                    ELSE
                      cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                            p_operation_id,
                                                            'FA QUANTITY EXCEEDS');
                    END IF;
                  END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20623,
                                            SQLERRM ||
                                            '*******************' ||
                                            ' Error in integration with FA with parent invoice' ||
                                            '*******************');
                END;
              END IF;
            END LOOP;
          END IF;
          -- Bug 9017036 - SSimoes - 20/11/2009 - Fim
          IF (r_invoices.fixed_assets_flag IN ('S', 'O') AND
             r_invoices.parent_flag = 'Y') THEN
            -- ER 9017036
            ncountpedidos  := 0;
            ncountreleases := 0;
          ELSE
            IF r_invoices.return_customer_flag <> 'F' THEN
              IF p_interface = 'N' THEN
                -- ER 7483063 AIrmer 16/04/2009
                BEGIN
                  IF (r_invoices.complex_service_flag = 'Y') THEN
                    SELECT COUNT(1)
                      INTO ncountpedidos
                      FROM cll_f189_invoice_lines ril,
                           cll_f189_invoices      ri,
                           po_line_locations_all  pll,
                           po_headers_all         ph,
                           cll_f189_invoice_types rit
                     WHERE ril.invoice_id = r_invoices.invoice_id
                       AND pll.line_location_id = ril.line_location_id
                       AND ph.po_header_id = pll.po_header_id
                       AND NVL(ril.receipt_flag, 'N') <> 'Y'
                       AND ri.invoice_id = ril.invoice_id
                       AND rit.invoice_type_id = ri.invoice_type_id
                          -- Begin BUG 24750424 e 24919430
                          /*
                          --<<BUG 20646945 --Start -->>
                          AND ((pll.closed_code = 'CLOSED FOR INVOICE'
                             AND EXISTS (SELECT 1
                                           FROM ap_invoices_all inv ,ap_invoice_lines_all invl
                                          WHERE inv.invoice_id = invl.invoice_id
                                            AND invl.po_line_location_id = pll.line_location_id
                                            AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                                            AND invl.tax_already_calculated_flag = 'Y')
                          AND   (r_invoices.payment_flag = 'Y'))
                           OR pll.closed_code = 'CLOSED FOR RECEIVING'
                           OR (pll.closed_code = 'CLOSED FOR INVOICE' and r_invoices.payment_flag = 'Y'))
                          */
                          /*
                          AND (DECODE (r_invoices.payment_flag, 'Y', DECODE (NVL (pll.closed_code, 'OPEN')
                                                      , 'OPEN', 'Y'
                                                      , 'CLOSED FOR RECEIVING', 'Y'
                                                      , 'N')
                             , DECODE (NVL (pll.closed_code, 'OPEN')
                                                           , 'OPEN', 'Y'
                                                           , 'CLOSED FOR INVOICE', 'Y'
                                                           , 'CLOSED FOR RECEIVING', 'Y'
                                                           , 'N')) = 'N'
                            OR ph.approved_flag <> 'Y')*/
                          --<< BUG 20646945 --End -->>
                       AND pll.po_release_id IS NULL
                       AND (pll.closed_code IN
                           ('CLOSED',
                             'CLOSE FOR INVOICE',
                             'FINALLY CLOSED' -- BUG 24621425
                             /*,'CLOSED FOR RECEIVING'*/) -- Quando comlex Service a PO fica com STATUS CLOSED FOR RECEIVING
                           OR
                           (pll.line_location_id IN
                           (SELECT invl.po_line_location_id
                                FROM ap_invoices_all      inv,
                                     ap_invoice_lines_all invl
                               WHERE inv.invoice_id = invl.invoice_id
                                 AND inv.invoice_type_lookup_code =
                                     'PREPAYMENT'
                                 AND pll.closed_code = 'CLOSED FOR INVOICE'
                                 AND NVL(inv.amount_paid, 0) = 0)));
                    -- End BUG 24750424 e 24919430
                  ELSE
                    -- ER 7483063 AIrmer 16/04/2009
                    SELECT COUNT(1)
                      INTO ncountpedidos
                      FROM cll_f189_invoice_lines ril,
                           cll_f189_invoices      ri,
                           po_line_locations_all  pll,
                           po_headers_all         ph,
                           cll_f189_invoice_types rit
                     WHERE ril.invoice_id = r_invoices.invoice_id
                       AND pll.line_location_id = ril.line_location_id
                       AND ph.po_header_id = pll.po_header_id
                       AND NVL(ril.receipt_flag, 'N') <> 'Y'
                       AND ri.invoice_id = ril.invoice_id
                       AND rit.invoice_type_id = ri.invoice_type_id
                          -- AND NVL(pll.approved_flag,'N') <> 'Y' -- 23137900
                       AND NVL(PLL.APPROVED_FLAG, 'N') = 'Y' -- 23137900
                          -- Begin BUG 24750424 e 24919430
                          --<<BUG 20646945 --Start -->>
                          /*
                          AND ((pll.closed_code = 'CLOSED FOR INVOICE'
                            AND EXISTS (SELECT 1
                                          FROM ap_invoices_all inv ,ap_invoice_lines_all invl
                                         WHERE inv.invoice_id = invl.invoice_id
                                           AND invl.po_line_location_id = pll.line_location_id
                                           AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                                           AND invl.tax_already_calculated_flag = 'Y')
                          AND (r_invoices.payment_flag = 'Y'))
                           OR pll.closed_code = 'CLOSED FOR RECEIVING'
                           OR (pll.closed_code = 'CLOSED FOR INVOICE' and r_invoices.payment_flag = 'Y'))
                           */
                          /* AND (DECODE (r_invoices.payment_flag , 'Y',
                              DECODE (NVL (pll.closed_code, 'OPEN')
                                                          , 'OPEN', 'Y'
                                                          , 'CLOSED FOR INVOICE', 'Y' -- Bug 18306068
                                                          , 'N')
                            , DECODE (NVL (pll.closed_code, 'OPEN')
                                                          , 'OPEN', 'Y'
                                                          , 'CLOSED FOR INVOICE', 'Y'
                                                          , 'N')) = 'N'
                          OR ph.approved_flag <> 'Y')*/
                          --<< BUG 20646945 --End -->>
                       AND pll.po_release_id IS NULL -- BUG 4036472
                       AND (pll.closed_code IN
                           ('CLOSED',
                             'CLOSE FOR INVOICE',
                             'FINALLY CLOSED' -- BUG 24621425
                            ,
                             'CLOSED FOR RECEIVING') -- BUG 24621425
                           OR
                           (pll.line_location_id IN
                           (SELECT invl.po_line_location_id
                                FROM ap_invoices_all      inv,
                                     ap_invoice_lines_all invl
                               WHERE inv.invoice_id = invl.invoice_id
                                 AND inv.invoice_type_lookup_code =
                                     'PREPAYMENT'
                                 AND pll.closed_code = 'CLOSED FOR INVOICE'
                                 AND NVL(inv.amount_paid, 0) = 0)));
                    -- End BUG 24750424 e 24919430
                  END IF; -- ER 7483063 AIrmer 16/04/2009
                  --
                  SELECT COUNT(1)
                    INTO ncounttemreleases
                    FROM cll_f189_invoice_lines ril,
                         cll_f189_invoices      ri,
                         po_line_locations_all  pll,
                         po_headers_all         ph,
                         cll_f189_invoice_types rit
                   WHERE ril.invoice_id = r_invoices.invoice_id
                     AND pll.line_location_id = ril.line_location_id
                     AND ph.po_header_id = pll.po_header_id
                     AND NVL(ril.receipt_flag, 'N') <> 'Y'
                     AND ri.invoice_id = ril.invoice_id
                     AND rit.invoice_type_id = ri.invoice_type_id
                     AND pll.po_release_id IS NOT NULL; -- BUG 4036472
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20607,
                                            SQLERRM ||
                                            '*******************' ||
                                            ' View 1 CLL_F189_VIEW_PURCHASE_ORDERS not found' ||
                                            '*******************');
                END;
              ELSE
                BEGIN
                  IF (r_invoices.complex_service_flag = 'Y') THEN
                    SELECT COUNT(1)
                      INTO ncountpedidos
                      FROM cll_f189_invoice_lines_iface ril,
                           cll_f189_invoices_interface  ri,
                           po_line_locations_all        pll,
                           po_headers_all               ph,
                           cll_f189_invoice_types       rit
                     WHERE ril.interface_invoice_id =
                           r_invoices.interface_invoice_id
                       AND pll.line_location_id = ril.line_location_id
                       AND ph.po_header_id = pll.po_header_id
                       AND NVL(ril.receipt_flag, 'N') <> 'Y'
                       AND ri.interface_invoice_id =
                           ril.interface_invoice_id
                       AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                           rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
                       AND rit.organization_id = p_organization_id -- BUG 19722064
                          -- Begin BUG 24750424 e 24919430
                          /*
                          --<<BUG 20646945 --Start -->>
                          AND ( (pll.closed_code = 'CLOSED FOR INVOICE'
                            AND EXISTS (SELECT 1
                                          FROM ap_invoices_all inv ,ap_invoice_lines_all invl
                                         WHERE inv.invoice_id = invl.invoice_id
                                           AND invl.po_line_location_id = pll.line_location_id
                                           AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                                           AND invl.tax_already_calculated_flag = 'Y')
                          AND (r_invoices.payment_flag = 'Y'))
                           OR pll.closed_code = 'CLOSED FOR RECEIVING'
                           OR (pll.closed_code = 'CLOSED FOR INVOICE' and r_invoices.payment_flag = 'Y'))
                           */
                          /* AND (DECODE (r_invoices.payment_flag , 'Y',
                              DECODE (NVL (pll.closed_code, 'OPEN')
                                                          , 'OPEN', 'Y'
                                                          , 'CLOSED FOR RECEIVING', 'Y'
                                                          , 'N')
                            , DECODE (NVL (pll.closed_code, 'OPEN')
                                                          , 'OPEN', 'Y'
                                                          , 'CLOSED FOR INVOICE', 'Y'
                                                          , 'CLOSED FOR RECEIVING', 'Y'
                                                          , 'N')) = 'N'
                          OR ph.approved_flag <> 'Y')*/
                          --<< BUG 20646945 --End -->>
                       AND pll.po_release_id IS NULL
                       AND (pll.closed_code IN
                           ('CLOSED',
                             'CLOSE FOR INVOICE',
                             'FINALLY CLOSED' -- BUG 24621425
                             /*,'CLOSED FOR RECEIVING'*/) -- Quando comlex Service a PO fica com STATUS CLOSED FOR RECEIVING
                           OR
                           (pll.line_location_id IN
                           (SELECT invl.po_line_location_id
                                FROM ap_invoices_all      inv,
                                     ap_invoice_lines_all invl
                               WHERE inv.invoice_id = invl.invoice_id
                                 AND inv.invoice_type_lookup_code =
                                     'PREPAYMENT'
                                 AND pll.closed_code = 'CLOSED FOR INVOICE'
                                 AND NVL(inv.amount_paid, 0) = 0)));
                    -- End BUG 24750424 e 24919430
                  ELSE
                    -- ER 7483063 AIrmer 16/04/2009
                    SELECT COUNT(1)
                      INTO ncountpedidos
                      FROM cll_f189_invoice_lines_iface ril,
                           cll_f189_invoices_interface  ri,
                           po_line_locations_all        pll,
                           po_headers_all               ph,
                           cll_f189_invoice_types       rit
                     WHERE ril.interface_invoice_id =
                           r_invoices.interface_invoice_id
                       AND pll.line_location_id = ril.line_location_id
                       AND ph.po_header_id = pll.po_header_id
                       AND NVL(ril.receipt_flag, 'N') <> 'Y'
                       AND ri.interface_invoice_id =
                           ril.interface_invoice_id
                       AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                           rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
                       AND rit.organization_id = p_organization_id -- BUG 19722064
                          -- AND NVL(pll.approved_flag,'N') <> 'Y' -- 23137900
                       AND NVL(PLL.APPROVED_FLAG, 'N') = 'Y' -- 23137900
                          -- Begin BUG 24750424 e 24919430
                          /*
                          --<<BUG 20646945 --Start -->>
                          AND ( (pll.closed_code = 'CLOSED FOR INVOICE'
                            AND EXISTS (SELECT 1
                                          FROM ap_invoices_all inv ,ap_invoice_lines_all invl
                                         WHERE inv.invoice_id = invl.invoice_id
                                           AND invl.po_line_location_id = pll.line_location_id
                                           AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                                           AND invl.tax_already_calculated_flag = 'Y')
                          AND   (r_invoices.payment_flag = 'Y'))
                           OR pll.closed_code = 'CLOSED FOR RECEIVING'
                           OR (pll.closed_code = 'CLOSED FOR INVOICE' and r_invoices.payment_flag = 'Y'))
                           */
                          /* AND (DECODE (r_invoices.payment_flag , 'Y',
                                  DECODE (NVL (pll.closed_code, 'OPEN')
                                                              , 'OPEN', 'Y'
                                                              , 'CLOSED FOR INVOICE', 'Y' -- Bug 18306068
                                                              , 'N')
                                , DECODE (NVL (pll.closed_code, 'OPEN')
                                                              , 'OPEN', 'Y'
                                                              , 'CLOSED FOR INVOICE', 'Y'
                                                              , 'N')) = 'N'
                              OR ph.approved_flag <> 'Y')
                          */
                          --<<BUG 20646945 --End -->>
                       AND pll.po_release_id IS NULL -- BUG 4036472
                       AND (pll.closed_code IN
                           ('CLOSED',
                             'CLOSE FOR INVOICE',
                             'FINALLY CLOSED' -- BUG 24621425
                            ,
                             'CLOSED FOR RECEIVING') -- BUG 24621425
                           OR
                           (pll.line_location_id IN
                           (SELECT invl.po_line_location_id
                                FROM ap_invoices_all      inv,
                                     ap_invoice_lines_all invl
                               WHERE inv.invoice_id = invl.invoice_id
                                 AND inv.invoice_type_lookup_code =
                                     'PREPAYMENT'
                                 AND pll.closed_code = 'CLOSED FOR INVOICE'
                                 AND NVL(inv.amount_paid, 0) = 0)));
                    -- End BUG 24750424 e 24919430
                  END IF; -- ER 7483063 AIrmer 16/04/2009
                  --
                  SELECT COUNT(1)
                    INTO ncounttemreleases
                    FROM cll_f189_invoice_lines_iface ril,
                         cll_f189_invoices_interface  ri,
                         po_line_locations_all        pll,
                         po_headers_all               ph,
                         cll_f189_invoice_types       rit
                   WHERE --RIL.INVOICE_ID = r_invoices.invoice_id  -- Bug 4658115 AIrmer 14/10/2005
                   ril.interface_invoice_id =
                   r_invoices.interface_invoice_id
                  -- Bug 4658115 AIrmer 14/10/2005
                   AND pll.line_location_id = ril.line_location_id
                   AND ph.po_header_id = pll.po_header_id
                   AND NVL(ril.receipt_flag, 'N') <> 'Y'
                   AND ri.invoice_id = ril.invoice_id
                   AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                   rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
                   AND rit.organization_id = p_organization_id -- BUG 19722064
                   AND pll.po_release_id IS NOT NULL; -- BUG 4036472
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20607,
                                            SQLERRM ||
                                            '*******************' ||
                                            ' View 2 CLL_F189_VIEW_PURCHASE_ORDERS (interface) - not found' ||
                                            '*******************');
                END;
              END IF;
            ELSE
              IF p_interface = 'N' THEN
                BEGIN
                  SELECT COUNT(1)
                    INTO ncountpedidos
                    FROM cll_f189_invoice_lines ril,
                         cll_f189_invoices      ri,
                         po_line_locations_all  pll,
                         po_headers_all         ph,
                         cll_f189_invoice_types rit
                   WHERE ril.invoice_id = r_invoices.invoice_id
                     AND pll.line_location_id = ril.line_location_id
                     AND ph.po_header_id = pll.po_header_id
                     AND ri.invoice_id = ril.invoice_id
                     AND rit.invoice_type_id = ri.invoice_type_id
                     AND (pll.closed_code = 'FINALLY CLOSED' OR
                         ph.approved_flag <> 'Y')
                     AND pll.po_release_id IS NULL; -- BUG 4036472
                  --
                  SELECT COUNT(1)
                    INTO ncounttemreleases
                    FROM cll_f189_invoice_lines ril,
                         cll_f189_invoices      ri,
                         po_line_locations_all  pll,
                         po_headers_all         ph,
                         cll_f189_invoice_types rit
                   WHERE ril.invoice_id = r_invoices.invoice_id
                     AND pll.line_location_id = ril.line_location_id
                     AND ph.po_header_id = pll.po_header_id
                     AND ri.invoice_id = ril.invoice_id
                     AND rit.invoice_type_id = ri.invoice_type_id
                     AND pll.po_release_id IS NOT NULL; -- BUG 4036472
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20607,
                                            SQLERRM ||
                                            '*******************' ||
                                            ' View 3 CLL_F189_VIEW_PURCHASE_ORDERS - not found' ||
                                            '*******************');
                END;
              ELSE
                BEGIN

                  SELECT COUNT(1)
                    INTO ncountpedidos
                    FROM cll_f189_invoice_lines_iface ril,
                         cll_f189_invoices_interface  ri,
                         po_line_locations_all        pll,
                         po_headers_all               ph,
                         cll_f189_invoice_types       rit
                   WHERE ril.interface_invoice_id =
                         r_invoices.interface_invoice_id
                     AND pll.line_location_id = ril.line_location_id
                     AND ph.po_header_id = pll.po_header_id
                        --AND ri.invoice_id             =  ril.invoice_id   -- Bug 4658115 AIrmer 14/10/2005
                     AND ri.interface_invoice_id = ril.interface_invoice_id
                        -- Bug 4658115 AIrmer 14/10/2005
                     AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                         rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
                     AND rit.organization_id = p_organization_id -- BUG 19722064
                     AND (pll.closed_code = 'FINALLY CLOSED' OR
                         ph.approved_flag <> 'Y')
                     AND pll.po_release_id IS NULL; -- BUG 4036472

                  SELECT COUNT(1)
                    INTO ncounttemreleases
                    FROM cll_f189_invoice_lines_iface ril,
                         cll_f189_invoices_interface  ri,
                         po_line_locations_all        pll,
                         po_headers_all               ph,
                         cll_f189_invoice_types       rit
                   WHERE
                  -- RIL.INVOICE_ID = r_invoices.invoice_id  -- Bug 4658115 AIrmer 14/10/2005
                   ril.interface_invoice_id =
                   r_invoices.interface_invoice_id
                  -- Bug 4658115 AIrmer 14/10/2005
                   AND pll.line_location_id = ril.line_location_id
                   AND ph.po_header_id = pll.po_header_id
                   AND ri.invoice_id = ril.invoice_id
                   AND rit.organization_id = p_organization_id -- BUG 19722064
                   AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                   rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
                   AND pll.po_release_id IS NOT NULL; -- BUG 4036472
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20607,
                                            SQLERRM ||
                                            '*******************' ||
                                            ' View 4 CLL_F189_VIEW_PURCHASE_ORDERS (interface) not found' ||
                                            '*******************');
                END;
              END IF;
            END IF; -- ER 9017036
          END IF;
          --
          SELECT (1 + NVL(qty_rcv_tolerance, 0) / 100)
            INTO x_qty_rcv_tolerance
            FROM cll_f189_parameters
           WHERE organization_id = p_organization_id;
          --
          IF ncountpedidos > 0 THEN
            -- BUG 4036472
            IF r_invoices.price_adjust_flag = 'N' AND -- BUG 24621425
               r_invoices.tax_adjust_flag = 'N' AND -- BUG 24621425
               r_invoices.cost_adjust_flag = 'N' THEN
              -- BUG 24482800
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'STATUS PURCH INVALID',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'STATUS PURCH INVALID');
              END IF;
            END IF; -- BUG 24482800
            -- BUG 4036472 - Start
          ELSIF ncounttemreleases > 0 THEN
            IF r_invoices.return_customer_flag <> 'F' THEN
              IF r_invoices.price_adjust_flag = 'N' AND -- BUG 24621425
                 r_invoices.tax_adjust_flag = 'N' AND -- BUG 24621425
                 r_invoices.cost_adjust_flag = 'N' THEN
                -- BUG 24482800
                IF p_interface = 'N' THEN
                  BEGIN
                    SELECT COUNT(1)
                      INTO ncountreleases
                      FROM cll_f189_invoice_lines ril,
                           cll_f189_invoices      ri,
                           po_line_locations_all  pll,
                           po_headers_all         ph,
                           cll_f189_invoice_types rit,
                           po_releases_all        pra
                     WHERE ril.invoice_id = r_invoices.invoice_id
                       AND pll.line_location_id = ril.line_location_id
                       AND ph.po_header_id = pll.po_header_id
                       AND NVL(ril.receipt_flag, 'N') <> 'Y'
                       AND ri.invoice_id = ril.invoice_id
                       AND rit.invoice_type_id = ri.invoice_type_id
                       AND pra.po_release_id(+) = pll.po_release_id
                       AND pra.po_header_id(+) = pll.po_header_id
                       AND (pra.approved_flag <> 'Y' --BUG 16283024 - Egini - 19/03/2013
                           OR pra.cancel_flag = 'Y') --BUG 16283024 - Egini - 19/03/2013
                       AND ph.type_lookup_code IN ('BLANKET', 'PLANNED');
                  EXCEPTION
                    WHEN OTHERS THEN
                      ncountreleases := 0;
                  END;
                ELSE
                  BEGIN
                    SELECT COUNT(1)
                      INTO ncountreleases
                      FROM cll_f189_invoice_lines_iface ril,
                           cll_f189_invoices_interface  ri,
                           po_line_locations_all        pll,
                           po_headers_all               ph,
                           cll_f189_invoice_types       rit,
                           po_releases_all              pra
                     WHERE ril.interface_invoice_id =
                           r_invoices.interface_invoice_id
                       AND pll.line_location_id = ril.line_location_id
                       AND ph.po_header_id = pll.po_header_id
                       AND NVL(ril.receipt_flag, 'N') <> 'Y'
                       AND ri.interface_invoice_id =
                           ril.interface_invoice_id
                       AND rit.organization_id = p_organization_id -- BUG 19722064
                       AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                           rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
                       AND pra.po_release_id(+) = pll.po_release_id
                       AND pra.po_header_id(+) = pll.po_header_id
                       AND (pra.approved_flag <> 'Y' --BUG 16283024 - Egini - 19/03/2013
                           OR pra.cancel_flag = 'Y') --BUG 16283024 - Egini - 19/03/2013
                       AND ph.type_lookup_code IN ('BLANKET', 'PLANNED');
                  EXCEPTION
                    WHEN OTHERS THEN
                      ncountreleases := 0;
                  END;
                END IF;
              END IF; -- BUG 24482800
            ELSE
              IF r_invoices.price_adjust_flag = 'N' AND -- BUG 24621425
                 r_invoices.tax_adjust_flag = 'N' AND -- BUG 24621425
                 r_invoices.cost_adjust_flag = 'N' THEN
                -- BUG 24482800
                IF p_interface = 'N' THEN
                  BEGIN
                    SELECT COUNT(1)
                      INTO ncountreleases
                      FROM cll_f189_invoice_lines ril,
                           cll_f189_invoices      ri,
                           po_line_locations_all  pll,
                           po_headers_all         ph,
                           cll_f189_invoice_types rit,
                           po_releases_all        pra
                     WHERE ril.invoice_id = r_invoices.invoice_id
                       AND pll.line_location_id = ril.line_location_id
                       AND ph.po_header_id = pll.po_header_id
                       AND ri.invoice_id = ril.invoice_id
                       AND rit.invoice_type_id = ri.invoice_type_id
                       AND pra.po_release_id(+) = pll.po_release_id
                       AND pra.po_header_id(+) = pll.po_header_id
                       AND (pra.approved_flag <> 'Y' --BUG 16283024 - Egini - 19/03/2013
                           OR pra.cancel_flag = 'Y') --BUG 16283024 - Egini - 19/03/2013
                       AND ph.type_lookup_code IN ('BLANKET', 'PLANNED');
                  EXCEPTION
                    WHEN OTHERS THEN
                      ncountreleases := 0;
                  END;
                ELSE
                  BEGIN
                    SELECT COUNT(1)
                      INTO ncountreleases
                      FROM cll_f189_invoice_lines_iface ril,
                           cll_f189_invoices_interface  ri,
                           po_line_locations_all        pll,
                           po_headers_all               ph,
                           cll_f189_invoice_types       rit,
                           po_releases_all              pra
                     WHERE ril.interface_invoice_id =
                           r_invoices.interface_invoice_id
                       AND pll.line_location_id = ril.line_location_id
                       AND ph.po_header_id = pll.po_header_id
                          -- AND ri.invoice_id             =  ril.invoice_id  -- Bug 4658115 AIrmer 14/10/2005
                       AND ri.interface_invoice_id =
                           ril.interface_invoice_id
                          -- Bug 4658115 AIrmer 14/10/2005
                       AND rit.organization_id = p_organization_id -- BUG 19722064
                       AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                           rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
                       AND pra.po_release_id(+) = pll.po_release_id
                       AND pra.po_header_id(+) = pll.po_header_id
                       AND (pra.approved_flag <> 'Y' --BUG 16283024 - Egini - 19/03/2013
                           OR pra.cancel_flag = 'Y') --BUG 16283024 - Egini - 19/03/2013
                       AND ph.type_lookup_code IN ('BLANKET', 'PLANNED');
                  EXCEPTION
                    WHEN OTHERS THEN
                      ncountreleases := 0;
                  END;
                END IF;
              END IF; -- BUG 24482800
            END IF;
            --
            IF ncountreleases > 0 THEN
              -- Begin BUG 24621425
              IF NVL(r_invoices.tax_adjust_flag, 'N') = 'N' AND
                 NVL(r_invoices.price_adjust_flag, 'N') = 'N' AND
                 NVL(r_invoices.cost_adjust_flag, 'N') = 'N' THEN
                -- End BUG 24621425
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'STATUS RELEASE INVALID',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'STATUS RELEASE INVALID');
                END IF;
              END IF; -- BUG 24621425
            END IF;
          END IF;
          -- BUG 4036472 - End
        END IF;
        --
        -- 23491406 - Start
        IF NVL(r_invoices.tax_adjust_flag, 'N') = 'N' AND -- BUG 24621425
           NVL(r_invoices.price_adjust_flag, 'N') = 'N' AND
           NVL(r_invoices.cost_adjust_flag, 'N') = 'N' THEN
          -- BUG 24482800
          IF (r_invoices.requisition_type = 'PO' AND
             r_invoices.return_customer_flag <> 'F') THEN
            IF p_interface = 'N' THEN
              IF (r_invoices.complex_service_flag = 'Y') THEN
                -- BUG 24750424 e 24919430
                SELECT COUNT(1)
                  INTO l_close_line_po
                  FROM cll_f189_invoice_lines ril,
                       cll_f189_invoices      ri,
                       po_line_locations_all  pll,
                       po_headers_all         ph,
                       cll_f189_invoice_types rit
                 WHERE ril.invoice_id = r_invoices.invoice_id
                   AND pll.line_location_id = ril.line_location_id
                   AND ph.po_header_id = pll.po_header_id
                   AND ri.invoice_id = ril.invoice_id
                   AND rit.invoice_type_id = ri.invoice_type_id
                      -- Begin BUG 24621425
                   AND NVL(ril.receipt_flag, 'N') <> 'Y'
                      /*AND pll.closed_code IN ('CLOSED','CLOSE FOR INVOICE','FINALLY CLOSED'
                      ,'CLOSED FOR INVOICE','CLOSED FOR RECEIVING');*/
                      -- Begin BUG 24750424 e 24919430
                      /*
                      AND ((pll.closed_code = 'CLOSED FOR INVOICE'
                                 AND EXISTS (SELECT 1
                                               FROM ap_invoices_all inv ,
                                                    ap_invoice_lines_all invl
                                              WHERE inv.invoice_id                   = invl.invoice_id
                                                AND invl.po_line_location_id         = pll.line_location_id
                                                AND inv.invoice_type_lookup_code     = 'PREPAYMENT'
                                                AND invl.tax_already_calculated_flag = 'Y')
                               AND (r_invoices.payment_flag = 'Y'))
                                -- OR pll.closed_code = 'CLOSED FOR RECEIVING' -- BUG 24621425
                                OR pll.closed_code IN ('CLOSED','CLOSE FOR INVOICE','FINALLY CLOSED' -- BUG 24621425
                                             ,'CLOSED FOR INVOICE','CLOSED FOR RECEIVING') -- BUG 24621425
                                OR (pll.closed_code = 'CLOSED FOR INVOICE' and r_invoices.payment_flag = 'Y'));
                      -- End BUG 24621425*/
                   AND (pll.closed_code IN
                       ('CLOSED',
                         'CLOSE FOR INVOICE',
                         'FINALLY CLOSED' -- BUG 24621425
                         /*,'CLOSED FOR RECEIVING'*/) -- BUG 24621425
                       OR
                       (pll.line_location_id IN
                       (SELECT invl.po_line_location_id
                            FROM ap_invoices_all      inv,
                                 ap_invoice_lines_all invl
                           WHERE inv.invoice_id = invl.invoice_id
                             AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                             AND pll.closed_code = 'CLOSED FOR INVOICE'
                             AND NVL(inv.amount_paid, 0) = 0)));
                -- End BUG 24750424 e 24919430
                -- BEGIN BUG 24750424 e 24919430
              ELSE
                SELECT COUNT(1)
                  INTO l_close_line_po
                  FROM cll_f189_invoice_lines ril,
                       cll_f189_invoices      ri,
                       po_line_locations_all  pll,
                       po_headers_all         ph,
                       cll_f189_invoice_types rit
                 WHERE ril.invoice_id = r_invoices.invoice_id
                   AND pll.line_location_id = ril.line_location_id
                   AND ph.po_header_id = pll.po_header_id
                   AND ri.invoice_id = ril.invoice_id
                   AND rit.invoice_type_id = ri.invoice_type_id
                      -- Begin BUG 24621425
                   AND NVL(ril.receipt_flag, 'N') <> 'Y'
                      /*AND pll.closed_code IN ('CLOSED','CLOSE FOR INVOICE','FINALLY CLOSED'
                      ,'CLOSED FOR INVOICE','CLOSED FOR RECEIVING');*/
                      -- Begin BUG 24750424 e 24919430
                      /*
                      AND ((pll.closed_code = 'CLOSED FOR INVOICE'
                                 AND EXISTS (SELECT 1
                                               FROM ap_invoices_all inv ,
                                                    ap_invoice_lines_all invl
                                              WHERE inv.invoice_id                   = invl.invoice_id
                                                AND invl.po_line_location_id         = pll.line_location_id
                                                AND inv.invoice_type_lookup_code     = 'PREPAYMENT'
                                                AND invl.tax_already_calculated_flag = 'Y')
                               AND (r_invoices.payment_flag = 'Y'))
                                -- OR pll.closed_code = 'CLOSED FOR RECEIVING' -- BUG 24621425
                                OR pll.closed_code IN ('CLOSED','CLOSE FOR INVOICE','FINALLY CLOSED' -- BUG 24621425
                                             ,'CLOSED FOR INVOICE','CLOSED FOR RECEIVING') -- BUG 24621425
                                OR (pll.closed_code = 'CLOSED FOR INVOICE' and r_invoices.payment_flag = 'Y'));
                      -- End BUG 24621425*/
                   AND (pll.closed_code IN
                       ('CLOSED',
                         'CLOSE FOR INVOICE',
                         'FINALLY CLOSED' -- BUG 24621425
                        ,
                         'CLOSED FOR RECEIVING') -- BUG 24621425
                       OR
                       (pll.line_location_id IN
                       (SELECT invl.po_line_location_id
                            FROM ap_invoices_all      inv,
                                 ap_invoice_lines_all invl
                           WHERE inv.invoice_id = invl.invoice_id
                             AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                             AND pll.closed_code = 'CLOSED FOR INVOICE'
                             AND NVL(inv.amount_paid, 0) = 0)));
                -- End BUG 24750424 e 24919430
              END IF;
              -- END BUG 24750424 e 24919430
            ELSE
              IF (r_invoices.complex_service_flag = 'Y') THEN
                -- BUG 24750424 e 24919430
                SELECT COUNT(1)
                  INTO l_close_line_po
                  FROM cll_f189_invoice_lines_iface ril,
                       cll_f189_invoices_interface  ri,
                       po_line_locations_all        pll,
                       po_headers_all               ph,
                       cll_f189_invoice_types       rit
                 WHERE ril.interface_invoice_id =
                       r_invoices.interface_invoice_id
                   AND pll.line_location_id = ril.line_location_id
                   AND ph.po_header_id = pll.po_header_id
                   AND ri.interface_invoice_id = ril.interface_invoice_id
                   AND rit.invoice_type_id = ri.invoice_type_id
                      -- Begin BUG 24621425
                   AND NVL(ril.receipt_flag, 'N') <> 'Y'
                      /*AND pll.closed_code IN ('CLOSED','CLOSE FOR INVOICE','FINALLY CLOSED'
                      ,'CLOSED FOR INVOICE','CLOSED FOR RECEIVING');*/
                      -- Begin BUG 24750424 e 24919430
                      /*
                      AND ((pll.closed_code = 'CLOSED FOR INVOICE'
                                 AND EXISTS (SELECT 1
                                               FROM ap_invoices_all inv ,
                                                    ap_invoice_lines_all invl
                                              WHERE inv.invoice_id                   = invl.invoice_id
                                                AND invl.po_line_location_id         = pll.line_location_id
                                                AND inv.invoice_type_lookup_code     = 'PREPAYMENT'
                                                AND invl.tax_already_calculated_flag = 'Y')
                               AND (r_invoices.payment_flag = 'Y'))
                                -- OR pll.closed_code = 'CLOSED FOR RECEIVING' -- BUG 24621425
                                OR pll.closed_code IN ('CLOSED','CLOSE FOR INVOICE','FINALLY CLOSED' -- BUG 24621425
                                             ,'CLOSED FOR INVOICE','CLOSED FOR RECEIVING') -- BUG 24621425
                                OR (pll.closed_code = 'CLOSED FOR INVOICE' and r_invoices.payment_flag = 'Y'));
                      -- End BUG 24621425*/
                   AND (pll.closed_code IN
                       ('CLOSED',
                         'CLOSE FOR INVOICE',
                         'FINALLY CLOSED' -- BUG 24621425
                         /*,'CLOSED FOR RECEIVING'*/) -- BUG 24621425
                       OR
                       (pll.line_location_id IN
                       (SELECT invl.po_line_location_id
                            FROM ap_invoices_all      inv,
                                 ap_invoice_lines_all invl
                           WHERE inv.invoice_id = invl.invoice_id
                             AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                             AND pll.closed_code = 'CLOSED FOR INVOICE'
                             AND NVL(inv.amount_paid, 0) = 0)));
                -- End BUG 24750424 e 24919430
                -- BEGIN BUG 24750424 e 24919430
              ELSE
                SELECT COUNT(1)
                  INTO l_close_line_po
                  FROM cll_f189_invoice_lines_iface ril,
                       cll_f189_invoices_interface  ri,
                       po_line_locations_all        pll,
                       po_headers_all               ph,
                       cll_f189_invoice_types       rit
                 WHERE ril.interface_invoice_id =
                       r_invoices.interface_invoice_id
                   AND pll.line_location_id = ril.line_location_id
                   AND ph.po_header_id = pll.po_header_id
                   AND ri.interface_invoice_id = ril.interface_invoice_id
                   AND rit.invoice_type_id = ri.invoice_type_id
                      -- Begin BUG 24621425
                   AND NVL(ril.receipt_flag, 'N') <> 'Y'
                      /*AND pll.closed_code IN ('CLOSED','CLOSE FOR INVOICE','FINALLY CLOSED'
                      ,'CLOSED FOR INVOICE','CLOSED FOR RECEIVING');*/
                      -- Begin BUG 24750424 e 24919430
                      /*
                      AND ((pll.closed_code = 'CLOSED FOR INVOICE'
                                 AND EXISTS (SELECT 1
                                               FROM ap_invoices_all inv ,
                                                    ap_invoice_lines_all invl
                                              WHERE inv.invoice_id                   = invl.invoice_id
                                                AND invl.po_line_location_id         = pll.line_location_id
                                                AND inv.invoice_type_lookup_code     = 'PREPAYMENT'
                                                AND invl.tax_already_calculated_flag = 'Y')
                               AND (r_invoices.payment_flag = 'Y'))
                                -- OR pll.closed_code = 'CLOSED FOR RECEIVING' -- BUG 24621425
                                OR pll.closed_code IN ('CLOSED','CLOSE FOR INVOICE','FINALLY CLOSED' -- BUG 24621425
                                             ,'CLOSED FOR INVOICE','CLOSED FOR RECEIVING') -- BUG 24621425
                                OR (pll.closed_code = 'CLOSED FOR INVOICE' and r_invoices.payment_flag = 'Y'));
                      -- End BUG 24621425*/
                   AND (pll.closed_code IN
                       ('CLOSED',
                         'CLOSE FOR INVOICE',
                         'FINALLY CLOSED' -- BUG 24621425
                        ,
                         'CLOSED FOR RECEIVING') -- BUG 24621425
                       OR
                       (pll.line_location_id IN
                       (SELECT invl.po_line_location_id
                            FROM ap_invoices_all      inv,
                                 ap_invoice_lines_all invl
                           WHERE inv.invoice_id = invl.invoice_id
                             AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                             AND pll.closed_code = 'CLOSED FOR INVOICE'
                             AND NVL(inv.amount_paid, 0) = 0)));
                -- End BUG 24750424 e 24919430
              END IF;
              -- END BUG 24750424 e 24919430
            END IF;
            --
            IF l_close_line_po > 0 THEN
              IF NVL(r_invoices.tax_adjust_flag, 'N') = 'N' AND -- BUG 24621425
                 NVL(r_invoices.price_adjust_flag, 'N') = 'N' AND
                 NVL(r_invoices.cost_adjust_flag, 'N') = 'N' THEN
                -- BUG 24482800
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'STATUS PURCH INVALID',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'STATUS PURCH INVALID');
                END IF;
              END IF; -- BUG 24621425
            END IF;
            -- Begin BUG 24750424 e 24919430
          ELSIF (r_invoices.requisition_type = 'PO' AND
                r_invoices.return_customer_flag = 'F') THEN
            IF p_interface = 'N' THEN
              SELECT COUNT(1)
                INTO l_close_line_po
                FROM cll_f189_invoice_lines ril,
                     cll_f189_invoices      ri,
                     po_line_locations_all  pll,
                     po_headers_all         ph,
                     cll_f189_invoice_types rit
               WHERE ril.invoice_id = r_invoices.invoice_id
                 AND pll.line_location_id = ril.line_location_id
                 AND ph.po_header_id = pll.po_header_id
                 AND ri.invoice_id = ril.invoice_id
                 AND rit.invoice_type_id = ri.invoice_type_id
                    -- Begin BUG 24621425
                 AND NVL(ril.receipt_flag, 'N') <> 'Y'
                    -- Begin BUG 24750424 e 24919430
                 AND (pll.closed_code IN
                     ('CLOSED',
                       'CLOSE FOR INVOICE',
                       'FINALLY CLOSED' -- BUG 24621425
                       /*,'CLOSED FOR RECEIVING'*/) -- BUG 24621425
                     AND (pll.closed_code = 'CLOSED FOR RECEIVING' and
                     rit.return_customer_flag = 'F') OR
                     (pll.line_location_id IN
                     (SELECT invl.po_line_location_id
                          FROM ap_invoices_all      inv,
                               ap_invoice_lines_all invl
                         WHERE inv.invoice_id = invl.invoice_id
                           AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                           AND pll.closed_code = 'CLOSED FOR INVOICE'
                           AND NVL(inv.amount_paid, 0) = 0)));
              -- End BUG 24750424 e 24919430
            ELSE
              SELECT COUNT(1)
                INTO l_close_line_po
                FROM cll_f189_invoice_lines_iface ril,
                     cll_f189_invoices_interface  ri,
                     po_line_locations_all        pll,
                     po_headers_all               ph,
                     cll_f189_invoice_types       rit
               WHERE ril.interface_invoice_id =
                     r_invoices.interface_invoice_id
                 AND pll.line_location_id = ril.line_location_id
                 AND ph.po_header_id = pll.po_header_id
                 AND ri.interface_invoice_id = ril.interface_invoice_id
                 AND rit.invoice_type_id = ri.invoice_type_id
                    -- Begin BUG 24621425
                 AND NVL(ril.receipt_flag, 'N') <> 'Y'
                 AND (pll.closed_code IN
                     ('CLOSED',
                       'CLOSE FOR INVOICE',
                       'FINALLY CLOSED' -- BUG 24621425
                       /*,'CLOSED FOR RECEIVING'*/) -- BUG 24621425
                     AND (pll.closed_code = 'CLOSED FOR RECEIVING' and
                     rit.return_customer_flag = 'F') OR
                     (pll.line_location_id IN
                     (SELECT invl.po_line_location_id
                          FROM ap_invoices_all      inv,
                               ap_invoice_lines_all invl
                         WHERE inv.invoice_id = invl.invoice_id
                           AND inv.invoice_type_lookup_code = 'PREPAYMENT'
                           AND pll.closed_code = 'CLOSED FOR INVOICE'
                           AND NVL(inv.amount_paid, 0) = 0)));
              -- End BUG 24750424 e 24919430
            END IF;
            --
            IF l_close_line_po > 0 THEN
              IF NVL(r_invoices.tax_adjust_flag, 'N') = 'N' AND -- BUG 24621425
                 NVL(r_invoices.price_adjust_flag, 'N') = 'N' AND
                 NVL(r_invoices.cost_adjust_flag, 'N') = 'N' THEN
                -- BUG 24482800
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'STATUS PURCH INVALID',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'STATUS PURCH INVALID');
                END IF;
              END IF; -- BUG 24621425
            END IF;
          END IF;
          -- End BUG 24750424 e 24919430
        END IF; --  -- BUG 24621425
        -- 23491406 - End
        --
        BEGIN
          -- Bug Bug 12898953/Bug 12403264 - lmedeiro - 05/sep/2011 - Inicio
          -- Bug 12403264 - SSimoes - 09/may/2011 - Inicio
          /*
           EXECUTE IMMEDIATE    'SELECT 1 FROM cll_f189_invoice_types,gl_code_combinations'
                             || ' WHERE invoice_type_id = :b1'
                             || ' AND code_combination_id IN (cr_code_combination_id, ir_code_combination_id,'
                             || 'icms_code_combination_id, iss_code_combination_id,'
                             || 'ipi_code_combination_id, diff_icms_code_combination_id)'
                             || ' AND '
                             || p_segment
                             || ' <> :b2'
                             || ' AND ROWNUM=1'
                        INTO v_account_seg
                       USING r_invoices.invoice_type_id, v_balance_seg;


           EXECUTE IMMEDIATE    'SELECT 1 '
                             || ' FROM gl_code_combinations'
                             || ' WHERE code_combination_id IN'
                             || ' (select cr_code_combination_id from cll_f189_invoice_types where invoice_type_id = :b1'
                             || ' UNION select ir_code_combination_id from cll_f189_invoice_types where invoice_type_id = :b1'
                             || ' UNION select icms_code_combination_id from cll_f189_invoice_types where invoice_type_id = :b1'
                             || ' UNION select iss_code_combination_id from cll_f189_invoice_types where invoice_type_id = :b1'
                             || ' UNION select ipi_code_combination_id from cll_f189_invoice_types where invoice_type_id = :b1'
                             || ' UNION select diff_icms_code_combination_id from cll_f189_invoice_types where invoice_type_id = :b1 )'
                             || ' AND '
                             || p_segment
                             || ' <> :b2'
                             || ' AND ROWNUM=1'
                        INTO v_account_seg
                       USING r_invoices.invoice_type_id, v_balance_seg;
          -- Bug 12403264 - SSimoes - 09/may/2011 - Fim
          */
          EXECUTE IMMEDIATE 'SELECT 1 FROM gl_code_combinations' ||
                            ' WHERE code_combination_id IN (:b1,:b2,' ||
                            ':b3, :b4,' || ':b5, :b6)' || ' AND ' ||
                            p_segment || ' <> :b7' || ' AND ROWNUM=1'
            INTO v_account_seg
            USING r_invoices.cr_code_combination_id, r_invoices.ir_code_combination_id, r_invoices.icms_code_combination_id, r_invoices.iss_code_combination_id, r_invoices.ipi_code_combination_id, r_invoices.diff_icms_code_combination_id, v_balance_seg;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_account_seg := 0;
          WHEN OTHERS THEN
            NULL;
            -- Bug Bug 12898953/Bug 12403264 - lmedeiro - 05/sep/2011 - Fim
        END;
        --
        -- Bug 16601192 Start
        /*
        BEGIN
           BEGIN
              SELECT rit.encumbrance_flag
                INTO cvalidaempERo
                FROM cll_f189_invoice_types rit
               WHERE rit.invoice_type_id = r_invoices.invoice_type_id
                 AND rit.requisition_type = 'PO';
           EXCEPTION
              WHEN OTHERS
              THEN
                 cvalidaempERo := 'N';
           END;
           IF (cvalidaempERo = 'S')
           THEN
              IF p_interface = 'N'
              THEN
                 BEGIN
                    SELECT COUNT (1)
                      INTO ncountempERo
                      FROM po_distributions_all pda,
                           cll_f189_invoice_lines ril
                     WHERE ril.invoice_id = r_invoices.invoice_id
                       AND pda.line_location_id = ril.line_location_id
                       AND pda.budget_account_id IS NULL;
                 EXCEPTION
                    WHEN OTHERS
                    THEN
                       ncountempERo := 1;
                 END;
              ELSE
                 BEGIN
                    SELECT COUNT (1)
                      INTO ncountempERo
                      FROM po_distributions_all pda,
                           cll_f189_invoice_lines_iface ril
                     WHERE ril.interface_invoice_id =
                                           r_invoices.interface_invoice_id
                       AND pda.line_location_id = ril.line_location_id
                       AND pda.budget_account_id IS NULL;
                 EXCEPTION
                    WHEN OTHERS
                    THEN
                       ncountempERo := 1;
                 END;
              END IF;
              IF (ncountempERo > 0)
              THEN
                 IF p_interface = 'N'
                 THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold
                                                  (p_operation_id,
                                                   p_organization_id,
                                                   p_location_id,
                                                   'DIV UTL ENCUMBRANCE',
                                                   r_invoices.invoice_id,
                                                   NULL
                                                  );
                 ELSE
                    cll_f189_check_holds_pkg.incluir_erro
                                        (r_invoices.interface_invoice_id,
                                         p_operation_id,
                                         'DIV UTL ENCUMBRANCE'
                                        );
                 END IF;
              END IF;
           END IF;
        END;
        */
        -- Bug 16601192 End
        -- ER 14124731 - Start
      --IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'Y' THEN                 -- 27579747
        IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
        AND p_interface = 'Y' THEN                                                     -- 27579747
          NULL;
        ELSE
          -- ER 14124731 - End
          IF UPPER(r_invoices.icms_type) <> 'INV LINES INF' THEN
            -- ER 9028781
            --  ICMS ST
            BEGIN
              ntotnficmsbase   := r_invoices.icms_st_base;
              ntotnficmsamount := r_invoices.icms_st_amount;
              --
              IF p_interface = 'N' THEN
                BEGIN
                  SELECT NVL(SUM(icms_st_amount), 0),
                         NVL(SUM(icms_st_base), 0)
                    INTO x_sum_icms_st_amount, nsumlinicmsbase
                    FROM cll_f189_invoice_lines
                   WHERE invoice_id = r_invoices.invoice_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20607,
                                            SQLERRM ||
                                            '*** Error: ICMS ST ****');
                END;
              ELSE
                BEGIN
                  SELECT NVL(SUM(icms_st_amount), 0),
                         NVL(SUM(icms_st_base), 0)
                    INTO x_sum_icms_st_amount, nsumlinicmsbase
                    FROM CLL_F189_INVOICE_LINES_IFACE
                   WHERE interface_invoice_id =
                         r_invoices.interface_invoice_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20607,
                                            SQLERRM ||
                                            '*** Error: ICMS ST ****');
                END;
              END IF;
              --
              IF r_invoices.icms_type <> 'EARLY SUBSTITUTE' THEN
                -- ER 4509645 --

                IF (ROUND(ntotnficmsbase, arr) <>
                   ROUND(nsumlinicmsbase, arr) AND
                   TRUNC(ntotnficmsbase, arr) <>
                   TRUNC(nsumlinicmsbase, arr)) THEN

                  IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'ICMS BASE ST LIN DIFF NF',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                          p_operation_id,
                                                          'ICMS BASE ST LIN DIFF NF');
                  END IF;

                END IF;
                --
                IF (ROUND(ntotnficmsamount, arr) <>
                   ROUND(x_sum_icms_st_amount, arr) AND
                   TRUNC(ntotnficmsamount, arr) <>
                   TRUNC(x_sum_icms_st_amount, arr)) THEN

                  IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'ICMS AMOUNT ST LIN DIF.NF',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                          p_operation_id,
                                                          'ICMS AMOUNT ST LIN DIF.NF');
                  END IF;
                END IF;
              END IF; -- ER 4509645 --
            END;
          ELSIF UPPER(r_invoices.icms_type) = 'INV LINES INF' THEN
            --  ICMS ST
            BEGIN
              ntotnficmsamount := r_invoices.icms_st_amount;
              --
              IF p_interface = 'N' THEN
                BEGIN
                  SELECT NVL(SUM(icms_st_amount), 0)
                    INTO x_sum_icms_st_amount
                    FROM cll_f189_invoice_lines
                   WHERE invoice_id = r_invoices.invoice_id
                     AND icms_type = 'SUBSTITUTE';
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20609,
                                            SQLERRM ||
                                            '*** Error: ICMS ST ****');
                END;
              ELSE
                BEGIN
                  SELECT NVL(SUM(icms_st_amount), 0)
                    INTO x_sum_icms_st_amount
                    FROM CLL_F189_INVOICE_LINES_IFACE
                   WHERE interface_invoice_id =
                         r_invoices.interface_invoice_id
                     AND icms_type = 'SUBSTITUTE';
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20609,
                                            SQLERRM ||
                                            '*** Error: ICMS ST ****');
                END;
              END IF;
              --
              IF (ROUND(ntotnficmsamount, arr) <>
                 ROUND(x_sum_icms_st_amount, arr) AND
                 TRUNC(ntotnficmsamount, arr) <>
                 TRUNC(x_sum_icms_st_amount, arr)) THEN

                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'ICMS AMOUNT ST LIN DIF.NF',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'ICMS AMOUNT ST LIN DIF.NF');
                END IF;
              END IF;
            END;
          END IF; -- ER 9028781
        END IF; -- ER 14124731
        --
        IF r_invoices.inss_substitute_flag IN ('S', 'D') AND
           r_invoices.inss_amount IS NULL THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'ERROR INSS SUB',
                                                       r_invoices.invoice_id,
                                                       NULL);
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                  p_operation_id,
                                                  'ERROR INSS SUB');
          END IF;
        END IF;
        -- IR_VENDOR
        IF NVL(r_invoices.ir_vendor, '4') = '1' THEN
          v_ir_amount := NVL(r_invoices.ir_amount, 0);
        ELSE
          v_ir_amount := 0;
        END IF;
        --
        IF (l_allow_mult_bal_segs = 'N') THEN
          -- ER 6399212 AIrmer 26/12/2007
          IF v_account_seg > 0 THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ERROR BALANCE INVTYPE',
                                                         r_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'ERROR BALANCE INVTYPE');
            END IF;
          END IF;
        END IF; -- ER 6399212 AIrmer 26/12/2007
        IF v_tolerance_code = 'REJECT' AND
           r_invoices.requisition_type = 'PO' THEN
          --
          BEGIN
            IF r_invoices.source_items <> '1' THEN
              IF p_interface = 'N' THEN
                -- ER 11820206 - Start
                /*   SELECT   SUM (ril.quantity * ril.unit_price)
                      - SUM
                           (DECODE
                               (ri.source_items,
                                1, ril.quantity * ril.unit_price,
                                  pll.quantity
                                * DECODE
                                     (r_invoices.user_defined_conversion_rate,
                                      NULL, pll.price_override,
                                        pll.price_override
                                      / r_invoices.user_defined_conversion_rate
                                     )
                               )
                           )
                 INTO v_divergencia
                 FROM cll_f189_invoice_lines ril,
                      cll_f189_invoices ri,
                      po_line_locations_all pll
                WHERE ril.line_location_id = pll.line_location_id
                  AND ril.invoice_id = ri.invoice_id
                  AND ri.invoice_id = r_invoices.invoice_id;  */

                DECLARE
                  CURSOR c_uom_ri IS
                    SELECT ril.uom ri_uom,
                           ril.unit_price,
                           ril.item_id,
                           ril.quantity,
                           ri.source_items,
                           pll.line_location_id,
                           pll.unit_meas_lookup_code po_uom,
                           pll.price_override,
                           (pll.quantity *
                           (1 + v_rcv_tolerance_percent / 100)) po_quantity
                      FROM cll_f189_invoice_lines ril,
                           po_line_locations_all  pll,
                           cll_f189_invoices      ri
                     WHERE pll.line_location_id = ril.line_location_id
                       AND ril.invoice_id = ri.invoice_id
                       AND ri.invoice_id = r_invoices.invoice_id
                       AND ril.uom <> pll.unit_meas_lookup_code;

                  l_divergencia_uom  NUMBER := 0;
                  l_div_conv         NUMBER := 0;
                  l_raise_conversion BOOLEAN := FALSE;
                  l_unit_price_conv  NUMBER;
                  l_quantity_conv    NUMBER;
                  l_status           VARCHAR2(30);

                BEGIN
                  SELECT count(1)
                    INTO l_uom_diff
                    FROM cll_f189_invoice_lines ril,
                         po_line_locations_all  pll
                   WHERE ril.line_location_id = pll.line_location_id
                     AND ril.invoice_id = r_invoices.invoice_id
                     AND ril.uom <> pll.unit_meas_lookup_code;
                  --
                  IF NVL(l_uom_diff, 0) > 0 THEN
                    FOR r_uom_ri IN c_uom_ri LOOP
                      l_unit_price_conv := r_uom_ri.unit_price;
                      l_quantity_conv   := r_uom_ri.quantity;
                      l_status          := NULL;
                      -- Inicio BUG 20387571
                      BEGIN
                        SELECT unit_of_measure
                          INTO l_unit_of_measure
                          FROM mtl_units_of_measure_vl
                         WHERE unit_of_measure = r_uom_ri.ri_uom;
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          l_unit_of_measure := null;
                      END;
                      --
                      IF l_unit_of_measure is null THEN
                        BEGIN
                          SELECT unit_of_measure
                            INTO x_unit_of_measure
                            FROM MTL_UNITS_OF_MEASURE_TL
                           WHERE unit_of_measure_tl = r_uom_ri.ri_uom;
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                            x_unit_of_measure := NULL;
                        END;
                      ELSE
                        x_unit_of_measure := l_unit_of_measure;
                      END IF;
                      --
                      -- Fim BUG 20387571
                      cll_f189_uom_pkg.uom_conversion(p_from_uom   => x_unit_of_measure --r_uom_ri.ri_uom -- BUG 20387571
                                                     ,
                                                      p_to_uom     => r_uom_ri.po_uom,
                                                      p_item_id    => r_uom_ri.item_id,
                                                      p_unit_price => l_unit_price_conv,
                                                      p_quantity   => l_quantity_conv,
                                                      p_status     => l_status);
                      --
                      IF l_status = 'CONV OK' THEN
                        SELECT (l_quantity_conv * l_unit_price_conv) -
                               (DECODE(r_uom_ri.source_items,
                                       1,
                                       l_quantity_conv * l_unit_price_conv,
                                       l_quantity_conv *
                                       DECODE(r_invoices.user_defined_conversion_rate,
                                              NULL,
                                              r_uom_ri.price_override,
                                              r_uom_ri.price_override /
                                              r_invoices.user_defined_conversion_rate)))
                          INTO l_div_conv
                          FROM DUAL;
                        l_divergencia_uom := (l_divergencia_uom +
                                             l_div_conv);
                      ELSIF (l_status = 'INVALID UOM') OR
                            (l_status = 'UOM ERROR') THEN
                        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                   p_organization_id,
                                                                   p_location_id,
                                                                   'NO UOM',
                                                                   r_invoices.invoice_id,
                                                                   NULL);
                      ELSIF l_status = 'NO CONV UOM' THEN
                        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                   p_organization_id,
                                                                   p_location_id,
                                                                   'INVALID UOM CONV',
                                                                   r_invoices.invoice_id,
                                                                   NULL);
                      ELSIF l_status = 'CONV NULL' THEN
                        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                   p_organization_id,
                                                                   p_location_id,
                                                                   'CONV NOT NULL',
                                                                   r_invoices.invoice_id,
                                                                   NULL);
                      ELSIF l_status = 'CONV ERROR' THEN
                        l_raise_conversion := TRUE;
                      END IF;
                    END LOOP;
                  END IF;
                  --
                  -- 25461628 - Start
                  /*SELECT NVL(SUM (ril.quantity * ril.unit_price) -
                         SUM (DECODE (ri.source_items,1, ril.quantity * ril.unit_price, pll.quantity *
                              DECODE (r_invoices.user_defined_conversion_rate, NULL, pll.price_override,
                                 pll.price_override / r_invoices.user_defined_conversion_rate))),0)
                  INTO v_divergencia
                  FROM cll_f189_invoice_lines ril
                     , cll_f189_invoices      ri
                     , po_line_locations_all  pll
                  WHERE ril.line_location_id = pll.line_location_id
                    AND ril.invoice_id = ri.invoice_id
                    AND ri.invoice_id = r_invoices.invoice_id
                    AND ril.uom = pll.unit_meas_lookup_code;
                  v_divergencia := v_divergencia + l_divergencia_uom;*/

                  BEGIN
                    SELECT NVL(SUM(ril.quantity * ril.unit_price), 0)
                      INTO l_total_ri
                      FROM cll_f189_invoice_lines ril, cll_f189_invoices ri
                     WHERE ril.invoice_id = ri.invoice_id
                       AND ri.invoice_id = r_invoices.invoice_id;
                  EXCEPTION
                    WHEN others THEN
                      l_total_ri := 0;
                  END;
                  --
                  BEGIN
                    SELECT NVL(SUM(pll.quantity *
                                   DECODE(r_invoices.user_defined_conversion_rate,
                                          NULL,
                                          pll.price_override,
                                          pll.price_override /
                                          r_invoices.user_defined_conversion_rate)),
                               0)
                      INTO l_total_po
                      FROM po_line_locations_all pll
                     WHERE pll.line_location_id IN
                           (SELECT ril.line_location_id
                              FROM cll_f189_invoices      ri,
                                   cll_f189_invoice_lines ril
                             WHERE ri.invoice_id = r_invoices.invoice_id
                               AND ri.invoice_id = ril.invoice_id);
--                               AND ril.uom = pll.unit_meas_lookup_code); /* 27267469 */
                  EXCEPTION
                    WHEN others THEN
                      l_total_po := 0;
                  END;
                  --
                  v_divergencia := (l_total_ri - l_total_po) +
                                   l_divergencia_uom;
                  -- 25461628 - End
                EXCEPTION
                  WHEN others THEN
                    NULL;
                END;
                -- ER 11820206 - End
              ELSE
                -- ER 11820206 - Start
                /*   SELECT   SUM (ril.quantity * ril.unit_price)
                      - SUM
                           (DECODE
                               (ri.source_items,
                                1, ril.quantity * ril.unit_price,
                                  pll.quantity
                                * DECODE
                                     (r_invoices.user_defined_conversion_rate,
                                      NULL, pll.price_override,
                                        pll.price_override
                                      / r_invoices.user_defined_conversion_rate
                                     )
                               )
                           )
                 INTO v_divergencia
                 FROM cll_f189_invoice_lines_iface    ril,
                      cll_f189_invoices_interface ri,
                      po_line_locations_all pll
                WHERE ril.line_location_id = pll.line_location_id
                  AND ril.interface_invoice_id = ri.interface_invoice_id
                  AND ri.interface_invoice_id = r_invoices.interface_invoice_id;   */
                DECLARE
                  CURSOR c_uom_ri IS
                    SELECT ril.uom                   ri_uom,
                           ril.unit_price,
                           ril.item_id,
                           ril.quantity,
                           pll.line_location_id,
                           pll.unit_meas_lookup_code po_uom,
                           ri.source_items,
                           pll.price_override
                      FROM cll_f189_invoice_lines_iface ril,
                           po_line_locations_all        pll,
                           cll_f189_invoices_interface  ri
                     WHERE pll.line_location_id = ril.line_location_id
                          -- Begin Bug 26330321
                          /*
                          AND ril.invoice_id       =  ri.invoice_id
                          AND ri.invoice_id        =  r_invoices.invoice_id*/
                       AND ril.interface_invoice_id =
                           ri.interface_invoice_id
                       AND ri.interface_invoice_id =
                           r_invoices.interface_invoice_id
                          -- End Bug 26330321
                       AND ril.uom <> pll.unit_meas_lookup_code;
                  l_divergencia_uom  NUMBER := 0;
                  l_div_conv         NUMBER := 0;
                  l_raise_conversion BOOLEAN := FALSE;
                  l_unit_price_conv  NUMBER;
                  l_quantity_conv    NUMBER;
                  l_status           VARCHAR2(30);
                BEGIN
                  SELECT count(1)
                    INTO l_uom_diff
                    FROM cll_f189_invoice_lines_iface ril,
                         po_line_locations_all        pll
                   WHERE ril.line_location_id = pll.line_location_id
                        -- Begin Bug 26330321
                        --AND ril.invoice_id       =  r_invoices.invoice_id
                     AND ril.interface_invoice_id =
                         r_invoices.interface_invoice_id
                        -- End Bug 26330321
                     AND ril.uom <> pll.unit_meas_lookup_code;
                  IF NVL(l_uom_diff, 0) > 0 THEN
                    FOR r_uom_ri IN c_uom_ri LOOP
                      l_unit_price_conv := r_uom_ri.unit_price;
                      l_quantity_conv   := r_uom_ri.quantity;
                      l_status          := NULL;
                      -- Inicio BUG 20387571
                      BEGIN
                        SELECT unit_of_measure
                          INTO l_unit_of_measure
                          FROM mtl_units_of_measure_vl
                         WHERE unit_of_measure = r_uom_ri.ri_uom;
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          l_unit_of_measure := null;
                      END;
                      --
                      IF l_unit_of_measure is null THEN
                        BEGIN
                          SELECT unit_of_measure
                            INTO x_unit_of_measure
                            FROM MTL_UNITS_OF_MEASURE_TL
                           WHERE unit_of_measure_tl = r_uom_ri.ri_uom;
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                            x_unit_of_measure := NULL;
                        END;
                      ELSE
                        x_unit_of_measure := l_unit_of_measure;
                      END IF;
                      --
                      -- Fim BUG 20387571
                      cll_f189_uom_pkg.uom_conversion(p_from_uom   => x_unit_of_measure --r_uom_ri.ri_uom -- BUG 20387571
                                                     ,
                                                      p_to_uom     => r_uom_ri.po_uom,
                                                      p_item_id    => r_uom_ri.item_id,
                                                      p_unit_price => l_unit_price_conv,
                                                      p_quantity   => l_quantity_conv,
                                                      p_status     => l_status);
                      IF l_status = 'CONV OK' THEN
                        SELECT (l_quantity_conv * l_unit_price_conv) -
                               (DECODE(r_uom_ri.source_items,
                                       1,
                                       l_quantity_conv * l_unit_price_conv,
                                       l_quantity_conv *
                                       DECODE(r_invoices.user_defined_conversion_rate,
                                              NULL,
                                              r_uom_ri.price_override,
                                              r_uom_ri.price_override /
                                              r_invoices.user_defined_conversion_rate)))
                          INTO l_div_conv
                          FROM DUAL;
                        l_divergencia_uom := (l_divergencia_uom +
                                             l_div_conv);
                      ELSIF (l_status = 'INVALID UOM') OR
                            (l_status = 'UOM ERROR') THEN
                        cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                              p_operation_id,
                                                              'NO UOM');
                      ELSIF l_status = 'NO CONV UOM' THEN
                        cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                              p_operation_id,
                                                              'INVALID UOM CONV');
                      ELSIF l_status = 'CONV NULL' THEN
                        cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                              p_operation_id,
                                                              'CONV NOT NULL');
                      ELSIF l_status = 'CONV ERROR' THEN
                        l_raise_conversion := TRUE;
                      END IF;
                    END LOOP;
                  END IF;
                  --
                  -- 25461628 - Start
                  /*SELECT   NVL(SUM (ril.quantity * ril.unit_price)
                             - SUM(DECODE(ri.source_items,1, ril.quantity * ril.unit_price,pll.quantity *
                               DECODE(r_invoices.user_defined_conversion_rate,NULL, pll.price_override,
                                      pll.price_override / r_invoices.user_defined_conversion_rate))),0)
                  INTO v_divergencia
                  FROM cll_f189_invoice_lines_iface    ril,
                       cll_f189_invoices_interface ri,
                       po_line_locations_all pll
                  WHERE ril.line_location_id = pll.line_location_id
                    AND ril.interface_invoice_id = ri.interface_invoice_id
                    AND ri.interface_invoice_id = r_invoices.interface_invoice_id
                    AND ril.uom = pll.unit_meas_lookup_code;
                  v_divergencia := v_divergencia + l_divergencia_uom;*/

                  BEGIN
                    SELECT NVL(SUM(ril.quantity * ril.unit_price), 0)
                      INTO l_total_ri
                      FROM cll_f189_invoices_interface  ri,
                           cll_f189_invoice_lines_iface ril
                     WHERE ri.interface_invoice_id =
                           r_invoices.interface_invoice_id
                       AND ril.interface_invoice_id =
                           ri.interface_invoice_id;
                  EXCEPTION
                    WHEN others THEN
                      l_total_ri := 0;
                  END;
                  --
                  BEGIN
                    SELECT NVL(SUM(pll.quantity *
                                   DECODE(r_invoices.user_defined_conversion_rate,
                                          NULL,
                                          pll.price_override,
                                          pll.price_override /
                                          r_invoices.user_defined_conversion_rate)),
                               0)
                      INTO l_total_po
                      FROM po_line_locations_all pll
                     WHERE pll.line_location_id IN
                           (SELECT ril.line_location_id
                              FROM cll_f189_invoices_interface  ri,
                                   cll_f189_invoice_lines_iface ril
                             WHERE ri.interface_invoice_id =
                                   r_invoices.interface_invoice_id
                               AND ri.interface_invoice_id =
                                   ril.interface_invoice_id);
--                               AND ril.uom = pll.unit_meas_lookup_code); /* 27267469 */
                  EXCEPTION
                    WHEN others THEN
                      l_total_po := 0;
                  END;

                  v_divergencia := (l_total_ri - l_total_po) +
                                   l_divergencia_uom;
                  -- 25461628 - End
                EXCEPTION
                  WHEN others THEN
                    NULL;
                END;
                -- ER 11820206 - End

              END IF;
              -- ER 11820206 - Start
              IF (l_raise_conversion) THEN
                -- TRUE
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NO VERIFY TOLERANCE',
                                                             r_invoices.invoice_id,
                                                             NULL);
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NO VERIFY TOLERANCE');
                END IF;
              ELSE
                -- ER 11820206 - End
                IF v_divergencia > v_tolerance_amount THEN
                  IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'TOLERANCE AMOUNT EXCEEDED',
                                                               r_invoices.invoice_id,
                                                               NULL);
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                          p_operation_id,
                                                          'TOLERANCE AMOUNT EXCEEDED');
                  END IF;
                END IF;
              END IF; -- ER 11820206
            END IF; -- r_invoices.source_items <> 1
          END;
        END IF;
        --
        BEGIN
          IF p_interface = 'N' THEN
            SELECT COUNT(1)
              INTO v_count
              FROM cll_f189_invoice_lines
             WHERE invoice_id = r_invoices.invoice_id;
          ELSE
            SELECT COUNT(1)
              INTO v_count
              FROM CLL_F189_INVOICE_LINES_IFACE
             WHERE interface_invoice_id = r_invoices.interface_invoice_id;
          END IF;
        END;
        --
        IF v_count = 0 THEN
          IF p_interface = 'N' THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'NONE INVOICE LINE',
                                                       r_invoices.invoice_id,
                                                       '');
          ELSE
            cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                  p_operation_id,
                                                  'NONE INVOICE LINE');
          END IF;
        ELSE
          BEGIN
            IF p_interface = 'N' THEN
              SELECT COUNT(1)
                INTO v_count
                FROM cll_f189_invoice_lines
               WHERE invoice_id = r_invoices.invoice_id
                 AND ipi_amount IS NULL
                 AND total_amount IS NULL;
            ELSE
              SELECT COUNT(1)
                INTO v_count
                FROM CLL_F189_INVOICE_LINES_IFACE
               WHERE interface_invoice_id = r_invoices.interface_invoice_id
                 AND ipi_amount IS NULL
                 AND total_amount IS NULL;
            END IF;
          END;
          --
          IF v_count > 0 AND
             (NVL(r_invoices.permanent_active_credit_flag, 'N') = 'N') THEN
            -- ERancement 4378189 AIrmer 27/07/2005
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'INVLINE WITHOUT TAXES',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
            --IF l_source <> 'CLL_F369 EFD LOADER' THEN                                               -- 27579747
              IF l_source NOT IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') THEN -- 27579747
                -- BUG 21909282
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVLINE WITHOUT TAXES');
              END IF; -- BUG 21909282
            END IF;
          END IF;
          --
          IF p_interface = 'N' THEN
            BEGIN
              SELECT NVL(SUM(NVL(ril.total_amount, 0)), 0) total_amount,
                     NVL(SUM(NVL(ROUND(ril.total_amount, 2), 0)), 0) total_amount_round,
                     NVL(SUM(NVL(TRUNC(ril.total_amount, 2), 0)), 0) total_amount_trunc,
                     -- Begin BUG 24795936
                     ---begin 27578727 27824785
/*                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(ril.icms_amount, 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_amount,
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(ROUND(ril.icms_amount, 2), 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_amount_round,
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(TRUNC(ril.icms_amount, 2), 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_amount_trunc,*/

                     ----------------------------
                     ---- Bug 28912642 Begin ----
                     ---- Caso seja devolucao ao fornecedor fazer o mesmo tratamento da rotina cll_f189_calc_other_values_pkg.upd_return_invoices
                     ---- Caso NAO seja devolucao ao fornecedor, nao alterar a forma de recuperar as informacoes
                     ----NVL(SUM(NVL(ril.icms_amount, 0)), 0)           icms_amount,
                     ----NVL(SUM(NVL(ROUND(ril.icms_amount, 2), 0)), 0) icms_amount_round,
                     ----NVL(SUM(NVL(TRUNC(ril.icms_amount, 2), 0)), 0) icms_amount_trunc,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ril.icms_amount,0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(ril.icms_amount,0)),0)
                     END icms_amount,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ROUND(ril.icms_amount,2),0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(ROUND(ril.icms_amount,2),0)),0)
                     END icms_amount_round,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(TRUNC(ril.icms_amount,2),0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(TRUNC(ril.icms_amount,2),0)),0)
                     END icms_amount_trunc,
                     ---- Bug 28912642 End ----
                     --------------------------

                     ---end 27578727 27824785
                     /*
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ril.icms_amount, 0),0)),0)             icms_amount,
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ROUND(ril.icms_amount,2),0),0)),0)     icms_amount_round,
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(TRUNC(ril.icms_amount,2),0),0)),0)     icms_amount_trunc,
                     */
                     ---begin 27578727 27824785
/*                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(ril.icms_base, 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_base,
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(ROUND(ril.icms_base, 2), 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_base_round,
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(TRUNC(ril.icms_base, 2), 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_base_trunc,*/

                     ----------------------------
                     ---- Bug 28912642 Begin ----
                     ---- Caso seja devolucao ao fornecedor fazer o mesmo tratamento da rotina cll_f189_calc_other_values_pkg.upd_return_invoices
                     ---- Caso NAO seja devolucao ao fornecedor, nao alterar a forma de recuperar as informacoes
                     ----NVL(SUM(NVL(ril.icms_base, 0)), 0)           icms_base,
                     ----NVL(SUM(NVL(ROUND(ril.icms_base, 2), 0)), 0) icms_base_round,
                     ----NVL(SUM(NVL(TRUNC(ril.icms_base, 2), 0)), 0) icms_base_trunc,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ril.icms_base,0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(ril.icms_base,0)),0)
                     END icms_base,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ROUND(ril.icms_base,2),0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(ROUND(ril.icms_base,2),0)),0)
                     END icms_base_round,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(TRUNC(ril.icms_base,2),0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(TRUNC(ril.icms_base,2),0)),0)
                     END icms_base_trunc,
                     ---- Bug 28912642 End ----
                     --------------------------

                     ---end 27578727 27824785
                     /* NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ril.icms_base,0),0)),0)             icms_base,
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ROUND(ril.icms_base,2),0),0)),0)    icms_base_round,
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(TRUNC(ril.icms_base,2),0),0)),0)    icms_base_trunc,*/
                     -- End BUG 24795936
                     NVL(SUM(NVL(ril.ipi_amount, 0)), 0) ipi_amount,
                     NVL(SUM(NVL(ROUND(ril.ipi_amount, 2), 0)), 0) ipi_amount_round,
                     NVL(SUM(NVL(TRUNC(ril.ipi_amount, 2), 0)), 0) ipi_amount_trunc,
                     /*
                     NVL(SUM(NVL(ril.quantity, 0) * NVL(ril.unit_price, 0)),0)                            base_ipi_import,
                     */ -- Bug 6979578 AIrmer 13/05/2008 (Adapted from R11i bug 6979563 fixed by AIrmer)
                     SUM(ROUND((NVL(ril.quantity, 0) *
                               NVL(ril.unit_price, 0)),
                               2)) base_ipi_import, -- Bug 6979578 AIrmer 13/05/2008 (Adapted from R11i bug 6979563 fixed by AIrmer)
                     NVL(SUM(NVL(ril.pis_st_amount, 0)), 0) pis_st_amount,
                     NVL(SUM(NVL(ROUND(ril.pis_st_amount, 2), 0)), 0) pis_st_amount_round,
                     NVL(SUM(NVL(TRUNC(ril.pis_st_amount, 2), 0)), 0) pis_st_amount_trunc,
                     NVL(SUM(NVL(ril.cofins_st_amount, 0)), 0) cofins_st_amount,
                     NVL(SUM(NVL(ROUND(ril.cofins_st_amount, 2), 0)), 0) cofins_st_amount_round,
                     NVL(SUM(NVL(TRUNC(ril.cofins_st_amount, 2), 0)), 0) cofins_st_amount_trunc,
                     NVL(SUM(NVL(ril.pis_cofins_st_base, 0)), 0) pis_cofins_st_base,
                     NVL(SUM(NVL(ROUND(ril.pis_cofins_st_base, 2), 0)), 0) pis_cofins_st_base_round,
                     NVL(SUM(NVL(TRUNC(ril.pis_cofins_st_base, 2), 0)), 0) pis_cofins_st_base_trunc,
                     NVL(SUM(NVL(ril.importation_pis_amount, 0)), 0) importation_pis_amount,
                     NVL(SUM(NVL(ril.importation_cofins_amount, 0)), 0) importation_cofins_amount,
                     NVL(SUM(NVL(ril.cide_amount, 0)), 0) cide_amount, -- 25341463
                     NVL(SUM(NVL(ril.presumed_icms_tax_amount, 0)), 0) presumed_icms_tax_amount, -- ER 5089320 --
                     NVL(SUM(NVL(ROUND(ril.presumed_icms_tax_amount, 2), 0)),
                         0) presumed_icms_tax_amount_round, -- ER 5089320 --
                     NVL(SUM(NVL(TRUNC(ril.presumed_icms_tax_amount, 2), 0)),
                         0) presumed_icms_tax_amount_trunc,
                     NVL(SUM(NVL(ril.iss_tax_amount, 0)), 0) iss_amount -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(ROUND(ril.iss_tax_amount, 2), 0)), 0) iss_amount_round -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(TRUNC(ril.iss_tax_amount, 2), 0)), 0) iss_amount_trunc -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(ril.iss_base_amount, 0)), 0) iss_base_amount -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(ROUND(ril.iss_base_amount, 2), 0)), 0) iss_base_amount_round -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(TRUNC(ril.iss_base_amount, 2), 0)), 0) iss_base_amount_trunc -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(ril.fcp_amount, 0)), 0) fcp_amount -- 25713076
                    ,
                     NVL(SUM(NVL(ROUND(ril.fcp_amount, 2), 0)), 0) fcp_amount_round -- 25713076
                    ,
                     NVL(SUM(NVL(TRUNC(ril.fcp_amount, 2), 0)), 0) fcp_amount_trunc -- 25713076
                    ,
                     NVL(SUM(NVL(ril.fcp_st_amount, 0)), 0) fcp_st_amount -- 25713076
                    ,
                     NVL(SUM(NVL(ROUND(ril.fcp_st_amount, 2), 0)), 0) fcp_st_amount_round -- 25713076
                    ,
                     NVL(SUM(NVL(TRUNC(ril.fcp_st_amount, 2), 0)), 0) fcp_st_amount_trunc -- 25713076
                    ,NVL(SUM(NVL(ril.discount_net_amount, 0)), 0) discount_net_amount     -- 28730612
                    ,NVL(SUM(NVL(ril.discount_amount, 0)), 0) discount_amount             -- 28730612
                    ,NVL(SUM(NVL(ril.discount_percent, 0)), 0) discount_percent           -- 28730612
                INTO v_sum_total_amount,
                     v_sum_total_amount_round,
                     v_sum_total_amount_trunc,
                     v_sum_total_icms,
                     v_sum_total_icms_round,
                     v_sum_total_icms_trunc,
                     v_sum_base_icms,
                     v_sum_base_icms_round,
                     v_sum_base_icms_trunc,
                     v_sum_ipi_amount,
                     v_sum_ipi_amount_round,
                     v_sum_ipi_amount_trunc,
                     v_base_ipi_import,
                     v_sum_pis_st_amount,
                     v_sum_pis_st_amount_round,
                     v_sum_pis_st_amount_trunc,
                     v_sum_cofins_st_amount,
                     v_sum_cofins_st_amount_round,
                     v_sum_cofins_st_amount_trunc,
                     v_sum_pis_cofins_st_base,
                     v_sum_pis_cofins_st_base_round,
                     v_sum_pis_cofins_st_base_trunc,
                     v_sum_pis_imp_amount --
                    ,
                     v_sum_cofins_imp_amount --
                    ,
                     v_sum_cide_imp_amount -- 25341463
                    ,
                     v_sum_pres_icms_amount -- ER 5089320 --
                    ,
                     v_sum_pres_icms_amount_round -- ER 5089320 --
                    ,
                     v_sum_pres_icms_amount_trunc -- ER 5089320 --
                    ,
                     v_sum_iss_amount -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_amount_round -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_amount_trunc -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_base_amount -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_base_amount_round -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_base_amount_trunc -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     l_sum_fcp_amount -- 25713076
                    ,
                     l_sum_fcp_amount_round -- 25713076
                    ,
                     l_sum_fcp_amount_trunc -- 25713076
                    ,
                     l_sum_fcp_st_amount -- 25713076
                    ,
                     l_sum_fcp_st_amount_round -- 25713076
                    ,
                     l_sum_fcp_st_amount_trunc -- 25713076
                    ,l_sum_discount_net_amount -- 28730612
                    ,l_sum_discount_amount     -- 28730612
                    ,l_sum_discount_percent    -- 28730612
                FROM cll_f189_invoice_lines     ril,
                     cll_f189_item_utilizations riu
               WHERE ril.invoice_id = r_invoices.invoice_id
                 AND riu.utilization_id = ril.utilization_id;
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20532,
                                        SQLERRM || '*********************' ||
                                        ' Select Total amount invoice lines ' ||
                                        '*********************');
            END;
          ELSE
            BEGIN
              SELECT NVL(SUM(NVL(rili.total_amount, 0)), 0) total_amount,
                     NVL(SUM(NVL(ROUND(rili.total_amount, 2), 0)), 0) total_amount_round,
                     NVL(SUM(NVL(TRUNC(rili.total_amount, 2), 0)), 0) total_amount_trunc,
                     -- Begin BUG 24795936
                     /*
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(rili.icms_amount,0),0)),0)              icms_amount,
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ROUND(rili.icms_amount,2),0),0)),0)     icms_amount_round,
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(TRUNC(rili.icms_amount,2),0),0)),0)     icms_amount_trunc,
                     */
                     ---begin 27578727 27824785
                     /*
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(rili.icms_amount, 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_amount,
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(ROUND(rili.icms_amount, 2), 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_amount_round,
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(TRUNC(rili.icms_amount, 2), 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_amount_trunc,
                     --
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(rili.icms_base, 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_base,
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(ROUND(rili.icms_base, 2), 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_base_round,
                     NVL(SUM(DECODE(riu.icms_differed_type,
                                    'N',
                                    NVL(TRUNC(rili.icms_base, 2), 0),
                                    'F',
                                    0,
                                    0)),
                         0) icms_base_trunc,
                     */
                     --

                     ----------------------------
                     ---- Bug 28912642 Begin ----
                     ---- Caso seja devolucao ao fornecedor fazer o mesmo tratamento da rotina cll_f189_calc_other_values_pkg.upd_return_invoices
                     ---- Caso NAO seja devolucao ao fornecedor, nao alterar a forma de recuperar as informacoes
                     --
                     ----NVL(SUM(NVL(rili.icms_amount, 0)), 0)           icms_amount,
                     ----NVL(SUM(NVL(ROUND(rili.icms_amount, 2), 0)), 0) icms_amount_round,
                     ----NVL(SUM(NVL(TRUNC(rili.icms_amount, 2), 0)), 0) icms_amount_trunc,
                     --
                     ----NVL(SUM(NVL(rili.icms_base, 0)), 0)             icms_base,
                     ----NVL(SUM(NVL(ROUND(rili.icms_base, 2), 0)), 0)   icms_base_round,
                     ----NVL(SUM(NVL(TRUNC(rili.icms_base, 2), 0)), 0)   icms_base_trunc,
                     --
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(rili.icms_amount,0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(rili.icms_amount,0)),0)
                     END icms_amount,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ROUND(rili.icms_amount,2),0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(ROUND(rili.icms_amount,2),0)),0)
                     END icms_amount_round,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(TRUNC(rili.icms_amount,2),0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(TRUNC(rili.icms_amount,2),0)),0)
                     END icms_amount_trunc,
                     --
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(rili.icms_base,0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(rili.icms_base,0)),0)
                     END icms_base,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ROUND(rili.icms_base,2),0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(ROUND(rili.icms_base,2),0)),0)
                     END icms_base_round,
                     CASE
                       WHEN r_invoices.return_customer_flag = 'F' THEN
                            NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(TRUNC(rili.icms_base,2),0),'F',0,0)),0)
                       ELSE
                            NVL(SUM(NVL(TRUNC(rili.icms_base,2),0)),0)
                     END icms_base_trunc,
                     --
                     ---- Bug 28912642 End ----
                     --------------------------

                     --
                     ---end 27578727 27824785
                     --
                     /* NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(rili.icms_base,0),0)),0)             icms_base,
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(ROUND(rili.icms_base,2),0),0)),0)    icms_base_round,
                     NVL(SUM(DECODE(riu.icms_differed_type,'N',NVL(TRUNC(rili.icms_base,2),0),0)),0)    icms_base_trunc,*/
                     -- End BUG 24795936
                     NVL(SUM(NVL(rili.ipi_amount, 0)), 0) ipi_amount,
                     NVL(SUM(NVL(ROUND(rili.ipi_amount, 2), 0)), 0) ipi_amount_round,
                     NVL(SUM(NVL(TRUNC(rili.ipi_amount, 2), 0)), 0) ipi_amount_trunc,
                     /*
                     NVL(SUM( NVL (rili.quantity,0)* NVL(rili.unit_price,0)),0)                            base_ipi_import,
                     */ -- Bug 6979578 AIrmer 13/05/2008 (Adapted from R11i bug 6979563 fixed by AIrmer)
                     SUM(ROUND((NVL(rili.quantity, 0) *
                               NVL(rili.unit_price, 0)),
                               2)) base_ipi_import, -- Bug 6979578 AIrmer 13/05/2008 (Adapted from R11i bug 6979563 fixed by AIrmer)
                     NVL(SUM(NVL(rili.importation_pis_amount, 0)), 0) importation_pis_amount,
                     NVL(SUM(NVL(rili.importation_cofins_amount, 0)), 0) importation_cofins_amount,
                     NVL(SUM(NVL(rili.cide_amount, 0)), 0) cide_amount, -- 25341463
                     NVL(SUM(NVL(rili.presumed_icms_tax_amount, 0)), 0) presumed_icms_tax_amount, -- ER 5089320 --
                     NVL(SUM(NVL(ROUND(rili.presumed_icms_tax_amount, 2), 0)),
                         0) presumed_icms_tax_amount_round, -- ER 5089320 --
                     NVL(SUM(NVL(TRUNC(rili.presumed_icms_tax_amount, 2), 0)),
                         0) presumed_icms_tax_amount_trunc -- ER 5089320 --
                    ,
                     NVL(SUM(NVL(rili.iss_tax_amount, 0)), 0) iss_amount -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(ROUND(rili.iss_tax_amount, 2), 0)), 0) iss_amount_round -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(TRUNC(rili.iss_tax_amount, 2), 0)), 0) iss_amount_trunc -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(rili.iss_base_amount, 0)), 0) iss_base_amount -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(ROUND(rili.iss_base_amount, 2), 0)), 0) iss_base_amount_round -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(TRUNC(rili.iss_base_amount, 2), 0)), 0) iss_base_amount_trunc -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     NVL(SUM(NVL(rili.fcp_amount, 0)), 0) fcp_amount -- 25713076
                    ,
                     NVL(SUM(NVL(ROUND(rili.fcp_amount, 2), 0)), 0) fcp_amount_round -- 25713076
                    ,
                     NVL(SUM(NVL(TRUNC(rili.fcp_amount, 2), 0)), 0) fcp_amount_trunc -- 25713076
                    ,
                     NVL(SUM(NVL(rili.fcp_st_amount, 0)), 0) fcp_st_amount -- 25713076
                    ,
                     NVL(SUM(NVL(ROUND(rili.fcp_st_amount, 2), 0)), 0) fcp_st_amount_round -- 25713076
                    ,
                     NVL(SUM(NVL(TRUNC(rili.fcp_st_amount, 2), 0)), 0) fcp_st_amount_trunc -- 25713076
                    ,NVL(SUM(NVL(rili.discount_net_amount, 0)), 0) discount_net_amount -- 28730612
                    ,NVL(SUM(NVL(rili.discount_amount, 0)), 0)     discount_amount     -- 28730612
                    ,NVL(SUM(NVL(rili.discount_percent, 0)), 0)    discount_percent    -- 28730612
                INTO v_sum_total_amount,
                     v_sum_total_amount_round,
                     v_sum_total_amount_trunc,
                     v_sum_total_icms,
                     v_sum_total_icms_round,
                     v_sum_total_icms_trunc,
                     v_sum_base_icms,
                     v_sum_base_icms_round,
                     v_sum_base_icms_trunc,
                     v_sum_ipi_amount,
                     v_sum_ipi_amount_round,
                     v_sum_ipi_amount_trunc,
                     v_base_ipi_import,
                     v_sum_pis_imp_amount, --
                     v_sum_cofins_imp_amount, --
                     v_sum_cide_imp_amount, -- 25341463
                     v_sum_pres_icms_amount, -- ER 5089320 --
                     v_sum_pres_icms_amount_round, -- ER 5089320 --
                     v_sum_pres_icms_amount_trunc -- ER 5089320 --
                    ,
                     v_sum_iss_amount -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_amount_round -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_amount_trunc -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_base_amount -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_base_amount_round -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     v_sum_iss_base_amount_trunc -- ER 6519914 - SSimoes - 15/05/2008
                    ,
                     l_sum_fcp_amount -- 25713076
                    ,
                     l_sum_fcp_amount_round -- 25713076
                    ,
                     l_sum_fcp_amount_trunc -- 25713076
                    ,
                     l_sum_fcp_st_amount -- 25713076
                    ,
                     l_sum_fcp_st_amount_round -- 25713076
                    ,
                     l_sum_fcp_st_amount_trunc -- 25713076
                    ,l_sum_discount_net_amount -- 28730612
                    ,l_sum_discount_percent    -- 28730612
                    ,l_sum_discount_amount     -- 28730612
                FROM CLL_F189_INVOICE_LINES_IFACE rili,
                     cll_f189_item_utilizations   riu
               WHERE rili.interface_invoice_id =
                     r_invoices.interface_invoice_id
                 AND (riu.utilization_id = rili.utilization_id OR
                     riu.utilization_code = rili.utilization_code);
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20532,
                                        SQLERRM || '*********************' ||
                                        ' Select Total amount invoice lines (interface) ' ||
                                        '*********************');
            END;
          END IF;

          -- DISCOUNT CONFLICT
          -- 28730612 - Start
          IF ((NVL(l_sum_discount_net_amount, 0) > 0) AND
             (NVL(l_sum_discount_amount, 0) > 0 OR
              NVL(l_sum_discount_percent, 0) > 0 )) THEN

             IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DISCOUNT CONFLICT',
                                                           r_invoices.invoice_id,
                                                           NULL);
             ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DISCOUNT CONFLICT');
             END IF;

          END IF;
          -- 28730612 - End

          -- PIS Importation
          IF ROUND(NVL(r_invoices.importation_pis_amount, 0), arr) <>
             ROUND(NVL(v_sum_pis_imp_amount, 0), arr) AND
             TRUNC(NVL(r_invoices.importation_pis_amount, 0), arr) <>
             TRUNC(NVL(v_sum_pis_imp_amount, 0), arr) THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'DIFF PIS IMP',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF PIS IMP');
            END IF;
          END IF;
          -- COFINS Importation
          IF ROUND(NVL(r_invoices.importation_cofins_amount, 0), arr) <>
             ROUND(NVL(v_sum_cofins_imp_amount, 0), arr) AND
             TRUNC(NVL(r_invoices.importation_cofins_amount, 0), arr) <>
             TRUNC(NVL(v_sum_cofins_imp_amount, 0), arr) THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'DIFF COFINS IMP',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF COFINS IMP');
            END IF;
          END IF;
          --
          -- ER 20450226 - Start
          --
          -- 25341463 - Start
          -- CIDE Importation
          IF ROUND(NVL(r_invoices.importation_cide_amount, 0), arr) <>
             ROUND(NVL(v_sum_cide_imp_amount, 0), arr) AND
             TRUNC(NVL(r_invoices.importation_cide_amount, 0), arr) <>
             TRUNC(NVL(v_sum_cide_imp_amount, 0), arr) THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'DIFF CIDE IMP',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'DIFF CIDE IMP');
            END IF;
          END IF;
          -- 25341463 - End
          --
          --
          BEGIN
            --
            IF l_national_state = 'N' THEN
              -- Informacao do Header
              IF p_interface = 'N' THEN
                SELECT SUM(NVL(ri.import_other_val_included_icms, 0) +
                           nvl(ri.import_other_val_not_icms, 0))
                  INTO v_sum_included_icms_head
                  FROM cll_f189_invoices ri
                 WHERE ri.operation_id = p_operation_id
                   AND ri.organization_id = p_organization_id;
              ELSE
                SELECT SUM(NVL(ri.import_other_val_included_icms, 0) +
                           nvl(ri.import_other_val_not_icms, 0))
                  INTO v_sum_included_icms_head
                  FROM cll_f189_invoices_interface ri
                 WHERE ri.interface_operation_id = p_operation_id
                   AND (ri.organization_id = p_organization_id OR
                       ri.organization_code = l_org_code);
              END IF;
              --Informacao da linha
              IF p_interface = 'N' THEN
                SELECT SUM(NVL(ril.import_other_val_included_icms, 0) +
                           nvl(ril.import_other_val_not_icms, 0))
                  INTO v_sum_included_icms_line
                  FROM cll_f189_invoices ri, cll_f189_invoice_lines ril
                 WHERE ri.operation_id = p_operation_id
                   AND ri.organization_id = p_organization_id
                   AND ri.invoice_id = ril.invoice_id;
              ELSE
                SELECT SUM(NVL(ril.import_other_val_included_icms, 0) +
                           nvl(ril.import_other_val_not_icms, 0))
                  INTO v_sum_included_icms_line
                  FROM cll_f189_invoices_interface  ri,
                       cll_f189_invoice_lines_iface ril
                 WHERE ri.interface_operation_id = p_operation_id
                   AND (ri.organization_id = p_organization_id OR
                       ri.organization_code = l_org_code)
                   AND ri.interface_invoice_id = ril.interface_invoice_id;
              END IF; --p_interface = N
              --

              IF v_sum_included_icms_head <> v_sum_included_icms_line THEN
                --
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'OTHER CUSTOM EXPENSES',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'OTHER CUSTOM EXPENSES');
                END IF; --p_interface
                --
              END IF; --v_sum_included_icms_head <> v_sum_included_icms_line
              --
              IF (r_invoices.import_other_val_not_icms IS NULL OR
                 r_invoices.import_other_val_included_icms IS NULL) AND
                 r_invoices.source_items = '1' THEN
                -- Bug 21320422
                --
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NULL OTHER CUSTOM EXPENSES',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NULL OTHER CUSTOM EXPENSES');
                END IF; --p_interface = 'N'
                --
              END IF; --r_invoices.import_other_val_not_icms IS NULL OR r_invoices.import_other_val_included_icms IS NULL)
              --
            END IF; --l_national_state = 'N'
            --
          END; --Begin principal

          --
          -- ER 20450226 - End
          --
          IF p_interface = 'Y' THEN
            v_importation_total := NVL(r_invoices.total_fob_amount,
                                       v_sum_total_amount) +
                                   NVL(r_invoices.freight_international, 0) +
                                   NVL(r_invoices.importation_insurance_amount,
                                       0) +
                                   NVL(r_invoices.importation_tax_amount, 0) +
                                   NVL(r_invoices.importation_pis_amount, 0) +
                                   NVL(r_invoices.importation_cofins_amount,
                                       0);
          ELSE
            v_importation_total := NVL(r_invoices.total_fob_amount,
                                       v_sum_total_amount) +
                                   NVL(r_invoices.freight_international, 0) +
                                   NVL(r_invoices.importation_insurance_amount,
                                       0) +
                                   NVL(r_invoices.importation_tax_amount, 0) +
                                   NVL(r_invoices.importation_pis_amount, 0) +
                                   NVL(r_invoices.importation_cofins_amount,
                                       0);
          END IF;
          --
          v_base_ipi_import_pis_cofins := v_base_ipi_import +
                                          v_sum_pis_imp_amount +
                                          v_sum_cofins_imp_amount;

          --
          IF v_importation_total > 0 AND
             ROUND(v_importation_total, arr) <>
             ROUND(v_base_ipi_import_pis_cofins, arr) AND
             TRUNC(v_importation_total, arr) <>
             TRUNC(v_base_ipi_import_pis_cofins, arr) THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         -- 'DIFF FOB AMOUNT', -- Bug 8607416 - SSimoes - 06/Jan/2011
                                                         'DIFF CIF AMOUNT', -- Bug 8607416 - SSimoes - 06/Jan/2011
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    -- 'DIFF FOB AMOUNT' -- Bug 8607416 - SSimoes - 06/Jan/2011
                                                    'DIFF CIF AMOUNT' -- Bug 8607416 - SSimoes - 06/Jan/2011
                                                    );
            END IF;
          END IF;
          --
          BEGIN
            -- Bug 7422494 - SSimoes - 10/06/2010 - Inicio
            /*
             SELECT rs.state_code
               INTO v_state_code
               FROM cll_f189_states rs,
                    cll_f189_fiscal_entities_all rfea
              WHERE rfea.entity_id = r_invoices.entity_id
                AND rs.state_id = rfea.state_id;
            */
            -- Bug 7422494 - SSimoes - 10/06/2010 - Fim
            -- ER 9069838 - SSimoes - 04/05/2010 - Inicio
            /*
             IF cprojectflag = 'I' AND v_state_code <> 'EX'
             THEN
                IF p_interface = 'N'
                THEN
                   cll_f189_check_holds_pkg.incluir_erro_hold
                                           (p_operation_id,
                                            p_organization_id,
                                            p_location_id,
                                            'INVALID INVOICE TYPE PROJ',
                                            r_invoices.invoice_id,
                                            NULL
                                           );
                ELSE
                   cll_f189_check_holds_pkg.incluir_erro
                                       (r_invoices.interface_invoice_id,
                                        p_operation_id,
                                        'INVALID INVOICE TYPE PROJ'
                                       );
                END IF;
             END IF;
            */
            -- ER 9069838 - SSimoes - 04/05/2010 - Fim
            -- Bug 7422494 - SSimoes - 10/06/2010 - Inicio
            --                  IF v_state_code = 'EX' THEN
            IF v_national_state = 'N' THEN
              -- Bug 7422494 - SSimoes - 10/06/2010 - Fim
              IF v_enforce_corp_conversion_rate = 'Y' THEN
                IF v_currency_conversion_rate = 'CORPORATE' THEN
                  BEGIN
                    BEGIN
                      SELECT gsb.currency_code
                        INTO v_currency_code
                        FROM org_organization_definitions ood,
                             gl_sets_of_books             gsb
                       WHERE ood.organization_id = p_organization_id
                         AND ood.set_of_books_id = gsb.set_of_books_id;
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        v_currency_code := NULL;
                    END;
                    --
                    w_set_of_books_id_alt1 := TO_NUMBER(fnd_profile.VALUE('CLL_F189_FIRST_ALTERNATIVE_SET_OF_BOOKS'));
                    IF w_set_of_books_id_alt1 IS NOT NULL THEN
                      BEGIN
                        SELECT gsb.currency_code
                          INTO v_currency_alt1
                          FROM gl_sets_of_books gsb
                         WHERE set_of_books_id = w_set_of_books_id_alt1;
                      EXCEPTION
                        WHEN OTHERS THEN
                          v_currency_alt1 := NULL;
                      END;
                    END IF;
                    --
                    w_set_of_books_id_alt2 := TO_NUMBER(fnd_profile.VALUE('CLL_F189_SECOND_ALTERNATIVE_SET_OF_BOOKS'));
                    IF w_set_of_books_id_alt2 IS NOT NULL THEN
                      BEGIN
                        SELECT gsb.currency_code
                          INTO v_currency_alt2
                          FROM gl_sets_of_books gsb
                         WHERE set_of_books_id = w_set_of_books_id_alt2;
                      EXCEPTION
                        WHEN OTHERS THEN
                          v_currency_alt2 := NULL;
                      END;
                    END IF;
                    --
                    BEGIN
                      SELECT NVL(MAX(gdr.conversion_date), SYSDATE)
                        INTO v_conversion_date
                        FROM gl_daily_rates gdr
                       WHERE gdr.from_currency = v_currency_code
                         AND gdr.to_currency = v_currency_alt1
                         AND gdr.conversion_type =
                             NVL(fnd_profile.VALUE('CLL_F189_CURR_CONVERSION_TYPE'),
                                 'Corporate')
                            -- BUG 4892028 CSilva 23/03/2006
                         AND gdr.conversion_date <= r_invoices.invoice_date;
                    EXCEPTION
                      WHEN no_data_found THEN
                        IF p_interface = 'N' THEN
                          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                     p_organization_id,
                                                                     p_location_id,
                                                                     'NONE CONVERSION RATE',
                                                                     r_invoices.invoice_id,
                                                                     '');
                        ELSE
                          cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                                p_operation_id,
                                                                'NONE CONVERSION RATE');
                        END IF;
                    END;
                    --
                    BEGIN
                      SELECT COUNT(1)
                        INTO v_quant
                        FROM gl_daily_rates gdr
                       WHERE gdr.from_currency = v_currency_code
                         AND gdr.to_currency = v_currency_alt1
                         AND gdr.conversion_type =
                             NVL(fnd_profile.VALUE('CLL_F189_CURR_CONVERSION_TYPE'),
                                 'Corporate')
                            -- BUG 4892028 CSilva 23/03/2006
                         AND gdr.conversion_date = v_conversion_date;
                      --
                      IF v_quant = 0 THEN
                        IF p_interface = 'N' THEN
                          cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                     p_organization_id,
                                                                     p_location_id,
                                                                     'NONE CONVERSION RATE',
                                                                     r_invoices.invoice_id,
                                                                     '');
                        ELSE
                          cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                                p_operation_id,
                                                                'NONE CONVERSION RATE');
                        END IF;
                      END IF;
                    END;
                  END;
                END IF;
                --
                BEGIN
                  IF v_enforce_corp_conversion_rate = 'Y' AND
                     r_invoices.alternate_currency_conv_rate = 0 AND
                     r_invoices.source_items = '2' THEN
                    IF p_interface = 'N' THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                 'NONE ALT CURR CONV RATE',
                                                                 r_invoices.invoice_id,
                                                                 '');
                    ELSE
                      cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                            p_operation_id,
                                                            'NONE ALT CURR CONV RATE');
                    END IF;
                  END IF;
                END;
              END IF;
            END IF;
          END;
          --
          IF r_invoices.funrural_amount > 0 AND
             r_invoices.funrural_ccid IS NULL THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE FUNRURAL CCID',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE FUNRURAL CCID');
            END IF;
          END IF;
          --
          -- ER 17551029 - Start
          IF r_invoices.funrural_tax = 0 AND
             (r_invoices.social_security_contrib_tax > 0 OR
             r_invoices.gilrat_tax > 0 OR r_invoices.senar_tax > 0) THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE RURALINSS TAX',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE RURALINSS TAX');
            END IF;
          END IF;
          --
          IF r_invoices.funrural_tax > 0 AND
             (r_invoices.social_security_contrib_tax > 0 OR
             r_invoices.gilrat_tax > 0 OR r_invoices.senar_tax > 0) THEN
            l_sum_funrural_tax := 0;
            l_sum_funrural_tax := r_invoices.social_security_contrib_tax +
                                  r_invoices.gilrat_tax +
                                  r_invoices.senar_tax;
            IF r_invoices.funrural_tax <> l_sum_funrural_tax THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV RURAL INSS TAX',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'INV RURAL INSS TAX');
              END IF;
            END IF;
          END IF;
          -- ER 17551029 - End
          --
            -- 27153706 - Start
            IF (r_invoices.funrural_amount = 0 AND
               (NVL(r_invoices.social_security_contrib_amount, 0) > 0 OR
               NVL(r_invoices.gilrat_amount, 0) > 0 OR
               NVL(r_invoices.senar_amount, 0) > 0)) THEN

              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE FUNRURAL AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE FUNRURAL AMOUNT');
              END IF;

            END IF;
            --
            IF r_invoices.funrural_amount <>
               (r_invoices.social_security_contrib_amount
              + r_invoices.gilrat_amount
              + r_invoices.senar_amount) THEN

              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV FUNRURAL AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'INV FUNRURAL AMOUNT');
              END IF;

            END IF;
            -- 27153706 - End
          --
          IF r_invoices.sest_senat_amount > 0 AND
             r_invoices.sest_senat_ccid IS NULL THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE SEST/SENAT CCID',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE SEST/SENAT CCID');
            END IF;
          END IF;
          --
          -- 25808200 - 25808214 - Start
          IF r_invoices.include_sest_senat_flag = 'Y' THEN
           IF l_source <> 'CLL_F369 EFD LOADER SHIPPER' THEN -- 27579747
            IF (r_invoices.sest_senat_tax = 0 AND
               (NVL(r_invoices.sest_tax, 0) > 0 OR
               NVL(r_invoices.senat_tax, 0) > 0)) THEN

              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE SESTSENAT TAX',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE SESTSENAT TAX');
              END IF;

            END IF;
            --
            IF r_invoices.sest_senat_tax <>
               (r_invoices.sest_tax + r_invoices.senat_tax) THEN

              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV SESTSENAT TAX',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'INV SESTSENAT TAX');
              END IF;

            END IF;
            -- 27153706 - Start
            IF (r_invoices.sest_senat_amount = 0 AND
               (NVL(r_invoices.sest_amount, 0) > 0 OR
               NVL(r_invoices.senat_amount, 0) > 0)) THEN

              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE SESTSENAT AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE SESTSENAT AMOUNT');
              END IF;
            END IF;
            --
            IF r_invoices.sest_senat_amount <>
               (r_invoices.sest_amount + r_invoices.senat_amount) THEN

              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INV SESTSENAT AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'INV SESTSENAT AMOUNT');
              END IF;

            END IF;
            -- 27153706 - End
           END IF; -- 27579747
          END IF;
          --
          IF l_document_type = 'CNPJ' THEN

            IF NOT
                CLL_F189_INSS_TAX_PKG.GET_SPECIAL_CONDITION(p_organization_id,
                                                            p_operation_id,
                                                            r_invoices.invoice_id,
                                                            r_invoices.invoice_type_id,
                                                            r_invoices.entity_id) THEN

              IF (NVL(r_invoices.inss_additional_tax_1, 0) +
                 NVL(r_invoices.inss_additional_tax_2, 0) +
                 NVL(r_invoices.inss_additional_tax_3, 0)) > 0 THEN

                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'SPECIAL CONDITION INVALID',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'SPECIAL CONDITION INVALID');
                END IF;

              END IF;

            END IF;
            --

            IF l_esocial_period_code <=
               TO_CHAR(r_invoices.invoice_date, 'YYYY-MM') THEN

              IF r_invoices.lp_inss_rate > l_lp_inss_rate_max_ret THEN

                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INSS LP RET RATE EXCEED MAX',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'INSS LP RET RATE EXCEED MAX');
                END IF;

              END IF;
              --
              -- 27859902 - Start
              IF  r_invoices.lp_inss_rate <> 0
              AND r_invoices.lp_inss_base_amount <> 0
              AND r_invoices.lp_inss_amount >= 0 THEN

                 IF p_interface = 'N' THEN

                    SELECT count(distinct msi.global_attribute21)
                      INTO l_count_service_class
                    FROM mtl_system_items msi
                       , cll_f189_invoice_lines ril
                    WHERE msi.organization_id = p_organization_id
                      AND ril.item_id         = msi.inventory_item_id
                      AND ril.invoice_id      = r_invoices.invoice_id;

                    IF l_count_service_class > 1 THEN

                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                  'REINF SERVICE CLASSIF DIVERG',
                                                                  r_invoices.invoice_id,
                                                                  '');

                    END IF;

                 ELSE

                    SELECT count(distinct msi.global_attribute21)
                      INTO l_count_service_class
                    FROM mtl_system_items msi
                       , cll_f189_invoice_lines_iface ril
                    WHERE msi.organization_id      = p_organization_id
                      AND ril.item_id              = msi.inventory_item_id
                      AND ril.interface_invoice_id = r_invoices.interface_invoice_id;

                    IF l_count_service_class > 1 THEN

                       cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                             p_operation_id,
                                                            'REINF SERVICE CLASSIF DIVERG');

                    END IF;

                 END IF;

              END IF;
              -- 27859902 - End
              --
              IF p_interface = 'N' THEN

                SELECT count(*)
                  INTO l_inv_total_lines
                  FROM cll_f189_invoice_lines cllil
                 WHERE cllil.invoice_id = r_invoices.invoice_id;

                SELECT count(*)
                  INTO l_null_item_serv_type_count
                  FROM (SELECT cllmsi.attribute1
                          FROM cll_f407_mtl_system_items_ext cllmsi,
                               cll_f189_invoice_lines        cllil
                         WHERE cllmsi.inventory_item_id = cllil.item_id
                           AND cllmsi.organization_id = p_organization_id
                           AND cllmsi.attribute1 IS NULL
                           AND cllil.invoice_id = r_invoices.invoice_id);

                IF l_null_item_serv_type_count <> 0 AND
                   l_inv_total_lines <> l_null_item_serv_type_count THEN

                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE SERVICE TYPE ITEM',
                                                             r_invoices.invoice_id,
                                                             '');

                ELSE

                  SELECT count(*)
                    INTO l_item_service_type_count
                    FROM (SELECT distinct cllmsi.attribute1
                            FROM cll_f407_mtl_system_items_ext cllmsi,
                                 cll_f189_invoice_lines        cllil
                           WHERE cllmsi.inventory_item_id = cllil.item_id
                             AND cllmsi.organization_id = p_organization_id
                             AND cllil.invoice_id = r_invoices.invoice_id);

                  IF l_item_service_type_count > 1 THEN

                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'MORE SERVICE TYPE ITEM',
                                                               r_invoices.invoice_id,
                                                               '');

                  END IF;

                END IF;

              ELSE

                SELECT count(*)
                  INTO l_inv_total_lines
                  FROM cll_f189_invoice_lines_iface cllil
                 WHERE cllil.invoice_id = r_invoices.interface_invoice_id;

                SELECT count(*)
                  INTO l_null_item_serv_type_count
                  FROM (SELECT cllmsi.attribute1
                          FROM cll_f407_mtl_system_items_ext cllmsi,
                               cll_f189_invoice_lines_iface  cllil
                         WHERE cllmsi.inventory_item_id = cllil.item_id
                           AND cllmsi.organization_id = p_organization_id
                           AND cllmsi.attribute1 IS NULL
                           AND cllil.invoice_id =
                               r_invoices.interface_invoice_id);

                IF l_null_item_serv_type_count <> 0 AND
                   l_inv_total_lines <> l_null_item_serv_type_count THEN

                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE SERVICE TYPE ITEM');

                ELSE

                  SELECT count(*)
                    INTO l_item_service_type_count
                    FROM (SELECT distinct cllmsi.attribute1
                            FROM cll_f407_mtl_system_items_ext cllmsi,
                                 cll_f189_invoice_lines_iface  cllil
                           WHERE cllmsi.inventory_item_id = cllil.item_id
                             AND cllmsi.organization_id = p_organization_id
                             AND cllil.invoice_id =
                                 r_invoices.interface_invoice_id);

                  IF l_item_service_type_count > 1 THEN

                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                          p_operation_id,
                                                          'MORE SERVICE TYPE ITEM');

                  END IF;

                END IF;

              END IF;

            END IF;

          END IF;
          -- 25808200 - 25808214 - End

          -- PIS/COFINS importantion
          IF NVL(r_invoices.importation_cofins_amount, 0) > 0 AND
             r_invoices.import_cofins_ccid IS NULL THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE COFINS IMP CCID',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE COFINS IMP CCID');
            END IF;
          END IF;
          --
          IF NVL(r_invoices.importation_pis_amount, 0) > 0 AND
             r_invoices.import_pis_ccid IS NULL THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'NONE PIS IMP CCID',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'NONE PIS IMP CCID');
            END IF;
          END IF;
          --
          --------------------
          -- 29688781 Begin --
          --------------------
          IF (NVL(r_invoices.freight_international, 0) > 0 OR
              NVL(r_invoices.importation_insurance_amount, 0) > 0 OR
              NVL(r_invoices.import_other_val_not_icms, 0) > 0 OR
              NVL(r_invoices.import_other_val_included_icms, 0) > 0
             ) AND
             v_national_state = 'N' AND
             r_invoices.requisition_type = 'RM' AND
             r_invoices.import_expense_rma_ccid IS NULL THEN
             --
             IF p_interface = 'N' THEN
                --
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE IMPORT EXPENSE RMA CCID',
                                                           r_invoices.invoice_id,
                                                           '');
                --
             ELSE
                --
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE IMPORT EXPENSE RMA CCID');
                --
             END IF;
             --
          END IF;
          ------------------
          -- 29688781 End --
          ------------------
          --

          --  27740002 - Start
          IF p_interface = 'N' THEN

             SELECT ROUND (NVL (SUM (NVL (ril.pis_amount, 0)), 0), 2)
                  , ROUND (NVL (SUM (NVL (ril.cofins_amount, 0)), 0), 2)
               INTO l_pis_amount
                  , l_cofins_amount
             FROM cll_f189_invoices ri
                , cll_f189_invoice_lines ril
             WHERE ri.operation_id    = p_operation_id
               AND ri.organization_id = p_organization_id
               AND ri.invoice_id      = r_invoices.invoice_id
               AND ri.invoice_id      = ril.invoice_id;

           ELSE

             SELECT ROUND (NVL (SUM (NVL (ril.pis_amount, 0)), 0), 2)
                  , ROUND (NVL (SUM (NVL (ril.cofins_amount, 0)), 0), 2)
               INTO l_pis_amount
                  , l_cofins_amount
             FROM cll_f189_invoices_interface ri
                , cll_f189_invoice_lines_iface ril
             WHERE ri.interface_operation_id = p_operation_id
               AND ri.organization_id        = p_organization_id
               AND ri.interface_invoice_id   = r_invoices.interface_invoice_id
               AND ri.interface_invoice_id   = ril.interface_invoice_id;

           END IF;
           --  27740002 - End

          -- Recover COFINS
          --  27740002 - Start
        --IF r_invoices.cofins_flag = 'Y' AND r_invoices.cofins_ccid IS NULL THEN
          IF r_invoices.cofins_flag = 'Y' THEN

             IF r_invoices.cofins_ccid IS NULL THEN
          --  27740002 - End
                IF p_interface = 'N' THEN
                   cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                              p_organization_id,
                                                              p_location_id,
                                                             'NONE COFINS CCID',
                                                              r_invoices.invoice_id,
                                                             '');
                ELSE
                   cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                         p_operation_id,
                                                        'NONE COFINS CCID');
                END IF;

             END IF;


             --  27740002 - Start
             IF r_invoices.contab_flag = 'I' AND l_cofins_amount > 0 THEN

                IF r_invoices.collect_cofins_ccid IS NULL THEN

                   IF p_interface = 'N' THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                'NONE COFINS TO COLLECT CCID',
                                                                 r_invoices.invoice_id,
                                                                '');
                   ELSE
                      cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                            p_operation_id,
                                                           'NONE COFINS TO COLLECT CCID');
                   END IF;

                END IF;

             END IF;

          END IF;
          --  27740002 - End
          --
          -- 27206522 - Start
        --IF r_invoices.pis_flag = 'Y' AND r_invoices.pis_ccid IS NULL THEN
          IF r_invoices.pis_flag = 'Y' THEN

             IF r_invoices.pis_ccid IS NULL THEN
          -- 27206522 - End

                IF p_interface = 'N' THEN
                   cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                              p_organization_id,
                                                              p_location_id,
                                                             'NONE PIS CCID',
                                                              r_invoices.invoice_id,
                                                             '');
                ELSE
                   cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                         p_operation_id,
                                                        'NONE PIS CCID');
                END IF;

             END IF;

          -- 27206522 - Start
             IF r_invoices.contab_flag = 'I' AND l_pis_amount > 0 THEN

                IF r_invoices.collect_pis_ccid IS NULL THEN

                   IF p_interface = 'N' THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                'NONE PIS TO COLLECT CCID',
                                                                 r_invoices.invoice_id,
                                                                '');
                   ELSE
                      cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                            p_operation_id,
                                                           'NONE PIS TO COLLECT CCID');
                   END IF;

                END IF;

             END IF;


          END IF;
          -- 27206522  - End
          --

----25591653 begin

/*          IF p_interface = 'N' THEN
            SELECT ROUND(NVL(SUM(NVL(ri.iss_amount, 0)), 0), 2)
              INTO v_iss_amount
              FROM cll_f189_invoices            ri,
                   cll_f189_fiscal_entities_all rfea,
                   cll_f189_cities              rc,
                   cll_f189_invoice_types       rit
             WHERE ri.invoice_id = r_invoices.invoice_id
               AND ri.entity_id = rfea.entity_id
               AND ri.iss_city_id = rc.city_id -- (0002)
                  -- AND rfea.city_id = rc.city_id -- (0002)
                  --AND rc.iss_tax_type = 'SUBSTITUTE' -- 25028715
               AND rit.invoice_type_id = ri.invoice_type_id
               AND rit.include_iss_flag = 'Y';
          ELSE
            SELECT ROUND(NVL(SUM(NVL(ri.iss_amount, 0)), 0), 2)
              INTO v_iss_amount
              FROM cll_f189_invoices_interface  ri,
                   cll_f189_fiscal_entities_all rfea,
                   cll_f189_cities              rc,
                   cll_f189_invoice_types       rit
             WHERE ri.interface_invoice_id =
                   r_invoices.interface_invoice_id
               AND ri.entity_id = rfea.entity_id
               AND ri.iss_city_id = rc.city_id
                  --AND rc.iss_tax_type = 'SUBSTITUTE' -- 25028715
               AND rit.organization_id = p_organization_id -- BUG 19722064
               AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                   rit.invoice_type_code = ri.invoice_type_code) -- BUG 19722064
               AND rit.include_iss_flag = 'Y';
          END IF;

          -- 25028715 - Start
          IF r_invoices.include_iss_flag = 'Y' THEN

            IF l_iss_tax_type IN ('NORMAL', 'EXEMPT') THEN

            --IF CLL_F189_FISCAL_UTIL_PKG.GET_FISCAL_OBLIGATION_ISS(p_location_id,     -- 25591653
            --                                                      l_city_id) THEN    -- 25591653

            IF CLL_F189_ISS_TAX_PKG.GET_FISCAL_OBLIGATION_ISS( p_location_id           -- 25591653
                                                                ,l_line_city_id ) THEN -- 25591653
                v_iss_amount := 0;

              END IF;

            END IF;

          END IF;
          -- 25028715 - End */

          v_iss_amount := 0;

          IF r_invoices.include_iss_flag = 'Y' THEN

             IF p_interface = 'N' THEN

                FOR r_iss IN (SELECT ROUND(NVL(SUM(NVL(ril.iss_tax_amount, 0)), 0), 2) iss_tax_amount
                                    ,rcst.iss_tax_type
                                    ,ril.iss_city_id
                                FROM cll_f189_invoices ri
                                    ,cll_f189_invoice_lines ril
                                    ,cll_f189_city_srv_type_rels rcst
                                    ,cll_f189_invoice_types rit
                               WHERE ri.invoice_id = r_invoices.invoice_id
                                 AND ril.invoice_id = ri.invoice_id
                                 AND rcst.city_service_type_rel_id = ril.city_service_type_rel_id
                                 AND rit.invoice_type_id = ri.invoice_type_id
                                 AND rit.include_iss_flag = 'Y'
                               GROUP BY rcst.iss_tax_type
                                       ,ril.iss_city_id) LOOP
                    --
                    IF r_iss.iss_tax_type IN ('NORMAL', 'EXEMPT') THEN
                       --
                       IF CLL_F189_ISS_TAX_PKG.GET_FISCAL_OBLIGATION_ISS(p_location_id
                                                                        ,r_iss.iss_city_id) THEN
                          NULL;
                       ELSE
                          v_iss_amount := v_iss_amount + r_iss.iss_tax_amount;
                       END IF;
                       --
                    ELSE
                       --
                       v_iss_amount := v_iss_amount + r_iss.iss_tax_amount;
                       --
                    END IF;
                    --
                END LOOP;

             ELSE ---IF p_interface = 'N'

                FOR r_iss IN (SELECT ROUND(NVL(SUM(NVL(ril.iss_tax_amount, 0)), 0), 2) iss_tax_amount
                                    ,rcst.iss_tax_type
                                    ,cit.city_id iss_city_id
                                FROM cll_f189_invoices_interface  ri
                                    ,Cll_F189_Invoice_Lines_Iface ril
                                    ,cll_f189_city_srv_type_rels  rcst
                                    ,cll_f189_invoice_types       rit
                                    ,cll_f189_cities              cit
                               WHERE ri.interface_invoice_id = r_invoices.interface_invoice_id
                                 AND ril.interface_invoice_id = ri.interface_invoice_id
                                 AND (cit.city_id = ril.iss_city_id or
                                      cit.city_code = ril.iss_city_code)
                                 AND rcst.city_id = cit.city_id
                                 /*AND (rcst.city_service_type_rel_id = ril.city_service_type_rel_id or                                    -- 30652099
                                      rcst.city_service_type_rel_code = ril.city_service_type_rel_code)*/                                  -- 30652099
                                 AND rcst.city_service_type_rel_id   = NVL(ril.city_service_type_rel_id,rcst.city_service_type_rel_id)     -- 30652099
                                 AND rcst.city_service_type_rel_code = NVL(ril.city_service_type_rel_code,rcst.city_service_type_rel_code) -- 30652099
                                 AND rit.organization_id = p_organization_id
                                 AND (rit.invoice_type_id = ri.invoice_type_id OR
                                     rit.invoice_type_code = ri.invoice_type_code)
                                 AND rit.include_iss_flag = 'Y'
                               GROUP BY rcst.iss_tax_type
                                       ,cit.city_id) LOOP
                    --
                    IF r_iss.iss_tax_type IN ('NORMAL', 'EXEMPT') THEN
                       --
                       IF CLL_F189_ISS_TAX_PKG.GET_FISCAL_OBLIGATION_ISS(p_location_id
                                                                        ,r_iss.iss_city_id) THEN
                          NULL;
                       ELSE
                          v_iss_amount := v_iss_amount + r_iss.iss_tax_amount;
                       END IF;
                       --
                    ELSE
                       --
                       v_iss_amount := v_iss_amount + r_iss.iss_tax_amount;
                       --
                    END IF;
                    --
                END LOOP;

            END IF; ---IF p_interface = 'N'

          END IF; ---IF r_invoices.include_iss_flag = 'Y'
----25591653 end

          -- Bug 9156266 - SSimoes - 25/11/2009 - Inicio
          IF NVL(v_fed_withholding_tax_flag, 'C') = 'I' AND
             NVL(r_invoices.inss_calculation_flag, 'N') = 'Y' THEN
            IF r_invoices.inss_substitute_flag IS NULL OR
              --
               (r_invoices.inss_substitute_flag = 'S' AND -- INSS Substituto
               r_invoices.inss_tax IS NULL) OR
              --
               (r_invoices.inss_substitute_flag = 'D' AND -- INSS Despesa
               r_invoices.inss_tax IS NULL) OR
              --
               (r_invoices.inss_substitute_flag = 'A' AND -- INSS Substituto/Despesa
               ( -- Bug 9372419 - SSimoes - 15/02/2010
                (r_invoices.inss_tax IS NULL AND
                r_invoices.inss_autonomous_tax IS NULL) OR
                (r_invoices.inss_tax IS NOT NULL AND
                r_invoices.inss_autonomous_tax IS NULL) OR
                (r_invoices.inss_tax IS NULL AND
                r_invoices.inss_autonomous_tax IS NOT NULL)) -- Bug 9372419 - SSimoes - 15/02/010
               ) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INSS SETUP NOT FOUND',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'INSS SETUP NOT FOUND');
              END IF;
            END IF;
          END IF;
          -- Bug 9156266 - SSimoes - 25/11/2009 - Fim
          --
          -- Bug 17650106 - Start
          /*
          -- ER 14630226 -- Start
          IF NVL(v_fed_withholding_tax_flag,'C') = 'I' THEN
             IF r_invoices.inv_inss_tax IS NOT NULL AND r_invoices.inv_inss_tax <> r_invoices.inss_tax THEN

                IF p_interface = 'N' THEN
                   cll_f189_check_holds_pkg.incluir_erro_hold
                                                 (p_operation_id,
                                                  p_organization_id,
                                                  p_location_id,
                                                  'DIFF INSSTAXRATE INVOICE TYPE',
                                                  r_invoices.invoice_id,
                                                  ''
                                                 );
                ELSE
                   cll_f189_check_holds_pkg.incluir_erro
                                                 (r_invoices.interface_invoice_id,
                                                  p_operation_id,
                                                 'DIFF INSSTAXRATE INVOICE TYPE'
                                                 );
                END IF;
             END IF;
          ELSE
              IF r_invoices.inv_inss_tax IS NOT NULL AND r_invoices.inv_inss_tax <> r_invoices.comp_inss_tax THEN

                 IF p_interface = 'N' THEN
                         cll_f189_check_holds_pkg.incluir_erro_hold
                                                       (p_operation_id,
                                                        p_organization_id,
                                                        p_location_id,
                                                        'DIFF INSSTAXRATE COMPANY TYPES',
                                                        r_invoices.invoice_id,
                                                        ''
                                                        );
                 ELSE
                      cll_f189_check_holds_pkg.incluir_erro
                                                    (r_invoices.interface_invoice_id,
                                                     p_operation_id,
                                                    'DIFF INSSTAXRATE COMPANY TYPES'
                                                    );
                 END IF;

              END IF;
          END IF;
          -- ER 14630226 - End
          */
          -- Bug 17650106 - End
          --
          -- ER 17551029 5a Fase - Start
          IF r_invoices.cei_number IS NOT NULL AND
             r_invoices.caepf_number IS NOT NULL THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'CAEPF OR CEI NUMBER',
                                                         r_invoices.invoice_id,
                                                         '');
            END IF;
          END IF;
          --
          IF p_location_id IS NOT NULL THEN

            BEGIN
              SELECT document_number
                INTO l_esocial_doc_number
                FROM cll_f189_fiscal_entities_all
               WHERE location_id = p_location_id;
              --
              -- 18762109 - Start
              --CLL_F407_UTIL_PKG.REGISTRATIONS_P(l_esocial_doc_number,l_registration_id);
              --CLL_F407_UTIL_PKG.PARAMETERS_P(l_registration_id,l_esocial_start_date);

              l_legal_entity_id_f  := CLL_F407_UTILITY_PKG.GET_LEGAL_ENTITY_ID_F(p_organization_id);
              l_esocial_start_date := CLL_F407_UTILITY_PKG.GET_START_DATE_F(l_legal_entity_id_f);
              -- 18762109 - End
              --
            EXCEPTION
              WHEN OTHERS THEN
                l_esocial_start_date := NULL;
            END;
          END IF;
          --
          IF l_esocial_start_date IS NOT NULL
          AND TO_CHAR(r_invoices.invoice_date, 'YYYY-MM') > l_esocial_start_date -- 18762109
          AND NVL(r_invoices.inss_calculation_flag, 'N') = 'Y' THEN              -- 27508156/27357141
            --AND r_invoices.invoice_date > l_esocial_start_date THEN            -- 18762109
            -- Validacao CAEPF - Start
            IF r_invoices.caepf_number IS NOT NULL THEN
              IF l_document_type = 'CPF' THEN
                IF LENGTH(r_invoices.caepf_number) < 12 THEN
                  IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'CAEPF NUM LESS 12',
                                                               r_invoices.invoice_id,
                                                               '');
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                          p_operation_id,
                                                          'CAEPF NUM LESS 12');
                  END IF;
                END IF;
                --
                l_caepf_num          := lpad(substr(r_invoices.caepf_number,
                                                    1,
                                                    11),
                                             15,
                                             '0');
                l_validate_caepf_num := CLL_F189_DIGIT_CALC_PKG.FUNC_DOC_VALIDATION(l_document_type,
                                                                                    l_caepf_num);
                --
                IF l_validate_caepf_num = 0 THEN
                  IF p_interface = 'N' THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'INVALID DOCUMENT NUMBER',
                                                               r_invoices.invoice_id,
                                                               '');
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                          p_operation_id,
                                                          'INVALID DOCUMENT NUMBER');
                  END IF;
                END IF;
              END IF;
            END IF;
            -- Validacao CAEPF - End

            -- 27357141 - Start
            IF l_esocial_period_code <= TO_CHAR(r_invoices.invoice_date, 'YYYY-MM') THEN

               IF l_document_type = 'CPF' THEN

                  IF r_invoices.worker_category_id IS NULL THEN

                     IF p_interface = 'N' THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                  'WORKER CATEGORY REQUIRED',
                                                                  r_invoices.invoice_id,
                                                                  '');
                     ELSE
                       cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                             p_operation_id,
                                                             'WORKER CATEGORY REQUIRED');
                     END IF;

                  END IF;

                  IF r_invoices.department_id IS NULL THEN

                     IF p_interface = 'N' THEN
                       cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                  p_organization_id,
                                                                  p_location_id,
                                                                  'LOCATION CODE REQUIRED',
                                                                  r_invoices.invoice_id,
                                                                  '');
                     ELSE
                        cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                             p_operation_id,
                                                             'LOCATION CODE REQUIRED');
                     END IF;

                  END IF;

               END IF;

            END IF;
            -- 27357141 - End

            IF r_invoices.worker_category_id IS NOT NULL THEN

              -- 25808200 - 25808214 - Start
              IF l_esocial_period_code <=
                 TO_CHAR(r_invoices.invoice_date, 'YYYY-MM') THEN

                BEGIN
                  SELECT '1'
                    INTO l_worker_category
                    FROM cll_f407_suppl_categ_cod cfscc
                   WHERE cfscc.active_flag = 'Y'
                     AND TRUNC(SYSDATE) BETWEEN TRUNC(cfscc.start_date) AND
                         TRUNC(NVL(cfscc.end_date, SYSDATE))
                     AND cfscc.supplier_categ_code_id =
                         r_invoices.worker_category_id;
                EXCEPTION
                  WHEN no_data_found THEN

                    IF p_interface = 'N' THEN
                      cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                 p_organization_id,
                                                                 p_location_id,
                                                                 'INVALID WORKER CATEGORY',
                                                                 r_invoices.invoice_id,
                                                                 '');
                    ELSE
                      cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                            p_operation_id,
                                                            'INVALID WORKER CATEGORY');
                    END IF;

                END;

              ELSE
                -- 25808200 - 25808214 - End

                IF (NVL(r_invoices.freight_flag, 'N') = 'Y') THEN
                  BEGIN
                    SELECT '1'
                      INTO l_worker_category
                      FROM cll_f407_category_cbo_v
                     WHERE category_type = 'F'
                       AND category_cbo_id = r_invoices.worker_category_id;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN

                      IF p_interface = 'N' THEN
                        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                   p_organization_id,
                                                                   p_location_id,
                                                                   'INVALID WORKER CATEGORY',
                                                                   r_invoices.invoice_id,
                                                                   '');
                      ELSE
                        cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                              p_operation_id,
                                                              'INVALID WORKER CATEGORY');
                      END IF;
                  END;
                ELSE
                  BEGIN
                    SELECT '1'
                      INTO l_worker_category
                      FROM cll_f407_category_cbo_v
                     WHERE NVL(category_type, '*') <> 'F'
                       AND category_cbo_id = r_invoices.worker_category_id;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN

                      IF p_interface = 'N' THEN
                        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                                   p_organization_id,
                                                                   p_location_id,
                                                                   'INVALID WORKER CATEGORY',
                                                                   r_invoices.invoice_id,
                                                                   '');
                      ELSE
                        cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                              p_operation_id,
                                                              'INVALID WORKER CATEGORY');
                      END IF;
                  END;
                END IF;
              END IF;

            END IF; -- 25808200 - 25808214

          END IF;
          -- ER 17551029 5a Fase - End

          -- ER 21804594 - Start
          IF cll_f189_fiscal_util_pkg.get_icms_inter_no_taxpayer(p_organization_id,
                                                                 r_invoices.invoice_type_id,
                                                                 r_invoices.entity_id,
                                                                 r_invoices.destination_state_id,
                                                                 r_invoices.icms_type) THEN
            -- 23278226 - Start
            BEGIN
              IF (p_interface = 'N') THEN
                SELECT SUM(NVL(ril.icms_fcp_amount, 0)),
                       SUM(NVL(ril.icms_sharing_dest_amount, 0)),
                       SUM(NVL(ril.icms_sharing_source_amount, 0))
                  INTO l_icms_fcp_amount,
                       l_icms_sharing_dest_amount,
                       l_icms_sharing_source_amount
                  FROM cll_f189_invoice_lines ril
                 WHERE ril.invoice_id = r_invoices.invoice_id;
              ELSE
                SELECT SUM(NVL(ril.icms_fcp_amount, 0)),
                       SUM(NVL(ril.icms_sharing_dest_amount, 0)),
                       SUM(NVL(ril.icms_sharing_source_amount, 0))
                  INTO l_icms_fcp_amount,
                       l_icms_sharing_dest_amount,
                       l_icms_sharing_source_amount
                  FROM cll_f189_invoice_lines_iface ril
                 WHERE ril.interface_invoice_id =
                       r_invoices.interface_invoice_id;
              END IF;

              IF l_icms_fcp_amount <> NVL(r_invoices.icms_fcp_amount, 0) OR
                 l_icms_sharing_dest_amount <> NVL(r_invoices.icms_sharing_dest_amount, 0) OR
                 l_icms_sharing_source_amount <> NVL(r_invoices.icms_sharing_source_amount, 0) THEN

                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID TOTAL ICMS INT NO TAX',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID TOTAL ICMS INT NO TAX');
                END IF;
              END IF;
            EXCEPTION
              WHEN OTHERS THEN
                l_icms_fcp_amount            := NULL;
                l_icms_sharing_dest_amount   := NULL;
                l_icms_sharing_source_amount := NULL;
            END;
            -- 23278226 - End
            IF (NVL(r_invoices.icms_fcp_amount, 0) > 0 AND
               NVL(r_invoices.icms_sharing_dest_amount, 0) > 0 AND
               NVL(r_invoices.icms_sharing_source_amount, 0) > 0) OR
               (NVL(r_invoices.icms_fcp_amount, 0) = 0 AND
               NVL(r_invoices.icms_sharing_dest_amount, 0) > 0 AND
               NVL(r_invoices.icms_sharing_source_amount, 0) > 0) THEN

              IF r_invoices.rec_diff_icms_rma_source_ccid IS NULL THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE RCDF ICMS RMA SOURCE CCID',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE RCDF ICMS RMA SOURCE CCID');
                END IF;
              END IF;

              IF r_invoices.rec_diff_icms_rma_dest_ccid IS NULL THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE RCDF ICMS RMA DEST CCID',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE RCDF ICMS RMA DEST CCID');
                END IF;
              END IF;

              -- 26538915 - Start
              IF r_invoices.diff_icms_rma_source_red_ccid IS NULL THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE ICMS RMA SOURCE RED CCID',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE ICMS RMA SOURCE RED CCID');
                END IF;
              END IF;
              --
              IF r_invoices.diff_icms_rma_dest_red_ccid IS NULL THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE ICMS RMA DEST RED CCID',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE ICMS RMA DEST RED CCID');
                END IF;
              END IF;
              -- 26538915 - End

              IF r_invoices.rec_fcp_rma_ccid IS NULL AND
                 NVL(r_invoices.icms_fcp_amount, 0) > 0 THEN

                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE REC FCP RMA CCID',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE REC FCP RMA CCID');
                END IF;
              END IF;

              -- BUG 26880062 26880945 Begin
              IF r_invoices.red_fcp_rma_ccid IS NULL AND
                 NVL(r_invoices.icms_fcp_amount, 0) > 0 THEN

                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'NONE RED FCP RMA CCID',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'NONE RED FCP RMA CCID');
                END IF;
              END IF;
              -- BUG 26880062 26880945 End


              -- 23278226 - Start
              /*
                                   BEGIN
                                     IF (p_interface = 'N') THEN
                                        SELECT SUM(NVL(ril.icms_fcp_amount,0)),
                                               SUM(NVL(ril.icms_sharing_dest_amount,0)),
                                               SUM(NVL(ril.icms_sharing_source_amount,0))
                                          INTO l_icms_fcp_amount,
                                               l_icms_sharing_dest_amount,
                                               l_icms_sharing_source_amount
                                          FROM cll_f189_invoice_lines ril
                                         WHERE ril.invoice_id = r_invoices.invoice_id;
                                     ELSE
                                        SELECT SUM(NVL(ril.icms_fcp_amount,0)),
                                               SUM(NVL(ril.icms_sharing_dest_amount,0)),
                                               SUM(NVL(ril.icms_sharing_source_amount,0))
                                          INTO l_icms_fcp_amount,
                                               l_icms_sharing_dest_amount,
                                               l_icms_sharing_source_amount
                                          FROM cll_f189_invoice_lines_iface ril
                                         WHERE ril.interface_invoice_id = r_invoices.interface_invoice_id;
                                     END IF;

                                     IF l_icms_fcp_amount <> NVL(r_invoices.icms_fcp_amount,0) OR
                                        l_icms_sharing_dest_amount <> NVL(r_invoices.icms_sharing_dest_amount,0) OR
                                        l_icms_sharing_source_amount <> NVL(r_invoices.icms_sharing_source_amount,0) THEN

                                        IF (p_interface = 'N') THEN
                                           cll_f189_check_holds_pkg.incluir_erro_hold
                                                                         (p_operation_id,
                                                                          p_organization_id,
                                                                          p_location_id,
                                                                          'INVALID TOTAL ICMS INT NO TAX',
                                                                          r_invoices.invoice_id,
                                                                          ''
                                                                          );
                                        ELSE
                                           cll_f189_check_holds_pkg.incluir_erro
                                                               (r_invoices.interface_invoice_id,
                                                                p_operation_id,
                                                                'INVALID TOTAL ICMS INT NO TAX'
                                                                );
                                        END IF;
                                     END IF;
                                   EXCEPTION
                                        WHEN OTHERS THEN
                                             l_icms_fcp_amount := NULL;
                                             l_icms_sharing_dest_amount := NULL;
                                             l_icms_sharing_source_amount := NULL;
                                   END;
              */
              -- 23278226 - End
            ELSE
              -- 23278226 - Start
              IF (r_invoices.ICMS_FCP_AMOUNT IS NULL AND
                 r_invoices.ICMS_SHARING_DEST_AMOUNT IS NULL AND
                 r_invoices.ICMS_SHARING_SOURCE_AMOUNT IS NULL) OR
                 (r_invoices.ICMS_FCP_AMOUNT >= 0 AND -- bug 23754818
                 r_invoices.ICMS_SHARING_DEST_AMOUNT = 0 AND
                 r_invoices.ICMS_SHARING_SOURCE_AMOUNT = 0) OR
                 (NVL(r_invoices.ICMS_FCP_AMOUNT, 0) > 0 AND
                 NVL(r_invoices.ICMS_SHARING_DEST_AMOUNT, 0) > 0 AND
                 NVL(r_invoices.ICMS_SHARING_SOURCE_AMOUNT, 0) > 0) OR
                 (NVL(r_invoices.ICMS_FCP_AMOUNT, 0) = 0 AND
                 NVL(r_invoices.ICMS_SHARING_DEST_AMOUNT, 0) > 0 AND
                 NVL(r_invoices.ICMS_SHARING_SOURCE_AMOUNT, 0) > 0)
                 --- 27579815 Begin
                 OR
                 (NVL(r_invoices.ICMS_FCP_AMOUNT, 0) = 0 AND
                  NVL(r_invoices.ICMS_SHARING_DEST_AMOUNT, 0) > 0 AND
                  NVL(r_invoices.ICMS_SHARING_SOURCE_AMOUNT, 0) = 0)
                 OR
                 (NVL(r_invoices.ICMS_FCP_AMOUNT, 0) = 0 AND
                  NVL(r_invoices.ICMS_SHARING_DEST_AMOUNT, 0) = 0 AND
                  NVL(r_invoices.ICMS_SHARING_SOURCE_AMOUNT, 0) > 0)
                 OR
                 (NVL(r_invoices.ICMS_FCP_AMOUNT, 0) > 0 AND
                  NVL(r_invoices.ICMS_SHARING_DEST_AMOUNT, 0) > 0 AND
                  NVL(r_invoices.ICMS_SHARING_SOURCE_AMOUNT, 0) = 0)
                 OR
                 (NVL(r_invoices.ICMS_FCP_AMOUNT, 0) > 0 AND
                  NVL(r_invoices.ICMS_SHARING_DEST_AMOUNT, 0) = 0 AND
                  NVL(r_invoices.ICMS_SHARING_SOURCE_AMOUNT, 0) > 0)
                 --- 27579815 End
                 THEN
                NULL;
              ELSE
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'ICMS INT NO TAX REQ',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'ICMS INT NO TAX REQ');
                END IF;
              END IF;
              -- 23278226 - End
            END IF;
          ELSIF (NVL(r_invoices.icms_fcp_amount, 0) +
                NVL(r_invoices.icms_sharing_dest_amount, 0) +
                NVL(r_invoices.icms_sharing_source_amount, 0)) > 0 THEN
            IF (p_interface = 'N') THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ICMS INT NO TAX INV',
                                                         r_invoices.invoice_id,
                                                         '');
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'ICMS INT NO TAX INV');
            END IF;
          END IF;
          -- ER 21804594 - End

          -- 25713076 - Start
          IF r_invoices.requisition_type = 'RM' THEN

            IF r_invoices.rec_fcp_st_rma_ccid IS NULL AND
               NVL(r_invoices.total_fcp_st_amount, 0) > 0 THEN

              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE REC FCP ST RMA CCID',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE REC FCP ST RMA CCID');
              END IF;

            END IF;

            -- BUG 26880062 26880945 End
            IF r_invoices.red_fcp_st_rma_ccid IS NULL AND
               NVL(r_invoices.total_fcp_st_amount, 0) > 0 THEN

              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE RED FCP ST RMA CCID',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE RED FCP ST RMA CCID');
              END IF;

            END IF;
            -- BUG 26880062 26880945 End

          ELSE

            IF ((r_invoices.fcp_liability_ccid IS NULL) OR
               (r_invoices.fcp_asset_ccid IS NULL)) AND
               NVL(r_invoices.total_fcp_amount, 0) > 0 THEN

              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE FCP CCID',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE FCP CCID');
              END IF;

            END IF;

            IF ((r_invoices.fcp_st_liability_ccid IS NULL) OR
               (r_invoices.fcp_st_asset_ccid IS NULL)) AND
               NVL(r_invoices.total_fcp_st_amount, 0) > 0 THEN

              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'NONE FCP ST CCID',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'NONE FCP ST CCID');
              END IF;

            END IF;

          END IF;
          -- 25713076 - End

          -- ER 10091174 - Start
          IF NVL(v_fed_withholding_tax_flag, 'C') = 'I' AND
             NVL(r_invoices.inss_calculation_flag, 'N') = 'Y' AND
             r_invoices.rit_income_code IS NOT NULL THEN
            IF NVL(v_allow_upd_payment_term_flag, 'N') = 'Y' THEN
              BEGIN
                SELECT '1'
                  INTO v_validity_payment_term
                  FROM fnd_lookup_values_vl
                 WHERE lookup_type = 'CLL_F037_PAYMENT_CODES'
                   AND lookup_code = r_invoices.income_code
                   AND tag = 'GPS'
                   AND enabled_flag = 'Y'
                   AND SYSDATE between start_date_active AND
                       NVL(end_date_active, SYSDATE + 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'INVALID PAYTERM',
                                                               r_invoices.invoice_id,
                                                               '');
                  ELSE
                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                          p_operation_id,
                                                          'INVALID PAYTERM');
                  END IF;
              END;
            ELSE
              IF r_invoices.income_code <> r_invoices.rit_income_code THEN
                --Payment Term Invoice Type

                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID PAYTERM',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID PAYTERM');
                END IF;
              END IF;
            END IF;
          ELSIF NVL(v_fed_withholding_tax_flag, 'C') = 'C' AND
                NVL(r_invoices.inss_calculation_flag, 'N') = 'Y' AND
                r_invoices.rbv_income_code IS NOT NULL THEN
            IF NVL(v_allow_upd_payment_term_flag, 'N') = 'Y' THEN
              BEGIN
                SELECT '1'
                  INTO v_validity_payment_term
                  FROM fnd_lookup_values_vl
                 WHERE lookup_type = 'CLL_F037_PAYMENT_CODES'
                   AND lookup_code = r_invoices.income_code
                   AND tag = 'GPS'
                   AND enabled_flag = 'Y'
                   AND SYSDATE between start_date_active AND
                       NVL(end_date_active, SYSDATE + 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF (p_interface = 'N') THEN
                    cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                               p_organization_id,
                                                               p_location_id,
                                                               'INVALID PAYTERM',
                                                               r_invoices.invoice_id,
                                                               '');
                  ELSE

                    cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                          p_operation_id,
                                                          'INVALID PAYTERM');
                  END IF;
              END;
            ELSE
              IF r_invoices.income_code <> r_invoices.rbv_income_code THEN
                --Payment Term Company Type
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID PAYTERM',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID PAYTERM');
                END IF;
              END IF;
            END IF;
          END IF;
          -- ER 10091174 - End
          --
          -- ER 9923702 - Start
          --SEST SENAT INCOME CODE VALIDATION
          --
          IF r_invoices.sest_senat_income_code IS NOT NULL THEN

            BEGIN
              SELECT '1'
                INTO v_validity_payment_term
                FROM fnd_lookup_values_vl
               WHERE lookup_type = 'CLL_F037_PAYMENT_CODES'
                 AND lookup_code = r_invoices.sest_senat_income_code
                 AND tag = 'GPS'
                 AND enabled_flag = 'Y'
                 AND SYSDATE between start_date_active AND
                     NVL(end_date_active, SYSDATE + 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'SESTSENAT INV INCOMECODE',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE

                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'SESTSENAT INV INCOMECODE');
                END IF;
            END;
          END IF;
          --
          --FUNRURAL INCOME CODE VALIDATION
          --
          IF r_invoices.funrural_income_code IS NOT NULL THEN
            BEGIN
              SELECT '1'
                INTO v_validity_payment_term
                FROM fnd_lookup_values_vl
               WHERE lookup_type = 'CLL_F037_PAYMENT_CODES'
                 AND lookup_code = r_invoices.funrural_income_code
                 AND tag = 'GPS'
                 AND enabled_flag = 'Y'
                 AND SYSDATE between start_date_active AND
                     NVL(end_date_active, SYSDATE + 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                IF (p_interface = 'N') THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'RURALINSS INV INCOMECODE',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'RURALINSS INV INCOMECODE');
                END IF;
            END;
          END IF;
          -- ER 9923702 - End
          --
          -- Bug 17835378 - Start
          IF r_invoices.return_cfo_id IS NOT NULL THEN
            BEGIN
              SELECT Count(1)
                INTO l_return_cfo_id
                FROM cll_f189_fiscal_operations
               WHERE return_flag = 'Y'
                 AND (inactive_date IS NULL OR inactive_date > sysdate)
                 AND cfo_id = r_invoices.return_cfo_id
               ORDER BY cfo_code;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                l_return_cfo_id := 0;
            END;
            IF l_return_cfo_id = 0 THEN
              IF (p_interface = 'N') THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID RETURN CFO',
                                                           r_invoices.invoice_id,
                                                           NULL);
              ELSE
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID RETURN CFO',
                                                           r_invoices.invoice_id,
                                                           NULL);
              END IF;
            END IF;
          END IF;
          -- Bug 17835378 - End
          -- Inicio BUG 21895963
          BEGIN
            SELECT MINIMUM_TAX_AMOUNT
              INTO x_minimum_tax_amount
              FROM CLL_F189_TAX_SITES
             WHERE ORGANIZATION_ID = p_organization_id
               AND TAX_TYPE = 'INSS';
          EXCEPTION
            WHEN OTHERS THEN
              x_minimum_tax_amount := null;
          END;
          -- Fim BUG 21895963
          --
          IF (NVL(r_invoices.inss_substitute_flag, 'N') IN ('S', 'N')) THEN
            -- Bug 9156266
            IF r_invoices.inss_substitute_flag = 'S' AND
               (NVL(r_invoices.inss_additional_amount_1, 0) <> 0 OR
               NVL(r_invoices.inss_additional_amount_2, 0) <> 0 OR
               NVL(r_invoices.inss_additional_amount_3, 0) <> 0) THEN
              -- Inicio Bug 21895963
              IF l_document_type = 'CNPJ' AND
                 NVL(r_invoices.inss_amount, 0) < x_minimum_tax_amount THEN
                v_sum_total_amount_nf   := v_sum_total_amount -
                                           NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                v_sum_total_amount_nf_r := v_sum_total_amount_round -
                                           NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                v_sum_total_amount_nf_t := v_sum_total_amount_trunc -
                                           NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                -- Fim Bug 21895963
              ELSE
                v_sum_total_amount_nf   := v_sum_total_amount
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.inss_amount, 0) -
                                           NVL(r_invoices.inss_additional_amount_1,
                                               0) - NVL(r_invoices.inss_additional_amount_2,
                                                        0) -
                                           NVL(r_invoices.inss_additional_amount_3,
                                               0) - NVL(r_invoices.funrural_amount,
                                                        0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                v_sum_total_amount_nf_r := v_sum_total_amount_round
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.inss_amount, 0) -
                                           NVL(r_invoices.inss_additional_amount_1,
                                               0) - NVL(r_invoices.inss_additional_amount_2,
                                                        0) -
                                           NVL(r_invoices.inss_additional_amount_3,
                                               0) - NVL(r_invoices.funrural_amount,
                                                        0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                v_sum_total_amount_nf_t := v_sum_total_amount_trunc
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.inss_amount, 0) -
                                           NVL(r_invoices.inss_additional_amount_1,
                                               0) - NVL(r_invoices.inss_additional_amount_2,
                                                        0) -
                                           NVL(r_invoices.inss_additional_amount_3,
                                               0) - NVL(r_invoices.funrural_amount,
                                                        0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
              END IF;
            ELSE
              -- Inicio Bug 21895963
              IF l_document_type = 'CNPJ' AND
                 NVL(r_invoices.inss_amount, 0) < x_minimum_tax_amount THEN
                v_sum_total_amount_nf   := v_sum_total_amount
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                v_sum_total_amount_nf_r := v_sum_total_amount_round
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                v_sum_total_amount_nf_t := v_sum_total_amount_trunc
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                -- Fim Bug 21895963
              ELSE
                v_sum_total_amount_nf   := v_sum_total_amount
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.inss_amount, 0) -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                v_sum_total_amount_nf_r := v_sum_total_amount_round
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.inss_amount, 0) -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
                v_sum_total_amount_nf_t := v_sum_total_amount_trunc
                                          --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                           - NVL(v_iss_amount, 0) -
                                           v_ir_amount -
                                           NVL(r_invoices.inss_amount, 0) -
                                           NVL(r_invoices.funrural_amount,
                                               0) -- Bug 9156266
                                           - NVL(r_invoices.sest_senat_amount,
                                                 0) -- Bug 9156266
                                           + NVL(v_sum_pis_imp_amount, 0) --
                                           +NVL(v_sum_cofins_imp_amount, 0); --
              END IF;
            END IF;
          ELSIF r_invoices.inss_substitute_flag = 'A' THEN
            v_sum_total_amount_nf   := v_sum_total_amount
                                      --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                       - NVL(v_iss_amount, 0) - v_ir_amount -
                                       NVL(r_invoices.inss_autonomous_amount,
                                           0) -
                                       NVL(r_invoices.funrural_amount, 0) -- Bug 9156266
                                       - NVL(r_invoices.sest_senat_amount,
                                             0) -- Bug 9156266
                                       + NVL(v_sum_pis_imp_amount, 0) --
                                       +NVL(v_sum_cofins_imp_amount, 0); --
            v_sum_total_amount_nf_r := v_sum_total_amount_round
                                      --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                       - NVL(v_iss_amount, 0) - v_ir_amount -
                                       NVL(r_invoices.inss_autonomous_amount,
                                           0) -
                                       NVL(r_invoices.funrural_amount, 0) -- Bug 9156266
                                       - NVL(r_invoices.sest_senat_amount,
                                             0) -- Bug 9156266
                                       + NVL(v_sum_pis_imp_amount, 0) --
                                       +NVL(v_sum_cofins_imp_amount, 0); --
            v_sum_total_amount_nf_t := v_sum_total_amount_trunc
                                      --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                       - NVL(v_iss_amount, 0) - v_ir_amount -
                                       NVL(r_invoices.inss_autonomous_amount,
                                           0) -
                                       NVL(r_invoices.funrural_amount, 0) -- Bug 9156266
                                       - NVL(r_invoices.sest_senat_amount,
                                             0) -- Bug 9156266
                                       + NVL(v_sum_pis_imp_amount, 0) --
                                       +NVL(v_sum_cofins_imp_amount, 0); --
          ELSIF r_invoices.inss_substitute_flag = 'D' THEN
            v_sum_total_amount_nf   := v_sum_total_amount
                                      --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                       - NVL(v_iss_amount, 0) - v_ir_amount -
                                       NVL(r_invoices.funrural_amount, 0) -- Bug 9156266
                                       - NVL(r_invoices.sest_senat_amount,
                                             0) -- Bug 9156266
                                       + NVL(v_sum_pis_imp_amount, 0) --
                                       +NVL(v_sum_cofins_imp_amount, 0); --
            v_sum_total_amount_nf_r := v_sum_total_amount_round
                                      --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                       - NVL(v_iss_amount, 0) - v_ir_amount -
                                       NVL(r_invoices.funrural_amount, 0) -- Bug 9156266
                                       - NVL(r_invoices.sest_senat_amount,
                                             0) -- Bug 9156266
                                       + NVL(v_sum_pis_imp_amount, 0) --
                                       +NVL(v_sum_cofins_imp_amount, 0); --
            v_sum_total_amount_nf_t := v_sum_total_amount_trunc
                                      --+ NVL (r_invoices.other_expenses, 0) -- BUG 18096092
                                       - NVL(v_iss_amount, 0) - v_ir_amount -
                                       NVL(r_invoices.funrural_amount, 0) -- Bug 9156266
                                       - NVL(r_invoices.sest_senat_amount,
                                             0) -- Bug 9156266
                                       + NVL(v_sum_pis_imp_amount, 0) --
                                       +NVL(v_sum_cofins_imp_amount, 0); --
          END IF;
          --
          IF r_invoices.import_icms_flag IN ('Y', 'D') THEN
            v_sum_total_amount_nf   := v_sum_total_amount_nf +
                                       NVL(r_invoices.icms_amount, 0);
            v_sum_total_amount_nf_r := v_sum_total_amount_nf_r +
                                       NVL(r_invoices.icms_amount, 0);
            v_sum_total_amount_nf_t := v_sum_total_amount_nf_t +
                                       NVL(r_invoices.icms_amount, 0);
          END IF;
          /*
           IF r_invoices.icms_type <> 'EARLY SUBSTITUTE' THEN           -- ER 4509645 --
             IF r_invoices.exclude_icms_st_flag = 'Y' THEN
               v_sum_total_amount_nf   := v_sum_total_amount_nf - NVL(x_sum_icms_st_amount,0);
               v_sum_total_amount_nf_r := v_sum_total_amount_nf_r - NVL(x_sum_icms_st_amount,0);
               v_sum_total_amount_nf_t := v_sum_total_amount_nf_t - NVL(r_invoices.icms_amount,0);
             END IF;
           END IF;                                                           -- ER 4509645 --
          */
          -- ER 5089320 - Start
          IF r_invoices.icms_type = 'EXEMPT' THEN
            SELECT rs.national_state
              INTO w_aux_national_state
              FROM cll_f189_states rs, cll_f189_fiscal_entities_all rfea
             WHERE rfea.entity_id = r_invoices.entity_id
               AND rfea.state_id = rs.state_id;
            IF w_aux_national_state = 'Y' THEN
              BEGIN
                SELECT free_trade_zone_flag
                  INTO w_free_trade_zone_flag
                  FROM cll_f189_fiscal_entities_all
                 WHERE location_id = p_location_id;

              -- 29883104 - Start
              /*IF w_free_trade_zone_flag = 'Y' THEN
                  v_sum_total_amount_nf   := v_sum_total_amount_nf -
                                             NVL(v_sum_pres_icms_amount, 0);
                  v_sum_total_amount_nf_r := v_sum_total_amount_nf_r -
                                             NVL(v_sum_pres_icms_amount_round,
                                                 0);
                  v_sum_total_amount_nf_t := v_sum_total_amount_nf_t -
                                             NVL(v_sum_pres_icms_amount_trunc,
                                                 0);
                END IF;*/
                -- 29883104 - End

              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  raise_application_error(-20701,
                                          SQLERRM ||
                                          '*********************' ||
                                          ' Select Total invoice lines ' ||
                                          '*********************');
                WHEN TOO_MANY_ROWS THEN
                  raise_application_error(-20702,
                                          SQLERRM ||
                                          '*********************' ||
                                          ' Select Total invoice lines ' ||
                                          '*********************');
                WHEN OTHERS THEN
                  raise_application_error(-20703,
                                          SQLERRM ||
                                          '*********************' ||
                                          ' Select Total invoice lines ' ||
                                          '*********************');
              END;
            END IF;
          END IF;
          -- ER 5089320 - End

          --
          -- BUG 17056156 - Start
          --
          BEGIN
            --
            SELECT SUM(NVL(ril.fundersul_amount, 0))
              INTO l_fundersul_amount
              FROM cll_f189_invoice_lines ril
             WHERE ril.invoice_id = r_invoices.invoice_id;
            --
          EXCEPTION
            WHEN OTHERS THEN
              l_fundersul_amount := NULL;
          END;
          --
          v_sum_total_amount_nf   := v_sum_total_amount_nf -
                                     NVL(l_fundersul_amount, 0);
          v_sum_total_amount_nf_r := v_sum_total_amount_nf_r -
                                     NVL(l_fundersul_amount, 0);
          v_sum_total_amount_nf_t := v_sum_total_amount_nf_t -
                                     NVL(l_fundersul_amount, 0);
          --
          -- BUG 17056156 - End
          --
          -- ER 14124731 - Start
        --IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'Y' THEN                 -- 27579747
          IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
          AND p_interface = 'Y' THEN                                                     -- 27579747
            NULL;
          ELSE
            -- ER 14124731 - End
           IF ROUND(v_sum_total_amount_nf, arr) <>
               ROUND(r_invoices.invoice_amount, arr) AND
               TRUNC(v_sum_total_amount_nf, arr) <>
               TRUNC(r_invoices.invoice_amount, arr) AND
               TRUNC(v_sum_total_amount_nf_t, arr) <>
               TRUNC(r_invoices.invoice_amount, arr) AND
               ROUND(v_sum_total_amount_nf_r, arr) <>
               ROUND(r_invoices.invoice_amount, arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF INVOICE AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DIFF INVOICE AMOUNT');
              END IF;
            END IF;
          END IF; -- ER 14124731
          --

          -- INICIO Gmonzano ER 25134545
          v_sum_amount_lines_parent := 0;
          v_sum_amount_lines_amount := 0;
          BEGIN

            IF (R_INVOICES.composition_invoice_flag = 'Y' and
               R_INVOICES.parent_flag = 'Y') THEN
              --
              IF p_interface = 'N' THEN
                BEGIN

                  SELECT NVL(SUM(clli2.invoice_amount), 0)
                    INTO v_sum_amount_lines_parent
                    FROM cll_f189_invoice_parents cllip,
                         cll_f189_invoices        clli,
                         cll_f189_invoice_types   clit,
                         cll_f189_invoices        clli2
                   WHERE clli.invoice_id = r_invoices.invoice_id
                     AND cllip.invoice_id = clli.invoice_id
                     AND clli.invoice_type_id = clit.invoice_type_id
                     AND clit.parent_flag = 'Y'
                     AND clit.composition_invoice_flag = 'Y'
                     AND cllip.invoice_parent_id = clli2.invoice_id;
                EXCEPTION
                  WHEN others THEN
                    l_sqlerrm := SQLERRM;
                END;

                IF v_sum_amount_lines_parent <> R_INVOICES.invoice_amount THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INV AMT DIFF PARENT',
                                                             r_invoices.invoice_id,
                                                             '');
                END IF;

              ELSIF p_interface = 'Y' THEN
                BEGIN
                  SELECT NVL(SUM(clli2.invoice_amount), 0)
                    INTO v_sum_amount_lines_amount
                    FROM cll_f189_invoice_parents_int cllip,
                         CLL_F189_INVOICES_INTERFACE  clli,
                         cll_f189_invoice_types       clit,
                         cll_f189_invoices            clli2
                   WHERE clli.interface_invoice_id =
                         r_invoices.interface_invoice_id
                     AND cllip.interface_invoice_id =
                         clli.interface_invoice_id
                     AND clli.invoice_type_id = clit.invoice_type_id
                     AND clit.parent_flag = 'Y'
                     AND clit.composition_invoice_flag = 'Y'
                     AND cllip.invoice_parent_id = clli2.invoice_id;
                EXCEPTION
                  WHEN others THEN
                    l_sqlerrm := SQLERRM;
                END;

                IF v_sum_amount_lines_amount <> R_INVOICES.invoice_amount THEN

                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'INV AMT DIFF PARENT');
                END IF;

              END IF;
              --
            END IF;
            --
          END; --
          --
          BEGIN
            --
            v_parent_associated     := 0;
            v_parent_associated_int := 0;

            IF (R_INVOICES.composition_invoice_flag = 'Y' and
               R_INVOICES.parent_flag = 'Y') THEN

              IF p_interface = 'N' THEN
                BEGIN
                  SELECT COUNT(*)
                    INTO v_parent_associated
                    FROM (SELECT PARENT.INVOICE_PARENT_ID, PARENT.INVOICE_ID
                            FROM CLL_F189_INVOICE_PARENTS PARENT
                           WHERE PARENT.INVOICE_ID = r_invoices.invoice_id
                             AND EXISTS
                           (SELECT PARENT1.INVOICE_ID
                                    FROM CLL_F189_INVOICE_PARENTS  PARENT1,
                                         CLL_F189_INVOICES         RI1,
                                         CLL_F189_ENTRY_OPERATIONS CEO
                                   WHERE PARENT1.INVOICE_PARENT_ID =
                                         PARENT.INVOICE_PARENT_ID
                                     AND PARENT1.INVOICE_ID <>
                                         PARENT.INVOICE_ID
                                     AND PARENT1.INVOICE_ID = RI1.INVOICE_ID
                                     AND RI1.OPERATION_ID = CEO.OPERATION_ID
                                     AND RI1.ORGANIZATION_ID =
                                         CEO.ORGANIZATION_ID
                                     AND CEO.STATUS = 'COMPLETE'));
                EXCEPTION
                  WHEN others THEN
                    l_sqlerrm := SQLERRM;
                END;

                IF v_parent_associated > 0 THEN

                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INV PAR CONC ASSOCIATED',
                                                             r_invoices.invoice_id,
                                                             '');
                END IF;
              ELSIF p_interface = 'Y' THEN
                -- ELSE

                BEGIN
                  SELECT NVL(COUNT(*), 0)
                    INTO v_parent_associated_int
                    FROM CLL_F189_INVOICES_INTERFACE  CFII,
                         CLL_F189_INVOICE_PARENTS_INT CFIP
                   WHERE CFII.INTERFACE_INVOICE_ID =
                         r_invoices.interface_invoice_id
                     AND CFII.invoice_parent_id = CFIP.invoice_parent_id
                   GROUP BY CFIP.invoice_parent_id;
                EXCEPTION
                  WHEN others THEN
                    l_sqlerrm := SQLERRM;

                END;

                IF v_parent_associated_int > 1 THEN

                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'INV PAR CONC ASSOCIATED');
                END IF;
              END IF;
            END IF;
          END; -- Fim Gmonzano ER 25134545

          --
          IF arr = 0 THEN
            w_arr := 0;
          ELSE
            -- Bug 9977332 - Gsantos - 22/09/2010 - Inicio
            -- w_arr := arr - 1;
            w_arr := arr;
            -- Bug 9977332 - Gsantos - 22/09/2010 - Fim
          END IF;
          --
          -- ER 14124731 - Start
        --IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'Y' THEN                 -- 27579747
          IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
          AND p_interface = 'Y' THEN                                                     -- 27579747
            NULL;
          ELSE
            -- ER 14124731 - End
            --
            IF ROUND(v_sum_total_icms, w_arr) <>
               ROUND(r_invoices.icms_amount, w_arr) AND
               TRUNC(v_sum_total_icms, w_arr) <>
               TRUNC(r_invoices.icms_amount, w_arr) AND
               v_sum_total_icms_round <>
               ROUND(r_invoices.icms_amount, w_arr) AND
               v_sum_total_icms_trunc <>
               TRUNC(r_invoices.icms_amount, w_arr) AND
               ( -- ER 9289619
                (r_invoices.simplified_br_tax_flag = 'N') OR
                (r_invoices.simplified_br_tax_flag = 'Y' AND
                p_interface = 'Y')) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF ICMS AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DIFF ICMS AMOUNT');
              END IF;
            END IF;
            --
            IF UPPER(r_invoices.icms_type) <> 'INV LINES INF' THEN
              -- ER 9028781

              IF ROUND(v_sum_base_icms, arr) <>
                 ROUND(r_invoices.icms_base, arr) AND
                 TRUNC(v_sum_base_icms, arr) <>
                 TRUNC(r_invoices.icms_base, arr) AND
                 TRUNC(v_sum_base_icms, arr) <>
                 ROUND(r_invoices.icms_base, arr) AND
                 v_sum_base_icms_round <> ROUND(r_invoices.icms_base, arr) AND
                 v_sum_base_icms_trunc <> TRUNC(r_invoices.icms_base, arr) AND
                 ( -- ER 9289619
                  (r_invoices.simplified_br_tax_flag = 'N') OR
                  (r_invoices.simplified_br_tax_flag = 'Y' AND
                  p_interface = 'Y')) THEN
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'DIFF ICMS BASE',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'DIFF ICMS BASE');
                END IF;
              END IF;

            END IF; -- ER 9028781

            -- ER 5089320
            IF ROUND(v_sum_pres_icms_amount, arr) <>
               ROUND(r_invoices.presumed_icms_tax_amount, arr) AND
               TRUNC(v_sum_pres_icms_amount, arr) <>
               TRUNC(r_invoices.presumed_icms_tax_amount, arr) AND
               TRUNC(v_sum_pres_icms_amount, arr) <>
               ROUND(r_invoices.presumed_icms_tax_amount, arr) AND
               v_sum_pres_icms_amount_round <>
               ROUND(r_invoices.presumed_icms_tax_amount, arr) AND
               v_sum_pres_icms_amount_trunc <>
               TRUNC(r_invoices.presumed_icms_tax_amount, arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF PRESUMED ICMS AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DIFF PRESUMED ICMS AMOUNT');
              END IF;
            END IF;

            -- PIS ST total amount
            IF ROUND(v_sum_pis_st_amount, w_arr) <>
               ROUND(r_invoices.pis_st_amount, w_arr) AND
               TRUNC(v_sum_pis_st_amount, w_arr) <>
               TRUNC(r_invoices.pis_st_amount, w_arr) AND
               v_sum_pis_st_amount_round <>
               ROUND(r_invoices.pis_st_amount, w_arr) AND
               v_sum_pis_st_amount_trunc <>
               TRUNC(r_invoices.pis_st_amount, w_arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF PIS ST AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id, -- Bug.4063693
                                                      p_operation_id, -- Bug.4063693
                                                      'DIFF PIS ST AMOUNT'); -- Bug.4063693
              END IF;
            END IF;
            -- COFINS ST total amount
            IF ROUND(v_sum_cofins_st_amount, w_arr) <>
               ROUND(r_invoices.cofins_st_amount, w_arr) AND
               TRUNC(v_sum_cofins_st_amount, w_arr) <>
               TRUNC(r_invoices.cofins_st_amount, w_arr) AND
               v_sum_cofins_st_amount_round <>
               ROUND(r_invoices.cofins_st_amount, w_arr) AND
               v_sum_cofins_st_amount_trunc <>
               TRUNC(r_invoices.cofins_st_amount, w_arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF COFINS ST AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id, -- Bug.4063693
                                                      p_operation_id, -- Bug.4063693
                                                      'DIFF COFINS ST AMOUNT'); -- Bug.4063693
              END IF;
            END IF;
            -- PIS/COFINS ST base amount
            IF ROUND(v_sum_pis_cofins_st_base, arr) <>
               ROUND(r_invoices.pis_cofins_st_base, arr) AND
               TRUNC(v_sum_pis_cofins_st_base, arr) <>
               TRUNC(r_invoices.pis_cofins_st_base, arr) AND
               TRUNC(v_sum_pis_cofins_st_base, arr) <>
               ROUND(r_invoices.pis_cofins_st_base, arr) AND
               v_sum_pis_cofins_st_base_round <>
               ROUND(r_invoices.pis_cofins_st_base, arr) AND
               v_sum_pis_cofins_st_base_trunc <>
               TRUNC(r_invoices.pis_cofins_st_base, arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF PIS COFINS ST BASE',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id, -- Bug.4063693
                                                      p_operation_id, -- Bug.4063693
                                                      'DIFF PIS COFINS ST BASE'); -- Bug.4063693
              END IF;
            END IF;
            -- IPI total amount
            IF ROUND(v_sum_ipi_amount, w_arr) <>
               ROUND(r_invoices.ipi_amount, w_arr) AND
               TRUNC(v_sum_ipi_amount, w_arr) <>
               TRUNC(r_invoices.ipi_amount, w_arr) AND
               v_sum_ipi_amount_round <>
               ROUND(r_invoices.ipi_amount, w_arr) AND
               v_sum_ipi_amount_trunc <>
               TRUNC(r_invoices.ipi_amount, w_arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF IPI AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DIFF IPI AMOUNT');
              END IF;
            END IF;
            --
            -- 25713076 - Start
            --
            -- Total FCP amount
            IF ROUND(l_sum_fcp_amount, w_arr) <>
               ROUND(r_invoices.total_fcp_amount, w_arr) AND
               TRUNC(l_sum_fcp_amount, w_arr) <>
               TRUNC(r_invoices.total_fcp_amount, w_arr) AND
               l_sum_fcp_amount_round <>
               ROUND(r_invoices.total_fcp_amount, w_arr) AND
               l_sum_fcp_amount_trunc <>
               TRUNC(r_invoices.total_fcp_amount, w_arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF FCP AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DIFF FCP AMOUNT');
              END IF;
            END IF;

            -- Total FCP ST amount
            IF ROUND(l_sum_fcp_st_amount, w_arr) <>
               ROUND(r_invoices.total_fcp_st_amount, w_arr) AND
               TRUNC(l_sum_fcp_st_amount, w_arr) <>
               TRUNC(r_invoices.total_fcp_st_amount, w_arr) AND
               l_sum_fcp_st_amount_round <>
               ROUND(r_invoices.total_fcp_st_amount, w_arr) AND
               l_sum_fcp_st_amount_trunc <>
               TRUNC(r_invoices.total_fcp_st_amount, w_arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF FCP ST AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DIFF FCP ST AMOUNT');
              END IF;
            END IF;

          END IF; -- ER 14124731
          -- Bug 20655988

          IF NVL(r_invoices.include_iss_flag, 'N') = 'N' THEN
            -- ER 22370431 Start
            IF r_invoices.iss_city_id IS NOT NULL AND
               NVL(r_invoices.iss_amount, 0) = 0 AND
               NVL(r_invoices.iss_base, 0) = 0 THEN

              IF p_interface = 'N' THEN
                SELECT COUNT(1)
                  INTO l_exists_service_type
                  FROM cll_f189_invoice_lines
                 WHERE invoice_id = r_invoices.invoice_id
                   AND city_service_type_rel_id IS NOT NULL;
              ELSE
                SELECT COUNT(1)
                  INTO l_exists_service_type
                  FROM cll_f189_invoice_lines_iface
                 WHERE invoice_id = r_invoices.interface_invoice_id
                   AND city_service_type_rel_id IS NOT NULL;
              END IF;

              IF l_exists_service_type = 0 THEN
                IF p_interface = 'N' THEN
                  cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                             p_organization_id,
                                                             p_location_id,
                                                             'INVALID ISS TYPE',
                                                             r_invoices.invoice_id,
                                                             '');
                ELSE
                  cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                        p_operation_id,
                                                        'INVALID ISS TYPE');
                END IF;
              END IF;
              -- ER 22370431 End
            ELSIF ((r_invoices.iss_amount IS NOT NULL AND
                  r_invoices.iss_amount <> 0) OR (r_invoices.iss_base IS NOT NULL AND
                  r_invoices.iss_base <> 0) OR
                  (r_invoices.iss_city_id IS NOT NULL)
                  ) THEN

              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'INVALID ISS TYPE',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'INVALID ISS TYPE');
              END IF;
            END IF;
          ELSE
            -- ER 6519914 - SSimoes - 15/05/2008 - Inicio
            -- Consistencia do Valor total do ISS
            IF ROUND(v_sum_iss_amount, w_arr) <>
               ROUND(r_invoices.iss_amount, w_arr) AND
               TRUNC(v_sum_iss_amount, w_arr) <>
               TRUNC(r_invoices.iss_amount, w_arr) AND
               v_sum_iss_amount_round <>
               ROUND(r_invoices.iss_amount, w_arr) AND
               v_sum_iss_amount_trunc <>
               TRUNC(r_invoices.iss_amount, w_arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF ISS AMOUNT',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DIFF ISS AMOUNT');
              END IF;
            END IF;

            -- Consistencia do Valor da Base do ISS
            IF ROUND(v_sum_iss_base_amount, w_arr) <>
               ROUND(r_invoices.iss_base, w_arr) AND
               TRUNC(v_sum_iss_base_amount, w_arr) <>
               TRUNC(r_invoices.iss_base, w_arr) AND
               v_sum_iss_base_amount_round <>
               ROUND(r_invoices.iss_base, w_arr) AND
               v_sum_iss_base_amount_trunc <>
               TRUNC(r_invoices.iss_base, w_arr) THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'DIFF ISS BASE',
                                                           r_invoices.invoice_id,
                                                           '');
              ELSE
                cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                      p_operation_id,
                                                      'DIFF ISS BASE');
              END IF;
            END IF;
            -- ER 6519914 - SSimoes - 15/05/2008 - Fim

          END IF; -- Bug 20655988

          -- Other expenses
          -- Header
          IF p_interface = 'N' THEN
            BEGIN
              SELECT NVL(SUM(NVL(ri.other_expenses, 0)), 0)
                INTO v_nf_other_expenses
                FROM cll_f189_invoices ri
               WHERE ri.operation_id = p_operation_id
                 AND ri.organization_id = p_organization_id;
            EXCEPTION
              WHEN OTHERS THEN
                v_nf_other_expenses := -1;
            END;
          ELSE
            BEGIN
              SELECT NVL(SUM(NVL(ri.other_expenses, 0)), 0)
                INTO v_nf_other_expenses
                FROM cll_f189_invoices_interface ri
               WHERE ri.interface_operation_id = p_operation_id
                 AND ri.organization_id = p_organization_id;
            EXCEPTION
              WHEN OTHERS THEN
                v_nf_other_expenses := -1;
            END;
          END IF;

          ------------
          -- Linhas --
          ------------
          IF p_interface = 'N' THEN
            BEGIN
              SELECT NVL(SUM(NVL(ril.other_expenses, 0)), 0)
                INTO v_linhas_other_expenses
                FROM cll_f189_invoice_lines ril, cll_f189_invoices ri
               WHERE ri.operation_id = p_operation_id
                 AND ri.organization_id = p_organization_id
                 AND ril.invoice_id = ri.invoice_id;
            EXCEPTION
              WHEN OTHERS THEN
                v_linhas_other_expenses := -2;
            END;
          ELSE
            BEGIN
              SELECT NVL(SUM(NVL(ril.other_expenses, 0)), 0)
                INTO v_linhas_other_expenses
                FROM CLL_F189_INVOICE_LINES_IFACE ril,
                     cll_f189_invoices_interface  ri
               WHERE ri.interface_operation_id = p_operation_id
                 AND ri.organization_id = p_organization_id
                 AND ril.interface_invoice_id = ri.interface_invoice_id;
            EXCEPTION
              WHEN OTHERS THEN
                v_linhas_other_expenses := -2;
            END;
          END IF;
          --
          IF (ROUND(v_linhas_other_expenses, w_arr) <>
             ROUND(v_nf_other_expenses, w_arr) AND
             TRUNC(v_linhas_other_expenses, w_arr) <>
             TRUNC(v_nf_other_expenses, w_arr)) THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'OTHER EXPENSES DIVERG',
                                                         r_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'OTHER EXPENSES DIVERG');
            END IF;
          END IF;
          -- FA
          v_raise_fa := FALSE;
          --
          SELECT COUNT(1) -- RI.248
            INTO x_cont_lia
            FROM ap_system_parameters
           WHERE liability_post_lookup_code = 'ACCOUNT_SEGMENT_VALUE';
          --
          IF p_interface = 'N' THEN
            FOR mlinhas IN (SELECT DISTINCT pda.code_combination_id
                              FROM po_distributions_all   pda,
                                   cll_f189_invoice_lines ril,
                                   cll_f189_invoices      ri,
                                   cll_f189_invoice_types rit
                             WHERE ri.invoice_id = r_invoices.invoice_id
                               AND rit.invoice_type_id = ri.invoice_type_id
                               AND NVL(rit.price_adjust_flag, 'N') = 'N'
                               AND NVL(rit.tax_adjust_flag, 'N') = 'N'
                               AND NVL(rit.fixed_assets_flag, 'N') = 'S'
                               AND ril.invoice_id = ri.invoice_id
                               AND pda.line_location_id =
                                   ril.line_location_id) LOOP
              --
              IF x_cont_lia >= 1 THEN
                BEGIN
                  EXECUTE IMMEDIATE 'SELECT ' || p_segment_conta ||
                                    ' FROM gl_code_combinations gcc ' ||
                                    'WHERE gcc.code_combination_id = :b1' ||
                                    ' AND gcc.chart_of_accounts_id = (SELECT chart_of_accounts_id' ||
                                    ' FROM org_organization_definitions' ||
                                    ' WHERE organization_id = :b2)'
                    INTO x_conta_ativo
                    USING mlinhas.code_combination_id, p_organization_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20550,
                                            SQLERRM ||
                                            '**********************' ||
                                            ' EXECUTE IMMEDIATE ' ||
                                            '**********************');
                END;
                --
                BEGIN
                  SELECT COUNT(1)
                    INTO v_fa_exists
                    FROM fa_category_books fcb
                   WHERE fcb.asset_clearing_acct = x_conta_ativo;
                EXCEPTION
                  WHEN OTHERS THEN
                    v_raise_fa := TRUE;
                END;
              ELSE
                BEGIN
                  SELECT COUNT(1)
                    INTO v_fa_exists
                    FROM fa_category_books fcb
                   WHERE fcb.asset_clearing_account_ccid =
                         mlinhas.code_combination_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    v_raise_fa := TRUE;
                END;
              END IF;
              --
              IF (v_fa_exists = 0) THEN
                v_raise_fa := TRUE;
              END IF;
            END LOOP;
          ELSE
            FOR mlinhas IN (SELECT DISTINCT pda.code_combination_id
                              FROM po_distributions_all         pda,
                                   cll_f189_invoice_lines_iface ril,
                                   cll_f189_invoices_interface  ri,
                                   cll_f189_invoice_types       rit
                             WHERE ri.interface_invoice_id =
                                   r_invoices.interface_invoice_id
                               AND rit.organization_id = p_organization_id -- BUG 19722064
                               AND (rit.invoice_type_id = ri.invoice_type_id OR -- BUG 19722064
                                   rit.invoice_type_code =
                                   ri.invoice_type_code) -- BUG 19722064
                               AND NVL(rit.price_adjust_flag, 'N') = 'N'
                               AND NVL(rit.tax_adjust_flag, 'N') = 'N'
                               AND NVL(rit.fixed_assets_flag, 'N') = 'S'
                               AND ril.interface_invoice_id =
                                   ri.interface_invoice_id
                               AND pda.line_location_id =
                                   ril.line_location_id) LOOP
              --
              IF x_cont_lia >= 1 THEN
                BEGIN
                  EXECUTE IMMEDIATE 'SELECT ' || p_segment_conta ||
                                    ' FROM gl_code_combinations gcc ' ||
                                    'WHERE gcc.code_combination_id = :b1' ||
                                    ' AND gcc.chart_of_accounts_id = (SELECT chart_of_accounts_id' ||
                                    ' FROM org_organization_definitions' ||
                                    ' WHERE organization_id = :b2)'
                    INTO x_conta_ativo
                    USING mlinhas.code_combination_id, p_organization_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    raise_application_error(-20551,
                                            SQLERRM ||
                                            '**********************' ||
                                            ' EXECUTE IMMEDIATE ' ||
                                            '**********************');
                END;
                --
                BEGIN
                  SELECT COUNT(1)
                    INTO v_fa_exists
                    FROM fa_category_books fcb
                   WHERE fcb.asset_clearing_acct = x_conta_ativo;
                EXCEPTION
                  WHEN OTHERS THEN
                    v_raise_fa := TRUE;
                END;
              ELSE
                BEGIN
                  SELECT COUNT(1)
                    INTO v_fa_exists
                    FROM fa_category_books fcb
                   WHERE fcb.asset_clearing_account_ccid =
                         mlinhas.code_combination_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    v_raise_fa := TRUE;
                END;
              END IF;
              --
              IF (v_fa_exists = 0) THEN
                v_raise_fa := TRUE;
              END IF;
            END LOOP;
          END IF;
          --
          IF (v_raise_fa) THEN
            IF p_interface = 'N' THEN
              cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                         p_organization_id,
                                                         p_location_id,
                                                         'ACCOUNT FA DIVERG',
                                                         r_invoices.invoice_id,
                                                         NULL);
            ELSE
              cll_f189_check_holds_pkg.incluir_erro(r_invoices.interface_invoice_id,
                                                    p_operation_id,
                                                    'ACCOUNT FA DIVERG');
            END IF;
          END IF;
        END IF;
        -- Bug 12352184 - GGarcia - 02/06/2011 - Fim
        --
        -- Start Bug 25064971 - ER:F189:ALLOW ENTRY OPERATIONS WITHOUT PO DOCUMENT TO UPDATE INVENTORY AND COSTS -- NTeles - 25/04/2017
        IF r_invoices.requisition_type = 'IN' THEN
          --
          declare
            l_return boolean;
          begin
            l_return := cll_f189_apprv_hierarchy_pkg.find_hierarchy_approval_f(p_operation_id    => p_operation_id,
                                                                               p_organization_id => p_organization_id,
                                                                               p_location_id     => p_location_id,
                                                                               p_user_called     => null);
            if not l_return then
              --
              if p_interface = 'N' then
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'HIERARCHY SETUP NOT FOUND',
                                                           '',
                                                           '');
              end if;
              --
            end if;
          end;
          --
        END IF;
        -- End Bug 25064971 - ER:F189:ALLOW ENTRY OPERATIONS WITHOUT PO DOCUMENT TO UPDATE INVENTORY AND COSTS -- NTeles - 25/04/2017
      END LOOP;
    END IF;
    --
    IF NVL(v_cred_type_inv, v_cred_type_frt) <>
       NVL(v_cred_type_frt, v_cred_type_inv) THEN
      IF p_interface = 'N' THEN
        cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                   p_organization_id,
                                                   p_location_id,
                                                   'DIFF CRE DEB TYPE',
                                                   '',
                                                   '');
      ELSE
        cll_f189_check_holds_pkg.incluir_erro( --NULL  -- Bug 5029863 AIrmer 21/02/2006
                                              p_interface_invoice_id -- Bug 5029863 AIrmer 21/02/2006
                                             ,
                                              p_operation_id,
                                              'DIFF CRE DEB TYPE');
      END IF;
    END IF;
    -- ER 11820206 - Start
    IF p_interface = 'N' THEN
      BEGIN
        FOR uom_lines IN cx_lines LOOP
          l_dist_uom := 0;
          SELECT COUNT(DISTINCT ril.uom)
            INTO l_dist_uom
            FROM cll_f189_invoice_lines ril, cll_f189_invoices ri
           WHERE ril.line_location_id = uom_lines.line_location_id
             AND ril.invoice_id = ri.invoice_id
             AND ri.operation_id = p_operation_id
             AND ri.organization_id = p_organization_id;
          IF l_dist_uom > 1 THEN
            cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                       p_organization_id,
                                                       p_location_id,
                                                       'DIFF UOM SAME ITEM',
                                                       uom_lines.invoice_id,
                                                       uom_lines.invoice_line_id);
            EXIT;
          END IF;
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          l_dist_uom := 0;
      END;
    END IF;
    -- ER 11820206 - End
    BEGIN
      -- Bug 12352184 - GGarcia - 02/06/2011 - Inicio
      IF NVL(l_uom_diff, 0) = 0 AND v_tolerance_code = 'REJECT' THEN
        -- ER 11820206
        FOR n_lines IN cx_lines -- Bug 12352184
         LOOP
          --
          --IF (n_lines.line_location_id IS NOT NULL) THEN
          BEGIN
            SELECT quantity * (1 + v_rcv_tolerance_percent / 100)
              INTO n_quantidade
              FROM po_line_locations_all
             WHERE line_location_id = n_lines.line_location_id;
          EXCEPTION
            WHEN OTHERS THEN
              n_quantidade := 0; -- Bug 12352184
          END;
          -- Debit
          IF p_interface = 'N' THEN
            BEGIN
              SELECT NVL(SUM(NVL(ril.quantity, 0)), 0)
                INTO n_debito
                FROM cll_f189_invoice_lines ril,
                     cll_f189_invoices      ri,
                     cll_f189_invoice_types rit
               WHERE ril.line_location_id = n_lines.line_location_id
                 AND ri.invoice_id = ril.invoice_id
                 AND rit.invoice_type_id = ri.invoice_type_id
                 AND rit.credit_debit_flag = 'D'
                 AND rit.price_adjust_flag = 'N'
                 AND rit.tax_adjust_flag = 'N'
                    -- Nao considerar Notas de Remessa FA
                 AND rit.invoice_type_id NOT IN
                     (select rit2.invoice_type_id
                        from cll_f189_invoice_types rit2
                       where rit2.fixed_assets_flag IN ('S', 'O')
                         and rit2.parent_flag = 'Y' -- Bug 9095316
                         AND rit2.credit_debit_flag = 'D'); -- Bug 9095316

            EXCEPTION
              WHEN OTHERS THEN
                n_debito := 0;
            END;
          END IF;
          -- Credit
          IF p_interface = 'N' THEN
            BEGIN
              SELECT NVL(SUM(NVL(ril.quantity, 0)), 0)
                INTO n_credito
                FROM cll_f189_invoice_lines ril,
                     cll_f189_invoices      ri,
                     cll_f189_invoice_types rit
               WHERE ril.line_location_id = n_lines.line_location_id
                 AND ri.invoice_id = ril.invoice_id
                 AND rit.invoice_type_id = ri.invoice_type_id
                 AND rit.credit_debit_flag = 'C'
                 AND rit.price_adjust_flag = 'N'
                 AND rit.tax_adjust_flag = 'N'
                    -- ER 9095316
                    /*
                    -- Nao considerar Notas de Remessa FA
                      AND  rit.invoice_type_id             NOT IN (select rit2.invoice_type_id
                                                                    from  cll_f189_invoice_types rit2
                                                                    where rit2.fixed_assets_flag IN ('S', 'O')
                                                                     and  rit2.parent_flag = 'Y'
                                                                     and  rit2.credit_debit_flag = 'D') */
                    -- Nao considerar reversao ou devolucao de Nota de Remessa de FA
                 AND ri.invoice_parent_id NOT IN
                     (select invoice_id
                        from cll_f189_invoices cfi2
                       where cfi2.invoice_type_id IN
                             (select rit3.invoice_type_id
                                from cll_f189_invoice_types rit3
                               where rit3.fixed_assets_flag IN ('S', 'O')
                                 and rit3.parent_flag = 'Y'
                                    --and rit3.credit_debit_flag = 'D')
                                 and rit3.credit_debit_flag = 'C') -- Bug 12352184
                         and cfi2.invoice_id = ri.invoice_parent_id);
              --
            EXCEPTION
              WHEN OTHERS THEN
                n_credito := 0;
            END;
          END IF;
          --
          IF ((n_debito - n_credito) > n_quantidade) THEN
            -- ER 11820206
            --AND (v_tolerance_code = 'REJECT') THEN -- ER 11820206
            IF n_inseriu = 0 THEN
              IF p_interface = 'N' THEN
                cll_f189_check_holds_pkg.incluir_erro_hold(p_operation_id,
                                                           p_organization_id,
                                                           p_location_id,
                                                           'QTY BILLED > QTY ORDERED',
                                                           n_lines.invoice_id, -- Bug 12352184
                                                           n_lines.invoice_line_id);

              END IF;

              n_inseriu := n_inseriu + 1;
            END IF;
          END IF;
          --END IF;
        END LOOP; -- Bug 12352184
      END IF; -- ER 11820206
    END;
    --
    v_count := cll_f189_holds_custom_pkg.func_holds_custom(
      p_operation_id,
      p_organization_id
    );
    
    BEGIN
      SELECT COUNT(1)
        INTO v_count
        FROM cll_f189_holds
       WHERE operation_id = p_operation_id
         AND organization_id = p_organization_id;
    END;
    --
    IF v_count = 0 THEN
      FOR r_inv IN c_invoices LOOP
        IF p_interface = 'N' THEN
          BEGIN
            SELECT ROUND(NVL(SUM(NVL(ril.icms_base, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.icms_amount, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.icms_amount_recover, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.ipi_amount, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.ipi_amount_recover, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.fcp_amount_recover, 0)), 0), 2) -- 28269989
              INTO w_icms_base,
                   w_icms_amount,
                   w_icms_amount_recover,
                   w_ipi_amount,
                   w_ipi_amount_recover,
                   w_fcp_amount_recover -- 28269989
              FROM cll_f189_invoice_lines ril
             WHERE ril.invoice_id = r_inv.invoice_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              w_icms_base           := 0;
              w_icms_amount         := 0;
              w_icms_amount_recover := 0;
              w_ipi_amount          := 0;
              w_ipi_amount_recover  := 0;
              w_fcp_amount_recover  := 0;-- 28269989
          END;
        ELSE
          BEGIN
            SELECT ROUND(NVL(SUM(NVL(ril.icms_base, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.icms_amount, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.icms_amount_recover, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.ipi_amount, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.ipi_amount_recover, 0)), 0), 2),
                   ROUND(NVL(SUM(NVL(ril.fcp_amount_recover, 0)), 0), 2) -- 28269989
              INTO w_icms_base,
                   w_icms_amount,
                   w_icms_amount_recover,
                   w_ipi_amount,
                   w_ipi_amount_recover,
                   w_fcp_amount_recover -- 28269989
              FROM CLL_F189_INVOICE_LINES_IFACE ril
             WHERE ril.interface_invoice_id = r_inv.interface_invoice_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              w_icms_base           := 0;
              w_icms_amount         := 0;
              w_icms_amount_recover := 0;
              w_ipi_amount          := 0;
              w_ipi_amount_recover  := 0;
              w_fcp_amount_recover  := 0;-- 28269989
          END;
        END IF;
        --
-- 29278192 - Start
/*
        -- ER 14124731 - Start
      --IF l_source = 'CLL_F369 EFD LOADER' AND p_interface = 'Y' THEN                 -- 27579747
        IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') -- 27579747
           THEN p_interface = 'Y' THEN                                                     -- 27579747
          NULL;
        ELSE
          -- ER 14124731 - End
*/
        IF l_source IN ('CLL_F369 EFD LOADER', 'CLL_F369 EFD LOADER SHIPPER') THEN
          NULL;
        ELSE
-- 29278192 - End

          IF ABS(w_icms_base - r_inv.icms_base) <= 0.04 AND
             ABS(w_icms_base - r_inv.icms_base) > 0 THEN
            UPDATE cll_f189_invoice_lines
               SET icms_base = icms_base - (w_icms_base - r_inv.icms_base)
             WHERE invoice_id = r_inv.invoice_id
                  -- Bug 4904964 AIrmer 03/01/2006
               AND icms_amount > 0
               AND icms_tax > 0
                  --
               AND ROWNUM = 1;
          END IF;
          --
          IF ABS(w_icms_amount - r_inv.icms_amount) <= 0.04 AND
             ABS(w_icms_amount - r_inv.icms_amount) > 0 THEN
            UPDATE cll_f189_invoice_lines
               SET icms_amount = icms_amount -
                                 (w_icms_amount - r_inv.icms_amount)
             WHERE invoice_id = r_inv.invoice_id
                  -- Bug 4904964 AIrmer 03/01/2006
               AND icms_amount > 0
               AND icms_tax > 0
                  --
               AND ROWNUM = 1;
          END IF;
          --
          IF ABS(w_icms_amount_recover - r_inv.icms_amount) <= 0.04 AND
             ABS(w_icms_amount_recover - r_inv.icms_amount) > 0 THEN
            UPDATE cll_f189_invoice_lines ril
               SET icms_amount_recover = icms_amount_recover -
                                         (w_icms_amount_recover -
                                         r_inv.icms_amount)
             WHERE invoice_id = r_inv.invoice_id
                  -- Bug 4904964 AIrmer 03/01/2006
               AND icms_amount > 0
               AND icms_tax > 0
                  --
               AND ROWNUM = 1
               AND utilization_id =
                   (SELECT utilization_id
                      FROM cll_f189_item_utilizations
                     WHERE utilization_id = ril.utilization_id
                       AND recover_icms_flag = 'Y');
          END IF;
          --
          IF ABS(w_ipi_amount - r_inv.ipi_amount) <= 0.04 AND
             ABS(w_ipi_amount - r_inv.ipi_amount) > 0 THEN
            UPDATE cll_f189_invoice_lines
               SET ipi_amount = ipi_amount -
                                (w_ipi_amount - r_inv.ipi_amount)
             WHERE invoice_id = r_inv.invoice_id
                  -- Bug 4904964 AIrmer 03/01/2006
               AND ipi_amount > 0
               AND ipi_tax > 0
                  --
               AND ROWNUM = 1;
          END IF;
          --
          IF ABS(w_ipi_amount_recover - r_inv.ipi_amount) <= 0.04 AND
             ABS(w_ipi_amount_recover - r_inv.ipi_amount) > 0 THEN
            UPDATE cll_f189_invoice_lines ril
               SET ipi_amount_recover = ipi_amount_recover -
                                        (w_ipi_amount_recover -
                                        r_inv.ipi_amount)
             WHERE invoice_id = r_inv.invoice_id
                  -- Bug 4904964 AIrmer 03/01/2006
               AND ipi_amount > 0
               AND ipi_tax > 0
                  --
               AND ROWNUM = 1
               AND utilization_id =
                   (SELECT utilization_id -- Bug 5232234 --
                      FROM cll_f189_item_utilizations -- Bug 5232234 --
                     WHERE utilization_id = ril.utilization_id
                          -- Bug 5232234 --
                       AND recover_icms_flag = 'Y'); -- Bug 5232234 --
          END IF;
          --
          -- 28269989 - Start
          IF ABS(w_fcp_amount_recover - r_inv.total_fcp_amount) <= 0.04 AND
             ABS(w_fcp_amount_recover - r_inv.total_fcp_amount) > 0 THEN
            UPDATE cll_f189_invoice_lines ril
               SET fcp_amount_recover = fcp_amount_recover -
                                        (w_fcp_amount_recover -
                                        r_inv.total_fcp_amount)
             WHERE invoice_id = r_inv.invoice_id
               AND fcp_amount > 0
               AND fcp_rate > 0
               --
               AND ROWNUM = 1
               AND utilization_id =
                   (SELECT utilization_id
                      FROM cll_f189_item_utilizations
                     WHERE utilization_id = ril.utilization_id
                       AND recover_icms_flag = 'Y');
          END IF;
          -- 28269989 - End
          --
        END IF; -- ER 14124731

      END LOOP;
    END IF;
    --
    RETURN(v_count);

  END func_check_holds;

  PROCEDURE incluir_erro_hold(p_operation_id    NUMBER,
                              p_organization_id NUMBER,
                              p_location_id     NUMBER,
                              p_hold_code       VARCHAR2,
                              p_invoice_id      NUMBER,
                              p_invoice_line_id NUMBER) IS
    --
  BEGIN
    BEGIN
      INSERT INTO cll_f189_holds
        (operation_id,
         organization_id,
         location_id,
         hold_id,
         last_update_date,
         last_updated_by,
         creation_date,
         created_by,
         hold_code,
         invoice_id,
         invoice_line_id)
      VALUES
        (p_operation_id,
         p_organization_id,
         p_location_id,
         cll_f189_holds_s.NEXTVAL,
         SYSDATE,
         -1,
         SYSDATE,
         -1,
         p_hold_code,
         p_invoice_id,
         p_invoice_line_id);
    EXCEPTION
      WHEN OTHERS THEN
        raise_application_error(-20499,
                                SQLERRM ||
                                ' **********************************' ||
                                ' Insert Hold ' || p_hold_code ||
                                ' ********************************');
    END;
  END incluir_erro_hold;

  PROCEDURE incluir_erro(
    p_invoice_id             NUMBER,
    p_interface_operation_id NUMBER,
    ERROR_CODE               VARCHAR2,
    p_invoice_line_id        NUMBER DEFAULT NULL
  ) IS
    --
    -- w_error_message     VARCHAR2 (80); -- ER 9289619
    w_error_message   VARCHAR2(240); -- ER 9289619
    w_organization_id cll_f189_interface_errors.organization_id%TYPE;
    aux               VARCHAR2(1);
    w_source          cll_f189_invoices_interface.SOURCE%TYPE;
    -- ERancement 4233742 AIrmer 12/08/2005
    l_error_code VARCHAR2(150); -- BUG 25341463
    --
  BEGIN
    --
    l_error_code := ERROR_CODE; -- BUG 25341463
    --
    BEGIN
      -- Bug 12352184 - GGarcia - 02/06/2011 - Inicio
      SELECT description
        INTO w_error_message
        FROM fnd_lookup_values_vl
       WHERE lookup_type IN
             ('CLL_F189_INTERFACE_HOLD_REASON', 'CLL_F189_HOLD_REASON')
         AND lookup_code = error_code
         AND NVL(end_date_active, SYSDATE + 1) > SYSDATE
         AND ROWNUM = 1;
      -- Bug 12352184 - GGarcia - 02/06/2011 - Fim
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        w_error_message := NULL;
    END;
    --
    BEGIN
      SELECT DISTINCT organization_id
        INTO w_organization_id
        FROM cll_f189_invoices_interface
       WHERE interface_invoice_id = p_invoice_id;
    EXCEPTION
      WHEN OTHERS THEN
        raise_application_error(-20498,SQLERRM ||' ************************************************' ||' Select organization interface ' ||ERROR_CODE ||' **********************************************');
    END;
    --
    IF w_organization_id IS NULL THEN
      --
      SELECT DISTINCT organization_id
        INTO w_organization_id
        FROM org_organization_definitions
       WHERE organization_code =
             (SELECT DISTINCT organization_code
                FROM cll_f189_invoices_interface
               WHERE interface_invoice_id = p_invoice_id);
    END IF;
    --
    -- ERancement 4533742 AIrmer 12/08/2005
    IF (p_interface_operation_id IS NOT NULL) THEN
      BEGIN
        SELECT rii.SOURCE
          INTO w_source
          FROM cll_f189_invoices_interface rii
         WHERE
        -- rii.invoice_id      = p_invoice_id -- Bug 4653014 AIrmer 14/10/2005
         rii.interface_invoice_id = p_invoice_id
        -- Bug 4653014 AIrmer 14/10/2005
         AND rii.organization_id = NVL(w_organization_id, rii.organization_id);
      EXCEPTION
        WHEN OTHERS THEN
          w_source := NULL;
      END;
    END IF;
    --
    BEGIN
      SELECT '1'
        INTO aux
        FROM cll_f189_interface_errors
       WHERE -- ERROR_CODE = ERROR_CODE     -- BUG 25341463
       ERROR_CODE = l_error_code -- BUG 25341463
       AND (interface_invoice_id = p_invoice_id OR
       (interface_invoice_id IS NULL AND p_invoice_id IS NULL))
       AND (interface_invoice_line_id = p_invoice_line_id OR
       (interface_invoice_line_id IS NULL AND p_invoice_line_id IS NULL));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          -- BUG 24621425
          INSERT INTO cll_f189_interface_errors
            (interface_operation_id,
             interface_invoice_id,
             interface_invoice_line_id,
             ERROR_CODE,
             error_message,
             creation_date,
             created_by,
             last_update_date,
             last_updated_by,
             SOURCE,
             table_associated,
             organization_id)
          VALUES
            (p_interface_operation_id,
             p_invoice_id,
             NVL(p_invoice_line_id, 0),
             ERROR_CODE,
             w_error_message,
             SYSDATE,
             0,
             SYSDATE,
             0,
             --DECODE(p_interface_operation_id,NULL,'CLL F189 INTEGRATED RCV','OPEN INTERFACE'),  -- ERancement 4533742 AIrmer 12/08/2005
             DECODE(p_interface_operation_id,
                    NULL,
                    'CLL F189 INTEGRATED RCV',
                    w_source), -- ERancement 4533742 AIrmer 12/08/2005
             -- '1',              -- ERancement 4533742 AIrmer 12/08/2005
             w_table_associated, -- ERancement 4533742 AIrmer 12/08/2005
             w_organization_id);

          -- BUG 24621425
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
          WHEN VALUE_ERROR THEN
            NULL;
          WHEN OTHERS THEN
            NULL;
        END;
        -- BUG 24621425
      WHEN TOO_MANY_ROWS THEN
        NULL;
    END;
  END incluir_erro;
  --
END xxfr_f189_check_holds_pkg;
