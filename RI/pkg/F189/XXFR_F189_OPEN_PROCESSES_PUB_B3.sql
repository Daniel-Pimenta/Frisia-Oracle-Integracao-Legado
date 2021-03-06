create or replace PACKAGE BODY XXFR_F189_OPEN_PROCESSES_PUB AS
/* $Header: CLLPRICB.pls 120.220 2019/12/13 20:17:48 sasimoes noship $ */
  --
  g_source                          VARCHAR2(27); -- usada no ADD_ERROR -- 27579747
  g_aprova                          VARCHAR2(1);
  g_generate_line_compl             VARCHAR2(1);
  g_cll_f189_invoices_s             NUMBER;       -- usada para inserir na PARENTS
  g_cll_f189_entry_operations_s     NUMBER;
  g_interface_operation_id          NUMBER; -- Bug 18043475
  g_freight_inter_operation_id      NUMBER; -- Bug 23018594
  g_cont_par_inv                    NUMBER := 0;
  g_cont_par_inv_line               NUMBER := 0;
  g_cont_frt                        NUMBER := 0; -- usada para exibir no log a qtde de notas de frete inseridas
  g_cont_line                       NUMBER := 0; -- usada para exibir no log a qtde de linhas inseridas
  g_cont_leg_processes              NUMBER := 0; -- usada para exibir no log a qtde de legal processes inseridos
  g_cont_out_invoice                NUMBER := 0; -- usada para exibir no log a qtde de notas de saidas
  g_cont_prior_billings             NUMBER := 0; -- usada para exibir no log a qtde de prior billings -- ER 17551029 4a Fase
  g_cont_payment_methods            NUMBER := 0; -- usada para exibir no log a qtde de metodos de Pagamento -- 28592012
  g_cont_ref_documents              NUMBER := 0; -- usada para exibir no log a qtde de Documentos de referencia -- 29330466 - 29338175 - 29385361 - 29480917
  g_process_flag                    NUMBER := NULL; -- usada para atualizar o status de processamento
  g_interface_invoice_num           cll_f189_freight_inv_iface_tmp.invoice_num%type := NULL; -- Bug 23018594
  --
  g_operation_status                cll_f189_entry_operations.status%type; --ER 26338366/26899224 2a fase Third party network 11-dez-2017  Dgouveia
  --
  TYPE t_cll_f189_operation_rec IS RECORD (  
    interface_operation_id NUMBER
    , organization_id        NUMBER
    , gl_date                DATE
    , receive_date           DATE
    , location_id            NUMBER
    , new_operation_id       NUMBER
    , user_id                NUMBER
    , interface_invoice_id   NUMBER
  );
  --
  TYPE t_cll_f189_operation_tab IS TABLE OF t_cll_f189_operation_rec INDEX BY BINARY_INTEGER;
  --
  r_cll_f189_operation  t_cll_f189_operation_tab;
  g_cll_f189_operation  NUMBER;
  g_index               NUMBER;
  l_debug               NUMBER;
  
  function check_erro return varchar2 is
    qtd number;
  begin
    SELECT COUNT(1)
    INTO qtd
    FROM cll_f189_interface_errors
    WHERE interface_operation_id in (select interface_operation_id from  cll_f189_invoices_interface where source = g_source);
    return qtd||' - Debug:'||l_debug;
  end;
  
  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
  end;
  
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_INTERFACE                                       |
  |                                                                          |
  | Description: Responsible for validate information and insert into RI     |
  |              final tables or insert errors in RI or Loader interface     |
  |              tables                                                      |
  |              Open Interface - status                                     |
  |              1 = Pending                                                 |
  |              2 = Processing                                              |
  |              3 = In interface hold                                       |
  |              4 = In RI hold                                              |
  |              5 = Approved                                                |
  |              6 = Processed                                               |
  |              Primeiro deriva ORGANIZATION e LOCATION, depois o INVOICE   |
  |              TYPE, para iniciar as validacoes da Open                    |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OPEN_INTERFACE (
    p_open_source                IN VARCHAR2
    ,p_source                     IN VARCHAR2
    ,p_interface_invoice_id       IN NUMBER
    ,p_approve                    IN VARCHAR2
    ,p_delete_line                IN VARCHAR2
    ,p_generate_line_compl        IN VARCHAR2 DEFAULT 'N'
    ,p_operating_unit             IN NUMBER
    ,p_type_exec                  IN VARCHAR2
    ,p_return_code                OUT NOCOPY VARCHAR2
    ,p_return_message             OUT NOCOPY VARCHAR2
  ) IS

  CURSOR c_valida_invoice_header IS
    SELECT
      reci.interface_invoice_id,
      reci.interface_operation_id,
      reci.source,
      reci.organization_id,
      reci.organization_code,
      reci.location_id,
      reci.location_code,
      reci.invoice_type_id,
      reci.invoice_type_code
    FROM
      cll_f189_invoice_iface_tmp reci
    WHERE reci.process_flag = 1
      AND reci.source = p_source
      AND reci.interface_invoice_id = nvl(p_interface_invoice_id, reci.interface_invoice_id);

  CURSOR c_invoice_header IS
    SELECT reci.interface_invoice_id
          ,reci.interface_operation_id
          ,reci.source
        --,reci.gl_date                -- 29559606
          ,TRUNC(reci.gl_date) gl_date -- 29559606
          ,reci.freight_flag
          ,reci.total_freight_weight
          ,reci.entity_id
          ,reci.document_type
          ,reci.document_number
          ,reci.invoice_num
          ,reci.series
          ,reci.organization_id
          ,reci.organization_code
          ,reci.location_id
          ,reci.location_code
          ,reci.invoice_amount
          ,reci.invoice_date
          ,reci.invoice_type_id
          ,reci.invoice_type_code
          ,reci.icms_type
          ,reci.icms_base
          ,reci.icms_tax
          ,reci.icms_amount
          ,reci.ipi_amount
          ,reci.subst_icms_base
          ,reci.subst_icms_amount
          ,reci.diff_icms_tax
          ,reci.diff_icms_amount
          ,reci.iss_base
          ,reci.iss_amount
          ,reci.ir_base
          ,reci.ir_tax
          ,reci.ir_amount
          ,reci.description
          ,reci.terms_id
          ,reci.terms_name
          ,reci.terms_date
          ,reci.first_payment_date
          ,reci.insurance_amount
          ,reci.freight_amount
          ,reci.payment_discount
          ,reci.return_cfo_id
          ,reci.return_cfo_code
          ,reci.return_amount
          ,reci.return_date
          ,reci.additional_tax
          ,reci.additional_amount
          ,reci.other_expenses
          ,reci.invoice_weight
          ,reci.contract_id
          ,reci.dollar_invoice_amount
          ,reci.source_items
          ,reci.importation_number
          ,reci.po_conversion_rate
          ,reci.importation_freight_weight
          ,reci.total_fob_amount
          ,reci.freight_international
          ,reci.importation_tax_amount
          ,reci.importation_insurance_amount
          ,reci.total_cif_amount
          ,reci.customs_expense_func
          ,reci.importation_expense_func
          ,reci.dollar_total_fob_amount
          ,reci.dollar_customs_expense
          ,reci.dollar_freight_international
          ,reci.dollar_importation_tax_amount
          ,reci.dollar_insurance_amount
          ,reci.dollar_total_cif_amount
          ,reci.importation_expense_dol
          ,reci.fiscal_document_model
          ,reci.irrf_base_date
          ,reci.inss_base
          ,reci.inss_tax
          ,reci.inss_amount
          ,reci.lp_inss_initial_base_amount --  21924115
          ,reci.lp_inss_base_amount         --  21924115
          ,reci.lp_inss_rate                --  21924115
          ,reci.lp_inss_amount              --  21924115
          ,reci.lp_inss_net_amount          --  21924115
          ,reci.ip_inss_initial_base_amount --  21924115
          ,reci.ip_inss_base_amount         --  21924115
          ,reci.ip_inss_rate                --  21924115
          ,reci.ip_inss_net_amount          --  21924115
          ,reci.ir_vendor
          ,reci.ir_categ
          ,reci.icms_st_base
          ,reci.icms_st_amount
          ,reci.icms_st_amount_recover
          ,reci.diff_icms_amount_recover
          ,reci.alternate_currency_conv_rate
          ,reci.gross_total_amount
          ,reci.source_state_id
          ,reci.destination_state_id
          ,reci.source_state_code
          ,reci.destination_state_code
          ,reci.funrural_base
          ,reci.funrural_tax
          ,reci.funrural_amount
          ,reci.sest_senat_base
          ,reci.sest_senat_tax
          ,reci.sest_senat_amount
          ,reci.user_defined_conversion_rate
          ,reci.po_currency_code
          ,reci.inss_autonomous_invoiced_total
          ,reci.inss_autonomous_amount
          ,reci.inss_autonomous_tax
          ,reci.inss_additional_tax_1
          ,reci.inss_additional_tax_2
          ,reci.inss_additional_tax_3
          ,reci.inss_additional_base_1
          ,reci.inss_additional_base_2
          ,reci.inss_additional_base_3
          ,reci.inss_additional_amount_1
          ,reci.inss_additional_amount_2
          ,reci.inss_additional_amount_3
          ,reci.iss_city_id
          ,reci.siscomex_amount
          ,reci.dollar_siscomex_amount
          ,reci.ship_via_lookup_code
          ,reci.iss_city_code
        --,reci.receive_date                     -- 29559606
          ,TRUNC(reci.receive_date) receive_date -- 29559606
          ,reci.importation_pis_amount
          ,reci.importation_cofins_amount
          ,reci.dollar_importation_pis_amount
          ,reci.dollar_import_cofins_amount
          ,reci.income_code
          ,reci.ie
          ,reci.creation_date
          ,reci.created_by
          ,reci.last_update_date
          ,reci.last_updated_by
          ,reci.last_update_login
          ,reci.ceo_attribute_category
          ,reci.ceo_attribute1
          ,reci.ceo_attribute2
          ,reci.ceo_attribute3
          ,reci.ceo_attribute4
          ,reci.ceo_attribute5
          ,reci.ceo_attribute6
          ,reci.ceo_attribute7
          ,reci.ceo_attribute8
          ,reci.ceo_attribute9
          ,reci.ceo_attribute10
          ,reci.ceo_attribute11
          ,reci.ceo_attribute12
          ,reci.ceo_attribute13
          ,reci.ceo_attribute14
          ,reci.ceo_attribute15
          ,reci.ceo_attribute16
          ,reci.ceo_attribute17
          ,reci.ceo_attribute18
          ,reci.ceo_attribute19
          ,reci.ceo_attribute20
          ,reci.cin_attribute_category
          ,reci.cin_attribute1
          ,reci.cin_attribute2
          ,reci.cin_attribute3
          ,reci.cin_attribute4
          ,reci.cin_attribute5
          ,reci.cin_attribute6
          ,reci.cin_attribute7
          ,reci.cin_attribute8
          ,reci.cin_attribute9
          ,reci.cin_attribute10
          ,reci.cin_attribute11
          ,reci.cin_attribute12
          ,reci.cin_attribute13
          ,reci.cin_attribute14
          ,reci.cin_attribute15
          ,reci.cin_attribute16
          ,reci.cin_attribute17
          ,reci.cin_attribute18
          ,reci.cin_attribute19
          ,reci.cin_attribute20
          ,reci.di_date
          ,reci.clearance_date
          ,reci.comments
          ,reci.vehicle_seller_doc_number
          ,reci.vehicle_seller_state_id
          ,reci.vehicle_seller_state_code
          ,reci.third_party_amount
          ,reci.abatement_amount
          ,reci.import_document_type
          ,reci.eletronic_invoice_key
          ,reci.process_indicator
          ,reci.process_origin
          ,reci.subseries
          ,reci.icms_free_service_amount
          ,reci.return_invoice_num
          ,reci.return_series
          ,reci.inss_subcontract_amount
          ,reci.invoice_parent_id
          ,reci.service_execution_date
          ,reci.pis_withhold_amount
          ,reci.cofins_withhold_amount
          ,reci.drawback_granted_act_number
          ,reci.cte_type
          ,reci.max_icms_amount_recover
          ,reci.icms_tax_rec_simpl_br
          ,reci.simplified_br_tax_flag
          ,reci.social_security_contrib_tax -- ER 17551029
          ,reci.gilrat_tax                  -- ER 17551029
          ,reci.senar_tax                   -- ER 17551029
          ,reci.social_security_contrib_amount -- 27153706
          ,reci.gilrat_amount                  -- 27153706
          ,reci.senar_amount                   -- 27153706
          ,reci.worker_category_id          -- ER 17551029 4a Fase
          ,reci.category_code               -- ER 17551029 4a Fase
          ,reci.cbo_code                    -- ER 17551029 4a Fase
          ,reci.material_equipment_amount   -- ER 17551029 4a Fase
          ,reci.deduction_amount            -- ER 17551029 4a Fase
          ,reci.cno_id                      -- 24325307
          ,reci.cno_number                  -- ER 17551029 4a Fase
          ,reci.caepf_number                -- ER 17551029 4a Fase
          ,reci.indicator_multiple_links    -- ER 17551029 4a Fase
          ,reci.inss_service_amount_1       -- ER 17551029 4a Fase
          ,reci.inss_service_amount_2       -- ER 17551029 4a Fase
          ,reci.inss_service_amount_3       -- ER 17551029 4a Fase
          ,reci.remuneration_freight_amount -- ER 17551029 4a Fase
          ,reci.sest_senat_income_code      -- ER 9923702
          ,reci.funrural_income_code        -- ER 9923702
          ,reci.import_other_val_included_icms -- ER 20450226
          ,reci.import_other_val_not_icms      -- ER 20450226
          ,reci.dollar_other_val_included_icms -- ER 20450226
          ,reci.dollar_other_val_not_icms      -- ER 20450226
          ,reci.carrier_document_type          -- ER 20404053
          ,reci.carrier_document_number        -- ER 20404053
          ,reci.carrier_state_id               -- ER 20404053
          ,reci.carrier_ie                     -- ER 20404053
          ,reci.carrier_vehicle_plate_num      -- ER 20404053
          ,reci.usage_authorization            -- ER 20382276
          ,reci.dar_number                     -- ER 20382276
          ,reci.dar_total_amount               -- ER 20382276
          ,reci.dar_payment_date               -- ER 20382276
          ,reci.first_alternative_rate         -- ER 20608903
          ,reci.second_alternative_rate        -- ER 20608903
          ,NVL(srce.soma_source,0)       soma_source
          ,NVL(frtf.soma_freight_flag,0) soma_freight_flag
          ,NVL(gldt.soma_gl_date,0)      soma_gl_date
          ,NVL(orga.soma_org_id,0)       soma_org_id
          ,NVL(loca.soma_location,0)     soma_location
          ,NVL(inty.soma_inv_type,0)     soma_inv_type
          ,reci.icms_fcp_amount                -- 21804594
          ,reci.icms_sharing_dest_amount       -- 21804594
          ,reci.icms_sharing_source_amount     -- 21804594
          ,reci.department_id                  -- 22285738
          ,reci.importation_cide_amount        -- 25341463
          ,reci.dollar_import_cide_amount      -- 25341463
          ,reci.total_fcp_amount               -- 25713076
          ,reci.total_fcp_st_amount            -- 25713076
          ,reci.sest_tax                       -- 25808200 - 25808214
          ,reci.senat_tax                      -- 25808200 - 25808214
          ,reci.sest_amount                    -- 27153706
          ,reci.senat_amount                   -- 27153706
          ,reci.source_city_id                 -- 27463767
          ,reci.destination_city_id            -- 27463767
          ,reci.source_ibge_city_code          -- 27463767
          ,reci.destination_ibge_city_code     -- 27463767
          ,reci.reference                      -- 27579747
          ,reci.ship_to_state_id               -- 28487689 - 28597878
          ,reci.freight_mode                   -- 29330466 - 29338175 - 29385361 - 29480917
          ,reci.fisco_additional_information   -- 29330466 - 29338175 - 29385361 - 29480917
          ,reci.ir_cumulative_base             -- 29448946
          ,reci.iss_mat_third_parties_amount   -- 29635195
          ,reci.iss_subcontract_amount         -- 29635195
          ,reci.iss_exempt_transactions_amount -- 29635195
          ,reci.iss_deduction_amount           -- 29635195
          ,reci.iss_fiscal_observation         -- 29635195
      FROM cll_f189_invoice_iface_tmp   reci
          ,(SELECT COUNT(1) soma_source
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id
              FROM cll_f189_invoice_iface_tmp
          GROUP BY source
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id)      srce
          --
          ,(SELECT COUNT(1) soma_freight_flag
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id
              FROM cll_f189_invoice_iface_tmp
          GROUP BY freight_flag
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id)     frtf
          --
          ,(SELECT COUNT(1) soma_gl_date
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id
              FROM cll_f189_invoice_iface_tmp
          GROUP BY TRUNC(gl_date)
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id)      gldt
          --
          ,(SELECT COUNT(1) soma_org_id
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id
              FROM cll_f189_invoice_iface_tmp
          GROUP BY organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id)      orga
          --
          ,(SELECT COUNT(1) soma_location
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id
              FROM cll_f189_invoice_iface_tmp
          GROUP BY location_id
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id)      loca
          --
          ,(SELECT COUNT(1) soma_inv_type
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id
              FROM cll_f189_invoice_iface_tmp
          GROUP BY invoice_type_id
                  ,organization_id
                  ,ORGANIZATION_CODE -- Bug 19013877
                  ,interface_operation_id)      inty
     WHERE reci.interface_operation_id    = srce.interface_operation_id
       AND (Nvl(reci.organization_id, NULL)    = Nvl(srce.organization_id,NULL) Or
            Nvl(reci.organization_code, NULL)  = Nvl(srce.organization_code,NULL))
      AND reci.interface_operation_id          = frtf.interface_operation_id
       AND (Nvl(reci.organization_id, NULL)    = Nvl(frtf.organization_id, NULL) Or
            Nvl(reci.organization_Code, NULL)  = Nvl(frtf.organization_Code, NULL))
       AND reci.interface_operation_id         = gldt.interface_operation_id
       AND (Nvl(reci.organization_id,NULL)     = Nvl(gldt.organization_id, NULL) Or
            Nvl(reci.organization_Code,NULL)   = Nvl(gldt.organization_Code, NULL))
       AND reci.interface_operation_id         = orga.interface_operation_id
       AND (Nvl(reci.organization_id, NULL)    = Nvl(orga.organization_id, NULL) Or
            Nvl(reci.organization_Code, NULL)  = Nvl(orga.organization_Code, NULL))
       AND reci.interface_operation_id         = loca.interface_operation_id
       AND (Nvl(reci.organization_id, NULL)    = Nvl(loca.organization_id, NULL) Or
            Nvl(reci.organization_Code, NULL)  = Nvl(loca.organization_Code, NULL))
       AND reci.interface_operation_id         = inty.interface_operation_id
       AND (Nvl(reci.organization_id, NULL)    = Nvl(inty.organization_id, NULL) Or
            Nvl(reci.organization_Code, NULL)  = Nvl(inty.organization_Code, NULL))
       -- Fim Bug 19013877
       AND reci.process_flag           = 1
       AND reci.source                 = p_source
       AND reci.interface_invoice_id   = NVL(p_interface_invoice_id, reci.interface_invoice_id);
    --
    l_module_name           CONSTANT VARCHAR2(100) := 'XXFR_F189_OPEN_PROCESSES_PUB.CREATE_OPEN_INTERFACE';

    --
    l_cont_erro             NUMBER := 0;
    l_cont_oper             NUMBER := 0;
    l_cont_oper_org         NUMBER := 0;
    l_cont_oper_loc         NUMBER := 0;
    l_cont_oper_inv_type    NUMBER := 0;
    l_cont_frt_org          NUMBER := 0;
    l_cont_frt_loc          NUMBER := 0;
    l_cont_frt_inv_type     NUMBER := 0;
    --
    l_cont                  NUMBER := 0;
    l_cont_frt              NUMBER := 0;
    l_cont_inv              NUMBER := 0;
    --
    l_organization_id       NUMBER;
    l_operating_unit        NUMBER;
    l_set_of_books_id       NUMBER;
    l_chart_of_accounts_id  NUMBER;
    l_location_id           NUMBER;
    l_error                 VARCHAR2(100) := NULL;
    l_error_code            VARCHAR2(100) := NULL;
    --
    l_invoice_type_id               cll_f189_invoice_types.invoice_type_id%type;
    l_requisition_type              cll_f189_invoice_types.requisition_type%type;
    l_utilities_flag                cll_f189_invoice_types.utilities_flag%type;
    l_payment_flag                  cll_f189_invoice_types.payment_flag%type;
    l_inss_additional_tax_1         cll_f189_invoice_types.inss_additional_tax_1%type;
    l_inss_additional_tax_2         cll_f189_invoice_types.inss_additional_tax_2%type;
    l_inss_additional_tax_3         cll_f189_invoice_types.inss_additional_tax_3%type;
    l_inss_substitute_flag          cll_f189_invoice_types.inss_substitute_flag%type;
    l_inss_tax                      cll_f189_invoice_types.inss_tax%type;
    l_parent_flag                   cll_f189_invoice_types.parent_flag%type;
    l_project_flag                  cll_f189_invoice_types.project_flag%type;
    l_cost_adjust_flag              cll_f189_invoice_types.cost_adjust_flag%type;
    l_price_adjust_flag             cll_f189_invoice_types.price_adjust_flag%type;
    l_tax_adjust_flag               cll_f189_invoice_types.tax_adjust_flag%type;
    l_include_iss_flag              cll_f189_invoice_types.include_iss_flag%type;
    l_pis_flag                      cll_f189_invoice_types.pis_flag%type;
    l_cofins_flag                   cll_f189_invoice_types.cofins_flag%type;
    l_cofins_code_combination_id    cll_f189_invoice_types.cofins_code_combination_id%type;
    l_contab_flag                   cll_f189_invoice_types.contab_flag%type;
    l_inss_calculation_flag         cll_f189_invoice_types.inss_calculation_flag%type;
    l_freight_flag                  cll_f189_invoice_types.freight_flag%type;
    l_fixed_assets_flag             cll_f189_invoice_types.fixed_assets_flag%type;
    l_fiscal_flag                   cll_f189_invoice_types.fiscal_flag%type;
    l_return_customer_flag          cll_f189_invoice_types.return_customer_flag%type; -- Bug 20130095
    l_Invoice_Num                   cll_f189_invoices.invoice_num%type;                -- 29908009
    --
    l_return_code                   VARCHAR2(100);
    l_return_message                VARCHAR2(500);
    --
    l_vendor_id                     NUMBER;
    l_allow_upd_price_flag          cll_f189_parameters.allow_upd_price_flag%type;
    l_rcv_tolerance_perc_amount     cll_f189_parameters.rcv_tolerance_perc_amount%type;
    l_rcv_tolerance_code            cll_f189_parameters.rcv_tolerance_code%type;
    l_pis_amount_recover_cnpj       cll_f189_parameters.pis_amount_recover_cnpj%type;
    l_cofins_amount_recover_cnpj    cll_f189_parameters.cofins_amount_recover_cnpj%type;
    --
    l_return_pkg                    NUMBER;
    l_interface_organization_id     NUMBER;
    l_frt_inter_organization_id     NUMBER; --23018594
    l_exist_rcv                     NUMBER;
    --
    l_user_id                       NUMBER := FND_GLOBAL.USER_ID;
    --
    l_inss_withhold_invoice_id      NUMBER;
    l_iss_withhold_invoice_id       NUMBER;
    l_cumulative_threshold_type     cll_f189_tax_sites.cumulative_threshold_type%type;
    l_minimum_tax_amount            cll_f189_tax_sites.minimum_tax_amount%type;
    l_document_type_out             VARCHAR2(30);
    l_funrural_contributor_flag     cll_f189_business_vendors.funrural_contributor_flag%type;
    l_ir_amount                     NUMBER;
    l_irrf_withhold_invoice_id      NUMBER;
    l_acumula_date                  DATE;
    l_rounding_precision            cll_f189_parameters.rounding_precision%type;
    l_entity_id_out                 NUMBER;
    l_first_payment_date            DATE;
    l_frt_first_payment_date        DATE;  -- 27854379
    l_first_payment_date_dummy      DATE;  -- 27854379
    l_terms_id                      NUMBER;
    l_return_cfo_id                 NUMBER;
    l_entity_parent_id              NUMBER;
    l_source_state_id               NUMBER;
    l_destination_state_id          NUMBER;
    l_source_city_id                NUMBER; -- 28487689 - 28597878
    l_destination_city_id           NUMBER; -- 28487689 - 28597878
    l_ship_to_state_id              NUMBER; -- 28487689 - 28597878
    l_source_ibge_city_code         NUMBER; -- 28730077
    l_destination_ibge_city_code    NUMBER; -- 28730077
    l_inss_additional_amount_1      NUMBER;
    l_inss_additional_amount_2      NUMBER;
    l_inss_additional_amount_3      NUMBER;
    l_city_id                       NUMBER;
    l_vehicle_seller_state_id       NUMBER;
    l_qtd_lines_tmp                 NUMBER;
    l_org_wms                       mtl_parameters.wms_enabled_flag%TYPE;
    l_qtde_nf_compl                 NUMBER;
    --
    l_cfo_id                        NUMBER;       --<<Bug 17375006 - Egini - 01/09/2013 >>--
    --
    l_status                        VARCHAR2(15); --<<Bug 17481870 - Egini - 20/09/2013 >>--
    l_rec_status                    VARCHAR2(15); -- 27579747
    --
    L_LOC_ID NUMBER;
    --
    l_invoice_line_id_par           NUMBER; -- BUG 19943706
    --
    v_cost_adjust_flag              VARCHAR2(1); -- BUG 21918279
    l_found_line                    NUMBER:= 0; -- 22080756
    l_ship_via_lookup_code          fnd_lookup_values_vl.lookup_code%type; -- 2309136
    --
    l_gl_date_diff_from_sysdate     cll_f189_parameters.gl_date_diff_from_sysdate%type;
    l_gl_date                       cll_f189_entry_operations.gl_date%type;
    l_rec_date_diff_from_sysdate    cll_f189_parameters.receive_date_diff_from_sysdate%type; -- 29559606
    l_receive_date                  cll_f189_entry_operations.receive_date%type;             -- 29559606
    --
    v_loop                          NUMBER; -- Bug 24717031
    --
    -- Begin Bug 24387238
    l_parent_id_out                 NUMBER;
    l_parent_line_id_out            NUMBER;
    l_inv_line_parent_id_out        NUMBER;
    l_line_location_id              NUMBER;
    l_requisition_line_id           NUMBER;
    l_item_id                       NUMBER;
    l_interface_parent_id           NUMBER;
    l_interface_parent_line_id      NUMBER;
    l_invoice_parent_line_id        NUMBER;
    l_interface_invoice_line_id     NUMBER;
    l_type_exec                     VARCHAR2(1);
    -- End Bug 24387238
    --
    l_debit_free                    cll_f189_fiscal_operations.debit_free%TYPE;       -- 27579747
    l_tpa_control_type              cll_f189_fiscal_operations.tpa_control_type%TYPE; -- 27579747
    l_iss_city_id                   NUMBER; -- 25591653
    
    l_cfop_return_id                NUMBER; -- 31001507

  BEGIN
    print_log('  CREATE_OPEN_INTERFACE');
    -- Inicio BUG 19722064
    print_log('  Inicio do loop (r_valida_invoice_header)');
    FOR r_valida_invoice_header IN c_valida_invoice_header LOOP
      ---------------------------
      -- Validando Organizacao --
      ---------------------------
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
      print_log('l_debit_free:'||l_debit_free);
      print_log('  Chamando CLL_F189_OPEN_VALIDATE_PUB.GET_ORGANIZATION_ID...');
      CLL_F189_OPEN_VALIDATE_PUB.GET_ORGANIZATION_ID (
        p_organization_code    => r_valida_invoice_header.organization_code
        ,p_organization_id_in   => r_valida_invoice_header.organization_id
        --out
        ,p_organization_id_out  => l_organization_id
        ,p_operating_unit       => l_operating_unit
        ,p_set_of_books_id      => l_set_of_books_id
        ,p_chart_of_accounts_id => l_chart_of_accounts_id
        ,p_error_code           => l_error
      );
      print_log('chart_of_accounts_id:'||l_chart_of_accounts_id);
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --1;
      ---------------------
      -- Validando Local --
      ---------------------
      BEGIN
        SELECT location_id
        INTO l_location_id
        FROM hr_locations
        WHERE (location_id = r_valida_invoice_header.location_id OR location_code = r_valida_invoice_header.location_code);
      EXCEPTION WHEN NO_DATA_FOUND THEN
        l_location_id := NULL;
      END;
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --2;
      ----------------------------
      -- Validando Invoice Type --
      ---------------------------
      print_log('  Chamando CLL_F189_OPEN_VALIDATE_PUB.GET_INVOICE_TYPE_ID...');
      CLL_F189_OPEN_VALIDATE_PUB.GET_INVOICE_TYPE_ID (
        p_invoice_type_id     => r_valida_invoice_header.invoice_type_id
        ,p_invoice_type_code   => r_valida_invoice_header.invoice_type_code
        ,p_organization_id     => r_valida_invoice_header.organization_id
        ,p_organization_code   => r_valida_invoice_header.organization_code
        --out
        ,p_invoice_type_id_out  => l_invoice_type_id
        ,p_error_code           => l_error
      );
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --3;
      --
      IF  r_valida_invoice_header.organization_id IS NULL AND r_valida_invoice_header.organization_code IS NOT NULL THEN
        --
        UPDATE cll_f189_invoice_iface_tmp
        SET organization_id  = l_organization_id
        WHERE interface_invoice_id = p_interface_invoice_id
        AND organization_code    = r_valida_invoice_header.organization_code;
        --
      END IF;
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
      IF  r_valida_invoice_header.location_id IS NULL AND r_valida_invoice_header.location_code IS NOT NULL THEN
        --
        UPDATE cll_f189_invoice_iface_tmp
        SET location_id  = l_location_id
        WHERE interface_invoice_id = p_interface_invoice_id
        AND location_code    = r_valida_invoice_header.location_code;
        --
      END IF;
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
      IF  r_valida_invoice_header.invoice_type_id IS NULL AND r_valida_invoice_header.invoice_type_code IS NOT NULL THEN
        --
        UPDATE cll_f189_invoice_iface_tmp
        SET invoice_type_id      = l_invoice_type_id
        WHERE interface_invoice_id = p_interface_invoice_id
        AND invoice_type_code    = r_valida_invoice_header.invoice_type_code;
        --
      END IF;
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --4;
      --
      COMMIT;
      --
    END LOOP;
    -- Fim BUG 19722064
    print_log('  Fim do loop (r_valida_invoice_header)');
    print_log('');
    --
    g_source              := p_source;
    g_aprova              := p_approve;
    g_generate_line_compl := p_generate_line_compl;
    --
    -- Iniciando validacoes do Header
    --
    print_log('  Inicio do loop (r_invoice_header)');
    FOR r_invoice_header IN c_invoice_header LOOP
      --
      IF r_invoice_header.organization_id IS NULL AND r_invoice_header.organization_code IS NULL THEN
        --
        -- ** (ID e CODE) nao estao informados na tabela temporaria ** --
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        print_log('p_open_source:'||p_open_source);
        IF p_open_source = 'RI' THEN
          ADD_ERROR(
            p_invoice_id              => r_invoice_header.interface_invoice_id
            ,p_interface_operation_id => r_invoice_header.interface_operation_id
            ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
            ,p_error_code             => 'NONE ORGANIZATION'
            ,p_invoice_line_id        => 0
            ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
            ,p_invalid_value          => NULL
          );
          --
          g_process_flag  := 3; -- In interface hold
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          --
        END IF; --IF p_open_source = 'RI' THEN
        --
        l_cont_oper_org := 1;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --5;
      --
      ELSIF r_invoice_header.organization_id IS NOT NULL AND r_invoice_header.organization_code IS NOT NULL THEN
        --
        -- ** (ID e CODE) estao informados na tabela temporaria ** --
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        IF l_organization_id IS NOT NULL THEN  -- ORGANIZATION_ID da Open esta valido, entao popula a variavel
          l_organization_id := r_invoice_header.organization_id;
        ELSE
          IF l_error = 'NO_DATA_FOUND' THEN
            l_error_code := 'NONE ORGANIZATION ID';
          ELSIF l_error = 'TOO_MANY_ROWS' THEN
            l_error_code := 'DUPLICATED ORG ID';
          ELSIF l_error = 'OTHERS' THEN
            l_error_code := 'INVALID ORGANIZATION';
          END IF;
          --
          IF p_open_source = 'RI' THEN
            ADD_ERROR(
              p_invoice_id             => r_invoice_header.interface_invoice_id
              ,p_interface_operation_id => r_invoice_header.interface_operation_id
              ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_error_code             => l_error_code
              ,p_invoice_line_id        => 0
              ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => 'ID = '||r_invoice_header.organization_id||' CODE = '||r_invoice_header.organization_code
            );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --6;
            --
            g_process_flag  := 3; -- In interface hold
            --
          END IF; --IF p_open_source = 'RI' THEN
          l_cont_oper_org := 1;
          --
        END IF;
        --
      ELSIF r_invoice_header.organization_id IS NULL AND r_invoice_header.organization_code IS NOT NULL THEN
        --
        -- ** (CODE) esta informado (ID) esta nulo na tabela temporaria ** --
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        IF l_organization_id IS NOT NULL THEN  -- Encontrou ID para o codigo, entao popula na tabela temporaria
          UPDATE cll_f189_invoice_iface_tmp
          SET organization_id      = l_organization_id
          WHERE interface_invoice_id = p_interface_invoice_id
          AND organization_code    = r_invoice_header.organization_code;
        --
        ELSE
          IF l_error = 'NO_DATA_FOUND' THEN
           l_error_code := 'NONE ORGANIZATION ID';
          ELSIF l_error = 'TOO_MANY_ROWS' THEN
           l_error_code := 'DUPLICATED ORG ID';
          ELSIF l_error = 'OTHERS' THEN
           l_error_code := 'INVALID ORGANIZATION';
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --219;
          IF p_open_source = 'RI' THEN
            ADD_ERROR(
              p_invoice_id              => r_invoice_header.interface_invoice_id
              ,p_interface_operation_id => r_invoice_header.interface_operation_id
              ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_error_code             => l_error_code
              ,p_invoice_line_id        => 0
              ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => 'CODE = '||r_invoice_header.organization_code
            );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --7;
            --
            g_process_flag  := 3; -- In interface hold
            --
          END IF; --IF p_open_source = 'RI' THEN
          l_cont_oper_org := 1;
          --
        END IF;
        --
      ELSIF r_invoice_header.organization_id IS NOT NULL AND r_invoice_header.organization_code IS NULL THEN
        --
        -- ** (ID) esta informado (CODE) esta nulo na tabela temporaria ** --
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        IF l_organization_id IS NULL THEN -- Se encontrou setup para o ID, a variavel vai estar populada, senao, da o erro
          IF l_error = 'NO_DATA_FOUND' THEN
            l_error_code := 'NONE ORGANIZATION ID';
          ELSIF l_error = 'TOO_MANY_ROWS' THEN
            l_error_code := 'DUPLICATED ORG ID';
          ELSIF l_error = 'OTHERS' THEN
            l_error_code := 'INVALID ORGANIZATION';
          END IF;
          --
          IF p_open_source = 'RI' THEN
            ADD_ERROR(
              p_invoice_id             => r_invoice_header.interface_invoice_id
              ,p_interface_operation_id => r_invoice_header.interface_operation_id
              ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_error_code             => l_error_code
              ,p_invoice_line_id        => 0
              ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => 'ID = '||r_invoice_header.organization_id
            );
            --
            g_process_flag  := 3; -- In interface hold
          --
          END IF; --IF p_open_source = 'RI' THEN
          l_cont_oper_org := 1;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --8;
          --
        END IF;
      ELSIF r_invoice_header.location_id IS NULL AND r_invoice_header.location_code IS NULL THEN
        --
        -- ** (ID e CODE) nao estao informados na tabela temporaria ** --
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        IF p_open_source = 'RI' THEN
          ADD_ERROR(
            p_invoice_id             => r_invoice_header.interface_invoice_id
            ,p_interface_operation_id => r_invoice_header.interface_operation_id
            ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
            ,p_error_code             => 'NONE LOCATION'
            ,p_invoice_line_id        => 0
            ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
            ,p_invalid_value          => NULL
          );
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          g_process_flag  := 3; -- In interface hold
        END IF; --IF p_open_source = 'RI' THEN
        l_cont_oper_loc := 1;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --9;
        --
        --
      ELSIF r_invoice_header.location_id IS NOT NULL AND r_invoice_header.location_code IS NOT NULL THEN
        --
        -- ** (ID e CODE) estao informados na tabela temporaria ** --
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        IF l_location_id IS NOT NULL THEN  -- LOCATION_ID da Open esta valido, entao popula a variavel
          l_location_id := r_invoice_header.location_id;
        ELSE
          IF l_error = 'NO_DATA_FOUND' THEN
            l_error_code := 'NONE LOCATION ID';
          ELSIF l_error = 'TOO_MANY_ROWS' THEN
            l_error_code := 'DUPLICATED LOCATION ID';
          ELSIF l_error = 'OTHERS' THEN
            l_error_code := 'INVALID LOCATION';
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --219;
          IF p_open_source = 'RI' THEN
            ADD_ERROR(
              p_invoice_id             => r_invoice_header.interface_invoice_id
              ,p_interface_operation_id => r_invoice_header.interface_operation_id
              ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_error_code             => l_error_code
              ,p_invoice_line_id        => 0
              ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => 'ID = '||r_invoice_header.location_id||' CODE = '||r_invoice_header.location_code
            );
            --
            g_process_flag  := 3; -- In interface hold
          END IF; --IF p_open_source = 'RI' THEN
          l_cont_oper_loc:= 1;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --10;
          --
        END IF;
        --
      ELSIF r_invoice_header.location_id IS NULL AND r_invoice_header.location_code IS NOT NULL THEN
        --
        -- ** (CODE) esta informado (ID) esta nulo na tabela temporaria ** --
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        IF l_location_id IS NOT NULL THEN  -- Encontrou ID para o codigo, entao popula na tabela temporaria
          --
          UPDATE cll_f189_invoice_iface_tmp
          SET location_id          = l_location_id
          WHERE interface_invoice_id = p_interface_invoice_id
          AND location_code        = r_invoice_header.location_code;
          --
        ELSE
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          IF l_error = 'NO_DATA_FOUND' THEN
            l_error_code := 'NONE ORGANIZATION ID';
          ELSIF l_error = 'TOO_MANY_ROWS' THEN
            l_error_code := 'DUPLICATED ORG ID';
          ELSIF l_error = 'OTHERS' THEN
            l_error_code := 'INVALID ORGANIZATION';
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --219;
          IF p_open_source = 'RI' THEN
            ADD_ERROR(
              p_invoice_id             => r_invoice_header.interface_invoice_id
              ,p_interface_operation_id => r_invoice_header.interface_operation_id
              ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_error_code             => l_error_code
              ,p_invoice_line_id        => 0
              ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => 'CODE = '||r_invoice_header.location_code
            );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
            g_process_flag  := 3; -- In interface hold
          END IF; --IF p_open_source = 'RI' THEN
          l_cont_oper_loc := 1;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --11;
        END IF;
        --
      ELSIF r_invoice_header.location_id IS NOT NULL AND r_invoice_header.location_code IS NULL THEN
        --
        -- ** (ID) esta informado (CODE) esta nulo na tabela temporaria ** --
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        IF l_location_id IS NULL THEN -- Se encontrou setup para o ID, a variavel vai estar populada, senao, da o erro
          IF l_error = 'NO_DATA_FOUND' THEN
            l_error_code := 'NONE ORGANIZATION ID';
          ELSIF l_error = 'TOO_MANY_ROWS' THEN
            l_error_code := 'DUPLICATED ORG ID';
          ELSIF l_error = 'OTHERS' THEN
            l_error_code := 'INVALID ORGANIZATION';
          END IF;
          --
          IF p_open_source = 'RI' THEN
            ADD_ERROR(
              p_invoice_id             => r_invoice_header.interface_invoice_id
              ,p_interface_operation_id => r_invoice_header.interface_operation_id
              ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_error_code             => l_error_code
              ,p_invoice_line_id        => 0
              ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => 'ID = '||r_invoice_header.location_id
            );
            g_process_flag  := 3; -- In interface hold
          END IF; --IF p_open_source = 'RI' THEN
          l_cont_oper_loc := 1;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --12;
        END IF;
      END IF; -- validacoes iniciais - ORGANIZATION e LOCATION
      --
      -- Se encontrou erro, atualiza o status registro na Open e vai para o proximo registro do cursor, senao, deriva o tipo de nota
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
      IF l_cont_oper_loc > 0 OR l_cont_oper_org > 0 THEN
        l_cont_erro := l_cont_erro + 1;
        l_cont_oper := l_cont_oper + 1;
        --
        -- Atualiza o status do registro para retencao
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        IF p_open_source = 'RI' THEN
          SET_PROCESS_FLAG(
            p_process_flag         => g_process_flag
            ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
          );
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --13;
        END IF; --IF p_open_source = 'RI' THEN
      ELSE 
        -- Organizacao e Local derivados com sucesso, entao deriva o tipo de nota
        ----------------------------
        -- Validando Tipo de Nota --
        ----------------------------
        --
        l_error      := NULL;
        l_error_code := NULL;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        CLL_F189_OPEN_VALIDATE_PUB.GET_INVOICE_TYPE_DATA (
          p_invoice_type_id             => r_invoice_header.invoice_type_id
          ,p_invoice_type_code          => r_invoice_header.invoice_type_code
          ,p_organization_id            => NVL(l_organization_id,r_invoice_header.organization_id)
          -- out
          ,p_invoice_type_id_out        => l_invoice_type_id
          ,p_requisition_type           => l_requisition_type
          ,p_utilities_flag             => l_utilities_flag
          ,p_payment_flag               => l_payment_flag
          ,p_inss_additional_tax_1      => l_inss_additional_tax_1
          ,p_inss_additional_tax_2      => l_inss_additional_tax_2
          ,p_inss_additional_tax_3      => l_inss_additional_tax_3
          ,p_inss_substitute_flag       => l_inss_substitute_flag
          ,p_inss_tax                   => l_inss_tax
          ,p_parent_flag                => l_parent_flag
          ,p_project_flag               => l_project_flag
          ,p_cost_adjust_flag           => l_cost_adjust_flag
          ,p_price_adjust_flag          => l_price_adjust_flag
          ,p_tax_adjust_flag            => l_tax_adjust_flag
          ,p_include_iss_flag           => l_include_iss_flag
          ,p_pis_flag                   => l_pis_flag
          ,p_cofins_flag                => l_cofins_flag
          ,p_cofins_code_combination_id => l_cofins_code_combination_id
          ,p_contab_flag                => l_contab_flag
          ,p_inss_calculation_flag      => l_inss_calculation_flag
          ,p_freight_flag               => l_freight_flag
          ,p_fixed_assets_flag          => l_fixed_assets_flag
          ,p_fiscal_flag                => l_fiscal_flag
          ,p_return_customer_flag       => l_return_customer_flag -- Bug 20130095
          ,p_error_code                 => l_error
        );
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --14;
        --
        IF r_invoice_header.invoice_type_id IS NULL AND r_invoice_header.invoice_type_code IS NULL THEN
          --
          -- ** (ID e CODE) nao estao informados na tabela temporaria ** --
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          IF p_open_source = 'RI' THEN
            ADD_ERROR(
              p_invoice_id             => r_invoice_header.interface_invoice_id
              ,p_interface_operation_id => r_invoice_header.interface_operation_id
              ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_error_code             => 'NULL INVTYPE'
              ,p_invoice_line_id        => 0
              ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => NULL
            );
            --
            g_process_flag       := 3; -- In interface hold
          END IF; --IF p_open_source = 'RI' THEN
          l_cont_oper_inv_type := 1;
          --
        ELSIF r_invoice_header.invoice_type_id IS NOT NULL AND r_invoice_header.invoice_type_code IS NOT NULL THEN
          --
          -- ** (ID e CODE) estao informados na tabela temporaria ** --
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          IF l_invoice_type_id IS NOT NULL THEN  -- INVOICE_TYPE_ID da Open esta valido, entao popula a variavel
            l_invoice_type_id := r_invoice_header.invoice_type_id;
          ELSE
            IF l_error = 'NO_DATA_FOUND' THEN
              l_error_code := 'NONE INVOICE TYPE';
            ELSIF l_error = 'TOO_MANY_ROWS' THEN
              l_error_code := 'MORE THAN INV TIP';
            ELSIF l_error = 'OTHERS' THEN
              l_error_code := 'INVALID INVTYPE';
            END IF;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
            IF p_open_source = 'RI' THEN
              ADD_ERROR(
                p_invoice_id             => r_invoice_header.interface_invoice_id
                ,p_interface_operation_id => r_invoice_header.interface_operation_id
                ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                ,p_error_code             => l_error_code
                ,p_invoice_line_id        => 0
                ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => 'ID = '||r_invoice_header.invoice_type_id||' CODE = '||r_invoice_header.invoice_type_code
              );
              g_process_flag       := 3; -- In interface hold
            END IF; --IF p_open_source = 'RI' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
            l_cont_oper_inv_type := 1;
            --
          END IF;
        --
        ELSIF r_invoice_header.invoice_type_id IS NULL AND r_invoice_header.invoice_type_code IS NOT NULL THEN
          --
          -- ** (CODE) esta informado (ID) esta nulo na tabela temporaria ** --
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          IF l_invoice_type_id IS NOT NULL THEN  -- Encontrou ID para o codigo, entao popula na tabela temporaria
            UPDATE cll_f189_invoice_iface_tmp
            SET invoice_type_id      = l_invoice_type_id
            WHERE interface_invoice_id = p_interface_invoice_id
            AND invoice_type_code    = r_invoice_header.invoice_type_code;
            --
          ELSE
            IF l_error = 'NO_DATA_FOUND' THEN
              l_error_code := 'NONE INVOICE TYPE';
            ELSIF l_error = 'TOO_MANY_ROWS' THEN
              l_error_code := 'MORE THAN INV TIP';
            ELSIF l_error = 'OTHERS' THEN
              l_error_code := 'INVALID INVTYPE';
            END IF;
            --
            IF p_open_source = 'RI' THEN
              ADD_ERROR(
                p_invoice_id             => r_invoice_header.interface_invoice_id
                ,p_interface_operation_id => r_invoice_header.interface_operation_id
                ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                ,p_error_code             => l_error_code
                ,p_invoice_line_id        => 0
                ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => 'CODE = '||r_invoice_header.invoice_type_code
              );
              g_process_flag       := 3; -- In interface hold
            END IF; --IF p_open_source = 'RI' THEN
            l_cont_oper_inv_type := 1;
          --
          END IF;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          --
        ELSIF r_invoice_header.invoice_type_id IS NOT NULL AND r_invoice_header.invoice_type_code IS NULL THEN
          --
          -- ** (ID) esta informado (CODE) esta nulo na tabela temporaria ** --
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          IF l_invoice_type_id IS NULL THEN -- Se encontrou setup para o ID, a variavel vai estar populada, senao, da o erro
            IF l_error = 'NO_DATA_FOUND' THEN
              l_error_code := 'NONE INVOICE TYPE';
            ELSIF l_error = 'TOO_MANY_ROWS' THEN
              l_error_code := 'MORE THAN INV TIP';
            ELSIF l_error = 'OTHERS' THEN
              l_error_code := 'INVALID INVTYPE';
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
            IF p_open_source = 'RI' THEN
              ADD_ERROR(
                p_invoice_id             => r_invoice_header.interface_invoice_id
                ,p_interface_operation_id => r_invoice_header.interface_operation_id
                ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                ,p_error_code             => l_error_code
                ,p_invoice_line_id        => 0
                ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => 'ID = '||r_invoice_header.invoice_type_id
              );
              g_process_flag       := 3; -- In interface hold
            ELSIF p_open_source = 'LOADER' THEN
              NULL;
            END IF; --IF p_open_source = 'RI' THEN
            l_cont_oper_inv_type := 1;
            --
          END IF;
        END IF; -- validacoes iniciais - INVOICE_TYPE
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        --
        -- Bug 20130095 - Start
        -- Open Interface nao contempla nota de devolucao

        -- 29908009 - Start
        /*IF l_return_customer_flag = 'F' THEN
           ADD_ERROR(p_invoice_id             => r_invoice_header.interface_invoice_id
                    ,p_interface_operation_id => r_invoice_header.interface_operation_id
                    ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                    ,p_error_code             => 'INV REC TYPE'
                    ,p_invoice_line_id        => 0
                    ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                    ,p_invalid_value          => NULL
                    );
        END IF;*/
        -- 29908009 - End

        -- Bug 20130095 - End
        --
        -- Se o tipo de nota informado foi derivado com sucesso, continua o processamento, senao vai para o proximo registro
        --
        IF l_cont_oper_inv_type > 0 THEN
          --
          IF p_open_source = 'RI' THEN
            SET_PROCESS_FLAG(
              p_process_flag         => g_process_flag
              ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
            );
          END IF; --IF p_open_source = 'RI' THEN
          --
        ELSE -- Tipo de nota derivado com sucesso, dando inicio as derivacoes do header
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          l_cont  := l_cont + 1; -- conta os registros processados para exibir no log do concurrent
          --
          mo_global.set_policy_context('S',NULL);
          mo_global.set_policy_context('S',l_operating_unit);
          --
          print_log('-----------------------------------------------------------------------------------');
          CREATE_OPEN_HEADER (
            p_open_source                   => 'RI'
            ,p_interface_invoice_id          => r_invoice_header.interface_invoice_id
            ,p_interface_operation_id        => r_invoice_header.interface_operation_id
            ,p_organization_id               => NVL(l_organization_id,r_invoice_header.organization_id)
            ,p_location_id                   => NVL(l_location_id,r_invoice_header.location_id)
            ,p_operating_unit                => l_operating_unit
            ,p_source                        => r_invoice_header.source
            ,p_gl_date                       => r_invoice_header.gl_date
            ,p_receive_date                  => r_invoice_header.receive_date
            ,p_invoice_type_id               => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id)
            ,p_entity_id                     => r_invoice_header.entity_id
            ,p_document_type                 => r_invoice_header.document_type
            ,p_document_number               => r_invoice_header.document_number
            ,p_ie                            => r_invoice_header.ie
            ,p_inss_additional_base_1        => r_invoice_header.inss_additional_base_1
            ,p_inss_additional_base_2        => r_invoice_header.inss_additional_base_2
            ,p_inss_additional_base_3        => r_invoice_header.inss_additional_base_3
            ,p_inss_tax                      => r_invoice_header.inss_tax
            ,p_inss_additional_tax_1         => r_invoice_header.inss_additional_tax_1
            ,p_inss_additional_tax_2         => r_invoice_header.inss_additional_tax_2
            ,p_inss_additional_tax_3         => r_invoice_header.inss_additional_tax_3
            ,p_inss_substitute_flag          => l_inss_substitute_flag
            ,p_inss_additional_amount_1      => r_invoice_header.inss_additional_amount_1
            ,p_inss_additional_amount_2      => r_invoice_header.inss_additional_amount_2
            ,p_inss_additional_amount_3      => r_invoice_header.inss_additional_amount_3
            ,p_soma_source                   => r_invoice_header.soma_source
            ,p_soma_freight_flag             => r_invoice_header.soma_freight_flag
            ,p_soma_gl_date                  => r_invoice_header.soma_gl_date
            ,p_soma_org_id                   => r_invoice_header.soma_org_id
            ,p_soma_location                 => r_invoice_header.soma_location
            ,p_soma_inv_type                 => r_invoice_header.soma_inv_type
            ,p_invoice_num                   => r_invoice_header.invoice_num
            ,p_invoice_amount                => r_invoice_header.invoice_amount
            ,p_utilities_flag                => l_utilities_flag
            ,p_gross_total_amount            => r_invoice_header.gross_total_amount
            ,p_invoice_date                  => r_invoice_header.invoice_date
            ,p_simplified_br_tax_flag        => r_invoice_header.simplified_br_tax_flag
            ,p_icms_base                     => r_invoice_header.icms_base
            ,p_icms_amount                   => r_invoice_header.icms_amount
            ,p_max_icms_amount_recover       => r_invoice_header.max_icms_amount_recover
            ,p_icms_tax_rec_simpl_br         => r_invoice_header.icms_tax_rec_simpl_br
            ,p_icms_type                     => r_invoice_header.icms_type
            ,p_icms_st_amount                => r_invoice_header.icms_st_amount
            ,p_ipi_amount                    => r_invoice_header.ipi_amount
            ,p_set_of_books_id               => l_set_of_books_id
            ,p_payment_flag                  => l_payment_flag
            ,p_freight_flag                  => r_invoice_header.freight_flag --l_freight_flag
            ,p_total_freight_weight          => r_invoice_header.total_freight_weight
            ,p_requisition_type              => l_requisition_type
            ,p_series                        => r_invoice_header.series
            ,p_subseries                     => r_invoice_header.subseries
            ,p_fiscal_document_model         => r_invoice_header.fiscal_document_model
            ,p_eletronic_invoice_key         => r_invoice_header.eletronic_invoice_key
            ,p_cte_type                      => r_invoice_header.cte_type
            ,p_invoice_parent_id             => r_invoice_header.invoice_parent_id
            ,p_parent_flag                   => l_parent_flag
            ,p_cost_adjust_flag              => l_cost_adjust_flag
            ,p_price_adjust_flag             => l_price_adjust_flag
            ,p_tax_adjust_flag               => l_tax_adjust_flag
            ,p_fixed_assets_flag             => l_fixed_assets_flag
            ,p_cofins_flag                   => l_cofins_flag
            ,p_cofins_code_combination_id    => l_cofins_code_combination_id
            ,p_include_iss_flag              => l_include_iss_flag
            ,p_iss_city_id                   => r_invoice_header.iss_city_id
            ,p_iss_city_code                 => r_invoice_header.iss_city_code
            ,p_iss_base                      => r_invoice_header.iss_base
            ,p_iss_amount                    => r_invoice_header.iss_amount
            ,p_source_state_id               => r_invoice_header.source_state_id
            ,p_source_state_code             => r_invoice_header.source_state_code
            ,p_destination_state_id          => r_invoice_header.destination_state_id
            ,p_destination_state_code        => r_invoice_header.destination_state_code
            ,p_terms_id                      => r_invoice_header.terms_id
            ,p_terms_name                    => r_invoice_header.terms_name
            ,p_first_payment_date            => r_invoice_header.first_payment_date
            ,p_terms_date                    => r_invoice_header.terms_date
            ,p_additional_tax                => r_invoice_header.additional_tax
            ,p_additional_amount             => r_invoice_header.additional_amount
            ,p_return_cfo_id                 => r_invoice_header.return_cfo_id
            ,p_return_cfo_code               => r_invoice_header.return_cfo_code
            ,p_return_amount                 => r_invoice_header.return_amount
            ,p_source_items                  => r_invoice_header.source_items
            ,p_contract_id                   => r_invoice_header.contract_id
            ,p_importation_number            => r_invoice_header.importation_number
            ,p_total_fob_amount              => r_invoice_header.total_fob_amount
            ,p_freight_international         => r_invoice_header.freight_international
            ,p_importation_insurance_amount  => r_invoice_header.importation_insurance_amount
            ,p_importation_tax_amount        => r_invoice_header.importation_tax_amount
            ,p_importation_expense_func      => r_invoice_header.importation_expense_func
            ,p_customs_expense_func          => r_invoice_header.customs_expense_func
            ,p_total_cif_amount              => r_invoice_header.total_cif_amount
            ,p_inss_base                     => r_invoice_header.inss_base
            ,p_inss_calculation_flag         => l_inss_calculation_flag
            ,p_inss_amount                   => r_invoice_header.inss_amount
            ,p_inss_subcontract_amount       => r_invoice_header.inss_subcontract_amount
            ,p_inss_autonomous_tax           => r_invoice_header.inss_autonomous_tax
            ,p_inss_autonomous_amount        => r_invoice_header.inss_autonomous_amount
            ,p_inss_autonomous_inv_total     => r_invoice_header.inss_autonomous_invoiced_total
            ,p_ir_vendor                     => r_invoice_header.ir_vendor
            ,p_ir_base                       => r_invoice_header.ir_base
            ,p_ir_amount                     => r_invoice_header.ir_amount
            ,p_ir_tax                        => r_invoice_header.ir_tax
            ,p_ir_categ                      => r_invoice_header.ir_categ
            ,p_vehicle_seller_state_id       => r_invoice_header.vehicle_seller_state_id
            ,p_vehicle_seller_state_code     => r_invoice_header.vehicle_seller_state_code
            ,p_import_document_type          => r_invoice_header.import_document_type
            ,p_process_origin                => r_invoice_header.process_origin
            ,p_social_security_contrib_tax   => r_invoice_header.social_security_contrib_tax -- ER 17551029
            ,p_gilrat_tax                    => r_invoice_header.gilrat_tax                  -- ER 17551029
            ,p_senar_tax                     => r_invoice_header.senar_tax                   -- ER 17551029
            ,p_worker_category_id            => r_invoice_header.worker_category_id          -- ER 17551029 4a Fase
            ,p_category_code                 => r_invoice_header.category_code               -- ER 17551029 4a Fase
            ,p_cbo_code                      => r_invoice_header.cbo_code                    -- ER 17551029 4a Fase
            ,p_material_equipment_amount     => r_invoice_header.material_equipment_amount   -- ER 17551029 4a Fase
            ,p_deduction_amount              => r_invoice_header.deduction_amount            -- ER 17551029 4a Fase
            ,p_cno_id                        => r_invoice_header.cno_id                      -- 24325307
            ,p_cno_number                    => r_invoice_header.cno_number                  -- ER 17551029 4a Fase
            ,p_caepf_number                  => r_invoice_header.caepf_number                -- ER 17551029 4a Fase
            ,p_indicator_multiple_links      => r_invoice_header.indicator_multiple_links    -- ER 17551029 4a Fase
            ,p_inss_service_amount_1         => r_invoice_header.inss_service_amount_1       -- ER 17551029 4a Fase
            ,p_inss_service_amount_2         => r_invoice_header.inss_service_amount_2       -- ER 17551029 4a Fase
            ,p_inss_service_amount_3         => r_invoice_header.inss_service_amount_3       -- ER 17551029 4a Fase
            ,p_remuneration_freight_amount   => r_invoice_header.remuneration_freight_amount -- ER 17551029 4a Fase
            ,p_other_expenses                => r_invoice_header.other_expenses              -- 21091872
            ,p_insurance_amount              => r_invoice_header.insurance_amount            -- 21091872
            ,p_freight_amount                => r_invoice_header.freight_amount              -- 21091872
            ,p_lp_inss_initial_base_amount   => r_invoice_header.lp_inss_initial_base_amount --  21924115
            ,p_lp_inss_base_amount           => r_invoice_header.lp_inss_base_amount         --  21924115
            ,p_lp_inss_rate                  => r_invoice_header.lp_inss_rate                --  21924115
            ,p_lp_inss_amount                => r_invoice_header.lp_inss_amount              --  21924115
            ,p_lp_inss_net_amount            => r_invoice_header.lp_inss_net_amount          --  21924115
            ,p_ip_inss_initial_base_amount   => r_invoice_header.ip_inss_initial_base_amount --  21924115
            ,p_ip_inss_base_amount           => r_invoice_header.ip_inss_base_amount         --  21924115
            ,p_ip_inss_rate                  => r_invoice_header.ip_inss_rate                --  21924115
            ,p_ip_inss_net_amount            => r_invoice_header.ip_inss_net_amount          --  21924115
            ,p_source_city_id                => r_invoice_header.source_city_id              -- 28487689 - 28597878
            ,p_source_ibge_city_code         => r_invoice_header.source_ibge_city_code       -- 28487689 - 28597878
            ,p_destination_city_id           => r_invoice_header.destination_city_id         -- 28487689 - 28597878
            ,p_destination_ibge_city_code    => r_invoice_header.destination_ibge_city_code  -- 28487689 - 28597878
            ,p_ship_to_state_id              => r_invoice_header.ship_to_state_id            -- 28487689 - 28597878
            ,p_return_customer_flag          => l_return_customer_flag                       -- 29908009
            -- out
            ,p_process_flag                  => g_process_flag
            ,p_vendor_id                     => l_vendor_id
            ,p_allow_upd_price_flag          => l_allow_upd_price_flag
            ,p_rcv_tolerance_perc_amount     => l_rcv_tolerance_perc_amount
            ,p_rcv_tolerance_code            => l_rcv_tolerance_code
            ,p_pis_amount_recover_cnpj       => l_pis_amount_recover_cnpj
            ,p_cofins_amount_recover_cnpj    => l_cofins_amount_recover_cnpj
            ,p_cumulative_threshold_type     => l_cumulative_threshold_type
            ,p_minimum_tax_amount            => l_minimum_tax_amount
            ,p_document_type_out             => l_document_type_out
            ,p_funrural_contributor_flag     => l_funrural_contributor_flag
            ,p_rounding_precision            => l_rounding_precision
            ,p_entity_id_out                 => l_entity_id_out
            ,p_first_payment_date_out        => l_first_payment_date
            ,p_terms_id_out                  => l_terms_id
            ,p_return_cfo_id_out             => l_return_cfo_id
            ,p_source_state_id_out           => l_source_state_id
            ,p_destination_state_id_out      => l_destination_state_id
            ,p_source_city_id_out            => l_source_city_id             -- 28487689 - 28597878
            ,p_destination_city_id_out       => l_destination_city_id        -- 28487689 - 28597878
            ,p_ship_to_state_id_out          => l_ship_to_state_id           -- 28487689 - 28597878
            ,p_source_ibge_city_out          => l_source_ibge_city_code      -- 28730077
            ,p_destination_ibge_city_out     => l_destination_ibge_city_code -- 28730077
            ,p_inss_additional_amount_1_out  => l_inss_additional_amount_1
            ,p_inss_additional_amount_2_out  => l_inss_additional_amount_2
            ,p_inss_additional_amount_3_out  => l_inss_additional_amount_3
            ,p_city_id                       => l_city_id
            ,p_vehicle_seller_state_id_out   => l_vehicle_seller_state_id
            ,p_qtd_lines_tmp                 => l_qtd_lines_tmp
            ,p_qtde_nf_compl                 => l_qtde_nf_compl -- Bug 16600918
            ,p_return_code                   => l_return_code
            ,p_return_message                => l_return_message
          );
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
          print_log('-----------------------------------------------------------------------------------');
          -- 28730077 begin
          BEGIN
            UPDATE cll_f189_invoices_interface rii
            SET rii.source_city_id             = l_source_city_id
            , rii.source_state_id            = l_source_state_id
            , rii.destination_city_id        = l_destination_city_id
            , rii.destination_state_id       = l_destination_state_id
            , rii.ship_to_state_id           = l_ship_to_state_id
            , rii.source_ibge_city_code      = l_source_ibge_city_code      -- 28730077
            , rii.destination_ibge_city_code = l_destination_ibge_city_code -- 28730077
            WHERE rii.interface_invoice_id = r_invoice_header.interface_invoice_id;
          END;
          -- 28730077 end
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --100;
          IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao do header
            IF p_open_source = 'RI' THEN
              SET_PROCESS_FLAG(
                p_process_flag         => g_process_flag
                ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
              );
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --101;
            END IF; --IF p_open_source = 'RI' THEN
          ELSE
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --102;
            --Chama as validacoes das linhas
            print_log('-----------------------------------------------------------------------------------');
            CREATE_OPEN_LINES (
              p_type                         => 'VALIDATION'
              ,p_interface_invoice_id         => r_invoice_header.interface_invoice_id
              ,p_interface_operation_id       => r_invoice_header.interface_operation_id
              ,p_organization_id              => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_location_id                  => NVL(l_location_id,r_invoice_header.location_id)
              ,p_operating_unit               => l_operating_unit
              ,p_vendor_id                    => l_vendor_id
              ,p_entity_id                    => r_invoice_header.entity_id
              ,p_invoice_type_id              => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id)
              ,p_price_adjust_flag            => l_price_adjust_flag
              ,p_cost_adjust_flag             => l_cost_adjust_flag
              ,p_tax_adjust_flag              => l_tax_adjust_flag
              ,p_fixed_assets_flag            => l_fixed_assets_flag
              ,p_parent_flag                  => l_parent_flag
              ,p_contab_flag                  => l_contab_flag
              ,p_payment_flag                 => l_payment_flag
              ,p_freight_flag                 => r_invoice_header.freight_flag
              ,p_freight_flag_inv_type        => l_freight_flag
              ,p_project_flag                 => l_project_flag
              ,p_chart_of_accounts_id         => l_chart_of_accounts_id
              ,p_additional_tax               => r_invoice_header.additional_tax
              ,p_allow_upd_price_flag         => l_allow_upd_price_flag
              ,p_source_items                 => r_invoice_header.source_items
              ,p_user_defined_conversion_rate => r_invoice_header.user_defined_conversion_rate
              ,p_rcv_tolerance_perc_amount    => l_rcv_tolerance_perc_amount
              ,p_rcv_tolerance_code           => l_rcv_tolerance_code
              ,p_source_state_id              => r_invoice_header.source_state_id
              ,p_destination_state_id         => r_invoice_header.destination_state_id
              ,p_source_state_code            => r_invoice_header.source_state_code      -- Bug 17442462
              ,p_destination_state_code       => r_invoice_header.destination_state_code -- Bug 17442462
              ,p_gl_date                      => r_invoice_header.gl_date
              ,p_receive_date                 => r_invoice_header.receive_date
              ,p_qtde_nf_compl                => l_qtde_nf_compl -- Bug 16600918
              ,p_requisition_type             => l_requisition_type --<<Bug 17481870 - Egini - 20/09/2013 >>--
              ,p_invoice_date                 => r_invoice_header.invoice_date -- 22012023
              -- OUT
              ,p_invoice_line_id_par          => l_invoice_line_id_par -- BUG 19943706
              ,p_process_flag                 => g_process_flag
              ,p_return_code                  => l_return_code
              ,p_return_message               => l_return_message
              -- Begin Bug 24387238
              ,p_line_location_id             => l_line_location_id
              ,p_requisition_line_id          => l_requisition_line_id
              ,p_item_id                      => l_item_id
              -- End Bug 24387238
            );
            print_log('-----------------------------------------------------------------------------------');
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --178;
            IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao das linhas
              IF p_open_source = 'RI' THEN
                SET_PROCESS_FLAG(
                  p_process_flag          => g_process_flag
                  ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                );
              END IF; --IF p_open_source = 'RI' THEN
              --
            ELSE
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --179;
              -- 23018594 - Start
              IF (
                g_freight_inter_operation_id <> r_invoice_header.interface_operation_id OR
                l_frt_inter_organization_id <> r_invoice_header.organization_id OR
                g_freight_inter_operation_id IS NULL
              ) THEN
                --
                g_freight_inter_operation_id := r_invoice_header.interface_operation_id;
                l_frt_inter_organization_id  := r_invoice_header.organization_id;
                -- 23018594 - End
                -- Inicio BUG 23018594
                DECLARE
                  -- Inicio BUG 23018594
                  -- Buscar informacao de Origem e Destino do Frete, pois nao temos esses valores nesse momento
                  CURSOR c_freight IS
                  SELECT source_state_id, source_state_code, destination_state_id, destination_state_code
                  FROM cll_f189_freight_inv_interface
                  WHERE interface_operation_id = g_freight_inter_operation_id
                  AND organization_id        = l_frt_inter_organization_id;
                  --
                  v_source_state_id               cll_f189_freight_inv_interface.source_state_id%type;        -- 23018594
                  v_destination_state_id          cll_f189_freight_inv_interface.destination_state_id%type;   -- 23018594
                  --
                BEGIN
                  print_log('  Inicio do loop(r_freight');
                  FOR r_freight in c_freight LOOP
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --180;
                    v_source_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => r_freight.source_state_id
                                                                         ,p_state_code => r_freight.source_state_code
                                                                          );
                    v_destination_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => r_freight.destination_state_id
                                                                              ,p_state_code => r_freight.destination_state_code
                                                                               );
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --181;
                    -- Fim  BUG 23018594
                    --Chama as validacoes do Frete
                    CREATE_OPEN_FREIGHT (
                      p_type                       => 'VALIDATION'
                      ,p_interface_operation_id     => r_invoice_header.interface_operation_id
                      ,p_location_id                => NVL(l_location_id,r_invoice_header.location_id)
                      ,p_operating_unit             => l_operating_unit
                      ,p_gl_date                    => r_invoice_header.gl_date
                      ,p_set_of_books_id            => l_set_of_books_id
                      ,p_fiscal_flag                => l_fiscal_flag
                      ,p_source_state_id            => v_source_state_id      --r_invoice_header.source_state_id -- BUG 23018594
                      ,p_destination_state_id       => v_destination_state_id --r_invoice_header.destination_state_id -- BUG 23018594
                      ,p_pis_amount_recover_cnpj    => l_pis_amount_recover_cnpj
                      ,p_cofins_amount_recover_cnpj => l_cofins_amount_recover_cnpj
                      ,p_first_payment_date         => NULL                     -- 27854379
                      ,p_first_payment_date_out     => l_frt_first_payment_date -- 27854379
                      ,p_process_flag               => g_process_flag
                      ,p_cll_f189_entry_operations_s=> g_cll_f189_entry_operations_s
                      ,p_return_code                => l_return_code
                      ,p_return_message             => l_return_message
                    );
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --182;
                END LOOP; -- BUG 23018594
                print_log('  Fim do loop(r_freight');
                END; -- BUG 23018594
              END IF; -- 23018594
              --
              IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao do frete
              IF p_open_source = 'RI' THEN
              SET_PROCESS_FLAG(p_process_flag         => g_process_flag
                      ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                      );
              END IF; --IF p_open_source = 'RI' THEN
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --183;
              ELSE
              --
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --184;
              l_type_exec := p_type_exec; -- Bug 24387238
              --
              print_log('---------------------------------------------------------------------------------');
              CREATE_OPEN_INV_PARENTS (
                p_type                    => 'VALIDATION'
                ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                ,p_interface_operation_id => r_invoice_header.interface_operation_id
                ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                ,p_invoice_line_id_par    => l_invoice_line_id_par -- BUG 19943706
                ,p_process_flag           => g_process_flag
                ,p_return_code            => l_return_code
                ,p_return_message         => l_return_message
                ,p_invoice_type_id        => r_invoice_header.invoice_type_id -- Bug 17088635
                -- Begin Bug 24387238
                ,p_generate_line          => 'N'
                ,p_invoice_line_id        => l_invoice_line_id_par
                ,p_parent_id_out          => l_parent_id_out
                ,p_interface_parent_id    => l_interface_parent_id
                ,p_invoice_parent_line_id => l_invoice_parent_line_id
                ,p_parent_line_id_out     => l_parent_line_id_out
                ,p_inv_line_parent_id_out => l_inv_line_parent_id_out
                ,p_total                  => r_invoice_header.invoice_amount
                ,p_icms                   => r_invoice_header.icms_amount
                ,p_ipi                    => r_invoice_header.ipi_amount
                ,p_business_vendor        => l_vendor_id
                ,p_org_state_id           => NVL(r_invoice_header.destination_state_id,l_destination_state_id)
                ,p_vendor_state_id        => NVL(r_invoice_header.source_state_id,l_source_state_id)
                ,p_additional_tax         => r_invoice_header.additional_tax
                ,p_user_id                => l_user_id
                ,p_interface              => 'Y' -- 22080756
                ,p_line_location_id       => l_line_location_id
                ,p_requisition_line_id    => l_requisition_line_id
                ,p_item_id                => l_item_id
                ,p_type_exec              => l_type_exec
                -- End Bug 24387238
                ,p_return_customer_flag   => l_return_customer_flag -- 29908009
              );
              print_log('---------------------------------------------------------------------------------');
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --186;
              -- LINHA DA NOTA COMPLEMENTAR E FEITA DENTRO DA CHAMADA DA NOTA COMPLEMENTAR
              --
              IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao da nota complementar
                IF p_open_source = 'RI' THEN
                  SET_PROCESS_FLAG(
                    p_process_flag         => g_process_flag
                    ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                  );
                END IF; --IF p_open_source = 'RI' THEN
              ELSE
                CREATE_LEGAL_PROCESSES (
                  p_type                   => 'VALIDATION'
                  ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                  ,p_interface_operation_id => r_invoice_header.interface_operation_id
                  ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                  ,p_invoice_id             => NULL
                );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --187;
                --
                IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao do processo legal
                  IF p_open_source = 'RI' THEN
                    SET_PROCESS_FLAG(
                      p_process_flag         => g_process_flag
                      ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                    );
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --188;
                  END IF; --IF p_open_source = 'RI' THEN
                ELSE
                  --
                  CREATE_OUTBOUND_INVOICES (
                    p_type                   => 'VALIDATION'
                    ,p_insert                 => 'N' -- 22346186
                    ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                    ,p_interface_operation_id => r_invoice_header.interface_operation_id
                    ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                    ,p_invoice_id             => NULL
                  );
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --189;
                  --
                  IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao das notas de saida
                    IF p_open_source = 'RI' THEN
                      SET_PROCESS_FLAG(
                        p_process_flag         => g_process_flag
                        ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                      );
                      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --190;
                    END IF; --IF p_open_source = 'RI' THEN
                    -- ER 17551029 4a Fase - Start
                  ELSE
                    --
                    CREATE_PRIOR_BILLINGS (
                      p_type                   => 'VALIDATION'
                      ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                      ,p_interface_operation_id => r_invoice_header.interface_operation_id
                      ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                      ,p_invoice_id             => NULL
                     );
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --191;
                    --
                    IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao de prior billings
                      IF p_open_source = 'RI' THEN
                        SET_PROCESS_FLAG(
                          p_process_flag         => g_process_flag
                          ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                        );
                      END IF; --IF p_open_source = 'RI' THEN
                      -- 28592012 - Start
                    ELSE
                      --
                      CREATE_PAYMENT_METHODS (
                        p_type                   => 'VALIDATION'
                        ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                        ,p_interface_operation_id => r_invoice_header.interface_operation_id
                        ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                        ,p_invoice_id             => NULL
                      );
                      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --192;
                      --
                      IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao de payment_methods
                        IF p_open_source = 'RI' THEN
                          SET_PROCESS_FLAG(
                            p_process_flag         => g_process_flag
                            ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                          );
                        END IF; --IF p_open_source = 'RI' THEN
                        -- 29330466 - 29338175 - 29385361 - 29480917 - Start
                      ELSE
                        --
                        CREATE_REFERENCED_DOCUMENTS (
                          p_type                   => 'VALIDATION'
                          ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                          ,p_interface_operation_id => r_invoice_header.interface_operation_id
                          ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                          ,p_invoice_id             => NULL
                        );
                        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --193;
                        --
                        IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao de referenced_documents
                          IF p_open_source = 'RI' THEN
                            SET_PROCESS_FLAG(p_process_flag         => g_process_flag
                              ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                            );
                          END IF; --IF p_open_source = 'RI' THEN
                        END IF; --IF g_process_flag IS NOT NULL THEN  -- encontrou erro na derivacao de referenced_documents
                        -- 29330466 - 29338175 - 29385361 - 29480917 - End
                      END IF; --IF g_process_flag IS NOT NULL THEN  -- encontrou erro na derivacao de payment methods
                      -- 28592012 - End
                    END IF; --IF g_process_flag IS NOT NULL THEN  -- encontrou erro na derivacao de prior billings
                    -- 28592012 - End
                  END IF; --IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao das notas de saida
                END IF; --IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao do processo legal
              END IF; --IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao da nota complementar
              END IF; --IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao do frete
            END IF; --IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao das linhas
          END IF; --IF g_process_flag IS NOT NULL THEN -- encontrou erro na derivacao do header
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        END IF; --IF l_cont_oper_inv_type > 0 THEN
      END IF; --IF l_cont_oper_loc > 0 OR l_cont_oper_org > 0 THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --192;
      --
      BEGIN
        print_log('Passou por todas as validacoes, verifica se tem retencao, chamando a check_holds, para mudar o status para retencao ou aprovado');
        -- Passou por todas as validacoes, verifica se tem retencao, chamando a check_holds, para mudar o status para retencao ou aprovado
        -- VALIDAR SE EXISTE LINHA DA NOTA INSERIDA E SE O PARAMETRO PARA GERACAO AUTOMATICA E Y, PORQUE NAO INSERIU AS LINHAS AINDA (GERA
        -- A RETENCAO DE NONE INVOICE LINE) EXISTENTE NA CHECK_HOLDS
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --193;
        IF  NVL(l_qtd_lines_tmp,0) > 0 THEN
          --
          print_log('Chamando CLL_F189_CHECK_HOLDS_PKG.FUNC_CHECK_HOLDS..');
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --194;
          begin
            l_return_pkg := CLL_F189_CHECK_HOLDS_PKG.FUNC_CHECK_HOLDS (
              p_organization_id       => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_location_id          => NVL(l_location_id,r_invoice_header.location_id)
              ,p_operation_id         => r_invoice_header.interface_operation_id
              ,p_freight_flag         => r_invoice_header.freight_flag
              ,p_total_freight_weight => r_invoice_header.total_freight_weight
              ,p_interface            => 'Y'
              ,p_interface_invoice_id => p_interface_invoice_id
            );
          exception 
            when others then 
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --194;
              print_log('    ERRO:'||sqlerrm);
          end;
          print_log('    Retorno:'||l_return_pkg);
          IF NVL(l_return_pkg,0) > 0 THEN
            g_process_flag := 4;
          END IF;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --194;
        END IF; --IF NVL(g_generate_line_compl,'N') = 'N' AND NVL(l_qtd_lines_tmp,0) > 0 THEN
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
        BEGIN
          SELECT COUNT(1)
          INTO l_return_pkg
          FROM cll_f189_interface_errors
          WHERE interface_operation_id = r_invoice_header.interface_operation_id
          AND organization_id        = NVL(l_organization_id,r_invoice_header.organization_id);
        EXCEPTION
          WHEN OTHERS THEN
            l_return_pkg := 0;
        END;
        --
        IF l_return_pkg > 0 THEN
          g_process_flag := 3;
        END IF;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --195;
        --
        IF g_process_flag IS NOT NULL THEN -- encontrou erro na verificacao da check_holds
          --
          l_cont_erro := l_cont_erro + 1;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --195;
          IF p_open_source = 'RI' THEN
            SET_PROCESS_FLAG(
              p_process_flag         => g_process_flag
              ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
            );
          END IF; --IF p_open_source = 'RI' THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --196;
        ELSE
          --
          -- Recuperar o proximo valor da entry_operations e iniciar os inserts nas tabelas core
          --
          g_process_flag := 5;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --197;
          --
          IF g_interface_operation_id    <> r_invoice_header.interface_operation_id OR -- Bug 18043475
             l_interface_organization_id <> r_invoice_header.organization_id OR
             g_interface_operation_id    IS NULL THEN -- Bug 18043475
             --
             g_interface_operation_id    := r_invoice_header.interface_operation_id; -- Bug 18043475
             l_interface_organization_id := r_invoice_header.organization_id;
             l_cont_oper := l_cont_oper + 1;
             --
             g_cll_f189_entry_operations_s := CLL_F189_ENTRY_OPERATIONS_PUB.GET_ENTRY_OPERATION_S(p_organization_id => NVL(l_organization_id,r_invoice_header.organization_id));
             --
             IF l_requisition_type <> 'NA' THEN
               LOOP
                 l_exist_rcv := 0;
                 --
                 l_org_wms := CLL_F189_OPEN_VALIDATE_PUB.GET_MTL_PARAMETERS(p_organization_id => NVL(l_organization_id,r_invoice_header.organization_id));
                 --
                 IF NVL(l_org_wms,'N') = 'N' THEN
                   l_exist_rcv := CLL_F189_OPEN_VALIDATE_PUB.GET_RCV_SHIPMENT_REC(p_entry_operations => g_cll_f189_entry_operations_s
                                                                                 ,p_organization_id  => NVL(l_organization_id,r_invoice_header.organization_id)
                                                                                  );
                 ELSE
                   l_exist_rcv := CLL_F189_OPEN_VALIDATE_PUB.GET_RCV_SHIPMENT_SHIP(p_entry_operations => g_cll_f189_entry_operations_s
                                                                                  ,p_organization_id  => NVL(l_organization_id,r_invoice_header.organization_id)
                                                                                  );
                 END IF ;
                 --
                 IF l_exist_rcv <> 0 THEN
                   CLL_F189_OPEN_VALIDATE_PUB.SET_NEXT_NUMBER (p_organization_id => NVL(l_organization_id,r_invoice_header.organization_id));
                   --
                   COMMIT;
                   --
                   g_cll_f189_entry_operations_s := CLL_F189_ENTRY_OPERATIONS_PUB.GET_ENTRY_OPERATION_S(p_organization_id => NVL(l_organization_id,r_invoice_header.organization_id));
                 ELSE
                   EXIT;
                 END IF;
               END LOOP;
             END IF; -- IF l_requisition_type <> 'NA' THEN
             --
             CLL_F189_OPEN_VALIDATE_PUB.SET_NEXT_NUMBER (p_organization_id => r_invoice_header.organization_id);
             --
             COMMIT;
             --
             l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --198;
             --
             -- 24622578 - Start
             BEGIN
                SELECT NVL(gl_date_diff_from_sysdate,'N')
                INTO l_gl_date_diff_from_sysdate
                FROM cll_f189_parameters
                WHERE organization_id = NVL(l_organization_id,r_invoice_header.organization_id);
             EXCEPTION
               WHEN others THEN
                  l_gl_date_diff_from_sysdate := 'N';
             END;

             IF l_gl_date_diff_from_sysdate = 'R' THEN
                l_gl_date := trunc(SYSDATE);
             ELSE
                l_gl_date := r_invoice_header.gl_date;
             END IF;
             -- 24622578 - End
             --
             -- 29559606 - Start
             BEGIN
                SELECT NVL(receive_date_diff_from_sysdate,'N')
                INTO l_rec_date_diff_from_sysdate
                FROM cll_f189_parameters
                WHERE organization_id = NVL(l_organization_id,r_invoice_header.organization_id);
             EXCEPTION
               WHEN others THEN
                  l_rec_date_diff_from_sysdate := 'N';
             END;

             IF l_rec_date_diff_from_sysdate = 'R' THEN
                l_receive_date := trunc(SYSDATE);
             ELSE
                l_receive_date := r_invoice_header.receive_date;
             END IF;
             -- 29559606 - End
             -------------------------------------------------
             -- Inserindo na tabela final: ENTRY_OPERATIONS --
             -------------------------------------------------

             -- 27579747 - Start
             --
             --<<Bug 17481870 - Egini - 20/09/2013 Inicio >>--
             /*IF g_aprova = 'Y' AND l_requisition_type <> 'NA' THEN
                l_status := 'APPROVED';
             ELSE
                l_status := 'INCOMPLETE';
             END IF;*/
             --<<Bug 17481870 - Egini - 20/09/2013 Fim >>--
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --198;
            BEGIN
              --select * from cll_f189_fiscal_operations where cfo_id='3909'
              SELECT 
                NVL(rfo.debit_free,'N'), rfo.tpa_control_type --,ril.cfo_id, ril.cfo_code
              INTO l_debit_free, l_tpa_control_type
              FROM 
                cll_f189_invoice_lines_iface ril
                , cll_f189_fiscal_operations rfo
              WHERE 1=1
                and ril.interface_invoice_id =  r_invoice_header.interface_invoice_id
                AND (ril.cfo_code = rfo.cfo_code OR ril.cfo_id = rfo.cfo_id)
                AND ROWNUM = 1;
            EXCEPTION
              WHEN OTHERS THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --219;
                print_log('Erro :'||sqlerrm);
                l_debit_free       := NULL;
                l_tpa_control_type := NULL;
            END;
            print_log('l_debit_free      :'||l_debit_free);
            print_log('g_aprova          :'||g_aprova);
            print_log('l_requisition_type:'||l_requisition_type);
            print_log('l_tpa_control_type:'||l_tpa_control_type);
            IF (g_aprova = 'Y' AND l_requisition_type <> 'NA') THEN
              -- 28806961_27831745 - Start
              -- A partir desta solucao este trecho sera comentado para atender a aprovacao automatica de loader com pedido.
              /*
              IF p_source = 'CLL_F369 EFD LOADER SHIPPER'
              OR p_source = 'CLL_F369 EFD LOADER' THEN
              l_status := 'INCOMPLETE';
              ELSE
              */
              -- 28806961_27831745 - End
              l_status := 'APPROVED';
              --              END IF; -- 28806961_27831745
            ELSIF g_aprova = 'Y' AND l_requisition_type = 'NA' THEN
              -- 28806961_27831745 - Start
              -- A partir desta solucao este trecho sera comentado para atender a aprovacao automatica de loader sem pedido.
              /*
              IF p_source = 'CLL_F369 EFD LOADER SHIPPER'
              OR p_source = 'CLL_F369 EFD LOADER'
              */
              -- 28806961_27831745 - End
              -- 30485011 - Inicio
              IF p_source = 'CLL_F369 EFD LOADER SHIPPER' OR p_source = 'CLL_F369 EFD LOADER' THEN
                l_status := 'IN PROCESS';
              -- 30485011 - Fim
              ELSIF l_debit_free = 'Y' OR l_tpa_control_type IS NOT NULL THEN
                l_status := 'INCOMPLETE';
              ELSE
                l_status := 'COMPLETE';
              END IF;
            ELSE
              l_status := 'INCOMPLETE';
            END IF;
            --
            -- 27579747 - End
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --199;
            print_log('Chamando CLL_F189_ENTRY_OPERATIONS_PUB.CREATE_ENTRY_OPERATIONS...');
            CLL_F189_ENTRY_OPERATIONS_PUB.CREATE_ENTRY_OPERATIONS(
              p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
              ,p_location_id            => NVL(l_location_id,r_invoice_header.location_id)
              ,p_operation_id           => g_cll_f189_entry_operations_s
              ,p_user_id                => l_user_id
              --,p_receive_date           => r_invoice_header.receive_date -- 29559606
              ,p_receive_date           => l_receive_date                -- 29559606
              --,p_gl_date                => r_invoice_header.gl_date
              ,p_gl_date                => l_gl_date
              ,p_total_freight_weight   => r_invoice_header.total_freight_weight
              ,p_source                 => r_invoice_header.source
              ,p_freight_flag           => r_invoice_header.freight_flag
              ,p_status                 => l_status          --<<Bug 17481870 - Egini - 20/09/2013 >>--
              ,p_item_factor            => NULL
              ,p_translation_factor     => NULL
              ,p_icms_transl_factor     => NULL
              ,p_ipi_transl_factor      => NULL
              ,p_ii_transl_factor       => NULL
              ,p_freight_transl_factor  => NULL
              ,p_posted_flag            => 'N'
              ,p_reversion_flag         => NULL
              ,p_attribute_category     => r_invoice_header.ceo_attribute_category
              ,p_attribute1             => r_invoice_header.ceo_attribute1
              ,p_attribute2             => r_invoice_header.ceo_attribute2
              ,p_attribute3             => r_invoice_header.ceo_attribute3
              ,p_attribute4             => r_invoice_header.ceo_attribute4
              ,p_attribute5             => r_invoice_header.ceo_attribute5
              ,p_attribute6             => r_invoice_header.ceo_attribute6
              ,p_attribute7             => r_invoice_header.ceo_attribute7
              ,p_attribute8             => r_invoice_header.ceo_attribute8
              ,p_attribute9             => r_invoice_header.ceo_attribute9
              ,p_attribute10            => r_invoice_header.ceo_attribute10
              ,p_attribute11            => r_invoice_header.ceo_attribute11
              ,p_attribute12            => r_invoice_header.ceo_attribute12
              ,p_attribute13            => r_invoice_header.ceo_attribute13
              ,p_attribute14            => r_invoice_header.ceo_attribute14
              ,p_attribute15            => r_invoice_header.ceo_attribute15
              ,p_attribute16            => r_invoice_header.ceo_attribute16
              ,p_attribute17            => r_invoice_header.ceo_attribute17
              ,p_attribute18            => r_invoice_header.ceo_attribute18
              ,p_attribute19            => r_invoice_header.ceo_attribute19
              ,p_attribute20            => r_invoice_header.ceo_attribute20
              ,p_return_code            => l_return_code
              ,p_return_message         => l_return_message
            );
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --200;
            --
            -------------------------------------------------
            -- Inserindo na tabela final: FREIGHT INVOICES --
            -------------------------------------------------
            --
            -- Inicio BUG 23018594
            -- Buscar informacao de Origem e Destino do Frete, pois nao temos esses valores nesse momento
            DECLARE
              CURSOR c1_freight IS
              SELECT source_state_id, source_state_code, destination_state_id, destination_state_code
              FROM cll_f189_freight_inv_interface
              WHERE interface_operation_id = r_invoice_header.interface_operation_id
              AND organization_id        = r_invoice_header.organization_id
              ;
              v_source_state_id       cll_f189_freight_inv_interface.source_state_id%TYPE;
              v_destination_state_id  cll_f189_freight_inv_interface.destination_state_id%TYPE;
            BEGIN
              FOR r1_freight IN c1_freight LOOP
                v_source_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (
                  p_state_id   => r1_freight.source_state_id
                  ,p_state_code => r1_freight.source_state_code
                );
                v_destination_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (
                  p_state_id   => r1_freight.destination_state_id
                  ,p_state_code => r1_freight.destination_state_code);
                CREATE_OPEN_FREIGHT (
                  p_type                       => 'INSERT'
                  ,p_interface_operation_id     => r_invoice_header.interface_operation_id
                  ,p_location_id                => NVL(l_location_id,r_invoice_header.location_id)
                  ,p_operating_unit             => l_operating_unit
                  ,p_gl_date                    => r_invoice_header.gl_date
                  ,p_set_of_books_id            => l_set_of_books_id
                  ,p_fiscal_flag                => l_fiscal_flag
                  ,p_source_state_id            => v_source_state_id       -- BUG 23018594
                  ,p_destination_state_id       => v_destination_state_id  -- BUG 23018594
                  ,p_pis_amount_recover_cnpj    => l_pis_amount_recover_cnpj
                  ,p_cofins_amount_recover_cnpj => l_cofins_amount_recover_cnpj
                  ,p_cll_f189_entry_operations_s=> g_cll_f189_entry_operations_s
                  ,p_first_payment_date         => l_frt_first_payment_date   -- 27854379
                  -- out
                  ,p_first_payment_date_out     => l_first_payment_date_dummy -- 27854379
                  ,p_process_flag               => g_process_flag
                  ,p_return_code                => l_return_code
                  ,p_return_message             => l_return_message
                );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --201;
              END LOOP;
            END;
          END IF; --IF l_interface_operation_id    <> r_invoice_header.interface_operation_id OR
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --202;
          --
          l_cont_inv := l_cont_inv + 1;
          --
          g_cll_f189_invoices_s := CLL_F189_INVOICES_PUB.GET_INVOICES_S;
          --
          -- INSS
          --
          IF NVL(l_inss_calculation_flag,'N') = 'Y' THEN
              IF NVL(r_invoice_header.INSS_AMOUNT,0) <> 0 OR NVL(r_invoice_header.INSS_AUTONOMOUS_AMOUNT,0) <> 0 THEN
                  l_inss_withhold_invoice_id := g_cll_f189_invoices_s;
              ELSE
                  l_inss_withhold_invoice_id := NULL;
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --203;
          --
          -- ISS
          --
          IF NVL(r_invoice_header.iss_amount,0) <> 0 THEN
              l_iss_withhold_invoice_id := g_cll_f189_invoices_s;
          ELSE
              l_iss_withhold_invoice_id := NULL;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --204;
          --
          IF l_cumulative_threshold_type <> 0 THEN
              IF NVL(l_funrural_contributor_flag,'N') <> 'N' then
                  l_document_type_out := 'CPF';
              END IF;
              --
              IF (l_document_type_out NOT IN ('CPF','RG')) THEN
                  IF (r_invoice_header.ir_vendor  IN ('1', '2')) THEN
                      l_ir_amount                := 0;
                      l_irrf_withhold_invoice_id := g_cll_f189_invoices_s;
                      l_acumula_date             := NULL;
                      --
                      IF (l_cumulative_threshold_type = 1) OR (l_cumulative_threshold_type = 5) THEN
                          l_acumula_date := l_first_payment_date;
                      ELSIF (l_cumulative_threshold_type = 2) OR (l_cumulative_threshold_type = 6) THEN
                          l_acumula_date := r_invoice_header.gl_date;
                      ELSIF (l_cumulative_threshold_type = 7) THEN
                          l_acumula_date := r_invoice_header.receive_date;
                      END IF;
                      --
                      BASE_ACCUMULATE_IRRF(p_accumulate_type          => l_cumulative_threshold_type
                                          ,p_minimun_value            => l_minimum_tax_amount
                                          ,p_invoice_id               => g_cll_f189_invoices_s
                                          ,p_entity_id                => NVL(r_invoice_header.entity_id,l_entity_id_out)
                                          ,p_organization_id          => r_invoice_header.organization_id
                                          ,p_location_id              => r_invoice_header.location_id
                                          ,p_ir_base                  => r_invoice_header.ir_base
                                          ,p_ir_tax                   => r_invoice_header.ir_tax
                                          ,p_ir_amount                => l_ir_amount
                                          ,p_irrf_withhold_invoice_id => l_irrf_withhold_invoice_id
                                          ,p_accumulate_date          => l_acumula_date
                                          );
                      --
                      l_rounding_precision := NVL(l_rounding_precision, 2);
                      --
                      IF (      NVL(r_invoice_header.ir_amount,0)                       =       NVL(l_ir_amount,0) OR
                          ROUND(NVL(r_invoice_header.ir_amount,0),l_rounding_precision) = ROUND(NVL(l_ir_amount,0),l_rounding_precision) OR
                          TRUNC(NVL(r_invoice_header.ir_amount,0),l_rounding_precision) = TRUNC(NVL(l_ir_amount,0),l_rounding_precision) ) AND
                         (NVL(l_ir_amount,0) > 0) THEN
                          --
                          UPDATE_IRRF_WITHHOLD_INVOICE (p_accumulate_type     => l_cumulative_threshold_type
                                                       ,p_minimun_value       => l_minimum_tax_amount
                                                       ,p_invoice_id          => g_cll_f189_invoices_s
                                                       ,p_entity_id           => NVL(r_invoice_header.entity_id,l_entity_id_out)
                                                       ,p_organization_id     => r_invoice_header.organization_id
                                                       ,p_location_id         => r_invoice_header.location_id
                                                       ,p_accumulate_date     => l_acumula_date);
                          --
                      ELSIF (NVL(l_ir_amount,0) > 0) THEN
                          CLL_F189_FREIGHT_INVOICES_PUB.DELETE_FREIGHT_INVOICES(p_organization_id => r_invoice_header.organization_id
                                                                               ,p_operation_id    => g_cll_f189_entry_operations_s
                                                                               ,p_return_code     => l_return_code
                                                                               ,p_return_message  => l_return_message
                                                                               );
                          --
                          CLL_F189_ENTRY_OPERATIONS_PUB.DELETE_ENTRY_OPERATION(p_organization_id => r_invoice_header.organization_id
                                                                              ,p_operation_id    => g_cll_f189_entry_operations_s
                                                                              ,p_return_code     => l_return_code
                                                                              ,p_return_message  => l_return_message
                                                                              );
                          --
                          l_irrf_withhold_invoice_id := NULL;

                          --
                          ADD_ERROR(p_invoice_id             => r_invoice_header.interface_invoice_id
                                   ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                   ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                                   ,p_error_code             => 'INCORRECT IRRF AMOUNT'
                                   ,p_invoice_line_id        => 0
                                   ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                   ,p_invalid_value          => NULL
                                   );
                          --
                          -- Bug 17865884 - Start
                          g_process_flag := 3; -- In interface hold
                          --
                          -- Atualiza o status do registro para retencao
                          IF p_open_source = 'RI' THEN
                              SET_PROCESS_FLAG(p_process_flag         => g_process_flag
                                              ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                                              );
                          END IF; --IF p_open_source = 'RI' THEN
                          --
                          l_cont_erro := l_cont_erro + 1;
                          --
                          -- Bug 17865884 - End
                      ELSIF (NVL(l_ir_amount,0) = 0) AND -- 0
                            (NVL(r_invoice_header.ir_amount,0) > 0) THEN -- 15
                          CLL_F189_FREIGHT_INVOICES_PUB.DELETE_FREIGHT_INVOICES(p_organization_id => r_invoice_header.organization_id
                                                                               ,p_operation_id    => g_cll_f189_entry_operations_s
                                                                               ,p_return_code     => l_return_code
                                                                               ,p_return_message  => l_return_message
                                                                               );
                          --
                          CLL_F189_ENTRY_OPERATIONS_PUB.DELETE_ENTRY_OPERATION(p_organization_id => r_invoice_header.organization_id
                                                                              ,p_operation_id    => g_cll_f189_entry_operations_s
                                                                              ,p_return_code     => l_return_code
                                                                              ,p_return_message  => l_return_message
                                                                              );
                          --
                          ADD_ERROR(p_invoice_id             => r_invoice_header.interface_invoice_id
                                   ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                   ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                                   ,p_error_code             => 'INCORRECT IRRF AMOUNT'
                                   ,p_invoice_line_id        => 0
                                   ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                   ,p_invalid_value          => NULL
                                   );
                          --
                          -- Bug 17865884 - Start
                          g_process_flag := 3; -- In interface hold
                          --
                          -- Atualiza o status do registro para retencao
                          --
                          IF p_open_source = 'RI' THEN
                              SET_PROCESS_FLAG(p_process_flag         => g_process_flag
                                              ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
                                              );
                               NULL;
                          END IF; --IF p_open_source = 'RI' THEN
                          --
                          l_cont_erro := l_cont_erro + 1;
                          --
                          -- Bug 17865884 - End
                      END IF; --IF (      NVL(r_invoice_header.ir_amount,0)                       =       NVL(l_ir_amount,0) OR
                  END IF;   --IF (r_invoice_header.ir_vendor  IN ('1', '2')) THEN
              END IF;  --IF (l_document_type_out NOT IN ('CPF','RG')) THEN
              --
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --205;
          ELSIF (r_invoice_header.ir_amount > 0) THEN --IF l_cumulative_threshold_type <> 0 THEN
              --
              l_irrf_withhold_invoice_id :=  g_cll_f189_invoices_s;
              --
          END IF; --IF l_cumulative_threshold_type <> 0 THEN
          --
          -- Bug 17865884 - Start
          IF g_process_flag = 3 THEN -- Encontrou erro na acumulacao do imposto
             NULL;
          ELSE
            -- Bug 17865884 - End
            --
            -- COMO O CURSOR PRINCIPAL DO PROCESSAMENTO DA OPEN ACONTECE NA TABELA DE HEADER, ESSE INSERT FICA AQUI E NAO NA PROCEDURE CREATE_OPEN_HEADER
            --
            -- 23091360 - Start
            IF p_source = 'CLL_F369 EFD LOADER' OR
               p_source = 'CLL_F369 EFD LOADER SHIPPER' THEN -- 27579747
               l_ship_via_lookup_code := CLL_F189_LOADER_ADJUST_PKG.adjust_ship_via(r_invoice_header.ship_via_lookup_code);
            ELSE
               l_ship_via_lookup_code := r_invoice_header.ship_via_lookup_code;
            END IF;
            -- 23091360 - End
  
            -- 29908009 - Start
            IF l_return_customer_flag = 'F' THEN
  
               l_Invoice_Num := CLL_F189_VENDOR_RETURN_PKG.Adjust_Invoice_Num (p_organization_id => NVL(r_invoice_header.organization_id,l_organization_id)
                                                                              ,p_operation_id    => g_cll_f189_entry_operations_s
                                                                              ,p_invoice_type_id => NVL(r_invoice_header.invoice_type_id,l_invoice_type_id)
                                                                              ,p_entity_id       => NVL(r_invoice_header.entity_id,l_entity_id_out)
                                                                              ,p_invoice_num     => r_invoice_header.invoice_num);
  
            ELSE
  
               l_Invoice_Num := r_invoice_header.invoice_num;
  
            END IF;
            -- 29908009 - End
            print_log('Chamando CLL_F189_INVOICES_PUB.CREATE_INVOICES...');
            print_log('invoice_parent_id :'||r_invoice_header.invoice_parent_id);
            CLL_F189_INVOICES_PUB.CREATE_INVOICES (
              p_invoices_id                    => g_cll_f189_invoices_s
              ,p_entity_id                      => NVL(r_invoice_header.entity_id,l_entity_id_out)
            --,p_invoice_num                    => r_invoice_header.invoice_num -- 29908009
              ,p_invoice_num                    => l_Invoice_Num                -- 29908009
              ,p_series                         => r_invoice_header.series
              ,p_user_id                        => l_user_id
              ,p_operation_id                   => g_cll_f189_entry_operations_s
              ,p_organization_id                => NVL(r_invoice_header.organization_id,l_organization_id)
              ,p_location_id                    => NVL(r_invoice_header.location_id,l_location_id)
              ,p_invoice_amount                 => r_invoice_header.invoice_amount
              ,p_invoice_date                   => r_invoice_header.invoice_date
              ,p_invoice_type_id                => NVL(r_invoice_header.invoice_type_id,l_invoice_type_id)
              ,p_icms_type                      => r_invoice_header.icms_type
              ,p_icms_base                      => r_invoice_header.icms_base
              ,p_icms_tax                       => r_invoice_header.icms_tax
              ,p_icms_amount                    => r_invoice_header.icms_amount
              ,p_ipi_amount                     => r_invoice_header.ipi_amount
              ,p_subst_icms_base                => r_invoice_header.subst_icms_base
              ,p_subst_icms_amount              => r_invoice_header.subst_icms_amount
              ,p_diff_icms_tax                  => r_invoice_header.diff_icms_tax
              ,p_diff_icms_amount               => r_invoice_header.diff_icms_amount
              ,p_iss_base                       => r_invoice_header.iss_base
              ,p_iss_amount                     => r_invoice_header.iss_amount
              ,p_ir_base                        => r_invoice_header.ir_base
              ,p_ir_tax                         => r_invoice_header.ir_tax
              ,p_ir_amount                      => r_invoice_header.ir_amount
              ,p_irrf_withhold_invoice_id       => l_irrf_withhold_invoice_id
              ,p_description                    => r_invoice_header.description
              ,p_terms_id                       => NVL(r_invoice_header.terms_id,l_terms_id)
            --,p_terms_date                     => r_invoice_header.terms_date                                    -- 27854379
              ,p_terms_date                     => NVL(r_invoice_header.terms_date,r_invoice_header.invoice_date) -- 27854379
              ,p_first_payment_date             => l_first_payment_date
              ,p_insurance_amount               => r_invoice_header.insurance_amount
              ,p_freight_amount                 => r_invoice_header.freight_amount
              ,p_payment_discount               => r_invoice_header.payment_discount
              ,p_return_cfo_id                  => NVL(r_invoice_header.return_cfo_id,l_return_cfo_id)
              ,p_return_amount                  => r_invoice_header.return_amount
              ,p_return_date                    => r_invoice_header.return_date
              ,p_additional_tax                 => r_invoice_header.additional_tax
              ,p_additional_amount              => r_invoice_header.additional_amount
              ,p_other_expenses                 => r_invoice_header.other_expenses
              ,p_invoice_weight                 => r_invoice_header.invoice_weight
              ,p_contract_id                    => r_invoice_header.contract_id
              ,p_invoice_parent_id              => r_invoice_header.invoice_parent_id
              ,p_dollar_invoice_amount          => r_invoice_header.dollar_invoice_amount
              ,p_source_items                   => r_invoice_header.source_items
              ,p_importation_number             => r_invoice_header.importation_number
              ,p_po_conversion_rate             => r_invoice_header.po_conversion_rate
              ,p_importation_freight_weight     => r_invoice_header.importation_freight_weight
              ,p_total_fob_amount               => r_invoice_header.total_fob_amount
              ,p_freight_international          => r_invoice_header.freight_international
              ,p_importation_tax_amount         => r_invoice_header.importation_tax_amount
              ,p_importation_insurance_amount   => r_invoice_header.importation_insurance_amount
              ,p_total_cif_amount               => r_invoice_header.total_cif_amount
              ,p_customs_expense_func           => r_invoice_header.customs_expense_func
              ,p_importation_expense_func       => r_invoice_header.importation_expense_func
              ,p_dollar_total_fob_amount        => r_invoice_header.dollar_total_fob_amount
              ,p_dollar_customs_expense         => r_invoice_header.dollar_customs_expense
              ,p_dollar_freight_international   => r_invoice_header.dollar_freight_international
              ,p_dollar_import_tax_amount       => r_invoice_header.dollar_importation_tax_amount
              ,p_dollar_insurance_amount        => r_invoice_header.dollar_insurance_amount
              ,p_dollar_total_cif_amount        => r_invoice_header.dollar_total_cif_amount
              ,p_importation_expense_dol        => r_invoice_header.importation_expense_dol
              ,p_invoice_num_ap                 => NULL
              ,p_ap_interface_flag              => 'N'
              ,p_po_interface_flag              => 'N'
              ,p_fiscal_interface_flag          => 'N'
              ,p_fiscal_interface_date          => NULL
              ,p_translation_factor             => NULL
              ,p_icms_transl_factor             => NULL
              ,p_ipi_transl_factor              => NULL
              ,p_ii_transl_factor               => NULL
              ,p_item_transl_factor             => NULL
              ,p_attribute_category             => r_invoice_header.cin_attribute_category
              ,p_attribute1                     => r_invoice_header.cin_attribute1
              ,p_attribute2                     => r_invoice_header.cin_attribute2
              ,p_attribute3                     => r_invoice_header.cin_attribute3
              ,p_attribute4                     => r_invoice_header.cin_attribute4
              ,p_attribute5                     => r_invoice_header.cin_attribute5
              ,p_attribute6                     => r_invoice_header.cin_attribute6
              ,p_attribute7                     => r_invoice_header.cin_attribute7
              ,p_attribute8                     => r_invoice_header.cin_attribute8
              ,p_attribute9                     => r_invoice_header.cin_attribute9
              ,p_attribute10                    => r_invoice_header.cin_attribute10
              ,p_attribute11                    => r_invoice_header.cin_attribute11
              ,p_attribute12                    => r_invoice_header.cin_attribute12
              ,p_attribute13                    => r_invoice_header.cin_attribute13
              ,p_attribute14                    => r_invoice_header.cin_attribute14
              ,p_attribute15                    => r_invoice_header.cin_attribute15
              ,p_attribute16                    => r_invoice_header.cin_attribute16
              ,p_attribute17                    => r_invoice_header.cin_attribute17
              ,p_attribute18                    => r_invoice_header.cin_attribute18
              ,p_attribute19                    => r_invoice_header.cin_attribute19
              ,p_attribute20                    => r_invoice_header.cin_attribute20
              ,p_fiscal_document_model          => r_invoice_header.fiscal_document_model
              ,p_entity_parent_id               => r_invoice_header.invoice_parent_id --l_entity_parent_id
              ,p_irrf_base_date                 => r_invoice_header.irrf_base_date
              ,p_inss_base                      => r_invoice_header.inss_base
              ,p_inss_tax                       => r_invoice_header.inss_tax
              ,p_inss_amount                    => r_invoice_header.inss_amount
              ,p_ir_vendor                      => r_invoice_header.ir_vendor
              ,p_ir_categ                       => r_invoice_header.ir_categ
              ,p_icms_st_base                   => r_invoice_header.icms_st_base
              ,p_icms_st_amount                 => r_invoice_header.icms_st_amount
              ,p_icms_st_amount_recover         => r_invoice_header.icms_st_amount_recover
              ,p_diff_icms_amount_recover       => r_invoice_header.diff_icms_amount_recover
              ,p_alternate_currency_conv_rate   => r_invoice_header.alternate_currency_conv_rate
              ,p_gross_total_amount             => r_invoice_header.gross_total_amount
              ,p_source_state_id                => l_source_state_id
              ,p_destination_state_id           => l_destination_state_id
              ,p_inss_autonomous_inv_total      => r_invoice_header.inss_autonomous_invoiced_total
              ,p_inss_autonomous_amount         => r_invoice_header.inss_autonomous_amount
              ,p_inss_autonomous_tax            => r_invoice_header.inss_autonomous_tax
              ,p_inss_additional_tax_1          => l_inss_additional_tax_1
              ,p_inss_additional_tax_2          => l_inss_additional_tax_2
              ,p_inss_additional_tax_3          => l_inss_additional_tax_3
              ,p_inss_additional_base_1         => r_invoice_header.inss_additional_base_1
              ,p_inss_additional_base_2         => r_invoice_header.inss_additional_base_2
              ,p_inss_additional_base_3         => r_invoice_header.inss_additional_base_3
              ,p_inss_additional_amount_1       => l_inss_additional_amount_1
              ,p_inss_additional_amount_2       => l_inss_additional_amount_2
              ,p_inss_additional_amount_3       => l_inss_additional_amount_3
              ,p_inss_withhold_invoice_id       => l_inss_withhold_invoice_id
              ,p_iss_withhold_invoice_id        => l_iss_withhold_invoice_id
              ,p_interface_invoice_id           => r_invoice_header.interface_invoice_id
              ,p_siscomex_amount                => r_invoice_header.siscomex_amount
              ,p_dollar_siscomex_amount         => r_invoice_header.dollar_siscomex_amount
              ,p_iss_city_id                    => NVL(r_invoice_header.iss_city_id, l_city_id)
              ,p_importation_pis_amount         => r_invoice_header.importation_pis_amount
              ,p_importation_cofins_amount      => r_invoice_header.importation_cofins_amount
              ,p_dollar_import_pis_amount       => r_invoice_header.dollar_importation_pis_amount
              ,p_dollar_import_cofins_amount    => r_invoice_header.dollar_import_cofins_amount
              ,p_income_code                    => r_invoice_header.income_code
              ,p_funrural_base                  => r_invoice_header.funrural_base
              ,p_funrural_tax                   => r_invoice_header.funrural_tax
              ,p_funrural_amount                => r_invoice_header.funrural_amount
              ,p_sest_senat_base                => r_invoice_header.sest_senat_base
              ,p_sest_senat_tax                 => r_invoice_header.sest_senat_tax
              ,p_sest_senat_amount              => r_invoice_header.sest_senat_amount
              ,p_po_currency_code               => r_invoice_header.po_currency_code
              ,p_user_defined_conversion_rate   => r_invoice_header.user_defined_conversion_rate
              ,p_di_date                        => r_invoice_header.di_date
              ,p_clearance_date                 => r_invoice_header.clearance_date
              ,p_comments                       => r_invoice_header.comments
              ,p_vehicle_seller_doc_number      => r_invoice_header.vehicle_seller_doc_number
              ,p_vehicle_seller_state_id        => l_vehicle_seller_state_id
              ,p_third_party_amount             => r_invoice_header.third_party_amount
              ,p_abatement_amount               => r_invoice_header.abatement_amount
              ,p_import_document_type           => r_invoice_header.import_document_type
              ,p_eletronic_invoice_key          => r_invoice_header.eletronic_invoice_key
              ,p_process_indicator              => r_invoice_header.process_indicator
              ,p_process_origin                 => r_invoice_header.process_origin
              ,p_subseries                      => r_invoice_header.subseries
              ,p_icms_free_service_amount       => r_invoice_header.icms_free_service_amount
              ,p_return_invoice_num             => r_invoice_header.return_invoice_num
              ,p_return_series                  => r_invoice_header.return_series
              ,p_inss_subcontract_amount        => r_invoice_header.inss_subcontract_amount
              ,p_ship_via_lookup_code           => l_ship_via_lookup_code                -- 23091360
              ,p_service_execution_date         => r_invoice_header.service_execution_date
              ,p_pis_withhold_amount            => r_invoice_header.pis_withhold_amount
              ,p_cofins_withhold_amount         => r_invoice_header.cofins_withhold_amount
              ,p_drawback_granted_act_number    => r_invoice_header.drawback_granted_act_number
              ,p_cte_type                       => r_invoice_header.cte_type
              ,p_max_icms_amount_recover        => r_invoice_header.max_icms_amount_recover
              ,p_icms_tax_rec_simpl_br          => r_invoice_header.icms_tax_rec_simpl_br
              ,p_simplified_br_tax_flag         => r_invoice_header.simplified_br_tax_flag
              ,p_social_security_contrib_tax    => r_invoice_header.social_security_contrib_tax -- ER 17551029
              ,p_gilrat_tax                     => r_invoice_header.gilrat_tax                  -- ER 17551029
              ,p_senar_tax                      => r_invoice_header.senar_tax                   -- ER 17551029
              ,p_social_security_contrib_amt    => r_invoice_header.social_security_contrib_amount -- 27153706
              ,p_gilrat_amount                  => r_invoice_header.gilrat_amount                  -- 27153706
              ,p_senar_amount                   => r_invoice_header.senar_amount                   -- 27153706
              ,p_worker_category_id             => r_invoice_header.worker_category_id          -- ER 17551029 4a Fase
              ,p_material_equipment_amount      => r_invoice_header.material_equipment_amount   -- ER 17551029 4a Fase
              ,p_deduction_amount               => r_invoice_header.deduction_amount            -- ER 17551029 4a Fase
              ,p_cno_id                         => r_invoice_header.cno_id                      -- 24325307
              ,p_cno_number                     => r_invoice_header.cno_number                  -- ER 17551029 4a Fase
              ,p_caepf_number                   => r_invoice_header.caepf_number                -- ER 17551029 4a Fase
              ,p_indicator_multiple_links       => r_invoice_header.indicator_multiple_links    -- ER 17551029 4a Fase
              ,p_inss_service_amount_1          => r_invoice_header.inss_service_amount_1       -- ER 17551029 4a Fase
              ,p_inss_service_amount_2          => r_invoice_header.inss_service_amount_2       -- ER 17551029 4a Fase
              ,p_inss_service_amount_3          => r_invoice_header.inss_service_amount_3       -- ER 17551029 4a Fase
              ,p_remuneration_freight_amount    => r_invoice_header.remuneration_freight_amount -- ER 17551029 4a Fase
              ,p_sest_senat_income_code         => r_invoice_header.sest_senat_income_code      -- ER 9923702
              ,p_funrural_income_code           => r_invoice_header.funrural_income_code        -- ER 9923702
              ,p_imp_other_val_included_icms    => r_invoice_header.import_other_val_included_icms -- ER 20450226
              ,p_imp_other_val_not_icms         => r_invoice_header.import_other_val_not_icms      -- ER 20450226
              ,p_doll_other_val_included_icms   => r_invoice_header.dollar_other_val_included_icms -- ER 20450226
              ,p_doll_other_val_not_icms        => r_invoice_header.dollar_other_val_not_icms      -- ER 20450226
              ,p_carrier_document_type          => r_invoice_header.carrier_document_type          -- ER 20404053
              ,p_carrier_document_number        => r_invoice_header.carrier_document_number        -- ER 20404053
              ,p_carrier_state_id               => r_invoice_header.carrier_state_id               -- ER 20404053
              ,p_carrier_ie                     => r_invoice_header.carrier_ie                     -- ER 20404053
              ,p_carrier_vehicle_plate_num      => r_invoice_header.carrier_vehicle_plate_num      -- ER 20404053
              ,p_usage_authorization            => r_invoice_header.usage_authorization            -- ER 20382276
              ,p_dar_number                     => r_invoice_header.dar_number                     -- ER 20382276
              ,p_dar_total_amount               => r_invoice_header.dar_total_amount               -- ER 20382276
              ,p_dar_payment_date               => r_invoice_header.dar_payment_date               -- ER 20382276
              ,p_first_alternative_rate         => r_invoice_header.first_alternative_rate         -- ER 20608903
              ,p_second_alternative_rate        => r_invoice_header.second_alternative_rate        -- ER 20608903
              ,p_lp_inss_initial_base_amount    => r_invoice_header.lp_inss_initial_base_amount    --  21924115
              ,p_lp_inss_base_amount            => r_invoice_header.lp_inss_base_amount            --  21924115
              ,p_lp_inss_rate                   => r_invoice_header.lp_inss_rate                   --  21924115
              ,p_lp_inss_amount                 => r_invoice_header.lp_inss_amount                 --  21924115
              ,p_lp_inss_net_amount             => r_invoice_header.lp_inss_net_amount             --  21924115
              ,p_ip_inss_initial_base_amount    => r_invoice_header.ip_inss_initial_base_amount    --  21924115
              ,p_ip_inss_base_amount            => r_invoice_header.ip_inss_base_amount            --  21924115
              ,p_ip_inss_rate                   => r_invoice_header.ip_inss_rate                   --  21924115
              ,p_ip_inss_net_amount             => r_invoice_header.ip_inss_net_amount             --  21924115
              ,p_icms_fcp_amount                => r_invoice_header.icms_fcp_amount                -- 21804594
              ,p_icms_sharing_dest_amount       => r_invoice_header.icms_sharing_dest_amount       -- 21804594
              ,p_icms_sharing_source_amount     => r_invoice_header.icms_sharing_source_amount     -- 21804594
              ,p_department_id                  => r_invoice_header.department_id                  -- 22285738
              ,p_importation_cide_amount        => r_invoice_header.importation_cide_amount        -- 25341463
              ,p_dollar_import_cide_amount      => r_invoice_header.dollar_import_cide_amount      -- 25341463
              ,p_total_fcp_amount               => r_invoice_header.total_fcp_amount               -- 25713076
              ,p_total_fcp_st_amount            => r_invoice_header.total_fcp_st_amount            -- 25713076
              ,p_sest_tax                       => r_invoice_header.sest_tax                       -- 25808200 - 25808214
              ,p_senat_tax                      => r_invoice_header.senat_tax                      -- 25808200 - 25808214
              ,p_sest_amount                    => r_invoice_header.sest_amount                    -- 27153706
              ,p_senat_amount                   => r_invoice_header.senat_amount                   -- 27153706
            --,p_source_city_id                 => r_invoice_header.source_city_id                 -- 27463767 -- 28487689 - 28597878
              ,p_source_city_id                 => l_source_city_id                                -- 28487689 - 28597878
            --,p_destination_city_id            => r_invoice_header.destination_city_id            -- 27463767 -- 28487689 - 28597878
              ,p_destination_city_id            => l_destination_city_id                           -- 28487689 - 28597878
              ,p_source_ibge_city_code          => r_invoice_header.source_ibge_city_code          -- 27463767
              ,p_destination_ibge_city_code     => r_invoice_header.destination_ibge_city_code     -- 27463767
              ,p_reference                      => r_invoice_header.reference                      -- 27579747
              ,p_ship_to_state_id               => l_ship_to_state_id                              -- 28487689 - 28597878
              ,p_freight_mode                   => r_invoice_header.freight_mode                   -- 29330466 - 29338175 - 29385361 - 29480917
              ,p_fisco_additional_information   => r_invoice_header.fisco_additional_information   -- 29330466 - 29338175 - 29385361 - 29480917
              ,p_ir_cumulative_base             => r_invoice_header.ir_cumulative_base             -- 29448946
              ,p_iss_mat_third_parties_amount   => r_invoice_header.iss_mat_third_parties_amount   -- 29635195
              ,p_iss_subcontract_amount         => r_invoice_header.iss_subcontract_amount         -- 29635195
              ,p_iss_exempt_transac_amount      => r_invoice_header.iss_exempt_transactions_amount -- 29635195
              ,p_iss_deduction_amount           => r_invoice_header.iss_deduction_amount           -- 29635195
              ,p_iss_fiscal_observation         => r_invoice_header.iss_fiscal_observation         -- 29635195
              ,p_return_code                    => l_return_code
              ,p_return_message                 => l_return_message
            );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --206;
            --
            -- Inserindo Nota de saida
            --
            CREATE_OUTBOUND_INVOICES (p_type                   => 'VALIDATION' -- 22346186
                                     ,p_insert                 => 'Y'          -- 22346186
                                     ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                                     ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                     ,p_organization_id        => r_invoice_header.organization_id
                                     ,p_invoice_id             => g_cll_f189_invoices_s
                                     );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --207;
            --
            -- Inserindo Legal Process da Nota
            --
            CREATE_LEGAL_PROCESSES (p_type                   => 'INSERT'
                                   ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                                   ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                   ,p_organization_id        => r_invoice_header.organization_id
                                   ,p_invoice_id             => g_cll_f189_invoices_s
                                   );
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --208;
            -- ER 17551029 4a Fase - Start                                --
            -- Inserindo Prior Billings
            --
            CREATE_PRIOR_BILLINGS (p_type                   => 'INSERT'
                                  ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                                  ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                  ,p_organization_id        => r_invoice_header.organization_id
                                  ,p_invoice_id             => g_cll_f189_invoices_s
                                     );
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --209;
            -- ER 17551029 4a Fase - End
            --
            -- 28592012 - Start
            -- Inserindo Payment Methods
            --
  
            CREATE_PAYMENT_METHODS (p_type                   => 'INSERT'
                                   ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                                   ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                   ,p_organization_id        => r_invoice_header.organization_id
                                   ,p_invoice_id             => g_cll_f189_invoices_s
                                     );
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --209;
            -- 28592012 - End
            --
            --  29330466 - 29338175 - 29385361 - 29480917 - Start
            -- Inserindo Referenced Documents
            --
  
            CREATE_REFERENCED_DOCUMENTS (p_type                   => 'INSERT'
                                        ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                                        ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                        ,p_organization_id        => r_invoice_header.organization_id
                                        ,p_invoice_id             => g_cll_f189_invoices_s
                                        );
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --210;
            --  29330466 - 29338175 - 29385361 - 29480917 - Start
            -- Correcao do BUG 19943706, a chamada das linhas vem antes da chamada para Nota Complementar por utilizar informacoes das linhas nas linhas da Complementar
            -- Inserindo as linhas da Nota
            --
            -- Begin BUG 24387238 -- Reestruturacao da geracao de Notas Complementares (Custo, Imposto, Preco)
            --                    com geracao automatica da linha e copia da linha da interface
            IF NVL(g_generate_line_compl,'N') <> 'Y' THEN -- 21113828
              -- Nao gerar linha automaticamente
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --210;
              --
              l_type_exec := 'C';
              --
              g_operation_status := l_status; --ER 26338366/26899224 2a fase Third party network
              --
              CREATE_OPEN_LINES (p_type                         => 'INSERT'
                                ,p_interface_invoice_id         => r_invoice_header.interface_invoice_id
                                ,p_interface_operation_id       => r_invoice_header.interface_operation_id
                                ,p_organization_id              => NVL(l_organization_id,r_invoice_header.organization_id)
                                ,p_location_id                  => NVL(l_location_id,r_invoice_header.location_id)
                                ,p_operating_unit               => l_operating_unit
                                ,p_vendor_id                    => l_vendor_id
                                ,p_entity_id                    => r_invoice_header.entity_id
                                ,p_invoice_type_id              => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id)
                                ,p_price_adjust_flag            => l_price_adjust_flag
                                ,p_cost_adjust_flag             => l_cost_adjust_flag
                                ,p_tax_adjust_flag              => l_tax_adjust_flag
                                ,p_fixed_assets_flag            => l_fixed_assets_flag
                                ,p_parent_flag                  => l_parent_flag
                                ,p_contab_flag                  => l_contab_flag
                                ,p_payment_flag                 => l_payment_flag
                                ,p_freight_flag                 => r_invoice_header.freight_flag
                                ,p_freight_flag_inv_type        => l_freight_flag
                                ,p_project_flag                 => l_project_flag
                                ,p_chart_of_accounts_id         => l_chart_of_accounts_id
                                ,p_additional_tax               => r_invoice_header.additional_tax
                                ,p_allow_upd_price_flag         => l_allow_upd_price_flag
                                ,p_source_items                 => r_invoice_header.source_items
                                ,p_user_defined_conversion_rate => r_invoice_header.user_defined_conversion_rate
                                ,p_rcv_tolerance_perc_amount    => l_rcv_tolerance_perc_amount
                                ,p_rcv_tolerance_code           => l_rcv_tolerance_code
                                ,p_source_state_id              => r_invoice_header.source_state_id
                                ,p_destination_state_id         => r_invoice_header.destination_state_id
                                ,p_source_state_code            => r_invoice_header.source_state_code      -- Bug 17442462
                                ,p_destination_state_code       => r_invoice_header.destination_state_code -- Bug 17442462
                                ,p_gl_date                      => r_invoice_header.gl_date
                                ,p_receive_date                 => r_invoice_header.receive_date
                                ,p_qtde_nf_compl                => NULL
                                ,p_invoice_line_id_par          => l_invoice_line_id_par
                                ,p_requisition_type             => l_requisition_type   --<<Bug 17481870 - Egini - 20/09/2013 >>--
                                ,p_invoice_date                 => r_invoice_header.invoice_date -- 22012023
                                ,p_process_flag                 => g_process_flag
                                ,p_return_code                  => l_return_code
                                ,p_return_message               => l_return_message
                                -- Begin BUG 24387238
                                ,p_line_location_id             => l_line_location_id
                                ,p_requisition_line_id          => l_requisition_line_id
                                ,p_item_id                      => l_item_id
                                -- End BUG 24387238
                                );
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --211;
              CREATE_OPEN_INV_PARENTS (p_type                   => 'INSERT'
                                      ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                                      ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                      ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                                      ,p_invoice_line_id_par    => l_invoice_line_id_par -- BUG 19943706
                                      ,p_process_flag           => g_process_flag
                                      ,p_return_code            => l_return_code
                                      ,p_return_message         => l_return_message
                                      ,p_invoice_type_id        => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id) -- Bug 24387238 NULL -- Bug 17088635
                                      -- Begin BUG 24387238
                                      ,p_generate_line          => NVL(g_generate_line_compl,'N')
                                      ,p_invoice_line_id        => l_invoice_line_id_par
                                      ,p_parent_id_out          => l_parent_id_out
                                      ,p_interface_parent_id    => l_interface_parent_id
                                      ,p_invoice_parent_line_id => l_invoice_parent_line_id
                                      ,p_parent_line_id_out     => l_parent_line_id_out
                                      ,p_inv_line_parent_id_out => l_inv_line_parent_id_out
                                      ,p_total                  => r_invoice_header.invoice_amount
                                      ,p_icms                   => r_invoice_header.icms_amount
                                      ,p_ipi                    => r_invoice_header.ipi_amount
                                      ,p_business_vendor        => l_vendor_id
                                      ,p_org_state_id           => NVL(r_invoice_header.destination_state_id,l_destination_state_id)
                                      ,p_vendor_state_id        => NVL(r_invoice_header.source_state_id,l_source_state_id)
                                      ,p_additional_tax         => r_invoice_header.additional_tax
                                      ,p_user_id                => l_user_id
                                      ,p_interface              => 'Y' -- 22080756
                                      ,p_line_location_id       => l_line_location_id
                                      ,p_requisition_line_id    => l_requisition_line_id
                                      ,p_item_id                => l_item_id
                                      ,p_type_exec              => l_type_exec
                                      -- End  Bug 24387238
                                      ,p_return_customer_flag   => l_return_customer_flag -- 29908009
                                      );
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --212;
              --
              /*
              CLL_F189_COMPL_INVOICE_PKG.PROC_COMPL_INVOICE(p_invoice_id             => g_cll_f189_invoices_s
                                                           ,p_invoice_type_id        => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id)
                                                           ,p_total                  => r_invoice_header.invoice_amount
                                                           ,p_icms                   => r_invoice_header.icms_amount
                                                           ,p_ipi                    => r_invoice_header.ipi_amount
                                                           ,p_business_vendor        => l_vendor_id
                                                           ,p_org_state_id           => NVL(r_invoice_header.destination_state_id,l_destination_state_id)
                                                           ,p_vendor_state_id        => NVL(r_invoice_header.source_state_id,l_source_state_id)
                                                           ,p_additional_tax         => r_invoice_header.additional_tax
                                                           ,p_user_id                => l_user_id
                                                           ,p_interface              => 'Y' -- 22080756
                                                           -- Begin Bug 24387238
                                                           ,p_generate_line          => NVL(g_generate_line_compl,'N')
                                                           ,p_parent_id              => l_parent_id_out
                                                           ,p_parent_line_id         => l_parent_line_id_out
                                                           ,p_interface_inv_line_id  => NULL
                                                           ,p_invoice_line_id_in     => NULL
                                                           ,p_inv_line_parent_id_in  => NULL
                                                           ,p_type_exec              => p_type_exec
                                                           -- End Bug 24387238
                                                           );*/
  
            ELSE -- 21113828 -- GERA LINHAS AUTOMATICAS
              -- Gera linhas automaticas
              -- Validando se o parametro esta informado para gerar nota complementar de Custo
              BEGIN
                SELECT NVL(COST_ADJUST_FLAG,'N')
                  INTO V_COST_ADJUST_FLAG
                  FROM CLL_F189_INVOICE_TYPES
                 WHERE invoice_type_id = NVL(r_invoice_header.invoice_type_id,l_invoice_type_id)
                   AND organization_id = NVL(l_organization_id,r_invoice_header.organization_id);
              EXCEPTION WHEN NO_DATA_FOUND THEN
                V_COST_ADJUST_FLAG := 'N';
              END;
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --213;
              --
              print_log('V_COST_ADJUST_FLAG:'||V_COST_ADJUST_FLAG);
              IF V_COST_ADJUST_FLAG = 'Y' THEN
                --  Ajuste de Custo
                l_type_exec := 'N'; -- BUG 24387238 (quando ajuste de custo a linha de deve estar inserida
                --
                CREATE_OPEN_LINES (
                  p_type                         => 'INSERT'
                  ,p_interface_invoice_id         => r_invoice_header.interface_invoice_id
                  ,p_interface_operation_id       => r_invoice_header.interface_operation_id
                  ,p_organization_id              => NVL(l_organization_id,r_invoice_header.organization_id)
                  ,p_location_id                  => NVL(l_location_id,r_invoice_header.location_id)
                  ,p_operating_unit               => l_operating_unit
                  ,p_vendor_id                    => l_vendor_id
                  ,p_entity_id                    => r_invoice_header.entity_id
                  ,p_invoice_type_id              => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id)
                  ,p_price_adjust_flag            => l_price_adjust_flag
                  ,p_cost_adjust_flag             => l_cost_adjust_flag
                  ,p_tax_adjust_flag              => l_tax_adjust_flag
                  ,p_fixed_assets_flag            => l_fixed_assets_flag
                  ,p_parent_flag                  => l_parent_flag
                  ,p_contab_flag                  => l_contab_flag
                  ,p_payment_flag                 => l_payment_flag
                  ,p_freight_flag                 => r_invoice_header.freight_flag
                  ,p_freight_flag_inv_type        => l_freight_flag
                  ,p_project_flag                 => l_project_flag
                  ,p_chart_of_accounts_id         => l_chart_of_accounts_id
                  ,p_additional_tax               => r_invoice_header.additional_tax
                  ,p_allow_upd_price_flag         => l_allow_upd_price_flag
                  ,p_source_items                 => r_invoice_header.source_items
                  ,p_user_defined_conversion_rate => r_invoice_header.user_defined_conversion_rate
                  ,p_rcv_tolerance_perc_amount    => l_rcv_tolerance_perc_amount
                  ,p_rcv_tolerance_code           => l_rcv_tolerance_code
                  ,p_source_state_id              => r_invoice_header.source_state_id
                  ,p_destination_state_id         => r_invoice_header.destination_state_id
                  ,p_source_state_code            => r_invoice_header.source_state_code      -- Bug 17442462
                  ,p_destination_state_code       => r_invoice_header.destination_state_code -- Bug 17442462
                  ,p_gl_date                      => r_invoice_header.gl_date
                  ,p_receive_date                 => r_invoice_header.receive_date
                  ,p_qtde_nf_compl                => NULL
                  ,p_invoice_line_id_par          => l_invoice_line_id_par
                  ,p_requisition_type             => l_requisition_type   --<<Bug 17481870 - Egini - 20/09/2013 >>--
                  ,p_invoice_date                 => r_invoice_header.invoice_date -- 22012023
                  ,p_process_flag                 => g_process_flag
                  ,p_return_code                  => l_return_code
                  ,p_return_message               => l_return_message
                  -- Begin BUG 24387238
                  ,p_line_location_id             => l_line_location_id
                  ,p_requisition_line_id          => l_requisition_line_id
                  ,p_item_id                      => l_item_id
                  -- End BUG 24387238
                );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --214;
                -- Insere a parent header
                CREATE_OPEN_INV_PARENTS (p_type                  => 'INSERT'
                                        ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                                        ,p_interface_operation_id => r_invoice_header.interface_operation_id
                                        ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                                        ,p_invoice_line_id_par    => l_invoice_line_id_par -- BUG 19943706
                                        ,p_process_flag           => g_process_flag
                                        ,p_return_code            => l_return_code
                                        ,p_return_message         => l_return_message
                                        ,p_invoice_type_id        => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id) -- NULL -- Bug 17088635 -- UG 24387238
                                        -- Begin BUG 24387238
                                        ,p_generate_line          => NVL(g_generate_line_compl,'N')
                                        ,p_invoice_line_id        => l_invoice_line_id_par
                                        ,p_parent_id_out          => l_parent_id_out
                                        ,p_interface_parent_id    => l_interface_parent_id
                                        ,p_invoice_parent_line_id => l_invoice_parent_line_id
                                        ,p_parent_line_id_out     => l_parent_line_id_out
                                        ,p_inv_line_parent_id_out => l_inv_line_parent_id_out
                                        ,p_total                  => r_invoice_header.invoice_amount
                                        ,p_icms                   => r_invoice_header.icms_amount
                                        ,p_ipi                    => r_invoice_header.ipi_amount
                                        ,p_business_vendor        => l_vendor_id
                                        ,p_org_state_id           => NVL(r_invoice_header.destination_state_id,l_destination_state_id)
                                        ,p_vendor_state_id        => NVL(r_invoice_header.source_state_id,l_source_state_id)
                                        ,p_additional_tax         => r_invoice_header.additional_tax
                                        ,p_user_id                => l_user_id
                                        ,p_interface              => 'Y' -- 22080756
                                        ,p_line_location_id       => l_line_location_id
                                        ,p_requisition_line_id    => l_requisition_line_id
                                        ,p_item_id                => l_item_id
                                        ,p_type_exec              => l_type_exec
                                        -- End  Bug 24387238
                                        ,p_return_customer_flag   => l_return_customer_flag -- 29908009
                                        );
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --215;
                --
              -- Begin Bug 24387238
              ELSE
                --
                l_type_exec := p_type_exec;
                --
                print_log('l_type_exec:'||l_type_exec);
                IF l_type_exec = 'N' THEN
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --216;
                  -- Ajuste de preco e imposto
                  print_log('------------------------------------------------------------------------------------------------');
                  CREATE_OPEN_LINES (
                    p_type                         => 'INSERT'
                    ,p_interface_invoice_id         => r_invoice_header.interface_invoice_id
                    ,p_interface_operation_id       => r_invoice_header.interface_operation_id
                    ,p_organization_id              => NVL(l_organization_id,r_invoice_header.organization_id)
                    ,p_location_id                  => NVL(l_location_id,r_invoice_header.location_id)
                    ,p_operating_unit               => l_operating_unit
                    ,p_vendor_id                    => l_vendor_id
                    ,p_entity_id                    => r_invoice_header.entity_id
                    ,p_invoice_type_id              => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id)
                    ,p_price_adjust_flag            => l_price_adjust_flag
                    ,p_cost_adjust_flag             => l_cost_adjust_flag
                    ,p_tax_adjust_flag              => l_tax_adjust_flag
                    ,p_fixed_assets_flag            => l_fixed_assets_flag
                    ,p_parent_flag                  => l_parent_flag
                    ,p_contab_flag                  => l_contab_flag
                    ,p_payment_flag                 => l_payment_flag
                    ,p_freight_flag                 => r_invoice_header.freight_flag
                    ,p_freight_flag_inv_type        => l_freight_flag
                    ,p_project_flag                 => l_project_flag
                    ,p_chart_of_accounts_id         => l_chart_of_accounts_id
                    ,p_additional_tax               => r_invoice_header.additional_tax
                    ,p_allow_upd_price_flag         => l_allow_upd_price_flag
                    ,p_source_items                 => r_invoice_header.source_items
                    ,p_user_defined_conversion_rate => r_invoice_header.user_defined_conversion_rate
                    ,p_rcv_tolerance_perc_amount    => l_rcv_tolerance_perc_amount
                    ,p_rcv_tolerance_code           => l_rcv_tolerance_code
                    ,p_source_state_id              => r_invoice_header.source_state_id
                    ,p_destination_state_id         => r_invoice_header.destination_state_id
                    ,p_source_state_code            => r_invoice_header.source_state_code      -- Bug 17442462
                    ,p_destination_state_code       => r_invoice_header.destination_state_code -- Bug 17442462
                    ,p_gl_date                      => r_invoice_header.gl_date
                    ,p_receive_date                 => r_invoice_header.receive_date
                    ,p_qtde_nf_compl                => NULL
                    ,p_invoice_line_id_par          => l_invoice_line_id_par
                    ,p_requisition_type             => l_requisition_type   --<<Bug 17481870 - Egini - 20/09/2013 >>--
                    ,p_invoice_date                 => r_invoice_header.invoice_date -- 22012023
                    ,p_process_flag                 => g_process_flag
                    ,p_return_code                  => l_return_code
                    ,p_return_message               => l_return_message
                    -- Begin Bug 24387238
                    ,p_line_location_id             => l_line_location_id
                    ,p_requisition_line_id          => l_requisition_line_id
                    ,p_item_id                      => l_item_id
                    -- End Bug 24387238
                  );
                  print_log('------------------------------------------------------------------------------------------------');
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --217;
                  --
                  -- Insere parent e parent line
                  print_log('------------------------------------------------------------------------------------------------');
                  CREATE_OPEN_INV_PARENTS (
                    p_type                   => 'INSERT'
                    ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                    ,p_interface_operation_id => r_invoice_header.interface_operation_id
                    ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                    ,p_invoice_line_id_par    => l_invoice_line_id_par
                    ,p_process_flag           => g_process_flag
                    ,p_return_code            => l_return_code
                    ,p_return_message         => l_return_message
                    ,p_invoice_type_id        => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id) -- Bug 24387238 NULL -- Bug 17088635
                    -- Begin BUG 24387238
                    ,p_generate_line          => NVL(g_generate_line_compl,'N')
                    ,p_invoice_line_id        => l_invoice_line_id_par
                    ,p_parent_id_out          => l_parent_id_out
                    ,p_interface_parent_id    => l_interface_parent_id
                    ,p_invoice_parent_line_id => l_invoice_parent_line_id
                    ,p_parent_line_id_out     => l_parent_line_id_out
                    ,p_inv_line_parent_id_out => l_inv_line_parent_id_out
                    ,p_total                  => r_invoice_header.invoice_amount
                    ,p_icms                   => r_invoice_header.icms_amount
                    ,p_ipi                    => r_invoice_header.ipi_amount
                    ,p_business_vendor        => l_vendor_id
                    ,p_org_state_id           => NVL(r_invoice_header.destination_state_id,l_destination_state_id)
                    ,p_vendor_state_id        => NVL(r_invoice_header.source_state_id,l_source_state_id)
                    ,p_additional_tax         => r_invoice_header.additional_tax
                    ,p_user_id                => l_user_id
                    ,p_interface              => 'Y' -- 22080756
                    ,p_line_location_id       => l_line_location_id
                    ,p_requisition_line_id    => l_requisition_line_id
                    ,p_item_id                => l_item_id
                    ,p_type_exec              => l_type_exec
                    -- End  24387238
                    ,p_return_customer_flag   => l_return_customer_flag -- 29908009
                  );
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --218;
                ELSIF l_type_exec = 'C' THEN
                  print_log('------------------------------------------------------------------------------------------------');
                  CREATE_OPEN_INV_PARENTS (
                    p_type                   => 'INSERT'
                    ,p_interface_invoice_id   => r_invoice_header.interface_invoice_id
                    ,p_interface_operation_id => r_invoice_header.interface_operation_id
                    ,p_organization_id        => NVL(l_organization_id,r_invoice_header.organization_id)
                    ,p_invoice_line_id_par    => l_invoice_line_id_par
                    ,p_process_flag           => g_process_flag
                    ,p_return_code            => l_return_code
                    ,p_return_message         => l_return_message
                    ,p_invoice_type_id        => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id) -- Bug 24387238 NULL -- Bug 17088635
                    -- Begin BUG 24387238
                    ,p_generate_line          => NVL(g_generate_line_compl,'N')
                    ,p_invoice_line_id        => l_invoice_line_id_par
                    ,p_parent_id_out          => l_parent_id_out
                    ,p_interface_parent_id    => l_interface_parent_id
                    ,p_invoice_parent_line_id => l_invoice_parent_line_id
                    ,p_parent_line_id_out     => l_parent_line_id_out
                    ,p_inv_line_parent_id_out => l_inv_line_parent_id_out
                    ,p_total                  => r_invoice_header.invoice_amount
                    ,p_icms                   => r_invoice_header.icms_amount
                    ,p_ipi                    => r_invoice_header.ipi_amount
                    ,p_business_vendor        => l_vendor_id
                    ,p_org_state_id           => NVL(r_invoice_header.destination_state_id,l_destination_state_id)
                    ,p_vendor_state_id        => NVL(r_invoice_header.source_state_id,l_source_state_id)
                    ,p_additional_tax         => r_invoice_header.additional_tax
                    ,p_user_id                => l_user_id
                    ,p_interface              => 'Y' -- 22080756
                    ,p_line_location_id       => l_line_location_id
                    ,p_requisition_line_id    => l_requisition_line_id
                    ,p_item_id                => l_item_id
                    ,p_type_exec              => l_type_exec
                    -- End Bug 24387238
                    ,p_return_customer_flag   => l_return_customer_flag -- 29908009
                  );
                  --
                  print_log('  Chamando CLL_F189_COMPL_INVOICE_PKG.PROC_COMPL_INVOICE...');
                  CLL_F189_COMPL_INVOICE_PKG.PROC_COMPL_INVOICE(
                    p_invoice_id             => g_cll_f189_invoices_s
                    ,p_invoice_type_id        => NVL(l_invoice_type_id,r_invoice_header.invoice_type_id)
                    ,p_total                  => r_invoice_header.invoice_amount
                    ,p_icms                   => r_invoice_header.icms_amount
                    ,p_ipi                    => r_invoice_header.ipi_amount
                    ,p_business_vendor        => l_vendor_id
                    ,p_org_state_id           => NVL(r_invoice_header.destination_state_id,l_destination_state_id)
                    ,p_vendor_state_id        => NVL(r_invoice_header.source_state_id,l_source_state_id)
                    ,p_additional_tax         => r_invoice_header.additional_tax
                    ,p_user_id                => l_user_id
                    ,p_interface              => 'Y' -- 22080756
                    -- Begin Bug 24387238
                    ,p_generate_line          => NVL(g_generate_line_compl,'N')
                    ,p_parent_id              => l_parent_id_out
                    ,p_parent_line_id         => l_parent_line_id_out
                    ,p_interface_inv_line_id  => NULL
                    ,p_invoice_line_id_in     => NULL
                    ,p_inv_line_parent_id_in  => NULL
                    ,p_type_exec              => p_type_exec
                    -- End Bug 24387238
                    ,p_ret_code               => l_return_code    -- Enh 28884403
                    ,p_ret_message            => l_return_message -- Enh 28884403
                  );
                  -- End Bug 24387238
                END IF; -- Bug 24387238
              END IF; -- Bug 24387238
            END IF;
            -- End BUG 24387238
            --- 29908009 BEGIN
            IF l_return_customer_flag = 'F' THEN            
              CLL_F189_VENDOR_RETURN_PKG.CREATE_LINES( 
                p_invoice_id                 => g_cll_f189_invoices_s
                ,p_invoice_type_id            => l_invoice_type_id
                ,p_total                      => r_invoice_header.invoice_amount
                ,p_icms                       => r_invoice_header.icms_amount
                ,p_ipi                        => r_invoice_header.ipi_amount
                ,p_business_vendor            => l_vendor_id
                ,p_org_state_id               => NVL(r_invoice_header.destination_state_id,l_destination_state_id)
                ,p_vendor_state_id            => NVL(r_invoice_header.source_state_id,l_source_state_id)
                ,p_additional_tax             => r_invoice_header.additional_tax
                ,p_user_id                    => l_user_id
                ,p_cfop_id                    => l_cfop_return_id                                  -- 31001507
                ---,p_interface                  => 'Y'                                               -- 29908009
                ---,p_rtv_cfo_id                 => r_invoice_parents_lines.rtv_cfo_id                -- 29908009
                ---,p_rtv_quantity               => r_invoice_parents_lines.rtv_quantity              -- 29908009
                ---,p_rtv_icms_tributary_code    => r_invoice_parents_lines.rtv_icms_tributary_code   -- 29908009
                ---,p_rtv_ipi_tributary_code     => r_invoice_parents_lines.rtv_ipi_tributary_code    -- 29908009
                ---,p_rtv_pis_tributary_code     => r_invoice_parents_lines.rtv_pis_tributary_code    -- 29908009
                ---,p_rtv_cofins_tributary_code  => r_invoice_parents_lines.rtv_cofins_tributary_code -- 29908009
              );
              -- 31001507 - Start
              IF g_aprova = 'Y' and l_requisition_type = 'NA'  THEN
                 --
                 g_index  := r_invoice_header.interface_operation_id;
                 l_debug := 218;
                 --
                 IF NOT(r_cll_f189_operation.exists(g_index))THEN
                    r_cll_f189_operation(g_index).organization_id        := NVL(l_organization_id,r_invoice_header.organization_id);
                    r_cll_f189_operation(g_index).new_operation_id       := g_cll_f189_entry_operations_s;
                    r_cll_f189_operation(g_index).location_id            := NVL(l_location_id,r_invoice_header.location_id);
                    r_cll_f189_operation(g_index).gl_date                := r_invoice_header.gl_date;
                    r_cll_f189_operation(g_index).receive_date           := NVL(r_invoice_header.receive_date,SYSDATE);
                    r_cll_f189_operation(g_index).user_id                := l_user_id;
                    r_cll_f189_operation(g_index).interface_operation_id := r_invoice_header.interface_operation_id;
                    r_cll_f189_operation(g_index).interface_invoice_id   := r_invoice_header.interface_invoice_id;
                 END IF;
              END IF; --IF g_aprova = 'Y' and l_requisition_type = 'NA' THEN
              -- 31001507 - End
            END IF;
            --- 29908009 END
            -- Atualizando a nota para processado na Open
            --
            IF p_open_source = 'RI' THEN
              SET_PROCESS_FLAG(
                p_process_flag         => 6
                ,p_interface_invoice_id => r_invoice_header.interface_invoice_id
              );
            END IF; --IF p_open_source = 'RI' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --219;
            -- 31001507 - Start
            IF l_return_customer_flag = 'F' THEN    
              BEGIN
                SELECT NVL(rfo.debit_free,'N')
                , rfo.tpa_control_type
                INTO l_debit_free
                , l_tpa_control_type
                FROM   cll_f189_fiscal_operations rfo
                WHERE  rfo.cfo_id = l_cfop_return_id;
              EXCEPTION
                WHEN OTHERS THEN
                  l_debit_free       := 'N';
                  l_tpa_control_type := NULL;
              END;
            ELSE
            -- 31001507 - End
              --
              -- 27579747 - Start
              BEGIN
                SELECT 
                  NVL(rfo.debit_free,'N')
                  ,rfo.tpa_control_type
                INTO 
                  l_debit_free
                  ,l_tpa_control_type
                FROM 
                  cll_f189_invoice_lines_iface ril
                  , cll_f189_fiscal_operations rfo
                WHERE 1=1
                  AND ril.interface_invoice_id = r_invoice_header.interface_invoice_id
                  AND (ril.cfo_code = rfo.cfo_code OR ril.cfo_id = rfo.cfo_id)
                  AND ROWNUM = 1;
              EXCEPTION WHEN OTHERS THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --219;
                --l_debit_free       := NULL; -- 31001507
                l_debit_free       := 'N';  -- 31001507
                l_tpa_control_type := NULL;
              END;
            END IF; -- 31001507

            print_log('g_aprova          :'||g_aprova);
            print_log('l_requisition_type:'||l_requisition_type);
            IF g_aprova = 'Y' AND l_requisition_type <> 'NA' THEN
              -- 28806961_27831745 - Start
              -- A partir desta solucao este trecho sera comentado para atender a aprovacao automatica de loader com pedido.
              /*
              IF p_source = 'CLL_F369 EFD LOADER SHIPPER'
              OR p_source = 'CLL_F369 EFD LOADER' THEN
              l_rec_status := 'INCOMPLETE';
              ELSE
              */
              -- 28806961_27831745 - End
              l_rec_status := 'APPROVED';
              --END IF; -- 28806961_27831745
            ELSIF g_aprova = 'Y' AND l_requisition_type = 'NA' THEN
              -- 28806961_27831745 - Start
              -- A partir desta solucao este trecho sera comentado para atender a aprovacao automatica de loader com pedido.
              /*
                           IF p_source = 'CLL_F369 EFD LOADER SHIPPER'
                           OR p_source = 'CLL_F369 EFD LOADER'
              */
              -- 28806961_27831745 - End
              -- 30485011 - Inicio
              IF p_source = 'CLL_F369 EFD LOADER SHIPPER' OR p_source = 'CLL_F369 EFD LOADER' THEN
                l_status := 'IN PROCESS';
                -- 30485011 - Fim
              ELSIF l_debit_free = 'Y' OR l_tpa_control_type IS NOT NULL THEN
                l_rec_status := 'INCOMPLETE';
              ELSE
                l_rec_status := 'COMPLETE';
              END IF;
            ELSE
              l_rec_status := 'INCOMPLETE';
            END IF;
            print_log('l_rec_status      :'||l_rec_status);
            CLL_F189_ENTRY_OPERATIONS_PUB.SET_STATUS_ENTRY_OPERATIONS (
              p_status          => l_rec_status
              ,p_operation_id    => g_cll_f189_entry_operations_s
              ,p_organization_id => r_invoice_header.organization_id
            );
            /*IF g_aprova = 'Y' AND l_requisition_type = 'NA' THEN
            CLL_F189_ENTRY_OPERATIONS_PUB.SET_STATUS_ENTRY_OPERATIONS (p_status          => 'INCOMPLETE'
            ,p_operation_id    => g_cll_f189_entry_operations_s
            ,p_organization_id => r_invoice_header.organization_id
            );
            END IF;*/
            -- 27579747 - End
          END IF; -- Encontrou erro na acumulacao do imposto -- Bug 17865884
        END IF; -- IF g_process_flag IS NOT NULL THEN -- encontrou erro na verificacao da check_holds
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --220;
      EXCEPTION WHEN OTHERS THEN
        --
        -- Atualiza a tabela de interface do RI
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --221;
        print_log('ERRO          :'||sqlerrm);
        print_log('g_process_flag:'||g_process_flag);
        IF p_open_source = 'RI' THEN
          UPDATE cll_f189_invoices_interface
          SET process_flag = g_process_flag
          WHERE interface_invoice_id = r_invoice_header.interface_invoice_id;
          --
        END IF; --IF p_open_source = 'RI' THEN
        --
        l_cont_erro := l_cont_erro + 1;
        --
      END;
    END LOOP; --r_invoice_header
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --221;
    print_log('  Fim do loop (r_invoice_header)');
    print_log('');
    --
    print_log('  Inicio do loop (operations) '||NVL(r_cll_f189_operation.first, 0)||' a '||NVL(r_cll_f189_operation.last, 0));
    FOR g_index IN NVL(r_cll_f189_operation.first, 0)..NVL(r_cll_f189_operation.last, 0) LOOP
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --221;
      IF r_cll_f189_operation.exists(g_index) THEN
        --
        -- 27579747 - Start
        --IF p_source <> 'CLL_F369 EFD LOADER' THEN -- ER 14124731
        --           IF p_source NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN -- 28806961_27831745
        print_log('l_debit_free      :'||l_debit_free);
        print_log('l_tpa_control_type:'||l_tpa_control_type);
        IF (l_debit_free = 'N' AND l_tpa_control_type IS NULL) THEN
          -- 27579747 - End
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --222;
          APPROVE_INTERFACE( 
            p_organization_id => r_cll_f189_operation(g_index).organization_id
            ,p_operation_id    => r_cll_f189_operation(g_index).new_operation_id
            ,p_location_id     => r_cll_f189_operation(g_index).location_id
            ,p_gl_date         => l_gl_date                                  -- 29559606
            ,p_receive_date    => l_receive_date                             -- 29559606
            --,p_gl_date         => r_cll_f189_operation(g_index).gl_date      -- 29559606
            --,p_receive_date    => r_cll_f189_operation(g_index).receive_date -- 29559606
            ,p_created_by      => r_cll_f189_operation(g_index).user_id
            ,p_source          => p_source
            ,p_interface       => 'Y'
            ,p_int_invoice_id  => r_cll_f189_operation(g_index).interface_invoice_id 
          );
          --
          --
          -- BUG 30789077 - Start
          --
          IF NVL(l_tpa_control_type, 'x') = 'DEVOLUTION_OF' THEN
            --
            cll_f189_interface_pkg.ar_tpa (r_cll_f189_operation(g_index).new_operation_id, r_cll_f189_operation(g_index).organization_id) ;
            -- 31001507 - Start
          ELSE
            --
            CLL_F189_INTERFACE_PKG.AR (r_cll_f189_operation(g_index).new_operation_id, r_cll_f189_operation(g_index).organization_id);
            --
            -- 31001507 - End
          END IF ;
          --
          -- BUG 30789077 - End
          --
        END IF; -- 27579747
        --
        --END IF; -- ER 14124731 -- 28806961_27831745
      END IF;
    END LOOP;
    print_log('  Fim do loop (operations)');
    print_log('');
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15;
    r_cll_f189_operation.delete;
    --
    IF p_delete_line = 'Y' THEN
      DELETE cll_f189_interface_errors
      WHERE interface_operation_id IN (
        SELECT DISTINCT interface_operation_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      --
      DELETE cll_f189_ra_cust_trx_int
      WHERE interface_invoice_id IN (
        SELECT DISTINCT interface_invoice_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      --
      DELETE cll_f189_legal_processes_int
      WHERE interface_invoice_id IN (SELECT DISTINCT interface_invoice_id
      FROM cll_f189_invoices_interface
      WHERE process_flag = 6
      AND source       = p_source
      );
      --
      DELETE cll_f189_freight_inv_interface
      WHERE interface_operation_id IN (
        SELECT DISTINCT interface_operation_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      --
      DELETE cll_f189_invoice_line_par_int
      WHERE interface_parent_id IN (
        SELECT interface_parent_id
        FROM cll_f189_invoice_parents_int
        WHERE interface_invoice_id IN (
          SELECT DISTINCT interface_invoice_id
          FROM cll_f189_invoices_interface
          WHERE process_flag = 6
          AND source       = p_source
        )
      );
      --
      DELETE cll_f189_invoice_parents_int
      WHERE interface_invoice_id IN (
        SELECT DISTINCT interface_invoice_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      --
      DELETE cll_f189_invoice_lines_iface
      WHERE interface_invoice_id IN (
        SELECT DISTINCT interface_invoice_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      --
      -- 29921054 - Start
      /*DELETE cll_f189_invoices_interface
      WHERE process_flag = 6
      AND source       = p_source;*/
      -- 29921054 - End
      --
      -- ER 17551029 4a Fase - Start
      --
      DELETE cll_f189_prior_billings_int
      WHERE interface_invoice_id IN (
        SELECT DISTINCT interface_invoice_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      -- ER 17551029 4a Fase - End
      --
      -- 28592012 - Start
      DELETE cll_f189_payment_methods_iface
      WHERE interface_invoice_id IN (
        SELECT DISTINCT interface_invoice_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      -- 28592012 - End
      --
      -- 29330466 - 29338175 - 29385361 - 29480917 - Start
      DELETE cll_f189_ref_docs_iface
      WHERE interface_invoice_id IN (
        SELECT DISTINCT interface_invoice_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      -- 29330466 - 29338175 - 29385361 - 29480917 - End
      --
      -- ER 26338366/26899224 - Start
      --
      DELETE CLL_F513_TPA_RET_IFACE
      WHERE interface_invoice_id IN (
        SELECT DISTINCT interface_invoice_id
        FROM cll_f189_invoices_interface
        WHERE process_flag = 6
        AND source       = p_source
      );
      --
      -- 29921054 - Start
      DELETE cll_f189_invoices_interface
      WHERE process_flag = 6
      AND source       = p_source;
      -- 29921054 - End
      --
      -- ER 26338366/26899224 - End
    END IF; --IF p_delete_line = 'Y' THEN
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --223;
    COMMIT;
    --
    IF p_type_exec = 'C' THEN
      print_log('*******************************************************************************');
      print_log('        Integrated Receiving - Open Interface');
      print_log('+-----------------------------------------------------------------------------+');
      print_log('Total Rows processed                            :  '||TO_CHAR(NVL(l_cont,0)));
      print_log('Rows created CLL_F189_ENTRY_OPERATIONS          :  '||TO_CHAR(NVL(l_cont_oper,0)));
      print_log('Rows created CLL_F189_FREIGHT_INVOICES          :  '||TO_CHAR(NVL(g_cont_frt,0)));
      print_log('Rows created CLL_F189_INVOICES                  :  '||TO_CHAR(NVL(l_cont_inv,0)));
      print_log('Rows created CLL_F189_INVOICES_LINES            :  '||TO_CHAR(NVL(g_cont_line,0)));
      print_log('Rows created CLL_F189_INVOICES_PARENTS_INT      :  '||TO_CHAR(NVL(g_cont_par_inv,0)));
      print_log('Rows created CLL_F189_INVOICES_LINE_PARENTS_INT :  '||TO_CHAR(NVL(g_cont_par_inv_line,0)));
      print_log('Rows created CLL_F189_RA_CUST_TRX               :  '||TO_CHAR(NVL(g_cont_out_invoice,0)));
      print_log('Rows created CLL_F189_LEGAL_PROCESSES           :  '||TO_CHAR(NVL(g_cont_leg_processes,0)));
      print_log('Rows created CLL_F189_PRIOR_BILLINGS            :  '||TO_CHAR(NVL(g_cont_prior_billings,0)));
      print_log('Rows created CLL_F189_PAYMENT_METHODS           :  '||TO_CHAR(NVL(g_cont_payment_methods,0))); -- 28592012
      print_log('Rows created CLL_F189_REFERENCED_DOCUMENTS      :  '||TO_CHAR(NVL(g_cont_ref_documents,0)));   -- 29330466 - 29338175 - 29385361 - 29480917
      print_log('Rows with errors                                :  '||TO_CHAR(NVL(l_cont_erro,0)));
      print_log('*******************************************************************************');
    END IF;
    print_log('FIM CREATE_OPEN_INTERFACE');
  EXCEPTION WHEN others THEN
    p_return_code    := SQLCODE;
    p_return_message := l_module_name||' - ERROR: '||SQLERRM;
    ROLLBACK;
    raise_application_error(-20010, l_module_name||' - ERROR l_debug number: { '||TO_CHAR(l_debug)||' } GENERAL ERROR: '||SQLERRM);
  END CREATE_OPEN_INTERFACE;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_HEADER                                          |
  |                                                                          |
  | Description: Responsavel por fazer a chamada das procedures responsaveis |
  |              pelas validacoes de header                                  |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OPEN_HEADER (p_open_source                   IN VARCHAR2
                               ,p_interface_invoice_id          IN NUMBER
                               ,p_interface_operation_id        IN NUMBER
                               ,p_organization_id               IN NUMBER
                               ,p_location_id                   IN NUMBER
                               ,p_operating_unit                IN NUMBER
                               ,p_source                        IN VARCHAR2
                               ,p_gl_date                       IN DATE
                               ,p_receive_date                  IN DATE
                               ,p_invoice_type_id               IN NUMBER
                               ,p_entity_id                     IN NUMBER
                               ,p_document_type                 IN VARCHAR2
                               ,p_document_number               IN VARCHAR2
                               ,p_ie                            IN VARCHAR2
                               ,p_inss_additional_base_1        IN NUMBER
                               ,p_inss_additional_base_2        IN NUMBER
                               ,p_inss_additional_base_3        IN NUMBER
                               ,p_inss_tax                      IN NUMBER
                               ,p_inss_additional_tax_1         IN NUMBER
                               ,p_inss_additional_tax_2         IN NUMBER
                               ,p_inss_additional_tax_3         IN NUMBER
                               ,p_inss_substitute_flag          IN VARCHAR2
                               ,p_inss_additional_amount_1      IN NUMBER
                               ,p_inss_additional_amount_2      IN NUMBER
                               ,p_inss_additional_amount_3      IN NUMBER
                               ,p_soma_source                   IN NUMBER
                               ,p_soma_freight_flag             IN NUMBER
                               ,p_soma_gl_date                  IN NUMBER
                               ,p_soma_org_id                   IN NUMBER
                               ,p_soma_location                 IN NUMBER
                               ,p_soma_inv_type                 IN NUMBER
                               ,p_invoice_num                   IN NUMBER
                               ,p_invoice_amount                IN NUMBER
                               ,p_utilities_flag                IN VARCHAR2
                               ,p_gross_total_amount            IN NUMBER
                               ,p_invoice_date                  IN DATE
                               ,p_simplified_br_tax_flag        IN VARCHAR2
                               ,p_icms_base                     IN NUMBER
                               ,p_icms_amount                   IN NUMBER
                               ,p_max_icms_amount_recover       IN NUMBER
                               ,p_icms_tax_rec_simpl_br         IN NUMBER
                               ,p_icms_type                     IN VARCHAR2
                               ,p_icms_st_amount                IN NUMBER
                               ,p_ipi_amount                    IN NUMBER
                               ,p_set_of_books_id               IN NUMBER
                               ,p_payment_flag                  IN VARCHAR2
                               ,p_freight_flag                  IN VARCHAR2
                               ,p_total_freight_weight          IN NUMBER
                               ,p_requisition_type              IN VARCHAR2
                               ,p_series                        IN VARCHAR2
                               ,p_subseries                     IN VARCHAR2
                               ,p_fiscal_document_model         IN VARCHAR2
                               ,p_eletronic_invoice_key         IN VARCHAR2 -- ER 14124731
                               ,p_cte_type                      IN NUMBER
                               ,p_invoice_parent_id             IN NUMBER
                               ,p_parent_flag                   IN VARCHAR2
                               ,p_cost_adjust_flag              IN VARCHAR2
                               ,p_price_adjust_flag             IN VARCHAR2
                               ,p_tax_adjust_flag               IN VARCHAR2
                               ,p_fixed_assets_flag             IN VARCHAR2
                               ,p_cofins_flag                   IN VARCHAR2
                               ,p_cofins_code_combination_id    IN NUMBER
                               ,p_include_iss_flag              IN VARCHAR2
                               ,p_iss_city_id                   IN NUMBER
                               ,p_iss_city_code                 IN VARCHAR2
                               ,p_iss_base                      IN NUMBER
                               ,p_iss_amount                    IN NUMBER
                               ,p_source_state_id               IN NUMBER
                               ,p_source_state_code             IN VARCHAR2
                               ,p_destination_state_id          IN NUMBER
                               ,p_destination_state_code        IN VARCHAR2
                               ,p_terms_id                      IN NUMBER
                               ,p_terms_name                    IN VARCHAR2
                               ,p_first_payment_date            IN DATE
                               ,p_terms_date                    IN DATE
                               ,p_additional_tax                IN NUMBER
                               ,p_additional_amount             IN NUMBER
                               ,p_return_cfo_id                 IN NUMBER
                               ,p_return_cfo_code               IN VARCHAR2
                               ,p_return_amount                 IN NUMBER
                               ,p_source_items                  IN VARCHAR2
                               ,p_contract_id                   IN NUMBER
                               ,p_importation_number            IN VARCHAR2
                               ,p_total_fob_amount              IN NUMBER
                               ,p_freight_international         IN NUMBER
                               ,p_importation_insurance_amount  IN NUMBER
                               ,p_importation_tax_amount        IN NUMBER
                               ,p_importation_expense_func      IN NUMBER
                               ,p_customs_expense_func          IN NUMBER
                               ,p_total_cif_amount              IN NUMBER
                               ,p_inss_base                     IN NUMBER
                               ,p_inss_calculation_flag         IN VARCHAR2
                               ,p_inss_amount                   IN NUMBER
                               ,p_inss_subcontract_amount       IN NUMBER
                               ,p_inss_autonomous_tax           IN NUMBER
                               ,p_inss_autonomous_amount        IN NUMBER
                               ,p_inss_autonomous_inv_total     IN NUMBER
                               ,p_ir_vendor                     IN VARCHAR2
                               ,p_ir_base                       IN NUMBER
                               ,p_ir_amount                     IN NUMBER
                               ,p_ir_tax                        IN NUMBER
                               ,p_ir_categ                      IN VARCHAR2
                               ,p_vehicle_seller_state_id       IN NUMBER
                               ,p_vehicle_seller_state_code     IN VARCHAR2
                               ,p_import_document_type          IN VARCHAR2
                               ,p_process_origin                IN VARCHAR2
                               ,p_social_security_contrib_tax   IN NUMBER   -- ER 17551029
                               ,p_gilrat_tax                    IN NUMBER   -- ER 17551029
                               ,p_senar_tax                     IN NUMBER   -- ER 17551029
                               ,p_worker_category_id            IN NUMBER   -- ER 17551029 4a Fase
                               ,p_category_code                 IN NUMBER   -- ER 17551029 4a Fase
                               ,p_cbo_code                      IN VARCHAR2 -- ER 17551029 4a Fase
                               ,p_material_equipment_amount     IN NUMBER   -- ER 17551029 4a Fase
                               ,p_deduction_amount              IN NUMBER   -- ER 17551029 4a Fase
                               ,p_cno_id                        IN NUMBER   -- 24325307
                               ,p_cno_number                    IN NUMBER   -- ER 17551029 4a Fase
                               ,p_caepf_number                  IN VARCHAR2 -- ER 17551029 4a Fase
                               ,p_indicator_multiple_links      IN NUMBER   -- ER 17551029 4a Fase
                               ,p_inss_service_amount_1         IN NUMBER   -- ER 17551029 4a Fase
                               ,p_inss_service_amount_2         IN NUMBER   -- ER 17551029 4a Fase
                               ,p_inss_service_amount_3         IN NUMBER   -- ER 17551029 4a Fase
                               ,p_remuneration_freight_amount   IN NUMBER   -- ER 17551029 4a Fase
                               ,p_other_expenses                IN NUMBER   -- 21091872
                               ,p_insurance_amount              IN NUMBER   -- 21091872
                               ,p_freight_amount                IN NUMBER   -- 21091872
                               ,p_lp_inss_initial_base_amount   IN NUMBER   --  21924115
                               ,p_lp_inss_base_amount           IN NUMBER   --  21924115
                               ,p_lp_inss_rate                  IN NUMBER   --  21924115
                               ,p_lp_inss_amount                IN NUMBER   --  21924115
                               ,p_lp_inss_net_amount            IN NUMBER   --  21924115
                               ,p_ip_inss_initial_base_amount   IN NUMBER   --  21924115
                               ,p_ip_inss_base_amount           IN NUMBER   --  21924115
                               ,p_ip_inss_rate                  IN NUMBER   --  21924115
                               ,p_ip_inss_net_amount            IN NUMBER   --  21924115
                               ,p_source_city_id                IN NUMBER   -- 28487689 - 28597878
                               ,p_source_ibge_city_code         IN NUMBER   -- 28487689 - 28597878
                               ,p_destination_city_id           IN NUMBER   -- 28487689 - 28597878
                               ,p_destination_ibge_city_code    IN NUMBER   -- 28487689 - 28597878
                               ,p_ship_to_state_id              IN NUMBER   -- 28487689 - 28597878
                               ,p_return_customer_flag          IN VARCHAR2 -- 29908009
                               ,p_process_flag                  OUT NOCOPY NUMBER
                               ,p_vendor_id                     OUT NOCOPY NUMBER
                               ,p_allow_upd_price_flag          OUT NOCOPY VARCHAR2
                               ,p_rcv_tolerance_perc_amount     OUT NOCOPY NUMBER
                               ,p_rcv_tolerance_code            OUT NOCOPY VARCHAR2
                               ,p_pis_amount_recover_cnpj       OUT NOCOPY NUMBER
                               ,p_cofins_amount_recover_cnpj    OUT NOCOPY NUMBER
                               ,p_cumulative_threshold_type     OUT NOCOPY VARCHAR2
                               ,p_minimum_tax_amount            OUT NOCOPY VARCHAR2
                               ,p_document_type_out             OUT NOCOPY VARCHAR2
                               ,p_funrural_contributor_flag     OUT NOCOPY VARCHAR2
                               ,p_rounding_precision            OUT NOCOPY NUMBER
                               ,p_entity_id_out                 OUT NOCOPY NUMBER
                               ,p_first_payment_date_out        OUT NOCOPY DATE
                               ,p_terms_id_out                  OUT NOCOPY NUMBER
                               ,p_return_cfo_id_out             OUT NOCOPY NUMBER
                               ,p_source_state_id_out           OUT NOCOPY NUMBER
                               ,p_destination_state_id_out      OUT NOCOPY NUMBER
                               ,p_source_city_id_out            OUT NOCOPY NUMBER -- 28487689 - 28597878
                               ,p_destination_city_id_out       OUT NOCOPY NUMBER -- 28487689 - 28597878
                               ,p_ship_to_state_id_out          OUT NOCOPY NUMBER -- 28487689 - 28597878
                               ,p_source_ibge_city_out          OUT NOCOPY NUMBER -- 28730077
                               ,p_destination_ibge_city_out     OUT NOCOPY NUMBER -- 28730077
                               ,p_inss_additional_amount_1_out  OUT NOCOPY NUMBER
                               ,p_inss_additional_amount_2_out  OUT NOCOPY NUMBER
                               ,p_inss_additional_amount_3_out  OUT NOCOPY NUMBER
                               ,p_city_id                       OUT NOCOPY NUMBER
                               ,p_vehicle_seller_state_id_out   OUT NOCOPY NUMBER
                               ,p_qtd_lines_tmp                 OUT NOCOPY NUMBER
                               ,p_qtde_nf_compl                 OUT NOCOPY NUMBER -- Bug 16600918
                               ,p_return_code                   OUT NOCOPY VARCHAR2
                               ,p_return_message                OUT NOCOPY VARCHAR2
                               ) IS
    --

    --
    l_error                         VARCHAR2(100) := NULL;
    l_error_code                    VARCHAR2(100) := NULL;
    --
    l_inss_aut_max_retention        cll_f189_parameters.inss_autonomous_max_retention%type;
    l_fed_withholding_tax_flag      cll_f189_parameters.federal_withholding_tax_flag%type;
    l_gl_date_diff_from_sysdate     cll_f189_parameters.gl_date_diff_from_sysdate%type;
    l_rec_date_diff_from_sysdate    cll_f189_parameters.receive_date_diff_from_sysdate%type;
    l_invoice_date_less_than        cll_f189_parameters.invoice_date_less_than%type; -- Bug 10367485
    l_invoice_days                  NUMBER;                                          -- Bug 10367485
    --
    l_inss_additional_tax_1_ci      cll_f189_business_vendors.inss_additional_tax_1%type;
    l_inss_additional_tax_2_ci      cll_f189_business_vendors.inss_additional_tax_2%type;
    l_inss_additional_tax_3_ci      cll_f189_business_vendors.inss_additional_tax_3%type;
    l_inss_substitute_flag_ci       cll_f189_business_vendors.inss_substitute_flag%type;
    l_inss_tax_ci                   cll_f189_business_vendors.inss_tax%type;

    --
    l_inss_additional_tax_1_calc    NUMBER;
    l_inss_additional_tax_2_calc    NUMBER;
    l_inss_additional_tax_3_calc    NUMBER;
    l_inss_substitute_flag_calc     VARCHAR2(1);
    l_inss_tax_calc                 NUMBER;
    --
    l_validate_flag                 VARCHAR2(1)  := NVL(fnd_profile.value('CLL_F189_INVOICE_NUMBER_VALIDATE'),'N');
    l_rural_contributions_flag      VARCHAR2(1)  := NVL(FND_PROFILE.VALUE('CLL_F189_RURAL_CONTRIBUTIONS'),'N');
    l_prf_setup_iss                 VARCHAR2(30) := NVL(FND_PROFILE.VALUE('CLL_F189_SETUP_ISS'),'N');
    --
    l_inventory_organization_id     NUMBER;
    l_soma_operation                NUMBER;
    l_gl_periods                    VARCHAR2(30);
    l_lookup_frete                  fnd_lookup_values_vl.meaning%type;
    l_freight_invoice_interface     NUMBER := 0;
    l_sum_invoice_weight            NUMBER;
    l_freight_invoice_weight        NUMBER;
    --
    l_business_vendor_id            NUMBER;
    --
    l_validation_rule_serie         VARCHAR2(80);
    l_validation_rule_subserie      VARCHAR2(80);
    l_validation_rule_icms_type     VARCHAR2(80);
    l_validation_rule_fisc_doc_mod  VARCHAR2(80);
    --
    l_qtd_invoices                  NUMBER;
    l_qtd_invoices_tmp              NUMBER;
    l_invoice_num_dec               NUMBER;
    l_max_invoice_num               NUMBER;
    --
    l_efd_type                      cll_f189_fiscal_document_types.efd_type%type;
    l_invoice_key_required_flag     cll_f189_fiscal_document_types.invoice_key_required_flag%type;
    l_invoice_key_validation_flag   cll_f189_fiscal_document_types.invoice_key_validation_flag%type;
    l_invoice_number_length_flag    cll_f189_fiscal_document_types.invoice_number_length_flag%type;
    --
    l_invoice_parent_id             NUMBER;
    l_inv_period_name               VARCHAR2(15);
    l_tax_rural_period              VARCHAR2(80);
    l_tax_period                    VARCHAR2(80);
    l_city_calendar                 NUMBER;
    l_tax_bureau_site_id            NUMBER;
    l_error_code_iss_entities       VARCHAR2(50);
    l_error_code_iss                VARCHAR2(50);
    l_verify_supplier_site          NUMBER;
    --
    l_dmf                           NUMBER;
    l_ddm                           NUMBER;
    l_dd                            NUMBER;
    l_dcd                           NUMBER;
    --
    l_contract_id                   NUMBER;
    l_retencao_faturado             NUMBER := 0;
    l_retencao_nf                   NUMBER := 0;
    --
    l_ir_vendor                     VARCHAR2(80);
    l_ir_categ                      VARCHAR2(80);
    l_import_document_type          VARCHAR2(80);
    l_process_origin                VARCHAR2(80);
    l_worker_category               NUMBER;   -- ER 17551029 5a Fase
    l_esocial_period_code           cll_f407_entity_profiles.start_period_code%TYPE := NULL; -- 27357141
    --
    l_loader_exist                  NUMBER; -- ER 14124731
    l_line_iss_tax_type             cll_f189_cities.iss_tax_type%TYPE; -- 25028715
    --
    l_tpa_return_type               NUMBER; -- 30211420
    --
    l_manual_return_num_type        cll_f189_parameters.manual_return_num_type%TYPE; -- ER 29908009
    --
  BEGIN
    print_log('  CREATE_OPEN_HEADER');
    print_log('  p_parent_flag      :'||p_parent_flag);
    print_log('  p_invoice_parent_id:'||p_invoice_parent_id);
    -----------------------------------------------------
    -- Recuperando dados dos Parametros da Organizacao --
    -----------------------------------------------------
    --
    l_error      := NULL;
    l_error_code := NULL;
    --
    CLL_F189_OPEN_VALIDATE_PUB.GET_PARAMETERS (
      p_organization_id            => p_organization_id
      -- out
      ,p_allow_upd_price_flag       => p_allow_upd_price_flag
      ,p_rcv_tolerance_perc_amount  => p_rcv_tolerance_perc_amount
      ,p_rcv_tolerance_code         => p_rcv_tolerance_code
      ,p_inss_aut_max_retention     => l_inss_aut_max_retention
      ,p_rounding_precision         => p_rounding_precision
      ,p_fed_withholding_tax_flag   => l_fed_withholding_tax_flag
      ,p_gl_date_diff_from_sysdate  => l_gl_date_diff_from_sysdate
      ,p_rec_date_diff_from_sysdate => l_rec_date_diff_from_sysdate
      ,p_pis_amount_recover_cnpj    => p_pis_amount_recover_cnpj
      ,p_cofins_amount_recover_cnpj => p_cofins_amount_recover_cnpj
      ,p_invoice_date_less_than     => l_invoice_date_less_than -- Bug 10367485
      ,p_manual_return_num_type     => l_manual_return_num_type -- ER 29908009
      ,p_error_code                 => l_error
    );
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    --
    IF l_error = 'NO_DATA_FOUND' THEN
      l_error_code := 'NONE PARAMETERS';
    ELSIF l_error = 'TOO_MANY_ROWS' THEN
      l_error_code := 'DUPLICATED PARAMETERS';
    ELSIF l_error = 'OTHERS' THEN
      l_error_code := 'INVALID PARAMETERS';
    END IF;
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF l_error IS NOT NULL THEN
      IF p_open_source = 'RI' THEN
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => l_error_code
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => 'ID = '||p_organization_id
        );
        p_process_flag       := 2; -- Processing
        --
      END IF; --IF p_open_source = 'RI' THEN
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    -------------------------------
    -- Recuperando dados do IRRF do Agente Arrecadador --
    -------------------------------
    --
    l_error      := NULL;
    l_error_code := NULL;
    --
    CLL_F189_OPEN_VALIDATE_PUB.GET_TAX_SITES (
      p_organization_id           => p_organization_id
      ,p_tax_type                  => 'IRRF'
      -- out
      ,p_minimum_tax_amount        => p_minimum_tax_amount
      ,p_cumulative_threshold_type => p_cumulative_threshold_type
      ,p_error_code                => l_error
    );
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --17;
    --
    IF l_error = 'NO_DATA_FOUND' THEN
      l_error_code := 'NONE IRRF';
    ELSIF l_error = 'TOO_MANY_ROWS' THEN
      l_error_code := 'DUPLICATED IRRF';
    ELSIF l_error = 'OTHERS' THEN
      l_error_code := 'INVALID IRRF';
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF l_error IS NOT NULL THEN
      IF p_open_source = 'RI' THEN
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => l_error_code
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => 'ID = '||p_organization_id
        );
        --
        p_process_flag       := 2; -- Processing
        --
      END IF; --IF p_open_source = 'RI' THEN
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --18;
    --
    ---------------------------------------------
    -- Validando data GL e data do Recebimento --
    ---------------------------------------------
    --
    IF l_gl_date_diff_from_sysdate = 'N' THEN
      IF p_gl_date <> trunc(SYSDATE) THEN
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => 'GL DATE DIFF SYSDATE'
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => p_gl_date
        );
      END IF;
    END IF;
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF l_gl_date_diff_from_sysdate = 'Y' THEN
      IF p_gl_date > trunc(SYSDATE) THEN
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => 'GL AFTER DATE'
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => p_gl_date
        );
      END IF;
    END IF;
    -- 29559606 - End
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF l_rec_date_diff_from_sysdate = 'N' THEN
      IF p_receive_date <> trunc(SYSDATE) THEN
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => 'RECEIPT DATE DIFF SYSDATE'
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => p_receive_date
        );
      END IF;
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    -- 29559606 - Start
    IF l_rec_date_diff_from_sysdate = 'Y' THEN
      IF p_receive_date > trunc(SYSDATE) THEN
          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                   ,p_interface_operation_id => p_interface_operation_id
                   ,p_organization_id        => p_organization_id
                   ,p_error_code             => 'REC AFTER DATE'
                   ,p_invoice_line_id        => 0
                   ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                   ,p_invalid_value          => p_receive_date
                   );
      END IF;
    END IF;
    -- 29559606 - End
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --19;
    --
    -- Bug 10367485 - Start
    ---------------------------------------------
    -- Validando Data de Emissao retroativa    --
    ---------------------------------------------
    --
    l_invoice_days := to_number(trunc(trunc(SYSDATE) - p_invoice_date));
    --
    IF l_invoice_date_less_than < l_invoice_days THEN
       ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'INVOICE DATE LESS THAN'
                ,p_invoice_line_id        => 0
                ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => p_invoice_date
                   );
    END IF;
    -- Bug 10367485 - End
    ----------------------------------
    -- Validando os valores do INSS --
    ----------------------------------
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    CLL_F189_OPEN_VALIDATE_PUB.GET_COMPANY_INFOS (p_entity_id                 => p_entity_id
                                                  -- out
                                                 ,p_inss_additional_tax_1     => l_inss_additional_tax_1_ci
                                                 ,p_inss_additional_tax_2     => l_inss_additional_tax_2_ci
                                                 ,p_inss_additional_tax_3     => l_inss_additional_tax_3_ci
                                                 ,p_inss_substitute_flag      => l_inss_substitute_flag_ci
                                                 ,p_inss_tax                  => l_inss_tax_ci
                                                 ,p_funrural_contributor_flag => p_funrural_contributor_flag --l_funrural_contributor_flag_ci
                                                 );
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --19;
    --
    IF NVL(l_fed_withholding_tax_flag,'C') = 'I' THEN -- Invoice Type
        l_inss_substitute_flag_calc  := p_inss_substitute_flag;
    ELSE  -- Company Infos
        l_inss_substitute_flag_calc  := l_inss_substitute_flag_ci;
    END IF; --IF NVL(l_fed_withholding_tax_flag,'C') = 'I' THEN
    --
    IF NVL(p_inss_additional_base_1,0) <> 0 AND NVL(l_inss_additional_tax_1_calc,0) <> 0 THEN
        p_inss_additional_amount_1_out := ((p_inss_additional_base_1 * l_inss_additional_tax_1_calc) / 100);
    ELSE
        p_inss_additional_amount_1_out := NULL;
    END IF;
    --
    IF NVL(p_inss_additional_base_2,0) <> 0 AND NVL(l_inss_additional_tax_2_calc,0) <> 0 THEN
        p_inss_additional_amount_2_out := ((p_inss_additional_base_2 * l_inss_additional_tax_2_calc) / 100);
    ELSE
        p_inss_additional_amount_2_out := NULL;
    END IF;
    --
    IF NVL(p_inss_additional_base_3,0) <> 0 AND NVL(l_inss_additional_tax_3_calc,0) <> 0 THEN
        p_inss_additional_amount_3_out := ((p_inss_additional_base_3 * l_inss_additional_tax_3_calc) / 100);
    ELSE
        p_inss_additional_amount_3_out := NULL;
    END IF;
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --20;
    --
    -------------------------------------------
    -- Validando a Organizacao de Inventario --
    -------------------------------------------
    --
    print_log('  Validando Organização de Invetario(organization_id/location_id)');
    print_log('  '||p_organization_id||'/'||p_location_id);
    l_inventory_organization_id := CLL_F189_OPEN_VALIDATE_PUB.GET_INVENTORY_ORGANIZATION (
      p_organization_id  => p_organization_id
      ,p_location_id     => p_location_id
    );
    
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --21;
    --
    IF l_inventory_organization_id IS NULL THEN
      
      ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => 'INVALID INV_ORG' --'INVALID LOCATION'
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => 'ORGANIZATION_ID = '||p_organization_id||' - LOCATION_ID = '||p_location_id
      );
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    --------------------------------------------------------
    -- Validando as quantidades de notas por operation_id --
    --------------------------------------------------------
    BEGIN
      SELECT COUNT(1)
        INTO l_soma_operation
        FROM cll_f189_invoice_iface_tmp
       WHERE interface_operation_id = p_interface_operation_id
         AND organization_id        = p_organization_id;
    EXCEPTION
        WHEN OTHERS THEN
            l_soma_operation := 0;
    END;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF l_soma_operation <> p_soma_source THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'DIFFERENT SOURCE'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSIF l_soma_operation <> p_soma_freight_flag THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'DIFFERENT FREIGHT_FLAG'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSIF l_soma_operation <> p_soma_gl_date THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'DIFFERENT GL_DATE'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSIF l_soma_operation <> p_soma_org_id THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
       ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'DIFFERENT ORGANIZATION'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSIF l_soma_operation <> p_soma_location THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'DIFFERENT LOCATION'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSIF l_soma_operation <> p_soma_inv_type THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'DIFFERENT INVOICE_TYPE'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    END IF; --IF l_soma_operation <> r_invoice_header.soma_source THEN
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --22;
    --
    ---------------------------------------------
    -- Validando campos obrigatorios do header --
    ---------------------------------------------
    IF p_interface_invoice_id IS NULL THEN
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'INTERFACE INVID NULL'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF p_invoice_num IS NULL THEN
       l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
       IF NOT (p_return_customer_flag = 'F' and l_manual_return_num_type = 'A') THEN -- ER 29908009
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
          ADD_ERROR(
            p_invoice_id             => p_interface_invoice_id
           ,p_interface_operation_id => p_interface_operation_id
           ,p_organization_id        => p_organization_id
           ,p_error_code             => 'NULL INVOICENUM'
           ,p_invoice_line_id        => 0
           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
           ,p_invalid_value          => NULL
          );
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
       END IF; -- ER 29908009
       l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF p_interface_operation_id IS NULL THEN
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'INTERFACE OPERID NULL'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    END IF;
    --
    -- Bug 17334912 - start
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF p_receive_date IS NULL THEN
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'NULL RECEIVE DATE'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --23;
    --
    -- Bug 17334912 - end
    --
    IF p_invoice_amount IS NULL THEN
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'NULL INVAMOUNT'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSIF p_invoice_amount <= 0 AND NVL(p_utilities_flag,'N') = 'N' AND NVL(p_tax_adjust_flag,'N') <> 'Y' THEN -- 22462893
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'INVALID INVAMOUNT'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => p_invoice_amount
                 );
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF p_gross_total_amount IS NULL THEN
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'NULL GROSSAMOUNT'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSIF p_gross_total_amount <= 0 AND NVL(p_utilities_flag,'N') = 'N' AND NVL(p_tax_adjust_flag,'N') <> 'Y' THEN -- 22462893
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'INVALID GROSSAMOUNT'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => p_gross_total_amount
                 );
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF p_invoice_date IS NULL THEN
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'NULL INVDATE'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSIF TRUNC(p_invoice_date) > TRUNC(SYSDATE) OR TRUNC(p_invoice_date) > TRUNC(p_gl_date)  THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'INVALID INVDATE'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => p_invoice_date
                 );
    END IF;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF p_simplified_br_tax_flag = 'Y' THEN
        IF nvl(p_icms_base,0) > 0 THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                   --,p_error_code             => 'ICMS CALC BASIS NOT NULL' -- 20464126
                     ,p_error_code             => 'ICMS BASE TO SN NOT ALLOWED' -- 20464126
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_base
                     );
        END IF ;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        IF NVL(p_icms_amount,0) > 0 THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                   --,p_error_code             => 'ICMS AMOUNT NOT NULL'       -- 20464126
                     ,p_error_code             => 'ICMS AMT TO SN NOT ALLOWED' -- 20464126
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_amount
                     );
        END IF;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        -- 20464126 - Start
        IF NVL(p_ipi_amount,0) > 0 THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'IPI AMT TO SN NOT ALLOWED'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_ipi_amount
                     );
        END IF;
        -- 20464126 - End
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    ELSE
        IF NVL(p_max_icms_amount_recover,0) > 0 THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'MAX ICMS REC AMT NOT NULL'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_max_icms_amount_recover
                     );
        END IF;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        IF nvl(p_icms_tax_rec_simpl_br,0) > 0 THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'ICMS REC RATE NOT NULL'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_tax_rec_simpl_br
                     );
        END IF;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        IF p_icms_base IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NULL ICMSBASE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => NULL
                     );
        ELSIF p_icms_type = 'NORMAL' AND p_icms_base < 0 THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID ICMSBASE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_base
                     );
        ELSIF p_icms_type = 'NOT APPLIED' AND p_icms_base <> 0 THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID ICMSBASE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_base
                     );
        -- 20463626 - Start
        ELSIF p_icms_type = 'EXEMPT' AND p_icms_base <> 0 THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'ICMS TYPE EXEMPT'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_base
                     );
        -- 20463626 - End
        END IF;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        IF p_icms_amount IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NULL ICMSAMT'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => NULL
                     );
        ELSIF p_icms_type = 'NORMAL' AND p_icms_amount < 0 THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID ICMSAMT'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_amount
                     );
        ELSIF p_icms_type = 'NOT APPLIED' AND p_icms_amount <> 0 THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID ICMSAMTNOT' --'INVALID ICMSAMT'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_amount
                     );
        -- 20463626 - Start
        ELSIF p_icms_type = 'EXEMPT' AND p_icms_amount <> 0 THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'ICMS TYPE EXEMPT'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_icms_amount
                     );
        -- 20463626 - End
        END IF;
    END IF; -- IF r_invoice_header.simplified_br_tax_flag = 'Y' THEN
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --24;
    --
-- 27579747 - Start
--  IF g_source <> 'CLL_F369 EFD LOADER' THEN -- BUG 21909282
    IF g_source NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
      IF p_ipi_amount IS NULL THEN
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                   ,p_interface_operation_id => p_interface_operation_id
                   ,p_organization_id        => p_organization_id
                   ,p_error_code             => 'NULL IPIAMT'
                   ,p_invoice_line_id        => 0
                   ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                   ,p_invalid_value          => NULL
                   );
      ELSIF p_ipi_amount < 0 THEN
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                   ,p_interface_operation_id => p_interface_operation_id
                   ,p_organization_id        => p_organization_id
                   ,p_error_code             => 'INVALID IPIAMT'
                   ,p_invoice_line_id        => 0
                   ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                   ,p_invalid_value          => p_ipi_amount
                   );
      END IF;
    END IF; -- BUG 21909282
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --24;
    --
    -------------------------------
    -- Validando o Periodo no GL --
    -------------------------------
    l_gl_periods := CLL_F189_OPEN_VALIDATE_PUB.GET_GL_PERIODS (p_set_of_books_id => p_set_of_books_id
                                                              ,p_gl_date         => p_gl_date
                                                              );
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --25;
    --
    IF NVL(p_payment_flag, 'N') = 'Y' THEN
        IF l_gl_periods IS NULL THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID AP_DATE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => NULL
                     );
        END IF;
    END IF;
    --
    --------------------------------
    -- Validando valores do frete --
    --------------------------------
    l_lookup_frete := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES (p_lookup_type => 'CLL_F189_CIF_FOB_FREIGHT'
                                                            ,p_lookup_code => p_freight_flag
                                                            );
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --26;
    --
    IF l_lookup_frete IS NULL THEN
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'INVALID FREIGHT_FLAG'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => 'INVOICE TYPE ID = '||p_invoice_type_id
                 );
    ELSE
        --
        --------------------------------------------
        -- Validando informacoes do frete na nota --
        --------------------------------------------
        IF p_freight_flag = 'F' THEN
            --
            -- Verifica se tem nota de frete informada na tabela temporaria para o operation_id
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            BEGIN
              SELECT count(*)
                INTO l_freight_invoice_interface
                FROM /*cll_f189_freight_inv_iface_tmp*/
                    cll_f189_freight_inv_interface
               WHERE interface_operation_id = p_interface_operation_id
                 AND organization_id        = p_organization_id;
            EXCEPTION
                WHEN OTHERS THEN
                    l_freight_invoice_interface := 0;
            END;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            IF l_freight_invoice_interface = 0 THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'REQUIRED FREIGHT INVOICE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            IF NVL(p_total_freight_weight,0) = 0 THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL FREIGHT WEIGHT' --'INVALID OPFREIGHT WEIGHT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
                -- Soma o peso do frete informado na nota
                --
                BEGIN
                  SELECT SUM(invoice_weight)
                    INTO l_sum_invoice_weight
                    FROM cll_f189_invoices_interface
                   WHERE interface_operation_id = p_interface_operation_id
                     AND organization_id        = p_organization_id;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_sum_invoice_weight := 0;
                END;
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
                IF l_sum_invoice_weight <> p_total_freight_weight THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INVOICE WEIGHT ERROR'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_total_freight_weight
                             );
                END IF;
                --
                -- Verifica se a nota de frete tem o mesmo peso informado na nota
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
                BEGIN
                  SELECT count(*)
                    INTO l_freight_invoice_weight
                    FROM cll_f189_freight_inv_interface
                   WHERE interface_operation_id = p_interface_operation_id
                     AND organization_id        = p_organization_id
                     AND total_freight_weight   = p_total_freight_weight;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_freight_invoice_weight := 0;
                END;
                --
                IF l_freight_invoice_weight = 0 THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'FREIGHT WEIGHT ERROR'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 --3
                             ,p_invalid_value          => p_total_freight_weight
                             );
                END IF;
            END IF; --IF NVL(r_invoice_header.total_freight_weight,0) = 0 THEN
        ELSE --IF r_invoice_header.freight_flag = 'F' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            IF p_total_freight_weight IS NOT NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'FREIGHT WEIGHT FND' --'INVALID OPFREIGHT WEIGHT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_total_freight_weight
                         );
            END IF;
        END IF; -- IF r_invoice_header.freight_flag = 'F' THEN
    END IF; --IF l_lookup_frete IS NULL THEN
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --27;
    -------------------------------
    -- Validando Entidade Fiscal --
    -------------------------------
    IF p_requisition_type <> 'RM' THEN
        --
        -- Suppliers
        --
        p_entity_id_out      := NULL;
        p_document_type_out  := NULL;
        l_business_vendor_id := NULL;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        CLL_F189_OPEN_VALIDATE_PUB.GET_FISCAL_ENTITIES (p_operating_unit     => p_operating_unit
                                                       ,p_entity_id          => p_entity_id
                                                       ,p_document_type      => p_document_type
                                                       ,p_document_number    => p_document_number
                                                       ,p_ie                 => p_ie
                                                       -- out
                                                       ,p_entity_id_out      => p_entity_id_out
                                                       ,p_vendor_id          => p_vendor_id
                                                       ,p_document_type_out  => p_document_type_out
                                                       ,p_business_vendor_id => l_business_vendor_id
                                                       );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --28;
    ELSE --IF l_requisition_type <> 'RM' THEN
        --
        -- Customers
        --
        p_entity_id_out      := NULL;
        p_document_type_out  := NULL;
        l_business_vendor_id := NULL;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        CLL_F189_OPEN_VALIDATE_PUB.GET_CUSTOMERS (p_operating_unit     => p_operating_unit
                                                 ,p_entity_id          => p_entity_id
                                                 ,p_document_type      => p_document_type
                                                 ,p_document_number    => p_document_number
                                                 ,p_ie                 => p_ie
                                                 -- out
                                                 ,p_entity_id_out      => p_entity_id_out
                                                 ,p_document_type_out  => p_document_type_out
                                                 ,p_business_vendor_id => l_business_vendor_id
                                                 );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --29;
    END IF; --IF l_requisition_type <> 'RM' THEN
    --
    IF p_entity_id IS NULL AND (p_document_type IS NULL OR p_document_number IS NULL) THEN -- Supplier nao esta preenchido na Open
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'NULL VENDOR SITE'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => NULL
                 );
    ELSE
        IF p_entity_id_out IS NOT NULL THEN -- encontrou setup para as informacoes da open
            IF p_document_type IS NOT NULL AND p_document_number IS NOT NULL AND p_entity_id IS NULL THEN -- valida as informacoes na Open
                 l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
                 --Atualiza o ID na tabela temporaria
                 --
                 UPDATE cll_f189_invoice_iface_tmp
                    SET entity_id              = p_entity_id_out
                  WHERE interface_invoice_id   = p_interface_invoice_id
                    AND interface_operation_id = p_interface_operation_id
                    AND organization_id        = p_organization_id
                    AND source                 = p_source;
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --30;
            END IF;
            --
        ELSE -- nao encontrou setup para as informacoes da open
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            IF p_requisition_type <> 'RM' THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID VENDOR SITE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_entity_id
                         );
            ELSE
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID CUSTOMER SITE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_entity_id
                         );
            END IF; --IF l_requisition_type <> 'RM' THEN
        END IF; --IF l_entity_id_out NOT IS NULL THEN
    END IF; --IF r_invoice_header.entity_id IS NULL AND (r_invoice_header.document_type IS NULL OR r_invoice_header.document_number IS NULL) THEN
    --
    -----------------------
    -- Validando a serie --
    -----------------------
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    IF p_series IS NULL THEN
        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'NULL INVSERIES'
                 ,p_invoice_line_id        => 0
                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => p_entity_id
                 );
    ELSE
      print_log('  Invoice_Type_Id:'||p_invoice_type_id);
        l_validation_rule_serie := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_INVOICE_SERIES'
                                                                                         ,p_code            => p_series
                                                                                         ,p_invoice_type_id => p_invoice_type_id
                                                                                         ,p_validity_type   => 'INVOICE SERIES'
                                                                                         );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --31;
        --
        IF l_validation_rule_serie IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID INVSERIES'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_series
                     );
        END IF;
    END IF;
    --
    ---------------------------
    -- Validando a sub-serie --
    ---------------------------
    IF p_subseries IS NOT NULL THEN
        l_validation_rule_subserie := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_INVOICE_SUBSERIES'
                                                                                            ,p_code            => p_subseries
                                                                                            ,p_invoice_type_id => p_invoice_type_id
                                                                                            ,p_validity_type   => 'INVOICE SUBSERIES'
                                                                                            );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --32;
        --
        IF l_validation_rule_subserie IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID INVSUBSERIES'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_subseries
                     );
        END IF;
    END IF;
    --
    -----------------------------------
    -- Validando duplicidade da nota --
    -----------------------------------
    -- Recuperando quantidade da nota na tabela temporaria
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
    BEGIN
        SELECT COUNT(*)
         INTO l_qtd_invoices_tmp
         FROM cll_f189_invoice_iface_tmp
        WHERE entity_id           = NVL(p_entity_id_out,p_entity_id)
          AND series              = p_series
          AND invoice_num         = p_invoice_num
          AND ( (l_validate_flag = 'Y' AND trunc(invoice_date) = trunc(p_invoice_date))
             OR (l_validate_flag = 'N')
              );
    EXCEPTION
        WHEN OTHERS THEN
            l_qtd_invoices_tmp := 0;
    END;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --33;
    --
    -- Recuperando decimal no numero da nota na open
    --
    BEGIN
        SELECT DECODE ((invoice_num * 100) - (TRUNC (invoice_num) * 100)
                       ,0
                       ,0
                       ,1
                      )       invoice_num_dec
          INTO l_invoice_num_dec
          FROM cll_f189_invoice_iface_tmp
         WHERE entity_id           = NVL(p_entity_id_out,p_entity_id)
           AND series              = p_series
           AND invoice_num         = p_invoice_num
           AND ( (l_validate_flag = 'Y' AND trunc(invoice_date) = trunc(p_invoice_date))
              OR (l_validate_flag = 'N')
              );
    EXCEPTION
        WHEN OTHERS THEN
            l_invoice_num_dec := 0;
    END;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --34;
    --
    -- Iniciando validacoes
    --
    IF l_validate_flag = 'Y' THEN -- considera a data de emissao
        --
        -- Busca qtde na tabela final do RI
        --
        l_qtd_invoices := CLL_F189_OPEN_VALIDATE_PUB.GET_QTY_INVOICES (p_entity_id    => NVL(p_entity_id_out,p_entity_id)
                                                                      ,p_series       => p_series
                                                                      ,p_invoice_num  => p_invoice_num
                                                                      ,p_invoice_date => p_invoice_date
                                                                      );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --35;
        --
        IF (l_qtd_invoices > 0 ) OR (l_qtd_invoices_tmp > 1 ) THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'DUPLICATED INVOICE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_invoice_num
                     );
        ELSE
            --
            -- Validando numero da nota revertida - com decimal
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16;
            IF l_invoice_num_dec = 1 THEN -- Encontrou nota com numero decimal informado na open
                --
                -- Recupera o maior valor da nota no RI
                --
                l_max_invoice_num := CLL_F189_OPEN_VALIDATE_PUB.GET_MAX_INVOICE_NUM (p_entity_id     => NVL(p_entity_id_out,p_entity_id)
                                                                                    ,p_series        => p_series
                                                                                    ,p_invoice_num   => p_invoice_num
                                                                                    ,p_invoice_date  => p_invoice_date
                                                                                    ,p_validate_flag => l_validate_flag
                                                                                    );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --36;
                --
                -- Valida se o numero que esta na Open e maior que o maior numero existente no RI
                --
                IF p_invoice_num <= l_max_invoice_num THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'DUPLICATED INVOICE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'OPEN = '||p_invoice_num||'RI = '||l_max_invoice_num
                             );
                END IF;
            END IF; --IF l_invoice_num_dec = 1 THEN
        END IF; --IF (l_qtd_invoices > 0 ) OR (l_qtd_invoices_tmp > 1 ) THEN
    ELSE --IF l_validate_flag = 'Y' THEN
        --
        -- Busca qtde na tabela final do RI
        --
        l_qtd_invoices := CLL_F189_OPEN_VALIDATE_PUB.GET_QTY_INVOICES (p_entity_id    => NVL(p_entity_id_out,p_entity_id)
                                                                      ,p_series       => p_series
                                                                      ,p_invoice_num  => p_invoice_num
                                                                      ,p_invoice_date => NULL
                                                                      );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --37;
        --
        print_log('  Busca qtde na tabela final do RI(invoice_num/serie/entity_id) :'||p_invoice_num||'/'||p_series||'/'||NVL(p_entity_id_out,p_entity_id));
        print_log('  l_qtd_invoices    :'||l_qtd_invoices);
        print_log('  l_qtd_invoices_tmp:'||l_qtd_invoices_tmp);
        IF (l_qtd_invoices > 0 ) OR (l_qtd_invoices_tmp > 1 ) THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'DUPLICATED INVOICE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_invoice_num
                     );
        ELSE
            --
            -- Validando numero da nota revertida - com decimal
            --
            IF l_invoice_num_dec = 1 THEN -- Encontrou nota com numero decimal informado na open
                --
                -- Recupera o maior valor da nota no RI
                --
                l_max_invoice_num := CLL_F189_OPEN_VALIDATE_PUB.GET_MAX_INVOICE_NUM (p_entity_id     => NVL(p_entity_id_out,p_entity_id)
                                                                                    ,p_series        => p_series
                                                                                    ,p_invoice_num   => p_invoice_num
                                                                                    ,p_invoice_date  => NULL
                                                                                    ,p_validate_flag => 'N'
                                                                                    );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --38;
                --
                -- Valida se o numero que esta na Open e maior que o maior numero existente no RI
                --
                IF p_invoice_num <= l_max_invoice_num THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'DUPLICATED INVOICE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'OPEN = '||p_invoice_num||'RI = '||l_max_invoice_num
                             );
                END IF;
            END IF; --IF l_invoice_num_dec = 1 THEN
        END IF; --IF (l_qtd_invoices > 0 ) OR (l_qtd_invoices_tmp > 1 ) THEN
    END IF;
    --
    ---------------------------------------------------
    -- Validando se possui linhas informadas na open --
    ---------------------------------------------------
    BEGIN
        SELECT COUNT(*)
         INTO p_qtd_lines_tmp
         FROM cll_f189_inv_line_iface_tmp rii
        WHERE interface_invoice_id = p_interface_invoice_id;
    EXCEPTION
        WHEN OTHERS THEN
            p_qtd_lines_tmp := 0;
    END;
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --39;
    --
    IF NVL(p_qtd_lines_tmp,0) = 0 THEN
      IF ( NVL(g_generate_line_compl,'N') = 'N'  OR (NVL(p_cost_adjust_flag ,'N') = 'Y') ) AND p_return_customer_flag <> 'F' THEN    -- 29908009
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => 'NONE INVOICE LINE'
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => NULL
        );
      ELSIF NVL(g_generate_line_compl,'N') = 'Y' THEN
            --
            -- Verificando se o parametro esta informado para validar o fornecedor antes de gerar nota complementar
            --
            IF p_vendor_id IS NULL THEN
                IF p_requisition_type <> 'RM' THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id --r_invoice_header.interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id --r_invoice_header.interface_operation_id
                             ,p_organization_id        => p_organization_id --NVL(l_organization_id,r_invoice_header.organization_id)
                             ,p_error_code             => 'INVALID VENDOR SITE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'ENTITY_ID = '||NVL(p_entity_id_out,p_entity_id) --NVL(r_invoice_header.entity_id, l_entity_id_out)
                             );
                ELSE
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id --r_invoice_header.interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id --r_invoice_header.interface_operation_id
                             ,p_organization_id        => p_organization_id --NVL(l_organization_id,r_invoice_header.organization_id)
                             ,p_error_code             => 'INVALID CUSTOMER SITE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'ENTITY_ID = '||NVL(p_entity_id_out,p_entity_id) --NVL(r_invoice_header.entity_id, l_entity_id_out)
                             );
                END IF;
            END IF; --IF l_vendor_id IS NULL THEN
        END IF; --IF g_generate_line_compl = 'N' THEN
    END IF; --IF NVL(l_qtd_lines_tmp,0) = 0 THEN
    --
    ------------------------------------------
    -- Validando setup do tipo de documento --
    ------------------------------------------
    --
    print_log('');
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
    print_log('  Validando setup do tipo de documento');
    print_log('  p_fiscal_document_model:'||p_fiscal_document_model);
    CLL_F189_FISCAL_DOC_TYPE_PKG.GET_FISCAL_DOC_TYPE_SETUP(
      p_fiscal_document_type_code    => UPPER(p_fiscal_document_model)
      -- out
      ,p_efd_type                    => l_efd_type
      ,p_invoice_key_required_flag   => l_invoice_key_required_flag
      ,p_invoice_key_validation_flag => l_invoice_key_validation_flag
      ,p_invoice_number_length_flag  => l_invoice_number_length_flag
    );
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
    print_log('  l_efd_type                   :'||l_efd_type);
    print_log('  l_invoice_key_required_flag  :'||l_invoice_key_required_flag);
    print_log('  l_invoice_key_validation_flag:'||l_invoice_key_validation_flag);
    print_log('  l_invoice_number_length_flag :'||l_invoice_number_length_flag);
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
    --
    IF NVL(l_invoice_key_required_flag,'N') = 'Y' THEN
      IF p_eletronic_invoice_key IS NULL THEN
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
         ,p_interface_operation_id => p_interface_operation_id
         ,p_organization_id        => p_organization_id
         ,p_error_code             => 'NONE INVOICE KEY'
         ,p_invoice_line_id        => 0
         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
         ,p_invalid_value          => NULL
        );
      END IF;
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
      --
      IF l_efd_type = 'CTE' THEN
        IF p_cte_type IS NULL THEN
          ADD_ERROR(
            p_invoice_id             => p_interface_invoice_id
            ,p_interface_operation_id => p_interface_operation_id
            ,p_organization_id        => p_organization_id
            ,p_error_code             => 'CTE TYPE REQUIRED'
            ,p_invoice_line_id        => 0
            ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
            ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
          );
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
        END IF;
      ELSE
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
        IF l_efd_type IN ('NFSE','NFE') THEN
            IF p_cte_type IS NOT NULL THEN
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'CTE TYPE NOT NULL'
                ,p_invoice_line_id        => 0
                ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
              );
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
            END IF;
        END IF;
      END IF; -- IF l_efd_type = 'CTE' THEN
    ELSE --IF NVL(l_invoice_key_required_flag,'N') = 'Y' THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
      IF l_efd_type IN ('NFSE','NFE') OR l_efd_type IS NULL THEN
        IF p_cte_type IS NOT NULL THEN
          ADD_ERROR(
            p_invoice_id             => p_interface_invoice_id
            ,p_interface_operation_id => p_interface_operation_id
            ,p_organization_id        => p_organization_id
            ,p_error_code             => 'CTE TYPE NOT NULL'
            ,p_invoice_line_id        => 0
            ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
            ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
          );
        ELSIF p_eletronic_invoice_key IS NOT NULL THEN
          ADD_ERROR(
            p_invoice_id             => p_interface_invoice_id
            ,p_interface_operation_id => p_interface_operation_id
            ,p_organization_id        => p_organization_id
            ,p_error_code             => 'INVOICE KEY NOT NULL'
            ,p_invoice_line_id        => 0
            ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
            ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
          );
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --40;
        END IF;
      END IF;  --IF l_efd_type IN ('NFSE','NFE') OR l_efd_type IS NULL THEN
    END IF ; --IF NVL(l_invoice_key_required_flag,'N') = 'Y' THEN
    --
    -- ER 14124731 - Start
    -- 27579747 - Start
    -- IF g_source = 'CLL_F369 EFD LOADER' THEN
    IF g_source IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
    -- 27579747 - End
      BEGIN
        --
        SELECT COUNT(1)
          INTO l_loader_exist
          FROM cll_f369_efd_headers
         WHERE access_key_number = p_eletronic_invoice_key ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_loader_exist := 0;
      END ;
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --41 ;
      --
      IF NVL(l_loader_exist,0) = 0 THEN
        ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                  , p_interface_operation_id => p_interface_operation_id
                  , p_organization_id        => p_organization_id
                  , p_error_code             => 'DOC NOT LOADER'
                  , p_invoice_line_id        => 0
                  , p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                  , p_invalid_value          => p_eletronic_invoice_key
                  ) ;
      END IF ;
      --
    END IF;
    -- ER 14124731 - End
    ------------------------
    -- Validando nota pai --
    ------------------------
    --
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro); 
    print_log('  Validando nota Pai');
    print_log('  Invoice_parent_id:'||p_invoice_parent_id);
    print_log('  p_parent_flag          = '||p_parent_flag);
    print_log('  p_cost_adjust_flag     = '||p_cost_adjust_flag);
    print_log('  p_price_adjust_flag    = '||p_price_adjust_flag);
    print_log('  p_tax_adjust_flag      = '||p_tax_adjust_flag);
    print_log('  p_return_customer_flag = '||p_return_customer_flag);
    print_log('  p_fixed_assets_flag    = '||p_fixed_assets_flag);
    IF p_invoice_parent_id IS NOT NULL THEN
      IF p_parent_flag = 'Y' AND p_cost_adjust_flag = 'N' AND p_price_adjust_flag = 'N' AND p_tax_adjust_flag = 'N' AND p_return_customer_flag <> 'F' AND p_fixed_assets_flag NOT IN ('S', 'O') THEN
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro); 
        -- Verify if invoice choosen is on the table cll_f189_invoices
        l_invoice_parent_id := CLL_F189_OPEN_VALIDATE_PUB.GET_INVOICE_PARENTS (
          p_entity_id         => p_entity_id         -- Bug 18468814
          ,p_invoice_parent_id => p_invoice_parent_id -- Bug 18468814
        );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --42;
        --
        IF l_invoice_parent_id IS NULL THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro); 
          ADD_ERROR(
            p_invoice_id             => p_interface_invoice_id
            ,p_interface_operation_id => p_interface_operation_id
            ,p_organization_id        => p_organization_id
            ,p_error_code             => 'INVOICE NOT PARENT'
            ,p_invoice_line_id        => 0
            ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
            ,p_invalid_value          => NULL
          );
        END IF;
      ELSE
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro); 
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => 'COMPL INV TYPE INVALID'
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
        );
      END IF;
    ELSE
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro); 
      IF p_parent_flag = 'Y' AND p_cost_adjust_flag = 'N' AND p_price_adjust_flag = 'N' AND p_tax_adjust_flag = 'N' AND p_return_customer_flag <> 'F' AND p_fixed_assets_flag NOT IN ('S', 'O') THEN
        ADD_ERROR(
          p_invoice_id             => p_interface_invoice_id
          ,p_interface_operation_id => p_interface_operation_id
          ,p_organization_id        => p_organization_id
          ,p_error_code             => 'COMPL PARENT ID NULL'
          ,p_invoice_line_id        => 0
          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
          ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
        );
      END IF;
    END IF;

    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --43;
        --
        ----------------------------------------------------------------
        -- Validando se tem nota complementar nas tabelas temporarias --
        ----------------------------------------------------------------
        print_log('  Validando se tem nota complementar nas tabelas temporarias');
        BEGIN
            SELECT COUNT(1)
              INTO p_qtde_nf_compl
              FROM cll_f189_inv_parent_iface_tmp
             WHERE interface_invoice_id = p_interface_invoice_id;
        EXCEPTION
            WHEN OTHERS THEN
                p_qtde_nf_compl := 0;
        END;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --44;
        --
        IF p_parent_flag = 'Y' AND p_invoice_parent_id IS NULL AND p_qtde_nf_compl = 0 THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'REQUIRED COMPL INVOICE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
                     );
        ELSIF p_parent_flag = 'N' AND p_invoice_parent_id IS NULL AND p_qtde_nf_compl > 0 THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NOT REQUIRED COMPL INVOICE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
                     );
        END IF;
        ----------------------
        -- Check INV Period --
        ----------------------
        BEGIN
            l_inv_period_name := CLL_F189_OPEN_VALIDATE_PUB.GET_INV_PERIODS (p_organization_id   => p_organization_id
                                                                            ,p_receive_date      => p_receive_date
                                                                            );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --45;
            --
            IF l_inv_period_name IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'OUT OF PERIOD INV'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
                         );
            END IF;
            --
        END;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --45;
        --------------------------
        -- Check tax collectors --
        --------------------------
        BEGIN
            IF l_rural_contributions_flag = 'Y' THEN
                --
                l_tax_rural_period := CLL_F189_OPEN_VALIDATE_PUB.GET_TAX_TP_RURAL (p_organization_id   => p_organization_id
                                                                                  ,p_receive_date      => p_receive_date
                                                                                  );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --46;
                --
                IF l_tax_rural_period IS NOT NULL THEN -- encontrou imposto cadastrado na lookup que nao esta cadastrado no setup de calendario de imposto do RI
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'OUTDATED TRIBUTE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'DATE = '||p_receive_date
                             );
                END IF;
                --
            ELSE
                --
                l_tax_period := CLL_F189_OPEN_VALIDATE_PUB.GET_TAX_TP (p_organization_id   => p_organization_id
                                                                      ,p_receive_date      => p_receive_date
                                                                      );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --47;
                --
                IF l_tax_rural_period IS NOT NULL THEN -- encontrou imposto cadastrado na lookup que nao esta cadastrado no setup de calendario de imposto do RI
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'OUTDATED TRIBUTE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'DATE = '||p_receive_date
                             );
                END IF;
                --
            END IF; --IF l_rural_contributions_flag = 'Y' THEN
        END;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --48;
        ---------
        -- ISS --
        ---------
        IF l_prf_setup_iss = 'LOCATION' THEN
            --
            l_city_calendar := CLL_F189_OPEN_VALIDATE_PUB.GET_CALENDAR_TAX_CITIES (p_receive_date => p_receive_date
                                                                                  ,p_location_id  => p_location_id
                                                                                  );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --49;
            --
            IF l_city_calendar IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'OUTDATED AGENDA CITY'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'CITY_ID = '||l_city_calendar||' - DATE = '||p_receive_date
                         );
            END IF;
            --
        END IF;
        --------------------------
        -- Check account COFINS --
        --------------------------
        IF p_cofins_flag = 'Y' AND NVL(p_cofins_code_combination_id,0) = 0   THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NONE COFINS CCID'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => 'INVOICE_TYPE_ID = '||p_invoice_type_id
                     );
        END IF;
        -----------------------------------------------------
        -- Verificar se existe Agente Arrecadador para ISS --
        -----------------------------------------------------
        IF p_include_iss_flag = 'Y' THEN
            -- As informacoes do ISS nao serao obrigatorias para fornecedores optantes do regime SN.
            -- Porem se houver ISS na NF, a validacao seguira como uma nota normal.
            IF NVL(p_simplified_br_tax_flag,'N') = 'Y' AND
                   p_iss_city_id               IS NULL AND
                   p_iss_city_code             IS NULL AND
                   p_iss_base                  IS NULL AND
                   p_iss_amount                IS NULL THEN
                    NULL;
            ELSE
                p_city_id := CLL_F189_OPEN_VALIDATE_PUB.GET_CITIES (p_iss_city_code => p_iss_city_code
                                                                   ,p_iss_city_id   => p_iss_city_id
                                                                   );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --50;
                --
                IF p_iss_city_id IS NULL AND p_iss_city_code IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'NULL ISS CITY'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_iss_city_id
                             );
                ELSIF p_iss_city_id IS NOT NULL AND p_iss_city_code IS NOT NULL THEN
                    --
                    IF p_city_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'INVALID ISS CITY'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => 'ID = '||p_iss_city_id||' - CODE = '||p_iss_city_code
                                 );
                    END IF;
                    --
                ELSIF p_iss_city_id IS NULL AND p_iss_city_code IS NOT NULL THEN
                    --
                    IF p_city_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'NONE ISS CITY CODE'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => p_iss_city_code
                                 );
                    END IF;
                    --
                ELSIF p_iss_city_id IS NOT NULL AND p_iss_city_code IS NULL THEN
                    --
                    IF p_city_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'INVALID CITY ID'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => p_iss_city_id
                                 );
                    END IF;
                    --
                END IF;
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --51;
                -------------------------
                -- Check tax collector --
                -------------------------
                IF l_prf_setup_iss = 'LOCATION' THEN
                    CLL_F189_OPEN_VALIDATE_PUB.GET_ISS_ENTITIES (p_organization_id    => p_organization_id
                                                                ,p_iss_city_id        => NVL(p_iss_city_id,p_city_id)
                                                                -- out
                                                                ,p_tax_bureau_site_id => l_tax_bureau_site_id
                                                                ,p_error_code         => l_error_code_iss_entities
                                                                );
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --53;
                     --
                ELSE
                    CLL_F189_OPEN_VALIDATE_PUB.GET_TAX_SITES (p_organization_id           => p_organization_id
                                                             ,p_tax_type                  => 'ISS'
                                                              -- out
                                                             ,p_minimum_tax_amount        => p_minimum_tax_amount
                                                             ,p_cumulative_threshold_type => p_cumulative_threshold_type
                                                             ,p_error_code                => l_error_code_iss_entities
                                                             );
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --53;
                END IF;
                --
                IF l_error_code_iss_entities = 'NO_DATA_FOUND' THEN
                  l_error_code_iss := 'NONE ISS BUREAU';
                ELSIF l_error_code_iss_entities = 'TOO_MANY_ROWS' THEN
                  l_error_code_iss := 'TOO MANY TAX AUTHORITIES';
                ELSIF l_error_code_iss_entities = 'OTHERS' THEN
                  l_error_code_iss := 'INVALID ISS BUREAU';
                END IF;
                --
                IF l_error_code_iss_entities IS NOT NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => l_error_code_iss
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                END IF;
                -------------------------------------
                -- Validando o local do fornecedor --
                -------------------------------------
                IF l_prf_setup_iss = 'LOCATION' THEN
                    --
                    l_verify_supplier_site := CLL_F189_OPEN_VALIDATE_PUB.GET_LOCAL_AUTHORITY (p_operating_unit  => p_operating_unit
                                                                                             ,p_iss_city_id     => NVL(p_iss_city_id,p_city_id)
                                                                                             ,p_organization_id => p_organization_id
                                                                                             );
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --54;
                    --
                    IF l_verify_supplier_site = 0 THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'INV ISS CITY BUREAU'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => 'CITY_ID = '||NVL(p_iss_city_id,p_city_id)
                                 );
                    END IF;
                END IF;
                --------------------------------------------------------------------------
                -- Check if ISS_BASE and ISS_AMOUNT aren't NULL if INVOICE_TYPE has ISS --
                --------------------------------------------------------------------------

                IF p_entity_id IS NOT NULL THEN -- 25947529
                   --
                   -- 25028715 - Start
                   SELECT rc.iss_tax_type
                   INTO l_line_iss_tax_type
                   FROM cll_f189_fiscal_entities_all rfea
                       ,cll_f189_cities rc
                   WHERE rfea.entity_id = p_entity_id
                     AND rfea.city_id   = rc.city_id;
                   --
                END IF;                        -- 25947529

                IF l_line_iss_tax_type = 'SUBSTITUTE' THEN
                -- 25028715 - End

                   IF p_iss_base IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'NULL ISSBASE'
                               ,p_invoice_line_id        => 0
                               ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                   END IF;
                   --
                   IF p_iss_amount IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'NULL ISSAMOUNT'
                               ,p_invoice_line_id        => 0
                               ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                   END IF;
               END IF; -- IF l_line_iss_tax_type = 'SUBSTITUTE' THEN  -- 25028715
            END IF; --IF NVL(r_invoice_header.simplified_br_tax_flag,'N') = 'Y' AND
        END IF; --IF l_include_iss_flag = 'Y' THEN
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --55;
        --------------------
        -- Validando ICMS --
        --------------------
        IF p_icms_type IS NULL THEN
           ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                    ,p_interface_operation_id => p_interface_operation_id
                    ,p_organization_id        => p_organization_id
                    ,p_error_code             => 'NULL ICMS TYPE'
                    ,p_invoice_line_id        => 0
                    ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                    ,p_invalid_value          => NULL
                    );
        ELSE
           IF p_icms_type <> 'INV LINES INF' THEN -- ER 9028781
              --
              l_validation_rule_icms_type := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_ICMS_TYPE'
                                                                                                   ,p_code            => p_icms_type
                                                                                                   ,p_invoice_type_id => p_invoice_type_id
                                                                                                   ,p_validity_type   => 'ICMS TYPE'
                                                                                                   );
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --56;
              --
              IF l_validation_rule_icms_type IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID ICMSTYPE'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => NULL
                           );
              END IF;
           END IF; -- ER 9028781
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --57;
        --
        -- 28487689 - 28597878 - Start
        IF p_source_ibge_city_code IS NOT NULL AND p_source_city_id IS NULL THEN

           BEGIN
              SELECT cllci.CITY_ID
                INTO p_source_city_id_out
              FROM CLL_F189_CITIES cllci
              WHERE cllci.IBGE_CODE = p_source_ibge_city_code;
           EXCEPTION
              WHEN OTHERS THEN
                  p_source_city_id_out := NULL;
           END;

        ELSE

           p_source_city_id_out := p_source_city_id;

        END IF;
        -- 28487689 - 28597878 - End
        --
        -- 28730077 - Start
        IF p_source_ibge_city_code IS NULL
        AND p_source_city_id_out IS NOT NULL THEN

           BEGIN
              SELECT cllci.IBGE_CODE
                INTO p_source_ibge_city_out
              FROM CLL_F189_CITIES cllci
              WHERE cllci.CITY_ID = p_source_city_id_out;
           EXCEPTION
              WHEN OTHERS THEN
                  p_source_ibge_city_out := NULL;
           END;

        ELSE

           p_source_ibge_city_out := p_source_ibge_city_code;

        END IF;
        -- 28730077 - End
        --------------------------------
        -- Validando estado de origem --
        --------------------------------
        p_source_state_id_out := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => p_source_state_id
                                                                       ,p_state_code => p_source_state_code
                                                                       );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --58;
        --
        IF p_source_state_id IS NULL AND p_source_state_code IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NULL SOURCE STATE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => NULL
                     );
        ELSIF p_source_state_id IS NOT NULL AND p_source_state_code IS NOT NULL THEN
            --
            IF p_source_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID SOURCE STATE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_source_state_id
                         );
            END IF;
        ELSIF p_source_state_id IS NOT NULL AND p_source_state_code IS NULL THEN
            --
            IF p_source_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID SOURCE STATE ID'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_source_state_id
                         );
            END IF;
        ELSIF p_source_state_id IS NULL AND p_source_state_code IS NOT NULL THEN
            --
            IF p_source_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID SOURCE STATE CODE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_source_state_code
                         );
            END IF;
        ELSE
            p_source_state_id_out := p_source_state_id;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --59;
        --
        -- 28978447 - Start
        IF p_ship_to_state_id IS NULL THEN

           BEGIN
              SELECT rs.state_id
              INTO p_ship_to_state_id_out
              FROM cll_f189_fiscal_entities_all rfea
                 , cll_f189_states rs
              WHERE rfea.location_id = p_location_id
                AND rs.state_id = rfea.state_id;
           EXCEPTION
              WHEN OTHERS THEN
                  p_ship_to_state_id_out := NULL;
           END;

        ELSE

           p_ship_to_state_id_out := p_ship_to_state_id;

        END IF;
        -- 28978447 - End
        --
        -- 28487689 - 28597878 - Start
        IF p_destination_ibge_city_code IS NOT NULL AND p_destination_city_id IS NULL THEN

           BEGIN
              SELECT cllci.CITY_ID
                   , cllci.STATE_ID
                INTO p_destination_city_id_out
                   , p_destination_state_id_out -- 28978447
                 --, p_ship_to_state_id_out     -- 28978447
              FROM CLL_F189_CITIES cllci
              WHERE cllci.IBGE_CODE = p_destination_ibge_city_code;
           EXCEPTION
              WHEN OTHERS THEN
                     p_destination_city_id_out  := NULL;
                     p_destination_state_id_out := NULL; -- 28978447
                   --p_ship_to_state_id_out     := NULL; -- 28978447
           END;

        ELSE

           p_destination_city_id_out  := p_destination_city_id;
           p_destination_state_id_out := p_destination_state_id; -- 28978447
         --p_ship_to_state_id_out     := p_ship_to_state_id;     -- 28978447

        END IF;
        -- 28487689 - 28597878 - End
        --
        -- 28730077 - Start
        IF p_destination_ibge_city_code IS NULL
        AND p_destination_city_id_out IS NOT NULL THEN

           BEGIN
              SELECT cllci.IBGE_CODE
                INTO p_destination_ibge_city_out
              FROM CLL_F189_CITIES cllci
              WHERE cllci.CITY_ID = p_destination_city_id_out;
           EXCEPTION
              WHEN OTHERS THEN
                 p_destination_ibge_city_out := NULL;
           END;

        ELSE

           p_destination_ibge_city_out := p_destination_ibge_city_code;

        END IF;
        -- 28730077 - End
        ---------------------------------
        -- Validando estado de destino --
        ---------------------------------
        p_destination_state_id_out := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => p_destination_state_id
                                                                            ,p_state_code => p_destination_state_code
                                                                            );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --60;
        --
        IF p_destination_state_id IS NULL AND p_destination_state_code IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NULL DESTINATION STATE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => NULL
                     );
        ELSIF p_destination_state_id IS NOT NULL AND p_destination_state_code IS NOT NULL THEN
            --
            IF p_destination_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID DESTINATION STATE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_destination_state_id
                         );
            END IF;
        ELSIF p_destination_state_id IS NOT NULL AND p_destination_state_code IS NULL THEN
            --
            IF p_destination_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID DESTINATION STATE ID'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_destination_state_id
                         );
            END IF;
        ELSIF p_destination_state_id IS NULL AND p_destination_state_code IS NOT NULL THEN
            --
            IF p_destination_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID DESTINATION STATE CODE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_destination_state_code
                         );
            END IF;
        ELSE
            p_destination_state_id_out := p_destination_state_id;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --61;
        --
        ---------------------------------------
        -- Validando a condicao de pagamento --
        ---------------------------------------
        --
        IF p_terms_id IS NULL AND p_terms_name IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NULL TERMS'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => NULL
                     );
        ELSE
            p_terms_id_out := CLL_F189_OPEN_VALIDATE_PUB.GET_AP_TERMS (p_terms_id   => p_terms_id
                                                                      ,p_terms_name => p_terms_name
                                                                      );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --62;
            IF p_terms_id IS NOT NULL AND p_terms_name IS NULL THEN
                --
                IF p_terms_id_out IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INVALID TERMS ID'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_terms_id
                             );
                END IF;
            ELSIF p_terms_id IS NULL AND p_terms_name IS NOT NULL THEN
                --
                IF p_terms_id_out IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INVALID TERMS NAME'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_terms_name
                             );
                END IF;
            ELSE
                --
                IF p_terms_id_out IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INVALID TERMS'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'ID = '||p_terms_id||' - NAME = '||p_terms_name
                             );
                END IF;
            END IF;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --63;
        --
        -----------------------------------------------------------
        -- Recuperando dados das linhas da condicao de pagamento --
        -----------------------------------------------------------
        CLL_F189_INVOICES_UTIL_PKG.GET_TERMS_LINES (p_terms_id => NVL(p_terms_id,p_terms_id_out)
                                                   ,p_dmf      => l_dmf
                                                   ,p_ddm      => l_ddm
                                                   ,p_dd       => l_dd
                                                   ,p_dcd      => l_dcd
                                                   );
        --
        IF l_dmf IS NULL OR l_ddm IS NULL OR l_dd IS NULL OR l_dcd IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NULL PAYMENTDATE'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => 'ID = '||NVL(p_terms_id,p_terms_id_out)
                     );
        ELSE
            ----------------------------------------------
            -- Recuperando a data do primeiro pagamento --
            ----------------------------------------------
            CLL_F189_INVOICES_UTIL_PKG.GET_FIRST_PAYMENT_DATE(p_first_payment_date     => p_first_payment_date
                                                           --,p_terms_date             => p_terms_date                     -- 27854379
                                                             ,p_terms_date             => NVL(p_terms_date,p_invoice_date) -- 27854379
                                                             ,p_dcd                    => l_dcd
                                                             ,p_dmf                    => l_dmf
                                                             ,p_ddm                    => l_ddm
                                                             ,p_dd                     => l_dd
                                                             -- out
                                                             ,p_first_payment_date_out => p_first_payment_date_out
                                                             );
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --64;
        --
        ----------------------------------
        -- Validando valores adicionais --
        ----------------------------------
        IF p_additional_tax IS NOT NULL AND p_additional_amount IS NOT NULL THEN
-- 27579747 - Start
--           IF p_source <> 'CLL_F369 EFD LOADER' THEN -- ER 14124731
           IF p_source NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
              IF ROUND(p_additional_tax) <> ROUND(100 * (p_additional_amount / (NVL(p_invoice_amount,0)    -
                                                                                NVL(p_ipi_amount,0)        -
                                                                                NVL(p_icms_st_amount,0)    -
                                                                                NVL(p_additional_amount,0) -
                                                                                NVL(p_other_expenses,0)    -  -- 21091872
                                                                                NVL(p_insurance_amount,0)  -  -- 21091872
                                                                                NVL(p_freight_amount,0))))THEN       -- 21091872
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID ADDITIONALTAX'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => p_additional_tax
                           );
              END IF;
           END IF; -- ER 14124731
           l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --65;
        -- Bug 13360408 - Start
        ELSIF p_additional_tax IS NULL AND p_additional_amount IS NOT NULL THEN
            ----------------------------------------------
            -- Validando Percentual e Valor do Desconto --
            ----------------------------------------------
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID DISCOUNTAMT'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => p_additional_amount
                     );
        -- Bug 13360408 - End
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --66;
        --
        --------------------------------
        -- Validando dados de retorno --
        --------------------------------
        p_return_cfo_id_out := CLL_F189_OPEN_VALIDATE_PUB.GET_FISCAL_OPERATIONS_RETURN(p_cfo_id      => p_return_cfo_id
                                                                                      ,p_cfo_code    => p_return_cfo_code
                                                                                      ,p_return_flag => 'Y'
                                                                                      );
        --
        IF p_return_cfo_id IS NOT NULL AND p_return_cfo_code IS NULL THEN
            IF p_return_cfo_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID RETURNCFO ID'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'ID = '||p_return_cfo_id
                         );
            END IF;
        ELSIF p_return_cfo_id IS NULL AND p_return_cfo_code IS NOT NULL THEN
            --
            IF p_return_cfo_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID RETURNCFO CODE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'CODE = '||p_return_cfo_code
                         );
            END IF;
        ELSIF p_return_cfo_id IS NOT NULL AND p_return_cfo_code IS NOT NULL THEN
            --
            IF p_return_cfo_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID RETURNCFO'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'ID = '||p_return_cfo_id||' - CODE = '||p_return_cfo_code
                         );
            END IF;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --67;
        --
        IF p_return_amount IS NOT NULL AND p_return_amount <= 0 THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID RETURNAMOUNT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_return_amount
                         );
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --68;
        --
        ---------------------------------
        -- Validando dados do contrato --
        ---------------------------------
        IF p_requisition_type = 'CT' THEN
            IF p_contract_id IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL CONTRACT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                --
                l_contract_id := CLL_F189_OPEN_VALIDATE_PUB.GET_CONTRACT_PO(p_vendor_id      => p_vendor_id
                                                                           ,p_location_id    => p_location_id
                                                                           ,p_operating_unit => p_operating_unit
                                                                           ,p_po_header_id   => p_contract_id
                                                                           );
                --
                IF l_contract_id IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INVALID CONTRACT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_contract_id
                             );
                END IF;
                --
            END IF;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --69;
        --------------------------
        -- Validando Importacao --
        --------------------------
        IF p_source_items = '1' THEN
            IF p_importation_number IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL DINUMBER'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF p_total_fob_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL FOBAMT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF p_freight_international IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL INTFRETE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF p_importation_insurance_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL IMPSEGURO'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF p_importation_tax_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL IMPIMPOSTO'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                IF p_total_cif_amount IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'NULL CIFAMT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                ELSIF p_total_cif_amount <> (p_total_fob_amount +
                                             p_freight_international +
                                             p_importation_insurance_amount) THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INVALID CIFAMT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_total_cif_amount
                             );
                END IF;
            END IF; --IF r_invoice_header.importation_number IS NULL THEN
        END IF; --IF r_invoice_header.source_items = '1' THEN
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --70;
        --------------------------------------------
        -- Validando o Modelo Fiscal do documento --
        --------------------------------------------
        IF p_fiscal_document_model IS NULL THEN
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => p_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'NULL DOCMODEL'
                     ,p_invoice_line_id        => 0
                     ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                     ,p_invalid_value          => NULL
                     );
        ELSE
            --
            l_validation_rule_fisc_doc_mod := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_FISCAL_DOCUMENT_MODEL'
                                                                                                    ,p_code            => p_fiscal_document_model
                                                                                                    ,p_invoice_type_id => p_invoice_type_id
                                                                                                    ,p_validity_type   => 'FISCAL DOCUMENT MODEL'
                                                                                                    );
            --
            IF l_validation_rule_fisc_doc_mod IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID DOCMODEL'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_fiscal_document_model
                         );
            END IF;
        END IF; --IF r_invoice_header.fiscal_document_model IS NULL THEN
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --71;
        ----------
        -- INSS --
        ----------

-- 28730077 - Start
        IF  p_source <> 'CLL_F369 EFD LOADER SHIPPER' THEN
-- 28730077 - End
        IF l_inss_tax_ci IS NOT NULL AND NVL(p_inss_calculation_flag,'N') = 'Y' THEN  --<<Bug 17377522 - Egini - 01/09/2013 >>--
            IF l_inss_tax_ci IS NULL THEN   --<<Bug 17377522 - Egini - 01/09/2013 >>--
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL INSSTAX'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF p_inss_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL INSSAMOUNT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF (ROUND(NVL(p_inss_amount,0),2)+ROUND(NVL(p_inss_subcontract_amount,0),2)) <>
                   ROUND(((p_inss_base * p_inss_tax)/100),2) THEN            --<<Bug 17377522 - Egini - 05/09/2013 >>--
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID INSSAMOUNT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
        END IF; --IF r_invoice_header.inss_base IS NOT NULL AND NVL(l_inss_calculation_flag,'N') = 'Y' THEN
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --72;
-- 28730077 - Start
        END IF;
-- 28730077 - End
        ---------------------
        -- INSS Autonomous --
        ---------------------
-- 27579747 - Start
        IF  p_source <> 'CLL_F369 EFD LOADER SHIPPER' THEN
-- 27579747 - End
        IF p_inss_base IS NOT NULL AND p_inss_substitute_flag  = 'A' THEN
            IF p_inss_autonomous_tax IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL INSSTAXMP83'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF p_inss_autonomous_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL INSSAMOUNTMP83'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                l_retencao_faturado := ( NVL(p_inss_autonomous_inv_total, 0) * (p_inss_autonomous_tax / 100) );
                --
                IF ROUND(l_retencao_faturado,2) > ROUND(l_inss_aut_max_retention,2) THEN -- Ultrapassou o limite de retencao
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'EXCEEDED INSSAMOUNTMP83'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                ELSE
                    l_retencao_nf := ((p_inss_base * p_inss_autonomous_tax) / 100);
                    --
                    IF ROUND((l_retencao_faturado      + l_retencao_nf),2)        > ROUND(l_inss_aut_max_retention,2) AND
                       ROUND((l_inss_aut_max_retention - l_retencao_faturado),2) <> ROUND(p_inss_autonomous_amount,2) THEN -- limite over
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'EXCEEDED INSSAMOUNT NF' --'EXCEEDED INSSAMOUNTMP83'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => ROUND(p_inss_autonomous_amount,2)
                                 );
                    END IF;
                END IF;
            END IF; --IF r_invoice_header.inss_autonomous_tax IS NULL THEN
        END IF; --IF r_invoice_header.inss_base IS NOT NULL AND l_inss_substitute_flag  = 'A' THEN
-- 27579747 - Start
        END IF;
-- 27579747 - End
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --73;
        ---------
        -- ISS --
        ---------
        IF p_iss_base IS NOT NULL THEN
            IF p_iss_base > p_gross_total_amount THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID ISSBASE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'ISS_BASE = '||p_iss_base||' - GROSS_TOTAL_AMOUNT = '||p_gross_total_amount
                         );
            ELSIF p_iss_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID ISSAMOUNT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --74;
        --------
        -- IR --
        --------
        -- As informacoes do IR nao serao obrigatorias para fornecedores optantes do regime SN.
        -- Porem se houver IR na NF, a validacao seguira como uma nota normal.
        IF NVL(p_simplified_br_tax_flag,'N') = 'Y' AND
               p_ir_vendor                 IS NULL AND
               p_ir_base                   IS NULL AND
               p_ir_amount                 IS NULL AND
               p_ir_tax                    IS NULL AND
               p_ir_categ                  IS NULL THEN
            NULL;
        ELSE
            IF p_ir_vendor IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL IRVENDOR'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                --
                l_ir_vendor := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES (p_lookup_type => 'CLL_F189_IR_VENDOR'
                                                                     ,p_lookup_code => p_ir_vendor
                                                                     );
                --
                IF l_ir_vendor IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INVALID IRVENDOR'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_ir_vendor
                             );
                END IF;
            END IF; --IF r_invoice_header.ir_vendor IS NULL THEN
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --75;
            --
            IF p_ir_vendor IN ('1','2') THEN
                IF p_ir_base IS NULL OR p_ir_amount IS NULL OR p_ir_categ IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'NULL IRVALUES'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_ir_vendor
                             );
                END IF;
                --
                l_ir_categ := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES (p_lookup_type => 'CLL_F189_IR_CATEG'
                                                                    ,p_lookup_code => p_ir_categ
                                                                    );
                --
                IF l_ir_categ IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INVALID IRCATEG'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => p_ir_categ
                             );
                END IF;
            END IF; --IF r_invoice_header.ir_vendor IN ('1','2') THEN
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --76;
            --
            IF p_ir_base IS NOT NULL THEN
                IF p_ir_amount IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'NULL IRAMOUNT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                END IF;
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --77;
            ------------------------------
            -- Validando casas decimais --
            ------------------------------
            IF p_ir_base IS NOT NULL THEN
                IF (nvl(p_ir_base,0) - trunc(nvl(p_ir_base,0),2)) > 0 THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'IR_BASE = '||p_ir_base
                             );
                END IF;
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --78;
            --
            IF p_ir_tax IS NOT NULL THEN
                IF (nvl(p_ir_tax,0) - trunc(nvl(p_ir_tax,0),2)) > 0 THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'IR_TAX = '||p_ir_tax
                             );
                END IF;
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --79;
            --
            IF p_ir_amount IS NOT NULL  THEN
                IF (nvl(p_ir_amount,0) - trunc(nvl(p_ir_amount,0),2)) > 0 THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'IR_AMOUNT = '||p_ir_amount
                             );
                END IF;
            END IF;
        END IF; --IF NVL(r_invoice_header.simplified_br_tax_flag,'N') = 'Y' AND
        --
        IF NVL(p_inss_calculation_flag,'N') = 'Y' THEN
          --
          IF p_inss_base IS NOT NULL THEN
              IF (nvl(p_inss_base,0) - trunc(nvl(p_inss_base,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_BASE = '||p_inss_base
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --80;
          --
          IF p_inss_tax IS NOT NULL THEN
              IF (nvl(p_inss_tax,0) - trunc(nvl(p_inss_tax,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_TAX = '||p_inss_tax
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --81;
          --
          IF p_inss_amount IS NOT NULL THEN
              IF (nvl(p_inss_amount,0) - trunc(nvl(p_inss_amount,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_AMOUNT = '||p_inss_amount
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --82;
          --
          IF p_inss_autonomous_inv_total IS NOT NULL THEN
              IF (nvl(p_inss_autonomous_inv_total,0) - trunc(nvl(p_inss_autonomous_inv_total,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_AUTONOMOUS_INVOICED_TOTAL = '||p_inss_autonomous_inv_total
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --83;
          --
          IF p_inss_autonomous_amount IS NOT NULL THEN
              IF (nvl(p_inss_autonomous_amount,0) - trunc(nvl(p_inss_autonomous_amount,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_AUTONOMOUS_AMOUNT = '||p_inss_autonomous_amount
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --84;
          --
          IF p_inss_autonomous_tax IS NOT NULL THEN
              IF (nvl(p_inss_autonomous_tax,0) - trunc(nvl(p_inss_autonomous_tax,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_AUTONOMOUS_TAX = '||p_inss_autonomous_tax
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --85;
          --
          IF p_inss_additional_tax_1 IS NOT NULL THEN
              IF (nvl(p_inss_additional_tax_1,0) - trunc(nvl(p_inss_additional_tax_1,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_TAX_1 = '||p_inss_additional_tax_1
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --86;
          --
          IF p_inss_additional_tax_2 IS NOT NULL THEN
              IF (nvl(p_inss_additional_tax_2,0) - trunc(nvl(p_inss_additional_tax_2,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_TAX_2 = '||p_inss_additional_tax_2
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --87;
          --
          IF p_inss_additional_tax_3 IS NOT NULL  THEN
              IF (nvl(p_inss_additional_tax_3,0) - trunc(nvl(p_inss_additional_tax_3,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_TAX_3 = '||p_inss_additional_tax_3
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --88;
          --
          IF p_inss_additional_base_1 IS NOT NULL  THEN
              IF (nvl(p_inss_additional_base_1,0) - trunc(nvl(p_inss_additional_base_1,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_BASE_1 = '||p_inss_additional_base_1
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --89;
          --
          IF p_inss_additional_base_2 IS NOT NULL  THEN
              IF (nvl(p_inss_additional_base_2,0) - trunc(nvl(p_inss_additional_base_2,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_BASE_2 = '||p_inss_additional_base_2
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --90;
          --
          IF p_inss_additional_base_3 IS NOT NULL  THEN
              IF (nvl(p_inss_additional_base_3,0) - trunc(nvl(p_inss_additional_base_3,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_BASE_3 = '||p_inss_additional_base_3
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --91;
          --
          IF p_inss_additional_amount_1 IS NOT NULL  THEN
              IF (nvl(p_inss_additional_amount_1,0) - trunc(nvl(p_inss_additional_amount_1,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_AMOUNT_1 = '||p_inss_additional_amount_1
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --92;
          --
          IF p_inss_additional_amount_2 IS NOT NULL  THEN
              IF (nvl(p_inss_additional_amount_2,0) - trunc(nvl(p_inss_additional_amount_2,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_AMOUNT_2 = '||p_inss_additional_amount_2
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --93;
          --
          IF p_inss_additional_amount_3 IS NOT NULL  THEN
              IF (nvl(p_inss_additional_amount_3,0) - trunc(nvl(p_inss_additional_amount_3,0),2)) > 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                           ,p_invoice_line_id        => 0
                           ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'INSS_ADDITIONAL_AMOUNT_3 = '||p_inss_additional_amount_3
                           );
              END IF;
          END IF;
        END IF; --IF NVL(l_inss_calculation_flag,'N') = 'Y' THEN
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --94;
        IF p_gross_total_amount IS NOT NULL  THEN
            IF (nvl(p_gross_total_amount,0) - trunc(nvl(p_gross_total_amount,0),2)) > 0 THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'GROSS_TOTAL_AMOUNT = '||p_gross_total_amount
                         );
            END IF;
        END IF;
        --
        IF p_iss_base IS NOT NULL  THEN
            IF (nvl(p_iss_base,0) - trunc(nvl(p_iss_base,0),2)) > 0 THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'ISS_BASE = '||p_iss_base
                         );
            END IF;
        END IF;
        --
        IF p_iss_amount IS NOT NULL  THEN
            IF (nvl(p_iss_amount,0) - trunc(nvl(p_iss_amount,0),2)) > 0 THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'ISS_AMOUNT = '||p_iss_amount
                         );
            END IF;
        END IF;
        --
        IF p_invoice_amount IS NOT NULL  THEN
            IF (nvl(p_invoice_amount,0) - trunc(nvl(p_invoice_amount,0),2)) > 0 THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INCORRECT DECIMAL PLACES'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'INVOICE_AMOUNT = '||p_invoice_amount
                         );
            END IF;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --95;
        --
        -----------------------
        -- Validando Veiculo --
        -----------------------
        p_vehicle_seller_state_id_out := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES(p_state_id   => p_vehicle_seller_state_id
                                                                              ,p_state_code => p_vehicle_seller_state_code
                                                                              );
        IF p_vehicle_seller_state_id IS NOT NULL AND p_vehicle_seller_state_code IS NOT NULL THEN
            --
            IF p_vehicle_seller_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INV VEHICLE SEL STATE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_vehicle_seller_state_id
                         );
            END IF;
            --
        ELSIF p_vehicle_seller_state_id IS NOT NULL AND p_vehicle_seller_state_code IS NULL THEN
            IF p_vehicle_seller_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INV VEHICLE SEL STATE ID'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_vehicle_seller_state_id
                         );
            END IF;
            --
        ELSIF p_vehicle_seller_state_id IS NULL AND p_vehicle_seller_state_code IS NOT NULL THEN
            IF p_vehicle_seller_state_id_out IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INV VEHICLE SEL STATE COD'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_vehicle_seller_state_code
                         );
            END IF;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --96;
        --
        IF p_import_document_type IS NOT NULL THEN
            l_import_document_type := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES (p_lookup_type => 'CLL_F189_IMPORT_DOCUMENT_TYPE'
                                                                            ,p_lookup_code => p_import_document_type
                                                                            );
            --
            IF l_import_document_type IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INV IMPORT DOC TYPE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_import_document_type
                         );
            END IF;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --97;
        --------------------
        -- Process Origin --
        --------------------
        IF p_process_origin IS NOT NULL THEN
            l_process_origin := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES (p_lookup_type => 'CLL_F189_PROCESS_ORIGIN'
                                                                      ,p_lookup_code => p_process_origin
                                                                      );
            --
            IF l_process_origin IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INV PROCESS ORIGIN'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => p_process_origin
                         );
            END IF;
        END IF;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --98;
        --
        -- ER 17551029 5a Fase - Start
        -------------------------------------------------
        -- Worker Category, Category Code and CBO Code --
        -------------------------------------------------
        l_esocial_period_code := CLL_F407_UTILITY_PKG.get_start_date_org_f(p_organization_id); -- 27357141


        IF l_esocial_period_code > NVL(TO_CHAR(p_invoice_date, 'YYYY-MM'),TO_CHAR(SYSDATE, 'YYYY-MM')) THEN  -- 27357141

           IF p_worker_category_id IS NOT NULL OR
              p_category_code IS NOT NULL OR
              p_cbo_code IS NOT NULL THEN -- Somente validar se pelo menos um dos campos estiver informado
              l_worker_category := CLL_F189_OPEN_VALIDATE_PUB.GET_WORKER_CATEGORY (p_worker_category_id  => p_worker_category_id
                                                                                  ,p_category_code       => p_category_code
                                                                                  ,p_cbo_code            => p_cbo_code
                                                                                  );
              IF l_worker_category IS NULL THEN
                 ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                          ,p_interface_operation_id => p_interface_operation_id
                          ,p_organization_id        => p_organization_id
                          ,p_error_code             => 'INCONSISTENT WORKER CATEGORY'
                          ,p_invoice_line_id        => 0
                          ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                          ,p_invalid_value          => p_worker_category_id
                          );
              END IF;

           END IF;

        END IF;  -- 27357141
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --99 ;
        --
        -- ER 17551029 5a Fase - End
        --
        -- Enh 29907995 - Start
        /*
        -- 30211420 - Start
        --
        SELECT COUNT(*)
          INTO l_tpa_return_type
          FROM cll_f189_invoice_types
         WHERE invoice_type_id                     = p_invoice_type_id
           AND organization_id                     = p_organization_id
           AND return_customer_flag                = 'T'
           AND NVL(inactive_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE) ;
        --
        IF l_tpa_return_type > 0 THEN
          --
          ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                    , p_interface_operation_id => p_interface_operation_id
                    , p_organization_id        => p_organization_id
                    , p_error_code             => 'INVOICE TYPE DEV INV'
                    , p_invoice_line_id        => 0
                    , p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                    , p_invalid_value          => NULL
                    ) ;
          --
        END IF ;
        --
        -- 30211420 - End
        --
        */
        -- Enh 29907995 - End
        --
    print_log('  FIM CREATE_OPEN_HEADER');
  END CREATE_OPEN_HEADER;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_LINES                                           |
  |                                                                          |
  | Description: Responsible for validate information and insert into RI     |
  |              final tables or insert errors in RI or Loader interface     |
  |              tables                                                      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OPEN_LINES (p_type                           IN VARCHAR2
                              ,p_interface_invoice_id           IN NUMBER
                              ,p_interface_operation_id         IN NUMBER
                              ,p_organization_id                IN NUMBER
                              ,p_location_id                    IN NUMBER
                              ,p_operating_unit                 IN NUMBER
                              ,p_vendor_id                      IN NUMBER
                              ,p_entity_id                      IN NUMBER
                              ,p_invoice_type_id                IN NUMBER
                              ,p_price_adjust_flag              IN VARCHAR2
                              ,p_cost_adjust_flag               IN VARCHAR2
                              ,p_tax_adjust_flag                IN VARCHAR2
                              ,p_fixed_assets_flag              IN VARCHAR2
                              ,p_parent_flag                    IN VARCHAR2
                              ,p_contab_flag                    IN VARCHAR2
                              ,p_payment_flag                   IN VARCHAR2
                              ,p_freight_flag                   IN VARCHAR2
                              ,p_freight_flag_inv_type          IN VARCHAR2
                              ,p_project_flag                   IN VARCHAR2
                              ,p_chart_of_accounts_id           IN NUMBER
                              ,p_additional_tax                 IN NUMBER
                              ,p_allow_upd_price_flag           IN VARCHAR2
                              ,p_source_items                   IN VARCHAR2
                              ,p_user_defined_conversion_rate   IN NUMBER
                              ,p_rcv_tolerance_perc_amount      IN NUMBER
                              ,p_rcv_tolerance_code             IN VARCHAR2
                              ,p_source_state_id                IN NUMBER
                              ,p_destination_state_id           IN NUMBER
                              ,p_source_state_code              IN VARCHAR2 -- Bug 17442462
                              ,p_destination_state_code         IN VARCHAR2 -- Bug 17442462
                              ,p_gl_date                        IN DATE
                              ,p_receive_date                   IN DATE
                              ,p_qtde_nf_compl                  IN NUMBER -- Bug 16600918
                              ,p_requisition_type               IN VARCHAR2 --<<Bug 17481870 - Egini - 20/09/2013 >>--
                              ,p_invoice_date                   IN DATE     --  22012023
                              ,p_invoice_line_id_par            OUT NOCOPY NUMBER -- BUG 19943706
                              ,p_process_flag                   OUT NOCOPY NUMBER
                              ,p_return_code                    OUT NOCOPY VARCHAR2
                              ,p_return_message                 OUT NOCOPY VARCHAR2
                              -- Begin BUG 24387238
                              ,p_line_location_id               OUT NOCOPY NUMBER
                              ,p_requisition_line_id            OUT NOCOPY NUMBER
                              ,p_item_id                        OUT NOCOPY NUMBER
                              -- End BUG 24387238
                              ) IS
  CURSOR c_invoice_lines IS
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
              ,uom_tl.unit_of_measure uom -- Bug 20506497
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
              ,reli.customs_total_value
              ,reli.ci_percent
              ,reli.total_import_parcel
              ,reli.fci_number
              ,reli.recopi_number      -- Bug 20145693
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
              ,reli.icms_type                 -- ER 9028781
              ,reli.icms_free_service_amount  -- ER 9028781
              ,reli.max_icms_amount_recover   -- ER 9028781
              ,reli.icms_tax_rec_simpl_br     -- ER 9028781
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
              ,reli.anvisa_product_code            -- 25713076
              ,reli.anp_product_code               -- 25713076
            --,reli.anp_product_description        -- 25713076 -- 26987509 - 26986232
              ,reli.anp_product_descr              -- 26987509 - 26986232
              ,reli.product_lot_number             -- 26987509 - 26986232
              ,reli.lot_quantity                   -- 25713076
              ,reli.production_date                -- 25713076
              ,reli.expiration_date                -- 25713076
              ,reli.aggregation_code               -- 25713076
              ,reli.glp_derived_oil_perc           -- 25713076
              ,reli.glgnn_glp_product_perc         -- 25713076
              ,reli.glgni_glp_product_perc         -- 25713076
              ,reli.starting_value                 -- 25713076
              ,reli.codif_authorization            -- 25713076
              ,reli.iss_city_id                    -- 25591653
              ,reli.iss_city_code                  -- 25591653
              ,reli.service_execution_date         -- 25591653
              ,reli.iss_fo_base_amount             -- 25591653
              ,reli.iss_fo_tax_rate                -- 25591653
              ,reli.iss_fo_amount                  -- 25591653
              -- 27501091 - Start
              ,reli.significant_scale_prod_ind
              ,reli.manufac_goods_doc_number
              ,reli.fcp_base_amount
              ,reli.fcp_rate
              ,reli.fcp_amount
              ,reli.fcp_st_base_amount
              ,reli.fcp_st_rate
              ,reli.fcp_st_amount
              -- 27501091 - End
              ,reli.fcp_amount_recover             -- 28194547
              ,reli.fcp_st_amount_recover          -- 28194547
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
              ,reli.anvisa_exemption_reazon   -- 29330466 - 29338175 - 29385361 - 29480917
              ,reli.icms_prev_withheld_amount -- 29330466 - 29338175 - 29385361 - 29480917
         FROM cll_f189_inv_line_iface_tmp reli
         -- Bug 20506497 - Start
             ,(SELECT DISTINCT  unit_of_measure
                               ,unit_of_measure_tl
                 FROM mtl_units_of_measure) uom_tl  -- 21531065
         WHERE uom_tl.unit_of_measure = reli.uom    -- 21531065
         -- Bug 20506497 - End
           AND reli.interface_invoice_id = p_interface_invoice_id;
    --
    -- ER 26338366/26899224 -- start
    --
    CURSOR c_invoice_lines_tpa
       ( p_interface_invoice_line_id IN NUMBER ) -- Bug 29553127
      IS
      SELECT tmp.interface_invoice_id
           , tmp.interface_invoice_line_id
           , tmp.tpa_remit_interface_id
           , tmp.tpa_remit_control_id
           , tmp.new_subinventory_code
           , tmp.new_locator_id
           , tmp.new_locator_code
           , tmp.attribute_category
           , tmp.attribute1
           , tmp.attribute2
           , tmp.attribute3
           , tmp.attribute4
           , tmp.attribute5
           , tmp.attribute6
           , tmp.attribute7
           , tmp.attribute8
           , tmp.attribute9
           , tmp.attribute10
           , tmp.attribute11
           , tmp.attribute12
           , tmp.attribute13
           , tmp.attribute14
           , tmp.attribute15
           , tmp.attribute16
           , tmp.attribute17
           , tmp.attribute18
           , tmp.attribute19
           , tmp.attribute20
           , tmp.creation_date
           , tmp.created_by
           , tmp.last_update_date
           , tmp.last_update_login
           , tmp.request_id
           , tmp.program_application_id
           , tmp.program_id
           , tmp.program_update_date
           , inv.invoice_date --trc.trx_date invoice_date
           , inv.invoice_num  invoice_number -- trc.trx_number invoice_number
           , inv.receive_date
           , trc.ship_to_site_use_id
           , trc.organization_id
           , tmp.quantity           -- ER 26338366/26899224 2a Fase
           , lines.item_number
           , lines.unit_price
           , symbolic_return_flag   -- ENR 30120364
        FROM cll_f513_tpa_ret_iface_tmp tmp, -- Bug 27348371
             cll_f513_tpa_remit_control trc,
             cll_f189_invoices_interface inv, -- Bug 27348371
             cll_f189_invoice_lines_iface lines -- Bug 27348371
       WHERE trc.tpa_remit_control_id(+) = tmp.tpa_remit_control_id
         AND tmp.interface_invoice_id = p_interface_invoice_id
         AND inv.interface_invoice_id = tmp.interface_invoice_id
         AND lines.interface_invoice_line_id = tmp.interface_invoice_line_id
         AND lines.interface_invoice_line_id = p_interface_invoice_line_id ; -- Bug 29553127

    --ER 26338366/26899224 -- end
    --
    -- Enh 29907995 -- Start
    CURSOR c_inv_lines_dev_tpa ( p_interface_invoice_line_id IN NUMBER ) IS
      SELECT cftd.interface_invoice_id
           , cftd.interface_invoice_line_id
           , cftd.tpa_receipt_interface_id
           , cftd.tpa_receipt_control_id
           , cftd.new_subinventory_code
           , cftd.quantity
           , cftd.new_locator_id
           , cftd.new_locator_code
           , cftd.symbolic_devolution_flag
           , cftd.attribute_category
           , cftd.attribute1
           , cftd.attribute2
           , cftd.attribute3
           , cftd.attribute4
           , cftd.attribute5
           , cftd.attribute6
           , cftd.attribute7
           , cftd.attribute8
           , cftd.attribute9
           , cftd.attribute10
           , cftd.attribute11
           , cftd.attribute12
           , cftd.attribute13
           , cftd.attribute14
           , cftd.attribute15
           , cftd.attribute16
           , cftd.attribute17
           , cftd.attribute18
           , cftd.attribute19
           , cftd.attribute20
           , cftd.creation_date
           , cftd.created_by
           , cftd.last_update_date
           , cftd.last_update_login
           , cftd.last_updated_by
           , cftd.request_id
           , cftd.program_application_id
           , cftd.program_id
           , cftd.program_update_date
           , trc.ship_to_site_use_id
           , trc.organization_id
           , trc.org_id
           , inv.invoice_date
           , inv.invoice_num
           , inv.receive_date
           , lines.item_number
           , lines.unit_price
           , lines.item_id
           , lines.uom
           , trc.parent_lot_number
           , trc.lot_number
           , trc.lot_expiration_date
           , trc.serial_number
           , trc.receipt_transaction_id
           , lines.db_code_combination_id
        FROM cll_f513_tpa_dev_iface        cftd
           , cll_f513_tpa_receipts_control trc
           , cll_f189_invoices_interface   inv
           , cll_f189_invoice_lines_iface  lines
       WHERE trc.tpa_receipts_control_id (+) = cftd.tpa_receipt_control_id
         AND inv.interface_invoice_id        = cftd.interface_invoice_id
         AND lines.interface_invoice_line_id = cftd.interface_invoice_line_id
         AND lines.interface_invoice_line_id = p_interface_invoice_line_id ;
    --
    -- Enh 29907995 -- End
    --
    --
    l_federal_service_type_id       cll_f189_city_srv_type_rels.federal_service_type_id%type;
    l_municipal_service_type_id     cll_f189_city_srv_type_rels.municipal_service_type_id%type;
    l_city_service_type_rel_id      cll_f189_city_srv_type_rels.city_service_type_rel_id%type;
    l_iss_tax_type                  cll_f189_city_srv_type_rels.iss_tax_type%type;
    --
    l_line_location_id              NUMBER;
    l_item_id_oc                    NUMBER;
    l_item_id_rsl                   NUMBER;
    l_item_id_rma                   NUMBER;
    --
    l_destination_type_code         po_distributions_all.destination_type_code%type;
    l_project_exists                NUMBER;
    l_code_combination_id           gl_code_combinations.code_combination_id%type;
    l_classification_id             cll_f189_fiscal_class.classification_id%type;
    l_utilization_id                cll_f189_item_utilizations.utilization_id%type;
    l_cfo_id                        cll_f189_fiscal_operations.cfo_id%type;
    l_utilization_cfo               NUMBER;
    l_unit_of_measure               mtl_units_of_measure.unit_of_measure%type;
    l_operation_fiscal_type         VARCHAR2(80);
    l_item_description              mtl_system_items.description%TYPE;
    --
    l_validation_rule_cst_icms      VARCHAR2(80);
    l_validation_rule_icms          VARCHAR2(80);
    l_validation_rule_icms_type     VARCHAR2(80); -- ER 9028781
    l_validation_rule_ipi           VARCHAR2(80);
    l_validation_rule_cst_ipi       VARCHAR2(80);
    l_validation_rule_cst_pis       VARCHAR2(80);
    l_validation_rule_cst_cofins    VARCHAR2(80);
    --
    lNetAmountCalc                  NUMBER;
    lDiferencaTotalNf               NUMBER;
    lTolerancia                     NUMBER;
    --
    l_project_id                    pa_projects_expend_v.project_id%type;
    l_task_id                       pa_tasks_expend_v.task_id%type;
    l_expenditure_type              pa_expenditure_types_expend_v.expenditure_type%type;
    l_expenditure_organization_id   pa_organizations_expend_v.organization_id%type;
    --
    l_unit_price                    po_lines_all.unit_price%type;
    l_unit_meas_lookup_code         po_lines_all.unit_meas_lookup_code%type;
    l_item_id                       po_lines_all.item_id%type;
    l_price_override                po_line_locations_all.price_override%type;
    --
    l_uom_status                    VARCHAR2(20);
    l_uom_unit_price                po_lines_all.unit_price%type;
    l_uom_rate                      mtl_uom_conversions.conversion_rate%type;
    l_uom_conv_status               VARCHAR2(20);
    --
    l_awt_group_id                  ap_awt_groups.group_id%type;
    l_vehicle_oper_type             VARCHAR2(80);
    --
    l_uom_po                        cll_f189_invoice_lines.uom_po%TYPE;
    l_quantity_uom_po               cll_f189_invoice_lines.quantity_uom_po%TYPE;
    l_unit_price_uom_po             cll_f189_invoice_lines.unit_price_uom_po%TYPE;
    l_rate_uom_po                   mtl_uom_conversions.conversion_rate%TYPE;
    l_conv_status_uom_po            VARCHAR2(20);
    --
    l_invoice_line_id_s             NUMBER;
    l_user_id                       NUMBER := FND_GLOBAL.USER_ID;
    --
    l_return_code                   VARCHAR2(100);
    l_return_message                VARCHAR2(100);
    --
    l_count                         NUMBER;
    l_possui_item                   NUMBER; --Bug 17334612
    --
    l_utilization_code              VARCHAR2(100);  --<<Bug 17375006 - Egini - 01/09/2013 >>--
    l_cfo_code                      VARCHAR2(10);   --<<Bug 17375006 - Egini - 01/09/2013 >>--
    --
    l_source_state_id               cll_f189_states.state_id%TYPE; -- Bug 17442462
    l_destination_state_id          cll_f189_states.state_id%TYPE; -- Bug 17442462

    l_national_state                cll_f189_states.national_state%TYPE; -- Bug 18983273
    --
    l_vendor_id                     NUMBER; --BUG 19688888
    --
    l_icms_type                      cll_f189_invoices.icms_type%TYPE;              -- ER 9028781
    l_simplified_br_tax_flag         cll_f189_invoices.simplified_br_tax_flag%TYPE; -- ER 9028781
    --
    l_siscomex_amount               NUMBER; -- BUG 19297595
    l_dsp_siscomex_amount           NUMBER; -- BUG 19297595
    --
    l_unit_price_OUT                po_lines_all.unit_price%type; -- BUG 19906534
    --
    l_source                        cll_f189_invoices_interface.source%type;
    --
    l_allow_fundersul               VARCHAR2(01) ;                                         -- BUG 17056156
    l_fundersul_per_u_meas          NUMBER ;                                               -- BUG 17056156
    l_fundersul_unit_amount         NUMBER ;                                               -- BUG 17056156
    l_fundersul_unit_percent        NUMBER ;                                               -- BUG 17056156
    l_fundersul_additional_amount   NUMBER ;                                               -- BUG 17056156
    l_fundersul_amount              NUMBER ;                                               -- BUG 17056156
    l_org_name                      hr_all_organization_units.name%TYPE;                   -- BUG 17056156
    l_fundersul_own_flag            cll_f189_invoice_types.fundersul_own_flag%TYPE;        -- BUG 17056156
    l_fundersul_sup_part_flag       cll_f189_invoice_types.fundersul_sup_part_flag%TYPE;   -- BUG 17056156
    l_invoice_type_code             cll_f189_invoice_types.invoice_type_code%TYPE;         -- BUG 17056156
    l_requisition_type              cll_f189_invoice_types.requisition_type%TYPE;          -- 25961981
    l_return_customer_flag          cll_f189_invoice_types.return_customer_flag%TYPE;      -- 29908009
    --
    X_INVOICE_LINE_ID_S         NUMBER; --Bug 24387238
    X_INVOICE_ID_S              NUMBER; --ER 26338366/26899224 2a fase Third party network
    --
    -- Begin Bug 25985854
    l_ship_to_location_id       po_line_locations_all.ship_to_location_id%TYPE;
    l_ship_to_organization_id   po_line_locations_all.ship_to_organization_id%TYPE;
    l_po_header_id              po_line_locations_all.po_header_id%TYPE;
    l_po_line_id                po_line_locations_all.po_line_id%TYPE;
    l_org_id                    po_line_locations_all.org_id%TYPE;
    l_vendor_site_id            po_headers_all.vendor_site_id %TYPE;
    l_invoice_date              date;
    -- Princing
    x_base_unit_price           number;
    x_unit_price                number;
    x_return_status_pr          varchar2(100);
    -- End Bug 25985854

    -- 26366374 - Start
    l_po_project_id             po_distributions_all.project_id%TYPE;
    l_po_task_id                po_distributions_all.task_id%TYPE;
    l_po_expenditure_type       po_distributions_all.expenditure_type%TYPE;
    l_po_expenditure_org_id     po_distributions_all.expenditure_organization_id%TYPE;
    l_po_expenditure_item_date  po_distributions_all.expenditure_item_date%TYPE;
    -- 26366374 - End
    l_city_id                   NUMBER; -- 25591653
    l_city_serv_type_rel_id     NUMBER; -- 25591653
    l_iss_flag                  cll_f189_invoice_types.include_iss_flag%type; -- 25591653
    l_type_lookup_code          po_headers_all.type_lookup_code%type;         -- 28192844
    --
    l_rec_tpa_devol_ctrl        cll_f513_tpa_devolutions_ctrl %ROWTYPE ;      -- Enh 29907995
    l_crec_tpa_devol_ctrl       cll_f513_tpa_devolutions_ctrl %ROWTYPE ;      -- Enh 29907995
    --
  BEGIN
    print_log('  CREATE_OPEN_LINES');
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --103;
    --
    l_count := 0;
    -- Iniciando validacoes das Line
    -- ER 9028781 - Start
    BEGIN
      SELECT UPPER(ri.icms_type),simplified_br_tax_flag
      INTO l_icms_type, l_simplified_br_tax_flag
      FROM cll_f189_invoice_iface_tmp ri
      WHERE ri.interface_invoice_id = p_interface_invoice_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_icms_type := NULL;
        l_simplified_br_tax_flag := NULL;
    END;
    -- ER 9028781 - End
    print_log('  Inicio do Loop (invoice lines)'); 
    FOR r_invoice_lines IN c_invoice_lines LOOP
    --
      l_count := l_count + 1;

      -- Bug 26908937, 26997066, 25961981 - Inicio
      BEGIN
        SELECT 
          requisition_type
          ,include_iss_flag       -- 25591653
          ,return_customer_flag   -- 29908009
        INTO 
          l_requisition_type
          ,l_iss_flag             -- 25591653
          ,l_return_customer_flag -- 29908009
        FROM 
          cll_f189_invoices_interface  cfii,
          cll_f189_invoice_types       cfit
        WHERE cfii.interface_invoice_id  = p_interface_invoice_id
          AND cfii.organization_id       = p_organization_id
          AND cfii.invoice_type_id       = cfit.invoice_type_id
          AND cfii.organization_id       = cfit.organization_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_requisition_type := 'X';
          l_iss_flag := NULL; -- 25591653
      END;
      -- Bug 26908937, 26997066, 25961981 - Fim
      IF p_type = 'VALIDATION' THEN
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --104;
        -- 29908009 - Start
        IF l_return_customer_flag = 'F' THEN
          IF r_invoice_lines.interface_invoice_line_id IS NOT NULL THEN
            ADD_ERROR(
              p_invoice_id             => p_interface_invoice_id
              ,p_interface_operation_id => p_interface_operation_id
              ,p_organization_id        => p_organization_id
              ,p_error_code             => 'INVALID LINE IFACE NOT NULL'
              ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
              ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => NULL
            );
          END IF;
        END IF;
        -- 29908009 - End
        --------------------------------------------------------------------
        -- Validacoes iniciais na linha - campos obrigatorios preenchidos --
        --------------------------------------------------------------------
        IF r_invoice_lines.interface_invoice_line_id IS NULL THEN
          ADD_ERROR(
            p_invoice_id             => p_interface_invoice_id
            ,p_interface_operation_id => p_interface_operation_id
            ,p_organization_id        => p_organization_id
            ,p_error_code             => 'INTERFACE INVLINEID NULL'
            ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
            ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
            ,p_invalid_value          => NULL
          );
        END IF;
        --
        --
        IF r_invoice_lines.interface_invoice_id IS NULL THEN
          ADD_ERROR(
            p_invoice_id             => p_interface_invoice_id
            ,p_interface_operation_id => p_interface_operation_id
            ,p_organization_id        => p_organization_id
            ,p_error_code             => 'INTERFACE INVID NULL' --'INTERFACE LINEINVID NULL'
            ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
            ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
            ,p_invalid_value          => NULL
          );
        END IF;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
        --
        -- 25591653 - Start
        ---------------------------------
        -- Lines City Validation - ISS --
        ---------------------------------

        -- As informacoes do ISS nao serao obrigatorias para fornecedores optantes do regime SN.
        -- Porem se houver ISS na NF, a validacao seguira como uma nota normal.
          IF l_iss_flag = 'Y' AND NVL(l_simplified_br_tax_flag,'N') <> 'Y' THEN
            l_city_id := CLL_F189_OPEN_VALIDATE_PUB.GET_CITIES (
              p_iss_city_code => r_invoice_lines.iss_city_code
              ,p_iss_city_id   => r_invoice_lines.iss_city_id
            );
            --
            IF r_invoice_lines.iss_city_id IS NULL AND r_invoice_lines.iss_city_code IS NULL THEN
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'NULL ISS CITY'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => r_invoice_lines.iss_city_id
              );
            ELSIF r_invoice_lines.iss_city_id IS NOT NULL AND r_invoice_lines.iss_city_code IS NOT NULL THEN
              IF l_city_id IS NULL THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'INVALID ISS CITY'
                 ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                 ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => 'ID = '||r_invoice_lines.iss_city_id||' - CODE = '||r_invoice_lines.iss_city_code
                );
              END IF;
            ELSIF r_invoice_lines.iss_city_id IS NULL AND r_invoice_lines.iss_city_code IS NOT NULL THEN
              IF l_city_id IS NULL THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'NONE ISS CITY CODE'
                 ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                 ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => r_invoice_lines.iss_city_code
                );
              END IF;
            ELSIF r_invoice_lines.iss_city_id IS NOT NULL AND r_invoice_lines.iss_city_code IS NULL THEN
              IF l_city_id IS NULL THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                 ,p_interface_operation_id => p_interface_operation_id
                 ,p_organization_id        => p_organization_id
                 ,p_error_code             => 'INVALID CITY ID'
                 ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                 ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                 ,p_invalid_value          => r_invoice_lines.iss_city_id
                );
              END IF;
            END IF;
          END IF;
          -- 25591653 - End
          -------------------------------------
          -- Validando Tipo de Servico - ISS --
          -------------------------------------
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
          IF (r_invoice_lines.city_service_type_rel_code IS NULL     AND r_invoice_lines.city_service_type_rel_id IS NOT NULL) OR
             (r_invoice_lines.city_service_type_rel_code IS NOT NULL AND r_invoice_lines.city_service_type_rel_id IS NOT NULL) OR
             (r_invoice_lines.city_service_type_rel_code IS NOT NULL AND r_invoice_lines.city_service_type_rel_id IS NULL) THEN
            --
            l_city_serv_type_rel_id := NULL;
            IF r_invoice_lines.city_service_type_rel_id IS NULL AND r_invoice_lines.city_service_type_rel_code IS NOT NULL AND l_city_id IS NOT NULL THEN
              BEGIN
                SELECT city_service_type_rel_id
                INTO l_city_serv_type_rel_id
                FROM cll_f189_city_srv_type_rels
                WHERE city_service_type_rel_code = r_invoice_lines.city_service_type_rel_code
                  AND city_id = l_city_id
                  AND (inactive_date IS NULL OR TRUNC (inactive_date) >= TRUNC(sysdate));
              EXCEPTION WHEN OTHERS THEN
                l_city_serv_type_rel_id := NULL;
              END;
            END IF;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
            l_city_serv_type_rel_id := NVL(l_city_serv_type_rel_id,r_invoice_lines.city_service_type_rel_id);
            
            CLL_F189_VALID_RULES_PKG.GET_CITY_SERV_TYPE_RELS_VRULES (
              p_city_service_type_rel_id     => l_city_serv_type_rel_id
              ,p_city_service_type_rel_code   => r_invoice_lines.city_service_type_rel_code
              ,p_invoice_type_id              => p_invoice_type_id
              -- out
              ,p_federal_service_type_id      => l_federal_service_type_id
              ,p_municipal_service_type_id    => l_municipal_service_type_id
              ,p_city_service_type_rel_id_out => l_city_service_type_rel_id
              ,p_iss_tax_type                 => l_iss_tax_type
            );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
            IF l_iss_tax_type IS NULL THEN
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'INVALID SERVTYPE'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => 'ID = '||r_invoice_lines.city_service_type_rel_id||' - CODE = '||r_invoice_lines.city_service_type_rel_code
              );
            ELSE
              IF l_iss_tax_type = 'SUBSTITUTE' THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
                IF r_invoice_lines.iss_base_amount IS NULL THEN
                  ADD_ERROR(
                    p_invoice_id             => p_interface_invoice_id
                    ,p_interface_operation_id => p_interface_operation_id
                    ,p_organization_id        => p_organization_id
                    ,p_error_code             => 'NULL LINEISSBASE'
                    ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                    ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                    ,p_invalid_value          => NULL
                  );
                END IF;
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
                IF r_invoice_lines.iss_tax_rate IS NULL THEN
                  ADD_ERROR(
                    p_invoice_id             => p_interface_invoice_id
                    ,p_interface_operation_id => p_interface_operation_id
                    ,p_organization_id        => p_organization_id
                    ,p_error_code             => 'NULL LINEISSTAX'
                    ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                    ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                    ,p_invalid_value          => NULL
                  );
                END IF;
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --105;
                IF r_invoice_lines.iss_tax_amount IS NULL THEN
                  ADD_ERROR(
                    p_invoice_id             => p_interface_invoice_id
                    ,p_interface_operation_id => p_interface_operation_id
                    ,p_organization_id        => p_organization_id
                    ,p_error_code             => 'NULL LINEISSAMT'
                    ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                    ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                    ,p_invalid_value          => NULL
                  );
                END IF;
              END IF; --IF l_iss_tax_type = 'SUBSTITUTE' THEN
            END IF; --IF l_iss_tax_type IS NULL THEN
          END IF; --IF (r_invoice_lines.city_service_type_rel_code IS NULL     AND r_invoice_lines.city_service_type_rel_id IS NOT NULL) OR
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --106;
          --
          print_log('  line_location_id:'||r_invoice_lines.line_location_id);
          IF r_invoice_lines.line_location_id IS NOT NULL THEN
            IF p_vendor_id IS NULL THEN
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --106;
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'INVALID POSHIPMENT'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => NULL
              );
            END IF;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --108;
            IF p_price_adjust_flag = 'N' AND p_cost_adjust_flag = 'N' AND p_tax_adjust_flag = 'N' THEN
              IF (p_fixed_assets_flag IN ('S', 'O') AND p_parent_flag = 'Y') THEN
                NULL;
              ELSE
                CLL_F189_OPEN_VALIDATE_PUB.GET_PURCHASE_ORDERS(p_line_location_id      => r_invoice_lines.line_location_id
                  ,p_organization_id       => p_organization_id
                  ,p_location_id           => p_location_id
                  ,p_vendor_id             => p_vendor_id
                  ,p_operating_unit        => NULL
                  ,p_purchase_order_num    => NULL
                  ,p_line_num              => NULL
                  ,p_shipment_num          => NULL
                  -- out
                  ,p_item_id_oc           => l_item_id_oc
                  ,p_line_location_id_out => l_line_location_id
                  ,p_possui_item          => l_possui_item -- Bug 17334612
                );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --107;
                --
                IF l_possui_item > 0 THEN  -- Bug 17334612
                  IF r_invoice_lines.item_id IS NULL THEN -- Bug 17334612
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --108;
                    ADD_ERROR(
                      p_invoice_id             => p_interface_invoice_id
                      ,p_interface_operation_id => p_interface_operation_id
                      ,p_organization_id        => p_organization_id
                      ,p_error_code             => 'NONE ITEM' --'INVALID POSHIPMENT'
                      ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                      ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                      ,p_invalid_value          => NULL
                    );
                  ELSE
                    IF r_invoice_lines.item_id <> l_item_id_oc THEN
                      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --108;
                      ADD_ERROR(
                        p_invoice_id             => p_interface_invoice_id
                        ,p_interface_operation_id => p_interface_operation_id
                        ,p_organization_id        => p_organization_id
                        ,p_error_code             => 'INVALID ITEM'
                        ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                        ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                        ,p_invalid_value          => NULL
                      );
                    END IF;
                  END IF;
                END IF; --IF l_possui_item > 0 THEN  -- Bug 17334612
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --108;
              END IF; --IF (p_fixed_assets_flag IN ('S', 'O') AND p_parent_flag = 'Y') THEN
            END IF; --IF p_price_adjust_flag = 'N' AND p_cost_adjust_flag = 'N' AND p_tax_adjust_flag = 'N' THEN
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --108;
            --
            CLL_F189_OPEN_VALIDATE_PUB.GET_PO_LINES_AND_LOCATIONS(
              p_line_location_id      => r_invoice_lines.line_location_id
              -- out
              ,p_unit_price            => l_unit_price
              ,p_unit_meas_lookup_code => l_unit_meas_lookup_code
              ,p_item_id               => l_item_id
              ,p_price_override        => l_price_override
            );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --108;
            -- Inicio BUG 19688888
            BEGIN
              SELECT vendor_id
              INTO l_vendor_id
              FROM 
                po_headers_all pha,
                po_line_locations_all plla
              WHERE 1=1
                and plla.po_header_id     = pha.po_header_iD
                AND plla.line_location_id = r_invoice_lines.line_location_id
                AND rownum = 1;
            EXCEPTION WHEN NO_DATA_FOUND THEN
              l_vendor_id := 0;
            END;
            --
            IF p_vendor_id <> l_vendor_id THEN
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'VENDOR ID INVALID'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => NULL
              );
            END IF;
            -- Fim BUG 19688888
            --
            -- UOM PO VALIDATE
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --109;
            --
            IF r_invoice_lines.uom_po IS NULL THEN
              l_uom_po := l_unit_meas_lookup_code;
            ELSE
              l_uom_po := r_invoice_lines.uom_po;
              --
              IF r_invoice_lines.uom_po <> l_unit_meas_lookup_code THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --108;
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'UOM OC INVALID'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => NULL
                );
              END IF;
            END IF;
            --
            -- QUANTITY UOM PO VALIDATE
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --110;
            --
            l_quantity_uom_po := r_invoice_lines.quantity;
            --
            IF r_invoice_lines.quantity_uom_po IS NULL THEN
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
              CLL_F189_UOM_PKG.UOM_CONV_QTY ( 
                p_from_uom   => r_invoice_lines.uom
                , p_to_uom     => l_unit_meas_lookup_code
                , p_item_id    => l_item_id
                , p_quantity   => l_quantity_uom_po
              );
            ELSE
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
              CLL_F189_UOM_PKG.UOM_CONV_QTY ( 
                p_from_uom   => r_invoice_lines.uom
                , p_to_uom     => r_invoice_lines.uom_po
                , p_item_id    => r_invoice_lines.item_id
                , p_quantity   => l_quantity_uom_po
              );
              --
              IF r_invoice_lines.quantity_uom_po <> l_quantity_uom_po THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'QTY UOM OC INVALID'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => NULL
                );
              END IF;
            END IF;
            --
            -- UNIT PRICE UOM PO VALIDATE
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --111;
            --
            l_unit_price_uom_po := r_invoice_lines.unit_price;
            --
            IF r_invoice_lines.unit_price_uom_po IS NULL THEN
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
              CLL_F189_UOM_PKG.UOM_CONV_PRICE( 
                p_from_uom   => r_invoice_lines.uom
                , p_to_uom     => l_unit_meas_lookup_code
                , p_item_id    => l_item_id
                , p_unit_price => l_unit_price_uom_po -- IN OUT
                -- out
                , p_uom_rate   => l_rate_uom_po
                , p_status     => l_conv_status_uom_po
              );
              --
              IF l_conv_status_uom_po = 'CONV NULL' THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'CONV NOT NULL'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => NULL
                );
              ELSIF l_conv_status_uom_po = 'NO CONV UOM' THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'INVALID UOM CONV'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => NULL
                );
              END IF;
            ELSE
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
              CLL_F189_UOM_PKG.UOM_CONV_PRICE(
                p_from_uom   => r_invoice_lines.uom
                , p_to_uom     => r_invoice_lines.uom_po
                , p_item_id    => r_invoice_lines.item_id
                , p_unit_price => l_unit_price_uom_po --IN OUT
                -- out
                , p_uom_rate   => l_rate_uom_po
                , p_status     => l_conv_status_uom_po
              );
              --
              IF l_conv_status_uom_po = 'CONV NULL' THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'CONV NOT NULL'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => NULL
                );
              ELSIF l_conv_status_uom_po = 'NO CONV UOM' THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'INVALID UOM CONV'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => NULL
                );
              END IF;
              --
              IF r_invoice_lines.unit_price_uom_po <> l_unit_price_uom_po THEN
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'UNIT PRICE UOM OC INVALID'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => NULL
                );
              END IF; --IF r_invoice_lines.unit_price_uom_po <> l_unit_price_uom_po THEN
            END IF; --IF r_invoice_lines.unit_price_uom_po IS NULL THEN
          --
          ELSE -- IF r_invoice_lines.line_location_id IS NOT NULL THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
            IF r_invoice_lines.purchase_order_num IS NOT NULL OR r_invoice_lines.line_num IS NOT NULL OR r_invoice_lines.shipment_num IS NOT NULL THEN
              CLL_F189_OPEN_VALIDATE_PUB.GET_PURCHASE_ORDERS(
                p_line_location_id      => NULL
                ,p_organization_id       => NULL
                ,p_location_id           => NULL
                ,p_vendor_id             => NULL
                ,p_operating_unit        => p_operating_unit
                ,p_purchase_order_num    => r_invoice_lines.purchase_order_num
                ,p_line_num              => r_invoice_lines.line_num
                ,p_shipment_num          => r_invoice_lines.shipment_num
                -- out
                ,p_item_id_oc           => l_item_id_oc
                ,p_line_location_id_out => l_line_location_id
                ,p_possui_item          => l_possui_item -- Bug 17334612
              );
              --
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
              IF l_line_location_id IS NULL THEN
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'PO NOT FOUND'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => NULL
                );
              END IF;
              -- Bug 26908937, 26997066, 25961981 - Inicio
              /*
              -- 25961981 - Start
              ELSE
                 BEGIN
                    SELECT requisition_type
                    INTO l_requisition_type
                    FROM cll_f189_invoices_interface  cfii,
                         cll_f189_invoice_types       cfit
                   WHERE cfii.interface_invoice_id  = p_interface_invoice_id
                     AND cfii.organization_id       = p_organization_id
                     AND cfii.invoice_type_id       = cfit.invoice_type_id
                     AND cfii.organization_id       = cfit.organization_id;
                 EXCEPTION WHEN NO_DATA_FOUND THEN
                    l_requisition_type := 'X';
                 END;
                 --
                 IF l_requisition_type <> 'NA' THEN
                    IF l_line_location_id IS NULL THEN
                       ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                ,p_interface_operation_id => p_interface_operation_id
                                ,p_organization_id        => p_organization_id
                                ,p_error_code             => 'PO NOT FOUND'
                                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                ,p_invalid_value          => NULL
                                );
                    END IF;
                 END IF;
              -- 25961981 - End
              */
            ELSE
            IF l_requisition_type = 'PO' THEN
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'PO NOT FOUND'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => NULL
              );
            END IF;
            -- Bug 26908937, 26997066, 25961981 - Fim
          END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);
            IF (r_invoice_lines.uom_po IS NOT NULL OR r_invoice_lines.quantity_uom_po IS NOT NULL OR r_invoice_lines.unit_price_uom_po IS NOT NULL) THEN
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'NULL PO'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => 'LINE_LOCATION_ID = '||r_invoice_lines.line_location_id
              );
            END IF;
              --
          END IF; -- IF r_invoice_lines.line_location_id IS NOT NULL THEN
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --112;
          --
          IF r_invoice_lines.requisition_line_id IS NOT NULL AND r_invoice_lines.shipment_line_id IS NOT NULL THEN
            --
            l_item_id_rsl := CLL_F189_OPEN_VALIDATE_PUB.GET_REQUISITION_RCV(
              p_organization_id     => p_organization_id
              ,p_shipment_line_id    => r_invoice_lines.shipment_line_id
              ,p_requisition_line_id => r_invoice_lines.requisition_line_id
            );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --113;
            --
            IF l_item_id_rsl IS NULL THEN
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'INVALID REQUISITION'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => NULL
              );
            END IF;
            --
            IF r_invoice_lines.requisition_line_id IS NOT NULL AND r_invoice_lines.shipment_line_id IS NULL THEN
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'INVALID SHIPMENT LINE ID'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => NULL
              );
            END IF;
          END IF; --IF r_invoice_lines.requisition_line_id IS NOT NULL AND r_invoice_lines.shipment_line_id IS NOT NULL THEN
          --
          --
          -- Bug 26908937, 26997066, 25961981 - Inicio
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --116;
          IF r_invoice_lines.requisition_line_id IS NULL AND l_requisition_type = 'OE' THEN
            ADD_ERROR(
              p_invoice_id              => p_interface_invoice_id
              ,p_interface_operation_id => p_interface_operation_id
              ,p_organization_id        => p_organization_id
              ,p_error_code             => 'OE NOT FOUND'
              ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
              ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
              ,p_invalid_value          => NULL
            );
          END IF;
          -- Bug 26908937, 26997066, 25961981 - Fim
          --
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --114;
          --
          IF r_invoice_lines.rma_interface_id IS NOT NULL AND (p_qtde_nf_compl = 0 AND p_parent_flag = 'N') THEN -- Bug 16600918
            --
            l_item_id_rma := CLL_F189_OPEN_VALIDATE_PUB.GET_RMA_RECEIPTS(
              p_entity_id        => p_entity_id
              ,p_rma_interface_id => r_invoice_lines.rma_interface_id  -- Bug 16600918
            );
            --
            IF l_item_id_rma IS NULL THEN
              ADD_ERROR(
                p_invoice_id             => p_interface_invoice_id
                ,p_interface_operation_id => p_interface_operation_id
                ,p_organization_id        => p_organization_id
                ,p_error_code             => 'INVALID RMA'
                ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                ,p_invalid_value          => NULL
              );
            END IF;
          END IF;
          --
          --
          -- Bug 26908937, 26997066, 25961981 - Inicio
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --117;
          IF r_invoice_lines.rma_interface_id IS NULL AND
             l_requisition_type = 'RM' THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'RM NOT FOUND'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          END IF;
          -- Bug 26908937, 26997066, 25961981 - Fim
          --
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --115;
          --
          -- Bug 18404395 - Inicio
          IF p_price_adjust_flag = 'N' AND p_cost_adjust_flag = 'N' AND p_tax_adjust_flag = 'N' THEN    --<< bug 17662162 - Egini - 31/10/2013 >>--
             IF (p_fixed_assets_flag IN ('S', 'O') AND p_parent_flag = 'Y') THEN                        --<< bug 17662162 - Egini - 31/10/2013 >>--
                 NULL;                                                                                  --<< bug 17662162 - Egini - 31/10/2013 >>--
             ELSE                                                                                      --<< bug 17662162 - Egini - 31/10/2013 >>--
             -- Bug 18404395 - Fim
                --
                IF (l_item_id_oc  IS NULL AND NVL(l_line_location_id,r_invoice_lines.line_location_id) IS NOT NULL) OR
                   (l_item_id_rsl IS NULL AND r_invoice_lines.requisition_line_id IS NOT NULL) OR
                   (l_item_id_rma IS NULL AND r_invoice_lines.rma_interface_id IS NOT NULL) THEN
                   --
                   CLL_F189_OPEN_VALIDATE_PUB.GET_DISTRIBUTIONS(p_line_location_id      => NVL(l_line_location_id,r_invoice_lines.line_location_id)
                                                                -- out
                                                               ,p_destination_type_code => l_destination_type_code
                                                               ,p_project_exists        => l_project_exists
                                                               );
                   --
                   IF l_destination_type_code NOT IN ('EXPENSE','SHOP FLOOR') THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'NONE ITEM'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => NULL
                           );
                   END IF; --IF l_destination_type_code NOT IN ('EXPENSE','SHOP FLOOR') THEN
                END IF;
                --
                -- Bug 18404395 - Inicio
             END IF;  --IF p_price_adjust_flag = 'N' AND p_cost_adjust_flag = 'N' AND p_tax_adjust_flag = 'N' THEN   --<< bug 17662162 - Egini - 31/10/2013 >>--
          END IF; --IF (p_fixed_assets_flag IN ('S', 'O') AND p_parent_flag = 'Y') THEN                              --<< bug 17662162 - Egini - 31/10/2013 >>--
          -- Bug 18404395 - Fim
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --120;
          --
          IF NVL(l_line_location_id,r_invoice_lines.line_location_id) IS NULL AND r_invoice_lines.requisition_line_id IS NULL AND r_invoice_lines.rma_interface_id IS NULL THEN
              IF r_invoice_lines.db_code_combination_id IS NULL then
                  IF p_contab_flag IN ('N','I') AND p_payment_flag = 'N' THEN
                     NULL;
                  ELSE
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID LINE'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  END IF; -- Bug 7454400 - SSimoes - 21/10/2008
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --121;
          --
          IF r_invoice_lines.db_code_combination_id IS NOT NULL THEN
              --
              l_code_combination_id := CLL_F189_OPEN_VALIDATE_PUB.GET_GL_CODE_COMBINATIONS(
                p_chart_of_accounts_id   => p_chart_of_accounts_id
                ,p_db_code_combination_id => r_invoice_lines.db_code_combination_id
              );
              --
              IF l_code_combination_id IS NULL THEN
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'INVALID CCOMBINATION'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => r_invoice_lines.db_code_combination_id
                );
              END IF;
          END IF;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --122;
          --
          ---------------------------
          -- Fiscal Classification --
          ---------------------------
          IF r_invoice_lines.classification_id IS NULL AND r_invoice_lines.classification_code IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL CLASSIFICATION'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          ELSE
              l_classification_id := CLL_F189_OPEN_VALIDATE_PUB.GET_FISCAL_CLASSIFICATION(p_classification_id        => r_invoice_lines.classification_id
                                                                                         ,p_classification_code      => r_invoice_lines.classification_code
                                                                                         ,p_exception_classific_code => r_invoice_lines.exception_classification_code
                                                                                         );
              --
              IF r_invoice_lines.classification_id IS NOT NULL AND r_invoice_lines.classification_code IS NULL THEN
                  --
                  IF l_classification_id IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID CLASSIFICATION ID'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.classification_id
                               );
                  END IF;
              ELSIF r_invoice_lines.classification_id IS NULL AND r_invoice_lines.classification_code IS NOT NULL THEN
                  --
                  IF l_classification_id IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID CLASSIFICATION CODE'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.classification_code||' - EX-TIPI = '||r_invoice_lines.exception_classification_code
                               );
                  END IF;
              ELSE
                  --
                  IF l_classification_id IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID CLASSIFICATION'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => 'ID = '||r_invoice_lines.classification_id||' - CODE = '||r_invoice_lines.classification_code||' - EX-TIPI = '||r_invoice_lines.exception_classification_code
                               );
                  END IF;
              END IF;
          END IF; --IF r_invoice_lines.classification_id IS NULL AND r_invoice_lines.classification_code IS NULL THEN
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --123;
          --
          -----------------
          -- Intende Use --
          -----------------
          IF r_invoice_lines.utilization_id IS NULL AND r_invoice_lines.utilization_code IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL UTILIZATION'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          ELSE
              --
              l_utilization_id := CLL_F189_VALID_RULES_PKG.GET_ITEM_UTILIZATIONS_VRULES(p_utilization_id   => r_invoice_lines.utilization_id
                                                                                       ,p_utilization_code => r_invoice_lines.utilization_code
                                                                                       ,p_invoice_type_id  => p_invoice_type_id
                                                                                       );
              --
              IF ( (r_invoice_lines.utilization_id IS NOT NULL AND r_invoice_lines.utilization_code IS NULL) OR
                 (r_invoice_lines.utilization_id IS NOT NULL AND r_invoice_lines.utilization_code IS NOT NULL) ) THEN -- Bug 17442462
                  --
                  IF l_utilization_id IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID UTILIZATION ID'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.utilization_id
                               );
                  END IF;
              ELSIF r_invoice_lines.utilization_id IS NULL AND r_invoice_lines.utilization_code IS NOT NULL THEN
                  --
                  IF l_utilization_id IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID UTILIZATION CODE'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.utilization_code
                               );
                  END IF;
              ELSE
                  --
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID UTILIZATION'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => 'ID = '||r_invoice_lines.utilization_id||' - CODE = '||r_invoice_lines.utilization_code
                           );
              END IF;
          END IF; --IF r_invoice_lines.utilization_id IS NULL AND r_invoice_lines.utilization_code IS NULL THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --124;
          -- Bug 17442462 - Start
          l_source_state_id      := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => p_source_state_id
                                                                          ,p_state_code => p_source_state_code);
          --
          l_destination_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => p_destination_state_id
                                                                          ,p_state_code => p_destination_state_code);
          -- Bug 17442462 - End
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --125;
          ----------
          -- CFOP --
          ----------
          IF r_invoice_lines.cfo_id IS NULL AND r_invoice_lines.cfo_code IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL INVLINECFO'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          ELSE
          -- 27579747 - Start
            IF g_source = 'CLL_F369 EFD LOADER SHIPPER' THEN
            BEGIN
              SELECT cfo.cfo_id
              INTO l_cfo_id
              FROM 
                cll_f189_fiscal_operations cfo
                , cll_f189_validity_rules cfvr
              WHERE 1=1
                and cfo.cfo_id   = NVL(r_invoice_lines.cfo_id,cfo.cfo_id)
                AND cfo.cfo_code = NVL(r_invoice_lines.cfo_code,cfo.cfo_code)
                AND NVL(cfo.inactive_date,SYSDATE) >= SYSDATE
                AND cfo.cfo_id = cfvr.validity_key_1
                AND cfvr.invoice_type_id = p_invoice_type_id
                AND cfvr.validity_type   = 'CFO'
              ;
            EXCEPTION WHEN OTHERS THEN
              l_cfo_id := NULL;
            END;
          ELSE
            -- 27579747 - End
            l_cfo_id := CLL_F189_VALID_RULES_PKG.GET_FISCAL_OPERATIONS_VRULES(
              p_cfo_id                 => r_invoice_lines.cfo_id
              ,p_cfo_code              => r_invoice_lines.cfo_code
              ,p_invoice_type_id       => p_invoice_type_id
              ,p_freight_flag          => p_freight_flag_inv_type
              ,p_freight_flag_inv_type => NULL
              -- Bug 17442462 - Start
              --,p_source_state_id       => p_source_state_id
              --,p_destination_state_id  => p_destination_state_id
              ,p_source_state_id       => l_source_state_id
              ,p_destination_state_id  => l_destination_state_id
              -- Bug 17442462 - End
              ,p_cfo_transporter       => NULL
            );
          END IF; -- 27579747
            --
            IF r_invoice_lines.cfo_id IS NOT NULL AND r_invoice_lines.cfo_code IS NULL THEN
              --
              IF l_cfo_id IS NULL THEN
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'INVALID INVLINECFO ID'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => r_invoice_lines.cfo_id
                );
              END IF;
            ELSIF r_invoice_lines.cfo_id IS NULL AND r_invoice_lines.cfo_code IS NOT NULL THEN
              --
              IF l_cfo_id IS NULL THEN
                ADD_ERROR(
                  p_invoice_id              => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'INVALID INVLINECFO CODE'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => r_invoice_lines.cfo_code
                );
              END IF;
            ELSE
              --
              IF l_cfo_id IS NULL THEN
                ADD_ERROR(
                  p_invoice_id             => p_interface_invoice_id
                  ,p_interface_operation_id => p_interface_operation_id
                  ,p_organization_id        => p_organization_id
                  ,p_error_code             => 'INVALID INVLINECFO'
                  ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                  ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                  ,p_invalid_value          => 'ID = '||r_invoice_lines.cfo_id||' CODE = '||r_invoice_lines.cfo_code
                );
              END IF;
            END IF; --IF r_invoice_lines.cfo_id IS NOT NULL AND r_invoice_lines.cfo_code IS NULL THEN
          END IF; --IF r_invoice_lines.cfo_id IS NULL AND r_invoice_lines.cfo_code IS NULL THEN
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --126;
          --
          -- <<Bug 17375006 - Egini - 01/09/2013 - Inicio >>--
          ------------------------
          --        CFOP        --
          ------------------------
          l_cfo_id := CLL_F189_OPEN_VALIDATE_PUB.GET_CFO(
            p_cfo_id    => NVL(r_invoice_lines.cfo_id,l_cfo_id)
            ,p_cfo_code  => NVL(r_invoice_lines.cfo_code,l_cfo_code)
          );
          -- <<Bug 17375006 - Egini - 01/09/2013 - Fim >>--
          ------------------------
          -- CFOP x Intende Use --
          ------------------------
          --
          l_utilization_cfo := CLL_F189_OPEN_VALIDATE_PUB.GET_CFO_UTILIZATIONS (
            p_cfo_id           => NVL(r_invoice_lines.cfo_id,l_cfo_id)
            ,p_utilization_id   => NVL(r_invoice_lines.utilization_id,l_utilization_id)
            ,p_utilization_code => NVL(r_invoice_lines.utilization_code,l_utilization_code)  -- <<Bug 17375006 - Egini - 01/09/2013 >>--
            ,p_cfo_code         => nvl(r_invoice_lines.cfo_code, l_cfo_code)                 -- <<Bug 17375006 - Egini - 01/09/2013 >>--
          );
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --127;
          --
          IF l_utilization_cfo IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'INVALID CFOUTILIZATION'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => 'CFO ID = '||NVL(r_invoice_lines.cfo_id,l_cfo_id)||' INTENDED USE ID = '||NVL(r_invoice_lines.utilization_id,l_utilization_id)
                       );
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --128;
          ---------
          -- UOM --
          ---------
          IF r_invoice_lines.uom IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL UOM'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
           ELSE
              --
              l_unit_of_measure := CLL_F189_OPEN_VALIDATE_PUB.GET_UOM ( p_uom => r_invoice_lines.uom );
              --
              IF l_unit_of_measure IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID UOM'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.uom
                           );
              END IF;
              --
              IF r_invoice_lines.quantity IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'NULL LINEQUANTITY'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => NULL
                           );
              END IF;
              --
              IF r_invoice_lines.quantity = 0 AND NVL(p_tax_adjust_flag,'N') = 'N' THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'LINEQUANTITY ZERO'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => NULL
                           );
              END IF;
              --
              IF r_invoice_lines.unit_price IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'NULL LINEPRICE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => NULL
                           );
              END IF;
              --
          END IF; --IF r_invoice_lines.uom IS NULL THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --129;
          ---------------------------
          -- Fiscal Operation Type --
          ---------------------------
          IF r_invoice_lines.operation_fiscal_type IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL OPFISCALTYPE'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          ELSE
              --
              l_operation_fiscal_type := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES (p_lookup_type => 'CLL_F189_OPERATION_FISCAL_TYPE'
                                                                               ,p_lookup_code => r_invoice_lines.operation_fiscal_type
                                                                               );
              --
              IF l_operation_fiscal_type IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID OPFISCALTYPE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.operation_fiscal_type
                           );
              END IF;
          END IF; --IF r_invoice_lines.operation_fiscal_type IS NULL THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --130;
          ----------
          -- Item --
          ----------
          IF r_invoice_lines.item_id IS NULL AND r_invoice_lines.description IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL ITEM' --'NULL DESCRIPTION'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          ELSE
              --
              IF r_invoice_lines.item_id IS NOT NULL THEN
                  --
                  l_item_description := CLL_F189_OPEN_VALIDATE_PUB.GET_MTL_SYSTEM_ITEMS (p_item_id         => r_invoice_lines.item_id
                                                                                        ,p_organization_id => p_organization_id
                                                                                        );
                  --
                  IF l_item_description IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'ITEM NOT FOUND ID'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.item_id
                               );
                  END IF;
              END IF; --IF r_invoice_lines.item_id IS NOT NULL THEN
          END IF; --IF r_invoice_lines.item_id IS NULL AND r_invoice_lines.description IS NULL THEN
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --131;
          --
          -- ER 9028781 - Start
          IF l_icms_type <> 'INV LINES INF' AND r_invoice_lines.icms_type IS NOT NULL THEN
             ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                      ,p_interface_operation_id => p_interface_operation_id
                      ,p_organization_id        => p_organization_id
                      ,p_error_code             => 'ICMS_TYPE_INCORRECT'
                      ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                      ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                      ,p_invalid_value          => r_invoice_lines.icms_base
                       );
          END IF;
          --
          IF l_simplified_br_tax_flag = 'Y' THEN
             --
             IF l_icms_type = 'INV LINES INF' THEN
                --
                IF nvl(r_invoice_lines.icms_base,0) > 0 THEN
                   ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                            ,p_interface_operation_id => p_interface_operation_id
                            ,p_organization_id        => p_organization_id
                            ,p_error_code             => 'ICMS CALC BASIS NOT NULL'
                            ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                            ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                            ,p_invalid_value          => r_invoice_lines.icms_base
                            );
                END IF ;
                --
                IF NVL(r_invoice_lines.icms_amount,0) > 0 THEN
                   ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                            ,p_interface_operation_id => p_interface_operation_id
                            ,p_organization_id        => p_organization_id
                            ,p_error_code             => 'ICMS AMOUNT NOT NULL'
                            ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                            ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                            ,p_invalid_value          => r_invoice_lines.icms_amount
                            );
                END IF;
               --
             END IF;
          ELSE
             IF l_icms_type = 'INV LINES INF' THEN
                --
                IF NVL(r_invoice_lines.max_icms_amount_recover,0) > 0 THEN
                   ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                            ,p_interface_operation_id => p_interface_operation_id
                            ,p_organization_id        => p_organization_id
                            ,p_error_code             => 'MAX ICMS REC AMT NOT NULL'
                            ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                            ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                            ,p_invalid_value          => r_invoice_lines.max_icms_amount_recover
                            );
                END IF;
                --
                IF nvl(r_invoice_lines.icms_tax_rec_simpl_br,0) > 0 THEN
                   ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                            ,p_interface_operation_id => p_interface_operation_id
                            ,p_organization_id        => p_organization_id
                            ,p_error_code             => 'ICMS REC RATE NOT NULL'
                            ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                            ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                            ,p_invalid_value          => r_invoice_lines.icms_tax_rec_simpl_br
                            );
                END IF;
               --
             END IF;
             -- ER 9028781 - End
             l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --132;
             IF r_invoice_lines.icms_base IS NULL THEN
-- 27579747 - Start
--                  IF  NVL(l_source,NULL) <> 'CLL_F369 EFD LOADER' THEN -- BUG 23018594
                IF  NVL(l_source,NULL) NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'NULL LINEICMSBASE'
                             ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                             ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                END IF; -- BUG 23018594
             ELSE
                -- ER 9028781 - Start
                IF l_icms_type = 'INV LINES INF' THEN
                   --
                   IF r_invoice_lines.icms_type = 'NORMAL' AND r_invoice_lines.icms_base < 0 THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID ICMSBASE'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.icms_base
                               );
                   ELSIF r_invoice_lines.icms_type = 'NOT APPLIED' AND r_invoice_lines.icms_base <> 0 THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID ICMSBASE'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.icms_base
                               );
                   END IF;
                   --
                END IF;
                -- ER 9028781 - End
             END IF;
             --
             l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --133;
             --
             IF r_invoice_lines.icms_amount IS NULL THEN
-- 27579747 - Start
--                 IF  NVL(l_source,NULL) <> 'CLL_F369 EFD LOADER' THEN -- BUG 23018594
               IF  NVL(l_source,NULL) NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
                 ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                          ,p_interface_operation_id => p_interface_operation_id
                          ,p_organization_id        => p_organization_id
                          ,p_error_code             => 'NULL LINEICMSAMT'
                          ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                          ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                          ,p_invalid_value          => NULL
                          );
               END IF; -- BUG 23018594
             -- ER 9028781 - Start
             ELSE
                --
                IF l_icms_type = 'INV LINES INF' THEN
                   --
                   IF r_invoice_lines.icms_type = 'NORMAL' AND r_invoice_lines.icms_amount < 0 THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID ICMSAMT'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.icms_amount
                               );
                   ELSIF r_invoice_lines.icms_type = 'NOT APPLIED' AND r_invoice_lines.icms_amount <> 0 THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'INVALID ICMSAMTNOT' --'INVALID ICMSAMT'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.icms_amount
                               );
                   END IF;
                   -- ER 9028781 - End
                END IF;
             END IF;
             --
          END IF;-- ER 9028781
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --134;
          ------------------------------
          -- Validacoes valores nulos --
          ------------------------------
          -- Inicio BUG 23018594
          BEGIN
            SELECT source
              INTO l_source
              FROM cll_f189_invoices_interface
             WHERE invoice_id             = p_interface_invoice_id
               AND interface_operation_id = p_interface_operation_id
               AND organization_id        = p_organization_id;
          EXCEPTION WHEN NO_DATa_FOUND THEN
            l_source := NULL;
          END;
          --
-- 27579747 - Start
--            IF  NVL(l_source,NULL) <> 'CLL_F369 EFD LOADER' THEN -- BUG 23018594
          IF  NVL(l_source,NULL) NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
            IF r_invoice_lines.icms_tax IS NULL THEN
               ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                        ,p_interface_operation_id => p_interface_operation_id
                        ,p_organization_id        => p_organization_id
                        ,p_error_code             => 'NULL LINEICMSTAX'
                        ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                        ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                        ,p_invalid_value          => NULL
                        );
            END IF;
            --
            IF r_invoice_lines.icms_amount_recover IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL LINEICMSAMTREC'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
            END IF;
            --
            IF r_invoice_lines.diff_icms_tax IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL LINEDIFICMSTAX'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
            END IF;
            --
            IF r_invoice_lines.diff_icms_amount IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL LINEDIFICMSAMT'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
            END IF;
            --
            IF r_invoice_lines.diff_icms_amount_recover IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL LINEDIFICMSAMTREC'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
            END IF;
            --
          END IF; -- Bug 23018594
          --
          IF r_invoice_lines.net_amount IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL LINENETAMT'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --135;
          --
-- 27579747 - Start
--            IF  NVL(l_source,NULL) <> 'CLL_F369 EFD LOADER' THEN
          IF  NVL(l_source,NULL) NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
          -- fim BUG 21909282
            IF r_invoice_lines.ipi_base_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL LINEIPIBASE'
                         ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                         ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
            --
            IF r_invoice_lines.ipi_tax IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL LINEIPITAX'
                         ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                         ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                       );
            END IF;
            --
            IF r_invoice_lines.ipi_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL LINEIPIAMT'
                         ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                         ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
            --
          END IF; -- BUG 21909282
          --
          IF r_invoice_lines.ipi_amount_recover IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL LINEIPIAMTREC'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          END IF;
          --
-- 27579747 - Start
--            IF  NVL(l_source,NULL) <> 'CLL_F369 EFD LOADER' THEN -- BUG 25543706
          IF  NVL(l_source,NULL) NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
            IF r_invoice_lines.total_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL LINETOTALAMT'
                         ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                         ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
          END IF; -- BUG 25543706
          --
          IF r_invoice_lines.discount_percent IS NOT NULL THEN
              IF r_invoice_lines.discount_percent <= 0 THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID LINEDISCOUNT'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.discount_percent
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --136;
          ------------------------
          -- Validando CST ICMS --
          ------------------------
          IF r_invoice_lines.tributary_status_code IS NOT NULL THEN
              l_validation_rule_cst_icms := CLL_F189_VALID_RULES_PKG.GET_TRIBUTARY_SITUATION_VRULES (p_tributary_status_code => r_invoice_lines.tributary_status_code
                                                                                                    ,p_invoice_type_id       => p_invoice_type_id
                                                                                                    ,p_invoice_date          => p_invoice_date -- 22012023
                                                                                                    );
              --
              IF l_validation_rule_cst_icms IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID TRIB STATUS CODE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.tributary_status_code
                           );
              END IF;
          END IF;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --137;
          -------------------------
          -- Validando ICMS Code --
          -------------------------
-- 29055483 - Start
        IF NVL(l_source,NULL) NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 29055483 - End
          IF r_invoice_lines.icms_tax_code IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL LINEICMSTAXCODE'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          ELSE
              l_validation_rule_icms := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_STATE_TRIBUT_CODE'
                                                                                              ,p_code            => r_invoice_lines.icms_tax_code
                                                                                              ,p_invoice_type_id => p_invoice_type_id
                                                                                              ,p_validity_type   => 'ICMS TAXABLE FLAG'
                                                                                              );
              --
              IF l_validation_rule_icms IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID LINEICMSTAXCODE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.icms_tax_code
                           );
              END IF;
          END IF;
        END IF; -- 29055483
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --139;
          --
          -- ER 9028781 - Start
          --------------------
          -- Validando ICMS --
          --------------------
          IF l_icms_type = 'INV LINES INF' THEN
             IF r_invoice_lines.icms_type IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'NULL ICMS TYPE'
                         ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                         ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
             ELSE
                l_validation_rule_icms_type := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_ICMS_TYPE'
                                                                                                     ,p_code            => r_invoice_lines.icms_type
                                                                                                     ,p_invoice_type_id => p_invoice_type_id
                                                                                                     ,p_validity_type   => 'ICMS TYPE'
                                                                                                      );
                --
                IF l_validation_rule_icms_type IS NULL THEN
                   ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                            ,p_interface_operation_id => p_interface_operation_id
                            ,p_organization_id        => p_organization_id
                            ,p_error_code             => 'INVALID ICMSTYPE'
                            ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                            ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                            ,p_invalid_value          => r_invoice_lines.icms_type
                            );
                END IF;
             END IF;
          END IF;
          -- ER 9028781 - End
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --140;
          ------------------------
          -- Validando IPI Code --
          ------------------------

-- 29055483 - Start
        IF NVL(l_source,NULL) NOT IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 29055483 - End
          IF r_invoice_lines.ipi_tax_code IS NULL THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'NULL LINEIPITAXCODE'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => r_invoice_lines.icms_tax_code
                       );
          ELSE
              l_validation_rule_ipi := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_FEDERAL_TRIBUT_CODE'
                                                                                             ,p_code            => r_invoice_lines.ipi_tax_code
                                                                                             ,p_invoice_type_id => p_invoice_type_id
                                                                                             ,p_validity_type   => 'IPI TAXABLE FLAG'
                                                                                             );
              --
              IF l_validation_rule_ipi IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID LINEIPITAXCODE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.ipi_tax_code
                           );
              END IF;
          END IF;
        END IF; -- 29055483
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --141;
          --------------------------
          -- Validando Tolerancia --
          --------------------------
          -- Bug 18983273 - Start
          BEGIN
             SELECT NVL(rs.national_state,'N')
             INTO l_national_state
             FROM cll_f189_states rs,
                  cll_f189_fiscal_entities_all rfea
             WHERE rfea.entity_id = p_entity_id
               AND rfea.state_id  = rs.state_id;
          EXCEPTION
             WHEN OTHERS THEN
                l_national_state := NULL;
          END;
          --
          lNetAmountCalc    := round(r_invoice_lines.unit_price * r_invoice_lines.quantity * (1+(nvl(p_additional_tax,0)/100)),5);  -- Desconto/Encargo
          lNetAmountCalc    := round(lNetAmountCalc * (1-(nvl(r_invoice_lines.discount_percent,0)/100)),5);                         -- Desconto por produto
          lNetAmountCalc    := round(lNetAmountCalc - NVL(r_invoice_lines.discount_net_amount,0),2);                    -- Desconto total na linha BUG 28468398
          -- Inicio BUG 19297595
          IF l_national_state = 'N' THEN
             BEGIN
               SELECT nvl(import_other_val_not_icms,0) + nvl(import_other_val_included_icms,0) -- ER 20450226
                      --Nvl(siscomex_amount,0)                                   -- ER 20450226
                 INTO l_siscomex_amount
                 FROM cll_f189_invoice_iface_tmp
                WHERE interface_invoice_id     = p_interface_invoice_id
                  AND interface_operation_id   = p_interface_operation_id
                  AND organization_id          = p_organization_id;
             EXCEPTION WHEN NO_DATA_FOUND THEN
               l_siscomex_amount :=0;
             END;
             --
             IF l_siscomex_amount <> 0 THEN
               l_dsp_siscomex_amount := round(r_invoice_lines.net_amount,2) - round(lNetAmountCalc,2); -- Valor do SISCOMEX rateado
             ELSE
               l_dsp_siscomex_amount := 0;
             END IF;
          END IF;
          -- Fim BUG 19297595
          -- Bug 18983273 - Start
          IF l_national_state = 'Y' THEN
             lNetAmountCalc    := (lNetAmountCalc + NVL(r_invoice_lines.freight_amount,0) + NVL(r_invoice_lines.insurance_amount,0) + NVL(r_invoice_lines.other_expenses,0));-- Frete/Seguro/Outras Despesas  -- BUG 18096092
          ELSE
             lNetAmountCalc    := (lNetAmountCalc + NVL(r_invoice_lines.freight_amount,0) + NVL(r_invoice_lines.insurance_amount,0) + NVL(l_dsp_siscomex_amount,0));-- Frete e Seguro + -- BUG 19297595 Rateio do SISCOMEX
          END IF;
          -- Bug 18983273 - End
          lDiferencaTotalNf := round(lNetAmountCalc,2) - round(r_invoice_lines.net_amount,2);                                       -- Arredondar em 2 casas decimais
          lTolerancia       := 0.01;                                                                                                -- Tolerancia
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --142;
          IF lDiferencaTotalNf > lTolerancia OR lDiferencaTotalNf < (lTolerancia * -1) THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'INCORRECT LINENETAMT'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => NULL
                       );
          END IF;
          --------------------------------
          -- Validando Flag AP do Frete --
          --------------------------------
          IF r_invoice_lines.freight_ap_flag NOT IN ('Y','N') THEN
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => p_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'INVALID FREIGHT AP FLAG'
                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                       ,p_invalid_value          => r_invoice_lines.freight_ap_flag
                       );
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --143;
          -----------------------
          -- Validando Projeto --
          -----------------------
          /*
          S - National Purchase
          I - Charges
          N - Not Applied
          B - Seiban
          */
          IF p_project_flag = 'N' THEN -- Bug 17243833
              IF r_invoice_lines.project_id                    IS NOT NULL OR
                 r_invoice_lines.project_number                IS NOT NULL OR
                 r_invoice_lines.task_id                       IS NOT NULL OR
                 r_invoice_lines.task_number                   IS NOT NULL OR
                 r_invoice_lines.expenditure_type              IS NOT NULL OR
                 r_invoice_lines.expenditure_organization_id   IS NOT NULL OR
                 r_invoice_lines.expenditure_organization_name IS NOT NULL OR
                 r_invoice_lines.expenditure_item_date         IS NOT NULL THEN
                  --
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'PROJ NOT NULL'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => p_invoice_type_id
                           );
              END IF;
          --
          -- Bug 17243833 - Start
          --
          ELSIF p_project_flag = 'I' THEN -- Integracao PA = Charges
              IF r_invoice_lines.project_id                    IS NULL AND
                 r_invoice_lines.project_number                IS NULL AND
                 r_invoice_lines.task_id                       IS NULL AND
                 r_invoice_lines.task_number                   IS NULL AND
                 r_invoice_lines.expenditure_type              IS NULL AND
                 r_invoice_lines.expenditure_organization_id   IS NULL AND
                 r_invoice_lines.expenditure_organization_name IS NULL AND
                 r_invoice_lines.expenditure_item_date         IS NULL THEN -- nao foi encontrada informacoes de projeto
                  --
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'PROJ NULL CHARGES'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => p_invoice_type_id
                           );
              ELSE -- Informacoes de projeto foram informadas, precisa validar se estao corretas
                 --
                  ---------------------------------
                  -- Validando o projeto na open --
                  ---------------------------------
                  --
                  IF r_invoice_lines.project_id IS NULL AND r_invoice_lines.project_number IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'PROJ NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  ELSE
                      --
                      l_project_id := CLL_F189_OPEN_VALIDATE_PUB.GET_PA_PROJECTS(p_project_id     => r_invoice_lines.project_id
                                                                                ,p_project_number => r_invoice_lines.project_number
                                                                                );
                      --
                      IF r_invoice_lines.project_id IS NOT NULL AND r_invoice_lines.project_number IS NULL THEN
                          IF l_project_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV PROJ ID'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.project_id
                                       );
                          END IF;
                      ELSIF r_invoice_lines.project_id IS NULL AND r_invoice_lines.project_number IS NOT NULL THEN
                          IF l_project_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV PROJ NUMBER'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.project_number
                                       );
                          END IF;
                          --
                      ELSIF r_invoice_lines.project_id IS NOT NULL AND r_invoice_lines.project_number IS NOT NULL THEN
                          IF l_project_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV PROJ'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => 'ID = '||r_invoice_lines.project_id||' - NUMBER ='||r_invoice_lines.project_number
                                       );
                          END IF;
                      END IF;
                      --
                      r_invoice_lines.project_id := l_project_id;
                      --
                  END IF; --IF r_invoice_lines.project_id IS NULL AND r_invoice_lines.project_number IS NULL THEN
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --144;
                  --
                  -- 26366374 - Start
                  BEGIN
                     SELECT project_id
                          , task_id
                          , expenditure_type
                          , expenditure_organization_id
                          , expenditure_item_date
                     INTO l_po_project_id
                        , l_po_task_id
                        , l_po_expenditure_type
                        , l_po_expenditure_org_id
                        , l_po_expenditure_item_date
                     FROM po_distributions_all
                     WHERE line_location_id = NVL(l_line_location_id,r_invoice_lines.line_location_id);
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        l_po_project_id                  := NULL;
                        l_po_task_id                     := NULL;
                        l_po_expenditure_type            := NULL;
                        l_po_expenditure_org_id          := NULL;
                        l_po_expenditure_item_date       := NULL;
                     WHEN OTHERS THEN
                        l_po_project_id                  := NULL;
                        l_po_task_id                     := NULL;
                        l_po_expenditure_type            := NULL;
                        l_po_expenditure_org_id          := NULL;
                        l_po_expenditure_item_date       := NULL;
                  END;

                  IF ( (l_po_project_id                  <> r_invoice_lines.project_id)
                  OR   (l_po_task_id                     <> r_invoice_lines.task_id)
                  OR   (l_po_expenditure_type            <> r_invoice_lines.expenditure_type)
                  OR   (l_po_expenditure_org_id          <> r_invoice_lines.expenditure_organization_id)
                  OR   (l_po_expenditure_item_date       <> r_invoice_lines.expenditure_item_date) ) THEN

                     ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                              ,p_interface_operation_id => p_interface_operation_id
                              ,p_organization_id        => p_organization_id
                              ,p_error_code             => 'PROJ INF DIF PROJ PO'
                              ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                              ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                              ,p_invalid_value          => 'ID = '||r_invoice_lines.project_id||' - NUMBER ='||r_invoice_lines.project_number
                               );

                  END IF;
                 -- 26366374 - End

                  --------------------------------
                  -- Validando a tarefa na open --
                  --------------------------------
                  IF r_invoice_lines.task_id IS NULL AND r_invoice_lines.task_number IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'TASK NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  ELSE
                      --
                      l_task_id := CLL_F189_OPEN_VALIDATE_PUB.GET_PA_TASKS(p_project_id  => r_invoice_lines.project_id
                                                                          ,p_task_id     => r_invoice_lines.task_id
                                                                          ,p_task_number => r_invoice_lines.task_number
                                                                          );
                      --
                      IF r_invoice_lines.task_id IS NOT NULL AND r_invoice_lines.task_number IS NULL THEN
                          IF l_task_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV TASK ID'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.task_id
                                       );
                          END IF;
                      ELSIF r_invoice_lines.task_id IS NULL AND r_invoice_lines.task_number IS NOT NULL THEN
                          IF l_task_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV TASK NUMBER'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.task_number
                                       );
                          END IF;
                      ELSIF r_invoice_lines.task_id IS NOT NULL AND r_invoice_lines.task_number IS NOT NULL THEN
                          IF l_task_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV TASK'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => 'ID = '||r_invoice_lines.task_id||' - NUMBER ='||r_invoice_lines.task_number
                                       );
                          END IF;
                      END IF;
                      --
                      r_invoice_lines.task_id := l_task_id;
                      --
                  END IF; --IF r_invoice_lines.task_id IS NULL AND r_invoice_lines.task_number IS NULL THEN
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --145;
                  --
                  ----------------------------------------------------
                  -- Validando o tipo de despesa do projeto na open --
                  ----------------------------------------------------
                  IF r_invoice_lines.expenditure_type IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'EXPEND TYPE NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  ELSE
                      l_expenditure_type := CLL_F189_OPEN_VALIDATE_PUB.GET_PA_EXPENDITURE_TYPES(p_project_id       => r_invoice_lines.project_id
                                                                                               ,p_expenditure_type => r_invoice_lines.expenditure_type
                                                                                               );
                      IF l_expenditure_type IS NULL THEN
                          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                   ,p_interface_operation_id => p_interface_operation_id
                                   ,p_organization_id        => p_organization_id
                                   ,p_error_code             => 'INV EXPEND TYPE'
                                   ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                   ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                   ,p_invalid_value          => r_invoice_lines.expenditure_type
                                   );
                      END IF;
                  END IF;
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --146;
                  --
                  -----------------------------------------------------------
                  -- Validando a organizacao de despesa do projeto na open --
                  -----------------------------------------------------------
                  IF r_invoice_lines.expenditure_organization_id IS NULL AND r_invoice_lines.expenditure_organization_name IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'EXPEND ORG NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  ELSE
                      l_expenditure_organization_id := CLL_F189_OPEN_VALIDATE_PUB.GET_PA_ORGANIZATIONS_EXPEND(p_expenditure_org_id   => r_invoice_lines.expenditure_organization_id
                                                                                                             ,p_expenditure_org_name => r_invoice_lines.expenditure_organization_name
                                                                                                             );
                      IF r_invoice_lines.expenditure_organization_id IS NOT NULL AND r_invoice_lines.expenditure_organization_name IS NULL THEN
                          IF l_expenditure_organization_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV EXP ORG ID'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.expenditure_organization_id
                                       );
                          END IF;
                      ELSIF r_invoice_lines.expenditure_organization_id IS NULL AND r_invoice_lines.expenditure_organization_name IS NOT NULL THEN
                          IF l_expenditure_organization_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV EXP ORG NAME'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.expenditure_organization_name
                                       );
                          END IF;
                      ELSIF r_invoice_lines.expenditure_organization_id IS NOT NULL AND r_invoice_lines.expenditure_organization_name IS NOT NULL THEN
                          IF l_expenditure_organization_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV EXP ORG'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => 'ID = '||r_invoice_lines.expenditure_organization_id||' - NAME = '||r_invoice_lines.expenditure_organization_name
                                       );
                          END IF;
                      END IF;
                      --
                      r_invoice_lines.expenditure_organization_id := l_expenditure_organization_id;
                      --
                  END IF; --IF r_invoice_lines.expenditure_organization_id IS NULL AND r_invoice_lines.expenditure_organization_name IS NULL THEN
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --147;
                  --
                  ------------------------------------------------------------
                  -- Validando a data do item de despesa do projeto na open --
                  ------------------------------------------------------------
                  IF r_invoice_lines.expenditure_item_date IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'EXPEND ITEM DATE NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  END IF;
              END IF;
          --
          -- Bug 17243833 - End
          --
          ELSIF p_project_flag = 'S' THEN -- Integracao PA = Compra Nacional
              --
              l_project_exists := 0;
              --
              IF r_invoice_lines.line_location_id IS NOT NULL THEN
                  CLL_F189_OPEN_VALIDATE_PUB.GET_DISTRIBUTIONS(p_line_location_id      => NVL(l_line_location_id,r_invoice_lines.line_location_id)
                                                              -- out
                                                              ,p_destination_type_code => l_destination_type_code
                                                              ,p_project_exists        => l_project_exists
                                                              );
              END IF;
              --
              IF l_project_exists > 0 THEN -- a linha do PO tem projeto e as informacoes tambem estao preenchidas na open

                 IF NVL(l_source,NULL) <> 'CLL_F369 EFD LOADER' THEN -- 27938576

                    IF r_invoice_lines.project_id                    IS NOT NULL OR
                       r_invoice_lines.project_number                IS NOT NULL OR
                       r_invoice_lines.task_id                       IS NOT NULL OR
                       r_invoice_lines.task_number                   IS NOT NULL OR
                       r_invoice_lines.expenditure_type              IS NOT NULL OR
                       r_invoice_lines.expenditure_organization_id   IS NOT NULL OR
                       r_invoice_lines.expenditure_organization_name IS NOT NULL OR
                       r_invoice_lines.expenditure_item_date         IS NOT NULL THEN
                        --
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'PROJ NOT NULL PO' --'PROJ NOT NULL'
                                 ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                 ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => 'LINE_LOCATION_ID = '||r_invoice_lines.line_location_id
                                 );
                    END IF;

                 -- 28439553 - Start
                 ELSIF NVL(l_source,NULL) = 'CLL_F369 EFD LOADER' THEN

                    l_po_project_id                  := NULL;
                    l_po_task_id                     := NULL;
                    l_po_expenditure_type            := NULL;
                    l_po_expenditure_org_id          := NULL;
                    l_po_expenditure_item_date       := NULL;

                 -- 28439553 - End
                 END IF; -- 27938576

              ELSIF l_project_exists = 0 THEN -- Nao encontrou projeto na linha do PO, entao valida se as informacoes existem na interface
                  --
                  ---------------------------------
                  -- Validando o projeto na open --
                  ---------------------------------
                  --
                  IF r_invoice_lines.project_id IS NULL AND r_invoice_lines.project_number IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'PROJ NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  ELSE
                      --
                      l_project_id := CLL_F189_OPEN_VALIDATE_PUB.GET_PA_PROJECTS(p_project_id     => r_invoice_lines.project_id
                                                                                ,p_project_number => r_invoice_lines.project_number
                                                                                );
                      --
                      IF r_invoice_lines.project_id IS NOT NULL AND r_invoice_lines.project_number IS NULL THEN
                          IF l_project_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV PROJ ID'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.project_id
                                       );
                          END IF;
                      ELSIF r_invoice_lines.project_id IS NULL AND r_invoice_lines.project_number IS NOT NULL THEN
                          IF l_project_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV PROJ NUMBER'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.project_number
                                       );
                          END IF;
                          --
                      ELSIF r_invoice_lines.project_id IS NOT NULL AND r_invoice_lines.project_number IS NOT NULL THEN
                          IF l_project_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV PROJ'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => 'ID = '||r_invoice_lines.project_id||' - NUMBER ='||r_invoice_lines.project_number
                                       );
                          END IF;
                      END IF;
                      --
                      r_invoice_lines.project_id := l_project_id;
                      --
                  END IF; --IF r_invoice_lines.project_id IS NULL AND r_invoice_lines.project_number IS NULL THEN
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --148;
                  --
                  --------------------------------
                  -- Validando a tarefa na open --
                  --------------------------------
                  IF r_invoice_lines.task_id IS NULL AND r_invoice_lines.task_number IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'TASK NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  ELSE
                      --
                      l_task_id := CLL_F189_OPEN_VALIDATE_PUB.GET_PA_TASKS(p_project_id  => r_invoice_lines.project_id
                                                                          ,p_task_id     => r_invoice_lines.task_id
                                                                          ,p_task_number => r_invoice_lines.task_number
                                                                          );
                      --
                      IF r_invoice_lines.task_id IS NOT NULL AND r_invoice_lines.task_number IS NULL THEN
                          IF l_task_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV TASK ID'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.task_id
                                       );
                          END IF;
                      ELSIF r_invoice_lines.task_id IS NULL AND r_invoice_lines.task_number IS NOT NULL THEN
                          IF l_task_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV TASK NUMBER'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.task_number
                                       );
                          END IF;
                      ELSIF r_invoice_lines.task_id IS NOT NULL AND r_invoice_lines.task_number IS NOT NULL THEN
                          IF l_task_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV TASK'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => 'ID = '||r_invoice_lines.task_id||' - NUMBER ='||r_invoice_lines.task_number
                                       );
                          END IF;
                      END IF;
                      --
                      r_invoice_lines.task_id := l_task_id;
                      --
                  END IF; --IF r_invoice_lines.task_id IS NULL AND r_invoice_lines.task_number IS NULL THEN
                  --
                  ----------------------------------------------------
                  -- Validando o tipo de despesa do projeto na open --
                  ----------------------------------------------------
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --149;
                  IF r_invoice_lines.expenditure_type IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'EXPEND TYPE NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  ELSE
                      l_expenditure_type := CLL_F189_OPEN_VALIDATE_PUB.GET_PA_EXPENDITURE_TYPES(p_project_id       => r_invoice_lines.project_id
                                                                                               ,p_expenditure_type => r_invoice_lines.expenditure_type
                                                                                               );
                      IF l_expenditure_type IS NULL THEN
                          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                   ,p_interface_operation_id => p_interface_operation_id
                                   ,p_organization_id        => p_organization_id
                                   ,p_error_code             => 'INV EXPEND TYPE'
                                   ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                   ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                   ,p_invalid_value          => r_invoice_lines.expenditure_type
                                   );
                      END IF;
                  END IF;
                  --
                  -----------------------------------------------------------
                  -- Validando a organizacao de despesa do projeto na open --
                  -----------------------------------------------------------
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --150;
                  IF r_invoice_lines.expenditure_organization_id IS NULL AND r_invoice_lines.expenditure_organization_name IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'EXPEND ORG NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  ELSE
                      l_expenditure_organization_id := CLL_F189_OPEN_VALIDATE_PUB.GET_PA_ORGANIZATIONS_EXPEND(p_expenditure_org_id   => r_invoice_lines.expenditure_organization_id
                                                                                                             ,p_expenditure_org_name => r_invoice_lines.expenditure_organization_name
                                                                                                             );
                      IF r_invoice_lines.expenditure_organization_id IS NOT NULL AND r_invoice_lines.expenditure_organization_name IS NULL THEN
                          IF l_expenditure_organization_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV EXP ORG ID'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.expenditure_organization_id
                                       );
                          END IF;
                      ELSIF r_invoice_lines.expenditure_organization_id IS NULL AND r_invoice_lines.expenditure_organization_name IS NOT NULL THEN
                          IF l_expenditure_organization_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV EXP ORG NAME'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => r_invoice_lines.expenditure_organization_name
                                       );
                          END IF;
                      ELSIF r_invoice_lines.expenditure_organization_id IS NOT NULL AND r_invoice_lines.expenditure_organization_name IS NOT NULL THEN
                          IF l_expenditure_organization_id IS NULL THEN
                              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => p_organization_id
                                       ,p_error_code             => 'INV EXP ORG'
                                       ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                       ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                       ,p_invalid_value          => 'ID = '||r_invoice_lines.expenditure_organization_id||' - NAME = '||r_invoice_lines.expenditure_organization_name
                                       );
                          END IF;
                      END IF;
                      --
                      r_invoice_lines.expenditure_organization_id := l_expenditure_organization_id;
                      --
                  END IF; --IF r_invoice_lines.expenditure_organization_id IS NULL AND r_invoice_lines.expenditure_organization_name IS NULL THEN
                  --
                  ------------------------------------------------------------
                  -- Validando a data do item de despesa do projeto na open --
                  ------------------------------------------------------------
                  l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --151;
                  IF r_invoice_lines.expenditure_item_date IS NULL THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'EXPEND ITEM DATE NULL'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                  END IF;
              ELSE --IF l_project_exists > 0 THEN
                  l_task_id := NULL;
                  l_expenditure_organization_id := NULL;
              END IF; --IF l_project_exists > 0 THEN
          END IF; --IF p_project_flag IN ('N', 'I') THEN
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --152;
          --
          -- 28192844 - Start
          BEGIN
             SELECT ph.type_lookup_code
             INTO l_type_lookup_code
             FROM po_headers_all ph
                , po_lines_all          pla
                , po_line_locations_all plla
             WHERE ph.po_header_id = pla.po_header_id
               AND plla.po_line_id       = pla.po_line_id
               AND plla.line_location_id = r_invoice_lines.line_location_id;
          EXCEPTION
             WHEN OTHERS THEN
             l_type_lookup_code := '***';
          END;
          --
          IF l_type_lookup_code <> 'BLANKET' THEN
          -- 28192844 - End

             IF p_allow_upd_price_flag = 'N' AND p_source_items = '0' AND p_parent_flag <> 'Y' THEN
                CLL_F189_OPEN_VALIDATE_PUB.GET_PO_LINES_AND_LOCATIONS(p_line_location_id      => r_invoice_lines.line_location_id
                                                                      -- out
                                                                      ,p_unit_price            => l_unit_price
                                                                      ,p_unit_meas_lookup_code => l_unit_meas_lookup_code
                                                                      ,p_item_id               => l_item_id
                                                                      ,p_price_override        => l_price_override
                                                                      );
                --
                IF l_unit_price IS NOT NULL THEN
                   IF r_invoice_lines.unit_price <> l_unit_price THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'DIFFERENT UNITARY PRICE'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                   END IF;
                END IF;
             END IF;
             --
          END IF; -- 28192844
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --153;
          --
          IF p_source_items <> '1' AND p_parent_flag <> 'Y' THEN
              --
              l_unit_price :=  r_invoice_lines.unit_price;
              --
              CLL_F189_OPEN_VALIDATE_PUB.GET_PO_LINES_AND_LOCATIONS(p_line_location_id      => r_invoice_lines.line_location_id
                                                                   -- out
                                                                   ,p_unit_price            => l_unit_price_out -- l_unit_price -- BUG 19906534
                                                                   ,p_unit_meas_lookup_code => l_unit_meas_lookup_code
                                                                   ,p_item_id               => l_item_id
                                                                   ,p_price_override        => l_price_override
                                                                   );
              ------------------------------------------------------------------
              -- Validando conversao de UOM para validar se excede tolerancia --
              ------------------------------------------------------------------
              IF l_unit_meas_lookup_code <> r_invoice_lines.uom THEN
                  CLL_F189_UOM_PKG.VAL_UOM (p_unit_of_measure => r_invoice_lines.uom
                                           -- out
                                           ,p_status          => l_uom_status
                                           );
                  --
                  IF l_uom_status IN ('INVALID UOM','UOM ERROR') THEN
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'NO UOM'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => r_invoice_lines.uom
                               );
                  ELSIF l_uom_status = 'UOM OK' THEN
                      --
                      l_uom_unit_price := r_invoice_lines.unit_price;
                      --
                      CLL_F189_UOM_PKG.UOM_CONV_PRICE (p_from_uom   => r_invoice_lines.uom
                                                      ,p_to_uom     => l_unit_meas_lookup_code
                                                      ,p_item_id    => r_invoice_lines.item_id
                                                      ,p_unit_price => l_uom_unit_price --IN OUT
                                                      -- out
                                                      ,p_uom_rate   => l_uom_rate
                                                      ,p_status     => l_uom_conv_status
                                                      );
                      --
                      IF l_uom_conv_status = 'CONV NULL' THEN
                          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                   ,p_interface_operation_id => p_interface_operation_id
                                   ,p_organization_id        => p_organization_id
                                   ,p_error_code             => 'CONV NOT NULL'
                                   ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                   ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                   ,p_invalid_value          => l_uom_rate
                                   );
                      ELSIF l_uom_conv_status = 'NO CONV UOM' THEN
                          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                   ,p_interface_operation_id => p_interface_operation_id
                                   ,p_organization_id        => p_organization_id
                                   ,p_error_code             => 'INVALID UOM CONV'
                                   ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                   ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                   ,p_invalid_value          => l_uom_rate
                                   );
                      ELSIF l_uom_conv_status = 'CONV OK' THEN
                          l_unit_price := l_uom_unit_price;
                      END IF;
                  END IF; --IF l_uom_status IN ('INVALID UOM','UOM ERROR') THEN
              END IF; --IF l_unit_meas_lookup_code <> r_invoice_lines.uom THEN
              --
              IF p_user_defined_conversion_rate IS NOT NULL THEN
                  l_unit_price := l_unit_price * p_user_defined_conversion_rate;
              END IF;
              --
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --154;
              --
              -- Begin Bug 25985854
              BEGIN
                SELECT pll.ship_to_location_id,
                       pll.ship_to_organization_id,
                       pll.po_header_id,
                       pll.po_line_id,
                       pll.org_id,
                       po.vendor_site_id
                  INTO l_ship_to_location_id,
                       l_ship_to_organization_id,
                       l_po_header_id,
                       l_po_line_id,
                       l_org_id,
                       l_vendor_site_id
                  FROM po_line_locations_all  pll,
                       po_headers_all         po
                 WHERE pll.line_location_id = r_invoice_lines.line_location_id
                   AND po.po_header_id      = pll.po_header_id;
              EXCEPTION WHEN NO_DATA_FOUND THEN
                  l_ship_to_location_id     := NULL;
                  l_ship_to_organization_id := NULL;
                  l_po_header_id            := NULL;
                  l_po_line_id              := NULL;
              END;
              --
              BEGIN
                SELECT invoice_date
                  INTO l_invoice_date
                  FROM cll_f189_invoices_interface
                 WHERE interface_operation_id = p_interface_operation_id
                   AND interface_invoice_id   = p_interface_invoice_id;
              EXCEPTION WHEN NO_DATA_FOUND THEN
                  l_invoice_date     := NULL;
              END;
              --
              cll_f189_adv_pricing_hk.pricing_custom   ( l_org_id
                                                       , p_vendor_id
                                                       , l_vendor_site_id
                                                       , l_invoice_date
                                                       , l_ship_to_location_id
                                                       , l_ship_to_organization_id
                                                       , l_po_header_id
                                                       , l_po_line_id
                                                       , p_item_id
                                                       , l_invoice_date
                                                       , x_base_unit_price
                                                       , x_unit_price
                                                       , x_return_status_pr );
              --
              IF nvl(x_unit_price  ,0) <> 0 THEN
                IF l_unit_price <> nvl(x_unit_price,0) THEN
                  IF l_unit_price > nvl(x_unit_price,0) * ( 1 + p_rcv_tolerance_perc_amount / 100) OR
                     r_invoice_lines.unit_price * ( 1 + p_rcv_tolerance_perc_amount / 100) < l_unit_price THEN
                    IF (p_rcv_tolerance_code = 'NONE' OR p_rcv_tolerance_code = 'WARNING') THEN -- 22393491
                       NULL;
                    ELSE
                      ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'PRICE EXCEDDS TOLERANCE'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                               );
                     END IF;
                  ELSE
                    NULL;
                  END IF;
                END IF;
              ELSE
              -- End Bug 25985854
                IF l_unit_price > l_price_override * ( 1 + p_rcv_tolerance_perc_amount / 100) THEN
                  --IF p_rcv_tolerance_code = 'NONE' THEN                                       -- 22393491
                  IF (p_rcv_tolerance_code = 'NONE' OR p_rcv_tolerance_code = 'WARNING') THEN -- 22393491
                    NULL;
                  ELSE
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                               ,p_interface_operation_id => p_interface_operation_id
                               ,p_organization_id        => p_organization_id
                               ,p_error_code             => 'PRICE EXCEDDS TOLERANCE'
                               ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               ,p_invalid_value          => NULL
                             );
                  END IF;
                END IF;
            END IF; ---- End Bug 25985854
          END IF; --IF p_source_items <> '1' AND p_parent_flag <> 'Y' THEN
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --155;
          --
          -----------------------
          -- Validando CST IPI --
          -----------------------
          IF r_invoice_lines.ipi_tributary_code IS NOT NULL THEN
              --
              l_validation_rule_cst_ipi := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_IPI_TRIBUTARY_CODE'
                                                                                                 ,p_code            => r_invoice_lines.ipi_tributary_code
                                                                                                 ,p_invoice_type_id => p_invoice_type_id
                                                                                                 ,p_validity_type   => 'CST IPI'
                                                                                                 );
              --
              IF l_validation_rule_cst_ipi IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INV IPI TRIBUT CODE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.ipi_tributary_code
                           );
              END IF;
          END IF;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --156;
          --
          -----------------------
          -- Validando CST PIS --
          -----------------------
          IF r_invoice_lines.pis_tributary_code IS NOT NULL THEN
              --
              l_validation_rule_cst_pis := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_PIS_TRIBUTARY_CODE'
                                                                                                 ,p_code            => r_invoice_lines.pis_tributary_code
                                                                                                 ,p_invoice_type_id => p_invoice_type_id
                                                                                                 ,p_validity_type   => 'CST PIS'
                                                                                                 );
              --
              IF l_validation_rule_cst_pis IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INV PIS TRIBUT CODE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.pis_tributary_code
                           );
              END IF;
          END IF;
          --
          --------------------------
          -- Validando CST COFINS --
          --------------------------
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --157;
          --
          IF r_invoice_lines.cofins_tributary_code IS NOT NULL THEN
              --
              l_validation_rule_cst_cofins := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_COFINS_TRIBUTARY_CODE'
                                                                                                    ,p_code            => r_invoice_lines.cofins_tributary_code
                                                                                                    ,p_invoice_type_id => p_invoice_type_id
                                                                                                    ,p_validity_type   => 'CST COFINS'
                                                                                                    );
              --
              IF l_validation_rule_cst_cofins IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INV COFINS TRIBUT CODE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.cofins_tributary_code
                           );
              END IF;
          END IF;
          --
          ----------------------------------
          -- Validando Grupo de pagamento --
          ----------------------------------
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --158;
          IF r_invoice_lines.awt_group_id IS NOT NULL THEN
              l_awt_group_id := CLL_F189_OPEN_VALIDATE_PUB.GET_AP_AWT_GROUP (p_awt_group_id   => r_invoice_lines.awt_group_id
                                                                            ,p_operating_unit => p_operating_unit
                                                                            );
              --
              IF l_awt_group_id IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID AWT GROUP ID'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.awt_group_id
                           );
              END IF;
          END IF;
          --
          -----------------------
          -- Validando Veiculo --
          -----------------------
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --159;
          IF r_invoice_lines.vehicle_oper_type IS NOT NULL THEN
              l_vehicle_oper_type := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES (p_lookup_type => 'CLL_F189_VEHICLE_OPER_TYPE'
                                                                           ,p_lookup_code => r_invoice_lines.vehicle_oper_type
                                                                           );
              --
              IF l_vehicle_oper_type IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INV VEHICLE OPER TYPE'
                           ,p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                           ,p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                           ,p_invalid_value          => r_invoice_lines.vehicle_oper_type
                           );
              END IF;
          END IF;
          --
          -- BUG 17056156 Start
          --
          IF r_invoice_lines.fundersul_per_u_meas   IS NOT NULL OR
             r_invoice_lines.fundersul_unit_amount  IS NOT NULL OR
             r_invoice_lines.fundersul_unit_percent IS NOT NULL OR
             r_invoice_lines.fundersul_amount       IS NOT NULL OR
             r_invoice_lines.fundersul_addt_amount  IS NOT NULL THEN
              --
              BEGIN
                 --
                 SELECT cfp.allow_fundersul
                      , haou.name
                   INTO l_allow_fundersul
                      , l_org_name
                   FROM cll_f189_parameters       cfp
                      , hr_all_organization_units haou
                  WHERE haou.organization_id = cfp.organization_id
                    AND cfp.organization_id  = p_organization_id ;
                 --
              EXCEPTION
                 WHEN OTHERS THEN
                       l_allow_fundersul := NULL ;
              END ;
              --
              --
              IF NVL(l_allow_fundersul, 'N') = 'N' THEN
                  --
                  ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                            , p_interface_operation_id => p_interface_operation_id
                            , p_organization_id        => p_organization_id
                            , p_error_code             => 'INVALID FUNDERSUL ORGANIZATION'
                            , p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                            , p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                            , p_invalid_value          => l_org_name
                            ) ;
                  --
              ELSE
                  --
                  BEGIN
                     --
                     SELECT fundersul_own_flag
                          , fundersul_sup_part_flag
                          , invoice_type_code
                       INTO l_fundersul_own_flag
                          , l_fundersul_sup_part_flag
                          , l_invoice_type_code
                       FROM cll_f189_invoice_types
                      WHERE invoice_type_id = p_invoice_type_id
                        AND organization_id = p_organization_id;
                 --
                  EXCEPTION
                 WHEN OTHERS THEN
                       l_fundersul_own_flag      := NULL ;
                       l_fundersul_sup_part_flag := NULL ;
                       l_invoice_type_code       := NULL ;
                  END ;
                  --
                  --
                  IF l_fundersul_own_flag      IS NULL AND
                     l_fundersul_sup_part_flag IS NULL THEN
                     --
                     ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                               , p_interface_operation_id => p_interface_operation_id
                               , p_organization_id        => p_organization_id
                               , p_error_code             => 'INVALID FUNDERSUL INVOICE TYPE'
                               , p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                               , p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                               , p_invalid_value          => l_invoice_type_code
                               ) ;
                     --
                  END IF ;
                  --
                  BEGIN
                     --
                     cll_f189_calc_fundersul_pkg.get_fundersul
                         ( p_organization_id             => p_organization_id
                         , p_invoice_type_id             => p_invoice_type_id
                         , p_item_id                     => r_invoice_lines.item_id
                         , p_classification_id           => NVL(r_invoice_lines.classification_id, l_classification_id)
                         , p_invoice_date                => p_invoice_date
                         , p_quantity                    => r_invoice_lines.quantity
                         , p_uom                         => r_invoice_lines.uom
                         , p_fundersul_per_u_meas        => l_fundersul_per_u_meas
                         , p_fundersul_unit_amount       => l_fundersul_unit_amount
                         , p_fundersul_unit_percent      => l_fundersul_unit_percent
                         , p_fundersul_additional_amount => l_fundersul_additional_amount
                         , p_fundersul_amount            => l_fundersul_amount ) ;
                     --
                  EXCEPTION
                     WHEN OTHERS THEN
                           l_fundersul_per_u_meas        := NULL ;
                           l_fundersul_unit_amount       := NULL ;
                           l_fundersul_unit_percent      := NULL ;
                           l_fundersul_additional_amount := NULL ;
                           l_fundersul_amount            := NULL ;
                  END ;
                  --
                  --
                  IF NVL(l_fundersul_per_u_meas, 0) <> NVL(r_invoice_lines.fundersul_per_u_meas, 0) THEN
                      --                         --
                      ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                                , p_interface_operation_id => p_interface_operation_id
                                , p_organization_id        => p_organization_id
                                , p_error_code             => 'INVALID FUNDERSUL UNIT OF MEAS'
                                , p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                , p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                , p_invalid_value          => NVL(r_invoice_lines.fundersul_per_u_meas, 0)
                                ) ;
                      --
                  END IF ;
                  --
                  IF NVL(l_fundersul_unit_amount, 0) <> NVL(r_invoice_lines.fundersul_unit_amount, 0) THEN
                      --
                      ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                                , p_interface_operation_id => p_interface_operation_id
                                , p_organization_id        => p_organization_id
                                , p_error_code             => 'INVALID FUNDERSUL UNIT AMOUNT'
                                , p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                , p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                , p_invalid_value          => NVL(r_invoice_lines.fundersul_unit_amount, 0)
                                ) ;
                      --
                  END IF ;
                  --
                  IF NVL(l_fundersul_unit_percent, 0) <> NVL(r_invoice_lines.fundersul_unit_percent, 0) THEN
                      --
                      ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                                , p_interface_operation_id => p_interface_operation_id
                                , p_organization_id        => p_organization_id
                                , p_error_code             => 'INVALID FUNDERSUL TAX RATE'
                                , p_invoice_line_id        => r_invoice_lines.interface_invoice_line_id
                                , p_table_associated       => 2 -- CLL_F189_INVOICES_INTERFACE
                                , p_invalid_value          => NVL(r_invoice_lines.fundersul_unit_percent, 0)
                                ) ;
                      --
                  END IF ;
                  --
              END IF ;
              --
          END IF ;
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --160;
          --
          -- BUG 17056156 End
          --
          ------------------------------------------------------------------
          --<< ER 26338366/26899224 Start (2a fase) dgouveia 12/12/2017 >>--
          ------------------------------------------------------------------
          --
          CREATE_OPEN_TPA_RETURNS ( p_type                       => 'VALIDATE'
                                  , p_tpa_return_control_id      => NULL
                                  , p_organization_id            => p_organization_id
                                  , p_tpa_remit_control_id       => NULL
                                  , p_ship_to_site_user_id       => NULL
                                  , p_operation_id               => p_interface_operation_id
                                  , p_entity_id                  => NULL
                                  , p_operation_status           => NULL
                                  , p_reversion_transaction_id   => NULL
                                  , p_invoice_id                 => NULL
                                  , p_invoice_line_id            => NULL
                                  , p_interface_invoice_id       => p_interface_invoice_id
                                  , p_interface_invoice_line_id  => r_invoice_lines.interface_invoice_line_id
                                  , p_invoice_number             => NULL
                                  , p_invoice_date               => NULL
                                  , p_returned_date              => NULL
                                  , p_inventory_item_id          => NULL
                                  , p_returned_quantity          => NULL
                                  , p_new_subinventory_code      => NULL
                                  , p_new_locator_id             => NULL
                                  , p_new_locator_code           => NULL
                                  , p_unit_price                 => NULL
                                  , p_returned_transaction_id    => NULL
                                  , p_reversion_flag             => NULL
                                  , p_attribute_category         => NULL
                                  , p_attribute1                 => NULL
                                  , p_attribute2                 => NULL
                                  , p_attribute3                 => NULL
                                  , p_attribute4                 => NULL
                                  , p_attribute5                 => NULL
                                  , p_attribute6                 => NULL
                                  , p_attribute7                 => NULL
                                  , p_attribute8                 => NULL
                                  , p_attribute9                 => NULL
                                  , p_attribute10                => NULL
                                  , p_attribute11                => NULL
                                  , p_attribute12                => NULL
                                  , p_attribute13                => NULL
                                  , p_attribute14                => NULL
                                  , p_attribute15                => NULL
                                  , p_attribute16                => NULL
                                  , p_attribute17                => NULL
                                  , p_attribute18                => NULL
                                  , p_attribute19                => NULL
                                  , p_attribute20                => NULL
                                  , p_created_by                 => NULL
                                  , p_creation_date              => NULL
                                  , p_last_update_date           => NULL
                                  , p_last_update_login          => NULL
                                  , p_request_id                 => NULL
                                  , p_program_application_id     => NULL
                                  , p_program_id                 => NULL
                                  , p_program_update_date        => NULL
                                  , p_item_number                => NULL
                                  , p_symbolic_return_flag       => NULL   -- ENR 30120364
                                  , p_return_code                => l_return_code
                                  , p_return_message             => l_return_message
                                  ) ;
          ------------------------------------------------------------------
          --<< ER 26338366/26899224 End (2a fase) dgouveia 12/12/2017 >>--
          ------------------------------------------------------------------
          --
          -- Enh 29907995 - Start
          --
          IF cll_f189_open_validate_pub.get_cfop_devolution ( p_inv_type_id   => p_invoice_type_id
                                                            , p_inv_type_code => NULL ) = 'Y' THEN
            --
            l_rec_tpa_devol_ctrl := l_crec_tpa_devol_ctrl ;
            --
            l_rec_tpa_devol_ctrl.devolution_operation_id    := p_interface_operation_id ;
            l_rec_tpa_devol_ctrl.organization_id            := p_organization_id ;
            l_rec_tpa_devol_ctrl.devolution_invoice_id      := p_interface_invoice_id ;
            l_rec_tpa_devol_ctrl.devolution_invoice_line_id := r_invoice_lines.interface_invoice_line_id ;
            --
            create_open_tpa_devolut ( 'VALIDATE', l_rec_tpa_devol_ctrl, l_return_code, l_return_message ) ;
            --
          END IF ;
          --
          -- Enh 29907995 - End
          --
      ELSIF p_type = 'INSERT' THEN
          --
          l_invoice_line_id_s := CLL_F189_INVOICE_LINES_PUB.GET_INVOICE_LINES_S;
          --
          p_invoice_line_id_par := l_invoice_line_id_s; -- BUG 19943706
          --
          /*l_city_serv_type_rel_id := NULL;

          IF r_invoice_lines.city_service_type_rel_id IS NULL AND r_invoice_lines.city_service_type_rel_code IS NOT NULL AND l_city_id IS NOT NULL THEN
             BEGIN
               SELECT city_service_type_rel_id
                 INTO l_city_serv_type_rel_id
                 FROM cll_f189_city_srv_type_rels
                WHERE city_service_type_rel_code = r_invoice_lines.city_service_type_rel_code
                  AND city_id = l_city_id
                  AND (inactive_date IS NULL OR
                TRUNC (inactive_date) >= TRUNC(sysdate));

             EXCEPTION
                  WHEN OTHERS THEN
                       l_city_serv_type_rel_id := NULL;
             END;
          END IF;

          l_city_serv_type_rel_id := NVL(l_city_serv_type_rel_id,r_invoice_lines.city_service_type_rel_id);

          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --161;
          -- Inicio BUG 20424342
          CLL_F189_VALID_RULES_PKG.GET_CITY_SERV_TYPE_RELS_VRULES (p_city_service_type_rel_id     => l_city_serv_type_rel_id
                                                                  ,p_city_service_type_rel_code   => r_invoice_lines.city_service_type_rel_code
                                                                  ,p_invoice_type_id              => p_invoice_type_id
                                                                  -- out
                                                                  ,p_federal_service_type_id      => l_federal_service_type_id
                                                                  ,p_municipal_service_type_id    => l_municipal_service_type_id
                                                                  ,p_city_service_type_rel_id_out => l_city_service_type_rel_id
                                                                  ,p_iss_tax_type                 => l_iss_tax_type
                                                                  );*/
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --162;
          --
          -- Fim BUG 20424342
          -- 22048611 - Start
          IF r_invoice_lines.line_location_id IS NOT NULL THEN
             CLL_F189_OPEN_VALIDATE_PUB.GET_PO_LINES_AND_LOCATIONS( p_line_location_id      => r_invoice_lines.line_location_id
                                                                    -- out
                                                                   ,p_unit_price            => l_unit_price
                                                                   ,p_unit_meas_lookup_code => l_unit_meas_lookup_code
                                                                   ,p_item_id               => l_item_id
                                                                   ,p_price_override        => l_price_override );
             -- UOM PO VALIDATE
             --
             IF r_invoice_lines.uom_po IS NULL THEN
                l_uom_po := l_unit_meas_lookup_code;
             ELSE
                l_uom_po := r_invoice_lines.uom_po;
             END IF;
             --
             -- QUANTITY UOM PO VALIDATE
             --
             l_quantity_uom_po := r_invoice_lines.quantity;
             --
             --
             IF r_invoice_lines.quantity_uom_po IS NULL THEN
                CLL_F189_UOM_PKG.UOM_CONV_QTY ( p_from_uom   => r_invoice_lines.uom
                                              , p_to_uom     => l_unit_meas_lookup_code
                                              , p_item_id    => l_item_id
                                              , p_quantity   => l_quantity_uom_po );
             ELSE
                CLL_F189_UOM_PKG.UOM_CONV_QTY ( p_from_uom   => r_invoice_lines.uom
                                              , p_to_uom     => r_invoice_lines.uom_po
                                              , p_item_id    => r_invoice_lines.item_id
                                              , p_quantity   => l_quantity_uom_po );
             END IF;
             --
             -- UNIT PRICE UOM PO VALIDATE
             --
             l_unit_price_uom_po := r_invoice_lines.unit_price;
             l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --163;
             --
             IF r_invoice_lines.unit_price_uom_po IS NULL THEN
                CLL_F189_UOM_PKG.UOM_CONV_PRICE( p_from_uom   => r_invoice_lines.uom
                                               , p_to_uom     => l_unit_meas_lookup_code
                                               , p_item_id    => l_item_id
                                               , p_unit_price => l_unit_price_uom_po -- IN OUT
                                               -- out
                                               , p_uom_rate   => l_rate_uom_po
                                               , p_status     => l_conv_status_uom_po );
               --
             ELSE
                CLL_F189_UOM_PKG.UOM_CONV_PRICE(p_from_uom   => r_invoice_lines.uom
                                              , p_to_uom     => r_invoice_lines.uom_po
                                              , p_item_id    => r_invoice_lines.item_id
                                              , p_unit_price => l_unit_price_uom_po --IN OUT
                                              -- out
                                              , p_uom_rate   => l_rate_uom_po
                                              , p_status     => l_conv_status_uom_po );
             END IF; --IF r_invoice_lines.unit_price_uom_po IS NULL THEN
          END IF;
          -- 22048611 - End
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --164;

          -- 28439553 - Start
          -- A linha do PO tem projeto e as informacoes tambem estao preenchidas na open
          IF p_project_flag = 'S' AND
             r_invoice_lines.line_location_id IS NOT NULL THEN
             l_po_project_id                  := NULL;
             l_po_task_id                     := NULL;
             l_po_expenditure_type            := NULL;
             l_po_expenditure_org_id          := NULL;
             l_po_expenditure_item_date       := NULL;
          ELSE
             l_po_project_id                  := r_invoice_lines.project_id;
             l_po_task_id                     := NVL(r_invoice_lines.task_id,l_task_id);
             l_po_expenditure_type            := r_invoice_lines.expenditure_type;
             l_po_expenditure_org_id          := NVL(r_invoice_lines.expenditure_organization_id,l_expenditure_organization_id);
             l_po_expenditure_item_date       := r_invoice_lines.expenditure_item_date;
          END IF;
          -- 28439553 - End

          CLL_F189_INVOICE_LINES_PUB.CREATE_INVOICE_LINES(p_invoice_line_id              => l_invoice_line_id_s
                                                         ,p_user_id                      => l_user_id
                                                         ,p_invoice_id                   => g_cll_f189_invoices_s
                                                         ,p_organization_id              => p_organization_id
                                                         ,p_line_location_id             => NVL(l_line_location_id,r_invoice_lines.line_location_id)
                                                         ,p_requisition_line_id          => r_invoice_lines.requisition_line_id
                                                         ,p_item_id                      => NVL(r_invoice_lines.item_id,l_item_id_oc)
                                                         ,p_db_code_combination_id       => r_invoice_lines.db_code_combination_id
                                                         ,p_classification_id            => NVL(r_invoice_lines.classification_id, l_classification_id)
                                                         ,p_utilization_id               => NVL(r_invoice_lines.utilization_id, l_utilization_id)
                                                         ,p_cfo_id                       => NVL(r_invoice_lines.cfo_id,l_cfo_id)
                                                         ,p_uom                          => r_invoice_lines.uom
                                                         ,p_quantity                     => r_invoice_lines.quantity
                                                         ,p_unit_price                   => r_invoice_lines.unit_price
                                                         ,p_dollar_unit_price            => NULL
                                                         ,p_operation_fiscal_type        => r_invoice_lines.operation_fiscal_type
                                                         ,p_description                  => NVL(r_invoice_lines.description,l_item_description)
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
                                                         ,p_pis_amount_recover           => r_invoice_lines.pis_amount_recover
                                                         ,p_total_amount                 => r_invoice_lines.total_amount
                                                         ,p_cost_amount                  => NULL
                                                         ,p_cost_freight                 => NULL
                                                         ,p_receipt_flag                 => 'N'
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
                                                         ,p_cost_flag                    => NULL
                                                         ,p_icms_st_base                 => r_invoice_lines.icms_st_base
                                                         ,p_icms_st_amount               => r_invoice_lines.icms_st_amount
                                                         ,p_icms_st_amount_recover       => r_invoice_lines.icms_st_amount_recover
                                                         ,p_diff_icms_amount_recover     => r_invoice_lines.diff_icms_amount_recover
                                                         ,p_rma_interface_id             => r_invoice_lines.rma_interface_id
                                                         ,p_other_expenses               => r_invoice_lines.other_expenses
                                                         ,p_discount_amount              => r_invoice_lines.discount_amount
                                                         ,p_freight_amount               => r_invoice_lines.freight_amount
                                                         ,p_insurance_amount             => r_invoice_lines.insurance_amount
                                                         ,p_shipment_line_id             => r_invoice_lines.shipment_line_id
                                                         ,p_update_tax_code_reason       => NULL
                                                         ,p_tax_code_updated_by          => NULL
                                                         ,p_update_tax_code_date         => NULL
                                                       -- 28439553 - Start
                                                       --,p_project_id                   => r_invoice_lines.project_id
                                                       --,p_task_id                      => NVL(r_invoice_lines.task_id,l_task_id)
                                                       --,p_expenditure_type             => r_invoice_lines.expenditure_type
                                                       --,p_expenditure_organization_id  => NVL(r_invoice_lines.expenditure_organization_id,l_expenditure_organization_id)
                                                       --,p_expenditure_item_date        => r_invoice_lines.expenditure_item_date
                                                         ,p_project_id                   => l_po_project_id
                                                         ,p_task_id                      => l_po_task_id
                                                         ,p_expenditure_type             => l_po_expenditure_type
                                                         ,p_expenditure_organization_id  => l_po_expenditure_org_id
                                                         ,p_expenditure_item_date        => l_po_expenditure_item_date
                                                         -- 28439553 - End
                                                         ,p_account_created_by_type      => r_invoice_lines.db_code_combination_id
                                                         ,p_tributary_status_code        => r_invoice_lines.tributary_status_code
                                                         ,p_interface_invoice_line_id    => r_invoice_lines.interface_invoice_line_id
                                                         ,p_cofins_amount_recover        => r_invoice_lines.cofins_amount_recover
                                                         ,p_awt_group_id                 => r_invoice_lines.awt_group_id
                                                         ,p_freight_ap_flag              => r_invoice_lines.freight_ap_flag
                                                         ,p_importation_pis_cofins_base  => r_invoice_lines.importation_pis_cofins_base
                                                         ,p_importation_pis_amount       => r_invoice_lines.importation_pis_amount
                                                         ,p_importation_cofins_amount    => r_invoice_lines.importation_cofins_amount
                                                         ,p_ipi_unit_amount              => r_invoice_lines.ipi_unit_amount
                                                       --,p_city_service_type_rel_id     => NVl(l_city_serv_type_rel_id,l_city_service_type_rel_id)                  -- 25591653
                                                         ,p_city_service_type_rel_id     => NVl(r_invoice_lines.city_service_type_rel_id,l_city_service_type_rel_id) -- 25591653
                                                         ,p_federal_service_type_id      => l_federal_service_type_id
                                                         ,p_municipal_service_type_id    => l_municipal_service_type_id
                                                         ,p_iss_tax_type                 => l_iss_tax_type
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
                                                         ,p_pis_amount_rec_lin           => r_invoice_lines.pis_amount_recover
                                                         ,p_cofins_amount_rec_lin        => r_invoice_lines.cofins_amount_recover
                                                         ,p_deferred_icms_amount         => r_invoice_lines.deferred_icms_amount
                                                         ,p_net_amount                   => r_invoice_lines.net_amount
                                                         ,p_icms_base_reduc_perc         => r_invoice_lines.icms_base_reduc_perc
                                                         ,p_vehicle_oper_type            => r_invoice_lines.vehicle_oper_type
                                                         ,p_vehicle_chassi               => r_invoice_lines.vehicle_chassi
                                                         ,p_uom_po                       => l_uom_po
                                                         ,p_quantity_uom_po              => l_quantity_uom_po
                                                         ,p_unit_price_uom_po            => l_unit_price_uom_po
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
                                                         ,p_anvisa_product_code          => r_invoice_lines.anvisa_product_code            -- 25713076
                                                         ,p_anp_product_code             => r_invoice_lines.anp_product_code               -- 25713076
                                                       --,p_anp_product_description      => r_invoice_lines.anp_product_description        -- 25713076 -- 26987509 - 26986232
                                                         ,p_anp_product_descr            => r_invoice_lines.anp_product_descr              -- 26987509 - 26986232
                                                         ,p_product_lot_number           => r_invoice_lines.product_lot_number             -- 26987509 - 26986232
                                                         ,p_lot_quantity                 => r_invoice_lines.lot_quantity                   -- 25713076
                                                         ,p_production_date              => r_invoice_lines.production_date                -- 25713076
                                                         ,p_expiration_date              => r_invoice_lines.expiration_date                -- 25713076
                                                         ,p_aggregation_code             => r_invoice_lines.aggregation_code               -- 25713076
                                                         ,p_glp_derived_oil_perc         => r_invoice_lines.glp_derived_oil_perc           -- 25713076
                                                         ,p_glgnn_glp_product_perc       => r_invoice_lines.glgnn_glp_product_perc         -- 25713076
                                                         ,p_glgni_glp_product_perc       => r_invoice_lines.glgni_glp_product_perc         -- 25713076
                                                         ,p_starting_value               => r_invoice_lines.starting_value                 -- 25713076
                                                         ,p_codif_authorization          => r_invoice_lines.codif_authorization            -- 25713076
                                                         ,p_iss_city_id                  => NVL(r_invoice_lines.iss_city_id,l_city_id)     -- 25591653
                                                         ,p_service_execution_date       => r_invoice_lines.service_execution_date         -- 25591653
                                                         ,p_iss_fo_base_amount           => r_invoice_lines.iss_fo_base_amount             -- 25591653
                                                         ,p_iss_fo_tax_rate              => r_invoice_lines.iss_fo_tax_rate                -- 25591653
                                                         ,p_iss_fo_amount                => r_invoice_lines.iss_fo_amount                  -- 25591653
                                                         ,p_significant_scale_prod_ind   => r_invoice_lines.significant_scale_prod_ind     -- 27501091
                                                         ,p_manufac_goods_doc_number     => r_invoice_lines.manufac_goods_doc_number       -- 27501091
                                                         ,p_fcp_base_amount              => r_invoice_lines.fcp_base_amount                -- 27501091
                                                         ,p_fcp_rate                     => r_invoice_lines.fcp_rate                       -- 27501091
                                                         ,p_fcp_amount                   => r_invoice_lines.fcp_amount                     -- 27501091
                                                         ,p_fcp_st_base_amount           => r_invoice_lines.fcp_st_base_amount             -- 27501091
                                                         ,p_fcp_st_rate                  => r_invoice_lines.fcp_st_rate                    -- 27501091
                                                         ,p_fcp_st_amount                => r_invoice_lines.fcp_st_amount                  -- 27501091
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
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --165;
          -- Begin Bug 24387238
          p_line_location_id      := NVL(l_line_location_id,r_invoice_lines.line_location_id);
          p_requisition_line_id   := r_invoice_lines.requisition_line_id;
          p_item_id               := NVL(r_invoice_lines.item_id,l_item_id_oc);
          x_INVOICE_LINE_ID_S     := l_invoice_line_id_s;
          x_INVOICE_ID_S          := g_cll_f189_invoices_s; --ER 26338366/26899224 2a fase Third party network

          -- End Bug 24387238
          --
          g_cont_line := l_count;
          --
          IF NVL(g_generate_line_compl,'N') = 'Y' THEN
            CLL_F189_OPEN_VALIDATE_PUB.GENERATE_LINE_COMPL(p_interface_invoice_line_id => r_invoice_lines.interface_invoice_line_id
                                                          ,p_invoice_line_id_s         => l_invoice_line_id_s
                                                          ,p_cll_f189_invoices_s       => g_cll_f189_invoices_s
                                                          -- out
                                                          ,p_return_code               => l_return_code
                                                          ,p_return_message            => l_return_message
                                                          );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --167;
            --

          END IF; --IF NVL(g_generate_line_compl,'N') = 'Y' THEN
          --
          IF g_aprova = 'Y' and p_requisition_type = 'NA'  THEN
             --
             g_index  := p_interface_operation_id;
             l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --175;
             --
            IF NOT(r_cll_f189_operation.exists(g_index))THEN
              r_cll_f189_operation(g_index).organization_id        := p_organization_id;
              r_cll_f189_operation(g_index).new_operation_id       := g_cll_f189_entry_operations_s;
              r_cll_f189_operation(g_index).location_id            := p_location_id;
              r_cll_f189_operation(g_index).gl_date                := p_gl_date;
              r_cll_f189_operation(g_index).receive_date           := NVL(p_receive_date,SYSDATE);
              r_cll_f189_operation(g_index).user_id                := l_user_id;
              r_cll_f189_operation(g_index).interface_operation_id := p_interface_operation_id;
              r_cll_f189_operation(g_index).interface_invoice_id   := p_interface_invoice_id;
            END IF;
          END IF; --IF g_aprova = 'Y' THEN
          --
      END IF; --IF p_type = 'VALIDATION' THEN
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --176;
      --<<Bug 17375006 - Egini - 01/09/2013 - Inicio >>--
      BEGIN
         --
         UPDATE CLL_F189_INV_LINE_IFACE_TMP
         SET classification_id = l_classification_id
            ,cfo_id            = l_cfo_id
            ,utilization_id    = l_utilization_id
            ,iss_city_id       = l_city_id                               -- 25591653
            ,city_service_type_rel_id = l_city_serv_type_rel_id          -- 25591653
            ,project_id                  = l_project_id                  -- 27938576
            ,task_id                     = l_task_id                     -- 27938576
            ,expenditure_type            = l_expenditure_type            -- 27938576
            ,expenditure_organization_id = l_expenditure_organization_id -- 27938576
         WHERE INTERFACE_INVOICE_LINE_ID = r_invoice_lines.INTERFACE_INVOICE_LINE_ID;
         --
      END;
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --177;
  --
  --<<Bug 17375006 - Egini - 01/09/2013 - Inicio >>--
    --<< ER 26338366/26899224 Start>>
    --TPA Open Interface

    FOR r_invoice_lines_tpa IN c_invoice_lines_tpa ( r_invoice_lines.interface_invoice_line_id ) LOOP -- Bug 29553127
      --
      IF x_INVOICE_LINE_ID_S IS NOT NULL THEN
        --
        BEGIN
          --
          CREATE_OPEN_TPA_RETURNS ( p_type                      => 'INSERT'
                                  , p_tpa_return_control_id     => CLL_F513_TPA_RETURNS_CTRL_PUB.GET_TPA_RET_CONTROL_S
                                  , p_organization_id           => r_invoice_lines_tpa.organization_id
                                  , p_tpa_remit_control_id      => r_invoice_lines_tpa.tpa_remit_control_id
                                  , p_ship_to_site_user_id      => r_invoice_lines_tpa.ship_to_site_use_id
                                  , p_operation_id              => g_cll_f189_entry_operations_s
                                  , p_entity_id                 => p_entity_id
                                  , p_operation_status          => g_operation_status
                                  , p_reversion_transaction_id  => NULL
                                  , p_invoice_id                => x_INVOICE_ID_S --  g_cll_f189_invoices_s --r_invoice_lines_tpa.interface_invoice_id --g_cll_f189_invoices_s
                                  , p_invoice_line_id           => x_INVOICE_LINE_ID_S --r_invoice_lines_tpa.interface_invoice_line_id --l_invoice_line_id_s
                                  , p_interface_invoice_id      => r_invoice_lines_tpa.interface_invoice_id --g_cll_f189_invoices_s
                                  , p_interface_invoice_line_id => r_invoice_lines_tpa.interface_invoice_line_id --l_invoice_line_id_s
                                  , p_invoice_number            => r_invoice_lines_tpa.invoice_number
                                  , p_invoice_date              => r_invoice_lines_tpa.invoice_date
                                  , p_returned_date             => r_invoice_lines_tpa.receive_date
                                  , p_inventory_item_id         => NVL(r_invoice_lines.item_id,l_item_id_oc)
                                  , p_returned_quantity         => r_invoice_lines_tpa.quantity --ER 26338366/26899224 --r_invoice_lines.quantity --r_invoice_lines_tpa.returned_quantity
                                  , p_new_subinventory_code     => r_invoice_lines_tpa.new_subinventory_code
                                  , p_new_locator_id            => r_invoice_lines_tpa.NEW_LOCATOR_id
                                  , p_new_locator_code          => r_invoice_lines_tpa.NEW_LOCATOR_code
                                  , p_unit_price                => r_invoice_lines.unit_price
                                  , p_returned_transaction_id   => NULL
                                  , p_reversion_flag            => NULL
                                  , p_attribute_category        => r_invoice_lines_tpa.attribute_category
                                  , p_attribute1                => r_invoice_lines_tpa.attribute1
                                  , p_attribute2                => r_invoice_lines_tpa.attribute2
                                  , p_attribute3                => r_invoice_lines_tpa.attribute3
                                  , p_attribute4                => r_invoice_lines_tpa.attribute4
                                  , p_attribute5                => r_invoice_lines_tpa.attribute5
                                  , p_attribute6                => r_invoice_lines_tpa.attribute6
                                  , p_attribute7                => r_invoice_lines_tpa.attribute7
                                  , p_attribute8                => r_invoice_lines_tpa.attribute8
                                  , p_attribute9                => r_invoice_lines_tpa.attribute9
                                  , p_attribute10               => r_invoice_lines_tpa.attribute10
                                  , p_attribute11               => r_invoice_lines_tpa.attribute11
                                  , p_attribute12               => r_invoice_lines_tpa.attribute12
                                  , p_attribute13               => r_invoice_lines_tpa.attribute13
                                  , p_attribute14               => r_invoice_lines_tpa.attribute14
                                  , p_attribute15               => r_invoice_lines_tpa.attribute15
                                  , p_attribute16               => r_invoice_lines_tpa.attribute16
                                  , p_attribute17               => r_invoice_lines_tpa.attribute17
                                  , p_attribute18               => r_invoice_lines_tpa.attribute18
                                  , p_attribute19               => r_invoice_lines_tpa.attribute19
                                  , p_attribute20               => r_invoice_lines_tpa.attribute20
                                  , p_created_by                => r_invoice_lines_tpa.created_by
                                  , p_creation_date             => r_invoice_lines_tpa.creation_date
                                  , p_last_update_date          => sysdate
                                  , p_last_update_login         => r_invoice_lines_tpa.last_update_login
                                  , p_request_id                => NULL
                                  , p_program_application_id    => r_invoice_lines_tpa.program_application_id
                                  , p_program_id                => NULL
                                  , p_program_update_date       => sysdate
                                  , p_item_number               => r_invoice_lines_tpa.item_number            -- ER  26338366/26899224 2a fase
                                  , p_symbolic_return_flag      => r_invoice_lines_tpa.symbolic_return_flag   -- ENR 30120364
                                  , p_return_code               => l_return_code
                                  , p_return_message            => l_return_message
                                  ) ;
        END ;
    --
      END IF ;
  --
    END LOOP r_invoice_lines_tpa ;
    --
    -- << ER 26338366/26899224 End>>
    --
    -- Enh 29907995 - Start
    --
    IF cll_f189_open_validate_pub.get_cfop_devolution ( p_inv_type_id   => p_invoice_type_id, p_inv_type_code => NULL ) = 'Y' THEN
      FOR r_dev_tpa IN c_inv_lines_dev_tpa ( r_invoice_lines.interface_invoice_line_id ) LOOP
        IF x_INVOICE_LINE_ID_S IS NOT NULL THEN
          BEGIN
            --
            l_rec_tpa_devol_ctrl := l_crec_tpa_devol_ctrl ;
            --
            l_rec_tpa_devol_ctrl.devolution_operation_id    := g_cll_f189_entry_operations_s ;
            l_rec_tpa_devol_ctrl.tpa_devolutions_control_id := cll_f513_tpa_devol_ctrl_s.NEXTVAL ;
            l_rec_tpa_devol_ctrl.tpa_receipts_control_id    := r_dev_tpa.tpa_receipt_control_id ;
            l_rec_tpa_devol_ctrl.org_id                     := r_dev_tpa.org_id ;
            l_rec_tpa_devol_ctrl.devolution_status          := 'INVOICE PENDING' ;
            l_rec_tpa_devol_ctrl.organization_id            := p_organization_id ;
            l_rec_tpa_devol_ctrl.devolution_entity_id       := p_entity_id ;
            l_rec_tpa_devol_ctrl.devolution_invoice_id      := x_INVOICE_ID_S ;
            l_rec_tpa_devol_ctrl.devolution_invoice_line_id := x_INVOICE_LINE_ID_S ;
            l_rec_tpa_devol_ctrl.devolution_item_number     := r_dev_tpa.item_number ;
            l_rec_tpa_devol_ctrl.ship_to_site_use_id        := r_dev_tpa.ship_to_site_use_id ;
            l_rec_tpa_devol_ctrl.devolution_date            := r_dev_tpa.invoice_date ;
            l_rec_tpa_devol_ctrl.inventory_item_id          := r_dev_tpa.item_id ;
            l_rec_tpa_devol_ctrl.item_uom_code              := r_dev_tpa.uom ;
            l_rec_tpa_devol_ctrl.unit_price                 := r_dev_tpa.unit_price ;
            l_rec_tpa_devol_ctrl.devolution_quantity        := r_dev_tpa.quantity ;
            l_rec_tpa_devol_ctrl.subinventory               := r_dev_tpa.new_subinventory_code ;
            l_rec_tpa_devol_ctrl.locator_id                 := r_dev_tpa.new_locator_id ;
            l_rec_tpa_devol_ctrl.parent_lot_number          := r_dev_tpa.parent_lot_number ;
            l_rec_tpa_devol_ctrl.lot_number                 := r_dev_tpa.lot_number ;
            l_rec_tpa_devol_ctrl.expiration_date            := r_dev_tpa.lot_expiration_date ;
            l_rec_tpa_devol_ctrl.serial_number              := r_dev_tpa.serial_number ;
            l_rec_tpa_devol_ctrl.receipt_transaction_id     := r_dev_tpa.receipt_transaction_id ;
            l_rec_tpa_devol_ctrl.devolution_account_id      := r_dev_tpa.db_code_combination_id ;
            l_rec_tpa_devol_ctrl.symbolic_devolution_flag   := r_dev_tpa.symbolic_devolution_flag ;
            l_rec_tpa_devol_ctrl.attribute_category         := r_dev_tpa.attribute_category ;
            l_rec_tpa_devol_ctrl.attribute1                 := r_dev_tpa.attribute1 ;
            l_rec_tpa_devol_ctrl.attribute2                 := r_dev_tpa.attribute2 ;
            l_rec_tpa_devol_ctrl.attribute3                 := r_dev_tpa.attribute3 ;
            l_rec_tpa_devol_ctrl.attribute4                 := r_dev_tpa.attribute4 ;
            l_rec_tpa_devol_ctrl.attribute5                 := r_dev_tpa.attribute5 ;
            l_rec_tpa_devol_ctrl.attribute6                 := r_dev_tpa.attribute6 ;
            l_rec_tpa_devol_ctrl.attribute7                 := r_dev_tpa.attribute7 ;
            l_rec_tpa_devol_ctrl.attribute8                 := r_dev_tpa.attribute8 ;
            l_rec_tpa_devol_ctrl.attribute9                 := r_dev_tpa.attribute9 ;
            l_rec_tpa_devol_ctrl.attribute10                := r_dev_tpa.attribute10 ;
            l_rec_tpa_devol_ctrl.attribute11                := r_dev_tpa.attribute11 ;
            l_rec_tpa_devol_ctrl.attribute12                := r_dev_tpa.attribute12 ;
            l_rec_tpa_devol_ctrl.attribute13                := r_dev_tpa.attribute13 ;
            l_rec_tpa_devol_ctrl.attribute14                := r_dev_tpa.attribute14 ;
            l_rec_tpa_devol_ctrl.attribute15                := r_dev_tpa.attribute15 ;
            l_rec_tpa_devol_ctrl.attribute16                := r_dev_tpa.attribute16 ;
            l_rec_tpa_devol_ctrl.attribute17                := r_dev_tpa.attribute17 ;
            l_rec_tpa_devol_ctrl.attribute18                := r_dev_tpa.attribute18 ;
            l_rec_tpa_devol_ctrl.attribute19                := r_dev_tpa.attribute19 ;
            l_rec_tpa_devol_ctrl.attribute20                := r_dev_tpa.attribute20 ;
            l_rec_tpa_devol_ctrl.created_by                 := r_dev_tpa.created_by ;
            l_rec_tpa_devol_ctrl.creation_date              := SYSDATE ;
            l_rec_tpa_devol_ctrl.last_update_date           := SYSDATE ;
            l_rec_tpa_devol_ctrl.last_updated_by            := r_dev_tpa.last_updated_by ;
            l_rec_tpa_devol_ctrl.last_update_login          := r_dev_tpa.last_update_login ;
            --
            create_open_tpa_devolut ( 'INSERT', l_rec_tpa_devol_ctrl, l_return_code, l_return_message ) ;
            --
           END ;
        END IF ;
      END LOOP ;
    END IF ;
    --
    -- Enh 29907995 - End
    --
    END LOOP ; -- r_invoice_lines
    print_log('  Fim do Loop (invoice lines)'); 
    print_log('  FIM CREATE_OPEN_LINES');
  END CREATE_OPEN_LINES ;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_FREIGHT                                         |
  |                                                                          |
  | Description: Responsible for validate information and insert into RI     |
  |              final tables or insert errors in RI or Loader interface     |
  |              tables                                                      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OPEN_FREIGHT (p_type                           IN VARCHAR2
                                ,p_interface_operation_id         IN NUMBER
                                ,p_location_id                    IN NUMBER
                                ,p_operating_unit                 IN NUMBER
                                ,p_gl_date                        IN DATE
                                ,p_set_of_books_id                IN NUMBER
                                ,p_fiscal_flag                    IN VARCHAR2
                                ,p_source_state_id                IN NUMBER
                                ,p_destination_state_id           IN NUMBER
                                ,p_pis_amount_recover_cnpj        IN NUMBER
                                ,p_cofins_amount_recover_cnpj     IN NUMBER
                                ,p_cll_f189_entry_operations_s    IN NUMBER
                                ,p_first_payment_date             IN DATE         -- 27854379
                                ,p_first_payment_date_out         OUT NOCOPY DATE -- 27854379
                                ,p_process_flag                   OUT NOCOPY NUMBER
                                ,p_return_code                    OUT NOCOPY VARCHAR2
                                ,p_return_message                 OUT NOCOPY VARCHAR2
                                ) IS

  CURSOR c_valida_freight IS
        SELECT refr.interface_invoice_id
              ,refr.interface_operation_id
              ,refr.organization_id
              ,refr.organization_code
              ,refr.location_id
              ,refr.location_code
              ,refr.invoice_type_id
              ,refr.invoice_type_code
         FROM cll_f189_freight_inv_iface_tmp refr
        WHERE refr.interface_operation_id = NVL(p_interface_operation_id,refr.interface_operation_id);


  CURSOR c_freight IS
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
              ,refr.pis_tributary_code
              ,refr.cofins_tributary_code
              ,NVL(orga.soma_org_id,0)   soma_org_id
              ,NVL(loca.soma_location,0) soma_location
              ,NVL(inty.soma_inv_type,0) soma_inv_type
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
              ,refr.usage_authorization -- ER 20382276
              ,refr.source_city_id             -- 27463767
              ,refr.destination_city_id        -- 27463767
              ,refr.source_ibge_city_code      -- 27463767
              ,refr.destination_ibge_city_code -- 27463767
              ,refr.reference                  -- 27579747
              ,refr.ship_to_state_id           -- 28487689 - 28597878
        FROM cll_f189_freight_inv_iface_tmp refr
            ,(SELECT COUNT(1) soma_org_id
                    ,interface_operation_id
                FROM cll_f189_freight_inv_interface
               GROUP BY organization_id
                       ,interface_operation_id)     orga
            --
            ,(SELECT COUNT(1) soma_location
                    ,interface_operation_id
                FROM cll_f189_freight_inv_interface
               GROUP BY location_id
                       ,interface_operation_id)     loca
            --
            ,(SELECT COUNT(1) soma_inv_type
                    ,interface_operation_id
                FROM cll_f189_freight_inv_interface
               GROUP BY invoice_type_id
                       ,interface_operation_id)     inty
        WHERE refr.interface_operation_id = orga.interface_operation_id
          AND refr.interface_operation_id = loca.interface_operation_id
          AND refr.interface_operation_id = inty.interface_operation_id
          AND refr.interface_operation_id = NVL(p_interface_operation_id,refr.interface_operation_id);
    --
    --
    l_soma_freight_operation            NUMBER;
    --
    l_entity_id_out                     NUMBER;
    l_vendor_id                         NUMBER;
    l_document_type_out                 VARCHAR2(30);
    l_business_vendor_id                NUMBER;
    --
    l_validation_rule_series            VARCHAR2(80);
    l_validation_rule_subseries         VARCHAR2(80);
    l_validation_rule_icms_type         VARCHAR2(80);
    l_validation_rule_icms              VARCHAR2(80);
    l_validation_rule_cst_pis           VARCHAR2(80);
    l_validation_rule_cst_cofins        VARCHAR2(80);
    l_validation_rule_fisc_doc_mod      VARCHAR2(80);
    --
    l_qty_freight_invoices              NUMBER;
    l_qty_freight_invoices_tmp          NUMBER;
    --
    l_invoice_type_id                   cll_f189_invoice_types.invoice_type_id%type;
    l_requisition_type                  cll_f189_invoice_types.requisition_type%type;
    l_utilities_flag                    cll_f189_invoice_types.utilities_flag%type;
    l_payment_flag                      cll_f189_invoice_types.payment_flag%type;
    l_inss_additional_tax_1             cll_f189_invoice_types.inss_additional_tax_1%type;
    l_inss_additional_tax_2             cll_f189_invoice_types.inss_additional_tax_2%type;
    l_inss_additional_tax_3             cll_f189_invoice_types.inss_additional_tax_3%type;
    l_inss_substitute_flag              cll_f189_invoice_types.inss_substitute_flag%type;
    l_inss_tax                          cll_f189_invoice_types.inss_tax%type;
    l_parent_flag                       cll_f189_invoice_types.parent_flag%type;
    l_project_flag                      cll_f189_invoice_types.project_flag%type;
    l_cost_adjust_flag                  cll_f189_invoice_types.cost_adjust_flag%type;
    l_price_adjust_flag                 cll_f189_invoice_types.price_adjust_flag%type;
    l_tax_adjust_flag                   cll_f189_invoice_types.tax_adjust_flag%type;
    l_include_iss_flag                  cll_f189_invoice_types.include_iss_flag%type;
    l_pis_flag                          cll_f189_invoice_types.pis_flag%type;
    l_cofins_flag                       cll_f189_invoice_types.cofins_flag%type;
    l_cofins_code_combination_id        cll_f189_invoice_types.cofins_code_combination_id%type;
    l_contab_flag                       cll_f189_invoice_types.contab_flag%type;
    l_inss_calculation_flag             cll_f189_invoice_types.inss_calculation_flag%type;
    l_freight_flag                      cll_f189_invoice_types.freight_flag%type;
    l_fixed_assets_flag                 cll_f189_invoice_types.fixed_assets_flag%type;
    l_fiscal_flag                       cll_f189_invoice_types.fiscal_flag%type;
    l_return_customer_flag              cll_f189_invoice_types.return_customer_flag%type;-- Bug 20130095
    l_error_code                        VARCHAR2(100) := NULL;
    --
    l_period_name                       gl_period_statuses.period_name%type;
    l_terms_id                          ap_terms.term_id%type;
    l_dmf                               NUMBER;
    l_ddm                               NUMBER;
    l_dd                                NUMBER;
    l_dcd                               NUMBER;
    l_first_payment_date                DATE;
    --
    l_validate_flag                     VARCHAR2(1)  := NVL(fnd_profile.value('CLL_F189_INVOICE_NUMBER_VALIDATE'),'N');
    l_cfo_transporter                   VARCHAR2(1) := NVL(fnd_profile.value('CLL_F189_CFO_TRANSPORTER'),0);
    l_cfo_id                            cll_f189_fiscal_operations.cfo_id%type;
    l_utilization_id                    cll_f189_item_utilizations.utilization_id%type;
    l_utilization_cfo                   NUMBER;
    l_contract_id                       NUMBER;
    l_ship_via_lookup_code              VARCHAR2(50);
    --
    l_source_state_id                   NUMBER;
    l_destination_state_id              NUMBER;
    l_source_city_id                    NUMBER; -- 28487689 - 28597878
    l_destination_city_id               NUMBER; -- 28487689 - 28597878
    l_ship_to_state_id                  NUMBER; -- 28487689 - 28597878
    l_source_ibge_city_code             NUMBER; -- 28730077
    l_destination_ibge_city_code        NUMBER; -- 28730077
    --
    l_freight_invoice_num_dec           NUMBER;
    l_max_freight_invoice_num           NUMBER;
    --
    l_interface_invoice_num             cll_f189_freight_inv_iface_tmp.invoice_num%type;
    l_freight_inv_s                     NUMBER;
    l_user_id                           NUMBER := FND_GLOBAL.USER_ID;
    --
    l_return_code                       VARCHAR2(100);
    l_return_message                    VARCHAR2(500);
    --
    l_cfo_code                          VARCHAR2(100);
    l_utilization_code                  VARCHAR2(100);
    --
    -- Inicio BUG 19722064
    l_organization_id                   NUMBER;
    l_operating_unit                    NUMBER;
    l_set_of_books_id                   NUMBER;
    l_chart_of_accounts_id              NUMBER;
    l_location_id                       NUMBER;
    l_error                             VARCHAR2(100) := NULL;
    -- Fim BUG 19722064
    --
    l_loader_exist                      NUMBER; -- ER 14124731
    -- Inicio BUG 23018594
    x_source_state_id               cll_f189_freight_inv_interface.source_state_id%type;        -- 23018594
    x_source_state_code             cll_f189_freight_inv_interface.source_state_code%type;      -- 23018594
    x_destination_state_id          cll_f189_freight_inv_interface.destination_state_id%type;   -- 23018594
    x_destination_state_code        cll_f189_freight_inv_interface.destination_state_code%type; -- 23018594
    --
    l_frt_ship_via_lookup_code      fnd_lookup_values_vl.lookup_code%type; -- 23091360
    --
    --  v_source_state_id           cll_f189_freight_inv_interface.source_state_id%type;        -- 23018594
    --  v_destination_state_id      cll_f189_freight_inv_interface.destination_state_id%type;   -- 23018594
    -- Fim BUG 23018594
    --
  BEGIN
    print_log('  CREATE_OPEN_FREIGHT');
    --
    -- Iniciando validacoes do Frete
    --
    -- Inicio BUG 19722064
    FOR r_valida_freight IN c_valida_freight LOOP
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --460;
        ---------------------------
        -- Validando Organizacao --
        ---------------------------
        CLL_F189_OPEN_VALIDATE_PUB.GET_ORGANIZATION_ID (
          p_organization_code     => r_valida_freight.organization_code
          ,p_organization_id_in   => r_valida_freight.organization_id
          --out
          ,p_organization_id_out  => l_organization_id
          ,p_operating_unit       => l_operating_unit
          ,p_set_of_books_id      => l_set_of_books_id
          ,p_chart_of_accounts_id => l_chart_of_accounts_id
          ,p_error_code           => l_error
        );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --461;
        ---------------------
        -- Validando Local --
        ---------------------
        BEGIN
          SELECT location_id
            INTO l_location_id
            FROM hr_locations
           WHERE (location_id   = r_valida_freight.location_id OR
                  location_code = r_valida_freight.location_code);
        EXCEPTION WHEN NO_DATA_FOUND THEN
          l_location_id := NULL;
        END;
        ----------------------------
        -- Validando Invoice Type --
        ---------------------------
        CLL_F189_OPEN_VALIDATE_PUB.GET_INVOICE_TYPE_ID (p_invoice_type_id     => r_valida_freight.invoice_type_id
                                                       ,p_invoice_type_code   => r_valida_freight.invoice_type_code
                                                       ,p_organization_id     => r_valida_freight.organization_id
                                                       ,p_organization_code   => r_valida_freight.organization_code
                                                       --out
                                                       ,p_invoice_type_id_out  => l_invoice_type_id
                                                       ,p_error_code           => l_error
                                                       );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --462;
        IF  r_valida_freight.organization_id IS NULL AND
            r_valida_freight.organization_code IS NOT NULL THEN
            --
            UPDATE cll_f189_freight_inv_iface_tmp
               SET organization_id  = l_organization_id
             WHERE interface_operation_id = p_interface_operation_id
               AND organization_code    = r_valida_freight.organization_code;
            --
        END IF;
        --
        IF  r_valida_freight.location_id IS NULL AND
            r_valida_freight.location_code IS NOT NULL THEN
            --
            UPDATE cll_f189_freight_inv_iface_tmp
               SET location_id  = l_location_id
             WHERE interface_operation_id = p_interface_operation_id
               AND location_code    = r_valida_freight.location_code;
            --
        END IF;
        --
        IF  r_valida_freight.invoice_type_id IS NULL AND
            r_valida_freight.invoice_type_code IS NOT NULL THEN
            --
            UPDATE cll_f189_freight_inv_iface_tmp
               SET invoice_type_id      = l_invoice_type_id
             WHERE interface_operation_id = p_interface_operation_id
               AND invoice_type_code    = r_valida_freight.invoice_type_code;
            --
        END IF;
        --
        COMMIT;
        --
    END LOOP;
    -- Fim BUG 19722064
    --
    FOR r_freight IN c_freight LOOP

        IF p_type = 'VALIDATION' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --463;
            --------------------------------------------------------------------
            -- Validacoes iniciais do frete - campos obrigatorios preenchidos --
            --------------------------------------------------------------------
            --
            IF r_freight.organization_id IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'ORGANIZATION NOTFND'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --464;
            --
            IF r_freight.interface_invoice_id IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'FRTINTERF INVID NOT NULL'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
            --
            ---------------------------------------------------
            -- Validando a soma dos valores na nota de frete --
            ---------------------------------------------------
            BEGIN
                SELECT COUNT(1)
                  INTO l_soma_freight_operation
                  FROM /*cll_f189_freight_inv_iface_tmp*/
                       cll_f189_freight_inv_interface
                 WHERE interface_operation_id = r_freight.interface_operation_id
                   AND organization_id        = r_freight.organization_id;
            EXCEPTION
                WHEN OTHERS THEN
                    l_soma_freight_operation := 0;
            END;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --465;
            --
            IF l_soma_freight_operation <> r_freight.soma_org_id THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'DIFFERENT FRTORGANIZATION'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF l_soma_freight_operation <> r_freight.soma_location THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'DIFFERENT FRTLOCATION'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF l_soma_freight_operation <> r_freight.soma_inv_type THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'DIFFERENT FRTINVOICE_TYPE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
            --
            -------------------------------
            -- Validando o transportador --
            -------------------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --466;
            --
            IF r_freight.entity_id IS NULL AND (r_freight.document_type IS NULL OR r_freight.document_number IS NULL) THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTVENDOR SITE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                --
                CLL_F189_OPEN_VALIDATE_PUB.GET_FISCAL_ENTITIES (p_operating_unit     => p_operating_unit
                                                               ,p_entity_id          => r_freight.entity_id
                                                               ,p_document_type      => r_freight.document_type
                                                               ,p_document_number    => r_freight.document_number
                                                               ,p_ie                 => NULL
                                                               -- out
                                                               ,p_entity_id_out      => l_entity_id_out
                                                               ,p_vendor_id          => l_vendor_id
                                                               ,p_document_type_out  => l_document_type_out
                                                               ,p_business_vendor_id => l_business_vendor_id
                                                               );
                --
                IF r_freight.entity_id IS NOT NULL AND r_freight.document_type IS NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --467;
                    --
                    IF l_entity_id_out IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTVENDOR SITE ID'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => r_freight.entity_id
                                 );
                    END IF;
                ELSIF r_freight.document_type IS NOT NULL AND r_freight.entity_id IS NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --468;
                    --
                    IF l_entity_id_out IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTVENDOR SITE NUM'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => 'DOC TYPE = '||r_freight.document_type||' - DOC NUMBER = '||r_freight.document_type
                                 );
                    END IF;
                ELSE
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --469;
                    --
                    IF l_entity_id_out IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTVENDOR SITE'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => 'ID = '||r_freight.document_type||' - DOC TYPE = '||r_freight.document_type||' - DOC NUMBER = '||r_freight.document_type
                                 );
                    END IF;
                END IF; -- IF r_freight.entity_id IS NOT NULL AND r_freight.document_type IS NULL THEN
            END IF; -- IF r_freight.entity_id IS NULL AND (r_freight.document_type IS NULL OR r_freight.document_number IS NULL) THEN
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --470;
            --
            ----------------------------------------
            -- Validando a serie da nota de frete --
            ----------------------------------------
            IF r_freight.series IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTSERIES'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                l_validation_rule_series := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_INVOICE_SERIES'
                                                                                                  ,p_code            => r_freight.series
                                                                                                  ,p_invoice_type_id => r_freight.invoice_type_id
                                                                                                  ,p_validity_type   => 'INVOICE SERIES'
                                                                                                  );
                IF l_validation_rule_series IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTSERIES'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                             ,p_invalid_value          => r_freight.series
                             );
                END IF;
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --471;
            --
            --------------------------------------------
            -- Validando a sub-serie da nota de frete --
            --------------------------------------------
            --
            IF r_freight.subseries IS NOT NULL THEN
                l_validation_rule_subseries := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_INVOICE_SUBSERIES'
                                                                                                     ,p_code            => r_freight.subseries
                                                                                                     ,p_invoice_type_id => r_freight.invoice_type_id
                                                                                                     ,p_validity_type   => 'INVOICE SUBSERIES'
                                                                                                     );
                IF l_validation_rule_subseries IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTSUBSERIES'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                             ,p_invalid_value          => r_freight.subseries
                             );
                END IF;
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --472;
            --
            --------------------------------------------
            -- Validando duplicidade da nota de frete --
            --------------------------------------------
            --
            -- Recuperando quantidade da nota na open
            --
            BEGIN
                SELECT count(*)
                  INTO l_qty_freight_invoices_tmp
                  FROM /*cll_f189_freight_inv_iface_tmp*/
                       cll_f189_freight_inv_interface
                 WHERE interface_operation_id = r_freight.interface_operation_id
                   AND entity_id              = NVL(r_freight.entity_id,l_entity_id_out)
                   AND series                 = r_freight.series
                   AND invoice_num            = r_freight.invoice_num
                   AND ( (l_validate_flag     = 'Y' AND trunc(invoice_date) = trunc(r_freight.invoice_date))
                      OR (l_validate_flag     = 'N'));

            EXCEPTION
                WHEN OTHERS THEN
                    l_qty_freight_invoices_tmp := 0;
            END;
            --
            -- Recuperando decimal no numero da nota na open
            --
            BEGIN
                SELECT DECODE ((invoice_num * 100) - (TRUNC (invoice_num) * 100)
                               ,0
                               ,0
                               ,1
                              )       invoice_num_dec
                  INTO l_freight_invoice_num_dec
                  FROM cll_f189_freight_inv_iface_tmp
                 WHERE entity_id           = NVL(r_freight.entity_id,l_entity_id_out)
                   AND series              = r_freight.series
                   AND invoice_num         = r_freight.invoice_num
                   AND ( (l_validate_flag = 'Y' AND trunc(invoice_date) = trunc(r_freight.invoice_date))
                      OR (l_validate_flag = 'N')
                      );
            EXCEPTION
                WHEN OTHERS THEN
                    l_freight_invoice_num_dec := 0;
            END;
            --
            -- Iniciando validacoes
            --
            IF l_validate_flag = 'Y' THEN
                l_qty_freight_invoices := CLL_F189_OPEN_VALIDATE_PUB.GET_QTY_FREIGHT_INVOICE (p_entity_id    => NVL(r_freight.entity_id,l_entity_id_out)
                                                                                             ,p_invoice_num  => r_freight.invoice_num
                                                                                             ,p_series       => r_freight.series
                                                                                             ,p_invoice_date => r_freight.invoice_date
                                                                                             );
               -- 23018594 - Start
               IF g_interface_invoice_num <> r_freight.invoice_num OR g_interface_invoice_num IS NULL THEN

                  g_interface_invoice_num := r_freight.invoice_num;
               -- 23018594 - End

                   IF (l_qty_freight_invoices > 0 ) OR (l_qty_freight_invoices_tmp > 1 ) THEN
                       ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                ,p_interface_operation_id => r_freight.interface_operation_id
                                ,p_organization_id        => r_freight.organization_id
                                ,p_error_code             => 'DUPLICATED FRTINVOICE'
                                ,p_invoice_line_id        => 0
                                ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                ,p_invalid_value          => r_freight.invoice_num
                                );
                   ELSE
                      --
                      -- Validando numero da nota revertida - com decimal
                      --
                      IF l_freight_invoice_num_dec = 1 THEN -- Encontrou nota com numero decimal informado na open
                         --
                         -- Recupera o maior valor da nota no RI
                         --
                         l_max_freight_invoice_num := CLL_F189_OPEN_VALIDATE_PUB.GET_MAX_FREIGHT_INVOICE_NUM (p_entity_id     => NVL(r_freight.entity_id,l_entity_id_out)
                                                                                                             ,p_series        => r_freight.series
                                                                                                             ,p_invoice_num   => r_freight.invoice_num
                                                                                                             ,p_invoice_date  => r_freight.invoice_date
                                                                                                             ,p_validate_flag => l_validate_flag
                                                                                                             );
                         --
                         -- Valida se o numero que esta na Open e maior que o maior numero existente no RI
                         --
                         IF r_freight.invoice_num <= l_max_freight_invoice_num THEN
                            ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                     ,p_interface_operation_id => r_freight.interface_operation_id
                                     ,p_organization_id        => r_freight.organization_id
                                     ,p_error_code             => 'DUPLICATED FRTINVOICE'
                                     ,p_invoice_line_id        => 0
                                     ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                     ,p_invalid_value          => 'OPEN = '||r_freight.invoice_num||'RI = '||l_max_freight_invoice_num
                                     );
                         END IF;
                      END IF; --IF l_freight_invoice_num_dec = 1 THEN
                  END IF; -- IF (l_qty_freight_invoices > 0 ) OR (l_qty_freight_invoices_tmp > 1 ) THEN
               END IF; -- 23018594 IF g_interface_invoice_num <> r_freight.invoice_num OR g_interface_invoice_num IS NULL
            ELSE -- IF l_validate_flag = 'Y' THEN
               --
               -- Busca qtde na tabela final do RI
               --
               l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --473;
               l_qty_freight_invoices := CLL_F189_OPEN_VALIDATE_PUB.GET_QTY_FREIGHT_INVOICE (p_entity_id    => NVL(r_freight.entity_id,l_entity_id_out)
                                                                                            ,p_invoice_num  => r_freight.invoice_num
                                                                                            ,p_series       => r_freight.series
                                                                                            ,p_invoice_date => NULL
                                                                                            );

               -- 23018594 - Start
               IF g_interface_invoice_num <> r_freight.invoice_num OR g_interface_invoice_num IS NULL THEN
                  --
                  g_interface_invoice_num := r_freight.invoice_num;
                  -- 23018594 - End
                  IF (l_qty_freight_invoices > 0 ) OR (l_qty_freight_invoices_tmp > 1 ) THEN
                     ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                              ,p_interface_operation_id => r_freight.interface_operation_id
                              ,p_organization_id        => r_freight.organization_id
                              ,p_error_code             => 'DUPLICATED FRTINVOICE'
                              ,p_invoice_line_id        => 0
                              ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                              ,p_invalid_value          => 'INVOICE_NUM = '||r_freight.invoice_num
                              );
                  ELSE
                     --
                     -- Validando numero da nota revertida - com decimal
                     --
                     IF l_freight_invoice_num_dec = 1 THEN -- Encontrou nota com numero decimal informado na open
                        --
                        -- Recupera o maior valor da nota no RI
                        --
                        l_max_freight_invoice_num := CLL_F189_OPEN_VALIDATE_PUB.GET_MAX_FREIGHT_INVOICE_NUM (p_entity_id     => NVL(r_freight.entity_id,l_entity_id_out)
                                                                                                            ,p_series        => r_freight.series
                                                                                                            ,p_invoice_num   => r_freight.invoice_num
                                                                                                            ,p_invoice_date  => NULL
                                                                                                            ,p_validate_flag => 'N'
                                                                                                            );
                        --
                        -- Valida se o numero que esta na Open e maior que o maior numero existente no RI
                        --
                        IF r_freight.invoice_num <= l_max_freight_invoice_num THEN
                           ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                    ,p_interface_operation_id => r_freight.interface_operation_id
                                    ,p_organization_id        => r_freight.organization_id
                                    ,p_error_code             => 'DUPLICATED FRTINVOICE'
                                    ,p_invoice_line_id        => 0
                                    ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                    ,p_invalid_value          => 'OPEN = '||r_freight.invoice_num||'RI = '||l_max_freight_invoice_num
                                    );
                        END IF;
                     END IF; --IF l_freight_invoice_num_dec = 1 THEN
                  END IF; --IF (l_qty_freight_invoices > 0 ) OR (l_qty_freight_invoices_tmp > 1 ) THEN
               END IF;-- 23018594 g_interface_invoice_num <> r_freight.invoice_num OR g_interface_invoice_num IS NULL
            END IF; -- IF l_validate_flag = 'Y' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --478;
            --
            ------------------------------
            -- Validacoes valores nulos --
            ------------------------------
            IF r_freight.invoice_num IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTINVOICENUM'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --479;
            --
            IF r_freight.interface_operation_id IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'INTERFACE FRT OPERID NULL'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --480;
            --
            ------------------------------
            -- Validando Invoice Amount --
            ------------------------------
            IF r_freight.invoice_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTINVAMOUNT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF r_freight.invoice_amount <= 0 THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'INVALID FRTINVAMOUNT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => r_freight.invoice_amount
                         );
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --481;
            --
            ----------------------------
            -- Validando Invoice Date --
            ----------------------------
            IF r_freight.invoice_date IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTINVDATE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF TRUNC(r_freight.invoice_date) > TRUNC(SYSDATE) OR  -- BUG 19722064
                  TRUNC(r_freight.invoice_date) > p_gl_date THEN     -- BUG 19722064
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'INVALID FRTINVDATE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => r_freight.invoice_date
                         );
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --482;
            --
            ------------------------------
            -- Validando o Tipo de Nota --
            ------------------------------
            IF r_freight.invoice_type_id IS NULL AND r_freight.invoice_type_code IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTINVTYPE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => r_freight.invoice_date
                         );
            ELSE
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --483;
                CLL_F189_OPEN_VALIDATE_PUB.GET_INVOICE_TYPE_DATA (p_invoice_type_id            => r_freight.invoice_type_id
                                                                 ,p_invoice_type_code          => r_freight.invoice_type_code
                                                                 ,p_organization_id            => r_freight.organization_id
                                                                 -- out
                                                                 ,p_invoice_type_id_out        => l_invoice_type_id
                                                                 ,p_requisition_type           => l_requisition_type
                                                                 ,p_utilities_flag             => l_utilities_flag
                                                                 ,p_payment_flag               => l_payment_flag
                                                                 ,p_inss_additional_tax_1      => l_inss_additional_tax_1
                                                                 ,p_inss_additional_tax_2      => l_inss_additional_tax_2
                                                                 ,p_inss_additional_tax_3      => l_inss_additional_tax_3
                                                                 ,p_inss_substitute_flag       => l_inss_substitute_flag
                                                                 ,p_inss_tax                   => l_inss_tax
                                                                 ,p_parent_flag                => l_parent_flag
                                                                 ,p_project_flag               => l_project_flag
                                                                 ,p_cost_adjust_flag           => l_cost_adjust_flag
                                                                 ,p_price_adjust_flag          => l_price_adjust_flag
                                                                 ,p_tax_adjust_flag            => l_tax_adjust_flag
                                                                 ,p_include_iss_flag           => l_include_iss_flag
                                                                 ,p_pis_flag                   => l_pis_flag
                                                                 ,p_cofins_flag                => l_cofins_flag
                                                                 ,p_cofins_code_combination_id => l_cofins_code_combination_id
                                                                 ,p_contab_flag                => l_contab_flag
                                                                 ,p_inss_calculation_flag      => l_inss_calculation_flag
                                                                 ,p_freight_flag               => l_freight_flag
                                                                 ,p_fixed_assets_flag          => l_fixed_assets_flag
                                                                 ,p_fiscal_flag                => l_fiscal_flag
                                                                 ,p_return_customer_flag       => l_return_customer_flag -- Bug 20130095
                                                                 ,p_error_code                 => l_error_code
                                                                 );
                IF r_freight.invoice_type_id IS NOT NULL AND r_freight.invoice_type_code IS NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --484;
                    --
                    IF l_invoice_type_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTINVTYPE ID'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => r_freight.invoice_type_id
                                 );
                    END IF;
                ELSIF r_freight.invoice_type_code IS NOT NULL AND r_freight.invoice_type_id IS NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --485;
                    --
                    IF l_invoice_type_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTINVTYPE CODE'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => r_freight.invoice_type_code
                                 );
                    END IF;
                ELSE
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --486;
                    --
                    IF l_invoice_type_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTINVTYPE'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => 'ID = '||r_freight.invoice_type_code||' - CODE = '||r_freight.invoice_type_code
                                 );
                    END IF;
                END IF; --IF r_freight.invoice_type_id IS NOT NULL AND r_freight.invoice_type_code IS NULL THEN
            END IF; --IF r_freight.invoice_type_id IS NULL AND r_freight.invoice_type_code IS NULL THEN
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --487;
            ------------------------------------
            -- Validando periodo aberto no AP --
            ------------------------------------
            IF NVL(l_payment_flag, 'N') = 'Y' THEN
                l_period_name := CLL_F189_OPEN_VALIDATE_PUB.GET_GL_PERIODS (p_set_of_books_id => p_set_of_books_id
                                                                           ,p_gl_date         => p_gl_date
                                                                           );
                IF l_period_name IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRT AP_DATE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                             ,p_invalid_value          => 'INVOICE GL DATE = '||p_gl_date
                             );
                END IF;
            END IF;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --488;
            --
            --------------------
            -- Validando ICMS --
            --------------------
            IF r_freight.icms_type IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTICMSTYPE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                l_validation_rule_icms_type := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_ICMS_TYPE'
                                                                                                     ,p_code            => r_freight.icms_type
                                                                                                     ,p_invoice_type_id => NVL(r_freight.invoice_type_id,l_invoice_type_id)
                                                                                                     ,p_validity_type   => 'ICMS TYPE'
                                                                                                     );
                IF l_validation_rule_icms_type IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTICMSTYPE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                             ,p_invalid_value          => r_freight.icms_type
                             );
                END IF;
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --489;
            --
            IF r_freight.icms_base IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTICMSBASE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => r_freight.icms_type
                         );
            ELSIF r_freight.icms_type = 'NORMAL' AND r_freight.icms_base <= 0 THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'INVALID FRTICMSBASE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => 'TYPE = '||r_freight.icms_type||' - BASE = '||r_freight.icms_base
                         );
            ELSIF r_freight.icms_type = 'NOT APPLIED' AND r_freight.icms_base <> 0 THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'INVALID FRTICMSBASE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => 'TYPE = '||r_freight.icms_type||' - BASE = '||r_freight.icms_base
                         );
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --490;
            --
            IF r_freight.icms_amount IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTICMSAMT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSIF r_freight.icms_type = 'NORMAL' AND r_freight.icms_amount < 0 THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'INVALID FRTICMSAMT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => 'TYPE = '||r_freight.icms_type||' - AMOUNT = '||r_freight.icms_amount
                         );
            ELSIF r_freight.icms_type = 'NOT APPLIED' AND r_freight.icms_amount <> 0 THEN

                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'INVALID FRTICMSAMT'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => 'TYPE = '||r_freight.icms_type||' - AMOUNT = '||r_freight.icms_amount
                         );
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --491;
            --
            IF r_freight.icms_tax_code IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTICMSTAXCODE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                l_validation_rule_icms := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_STATE_TRIBUT_CODE'
                                                                                                ,p_code            => r_freight.icms_tax_code
                                                                                                ,p_invoice_type_id => NVL(r_freight.invoice_type_id,l_invoice_type_id)
                                                                                                ,p_validity_type   => 'ICMS TAXABLE FLAG'
                                                                                                );
                IF l_validation_rule_icms IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTICMSTAXCODE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                             ,p_invalid_value          => r_freight.icms_tax_code
                             );
                END IF;
            END IF;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --492;
            -----------------------
            -- Validando CST PIS --
            -----------------------
            -- Bug 20207037 - Start
            IF r_freight.pis_tributary_code IS NOT NULL THEN
            -- Bug 20207037 - End
                l_validation_rule_cst_pis := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_PIS_TRIBUTARY_CODE'
                                                                                                   ,p_code            => r_freight.pis_tributary_code
                                                                                                   ,p_invoice_type_id => NVL(r_freight.invoice_type_id,l_invoice_type_id)
                                                                                                   ,p_validity_type   => 'CST PIS'
                                                                                                   );
                IF l_validation_rule_cst_pis IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTCSTPISTAXCODE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                             ,p_invalid_value          => r_freight.pis_tributary_code
                             );
                END IF;
            END IF;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --493;
            --------------------------
            -- Validando CST COFINS --
            --------------------------
            -- Bug 20207037 - Start
            IF r_freight.cofins_tributary_code IS NOT NULL THEN
            -- Bug 20207037 - End
                l_validation_rule_cst_cofins := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_COFINS_TRIBUTARY_CODE'
                                                                                                      ,p_code            => r_freight.cofins_tributary_code
                                                                                                      ,p_invoice_type_id => NVL(r_freight.invoice_type_id,l_invoice_type_id)
                                                                                                      ,p_validity_type   => 'CST COFINS'
                                                                                                      );
                IF l_validation_rule_cst_cofins IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTCSTCOFINSTAXCODE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                             ,p_invalid_value          => r_freight.cofins_tributary_code
                             );
                END IF;
            END IF;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --494;
            -------------------------------------
            -- Validando Condicao de Pagamento --
            -------------------------------------
            IF r_freight.terms_id IS NULL AND r_freight.terms_name IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTTERMS'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                l_terms_id := CLL_F189_OPEN_VALIDATE_PUB.GET_AP_TERMS (p_terms_id   => r_freight.terms_id
                                                                      ,p_terms_name => r_freight.terms_name
                                                                      );
                IF r_freight.terms_id IS NOT NULL AND r_freight.terms_name IS NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --495;
                    --
                    IF l_terms_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTTERMS ID'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => r_freight.terms_id
                                 );
                    END IF;
                    --
                ELSIF r_freight.terms_id IS NULL AND r_freight.terms_name IS NOT NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --496;
                    --
                    IF l_terms_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTTERMS NAME'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => r_freight.terms_name
                                 );
                    END IF;
                ELSE
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --497;
                    --
                    IF l_terms_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTTERMS'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_FREIGHT_INV_INTERFACE
                                 ,p_invalid_value          => 'ID = '||r_freight.terms_id||' - NAME = '||r_freight.terms_name
                                 );
                    END IF;
                END IF; --IF r_freight.terms_id IS NOT NULL AND r_freight.terms_name IS NULL THEN
            END IF; --IF r_freight.terms_id IS NULL AND r_freight.terms_name IS NULL THEN
            --
            ---------------------------------------------------------
            -- Encontrando dados da linha da condicao de pagamento --
            ---------------------------------------------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --498;
            --
            CLL_F189_INVOICES_UTIL_PKG.GET_TERMS_LINES (p_terms_id => NVL(r_freight.terms_id,l_terms_id)
                                                       ,p_dmf      => l_dmf
                                                       ,p_ddm      => l_ddm
                                                       ,p_dd       => l_dd
                                                       ,p_dcd      => l_dcd
                                                       );
            IF l_dmf IS NULL OR l_ddm IS NULL OR l_dd IS NULL OR l_dcd IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTPAYMENTDATE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'ID = '||NVL(r_freight.terms_id,l_terms_id)
                         );
            END IF;
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --499;
            ----------------------------------------------
            -- Recuperando a data do primeiro pagamento --
            ----------------------------------------------
            CLL_F189_INVOICES_UTIL_PKG.GET_FIRST_PAYMENT_DATE(p_first_payment_date     => r_freight.first_payment_date
                                                           --,p_terms_date             => r_freight.terms_date                             -- 27854379
                                                             ,p_terms_date             => NVL(r_freight.terms_date,r_freight.invoice_date) -- 27854379
                                                             ,p_dcd                    => l_dcd
                                                             ,p_dmf                    => l_dmf
                                                             ,p_ddm                    => l_ddm
                                                             ,p_dd                     => l_dd
                                                             -- out
                                                           --,p_first_payment_date_out => l_first_payment_date     -- 27854379
                                                             ,p_first_payment_date_out => p_first_payment_date_out -- 27854379
                                                             );
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --500;
            --
            -------------------
            -- Validando CFO --
            -------------------
            IF r_freight.cfo_id IS NULL AND r_freight.cfo_code IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTRETURNCFO'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'ID = '||NVL(r_freight.terms_id,l_terms_id)
                         );
            ELSE
                --
                l_cfo_id := CLL_F189_VALID_RULES_PKG.GET_FISCAL_OPERATIONS_VRULES(p_cfo_id                => r_freight.cfo_id
                                                                                 ,p_cfo_code              => r_freight.cfo_code
                                                                                 ,p_invoice_type_id       => NVL(r_freight.invoice_type_id,l_invoice_type_id)
--                                                                                 ,p_freight_flag          => 'S' -- 29856589
                                                                                 ,p_freight_flag          => 'Y' -- 29856589
                                                                                 ,p_freight_flag_inv_type => l_freight_flag
                                                                                 ,p_source_state_id       => p_source_state_id
                                                                                 ,p_destination_state_id  => p_destination_state_id
                                                                                 ,p_cfo_transporter       => l_cfo_transporter
                                                                                 );
                ----<<Bug 17375006 - Egini - 01/09/2013 - Inicio >>--
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --501;
                ------------------------
                --    CFOP FRETE      --
                ------------------------
                --
                l_cfo_id := CLL_F189_OPEN_VALIDATE_PUB.GET_CFO(p_cfo_id    => NVL(r_freight.cfo_id,l_cfo_id)
                                                              ,p_cfo_code  => NVL(r_freight.cfo_code,l_cfo_code)
                                                              );
                --
                --<<Bug 17375006 - Egini - 01/09/2013 - FIM >>--
                --
                IF r_freight.cfo_id IS NOT NULL AND r_freight.cfo_code IS NULL THEN
                    IF l_cfo_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTCFO ID'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => r_freight.cfo_id
                                 );
                    END IF;
                ELSIF r_freight.cfo_id IS NULL AND r_freight.cfo_code IS NOT NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --502;
                    --
                    IF l_cfo_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTCFO CODE'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => r_freight.cfo_code
                                 );
                    END IF;
                ELSE
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --503;
                    --
                    IF l_cfo_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'INVALID FRTCFO'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => 'ID = '||r_freight.cfo_id||' - CODE = '||r_freight.cfo_code
                                 );
                    END IF;
                END IF; --IF r_freight.cfo_id IS NOT NULL AND r_freight.cfo_code IS NULL THEN
            END IF; --IF r_freight.cfo_id IS NULL AND r_freight.cfo_code IS NULL THEN
            --
            -------------------------------------------------------
            -- Valida Utilizacao Fiscal no Conhecimento de Frete --
            -------------------------------------------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --504;
            --
            l_utilization_id := CLL_F189_VALID_RULES_PKG.GET_ITEM_UTILIZATIONS_VRULES(p_utilization_id   => r_freight.utilization_id
                                                                                     ,p_utilization_code => r_freight.utilization_code
                                                                                     ,p_invoice_type_id  => NVL(r_freight.invoice_type_id,l_invoice_type_id)
                                                                                     );
            --
            IF r_freight.utilization_id IS NOT NULL AND r_freight.utilization_code IS NULL THEN
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --505;
                --
                IF l_utilization_id IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTUTILIZATION ID'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.utilization_id
                             );
                END IF;
            ELSIF r_freight.utilization_id IS NULL AND r_freight.utilization_code IS NOT NULL THEN
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --506;
                --
                IF l_utilization_id IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTUTILIZATION CODE'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.utilization_code
                             );
                END IF;
            ELSIF r_freight.utilization_id IS NOT NULL AND r_freight.utilization_code IS NOT NULL THEN
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --507;
                --
                IF l_utilization_id IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTUTILIZATION'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'ID = '||r_freight.utilization_id||' - CODE = '||r_freight.utilization_code
                             );
                END IF;
            END IF;
            --
            ------------------------------------------------------
            -- Valida CFO x Utilizacao no Conhecimento de Frete --
            ------------------------------------------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --508;
            --
            IF r_freight.utilization_id IS NOT NULL OR r_freight.utilization_code IS NOT NULL THEN
                --
                l_utilization_cfo := CLL_F189_OPEN_VALIDATE_PUB.GET_CFO_UTILIZATIONS (p_cfo_id         => NVL(r_freight.cfo_id,l_cfo_id)
                                                                                     ,p_utilization_id => NVL(r_freight.cfo_code,l_utilization_id)
                                                                                     ,p_utilization_code => NVL(r_freight.utilization_code,l_utilization_code) --<<Bug 17375006 - Egini - 01/09/2013 >>--
                                                                                     ,p_cfo_code         => NVL(r_freight.cfo_code,l_cfo_code)                 --<<Bug 17375006 - Egini - 01/09/2013 >>--
                                                                                     );
                --
                IF l_utilization_cfo IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTCFOUTILIZATION'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'CFO ID = '||NVL(r_freight.cfo_id,l_cfo_id)||' - INTENDED USE ID = '||NVL(r_freight.cfo_code,l_utilization_id)
                             );
                END IF;
            END IF;
            --
            -----------------------------
            -- Validando Contrato - PO --
            -----------------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --509;
            --
            IF l_requisition_type = 'CT' THEN -- 27579747
               --
               IF r_freight.po_header_id IS NULL THEN
                   ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                            ,p_interface_operation_id => r_freight.interface_operation_id
                            ,p_organization_id        => r_freight.organization_id
                            ,p_error_code             => 'NULL FRTCONTRACT'
                            ,p_invoice_line_id        => 0
                            ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                            ,p_invalid_value          => NULL
                         );
               ELSE
                   --
                   l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --510;
                   --
                   l_contract_id := CLL_F189_OPEN_VALIDATE_PUB.GET_CONTRACT_PO(p_vendor_id      => l_vendor_id
                                                                              ,p_location_id    => p_location_id
                                                                              ,p_operating_unit => p_operating_unit
                                                                              ,p_po_header_id   => r_freight.po_header_id
                                                                              );
                   --
                   IF l_contract_id IS NULL THEN
                       ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                ,p_interface_operation_id => r_freight.interface_operation_id
                                ,p_organization_id        => r_freight.organization_id
                                ,p_error_code             => 'INVALID FRTCONTRACT'
                                ,p_invoice_line_id        => 0
                                ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                ,p_invalid_value          => r_freight.po_header_id
                                );
                   END IF;
               END IF;
               --
            END IF; -- 27579747
            --
            ---------------------------------------------------
            -- Validando Modelo fiscal do documento de frete --
            ---------------------------------------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --511;
            --
            IF r_freight.fiscal_document_model IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTDOCMODEL'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --512;
                --
                l_validation_rule_fisc_doc_mod := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type     => 'CLL_F189_FISCAL_DOCUMENT_MODEL'
                                                                                                        ,p_code            => r_freight.fiscal_document_model
                                                                                                        ,p_invoice_type_id => NVL(r_freight.invoice_type_id,l_invoice_type_id)
                                                                                                        ,p_validity_type   => 'FISCAL DOCUMENT MODEL'
                                                                                                        );
                IF l_validation_rule_fisc_doc_mod IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTDOCMODEL'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.fiscal_document_model
                             );
                END IF;
            END IF;
            --
            --------------------------------
            -- Validando Simples Nacional --
            --------------------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --513;
            --
            IF r_freight.simplified_br_tax_flag = 'Y' THEN
                IF r_freight.icms_type <> 'EXEMPT' THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'ICMS TYPE NOT ALLOWED'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.icms_type
                             );
                END IF ;
            END IF ;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --514;
            --
            -------------------------------------------
            -- Validando Meio de Transporte do frete --
            -------------------------------------------
            --
            IF r_freight.ship_via_lookup_code IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'NULL FRTSHIPVIA'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --515;
                --
                -- 23091360 - Start
-- 27579747 - Start
--                IF g_source = 'CLL_F369 EFD LOADER' THEN
                IF g_source IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
                   l_frt_ship_via_lookup_code := CLL_F189_LOADER_ADJUST_PKG.adjust_ship_via(r_freight.ship_via_lookup_code);
                ELSE
                   l_frt_ship_via_lookup_code := r_freight.ship_via_lookup_code;
                END IF;
                -- 23091360 - End
                l_ship_via_lookup_code := CLL_F189_LOOKUP_PKG.GET_LOOKUP_VALUES (p_lookup_type => 'CLL_F189_SHIP_VIA'
                                                                                ,p_lookup_code => l_frt_ship_via_lookup_code     -- 23091360
                                                                              --,p_lookup_code => r_freight.ship_via_lookup_code -- 23091360
                                                                                );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --516;
                --
                IF l_ship_via_lookup_code IS NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID FRTSHIPVIA'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.ship_via_lookup_code
                             );
                END IF;
            END IF;
            --
            -- 28487689 - 28597878 - Start
            IF r_freight.source_ibge_city_code IS NOT NULL AND r_freight.source_city_id IS NULL THEN

               l_source_city_id := NULL;

               BEGIN
                  SELECT cllci.CITY_ID
                    INTO l_source_city_id
                  FROM CLL_F189_CITIES cllci
                  WHERE cllci.IBGE_CODE = r_freight.source_ibge_city_code;
               EXCEPTION
                  WHEN OTHERS THEN

                     l_source_city_id := NULL;

               END;

            ELSE

               l_source_city_id := r_freight.source_city_id;

            END IF;
            -- 28487689 - 28597878 - End
            --
            -- 28730077 - Start
            IF r_freight.source_ibge_city_code IS NULL
            AND l_source_city_id IS NOT NULL THEN

               BEGIN
                  SELECT cllci.IBGE_CODE
                  INTO l_source_ibge_city_code
                  FROM CLL_F189_CITIES cllci
                  WHERE cllci.CITY_ID = l_source_city_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     l_source_ibge_city_code := NULL;
               END;

            ELSE

               l_source_ibge_city_code := r_freight.source_ibge_city_code;

            END IF;
            -- 28730077 - End
            --------------------------------
            -- Validando estado de origem --
            --------------------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --517;
            --
            IF r_freight.source_state_id IS NULL AND r_freight.source_state_code IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'FRT NULL SOURCE STATE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                --
                l_source_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => r_freight.source_state_id
                                                                           ,p_state_code => r_freight.source_state_code
                                                                           );
                --
                IF r_freight.source_state_id IS NOT NULL AND r_freight.source_state_code IS NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --518;
                    --
                    IF l_source_state_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'FRT INVALID SOURCE STATE ID'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => r_freight.source_state_id
                                 );
                    END IF;
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --519;
                    l_source_state_id := r_freight.source_state_id;
                    --
                ELSIF r_freight.source_state_id IS NULL AND r_freight.source_state_code IS NOT NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --520;
                    --
                    IF l_source_state_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'FRT INVALID SOURCE STATE CODE'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => r_freight.source_state_code
                                 );
                    END IF;
                ELSIF r_freight.source_state_id IS NOT NULL AND r_freight.source_state_code IS NOT NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --521;
                    --
                    IF l_source_state_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'FRT INVALID SOURCE STATE'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => r_freight.source_state_code
                                 );
                    END IF;
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --522;
                    l_source_state_id := r_freight.source_state_id;
                    --
                END IF;
            END IF; --IF r_freight.source_state_id IS NULL AND r_freight.source_state_code IS NULL THEN
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --523;
            --
            -- 28978447 - Start
            IF r_freight.ship_to_state_id IS NULL THEN

               BEGIN
                  SELECT rs.state_id
                  INTO l_ship_to_state_id
                  FROM cll_f189_fiscal_entities_all rfea
                     , cll_f189_states rs
                  WHERE rfea.location_id = p_location_id
                    AND rs.state_id = rfea.state_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     l_ship_to_state_id := NULL;
               END;

            ELSE

              l_ship_to_state_id := r_freight.ship_to_state_id;

            END IF;
            -- 28978447 - End
            --
            -- 28487689 - 28597878 - Start
            IF r_freight.destination_ibge_city_code IS NOT NULL AND r_freight.destination_city_id IS NULL THEN

               l_destination_city_id := NULL;

               BEGIN
                  SELECT cllci.CITY_ID
                       , cllci.STATE_ID
                    INTO l_destination_city_id  -- 28978447
                       , l_destination_state_id -- 28978447
                     --, l_ship_to_state_id
                  FROM CLL_F189_CITIES cllci
                  WHERE cllci.IBGE_CODE = r_freight.destination_ibge_city_code;
               EXCEPTION
                  WHEN OTHERS THEN

                     l_destination_city_id  := NULL;
                     l_destination_state_id := NULL; -- 28978447
                   --l_ship_to_state_id     := NULL; -- 28978447

               END;

            ELSE

               l_destination_city_id  := r_freight.destination_city_id;
               l_destination_state_id := r_freight.destination_state_id; -- 28978447
             --l_ship_to_state_id    := r_freight.ship_to_state_id;      -- 28978447

            END IF;
            -- 28487689 - 28597878 - End
            --
            -- 28730077 - Start
            IF r_freight.destination_ibge_city_code IS NULL
            AND l_destination_city_id IS NOT NULL THEN

               BEGIN
                  SELECT cllci.IBGE_CODE
                  INTO l_destination_ibge_city_code
                  FROM CLL_F189_CITIES cllci
                  WHERE cllci.CITY_ID = l_destination_city_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     l_destination_ibge_city_code := NULL;
               END;

            ELSE

               l_destination_ibge_city_code := r_freight.destination_ibge_city_code;

            END IF;
            -- 28730077 - End
            ---------------------------------
            -- Validando estado de destino --
            ---------------------------------
            --
            IF r_freight.destination_state_id IS NULL AND r_freight.destination_state_code IS NULL THEN
                ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                         ,p_interface_operation_id => r_freight.interface_operation_id
                         ,p_organization_id        => r_freight.organization_id
                         ,p_error_code             => 'FRT NULL DESTINATION STATE'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            ELSE
                --
                l_destination_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => r_freight.destination_state_id
                                                                                ,p_state_code => r_freight.destination_state_code
                                                                                );
                --
                IF r_freight.destination_state_id IS NOT NULL AND r_freight.destination_state_code IS NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --524;
                    --
                    IF l_destination_state_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'FRT INVALID DESTINAT STATE ID'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => NULL
                                 );
                    END IF;
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --525;
                    l_destination_state_id := r_freight.destination_state_id;
                    --
                ELSIF r_freight.destination_state_id IS NULL AND r_freight.destination_state_code IS NOT NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --526;
                    --
                    IF l_destination_state_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'FRT INVALID DESTINAT STATE COD'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => NULL
                                 );
                    END IF;
                ELSIF r_freight.destination_state_id IS NOT NULL AND r_freight.destination_state_code IS NOT NULL THEN
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --527;
                    --
                    IF l_destination_state_id IS NULL THEN
                        ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                                 ,p_interface_operation_id => r_freight.interface_operation_id
                                 ,p_organization_id        => r_freight.organization_id
                                 ,p_error_code             => 'FRT INVALID DESTINATION STATE'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => NULL
                                 );
                    END IF;
                    --
                    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --528;
                    l_destination_state_id := r_freight.destination_state_id;
                    --
                END IF;
            END IF; --IF r_freight.destination_state_id IS NULL AND r_freight.destination_state_code IS NULL THEN
            --
            -------------------
            -- Validando PIS --
            -------------------
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --529;
            --
            IF l_pis_flag = 'Y' THEN
                IF r_freight.pis_base_amount is NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'NULL PISFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                ELSIF p_pis_amount_recover_cnpj <> r_freight.pis_tax_rate THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID PISFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.pis_tax_rate
                             );
                ELSIF r_freight.pis_amount_recover > r_freight.invoice_amount THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'EXCEEDED AMOUNT PISFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.pis_amount_recover
                             );
                ELSIF r_freight.pis_base_amount > r_freight.invoice_amount THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'EXCEEDED BASE AMOUNT PISFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.pis_base_amount
                             );
                END IF;
            ELSE --IF r_freight.pis_flag = 'Y' THEN
                IF (r_freight.pis_base_amount > 0 OR r_freight.pis_tax_rate > 0) THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID PISFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.pis_base_amount
                             );
                END IF;
            END IF; --IF r_freight.pis_flag = 'Y' THEN
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --530;
            ----------------------
            -- Validando COFINS --
            ----------------------
            --
            IF l_cofins_flag = 'Y' THEN
                IF r_freight.cofins_base_amount is NULL THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'NULL COFINSFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                ELSIF p_cofins_amount_recover_cnpj <> r_freight.cofins_tax_rate THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID COFINSFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.cofins_tax_rate
                             );
                ELSIF r_freight.cofins_amount_recover > r_freight.invoice_amount THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'EXCEEDED AMOUNT COFINSFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.cofins_amount_recover
                             );
                ELSIF r_freight.cofins_base_amount > r_freight.invoice_amount THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'EXCEEDED BASE AMOUNT COFINSFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.cofins_amount_recover
                             );
                END IF;
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --531;
            ELSE --IF l_cofins_flag = 'Y' THEN
                IF (r_freight.cofins_base_amount > 0 OR r_freight.cofins_tax_rate > 0) THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'INVALID COFINSFRT'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.cofins_amount_recover
                             );
                END IF;
            END IF; --IF l_cofins_flag = 'Y' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --532;
            -- ER 14124731 - Start
-- 27579747 - Start
--            IF g_source = 'CLL_F369 EFD LOADER' THEN
            IF g_source IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
               BEGIN
                  SELECT COUNT(1)
                  INTO l_loader_exist
                  FROM cll_f369_efd_headers
                  WHERE access_key_number = r_freight.eletronic_invoice_key;
               EXCEPTION
                  WHEN OTHERS THEN
                     l_loader_exist := 0;
               END;
               --
               IF NVL(l_loader_exist,0) = 0 THEN
                    ADD_ERROR(p_invoice_id             => r_freight.interface_invoice_id
                             ,p_interface_operation_id => r_freight.interface_operation_id
                             ,p_organization_id        => r_freight.organization_id
                             ,p_error_code             => 'DOC NOT LOADER'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 3 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => r_freight.eletronic_invoice_key
                             );
               END IF;
            END IF;
            -- ER 14124731 - End
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --533;
            -- Fazendo a Validacao do Processo Legal do Frete
            --
            CREATE_LEGAL_PROCESSES (p_type                   => 'VALIDATION'
                                   ,p_interface_invoice_id   => r_freight.interface_invoice_id
                                   ,p_interface_operation_id => p_interface_operation_id
                                   ,p_organization_id        => r_freight.organization_id
                                   ,p_invoice_id             => l_freight_inv_s
                                   -- out
                                   --,p_cont_leg_processes     => g_cont_leg_processes
                                   );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --534;
           --
           -- 28487689 - 28597878 - Start
           BEGIN
              --
              UPDATE cll_f189_freight_inv_iface_tmp
              SET source_city_id             = l_source_city_id
                 ,destination_city_id        = l_destination_city_id
               --,ship_to_state_id           = l_ship_to_state_id
                 ,destination_state_id       = l_destination_state_id       -- 28978447
                 ,source_ibge_city_code      = l_source_ibge_city_code      -- 28730077
                 ,destination_ibge_city_code = l_destination_ibge_city_code -- 28730077
              WHERE interface_operation_id = r_freight.interface_operation_id;
              --
           END;
            -- 28487689 - 28597878 - End

        ELSIF p_type = 'INSERT' THEN -- IF p_type = 'VALIDATION' THEN
            --
            -- Inicio BUG 23018594
            -- Buscar informacao de Origem e Destino do Frete, pois nao temos esses valores nesse momento
            BEGIN
              SELECT source_state_id, source_state_code, destination_state_id, destination_state_code
                INTO x_source_state_id, x_source_state_code, x_destination_state_id, x_destination_state_code
                FROM cll_f189_freight_inv_interface
               WHERE interface_operation_id = p_interface_operation_id
                 AND organization_id        = r_freight.organization_id;
            EXCEPTION WHEN  NO_DATA_FOUND THEN
              x_source_state_id        := NULL;
              x_source_state_code      := NULL;
              x_destination_state_id   := NULL;
              x_destination_state_code := NULL;
            END;
            x_source_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => x_source_state_id
                                                                       ,p_state_code => x_source_state_code);
            x_destination_state_id := CLL_F189_OPEN_VALIDATE_PUB.GET_STATES (p_state_id   => x_destination_state_id
                                                                            ,p_state_code => x_destination_state_code);
            -- Fim BUG 23018594
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --535;
            --
            r_freight.source_state_id      := x_source_state_id;      -- BUG 23018594
            r_freight.destination_state_id := x_destination_state_id; -- BUG 23018594
            --
            IF l_interface_invoice_num <> r_freight.invoice_num OR l_interface_invoice_num IS NULL THEN
                --
                l_interface_invoice_num := r_freight.invoice_num;
                l_freight_inv_s := CLL_F189_FREIGHT_INVOICES_PUB.GET_FREIGHT_INVOICES_S;
                --
                g_cont_frt := g_cont_frt + 1;
                --
                -- Insere a nota de Frete na tabela final do RI
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --536;
                -- 23091360 - Start
-- 27579747 - Start
--                IF g_source = 'CLL_F369 EFD LOADER' THEN
                IF g_source IN ('CLL_F369 EFD LOADER','CLL_F369 EFD LOADER SHIPPER') THEN
-- 27579747 - End
                   l_frt_ship_via_lookup_code := CLL_F189_LOADER_ADJUST_PKG.adjust_ship_via(r_freight.ship_via_lookup_code);
                ELSE
                   l_frt_ship_via_lookup_code := r_freight.ship_via_lookup_code;

                END IF;
                -- 23091360 - End

                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --537;
                CLL_F189_FREIGHT_INVOICES_PUB.CREATE_FREIGHT_INVOICES (p_invoice_id               => l_freight_inv_s
                                                                      ,p_entity_id                => NVL(r_freight.entity_id,l_entity_id_out)
                                                                      ,p_invoice_num              => r_freight.invoice_num
                                                                      ,p_series                   => r_freight.series
                                                                      ,p_user_id                  => l_user_id
                                                                      ,p_operation_id             => p_cll_f189_entry_operations_s
                                                                      ,p_organization_id          => r_freight.organization_id
                                                                      ,p_location_id              => r_freight.location_id
                                                                      ,p_invoice_date             => r_freight.invoice_date
                                                                      ,p_invoice_amount           => r_freight.invoice_amount
                                                                      ,p_invoice_type_id          => NVL(r_freight.invoice_type_id,l_invoice_type_id)
                                                                      ,p_cfo_id                   => NVL(r_freight.cfo_id,l_cfo_id)
                                                                      ,p_terms_id                 => NVL(r_freight.terms_id,l_terms_id)
                                                                      ,p_terms_date               => r_freight.terms_date
                                                                    --,p_first_payment_date       => l_first_payment_date -- 27854379
                                                                      ,p_first_payment_date       => p_first_payment_date -- 27854379
                                                                      ,p_po_header_id             => r_freight.po_header_id
                                                                      ,p_description              => r_freight.description
                                                                      ,p_total_freight_weight     => r_freight.total_freight_weight
                                                                      ,p_icms_type                => r_freight.icms_type
                                                                      ,p_icms_base                => r_freight.icms_base
                                                                      ,p_icms_tax                 => r_freight.icms_tax
                                                                      ,p_icms_amount              => r_freight.icms_amount
                                                                      ,p_diff_icms_tax            => r_freight.diff_icms_tax
                                                                      ,p_diff_icms_amount         => r_freight.diff_icms_amount
                                                                      ,p_invoice_num_ap           => NULL
                                                                      ,p_interface_flag           => 'N'
                                                                      ,p_fiscal_interface_flag    => 'N'
                                                                      ,p_fiscal_interface_date    => NULL
                                                                      ,p_translation_factor       => NULL
                                                                      ,p_item_transl_factor       => NULL
                                                                      ,p_icms_transl_factor       => NULL
                                                                    --,p_ship_via_lookup_code     => r_freight.ship_via_lookup_code -- 23091360
                                                                      ,p_ship_via_lookup_code     => l_frt_ship_via_lookup_code     -- 23091360
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
                                                                      ,p_fiscal_document_model    => r_freight.fiscal_document_model
                                                                      ,p_diff_icms_amount_recover => r_freight.diff_icms_amount_recover
                                                                      ,p_source_state_id          => r_freight.source_state_id
                                                                      ,p_destination_state_id     => r_freight.destination_state_id
                                                                      ,p_interface_invoice_id     => r_freight.interface_invoice_id
                                                                      ,p_subseries                => r_freight.subseries
                                                                      ,p_utilization_id           => r_freight.utilization_id
                                                                      ,p_tributary_status_code    => r_freight.tributary_status_code
                                                                      ,p_cte_type                 => r_freight.cte_type
                                                                      ,p_eletronic_invoice_key    => r_freight.eletronic_invoice_key
                                                                      ,p_simplified_br_tax_flag   => r_freight.simplified_br_tax_flag
                                                                      ,p_icms_tax_code            => r_freight.icms_tax_code
                                                                      ,p_pis_amount_recover       => r_freight.pis_amount_recover
                                                                      ,p_pis_tax_rate             => r_freight.pis_tax_rate
                                                                      ,p_pis_base_amount          => r_freight.pis_base_amount
                                                                      ,p_cofins_amount_recover    => r_freight.cofins_amount_recover
                                                                      ,p_cofins_tax_rate          => r_freight.cofins_tax_rate
                                                                      ,p_cofins_base_amount       => r_freight.cofins_base_amount
                                                                      ,p_pis_tributary_code       => r_freight.pis_tributary_code
                                                                      ,p_cofins_tributary_code    => r_freight.cofins_tributary_code
                                                                      ,p_usage_authorization      => r_freight.usage_authorization -- ER 20382276
                                                                      ,p_source_city_id           => r_freight.source_city_id                 -- 27463767
                                                                      ,p_destination_city_id      => r_freight.destination_city_id            -- 27463767
                                                                      ,p_source_ibge_city_code    => r_freight.source_ibge_city_code          -- 27463767
                                                                      ,p_destination_ibge_city_code => r_freight.destination_ibge_city_code   -- 27463767
                                                                      ,p_reference                => r_freight.reference                      -- 27579747
                                                                      ,p_ship_to_state_id         => r_freight.ship_to_state_id               -- 28487689 - 28597878
                                                                      ,p_return_code              => l_return_code
                                                                      ,p_return_message           => l_return_message
                                                                      );
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --538;
                -- Valida e Insere o Processo Legal do Frete na tabela final do RI
                --
                CREATE_LEGAL_PROCESSES (p_type                   => 'INSERT'
                                       ,p_interface_invoice_id   => r_freight.interface_invoice_id
                                       ,p_interface_operation_id => p_interface_operation_id
                                       ,p_organization_id        => r_freight.organization_id
                                       ,p_invoice_id             => l_freight_inv_s
                                       -- out
                                       --,p_cont_leg_processes     => g_cont_leg_processes
                                       );
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --539;
                --
            END IF; --IF l_interface_invoice_num <> r_freight.invoice_num OR l_interface_invoice_num IS NULL THEN
        END IF; --IF p_type = 'VALIDATION' THEN

    END LOOP; -- r_freight
    print_log('  FIM CREATE_OPEN_FREIGHT');
  END CREATE_OPEN_FREIGHT;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_INV_PARENTS                                     |
  |                                                                          |
  | Description: Responsible for validate information and insert into RI     |
  |              final tables or insert errors in RI or Loader interface     |
  |              tables                                                      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OPEN_INV_PARENTS (p_type                           IN VARCHAR2
                                    ,p_interface_invoice_id           IN NUMBER
                                    ,p_interface_operation_id         IN NUMBER
                                    ,p_organization_id                IN NUMBER
                                    ,p_invoice_line_id_par            IN OUT NOCOPY NUMBER
                                    ,p_process_flag                   OUT NOCOPY NUMBER
                                    ,p_return_code                    OUT NOCOPY VARCHAR2
                                    ,p_return_message                 OUT NOCOPY VARCHAR2
                                    ,p_invoice_type_id                IN NUMBER -- Bug 17088635
                                    -- Begin BUG 24387238
                                    ,p_generate_line                  IN VARCHAR2 DEFAULT 'N'
                                    ,p_invoice_line_id                IN NUMBER
                                    ,p_parent_id_out                  OUT NOCOPY NUMBER
                                    ,p_interface_parent_id            OUT NOCOPY NUMBER
                                    ,p_invoice_parent_line_id         OUT NOCOPY NUMBER
                                    ,p_parent_line_id_out             OUT NOCOPY NUMBER
                                    ,p_inv_line_parent_id_out         OUT NOCOPY NUMBER
                                    ,p_total                          IN NUMBER
                                    ,p_icms                           IN NUMBER
                                    ,p_ipi                            IN NUMBER
                                    ,p_business_vendor                IN NUMBER
                                    ,p_org_state_id                   IN NUMBER
                                    ,p_vendor_state_id                IN NUMBER
                                    ,p_additional_tax                 IN NUMBER
                                    ,p_user_id                        IN NUMBER
                                    ,p_interface                      IN VARCHAR2
                                    ,p_line_location_id               IN NUMBER
                                    ,p_requisition_line_id            IN NUMBER
                                    ,p_item_id                        IN NUMBER
                                    ,p_type_exec                      IN VARCHAR2 DEFAULT 'N'
                                     -- End BUG 24387238
                                    ,p_return_customer_flag           IN VARCHAR2 -- 29908009
                                    ) IS

  CURSOR c_invoice_parents_header IS
        SELECT  interface_parent_id
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
           FROM cll_f189_inv_parent_iface_tmp
          WHERE interface_invoice_id = p_interface_invoice_id;
   -- Begin BUG 24387238
  CURSOR c_invoice_parents_lines (p_interface_parent_id IN  NUMBER) IS
    SELECT interface_invoice_line_id
      FROM cll_f189_par_line_iface_tmp
     WHERE interface_parent_id      = p_interface_parent_id;
   -- End BUG 24387238
    --
    --
    l_qty_invoice_parents               NUMBER;
    l_qty_invoice_parents_lines         NUMBER;
    --
    l_invoice_parent_id                 NUMBER;
    l_parent_id                         NUMBER;
    l_user_id                           NUMBER := FND_GLOBAL.USER_ID;
    --
    l_return_code                       VARCHAR2(100);
    l_return_message                    VARCHAR2(500);
    --
    l_count                             NUMBER;
    --
    -- Begin Bug 24387238
    l_parent_line_id_out                NUMBER;
    l_inv_line_parent_id_out            NUMBER;
    l_parent_id_out                     NUMBER;
    l_interface_parent_line_id          NUMBER;
    l_invoice_parent_line_id            NUMBER;
    l_interface_invoice_line_id         NUMBER;
    l_interface_parent_id               NUMBER;
    v_existe_par                        NUMBER; -- Bug 24387238
    l_generate_lines                    VARCHAR2(1);
    -- End Bug 24387238
  BEGIN
    print_log('  CREATE_OPEN_INV_PARENTS');
    l_count := 0;
    --
    -- Iniciando validacoes da Nota Complementar
    --
    FOR r_invoice_parents_header IN c_invoice_parents_header LOOP
        --
        l_count := l_count + 1;
        --
        IF p_type = 'VALIDATION' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --543;
            --------------------------------------------------------------------------------
            -- Validacoes iniciais da Nota Complementar - campos obrigatorios preenchidos --
            --------------------------------------------------------------------------------
            IF r_invoice_parents_header.invoice_parent_id IS NULL AND r_invoice_parents_header.invoice_parent_num IS NULL THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'PARENT INVOICE NULL' --COMPL PARENT ID NULL
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 4 -- CLL_F189_INVOICE_PARENTS
                         ,p_invalid_value          => NULL
                         );
            ELSIF r_invoice_parents_header.invoice_parent_id IS NOT NULL THEN
                --
                l_qty_invoice_parents := CLL_F189_OPEN_VALIDATE_PUB.GET_QTY_INVOICE_PARENTS (p_invoice_parent_id  => r_invoice_parents_header.invoice_parent_id
                                                                                            ,p_entity_id          => NULL
                                                                                            ,p_invoice_parent_num => NULL
                                                                                            ,p_invoice_date       => NULL
                                                                                            );

                --
                IF l_qty_invoice_parents = 0 THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'PARENT INVOICE ID NOT FOUND' --INVOICE NOT PARENT
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 4 -- CLL_F189_INVOICE_PARENTS
                             ,p_invalid_value          => r_invoice_parents_header.invoice_parent_id
                             );
                ELSE -- Valida se tem linha informada na tabela da open
                    --
                    BEGIN
                        SELECT COUNT(1)
                          INTO l_qty_invoice_parents_lines
                          FROM cll_f189_par_line_iface_tmp
                         WHERE interface_parent_id = r_invoice_parents_header.interface_parent_id;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_qty_invoice_parents_lines := 0;
                    END;
                    --
                    IF l_qty_invoice_parents_lines = 0 THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'PARENT INV LINE NOT FOUND' --'PARENT INVOICE NOT FOUND'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 4 -- CLL_F189_INVOICE_PARENTS
                                 ,p_invalid_value          => r_invoice_parents_header.invoice_parent_id
                                 );
                    END IF;
                END IF;
            ELSIF r_invoice_parents_header.invoice_parent_num IS NOT NULL THEN
                IF r_invoice_parents_header.entity_id IS NULL THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'PARENT ENTITY NULL'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 4 -- CLL_F189_INVOICE_PARENTS
                             ,p_invalid_value          => r_invoice_parents_header.invoice_parent_num
                             );
                ELSE
                    --
                    l_qty_invoice_parents := CLL_F189_OPEN_VALIDATE_PUB.GET_QTY_INVOICE_PARENTS (p_invoice_parent_id  => NULL
                                                                                                ,p_entity_id          => r_invoice_parents_header.entity_id
                                                                                                ,p_invoice_parent_num => r_invoice_parents_header.invoice_parent_num
                                                                                                ,p_invoice_date       => r_invoice_parents_header.invoice_date
                                                                                                );
                    --
                    IF l_qty_invoice_parents = 0 THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'PARENT INVOICE NOT FOUND' --INVOICE NOT PARENT
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 4 -- CLL_F189_INVOICE_PARENTS
                                 ,p_invalid_value          => r_invoice_parents_header.invoice_parent_num
                                 );
                    END IF;
                END IF; --IF r_invoice_parents_header.entity_id IS NULL THEN
            END IF; -- IF r_invoice_parents_header.invoice_parent_id IS NULL AND r_invoice_parents_header.invoice_parent_num IS NULL THEN
            --
            -- Chamando as validacoes da linha da nota complementar
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --544;
            CREATE_INVOICE_PAR_LINES_TMP (p_type                      => 'VALIDATION'
                                         ,p_interface_invoice_id      => p_interface_invoice_id
                                         ,p_interface_operation_id    => p_interface_operation_id
                                         ,p_organization_id           => p_organization_id
                                         ,p_interface_parent_id       => r_invoice_parents_header.interface_parent_id
                                         ,p_parent_id                 => p_parent_id_out -- NULL -- Bug 24387238
                                         ,p_invoice_line_id           => NULL --p_invoice_line_id_par -- BUG 19943706 -- Bug 24387238
                                         -- ,p_process_flag
                                         ,p_return_code               => l_return_code
                                         ,p_return_message            => l_return_message
                                          -- Begin BUG 24387238
                                         --,p_invoice_type_id           => NULL -- Bug 17088635
                                         ,p_invoice_type_id           => p_invoice_type_id
                                         ,p_generate_line             => 'N'
                                         ,p_interface_invoice_line_id => NULL
                                         ,p_parent_line_id_out        => l_parent_line_id_out
                                         ,p_inv_line_parent_id_out    => l_inv_line_parent_id_out
                                         ,p_invoice_id                => NULL
                                         ,p_total                     => p_total
                                         ,p_icms                      => p_icms
                                         ,p_ipi                       => p_ipi
                                         ,p_business_vendor           => p_business_vendor
                                         ,p_org_state_id              => p_org_state_id
                                         ,p_vendor_state_id           => p_vendor_state_id
                                         ,p_additional_tax            => p_additional_tax
                                         ,p_user_id                   => p_user_id
                                         ,p_interface                 => p_interface
                                         ,p_invoice_line_id_in        => p_invoice_line_id
                                         ,p_inv_line_parent_id_in     => p_inv_line_parent_id_out
                                         ,p_line_location_id          => p_line_location_id
                                         ,p_requisition_line_id       => p_requisition_line_id
                                         ,p_item_id                   => p_item_id
                                         ,p_type_exec                 => p_type_exec
                                          -- End BUG 24387238
                                         ,p_return_customer_flag      => p_return_customer_flag -- 29908009
                                         );
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --548;
        ELSIF p_type = 'INSERT' THEN
            IF r_invoice_parents_header.invoice_parent_id IS NULL THEN
                l_invoice_parent_id := CLL_F189_OPEN_VALIDATE_PUB.GET_INVOICE_PARENTS(p_entity_id          => r_invoice_parents_header.entity_id
                                                                                     ,p_invoice_parent_num => r_invoice_parents_header.invoice_parent_num
                                                                                     ,p_invoice_date       => r_invoice_parents_header.invoice_date
                                                                                     );
            ELSE
                l_invoice_parent_id := r_invoice_parents_header.invoice_parent_id;
            END IF;
            --
            l_parent_id := CLL_F189_INV_PARENTS_PUB.GET_INVOICE_PARENTS_S;
            --
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --549;
            --
            p_interface_parent_id := r_invoice_parents_header.interface_parent_id; -- Bug 24387238
            --
            -- Begin BUG 24387238
            BEGIN
              SELECT 1
                INTO v_existe_par
                FROM cll_f189_invoice_parents
               WHERE invoice_parent_id    = l_invoice_parent_id
                 AND interface_parent_id  = r_invoice_parents_header.interface_parent_id
                 AND invoice_id           = g_cll_f189_invoices_s;
            EXCEPTION WHEN no_data_found THEN
              v_existe_par := 0;
            END;
            --
            IF v_existe_par = 0 THEN
            -- End BUG 24387238
              CLL_F189_INV_PARENTS_PUB.CREATE_INVOICE_PARENTS(p_parent_id           => l_parent_id
                                                             ,p_invoice_id          => g_cll_f189_invoices_s
                                                             ,p_invoice_parent_id   => l_invoice_parent_id
                                                             ,p_interface_parent_id => p_interface_parent_id --r_invoice_parents_header.interface_parent_id -- Bug 24387238
                                                             ,p_user_id             => l_user_id
                                                             ,p_attribute_category  => r_invoice_parents_header.attribute_category
                                                             ,p_attribute1          => r_invoice_parents_header.attribute1
                                                             ,p_attribute2          => r_invoice_parents_header.attribute2
                                                             ,p_attribute3          => r_invoice_parents_header.attribute3
                                                             ,p_attribute4          => r_invoice_parents_header.attribute4
                                                             ,p_attribute5          => r_invoice_parents_header.attribute5
                                                             ,p_attribute6          => r_invoice_parents_header.attribute6
                                                             ,p_attribute7          => r_invoice_parents_header.attribute7
                                                             ,p_attribute8          => r_invoice_parents_header.attribute8
                                                             ,p_attribute9          => r_invoice_parents_header.attribute9
                                                             ,p_attribute10         => r_invoice_parents_header.attribute10
                                                             ,p_attribute11         => r_invoice_parents_header.attribute11
                                                             ,p_attribute12         => r_invoice_parents_header.attribute12
                                                             ,p_attribute13         => r_invoice_parents_header.attribute13
                                                             ,p_attribute14         => r_invoice_parents_header.attribute14
                                                             ,p_attribute15         => r_invoice_parents_header.attribute15
                                                             ,p_attribute16         => r_invoice_parents_header.attribute16
                                                             ,p_attribute17         => r_invoice_parents_header.attribute17
                                                             ,p_attribute18         => r_invoice_parents_header.attribute18
                                                             ,p_attribute19         => r_invoice_parents_header.attribute19
                                                             ,p_attribute20         => r_invoice_parents_header.attribute20
                                                             ,p_return_code         => l_return_code
                                                             ,p_return_message      => l_return_message
                                                             ,p_parent_id_out       => l_parent_id_out -- Bug 24387238
                                                             );
              p_parent_id_out := l_parent_id_out; -- BUG 24387238
              --
              l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --550;
              --
              g_cont_par_inv := l_count;
              --
              IF l_return_code IS NULL THEN -- nao deu erro ao inserir o cabecalho, entao insere as linhas
                --
                -- Chamando as validacoes da linha da nota complementar
                --
                l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --551;
                --
                -- Begin BUG 24387238
                l_interface_parent_id := r_invoice_parents_header.interface_parent_id;
                --
                FOR r_invoice_parents_lines IN c_invoice_parents_lines (l_interface_parent_id) LOOP
                  CREATE_INVOICE_PAR_LINES_TMP (p_type                      => 'INSERT'
                                               ,p_interface_invoice_id      => p_interface_invoice_id
                                               ,p_interface_operation_id    => p_interface_operation_id
                                               ,p_organization_id           => p_organization_id
                                               ,p_interface_parent_id       => l_interface_parent_id --r_invoice_parents_header.interface_parent_id -- Bug 24387238
                                               ,p_parent_id                 => l_parent_id
                                               ,p_invoice_line_id           => p_invoice_line_id_par -- BUG 19943706
                                               -- ,p_process_flag
                                               ,p_return_code               => l_return_code
                                               ,p_return_message            => l_return_message
                                               -- Begin BUG 24387238
                                               --,p_invoice_type_id           => NULL -- Bug 17088635
                                               ,p_invoice_type_id           => p_invoice_type_id
                                               ,p_generate_line             => nvl(p_generate_line,'N')
                                               ,p_interface_invoice_line_id => r_invoice_parents_lines.interface_invoice_line_id -- r_invoice_parents_header.interface_invoice_line_id
                                               ,p_parent_line_id_out        => l_parent_line_id_out
                                               ,p_inv_line_parent_id_out    => l_inv_line_parent_id_out
                                               ,p_invoice_id                => g_cll_f189_invoices_s
                                               ,p_total                     => p_total
                                               ,p_icms                      => p_icms
                                               ,p_ipi                       => p_ipi
                                               ,p_business_vendor           => p_business_vendor
                                               ,p_org_state_id              => p_org_state_id
                                               ,p_vendor_state_id           => p_vendor_state_id
                                               ,p_additional_tax            => p_additional_tax
                                               ,p_user_id                   => p_user_id
                                               ,p_interface                 => p_interface
                                               ,p_invoice_line_id_in        => p_invoice_line_id
                                               ,p_inv_line_parent_id_in     => p_inv_line_parent_id_out
                                               ,p_line_location_id          => p_line_location_id
                                               ,p_requisition_line_id       => p_requisition_line_id
                                               ,p_item_id                   => p_item_id
                                               ,p_type_exec                 => p_type_exec
                                               -- End BUG 24387238
                                               ,p_return_customer_flag      => p_return_customer_flag -- 29908009
                                               );
                  p_invoice_parent_line_id := r_invoice_parents_lines.interface_invoice_line_id; --r_invoice_parents_header.interface_invoice_line_id;
                  p_parent_line_id_out     := l_parent_line_id_out;
                  p_inv_line_parent_id_out := l_inv_line_parent_id_out;
                  --
                END LOOP;
                --
                p_parent_id_out          := l_parent_id_out;
                p_interface_parent_id    := r_invoice_parents_header.interface_parent_id;
              END IF;
            END IF;
            -- End Bug 24387238
        END IF; --IF p_type = 'VALIDATION' THEN
        --
    END LOOP;
    print_log('  FIM CREATE_OPEN_INV_PARENTS');
  END CREATE_OPEN_INV_PARENTS;

 /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_TPA_RETURNS                                     |
  |                                                                          |
  | Description: Responsible for validate information and insert into        |
  |              CLL F513 third Party transaction                            |
  |              tables                                                      |
  |                                                                          |
  +=========================================================================*/
  --<< ER 26338366/26899224 - dgouveia - 04/10/2017 - Start >>--
 PROCEDURE CREATE_OPEN_TPA_RETURNS ( p_type                      IN VARCHAR2
                                   , p_tpa_return_control_id     IN NUMBER
                                   , p_organization_id           IN NUMBER
                                   , p_tpa_remit_control_id      IN NUMBER
                                   , p_ship_to_site_user_id      IN NUMBER
                                   , p_operation_id              IN NUMBER
                                   , p_entity_id                 IN NUMBER
                                   , p_operation_status          IN VARCHAR2
                                   , p_reversion_transaction_id  IN VARCHAR2
                                   , p_invoice_id                IN NUMBER
                                   , p_invoice_line_id           IN NUMBER
                                   , p_interface_invoice_id      IN NUMBER
                                   , p_interface_invoice_line_id IN NUMBER
                                   , p_invoice_number            IN NUMBER
                                   , p_invoice_date              IN DATE
                                   , p_returned_date             IN DATE
                                   , p_inventory_item_id         IN NUMBER
                                   , p_returned_quantity         IN NUMBER
                                   , p_new_subinventory_code     IN VARCHAR2
                                   , p_new_locator_id            IN NUMBER
                                   , p_new_locator_code          IN VARCHAR2
                                   , p_unit_price                IN NUMBER
                                   , p_returned_transaction_id   IN NUMBER
                                   , p_reversion_flag            IN VARCHAR2
                                   , p_attribute_category        IN VARCHAR2
                                   , p_attribute1                IN VARCHAR2
                                   , p_attribute2                IN VARCHAR2
                                   , p_attribute3                IN VARCHAR2
                                   , p_attribute4                IN VARCHAR2
                                   , p_attribute5                IN VARCHAR2
                                   , p_attribute6                IN VARCHAR2
                                   , p_attribute7                IN VARCHAR2
                                   , p_attribute8                IN VARCHAR2
                                   , p_attribute9                IN VARCHAR2
                                   , p_attribute10               IN VARCHAR2
                                   , p_attribute11               IN VARCHAR2
                                   , p_attribute12               IN VARCHAR2
                                   , p_attribute13               IN VARCHAR2
                                   , p_attribute14               IN VARCHAR2
                                   , p_attribute15               IN VARCHAR2
                                   , p_attribute16               IN VARCHAR2
                                   , p_attribute17               IN VARCHAR2
                                   , p_attribute18               IN VARCHAR2
                                   , p_attribute19               IN VARCHAR2
                                   , p_attribute20               IN VARCHAR2
                                   , p_created_by                IN NUMBER
                                   , p_creation_date             IN DATE
                                   , p_last_update_date          IN DATE
                                   , p_last_update_login         IN NUMBER
                                   , p_request_id                IN NUMBER
                                   , p_program_application_id    IN NUMBER
                                   , p_program_id                IN NUMBER
                                   , p_program_update_date       IN DATE
                                   , p_item_number               IN NUMBER     -- ER  26338366/26899224 2a fase
                                   , p_symbolic_return_flag      IN VARCHAR2   -- ENR 30120364
                                -- , p_quantity                  IN NUMBER     -- ER  26338366/26899224 2a fase
                                   , p_return_code               OUT NOCOPY VARCHAR2
                                   , p_return_message            OUT NOCOPY VARCHAR2
                                   ) IS

  -- 30211420 - Start
  CURSOR c_invoice_lines_tpa
     ( p_interface_invoice_line_id IN NUMBER ) IS
   SELECT tmp.ROWID linha  -- BUG 30633489
        , tmp.tpa_remit_control_id
        , tmp.new_subinventory_code
        , tmp.new_locator_id
        , tmp.new_locator_code
   FROM cll_f513_tpa_ret_iface_tmp tmp,
        cll_f513_tpa_remit_control trc,
        cll_f189_invoices_interface inv,
        cll_f189_invoice_lines_iface lines
   WHERE trc.tpa_remit_control_id(+) = tmp.tpa_remit_control_id
     AND tmp.interface_invoice_id = p_interface_invoice_id
     AND inv.interface_invoice_id = tmp.interface_invoice_id
     AND lines.interface_invoice_line_id = tmp.interface_invoice_line_id
     AND lines.interface_invoice_line_id = p_interface_invoice_line_id;
   -- 30211420 - End
   l_tpa_control_flag       cll_f189_fiscal_operations.tpa_control_type %TYPE ; -- Enh 29907995 VARCHAR2(01) ;
   --
   l_cfo_id                 cll_f189_fiscal_operations.cfo_id%type;
   l_interface_operation_id cll_f189_invoice_iface_tmp.interface_operation_id%type;
   l_count_tpa_return       number;
   l_secondary_inventory    mtl_secondary_inventories.secondary_inventory_name%type;
   l_subinventory_code      cll_f513_tpa_remit_control.subinventory%type;
   l_location_id            mtl_item_locations.inventory_location_id%type;
   l_qtd_records            NUMBER;
   l_count_symbolic         NUMBER; -- ENR 30120364
   l_tpa_dev_off            NUMBER; -- 30211420
   l_tpa_mat_off            NUMBER; -- 30211420
   l_tpa_return_from        NUMBER; -- 30211420
   --
  BEGIN
    print_log('  CREATE_OPEN_TPA_RETURNS');
    IF p_type = 'VALIDATE' then
      -- GET TPA CFO ID
      begin
       SELECT cfo_id
         into l_cfo_id
         FROM cll_f189_inv_line_iface_tmp reli
        WHERE reli.interface_invoice_id = p_interface_invoice_id --r_tpa_tmp.interface_invoice_id
          and interface_invoice_line_id = p_interface_invoice_line_id; --r_tpa_tmp.interface_invoice_line_id;
      exception
       when others then
         l_cfo_id := NULL;
      end ;
      --
      -- Recuperar OPERATION_ID
      --
      begin
        select interface_operation_id
          into l_interface_operation_id
          from cll_f189_invoice_iface_tmp reci
         where reci.interface_invoice_id = p_interface_invoice_id;
      exception
       when others then
         l_interface_operation_id := NULL;
      end ;
      --
      l_tpa_control_flag := CLL_F189_OPEN_VALIDATE_PUB.GET_CFO_THIRD_PARTY ( p_cfo_id => l_cfo_id, p_cfo_code => NULL ) ;
      --
      BEGIN
       SELECT count(1)
         into l_count_tpa_return
         from cll_f513_tpa_ret_iface
        where interface_invoice_id = p_interface_invoice_id; --r_tpa_tmp.interface_invoice_id;
       EXCEPTION
         WHEN others THEN
           l_count_tpa_return := 0;
      END;

      -- 30211420 - Start
    /*-- -------------------
      -- TPA RETURN REQUIRED
      -- -------------------
      IF l_tpa_control_flag = 'Y'  AND l_count_tpa_return = 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_interface_invoice_id      -- r_tpa_tmp.interface_invoice_id
                  , p_interface_operation_id => l_interface_operation_id    -- l_interface_operation_id
                  , p_organization_id        => p_organization_id           -- l_organization_id
                  , p_error_code             => 'TPA RETURN REQUIRED'
                  , p_invoice_line_id        => p_interface_invoice_line_id -- r_tpa_tmp.interface_invoice_line_id
                  , p_table_associated       => 5                           -- CLL_F513_TPA_RETURNS_IFACE
                  , p_invalid_value          => NULL
                  ) ;
        --
        p_return_code    := 'E' ;
        p_return_message := 'TPA RETURN REQUIRED' ;
        --
      END IF ; */
      -- 30211420 - End
      --
      -- Caso exista dados na interface TPA e o CFOP nao seja compativel gravar erro na open
      --
      IF ( l_tpa_control_flag <> 'RETURN_FROM' /* = 'N' Enh 29907995 */ AND l_count_tpa_return > 0 ) THEN
        -- --------------------
        -- TPA INV RETURN CFOP
        -- --------------------
        ADD_ERROR ( p_invoice_id             => p_interface_invoice_id      -- r_tpa_tmp.interface_invoice_id
                  , p_interface_operation_id => l_interface_operation_id    -- l_interface_operation_id
                  , p_organization_id        => p_organization_id           -- l_organization_id
                  , p_error_code             => 'TPA INV RETURN CFOP'
                  , p_invoice_line_id        => p_interface_invoice_line_id -- r_tpa_tmp.interface_invoice_line_id
                  , p_table_associated       => 5                           -- CLL_F513_TPA_RETURNS_IFACE
                  , p_invalid_value          => l_cfo_id
                  ) ;
        --
        p_return_code    := 'E' ;
        p_return_message := 'TPA INV RETURN CFOP' ;
        --
      END IF ;
      --
      --
  --  IF (l_tpa_control_flag = 'Y' AND l_count_tpa_return > 0) AND p_return_code = 'S' THEN -- 30211420

      IF l_tpa_control_flag  = 'RETURN_FROM' /* 'Y' -- Enh 29907995 */ THEN                 -- 30211420
        --
        -- Se estiver tudo OK abrir cursor
        -- FOR r_tpa in c_tpa LOOP
        --
        /* Bug 29449519 - START
        --
        -- ------------------
        -- NULL INTERF INV ID
        -- ------------------
        IF p_interface_invoice_id IS NULL THEN -- r_tpa_tmp.interface_invoice_id is NULL THEN
          --
          ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                    , p_interface_operation_id => l_interface_operation_id
                    , p_organization_id        => p_organization_id
                    , p_error_code             => 'NULL INTERF INV ID'
                    , p_invoice_line_id        => p_interface_invoice_line_id
                    , p_table_associated       => 5        -- CLL_F513_TPA_RETURNS_IFACE
                    , p_invalid_value          => NULL
                    ) ;
          --
          p_return_code    := 'E' ;
          p_return_message := 'NULL INTERF INV ID' ;
          --
        END IF ;
        -- ------------------------
        -- NULL INTERF INV LINE ID
        -- ------------------------
        IF (p_interface_invoice_line_id is NULL) then
          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                   ,p_interface_operation_id => l_interface_operation_id --l_interface_operation_id
                   ,p_organization_id        => p_organization_id --l_organization_id
                   ,p_error_code             => 'NULL INTERF INV LINE ID'
                   ,p_invoice_line_id        => p_interface_invoice_line_id
                   ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                   ,p_invalid_value          => NULL
                   );
          p_return_code := 'E';
          p_return_message := 'NULL INTERF INV LINE ID';
        END IF;
        */
        --
        -- --------------------
        -- INTERFACE INVID NULL
        -- --------------------
        IF p_interface_invoice_id is NULL then --r_tpa_tmp.interface_invoice_id is NULL then
          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                   ,p_interface_operation_id => l_interface_operation_id
                   ,p_organization_id        => p_organization_id
                   ,p_error_code             => 'INTERFACE INVID NULL'
                   ,p_invoice_line_id        => p_interface_invoice_line_id
                   ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                   ,p_invalid_value          => NULL
                   );
          p_return_code    := 'E';
          p_return_message := 'INTERFACE INVID NULL';
        END IF;
        -- ------------------------
        -- INTERFACE LINEINVID NULL
        -- ------------------------
        IF (p_interface_invoice_line_id is NULL) then
          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                   ,p_interface_operation_id => l_interface_operation_id --l_interface_operation_id
                   ,p_organization_id        => p_organization_id --l_organization_id
                   ,p_error_code             => 'INTERFACE LINEINVID NULL'
                   ,p_invoice_line_id        => p_interface_invoice_line_id
                   ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                   ,p_invalid_value          => NULL
                   );
          p_return_code    := 'E';
          p_return_message := 'INTERFACE LINEINVID NULL';
        END IF;
        --
        -- Bug 29449519 - END
        --
        --
        -- 30211420 - Start
      /*-- ------------------------
        -- NULL TPA REMIT CTRL
        -- ------------------------
        IF (P_TPA_REMIT_CONTROL_ID is NULL) then
          ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                   ,p_interface_operation_id => l_interface_operation_id --l_interface_operation_id
                   ,p_organization_id        => p_organization_id --l_organization_id
                   ,p_error_code             => 'NULL TPA REMIT CTRL'
                   ,p_invoice_line_id        => p_interface_invoice_line_id --r_tpa_tmp.interface_invoice_line_id
                   ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                   ,p_invalid_value          => NULL
                   );
          p_return_code := 'E';
          p_return_message := 'NULL TPA REMIT CTRL';
        end if;
        -- ------------------------
        -- REMIT CONTROL NO STOCK
        -- ------------------------
        IF (P_NEW_SUBINVENTORY_CODE is not NULL) then
          --
          Begin
            SELECT subinventory
              into l_subinventory_code
              FROM cll_f513_tpa_remit_control
             WHERE tpa_remit_control_id = p_tpa_remit_control_id;
          Exception
            When others then
              l_subinventory_code := NULL;
          end;
          --
          IF (l_subinventory_code is NULL) then
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => l_interface_operation_id --l_interface_operation_id
                       ,p_organization_id        => p_organization_id --l_organization_id
                       ,p_error_code             => 'REMIT CONTROL NO STOCK'
                       ,p_invoice_line_id        => p_interface_invoice_line_id
                       ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                       ,p_invalid_value          => NULL
                       );
              p_return_code := 'E';
              p_return_message := 'REMIT CONTROL NO STOCK';
          else
              -- ------------------------------------------------------
              --  INV SUBINVENTORY CODE Valid secondary inventory name
              -- ------------------------------------------------------
              Begin
                Select secondary_inventory_name
                  into l_secondary_inventory
                  from mtl_secondary_inventories
                 where organization_id = p_organization_id --l_organization_id
                   and nvl(trunc(disable_date),sysdate) >= trunc(sysdate)
                   AND SECONDARY_INVENTORY_NAME = p_new_SUBINVENTORY_CODE;
              Exception
                when others then
                  l_secondary_inventory := NULL;
              end;
              --
              IF l_secondary_inventory is NULL then
                --
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => l_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INV SUBINVENTORY CODE'
                         ,p_invoice_line_id        => p_interface_invoice_line_id
                         ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                         ,p_invalid_value          => p_new_subinventory_code
                         );
                p_return_code := 'E';
                p_return_message := 'INV SUBINVENTORY CODE';
              end if;
            --
          END IF;
        ELSE --IF (r_tpa_tmp.NEW_SUBINVENTORY_CODE is NULL)
          IF (p_new_locator_code is not NULL) or (p_new_locator_id is not NULL) Then
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => l_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'INV SUBINVENTORY CODE'
                       ,p_invoice_line_id        => p_interface_invoice_line_id
                       ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                       ,p_invalid_value          => NULL
                       );
            p_return_code := 'E';
            p_return_message := 'INV SUBINVENTORY CODE';
          end if;
          --
        END IF;
        -- ----------------
        -- INV LOCATION ID  -- Bug 29449519
        -- INVALID LOCATION -- Bug 29449519
        -- ----------------
        IF ((p_new_locator_code is not NULL) or (p_new_locator_id is not NULL)) Then
          --
          Begin
            Select mic.inventory_location_id
              into l_location_id
              from mtl_item_locations mic
                   ,mtl_item_locations_kfv mic_kfv
             where 1=1
               and mic.inventory_location_id = mic_kfv.inventory_location_id
               and mic.organization_id = p_organization_id
               and mic.subinventory_code = l_secondary_inventory -- l_subinventory_code --elton
               and (mic.inventory_location_id = p_new_locator_id
                or mic_kfv.concatenated_segments = p_new_locator_code); --elton
          Exception
            when others then
              l_location_id := 0;
          end;
          --
          --insert into elton_teste values (p_organization_id||'--'||l_secondary_Inventory||'--'||p_new_locator_id ||'--'||p_new_locator_code||'--'||l_location_id);
          IF NVL(l_location_id,0) = 0 then --ELTON
            --
            /* Bug 29449519 - START
            ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => l_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INV LOCATION ID'
                     ,p_invoice_line_id        => p_interface_invoice_line_id
                     ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                     ,p_invalid_value          => NULL
                     );
            p_return_code := 'E';
            p_return_message := 'INV LOCATION ID'; --'INV LOCATION ID';
            */
          /*ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                     ,p_interface_operation_id => l_interface_operation_id
                     ,p_organization_id        => p_organization_id
                     ,p_error_code             => 'INVALID LOCATOR' -- Enh 29907995 'INVALID LOCATION'
                     ,p_invoice_line_id        => p_interface_invoice_line_id
                     ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                     ,p_invalid_value          => NULL
                     );
            p_return_code    := 'E';
            p_return_message := 'INVALID LOCATOR' ; -- Enh 29907995 'INVALID LOCATION'
            --
            -- Bug 29449519 - END
            --
          END IF ;
        END IF ;
      END IF ; -- IF l_tpa_control_flag  = 'RETURN_FROM' -- 'Y' -- Enh 29907995 -- THEN                 -- 30211420
      --
      -- ENR 30120364 - Start
      --
      BEGIN
        --
        SELECT COUNT(DISTINCT NVL(symbolic_return_flag, 'N'))
          INTO l_count_symbolic
          FROM cll_f513_tpa_ret_iface_tmp
         WHERE interface_invoice_line_id = p_interface_invoice_line_id ;
        --
        IF l_count_symbolic > 1 THEN
        --
          ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                    , p_interface_operation_id => l_interface_operation_id
                    , p_organization_id        => p_organization_id
                    , p_error_code             => 'INVALID SYMBOLIC TYPE'
                    , p_invoice_line_id        => p_interface_invoice_line_id
                    , p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                    , p_invalid_value          => NULL
                    ) ;
          --
        END IF ;
      END ;
      */
      --
      -- 30211420 - End
      --
      -- ENR 30120364 - End
      --
      -- Enh 29907995 -- Start
      /*
      -- 30211420 - Start
      -- ------------------
      -- CFOP TYPE DEV INV
      -- ------------------
      SELECT COUNT(*)
        INTO l_tpa_dev_off
        FROM cll_f189_invoices_interface     cfil
           , cll_f189_invoice_lines_iface    cfili
           , cll_f189_fiscal_operations      cffo
       WHERE cfil.interface_invoice_id = cfili.interface_invoice_id
         AND cfili.cfo_id              = cffo.cfo_id
         AND cffo.tpa_control_type     = 'DEVOLUTION_OF'
         AND NVL(cffo.inactive_date,TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
         AND cfil.interface_invoice_id = p_interface_invoice_id;
      --
      IF l_tpa_dev_off > 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                  , p_interface_operation_id => l_interface_operation_id
                  , p_organization_id        => p_organization_id
                  , p_error_code             => 'CFOP TYPE DEV INV'
                  , p_invoice_line_id        => p_interface_invoice_line_id
                  , p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                  , p_invalid_value          => NULL
                  ) ;

        p_return_code := 'E';
        p_return_message := 'CFOP TYPE DEV INV';
        --
      END IF;
      */
      -- Enh 29907995 - End
      --
      -- ----------------------
      -- CFO RECEIPT ASSOC INV
      -- ----------------------
      SELECT COUNT(*)
        INTO l_tpa_mat_off
        FROM cll_f189_invoices_interface     cfil
           , cll_f189_invoice_lines_iface    cfili
           , cll_f189_fiscal_operations      cffo
       WHERE cfil.interface_invoice_id = cfili.interface_invoice_id
         AND cfili.cfo_id              = cffo.cfo_id
         AND cffo.tpa_control_type     = 'MATERIAL_OF'
         AND NVL(cffo.inactive_date,TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
         AND cfil.interface_invoice_id = p_interface_invoice_id ;
      --
      IF l_tpa_mat_off > 0 AND l_count_tpa_return <> 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                  , p_interface_operation_id => l_interface_operation_id
                  , p_organization_id        => p_organization_id
                  , p_error_code             => 'CFO RECEIPT ASSOC INV'
                  , p_invoice_line_id        => p_interface_invoice_line_id
                  , p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                  , p_invalid_value          => NULL
                  ) ;
        --
        p_return_code := 'E';
        p_return_message := 'CFO RECEIPT ASSOC INV';
        --
      END IF;
      --
      -- --------------------------
      -- INV CFO THIRD PARTY ASSOC
      -- --------------------------
      SELECT COUNT(*)
        INTO l_tpa_return_from
        FROM cll_f189_invoices_interface     cfil
           , cll_f189_invoice_lines_iface    cfili
           , cll_f189_fiscal_operations      cffo
       WHERE cfil.interface_invoice_id = cfili.interface_invoice_id
         AND cfili.cfo_id              = cffo.cfo_id
         AND cffo.tpa_control_type     = 'RETURN_FROM'
         AND NVL(cffo.inactive_date,TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
         AND cfil.interface_invoice_id = p_interface_invoice_id;
      --
      IF l_tpa_return_from > 0 AND l_count_tpa_return = 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                  , p_interface_operation_id => l_interface_operation_id
                  , p_organization_id        => p_organization_id
                  , p_error_code             => 'INV CFO THIRD PARTY ASSOC'
                  , p_invoice_line_id        => p_interface_invoice_line_id
                  , p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                  , p_invalid_value          => NULL
                  ) ;

        p_return_code    := 'E';
        p_return_message := 'INV CFO THIRD PARTY ASSOC';
        --
      ELSIF l_tpa_return_from > 0  AND l_count_tpa_return > 0 THEN
        --
        FOR r_invoice_lines_tpa IN c_invoice_lines_tpa ( p_interface_invoice_line_id ) LOOP
          -- ------------------------
          -- NULL TPA REMIT CTRL
          -- ------------------------
          IF (r_invoice_lines_tpa.tpa_remit_control_id IS NULL) then
            --
            ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                      , p_interface_operation_id => l_interface_operation_id    -- l_interface_operation_id
                      , p_organization_id        => p_organization_id           -- l_organization_id
                      , p_error_code             => 'NULL TPA REMIT CTRL'
                      , p_invoice_line_id        => p_interface_invoice_line_id -- r_tpa_tmp.interface_invoice_line_id
                      , p_table_associated       => 5                           -- CLL_F513_TPA_RETURNS_IFACE
                      , p_invalid_value          => NULL
                      ) ;
            --
            p_return_code := 'E';
            p_return_message := 'NULL TPA REMIT CTRL';
            --
          END IF ;
          --
          -- ------------------------
          -- REMIT CONTROL NO STOCK
          -- ------------------------
          IF (r_invoice_lines_tpa.new_subinventory_code IS NOT NULL) then
            --
            BEGIN
              --
              SELECT r_invoice_lines_tpa.new_subinventory_code
                INTO l_subinventory_code
                FROM cll_f513_tpa_remit_control
               WHERE tpa_remit_control_id = r_invoice_lines_tpa.tpa_remit_control_id
--               AND subinventory         = r_invoice_lines_tpa.new_subinventory_code
                 AND subinventory         IS NULL
                 AND r_invoice_lines_tpa.new_subinventory_code IS NOT NULL ;
              --
            EXCEPTION
               WHEN OTHERS THEN
                  l_subinventory_code := NULL ;
            END;
            --
            IF (l_subinventory_code IS NOT NULL) THEN
               ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                        ,p_interface_operation_id => l_interface_operation_id --l_interface_operation_id
                        ,p_organization_id        => p_organization_id --l_organization_id
                        ,p_error_code             => 'REMIT CONTROL NO STOCK'
                        ,p_invoice_line_id        => p_interface_invoice_line_id
                        ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                        ,p_invalid_value          => NULL
                        );

               p_return_code := 'E';
               p_return_message := 'REMIT CONTROL NO STOCK';
               --
            ELSE
               --
               -- ------------------------------------------------------
               --  INV SUBINVENTORY CODE Valid secondary inventory name
               -- ------------------------------------------------------
               BEGIN

                  SELECT secondary_inventory_name
                    INTO l_secondary_inventory
                    FROM mtl_secondary_inventories
                   WHERE organization_id = p_organization_id --l_organization_id
                     AND nvl(trunc(disable_date),sysdate) >= trunc(sysdate)
                     AND SECONDARY_INVENTORY_NAME = r_invoice_lines_tpa.new_subinventory_code;

               EXCEPTION
                  WHEN OTHERS THEN
                     l_secondary_inventory := NULL;
               END;
               --
               IF l_secondary_inventory is NULL then
                  --
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => l_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INV SUBINVENTORY CODE'
                           ,p_invoice_line_id        => p_interface_invoice_line_id
                           ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                           ,p_invalid_value          => p_new_subinventory_code
                           );

                  p_return_code := 'E';
                  p_return_message := 'INV SUBINVENTORY CODE';

               END IF;
               --
            END IF;
            -- ----------------
            -- INV LOCATION ID  -- Bug 29449519
            -- INVALID LOCATION -- Bug 29449519
            -- ----------------
            IF ((r_invoice_lines_tpa.new_locator_code IS NOT NULL) OR (r_invoice_lines_tpa.new_locator_id IS NOT NULL)) THEN
              --
              -- BUG 30633489 - Start
              /*
              BEGIN
                --
                SELECT mic.inventory_location_id
                  INTO l_location_id
                  FROM mtl_item_locations mic
                     , mtl_item_locations_kfv mic_kfv
                 WHERE mic.inventory_location_id      = mic_kfv.inventory_location_id
                   AND mic.organization_id            = p_organization_id
                   AND mic.subinventory_code          = l_secondary_inventory -- l_subinventory_code -- elton
                   AND (mic.inventory_location_id     = r_invoice_lines_tpa.new_locator_id
                    OR  mic_kfv.concatenated_segments = r_invoice_lines_tpa.new_locator_code);       -- elton
                --
              EXCEPTION
                 WHEN OTHERS THEN
                   l_location_id := 0;
              END;
              --
              */
              --
              l_location_id := NULL ;
              --
              IF r_invoice_lines_tpa.new_locator_id IS NOT NULL THEN
                --
                BEGIN
                  --
                  SELECT mic.inventory_location_id
                    INTO l_location_id
                    FROM mtl_item_locations     mic
                       , mtl_item_locations_kfv mic_kfv
                   WHERE mic.inventory_location_id = mic_kfv.inventory_location_id
                     AND mic.organization_id       = p_organization_id
                     AND mic.subinventory_code     = r_invoice_lines_tpa.new_subinventory_code
                     AND mic.inventory_location_id = r_invoice_lines_tpa.new_locator_id ;
                  --
                EXCEPTION
                  WHEN OTHERS THEN
                    l_location_id := NULL ;
                END ;
                --
              ELSE
                --
                BEGIN
                  --
                  SELECT mic.inventory_location_id
                    INTO l_location_id
                    FROM mtl_item_locations     mic
                       , mtl_item_locations_kfv mic_kfv
                   WHERE mic.inventory_location_id     = mic_kfv.inventory_location_id
                     AND mic.organization_id           = p_organization_id
                     AND mic.subinventory_code         = r_invoice_lines_tpa.new_subinventory_code
                     AND mic_kfv.concatenated_segments = r_invoice_lines_tpa.new_locator_code ;
                  --
                EXCEPTION
                  WHEN OTHERS THEN
                    l_location_id  := NULL ;
                END ;
                --
              END IF ;
              --
              -- BUG 30633489 - End
              --
              IF NVL(l_location_id,0) = 0 then --ELTON
                --
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => l_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'INVALID LOCATOR' -- Enh 29907995 'INVALID LOCATION'
                         ,p_invoice_line_id        => p_interface_invoice_line_id
                         ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                         ,p_invalid_value          => NVL(TO_CHAR(r_invoice_lines_tpa.new_locator_id), r_invoice_lines_tpa.new_locator_code)
                         );

                p_return_code    := 'E';
                p_return_message := 'INVALID LOCATOR' ; -- Enh 29907995 'INVALID LOCATION'
                --
                -- BUG 30633489 - Start
				--
              ELSE
                --
                UPDATE cll_f513_tpa_ret_iface_tmp
                   SET new_locator_id = l_location_id
                 WHERE ROWID = r_invoice_lines_tpa.linha ;
                --
                -- BUG 30633489 - End
                --
              END IF ;
              --
            END IF ;
            --
          ELSE -- If (r_tpa_tmp.NEW_SUBINVENTORY_CODE is NULL)
            --
            IF ((r_invoice_lines_tpa.new_locator_code IS NOT NULL) OR (r_invoice_lines_tpa.new_locator_id IS NOT NULL)) THEN
              --
              ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                       ,p_interface_operation_id => l_interface_operation_id
                       ,p_organization_id        => p_organization_id
                       ,p_error_code             => 'LOCATION FILLED INV'
                       ,p_invoice_line_id        => p_interface_invoice_line_id
                       ,p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                       ,p_invalid_value          => NULL
                       );
              --
              p_return_code := 'E';
              p_return_message := 'LOCATION FILLED INV';
              --
            END IF ;
            --
            -- ENR 30120364 - Start
            --
          END IF ;
          --
          BEGIN
            --
            SELECT COUNT(DISTINCT NVL(symbolic_return_flag, 'N'))
              INTO l_count_symbolic
              FROM cll_f513_tpa_ret_iface_tmp
             WHERE interface_invoice_line_id = p_interface_invoice_line_id ;
            --
            IF l_count_symbolic > 1 THEN
              --
              ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                        , p_interface_operation_id => l_interface_operation_id
                        , p_organization_id        => p_organization_id
                        , p_error_code             => 'INVALID SYMBOLIC TYPE'
                        , p_invoice_line_id        => p_interface_invoice_line_id
                        , p_table_associated       => 5 -- CLL_F513_TPA_RETURNS_IFACE
                        , p_invalid_value          => NULL
                        ) ;
              --
            END IF ;
            --
          END ;
          --
        END LOOP ;
        --
      ELSE
        -- -------------------
        -- TPA RETURN REQUIRED
        -- -------------------
        IF l_tpa_control_flag = 'RETURN_FROM' /* 'Y' Enh 29907995 */ AND l_count_tpa_return = 0 AND l_tpa_mat_off = 0 THEN
          --
          ADD_ERROR ( p_invoice_id             => p_interface_invoice_id      -- r_tpa_tmp.interface_invoice_id
                    , p_interface_operation_id => l_interface_operation_id    -- l_interface_operation_id
                    , p_organization_id        => p_organization_id           -- l_organization_id
                    , p_error_code             => 'TPA RETURN REQUIRED'
                    , p_invoice_line_id        => p_interface_invoice_line_id -- r_tpa_tmp.interface_invoice_line_id
                    , p_table_associated       => 5                           -- CLL_F513_TPA_RETURNS_IFACE
                    , p_invalid_value          => NULL
                    ) ;
          --
          p_return_code    := 'E' ;
          p_return_message := 'TPA RETURN REQUIRED' ;
          --
        END IF ;
        --
      END IF ;
      --
      -- 30211420 - End
      --
      END IF ;
	  --
	  -- BUG 30633489 13/12 - Start
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f189_invoices_interface   cfii
             , cll_f189_invoice_lines_iface  cfil
             , cll_f513_tpa_remit_control    cftrc
             , cll.cll_f513_tpa_ret_iface    cftd
             , cll_f189_fiscal_entities_all  cffe
             , hz_cust_site_uses_all         hcsua
         WHERE cfil.interface_invoice_id      = cfii.interface_invoice_id
           AND cftrc.organization_id          = cfii.organization_id
           AND cftrc.inventory_item_id        = cfil.item_id
           AND cftd.interface_invoice_line_id = cfil.interface_invoice_line_id
           AND cftrc.tpa_remit_control_id     = cftd.tpa_remit_control_id
           AND cffe.entity_id                 = cfii.entity_id
           AND cffe.cust_acct_site_id         = hcsua.cust_acct_site_id
           AND hcsua.site_use_id              = cftrc.ship_to_site_use_id
           AND cfii.interface_invoice_id      = p_interface_invoice_id
           AND cfil.interface_invoice_line_id = p_interface_invoice_line_id ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) = 0 AND NVL(l_count_tpa_return, 0) > 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_interface_invoice_id
                  , p_interface_operation_id => l_interface_operation_id
                  , p_organization_id        => p_organization_id
                  , p_error_code             => 'INV REMIT ASSOC'
                  , p_invoice_line_id        => p_interface_invoice_line_id
                  , p_table_associated       => 5
                  , p_invalid_value          => NULL
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'INV REMIT ASSOC' ;
         --
      END IF ;
	  --
	  -- BUG 30633489 13/12 - End
      --
    ELSIF p_type = 'INSERT' then
       --
       -- Chamar CLL_F513_TPA_RETURNS_CTRL_PUB
       --
       CLL_F513_TPA_RETURNS_CTRL_PUB.CREATE_OPEN_TPA_RETURNS ( p_tpa_return_control_id    => p_tpa_return_control_id
                                                             , p_organization_id          => p_organization_id
                                                             , p_tpa_remmit_control_id    => p_tpa_remit_control_id --p_tpa_remit_control_id
                                                             , p_ship_to_site_user_id     => p_ship_to_site_user_id
                                                             , p_operation_id             => p_operation_id
                                                             , p_entity_id                => p_entity_id
                                                             , p_operation_status         => p_operation_status
                                                             , p_reversion_transaction_id => p_reversion_transaction_id
                                                             , p_invoice_id               => p_invoice_id  --p_invoice_id
                                                             , p_invoice_line_id          => p_invoice_line_id --p_invoice_line_id
                                                             , p_invoice_number           => p_invoice_number
                                                             , p_invoice_date             => p_invoice_date
                                                             , p_returned_date            => p_returned_date
                                                             , p_inventory_item_id        => p_inventory_item_id
                                                             , p_returned_quantity        => p_returned_quantity
                                                             , p_new_subinventory_code    => p_new_subinventory_code --p_new_subinventory_code
                                                             , p_new_locator_id           => p_new_locator_id --p_new_locator_id
                                                             , p_unit_price               => p_unit_price
                                                             , p_returned_transaction_id  => p_returned_transaction_id
                                                             , p_reversion_flag           => p_reversion_flag
                                                             , p_attribute_category       => p_attribute_category
                                                             , p_attribute1               => p_attribute1
                                                             , p_attribute2               => p_attribute2
                                                             , p_attribute3               => p_attribute3
                                                             , p_attribute4               => p_attribute4
                                                             , p_attribute5               => p_attribute5
                                                             , p_attribute6               => p_attribute6
                                                             , p_attribute7               => p_attribute7
                                                             , p_attribute8               => p_attribute8
                                                             , p_attribute9               => p_attribute9
                                                             , p_attribute10              => p_attribute10
                                                             , p_attribute11              => p_attribute11
                                                             , p_attribute12              => p_attribute12
                                                             , p_attribute13              => p_attribute13
                                                             , p_attribute14              => p_attribute14
                                                             , p_attribute15              => p_attribute15
                                                             , p_attribute16              => p_attribute16
                                                             , p_attribute17              => p_attribute17
                                                             , p_attribute18              => p_attribute18
                                                             , p_attribute19              => p_attribute19
                                                             , p_attribute20              => p_attribute20
                                                             , p_created_by               => p_created_by
                                                             , p_creation_date            => p_creation_date
                                                             , p_last_update_date         => p_last_update_date
                                                             , p_last_update_login        => p_last_update_login
                                                             , p_request_id               => p_request_id
                                                             , p_program_application_id   => p_program_application_id
                                                             , p_program_id               => p_program_id
                                                             , p_program_update_date      => p_program_update_date
                                                             , p_item_number              => p_item_number                  -- ER  26338366/26899224 2a fase
                                                             , p_symbolic_return_flag     => p_symbolic_return_flag        -- ENR 30120364
                                                             ) ;
             --
         end if; --p_type
         --
     --END IF;
    print_log('  FIM CREATE_OPEN_TPA_RETURNS');
  END CREATE_OPEN_TPA_RETURNS;
  --<< ER 26338366/26899224 - dgouveia - 04/10/2017 - End >>--
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_INVOICE_PAR_LINES_TMP                                |
  |                                                                          |
  | Description: Responsible for validate information and insert into RI     |
  |              final tables or insert errors in RI or Loader interface     |
  |              tables                                                      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_INVOICE_PAR_LINES_TMP (p_type                           IN VARCHAR2
                                         ,p_interface_invoice_id           IN NUMBER
                                         ,p_interface_operation_id         IN NUMBER
                                         ,p_organization_id                IN NUMBER
                                         ,p_interface_parent_id            IN NUMBER
                                         ,p_parent_id                      IN NUMBER
                                         ,p_invoice_line_id                IN NUMBER -- BUG 19943706
                                         ,p_return_code                    OUT NOCOPY VARCHAR2
                                         ,p_return_message                 OUT NOCOPY VARCHAR2
                                         ,p_invoice_type_id                IN NUMBER -- Bug 17088635
                                         -- Begin BUG 24387238
                                         ,p_generate_line                  IN VARCHAR2 DEFAULT 'N'
                                         ,p_interface_invoice_line_id      IN NUMBER
                                         ,p_parent_line_id_out             OUT NOCOPY NUMBER
                                         ,p_inv_line_parent_id_out         OUT NOCOPY NUMBER
                                         ,p_invoice_id                     IN NUMBER
                                         ,p_total                          IN     NUMBER
                                         ,p_icms                           IN     NUMBER
                                         ,p_ipi                            IN     NUMBER
                                         ,p_business_vendor                IN     NUMBER
                                         ,p_org_state_id                   IN     NUMBER
                                         ,p_vendor_state_id                IN     NUMBEr
                                         ,p_additional_tax                 IN     NUMBER
                                         ,p_user_id                        IN     NUMBER
                                         ,p_interface                      IN     VARCHAR2
                                         ,p_invoice_line_id_in             IN     NUMBER DEFAULT NULL
                                         ,p_inv_line_parent_id_in          IN     NUMBER DEFAULT NULL
                                         ,p_line_location_id               IN     NUMBER DEFAULT NULL
                                         ,p_requisition_line_id            IN     NUMBER DEFAULT NULL
                                         ,p_item_id                        IN     NUMBER DEFAULT NULL
                                         ,p_type_exec                      IN     VARCHAR2 DEFAULT 'N'
                                         -- End BUG 24387238
                                         ,p_return_customer_flag            IN VARCHAR2 -- 29908009
                                         ) IS
  CURSOR c_invoice_parents_lines IS
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
            ,rtv_cfo_id                -- 29908009
            ,rtv_cfo_code              -- 29908009
            ,rtv_quantity              -- 29908009
            ,rtv_icms_tributary_code   -- 29908009
            ,rtv_ipi_tributary_code    -- 29908009
            ,rtv_pis_tributary_code    -- 29908009
            ,rtv_cofins_tributary_code -- 29908009
       FROM cll_f189_par_line_iface_tmp
      WHERE interface_parent_id        = p_interface_parent_id
      --AND interface_invoice_line_id  = p_interface_invoice_line_id; --poliana                                  -- 27448432
        AND ( interface_invoice_line_id  = p_interface_invoice_line_id OR p_interface_invoice_line_id IS NULL ); -- 27448432
    --

    l_exists_lines                      NUMBER;
    l_user_id                           NUMBER := FND_GLOBAL.USER_ID;
    --
    l_return_code                       VARCHAR2(100);
    l_return_message                    VARCHAR2(500);
    --
    l_ipi_tax_code                      VARCHAR2(30);  -- Bug 17088635
    l_icms_tax_code                     VARCHAR2(30);  -- Bug 17088635
    l_validation_rule_ipi               VARCHAR2(30);  -- Bug 17088635
    l_validation_rule_icms              VARCHAR2(30);  -- Bug 17088635
    --
    -- Begin BUG 24387238
    l_parent_line_id                    NUMBER;
    v_achei_line                        NUMBER :=0;
    -- End BUG 24387238
    l_rtv_cfo_id_out                    cll_f189_par_line_iface_tmp.rtv_cfo_id%TYPE;

  BEGIN
    print_log('  CREATE_INVOICE_PAR_LINES_TMP');
    --
    -- Iniciando validacoes da Nota Complementar
    --
    FOR r_invoice_parents_lines IN c_invoice_parents_lines LOOP
        IF p_type = 'VALIDATION' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --545;
            ----------------------------------------------------------------------
            -- Validando se existe no RI a linha informada na nota complementar --
            ----------------------------------------------------------------------
            l_exists_lines := CLL_F189_OPEN_VALIDATE_PUB.GET_QTY_INVOICE_LINES (p_invoice_parent_line_id  => r_invoice_parents_lines.invoice_parent_line_id
                                                                               );
            --
            IF l_exists_lines = 0 THEN
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'PARENT INV LINE NOT FOUND'
                         ,p_invoice_line_id        => r_invoice_parents_lines.interface_parent_line_id
                         ,p_table_associated       => 5 -- CLL_F189_INVOICE_LINE_PARENTS
                         ,p_invalid_value          => r_invoice_parents_lines.invoice_parent_line_id
                         );
            --
            -- Bug 17088635 Start

            -- 30015443 - Start
            /*  --- retirado validacao entre IPI_TAX_CODE e ICMS_TAX_CODE da nota pai x tipo de nota complementar ---
            ELSE
              --
              IF NVL(g_generate_line_compl,'N') = 'Y' THEN
                --
                CLL_F189_OPEN_VALIDATE_PUB.GET_INVOICE_LINE (p_invoice_line_id    => r_invoice_parents_lines.invoice_parent_line_id
                                                            ,p_ipi_tax_code       => l_ipi_tax_code
                                                            ,p_icms_tax_code      => l_icms_tax_code
                                                            );
                --
                l_validation_rule_ipi := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type        => 'CLL_F189_FEDERAL_TRIBUT_CODE'
                                                                                               ,p_code               => l_ipi_tax_code
                                                                                               ,p_invoice_type_id    => p_invoice_type_id
                                                                                               ,p_validity_type      => 'IPI TAXABLE FLAG'
                                                                                               );
                --
                IF l_validation_rule_ipi IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID IPI FLAG PAR'
                           ,p_invoice_line_id        => r_invoice_parents_lines.interface_parent_line_id
                           ,p_table_associated       => 5 -- CLL_F189_INVOICE_LINE_PARENTS
                           ,p_invalid_value          => l_ipi_tax_code
                           );
                END IF;
                --
                l_validation_rule_icms := CLL_F189_VALID_RULES_PKG.GET_GENERIC_VALIDATION_RULES (p_lookup_type        => 'CLL_F189_STATE_TRIBUT_CODE'
                                                                                                ,p_code               => l_icms_tax_code
                                                                                                ,p_invoice_type_id    => p_invoice_type_id
                                                                                                ,p_validity_type      => 'ICMS TAXABLE FLAG'
                                                                                                );
                --
                IF l_validation_rule_icms IS NULL THEN
                  ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                           ,p_interface_operation_id => p_interface_operation_id
                           ,p_organization_id        => p_organization_id
                           ,p_error_code             => 'INVALID ICMS FLAG PAR'
                           ,p_invoice_line_id        => r_invoice_parents_lines.interface_parent_line_id
                           ,p_table_associated       => 5 -- CLL_F189_INVOICE_LINE_PARENTS
                           ,p_invalid_value          => l_icms_tax_code
                           );
                END IF;
                --
              END IF; -- NVL(g_generate_line_compl,'N') = 'Y'
              --
              */ -- 30015443 - End

            -- Bug 17088635 End
            --
            -- 29908009 - Start
            ELSE

               IF p_return_customer_flag = 'F' THEN

                  IF (r_invoice_parents_lines.rtv_cfo_id IS NOT NULL) OR (r_invoice_parents_lines.rtv_cfo_code IS NOT NULL) THEN

                     l_rtv_cfo_id_out := CLL_F189_OPEN_VALIDATE_PUB.GET_FISCAL_OPERATIONS_RTV (p_cfo_id                 => r_invoice_parents_lines.rtv_cfo_id
                                                                                              ,p_cfo_code               => r_invoice_parents_lines.rtv_cfo_code
                                                                                              ,p_invoice_type_id        => p_invoice_type_id
                                                                                              ,p_source_state_id        => p_vendor_state_id
                                                                                              ,p_destination_state_id   => p_org_state_id
                                                                                              ,p_invoice_parent_line_id => r_invoice_parents_lines.invoice_parent_line_id
                                                                                              );

                     IF l_rtv_cfo_id_out IS NULL THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'RTV CFO INVALID'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => 'ID = '||r_invoice_parents_lines.rtv_cfo_id||' - CODE = '||r_invoice_parents_lines.rtv_cfo_code
                                 );
                     END IF;

                    IF  r_invoice_parents_lines.rtv_cfo_id IS NULL AND
                        r_invoice_parents_lines.rtv_cfo_code IS NOT NULL AND
                        l_rtv_cfo_id_out IS NOT NULL THEN
                        --
                        UPDATE cll_f189_par_line_iface_tmp
                           SET rtv_cfo_id = l_rtv_cfo_id_out
                         WHERE interface_parent_id      = p_interface_parent_id
                           AND interface_parent_id      = r_invoice_parents_lines.Interface_Parent_Id
                           AND interface_parent_line_id = r_invoice_parents_lines.interface_parent_line_id;
                        --
                    END IF;


                  END IF;

               END IF;
            -- 29908009 - End

            END IF;
        ELSIF p_type = 'INSERT' THEN
            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --546;
            --
            l_parent_line_id := CLL_F189_INV_PAR_LINES_PUB.GET_INVOICE_PARENT_LINES_S;

            -- 29908009 - Start
            IF p_return_customer_flag = 'F' THEN

               BEGIN
                  SELECT 1
                  INTO v_achei_line
                  FROM cll_f189_invoice_line_parents
                  WHERE parent_id                = p_parent_id
                    AND invoice_parent_line_id   = r_invoice_parents_lines.invoice_parent_line_id;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_achei_line := 0;
               END;

               IF v_achei_line = 0 THEN

                  CLL_F189_INV_PAR_LINES_PUB.CREATE_INVOICE_PARENT_LINES(p_parent_id                 => p_parent_id
                                                                        ,p_parent_line_id            => l_parent_line_id
                                                                        ,p_invoice_line_id           => p_invoice_line_id
                                                                        ,p_invoice_line_parent_id    => r_invoice_parents_lines.invoice_parent_line_id
                                                                        ,p_interface_parent_line_id  => r_invoice_parents_lines.interface_parent_line_id
                                                                        ,p_user_id                   => l_user_id
                                                                        ,p_attribute_category        => r_invoice_parents_lines.attribute_category
                                                                        ,p_attribute1                => r_invoice_parents_lines.attribute1
                                                                        ,p_attribute2                => r_invoice_parents_lines.attribute2
                                                                        ,p_attribute3                => r_invoice_parents_lines.attribute3
                                                                        ,p_attribute4                => r_invoice_parents_lines.attribute4
                                                                        ,p_attribute5                => r_invoice_parents_lines.attribute5
                                                                        ,p_attribute6                => r_invoice_parents_lines.attribute6
                                                                        ,p_attribute7                => r_invoice_parents_lines.attribute7
                                                                        ,p_attribute8                => r_invoice_parents_lines.attribute8
                                                                        ,p_attribute9                => r_invoice_parents_lines.attribute9
                                                                        ,p_attribute10               => r_invoice_parents_lines.attribute10
                                                                        ,p_attribute11               => r_invoice_parents_lines.attribute11
                                                                        ,p_attribute12               => r_invoice_parents_lines.attribute12
                                                                        ,p_attribute13               => r_invoice_parents_lines.attribute13
                                                                        ,p_attribute14               => r_invoice_parents_lines.attribute14
                                                                        ,p_attribute15               => r_invoice_parents_lines.attribute15
                                                                        ,p_attribute16               => r_invoice_parents_lines.attribute16
                                                                        ,p_attribute17               => r_invoice_parents_lines.attribute17
                                                                        ,p_attribute18               => r_invoice_parents_lines.attribute18
                                                                        ,p_attribute19               => r_invoice_parents_lines.attribute19
                                                                        ,p_attribute20               => r_invoice_parents_lines.attribute20
                                                                        ,p_rtv_cfo_id                => r_invoice_parents_lines.rtv_cfo_id
                                                                        ,p_rtv_quantity              => r_invoice_parents_lines.rtv_quantity
                                                                        ,p_rtv_icms_tributary_code   => r_invoice_parents_lines.rtv_icms_tributary_code
                                                                        ,p_rtv_ipi_tributary_code    => r_invoice_parents_lines.rtv_ipi_tributary_code
                                                                        ,p_rtv_pis_tributary_code    => r_invoice_parents_lines.rtv_pis_tributary_code
                                                                        ,p_rtv_cofins_tributary_code => r_invoice_parents_lines.rtv_cofins_tributary_code
                                                                        ,p_return_code               => l_return_code
                                                                        ,p_return_message            => l_return_message
                                                                        );
                  p_parent_line_id_out      := l_parent_line_id;
                  p_inv_line_parent_id_out  := r_invoice_parents_lines.invoice_parent_line_id;


---               CLL_F189_VENDOR_RETURN_PKG.CREATE_LINES( p_invoice_id                 => g_cll_f189_invoices_s
---                                                       ,p_invoice_type_id            => p_invoice_type_id
---                                                       ,p_total                      => p_total
---                                                       ,p_icms                       => p_icms
---                                                       ,p_ipi                        => p_ipi
---                                                       ,p_business_vendor            => p_business_vendor
---                                                       ,p_org_state_id               => p_org_state_id
---                                                       ,p_vendor_state_id            => p_vendor_state_id
---                                                       ,p_additional_tax             => p_additional_tax
---                                                       ,p_user_id                    => p_user_id
---                                                       ,p_interface                  => 'Y'                                               -- 29908009
---                                                       ,p_rtv_cfo_id                 => r_invoice_parents_lines.rtv_cfo_id                -- 29908009
---                                                       ,p_rtv_quantity               => r_invoice_parents_lines.rtv_quantity              -- 29908009
---                                                       ,p_rtv_icms_tributary_code    => r_invoice_parents_lines.rtv_icms_tributary_code   -- 29908009
---                                                       ,p_rtv_ipi_tributary_code     => r_invoice_parents_lines.rtv_ipi_tributary_code    -- 29908009
---                                                       ,p_rtv_pis_tributary_code     => r_invoice_parents_lines.rtv_pis_tributary_code    -- 29908009
---                                                       ,p_rtv_cofins_tributary_code  => r_invoice_parents_lines.rtv_cofins_tributary_code -- 29908009
---                                                       );

               END IF;

            ELSE
            -- 29908009 - End

               --
               -- Begin BUG 24387238
               IF p_type_exec = 'N' THEN
                  BEGIN
                     SELECT 1
                     INTO v_achei_line
                     FROM cll_f189_invoice_line_parents
                    WHERE parent_id                = p_parent_id
                      AND invoice_parent_line_id   = r_invoice_parents_lines.invoice_parent_line_id
                      AND invoice_line_id          = p_invoice_line_id;
                  EXCEPTION WHEN NO_DATA_FOUND THEN
                     v_achei_line := 0;
                  END;
               ELSIF p_type_exec = 'C' THEN
                  BEGIN
                     SELECT 1
                     INTO v_achei_line
                     FROM cll_f189_invoice_line_parents
                    WHERE parent_id                = p_parent_id
                      AND invoice_parent_line_id   = r_invoice_parents_lines.invoice_parent_line_id;
                 EXCEPTION WHEN NO_DATA_FOUND THEN
                   v_achei_line := 0;
                 END;
               END IF;
               --
               IF v_achei_line = 0 THEN
               -- End BUG 24387238
                  CLL_F189_INV_PAR_LINES_PUB.CREATE_INVOICE_PARENT_LINES(p_parent_id                 => p_parent_id
                                                                        ,p_parent_line_id            => l_parent_line_id  -- BUG 24387238
                                                                        ,p_invoice_line_id           => p_invoice_line_id -- r_invoice_parents_lines.interface_invoice_line_id -- BUG 19943706
                                                                        ,p_invoice_line_parent_id    => r_invoice_parents_lines.invoice_parent_line_id
                                                                        ,p_interface_parent_line_id  => r_invoice_parents_lines.interface_parent_line_id
                                                                        ,p_user_id                   => l_user_id
                                                                        ,p_attribute_category        => r_invoice_parents_lines.attribute_category
                                                                        ,p_attribute1                => r_invoice_parents_lines.attribute1
                                                                        ,p_attribute2                => r_invoice_parents_lines.attribute2
                                                                        ,p_attribute3                => r_invoice_parents_lines.attribute3
                                                                        ,p_attribute4                => r_invoice_parents_lines.attribute4
                                                                        ,p_attribute5                => r_invoice_parents_lines.attribute5
                                                                        ,p_attribute6                => r_invoice_parents_lines.attribute6
                                                                        ,p_attribute7                => r_invoice_parents_lines.attribute7
                                                                        ,p_attribute8                => r_invoice_parents_lines.attribute8
                                                                        ,p_attribute9                => r_invoice_parents_lines.attribute9
                                                                        ,p_attribute10               => r_invoice_parents_lines.attribute10
                                                                        ,p_attribute11               => r_invoice_parents_lines.attribute11
                                                                        ,p_attribute12               => r_invoice_parents_lines.attribute12
                                                                        ,p_attribute13               => r_invoice_parents_lines.attribute13
                                                                        ,p_attribute14               => r_invoice_parents_lines.attribute14
                                                                        ,p_attribute15               => r_invoice_parents_lines.attribute15
                                                                        ,p_attribute16               => r_invoice_parents_lines.attribute16
                                                                        ,p_attribute17               => r_invoice_parents_lines.attribute17
                                                                        ,p_attribute18               => r_invoice_parents_lines.attribute18
                                                                        ,p_attribute19               => r_invoice_parents_lines.attribute19
                                                                        ,p_attribute20               => r_invoice_parents_lines.attribute20
                                                                        ,p_rtv_cfo_id                => r_invoice_parents_lines.rtv_cfo_id                -- 29908009
                                                                        ,p_rtv_quantity              => r_invoice_parents_lines.rtv_quantity              -- 29908009
                                                                        ,p_rtv_icms_tributary_code   => r_invoice_parents_lines.rtv_icms_tributary_code   -- 29908009
                                                                        ,p_rtv_ipi_tributary_code    => r_invoice_parents_lines.rtv_ipi_tributary_code    -- 29908009
                                                                        ,p_rtv_pis_tributary_code    => r_invoice_parents_lines.rtv_pis_tributary_code    -- 29908009
                                                                        ,p_rtv_cofins_tributary_code => r_invoice_parents_lines.rtv_cofins_tributary_code -- 29908009
                                                                        ,p_return_code               => l_return_code
                                                                        ,p_return_message            => l_return_message
                                                                        );
                  p_parent_line_id_out      := l_parent_line_id;
                  p_inv_line_parent_id_out  := r_invoice_parents_lines.invoice_parent_line_id;
                  --
                  IF p_type_exec = 'N' THEN
                     CLL_F189_COMPL_INVOICE_PKG.PROC_COMPL_INVOICE(p_invoice_id             => g_cll_f189_invoices_s
                                                                  ,p_invoice_type_id        => p_invoice_type_id
                                                                  ,p_total                  => p_total
                                                                  ,p_icms                   => p_icms
                                                                  ,p_ipi                    => p_ipi
                                                                  ,p_business_vendor        => p_business_vendor
                                                                  ,p_org_state_id           => p_org_state_id
                                                                  ,p_vendor_state_id        => p_vendor_state_id
                                                                  ,p_additional_tax         => p_additional_tax
                                                                  ,p_user_id                => p_user_id
                                                                  ,p_interface              => 'Y' -- 22080756
                                                                  -- Begin BUG 24387238
                                                                  ,p_generate_line          => NVL(g_generate_line_compl,'N')
                                                                  ,p_parent_id              => p_parent_id
                                                                  ,p_parent_line_id         => l_parent_line_id
                                                                  ,p_interface_inv_line_id  => p_interface_invoice_line_id
                                                                  ,p_invoice_line_id_in     => p_invoice_line_id_in
                                                                  ,p_inv_line_parent_id_in  => r_invoice_parents_lines.invoice_parent_line_id
                                                                  ,p_type_exec              => p_type_exec
                                                                ,p_ret_code               => l_return_code    -- Enh 28884403
                                                                ,p_ret_message            => l_return_message -- Enh 28884403
                                                                  -- End BUG 24387238
                                                                  );
                  ELSIF p_type_exec = 'C' THEN

                     IF NVL(g_generate_line_compl,'N') = 'N' THEN
                        CLL_F189_COMPL_INVOICE_PKG.PROC_COMPL_INVOICE(p_invoice_id             => g_cll_f189_invoices_s
                                                                     ,p_invoice_type_id        => p_invoice_type_id
                                                                     ,p_total                  => p_total
                                                                     ,p_icms                   => p_icms
                                                                     ,p_ipi                    => p_ipi
                                                                     ,p_business_vendor        => p_business_vendor
                                                                     ,p_org_state_id           => p_org_state_id
                                                                     ,p_vendor_state_id        => p_vendor_state_id
                                                                     ,p_additional_tax         => p_additional_tax
                                                                     ,p_user_id                => p_user_id
                                                                     ,p_interface              => 'Y' -- 22080756
                                                                     -- Begin BUG 24387238
                                                                     ,p_generate_line          => NVL(g_generate_line_compl,'N')
                                                                     ,p_parent_id              => p_parent_id
                                                                     ,p_parent_line_id         => l_parent_line_id
                                                                     ,p_interface_inv_line_id  => p_interface_invoice_line_id
                                                                     ,p_invoice_line_id_in     => p_invoice_line_id_in
                                                                     ,p_inv_line_parent_id_in  => r_invoice_parents_lines.invoice_parent_line_id
                                                                     ,p_type_exec              => p_type_exec
                                                                   ,p_ret_code               => l_return_code    -- Enh 28884403
                                                                   ,p_ret_message            => l_return_message -- Enh 28884403
                                                                     -- End BUG 24387238
                                                                     );
                     END IF;

                  END IF;
                  -- End BUG 24387238

               END IF;
               --
            END IF;-- 29908009

            l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --547;
            g_cont_par_inv_line := g_cont_par_inv_line + 1;
            --
        END IF; --IF p_type = 'VALIDATION' THEN
    END LOOP;
    print_log('  FIM CREATE_INVOICE_PAR_LINES_TMP');
  END CREATE_INVOICE_PAR_LINES_TMP;
  --
  /*=========================================================================+
  |                                                                          |
  | Function:    CREATE_LEGAL_PROCESSES                                      |
  |                                                                          |
  | Description: Responsible for validate information and insert into RI     |
  |              final tables or insert errors in RI or Loader interface     |
  |              tables                                                      |
  |              E chamado apos ter feita todas as outras validacoes do RI,  |
  |              por isso valida e insere os Processos Legais                |
  |                                                                          |
  +=========================================================================*/
   PROCEDURE CREATE_LEGAL_PROCESSES (
    p_type                   IN VARCHAR2
,p_interface_invoice_id   IN NUMBER
,p_interface_operation_id IN NUMBER
,p_organization_id        IN NUMBER
,p_invoice_id             IN NUMBER
) IS
  CURSOR c_legal_processes (p_interface_invoice_id_IN  IN NUMBER) IS
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
      FROM cll_f189_legal_proc_iface_tmp
     WHERE interface_invoice_id = p_interface_invoice_id_IN;
   --
   l_legal_processes_id    NUMBER;
   l_count_leg_proc        NUMBER;
   --
   l_return_code           VARCHAR2(100);
   l_return_message        VARCHAR2(500);
   --
   l_count                 NUMBER := 0;
   --
   BEGIN
     print_log('  CREATE_LEGAL_PROCESSES');
     l_count := 0;
     --
     FOR r_fiscal_proc IN c_legal_processes(p_interface_invoice_id_IN => p_interface_invoice_id) LOOP
         --
         l_count := l_count + 1;
         --
        IF p_type = 'VALIDATION' THEN
            --
            -- Fazendo as validacoes
            --
            IF r_fiscal_proc.legal_process_number IS NULL THEN
                IF r_fiscal_proc.reference_table = 'FRT' THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'FRT PROC NUM REQUIRED'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                ELSE
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'PROCESS NUM REQUIRED'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                END IF ;
            END IF;
            --
            IF r_fiscal_proc.process_origin IS NULL THEN
                IF r_fiscal_proc.reference_table = 'FRT' THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'FRT PROC ORIG REQUIRED'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                ELSE
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'PROCESS ORIG REQUIRED'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
                END IF ;
            END IF;
            --
            BEGIN
                SELECT count(legal_process_id)
                  INTO l_count_leg_proc
                  FROM cll_f189_legal_proc_iface_tmp
                 WHERE reference_table      = r_fiscal_proc.reference_table
                   AND interface_invoice_id = r_fiscal_proc.interface_invoice_id
                   AND legal_process_number = r_fiscal_proc.legal_process_number
                   AND process_origin       = r_fiscal_proc.process_origin ;
            EXCEPTION
                WHEN OTHERS THEN
                    l_count_leg_proc := 0;
            END ;
            --
            IF l_count_leg_proc > 1 THEN
                IF r_fiscal_proc.reference_table = 'FRT' THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'DUPL FRT LEGAL PROCESS'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'NUMBER = '||r_fiscal_proc.legal_process_number||' - ORIGIN = '||r_fiscal_proc.process_origin
                             );
                ELSE
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'DUPLICATED LEGAL PROC'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => 'NUMBER = '||r_fiscal_proc.legal_process_number||' - ORIGIN = '||r_fiscal_proc.process_origin
                             );
                END IF ;
            END IF;
            --
            -- Fazendo os inserts
            --
       ELSIF p_type = 'INSERT' THEN
            l_legal_processes_id := CLL_F189_LEGAL_PROCESSES_PUB.GET_LEGAL_PROCESSES_S;
            --
            BEGIN
                --
                CLL_F189_LEGAL_PROCESSES_PUB.CREATE_LEGAL_PROCESSES(p_legal_process_id     => l_legal_processes_id --r_fiscal_proc.legal_process_id --
                                                                   ,p_reference_table      => r_fiscal_proc.reference_table
                                                                   ,p_invoice_id           => p_invoice_id
                                                                   ,p_legal_process_number => r_fiscal_proc.legal_process_number
                                                                   ,p_process_origin       => r_fiscal_proc.process_origin
                                                                   ,p_user_id              => r_fiscal_proc.created_by
                                                                   ,p_attribute_category   => r_fiscal_proc.attribute_category
                                                                   ,p_attribute1           => r_fiscal_proc.attribute1
                                                                   ,p_attribute2           => r_fiscal_proc.attribute2
                                                                   ,p_attribute3           => r_fiscal_proc.attribute3
                                                                   ,p_attribute4           => r_fiscal_proc.attribute4
                                                                   ,p_attribute5           => r_fiscal_proc.attribute5
                                                                   ,p_attribute6           => r_fiscal_proc.attribute6
                                                                   ,p_attribute7           => r_fiscal_proc.attribute7
                                                                   ,p_attribute8           => r_fiscal_proc.attribute8
                                                                   ,p_attribute9           => r_fiscal_proc.attribute9
                                                                   ,p_attribute10          => r_fiscal_proc.attribute10
                                                                   ,p_attribute11          => r_fiscal_proc.attribute11
                                                                   ,p_attribute12          => r_fiscal_proc.attribute12
                                                                   ,p_attribute13          => r_fiscal_proc.attribute13
                                                                   ,p_attribute14          => r_fiscal_proc.attribute14
                                                                   ,p_attribute15          => r_fiscal_proc.attribute15
                                                                   ,p_attribute16          => r_fiscal_proc.attribute16
                                                                   ,p_attribute17          => r_fiscal_proc.attribute17
                                                                   ,p_attribute18          => r_fiscal_proc.attribute18
                                                                   ,p_attribute19          => r_fiscal_proc.attribute19
                                                                   ,p_attribute20          => r_fiscal_proc.attribute20
                                                                   ,p_tax_type             => r_fiscal_proc.tax_type                   -- ER 17551029 4a Fase
                                                                   ,p_not_withheld_amount  => r_fiscal_proc.not_withheld_amount        -- ER 17551029 4a Fase
                                                                   ,p_process_id           => r_fiscal_proc.process_id                 -- 25808200 - 25808214
                                                                   ,p_process_suspension_code => r_fiscal_proc.process_suspension_code -- 25808200 - 25808214
                                                                   ,p_return_code          => l_return_code
                                                                   ,p_return_message       => l_return_message
                                                                   );
            END;
        END IF; -- IF p_type = 'VALIDATION' THEN
        --
     END LOOP ;
     --
     IF p_type = 'INSERT' THEN
         g_cont_leg_processes := g_cont_leg_processes + l_count;
     END IF;
     print_log('  FIM CREATE_LEGAL_PROCESSES');
   END CREATE_LEGAL_PROCESSES;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OUTBOUND_INVOICES                                    |
  |                                                                          |
  | Description: Responsavel por validar e inserir notas de saida            |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OUTBOUND_INVOICES (p_type                   IN VARCHAR2
                                     ,p_insert                 IN VARCHAR2 -- 22346186
                                     ,p_interface_invoice_id   IN NUMBER
                                     ,p_interface_operation_id IN NUMBER
                                     ,p_organization_id        IN NUMBER
                                     ,p_invoice_id             IN NUMBER
                                     ) IS
  CURSOR c_outbound_invoices(p_interface_invoice IN NUMBER) IS
        SELECT int_ra_cust_trx_id
              ,interface_invoice_id
              ,customer_trx_id
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
          FROM cll_f189_ra_cust_trx_iface_tmp
         WHERE interface_invoice_id = p_interface_invoice;
  --
  l_trx_number            ra_customer_trx.trx_number%TYPE;
  l_trx_date              ra_customer_trx.trx_date%TYPE;
  l_bill_to_site_use_id   ra_customer_trx.bill_to_site_use_id%TYPE;
  l_document              VARCHAR2(20);
  l_document_type         VARCHAR2(10);
  l_cust_acct_site_id     NUMBER;
  l_int_ra_cust_trx_id    NUMBER;
  l_allow_outbound        VARCHAR2(1);
  --
  l_user_id               NUMBER := FND_GLOBAL.USER_ID;
  l_return_code           VARCHAR2(100);
  l_return_message        VARCHAR2(500);
  l_count                 NUMBER := 0;
  --l_erro                  NUMBER;
  l_ship_to_site_use_id   ra_customer_trx.bill_to_site_use_id%TYPE; -- BUG 23534888
  --
  BEGIN
    print_log('  CREATE_OUTBOUND_INVOICES');
    FOR r_outbound_invoices IN c_outbound_invoices(p_interface_invoice => p_interface_invoice_id) LOOP
        --
        l_count := l_count + 1;
        --
        IF p_type = 'VALIDATION' THEN
            --
            -- Validando o Tipo de Nota
            --
            BEGIN
                SELECT 'Y'
                  INTO l_allow_outbound
                  FROM cll_f189_invoice_iface_tmp  cfii
                      ,cll_f189_invoice_types      cfit
                 WHERE cfii.interface_invoice_id = p_interface_invoice_id
                   AND cfit.organization_id      = p_organization_id
                   AND (cfii.invoice_type_id   = cfit.invoice_type_id OR
                        cfii.invoice_type_code = cfit.invoice_type_code
                       )
                   AND cfit.freight_flag         = 'Y'
                   AND NVL(cfit.parent_flag,'N') = 'N';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                             ,p_interface_operation_id => p_interface_operation_id
                             ,p_organization_id        => p_organization_id
                             ,p_error_code             => 'OUTBOUND INV TYPE INVALID'
                             ,p_invoice_line_id        => 0
                             ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                             ,p_invalid_value          => NULL
                             );
            END ;
            --
            -- Validando o ID da nota
            --
            IF r_outbound_invoices.customer_trx_id IS NOT NULL THEN
                BEGIN
                    SELECT trx_number
                          ,trx_date
                          -- Inicio BUG 23534888
                          -- Alteracao de BILL_TO_SITE_USE para SHIP_TO_SITE_USE para estar de acordo com a definicao e forms de OUTBOUND
                          --,bill_to_site_use_id
                          ,ship_to_site_use_id
                          -- Fim BUG 23534888
                      INTO l_trx_number
                          ,l_trx_date
                          --,l_bill_to_site_use_id
                          ,l_ship_to_site_use_id
                      FROM ra_customer_trx_all
                     WHERE customer_trx_id = r_outbound_invoices.customer_trx_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'CUSTOMER TXN ID NOT FND'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => r_outbound_invoices.customer_trx_id
                                 );
                END ;
            ELSE
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'CUSTOMER TXN ID NULL' --CUSTOMER TXN ID NOT FND
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF ;
            --
            -- Validando o endereco
            --
            IF r_outbound_invoices.cust_acct_site_id IS NOT NULL THEN
                BEGIN
                    SELECT DECODE(hcas.global_attribute2,'2',
                                                         DECODE(LENGTH(LTRIM(RTRIM(hcas.global_attribute3))),9,
                                                                SUBSTR(hcas.global_attribute3,2,8),
                                                                SUBSTR(hcas.global_attribute3,1,8)
                                                               )||SUBSTR(hcas.global_attribute4,1,4)||SUBSTR(hcas.global_attribute5,1,2)
                                                        ,'1',
                                                        SUBSTR(hcas.global_attribute3,1,9)||SUBSTR(LTRIM(hcas.global_attribute5),1,2),SUBSTR(hcas.global_attribute3,1,14)
                                 )  document
                         ,DECODE(hcas.global_attribute2,'2','CNPJ','1','CPF','OTHERS') document_type
                         ,hcsu.site_use_id
                     INTO l_document
                         ,l_document_type
                         ,l_cust_acct_site_id
                     FROM hz_cust_acct_sites hcas,
                          hz_cust_accounts hca,
                          hz_cust_site_uses_all hcsu,
                          hz_party_sites hps,
                          hz_locations loc,
                          ar_customers ac
                    WHERE ac.customer_id          = hcas.cust_account_id
                      AND hcas.cust_acct_site_id  = hcsu.cust_acct_site_id
                      AND hca.cust_account_id     = hcas.cust_account_id
                      AND hcas.party_site_id      = hps.party_site_id
                      AND hps.location_id         = loc.location_id
                      AND NVL(hca.status,'I')     = 'A'
                      AND hca.status              = hcas.status
                      AND hcas.global_attribute3 IS NOT NULL
                      -- Inicio BUG 23534888
                      -- Alteracao de BILL_TO para SHIP_TO para estar de acordo com a definicao e forms de OUTBOUND
                      -- AND hcsu.site_use_code      = 'BILL_TO'
                      AND hcsu.site_use_code      = 'SHIP_TO'
                      -- Fim BUG 23534888
                      AND hcsu.site_use_id        = r_outbound_invoices.cust_acct_site_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                                 ,p_interface_operation_id => p_interface_operation_id
                                 ,p_organization_id        => p_organization_id
                                 ,p_error_code             => 'CUSTOMER NOT FND'
                                 ,p_invoice_line_id        => 0
                                 ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                                 ,p_invalid_value          => 'CUST_ACCT_SITE_ID='||r_outbound_invoices.cust_acct_site_id
                                 );
                END;
            ELSE
                ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'CUSTOMER NULL' --CUSTOMER NOT FND
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => NULL
                         );
            END IF ;
            --
            -- IF nvl(l_bill_to_site_use_id,0) <> nvl(l_cust_acct_site_id,0) THEN -- BUG 23534888
            IF nvl(l_ship_to_site_use_id,0) <> nvl(l_cust_acct_site_id,0) THEN    -- BUG 23534888
               ADD_ERROR(p_invoice_id             => p_interface_invoice_id
                         ,p_interface_operation_id => p_interface_operation_id
                         ,p_organization_id        => p_organization_id
                         ,p_error_code             => 'OUTBOUND INVOICE NOT FND'
                         ,p_invoice_line_id        => 0
                         ,p_table_associated       => 1 -- CLL_F189_INVOICES_INTERFACE
                         ,p_invalid_value          => 'BILL_TO_SITE_USE_ID='||l_bill_to_site_use_id||'-CUST_ACCT_SITE_ID='||l_cust_acct_site_id
                         );
            END IF;
            --
            IF p_insert = 'Y' THEN      -- 22346186
               --
               l_int_ra_cust_trx_id := CLL_F189_RA_CUST_TRX_PUB.GET_RA_CUST_TRX_S;
               --
               BEGIN
                  CLL_F189_RA_CUST_TRX_PUB.CREATE_RA_CUST_TRX_PUB (p_ra_cust_trx_id       => l_int_ra_cust_trx_id
                                                                  ,p_invoice_id           => p_invoice_id
                                                                  ,p_customer_trx_id      => r_outbound_invoices.customer_trx_id
                                                                  ,p_cust_acct_site_id    => NVL(l_cust_acct_site_id,r_outbound_invoices.cust_acct_site_id)
                                                                  ,p_trx_number           => l_trx_number
                                                                  ,p_trx_date             => l_trx_date
                                                                  ,p_user_id              => l_user_id
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
                                                                  ,p_eletronic_invoice_key  => r_outbound_invoices.eletronic_invoice_key -- 27579747
                                                                  ,p_return_code          => l_return_code
                                                                  ,p_return_message       => l_return_message
                                                                  );
                  --
                  COMMIT;
                  --
               END;
            END IF; -- IF p_insert = 'Y' THEN -- 22346186
        END IF; --IF p_type = 'VALIDATION' THEN
    END LOOP;
    --
    IF p_type = 'INSERT' THEN
        g_cont_out_invoice := g_cont_out_invoice + l_count;
    END IF;
    print_log('  FIM CREATE_OUTBOUND_INVOICES');
  END CREATE_OUTBOUND_INVOICES;
  --
  -- ER 17551029 4a Fase - Start
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_PRIOR_BILLINGS                                       |
  |                                                                          |
  | Description: Responsavel por validar e inserir prior Billings            |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_PRIOR_BILLINGS (p_type                   IN VARCHAR2
                                  ,p_interface_invoice_id   IN NUMBER
                                  ,p_interface_operation_id IN NUMBER
                                  ,p_organization_id        IN NUMBER
                                  ,p_invoice_id             IN NUMBER
                                     ) IS
  CURSOR c_prior_billings(p_interface_invoice IN NUMBER) IS
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
          FROM cll_f189_prior_bill_iface_tmp
         WHERE interface_invoice_id = p_interface_invoice;
  --
  l_prior_billings_id     NUMBER;
  --
  l_user_id               NUMBER := FND_GLOBAL.USER_ID;
  l_return_code           VARCHAR2(100);
  l_return_message        VARCHAR2(500);
  l_count                 NUMBER := 0;
  --
  BEGIN
    print_log('  CREATE_PRIOR_BILLINGS');
    FOR r_prior_billings IN c_prior_billings(p_interface_invoice => p_interface_invoice_id) LOOP
        --
        l_count := l_count + 1;
        --
        IF p_type = 'VALIDATION' THEN
            --
            -- Validando prior billings
            --
           NULL;
        ELSIF p_type = 'INSERT' THEN
            l_prior_billings_id := CLL_F189_PRIOR_BILLINGS_PUB.GET_PRIOR_BILLINGS_S;
            --
            BEGIN
                --
                CLL_F189_PRIOR_BILLINGS_PUB.CREATE_PRIOR_BILLINGS(p_prior_billings_id    => l_prior_billings_id
                                                                 ,p_invoice_id           => p_invoice_id
                                                                 ,p_document_type        => r_prior_billings.document_type
                                                                 ,p_document_number      => r_prior_billings.document_number
                                                                 ,p_total_remuneration_amount => r_prior_billings.total_remuneration_amount
                                                                 ,p_user_id              => r_prior_billings.created_by
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
            END;
        END IF; --IF p_type = 'VALIDATION' THEN
    END LOOP;
    --
    IF p_type = 'INSERT' THEN
        g_cont_prior_billings := g_cont_prior_billings  + l_count;
    END IF;
    print_log('  FIM CREATE_PRIOR_BILLINGS');
  END CREATE_PRIOR_BILLINGS;
  -- ER 17551029 4a Fase - End
  --
  -- 28592012 - Start
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_PAYMENT_METHODS                                      |
  |                                                                          |
  | Description: Responsavel por validar e inserir Payment Methods           |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_PAYMENT_METHODS (
    p_type                   IN VARCHAR2
    ,p_interface_invoice_id   IN NUMBER
    ,p_interface_operation_id IN NUMBER
    ,p_organization_id        IN NUMBER
    ,p_invoice_id             IN NUMBER
  ) IS
  CURSOR c_payment_methods(p_interface_invoice IN NUMBER) IS
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
          FROM cll_f189_pay_mtd_iface_tmp
         WHERE interface_invoice_id = p_interface_invoice;
  --
  l_payment_method_id     NUMBER;
  --
  l_user_id               NUMBER := FND_GLOBAL.USER_ID;
  l_return_code           VARCHAR2(100);
  l_return_message        VARCHAR2(500);
  l_count                 NUMBER := 0;
  --
  BEGIN
    print_log('  CREATE_PAYMENT_METHODS');
    FOR r_payment_methods IN c_payment_methods(p_interface_invoice => p_interface_invoice_id) LOOP
      --
      l_count := l_count + 1;
      --
      IF p_type = 'VALIDATION' THEN
        -- Validando Payment Methods
        NULL;
      ELSIF p_type = 'INSERT' THEN
        l_payment_method_id := CLL_F189_PAYMENT_METHODS_PUB.GET_PAYMENT_METHODS_S;
        --
        BEGIN
          --
          CLL_F189_PAYMENT_METHODS_PUB.CREATE_PAYMENT_METHODS(
            p_payment_method_id        => l_payment_method_id
            ,p_invoice_id               => p_invoice_id
            ,p_payment_method_indicator => r_payment_methods.payment_method_indicator
            ,p_payment_method           => r_payment_methods.payment_method
            ,p_payment_amount           => r_payment_methods.payment_amount
            ,p_user_id                  => r_payment_methods.created_by
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
        END;
      END IF; --IF p_type = 'VALIDATION' THEN
    END LOOP;
    --
    IF p_type = 'INSERT' THEN
      g_cont_payment_methods := g_cont_payment_methods  + l_count;
    END IF;
    print_log(' FIM CREATE_PAYMENT_METHODS');
  END CREATE_PAYMENT_METHODS;
  -- 28592012 - End
  --
  -- 29330466 - 29338175 - 29385361 - 29480917 - Start
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_REFERENCED_DOCUMENTS                                 |
  |                                                                          |
  | Description: Responsavel por validar e inserir Referenced Documents      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_REFERENCED_DOCUMENTS (
    p_type                   IN VARCHAR2
    ,p_interface_invoice_id   IN NUMBER
    ,p_interface_operation_id IN NUMBER
    ,p_organization_id        IN NUMBER
    ,p_invoice_id             IN NUMBER
  ) IS
  CURSOR c_referenced_documents(p_interface_invoice IN NUMBER) IS
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
          FROM cll_f189_ref_docs_iface_tmp
         WHERE interface_invoice_id = p_interface_invoice;
  --
  l_referenced_documents_id     NUMBER;
  --
  l_user_id               NUMBER := FND_GLOBAL.USER_ID;
  l_return_code           VARCHAR2(100);
  l_return_message        VARCHAR2(500);
  l_count                 NUMBER := 0;
  --
  BEGIN
    print_log('  CREATE_REFERENCED_DOCUMENTS');
    FOR r_referenced_documents IN c_referenced_documents(p_interface_invoice => p_interface_invoice_id) LOOP
      --
      l_count := l_count + 1;
      --
      IF p_type = 'VALIDATION' THEN
        -- Validando Referenced Documents
        NULL;
      ELSIF p_type = 'INSERT' THEN
        l_referenced_documents_id := CLL_F189_REF_DOCS_PUB.GET_REF_DOCUMENTS_S;
        --
        BEGIN
          --
          CLL_F189_REF_DOCS_PUB.CREATE_REFERENCED_DOCUMENTS(
            p_referenced_documents_id   => l_referenced_documents_id
            ,p_invoice_id                => p_invoice_id
            ,p_referenced_documents_type => r_referenced_documents.referenced_documents_type
            ,p_eletronic_invoice_key     => r_referenced_documents.eletronic_invoice_key
            ,p_source_document_type      => r_referenced_documents.source_document_type
            ,p_document_description      => r_referenced_documents.document_description
            ,p_document_number           => r_referenced_documents.document_number
            ,p_document_issue_date       => r_referenced_documents. document_issue_date
            ,p_user_id                   => r_referenced_documents.created_by
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
        END;
      END IF; --IF p_type = 'VALIDATION' THEN
    END LOOP;
    --
    IF p_type = 'INSERT' THEN
      g_cont_ref_documents := g_cont_ref_documents  + l_count;
    END IF;
    print_log('  FIM CREATE_REFERENCED_DOCUMENTS');
  END CREATE_REFERENCED_DOCUMENTS;
  -- 29330466 - 29338175 - 29385361 - 29480917 - End
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   APPROVE_INTERFACE                                           |
  |                                                                          |
  | Description: Responsavel por fazer a aprovacao do documento na Open      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE APPROVE_INTERFACE (
    p_organization_id   IN cll_f189_entry_operations.organization_id%TYPE
    ,p_operation_id      IN cll_f189_entry_operations.operation_id%TYPE
    ,p_location_id       IN cll_f189_invoices.location_id%TYPE
    ,p_gl_date           IN cll_f189_entry_operations.gl_date%TYPE
    ,p_receive_date      IN cll_f189_entry_operations.receive_date%TYPE
    ,p_created_by        IN cll_f189_entry_operations.created_by%TYPE
    ,p_source            IN VARCHAR2
    ,p_interface         IN VARCHAR2 DEFAULT 'N'
    ,p_int_invoice_id    IN cll_f189_invoices_interface.interface_invoice_id%TYPE
  ) IS

    l_processo            VARCHAR2(50);
    l_operating_unit      NUMBER;
    l_error_message       VARCHAR2(80);
    l_aux                 VARCHAR2(1);

    l_trans_factor        NUMBER;
    l_itm_trans_factor    NUMBER;
    l_icms_trans_factor   NUMBER;
    l_ipi_trans_factor    NUMBER;
    l_ii_trans_factor     NUMBER;
    l_frt_trans_factor    NUMBER;
    l_gl_date             DATE;
    l_return_flag         VARCHAR2(10);
    l_user_id             NUMBER := FND_GLOBAL.USER_ID;
    l_contab_flag         cll_f189_invoice_types.contab_flag%TYPE;
    l_module_name         CONSTANT VARCHAR2(100) := 'CLL_F189_OPEN_INTERFACE_PKG.APPROVE_INTERFACE';
    l_outbound_qty        NUMBER := 0;
    l_posted_flag         VARCHAR2(1); --<< BUG 19814516 --Egini -- 11/12/2014 -->>
    l_icms_st_base        NUMBER; -- 21909282
    l_internal_icms_tax   NUMBER; -- 21909282
    l_fcp_st_rate         NUMBER; -- 25713076
    l_fcp_st_amount       NUMBER; -- 25713076
    l_return_status       VARCHAR2(1) := '0'; -- 28806961_27831745

  BEGIN
    print_log('  APPROVE_INTERFACE');
    print_log('  '||l_module_name || ' - Start process approve.');
    l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --0;
    --
    BEGIN
      SELECT operating_unit
      INTO l_operating_unit
      FROM org_organization_definitions
      WHERE organization_id = p_organization_id;
    EXCEPTION WHEN OTHERS THEN
      print_log('    Erro ao recuperar Operation_unit:'||sqlerrm);
      raise_application_error (-20001,SQLERRM|| '- SELECT org_organization_definitions - '|| ' organization_id:'|| p_organization_id|| ' operation_unit:'|| l_operating_unit);
    END;
    -- 28806961_27831745 - Start
    -- Inclusao das chamadas das pkgs de validacao e calculos
    IF p_source IN ('CLL_F369 EFD LOADER SHIPPER','CLL_F369 EFD LOADER') THEN
      -- Iniciar o tratamento dos recebimentos originados pelo EFD_Loader
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --900;
      print_log('    Chamando CLL_F189_LOADER_ADJUST_PKG.ADJUST_PROCESS...');
      cll_f189_loader_adjust_pkg.adjust_process(
        p_organization_id   => p_organization_id
        ,p_operation_id      => p_operation_id
        ,p_source            => p_source
        ,p_return_status     => l_return_status
      );
      IF l_return_status = '1' THEN
        -- Gerar divergencias e reter o recebimento
        ROLLBACK;
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --910;
        --
        UPDATE cll_f189_entry_operations
        SET status = 'IN HOLD'
        WHERE operation_id = p_operation_id
        AND organization_id = p_organization_id;
        --
        print_log('    Chamando CLL_F189_CHECK_HOLDS_PKG.INCLUIR_ERRO_HOLD...');
        CLL_F189_CHECK_HOLDS_PKG.INCLUIR_ERRO_HOLD (
          p_operation_id,
          p_organization_id,
          p_location_id,
          'DIVERGENCE ERROR',
          NULL,
          NULL
        );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --910;
      ELSE
        -- Acionar a rotina de calculo dos impostos
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --920;
        print_log('    Chamando CLL_F189_LOADER_ADJUST_PKG.CALCULATE_TAXES...');
        cll_f189_loader_adjust_pkg.calculate_taxes(
          p_organization_id => p_organization_id
          ,p_operation_id    => p_operation_id
          ,p_tax             => 'OTHERS'
          ,p_return_status   => l_return_status 
        );
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --930;
        --
        IF l_return_status = '1' THEN
          -- Gerar divergencias e reter o recebimento
          ROLLBACK;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --930;
          --
          UPDATE cll_f189_entry_operations
          SET status = 'IN HOLD'
          WHERE operation_id = p_operation_id
          AND organization_id = p_organization_id;
          --
          print_log('    Chamando CLL_F189_CHECK_HOLDS_PKG.INCLUIR_ERRO_HOLD...');
          CLL_F189_CHECK_HOLDS_PKG.INCLUIR_ERRO_HOLD (
            p_operation_id,
            p_organization_id,
            p_location_id,
            'DIVERGENCE ERROR',
            NULL,
            NULL
          );
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --930;
        END IF;
      END IF;
    ELSE
      l_return_status := '0';
    END IF;

    IF l_return_status = '0' THEN
      -- 28806961_27831745 - End
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --1000;
      --
      print_log('    Chamando CLL_F189_ICMS_TAX_PKG.GET_ICMS_ST_ADVANCED...');
      CLL_F189_ICMS_TAX_PKG.get_icms_st_advanced (
        p_organization_id => p_organization_id
        ,p_location_id     => p_location_id
        ,p_operation_id    => p_operation_id
      );
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --2000;
      --
      print_log('    Chamando CLL_F189_ICMS_TAX_PKG.GET_ICMS_ST...');
      CLL_F189_ICMS_TAX_PKG.get_icms_st (
        p_organization_id   => p_organization_id
        ,p_location_id       => p_location_id
        ,p_operation_id      => p_operation_id
        ,p_call_source       => NULL                -- 21909282
        ,p_source            => NULL                -- 21909282
        ,p_invoice_line_id   => NULL                -- 23534888
        ,p_icms_st_base      => l_icms_st_base      -- 21909282
        ,p_internal_icms_tax => l_internal_icms_tax -- 21909282
      );
      -- ER 16863381-NEW SOLUTION FOR TAX CALCULATION - End
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --2000;

      print_log('    Chamando CLL_F189_FREIGHT_DIFFERENT_PKG.PROC_FREIGHT_DIFFERENTIAL...');
      CLL_F189_FREIGHT_DIFFERENT_PKG.PROC_FREIGHT_DIFFERENTIAL (
        p_operation_id
        ,p_location_id
        ,p_organization_id
      );

      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --3000;
      --
      BEGIN
        SELECT COUNT(1)
        INTO l_outbound_qty
        FROM 
          cll_f189_invoices cfi
          ,cll_f189_invoice_types cfit
          ,cll_f189_invoice_lines cfil
        WHERE 1=1
          and cfi.organization_id            = p_organization_id
          AND cfi.operation_id               = p_operation_id
          AND cfit.invoice_type_id           = cfi.invoice_type_id
          AND cfit.organization_id           = cfi.organization_id
          AND cfit.freight_flag              = 'Y'
          AND NVL(cfit.parent_flag,'N')      = 'N'
          AND cfil.invoice_id                = cfi.invoice_id
          AND (NVL(cfil.pis_amount_rec_lin,0) > 0 OR NVL(cfil.cofins_amount_rec_lin,0) > 0);
      EXCEPTION WHEN OTHERS THEN
        l_outbound_qty := 0;
      END;
      --
      IF l_outbound_qty > 0 THEN
        CLL_F189_OUTBOUND_INVOICES_PKG.CALC_RATIO_FRT (
          p_operation_id
          ,p_organization_id
        );
      END IF;
      --
      CLL_F189_AVERAGE_COST_PKG.PROC_AVERAGE_COST (
        p_operation_id
        ,p_organization_id
        ,p_location_id
      );
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --4000;
      --
      CLL_F189_CALC_IDX_DOLLAR_PKG.PROC_CALC_IDX_DOLLAR (
        p_operation_id
        ,p_location_id
        ,p_organization_id
        ,'N'
        ,NULL               -- 23275142
        ,NULL               -- 23275142
        ,NULL               -- 23275142
        ,l_trans_factor
        ,l_itm_trans_factor
        ,l_icms_trans_factor
        ,l_ipi_trans_factor
        ,l_ii_trans_factor
        ,l_frt_trans_factor
      );
      --
      -- ENH 28802908 - Start
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --4050;
      IF p_source IN ('CLL_F369 EFD LOADER SHIPPER','CLL_F369 EFD LOADER') THEN
        cll_f189_cost_complement_pkg.proc_cost_complement (p_organization_id,p_operation_id);
      END IF;
      -- ENH 28802908 - End
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --5000;
      UPDATE cll_f189_entry_operations
      SET 
        translation_factor    = l_trans_factor
        ,item_factor           = l_itm_trans_factor
        ,icms_transl_factor    = l_icms_trans_factor
        ,ipi_transl_factor     = l_ipi_trans_factor
        ,ii_transl_factor      = l_ii_trans_factor
        ,freight_transl_factor = l_frt_trans_factor
        ,last_update_date      = SYSDATE
        ,last_updated_by       = l_user_id
      WHERE operation_id    = p_operation_id
      AND organization_id = p_organization_id;
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --5000;
      l_gl_date := p_gl_date;
      --
      BEGIN
        print_log('l_gl_date        :'||l_gl_date);
        print_log('p_operation_id   :'||p_operation_id);
        print_log('p_organization_id:'||p_organization_id);
        --
        SELECT rit.contab_flag
        INTO l_contab_flag
        FROM 
          cll_f189_invoice_types   rit
          ,cll_f189_invoices        ri
        WHERE 1=1
        and ri.invoice_type_id = rit.invoice_type_id
        AND ri.operation_id    = p_operation_id
        AND ri.organization_id = p_organization_id
        AND TRUNC (NVL (rit.inactive_date, SYSDATE + 1)) > TRUNC (SYSDATE)
        AND ROWNUM = 1;
        
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --5000;
        
        IF l_contab_flag = 'I'THEN
          CLL_F189_TAX_ONLY_PKG.PROC_TAX_ONLY (
            p_operation_id
            ,l_operating_unit
            ,p_organization_id
            ,l_gl_date
            ,p_receive_date
            ,p_created_by
            ,l_return_flag
            ,l_trans_factor
            ,l_itm_trans_factor
          );
          ELSE
          CLL_F189_POST_TO_GL_PKG.PROC_POST_TO_GL (
            p_operation_id
            ,l_operating_unit
            ,p_organization_id
            ,l_gl_date
            ,p_receive_date
            ,p_created_by
            ,l_return_flag
            ,l_trans_factor
            ,l_itm_trans_factor
          );
        END IF;
      EXCEPTION WHEN OTHERS THEN
        print_log('**************************************');
        print_log('Problems Approve receive.');
        print_log('ERROR access invoice types.');
        print_log('ERROR: ' || TO_CHAR (SQLCODE) || SQLERRM);
        print_log('**************************************');
        print_log(' ');
      END;
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --7000;
      --
      IF l_return_flag IS NOT NULL THEN
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --8000;
        --
        UPDATE cll_f189_entry_operations
        SET 
          translation_factor = l_trans_factor
          ,item_factor        = l_itm_trans_factor
          ,gl_date            = l_gl_date
          ,last_update_date   = SYSDATE
          ,last_updated_by    = l_user_id
        WHERE operation_id    = p_operation_id
        AND organization_id = p_organization_id;
        --
        l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --9000;
        --
        BEGIN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --10000;
          l_processo := 'CLL_F189_INTERFACE_PKG.GL';
          CLL_F189_INTERFACE_PKG.GL (p_operation_id, p_organization_id);
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --11000;
          l_processo := 'CLL_F189_INTERFACE_PKG.AP';
          CLL_F189_INTERFACE_PKG.AP (
            p_operation_id,
            p_organization_id,
            l_operating_unit,
            p_created_by
          );
          --
          -- Bug 30485011 - Inicio
          IF p_source = 'CLL_F369 EFD LOADER SHIPPER' OR p_source = 'CLL_F369 EFD LOADER' THEN
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --12000;
          l_processo := 'CLL_F189_UPD_COSTS_PKG.PROC_UPD_COSTS';
          CLL_F189_UPD_COSTS_PKG.PROC_UPD_COSTS (
            p_organization_id
            ,p_operation_id
          );
          END IF;
          -- Bug 30485011 - Fim
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --13000;
          l_processo := 'CLL_F189_INTERFACE_PKG.FSC';
          CLL_F189_INTERFACE_PKG.FSC (
            p_operation_id,
            p_organization_id,
            p_created_by
          );
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --14000;
          l_processo := 'CLL_F189_INTERFACE_PKG.FA';
          CLL_F189_INTERFACE_PKG.FA (
            p_operation_id,
            p_organization_id,
            p_created_by
          );
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --15000;
          l_processo := 'CLL_F189_INTERFACE_OPM_PKG.PROC_INTERFACE_OPM';
          CLL_F189_INTERFACE_OPM_PKG.PROC_INTERFACE_OPM (
            p_operation_id,
            p_organization_id,
            p_created_by
          );
          --
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --16000;
          --
          --<< BUG 19814516 - Egini -- 11/12/2014 --Start -->>
          --
          BEGIN
            IF l_contab_flag = 'N' OR l_contab_flag = 'P' THEN
              l_posted_flag := 'N';
            ELSE
              l_posted_flag := 'Y';
            END IF;
          END;
          --
          --<< BUG 19814516 - Egini -- 11/12/2014 --Start -->>
          --
          UPDATE cll_f189_entry_operations
          SET 
            status       = 'COMPLETE'
            ,completed_by = 'O'
            --,posted_flag  = 'Y'         --<< BUG 19814516 - Egini -- 11/12/2014 --Start -->>
            ,posted_flag = l_posted_flag  --<< BUG 19814516 - Egini -- 11/12/2014 --Start -->>
          WHERE operation_id = p_operation_id
          AND organization_id = p_organization_id;
        EXCEPTION WHEN OTHERS THEN
          print_log(l_module_name);
          print_log('**************************************');
          print_log('Problems approve receive.');
          print_log(l_processo || ' ERROR.');
          print_log('ERROR: ' || TO_CHAR (SQLCODE) || SQLERRM);
          print_log('**************************************');
          print_log(' ');
          ROLLBACK;
          l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --17000;
          --
          UPDATE cll_f189_entry_operations
          SET status = 'IN HOLD'
          WHERE operation_id = p_operation_id
          AND organization_id = p_organization_id;
          CLL_F189_CHECK_HOLDS_PKG.INCLUIR_ERRO_HOLD (
            p_operation_id,
            p_organization_id,
            p_location_id,
            'INTERF GENERATION ERROR',
            NULL,
            NULL
          );
        END;
      END IF; --IF l_return_flag IS NOT NULL THEN
      --
      l_debug := $$PLSQL_LINE; print_log('    Err:'||check_erro);  --18000;
    END IF; --  l_return_status = '0' -- 28806961_27831745
    COMMIT;
    print_log('  FIM APPROVE_INTERFACE');
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      print_log(' ');
      print_log(l_module_name || ' - ERROR l_debug number: { ' || TO_CHAR (l_debug)||' }');
      print_log('Interface_Invoice_Id = '||p_int_invoice_id);
      print_log(' ');
      print_log('  FIM APPROVE_INTERFACE');
      raise_application_error (-20002,l_module_name|| ' - ERROR l_debug number: { '|| TO_CHAR (l_debug)||' } - '|| SQLERRM);
  END APPROVE_INTERFACE;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:    BASE_ACCUMULATE_IRRF                                       |
  |                                                                          |
  | Description: Responsavel por calcular e retornar os valores do IRRF      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE BASE_ACCUMULATE_IRRF (
    p_accumulate_type            IN cll_f189_tax_sites.cumulative_threshold_type%TYPE DEFAULT NULL
   ,p_minimun_value              IN cll_f189_tax_sites.minimum_tax_amount%TYPE DEFAULT NULL
   ,p_invoice_id                 IN cll_f189_invoices.invoice_id%TYPE DEFAULT NULL
   ,p_entity_id                  IN cll_f189_invoices.entity_id%TYPE DEFAULT NULL
   ,p_organization_id            IN cll_f189_invoices.organization_id%TYPE DEFAULT NULL
   ,p_location_id                IN cll_f189_invoices.location_id%TYPE DEFAULT NULL
   ,p_ir_base                    IN cll_f189_invoices.ir_base%TYPE DEFAULT NULL
   ,p_ir_tax                     IN cll_f189_invoices.ir_tax%TYPE DEFAULT NULL
   ,p_accumulate_date            IN DATE DEFAULT NULL
   ,p_irrf_withhold_invoice_id   IN OUT NOCOPY cll_f189_invoices.irrf_withhold_invoice_id%TYPE
   ,p_ir_amount                  OUT NOCOPY cll_f189_invoices.ir_amount%TYPE
  ) IS
    l_withhold_invoice   NUMBER;
    l_base               NUMBER := 0;
    l_imposto            NUMBER := 0;
    l_base_retida        NUMBER := 0;
    l_base_reter         NUMBER := 0;
    l_imposto_retido     NUMBER := 0;
    l_imposto_reter      NUMBER := 0;
    l_module_name CONSTANT VARCHAR2 (100) := 'XXFR_F189_OPEN_PROCESSES_PUB.BASE_ACCUMULATE_IRRF' ;
    --
    CURSOR irrf1 IS
        SELECT DECODE (rit.credit_debit_flag,
                       'D',
                       NVL (ri.ir_base, 0),
                       'C',
                       NVL (ri.ir_base, 0) * -1)    ir_base
               ,ri.irrf_withhold_invoice_id
               ,DECODE (rit.credit_debit_flag,
                        'D',
                        ROUND ( (NVL (ri.ir_base, 0) * NVL (ri.ir_tax, 0) / 100),2),
                        'C',
                        ROUND (NVL (ri.ir_amount, 0) * (-1), 2))   ir_amount
          FROM cll_f189_entry_operations reo,
               cll_f189_invoices         ri,
               cll_f189_invoice_types    rit
         WHERE reo.operation_id             = ri.operation_id
           AND reo.organization_id          = ri.organization_id
           AND reo.location_id              = ri.location_id
           AND reo.status IN ('COMPLETE', 'IN PROCESS')
           AND ri.invoice_type_id           = rit.invoice_type_id
           AND ri.entity_id                 = p_entity_id
           AND ri.organization_id           = p_organization_id
           AND ri.location_id               = p_location_id
           AND TRUNC(ri.first_payment_date) = TRUNC(p_accumulate_date);
    --
    CURSOR irrf2 IS
        SELECT DECODE (rit.credit_debit_flag,
                       'D',
                       NVL (ri.ir_base, 0),
                       'C',
                       NVL (ri.ir_base, 0) * -1)    ir_base
              ,ri.irrf_withhold_invoice_id
              ,DECODE (rit.credit_debit_flag,
                       'D',
                       ROUND ( (NVL (ri.ir_base, 0) * NVL (ri.ir_tax, 0) / 100),2),
                       'C',
                       ROUND (NVL (ri.ir_amount, 0) * (-1), 2))     ir_amount
          FROM cll_f189_entry_operations reo,
               cll_f189_invoices         ri,
               cll_f189_invoice_types    rit
         WHERE reo.operation_id    = ri.operation_id
           AND reo.organization_id = ri.organization_id
           AND reo.location_id     = ri.location_id
           AND reo.status IN ('COMPLETE', 'IN PROCESS')
           AND ri.invoice_type_id  = rit.invoice_type_id
           AND ri.entity_id        = p_entity_id
           AND ri.organization_id  = p_organization_id
           AND ri.location_id      = p_location_id
           AND TRUNC(reo.gl_date)  = TRUNC(p_accumulate_date);
    --
    CURSOR irrf4 IS
        SELECT DECODE (rit.credit_debit_flag,
                       'D',
                       NVL (ri.ir_base, 0),
                       'C',
                       NVL (ri.ir_base, 0) * -1)    ir_base
              ,ri.irrf_withhold_invoice_id
              ,DECODE (rit.credit_debit_flag,
                       'D',
                       ROUND ( (NVL (ri.ir_base, 0) * NVL (ri.ir_tax, 0) / 100),2),
                       'C',
                       ROUND (NVL (ri.ir_amount, 0) * (-1), 2))     ir_amount
          FROM cll_f189_entry_operations reo,
               cll_f189_invoices         ri,
               cll_f189_invoice_types    rit
         WHERE reo.operation_id    = ri.operation_id
           AND reo.organization_id = ri.organization_id
           AND reo.location_id     = ri.location_id
           AND reo.status IN ('COMPLETE', 'IN PROCESS')
           AND ri.invoice_type_id  = rit.invoice_type_id
           AND ri.entity_id        = p_entity_id
           AND ri.organization_id  = p_organization_id
           AND ri.location_id      = p_location_id;
    --
    CURSOR irrf5 IS
        SELECT DECODE (rit.credit_debit_flag,
                       'D',
                       NVL (ri.ir_base, 0),
                       'C',
                       NVL (ri.ir_base, 0) * -1)    ir_base
              ,ri.irrf_withhold_invoice_id
              ,DECODE (rit.credit_debit_flag,
                       'D',
                       ROUND ( (NVL (ri.ir_base, 0) * NVL (ri.ir_tax, 0) / 100),2),
                       'C',
                       ROUND (NVL (ri.ir_amount, 0) * (-1), 2))     ir_amount
          FROM cll_f189_entry_operations reo,
               cll_f189_invoices         ri,
               cll_f189_invoice_types    rit
         WHERE reo.operation_id                        = ri.operation_id
           AND reo.organization_id                     = ri.organization_id
           AND reo.location_id                         = ri.location_id
           AND reo.status IN ('COMPLETE', 'IN PROCESS')
           AND ri.invoice_type_id                      = rit.invoice_type_id
           AND ri.entity_id                            = p_entity_id
           AND ri.organization_id                      = p_organization_id
           AND ri.location_id                          = p_location_id
           AND TO_CHAR(ri.first_payment_date,'MMYYYY') = TO_CHAR(p_accumulate_date,'MMYYYY');
    --
    CURSOR irrf6 IS
        SELECT DECODE (rit.credit_debit_flag,
                       'D',
                       NVL (ri.ir_base, 0),
                       'C',
                       NVL (ri.ir_base, 0) * -1)         ir_base
              ,ri.irrf_withhold_invoice_id
              ,DECODE (rit.credit_debit_flag,
                       'D',
                       ROUND ( (NVL (ri.ir_base, 0) * NVL (ri.ir_tax, 0) / 100),2),
                       'C',
                       ROUND (NVL (ri.ir_amount, 0) * (-1), 2))         ir_amount
          FROM cll_f189_entry_operations reo,
               cll_f189_invoices         ri,
               cll_f189_invoice_types    rit
         WHERE reo.operation_id              = ri.operation_id
           AND reo.organization_id           = ri.organization_id
           AND reo.location_id               = ri.location_id
           AND reo.status IN ('COMPLETE', 'IN PROCESS')
           AND ri.invoice_type_id            = rit.invoice_type_id
           AND ri.entity_id                  = p_entity_id
           AND ri.organization_id            = p_organization_id
           AND ri.location_id                = p_location_id
           AND TO_CHAR(reo.gl_date,'MMYYYY') = TO_CHAR (p_accumulate_date,'MMYYYY');
    --
    CURSOR irrf7 IS
        SELECT DECODE (rit.credit_debit_flag,
                       'D',
                       NVL (ri.ir_base, 0),
                       'C',
                       NVL (ri.ir_base, 0) * -1)        ir_base
               ,ri.irrf_withhold_invoice_id
               ,DECODE (rit.credit_debit_flag,
                       'D',
                       ROUND ( (NVL (ri.ir_base, 0) * NVL (ri.ir_tax, 0) / 100),2),
                       'C',
                       ROUND (NVL (ri.ir_amount, 0) * (-1), 2))     ir_amount
          FROM cll_f189_entry_operations reo,
               cll_f189_invoices         ri,
               cll_f189_invoice_types    rit
         WHERE reo.operation_id                    = ri.operation_id
           AND reo.organization_id                 = ri.organization_id
           AND reo.location_id                     = ri.location_id
           AND reo.status IN ('COMPLETE', 'IN PROCESS')
           AND ri.invoice_type_id                  = rit.invoice_type_id
           AND ri.entity_id                        = p_entity_id
           AND ri.organization_id                  = p_organization_id
           AND ri.location_id                      = p_location_id
           AND TO_CHAR(reo.receive_date, 'MMYYYY') = TO_CHAR (p_accumulate_date, 'mmyyyy'); --TO_CHAR(:cg$ctrl.dsp_receive_date,'mmyyyy')
  --
  BEGIN
    print_log('  BASE_ACCUMULATE_IRRF');
    IF (p_accumulate_type = 1) THEN
      OPEN irrf1;
      LOOP
        FETCH irrf1
        INTO l_base, l_withhold_invoice, l_imposto;
        --
        EXIT WHEN irrf1%NOTFOUND;
        --
        IF (l_withhold_invoice IS NOT NULL) THEN
          IF (l_withhold_invoice = p_invoice_id) THEN
            l_base_reter    := l_base_reter + l_base;
            l_imposto_reter := l_imposto_reter + l_imposto;
          ELSE
            l_base_retida    := l_base_retida + l_base;
            l_imposto_retido := l_imposto_retido + l_imposto;
          END IF;
        ELSE
          l_base_reter    := l_base_reter + l_base;
          l_imposto_reter := l_imposto_reter + l_imposto;
        END IF;
      END LOOP;
      --
      CLOSE irrf1;
      --
    ELSIF (p_accumulate_type = 2) THEN
      OPEN irrf2;
      LOOP
        FETCH irrf2
        INTO l_base, l_withhold_invoice, l_imposto;
        --
        EXIT WHEN irrf2%NOTFOUND;
        --
        IF (l_withhold_invoice IS NOT NULL) THEN
          IF (l_withhold_invoice = p_invoice_id) THEN
            l_base_reter    := l_base_reter + l_base;
            l_imposto_reter := l_imposto_reter + l_imposto;
          ELSE
            l_base_retida    := l_base_retida + l_base;
            l_imposto_retido := l_imposto_retido + l_imposto;
          END IF;
        ELSE
          l_base_reter    := l_base_reter + l_base;
          l_imposto_reter := l_imposto_reter + l_imposto;
        END IF;
      END LOOP;
      --
      CLOSE irrf2;
      --
    ELSIF (p_accumulate_type = 3) THEN
        NULL;
    ELSIF (p_accumulate_type = 4) THEN
      OPEN irrf4;
      LOOP
        FETCH irrf4
        INTO l_base, l_withhold_invoice, l_imposto;
        --
        EXIT WHEN irrf4%NOTFOUND;
        --
        IF (l_withhold_invoice IS NOT NULL) THEN
          IF (l_withhold_invoice = p_invoice_id) THEN
            l_base_reter    := l_base_reter + l_base;
            l_imposto_reter := l_imposto_reter + l_imposto;
          ELSE
            l_base_retida    := l_base_retida + l_base;
            l_imposto_retido := l_imposto_retido + l_imposto;
          END IF;
        ELSE
          l_base_reter    := l_base_reter + l_base;
          l_imposto_reter := l_imposto_reter + l_imposto;
        END IF;
      END LOOP;
      --
      CLOSE irrf4;
      --
    ELSIF (p_accumulate_type = 5) THEN
      OPEN irrf5;
      LOOP
        FETCH irrf5
        INTO l_base, l_withhold_invoice, l_imposto;
        --
        EXIT WHEN irrf5%NOTFOUND;
        --
        IF (l_withhold_invoice IS NOT NULL) THEN
          IF (l_withhold_invoice = p_invoice_id) THEN
            l_base_reter    := l_base_reter + l_base;
            l_imposto_reter := l_imposto_reter + l_imposto;
          ELSE
            l_base_retida    := l_base_retida + l_base;
            l_imposto_retido := l_imposto_retido + l_imposto;
          END IF;
        ELSE
          l_base_reter    := l_base_reter + l_base;
          l_imposto_reter := l_imposto_reter + l_imposto;
        END IF;
      END LOOP;
      --
      CLOSE irrf5;
      --
    ELSIF (p_accumulate_type = 6) THEN
      OPEN irrf6;
      LOOP
        FETCH irrf6
        INTO l_base, l_withhold_invoice, l_imposto;
        --
        EXIT WHEN irrf6%NOTFOUND;
        --
        IF (l_withhold_invoice IS NOT NULL) THEN
          IF (l_withhold_invoice = p_invoice_id) THEN
            l_base_reter    := l_base_reter + l_base;
            l_imposto_reter := l_imposto_reter + l_imposto;
          ELSE
            l_base_retida    := l_base_retida + l_base;
            l_imposto_retido := l_imposto_retido + l_imposto;
          END IF;
        ELSE
          l_base_reter    := l_base_reter + l_base;
          l_imposto_reter := l_imposto_reter + l_imposto;
        END IF;
      END LOOP;
      --
      CLOSE irrf6;
      --
    ELSIF (p_accumulate_type = 7) THEN
      OPEN irrf7;
      LOOP
        FETCH irrf7
        INTO l_base, l_withhold_invoice, l_imposto;
        --
        EXIT WHEN irrf7%NOTFOUND;
        --
        IF (l_withhold_invoice IS NOT NULL) THEN
          IF (l_withhold_invoice = p_invoice_id) THEN
            l_base_reter    := l_base_reter + l_base;
            l_imposto_reter := l_imposto_reter + l_imposto;
          ELSE
            l_base_retida    := l_base_retida + l_base;
            l_imposto_retido := l_imposto_retido + l_imposto;
          END IF;
        ELSE
          l_base_reter    := l_base_reter + l_base;
          l_imposto_reter := l_imposto_reter + l_imposto;
        END IF;
      END LOOP;
      --
      CLOSE irrf7;
      --
    END IF;
    --
    l_base_reter    := l_base_reter + NVL (p_ir_base, 0);
    l_imposto_reter := l_imposto_reter + ROUND ( (NVL (p_ir_base, 0) * NVL (p_ir_tax, 0) / 100), 2);
    --
    IF (l_imposto_retido > 0) THEN
      p_ir_amount := ROUND ( (NVL (p_ir_base, 0) * NVL (p_ir_tax, 0) / 100), 2);
    ELSE
      IF (l_imposto_reter >= p_minimun_value)THEN
        p_ir_amount := l_imposto_reter;
      ELSE
        IF (p_accumulate_type <> 0) THEN
          p_irrf_withhold_invoice_id := NULL;
          p_ir_amount                := 0;
        ELSE
          p_ir_amount := l_imposto_reter;
        END IF;
      END IF;
    END IF;
    print_log('  FIM BASE_ACCUMULATE_IRRF');
  END BASE_ACCUMULATE_IRRF;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:    UPDATE_IRRF_WITHHOLD_INVOICE                               |
  |                                                                          |
  | Description: Responsavel por calcular e retornar os valores do IRRF      |
  |              Retido                                                      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE UPDATE_IRRF_WITHHOLD_INVOICE (p_accumulate_type   IN cll_f189_tax_sites.cumulative_threshold_type%TYPE DEFAULT NULL
                                         ,p_minimun_value     IN cll_f189_tax_sites.minimum_tax_amount%TYPE DEFAULT NULL
                                         ,p_invoice_id        IN cll_f189_invoices.invoice_id%TYPE DEFAULT NULL
                                         ,p_entity_id         IN cll_f189_invoices.entity_id%TYPE DEFAULT NULL
                                         ,p_organization_id   IN cll_f189_invoices.organization_id%TYPE DEFAULT NULL
                                         ,p_location_id       IN cll_f189_invoices.location_id%TYPE DEFAULT NULL
                                         ,p_accumulate_date   IN DATE DEFAULT NULL
                                         ) IS
    l_withhold_invoice      NUMBER := NULL;
    l_module_name  CONSTANT VARCHAR2 (100):= 'XXFR_F189_OPEN_PROCESSES_PUB.UPDATE_IRRF_WITHHOLD_INVOICE' ;
    --
    CURSOR irrf1 IS
            SELECT ri.irrf_withhold_invoice_id
              FROM cll_f189_entry_operations reo
                  ,cll_f189_invoices         ri
             WHERE reo.operation_id             = ri.operation_id
               AND reo.organization_id          = ri.organization_id
               AND reo.location_id              = ri.location_id
               AND ri.entity_id                 = p_entity_id
               AND ri.organization_id           = p_organization_id
               AND ri.location_id               = p_location_id
               AND reo.status IN ('COMPLETE', 'IN PROCESS')
               AND TRUNC(ri.first_payment_date) = TRUNC(p_accumulate_date)
        FOR UPDATE OF ri.irrf_withhold_invoice_id NOWAIT;
    --
    CURSOR irrf2 IS
            SELECT ri.irrf_withhold_invoice_id
              FROM cll_f189_entry_operations reo
                  ,cll_f189_invoices         ri
             WHERE reo.operation_id    = ri.operation_id
               AND reo.organization_id = ri.organization_id
               AND reo.location_id     = ri.location_id
               AND ri.entity_id        = p_entity_id
               AND ri.organization_id  = p_organization_id
               AND ri.location_id      = p_location_id
               AND reo.status IN ('COMPLETE', 'IN PROCESS')
               AND TRUNC(reo.gl_date)  = TRUNC(p_accumulate_date)
        FOR UPDATE OF ri.irrf_withhold_invoice_id NOWAIT;
    --
    CURSOR irrf4 IS
            SELECT ri.irrf_withhold_invoice_id
              FROM cll_f189_entry_operations reo
                  ,cll_f189_invoices         ri
             WHERE reo.operation_id    = ri.operation_id
               AND reo.organization_id = ri.organization_id
               AND reo.location_id     = ri.location_id
               AND ri.entity_id        = p_entity_id
               AND ri.organization_id  = p_organization_id
               AND ri.location_id      = p_location_id
               AND reo.status IN ('COMPLETE', 'IN PROCESS')
        FOR UPDATE OF ri.irrf_withhold_invoice_id NOWAIT;
    --
    CURSOR irrf5 IS
            SELECT ri.irrf_withhold_invoice_id
              FROM cll_f189_entry_operations reo, cll_f189_invoices ri
             WHERE reo.operation_id    = ri.operation_id
               AND reo.organization_id = ri.organization_id
               AND reo.location_id     = ri.location_id
               AND ri.entity_id        = p_entity_id
               AND ri.organization_id  = p_organization_id
               AND ri.location_id      = p_location_id
               AND reo.status IN ('COMPLETE', 'IN PROCESS')
               AND TO_CHAR(ri.first_payment_date, 'MMYYYY') = TO_CHAR(p_accumulate_date, 'MMYYYY')
        FOR UPDATE OF ri.irrf_withhold_invoice_id NOWAIT;
    --
    CURSOR irrf6 IS
            SELECT ri.irrf_withhold_invoice_id
              FROM cll_f189_entry_operations reo
                  ,cll_f189_invoices         ri
             WHERE reo.operation_id    = ri.operation_id
               AND reo.organization_id = ri.organization_id
               AND reo.location_id     = ri.location_id
               AND ri.entity_id        = p_entity_id
               AND ri.organization_id  = p_organization_id
               AND ri.location_id      = p_location_id
               AND reo.status IN ('COMPLETE', 'IN PROCESS')
               AND TO_CHAR(reo.gl_date, 'MMYYYY') = TO_CHAR(p_accumulate_date, 'MMYYYY')
        FOR UPDATE OF ri.irrf_withhold_invoice_id NOWAIT;
    --
    CURSOR irrf7 IS
            SELECT ri.irrf_withhold_invoice_id
              FROM cll_f189_entry_operations reo, cll_f189_invoices ri
             WHERE reo.operation_id    = ri.operation_id
               AND reo.organization_id = ri.organization_id
               AND reo.location_id     = ri.location_id
               AND ri.entity_id        = p_entity_id
               AND ri.organization_id  = p_organization_id
               AND ri.location_id      = p_location_id
               AND TO_CHAR(reo.receive_date, 'MMYYYY') = TO_CHAR(p_accumulate_date, 'mmyyyy')
                     AND reo.status IN ('COMPLETE', 'IN PROCESS')
        FOR UPDATE OF ri.irrf_withhold_invoice_id NOWAIT;
  --
  BEGIN
    print_log('  UPDATE_IRRF_WITHHOLD_INVOICE');
    IF p_accumulate_type = 1 THEN
      OPEN irrf1;
      LOOP
        FETCH irrf1 INTO l_withhold_invoice;
        --
        EXIT WHEN irrf1%NOTFOUND;
        --
        IF (l_withhold_invoice IS NULL) THEN
          UPDATE cll_f189_invoices
          SET irrf_withhold_invoice_id = p_invoice_id
          WHERE CURRENT OF irrf1;
        END IF;
      END LOOP;
      --
      CLOSE irrf1;
      --
    ELSIF p_accumulate_type = 2 THEN
      OPEN irrf2;
      LOOP
        FETCH irrf2 INTO l_withhold_invoice;
        --
        EXIT WHEN irrf2%NOTFOUND;
        --
        IF (l_withhold_invoice IS NULL) THEN
          UPDATE cll_f189_invoices
          SET irrf_withhold_invoice_id = p_invoice_id
          WHERE CURRENT OF irrf2;
        END IF;
      END LOOP;
      --
      CLOSE irrf2;
      --
    ELSIF p_accumulate_type = 3 THEN
      NULL;
    ELSIF p_accumulate_type = 4 THEN
      OPEN irrf4;
      LOOP
        FETCH irrf4 INTO l_withhold_invoice;
        --
        EXIT WHEN irrf4%NOTFOUND;
        --
        IF (l_withhold_invoice IS NULL) THEN
          UPDATE cll_f189_invoices
          SET irrf_withhold_invoice_id = p_invoice_id
          WHERE CURRENT OF irrf4;
        END IF;
      END LOOP;
      --
      CLOSE irrf4;
      --
    ELSIF p_accumulate_type = 5 THEN
      OPEN irrf5;
      LOOP
        FETCH irrf5 INTO l_withhold_invoice;
        --
        EXIT WHEN irrf5%NOTFOUND;
        --
        IF (l_withhold_invoice IS NULL) THEN
          UPDATE cll_f189_invoices
          SET irrf_withhold_invoice_id = p_invoice_id
          WHERE CURRENT OF irrf5;
        END IF;
      END LOOP;
      --
      CLOSE irrf5;
      --
    ELSIF p_accumulate_type = 6 THEN
      OPEN irrf6;
      LOOP
        FETCH irrf6 INTO l_withhold_invoice;
        --
        EXIT WHEN irrf6%NOTFOUND;
        --
        IF (l_withhold_invoice IS NULL) THEN
          UPDATE cll_f189_invoices
          SET irrf_withhold_invoice_id = p_invoice_id
          WHERE CURRENT OF irrf6;
        END IF;
      END LOOP;
      --
      CLOSE irrf6;
      --
    ELSIF p_accumulate_type = 7 THEN
      OPEN irrf7;
      LOOP
        FETCH irrf7 INTO l_withhold_invoice;
        --
        EXIT WHEN irrf7%NOTFOUND;
        --
        IF (l_withhold_invoice IS NULL) THEN
          UPDATE cll_f189_invoices
          SET irrf_withhold_invoice_id = p_invoice_id
          WHERE CURRENT OF irrf7;
        END IF;
      END LOOP;
      --
      CLOSE irrf7;
      --
    END IF;
    print_log('  FIM UPDATE_IRRF_WITHHOLD_INVOICE');
  END UPDATE_IRRF_WITHHOLD_INVOICE;
  --
  /*=========================================================================+
  |                                                                          |
  | Function:   SET_PROCESS_FLAG                                             |
  |                                                                          |
  | Description: Responsavel por atualizar o flag de processamento na open   |
  |              com o status correspondente ao registro processado          |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE SET_PROCESS_FLAG (
    p_process_flag             IN NUMBER
    ,p_interface_invoice_id    IN NUMBER
  ) IS
    --
    l_module_name       CONSTANT VARCHAR2(100) := 'XXFR_F189_OPEN_PROCESSES_PUB.SET_PROCESS_FLAG';
    --
  BEGIN
    print_log('    SET_PROCESS_FLAG -->'||p_process_flag||' - Debug:'||l_debug);
    BEGIN
      UPDATE cll_f189_invoices_interface
      SET process_flag           = p_process_flag
      WHERE interface_invoice_id = p_interface_invoice_id;
      COMMIT;
    END;
    --
  END SET_PROCESS_FLAG;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   ADD_ERROR                                                   |
  |                                                                          |
  | Description: Responsavel por inserir a inconsistencia na tabela de erros |
  |              na tabela da Open Interface do RI                           |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE add_error ( 
    p_invoice_id               IN NUMBER
    , p_interface_operation_id IN NUMBER
    , p_organization_id        IN NUMBER
    , p_error_code             IN VARCHAR2
    , p_invoice_line_id        IN NUMBER
    , p_table_associated       IN NUMBER
    , p_invalid_value          IN VARCHAR2
  ) IS
    --
    l_module_name CONSTANT VARCHAR2 (100) := 'XXFR_F189_OPEN_PROCESSES_PUB.ADD_ERROR' ;
    l_error_message        VARCHAR2 (240);
    --
  BEGIN
    BEGIN
      SELECT description
      INTO l_error_message
      FROM fnd_lookup_values_vl
      WHERE 1=1
        and lookup_type = 'CLL_F189_INTERFACE_HOLD_REASON'
        AND lookup_code = p_error_code 
      ;
      print_log('    ADD_ERROR -> '||l_debug||' - Erro Code:'||p_error_code);
    EXCEPTION
      WHEN OTHERS THEN l_error_message := NULL;
    END;
    --
    BEGIN
      INSERT INTO cll_f189_interface_errors ( 
        interface_operation_id
        , interface_invoice_id
        , interface_invoice_line_id
        , error_code
        , error_message
        , source
        , table_associated
        , organization_id
        , creation_date
        , created_by
        , last_update_date
        , last_updated_by
        , request_id
        , program_id
        , program_application_id
        , program_update_date
        , invalid_value
      ) VALUES ( 
        p_interface_operation_id
        , p_invoice_id
        , NVL(p_invoice_line_id,0)
        , p_error_code
        , l_error_message
        , g_source
        , p_table_associated
        , p_organization_id
        , SYSDATE
        , fnd_global.user_id
        , SYSDATE
        , fnd_global.user_id
        , fnd_global.conc_request_id
        , fnd_global.conc_login_id
        , fnd_global.prog_appl_id
        , SYSDATE
        , p_invalid_value
      ) ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN NULL;
      WHEN DUP_VAL_ON_INDEX THEN NULL;
      WHEN OTHERS THEN NULL;
    END;
    --
    -- Dessa verificacao em diante e para que seja exibida o log por etapas, header, lines, frete, etc
    g_process_flag := 3;
    --
    IF p_error_code = 'NONE ORGANIZATION' OR p_error_code = 'NONE LOCATION' THEN
       NULL;
    ELSE
      DECLARE
        l_holds   NUMBER;
      BEGIN
        --
        -- Verifica se encontrou alguma hold customizada pelo cliente
        --
        l_holds := CLL_F189_HOLDS_CUSTOM_PKG.FUNC_HOLDS_CUSTOM (
          p_interface_operation_id
          ,p_organization_id
        );
        --
        BEGIN
          SELECT COUNT(*) INTO l_holds
          FROM cll_f189_interface_errors
          WHERE 1=1
          and interface_operation_id = p_interface_operation_id
          AND organization_id        = p_organization_id;
        EXCEPTION
          WHEN OTHERS THEN l_holds := 0;
        END;
        --
        IF l_holds > 0 THEN
          g_process_flag := 3;
        END IF;
      EXCEPTION WHEN OTHERS then
        print_log('*****  CLL_F189_HOLDS_CUSTOM_PKG.FUNC_HOLDS_CUSTOM');
      END;
    END IF;
  END add_error;
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_TPA_DEVOLUT                                     |
  |                                                                          |
  | Description: Responsible for validate information and insert into        |
  |              CLL F513 third Party transaction devolutions                |
  |              tables                                                      |
  |                                                                          |
  +=========================================================================*/
  --<< Enh 29907995 - RPRIMAO - 28/11/2019 - Start >>--
  PROCEDURE create_open_tpa_devolut ( p_type            IN VARCHAR2
                                    , p_tpadev          IN cll_f513_tpa_devolutions_ctrl%ROWTYPE
                                    , p_return_code    OUT NOCOPY VARCHAR2
                                    , p_return_message OUT NOCOPY VARCHAR2
                                    ) IS
  --
  l_rec_tpa_devol_ctrl      cll_f513_tpa_devolutions_ctrl              %ROWTYPE ;
  l_crec_tpa_devol_ctrl     cll_f513_tpa_devolutions_ctrl              %ROWTYPE ;
  l_cfo_code                cll_f189_fiscal_operations.cfo_code        %TYPE ;
  l_subinventory            cll_f513_tpa_receipts_control.subinventory %TYPE ;
  l_locator                 cll_f513_tpa_dev_iface.new_locator_code    %TYPE ;
  l_qtd_records             NUMBER ;
  l_qtd_rec_iface           NUMBER ;
  l_locator_id              NUMBER ; -- Enh 29907995 - 05/12
  l_msg_retorno             VARCHAR2(1000) ;
  --
  BEGIN
    print_log('  CREATE_OPEN_TPA_DEVOLUT');
    IF p_type = 'VALIDATE' THEN
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_rec_iface
          FROM cll_f513_tpa_dev_iface
         WHERE ( ( interface_invoice_id      = p_tpadev.devolution_invoice_id )
            OR   ( interface_invoice_line_id = p_tpadev.devolution_invoice_line_id ) ) ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_rec_iface:= NULL ;
      END ;
      --
/*    BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f189_interface_errors
         WHERE interface_invoice_id = p_tpadev.devolution_invoice_id
           AND error_code           = 'NO INVOICES DEVOLUTION' ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) = 0 THEN
        --
        BEGIN
          --
          SELECT COUNT(*)
            INTO l_qtd_records
            FROM ( SELECT cfil.interface_invoice_line_id
                        , SUM(cftd.quantity) devolution_quantity
                        , SUM(cfil.quantity) quantity
                     FROM cll_f189_invoice_lines_iface  cfil
                        , cll_f513_tpa_dev_iface        cftd
                    WHERE cftd.interface_invoice_id      (+) = cfil.interface_invoice_id
                      AND cftd.interface_invoice_line_id (+) = cfil.interface_invoice_line_id
                      AND cfil.interface_invoice_id          = p_tpadev.devolution_invoice_id
                    GROUP BY cfil.interface_invoice_line_id )
           WHERE NVL(devolution_quantity, 0) = 0 ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            l_qtd_records := NULL ;
        END ;
        --
        IF NVL(l_qtd_records, 0) > 0 THEN
          --
          ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                    , p_interface_operation_id => p_tpadev.devolution_operation_id
                    , p_organization_id        => p_tpadev.organization_id
                    , p_error_code             => 'NO INVOICES DEVOLUTION'
                    , p_invoice_line_id        => 0
                    , p_table_associated       => 6
                    , p_invalid_value          => NULL
                    ) ;
          --
          p_return_code    := 'E' ;
          p_return_message := 'NO INVOICES DEVOLUTION' ;
          --
        END IF ;
        --
      END IF ;
*/    --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f189_invoice_lines_iface  cfil
             , cll_f513_tpa_dev_iface        cftd
             , cll_f513_tpa_receipts_control cftdc
         WHERE cftd.interface_invoice_line_id = cfil.interface_invoice_line_id
           AND cftdc.tpa_receipts_control_id  = cftd.tpa_receipt_control_id
           AND cfil.item_id                  <> cftdc.inventory_item_id
           AND cfil.interface_invoice_id      = p_tpadev.devolution_invoice_id
           AND cfil.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) > 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'INV ITEM ASSOC FOR DEVOL'
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => NULL
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'INV ITEM ASSOC FOR DEVOL' ;
         --
      END IF ;
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f189_interface_errors
         WHERE interface_invoice_id = p_tpadev.devolution_invoice_id
           AND error_code           = 'INTERFACE LINEINVID NULL' ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) = 0 THEN
        --
        BEGIN
          --
          SELECT COUNT(*)
            INTO l_qtd_records
            FROM cll_f513_tpa_dev_iface
           WHERE interface_invoice_id      = p_tpadev.devolution_invoice_id
             AND interface_invoice_line_id IS NULL ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            l_qtd_records := NULL ;
        END ;
        --
        IF NVL(l_qtd_records, 0) > 0 THEN
          --
          ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                    , p_interface_operation_id => p_tpadev.devolution_operation_id
                    , p_organization_id        => p_tpadev.organization_id
                    , p_error_code             => 'INTERFACE LINEINVID NULL'
                    , p_invoice_line_id        => 0
                    , p_table_associated       => 6
                    , p_invalid_value          => NULL
                    ) ;
          --
          p_return_code    := 'E' ;
          p_return_message := 'INTERFACE LINEINVID NULL' ;
          --
        END IF ;
        --
      END IF ;
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f189_interface_errors
         WHERE interface_invoice_id = p_tpadev.devolution_invoice_id
           AND error_code           = 'INTERFACE INVID NULL' ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) = 0 THEN
        --
        BEGIN
          --
          SELECT COUNT(*)
            INTO l_qtd_records
            FROM cll_f513_tpa_dev_iface
           WHERE interface_invoice_line_id = p_tpadev.devolution_invoice_line_id
             AND interface_invoice_id      IS NULL ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            l_qtd_records := NULL ;
        END ;
        --
        IF NVL(l_qtd_records, 0) > 0 THEN
          --
          ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                    , p_interface_operation_id => p_tpadev.devolution_operation_id
                    , p_organization_id        => p_tpadev.organization_id
                    , p_error_code             => 'INTERFACE INVID NULL'
                    , p_invoice_line_id        => 0
                    , p_table_associated       => 6
                    , p_invalid_value          => NULL
                    ) ;
          --
          p_return_code    := 'E' ;
          p_return_message := 'INTERFACE INVID NULL' ;
          --
        END IF ;
        --
      END IF ;
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f189_interface_errors
         WHERE interface_invoice_id = p_tpadev.devolution_invoice_id
           AND error_code           = 'NULL TPA RECEIPT CTRL' ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) = 0 THEN
        --
        BEGIN
          --
          SELECT COUNT(*)
            INTO l_qtd_records
            FROM cll_f513_tpa_dev_iface
           WHERE ( ( interface_invoice_id      = p_tpadev.devolution_invoice_id )
              OR   ( interface_invoice_line_id = p_tpadev.devolution_invoice_line_id ) )
             AND tpa_receipt_control_id IS NULL ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            l_qtd_records := NULL ;
        END ;
        --
        IF NVL(l_qtd_records, 0) > 0 THEN
          --
          ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                    , p_interface_operation_id => p_tpadev.devolution_operation_id
                    , p_organization_id        => p_tpadev.organization_id
                    , p_error_code             => 'NULL TPA RECEIPT CTRL'
                    , p_invoice_line_id        => 0
                    , p_table_associated       => 6
                    , p_invalid_value          => NULL
                    ) ;
          --
          p_return_code    := 'E' ;
          p_return_message := 'NULL TPA RECEIPT CTRL' ;
          --
        END IF ;
        --
      END IF ;
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f189_invoices_interface   cfii
             , cll_f189_invoice_lines_iface  cfil
             , cll_f513_tpa_receipts_control cftrc
             , cll.cll_f513_tpa_dev_iface    cftd
             , cll_f189_fiscal_entities_all  cffe   -- BUG 30633489 13/12
             , hz_cust_site_uses_all         hcsua  -- BUG 30633489 13/12
         WHERE cfil.interface_invoice_id      = cfii.interface_invoice_id
           AND cftrc.organization_id          = cfii.organization_id
           AND cftrc.inventory_item_id        = cfil.item_id
           AND cftd.interface_invoice_line_id = cfil.interface_invoice_line_id
           AND cftrc.tpa_receipts_control_id  = cftd.tpa_receipt_control_id
           AND cffe.entity_id                 = cfii.entity_id            -- BUG 30633489 13/12
           AND cffe.cust_acct_site_id         = hcsua.cust_acct_site_id   -- BUG 30633489 13/12
           AND hcsua.site_use_id              = cftrc.ship_to_site_use_id -- BUG 30633489 13/12
           AND cfii.interface_invoice_id      = p_tpadev.devolution_invoice_id
           AND cfil.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) = 0 AND NVL(l_qtd_rec_iface, 0) > 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'INV RECEIPT ASSOC'		-- BUG 30633489 13/12
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => NULL
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'INV RECEIPT ASSOC' ;
         --
      END IF ;
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f189_interface_errors
         WHERE interface_invoice_id = p_tpadev.devolution_invoice_id
           AND error_code           = 'QUANTITY ASSOC NOT ENOUGH' ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) = 0 THEN
        --
        BEGIN
          --
          SELECT COUNT(*)
            INTO l_qtd_records
            FROM ( SELECT cftrc.tpa_receipts_control_id
                        , SUM(cftd.quantity) quantity
                        , cftrc.remaining_balance
                     FROM cll_f189_invoices_interface   cfii
                        , cll_f189_invoice_lines_iface  cfil
                        , cll_f513_tpa_receipts_control cftrc
                        , cll_f513_tpa_dev_iface        cftd
                    WHERE cfil.interface_invoice_id      = cfii.interface_invoice_id
                      AND cftrc.organization_id          = cfii.organization_id
                      AND cftrc.inventory_item_id        = cfil.item_id
                      AND cftd.interface_invoice_line_id = cfil.interface_invoice_line_id
                      AND cftrc.tpa_receipts_control_id  = cftd.tpa_receipt_control_id
                      AND cfii.interface_invoice_id      = p_tpadev.devolution_invoice_id
                    GROUP BY cftrc.tpa_receipts_control_id
                           , cftrc.remaining_balance )
           WHERE quantity > remaining_balance ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            l_qtd_records := NULL ;
        END ;
        --
        IF NVL(l_qtd_records, 0) > 0 THEN
          --
          ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                    , p_interface_operation_id => p_tpadev.devolution_operation_id
                    , p_organization_id        => p_tpadev.organization_id
                    , p_error_code             => 'QUANTITY ASSOC NOT ENOUGH'
                    , p_invoice_line_id        => 0
                    , p_table_associated       => 6
                    , p_invalid_value          => NULL
                    ) ;
          --
          p_return_code    := 'E' ;
          p_return_message := 'QUANTITY ASSOC NOT ENOUGH' ;
          --
        END IF ;
        --
      END IF ;
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM ( SELECT cfil.interface_invoice_line_id
                      , cfil.quantity
                      , SUM(cftd.quantity) qtd_assoc
                   FROM cll_f189_invoices_interface   cfii
                      , cll_f189_invoice_lines_iface  cfil
                      , cll_f513_tpa_receipts_control cftrc
                      , cll_f513_tpa_dev_iface        cftd
                  WHERE cfil.interface_invoice_id      = cfii.interface_invoice_id
                    AND cftrc.organization_id          = cfii.organization_id
                    AND cftrc.inventory_item_id        = cfil.item_id
                    AND cftd.interface_invoice_line_id = cfil.interface_invoice_line_id
                    AND cftrc.tpa_receipts_control_id  = cftd.tpa_receipt_control_id
                    AND cfii.interface_invoice_id      = p_tpadev.devolution_invoice_id
                    AND cfil.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id
                  GROUP BY cfil.interface_invoice_line_id
                      , cfil.quantity  )
         WHERE quantity <> qtd_assoc ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) > 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'INV QUANTITY ASSOC'
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => NULL
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'INV QUANTITY ASSOC' ;
         --
      END IF ;
      --
      BEGIN
        --
        SELECT cfo.cfo_code
          INTO l_cfo_code
          FROM cll_f189_invoice_lines_iface  cfil
             , cll_f189_fiscal_operations    cfo
         WHERE cfil.cfo_id                     = cfo.cfo_id
           AND NVL(cfo.tpa_control_type, 'x') <> 'DEVOLUTION_OF'
           AND cfil.interface_invoice_id      = p_tpadev.devolution_invoice_id
           AND cfil.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_cfo_code := NULL ;
      END ;
      --
      IF l_cfo_code IS NOT NULL THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'TPA INV DEVOLUTION CFOP'
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => l_cfo_code
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'TPA INV DEVOLUTION CFOP' ;
         --
      END IF ;
      --
      BEGIN
        --
        SELECT cftd.new_subinventory_code
          INTO l_subinventory
          FROM cll_f189_invoice_lines_iface  cfil
             , cll_f513_tpa_dev_iface        cftd
             , cll_f513_tpa_receipts_control cftdc
         WHERE cftd.interface_invoice_line_id = cfil.interface_invoice_line_id
           AND cftdc.tpa_receipts_control_id  = cftd.tpa_receipt_control_id
           AND cftdc.subinventory             IS NULL
           AND cftd.new_subinventory_code     IS NOT NULL
           AND cfil.interface_invoice_id      = p_tpadev.devolution_invoice_id
           AND cfil.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id
           AND ROWNUM                         = 1 ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_subinventory := NULL ;
      END ;
      --
      IF l_subinventory IS NOT NULL THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'RECEIPT CONTROL NO STOCK'
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => l_subinventory
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'RECEIPT CONTROL NO STOCK' ;
         --
      END IF ;
      --
      BEGIN
        --
        SELECT cftd.new_subinventory_code
          INTO l_subinventory
          FROM cll_f513_tpa_dev_iface     cftd
             , mtl_secondary_inventories  msi
         WHERE msi.secondary_inventory_name (+) = cftd.new_subinventory_code
           AND msi.organization_id          (+) = p_tpadev.organization_id
		   AND TRUNC(NVL(msi.disable_date   (+), SYSDATE)) >= TRUNC(SYSDATE) -- BUG 30633489
           AND cftd.interface_invoice_id        = p_tpadev.devolution_invoice_id
           AND cftd.interface_invoice_line_id   = p_tpadev.devolution_invoice_line_id
           AND cftd.new_subinventory_code       IS NOT NULL
           AND msi.secondary_inventory_name     IS NULL
           AND ROWNUM                           = 1 ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_subinventory := NULL ;
      END ;
      --
      IF l_subinventory IS NOT NULL THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'INV SUBINVENTORY CODE'
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => l_subinventory
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'INV SUBINVENTORY CODE' ;
         --
      END IF ;
      --
      BEGIN
        --
        SELECT NVL(new_locator_code, TO_CHAR(new_locator_id))
          INTO l_locator
          FROM cll_f513_tpa_dev_iface cftd
         WHERE cftd.interface_invoice_id      = p_tpadev.devolution_invoice_id
           AND cftd.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id
           AND ( ( new_locator_id   IS NOT NULL
            OR     new_locator_code IS NOT NULL )
           AND new_subinventory_code IS NULL )
           AND ROWNUM = 1 ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_locator := NULL ;
      END ;
      --
      IF l_locator IS NOT NULL THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'LOCATION FILLED INV'
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => l_locator
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'LOCATION FILLED INV' ;
         --
      END IF ;
      --
      FOR r_locators IN ( SELECT ROWID linha
                               , cftd.new_locator_id
                               , cftd.new_locator_code
                               , cftd.new_subinventory_code
                            FROM cll_f513_tpa_dev_iface cftd
                           WHERE cftd.interface_invoice_id      = p_tpadev.devolution_invoice_id
                             AND cftd.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id
                             AND ( cftd.new_locator_id    IS NOT NULL
                              OR   cftd.new_locator_code  IS NOT NULL ) ) LOOP
        --
        -- Enh 29907995 - 05/12 - Start
        --
        l_locator_id := NULL ;
        --
        IF r_locators.new_locator_id IS NOT NULL THEN
          --
          BEGIN
            --
            SELECT COUNT(*)
              INTO l_qtd_records
              FROM mtl_item_locations     mic
                 , mtl_item_locations_kfv mic_kfv
             WHERE mic.inventory_location_id = mic_kfv.inventory_location_id
               AND mic.organization_id       = p_tpadev.organization_id
               AND mic.subinventory_code     = r_locators.new_subinventory_code
               AND mic.inventory_location_id = r_locators.new_locator_id ;
            --
          EXCEPTION
            WHEN OTHERS THEN
              l_qtd_records := NULL ;
          END ;
          --
        ELSE
          --
          BEGIN
            --
            SELECT mic.inventory_location_id
              INTO l_locator_id
              FROM mtl_item_locations     mic
                 , mtl_item_locations_kfv mic_kfv
             WHERE mic.inventory_location_id     = mic_kfv.inventory_location_id
               AND mic.organization_id           = p_tpadev.organization_id
               AND mic.subinventory_code         = r_locators.new_subinventory_code
               AND mic_kfv.concatenated_segments = r_locators.new_locator_code ;
            --
          EXCEPTION
            WHEN OTHERS THEN
              l_qtd_records := NULL ;
              l_locator_id  := NULL ;
          END ;
          --
        END IF ;
        --
        IF NVL(l_qtd_records, 0) = 0 AND NVL(l_locator_id, 0) = 0 THEN
          --
          ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                    , p_interface_operation_id => p_tpadev.devolution_operation_id
                    , p_organization_id        => p_tpadev.organization_id
                    , p_error_code             => 'INVALID LOCATOR'
                    , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                    , p_table_associated       => 6
                    , p_invalid_value          => NVL(TO_CHAR(r_locators.new_locator_id), r_locators.new_locator_code)
                    ) ;
           --
           p_return_code    := 'E' ;
           p_return_message := 'INVALID LOCATOR' ;
           --
           EXIT ;
           --
        ELSE
           --
           IF l_locator_id IS NOT NULL THEN
             --
             UPDATE cll_f513_tpa_dev_iface
                SET new_locator_id = l_locator_id
              WHERE ROWID = r_locators.linha ;
             --
           END IF ;
           --
        END IF ;
        --
        -- Enh 29907995 - 05/12 - End
        --
      END LOOP ;
      --
      BEGIN
        --
        SELECT COUNT(DISTINCT NVL(symbolic_devolution_flag, 'N'))
          INTO l_qtd_records
          FROM cll_f513_tpa_dev_iface cftd
         WHERE cftd.interface_invoice_id      = p_tpadev.devolution_invoice_id
           AND cftd.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) > 1 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'INVALID SYMBOLIC DEVOLV TYPE'
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => NULL
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'INVALID SYMBOLIC DEVOLV TYPE' ;
         --
      END IF ;
      --
      BEGIN
        --
        SELECT COUNT(*)
          INTO l_qtd_records
          FROM cll_f513_tpa_dev_iface cftd
         WHERE cftd.interface_invoice_id      = p_tpadev.devolution_invoice_id
           AND cftd.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          l_qtd_records := NULL ;
      END ;
      --
      IF NVL(l_qtd_records, 0) = 0 THEN
        --
        ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                  , p_interface_operation_id => p_tpadev.devolution_operation_id
                  , p_organization_id        => p_tpadev.organization_id
                  , p_error_code             => 'TPA RETURN REQUIRED'
                  , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                  , p_table_associated       => 6
                  , p_invalid_value          => NULL
                  ) ;
         --
         p_return_code    := 'E' ;
         p_return_message := 'TPA RETURN REQUIRED' ;
         --
      ELSE
        --
        BEGIN
          --
          SELECT cfo.cfo_code
            INTO l_cfo_code
            FROM cll_f189_invoice_lines_iface cfil
               , cll_f189_fiscal_operations   cfo
           WHERE cfil.cfo_id                     = cfo.cfo_id
             AND NVL(cfo.tpa_control_type, 'x') <> 'DEVOLUTION_OF'
             AND cfil.interface_invoice_id      = p_tpadev.devolution_invoice_id
             AND cfil.interface_invoice_line_id = p_tpadev.devolution_invoice_line_id ;
          --
        EXCEPTION
          WHEN OTHERS THEN
            l_cfo_code := NULL ;
        END ;
        --
        IF l_cfo_code IS NOT NULL THEN
          --
          ADD_ERROR ( p_invoice_id             => p_tpadev.devolution_invoice_id
                    , p_interface_operation_id => p_tpadev.devolution_operation_id
                    , p_organization_id        => p_tpadev.organization_id
                    , p_error_code             => 'CFOP DEVOL ASSOC INV'
                    , p_invoice_line_id        => p_tpadev.devolution_invoice_line_id
                    , p_table_associated       => 6
                    , p_invalid_value          => l_cfo_code
                    ) ;
           --
           p_return_code    := 'E' ;
           p_return_message := 'CFOP DEVOL ASSOC INV' ;
           --
        END IF ;
        --
      END IF ;
      --
    ELSIF p_type = 'INSERT' THEN
      --
      l_rec_tpa_devol_ctrl := l_crec_tpa_devol_ctrl ;
      --
      l_rec_tpa_devol_ctrl.tpa_devolutions_control_id := p_tpadev.tpa_devolutions_control_id ;
      l_rec_tpa_devol_ctrl.tpa_receipts_control_id    := p_tpadev.tpa_receipts_control_id ;
      l_rec_tpa_devol_ctrl.devolution_operation_id    := p_tpadev.devolution_operation_id ;
      l_rec_tpa_devol_ctrl.devolution_status          := p_tpadev.devolution_status ;
      l_rec_tpa_devol_ctrl.org_id                     := p_tpadev.org_id ;
      l_rec_tpa_devol_ctrl.organization_id            := p_tpadev.organization_id ;
      l_rec_tpa_devol_ctrl.devolution_entity_id       := p_tpadev.devolution_entity_id ;
      l_rec_tpa_devol_ctrl.devolution_invoice_id      := p_tpadev.devolution_invoice_id ;
      l_rec_tpa_devol_ctrl.devolution_invoice_line_id := p_tpadev.devolution_invoice_line_id ;
      l_rec_tpa_devol_ctrl.devolution_item_number     := p_tpadev.devolution_item_number ;
      l_rec_tpa_devol_ctrl.cust_trx_type_id           := p_tpadev.cust_trx_type_id ;
      l_rec_tpa_devol_ctrl.customer_trx_id            := p_tpadev.customer_trx_id ;
      l_rec_tpa_devol_ctrl.ship_to_site_use_id        := p_tpadev.ship_to_site_use_id ;
      l_rec_tpa_devol_ctrl.customer_trx_line_id       := p_tpadev.customer_trx_line_id ;
      l_rec_tpa_devol_ctrl.trx_number                 := p_tpadev.trx_number ;
      l_rec_tpa_devol_ctrl.trx_date                   := p_tpadev.trx_date ;
      l_rec_tpa_devol_ctrl.sefaz_authorization_date   := p_tpadev.sefaz_authorization_date ;
      l_rec_tpa_devol_ctrl.devolution_date            := p_tpadev.devolution_date ;
      l_rec_tpa_devol_ctrl.inventory_item_id          := p_tpadev.inventory_item_id ;
      l_rec_tpa_devol_ctrl.item_uom_code              := p_tpadev.item_uom_code ;
      l_rec_tpa_devol_ctrl.unit_price                 := p_tpadev.unit_price ;
      l_rec_tpa_devol_ctrl.devolution_quantity        := p_tpadev.devolution_quantity ;
      l_rec_tpa_devol_ctrl.subinventory               := p_tpadev.subinventory ;
      l_rec_tpa_devol_ctrl.locator_id                 := p_tpadev.locator_id ;
      l_rec_tpa_devol_ctrl.parent_lot_number          := p_tpadev.parent_lot_number ;
      l_rec_tpa_devol_ctrl.lot_number                 := p_tpadev.lot_number ;
      l_rec_tpa_devol_ctrl.expiration_date            := p_tpadev.expiration_date ;
      l_rec_tpa_devol_ctrl.serial_number              := p_tpadev.serial_number ;
      l_rec_tpa_devol_ctrl.receipt_transaction_id     := p_tpadev.receipt_transaction_id ;
      l_rec_tpa_devol_ctrl.devolution_account_id      := p_tpadev.devolution_account_id ;
      l_rec_tpa_devol_ctrl.symbolic_devolution_flag   := p_tpadev.symbolic_devolution_flag ;
      l_rec_tpa_devol_ctrl.devolution_transaction_id  := p_tpadev.devolution_transaction_id ;
      l_rec_tpa_devol_ctrl.cancel_transaction_id      := p_tpadev.cancel_transaction_id ;
      l_rec_tpa_devol_ctrl.cancel_flag                := p_tpadev.cancel_flag ;
      l_rec_tpa_devol_ctrl.attribute_category         := p_tpadev.attribute_category ;
      l_rec_tpa_devol_ctrl.attribute1                 := p_tpadev.attribute1 ;
      l_rec_tpa_devol_ctrl.attribute2                 := p_tpadev.attribute2 ;
      l_rec_tpa_devol_ctrl.attribute3                 := p_tpadev.attribute3 ;
      l_rec_tpa_devol_ctrl.attribute4                 := p_tpadev.attribute4 ;
      l_rec_tpa_devol_ctrl.attribute5                 := p_tpadev.attribute5 ;
      l_rec_tpa_devol_ctrl.attribute6                 := p_tpadev.attribute6 ;
      l_rec_tpa_devol_ctrl.attribute7                 := p_tpadev.attribute7 ;
      l_rec_tpa_devol_ctrl.attribute8                 := p_tpadev.attribute8 ;
      l_rec_tpa_devol_ctrl.attribute9                 := p_tpadev.attribute9 ;
      l_rec_tpa_devol_ctrl.attribute10                := p_tpadev.attribute10 ;
      l_rec_tpa_devol_ctrl.attribute11                := p_tpadev.attribute11 ;
      l_rec_tpa_devol_ctrl.attribute12                := p_tpadev.attribute12 ;
      l_rec_tpa_devol_ctrl.attribute13                := p_tpadev.attribute13 ;
      l_rec_tpa_devol_ctrl.attribute14                := p_tpadev.attribute14 ;
      l_rec_tpa_devol_ctrl.attribute15                := p_tpadev.attribute15 ;
      l_rec_tpa_devol_ctrl.attribute16                := p_tpadev.attribute16 ;
      l_rec_tpa_devol_ctrl.attribute17                := p_tpadev.attribute17 ;
      l_rec_tpa_devol_ctrl.attribute18                := p_tpadev.attribute18 ;
      l_rec_tpa_devol_ctrl.attribute19                := p_tpadev.attribute19 ;
      l_rec_tpa_devol_ctrl.attribute20                := p_tpadev.attribute20 ;
      l_rec_tpa_devol_ctrl.created_by                 := p_tpadev.created_by ;
      l_rec_tpa_devol_ctrl.creation_date              := p_tpadev.creation_date ;
      l_rec_tpa_devol_ctrl.last_update_date           := p_tpadev.last_update_date ;
      l_rec_tpa_devol_ctrl.last_updated_by            := p_tpadev.last_updated_by ;
      l_rec_tpa_devol_ctrl.last_update_login          := p_tpadev.last_update_login ;
      l_rec_tpa_devol_ctrl.request_id                 := p_tpadev.request_id ;
      l_rec_tpa_devol_ctrl.program_application_id     := p_tpadev.program_application_id ;
      l_rec_tpa_devol_ctrl.program_id                 := p_tpadev.program_id ;
      l_rec_tpa_devol_ctrl.program_update_date        := p_tpadev.program_update_date ;
      l_rec_tpa_devol_ctrl.available_for_devolution   := p_tpadev.available_for_devolution ;
      l_msg_retorno                                   := NULL ;
      --
      cll_f513_utility_pkg.insert_tpa_devol_ctrl_p ( l_rec_tpa_devol_ctrl, l_msg_retorno ) ;
      --
    END IF ;
    print_log('FIM CREATE_OPEN_TPA_DEVOLUT');
  END create_open_tpa_devolut ;
  --
END XXFR_F189_OPEN_PROCESSES_PUB ;
