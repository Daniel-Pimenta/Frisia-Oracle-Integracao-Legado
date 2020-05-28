create or replace PACKAGE XXFR_F189_OPEN_PROCESSES_PUB AS
  /* $Header: CLLPRICS.pls 120.38 2019/12/04 13:15:46 sasimoes noship $ */
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_INTERFACE                                       |
  |                                                                          |
  | Description: Responsavel por iniciar o processamento e fazer a chamada   |
  |              das procedures responsaveis pelas validacoes e inserts      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OPEN_INTERFACE(p_open_source          IN VARCHAR2,
                                  p_source               IN VARCHAR2,
                                  p_interface_invoice_id IN NUMBER,
                                  p_approve              IN VARCHAR2,
                                  p_delete_line          IN VARCHAR2,
                                  p_generate_line_compl  IN VARCHAR2 DEFAULT 'N',
                                  p_operating_unit       IN NUMBER,
                                  p_type_exec            IN VARCHAR2,
                                  p_return_code          OUT NOCOPY VARCHAR2,
                                  p_return_message       OUT NOCOPY VARCHAR2);
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_HEADER                                          |
  |                                                                          |
  | Description: Responsavel por fazer a chamada das procedures responsaveis |
  |              pelas validacoes de header                                  |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OPEN_HEADER(p_open_source              IN VARCHAR2,
                               p_interface_invoice_id     IN NUMBER,
                               p_interface_operation_id   IN NUMBER,
                               p_organization_id          IN NUMBER,
                               p_location_id              IN NUMBER,
                               p_operating_unit           IN NUMBER,
                               p_source                   IN VARCHAR2,
                               p_gl_date                  IN DATE,
                               p_receive_date             IN DATE,
                               p_invoice_type_id          IN NUMBER,
                               p_entity_id                IN NUMBER,
                               p_document_type            IN VARCHAR2,
                               p_document_number          IN VARCHAR2,
                               p_ie                       IN VARCHAR2,
                               p_inss_additional_base_1   IN NUMBER,
                               p_inss_additional_base_2   IN NUMBER,
                               p_inss_additional_base_3   IN NUMBER,
                               p_inss_tax                 IN NUMBER,
                               p_inss_additional_tax_1    IN NUMBER,
                               p_inss_additional_tax_2    IN NUMBER,
                               p_inss_additional_tax_3    IN NUMBER,
                               p_inss_substitute_flag     IN VARCHAR2,
                               p_inss_additional_amount_1 IN NUMBER,
                               p_inss_additional_amount_2 IN NUMBER,
                               p_inss_additional_amount_3 IN NUMBER,
                               p_soma_source              IN NUMBER,
                               p_soma_freight_flag        IN NUMBER,
                               p_soma_gl_date             IN NUMBER,
                               p_soma_org_id              IN NUMBER,
                               p_soma_location            IN NUMBER,
                               p_soma_inv_type            IN NUMBER,
                               p_invoice_num              IN NUMBER,
                               p_invoice_amount           IN NUMBER,
                               p_utilities_flag           IN VARCHAR2,
                               p_gross_total_amount       IN NUMBER,
                               p_invoice_date             IN DATE,
                               p_simplified_br_tax_flag   IN VARCHAR2,
                               p_icms_base                IN NUMBER,
                               p_icms_amount              IN NUMBER,
                               p_max_icms_amount_recover  IN NUMBER,
                               p_icms_tax_rec_simpl_br    IN NUMBER,
                               p_icms_type                IN VARCHAR2,
                               p_icms_st_amount           IN NUMBER,
                               p_ipi_amount               IN NUMBER,
                               p_set_of_books_id          IN NUMBER,
                               p_payment_flag             IN VARCHAR2,
                               p_freight_flag             IN VARCHAR2,
                               p_total_freight_weight     IN NUMBER,
                               p_requisition_type         IN VARCHAR2,
                               p_series                   IN VARCHAR2,
                               p_subseries                IN VARCHAR2,
                               p_fiscal_document_model    IN VARCHAR2
                               --,p_eletronic_invoice_key       IN NUMBER   -- ER 14124731
                              ,
                               p_eletronic_invoice_key        IN VARCHAR2 -- ER 14124731
                              ,
                               p_cte_type                     IN NUMBER,
                               p_invoice_parent_id            IN NUMBER,
                               p_parent_flag                  IN VARCHAR2,
                               p_cost_adjust_flag             IN VARCHAR2,
                               p_price_adjust_flag            IN VARCHAR2,
                               p_tax_adjust_flag              IN VARCHAR2,
                               p_fixed_assets_flag            IN VARCHAR2,
                               p_cofins_flag                  IN VARCHAR2,
                               p_cofins_code_combination_id   IN NUMBER,
                               p_include_iss_flag             IN VARCHAR2,
                               p_iss_city_id                  IN NUMBER,
                               p_iss_city_code                IN VARCHAR2,
                               p_iss_base                     IN NUMBER,
                               p_iss_amount                   IN NUMBER,
                               p_source_state_id              IN NUMBER,
                               p_source_state_code            IN VARCHAR2,
                               p_destination_state_id         IN NUMBER,
                               p_destination_state_code       IN VARCHAR2,
                               p_terms_id                     IN NUMBER,
                               p_terms_name                   IN VARCHAR2,
                               p_first_payment_date           IN DATE,
                               p_terms_date                   IN DATE,
                               p_additional_tax               IN NUMBER,
                               p_additional_amount            IN NUMBER,
                               p_return_cfo_id                IN NUMBER,
                               p_return_cfo_code              IN VARCHAR2,
                               p_return_amount                IN NUMBER,
                               p_source_items                 IN VARCHAR2,
                               p_contract_id                  IN NUMBER,
                               p_importation_number           IN VARCHAR2,
                               p_total_fob_amount             IN NUMBER,
                               p_freight_international        IN NUMBER,
                               p_importation_insurance_amount IN NUMBER,
                               p_importation_tax_amount       IN NUMBER,
                               p_importation_expense_func     IN NUMBER,
                               p_customs_expense_func         IN NUMBER,
                               p_total_cif_amount             IN NUMBER,
                               p_inss_base                    IN NUMBER,
                               p_inss_calculation_flag        IN VARCHAR2,
                               p_inss_amount                  IN NUMBER,
                               p_inss_subcontract_amount      IN NUMBER,
                               p_inss_autonomous_tax          IN NUMBER,
                               p_inss_autonomous_amount       IN NUMBER,
                               p_inss_autonomous_inv_total    IN NUMBER,
                               p_ir_vendor                    IN VARCHAR2,
                               p_ir_base                      IN NUMBER,
                               p_ir_amount                    IN NUMBER,
                               p_ir_tax                       IN NUMBER,
                               p_ir_categ                     IN VARCHAR2,
                               p_vehicle_seller_state_id      IN NUMBER,
                               p_vehicle_seller_state_code    IN VARCHAR2,
                               p_import_document_type         IN VARCHAR2,
                               p_process_origin               IN VARCHAR2,
                               p_social_security_contrib_tax  IN NUMBER -- ER 17551029
                              ,
                               p_gilrat_tax                   IN NUMBER -- ER 17551029
                              ,
                               p_senar_tax                    IN NUMBER -- ER 17551029
                              ,
                               p_worker_category_id           IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_category_code                IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_cbo_code                     IN VARCHAR2 -- ER 17551029 4a Fase
                              ,
                               p_material_equipment_amount    IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_deduction_amount             IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_cno_id                       IN NUMBER -- 24325307
                              ,
                               p_cno_number                   IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_caepf_number                 IN VARCHAR2 -- ER 17551029 4a Fase
                              ,
                               p_indicator_multiple_links     IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_inss_service_amount_1        IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_inss_service_amount_2        IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_inss_service_amount_3        IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_remuneration_freight_amount  IN NUMBER -- ER 17551029 4a Fase
                              ,
                               p_other_expenses               IN NUMBER -- 21091872
                              ,
                               p_insurance_amount             IN NUMBER -- 21091872
                              ,
                               p_freight_amount               IN NUMBER -- 21091872
                              ,
                               p_lp_inss_initial_base_amount  IN NUMBER --  21924115
                              ,
                               p_lp_inss_base_amount          IN NUMBER --  21924115
                              ,
                               p_lp_inss_rate                 IN NUMBER --  21924115
                              ,
                               p_lp_inss_amount               IN NUMBER --  21924115
                              ,
                               p_lp_inss_net_amount           IN NUMBER --  21924115
                              ,
                               p_ip_inss_initial_base_amount  IN NUMBER --  21924115
                              ,
                               p_ip_inss_base_amount          IN NUMBER --  21924115
                              ,
                               p_ip_inss_rate                 IN NUMBER --  21924115
                              ,
                               p_ip_inss_net_amount           IN NUMBER --  21924115
                              ,
                               p_source_city_id               IN NUMBER,   -- 28487689 - 28597878
                               p_source_ibge_city_code        IN NUMBER,   -- 28487689 - 28597878
                               p_destination_city_id          IN NUMBER,   -- 28487689 - 28597878
                               p_destination_ibge_city_code   IN NUMBER,   -- 28487689 - 28597878
                               p_ship_to_state_id             IN NUMBER,   -- 28487689 - 28597878
                               p_return_customer_flag         IN VARCHAR2, -- 29908009
                               p_process_flag                 OUT NOCOPY NUMBER,
                               p_vendor_id                    OUT NOCOPY NUMBER,
                               p_allow_upd_price_flag         OUT NOCOPY VARCHAR2,
                               p_rcv_tolerance_perc_amount    OUT NOCOPY NUMBER,
                               p_rcv_tolerance_code           OUT NOCOPY VARCHAR2,
                               p_pis_amount_recover_cnpj      OUT NOCOPY NUMBER,
                               p_cofins_amount_recover_cnpj   OUT NOCOPY NUMBER,
                               p_cumulative_threshold_type    OUT NOCOPY VARCHAR2,
                               p_minimum_tax_amount           OUT NOCOPY VARCHAR2,
                               p_document_type_out            OUT NOCOPY VARCHAR2,
                               p_funrural_contributor_flag    OUT NOCOPY VARCHAR2,
                               p_rounding_precision           OUT NOCOPY NUMBER,
                               p_entity_id_out                OUT NOCOPY NUMBER,
                               p_first_payment_date_out       OUT NOCOPY DATE,
                               p_terms_id_out                 OUT NOCOPY NUMBER,
                               p_return_cfo_id_out            OUT NOCOPY NUMBER,
                               p_source_state_id_out          OUT NOCOPY NUMBER,
                               p_destination_state_id_out     OUT NOCOPY NUMBER,
                               p_source_city_id_out           OUT NOCOPY NUMBER, -- 28487689 - 28597878
                               p_destination_city_id_out      OUT NOCOPY NUMBER, -- 28487689 - 28597878
                               p_ship_to_state_id_out         OUT NOCOPY NUMBER, -- 28487689 - 28597878
                               p_source_ibge_city_out         OUT NOCOPY NUMBER, -- 28730077
                               p_destination_ibge_city_out    OUT NOCOPY NUMBER, -- 28730077
                               p_inss_additional_amount_1_out OUT NOCOPY NUMBER,
                               p_inss_additional_amount_2_out OUT NOCOPY NUMBER,
                               p_inss_additional_amount_3_out OUT NOCOPY NUMBER,
                               p_city_id                      OUT NOCOPY NUMBER,
                               p_vehicle_seller_state_id_out  OUT NOCOPY NUMBER,
                               p_qtd_lines_tmp                OUT NOCOPY NUMBER,
                               p_qtde_nf_compl                OUT NOCOPY NUMBER -- Bug 16600918
                              ,
                               p_return_code                  OUT NOCOPY VARCHAR2,
                               p_return_message               OUT NOCOPY VARCHAR2);
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OPEN_INTERFACE                                       |
  |                                                                          |
  | Description: Responsible for validate information and insert into RI     |
  |              final tables or insert errors in RI or Loader interface     |
  |              tables                                                      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OPEN_LINES(p_type                         IN VARCHAR2,
                              p_interface_invoice_id         IN NUMBER,
                              p_interface_operation_id       IN NUMBER,
                              p_organization_id              IN NUMBER,
                              p_location_id                  IN NUMBER,
                              p_operating_unit               IN NUMBER,
                              p_vendor_id                    IN NUMBER,
                              p_entity_id                    IN NUMBER,
                              p_invoice_type_id              IN NUMBER,
                              p_price_adjust_flag            IN VARCHAR2,
                              p_cost_adjust_flag             IN VARCHAR2,
                              p_tax_adjust_flag              IN VARCHAR2,
                              p_fixed_assets_flag            IN VARCHAR2,
                              p_parent_flag                  IN VARCHAR2,
                              p_contab_flag                  IN VARCHAR2,
                              p_payment_flag                 IN VARCHAR2,
                              p_freight_flag                 IN VARCHAR2,
                              p_freight_flag_inv_type        IN VARCHAR2,
                              p_project_flag                 IN VARCHAR2,
                              p_chart_of_accounts_id         IN NUMBER,
                              p_additional_tax               IN NUMBER,
                              p_allow_upd_price_flag         IN VARCHAR2,
                              p_source_items                 IN VARCHAR2,
                              p_user_defined_conversion_rate IN NUMBER,
                              p_rcv_tolerance_perc_amount    IN NUMBER,
                              p_rcv_tolerance_code           IN VARCHAR2,
                              p_source_state_id              IN NUMBER,
                              p_destination_state_id         IN NUMBER,
                              p_source_state_code            IN VARCHAR2 -- Bug 17442462
                             ,
                              p_destination_state_code       IN VARCHAR2 -- Bug 17442462
                             ,
                              p_gl_date                      IN DATE,
                              p_receive_date                 IN DATE,
                              p_qtde_nf_compl                IN NUMBER -- Bug 16600918
                             ,
                              p_requisition_type             IN VARCHAR2 --<<Bug 17481870 - Egini - 20/09/2013 >>--
                             ,
                              p_invoice_date                 IN DATE --  22012023
                             ,
                              p_invoice_line_id_par          OUT NOCOPY NUMBER -- BUG 19943706
                             ,
                              p_process_flag                 OUT NOCOPY NUMBER,
                              p_return_code                  OUT NOCOPY VARCHAR2,
                              p_return_message               OUT NOCOPY VARCHAR2
                              -- Begin BUG 24387238
                             ,
                              p_line_location_id    OUT NOCOPY NUMBER,
                              p_requisition_line_id OUT NOCOPY NUMBER,
                              p_item_id             OUT NOCOPY NUMBER
                              -- End BUG 24387238
                              );
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
  PROCEDURE CREATE_OPEN_FREIGHT(p_type                        IN VARCHAR2,
                                p_interface_operation_id      IN NUMBER,
                                p_location_id                 IN NUMBER,
                                p_operating_unit              IN NUMBER,
                                p_gl_date                     IN DATE,
                                p_set_of_books_id             IN NUMBER,
                                p_fiscal_flag                 IN VARCHAR2,
                                p_source_state_id             IN NUMBER,
                                p_destination_state_id        IN NUMBER,
                                p_pis_amount_recover_cnpj     IN NUMBER,
                                p_cofins_amount_recover_cnpj  IN NUMBER,
                                p_cll_f189_entry_operations_s IN NUMBER,
                                p_first_payment_date          IN DATE,         -- 27854379
                                p_first_payment_date_out      OUT NOCOPY DATE, -- 27854379
                                p_process_flag                OUT NOCOPY NUMBER,
                                p_return_code                 OUT NOCOPY VARCHAR2,
                                p_return_message              OUT NOCOPY VARCHAR2);
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
  PROCEDURE CREATE_OPEN_INV_PARENTS(p_type                   IN VARCHAR2,
                                    p_interface_invoice_id   IN NUMBER,
                                    p_interface_operation_id IN NUMBER,
                                    p_organization_id        IN NUMBER,
                                    p_invoice_line_id_par    IN OUT NOCOPY NUMBER -- BUG 19943706
                                   ,
                                    p_process_flag           OUT NOCOPY NUMBER,
                                    p_return_code            OUT NOCOPY VARCHAR2,
                                    p_return_message         OUT NOCOPY VARCHAR2,
                                    p_invoice_type_id        IN NUMBER -- Bug 17088635
                                    -- Begin BUG 24387238
                                   ,
                                    p_generate_line          IN VARCHAR2 DEFAULT 'N',
                                    p_invoice_line_id        IN NUMBER,
                                    p_parent_id_out          OUT NOCOPY NUMBER,
                                    p_interface_parent_id    OUT NOCOPY NUMBER,
                                    p_invoice_parent_line_id OUT NOCOPY NUMBER,
                                    p_parent_line_id_out     OUT NOCOPY NUMBER,
                                    p_inv_line_parent_id_out OUT NOCOPY NUMBER,
                                    p_total                  IN NUMBER,
                                    p_icms                   IN NUMBER,
                                    p_ipi                    IN NUMBER,
                                    p_business_vendor        IN NUMBER,
                                    p_org_state_id           IN NUMBER,
                                    p_vendor_state_id        IN NUMBER,
                                    p_additional_tax         IN NUMBER,
                                    p_user_id                IN NUMBER,
                                    p_interface              IN VARCHAR2,
                                    p_line_location_id       IN NUMBER,
                                    p_requisition_line_id    IN NUMBER,
                                    p_item_id                IN NUMBER,
                                    p_type_exec              IN VARCHAR2 DEFAULT 'N',
                                    -- End BUG 24387238
                                    p_return_customer_flag   IN VARCHAR2 -- 29908009
                                    );
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
                                   , p_return_code               OUT NOCOPY VARCHAR2
                                   , p_return_message            OUT NOCOPY VARCHAR2
								   ) ;
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
  PROCEDURE CREATE_INVOICE_PAR_LINES_TMP(p_type                   IN VARCHAR2,
                                         p_interface_invoice_id   IN NUMBER,
                                         p_interface_operation_id IN NUMBER,
                                         p_organization_id        IN NUMBER,
                                         p_interface_parent_id    IN NUMBER,
                                         p_parent_id              IN NUMBER,
                                         p_invoice_line_id        IN NUMBER -- BUG 19943706
                                        ,
                                         p_return_code            OUT NOCOPY VARCHAR2,
                                         p_return_message         OUT NOCOPY VARCHAR2,
                                         p_invoice_type_id        IN NUMBER -- Bug 17088635
                                         -- Begin BUG 24387238
                                        ,
                                         p_generate_line             IN VARCHAR2 DEFAULT 'N',
                                         p_interface_invoice_line_id IN NUMBER,
                                         p_parent_line_id_out        OUT NOCOPY NUMBER,
                                         p_inv_line_parent_id_out    OUT NOCOPY NUMBER,
                                         p_invoice_id                IN NUMBER,
                                         p_total                     IN NUMBER,
                                         p_icms                      IN NUMBER,
                                         p_ipi                       IN NUMBER,
                                         p_business_vendor           IN NUMBER,
                                         p_org_state_id              IN NUMBER,
                                         p_vendor_state_id           IN NUMBEr,
                                         p_additional_tax            IN NUMBER,
                                         p_user_id                   IN NUMBER,
                                         p_interface                 IN VARCHAR2,
                                         p_invoice_line_id_in        IN NUMBER DEFAULT NULL,
                                         p_inv_line_parent_id_in     IN NUMBER DEFAULT NULL,
                                         p_line_location_id          IN NUMBER DEFAULT NULL,
                                         p_requisition_line_id       IN NUMBER DEFAULT NULL,
                                         p_item_id                   IN NUMBER DEFAULT NULL,
                                         p_type_exec                 IN VARCHAR2 DEFAULT 'N',
                                         -- End BUG 24387238
                                         p_return_customer_flag      IN VARCHAR2 -- 29908009
                                         );

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
  PROCEDURE CREATE_LEGAL_PROCESSES(p_type                   IN VARCHAR2,
                                   p_interface_invoice_id   IN NUMBER,
                                   p_interface_operation_id IN NUMBER,
                                   p_organization_id        IN NUMBER,
                                   p_invoice_id             IN NUMBER);
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_OUTBOUND_INVOICES                                    |
  |                                                                          |
  | Description: Responsavel por validar e inserir notas de saida            |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_OUTBOUND_INVOICES(p_type                   IN VARCHAR2,
                                     p_insert                 IN VARCHAR2 -- 22346186
                                    ,
                                     p_interface_invoice_id   IN NUMBER,
                                     p_interface_operation_id IN NUMBER,
                                     p_organization_id        IN NUMBER,
                                     p_invoice_id             IN NUMBER);
  --
  -- ER 17551029 4a Fase - Start
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_PRIOR_BILLINGS                                       |
  |                                                                          |
  | Description: Responsavel por validar e inserir prior billings            |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_PRIOR_BILLINGS(p_type                   IN VARCHAR2,
                                  p_interface_invoice_id   IN NUMBER,
                                  p_interface_operation_id IN NUMBER,
                                  p_organization_id        IN NUMBER,
                                  p_invoice_id             IN NUMBER);
  -- ER 17551029 4a Fase - End
  --
  -- 28592012 - Start
  /*=========================================================================+
  |                                                                          |
  | Procedure:   CREATE_PAYMENT_METHODS                                      |
  |                                                                          |
  | Description: Responsavel por validar e inserir payment methods           |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE CREATE_PAYMENT_METHODS(p_type                   IN VARCHAR2,
                                   p_interface_invoice_id   IN NUMBER,
                                   p_interface_operation_id IN NUMBER,
                                   p_organization_id        IN NUMBER,
                                   p_invoice_id             IN NUMBER);
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
  PROCEDURE CREATE_REFERENCED_DOCUMENTS (p_type                   IN VARCHAR2
                                        ,p_interface_invoice_id   IN NUMBER
                                        ,p_interface_operation_id IN NUMBER
                                        ,p_organization_id        IN NUMBER
                                        ,p_invoice_id             IN NUMBER
                                     );
  -- 29330466 - 29338175 - 29385361 - 29480917 - End
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   APPROVE_INTERFACE                                           |
  |                                                                          |
  | Description: Responsavel por fazer a aprovacao do documento na Open      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE APPROVE_INTERFACE(p_organization_id IN cll_f189_entry_operations.organization_id%TYPE,
                              p_operation_id    IN cll_f189_entry_operations.operation_id%TYPE,
                              p_location_id     IN cll_f189_invoices.location_id%TYPE,
                              p_gl_date         IN cll_f189_entry_operations.gl_date%TYPE,
                              p_receive_date    IN cll_f189_entry_operations.receive_date%TYPE,
                              p_created_by      IN cll_f189_entry_operations.created_by%TYPE,
                              p_source          IN VARCHAR2,
                              p_interface       IN VARCHAR2 DEFAULT 'N',
                              p_int_invoice_id  IN cll_f189_invoices_interface.interface_invoice_id%TYPE);
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:    BASE_ACCUMULATE_IRRF                                       |
  |                                                                          |
  | Description: Responsavel por calcular e retornar os valores do IRRF      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE BASE_ACCUMULATE_IRRF(p_accumulate_type          IN cll_f189_tax_sites.cumulative_threshold_type%TYPE DEFAULT NULL,
                                 p_minimun_value            IN cll_f189_tax_sites.minimum_tax_amount%TYPE DEFAULT NULL,
                                 p_invoice_id               IN cll_f189_invoices.invoice_id%TYPE DEFAULT NULL,
                                 p_entity_id                IN cll_f189_invoices.entity_id%TYPE DEFAULT NULL,
                                 p_organization_id          IN cll_f189_invoices.organization_id%TYPE DEFAULT NULL,
                                 p_location_id              IN cll_f189_invoices.location_id%TYPE DEFAULT NULL,
                                 p_ir_base                  IN cll_f189_invoices.ir_base%TYPE DEFAULT NULL,
                                 p_ir_tax                   IN cll_f189_invoices.ir_tax%TYPE DEFAULT NULL,
                                 p_accumulate_date          IN DATE DEFAULT NULL,
                                 p_irrf_withhold_invoice_id IN OUT NOCOPY cll_f189_invoices.irrf_withhold_invoice_id%TYPE,
                                 p_ir_amount                OUT NOCOPY cll_f189_invoices.ir_amount%TYPE);
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:    UPDATE_IRRF_WITHHOLD_INVOICE                               |
  |                                                                          |
  | Description: Responsavel por calcular e retornar os valores do IRRF      |
  |              Retido                                                      |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE UPDATE_IRRF_WITHHOLD_INVOICE(p_accumulate_type IN cll_f189_tax_sites.cumulative_threshold_type%TYPE DEFAULT NULL,
                                         p_minimun_value   IN cll_f189_tax_sites.minimum_tax_amount%TYPE DEFAULT NULL,
                                         p_invoice_id      IN cll_f189_invoices.invoice_id%TYPE DEFAULT NULL,
                                         p_entity_id       IN cll_f189_invoices.entity_id%TYPE DEFAULT NULL,
                                         p_organization_id IN cll_f189_invoices.organization_id%TYPE DEFAULT NULL,
                                         p_location_id     IN cll_f189_invoices.location_id%TYPE DEFAULT NULL,
                                         p_accumulate_date IN DATE DEFAULT NULL);
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:   SET_PROCESS_FLAG                                            |
  |                                                                          |
  | Description: Responsavel por atualizar o flag de processamento na open   |
  |              com o status correspondente ao registro processado          |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE SET_PROCESS_FLAG(p_process_flag         IN NUMBER,
                             p_interface_invoice_id IN NUMBER);
  --
  /*=========================================================================+
  |                                                                          |
  | Procedure:    ADD_ERROR                                                  |
  |                                                                          |
  | Description: Responsavel por inserir os erros de processamento da Open   |
  |              Interface na tabela: CLL_F189_INTERFACE_ERRORS              |
  |                                                                          |
  +=========================================================================*/
  PROCEDURE ADD_ERROR(p_invoice_id             IN NUMBER,
                      p_interface_operation_id IN NUMBER,
                      p_organization_id        IN NUMBER,
                      p_error_code             IN VARCHAR2,
                      p_invoice_line_id        IN NUMBER,
                      p_table_associated       IN NUMBER,
                      p_invalid_value          IN VARCHAR2);
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
                                    ) ;
  --
END XXFR_F189_OPEN_PROCESSES_PUB;
