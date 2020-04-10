create or replace PACKAGE BODY XXFR_AR_PCK_GERA_RI AS

  ok                              boolean      := true;
  isCommit                        boolean      := true;
  g_escopo                        varchar2(50) := 'XXFR_RI_PCK_INTEGRACAO_AR';
  g_sequencial                    varchar2(10) := '';

  g_org_id                        number       := fnd_profile.value('ORG_ID');
  g_customer_trx_id               number;
  g_trx_number                    varchar2(20);
  g_serie                         varchar2(300);
  g_serie_number                  varchar2(10);
  
  g_interface_line_context        varchar2(50);
  --
  p_approve                       varchar2(1) :='Y';
  p_delete_line                   varchar2(1) :='Y';
  p_generate_line_compl           varchar2(1) :='Y';
  --
  g_source                        varchar2(50) := 'XXFR_NFE_FORNECEDOR';
  --AR
  w_cust_trx_type_id              number;
  g_cust_trx_type_name            varchar2(50);

  w_cfop_entrada                  varchar2(20);
  w_cfop_saida                    varchar2(20);

  p_operating_unit                number;
  p_interface_invoice_id          number;

  x_errbuf                        varchar2(3000);
  x_ret_code                      number;

  r_cf_fret                       cll_f189_freight_inv_interface%rowtype;
  r_cf_invo                       cll_f189_invoices_interface%rowtype;
  r_cf_inli                       cll_f189_invoice_lines_iface%rowtype;

  w_interface_operation_id        cll_f189_invoices_interface.interface_operation_id%type;
  w_interface_invoice_id          cll_f189_invoices_interface.interface_invoice_id%type;
  --
  w_vendor_id                     po_headers_all.vendor_id%type;
  w_vendor_site_id                po_headers_all.vendor_site_id%type;
  w_terms_id                      po_headers_all.terms_id%type;
  w_freight_terms_lookup_code     po_headers_all.freight_terms_lookup_code%type;
  w_transaction_reason_code       po_lines_all.transaction_reason_code%type;
  w_location_id                   po_line_locations_all.ship_to_location_id%type;
  w_supply_cfop_code              varchar2(20);

  w_invoice_type_code             cll_f189_invoices_interface.invoice_type_code%type;
  w_invoice_type_id               cll_f189_invoices_interface.invoice_type_id%type;
  w_entity_id                     cll_f189_fiscal_entities_all.entity_id%type;
  w_business_vendor_id            cll_f189_fiscal_entities_all.business_vendor_id%type;
  w_document_type                 cll_f189_fiscal_entities_all.document_type%type;
  w_ir_vendor                     cll_f189_business_vendors.ir_vendor%type;
  w_invoice_id                    number;
  w_invoice_num                   varchar2(30);
  w_invoice_serie                 varchar2(30);
  w_batch_source_name             varchar2(50);
  w_operation_id                  number;
  w_purchase_order_num            varchar2(20);
  w_po_line_location_id           number;
  w_gl_date                       date;
  w_receive_date                  date;
  w_status                        varchar2(30);
  --
  w_invoice_type_lookup_code      varchar2(50);
  w_requisition_type              varchar2(50);
  w_description                   varchar2(300);
  w_invoide_id                    number;
  w_organization_id               number;
  w_organization_code             varchar2(50);
  w_warehouse_id                  number;
  w_document_number               varchar2(50);
  w_document_type_id              number;
  w_source_state_code             varchar2(2);
  w_destination_state_code        varchar2(2);
  w_source_state_id               number;
  w_destination_state_id          number;  
  w_count                         number;
  w_classification_id             number;
  w_utilization_id                number;
  w_classification_code           varchar2(20);
  w_interface_invoice_line_id     number;
  --
  w_cfop_id                       varchar2(50); 
  w_cfop_code                     varchar2(50); 
  w_cst_cofins                    varchar2(50);
  w_cst_icms                      varchar2(50);
  w_cst_ipi                       varchar2(50);
  w_cst_pis                       varchar2(50);
  w_fiscal_doc_model              varchar2(50);
  w_fiscal_utilization            varchar2(50);
  w_icms_tax_code                 varchar2(50);
  w_icms_type                     varchar2(50);
  w_ipi_tax_code                  varchar2(50);
  w_operation_fiscal_type         varchar2(50);
  w_eletronic_invoice_key         varchar2(200);
  w_chart_of_accounts_id          number;
  --
  w_interface_parent_id           number;
  w_interface_parent_line_id      number;

  w_invoice_parent_id             number;
  w_invoice_parent_line_id        number;

  w_invoice_parent_num            varchar(50);

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => upper(g_escopo)||'_'||g_customer_trx_id
    );
  end;

  procedure initialize is
    l_org_id              number;
    l_user_id             number;
    l_resp_id             number;
    l_resp_app_id         number;
    l_retorno             varchar2(3000);
  begin
    begin
      xxfr_pck_variaveis_ambiente.inicializar('CLL','UO_FRISIA','JEAN.BEJES');
      --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
    exception when others then
      l_retorno := 'Não foi possivel inicializar o ambiente Oracle:'||sqlerrm;
      print_log(l_retorno);
      ok:=false;
    end;
  end;

  procedure processar(
    p_customer_trx_id   in number,
    x_retorno           out varchar2
  ) is
  begin
    g_customer_trx_id := p_customer_trx_id;
    main(p_customer_trx_id, null, x_retorno);
  end;
  
  procedure main(
    p_customer_trx_id   in number,
    p_invoice_type_code in varchar2,
    x_retorno           out varchar2
  ) is
  
    e number;
  
    cursor c1 is
      select ii.invoice_num, ie.error_message, ie.invalid_value 
      from 
        cll_f189_invoices_interface ii,
        cll_f189_interface_errors   ie
      where 1=1
        and ii.interface_invoice_id = ie.interface_invoice_id
        and ii.source               = ie.source
        and ii.source               = g_source
        and ie.interface_operation_id = w_interface_operation_id
      order by ie.creation_date;
  
  begin
    g_customer_trx_id := p_customer_trx_id;
    print_log('============================================================================');
    print_log('INICIO DO PROCESSO - NFE AR -> RI '|| to_char(sysdate,'HH24:MI:SS') );
    print_log('============================================================================');
    ok := true;
    if (nvl(p_customer_trx_id,0) = 0) then
      print_log('Informe o ID da NFE !!!');
      return;
    end if;

    if (fnd_profile.value('ORG_ID') is null) then
      initialize;
    end if;
    
    print_log('ORG_ID :'||fnd_profile.value('ORG_ID'));
    print_log('USER_ID:'||fnd_profile.value('USER_ID'));
    limpa_interface(x_retorno);
    --g_invoice_type_code := p_invoice_type_code;
    -- RECUPERA INF DA NF de Entrada
    begin
      print_log('');
      print_log('Informações da NF de Entrada');
      select distinct a.customer_trx_id, a.trx_number, a.serie, a.serie_number, a.cust_trx_type_id, a.warehouse_id
      into            g_customer_trx_id, g_trx_number, g_serie, g_serie_number, w_cust_trx_type_id, w_warehouse_id
      from
        xxfr_ri_vw_inf_da_nfentrada a
        ,cll_f255_establishment_v   e
      where 1=1
        and e.inventory_organization_id = a.warehouse_id
        --and e.registration_number       = p_nf_devolucao.linha(l).nu_cnpj_emissor
        and a.customer_trx_id           = g_customer_trx_id
      ; 
      w_batch_source_name := g_serie;
      print_log('  Org Id                 :'||g_org_id);
      print_log('  Customer_trx_id        :'||g_customer_trx_id);
      print_log('  Num NF                 :'||g_trx_number);
      print_log('  Serie                  :'||g_serie);
      print_log('  Numero da Serie        :'||g_serie_number);
      print_log('  ID Transacao AR        :'||w_cust_trx_type_id);
    exception 
      when no_data_found then
        ok:=false;
        x_retorno := 'NFE não encontrada - '||sqlerrm;
        print_log(x_retorno);
      when others then
        ok:=false;
        x_retorno := 'Erro  - '||sqlerrm;
        print_log(x_retorno);
    end;
    -- Insere da Interface Header
    if (ok) then
      insere_ri_interface_header(
        p_customer_trx_id => g_customer_trx_id,
        x_retorno         => x_retorno
      );
    end if;
    -- Chama a API para a criação do documento no RI
    if (ok and isCommit) then
      commit;
      print_log('');
      print_log('Chamando...CLL_F189_OPEN_INTERFACE_PKG.OPEN_INTERFACE');
      
      --cll_f189_open_interface_pkg.open_interface (
      xxfr_f189_open_interface_pkg.open_interface (
        p_source               => g_source, 
        p_approve              => p_approve,
        p_delete_line          => p_delete_line,
        p_generate_line_compl  => p_generate_line_compl,
        p_operating_unit       => g_org_id,
        p_interface_invoice_id => w_interface_invoice_id,
        errbuf                 => x_errbuf,
        retcode                => x_ret_code
      );
      commit;
      print_log('Saida Codigo:'||x_ret_code);
      print_log('Saida Msg   :'||x_errbuf);
      e:=0;
      -- Inicia loop na tabela de Erros...
      for e1 in c1 loop
        e := e + 1;
        print_log('  Invoice Num:'||e1.invoice_num || ' - ' || e1.error_message ||' -> '||e1.invalid_value);
        ok:=false;
        x_retorno := 'ERRO AO PROCESSAR A INTERFACE';
      end loop;
      if (e = 0) then
        begin
          select invoice_id, invoice_num,   series,          entity_id,   organization_id,   location_id,   operation_id,   invoice_type_id --, creation_date
          into w_invoice_id, w_invoice_num, w_invoice_serie, w_entity_id, w_organization_id, w_location_id, w_operation_id, w_invoice_type_id
          from cll_f189_invoices 
          where 1=1
            --and ORGANIZATION_ID = 123
            and interface_invoice_id = w_interface_invoice_id
          --order by creation_date desc
          ;
        exception 
          when no_data_found then
            print_log('Interface não processada:'||sqlerrm);
            ok:=false;
          when others then
            print_log('ERRO:'||sqlerrm);
            ok:=false;
        end;
        -- Chama o processo de Aprovação...
        if (ok and isCommit) then
          --XXFR_F189_OPEN_PROCESSES_PUB.APPROVE_INTERFACE( 
          CLL_F189_OPEN_PROCESSES_PUB.APPROVE_INTERFACE( 
            p_organization_id => w_organization_id,
            p_operation_id    => w_operation_id,
            p_location_id     => w_location_id,
            p_gl_date         => w_gl_date,
            p_receive_date    => w_receive_date,
            p_created_by      => fnd_profile.value('USER_ID'),
            p_source          => g_source,
            p_interface       => 'Y',
            p_int_invoice_id  => w_interface_invoice_id
          );
          -- Recupera o Status do processo de aprovação...
          begin
            select status into w_status 
            from cll_f189_entry_operations 
            where 1=1
              and source = g_source
              and operation_id = w_operation_id
            ;
          exception when others then
            print_log('ERRO ao recuperar o Status da Aprovação:'||sqlerrm);
            ok:=false;
          end;
          -- Sinaliza o RI para a NF de Entrada
          if (ok) then
            --
            SELECT substr(NAME,1,3) 
            into w_organization_code
            FROM HR_ALL_ORGANIZATION_UNITS
            where ORGANIZATION_ID = w_organization_id
            ;
            --
            update ra_customer_trx_all
            set 
              --ATTRIBUTE15 = '011.190', 
              ATTRIBUTE15 = w_organization_code||'.'||w_operation_id, 
              ATTRIBUTE_CATEGORY = 'Informações notas de entrada'
            where 1=1
              and customer_trx_id = g_customer_trx_id
            ;
          end if;
          
          print_log('');
          print_log('== DOCUMENTO CRIADO NO RI ==');
          print_log('Status Processo:'||w_status);
          print_log('Invoice_id     :'||w_invoice_id);
          print_log('Invoice_num    :'||w_invoice_num);
          print_log('Entity_id      :'||w_entity_id);
          print_log('Organization_id:'||w_organization_id);
          print_log('Location_id    :'||w_location_id);
          print_log('Operation_Id   :'||w_operation_id);
          print_log('Invoice_type_id:'||w_invoice_type_id);
          commit;
        end if;        
      end if;
    end if;
    print_log('============================================================================');
    print_log('FIM DO PROCESSO - NFE AR -> RI '|| to_char(sysdate,'HH24:MI:SS') );
    print_log('============================================================================');
  end;

  procedure insere_ri_interface_header(
    p_customer_trx_id in number,
    x_retorno         out varchar2
  ) is

    cursor c1 is 
      select * 
      from XXFR_RI_VW_INF_DA_NFENTRADA
      where 1=1
        and customer_trx_id = p_customer_trx_id
    ;

    qtd_invoice   number;
    qtd_nfe       number;
    l_retorno     varchar2(3000);

  begin
    print_log(' '); 
    print_log('INSERE_INTERFACE_HEADER...');
    --w_invoice_type_code := g_invoice_type_code;
    qtd_invoice   := 0;
    qtd_nfe       := 0;
    -- Inicio do Loop
    for r1 in c1 loop
      r_cf_invo                      := null;
      w_interface_invoice_id         := null;
      w_vendor_id                    := r1.vendor_id;
      w_vendor_site_id               := r1.vendor_site_id;
      w_terms_id                     := r1.terms_id;
      w_cust_trx_type_id             := r1.cust_trx_type_id;
      w_organization_id              := r1.warehouse_id;
      w_freight_terms_lookup_code    := null;
      w_transaction_reason_code      := null;
      w_location_id                  := r1.location_id;
      w_supply_cfop_code             := null;
      w_entity_id                    := null;
      w_business_vendor_id           := null;
      w_document_type                := null;
      w_ir_vendor                    := null;
      w_source_state_code            := null;
      w_destination_state_code       := null;
      w_organization_id              := r1.warehouse_id;
      w_eletronic_invoice_key        := '1234';
      --
      recupera_inf_diversas(
        p_customer_trx_id  => r1.customer_trx_id,
        p_vendor_site_id   => r1.vendor_site_id,
        p_warehouse_id     => r1.warehouse_id,
        p_cust_trx_type_id => r1.cust_trx_type_id,
        x_retorno          => x_retorno
      );
      if (ok=false) then return; end if;
      
      print_log('');
      --Sequence Operation_invoice_id
      begin
        select cll.cll_f189_interface_operat_s.nextval
        into w_interface_operation_id
        from dual;
        print_log('  Interface_Operation_id:'||w_interface_operation_id);   
      exception
        when others then
          x_retorno := 'ERRO Gerando Interface_Operation_Id:'||sqlerrm;
          print_log('  '||x_retorno);
          ok:=false;
      end;
      --Sequence Interface_invoice_id
      begin
        w_interface_invoice_id := null;
        select cll_f189_invoices_interface_s.nextval
        into w_interface_invoice_id
        from dual;
      exception when others then
        x_retorno := 'ERRO Interface_Invoice_id:'||sqlerrm;
        print_log(x_retorno);
        ok := false;
        return;
      end;

      print_log('  Interface_Invoice_id  :'||w_interface_invoice_id);
      print_log('  Trx_number            :'||r1.trx_number||g_sequencial);
      print_log('  Customer_trx_id       :'||r1.customer_trx_id);
      print_log('  Organization_id       :'||w_organization_id);
      print_log('  Location_id           :'||w_location_id);
      print_log('  Tipo de Invoice       :'||w_description);

      r_cf_invo.source                      := g_source;
      r_cf_invo.comments                    := 'NFE Customer_trx_id:'||p_customer_trx_id;
      r_cf_invo.document_number             := w_document_number;
      r_cf_invo.document_type               := w_document_type;
      r_cf_invo.interface_operation_id      := w_interface_operation_id;
      r_cf_invo.interface_invoice_id        := w_interface_invoice_id;
      r_cf_invo.process_flag                := 1;
      r_cf_invo.gl_date                     := r1.trx_date;
      w_gl_date                             := r1.trx_date;
      w_receive_date                        := r1.trx_date;
      r_cf_invo.freight_flag                := 'N';
      r_cf_invo.entity_id                   := w_entity_id;
      --
      r_cf_invo.invoice_id                  := null;
      r_cf_invo.invoice_parent_id           := null; --w_invoice_parent_id;
      --
      if (w_invoice_parent_id is not null) then
        r_cf_invo.invoice_num                          := null;
      else
        r_cf_invo.invoice_num                          := r1.trx_number||g_sequencial;
      end if;

      r_cf_invo.series                               := g_serie_number;
      r_cf_invo.organization_id                      := w_organization_id;
      r_cf_invo.location_id                          := w_location_id;
      r_cf_invo.invoice_amount                       := round(r1.extended_amount,2);
      r_cf_invo.invoice_date                         := r1.trx_date;

      r_cf_invo.invoice_type_code                    := w_invoice_type_code;
      r_cf_invo.invoice_type_id                      := w_invoice_type_id; 

      r_cf_invo.icms_type                            := w_icms_type;     

      r_cf_invo.icms_base                            := 0;
      r_cf_invo.icms_tax                             := 0; --round(r1.tx_icms,2);
      r_cf_invo.icms_amount                          := 0; --null; --round(r1.icms,2);

      r_cf_invo.icms_st_base                         := null; --round(r1.extended_amount,2);
      r_cf_invo.icms_st_amount                       := null;
      r_cf_invo.icms_st_amount_recover               := null; -- Analisar
      --
      r_cf_invo.subst_icms_base                      := null;
      r_cf_invo.subst_icms_amount                    := null;
      r_cf_invo.diff_icms_tax                        := null;
      r_cf_invo.diff_icms_amount                     := 0;
      --
      r_cf_invo.ipi_amount                           := 0; --round(r1.ipi,2);

      r_cf_invo.iss_base                             := null; --round(r1.extended_amount,2);
      r_cf_invo.iss_tax                              := null; --round(r1.tx_iss,2);
      r_cf_invo.iss_amount                           := null; --round(r1.iss,2);
      r_cf_invo.ir_base                              := null; --round(r1.extended_amount,2);
      r_cf_invo.ir_tax                               := null;
      r_cf_invo.ir_amount                            := null;
      r_cf_invo.irrf_base_date                       := null; -- Analisar
      r_cf_invo.inss_base                            := null;
      r_cf_invo.inss_tax                             := null;
      r_cf_invo.inss_amount                          := null;
      r_cf_invo.ir_vendor                            := w_ir_vendor;
      r_cf_invo.ir_categ                             := null; -- Analisar
      r_cf_invo.diff_icms_amount_recover             := null; -- Analisar

      r_cf_invo.terms_id                             := w_terms_id;
      r_cf_invo.terms_date                           := r1.trx_date;
      r_cf_invo.first_payment_date                   := r1.trx_date;
      r_cf_invo.invoice_weight                       := null; --r_nofi.peso_bruto;
      r_cf_invo.source_items                         := null; -- Analisar
      r_cf_invo.total_fob_amount                     := null; -- Analisar
      r_cf_invo.total_cif_amount                     := null; -- Analisar
      r_cf_invo.fiscal_document_model                := w_fiscal_doc_model; 
      --
      r_cf_invo.gross_total_amount                   := round(r1.extended_amount,2);
      --
      r_cf_invo.source_state_id                      := w_source_state_id;
      r_cf_invo.source_state_code                    := w_source_state_code;
      r_cf_invo.destination_state_id                 := w_destination_state_id;
      r_cf_invo.destination_state_code               := w_destination_state_code;
      r_cf_invo.ship_to_state_id                     := w_destination_state_id;
      --
      r_cf_invo.receive_date                         := r1.trx_date;
      r_cf_invo.creation_date                        := sysdate;
      r_cf_invo.created_by                           := fnd_profile.value('USER_ID');
      r_cf_invo.last_update_date                     := sysdate;
      r_cf_invo.last_updated_by                      := fnd_profile.value('USER_ID');
      r_cf_invo.last_update_login                    := fnd_profile.value('LOGIN_ID');
      r_cf_invo.eletronic_invoice_key                := w_eletronic_invoice_key;
      r_cf_invo.vendor_id                            := w_vendor_id;
      r_cf_invo.vendor_site_id                       := w_vendor_site_id;
      --
      if (ok) then
        qtd_nfe := qtd_nfe + 1;
        insert into cll_f189_invoices_interface values r_cf_invo;
        if (isCommit) then commit; end if;
        --
        insere_ri_interface_lines(
          p_customer_trx_id => r1.customer_trx_id,
          x_retorno         => l_retorno
        );
        --
        print_log('  Retorno:'||l_retorno);
      end if;
    end loop;
    if (qtd_nfe = 0) then 
      ok:=false;
      l_retorno := 'Nenhuma NF encontrada para o ID Informado.';
    end if;
    x_retorno := l_retorno;
    print_log('  Qtd de NFEs enviadas para a Interface do RI: '||qtd_nfe);
    print_log(' ');
    print_log('FIM INSERE_NFE_INTERFACE_HEADER');
  exception when others then
    ok:=false;
    print_log('  **');
    x_retorno := '  ** Erro não previsto em: INSERE_NFE_INTERFACE_HEADER ->'||sqlerrm;
    print_log(x_retorno);
    print_log('FIM INSERE_NFE_INTERFACE_HEADER');
  end;

  procedure insere_ri_interface_lines(
    p_customer_trx_id in number,
    x_retorno         out varchar2
  ) is

    cursor c2 is 
      select * from 
      xxfr_ri_vw_inf_da_linha_nfe
      where 1=1
        and customer_trx_id = p_customer_trx_id
        --and line_number = p_linha.nu_linha_nota_fiscal
      order by customer_trx_id, line_type, line_number
    ;

    w_classification_id    number;

  begin
    print_log(''); 
    print_log('  INSERE_NFE_INTERFACE_LINES...');
    w_count := 0;
    --
    for r2 in c2 loop
      r_cf_inli := null;
      w_count := w_count + 1;
      print_log('    Processando linha:'||r2.customer_trx_line_id);
      --Sequence das linhas
      begin
        select cll_f189_invoice_lines_iface_s.nextval
        into w_interface_invoice_line_id
        from dual;
        print_log('    Interface_invoice_line_id:'||w_interface_invoice_line_id);
      exception
        when others then
          print_log('    ERRO SEQUENCE:' || sqlerrm);
          ok := false;
          exit;
      end;
      --
      r_cf_inli.interface_invoice_line_id      := w_interface_invoice_line_id;
      r_cf_inli.interface_invoice_id           := w_interface_invoice_id;
      r_cf_inli.item_id                        := r2.inventory_item_id;
      r_cf_inli.item_number                    := r2.line_number;
      r_cf_inli.line_num                       := null; --p_linha.nu_linha_nota_fiscal;    
      r_cf_inli.db_code_combination_id         := 11027;
      
      r_cf_inli.line_location_id               := r2.po_line_location_id;
      w_po_line_location_id                    := r2.po_line_location_id;
      
      --Recupera Classificação Fiscal
      print_log('  Recuperando Classificação Fiscal para o Item ('||r2.inventory_item_id||')');
      begin
        select c.classification_id, c.classification_code --,i.utilization_id 
        into w_classification_id,   w_classification_code --,w_utilization_id
        from 
          cll_f189_fiscal_items i, 
          cll_f189_fiscal_class c
        where 1=1 
          and i.classification_id = c.classification_id
          and i.inventory_item_id = r2.inventory_item_id 
          and i.organization_id   = r2.warehouse_id
        ;
        print_log('    Utilization ID          :'||w_utilization_id);
        print_log('    Classification ID       :'||w_classification_id);
        print_log('    Classification Code     :'||w_classification_code);
      exception
        when others then
          print_log('    Erro Informações Fiscais do Item:'||sqlerrm);
          ok:=false;
          exit;
      end;

      r_cf_inli.classification_id              := w_classification_id;
      r_cf_inli.classification_code            := w_classification_code;
      r_cf_inli.utilization_id                 := w_utilization_id;
      r_cf_inli.cfo_id                         := w_cfop_id;
      
      begin
        select unit_of_measure_tl 
        into r_cf_inli.uom
        from mtl_units_of_measure 
        where 1=1
          and language = 'PTB' 
          and uom_code = r2.uom_code
        ;
      exception
        when no_data_found then
          print_log('    Unidade de medida não encontrada na [MTL_UNITS_OF_MEASURE]:"'||r2.uom_code||'"');
          ok:=false;
          exit;
        when others then
          print_log('    Erro ao recuperar unidade de Medida:'||r2.uom_code);
          ok:=false;
          exit;
      end;
      r_cf_inli.quantity                       := r2.quantity_invoiced;

      r_cf_inli.unit_price                     := r2.unit_selling_price;
      r_cf_inli.operation_fiscal_type          := w_operation_fiscal_type;
      r_cf_inli.description                    := r2.description;
      --
      r_cf_inli.pis_base_amount                := nvl(r2.pis_base,0);
      r_cf_inli.pis_tax_rate                   := nvl(r2.pis_tx,0);
      r_cf_inli.pis_amount                     := nvl(r2.pis,0);
      r_cf_inli.pis_amount_recover             := 0;
      --
      r_cf_inli.cofins_base_amount             := nvl(r2.cofins_base,0);
      r_cf_inli.cofins_tax_rate                := nvl(r2.cofins_tx,0);
      r_cf_inli.cofins_amount                  := nvl(r2.cofins,0);
      r_cf_inli.cofins_amount_recover          := 0;
      --     
      r_cf_inli.icms_tax_code                  := w_icms_tax_code;
      r_cf_inli.icms_base                      := round(nvl(r2.icms_base,0),2);
      r_cf_inli.icms_tax                       := round(nvl(r2.icms_tx,0),2);
      r_cf_inli.icms_amount                    := round(nvl(r2.icms,0),2);
      r_cf_inli.icms_amount_recover            := 0;
      --
      r_cf_inli.ipi_tax_code                   := w_ipi_tax_code;
      r_cf_inli.ipi_base_amount                := round(nvl(r2.ipi_base,0),2);
      r_cf_inli.ipi_tax                        := round(nvl(r2.ipi_tx,0),2);
      r_cf_inli.ipi_amount                     := round(nvl(r2.ipi,0),2);
      r_cf_inli.ipi_amount_recover             := 0;
      --
      r_cf_inli.diff_icms_tax                  := 0;
      r_cf_inli.diff_icms_amount               := 0;
      r_cf_inli.diff_icms_amount_recover       := 0;
      r_cf_inli.diff_icms_base                 := 0;
      --
      r_cf_inli.icms_st_base                   := round(nvl(r2.icms_st_base,0),2);
      r_cf_inli.icms_st_amount                 := round(nvl(r2.icms_st,0),2);
      r_cf_inli.icms_st_amount_recover         := 0;
      --
      r_cf_inli.total_amount                   := r2.extended_amount + round(nvl(r2.ipi,0),2);
      r_cf_inli.net_amount                     := r_cf_inli.total_amount;
      r_cf_inli.fob_amount                     := null;

      --
      r_cf_inli.discount_amount                := 0;
      r_cf_inli.other_expenses                 := 0;
      r_cf_inli.freight_amount                 := 0;
      r_cf_inli.insurance_amount               := 0;

      r_cf_inli.creation_date                  := sysdate;
      r_cf_inli.created_by                     := fnd_profile.value('USER_ID');
      r_cf_inli.last_update_date               := sysdate;
      r_cf_inli.last_updated_by                := fnd_profile.value('USER_ID');
      r_cf_inli.last_update_login              := fnd_profile.value('LOGIN_ID');
      --
      r_cf_inli.tributary_status_code          := w_cst_icms;
      r_cf_inli.ipi_tributary_code             := w_cst_ipi;
      r_cf_inli.pis_tributary_code             := w_cst_pis;
      r_cf_inli.cofins_tributary_code          := w_cst_cofins;
      --
      r_cf_inli.attribute_category             := 'Informações Adicionais';
      --
      if (ok and w_po_line_location_id is not null) then
        print_log('    PO Line Location ID    :'||w_po_line_location_id);
        begin
          select segment1 
          into w_purchase_order_num
          from po_headers_all 
          where po_header_id = (
            select po_header_id 
            from po_line_locations_all 
            where line_location_id = w_po_line_location_id
          );
          print_log('    Numero da PO           :'||w_po_line_location_id);
          r_cf_inli.attribute_category             := 'Informações Adicionais - Numero PO:'||w_purchase_order_num;
        exception 
          when others then
           w_purchase_order_num := null;
        end;
      end if;
      r_cf_inli.purchase_order_num             := w_purchase_order_num;
      --
      if (ok) then
        insert into cll_f189_invoice_lines_iface values r_cf_inli;
      end if;
      --
    end loop;
    --
    print_log('');
    print_log('    Qtd linhas processadas:'||w_count);
    print_log('  FIM INSERE_NFE_INTERFACE_LINES');
    print_log('');
  end;

  -- ******************************************************************************
  procedure recupera_inf_diversas(
    p_customer_trx_id  in number,
    p_vendor_site_id   in number,
    p_warehouse_id     in number,
    p_cust_trx_type_id in number,
    x_retorno          out varchar
  )is
  
  begin
    --Informações do Fornecedor
    begin
      print_log('');
      print_log('Informações do Fornecedor...');
      SELECT 
           fea.entity_id, fea.business_vendor_id, fea.document_type, fea.document_number, bv.ir_vendor
      into w_entity_id,   w_business_vendor_id,   w_document_type,   w_document_number,   w_ir_vendor
      FROM 
        cll_f189_fiscal_entities_all  fea,
        cll_f189_business_vendors     bv
      WHERE 1=1    
        and bv.business_id                = fea.business_vendor_id 
        and fea.vendor_site_id            = p_vendor_site_id
      ;
      print_log('  Vendor_id             :'||w_vendor_id);
      print_log('  Vendor_site_id        :'||w_vendor_site_id);
      print_log('  Entity_Id             :'||w_entity_id);
      print_log('  IR_Vendor             :'||w_ir_vendor);
    exception when others then
      x_retorno := 'ERRO Informações do Fornecedor:'||sqlerrm;
      print_log(x_retorno);
      ok := false;
      return;
    end;
    --Recupera O Tipo De Transacao No Ar
    begin
      print_log('');
      print_log('Recupera Tipo de Transacao do AR');
      print_log('  Org Id                :'||g_org_id);
      print_log('  Id Org. Inventário    :'||p_warehouse_id);
      print_log('  Id Transacao AR       :'||w_cust_trx_type_id);
      select name  --, DESCRIPTION, TYPE
      into g_cust_trx_type_name
      from ra_cust_trx_types_all
      where 1=1
        and cust_trx_type_id = w_cust_trx_type_id
        and end_date         is null
        and org_id           = g_org_id
      ;
      print_log('  Tipo Transacao AR     :'||g_cust_trx_type_name);
    exception 
      when no_data_found then
        ok:=false;
        x_retorno := 'Tipo de Transacao do AR não encontrada - '||sqlerrm;
        print_log(x_retorno);
        return;
      when others then
        ok:=false;
        x_retorno := 'Erro  - '||sqlerrm;
        print_log(x_retorno);
        return;
    end;
    --Recupera O Tipo de Transacao No RI (Para a NF de Entrada)
    begin
      print_log('');
      print_log('Recupera Tipo de Transacao do RI...');
      select 
        v.id_tipo_de_nota_fiscal_do_ri, 
        v.tipo_de_nota_fiscal_do_ri, 
        v.cfop_entrada,   
        v.cfop_saida,
        v.tipo_de_icms,
        v.cst_cofins, 
        v.cst_icms, 
        v.cst_ipi, 
        v.cst_pis,
        v.tipo_documento_fiscal,
        v.utilizacao_fiscal,
        --
        v.indicador_tributavel_icms, 
        v.indicador_tributavel_ipi,
        --
        nvl(t.ir_vendor, w_ir_vendor),
        t.invoice_type_lookup_code,
        t.requisition_type, 
        t.description
      into 
        w_invoice_type_id,            
        w_invoice_type_code,       
        w_cfop_entrada, 
        w_cfop_saida,
        w_icms_type,
        w_cst_cofins,
        w_cst_icms,
        w_cst_ipi,
        w_cst_pis,
        w_fiscal_doc_model,
        w_fiscal_utilization,
        --
        w_icms_tax_code,
        w_ipi_tax_code,
        --
        w_ir_vendor,
        w_invoice_type_lookup_code, 
        w_requisition_type,      
        w_description 
      from
        q_pc_transferencia_ar_ri_v v,
        cll_f189_invoice_types     t
      where 1=1
        and v.id_tipo_de_nota_fiscal_do_ri = t.invoice_type_id 
        and v.id_organizacao               = t.organization_id
        and t.organization_id              = p_warehouse_id
        and v.id_tipo_de_nota_fiscal_do_ar = w_cust_trx_type_id
      ;
      print_log('  Id Transacao RI       :'||w_invoice_type_id);
      print_log('  Tipo Transacao RI     :'||w_invoice_type_code);
      print_log('  Tipo de Invoice       :'||w_description);
      print_log('  CFOP Entrada          :'||w_cfop_entrada);
      print_log('  CFOP Saida            :'||w_cfop_saida);
      --w_fiscal_doc_model := '55';       
      print_log('  Cst Cofins            :'||w_cst_cofins);
      print_log('  Cst ICMS              :'||w_cst_icms);
      print_log('  Cst IPI               :'||w_cst_ipi);
      print_log('  Cst PIS               :'||w_cst_pis);
      print_log('  Fiscal Document Model :'||w_fiscal_doc_model);
      print_log('  Fiscal Utilization    :'||w_fiscal_utilization);
      print_log('  Icms Type             :'||w_icms_type);
      print_log('  Icms Tax Code         :'||w_icms_tax_code);
      print_log('  IPI Tax Code          :'||w_ipi_tax_code);
    exception 
      when no_data_found then
        ok:=false;
        x_retorno := 'Tipo de Transacao do RI não encontrada - '||sqlerrm;
        print_log(x_retorno);
        return;
      when others then
        ok:=false;
        x_retorno := 'Erro  - '||sqlerrm;
        print_log(x_retorno);
        return;
    end;
    --Valida Operetion_Fiscal_Type
    begin      
      print_log('');
      print_log('Valida Operetion_Fiscal_Type...');
      select o.cfo_id  ,o.cfo_code  ,u.operation_fiscal_type, u.utilization_id
      into   w_cfop_id ,w_cfop_code ,w_operation_fiscal_type, w_utilization_id
      from 
        cll_f189_cfo_utilizations  u,
        cll_f189_fiscal_operations o
      where 1=1
        and u.inactive_date  is null
        and u.cfo_id         = o.cfo_id 
        and u.DESCRIPTION    = w_cfop_entrada||' - '||w_fiscal_utilization
        and o.cfo_code       = w_cfop_entrada
        --and u.utilization_id = w_fiscal_utilization
      ;
      print_log('  CFOP Id               :'||w_cfop_id);
      print_log('  CFOP Code             :'||w_cfop_code);
      print_log('  Oper Fiscal Type      :'||w_operation_fiscal_type);
    exception when others then
      x_retorno := 'ERRO Operation_fiscal_Type:'||sqlerrm;
      print_log('  ** '||x_retorno);
      ok := false;
      return;
    end;
    --Estado Origem 
    print_log('');
    print_log('Valida Estado Origem e Destino...');
    begin
      select assi.state --,assi.vendor_site_id
      into w_source_state_code
      from ap_supplier_sites_all assi
      where assi.vendor_site_id = w_vendor_site_id;

      select STATE_ID
      into w_source_state_id
      from CLL_F189_STATES
      where STATE_CODE = w_source_state_code;
      print_log('  Source_state_code     :'||w_source_state_code);
    exception when others then
      x_retorno := 'ERRO Estado Origem:('||w_vendor_site_id||') - '||sqlerrm;
      print_log(x_retorno);
      ok := false;
      return;
    end;
    --Estado Destino
    begin
      select a.REGION_2             --,a.location_id
      into w_destination_state_code --,w_location_id
      from 
        apps.cll_f255_establishment_v  a
        ,apps.ra_customer_trx_lines_all rctl
      where 1=1
        and rctl.org_id                    = a.operating_unit              
        and a.inventory_organization_id    = rctl.warehouse_id
        and rctl.customer_trx_id           = p_customer_trx_id
        and rctl.line_type                 = 'LINE'
        and rownum                         = 1
      ;       
      select STATE_ID
      into w_destination_state_id
      from CLL_F189_STATES
      where STATE_CODE = w_destination_state_code;

      print_log('  Destination_state_code:'||w_destination_state_code);
    exception when others then
      x_retorno := 'ERRO Estado Destino:('||w_vendor_site_id||') - '||sqlerrm;
      print_log(x_retorno);
      ok := false;
      return;
    end;
  end;

  procedure limpa_interface(
    x_retorno           out varchar2
  ) is
  begin
    print_log(' ');
    print_log('XXFR_AR_PCK_GERA_RI.LIMPA_INTERFACE');

    print_log('  LIMPA INTERFACE LINES PARENT...');
    delete cll_f189_invoice_line_par_int where INTERFACE_PARENT_ID in (
      select INTERFACE_PARENT_ID from cll_f189_invoice_parents_int   where 1=1 and interface_invoice_id in (
        select interface_invoice_id from cll_f189_invoices_interface where source like 'XXFR%' and nvl(PROCESS_FLAG,'1') IN ('3','1')
      )
    );
    print_log('  LIMPA INTERFACE PARENT...');
    delete cll_f189_invoice_parents_int   where 1=1 and interface_invoice_id in (
      select interface_invoice_id from cll_f189_invoices_interface where source like 'XXFR%' and nvl(PROCESS_FLAG,'1') IN ('3','1')
    );
    --
    print_log('  LIMPA INTERFACE LINES...');
    delete cll_f189_invoice_lines_iface 
    where interface_invoice_id in (
      select interface_invoice_id from cll_f189_invoices_interface 
      where source like 'XXFR%' and nvl(PROCESS_FLAG,'1') IN ('3','1')
    );
    print_log('  LIMPA INTERFACE TMP...');
    delete cll_f189_invoice_iface_tmp  
    where 1=1 
      and nvl(PROCESS_FLAG,'1') IN ('3','1')
      and source like 'XXFR%';
    --
    print_log('  LIMPA INTERFACE ERRO...');
    delete cll_f189_interface_errors 
    where interface_invoice_id in (
      select interface_invoice_id from cll_f189_invoices_interface where source like 'XXFR%' and nvl(PROCESS_FLAG,'1') IN ('3','1')
    );
    print_log('  LIMPA INTERFACE...');
    delete cll_f189_invoices_interface where source like 'XXFR%' and nvl(PROCESS_FLAG,'1') IN ('3','1');
    --
    commit;
    print_log('XXFR_AR_PCK_GERA_RI.LIMPA_INTERFACE');
  exception when others then
    ok:=false;
    rollback;
    x_retorno := 'Erro não previsto em: LIMPA_INTERFACE ->'||sqlerrm;
    print_log(x_retorno);
  end;

END;
/
