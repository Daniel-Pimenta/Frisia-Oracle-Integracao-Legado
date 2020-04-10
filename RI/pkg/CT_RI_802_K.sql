CREATE OR REPLACE PACKAGE ct_ri_802_k IS

  PROCEDURE insere_nfe_interface_ri (p_id_recebimento IN NUMBER
                                    );

END ct_ri_802_k;
/
CREATE OR REPLACE PACKAGE BODY ct_ri_802_k IS

  PROCEDURE insere_nfe_interface_ri (p_id_recebimento IN NUMBER
                                    )
  IS
    CURSOR c_recb
      IS SELECT id_filial 
               ,dt_recebimento   
               ,dt_processamento   
               ,id_instancia_bpel 
           FROM ct_ri_sply_recebimento
          WHERE id_recebimento = p_id_recebimento;

    CURSOR c_fret
      IS SELECT id_conhecimento
               ,id_filial
               ,numero
               ,id_local_transportadora
               ,nr_documento_transp
               ,tipo_transporte
               ,cfop
               ,peso_bruto
               ,serie
               ,vlr_frete
               ,dt_emissao
               ,icms_tipo
               ,icms_base
               ,icms_aliquota
               ,icms_valor
               ,icms_cst
               ,chave
               ,tipo
           FROM ct_ri_sply_conhec_frete
          WHERE id_recebimento = p_id_recebimento;

    CURSOR c_nofi
      IS SELECT id_nota_fiscal
               ,id_filial
               ,numero
               ,id_local_fornecedor
               ,nr_documento_forn
               ,serie
               ,vlr_total
               ,dt_emissao
               ,peso_bruto
               ,condicao_frete
               ,icms_base
               ,icms_valor
               ,icms_st_base
               ,icms_st_valor
               ,ipi_valor
               ,iss_base
               ,iss_valor
               ,ir_base
               ,ir_valor
               ,inss_base
               ,inss_valor
               ,chave
               ,tipo
           FROM ct_ri_sply_nota_fiscal
          WHERE id_recebimento = p_id_recebimento;

    CURSOR c_lnnf (p_id_nota_fiscal IN NUMBER)
      IS SELECT id_linha_nf
               ,id_local_linha_oc
               ,nr_ordem_compra
               ,nr_linha_compra
               ,cfop
               ,cd_unidade_medida
               ,quantidade
               ,preco_unitario
               ,vlr_desconto
               ,vlr_total
               ,vlr_frete
               ,vlr_seguro
               ,vlr_outras_despesas
               ,icms_cst
               ,icms_base
               ,icms_aliquota
               ,icms_valor
               ,icms_st_base
               ,icms_st_valor
               ,ipi_cst
               ,ipi_base
               ,ipi_aliquota
               ,ipi_valor
               ,pis_cst
               ,pis_base
               ,pis_aliquota
               ,pis_valor
               ,pis_st_base
               ,pis_st_aliquota
               ,pis_st_valor
               ,cofins_cst
               ,cofins_base
               ,cofins_aliquota
               ,cofins_valor
               ,cofins_st_base
               ,cofins_st_aliquota
               ,cofins_st_valor
           FROM ct_ri_sply_linha_nota
          WHERE id_nota_fiscal = p_id_nota_fiscal;

    r_cf_fret                      cll_f189_freight_inv_interface%ROWTYPE;
    r_cf_invo                      cll_f189_invoices_interface%ROWTYPE;
    r_cf_inli                      cll_f189_invoice_lines_iface%ROWTYPE;
    
    w_interface_operation_id       cll_f189_invoices_interface.interface_operation_id%TYPE;
    w_interface_invoice_id         cll_f189_invoices_interface.interface_invoice_id%TYPE;
    w_vendor_id                    po_headers_all.vendor_id%TYPE;
    w_vendor_site_id               po_headers_all.vendor_site_id%TYPE;
    w_terms_id                     po_headers_all.terms_id%TYPE;
    w_freight_terms_lookup_code    po_headers_all.freight_terms_lookup_code%TYPE;
    w_transaction_reason_code      po_lines_all.transaction_reason_code%TYPE;
    w_location_id                  po_line_locations_all.ship_to_location_id%TYPE;
    w_supply_cfop_code             ct_ri_sply_linha_nota.cfop%TYPE;
    w_invoice_type_code            cll_f189_invoices_interface.invoice_type_code%TYPE;
    w_entity_id                    cll_f189_fiscal_entities_all.entity_id%TYPE;
    w_business_vendor_id           cll_f189_fiscal_entities_all.business_vendor_id%TYPE;
    w_document_type                cll_f189_fiscal_entities_all.document_type%TYPE;
    w_ir_vendor                    cll_f189_business_vendors.ir_vendor%TYPE;
    w_source_state_code            ap_supplier_sites_all.state%TYPE;
    w_destination_state_code       hz_locations.state%TYPE;

  BEGIN
  
    FOR r_recb IN c_recb LOOP

      w_interface_operation_id       := NULL;

      BEGIN
        SELECT cll_f189_interface_operat_s.nextval
          INTO w_interface_operation_id
          FROM dual;

      EXCEPTION
        WHEN OTHERS THEN
          -- Tratar erro.
          NULL;
      END;

      FOR r_fret IN c_fret LOOP

        r_cf_fret := NULL;

        INSERT INTO cll_f189_freight_inv_interface VALUES r_cf_fret;

      END LOOP;

      FOR r_nofi IN c_nofi LOOP

        r_cf_invo                      := NULL;
        w_interface_invoice_id         := NULL;
        w_vendor_id                    := NULL;
        w_vendor_site_id               := NULL;
        w_terms_id                     := NULL;
        w_freight_terms_lookup_code    := NULL;
        w_transaction_reason_code      := NULL;
        w_location_id                  := NULL;
        w_supply_cfop_code             := NULL;
        w_invoice_type_code            := NULL;
        w_entity_id                    := NULL;
        w_business_vendor_id           := NULL;
        w_document_type                := NULL;
        w_ir_vendor                    := NULL;
        w_source_state_code            := NULL;
        w_destination_state_code       := NULL;

        BEGIN
          SELECT DISTINCT
                 phea.vendor_id
                ,phea.vendor_site_id
                ,phea.terms_id
                ,phea.freight_terms_lookup_code
                ,plin.transaction_reason_code
                ,pllo.ship_to_location_id
                ,slnf.cfop
            INTO w_vendor_id
                ,w_vendor_site_id
                ,w_terms_id
                ,w_freight_terms_lookup_code
                ,w_transaction_reason_code
                ,w_location_id
                ,w_supply_cfop_code
            FROM po_headers_all                 phea
                ,po_lines_all                   plin
                ,po_line_locations_all          pllo
                ,ct_ri_sply_linha_nota          slnf
           WHERE 1=1
             AND phea.po_header_id                   = plin.po_header_id
             AND plin.po_line_id                     = pllo.po_line_id
             AND pllo.line_location_id               = slnf.id_local_linha_oc
             AND pllo.ship_to_organization_id        = r_nofi.id_filial
             AND phea.vendor_site_id                 = r_nofi.id_local_fornecedor
             AND slnf.id_nota_fiscal                 = r_nofi.id_nota_fiscal;
        EXCEPTION
          WHEN OTHERS THEN
            -- Tratar erro.
            NULL;
        END;

        BEGIN
          SELECT etyp.invoice_type_code
            INTO w_invoice_type_code
            FROM ct_ri_inv_entry_cfos_v         ecfo
                ,ct_ri_inv_entry_types_v        etyp
           WHERE ecfo.inv_entry_cfo_id               = etyp.inv_entry_cfo_id
             AND ecfo.utilization_code               = w_transaction_reason_code
             AND ecfo.supplier_cfo_code              = w_supply_cfop_code
             AND etyp.organization_id                = r_nofi.id_filial;
        EXCEPTION
          WHEN OTHERS THEN
            -- Tratar erro.
            NULL;
        END;

        BEGIN
          SELECT cffe.entity_id
                ,cffe.business_vendor_id
                ,cffe.document_type
            INTO w_entity_id
                ,w_business_vendor_id
                ,w_document_type
            FROM cll_f189_fiscal_entities_all   cffe
           WHERE cffe.vendor_site_id                 = w_vendor_site_id;
        EXCEPTION
          WHEN OTHERS THEN
            -- Tratar erro.
            NULL;
        END;


        BEGIN
          SELECT buve.ir_vendor
            INTO w_ir_vendor
            FROM cll_f189_business_vendors      buve
           WHERE buve.business_id                    = w_business_vendor_id;
        EXCEPTION
          WHEN OTHERS THEN
            -- Tratar erro.
            NULL;
        END;

        BEGIN
          SELECT assi.state
            INTO w_source_state_code
            FROM ap_supplier_sites_all          assi
           WHERE assi.vendor_site_id                 = w_vendor_site_id;
        EXCEPTION
          WHEN OTHERS THEN
            -- Tratar erro.
            NULL;
        END;

        BEGIN
          SELECT hloc.state
            INTO w_destination_state_code
            FROM hz_locations                   hloc
                ,hz_party_sites                 hpsi
                ,hz_cust_acct_sites_all         hcas
                ,hz_cust_site_uses_all          hcsu
                ,po_location_associations_all   plas
           WHERE hloc.location_id                    = hpsi.location_id
             AND hpsi.party_site_id                  = hcas.party_site_id
             AND hcas.cust_acct_site_id              = hcsu.cust_acct_site_id
             AND hcsu.site_use_id                    = plas.site_use_id
             AND plas.organization_id                = r_nofi.id_filial;
        EXCEPTION
          WHEN OTHERS THEN
            -- Tratar erro.
            NULL;
        END;

        BEGIN
          SELECT cll_f189_invoices_interface_s.nextval
            INTO w_interface_invoice_id
            FROM dual;
        EXCEPTION
          WHEN OTHERS THEN
            -- Tratar erro.
            NULL;
        END;
      
        r_cf_invo.interface_operation_id               := w_interface_operation_id;
        r_cf_invo.interface_invoice_id                 := w_interface_invoice_id;
        r_cf_invo.source                               := 'NFe Supply';
        r_cf_invo.process_flag                         := 99;
        r_cf_invo.gl_date                              := r_nofi.dt_emissao;
        r_cf_invo.freight_flag                         := 'N';
        r_cf_invo.entity_id                            := w_entity_id;
        r_cf_invo.invoice_num                          := r_nofi.numero;
        r_cf_invo.series                               := to_number(r_nofi.serie);       -- Validar se é numerico antes
        r_cf_invo.organization_id                      := r_nofi.id_filial;              -- validar a filial antes
        r_cf_invo.location_id                          := w_location_id;
        r_cf_invo.invoice_amount                       := Round(r_nofi.vlr_total,2);
        r_cf_invo.invoice_date                         := r_nofi.dt_emissao;
        r_cf_invo.invoice_type_code                    := w_invoice_type_code;
        IF r_nofi.icms_valor > 0 THEN
          r_cf_invo.icms_type                            := 'NORMAL';
        ELSE
          r_cf_invo.icms_type                            := 'NOT APPLIED';
        END IF;      
        r_cf_invo.icms_base                            := Round(r_nofi.icms_base,2);
        --r_cf_invo.icms_tax                             := Round(r_nofi.icms_,2); O pessoal da G2KA tem que criar esse campo
        r_cf_invo.icms_amount                          := Round(r_nofi.icms_valor,2);
        r_cf_invo.ipi_amount                           := Round(r_nofi.ipi_valor,2);
        r_cf_invo.subst_icms_base                      := 0; -- Analisar
        r_cf_invo.subst_icms_amount                    := 0; -- Analisar
        r_cf_invo.diff_icms_tax                        := 0; -- Analisar
        r_cf_invo.diff_icms_amount                     := 0; -- Analisar
        r_cf_invo.iss_base                             := Round(r_nofi.iss_base,2);
        --r_cf_invo.iss_tax                              := Round(r_inv.iss_tax,2); O pessoal da G2KA tem que criar esse campo
        r_cf_invo.iss_amount                           := Round(r_nofi.iss_valor,2);
        r_cf_invo.ir_base                              := Round(r_nofi.ir_base,2);
        --r_cf_invo.ir_tax                               := Round(r_nofi.ir i,2); O pessoal da G2KA tem que criar esse campo
        r_cf_invo.ir_amount                            := Round(r_nofi.ir_valor,2);
        r_cf_invo.terms_id                             := w_terms_id;
        r_cf_invo.terms_date                           := r_nofi.dt_emissao;
        r_cf_invo.first_payment_date                   := r_nofi.dt_emissao;
        r_cf_invo.invoice_weight                       := r_nofi.peso_bruto;
        r_cf_invo.source_items                         := 0; -- Analisar
        r_cf_invo.total_fob_amount                     := NULL; -- Analisar
        r_cf_invo.total_cif_amount                     := NULL; -- Analisar
        r_cf_invo.fiscal_document_model                := 'NF-E';
        r_cf_invo.irrf_base_date                       := NULL; -- Analisar
        r_cf_invo.inss_base                            := Round(r_nofi.inss_base,2);
        --r_cf_invo.inss_tax                             := Round(r_nofi.inss_tax,2); O pessoal da G2KA tem que criar esse campo
        r_cf_invo.inss_amount                          := Round(r_nofi.inss_valor,2);
        r_cf_invo.ir_vendor                            := w_ir_vendor;
        r_cf_invo.ir_categ                             := NULL; -- Analisar
        r_cf_invo.icms_st_base                         := Round(r_nofi.icms_st_base,2);
        r_cf_invo.icms_st_amount                       := Round(r_nofi.icms_st_valor,2);
        r_cf_invo.icms_st_amount_recover               := NULL; -- Analisar
        r_cf_invo.diff_icms_amount_recover             := NULL; -- Analisar
        r_cf_invo.gross_total_amount                   := Round(r_nofi.vlr_total,2);
        r_cf_invo.source_state_code                    := w_source_state_code;
        r_cf_invo.destination_state_code               := w_destination_state_code;
        r_cf_invo.receive_date                         := r_nofi.dt_emissao;
        r_cf_invo.creation_date                        := SYSDATE;
        r_cf_invo.created_by                           := fnd_profile.value('USER_ID');
        r_cf_invo.last_update_date                     := SYSDATE;
        r_cf_invo.last_updated_by                      := fnd_profile.value('USER_ID');
        r_cf_invo.last_update_login                    := fnd_profile.value('LOGIN_ID');
        r_cf_invo.eletronic_invoice_key                := r_nofi.chave;
        r_cf_invo.vendor_id                            := w_vendor_id;
        r_cf_invo.vendor_site_id                       := w_vendor_site_id;
  
        INSERT INTO cll_f189_invoices_interface VALUES r_cf_invo;

        FOR r_lnnf IN c_lnnf (p_id_nota_fiscal => r_nofi.id_nota_fiscal) LOOP
          r_cf_inli := NULL;

          BEGIN
            SELECT pllo.line_location_id
                  ,plin.item_id
                  ,plin.transaction_reason_code
                  ,plin.item_description
              FROM po_headers_all                 phea
                  ,po_lines_all                   plin
                  ,po_line_locations_all          pllo
             WHERE phea.po_header_id                   = plin.po_header_id
               AND plin.po_line_id                     = pllo.po_line_id
               AND phea.segment1                       = p_po_header_number
               AND plin.line_num                       = p_po_line_number;
          EXCEPTION
            WHEN OTHERS THEN
              -- Tratar erro.
              NULL;
          END;

          IF w_invoice_line_error_flag = 'N' THEN
            fnd_file.put_line(fnd_file.log,'15110 - Seleciona a tabela CLL_F189_INVOICE_TYPES para'
                                        || ' ORGANIZATION_ID = ' || r_pohe.ship_to_organization_id
                                        || ' e INVOICE_TYPE_CODE = ' || w_invoice_type_code
                                        );
            BEGIN
              SELECT fity.operation_fiscal_type
                INTO w_operation_fiscal_type
                FROM cll_f189_invoice_types         fity
               WHERE fity.organization_id                = r_pohe.ship_to_organization_id
                 AND fity.invoice_type_code              = w_invoice_type_code;
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'-->> 15115 - Erro ao selecionar a tabela CLL_F189_INVOICE_TYPES para'
                                            || ' ORGANIZATION_ID = ' || r_pohe.ship_to_organization_id
                                            || ' e INVOICE_TYPE_CODE = ' || w_invoice_type_code                
                                            || '. Erro Oracle: ' || SQLERRM
                                            );
                errbuf                         := errbuf || chr(10)
                                               || '-->> 15115 - Erro ao selecionar a tabela CLL_F189_INVOICE_TYPES para'
                                               || ' ORGANIZATION_ID = ' || r_pohe.ship_to_organization_id
                                               || ' e INVOICE_TYPE_CODE = ' || w_invoice_type_code                
                                               || '. Erro Oracle: ' || SQLERRM;
                retcode                        := 1;
                w_invoice_line_error_flag      := 'Y';
            END;
          END IF;

          IF w_invoice_line_error_flag = 'N' THEN
            fnd_file.put_line(fnd_file.log,'15120 - Seleciona a tabela CLL_F189_FISCAL_ITEMS para'
                                        || ' ORGANIZATION_ID = ' || r_pohe.ship_to_organization_id
                                        || ' e INVENTORY_ITEM_ID = ' || r_poli.item_id
                                        );
            BEGIN
              SELECT cffi.classification_id
                INTO w_classification_id
                FROM cll_f189_fiscal_items          cffi
               WHERE cffi.organization_id                = r_pohe.ship_to_organization_id
                 AND cffi.inventory_item_id              = r_poli.item_id;
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'-->> 15125 - Erro ao selecionar a tabela CLL_F189_FISCAL_ITEMS para'
                                            || ' ORGANIZATION_ID = ' || r_pohe.ship_to_organization_id
                                            || ' e INVENTORY_ITEM_ID = ' || r_poli.item_id           
                                            || '. Erro Oracle: ' || SQLERRM
                                            );
                errbuf                         := errbuf || chr(10)
                                               || '-->> 15125 - Erro ao selecionar a tabela CLL_F189_FISCAL_ITEMS para'
                                               || ' ORGANIZATION_ID = ' || r_pohe.ship_to_organization_id
                                               || ' e INVENTORY_ITEM_ID = ' || r_poli.item_id
                                               || '. Erro Oracle: ' || SQLERRM;
                retcode                        := 1;
                w_invoice_line_error_flag      := 'Y';
            END;
          END IF;

          r_cfiu := NULL;

          IF w_invoice_line_error_flag = 'N' THEN          
            fnd_file.put_line(fnd_file.log,'15130 - Seleciona a tabela CLL_F189_ITEM_UTILIZATIONS para'
                                        || ' UTILIZATION_CODE = ' || r_poli.transaction_reason_code
                                        );
            BEGIN
              OPEN c_cfiu (r_poli.transaction_reason_code);
              FETCH c_cfiu INTO r_cfiu;
              CLOSE c_cfiu;
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'-->> 15131 - Erro ao abrir o cursor C_CFIU para'
                                            || ' UTILIZATION_CODE = ' || r_poli.transaction_reason_code
                                            || '. Erro Oracle: ' || SQLERRM
                                            );
                errbuf                         := errbuf || chr(10)
                                               || '-->> 15131 - Erro ao abrir o cursor C_CFIU para'
                                               || ' UTILIZATION_CODE = ' || r_poli.transaction_reason_code
                                               || '. Erro Oracle: ' || SQLERRM;
                retcode                        := 1;
                w_invoice_line_error_flag      := 'Y';
            END;
          END IF;

          IF w_invoice_line_error_flag = 'N' THEN
            fnd_file.put_line(fnd_file.log,'15135 - Seleciona o CFOP para'
                                        || ' o CFOP do Fornecedor = ' || trim(r_lin.supplier_cfo_code)
                                        || ' e Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'                                       
                                        );
            BEGIN
              SELECT ecfo.cfo_code
                INTO w_cfo_code
                FROM ct_ri_inv_entry_cfos_v         ecfo
               WHERE ecfo.utilization_id                  = r_cfiu.utilization_id
                 AND ecfo.supplier_cfo_code               = trim(r_lin.supplier_cfo_code)
                 AND ecfo.org_id                          = fnd_profile.value('ORG_ID');
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'-->> 15136 - Erro ao selecionar o CFOP para'
                                            || ' o CFOP do Fornecedor = ' ||r_lin.supplier_cfo_code
                                            || ' e Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                            || '. Erro Oracle: ' || SQLERRM
                                            );
                errbuf                         := errbuf || chr(10)
                                               || '-->> 15136 - Erro ao selecionar o CFOP para'
                                               || ' o CFOP do Fornecedor = ' ||r_lin.supplier_cfo_code
                                               || ' e Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                               || '. Erro Oracle: ' || SQLERRM;
                retcode                        := 1;
                w_invoice_line_error_flag      := 'Y';
            END;
          END IF;

          IF w_invoice_line_error_flag = 'N' THEN
            fnd_file.put_line(fnd_file.log,'15137 - Seleciona a unidade de medida para'
                                        || ' UPPER(MUOM.UOM_CODE) = ' || upper(r_lin.uom)
                                        );
            BEGIN
              SELECT muom.unit_of_measure
                INTO w_uom
                FROM mtl_units_of_measure_vl        muom
               WHERE upper(muom.uom_code)                = upper(trim(r_lin.uom));
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'-->> 15138 - Erro ao selecionar a unidade de medida na tabela MTL_UNITS_OF_MEASURE_VL para'
                                            || ' UOM_CODE = ' || trim(r_lin.uom)
                                            || '. Erro Oracle: ' || SQLERRM
                                            );
                errbuf                         := errbuf || chr(10)
                                               || '-->> 15138 - Erro ao selecionar a unidade de medida na tabela MTL_UNITS_OF_MEASURE_VL para'
                                               || ' UOM_CODE = ' || trim(r_lin.uom)
                                               || '. Erro Oracle: ' || SQLERRM;
                retcode                        := 1;
                w_invoice_line_error_flag      := 'Y';
            END;
          END IF;

          IF w_invoice_line_error_flag = 'N' THEN
            fnd_file.put_line(fnd_file.log,'15140 - Busca a CST do ICMS para'
                                        || ' o CST do Fornecedor = ' || trim(r_lin.supplier_cst_icms)
                                        || ' e CFOP = ' || trim(w_cfo_code)
                                        );
            BEGIN
              SELECT ecst.cst_code
                    ,ecsc.tax_code
                INTO w_icms_cst_code
                    ,w_icms_tax_code
                FROM ct_ri_inv_entry_csts_v         ecst
                    ,ct_ri_inv_entry_cst_cfos_v     ecsc
               WHERE ecst.inv_entry_cst_id               = ecsc.inv_entry_cst_id
                 AND ecst.cst_type                       = 'ICMS'
                 AND ecst.utilization_id                 IS NULL
                 AND to_number(ecst.supplier_cst_code)   = to_number(r_lin.supplier_cst_icms)
                 AND ecsc.cfo_code                       = trim(w_cfo_code)
                 AND ecst.org_id                         = fnd_profile.value('ORG_ID');
            EXCEPTION
              WHEN OTHERS THEN
                DECLARE
                  w_msg_erro                     VARCHAR2(100);
                BEGIN
                  -- no_data_found
                  IF SQLCODE = 100 THEN
                    w_msg_erro := 'Verifique se há CST de ICMS cadastrada para';
                  -- too_many_rows
                  ELSIF SQLCODE = -1422 THEN 
                    w_msg_erro := 'Tem que haver apenas uma CST de ICMS cadastrada para';
                  -- others
                  ELSE
                    w_msg_erro := 'Erro ao buscar a CST de ICMS para';
                  END IF;
                  fnd_file.put_line(fnd_file.log,'-->> 15141 ' || w_msg_erro
                                              || ' o CST do Fornecedor = ' || trim(r_lin.supplier_cst_icms)
                                              || ' e CFOP = ' || trim(w_cfo_code)
                                              || '. Erro Oracle: ' || SQLERRM
                                              );
                  errbuf                         := errbuf || chr(10)
                                                 || '-->> 15141 ' || w_msg_erro
                                                 || ' o CST do Fornecedor = ' || trim(r_lin.supplier_cst_icms)
                                                 || ' e CFOP = ' || trim(w_cfo_code)
                                                 || '. Erro Oracle: ' || SQLERRM;
                  retcode                        := 1;
                  w_invoice_line_error_flag      := 'Y';
                END;
            END;

            fnd_file.put_line(fnd_file.log,'15142 - Busca a CST do IPI para'
                                        || ' a Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                        || ' e CST do Fornecedor = ' || trim(r_lin.supplier_cst_ipi)
                                        || ' e CFOP = ' || trim(w_cfo_code)
                                        );
            BEGIN
              SELECT ecst.cst_code
                    ,ecsc.tax_code
                INTO w_ipi_cst_code
                    ,w_ipi_tax_code
                FROM ct_ri_inv_entry_csts_v         ecst
                    ,ct_ri_inv_entry_cst_cfos_v     ecsc
               WHERE ecst.inv_entry_cst_id               = ecsc.inv_entry_cst_id
                 AND ecst.cst_type                       = 'IPI'
                 AND ecst.utilization_id                 = r_cfiu.utilization_id
                 AND to_number(ecst.supplier_cst_code)   = to_number(r_lin.supplier_cst_ipi)
                 AND ecsc.cfo_code                       = trim(w_cfo_code)
                 AND ecst.org_id                         = fnd_profile.value('ORG_ID');
            EXCEPTION
              WHEN OTHERS THEN
                DECLARE
                  w_msg_erro                     VARCHAR2(100);
                BEGIN
                  -- no_data_found
                  IF SQLCODE = 100 THEN
                    w_msg_erro := 'Verificar se há CST de IPI cadastrada para';
                  -- too_many_rows
                  ELSIF SQLCODE = -1422 THEN 
                    w_msg_erro := 'Tem que haver apenas uma CST de IPI cadastrada para';
                  -- others
                  ELSE
                    w_msg_erro := 'Erro ao buscar a CST de IPI para';
                  END IF;
                  fnd_file.put_line(fnd_file.log,'-->> 15143 ' || w_msg_erro
                                              || ' a Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                              || ' e CST do Fornecedor = ' || trim(r_lin.supplier_cst_ipi)
                                              || ' e CFOP = ' || trim(w_cfo_code)
                                              || '. Erro Oracle: ' || SQLERRM
                                              );
                  errbuf                         := errbuf || chr(10)
                                                 || '-->> 15143 ' || w_msg_erro
                                                 || ' a Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                                 || ' e CST do Fornecedor = ' || trim(r_lin.supplier_cst_ipi)
                                                 || ' e CFOP = ' || trim(w_cfo_code)
                                                 || '. Erro Oracle: ' || SQLERRM;
                  retcode                        := 1;
                  w_invoice_line_error_flag      := 'Y';
                END;
            END;

            fnd_file.put_line(fnd_file.log,'15144 - Busca a CST do PIS para'
                                        || ' a Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                        || ' e CFOP = ' || w_cfo_code
                                        );
            BEGIN
              SELECT ecst.cst_code
                INTO w_pis_cst_code
                FROM ct_ri_inv_entry_csts_v         ecst
                    ,ct_ri_inv_entry_cst_cfos_v     ecsc
               WHERE ecst.inv_entry_cst_id               = ecsc.inv_entry_cst_id
                 AND ecst.cst_type                       = 'PIS'
                 AND ecst.utilization_id                 = r_cfiu.utilization_id
                 AND ecst.supplier_cst_code              IS NULL
                 AND ecsc.cfo_code                       = w_cfo_code
                 AND ecst.org_id                         = fnd_profile.value('ORG_ID');
            EXCEPTION
              WHEN OTHERS THEN
                DECLARE
                  w_msg_erro                     VARCHAR2(100);
                BEGIN
                  -- no_data_found
                  IF SQLCODE = 100 THEN
                    w_msg_erro := 'Verificar se há CST de PIS cadastrada para';
                  -- too_many_rows
                  ELSIF SQLCODE = -1422 THEN 
                    w_msg_erro := 'Tem que haver apenas uma CST de PIS cadastrada para';
                  -- others
                  ELSE
                    w_msg_erro := 'Erro ao buscar a CST de PIS para';
                  END IF;
                  fnd_file.put_line(fnd_file.log,'-->> 15141 ' || w_msg_erro
                                              || ' a Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                              || ' e CFOP = ' || w_cfo_code
                                              || '. Erro Oracle: ' || SQLERRM
                                              );
                  errbuf                         := errbuf || chr(10)
                                                 || '-->> 15141 ' || w_msg_erro
                                                 || ' a Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                                 || ' e CFOP = ' || w_cfo_code
                                                 || '. Erro Oracle: ' || SQLERRM;
                  retcode                        := 1;
                  w_invoice_line_error_flag      := 'Y';
                END;
            END;

            fnd_file.put_line(fnd_file.log,'15144 - Busca a CST do COFINS para'
                                        || ' Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                        || ' e CFOP = ' || w_cfo_code
                                        );
            BEGIN
              SELECT ecst.cst_code
                INTO w_cofins_cst_code
                FROM ct_ri_inv_entry_csts_v         ecst
                    ,ct_ri_inv_entry_cst_cfos_v     ecsc
               WHERE ecst.inv_entry_cst_id               = ecsc.inv_entry_cst_id
                 AND ecst.cst_type                       = 'COFINS'
                 AND ecst.utilization_id                 = r_cfiu.utilization_id
                 AND ecst.supplier_cst_code              IS NULL
                 AND ecsc.cfo_code                       = w_cfo_code
                 AND ecst.org_id                         = fnd_profile.value('ORG_ID');
            EXCEPTION
              WHEN OTHERS THEN
                DECLARE
                  w_msg_erro                     VARCHAR2(100);
                BEGIN
                  -- no_data_found
                  IF SQLCODE = 100 THEN
                    w_msg_erro := 'Verificar se há CST de COFINS cadastrada para';
                  -- too_many_rows
                  ELSIF SQLCODE = -1422 THEN 
                    w_msg_erro := 'Tem que haver apenas uma CST de COFINS cadastrada para';
                  -- others
                  ELSE
                    w_msg_erro := 'Erro ao buscar a CST de COFINS para';
                  END IF;
                  fnd_file.put_line(fnd_file.log,'-->> 15141 ' || w_msg_erro
                                              || ' Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                              || ' e CFOP = ' || w_cfo_code
                                              || '. Erro Oracle: ' || SQLERRM
                                              );
                  errbuf                         := errbuf || chr(10)
                                                 || '-->> 15141 ' || w_msg_erro
                                                 || ' Utilização = ' || r_poli.transaction_reason_code || '(' || r_cfiu.utilization_id || ')'
                                                 || ' e CFOP = ' || w_cfo_code
                                                 || '. Erro Oracle: ' || SQLERRM;
                  retcode                        := 1;
                  w_invoice_line_error_flag      := 'Y';
                END;
            END;
          END IF;

          IF w_invoice_line_error_flag = 'N' THEN
            fnd_file.put_line(fnd_file.log,'15152 - Seleciona a sequencia CLL_F189_INVOICE_LINES_IFACE_S.NEXTVAL'
                                        );
            BEGIN
              SELECT cll_f189_invoice_lines_iface_s.nextval
                INTO w_interface_invoice_line_id
                FROM dual;
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'-->> 15153 - Erro ao selecionar a sequencia CLL_F189_INVOICE_LINES_IFACE_S.NEXTVAL'
                                            || '. Erro Oracle: ' || SQLERRM
                                            );
                errbuf                         := errbuf || chr(10)
                                               || '-->> 15153 - Erro ao selecionar a sequencia CLL_F189_INVOICE_LINES_IFACE_S.NEXTVAL'
                                               || '. Erro Oracle: ' || SQLERRM;
                retcode                        := 1;
                w_invoice_line_error_flag      := 'Y';
            END;
          END IF;


          w_count := nvl(c_lin%ROWCOUNT,0);

          w_tb_invoice_lines_iface(w_count).interface_invoice_line_id      := w_interface_invoice_line_id;
          w_tb_invoice_lines_iface(w_count).interface_invoice_id           := w_interface_invoice_id;
          w_tb_invoice_lines_iface(w_count).line_location_id               := r_poli.line_location_id;
          w_tb_invoice_lines_iface(w_count).item_id                        := r_poli.item_id;
          w_tb_invoice_lines_iface(w_count).classification_id              := w_classification_id;
          w_tb_invoice_lines_iface(w_count).utilization_id                 := r_cfiu.utilization_id;
          w_tb_invoice_lines_iface(w_count).cfo_code                       := w_cfo_code;
          w_tb_invoice_lines_iface(w_count).uom                            := w_uom;
          w_tb_invoice_lines_iface(w_count).quantity                       := r_lin.quantity;
          w_tb_invoice_lines_iface(w_count).unit_price                     := r_lin.unit_price;
          w_tb_invoice_lines_iface(w_count).operation_fiscal_type          := w_operation_fiscal_type;
          w_tb_invoice_lines_iface(w_count).description                    := r_poli.item_description;
          w_tb_invoice_lines_iface(w_count).icms_base                      := Round(r_lin.icms_base,2);
          w_tb_invoice_lines_iface(w_count).icms_tax                       := Round(r_lin.icms_tax,2);
          w_tb_invoice_lines_iface(w_count).icms_amount                    := Round(r_lin.icms_amount,2);
          IF r_cfiu.recover_icms_flag = 'Y' THEN
            w_tb_invoice_lines_iface(w_count).icms_amount_recover            := Round(r_lin.icms_amount,2);
          ELSE
            w_tb_invoice_lines_iface(w_count).icms_amount_recover            := 0;
          END IF;
          w_tb_invoice_lines_iface(w_count).icms_tax_code                  := w_icms_tax_code;
          w_tb_invoice_lines_iface(w_count).diff_icms_tax                  := 0;
          w_tb_invoice_lines_iface(w_count).diff_icms_amount               := 0;
          w_tb_invoice_lines_iface(w_count).ipi_base_amount                := Round(r_lin.ipi_base_amount,2);
          w_tb_invoice_lines_iface(w_count).ipi_tax                        := Round(r_lin.ipi_tax,2);
          w_tb_invoice_lines_iface(w_count).ipi_amount                     := Round(r_lin.ipi_amount,2);
          IF r_cfiu.recover_ipi_flag = 'Y' THEN
            w_tb_invoice_lines_iface(w_count).ipi_amount_recover             := Round(r_lin.ipi_amount,2);
          ELSE
            w_tb_invoice_lines_iface(w_count).ipi_amount_recover             := 0;
          END IF;
          w_tb_invoice_lines_iface(w_count).ipi_tax_code                   := w_ipi_tax_code;
          w_tb_invoice_lines_iface(w_count).total_amount                   := r_lin.total_amount + Round(r_lin.ipi_amount,2);
          w_tb_invoice_lines_iface(w_count).net_amount                     := w_tb_invoice_lines_iface(w_count).total_amount;
          w_tb_invoice_lines_iface(w_count).fob_amount                     := NULL;
          w_tb_invoice_lines_iface(w_count).icms_st_base                   := NULL;
          w_tb_invoice_lines_iface(w_count).icms_st_amount                 := NULL;
          w_tb_invoice_lines_iface(w_count).icms_st_amount_recover         := NULL;
          w_tb_invoice_lines_iface(w_count).diff_icms_amount_recover       := 0;
          w_tb_invoice_lines_iface(w_count).other_expenses                 := NULL;
          w_tb_invoice_lines_iface(w_count).freight_amount                 := NULL;
          w_tb_invoice_lines_iface(w_count).insurance_amount               := NULL;
          w_tb_invoice_lines_iface(w_count).pis_base_amount                := r_lin.pis_base_amount;
          w_tb_invoice_lines_iface(w_count).pis_tax_rate                   := r_lin.pis_tax_rate;
          w_tb_invoice_lines_iface(w_count).pis_amount                     := r_lin.pis_amount;
          IF    (r_cfiu.recover_pis_flag_cnpj = 'Y' AND w_document_type = 'CNPJ')
             OR (r_cfiu.recover_pis_flag_cpf = 'Y' AND w_document_type = 'CPF')
          THEN
            w_tb_invoice_lines_iface(w_count).pis_amount_recover             := r_lin.pis_amount;
          ELSE
            w_tb_invoice_lines_iface(w_count).pis_amount_recover             := 0;
          END IF;
          w_tb_invoice_lines_iface(w_count).cofins_base_amount             := r_lin.cofins_base_amount;
          w_tb_invoice_lines_iface(w_count).cofins_tax_rate                := r_lin.cofins_tax_rate;
          w_tb_invoice_lines_iface(w_count).cofins_amount                  := r_lin.cofins_amount;
          IF    (r_cfiu.recover_cofins_flag_cnpj = 'Y' AND w_document_type = 'CNPJ')
             OR (r_cfiu.recover_cofins_flag_cpf = 'Y' AND w_document_type = 'CPF')
          THEN
            w_tb_invoice_lines_iface(w_count).cofins_amount_recover          := r_lin.cofins_amount;
          ELSE
            w_tb_invoice_lines_iface(w_count).cofins_amount_recover          := 0;
          END IF;
          w_tb_invoice_lines_iface(w_count).creation_date                  := SYSDATE;
          w_tb_invoice_lines_iface(w_count).created_by                     := fnd_profile.value('USER_ID');
          w_tb_invoice_lines_iface(w_count).last_update_date               := SYSDATE;
          w_tb_invoice_lines_iface(w_count).last_updated_by                := fnd_profile.value('USER_ID');
          w_tb_invoice_lines_iface(w_count).last_update_login              := fnd_profile.value('LOGIN_ID');
          w_tb_invoice_lines_iface(w_count).tributary_status_code          := w_icms_cst_code;
          w_tb_invoice_lines_iface(w_count).ipi_tributary_code             := w_ipi_cst_code;
          w_tb_invoice_lines_iface(w_count).pis_tributary_code             := w_pis_cst_code;
          w_tb_invoice_lines_iface(w_count).cofins_tributary_code          := w_cofins_cst_code;
          w_tb_invoice_lines_iface(w_count).attribute_category             := 'Informações Adicionais';

          INSERT INTO cll_f189_invoice_lines_iface VALUES r_cf_inli;

        END LOOP;

      END LOOP;

    END LOOP;
    --COMMIT;
  END insere_nfe_interface_ri;

END ct_ri_802_k;
/
