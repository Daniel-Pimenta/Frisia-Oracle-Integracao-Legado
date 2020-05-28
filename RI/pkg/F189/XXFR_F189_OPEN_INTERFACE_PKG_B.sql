create or replace PACKAGE BODY XXFR_F189_OPEN_INTERFACE_PKG AS
/* $Header: CLLVRIAB.pls 120.161 2019/08/13 21:11:34 vdzana noship $ */

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
  end;

  PROCEDURE open_interface (errbuf                 OUT NOCOPY VARCHAR2,
                            retcode                OUT NOCOPY NUMBER,
                            p_source               IN  VARCHAR2,
                            p_approve              IN  VARCHAR2,
                            p_delete_line          IN  VARCHAR2,
                            p_generate_line_compl  IN  VARCHAR2  DEFAULT 'N',
                            p_operating_unit       IN  NUMBER,
                            p_interface_invoice_id IN  NUMBER DEFAULT NULL
                           ) IS
  --
  l_module_name           CONSTANT VARCHAR2(100) := 'CLL_F189_OPEN_INTERFACE_PKG.OPEN_INTERFACE';
  l_return_code           VARCHAR2(100);
  l_return_message        VARCHAR2(500);
  l_type_exec             VARCHAR2(1);
  --
  CURSOR c_invoice_header IS
    SELECT interface_invoice_id
          ,interface_operation_id
          ,source
          ,process_flag
          ,gl_date
          ,freight_flag
          ,total_freight_weight
          ,invoice_id
          ,entity_id
          ,document_type
          ,document_number
          ,invoice_num
          ,series
          ,operation_id
          ,organization_id
          ,organization_code
          ,location_id
          ,location_code
          ,invoice_amount
          ,invoice_date
          ,invoice_type_id
          ,invoice_type_code
          ,icms_type
          ,icms_base
          ,icms_tax
          ,icms_amount
          ,ipi_amount
          ,subst_icms_base
          ,subst_icms_amount
          ,diff_icms_tax
          ,diff_icms_amount
          ,iss_base
          ,iss_amount
          ,ir_base
          ,ir_tax
          ,ir_amount
          ,description
          ,terms_id
          ,terms_name
          ,terms_date
          ,first_payment_date
          ,insurance_amount
          ,freight_amount
          ,payment_discount
          ,return_cfo_id
          ,return_cfo_code
          ,return_amount
          ,return_date
          ,additional_tax
          ,additional_amount
          ,other_expenses
          ,invoice_weight
          ,contract_id
          ,dollar_invoice_amount
          ,source_items
          ,importation_number
          ,po_conversion_rate
          ,importation_freight_weight
          ,total_fob_amount
          ,freight_international
          ,importation_tax_amount
          ,importation_insurance_amount
          ,total_cif_amount
          ,customs_expense_func
          ,importation_expense_func
          ,dollar_total_fob_amount
          ,dollar_customs_expense
          ,dollar_freight_international
          ,dollar_importation_tax_amount
          ,dollar_insurance_amount
          ,dollar_total_cif_amount
          ,importation_expense_dol
          ,fiscal_document_model
          ,irrf_base_date
          ,inss_base
          ,inss_tax
          ,inss_amount
          ,lp_inss_initial_base_amount --  21924115
          ,lp_inss_base_amount         --  21924115
          ,lp_inss_rate                --  21924115
          ,lp_inss_amount              --  21924115
          ,lp_inss_net_amount          --  21924115
          ,ip_inss_initial_base_amount --  21924115
          ,ip_inss_base_amount         --  21924115
          ,ip_inss_rate                --  21924115
          ,ip_inss_net_amount          --  21924115
          ,ir_vendor
          ,ir_categ
          ,icms_st_base
          ,icms_st_amount
          ,icms_st_amount_recover
          ,diff_icms_amount_recover
          ,alternate_currency_conv_rate
          ,gross_total_amount
          ,source_state_id
          ,destination_state_id
          ,source_state_code
          ,destination_state_code
          ,funrural_base
          ,funrural_tax
          ,funrural_amount
          ,sest_senat_base
          ,sest_senat_tax
          ,sest_senat_amount
          ,user_defined_conversion_rate
          ,po_currency_code
          ,inss_autonomous_invoiced_total
          ,inss_autonomous_amount
          ,inss_autonomous_tax
          ,inss_additional_tax_1
          ,inss_additional_tax_2
          ,inss_additional_tax_3
          ,inss_additional_base_1
          ,inss_additional_base_2
          ,inss_additional_base_3
          ,inss_additional_amount_1
          ,inss_additional_amount_2
          ,inss_additional_amount_3
          ,iss_city_id
          ,siscomex_amount
          ,dollar_siscomex_amount
          ,ship_via_lookup_code
          ,iss_city_code
          ,receive_date
          ,importation_pis_amount
          ,importation_cofins_amount
          ,dollar_importation_pis_amount
          ,dollar_import_cofins_amount
          ,income_code
          ,ie
          ,creation_date
          ,created_by
          ,last_update_date
          ,last_updated_by
          ,last_update_login
          ,ceo_attribute_category
          ,ceo_attribute1
          ,ceo_attribute2
          ,ceo_attribute3
          ,ceo_attribute4
          ,ceo_attribute5
          ,ceo_attribute6
          ,ceo_attribute7
          ,ceo_attribute8
          ,ceo_attribute9
          ,ceo_attribute10
          ,ceo_attribute11
          ,ceo_attribute12
          ,ceo_attribute13
          ,ceo_attribute14
          ,ceo_attribute15
          ,ceo_attribute16
          ,ceo_attribute17
          ,ceo_attribute18
          ,ceo_attribute19
          ,ceo_attribute20
          ,cin_attribute_category
          ,cin_attribute1
          ,cin_attribute2
          ,cin_attribute3
          ,cin_attribute4
          ,cin_attribute5
          ,cin_attribute6
          ,cin_attribute7
          ,cin_attribute8
          ,cin_attribute9
          ,cin_attribute10
          ,cin_attribute11
          ,cin_attribute12
          ,cin_attribute13
          ,cin_attribute14
          ,cin_attribute15
          ,cin_attribute16
          ,cin_attribute17
          ,cin_attribute18
          ,cin_attribute19
          ,cin_attribute20
          ,di_date
          ,clearance_date
          ,comments
          ,vehicle_seller_doc_number
          ,vehicle_seller_state_id
          ,vehicle_seller_state_code
          ,third_party_amount
          ,abatement_amount
          ,import_document_type
          ,eletronic_invoice_key
          ,process_indicator
          ,process_origin
          ,subseries
          ,icms_free_service_amount
          ,return_invoice_num
          ,return_series
          ,inss_subcontract_amount
          ,invoice_parent_id
          ,service_execution_date
          ,pis_withhold_amount
          ,cofins_withhold_amount
          ,drawback_granted_act_number
          ,cte_type
          ,max_icms_amount_recover
          ,icms_tax_rec_simpl_br
          ,simplified_br_tax_flag
          ,social_security_contrib_tax -- ER 17551029
          ,gilrat_tax                  -- ER 17551029
          ,senar_tax                   -- ER 17551029
          ,social_security_contrib_amount -- 27153706
          ,gilrat_amount                  -- 27153706
          ,senar_amount                   -- 27153706
          ,worker_category_id          -- ER 17551029 4a Fase
          ,category_code               -- ER 17551029 4a Fase
          ,cbo_code                    -- ER 17551029 4a Fase
          ,material_equipment_amount   -- ER 17551029 4a Fase
          ,deduction_amount            -- ER 17551029 4a Fase
          ,cno_id                      -- 24325307
          ,cno_number                  -- ER 17551029 4a Fase
          ,caepf_number                -- ER 17551029 4a Fase
          ,indicator_multiple_links    -- ER 17551029 4a Fase
          ,inss_service_amount_1       -- ER 17551029 4a Fase
          ,inss_service_amount_2       -- ER 17551029 4a Fase
          ,inss_service_amount_3       -- ER 17551029 4a Fase
          ,remuneration_freight_amount -- ER 17551029 4a Fase
          ,sest_senat_income_code      -- ER 9923702
          ,funrural_income_code        -- ER 9923702
          ,import_other_val_included_icms -- ER 20450226
          ,import_other_val_not_icms      -- ER 20450226
          ,dollar_other_val_included_icms -- ER 20450226
          ,dollar_other_val_not_icms      -- ER 20450226
          ,carrier_document_type          -- ER 20404053
          ,carrier_document_number        -- ER 20404053
          ,carrier_state_id               -- ER 20404053
          ,carrier_ie                     -- ER 20404053
          ,UPPER(carrier_vehicle_plate_num) carrier_vehicle_plate_num -- ER 20404053
          ,usage_authorization            -- ER 20382276
          ,dar_number                     -- ER 20382276
          ,dar_total_amount               -- ER 20382276
          ,dar_payment_date               -- ER 20382276
          ,first_alternative_rate         -- ER 20608903
          ,second_alternative_rate        -- ER 20608903
          ,icms_fcp_amount                -- 21804594
          ,icms_sharing_dest_amount       -- 21804594
          ,icms_sharing_source_amount     -- 21804594
          ,department_id                  -- 22285738
          ,importation_cide_amount        -- 25341463
          ,dollar_import_cide_amount      -- 25341463
          ,total_fcp_amount               -- 25713076
          ,total_fcp_st_amount            -- 25713076
          ,sest_tax                       -- 25808200 - 25808214
          ,senat_tax                      -- 25808200 - 25808214
          ,sest_amount                    -- 27153706
          ,senat_amount                   -- 27153706
          ,source_city_id                 -- 27463767
          ,destination_city_id            -- 27463767
          ,source_ibge_city_code          -- 27463767
          ,destination_ibge_city_code     -- 27463767
          ,reference                      -- 27579747
          ,ship_to_state_id               -- 28487689 - 28597878
          ,freight_mode                   -- 29330466 - 29338175 - 29385361 - 29480917
          ,fisco_additional_information   -- 29330466 - 29338175 - 29385361 - 29480917
          ,ir_cumulative_base             -- 29448946
          ,iss_mat_third_parties_amount   -- 29635195
          ,iss_subcontract_amount         -- 29635195
          ,iss_exempt_transactions_amount -- 29635195
          ,iss_deduction_amount           -- 29635195
          ,iss_fiscal_observation         -- 29635195
      FROM cll_f189_invoices_interface cllii
     WHERE cllii.source               = p_source
       AND cllii.process_flag         = 1
       AND cllii.interface_invoice_id = NVL(p_interface_invoice_id,cllii.interface_invoice_id)
       ;
  --
      CURSOR c_invoice_lines (p_interface_invoice IN NUMBER) IS
        SELECT reli.interface_invoice_line_id
              ,reli.creation_date
              ,reli.created_by
              ,reli.last_update_date
              ,reli.last_updated_by
              ,reli.last_update_login
              ,reli.invoice_id
              ,reli.interface_invoice_id
              ,reli.line_location_id
              ,reli.requisition_line_id
              ,reli.item_id
              ,reli.db_code_combination_id
              ,reli.classification_id
              ,reli.classification_code
              ,reli.exception_classification_code
              ,reli.utilization_id
              ,reli.utilization_code
              ,reli.cfo_id
              ,reli.cfo_code
              ,reli.uom
              ,reli.quantity
              ,reli.unit_price
              ,reli.operation_fiscal_type
              ,reli.description
              ,reli.icms_base
              ,reli.icms_tax
              ,reli.icms_amount
              ,reli.icms_amount_recover
              ,reli.icms_tax_code
              ,reli.diff_icms_tax
              ,reli.diff_icms_amount
              ,reli.ipi_base_amount
              ,reli.ipi_tax
              ,reli.ipi_amount
              ,reli.ipi_amount_recover
              ,reli.ipi_tax_code
              ,reli.total_amount
              ,reli.receipt_flag
              ,reli.release_tax_hold_reason
              ,reli.tax_hold_released_by
              ,reli.func_prepayment_amount
              ,reli.dollar_prepayment_amount
              ,reli.fob_amount
              ,reli.freight_internacional
              ,reli.importation_tax_amount
              ,reli.importation_insurance_amount
              ,reli.customs_expense_func
              ,reli.importation_expense_func
              ,reli.dollar_fob_amount
              ,reli.dollar_freight_internacional
              ,reli.dollar_importation_tax_amount
              ,reli.dollar_insurance_amount
              ,reli.dollar_customs_expense
              ,reli.dollar_importation_expense
              ,reli.discount_percent
              ,reli.icms_st_base
              ,reli.icms_st_amount
              ,reli.icms_st_amount_recover
              ,reli.diff_icms_amount_recover
              ,reli.pis_amount_recover
              ,reli.rma_interface_id
              ,reli.other_expenses
              ,reli.discount_amount
              ,reli.freight_amount
              ,reli.insurance_amount
              ,reli.purchase_order_num
              ,reli.line_num
              ,reli.shipment_num
              ,reli.project_number
              ,reli.project_id
              ,reli.task_number
              ,reli.task_id
              ,reli.expenditure_type
              ,reli.expenditure_organization_name
              ,reli.expenditure_organization_id
              ,reli.expenditure_item_date
              ,reli.tributary_status_code
              ,reli.cofins_amount_recover
              ,reli.shipment_line_id
              ,reli.freight_ap_flag
              ,reli.importation_pis_cofins_base
              ,reli.importation_pis_amount
              ,reli.importation_cofins_amount
              ,reli.awt_group_id
              ,nvl(reli.ipi_unit_amount,0) ipi_unit_amount
              ,reli.city_service_type_rel_id
              ,reli.city_service_type_rel_code
              ,reli.iss_base_amount
              ,reli.iss_tax_rate
              ,reli.iss_tax_amount
              ,reli.ipi_tributary_code
              ,reli.ipi_tributary_type
              ,reli.pis_base_amount
              ,reli.pis_tax_rate
              ,reli.pis_qty
              ,reli.pis_unit_amount
              ,reli.pis_amount
              ,reli.pis_tributary_code
              ,reli.cofins_base_amount
              ,reli.cofins_tax_rate
              ,reli.cofins_qty
              ,reli.cofins_unit_amount
              ,reli.cofins_amount
              ,reli.cofins_tributary_code
              ,reli.deferred_icms_amount
              ,reli.net_amount
              ,reli.icms_base_reduc_perc
              ,reli.vehicle_oper_type
              ,reli.vehicle_chassi
              ,reli.uom_po
              ,reli.quantity_uom_po
              ,reli.unit_price_uom_po
              ,reli.attribute_category
              ,reli.attribute1
              ,reli.attribute2
              ,reli.attribute3
              ,reli.attribute4
              ,reli.attribute5
              ,reli.attribute6
              ,reli.attribute7
              ,reli.attribute8
              ,reli.attribute9
              ,reli.attribute10
              ,reli.attribute11
              ,reli.attribute12
              ,reli.attribute13
              ,reli.attribute14
              ,reli.attribute15
              ,reli.attribute16
              ,reli.attribute17
              ,reli.attribute18
              ,reli.attribute19
              ,reli.attribute20
              ,reli.customs_total_value
              ,reli.ci_percent
              ,reli.total_import_parcel
              ,reli.fci_number
              ,reli.recopi_number                  -- Bug 20145693
              ,reli.icms_type                      -- ER 9028781
              ,reli.icms_free_service_amount       -- ER 9028781
              ,reli.max_icms_amount_recover        -- ER 9028781
              ,reli.icms_tax_rec_simpl_br          -- ER 9028781
              ,reli.import_other_val_included_icms -- ER 20450226
              ,reli.import_other_val_not_icms      -- ER 20450226
              ,reli.med_maximum_price_consumer     -- ER 20382276
              ,reli.item_number                    -- 21645107
              ,reli.cest_code                      -- 22119026
              ,reli.icms_dest_base_amount          -- 21804594
              ,reli.icms_fcp_dest_perc             -- 21804594
              ,reli.icms_dest_tax                  -- 21804594
              ,reli.icms_sharing_inter_perc        -- 21804594
              ,reli.icms_fcp_amount                -- 21804594
              ,reli.icms_sharing_dest_amount       -- 21804594
              ,reli.icms_sharing_source_amount     -- 21804594
              ,reli.fundersul_per_u_meas           -- BUG 17056156
              ,reli.fundersul_unit_amount          -- BUG 17056156
              ,reli.fundersul_unit_percent         -- BUG 17056156
              ,reli.fundersul_amount               -- BUG 17056156
              ,reli.fundersul_addt_amount          -- BUG 17056156
              ,reli.diff_icms_base                 -- 22834666
              -- BUG 25341463 - Start
              ,reli.cide_base_amount
              ,reli.cide_rate
              ,reli.cide_amount
              ,reli.cide_amount_recover
              -- BUG 25341463 - End
              -- 25713076 - Start
              ,reli.anvisa_product_code
              ,reli.anp_product_code
            --,reli.anp_product_description     -- 26987509 - 26986232
              ,reli.anp_product_descr           -- 26987509 - 26986232
              ,reli.glp_derived_oil_perc
              ,reli.glgnn_glp_product_perc
              ,reli.glgni_glp_product_perc
              ,reli.starting_value
              ,reli.codif_authorization
              ,reli.significant_scale_prod_ind
              ,reli.manufac_goods_doc_number
            --,reli.lot_number                  -- 26987509 - 26986232
              ,reli.product_lot_number          -- 26987509 - 26986232
              ,reli.lot_quantity
              ,reli.production_date
              ,reli.expiration_date
              ,reli.aggregation_code
              ,reli.fcp_base_amount
              ,reli.fcp_rate
              ,reli.fcp_amount
              ,reli.fcp_st_base_amount
              ,reli.fcp_st_rate
              ,reli.fcp_st_amount
              -- 25713076 - End
              ,reli.iss_city_id                   -- 25591653
              ,reli.iss_city_code                 -- 25591653
              ,reli.service_execution_date        -- 25591653
              ,reli.iss_fo_base_amount            -- 25591653
              ,reli.iss_fo_tax_rate               -- 25591653
              ,reli.iss_fo_amount                 -- 25591653
              ,reli.fcp_amount_recover            -- 28194547
              ,reli.fcp_st_amount_recover         -- 28194547
              ,reli.discount_net_amount           -- 28468398 - 28505834
              ,reli.icms_st_prev_withheld_base    -- 28468398 - 28505834
              ,reli.icms_st_prev_withheld_tx_rate -- 28468398 - 28505834
              ,reli.icms_st_prev_withheld_amount  -- 28468398 - 28505834
              ,reli.fcp_st_prev_withheld_base     -- 28468398 - 28505834
              ,reli.fcp_st_prev_withheld_tx_rate  -- 28468398 - 28505834
              ,reli.fcp_st_prev_withheld_amount   -- 28468398 - 28505834
              ,reli.ipi_tributary_code_out        -- 228730077
              ,reli.tributary_status_code_out     -- 228730077
              ,reli.pis_tributary_code_out        -- 228730077
              ,reli.cofins_tributary_code_out     -- 228730077
              ,reli.additional_information_code   -- 28843378
              ,reli.anvisa_exemption_reazon       -- 29330466 - 29338175 - 29385361 - 29480917
              ,reli.icms_prev_withheld_amount     -- 29330466 - 29338175 - 29385361 - 29480917
         FROM cll_f189_invoice_lines_iface reli
        WHERE reli.interface_invoice_id = p_interface_invoice;
  --
      CURSOR c_freight (p_interface_invoice      IN NUMBER
                       ,p_location_id            IN NUMBER
                       ,p_interface_operation_id IN NUMBER) IS
        SELECT refr.interface_invoice_id
              ,refr.entity_id
              ,refr.document_type
              ,refr.document_number
              ,refr.invoice_num
              ,refr.series
              ,refr.creation_date
              ,refr.created_by
              ,refr.last_update_date
              ,refr.last_updated_by
              ,refr.last_update_login
              --,refr.operation_id
              ,refr.interface_operation_id
              ,refr.organization_id
              ,refr.organization_code
              ,NVL(refr.location_id, p_location_id) location_id
              ,refr.location_code
              ,refr.invoice_date
              ,refr.invoice_amount
              ,refr.invoice_type_id
              ,refr.invoice_type_code
              ,refr.cfo_id
              ,refr.cfo_code
              ,refr.terms_id
              ,refr.terms_name
              ,NVL(refr.terms_date,refr.invoice_date) terms_date
              ,refr.first_payment_date
              ,refr.po_header_id
              ,refr.description
              ,refr.total_freight_weight
              ,refr.icms_type
              ,refr.icms_base
              ,refr.icms_tax
              ,refr.icms_amount
              ,refr.diff_icms_tax
              ,refr.diff_icms_amount
              ,refr.ship_via_lookup_code
              ,refr.fiscal_document_model
              ,refr.diff_icms_amount_recover
              ,refr.source_state_id
              ,refr.destination_state_id
              ,refr.source_state_code
              ,refr.destination_state_code
              ,refr.subseries
              ,refr.utilization_id
              ,refr.utilization_code
              ,refr.tributary_status_code
              ,refr.cte_type
              ,refr.eletronic_invoice_key
              ,NVL(refr.simplified_br_tax_flag,'N') simplified_br_tax_flag
              ,refr.icms_tax_code
              ,refr.pis_amount_recover
              ,refr.pis_base_amount
              ,refr.pis_tax_rate
              ,refr.cofins_amount_recover
              ,refr.cofins_base_amount
              ,refr.cofins_tax_rate
              ,refr.attribute_category
              ,refr.attribute1
              ,refr.attribute2
              ,refr.attribute3
              ,refr.attribute4
              ,refr.attribute5
              ,refr.attribute6
              ,refr.attribute7
              ,refr.attribute8
              ,refr.attribute9
              ,refr.attribute10
              ,refr.attribute11
              ,refr.attribute12
              ,refr.attribute13
              ,refr.attribute14
              ,refr.attribute15
              ,refr.attribute16
              ,refr.attribute17
              ,refr.attribute18
              ,refr.attribute19
              ,refr.attribute20
              ,refr.pis_tributary_code
              ,refr.cofins_tributary_code
              ,refr.usage_authorization -- ER 20382276
              ,refr.source_city_id             -- 27463767
              ,refr.destination_city_id        -- 27463767
              ,refr.source_ibge_city_code      -- 27463767
              ,refr.destination_ibge_city_code -- 27463767
              ,refr.reference                  -- 27579747
              ,refr.ship_to_state_id           -- 28487689 - 28597878
        FROM cll_f189_freight_inv_interface refr
        WHERE refr.interface_operation_id = NVL(p_interface_operation_id,refr.interface_operation_id);
  --
      CURSOR c_invoice_parents_header (p_interface_invoice   IN NUMBER) IS
          SELECT interface_parent_id
                ,interface_invoice_id
                ,invoice_parent_id
                ,invoice_parent_num
                ,entity_id
                ,invoice_date
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,attribute16
                ,attribute17
                ,attribute18
                ,attribute19
                ,attribute20
           FROM cll_f189_invoice_parents_int
          WHERE interface_invoice_id = p_interface_invoice;
  --
      CURSOR c_invoice_parent_lines (p_interface_parent_id    IN NUMBER  ) IS
          SELECT interface_parent_line_id
                ,interface_parent_id
                ,invoice_parent_line_id
                ,interface_invoice_line_id
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,attribute16
                ,attribute17
                ,attribute18
                ,attribute19
                ,attribute20
           FROM cll_f189_invoice_line_par_int
          WHERE interface_parent_id = p_interface_parent_id;
  --
      CURSOR c_legal_processes (p_interface_invoice    IN NUMBER  ) IS
          SELECT legal_process_id
                ,reference_table
                ,interface_invoice_id
                ,legal_process_number
                ,process_origin
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,attribute16
                ,attribute17
                ,attribute18
                ,attribute19
                ,attribute20
                ,tax_type                -- ER 17551029 4a Fase
                ,not_withheld_amount     -- ER 17551029 4a Fase
                ,process_id              -- 25808200 - 25808214
                ,process_suspension_code -- 25808200 - 25808214
            FROM cll_f189_legal_processes_int
           WHERE interface_invoice_id = p_interface_invoice;
  --
      CURSOR c_outbound_invoices (p_interface_invoice    IN NUMBER  ) IS
          SELECT int_ra_cust_trx_id
                ,interface_invoice_id
                ,customer_trx_id
                ,document_type
                ,document_number
                ,cust_acct_site_id
                ,trx_number
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,attribute16
                ,attribute17
                ,attribute18
                ,attribute19
                ,attribute20
                ,eletronic_invoice_key -- 27579747
            FROM cll_f189_ra_cust_trx_int
           WHERE interface_invoice_id = p_interface_invoice;
 /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_TPA_RETURNS                                     |
  |                                                                          |
  | Description: Responsible for validate information and insert into        |
  |              CLL F513 third Party transaction                            |
  |              tables ER 26338366/26899224                                 |
  |                                                                          |
  +=========================================================================*/
  --<< ER 26338366/26899224 - dgouveia - 04/10/2017 - Start >>--
  Cursor c_tpa (p_interface_invoice    IN NUMBER  ) is
    SELECT interface_invoice_id
         , interface_invoice_line_id
         , tpa_remit_interface_id
         , tpa_remit_control_id
         , new_subinventory_code
         , new_locator_id
         , new_locator_code
         , attribute_category
         , attribute1
         , attribute2
         , attribute3
         , attribute4
         , attribute5
         , attribute6
         , attribute7
         , attribute8
         , attribute9
         , attribute10
         , attribute11
         , attribute12
         , attribute13
         , attribute14
         , attribute15
         , attribute16
         , attribute17
         , attribute18
         , attribute19
         , attribute20
         , creation_date
         , created_by
         , last_update_date
         , last_update_login
         , request_id
         , program_application_id
         , program_id
         , program_update_date
         , quantity
         , symbolic_return_flag  -- ENR 30120364
      FROM cll_f513_tpa_ret_iface
     WHERE interface_invoice_id = p_interface_invoice ;
  --
  -- << ER 26338366/26899224 - dgouveia - 04/10/2017 - End >> --
  --

      -- ER 17551029 4a Fase - Start
      CURSOR c_prior_billings (p_interface_invoice    IN NUMBER  ) IS
          SELECT prior_billings_id
                ,interface_invoice_id
                ,document_type
                ,document_number
                ,total_remuneration_amount
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,attribute16
                ,attribute17
                ,attribute18
                ,attribute19
                ,attribute20
                ,category_code -- 25808200 - 25808214
            FROM cll_f189_prior_billings_int
           WHERE interface_invoice_id = p_interface_invoice;
           -- ER 17551029 4a Fase - End

      -- 28592012 - Start
      CURSOR c_payment_methods (p_interface_invoice    IN NUMBER  ) IS
          SELECT payment_method_id
                ,interface_invoice_id
                ,payment_method_indicator
                ,payment_method
                ,payment_amount
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,attribute16
                ,attribute17
                ,attribute18
                ,attribute19
                ,attribute20
            FROM cll_f189_payment_methods_iface
           WHERE interface_invoice_id = p_interface_invoice;
           -- 28592012 - End

           -- 29330466 - 29338175 - 29385361 - 29480917 - Start
      CURSOR c_referenced_documents (p_interface_invoice    IN NUMBER  ) IS
          SELECT interface_ref_document_id
                ,interface_invoice_id
                ,referenced_documents_type
                ,eletronic_invoice_key
                ,source_document_type
                ,document_description
                ,document_number
                ,document_issue_date
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,attribute16
                ,attribute17
                ,attribute18
                ,attribute19
                ,attribute20
            FROM cll_f189_ref_docs_iface
           WHERE interface_invoice_id = p_interface_invoice;
           -- 29330466 - 29338175 - 29385361 - 29480917 - End
  --
  BEGIN
    --
    print_log('  XXFR_F189_OPEN_INTERFACE_PKG.OPEN_INTERFACE');
    FOR r_invoice_header IN c_invoice_header LOOP
        --
        -- Deleta as tabelas temporarias para o ID que esta sendo processado, pois se encontrar erro no processamento o registro com erro esta armazenado na temporaria
        -- e exibe erro de duplicidade de nota
        --
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_INVOICE_IFACE_TMP      (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_INV_LINE_IFACE_TMP     (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_FREIGHT_INV_IFACE_TMP  (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_INVOICE_PARENT_TMP     (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;
        --CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_INVOICE_PAR_LINES_TMP(p_interface_parent_id -- Feito dentro do Loop de Invoice Parents
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_LEGAL_PROCESSES_TMP    (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_OUTBOUND_INVOICES_TMP  (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_PAYMENT_METHODS_TMP    (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;   -- 29330466 - 29338175 - 29385361 - 29480917
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_REF_DOCUMENTS_TMP      (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;   -- 29330466 - 29338175 - 29385361 - 29480917
        CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_TPA_IFACE_TMP          (p_interface_invoice_id => r_invoice_header.interface_invoice_id) ;   -- Bug 29553127
        --
        -- Inserindo dados do Header da Open na tabela temporaria
        --
        CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_INVOICE_IFACE_TMP(p_interface_invoice_id         => r_invoice_header.interface_invoice_id
                                                             ,p_interface_operation_id       => r_invoice_header.interface_operation_id
                                                             ,p_source                       => r_invoice_header.source
                                                             ,p_process_flag                 => r_invoice_header.process_flag
                                                             ,p_gl_date                      => r_invoice_header.gl_date
                                                             ,p_freight_flag                 => r_invoice_header.freight_flag
                                                             ,p_total_freight_weight         => r_invoice_header.total_freight_weight
                                                             ,p_entity_id                    => r_invoice_header.entity_id
                                                             ,p_document_type                => r_invoice_header.document_type
                                                             ,p_document_number              => r_invoice_header.document_number
                                                             ,p_invoice_num                  => r_invoice_header.invoice_num
                                                             ,p_series                       => r_invoice_header.series
                                                             ,p_organization_id              => r_invoice_header.organization_id
                                                             ,p_organization_code            => r_invoice_header.organization_code
                                                             ,p_location_id                  => r_invoice_header.location_id
                                                             ,p_location_code                => r_invoice_header.location_code
                                                             ,p_invoice_amount               => r_invoice_header.invoice_amount
                                                             ,p_invoice_date                 => r_invoice_header.invoice_date
                                                             ,p_invoice_type_id              => r_invoice_header.invoice_type_id
                                                             ,p_invoice_type_code            => r_invoice_header.invoice_type_code
                                                             ,p_icms_type                    => r_invoice_header.icms_type
                                                             ,p_icms_base                    => r_invoice_header.icms_base
                                                             ,p_icms_tax                     => r_invoice_header.icms_tax
                                                             ,p_icms_amount                  => r_invoice_header.icms_amount
                                                             ,p_ipi_amount                   => r_invoice_header.ipi_amount
                                                             ,p_subst_icms_base              => r_invoice_header.subst_icms_base
                                                             ,p_subst_icms_amount            => r_invoice_header.subst_icms_amount
                                                             ,p_diff_icms_tax                => r_invoice_header.diff_icms_tax
                                                             ,p_diff_icms_amount             => r_invoice_header.diff_icms_amount
                                                             ,p_iss_base                     => r_invoice_header.iss_base
                                                             ,p_iss_amount                   => r_invoice_header.iss_amount
                                                             ,p_ir_base                      => r_invoice_header.ir_base
                                                             ,p_ir_tax                       => r_invoice_header.ir_tax
                                                             ,p_ir_amount                    => r_invoice_header.ir_amount
                                                             ,p_description                  => r_invoice_header.description
                                                             ,p_terms_id                     => r_invoice_header.terms_id
                                                             ,p_terms_name                   => r_invoice_header.terms_name
                                                             ,p_terms_date                   => r_invoice_header.terms_date
                                                             ,p_first_payment_date           => r_invoice_header.first_payment_date
                                                             ,p_insurance_amount             => r_invoice_header.insurance_amount
                                                             ,p_freight_amount               => r_invoice_header.freight_amount
                                                             ,p_payment_discount             => r_invoice_header.payment_discount
                                                             ,p_return_cfo_id                => r_invoice_header.return_cfo_id
                                                             ,p_return_cfo_code              => r_invoice_header.return_cfo_code
                                                             ,p_return_amount                => r_invoice_header.return_amount
                                                             ,p_return_date                  => r_invoice_header.return_date
                                                             ,p_additional_tax               => r_invoice_header.additional_tax
                                                             ,p_additional_amount            => r_invoice_header.additional_amount
                                                             ,p_other_expenses               => r_invoice_header.other_expenses
                                                             ,p_invoice_weight               => r_invoice_header.invoice_weight
                                                             ,p_contract_id                  => r_invoice_header.contract_id
                                                             ,p_dollar_invoice_amount        => r_invoice_header.dollar_invoice_amount
                                                             ,p_source_items                 => r_invoice_header.source_items
                                                             ,p_importation_number           => r_invoice_header.importation_number
                                                             ,p_po_conversion_rate           => r_invoice_header.po_conversion_rate
                                                             ,p_importation_freight_weight   => r_invoice_header.importation_freight_weight
                                                             ,p_total_fob_amount             => r_invoice_header.total_fob_amount
                                                             ,p_freight_international        => r_invoice_header.freight_international
                                                             ,p_importation_tax_amount       => r_invoice_header.importation_tax_amount
                                                             ,p_importation_insurance_amount => r_invoice_header.importation_insurance_amount
                                                             ,p_total_cif_amount             => r_invoice_header.total_cif_amount
                                                             ,p_customs_expense_func         => r_invoice_header.customs_expense_func
                                                             ,p_importation_expense_func     => r_invoice_header.importation_expense_func
                                                             ,p_dollar_total_fob_amount      => r_invoice_header.dollar_total_fob_amount
                                                             ,p_dollar_customs_expense       => r_invoice_header.dollar_customs_expense
                                                             ,p_dollar_freight_international => r_invoice_header.dollar_freight_international
                                                             ,p_dollar_import_tax_amount     => r_invoice_header.dollar_importation_tax_amount
                                                             ,p_dollar_insurance_amount      => r_invoice_header.dollar_insurance_amount
                                                             ,p_dollar_total_cif_amount      => r_invoice_header.dollar_total_cif_amount
                                                             ,p_importation_expense_dol      => r_invoice_header.importation_expense_dol
                                                             ,p_fiscal_document_model        => r_invoice_header.fiscal_document_model
                                                             ,p_irrf_base_date               => r_invoice_header.irrf_base_date
                                                             ,p_inss_base                    => r_invoice_header.inss_base
                                                             ,p_inss_tax                     => r_invoice_header.inss_tax
                                                             ,p_inss_amount                  => r_invoice_header.inss_amount
                                                             ,p_ir_vendor                    => r_invoice_header.ir_vendor
                                                             ,p_ir_categ                     => r_invoice_header.ir_categ
                                                             ,p_icms_st_base                 => r_invoice_header.icms_st_base
                                                             ,p_icms_st_amount               => r_invoice_header.icms_st_amount
                                                             ,p_icms_st_amount_recover       => r_invoice_header.icms_st_amount_recover
                                                             ,p_diff_icms_amount_recover     => r_invoice_header.diff_icms_amount_recover
                                                             ,p_alternate_currency_conv_rate => r_invoice_header.alternate_currency_conv_rate
                                                             ,p_gross_total_amount           => r_invoice_header.gross_total_amount
                                                             ,p_source_state_id              => r_invoice_header.source_state_id
                                                             ,p_destination_state_id         => r_invoice_header.destination_state_id
                                                             ,p_source_state_code            => r_invoice_header.source_state_code
                                                             ,p_destination_state_code       => r_invoice_header.destination_state_code
                                                             ,p_funrural_base                => r_invoice_header.funrural_base
                                                             ,p_funrural_tax                 => r_invoice_header.funrural_tax
                                                             ,p_funrural_amount              => r_invoice_header.funrural_amount
                                                             ,p_sest_senat_base              => r_invoice_header.sest_senat_base
                                                             ,p_sest_senat_tax               => r_invoice_header.sest_senat_tax
                                                             ,p_sest_senat_amount            => r_invoice_header.sest_senat_amount
                                                             ,p_user_defined_conversion_rate => r_invoice_header.user_defined_conversion_rate
                                                             ,p_po_currency_code             => r_invoice_header.po_currency_code
                                                             ,p_inss_autonomous_inv_total    => r_invoice_header.inss_autonomous_invoiced_total
                                                             ,p_inss_autonomous_amount       => r_invoice_header.inss_autonomous_amount
                                                             ,p_inss_autonomous_tax          => r_invoice_header.inss_autonomous_tax
                                                             ,p_inss_additional_tax_1        => r_invoice_header.inss_additional_tax_1
                                                             ,p_inss_additional_tax_2        => r_invoice_header.inss_additional_tax_2
                                                             ,p_inss_additional_tax_3        => r_invoice_header.inss_additional_tax_3
                                                             ,p_inss_additional_base_1       => r_invoice_header.inss_additional_base_1
                                                             ,p_inss_additional_base_2       => r_invoice_header.inss_additional_base_2
                                                             ,p_inss_additional_base_3       => r_invoice_header.inss_additional_base_3
                                                             ,p_inss_additional_amount_1     => r_invoice_header.inss_additional_amount_1
                                                             ,p_inss_additional_amount_2     => r_invoice_header.inss_additional_amount_2
                                                             ,p_inss_additional_amount_3     => r_invoice_header.inss_additional_amount_3
                                                             ,p_iss_city_id                  => r_invoice_header.iss_city_id
                                                             ,p_siscomex_amount              => r_invoice_header.siscomex_amount
                                                             ,p_dollar_siscomex_amount       => r_invoice_header.dollar_siscomex_amount
                                                             ,p_ship_via_lookup_code         => r_invoice_header.ship_via_lookup_code
                                                             ,p_iss_city_code                => r_invoice_header.iss_city_code
                                                             ,p_receive_date                 => r_invoice_header.receive_date
                                                             ,p_importation_pis_amount       => r_invoice_header.importation_pis_amount
                                                             ,p_importation_cofins_amount    => r_invoice_header.importation_cofins_amount
                                                             ,p_dollar_import_pis_amount     => r_invoice_header.dollar_importation_pis_amount
                                                             ,p_dollar_import_cofins_amount  => r_invoice_header.dollar_import_cofins_amount
                                                             ,p_income_code                  => r_invoice_header.income_code
                                                             ,p_ie                           => r_invoice_header.ie
                                                             ,p_creation_date                => r_invoice_header.creation_date
                                                             ,p_created_by                   => r_invoice_header.created_by
                                                             ,p_last_update_date             => r_invoice_header.last_update_date
                                                             ,p_last_updated_by              => r_invoice_header.last_updated_by
                                                             ,p_last_update_login            => r_invoice_header.last_update_login
                                                             ,p_ceo_attribute_category       => r_invoice_header.ceo_attribute_category
                                                             ,p_ceo_attribute1               => r_invoice_header.ceo_attribute1
                                                             ,p_ceo_attribute2               => r_invoice_header.ceo_attribute2
                                                             ,p_ceo_attribute3               => r_invoice_header.ceo_attribute3
                                                             ,p_ceo_attribute4               => r_invoice_header.ceo_attribute4
                                                             ,p_ceo_attribute5               => r_invoice_header.ceo_attribute5
                                                             ,p_ceo_attribute6               => r_invoice_header.ceo_attribute6
                                                             ,p_ceo_attribute7               => r_invoice_header.ceo_attribute7
                                                             ,p_ceo_attribute8               => r_invoice_header.ceo_attribute8
                                                             ,p_ceo_attribute9               => r_invoice_header.ceo_attribute9
                                                             ,p_ceo_attribute10              => r_invoice_header.ceo_attribute10
                                                             ,p_ceo_attribute11              => r_invoice_header.ceo_attribute11
                                                             ,p_ceo_attribute12              => r_invoice_header.ceo_attribute12
                                                             ,p_ceo_attribute13              => r_invoice_header.ceo_attribute13
                                                             ,p_ceo_attribute14              => r_invoice_header.ceo_attribute14
                                                             ,p_ceo_attribute15              => r_invoice_header.ceo_attribute15
                                                             ,p_ceo_attribute16              => r_invoice_header.ceo_attribute16
                                                             ,p_ceo_attribute17              => r_invoice_header.ceo_attribute17
                                                             ,p_ceo_attribute18              => r_invoice_header.ceo_attribute18
                                                             ,p_ceo_attribute19              => r_invoice_header.ceo_attribute19
                                                             ,p_ceo_attribute20              => r_invoice_header.ceo_attribute20
                                                             ,p_cin_attribute_category       => r_invoice_header.cin_attribute_category
                                                             ,p_cin_attribute1               => r_invoice_header.cin_attribute1
                                                             ,p_cin_attribute2               => r_invoice_header.cin_attribute2
                                                             ,p_cin_attribute3               => r_invoice_header.cin_attribute3
                                                             ,p_cin_attribute4               => r_invoice_header.cin_attribute4
                                                             ,p_cin_attribute5               => r_invoice_header.cin_attribute5
                                                             ,p_cin_attribute6               => r_invoice_header.cin_attribute6
                                                             ,p_cin_attribute7               => r_invoice_header.cin_attribute7
                                                             ,p_cin_attribute8               => r_invoice_header.cin_attribute8
                                                             ,p_cin_attribute9               => r_invoice_header.cin_attribute9
                                                             ,p_cin_attribute10              => r_invoice_header.cin_attribute10
                                                             ,p_cin_attribute11              => r_invoice_header.cin_attribute11
                                                             ,p_cin_attribute12              => r_invoice_header.cin_attribute12
                                                             ,p_cin_attribute13              => r_invoice_header.cin_attribute13
                                                             ,p_cin_attribute14              => r_invoice_header.cin_attribute14
                                                             ,p_cin_attribute15              => r_invoice_header.cin_attribute15
                                                             ,p_cin_attribute16              => r_invoice_header.cin_attribute16
                                                             ,p_cin_attribute17              => r_invoice_header.cin_attribute17
                                                             ,p_cin_attribute18              => r_invoice_header.cin_attribute18
                                                             ,p_cin_attribute19              => r_invoice_header.cin_attribute19
                                                             ,p_cin_attribute20              => r_invoice_header.cin_attribute20
                                                             ,p_di_date                      => r_invoice_header.di_date
                                                             ,p_clearance_date               => r_invoice_header.clearance_date
                                                             ,p_comments                     => r_invoice_header.comments
                                                             ,p_vehicle_seller_doc_number    => r_invoice_header.vehicle_seller_doc_number
                                                             ,p_vehicle_seller_state_id      => r_invoice_header.vehicle_seller_state_id
                                                             ,p_vehicle_seller_state_code    => r_invoice_header.vehicle_seller_state_code
                                                             ,p_third_party_amount           => r_invoice_header.third_party_amount
                                                             ,p_abatement_amount             => r_invoice_header.abatement_amount
                                                             ,p_import_document_type         => r_invoice_header.import_document_type
                                                             ,p_eletronic_invoice_key        => r_invoice_header.eletronic_invoice_key
                                                             ,p_process_indicator            => r_invoice_header.process_indicator
                                                             ,p_process_origin               => r_invoice_header.process_origin
                                                             ,p_subseries                    => r_invoice_header.subseries
                                                             ,p_icms_free_service_amount     => r_invoice_header.icms_free_service_amount
                                                             ,p_return_invoice_num           => r_invoice_header.return_invoice_num
                                                             ,p_return_series                => r_invoice_header.return_series
                                                             ,p_inss_subcontract_amount      => r_invoice_header.inss_subcontract_amount
                                                             ,p_invoice_parent_id            => r_invoice_header.invoice_parent_id
                                                             ,p_service_execution_date       => r_invoice_header.service_execution_date
                                                             ,p_pis_withhold_amount          => r_invoice_header.pis_withhold_amount
                                                             ,p_cofins_withhold_amount       => r_invoice_header.cofins_withhold_amount
                                                             ,p_drawback_granted_act_number  => r_invoice_header.drawback_granted_act_number
                                                             ,p_cte_type                     => r_invoice_header.cte_type
                                                             ,p_max_icms_amount_recover      => r_invoice_header.max_icms_amount_recover
                                                             ,p_icms_tax_rec_simpl_br        => r_invoice_header.icms_tax_rec_simpl_br
                                                             ,p_simplified_br_tax_flag       => r_invoice_header.simplified_br_tax_flag
                                                             ,p_social_security_contrib_tax  => r_invoice_header.social_security_contrib_tax    -- ER 17551029
                                                             ,p_gilrat_tax                   => r_invoice_header.gilrat_tax                     -- ER 17551029
                                                             ,p_senar_tax                    => r_invoice_header.senar_tax                      -- ER 17551029
                                                             ,p_social_security_contrib_amt  => r_invoice_header.social_security_contrib_amount -- 27153706
                                                             ,p_gilrat_amount                => r_invoice_header.gilrat_amount                  -- 27153706
                                                             ,p_senar_amount                 => r_invoice_header.senar_amount                   -- 27153706
                                                             ,p_worker_category_id           => r_invoice_header.worker_category_id             -- ER 17551029 4a Fase
                                                             ,p_category_code                => r_invoice_header.category_code                  -- ER 17551029 4a Fase
                                                             ,p_cbo_code                     => r_invoice_header.cbo_code                       -- ER 17551029 4a Fase
                                                             ,p_material_equipment_amount    => r_invoice_header.material_equipment_amount      -- ER 17551029 4a Fase
                                                             ,p_deduction_amount             => r_invoice_header.deduction_amount               -- ER 17551029 4a Fase
                                                             ,p_cno_id                       => r_invoice_header.cno_id                         -- 24325307
                                                             ,p_cno_number                   => r_invoice_header.cno_number                     -- ER 17551029 4a Fase
                                                             ,p_caepf_number                 => r_invoice_header.caepf_number                   -- ER 17551029 4a Fase
                                                             ,p_indicator_multiple_links     => r_invoice_header.indicator_multiple_links       -- ER 17551029 4a Fase
                                                             ,p_inss_service_amount_1        => r_invoice_header.inss_service_amount_1          -- ER 17551029 4a Fase
                                                             ,p_inss_service_amount_2        => r_invoice_header.inss_service_amount_2          -- ER 17551029 4a Fase
                                                             ,p_inss_service_amount_3        => r_invoice_header.inss_service_amount_3          -- ER 17551029 4a Fase
                                                             ,p_remuneration_freight_amount  => r_invoice_header.remuneration_freight_amount    -- ER 17551029 4a Fase
                                                             ,p_sest_senat_income_code       => r_invoice_header.sest_senat_income_code         -- ER 9923702
                                                             ,p_funrural_income_code         => r_invoice_header.funrural_income_code           -- ER 9923702
                                                             ,p_imp_other_val_included_icms  => r_invoice_header.import_other_val_included_icms -- ER 20450226
                                                             ,p_imp_other_val_not_icms       => r_invoice_header.import_other_val_not_icms      -- ER 20450226
                                                             ,p_doll_other_val_included_icms => r_invoice_header.dollar_other_val_included_icms -- ER 20450226
                                                             ,p_doll_other_val_not_icms      => r_invoice_header.dollar_other_val_not_icms      -- ER 20450226
                                                             ,p_carrier_document_type        => r_invoice_header.carrier_document_type          -- ER 20404053
                                                             ,p_carrier_document_number      => r_invoice_header.carrier_document_number        -- ER 20404053
                                                             ,p_carrier_state_id             => r_invoice_header.carrier_state_id               -- ER 20404053
                                                             ,p_carrier_ie                   => r_invoice_header.carrier_ie                     -- ER 20404053
                                                             ,p_carrier_vehicle_plate_num    => r_invoice_header.carrier_vehicle_plate_num      -- ER 20404053
                                                             ,p_usage_authorization          => r_invoice_header.usage_authorization            -- ER 20382276
                                                             ,p_dar_number                   => r_invoice_header.dar_number                     -- ER 20382276
                                                             ,p_dar_total_amount             => r_invoice_header.dar_total_amount               -- ER 20382276
                                                             ,p_dar_payment_date             => r_invoice_header.dar_payment_date               -- ER 20382276
                                                             ,p_first_alternative_rate       => r_invoice_header.first_alternative_rate         -- ER 20608903
                                                             ,p_second_alternative_rate      => r_invoice_header.second_alternative_rate        -- ER 20608903
                                                             ,p_lp_inss_initial_base_amount  => r_invoice_header.lp_inss_initial_base_amount    -- 21924115
                                                             ,p_lp_inss_base_amount          => r_invoice_header.lp_inss_base_amount            -- 21924115
                                                             ,p_lp_inss_rate                 => r_invoice_header.lp_inss_rate                   -- 21924115
                                                             ,p_lp_inss_amount               => r_invoice_header.lp_inss_amount                 -- 21924115
                                                             ,p_lp_inss_net_amount           => r_invoice_header.lp_inss_net_amount             -- 21924115
                                                             ,p_ip_inss_initial_base_amount  => r_invoice_header.ip_inss_initial_base_amount    -- 21924115
                                                             ,p_ip_inss_base_amount          => r_invoice_header.ip_inss_base_amount            -- 21924115
                                                             ,p_ip_inss_rate                 => r_invoice_header.ip_inss_rate                   -- 21924115
                                                             ,p_ip_inss_net_amount           => r_invoice_header.ip_inss_net_amount             -- 21924115
                                                             ,p_icms_fcp_amount              => r_invoice_header.icms_fcp_amount                -- 21804594
                                                             ,p_icms_sharing_dest_amount     => r_invoice_header.icms_sharing_dest_amount       -- 21804594
                                                             ,p_icms_sharing_source_amount   => r_invoice_header.icms_sharing_source_amount     -- 21804594
                                                             ,p_department_id                => r_invoice_header.department_id                  -- 22285738
                                                             ,p_importation_cide_amount      => r_invoice_header.importation_cide_amount        -- 25341463
                                                             ,p_dollar_import_cide_amount    => r_invoice_header.dollar_import_cide_amount      -- 25341463
                                                             ,p_total_fcp_amount             => r_invoice_header.total_fcp_amount               -- 25713076
                                                             ,p_total_fcp_st_amount          => r_invoice_header.total_fcp_st_amount            -- 25713076
                                                             ,p_sest_tax                     => r_invoice_header.sest_tax                       -- 25808200 - 25808214
                                                             ,p_senat_tax                    => r_invoice_header.senat_tax                      -- 25808200 - 25808214
                                                             ,p_sest_amount                  => r_invoice_header.sest_amount                    -- 25808200 - 25808214
                                                             ,p_senat_amount                 => r_invoice_header.senat_amount                   -- 25808200 - 25808214
                                                             ,p_source_city_id               => r_invoice_header.source_city_id                 -- 27463767
                                                             ,p_destination_city_id          => r_invoice_header.destination_city_id            -- 27463767
                                                             ,p_source_ibge_city_code        => r_invoice_header.source_ibge_city_code          -- 27463767
                                                             ,p_destination_ibge_city_code   => r_invoice_header.destination_ibge_city_code     -- 27463767
                                                             ,p_reference                    => r_invoice_header.reference                      -- 27579747
                                                             ,p_ship_to_state_id             => r_invoice_header.ship_to_state_id               -- 28487689 - 28597878
                                                             ,p_freight_mode                 => r_invoice_header.freight_mode                   -- 29330466 - 29338175 - 29385361 - 29480917
                                                             ,p_fisco_additional_information => r_invoice_header.fisco_additional_information   -- 29330466 - 29338175 - 29385361 - 29480917
                                                             ,p_ir_cumulative_base           => r_invoice_header.ir_cumulative_base             -- 29448946
                                                             ,p_iss_mat_third_parties_amount => r_invoice_header.iss_mat_third_parties_amount   -- 29635195
                                                             ,p_iss_subcontract_amount       => r_invoice_header.iss_subcontract_amount         -- 29635195
                                                             ,p_iss_exempt_transac_amount    => r_invoice_header.iss_exempt_transactions_amount -- 29635195
                                                             ,p_iss_deduction_amount         => r_invoice_header.iss_deduction_amount           -- 29635195
                                                             ,p_iss_fiscal_observation       => r_invoice_header.iss_fiscal_observation         -- 29635195
                                                             ,p_return_code                  => l_return_code
                                                             ,p_return_message               => l_return_message
                                                             );
        --
        IF l_return_code IS NULL THEN
            --
            FOR r_invoice_lines IN c_invoice_lines (p_interface_invoice => r_invoice_header.interface_invoice_id)  LOOP
                --
                -- Inserindo dados de Lines da Open na tabela temporaria
                --
                CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_INV_LINE_IFACE_TMP(p_interface_invoice_id         => r_invoice_lines.interface_invoice_id
                                                                      ,p_interface_invoice_line_id    => r_invoice_lines.interface_invoice_line_id
                                                                      ,p_invoice_id                   => r_invoice_lines.invoice_id
                                                                      ,p_line_location_id             => r_invoice_lines.line_location_id
                                                                      ,p_requisition_line_id          => r_invoice_lines.requisition_line_id
                                                                      ,p_item_id                      => r_invoice_lines.item_id
                                                                      ,p_db_code_combination_id       => r_invoice_lines.db_code_combination_id
                                                                      ,p_classification_id            => r_invoice_lines.classification_id
                                                                      ,p_classification_code          => r_invoice_lines.classification_code
                                                                      ,p_utilization_id               => r_invoice_lines.utilization_id
                                                                      ,p_utilization_code             => r_invoice_lines.utilization_code
                                                                      ,p_cfo_id                       => r_invoice_lines.cfo_id
                                                                      ,p_cfo_code                     => r_invoice_lines.cfo_code
                                                                      ,p_uom                          => r_invoice_lines.uom
                                                                      ,p_quantity                     => r_invoice_lines.quantity
                                                                      ,p_unit_price                   => r_invoice_lines.unit_price
                                                                      ,p_operation_fiscal_type        => r_invoice_lines.operation_fiscal_type
                                                                      ,p_description                  => r_invoice_lines.description
                                                                      ,p_icms_base                    => r_invoice_lines.icms_base
                                                                      ,p_icms_tax                     => r_invoice_lines.icms_tax
                                                                      ,p_icms_amount                  => r_invoice_lines.icms_amount
                                                                      ,p_icms_amount_recover          => r_invoice_lines.icms_amount_recover
                                                                      ,p_icms_tax_code                => r_invoice_lines.icms_tax_code
                                                                      ,p_diff_icms_tax                => r_invoice_lines.diff_icms_tax
                                                                      ,p_diff_icms_amount             => r_invoice_lines.diff_icms_amount
                                                                      ,p_ipi_base_amount              => r_invoice_lines.ipi_base_amount
                                                                      ,p_ipi_tax                      => r_invoice_lines.ipi_tax
                                                                      ,p_ipi_amount                   => r_invoice_lines.ipi_amount
                                                                      ,p_ipi_amount_recover           => r_invoice_lines.ipi_amount_recover
                                                                      ,p_ipi_tax_code                 => r_invoice_lines.ipi_tax_code
                                                                      ,p_total_amount                 => r_invoice_lines.total_amount
                                                                      ,p_release_tax_hold_reason      => r_invoice_lines.release_tax_hold_reason
                                                                      ,p_tax_hold_released_by         => r_invoice_lines.tax_hold_released_by
                                                                      ,p_func_prepayment_amount       => r_invoice_lines.func_prepayment_amount
                                                                      ,p_dollar_prepayment_amount     => r_invoice_lines.dollar_prepayment_amount
                                                                      ,p_fob_amount                   => r_invoice_lines.fob_amount
                                                                      ,p_freight_internacional        => r_invoice_lines.freight_internacional
                                                                      ,p_importation_tax_amount       => r_invoice_lines.importation_tax_amount
                                                                      ,p_importation_insurance_amount => r_invoice_lines.importation_insurance_amount
                                                                      ,p_customs_expense_func         => r_invoice_lines.customs_expense_func
                                                                      ,p_importation_expense_func     => r_invoice_lines.importation_expense_func
                                                                      ,p_dollar_fob_amount            => r_invoice_lines.dollar_fob_amount
                                                                      ,p_dollar_freight_internacional => r_invoice_lines.dollar_freight_internacional
                                                                      ,p_dollar_import_tax_amount     => r_invoice_lines.dollar_importation_tax_amount
                                                                      ,p_dollar_insurance_amount      => r_invoice_lines.dollar_insurance_amount
                                                                      ,p_dollar_customs_expense       => r_invoice_lines.dollar_customs_expense
                                                                      ,p_dollar_importation_expense   => r_invoice_lines.dollar_importation_expense
                                                                      ,p_discount_percent             => r_invoice_lines.discount_percent
                                                                      ,p_icms_st_base                 => r_invoice_lines.icms_st_base
                                                                      ,p_icms_st_amount               => r_invoice_lines.icms_st_amount
                                                                      ,p_icms_st_amount_recover       => r_invoice_lines.icms_st_amount_recover
                                                                      ,p_diff_icms_amount_recover     => r_invoice_lines.diff_icms_amount_recover
                                                                      ,p_rma_interface_id             => r_invoice_lines.rma_interface_id
                                                                      ,p_other_expenses               => r_invoice_lines.other_expenses
                                                                      ,p_discount_amount              => r_invoice_lines.discount_amount
                                                                      ,p_freight_amount               => r_invoice_lines.freight_amount
                                                                      ,p_insurance_amount             => r_invoice_lines.insurance_amount
                                                                      ,p_purchase_order_num           => r_invoice_lines.purchase_order_num
                                                                      ,p_line_num                     => r_invoice_lines.line_num
                                                                      ,p_shipment_num                 => r_invoice_lines.shipment_num
                                                                      ,p_project_number               => r_invoice_lines.project_number
                                                                      ,p_project_id                   => r_invoice_lines.project_id
                                                                      ,p_task_number                  => r_invoice_lines.task_number
                                                                      ,p_task_id                      => r_invoice_lines.task_id
                                                                      ,p_expenditure_type             => r_invoice_lines.expenditure_type
                                                                      ,p_expenditure_org_name         => r_invoice_lines.expenditure_organization_name
                                                                      ,p_expenditure_org_id           => r_invoice_lines.expenditure_organization_id
                                                                      ,p_expenditure_item_date        => r_invoice_lines.expenditure_item_date
                                                                      ,p_pis_amount_recover           => r_invoice_lines.pis_amount_recover
                                                                      ,p_tributary_status_code        => r_invoice_lines.tributary_status_code
                                                                      ,p_cofins_amount_recover        => r_invoice_lines.cofins_amount_recover
                                                                      ,p_shipment_line_id             => r_invoice_lines.shipment_line_id
                                                                      ,p_freight_ap_flag              => r_invoice_lines.freight_ap_flag
                                                                      ,p_importation_pis_cofins_base  => r_invoice_lines.importation_pis_cofins_base
                                                                      ,p_importation_pis_amount       => r_invoice_lines.importation_pis_amount
                                                                      ,p_importation_cofins_amount    => r_invoice_lines.importation_cofins_amount
                                                                      ,p_awt_group_id                 => r_invoice_lines.awt_group_id
                                                                      ,p_creation_date                => r_invoice_lines.creation_date
                                                                      ,p_created_by                   => r_invoice_lines.created_by
                                                                      ,p_last_update_date             => r_invoice_lines.last_update_date
                                                                      ,p_last_updated_by              => r_invoice_lines.last_updated_by
                                                                      ,p_last_update_login            => r_invoice_lines.last_update_login
                                                                      ,p_attribute_category           => r_invoice_lines.attribute_category
                                                                      ,p_attribute1                   => r_invoice_lines.attribute1
                                                                      ,p_attribute2                   => r_invoice_lines.attribute2
                                                                      ,p_attribute3                   => r_invoice_lines.attribute3
                                                                      ,p_attribute4                   => r_invoice_lines.attribute4
                                                                      ,p_attribute5                   => r_invoice_lines.attribute5
                                                                      ,p_attribute6                   => r_invoice_lines.attribute6
                                                                      ,p_attribute7                   => r_invoice_lines.attribute7
                                                                      ,p_attribute8                   => r_invoice_lines.attribute8
                                                                      ,p_attribute9                   => r_invoice_lines.attribute9
                                                                      ,p_attribute10                  => r_invoice_lines.attribute10
                                                                      ,p_attribute11                  => r_invoice_lines.attribute11
                                                                      ,p_attribute12                  => r_invoice_lines.attribute12
                                                                      ,p_attribute13                  => r_invoice_lines.attribute13
                                                                      ,p_attribute14                  => r_invoice_lines.attribute14
                                                                      ,p_attribute15                  => r_invoice_lines.attribute15
                                                                      ,p_attribute16                  => r_invoice_lines.attribute16
                                                                      ,p_attribute17                  => r_invoice_lines.attribute17
                                                                      ,p_attribute18                  => r_invoice_lines.attribute18
                                                                      ,p_attribute19                  => r_invoice_lines.attribute19
                                                                      ,p_attribute20                  => r_invoice_lines.attribute20
                                                                      ,p_ipi_unit_amount              => r_invoice_lines.ipi_unit_amount
                                                                      ,p_city_service_type_rel_id     => r_invoice_lines.city_service_type_rel_id
                                                                      ,p_city_service_type_rel_code   => r_invoice_lines.city_service_type_rel_code
                                                                      ,p_iss_base_amount              => r_invoice_lines.iss_base_amount
                                                                      ,p_iss_tax_rate                 => r_invoice_lines.iss_tax_rate
                                                                      ,p_iss_tax_amount               => r_invoice_lines.iss_tax_amount
                                                                      ,p_ipi_tributary_code           => r_invoice_lines.ipi_tributary_code
                                                                      ,p_ipi_tributary_type           => r_invoice_lines.ipi_tributary_type
                                                                      ,p_pis_base_amount              => r_invoice_lines.pis_base_amount
                                                                      ,p_pis_tax_rate                 => r_invoice_lines.pis_tax_rate
                                                                      ,p_pis_qty                      => r_invoice_lines.pis_qty
                                                                      ,p_pis_unit_amount              => r_invoice_lines.pis_unit_amount
                                                                      ,p_pis_amount                   => r_invoice_lines.pis_amount
                                                                      ,p_pis_tributary_code           => r_invoice_lines.pis_tributary_code
                                                                      ,p_cofins_base_amount           => r_invoice_lines.cofins_base_amount
                                                                      ,p_cofins_tax_rate              => r_invoice_lines.cofins_tax_rate
                                                                      ,p_cofins_qty                   => r_invoice_lines.cofins_qty
                                                                      ,p_cofins_unit_amount           => r_invoice_lines.cofins_unit_amount
                                                                      ,p_cofins_amount                => r_invoice_lines.cofins_amount
                                                                      ,p_cofins_tributary_code        => r_invoice_lines.cofins_tributary_code
                                                                      ,p_exception_classif_code       => r_invoice_lines.exception_classification_code
                                                                      ,p_deferred_icms_amount         => r_invoice_lines.deferred_icms_amount
                                                                      ,p_net_amount                   => r_invoice_lines.net_amount
                                                                      ,p_icms_base_reduc_perc         => r_invoice_lines.icms_base_reduc_perc
                                                                      ,p_vehicle_oper_type            => r_invoice_lines.vehicle_oper_type
                                                                      ,p_vehicle_chassi               => r_invoice_lines.vehicle_chassi
                                                                      ,p_uom_po                       => r_invoice_lines.uom_po
                                                                      ,p_quantity_uom_po              => r_invoice_lines.quantity_uom_po
                                                                      ,p_unit_price_uom_po            => r_invoice_lines.unit_price_uom_po
                                                                      ,p_customs_total_value          => r_invoice_lines.customs_total_value
                                                                      ,p_ci_percent                   => r_invoice_lines.ci_percent
                                                                      ,p_total_import_parcel          => r_invoice_lines.total_import_parcel
                                                                      ,p_fci_number                   => r_invoice_lines.fci_number
                                                                      ,p_recopi_number                => r_invoice_lines.recopi_number                  -- Bug 20145693
                                                                      ,p_icms_type                    => r_invoice_lines.icms_type                      -- ER 9028781
                                                                      ,p_icms_free_service_amount     => r_invoice_lines.icms_free_service_amount       -- ER 9028781
                                                                      ,p_max_icms_amount_recover      => r_invoice_lines.max_icms_amount_recover        -- ER 9028781
                                                                      ,p_icms_tax_rec_simpl_br        => r_invoice_lines.icms_tax_rec_simpl_br          -- ER 9028781
                                                                      ,p_imp_other_val_included_icms  => r_invoice_lines.import_other_val_included_icms -- ER 20450226
                                                                      ,p_imp_other_val_not_icms       => r_invoice_lines.import_other_val_not_icms      -- ER 20450226
                                                                      ,p_med_maximum_price_consumer   => r_invoice_lines.med_maximum_price_consumer     -- ER 20382276
                                                                      ,p_item_number                  => r_invoice_lines.item_number                    -- 21645107
                                                                      ,p_cest_code                    => r_invoice_lines.cest_code                      -- 22119026
                                                                      ,p_icms_dest_base_amount        => r_invoice_lines.icms_dest_base_amount          -- 21804594
                                                                      ,p_icms_fcp_dest_perc           => r_invoice_lines.icms_fcp_dest_perc             -- 21804594
                                                                      ,p_icms_dest_tax                => r_invoice_lines.icms_dest_tax                  -- 21804594
                                                                      ,p_icms_sharing_inter_perc      => r_invoice_lines.icms_sharing_inter_perc        -- 21804594
                                                                      ,p_icms_fcp_amount              => r_invoice_lines.icms_fcp_amount                -- 21804594
                                                                      ,p_icms_sharing_dest_amount     => r_invoice_lines.icms_sharing_dest_amount       -- 21804594
                                                                      ,p_icms_sharing_source_amount   => r_invoice_lines.icms_sharing_source_amount     -- 21804594
                                                                      ,p_fundersul_per_u_meas         => r_invoice_lines.fundersul_per_u_meas           -- BUG 17056156
                                                                      ,p_fundersul_unit_amount        => r_invoice_lines.fundersul_unit_amount          -- BUG 17056156
                                                                      ,p_fundersul_unit_percent       => r_invoice_lines.fundersul_unit_percent         -- BUG 17056156
                                                                      ,p_fundersul_amount             => r_invoice_lines.fundersul_amount               -- BUG 17056156
                                                                      ,p_fundersul_addt_amount        => r_invoice_lines.fundersul_addt_amount          -- BUG 17056156
                                                                      ,p_diff_icms_base               => r_invoice_lines.diff_icms_base                 -- 22834666
                                                                      ,p_cide_base_amount             => r_invoice_lines.cide_base_amount               -- BUG 25341463
                                                                      ,p_cide_rate                    => r_invoice_lines.cide_rate                      -- BUG 25341463
                                                                      ,p_cide_amount                  => r_invoice_lines.cide_amount                    -- BUG 25341463
                                                                      ,p_cide_amount_recover          => r_invoice_lines.cide_amount_recover            -- BUG 25341463
                                                                      -- 25713076 - Start
                                                                      ,p_anvisa_product_code          => r_invoice_lines.anvisa_product_code
                                                                      ,p_anp_product_code             => r_invoice_lines.anp_product_code
                                                                    --,p_anp_product_description      => r_invoice_lines.anp_product_description        -- 26987509 - 26986232
                                                                      ,p_anp_product_descr            => r_invoice_lines.anp_product_descr              -- 26987509 - 26986232
                                                                      ,p_glp_derived_oil_perc         => r_invoice_lines.glp_derived_oil_perc
                                                                      ,p_glgnn_glp_product_perc       => r_invoice_lines.glgnn_glp_product_perc
                                                                      ,p_glgni_glp_product_perc       => r_invoice_lines.glgni_glp_product_perc
                                                                      ,p_starting_value               => r_invoice_lines.starting_value
                                                                      ,p_codif_authorization          => r_invoice_lines.codif_authorization
                                                                      ,p_significant_scale_prod_ind   => r_invoice_lines.significant_scale_prod_ind
                                                                      ,p_manufac_goods_doc_number     => r_invoice_lines.manufac_goods_doc_number
                                                                    --,p_lot_number                   => r_invoice_lines.lot_number                     -- 26987509 - 26986232
                                                                      ,p_product_lot_number           => r_invoice_lines.product_lot_number             -- 26987509 - 26986232
                                                                      ,p_lot_quantity                 => r_invoice_lines.lot_quantity
                                                                      ,p_production_date              => r_invoice_lines.production_date
                                                                      ,p_expiration_date              => r_invoice_lines.expiration_date
                                                                      ,p_aggregation_code             => r_invoice_lines.aggregation_code
                                                                      ,p_fcp_base_amount              => r_invoice_lines.fcp_base_amount
                                                                      ,p_fcp_rate                     => r_invoice_lines.fcp_rate
                                                                      ,p_fcp_amount                   => r_invoice_lines.fcp_amount
                                                                      ,p_fcp_st_base_amount           => r_invoice_lines.fcp_st_base_amount
                                                                      ,p_fcp_st_rate                  => r_invoice_lines.fcp_st_rate
                                                                      ,p_fcp_st_amount                => r_invoice_lines.fcp_st_amount
                                                                      -- 25713076 - End
                                                                      ,p_iss_city_id                  => r_invoice_lines.iss_city_id                    -- 25591653
                                                                      ,p_iss_city_code                => r_invoice_lines.iss_city_code                  -- 25591653
                                                                      ,p_service_execution_date       => r_invoice_lines.service_execution_date         -- 25591653
                                                                      ,p_iss_fo_base_amount           => r_invoice_lines.iss_fo_base_amount             -- 25591653
                                                                      ,p_iss_fo_tax_rate              => r_invoice_lines.iss_fo_tax_rate                -- 25591653
                                                                      ,p_iss_fo_amount                => r_invoice_lines.iss_fo_amount                  -- 25591653
                                                                      ,p_fcp_amount_recover           => r_invoice_lines.fcp_amount_recover             -- 28194547
                                                                      ,p_fcp_st_amount_recover        => r_invoice_lines.fcp_st_amount_recover          -- 28194547
                                                                      ,p_discount_net_amount          => r_invoice_lines.discount_net_amount            -- 28468398 - 28505834
                                                                      ,p_icms_st_prev_withheld_base   => r_invoice_lines.icms_st_prev_withheld_base     -- 28468398 - 28505834
                                                                      ,p_icms_st_prev_withheld_rate   => r_invoice_lines.icms_st_prev_withheld_tx_rate  -- 28468398 - 28505834
                                                                      ,p_icms_st_prev_withheld_amount => r_invoice_lines.icms_st_prev_withheld_amount   -- 28468398 - 28505834
                                                                      ,p_fcp_st_prev_withheld_base    => r_invoice_lines.fcp_st_prev_withheld_base      -- 28468398 - 28505834
                                                                      ,p_fcp_st_prev_withheld_rate    => r_invoice_lines.fcp_st_prev_withheld_tx_rate   -- 28468398 - 28505834
                                                                      ,p_fcp_st_prev_withheld_amount  => r_invoice_lines.fcp_st_prev_withheld_amount    -- 28468398 - 28505834
                                                                      ,p_ipi_tributary_code_out       => r_invoice_lines.ipi_tributary_code_out         -- 228730077
                                                                      ,p_tributary_status_code_out    => r_invoice_lines.tributary_status_code_out      -- 228730077
                                                                      ,p_pis_tributary_code_out       => r_invoice_lines.pis_tributary_code_out         -- 228730077
                                                                      ,p_cofins_tributary_code_out    => r_invoice_lines.cofins_tributary_code_out      -- 228730077
                                                                      ,p_additional_information_code  => r_invoice_lines.additional_information_code    -- 28843378
                                                                      ,p_anvisa_exemption_reazon      => r_invoice_lines.anvisa_exemption_reazon        -- 29330466 - 29338175 - 29385361 - 29480917
                                                                      ,p_icms_prev_withheld_amount    => r_invoice_lines.icms_prev_withheld_amount      -- 29330466 - 29338175 - 29385361 - 29480917
                                                                      ,p_return_code                  => l_return_code
                                                                      ,p_return_message               => l_return_message
                                                                      );
            --
            END LOOP; --r_invoice_lines
            --
            FOR r_freight IN c_freight (p_interface_invoice      => r_invoice_header.interface_invoice_id
                                       ,p_location_id            => r_invoice_header.location_id
                                       ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                       )  LOOP
                --
                -- Inserindo dados de Frete da Open na tabela temporaria
                --
                CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_FREIGHT_INV_IFACE_TMP(p_interface_invoice_id     => r_freight.interface_invoice_id
                                                                         ,p_entity_id                => r_freight.entity_id
                                                                         ,p_document_type            => r_freight.document_type
                                                                         ,p_document_number          => r_freight.document_number
                                                                         ,p_invoice_num              => r_freight.invoice_num
                                                                         ,p_series                   => r_freight.series
                                                                         ,p_interface_operation_id   => r_freight.interface_operation_id
                                                                         ,p_organization_id          => r_freight.organization_id
                                                                         ,p_organization_code        => r_freight.organization_code
                                                                         ,p_location_id              => r_freight.location_id
                                                                         ,p_location_code            => r_freight.location_code
                                                                         ,p_invoice_date             => r_freight.invoice_date
                                                                         ,p_invoice_amount           => r_freight.invoice_amount
                                                                         ,p_invoice_type_id          => r_freight.invoice_type_id
                                                                         ,p_invoice_type_code        => r_freight.invoice_type_code
                                                                         ,p_cfo_id                   => r_freight.cfo_id
                                                                         ,p_cfo_code                 => r_freight.cfo_code
                                                                         ,p_terms_id                 => r_freight.terms_id
                                                                         ,p_terms_name               => r_freight.terms_name
                                                                         ,p_terms_date               => r_freight.terms_date
                                                                         ,p_first_payment_date       => r_freight.first_payment_date
                                                                         ,p_po_header_id             => r_freight.po_header_id
                                                                         ,p_description              => r_freight.description
                                                                         ,p_total_freight_weight     => r_freight.total_freight_weight
                                                                         ,p_icms_type                => r_freight.icms_type
                                                                         ,p_icms_base                => r_freight.icms_base
                                                                         ,p_icms_tax                 => r_freight.icms_tax
                                                                         ,p_icms_amount              => r_freight.icms_amount
                                                                         ,p_diff_icms_tax            => r_freight.diff_icms_tax
                                                                         ,p_diff_icms_amount         => r_freight.diff_icms_amount
                                                                         ,p_ship_via_lookup_code     => r_freight.ship_via_lookup_code
                                                                         ,p_fiscal_document_model    => r_freight.fiscal_document_model
                                                                         ,p_diff_icms_amount_recover => r_freight.diff_icms_amount_recover
                                                                         ,p_source_state_id          => r_freight.source_state_id
                                                                         ,p_destination_state_id     => r_freight.destination_state_id
                                                                         ,p_source_state_code        => r_freight.source_state_code
                                                                         ,p_destination_state_code   => r_freight.destination_state_code
                                                                         ,p_creation_date            => r_freight.creation_date
                                                                         ,p_created_by               => r_freight.created_by
                                                                         ,p_last_update_date         => r_freight.last_update_date
                                                                         ,p_last_updated_by          => r_freight.last_updated_by
                                                                         ,p_last_update_login        => r_freight.last_update_login
                                                                         ,p_attribute_category       => r_freight.attribute_category
                                                                         ,p_attribute1               => r_freight.attribute1
                                                                         ,p_attribute2               => r_freight.attribute2
                                                                         ,p_attribute3               => r_freight.attribute3
                                                                         ,p_attribute4               => r_freight.attribute4
                                                                         ,p_attribute5               => r_freight.attribute5
                                                                         ,p_attribute6               => r_freight.attribute6
                                                                         ,p_attribute7               => r_freight.attribute7
                                                                         ,p_attribute8               => r_freight.attribute8
                                                                         ,p_attribute9               => r_freight.attribute9
                                                                         ,p_attribute10              => r_freight.attribute10
                                                                         ,p_attribute11              => r_freight.attribute11
                                                                         ,p_attribute12              => r_freight.attribute12
                                                                         ,p_attribute13              => r_freight.attribute13
                                                                         ,p_attribute14              => r_freight.attribute14
                                                                         ,p_attribute15              => r_freight.attribute15
                                                                         ,p_attribute16              => r_freight.attribute16
                                                                         ,p_attribute17              => r_freight.attribute17
                                                                         ,p_attribute18              => r_freight.attribute18
                                                                         ,p_attribute19              => r_freight.attribute19
                                                                         ,p_attribute20              => r_freight.attribute20
                                                                         ,p_subseries                => r_freight.subseries
                                                                         ,p_utilization_id           => r_freight.utilization_id
                                                                         ,p_utilization_code         => r_freight.utilization_code
                                                                         ,p_tributary_status_code    => r_freight.tributary_status_code
                                                                         ,p_cte_type                 => r_freight.cte_type
                                                                         ,p_eletronic_invoice_key    => r_freight.eletronic_invoice_key
                                                                         ,p_simplified_br_tax_flag   => r_freight.simplified_br_tax_flag
                                                                         ,p_icms_tax_code            => r_freight.icms_tax_code
                                                                         ,p_cofins_tax_rate          => r_freight.cofins_tax_rate
                                                                         ,p_cofins_base_amount       => r_freight.cofins_base_amount
                                                                         ,p_cofins_amount_recover    => r_freight.cofins_amount_recover
                                                                         ,p_pis_amount_recover       => r_freight.pis_amount_recover
                                                                         ,p_pis_base_amount          => r_freight.pis_base_amount
                                                                         ,p_pis_tax_rate             => r_freight.pis_tax_rate
                                                                         ,p_pis_tributary_code       => r_freight.pis_tributary_code
                                                                         ,p_cofins_tributary_code    => r_freight.cofins_tributary_code
                                                                         ,p_usage_authorization      => r_freight.usage_authorization -- ER 20382276
                                                                         ,p_source_city_id           => r_freight.source_city_id               -- 27463767
                                                                         ,p_destination_city_id      => r_freight.destination_city_id          -- 27463767
                                                                         ,p_source_ibge_city_code    => r_freight.source_ibge_city_code        -- 27463767
                                                                         ,p_destination_ibge_city_code => r_freight.destination_ibge_city_code -- 27463767
                                                                         ,p_reference                => r_freight.reference                    -- 27579747
                                                                         ,p_ship_to_state_id         => r_freight.ship_to_state_id             -- 28487689 - 28597878
                                                                         ,p_return_code              => l_return_code
                                                                         ,p_return_message           => l_return_message
                                                                         );
                --
                -- Inserindo na tabela de processo legal
                --
                FOR r_legal_processes IN c_legal_processes (p_interface_invoice => r_freight.interface_invoice_id
                                                           ) LOOP
                    --
                    -- Inserindo dados do Processo Legal da Open na tabela temporaria
                    --
                    CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_LEGAL_PROCESSES_TMP(p_interface_invoice_id => r_legal_processes.interface_invoice_id
                                                                           ,p_legal_process_id     => r_legal_processes.legal_process_id
                                                                           ,p_reference_table      => r_legal_processes.reference_table
                                                                           ,p_legal_process_number => r_legal_processes.legal_process_number
                                                                           ,p_process_origin       => r_legal_processes.process_origin
                                                                           ,p_creation_date        => r_legal_processes.creation_date
                                                                           ,p_created_by           => r_legal_processes.created_by
                                                                           ,p_last_update_date     => r_legal_processes.last_update_date
                                                                           ,p_last_updated_by      => r_legal_processes.last_updated_by
                                                                           ,p_last_update_login    => r_legal_processes.last_update_login
                                                                           ,p_attribute_category   => r_legal_processes.attribute_category
                                                                           ,p_attribute1           => r_legal_processes.attribute1
                                                                           ,p_attribute2           => r_legal_processes.attribute2
                                                                           ,p_attribute3           => r_legal_processes.attribute3
                                                                           ,p_attribute4           => r_legal_processes.attribute4
                                                                           ,p_attribute5           => r_legal_processes.attribute5
                                                                           ,p_attribute6           => r_legal_processes.attribute6
                                                                           ,p_attribute7           => r_legal_processes.attribute7
                                                                           ,p_attribute8           => r_legal_processes.attribute8
                                                                           ,p_attribute9           => r_legal_processes.attribute9
                                                                           ,p_attribute10          => r_legal_processes.attribute10
                                                                           ,p_attribute11          => r_legal_processes.attribute11
                                                                           ,p_attribute12          => r_legal_processes.attribute12
                                                                           ,p_attribute13          => r_legal_processes.attribute13
                                                                           ,p_attribute14          => r_legal_processes.attribute14
                                                                           ,p_attribute15          => r_legal_processes.attribute15
                                                                           ,p_attribute16          => r_legal_processes.attribute16
                                                                           ,p_attribute17          => r_legal_processes.attribute17
                                                                           ,p_attribute18          => r_legal_processes.attribute18
                                                                           ,p_attribute19          => r_legal_processes.attribute19
                                                                           ,p_attribute20          => r_legal_processes.attribute20
                                                                           ,p_tax_type             => r_legal_processes.tax_type                   -- ER 17551029 4a Fase
                                                                           ,p_not_withheld_amount  => r_legal_processes.not_withheld_amount        -- ER 17551029 4a Fase
                                                                           ,p_process_id           => r_legal_processes.process_id                 -- 25808200 - 25808214
                                                                           ,p_process_suspension_code => r_legal_processes.process_suspension_code -- 25808200 - 25808214
                                                                           ,p_return_code          => l_return_code
                                                                           ,p_return_message       => l_return_message
                                                                           );
                    --
                END LOOP; --r_legal_processes
            END LOOP; --r_freight
                --
            FOR r_invoice_parents_header IN c_invoice_parents_header (p_interface_invoice => r_invoice_header.interface_invoice_id
                                                                     ) LOOP
                -- Deleta as tabelas temporarias para o ID que esta sendo processado, pois se encontrar erro no processamento o registro com erro esta armazenado na temporaria
                -- e exibe erro de duplicidade de nota
                CLL_F189_OPEN_INSERT_TMP_PUB.DELETE_INVOICE_PAR_LINES_TMP (p_interface_parent_id => r_invoice_parents_header.invoice_parent_id);
                --
                -- Inserindo dados de Nota Complementar da Open na tabela temporaria
                --
                CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_INVOICE_PARENT_TMP(p_interface_invoice_id => r_invoice_parents_header.interface_invoice_id
                                                                      ,p_interface_parent_id  => r_invoice_parents_header.interface_parent_id
                                                                      ,p_invoice_parent_id    => r_invoice_parents_header.invoice_parent_id
                                                                      ,p_invoice_parent_num   => r_invoice_parents_header.invoice_parent_num
                                                                      ,p_entity_id            => r_invoice_parents_header.entity_id
                                                                      ,p_invoice_date         => r_invoice_parents_header.invoice_date
                                                                      ,p_creation_date        => r_invoice_parents_header.creation_date
                                                                      ,p_created_by           => r_invoice_parents_header.created_by
                                                                      ,p_last_update_date     => r_invoice_parents_header.last_update_date
                                                                      ,p_last_updated_by      => r_invoice_parents_header.last_updated_by
                                                                      ,p_last_update_login    => r_invoice_parents_header.last_update_login
                                                                      ,p_attribute_category   => r_invoice_parents_header.attribute_category
                                                                      ,p_attribute1           => r_invoice_parents_header.attribute1
                                                                      ,p_attribute2           => r_invoice_parents_header.attribute2
                                                                      ,p_attribute3           => r_invoice_parents_header.attribute3
                                                                      ,p_attribute4           => r_invoice_parents_header.attribute4
                                                                      ,p_attribute5           => r_invoice_parents_header.attribute5
                                                                      ,p_attribute6           => r_invoice_parents_header.attribute6
                                                                      ,p_attribute7           => r_invoice_parents_header.attribute7
                                                                      ,p_attribute8           => r_invoice_parents_header.attribute8
                                                                      ,p_attribute9           => r_invoice_parents_header.attribute9
                                                                      ,p_attribute10          => r_invoice_parents_header.attribute10
                                                                      ,p_attribute11          => r_invoice_parents_header.attribute11
                                                                      ,p_attribute12          => r_invoice_parents_header.attribute12
                                                                      ,p_attribute13          => r_invoice_parents_header.attribute13
                                                                      ,p_attribute14          => r_invoice_parents_header.attribute14
                                                                      ,p_attribute15          => r_invoice_parents_header.attribute15
                                                                      ,p_attribute16          => r_invoice_parents_header.attribute16
                                                                      ,p_attribute17          => r_invoice_parents_header.attribute17
                                                                      ,p_attribute18          => r_invoice_parents_header.attribute18
                                                                      ,p_attribute19          => r_invoice_parents_header.attribute19
                                                                      ,p_attribute20          => r_invoice_parents_header.attribute20
                                                                      ,p_return_code          => l_return_code
                                                                      ,p_return_message       => l_return_message
                                                                      );
                IF l_return_code IS NULL THEN
                    --
                    FOR r_invoice_parent_lines IN c_invoice_parent_lines (p_interface_parent_id   => r_invoice_parents_header.interface_parent_id
                                                                         ) LOOP
                        --
                        -- Inserindo dados de Linhas da Nota Complementar da Open na tabela temporaria
                        --
                        CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_INVOICE_PAR_LINES_TMP(p_interface_parent_id       => r_invoice_parent_lines.interface_parent_id
                                                                                 ,p_interface_parent_line_id  => r_invoice_parent_lines.interface_parent_line_id
                                                                                 ,p_invoice_parent_line_id    => r_invoice_parent_lines.invoice_parent_line_id
                                                                                 ,p_interface_invoice_line_id => r_invoice_parent_lines.interface_invoice_line_id
                                                                                 ,p_creation_date             => r_invoice_parent_lines.creation_date
                                                                                 ,p_created_by                => r_invoice_parent_lines.created_by
                                                                                 ,p_last_update_date          => r_invoice_parent_lines.last_update_date
                                                                                 ,p_last_updated_by           => r_invoice_parent_lines.last_updated_by
                                                                                 ,p_last_update_login         => r_invoice_parent_lines.last_update_login
                                                                                 ,p_attribute_category        => r_invoice_parent_lines.attribute_category
                                                                                 ,p_attribute1                => r_invoice_parent_lines.attribute1
                                                                                 ,p_attribute2                => r_invoice_parent_lines.attribute2
                                                                                 ,p_attribute3                => r_invoice_parent_lines.attribute3
                                                                                 ,p_attribute4                => r_invoice_parent_lines.attribute4
                                                                                 ,p_attribute5                => r_invoice_parent_lines.attribute5
                                                                                 ,p_attribute6                => r_invoice_parent_lines.attribute6
                                                                                 ,p_attribute7                => r_invoice_parent_lines.attribute7
                                                                                 ,p_attribute8                => r_invoice_parent_lines.attribute8
                                                                                 ,p_attribute9                => r_invoice_parent_lines.attribute9
                                                                                 ,p_attribute10               => r_invoice_parent_lines.attribute10
                                                                                 ,p_attribute11               => r_invoice_parent_lines.attribute11
                                                                                 ,p_attribute12               => r_invoice_parent_lines.attribute12
                                                                                 ,p_attribute13               => r_invoice_parent_lines.attribute13
                                                                                 ,p_attribute14               => r_invoice_parent_lines.attribute14
                                                                                 ,p_attribute15               => r_invoice_parent_lines.attribute15
                                                                                 ,p_attribute16               => r_invoice_parent_lines.attribute16
                                                                                 ,p_attribute17               => r_invoice_parent_lines.attribute17
                                                                                 ,p_attribute18               => r_invoice_parent_lines.attribute18
                                                                                 ,p_attribute19               => r_invoice_parent_lines.attribute19
                                                                                 ,p_attribute20               => r_invoice_parent_lines.attribute20
                                                                                 ,p_return_code               => l_return_code
                                                                                 ,p_return_message            => l_return_message
                                                                                 );
                    END LOOP; --r_invoice_parents_header
                END IF;
            END LOOP; --r_invoice_parents_header
            --
            -- Inserindo na tabela de processo legal
            --
            FOR r_legal_processes IN c_legal_processes (p_interface_invoice => r_invoice_header.interface_invoice_id
                                                       ) LOOP
                --
                -- Inserindo dados do Processo Legal da Open na tabela temporaria
                --
                CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_LEGAL_PROCESSES_TMP(p_interface_invoice_id => r_legal_processes.interface_invoice_id
                                                                       ,p_legal_process_id     => r_legal_processes.legal_process_id
                                                                       ,p_reference_table      => r_legal_processes.reference_table
                                                                       ,p_legal_process_number => r_legal_processes.legal_process_number
                                                                       ,p_process_origin       => r_legal_processes.process_origin
                                                                       ,p_creation_date        => r_legal_processes.creation_date
                                                                       ,p_created_by           => r_legal_processes.created_by
                                                                       ,p_last_update_date     => r_legal_processes.last_update_date
                                                                       ,p_last_updated_by      => r_legal_processes.last_updated_by
                                                                       ,p_last_update_login    => r_legal_processes.last_update_login
                                                                       ,p_attribute_category   => r_legal_processes.attribute_category
                                                                       ,p_attribute1           => r_legal_processes.attribute1
                                                                       ,p_attribute2           => r_legal_processes.attribute2
                                                                       ,p_attribute3           => r_legal_processes.attribute3
                                                                       ,p_attribute4           => r_legal_processes.attribute4
                                                                       ,p_attribute5           => r_legal_processes.attribute5
                                                                       ,p_attribute6           => r_legal_processes.attribute6
                                                                       ,p_attribute7           => r_legal_processes.attribute7
                                                                       ,p_attribute8           => r_legal_processes.attribute8
                                                                       ,p_attribute9           => r_legal_processes.attribute9
                                                                       ,p_attribute10          => r_legal_processes.attribute10
                                                                       ,p_attribute11          => r_legal_processes.attribute11
                                                                       ,p_attribute12          => r_legal_processes.attribute12
                                                                       ,p_attribute13          => r_legal_processes.attribute13
                                                                       ,p_attribute14          => r_legal_processes.attribute14
                                                                       ,p_attribute15          => r_legal_processes.attribute15
                                                                       ,p_attribute16          => r_legal_processes.attribute16
                                                                       ,p_attribute17          => r_legal_processes.attribute17
                                                                       ,p_attribute18          => r_legal_processes.attribute18
                                                                       ,p_attribute19          => r_legal_processes.attribute19
                                                                       ,p_attribute20          => r_legal_processes.attribute20
                                                                       ,p_tax_type             => r_legal_processes.tax_type                   -- ER 17551029 4a Fase
                                                                       ,p_not_withheld_amount  => r_legal_processes.not_withheld_amount        -- ER 17551029 4a Fase
                                                                       ,p_process_id           => r_legal_processes.process_id                 -- 25808200 - 25808214
                                                                       ,p_process_suspension_code => r_legal_processes.process_suspension_code -- 25808200 - 25808214
                                                                       ,p_return_code          => l_return_code
                                                                       ,p_return_message       => l_return_message
                                                                       );
                --
            END LOOP; --r_legal_processes
            --
            -- Inserindo na tabela de notas de saida
            FOR r_outbound_invoices IN c_outbound_invoices (p_interface_invoice => r_invoice_header.interface_invoice_id
                                                            ) LOOP
                --
                -- Inserindo dados das Notas de saida da Open na tabela temporaria
                --
                CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_OUTBOUND_INVOICES_TMP(p_int_ra_cust_trx_id   => r_outbound_invoices.int_ra_cust_trx_id
                                                                         ,p_interface_invoice_id => r_outbound_invoices.interface_invoice_id
                                                                         ,p_customer_trx_id      => r_outbound_invoices.customer_trx_id
                                                                         ,p_cust_acct_site_id    => r_outbound_invoices.cust_acct_site_id
                                                                         ,p_trx_number           => r_outbound_invoices.trx_number
                                                                         ,p_creation_date        => r_outbound_invoices.creation_date
                                                                         ,p_created_by           => r_outbound_invoices.created_by
                                                                         ,p_last_update_date     => r_outbound_invoices.last_update_date
                                                                         ,p_last_updated_by      => r_outbound_invoices.last_updated_by
                                                                         ,p_last_update_login    => r_outbound_invoices.last_update_login
                                                                         ,p_attribute_category   => r_outbound_invoices.attribute_category
                                                                         ,p_attribute1           => r_outbound_invoices.attribute1
                                                                         ,p_attribute2           => r_outbound_invoices.attribute2
                                                                         ,p_attribute3           => r_outbound_invoices.attribute3
                                                                         ,p_attribute4           => r_outbound_invoices.attribute4
                                                                         ,p_attribute5           => r_outbound_invoices.attribute5
                                                                         ,p_attribute6           => r_outbound_invoices.attribute6
                                                                         ,p_attribute7           => r_outbound_invoices.attribute7
                                                                         ,p_attribute8           => r_outbound_invoices.attribute8
                                                                         ,p_attribute9           => r_outbound_invoices.attribute9
                                                                         ,p_attribute10          => r_outbound_invoices.attribute10
                                                                         ,p_attribute11          => r_outbound_invoices.attribute11
                                                                         ,p_attribute12          => r_outbound_invoices.attribute12
                                                                         ,p_attribute13          => r_outbound_invoices.attribute13
                                                                         ,p_attribute14          => r_outbound_invoices.attribute14
                                                                         ,p_attribute15          => r_outbound_invoices.attribute15
                                                                         ,p_attribute16          => r_outbound_invoices.attribute16
                                                                         ,p_attribute17          => r_outbound_invoices.attribute17
                                                                         ,p_attribute18          => r_outbound_invoices.attribute18
                                                                         ,p_attribute19          => r_outbound_invoices.attribute19
                                                                         ,p_attribute20          => r_outbound_invoices.attribute20
                                                                         ,p_eletronic_invoice_key => r_outbound_invoices.eletronic_invoice_key -- 27579747
                                                                         ,p_return_code          => l_return_code
                                                                         ,p_return_message       => l_return_message
                                                                         );
                --
            END LOOP; --r_outbound_invoices
            --
            -- ER 17551029 4a Fase - Start
            -- Inserindo na tabela de prior billings
            FOR r_prior_billings IN c_prior_billings (p_interface_invoice => r_invoice_header.interface_invoice_id
                                                            ) LOOP
                --
                -- Inserindo dados de prior billings da Open na tabela temporaria
                --

                CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_PRIOR_BILLINGS_TMP(p_prior_billings_id    => r_prior_billings.prior_billings_id
                                                                      ,p_interface_invoice_id => r_prior_billings.interface_invoice_id
                                                                      ,p_document_type        => r_prior_billings.document_type
                                                                      ,p_document_number      => r_prior_billings.document_number
                                                                      ,p_total_remuneration_amount => r_prior_billings.total_remuneration_amount
                                                                      ,p_creation_date        => r_prior_billings.creation_date
                                                                      ,p_created_by           => r_prior_billings.created_by
                                                                      ,p_last_update_date     => r_prior_billings.last_update_date
                                                                      ,p_last_updated_by      => r_prior_billings.last_updated_by
                                                                      ,p_last_update_login    => r_prior_billings.last_update_login
                                                                      ,p_attribute_category   => r_prior_billings.attribute_category
                                                                      ,p_attribute1           => r_prior_billings.attribute1
                                                                      ,p_attribute2           => r_prior_billings.attribute2
                                                                      ,p_attribute3           => r_prior_billings.attribute3
                                                                      ,p_attribute4           => r_prior_billings.attribute4
                                                                      ,p_attribute5           => r_prior_billings.attribute5
                                                                      ,p_attribute6           => r_prior_billings.attribute6
                                                                      ,p_attribute7           => r_prior_billings.attribute7
                                                                      ,p_attribute8           => r_prior_billings.attribute8
                                                                      ,p_attribute9           => r_prior_billings.attribute9
                                                                      ,p_attribute10          => r_prior_billings.attribute10
                                                                      ,p_attribute11          => r_prior_billings.attribute11
                                                                      ,p_attribute12          => r_prior_billings.attribute12
                                                                      ,p_attribute13          => r_prior_billings.attribute13
                                                                      ,p_attribute14          => r_prior_billings.attribute14
                                                                      ,p_attribute15          => r_prior_billings.attribute15
                                                                      ,p_attribute16          => r_prior_billings.attribute16
                                                                      ,p_attribute17          => r_prior_billings.attribute17
                                                                      ,p_attribute18          => r_prior_billings.attribute18
                                                                      ,p_attribute19          => r_prior_billings.attribute19
                                                                      ,p_attribute20          => r_prior_billings.attribute20
                                                                      ,p_category_code        => r_prior_billings.category_code -- 25808200 - 25808214
                                                                      ,p_return_code          => l_return_code
                                                                      ,p_return_message       => l_return_message
                                                                      );
                --
            END LOOP; --r_prior_billings
            --
            -- ER 17551029 4a Fase - End
            --
            -- 28592012 - Start
            -- Inserindo na tabela de payment methods

            FOR r_payment_methods IN c_payment_methods (p_interface_invoice => r_invoice_header.interface_invoice_id
                                                            ) LOOP

                --
                -- Inserindo dados de payment methods da Open na tabela temporaria
                --

                CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_PAYMENT_METHODS_TMP(p_payment_method_id        => r_payment_methods.payment_method_id
                                                                       ,p_interface_invoice_id     => r_payment_methods.interface_invoice_id
                                                                       ,p_payment_method_indicator => r_payment_methods.payment_method_indicator
                                                                       ,p_payment_method           => r_payment_methods.payment_method
                                                                       ,p_payment_amount           => r_payment_methods.payment_amount
                                                                       ,p_creation_date            => r_payment_methods.creation_date
                                                                       ,p_created_by               => r_payment_methods.created_by
                                                                       ,p_last_update_date         => r_payment_methods.last_update_date
                                                                       ,p_last_updated_by          => r_payment_methods.last_updated_by
                                                                       ,p_last_update_login        => r_payment_methods.last_update_login
                                                                       ,p_attribute_category       => r_payment_methods.attribute_category
                                                                       ,p_attribute1               => r_payment_methods.attribute1
                                                                       ,p_attribute2               => r_payment_methods.attribute2
                                                                       ,p_attribute3               => r_payment_methods.attribute3
                                                                       ,p_attribute4               => r_payment_methods.attribute4
                                                                       ,p_attribute5               => r_payment_methods.attribute5
                                                                       ,p_attribute6               => r_payment_methods.attribute6
                                                                       ,p_attribute7               => r_payment_methods.attribute7
                                                                       ,p_attribute8               => r_payment_methods.attribute8
                                                                       ,p_attribute9               => r_payment_methods.attribute9
                                                                       ,p_attribute10              => r_payment_methods.attribute10
                                                                       ,p_attribute11              => r_payment_methods.attribute11
                                                                       ,p_attribute12              => r_payment_methods.attribute12
                                                                       ,p_attribute13              => r_payment_methods.attribute13
                                                                       ,p_attribute14              => r_payment_methods.attribute14
                                                                       ,p_attribute15              => r_payment_methods.attribute15
                                                                       ,p_attribute16              => r_payment_methods.attribute16
                                                                       ,p_attribute17              => r_payment_methods.attribute17
                                                                       ,p_attribute18              => r_payment_methods.attribute18
                                                                       ,p_attribute19              => r_payment_methods.attribute19
                                                                       ,p_attribute20              => r_payment_methods.attribute20
                                                                       ,p_return_code              => l_return_code
                                                                       ,p_return_message           => l_return_message
                                                                       );
                --
            END LOOP; --r_payment_methods
            -- 28592012 - End
            --
            -- 29330466 - 29338175 - 29385361 - 29480917 - Start
            -- Inserindo na tabela de Referenced Documents

            FOR r_referenced_documents IN c_referenced_documents (p_interface_invoice => r_invoice_header.interface_invoice_id
                                                            ) LOOP

                --
                -- Inserindo dados de Referenced Documents da Open na tabela temporaria
                --
                CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_REF_DOCUMENTS_TMP (p_interface_ref_document_id => r_referenced_documents.interface_ref_document_id
                                                                      ,p_interface_invoice_id      => r_referenced_documents.interface_invoice_id
                                                                      ,p_referenced_documents_type => r_referenced_documents.referenced_documents_type
                                                                      ,p_eletronic_invoice_key     => r_referenced_documents.eletronic_invoice_key
                                                                      ,p_source_document_type      => r_referenced_documents.source_document_type
                                                                      ,p_document_description      => r_referenced_documents.document_description
                                                                      ,p_document_number           => r_referenced_documents.document_number
                                                                      ,p_document_issue_date       => r_referenced_documents.document_issue_date
                                                                      ,p_creation_date             => r_referenced_documents.creation_date
                                                                      ,p_created_by                => r_referenced_documents.created_by
                                                                      ,p_last_update_date          => r_referenced_documents.last_update_date
                                                                      ,p_last_updated_by           => r_referenced_documents.last_updated_by
                                                                      ,p_last_update_login         => r_referenced_documents.last_update_login
                                                                      ,p_attribute_category        => r_referenced_documents.attribute_category
                                                                      ,p_attribute1                => r_referenced_documents.attribute1
                                                                      ,p_attribute2                => r_referenced_documents.attribute2
                                                                      ,p_attribute3                => r_referenced_documents.attribute3
                                                                      ,p_attribute4                => r_referenced_documents.attribute4
                                                                      ,p_attribute5                => r_referenced_documents.attribute5
                                                                      ,p_attribute6                => r_referenced_documents.attribute6
                                                                      ,p_attribute7                => r_referenced_documents.attribute7
                                                                      ,p_attribute8                => r_referenced_documents.attribute8
                                                                      ,p_attribute9                => r_referenced_documents.attribute9
                                                                      ,p_attribute10               => r_referenced_documents.attribute10
                                                                      ,p_attribute11               => r_referenced_documents.attribute11
                                                                      ,p_attribute12               => r_referenced_documents.attribute12
                                                                      ,p_attribute13               => r_referenced_documents.attribute13
                                                                      ,p_attribute14               => r_referenced_documents.attribute14
                                                                      ,p_attribute15               => r_referenced_documents.attribute15
                                                                      ,p_attribute16               => r_referenced_documents.attribute16
                                                                      ,p_attribute17               => r_referenced_documents.attribute17
                                                                      ,p_attribute18               => r_referenced_documents.attribute18
                                                                      ,p_attribute19               => r_referenced_documents.attribute19
                                                                      ,p_attribute20               => r_referenced_documents.attribute20
                                                                      ,p_return_code               => l_return_code
                                                                      ,p_return_message            => l_return_message
                                                                      );
                --
            END LOOP; --r_referenced_documents
            -- 29330466 - 29338175 - 29385361 - 29480917 - End
            --
            -- -------------------------------------------------
            -- ER 26338366/26899224  dgouveia 04/10/2017 - Start
            -- -------------------------------------------------
            --  Description: Responsible for insert into                                 |
            --  CLL F513 third Party transaction in tmp table               |
            --print_log(' CLL_F189_OPEN_INTERFACE_PKG call CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_INV_TPA_IFACE_TMP');
            --print_log(' CLL_F189_OPEN_INTERFACE_PKG antes do cursor r_invoice_header.interface_invoice_id='||r_invoice_header.interface_invoice_id);
            --
            FOR r_tpa IN c_tpa (p_interface_invoice => r_invoice_header.interface_invoice_id) LOOP
                --
                -- Inserindo dados de tpa na tabela temporaria da open
                --
                print_log(' CLL_F189_OPEN_INTERFACE_PKG entrou no loop call CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_INV_TPA_IFACE_TMP from CLL_F189_open_interface_pkg');
				--
                cll_f189_open_insert_tmp_pub.create_inv_tpa_iface_tmp ( p_interface_invoice_id      => r_tpa.interface_invoice_id
                                                                      , p_interface_invoice_line_id => r_tpa.interface_invoice_line_id
                                                                      , p_tpa_remit_interface_id    => r_tpa.tpa_remit_interface_id
                                                                      , p_tpa_remit_control_id      => r_tpa.tpa_remit_control_id
                                                                      , p_new_subinventory_code     => r_tpa.new_subinventory_code
                                                                      , p_new_locator_id            => r_tpa.new_locator_id
                                                                      , p_new_locator_code          => r_tpa.new_locator_code
                                                                      , p_attribute_category        => r_tpa.attribute_category
                                                                      , p_attribute1                => r_tpa.attribute1
                                                                      , p_attribute2                => r_tpa.attribute2
                                                                      , p_attribute3                => r_tpa.attribute3
                                                                      , p_attribute4                => r_tpa.attribute4
                                                                      , p_attribute5                => r_tpa.attribute5
                                                                      , p_attribute6                => r_tpa.attribute6
                                                                      , p_attribute7                => r_tpa.attribute7
                                                                      , p_attribute8                => r_tpa.attribute8
                                                                      , p_attribute9                => r_tpa.attribute9
                                                                      , p_attribute10               => r_tpa.attribute10
                                                                      , p_attribute11               => r_tpa.attribute11
                                                                      , p_attribute12               => r_tpa.attribute12
                                                                      , p_attribute13               => r_tpa.attribute13
                                                                      , p_attribute14               => r_tpa.attribute14
                                                                      , p_attribute15               => r_tpa.attribute15
                                                                      , p_attribute16               => r_tpa.attribute16
                                                                      , p_attribute17               => r_tpa.attribute17
                                                                      , p_attribute18               => r_tpa.attribute18
                                                                      , p_attribute19               => r_tpa.attribute19
                                                                      , p_attribute20               => r_tpa.attribute20
                                                                      , p_creation_date             => r_tpa.creation_date
                                                                      , p_created_by                => r_tpa.created_by
                                                                      , p_last_update_date          => r_tpa.last_update_date
                                                                      , p_last_update_login         => r_tpa.last_update_login
                                                                      , p_request_id                => r_tpa.request_id
                                                                      , p_program_application_id    => r_tpa.program_application_id
                                                                      , p_program_id                => r_tpa.program_id
                                                                      , p_program_update_date       => r_tpa.program_update_date
                                                                      , p_quantity                  => r_tpa.quantity               -- ER  26338366/26899224 2a Fase
                                                                      , p_symbolic_return_flag      => r_tpa.symbolic_return_flag   -- ENR 30120364
                                                                      , p_return_code               => l_return_code
                                                                      , p_return_message            => l_return_message
                                                                      ) ;
                --
            print_log('CLL_F189_OPEN_INTERFACE_PKG ap chamada CLL_F189_OPEN_INSERT_TMP_PUB.CREATE_INV_TPA_IFACE_TMP p_return_code='||l_return_code ||' l_return_message='||l_return_message);

            END LOOP;
            -- -------------------------------------------------
            -- ER 26338366/26899224  dgouveia 04/10/2017 - End
            -- -------------------------------------------------

            -- Com todos os dados populados nas tabelas termporarias, chama o processo de criacao da open para aquele operation_id
            --
            IF p_interface_invoice_id IS NULL THEN -- esta sendo executado pelo concurrent, nao informa o ID da nota na interface
                l_type_exec := 'C';
            ELSE
                l_type_exec := 'N';
            END IF;
            --
            print_log('l_type_exec:'||l_type_exec);
            print_log('Chamando... XXFR_F189_OPEN_PROCESSES_PUB.CREATE_OPEN_INTERFACE');
            XXFR_F189_OPEN_PROCESSES_PUB.CREATE_OPEN_INTERFACE (
              p_open_source          => 'RI'
              ,p_source               => p_source
              ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
              ,p_approve              => p_approve
              ,p_delete_line          => p_delete_line
              ,p_generate_line_compl  => p_generate_line_compl
              ,p_operating_unit       => p_operating_unit
              ,p_type_exec            => l_type_exec -- 'C'
              ,p_return_code          => l_return_code
              ,p_return_message       => l_return_message
            );
          print_log('Saida:'||l_return_message);
          errbuf := l_return_code;
          retcode:= l_return_message; 
        END IF; --IF l_return_code IS NULL THEN
        --
    END LOOP; --r_invoice_header
    print_log('  FIM XXFR_F189_OPEN_INTERFACE_PKG.OPEN_INTERFACE');
  
  END OPEN_INTERFACE;

END XXFR_F189_OPEN_INTERFACE_PKG;