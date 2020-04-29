create or replace PACKAGE BODY XXFR_RI_PCK_INT_NFDEVOLUCAO AS

  g_org_id                        number;
  g_escopo                        varchar2(50);
  g_usuario                       varchar2(50);
  g_cd_unidade_operacional        varchar2(50);
  g_customer_trx_id               number;
  g_trx_number                    varchar2(20);
  g_serie                         varchar2(300);
  g_serie_number                  varchar2(10);
  g_sequencial                    varchar2(20) := '';
  g_interface_line_context        varchar2(50);
  g_source                        varchar2(50) := 'XXFR_NFE_DEV_FORNECEDOR';
  --
  isCommit                        boolean      := true;
  --Apenas processa o Auto-Invoice para a NF. 
  isOnlyAR                        boolean      := false;
  --
  ok                              boolean      := true;
  
  g_errMessage                    varchar2(3000);
  
  g_rec_retorno      	            xxfr_pck_interface_integracao.rec_retorno_integracao;
  g_tab_mensagens                 xxfr_pck_interface_integracao.tab_retorno_mensagens;
  g_proc_devolucao                tp_proc_devolucao;
  --
  --AR Entrada
  w_cust_trx_type_id              number;
  w_cust_trx_type_name            varchar2(50);
  
  --RI Entrada
  w_invoice_type_id               number;
  w_invoice_type_code             varchar2(50);
  
  --RI Devolução
  w_dev_invoice_type_id           number;
  w_dev_invoice_type_code         varchar2(50);
  
  --AR Devolução
  w_dev_customer_trx_id           number;
  w_dev_trx_number                varchar2(20);
  w_dev_serie                     varchar2(300);
  w_dev_serie_number              varchar2(10);
  w_dev_cust_trx_type_id          number;
  w_dev_cust_trx_type_name        varchar2(50);
  --
  w_cfop_entrada                  varchar2(20);
  w_cfop_saida                    varchar2(20);
  w_cfop_id                       NUMBER;
  w_cfop_code                     VARCHAR2(30);
  --
  w_ar_interface_flag             varchar2(20);
  
  p_approve                       varchar2(1) :='Y'; 
  p_delete_line                   varchar2(1) :='N';
  p_generate_line_compl           varchar2(1) :='N';

  p_operating_unit                number;
  p_interface_invoice_id          number;

  x_errbuf                        varchar2(3000);
  x_ret_code                      number;

  r_cf_fret                       cll_f189_freight_inv_interface%rowtype;
  r_cf_invo                       cll_f189_invoices_interface%rowtype;
  r_cf_inli                       cll_f189_invoice_lines_iface%rowtype;

  w_interface_operation_id        cll_f189_invoices_interface.interface_operation_id%type;
  w_interface_invoice_id          cll_f189_invoices_interface.interface_invoice_id%type;
  w_vendor_id                     po_headers_all.vendor_id%type;
  w_vendor_site_id                po_headers_all.vendor_site_id%type;
  w_terms_id                      po_headers_all.terms_id%type;
  w_freight_terms_lookup_code     po_headers_all.freight_terms_lookup_code%type;
  w_transaction_reason_code       po_lines_all.transaction_reason_code%type;
  w_location_id                   po_line_locations_all.ship_to_location_id%type;
  w_supply_cfop_code              varchar2(20);

  w_entity_id                     cll_f189_fiscal_entities_all.entity_id%type;
  w_business_vendor_id            cll_f189_fiscal_entities_all.business_vendor_id%type;
  w_document_type                 cll_f189_fiscal_entities_all.document_type%type;
  w_ir_vendor                     cll_f189_business_vendors.ir_vendor%type;
  w_invoice_id                    varchar2(30);
  w_invoice_num                   varchar2(30);
  w_series                        varchar2(30);
  w_operation_id                  number;
  w_purchase_order_num            varchar2(20);
  w_purchace_invoice_id           number;
  w_po_line_location_id           number;
  w_gl_date                       date;
  w_receive_date                  date;
  w_status                        varchar2(30);
  w_quantity                      number;

  w_invoice_type_lookup_code      varchar2(50);
  w_requisition_type              varchar2(50);
  w_description                   varchar2(300);

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
  w_batch_source_name             varchar2(100);
  w_batch_source_id               number;
  --
  w_cfo_entrada_id                varchar2(50);
  -- 
  w_cst_cofins                    varchar2(50);
  w_cst_icms                      varchar2(50);
  w_cst_ipi                       varchar2(50);
  w_cst_pis                       varchar2(50);
  w_fiscal_doc_model              varchar2(50);
  w_fiscal_utilization            varchar2(50);
  w_icms_tax_code                 varchar2(50);
  w_icms_type                     varchar2(50);
  w_invoice_serie                 varchar2(50);
  w_ipi_tax_code                  varchar2(50);
  w_operation_fiscal_type         varchar2(50);
  w_eletronic_invoice_key         varchar2(200);
  w_chart_of_accounts_id          number;
  --
  w_interface_invoice_line_id     number;
  --
  w_interface_parent_id           number;
  w_interface_parent_line_id      number;

  w_invoice_parent_id             number;
  w_invoice_parent_line_id        number;

  w_invoice_parent_num            varchar(50);
  --
  w_request_id                    number;

  function getInvoiceInfo(p_interface_invoice_id number) return boolean is
    l_retorno varchar2(3000);
  begin
    select invoice_id, invoice_num,   entity_id,   organization_id,   location_id,   operation_id,  invoice_type_id, ar_interface_flag
    into w_invoice_id, w_invoice_num, w_entity_id, w_organization_id, w_location_id, w_operation_id, w_invoice_type_id, w_ar_interface_flag
    from cll_f189_invoices 
    where 1=1
      and interface_invoice_id = p_interface_invoice_id
    ;
    print_log('Ar-Interf. Flag:'||w_ar_interface_flag);
    return true;
  exception when others then
    l_retorno := 'Erro ao recuperar Inf. da Invoice (Interface não processada) :'||sqlerrm;
    print_log(l_retorno);
    return false;
  end;

  function processaAutoInvoice return boolean is
    --
    vs_phase1          varchar2(100);
    vs_status1         varchar2(100);
    vs_dev_phase1      varchar2(100);
    vs_dev_status1     varchar2(100);
    vs_message1        varchar2(100);
    
    l_request_id       number;
    l_request_id2      number;
    l_user_concurrent_program_name varchar2(200);
    l_status_code      varchar2(10);
    l_completion_text  varchar2(500);
    l_errbuf           varchar2(3000);
    l_retcode          number;
    
    i                  number;
    
    cursor c1 is
      select distinct ri.invoice_type_id, ri.invoice_type_code, ri.organization_id, ri.ar_transaction_type_id, ri.ar_source_id, ar.name, ar.description 
      from 
        cll_f189_invoice_types ri,
        ra_batch_sources_all   ar
      where 1=1
        and ar.batch_source_id   = ri.ar_source_id 
        and ri.invoice_type_code = w_dev_invoice_type_code
        and ri.organization_id   = w_organization_id
     ;
 
  begin   
    print_log('');
    print_log('XXFR_RI_PCK_INT_NFDEVOLUCAO.PROCESSA_AUTO_INVOICE');
    print_log('  Invoice_type_code:'||w_dev_invoice_type_code);
    print_log('  Organization_id  :'||w_organization_id);
    xxfr_pck_variaveis_ambiente.inicializar('AR',g_cd_unidade_operacional,g_usuario);
    i:=0;
    for r1 in c1 loop
      i:=i+1;
      print_log('  Batch_source_name:'||r1.name);
      w_batch_source_name := r1.name;
      print_log('  Chamando Pre-Processo...');
      XXFR_AR_PCK_PRE_PROCESSO_NF.prc_pre_processo( 
        errbuf  => l_errbuf,
        retcode => l_retcode
      );
      print_log('    Codigo :'||l_retcode);
      print_log('    Retorno:'||l_errbuf);
      --  RAXMTR
      begin
        print_log('');
        COMMIT;
        print_log('  Chamando Autoinvoice Master Program (Programa-mestre de NFFs Automáticas)...');
        l_request_id := fnd_request.submit_request(
          application => 'AR',
          program     => 'RAXMTR', 
          description => 'Autoinvoice Master Program',
          start_time  => to_char(sysdate, 'DD/MM/YYYY HH:MI:SS'),
          sub_request => FALSE,
          argument1   => '1',
          argument2   => g_org_id,
          argument3   => r1.ar_source_id,
          argument4   => r1.name,
          argument5   => to_char(sysdate,'DD/MM/YYYY HH:MI:SS'),          
          argument6   => '',
          argument7   => '',
          argument8   => '',
          argument9   => '',
          argument10  => '',
          argument11  => '',
          argument12  => '',-- trunc(sysdate),
          argument13  => '',-- trunc(sysdate)+0.9999,
          argument14  => '',
          argument15  => '',
          argument16  => '',
          argument17  => '',
          argument18  => '',--:B_VENDA.NR_ORDEM_VENDA ,
          argument19  => '',--:B_VENDA.NR_ORDEM_VENDA,
          argument20  => '',--trunc(sysdate),
          argument21  => '',--trunc(sysdate)+0.9999,
          argument22  => '',
          argument23  => '',
          argument24  => '',
          argument25  => '',
          argument26  => 'Y',
          argument27  => ''
        );
        COMMIT;
        print_log('    Request Id :'||nvl(l_request_id,0));
        -- Aguardando encerramento da execução...
        if nvl(l_request_id,0) != 0 then
          ok := fnd_concurrent.wait_for_request(
            l_request_id
            ,1
            ,0
            ,vs_phase1
            ,vs_status1
            ,vs_dev_phase1
            ,vs_dev_status1
            ,vs_message1
          );  
          print_log('    Saida      :'||vs_dev_status1);
          print_log('    Mensagen   :'||vs_message1);
          if (vs_dev_phase1='COMPLETE' and vs_dev_status1='NORMAL') then
            ok:=true;
          else
            ok:=false;
          end if;
        else
          ok:=false;
          print_log('    Falha na importação de NF');
        end if;
      end;
      --
      if (ok) then
        print_log('  Chamando Pos-Processo...');
        XXFR_AR_PCK_POS_PROCESSO_NF.prc_pos_processo( 
          errbuf  => l_errbuf,
          retcode => l_retcode
        );
        COMMIT;  
        print_log('    Codigo     :'||l_retcode);
        print_log('    Retorno    :'||l_errbuf);
      end if;
      --
    end loop;
    --
    if (i=0) then 
      ok:=false;
      g_errMessage := 'Vinculo de Origens entre AR e RI não encontrado [invoice_type_code][organization_id]:['||w_dev_invoice_type_code||']['||w_organization_id||']';
      print_log('  '||g_errMessage);
    end if;
    if (ok) then
      begin
        select distinct r.request_id, r.status_code, r.completion_text, p.user_concurrent_program_name 
        into l_request_id2, l_status_code, l_completion_text, l_user_concurrent_program_name 
        from 
          apps.fnd_concurrent_requests    r,
          apps.fnd_concurrent_programs_tl p
        where 1=1
          and p.concurrent_program_id = r.concurrent_program_id 
          and p.language              = 'PTB'
          and r.priority_request_id   = l_request_id
          and r.request_id            <> priority_request_id
        ;
        print_log('    Request Id2:'||nvl(l_request_id2,0));
        print_log('    Concurrent :'||l_user_concurrent_program_name );
        print_log('    Saida      :'||l_status_code);
        w_request_id := l_request_id2;
        if (l_status_code = 'E') then
          print_log('    ***');
          print_log('    Msg:'||l_completion_text);
          print_log('    ***');
          g_errMessage := l_completion_text;
          ok:=false;
        end if;
      exception when no_data_found then
        g_errMessage := 'Concurrent Finalizador do Auto Invoice não foi iniciado !';
        print_log('  '||g_errMessage);
        ok:=false;
      end;
    end if;
    print_log('FIM XXFR_RI_PCK_INT_NFDEVOLUCAO.PROCESSA_AUTO_INVOICE');
    return ok;
  end;

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;

  procedure initialize is
    l_org_id              number := fnd_profile.value('ORG_ID');
    l_user_id             number;
    l_resp_id             number;
    l_resp_app_id         number;
  begin
    xxfr_pck_variaveis_ambiente.inicializar('CLL',g_cd_unidade_operacional,g_usuario); 
    g_org_id := fnd_profile.value('ORG_ID');
  end;

  procedure retornar_clob( 
    p_id_integracao_detalhe in xxfr.xxfr_integracao_detalhe.id_integracao_detalhe%type, 
    p_retorno             in out clob
  ) is
  begin
    select ds_dados_retorno into p_retorno 
    from xxfr.xxfr_integracao_detalhe t
    where id_integracao_detalhe = p_id_integracao_detalhe;
    exception
      when others then
        p_retorno := null;
  end;

  procedure carrega_dados(
		p_id_integracao_detalhe IN  NUMBER,
    x_retorno               OUT varchar2
  ) is

    cursor c1 is 
      select distinct 
        id_integracao_detalhe,
        cd_unidade_operacional,
        usuario,
        ie_aprova_requisicao,
        cd_fornecedor, 
        --cd_local_fornecedor, 
        nu_propriedade_fornecedor, 
        cd_tipo_recebimento, 
        cd_referencia_origem, 
        tp_referencia_origem 
      from xxfr_ri_vw_int_proc_devolucao 
      where id_integracao_detalhe = p_id_integracao_detalhe
    ;
    --
    cursor c2(p_cd_fornecedor in varchar2, p_nu_propriedade_fornecedor in varchar2) is 
      select distinct 
        cd_referencia_origem_linha, 
        tp_referencia_origem_linha, 
        nu_linha_devolucao, nu_cnpj_emissor, nu_nota_fiscal, cd_serie, nu_linha_nota_fiscal, qt_quantidade, cd_unidade_medida
      from xxfr_ri_vw_int_proc_devolucao 
      where 1=1
        and id_integracao_detalhe     = p_id_integracao_detalhe
        and cd_fornecedor             = p_cd_fornecedor
        and nu_propriedade_fornecedor = p_nu_propriedade_fornecedor
      ;
    --
    l_nf_devolucao     array_nf_devolucao;
    l_linha            array_linha;
    --
    t_nf_devolucao     tp_nf_devolucao;
    t_linha            tp_linha;
    --
    i                  number;
    l                  number;

  begin
    g_proc_devolucao := null;
    l_nf_devolucao := array_nf_devolucao();
    i := 0;
    print_log('Carregando JSON...');
    begin
      for r1 in c1 loop
        i:=i+1;
        print_log('{');

        p_approve := 'N';
        if (r1.ie_aprova_requisicao = 'SIM') then
          p_approve := 'Y';
        end if;

        print_log('  Unidade Operacional :'||r1.cd_unidade_operacional);
        print_log('  Usuario             :'||r1.usuario);
        print_log('  Cod_fornecedor      :'||r1.cd_fornecedor);
        print_log('  Cod Tipo Recebimento:'||r1.cd_tipo_recebimento);
        
        g_cd_unidade_operacional := r1.cd_unidade_operacional;
        g_usuario := r1.usuario;
        
        l_nf_devolucao.extend;
        l_nf_devolucao(i).cd_fornecedor             := r1.cd_fornecedor;
        --l_nf_devolucao(i).cd_local_fornecedor       := r1.cd_local_fornecedor;
        l_nf_devolucao(i).nu_propriedade_fornecedor := r1.nu_propriedade_fornecedor;
        l_nf_devolucao(i).cd_tipo_recebimento       := r1.cd_tipo_recebimento;
        l_nf_devolucao(i).cd_referencia_origem      := r1.cd_referencia_origem;
        l_nf_devolucao(i).tp_referencia_origem      := r1.tp_referencia_origem;
        --
        l_linha := array_linha();
        l := 0;
        for r2 in c2(r1.cd_fornecedor, r1.nu_propriedade_fornecedor) loop
          print_log(' {');
          print_log('    nu_nota_fiscal    :'||r2.nu_nota_fiscal);
          print_log('    nu_linha_devolucao:'||r2.nu_linha_devolucao);
          print_log('    qt_quantidade     :'||r2.qt_quantidade);
          l := l +1;
          l_linha.extend;
          l_linha(l).cd_referencia_origem_linha := r2.cd_referencia_origem_linha;
          l_linha(l).tp_referencia_origem_linha := r2.tp_referencia_origem_linha;
          --
          l_linha(l).nu_linha_devolucao         := r2.nu_linha_devolucao;
          l_linha(l).nu_cnpj_emissor            := r2.nu_cnpj_emissor;
          l_linha(l).nu_nota_fiscal             := r2.nu_nota_fiscal;
          l_linha(l).cd_serie                   := r2.cd_serie;
          l_linha(l).nu_linha_nota_fiscal       := r2.nu_linha_nota_fiscal;
          l_linha(l).qt_quantidade              := r2.qt_quantidade;
          l_linha(l).cd_unidade_medida          := r2.cd_unidade_medida;
          print_log('  }');
        end loop;
        print_log('}');
        l_nf_devolucao(i).linha := l_linha;
      end loop;
      g_proc_devolucao.nf_devolucao := l_nf_devolucao;
      x_retorno := 'S';
    exception
      when others then
        ok:=false;
        x_retorno := 'ERRO AO CARREGAR O JSON:'||sqlerrm;
        print_log(x_retorno);
    end;
  end;

  procedure processar_devolucao(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  ) is

    l_nf_devolucao     array_nf_devolucao;
    l_linha            array_linha;
    t_nf_devolucao     tp_nf_devolucao;
    t_linha            tp_linha;
    --
    i                  number;
    j                  number;
    l                  number;

    l_retorno          varchar2(3000);

  begin
    g_escopo := 'DEVOLUCAO_NF_FORNECEDOR_'||p_id_integracao_detalhe;
    print_log('============================================================================');
    print_log('INICIO DO PROCESSO - NFE AR -> RI (DEVOLUCAO)'|| to_char(sysdate,'HH24:MI:SS') || 'Vr 2020-04-23-001');
    print_log('============================================================================');
    print_log('XXFR_RI_PCK_INT_NFDEVOLUCAO.PROCESSAR_DEVOLUCAO:'||p_id_integracao_detalhe);
    g_rec_retorno := null;
    g_rec_retorno."contexto"    := 'DEVOLUCAO_NF_FORNECEDOR';

    ok := true;
    -- Carrega dados do JSON
    carrega_dados(
      p_id_integracao_detalhe => p_id_integracao_detalhe,
      x_retorno               => l_retorno
    );    
    -- Inicializa ambiente e limpa tabelas temporarias
    if (ok) then
      limpa_interface(x_retorno => l_retorno);
      initialize;
      if (g_proc_devolucao.nf_devolucao.count > 1) then
        l_retorno := 'Este Integração so processa 1 (uma) NF por vez !';
        ok:=false;
      end if;
    end if; 
    i:=1; -- Será fixo com "1". Se uma futura versão contemplar mais de 1 NF por JSON, sera feito um loop com "g_proc_devolucao.nf_devolucao.count"
    -- ********************************************************************
    -- Gera e Processa a Interface do RI
    if (ok) then
      gera_interface(
        p_nf_devolucao    => g_proc_devolucao.nf_devolucao(i),
        x_retorno         => l_retorno
      );
    end if;
    -- ********************************************************************
    -- Processa o Autoinvoice do AR
    if (ok and isCommit) then
      ok := processaAutoInvoice;
      l_retorno := g_errMessage;
      -- Verifica se a NF foi criada no AR
      if (ok) then
        j:=0;
        for r2 in (
          select CUSTOMER_TRX_ID, TRX_NUMBER, SERIE_NUMBER from XXFR_RI_VW_INF_DA_NFENTRADA where CUSTOMER_TRX_ID in (
            select CUSTOMER_TRX_ID
            from ra_customer_trx_all 
            where 1=1
              and interface_header_context='CLL F189 INTEGRATED RCV'
              and request_id = w_request_id
          )
        ) loop
          j:=j+1;
          w_dev_customer_trx_id := r2.customer_trx_id;
          w_dev_trx_number      := r2.trx_number;
          w_dev_serie_number    := r2.serie_number;
          print_log('  NF('||j||')');
          print_log('    ID NF Devolucao :'|| r2.customer_trx_id);
          print_log('    Num NF Devolucao:'|| r2.trx_number);
          --
          select substr(name,1,3) into w_organization_code
          from hr_all_organization_units
          where organization_id = w_organization_id;
          --
          update ra_customer_trx_all
          set 
            attribute15 = w_organization_code||'.'||w_operation_id, 
            attribute_category = 'Informações notas de entrada'
          where 1=1
            and interface_header_context = 'CLL F189 INTEGRATED RCV'
            and request_id               = w_request_id
            and customer_trx_id          = w_dev_customer_trx_id
          ;
          l_retorno:= 'S';
        end loop;
        if (j=0) then
          l_retorno:='NF Devolução não gerada no AR';
          print_log(l_retorno);
          ok:=false;
          -- Captura mensagens de erro na RA_INTERFACE_ERRORS_ALL
          for r1 in (
            select e.message_text, nvl(e.invalid_value,'NA') valor_invalido, L.INTERFACE_LINE_ID, L.REQUEST_ID, L.INTERFACE_LINE_ATTRIBUTE3, L.INTERFACE_LINE_ATTRIBUTE4, L.CREATION_DATE
            from 
              ra_interface_lines_all  l,
              ra_interface_errors_all e
            where 1=1
              and l.interface_line_id         = e.interface_line_id
              and l.interface_line_context    ='CLL F189 INTEGRATED RCV'
              and l.batch_source_name         = w_batch_source_name
              and l.interface_line_attribute3 = w_invoice_id
            ) loop
              j:= j+1;
              g_rec_retorno."registros"(i)."mensagens"(j)."tipoMensagem" := 'ERRO';
              g_rec_retorno."registros"(i)."mensagens"(j)."mensagem"     := r1.message_text;
          end loop;
        end if;
      end if;        
    end if;
    -- ********************************************************************
    -- Monta o JSON de Retorno 
    if (ok and isCommit) then
      g_rec_retorno."registros"(i)."retornoProcessamento" := 'SUCESSO';
      --
      select-- a.customer_trx_id, a.serie, a.serie_number, 
        a.cust_trx_type_id, c.name
      into w_dev_cust_trx_type_id, w_dev_cust_trx_type_name 
      from
        xxfr_ri_vw_inf_da_nfentrada a
        ,ra_cust_trx_types_all      c
      where 1=1
        and c.end_date          is null
        and c.cust_trx_type_id  = a.cust_trx_type_id
        and c.org_id            = g_org_id
        and a.customer_trx_id   = w_dev_customer_trx_id
      ;
      g_rec_retorno."registros"(i)."tipoCabecalho"          := w_dev_cust_trx_type_name;  
      g_rec_retorno."registros"(i)."codigoCabecalho"        := g_proc_devolucao.nf_devolucao(1).linha(1).nu_cnpj_emissor||'.'||w_dev_trx_number||'.'||w_dev_serie_number;
      --
      g_rec_retorno."registros"(i)."linhas"(1)."tipoLinha"                   := 'LINE';
      g_rec_retorno."registros"(i)."linhas"(1)."codigoLinha"                 := '1';
      g_rec_retorno."registros"(i)."linhas"(1)."tipoReferenciaLinhaOrigem"   := g_proc_devolucao.nf_devolucao(1).tp_referencia_origem;
      g_rec_retorno."registros"(i)."linhas"(1)."codigoReferenciaLinhaOrigem" := g_proc_devolucao.nf_devolucao(1).cd_referencia_origem;
    else
      g_rec_retorno."registros"(i)."retornoProcessamento" := 'ERRO';
    end if; 
    
    g_rec_retorno."registros"(i)."tipoReferenciaOrigem"   := g_proc_devolucao.nf_devolucao(1).tp_referencia_origem;
    g_rec_retorno."registros"(i)."codigoReferenciaOrigem" := g_proc_devolucao.nf_devolucao(1).cd_referencia_origem;
    --
    print_log(' ');
    if (ok) then
      print_log('  SUCESSO !!!');
      g_rec_retorno."retornoProcessamento"         := 'SUCESSO';
      g_rec_retorno."mensagemRetornoProcessamento" := null;
      xxfr_pck_interface_integracao.sucesso (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
      COMMIT;
    else
      print_log('  ERRO !!!');
      if (isCommit) then ROLLBACK; end if;
      g_rec_retorno."retornoProcessamento"         := 'ERRO';
      g_rec_retorno."mensagemRetornoProcessamento" := l_retorno;
      xxfr_pck_interface_integracao.erro (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    end if;
    retornar_clob( 
      p_id_integracao_detalhe => p_id_integracao_detalhe, 
      p_retorno               => p_retorno
    );
    --
    print_log(p_retorno);
    print_log('----------------------------------------------------------------');
    print_log('FIM DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS'));
    print_log('----------------------------------------------------------------');
  exception when others then
    ok:=false;
    if (isCommit) then ROLLBACK; end if;
    p_retorno := 'Erro não previsto em: PROCESSAR_DEVOLUCAO ->'||sqlerrm;
    print_log(p_retorno);
    g_rec_retorno."retornoProcessamento"         := 'ERRO';
    g_rec_retorno."mensagemRetornoProcessamento" := p_retorno;
    xxfr_pck_interface_integracao.erro (
      p_id_integracao_detalhe   => p_id_integracao_detalhe,
      p_ds_dados_retorno        => g_rec_retorno
    );
    retornar_clob( 
      p_id_integracao_detalhe => p_id_integracao_detalhe, 
      p_retorno               => p_retorno
    );
  end;

  procedure gera_interface(
    p_nf_devolucao      in tp_nf_devolucao,
    x_retorno           out varchar2
  ) is

    l_retorno           varchar2(3000); 
    l_qtd_interface_ar  number;
    l                   number;
    e                   number;
    l_phase             varchar2(50);
    l_status            varchar2(50);
    l_dev_phase         varchar2(50);
    l_dev_status        varchar2(50);
    l_message           varchar2(50);
    l_request_id        number;

    cursor c1 is
      select ii.invoice_num, ie.error_message, ie.invalid_value 
      from 
        cll_f189_invoices_interface ii,
        cll_f189_interface_errors   ie
      where 1=1
        and ii.interface_invoice_id   = ie.interface_invoice_id
        and ii.source                 = ie.source
        and ii.source                 = g_source
        and ie.interface_operation_id = w_interface_operation_id
      order by ie.creation_date
    ;
    
  begin
    print_log('XXFR_RI_PCK_INT_NFDEVOLUCAO.GERA_INTERFACE');
    for l in 1 .. p_nf_devolucao.linha.count loop
      --
      print_log('**** Informações da NF de Entrada a ser Devolvida ****');
      print_log('  Fornecedor               :'||p_nf_devolucao.cd_fornecedor);
      print_log('  Cnpj Emissor             :'||p_nf_devolucao.linha(l).nu_cnpj_emissor);
      -- RECUPERA INF DA NF de Entrada
      begin
        select a.customer_trx_id, a.serie, a.serie_number, a.cust_trx_type_id, c.name, a.warehouse_id
        into g_customer_trx_id,   g_serie, g_serie_number, w_cust_trx_type_id, w_cust_trx_type_name, w_warehouse_id
        from
          xxfr_ri_vw_inf_da_nfentrada a
          ,cll_f255_establishment_v   e
          ,ra_cust_trx_types_all      c
        where 1=1
          and e.inventory_organization_id = a.warehouse_id
          and c.end_date                  is null
          and c.cust_trx_type_id          = a.cust_trx_type_id
          and c.org_id                    = g_org_id
          and e.registration_number       = p_nf_devolucao.linha(l).nu_cnpj_emissor
          and a.trx_number                = p_nf_devolucao.linha(l).nu_nota_fiscal
          and a.ACCOUNT_NUMBER            = p_nf_devolucao.cd_fornecedor
          --and a.VENDOR_SITE_CODE          = p_nf_devolucao.cd_fornecedor||'.'||p_nf_devolucao.nu_propriedade_fornecedor
          --and a.cust_account_id           = p_nf_devolucao.cd_fornecedor
        ; 
        w_batch_source_name := g_serie;
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
      print_log('  Org Id                   :'||g_org_id);
      print_log('  Customer_trx_id (Entrada):'||g_customer_trx_id);
      print_log('  Num NF (Entrda)          :'||p_nf_devolucao.linha(l).nu_nota_fiscal);
      print_log('  Serie                    :'||g_serie);
      print_log('  Numero da Serie          :'||g_serie_number);
      print_log('  ID Transacao AR          :'||w_cust_trx_type_id);
      print_log('  Tipo Transacao AR        :'||w_cust_trx_type_name);
      print_log('******************************************************');
      --
      -- POPULA A INTERFACE HEADER
      if (ok) then
        insere_interface_header(
          p_customer_trx_id   => g_customer_trx_id,
          --p_invoice_type_code => p_nf_devolucao.cd_tipo_recebimento,
          p_nf_devolucao      => p_nf_devolucao,
          p_linha             => p_nf_devolucao.linha(l),
          x_retorno           => l_retorno
        );
        x_retorno := l_retorno;
      end if;
      if (ok = false) then
        exit;
      end if;
    end loop;
    -- Testa se deve rodar apenas o Autoinvoice...
    if (isOnlyAR = false) then
      -- Processa a Interface do RI
      if (ok and isCommit) then
        print_log(' ');
        print_log('Chamando CLL_F189_OPEN_INTERFACE_PKG.OPEN_INTERFACE('||w_interface_invoice_id||')');
        COMMIT;
        --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
        cll_f189_open_interface_pkg.open_interface (
        --xxfr_f189_open_interface_pkg.open_interface (
          p_source               => g_source, 
          p_approve              => p_approve,
          p_delete_line          => p_delete_line,
          p_generate_line_compl  => p_generate_line_compl,
          p_operating_unit       => g_org_id,
          p_interface_invoice_id => w_interface_invoice_id,
          errbuf                 => x_errbuf,
          retcode                => x_ret_code
        );
        COMMIT;
        --
        print_log('Saida Codigo:'||x_ret_code);
        print_log('Saida Msg   :'||x_errbuf);
        e:=0;
      end if;
      -- Loop das mensagens de erros
      if (ok and isCommit) then
        for e1 in c1 loop
          e := e + 1;
          print_log('  Invoice Num:'||e1.invoice_num || ' - ' || e1.error_message ||' -> '||e1.invalid_value);
          g_rec_retorno."registros"(1)."mensagens"(e)."tipoMensagem" := 'ERRO';
          g_rec_retorno."registros"(1)."mensagens"(e)."mensagem"     := 'Invoice Num: '||e1.invoice_num || ' - ' || e1.error_message ||' -> '||e1.invalid_value;
          ok:=false;
          x_retorno := 'Erro ao processas a Interface';
        end loop;
        -- FIM LOOP DAS MSG DE ERROS
      end if;
      -- Processo de Aprovação
      if (ok and e = 0 and isCommit) then
        -- Recupera Informações da Invoice no RI
        ok := getInvoiceInfo(w_interface_invoice_id);
        -- Aprova Invoice no RI
        if (isCommit and ok and p_approve = 'Y') then
          print_log('Chamando...CLL_F189_OPEN_PROCESSES_PUB.APPROVE_INTERFACE...');
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
          COMMIT;
        end if;
        -- Recupera Status da Aprovação
        begin
          select status into w_status 
          from cll_f189_entry_operations 
          where 1=1
            and source       = g_source
            and operation_id = w_operation_id
          ;
        exception when others then
          l_retorno := 'Erro ao recuperar o Status da Aprovação :'||sqlerrm;
          ok:=false;
        end;
        print_log(' ');
        print_log('== DOCUMENTO CRIADO NO RI ==');
        print_log('Status Processo:'||w_status);
        print_log('Invoice_id     :'||w_invoice_id);
        print_log('Invoice_num    :'||w_invoice_num);
        print_log('Entity_id      :'||w_entity_id);
        print_log('Organization_id:'||w_organization_id);
        print_log('Location_id    :'||w_location_id);
        print_log('Operation_Id   :'||w_operation_id);
        print_log('Invoice_type_id:'||w_invoice_type_id); 
        print_log('Origem         :'||g_source);
        if (w_status <> 'COMPLETE') then
          ok:=false;
          l_retorno := 'Processo de aprovação do RI:'||w_status;
          print_log(l_retorno);
        end if;
      end if;
      -- Envia para a Interface do AR
      if (ok and w_status = 'COMPLETE' and w_invoice_parent_id is not null) then
        print_log('');
        /*
        -- Desativado apos a aplicação do Patch da Oracle
        --print_log('Chamando CLL_F189_INTERFACE_PKG.AR...');
        --cll_f189_interface_pkg.ar (w_operation_id, w_organization_id) ; 
        --COMMIT;
        */
        ok := getInvoiceInfo(w_interface_invoice_id);
        if (ok) then 
          l_qtd_interface_ar := 1;
          l_retorno := 'S';
        else
          l_retorno:='Interface do AR não populada !';
          ok:=false;
        end if;
      end if;
    end if;
    x_retorno := l_retorno;
  end;

  procedure insere_interface_header(
    p_customer_trx_id   in number,  
    --p_invoice_type_code in varchar2,
    p_nf_devolucao      in tp_nf_devolucao,
    p_linha             in tp_linha,
    x_retorno           out varchar2
  ) is

    cursor c1 is 
      select * 
      from XXFR_RI_VW_INF_DA_NFENTRADA
      where 1=1
        and customer_trx_id = p_customer_trx_id
    ;

    qtd_invoice   number;
    qtd_nfe       number;
    p_retorno     varchar2(3000);

  begin
    print_log(' '); 
    print_log('INSERE_INTERFACE_HEADER...');
    qtd_invoice   := 0;
    qtd_nfe       := 0;
    for r1 in c1 loop
      
      /*
      print_log('Vai 1 - ['||p_invoice_type_code||']['||r1.warehouse_id||']');
      select invoice_type_id, invoice_type_code 
      into w_dev_invoice_type_id, w_dev_invoice_type_code 
      from cll_f189_invoice_types
      where 1=1
        and invoice_type_code = p_invoice_type_code
        and organization_id   = r1.warehouse_id
      ;
      print_log('  Id Transacao Dev RI    :'||w_dev_invoice_type_id);
      print_log('  Tipo Transacao Dev RI  :'||w_dev_invoice_type_code);
      */
      
      print_log('Vai 2');
      select ec_id_tp_nf_dev_ri, ec_tp_nf_dev_ri 
      into w_dev_invoice_type_id, w_dev_invoice_type_code
      from q_pc_transferencia_ar_ri_v
      where 1=1
        and ec_tp_nf_ar       = w_cust_trx_type_name
        and ec_id_organizacao = r1.warehouse_id
      ;
      print_log('  Id Transacao Dev RI    :'||w_dev_invoice_type_id);
      print_log('  Tipo Transacao Dev RI  :'||w_dev_invoice_type_code);

      
      r_cf_invo                      := null;
      w_interface_invoice_id         := null;
      w_vendor_id                    := r1.vendor_id;
      w_vendor_site_id               := r1.vendor_site_id;
      w_terms_id                     := r1.terms_id;
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
      
      --Verifica NF Pai no RI!
      print_log('Valida NF Pai no RI (NF de Entrada)...');
      begin
        select invoice_id, invoice_num
        into w_invoice_parent_id, w_invoice_parent_num 
        from cll_f189_invoices              
        where 1=1
          and invoice_num     = r1.trx_number||g_sequencial 
          and entity_id       = w_entity_id 
          and organization_id = w_organization_id 
          and location_id     = w_location_id
        ; 
        print_log('  ID NF Pai no RI       :'||w_invoice_parent_id);
        print_log('  Num NF Pai no RI      :'||w_invoice_parent_num );
      exception when others then
        print_log('');
        x_retorno := '*** Não encontrada NF Pai no RI ***';
        print_log('  '||x_retorno);
        print_log('');
        w_invoice_parent_id  := null;
        ok:=false;
        return;
      end;
      print_log('');
      --Sequence Interface_invoice_id
      w_interface_invoice_id := null;
      begin
        select cll_f189_invoices_interface_s.nextval
        into w_interface_invoice_id
        from dual;
      exception when others then
        x_retorno := 'ERRO Interface_Invoice_id:'||sqlerrm;
        print_log(x_retorno);
        ok := false;
        return;
      end;
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

      r_cf_invo.source                      := g_source;
      r_cf_invo.comments                    := 'NF (Entrada) Customer_trx_id:'||p_customer_trx_id;
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

      r_cf_invo.invoice_type_code                    := w_dev_invoice_type_code;
      r_cf_invo.invoice_type_id                      := w_dev_invoice_type_id; 

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

      print_log('  Interface_Invoice_id  :'||w_interface_invoice_id);
      print_log('  Organization_id       :'||w_organization_id);
      print_log('  Location_id           :'||w_location_id);
      if (ok) then
        qtd_nfe := qtd_nfe + 1;
        insert into cll_f189_invoices_interface values r_cf_invo;
        --
        if (w_invoice_parent_id is not null) then
          insere_interface_parent_header(
            p_invoice_parent_id  => w_invoice_parent_id,
            p_invoice_date       => r_cf_invo.invoice_date,
            p_invoice_parent_num => w_invoice_parent_num,
            x_retorno            => p_retorno
          );
          p_generate_line_compl := 'S';
        end if;
        --
        insere_interface_lines(
          p_customer_trx_id => r1.customer_trx_id,
          p_nf_devolucao    => p_nf_devolucao,
          p_linha           => p_linha,
          x_retorno         => p_retorno
        );
        --
        print_log('  Retorno:'||p_retorno);
        x_retorno := p_retorno;
      end if;

    end loop;
    if (qtd_nfe = 0) then ok:=false; end if;
    print_log('  Qtd de NFEs enviadas para a Interface do RI: '||qtd_nfe);
    print_log(' ');
    print_log('FIM INSERE_NFE_INTERFACE_HEADER');
  exception when others then
    ok:=false;
    x_retorno := 'Erro não previsto em: INSERE_NFE_INTERFACE_HEADER ->'||sqlerrm;
    print_log(x_retorno);
  end;

  procedure insere_interface_parent_header(
    p_invoice_parent_id     in number,
    p_invoice_date          in date,
    p_invoice_parent_num    in varchar2,
    x_retorno               out varchar2
  ) is

    parent_header cll_f189_invoice_parents_int%rowtype;

  begin
    print_log(' '); 
    print_log('  INSERE_INTERFACE_PARENT_HEADER');
    --
    select cll_f189_invoice_parents_int_s.nextval
    into w_interface_parent_id
    from dual;

    print_log('    w_interface_parent_id:'||w_interface_parent_id);

    parent_header.interface_parent_id   := w_interface_parent_id;
    parent_header.interface_invoice_id  := w_interface_invoice_id;
    --
    parent_header.invoice_parent_id     := p_invoice_parent_id;
    parent_header.invoice_parent_num    := p_invoice_parent_num;
    --
    parent_header.entity_id             := null; --w_entity_id;
    parent_header.invoice_date          := p_invoice_date;
    parent_header.creation_date         := sysdate;
    parent_header.created_by            := fnd_profile.value('USER_ID');
    parent_header.last_update_date      := sysdate;
    parent_header.last_updated_by       := fnd_profile.value('USER_ID');
    parent_header.last_update_login     := fnd_profile.value('LOGIN_ID');
    parent_header.request_id            := null;
    parent_header.program_application_id:= null;
    parent_header.program_id            := null;
    parent_header.program_update_date   := null;
    --
    parent_header.attribute_category    := null;
    --
    parent_header.attribute1 := null;
    parent_header.attribute2 := null;
    parent_header.attribute3 := null;
    parent_header.attribute4 := null;
    parent_header.attribute5 := null;
    parent_header.attribute6 := null;
    parent_header.attribute7 := null;
    parent_header.attribute8 := null;
    parent_header.attribute9 := null;
    parent_header.attribute10:= null;
    parent_header.attribute11:= null;
    parent_header.attribute12:= null;
    parent_header.attribute13:= null;
    parent_header.attribute14:= null;
    parent_header.attribute15:= null;
    parent_header.attribute16:= null;
    parent_header.attribute17:= null;
    parent_header.attribute18:= null;
    parent_header.attribute19:= null;
    parent_header.attribute20:= null;
    --
    begin
    INSERT INTO cll_f189_invoice_parents_int VALUES parent_header;
    exception when others then
      print_log('    Erro ao inserir cll_f189_invoice_parents_int:'||sqlerrm);
    end;
    --
    print_log('  FIM INSERE_INTERFACE_PARENT_HEADER');
    print_log(' ');
  exception when others then
    ok:=false;
    x_retorno := 'Erro não previsto em: INSERE_INTERFACE_PARENT_HEADER ->'||sqlerrm;
    print_log(x_retorno);
  end;

  procedure insere_interface_lines(
    p_customer_trx_id   in number, 
    p_nf_devolucao      in tp_nf_devolucao,
    p_linha             in tp_linha,
    x_retorno           out varchar2
  ) is

    cursor c2 is 
      select * from 
      xxfr_ri_vw_inf_da_linha_nfe
      where 1=1
        and customer_trx_id = p_customer_trx_id
        and line_number     = p_linha.nu_linha_nota_fiscal
      order by customer_trx_id, line_type, line_number
    ;

    w_classification_id    number;

  begin
    print_log(' '); 
    print_log('  INSERE_NFE_INTERFACE_LINES...');
    w_count := 0;
    for r2 in c2 loop
      r_cf_inli := null;
      w_count := w_count + 1;
      print_log('    Processando linha:'||r2.customer_trx_line_id);

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
      r_cf_inli.line_location_id               := null;
      r_cf_inli.item_id                        := r2.inventory_item_id;
      r_cf_inli.item_number                    := p_linha.nu_linha_nota_fiscal;
      r_cf_inli.line_num                       := null; --p_linha.nu_linha_nota_fiscal;    
      r_cf_inli.db_code_combination_id         := retorna_cc_rem_fixar(r2.inventory_item_id, r2.warehouse_id);
      --
      r_cf_inli.line_location_id               := r2.line_location_id;
      w_po_line_location_id                    := r2.line_location_id;
      
      --Recupera Classificação Fiscal
      begin
        print_log('    Item Id                   :'||r2.inventory_item_id);
        select i.classification_id, i.utilization_id, c.classification_code 
        into w_classification_id, w_utilization_id, w_classification_code
        from 
          cll_f189_fiscal_items i, 
          cll_f189_fiscal_class c
        where 1=1 
          and i.classification_id = c.classification_id
          and i.inventory_item_id = r2.inventory_item_id 
          and i.organization_id   = r2.warehouse_id
        ;
      exception
        when others then
          print_log('    Erro Informações Fiscais do Item:'||sqlerrm);
          ok:=false;
          exit;
      end;

      r_cf_inli.classification_id              := w_classification_id;
      r_cf_inli.utilization_id                 := w_utilization_id;
      r_cf_inli.classification_code            := w_classification_code;
      r_cf_inli.cfo_id                         := w_cfop_id;

      select unit_of_measure_tl into r_cf_inli.uom
      from mtl_units_of_measure 
      where 1=1
        and language='PTB' 
        and uom_code=r2.uom_code
      ;

      r_cf_inli.quantity                       := p_linha.qt_quantidade;
      w_quantity                               := p_linha.qt_quantidade;

      print_log('    Quantidade original na NF :'||r2.quantity_invoiced);
      print_log('    Quantidade a ser devolvida:'||p_linha.qt_quantidade);

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
      r_cf_inli.total_amount                   := p_linha.qt_quantidade * r2.unit_selling_price;  --r2.extended_amount + round(nvl(r2.ipi,0),2);
      r_cf_inli.net_amount                     := p_linha.qt_quantidade * r2.unit_selling_price;  --r2.extended_amount + round(nvl(r2.ipi,0),2);
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
      begin
        select segment1 
        into w_purchase_order_num
        from po_headers_all 
        where po_header_id = (
          select po_header_id 
          from po_line_locations_all 
          where line_location_id = w_po_line_location_id
        );
      exception when others then
        w_purchase_order_num := null;
      end;

      if (w_invoice_parent_id is null) then
        r_cf_inli.attribute_category             := 'Numero PO:'||w_purchase_order_num;
        r_cf_inli.purchase_order_num             := w_purchase_order_num;
        insert into cll_f189_invoice_lines_iface values r_cf_inli;
      else
        begin
          --
          select DISTINCT invoice_line_id into w_invoice_parent_line_id 
          from cll_f189_invoice_lines              
          where 1=1
            and invoice_id      = w_invoice_parent_id 
            and organization_id = w_organization_id 
            and utilization_id  = w_utilization_id
          ;
          insere_interface_parent_lines(x_retorno => x_retorno);
        exception when others then
          print_log('  Erro ao recuperar informações fiscais do Item:'||sqlerrm);
          print_log('  Invoice_Parent_id:'||w_invoice_parent_id);
          print_log('  Organization_id  :'||w_organization_id);
          print_log('  Utilization_id   :'||w_utilization_id);
          w_invoice_parent_line_id  := null;
          ok:=false;
        end;
      end if;
    end loop;
    print_log('    Qtd linhas processadas:'||w_count);
    print_log('  FIM INSERE_NFE_INTERFACE_LINES');
    print_log(' ');
  exception when others then
    ok:=false;
    x_retorno := 'Erro não previsto em: INSERE_NFE_INTERFACE_LINES ->'||sqlerrm;
    print_log(x_retorno);
  end;

  procedure insere_interface_parent_lines(
    x_retorno           out varchar2
  ) is
    parent_lines cll_f189_invoice_line_par_int%rowtype;
  begin
    print_log(' ');
    print_log('    INSERE_INTERFACE_PARENT_LINES');

    --
    select cll_f189_invoice_line_par_i_s.nextval
    into w_interface_parent_line_id
    from dual;

    if (w_invoice_parent_id is not null) then
      begin
        select invoice_line_id into w_invoice_parent_line_id 
        from cll_f189_invoice_lines              
        where 1=1
          and invoice_id      = w_invoice_parent_id 
          and organization_id = w_organization_id 
          and utilization_id  = w_utilization_id
        ;
      exception when others then
        print_log('ERRO:'||sqlerrm);
      end;
    end if;

    print_log('    Id da Interface Parent Line:'||w_interface_parent_line_id);
    print_log('    Id da Invoice   Parent     :'||w_invoice_parent_id);
    print_log('    Id da Invoice   Parent Line:'||w_invoice_parent_line_id);
    --
    parent_lines.interface_parent_line_id  := w_interface_parent_line_id;
    parent_lines.interface_parent_id       := w_interface_parent_id;
    parent_lines.invoice_parent_line_id    := w_invoice_parent_line_id;
    parent_lines.interface_invoice_line_id := NULL; --w_INTERFACE_INVOICE_LINE_ID;
    --
    parent_lines.creation_date             := sysdate;            
    parent_lines.created_by                := fnd_profile.value('USER_ID');
    parent_lines.last_update_date          := sysdate;
    parent_lines.last_updated_by           := fnd_profile.value('USER_ID');
    parent_lines.last_update_login         := fnd_profile.value('LOGIN_ID');
    --
    parent_lines.request_id                := null;
    parent_lines.program_id                := null;
    parent_lines.program_application_id    := null;
    parent_lines.program_update_date       := null;
    --
    parent_lines.attribute_category        := null;
    --
    parent_lines.attribute1 := null;
    parent_lines.attribute2 := null;
    parent_lines.attribute3 := null;
    parent_lines.attribute4 := null;
    parent_lines.attribute5 := null;
    parent_lines.attribute6 := null;
    parent_lines.attribute7 := null;
    parent_lines.attribute8 := null;
    parent_lines.attribute9 := null;
    parent_lines.attribute10:= null;
    parent_lines.attribute11:= null;
    parent_lines.attribute12:= null;
    parent_lines.attribute13:= null;
    parent_lines.attribute14:= null;
    parent_lines.attribute15:= null;
    parent_lines.attribute16:= null;
    parent_lines.attribute17:= null;
    parent_lines.attribute18:= null;
    parent_lines.attribute19:= null;
    parent_lines.attribute20:= null;
    --
    parent_lines.rtv_cfo_id                := w_cfop_id;
    parent_lines.rtv_cfo_code              := w_cfop_code;
    parent_lines.rtv_quantity              := w_quantity;
    parent_lines.rtv_icms_tributary_code   := w_cst_icms;
    parent_lines.rtv_ipi_tributary_code    := w_cst_ipi;
    parent_lines.rtv_pis_tributary_code    := w_cst_pis;
    parent_lines.rtv_cofins_tributary_code := w_cst_cofins;
    --
    INSERT INTO cll_f189_invoice_line_par_int VALUES parent_lines;
    --
    print_log('    FIM INSERE_INTERFACE_PARENT_LINES');
    print_log(' ');
  exception when others then
    ok:=false;
    x_retorno := 'Erro não previsto em: INSERE_INTERFACE_PARENT_LINES ->'||sqlerrm;
    print_log(x_retorno);
  end;
  -- ******************************************************************************
  -- ******************************************************************************
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
    --Recupera O Tipo de Transacao No RI (Para a NF de Entrada)
    begin
      print_log('Recupera Tipo de Transacao do RI...');
      select 
        v.ec_id_tp_nf_ri,
        v.ec_tp_nf_ri,
        v.ec_cfop_entrada,   
        v.ec_cfop_saida,
        v.ec_tp_icms,
        v.ec_cst_cofins, 
        v.ec_cst_icms, 
        v.ec_cst_ipi, 
        v.ec_cst_pis,
        v.ec_tp_doc_fiscal_ri,
        v.ec_utilizacao_fiscal,
        --
        v.ec_indicador_trib_icms, 
        v.ec_indicador_trib_ipi,
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
        and v.ec_id_tp_nf_ri = t.invoice_type_id 
        and v.ec_id_organizacao            = t.organization_id
        and t.organization_id              = p_warehouse_id
        and v.ec_id_tp_nf_ar               = w_cust_trx_type_id
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
    print_log('Valida Operetion_Fiscal_Type...');
    begin      
      select o.cfo_id  ,o.cfo_code  ,u.operation_fiscal_type --,o.cfo_id, u.utilization_id, u.DESCRIPTION 
      into   w_cfop_id ,w_cfop_code ,w_operation_fiscal_type
      from 
        cll_f189_cfo_utilizations  u,
        cll_f189_fiscal_operations o
      where 1=1
        and u.inactive_date  is null
        and u.cfo_id         = o.cfo_id 
        and o.cfo_code       = w_cfop_saida
        and u.DESCRIPTION    = w_cfop_saida||' - '||w_fiscal_utilization
        --and u.utilization_id = w_fiscal_utilization
      order by 2 desc;
      print_log('  CFOP Id             :'||w_cfop_id);
      print_log('  CFOP Code           :'||w_cfop_code);
      print_log('  Oper Fiscal Type    :'||w_operation_fiscal_type);
    exception when others then
      x_retorno := 'ERRO Operation_fiscal_Type:'||sqlerrm;
      print_log('  ** '||x_retorno);
      ok := false;
      return;
    end;
    --Estado Origem 
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
    print_log('XXFR_RI_PCK_INT_NFDEVOLUCAO.LIMPA_INTERFACE');

    print_log('  LIMPA INTERFACE LINES PARENT...');
    delete cll_f189_invoice_line_par_int where INTERFACE_PARENT_ID in (
      select INTERFACE_PARENT_ID from cll_f189_invoice_parents_int   
      where 1=1 and interface_invoice_id in (
        select interface_invoice_id from cll_f189_invoices_interface 
        where source like 'XXFR%'
          and PROCESS_FLAG IN ('3','1')
      )
    );
    print_log('  LIMPA INTERFACE PARENT...');
    delete cll_f189_invoice_parents_int   where 1=1 and interface_invoice_id in (
      select interface_invoice_id from cll_f189_invoices_interface 
      where source like 'XXFR%'
        and PROCESS_FLAG IN ('3','1')
    );
    --
    print_log('  LIMPA INTERFACE LINES...');
    delete cll_f189_invoice_lines_iface 
    where interface_invoice_id in (
      select interface_invoice_id from cll_f189_invoices_interface 
      where source like 'XXFR%'
        and PROCESS_FLAG IN ('3','1')
    );
    print_log('  LIMPA INTERFACE TMP...');
    delete cll_f189_invoice_iface_tmp  
    where source like 'XXFR%'
      and PROCESS_FLAG IN ('3','1');
    --
    print_log('  LIMPA INTERFACE ERRO...');
    delete cll_f189_interface_errors 
    where interface_invoice_id in (
      select interface_invoice_id from cll_f189_invoices_interface 
      where source like 'XXFR%'
        and PROCESS_FLAG IN ('3','1')
    );
    print_log('  LIMPA INTERFACE...');
    delete cll_f189_invoices_interface 
    where source like 'XXFR%'
      and PROCESS_FLAG IN ('3','1');
    --
    COMMIT;
    print_log('FIM XXFR_RI_PCK_INT_NFDEVOLUCAO.LIMPA_INTERFACE');
  exception when others then
    ok:=false;
    rollback;
    x_retorno := 'Erro não previsto em: LIMPA_INTERFACE ->'||sqlerrm;
    print_log(x_retorno);
  end;

  function retorna_cc_rem_fixar(
    p_item_id                     in number,
    p_organization_id in number
  ) return number is
  
    v_cc_id          number;
    v_chave          varchar(100);
    v_cc_rem         number;
    v_cc_desp_item   number;
  
  begin
    begin
      select profile_option_value
      into v_cc_rem
      from 
        apps.fnd_profile_options_vl    fpo,
        apps.fnd_profile_option_values fpov
      where 1=1
        and fpo.profile_option_id = fpov.profile_option_id
        and fpo.profile_option_name = 'XXFR_RI_CC_PADRAO_REM_FIXAR';
    exception when no_data_found then
      v_cc_rem := 0;
    end;
  
  
    begin
      select b.expense_account
      into v_cc_desp_item
      from apps.mtl_system_items b
      where b.inventory_item_id = p_item_id
      and b.organization_id = p_organization_id;
    exception when no_data_found then
      v_cc_desp_item := 0;
    end;
  
    begin
      select 
        icc.segment1 || '.' || icc.segment2 || '.' || v_cc_rem || '.' ||
        icc.segment4 || '.' || icc.segment5 || '.' || icc.segment6 || '.' ||
        icc.segment7 || '.' || icc.segment8 || '.' || icc.segment9
      into v_chave
      from gl_code_combinations  icc
      where 1=1
        and icc.code_combination_id = v_cc_desp_item;
    exception when no_data_found then
      v_cc_id := 0;
    end;
  
    begin
      v_cc_id := fnd_flex_ext.get_ccid(
        'SQLGL',
        'GL#',
        50388,
        to_char(sysdate,
        'YYYY/MM/DD HH24:MI:SS'),
        v_chave
      );
    exception when no_data_found then
      v_cc_id := v_cc_desp_item;
    end;
    return v_cc_id;
  end;


END;
/