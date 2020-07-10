create or replace PACKAGE BODY XXFR_RI_PCK_INT_DEV_WORK AS

  g_id_integracao_detalhe         number;
  g_org_id                        number;
  g_cd_unidade_operacional        varchar2(50);
  g_ie_aprova_requisicao          varchar2(50);
  g_usuario                       varchar2(50);
  g_cd_chave_acesso               varchar2(100); 
  g_tp_referencia_origem          varchar2(50); 
  g_cd_referencia_origem          varchar2(50); 
  g_nu_linha_nota_fiscal          number; 
  g_qt_quantidade                 number;
  g_cd_unidade_medida             varchar2(50);
  g_source                        varchar2(50)  := 'XXFR_NFE_DEV_FORNECEDOR';
  g_escopo                        varchar2(50);
  g_comments                      varchar2(100) := '';
  g_errbuf                        varchar2(3000);
  --
  g_cnpj_emissor                  varchar2(50);
  g_operation_id                  number;
  --
  isCommit                        boolean      := true;
  --Apenas processa o Auto-Invoice para a NF. 
  isOnlyAR                        boolean      := false;
  --
  ok                              boolean      := true;
  
  --RI Entrada
  w_invoice_type_id               number;
  w_invoice_type_code             varchar2(50);
  
  --RI Devolução
  w_dev_invoice_type_id           number;
  w_dev_invoice_type_code         varchar2(50);
  
  --
  w_cfop_entrada                  varchar2(20);
  w_cfop_saida                    varchar2(20);
  w_cfop_saida_id                 number;
  --
  w_ar_interface_flag             varchar2(20);
  
  p_approve                       varchar2(1) :='Y'; 
  p_delete_line                   varchar2(1) :='N';
  p_generate_line_compl           varchar2(1) :='N';

  p_operating_unit                number;
  p_interface_invoice_id          number;

  x_errbuf                        varchar2(3000);
  x_ret_code                      number;

  r_header                        cll_f189_invoices_interface%rowtype;
  r_lines                         cll_f189_invoice_lines_iface%rowtype;
  r_frete                         cll_f189_freight_inv_interface%rowtype;

  w_interface_operation_id        cll_f189_invoices_interface.interface_operation_id%type;
  w_interface_invoice_id          cll_f189_invoices_interface.interface_invoice_id%type;
  w_vendor_id                     po_headers_all.vendor_id%type;
  w_vendor_site_id                po_headers_all.vendor_site_id%type;
  w_terms_id                      po_headers_all.terms_id%type;
  w_terms_name                    varchar2(50);
  w_freight_terms_lookup_code     po_headers_all.freight_terms_lookup_code%type;
  w_transaction_reason_code       po_lines_all.transaction_reason_code%type;
  w_location_id                   po_line_locations_all.ship_to_location_id%type;
  w_supply_cfop_code              varchar2(20);

  w_entity_id                     cll_f189_fiscal_entities_all.entity_id%type;
  w_business_vendor_id            cll_f189_fiscal_entities_all.business_vendor_id%type;
  w_document_type                 cll_f189_fiscal_entities_all.document_type%type;
  w_ir_vendor                     cll_f189_business_vendors.ir_vendor%type;
  --
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
  --
  w_dev_cust_trx_type_name        varchar2(50);
  w_dev_cust_trx_type_id          number;
  w_dev_customer_trx_id           number;
  w_dev_trx_number                varchar2(50);
  w_dev_serie_number              varchar2(10);
  
  i                  number;
  j                  number;
  l                  number;
  

  function getInvoiceInfo(p_interface_invoice_id number) return boolean is
    l_retorno varchar2(3000);
  begin
    print_log('** GetInvoiceInfo...');
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

  function processa_auto_invoice return boolean is
    --
    l_user_concurrent_program_name varchar2(200);
    --
    
    vs_phase1          varchar2(100);
    vs_status1         varchar2(100);
    vs_dev_phase1      varchar2(100);
    vs_dev_status1     varchar2(100);
    vs_message1        varchar2(100);
    
    l_request_id       number;
    l_request_id2      number;
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
    print_log('XXFR_RI_PCK_INT_DEV_WORK.PROCESSA_AUTO_INVOICE - '||to_char(sysdate,'HH24:MI:SS'));
    print_log('  Invoice_type_code:'||w_dev_invoice_type_code);
    print_log('  Organization_id  :'||w_organization_id);
    xxfr_pck_variaveis_ambiente.inicializar('AR', g_cd_unidade_operacional, g_usuario);
    i:=0;
    for r1 in c1 loop
      i:=i+1;
      print_log('  Batch_source_name:'||r1.name);
      w_batch_source_name := r1.name;
      print_log('  PRE-PROCESSO - '||to_char(sysdate,'HH24:MI:SS'));
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
        print_log('  RAXMTR - '||to_char(sysdate,'HH24:MI:SS'));                
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
      if (1=2) then
        print_log('  POS-PROCESSO - '||to_char(sysdate,'HH24:MI:SS'));
        print_log('  Chamando Pos-Processo...');
        XXFR_AR_PCK_POS_PROCESSO_NF.prc_pos_processo( 
          errbuf  => l_errbuf,
          retcode => l_retcode
        );
        print_log('    Codigo     :'||l_retcode);
        print_log('    Retorno    :'||l_errbuf);
      end if;
      --
    end loop;
    --
    if (i=0) then 
      ok:=false;
      g_errbuf := 'Vinculo de Origens entre AR e RI não encontrado [invoice_type_code][organization_id]:['||w_dev_invoice_type_code||']['||w_organization_id||']';
      print_log('  '||g_errbuf);
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
          g_errbuf := l_completion_text;
          ok:=false;
        end if;
      exception when no_data_found then
        g_errbuf := 'Concurrent Finalizador do Auto Invoice não foi iniciado !';
        print_log('  '||g_errbuf);
        ok:=false;
      end;
    end if;
    print_log('  FIM AUTOINVOICE - '||to_char(sysdate,'HH24:MI:SS'));
    print_log('FIM XXFR_RI_PCK_INT_DEV_WORK.PROCESSA_AUTO_INVOICE');
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
  begin
    xxfr_pck_variaveis_ambiente.inicializar('CLL', g_cd_unidade_operacional, g_usuario); 
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
      select *
      from xxfr_ri_vw_int_proc_devolucao2 
      where id_integracao_detalhe = p_id_integracao_detalhe
    ;
    --
    i                  number;
    l                  number;

  begin
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
        g_cd_unidade_operacional  := r1.cd_unidade_operacional;
        g_ie_aprova_requisicao    := r1.ie_aprova_requisicao;
        g_usuario                 := r1.usuario;
        g_cd_chave_acesso         := r1.cd_chave_acesso; 
        g_tp_referencia_origem    := r1.tp_referencia_origem; 
        g_cd_referencia_origem    := r1.cd_referencia_origem; 
        g_nu_linha_nota_fiscal    := r1.nu_linha_nota_fiscal; 
        g_qt_quantidade           := r1.qt_quantidade;
        g_cd_unidade_medida       := r1.cd_unidade_medida;
        print_log('  USUARIO:'||r1.usuario);
        print_log('  CD_UNIDADE_OPERACIONAL:'||r1.cd_unidade_operacional);
        print_log('  IE_APROVA_REQUISICAO  :'||r1.ie_aprova_requisicao);
        print_log('  CD_CHAVE_ACESSO       :'||r1.cd_chave_acesso);
        print_log('  TP_REFERENCIA_ORIGEM  :'||r1.tp_referencia_origem);
        print_log('  CD_REFERENCIA_ORIGEM  :'||r1.cd_referencia_origem);
        print_log('  NU_LINHA_NOTA_FISCAL  :'||r1.nu_linha_nota_fiscal);
        print_log('  QT_QUANTIDADE         :'||r1.qt_quantidade);
        print_log('  CD_UNIDADE_MEDIDA     :'||r1.cd_unidade_medida);
        print_log('}');
      end loop;
      x_retorno := 'S';
    exception
      when others then
        ok:=false;
        x_retorno := 'ERRO AO CARREGAR O JSON:'||sqlerrm;
        print_log(x_retorno);
    end;
  end carrega_dados;

  procedure init_retorno is
  begin
    g_rec_retorno."contexto"                                              := 'DEVOLUCAO_NF_FORNECEDOR';
    g_rec_retorno."retornoProcessamento"                                  := null;
    g_rec_retorno."mensagemRetornoProcessamento"                          := null;
    --
    g_rec_retorno."registros"(1)."tipoCabecalho"                          := null;
    g_rec_retorno."registros"(1)."codigoCabecalho"                        := null;
    g_rec_retorno."registros"(1)."tipoReferenciaOrigem"                   := null;
    g_rec_retorno."registros"(1)."codigoReferenciaOrigem"                 := null;
    g_rec_retorno."registros"(1)."retornoProcessamento"                   := null;
    --
    g_rec_retorno."registros"(1)."linhas"(1)."tipoLinha"                  := null;
    g_rec_retorno."registros"(1)."linhas"(1)."codigoLinha"                := null;
    g_rec_retorno."registros"(1)."linhas"(1)."tipoReferenciaLinhaOrigem"  := null;
    g_rec_retorno."registros"(1)."linhas"(1)."codigoReferenciaLinhaOrigem":= null;
    --
    g_rec_retorno."registros"(1)."linhas"(1)."mensagens"(1)."tipoMensagem":= null;
    g_rec_retorno."registros"(1)."linhas"(1)."mensagens"(1)."mensagem"    := null;

  end;

  procedure auto_invoice(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  ) is
  begin
    isOnlyAR := true;
    processar_devolucao(
      p_id_integracao_detalhe, 
      p_retorno
    );
  end;
    
  procedure processar_devolucao(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  ) is
    --
    l_retorno          varchar2(3000);
  begin
    g_escopo := 'DEVOLUCAO_NF_FORNECEDOR_'||p_id_integracao_detalhe;
    g_id_integracao_detalhe := p_id_integracao_detalhe;
    print_log('============================================================================');
    print_log('INICIO DO PROCESSO - NFE AR -> RI (DEVOLUCAO)'|| to_char(sysdate,'DD/MM/YYYY HH24:MI:SS') );
    print_log('============================================================================');
    print_log('XXFR_RI_PCK_INT_DEV_WORK.PROCESSAR_DEVOLUCAO:'||p_id_integracao_detalhe);
    g_rec_retorno := null;
    g_rec_retorno."contexto"    := 'DEVOLUCAO_NF_FORNECEDOR';
    --
    ok := true;
    -- Carrega dados do JSON
    if (ok) then
      carrega_dados(
        p_id_integracao_detalhe => p_id_integracao_detalhe,
        x_retorno               => l_retorno
      );    
    end if;
    init_retorno;
    begin
      initialize;
      g_org_id := fnd_profile.value('ORG_ID');
    exception when others then
      l_retorno := 'Erro ao Inicializar Ambiente Oracle[XXFR_PCK_VARIAVEIS_AMBIENTE.INICIALIZAR]:'||sqlerrm;
      print_log('Erro ao Inicializar Ambiente Oracle[XXFR_PCK_VARIAVEIS_AMBIENTE.INICIALIZAR]:'||sqlerrm);
      ok:=false;
    end;
    
    i:=1; -- Será fixo com "1". Se uma futura versão contemplar mais de 1 NF por JSON, sera feito um loop com "g_proc_devolucao.nf_devolucao.count"

    -- ********************************************************************
    -- Gera e Processa a Interface do RI
    if (ok) then
      gera_interface(
        x_retorno         => l_retorno
      );
    end if;
    -- ********************************************************************
    -- Processa o Autoinvoice do AR
    if (ok and isCommit) then
      ok := processa_auto_invoice;
      l_retorno := g_errbuf;
      -- Verifica se a NF foi criada no AR
      if (ok) then
        j:=0;
        for r2 in (
          select customer_trx_id, trx_number, serie_number 
          from xxfr_ri_vw_inf_da_nfentrada 
          where customer_trx_id in (
            select customer_trx_id
            from ra_customer_trx_all 
            where 1=1
              and interface_header_context='CLL F189 INTEGRATED RCV'
              and request_id = w_request_id
          )
        ) loop
          j:=j+1;
          print_log('  NF('||j||')');
          print_log('    ID NF Devolucao :'|| r2.customer_trx_id);
          print_log('    Num NF Devolucao:'|| r2.trx_number);
          print_log('    Request ID      :'||w_request_id);
          --
          w_dev_customer_trx_id := r2.customer_trx_id;
          
          update ra_customer_trx_all
          set 
            attribute15 = w_organization_code||'.'||w_operation_id, 
            attribute_category = 'Informações notas de entrada'
          where 1=1
            and interface_header_context = 'CLL F189 INTEGRATED RCV'
            and request_id               = w_request_id
            and customer_trx_id          = r2.customer_trx_id
          ;         
          l_retorno:= 'S';
        end loop;
        --
        if (j=0) then
          l_retorno:='NF Devolução não gerada no AR';
          print_log(l_retorno);
          ok:=false;
          -- Captura mensagens de erro na RA_INTERFACE_ERRORS_ALL
          for r1 in (
            select l.batch_source_name, e.message_text, nvl(e.invalid_value,'NA') valor_invalido, L.INTERFACE_LINE_ID, L.REQUEST_ID, L.INTERFACE_LINE_ATTRIBUTE3, L.INTERFACE_LINE_ATTRIBUTE4, L.CREATION_DATE
            from 
              ra_interface_lines_all  l,
              ra_interface_errors_all e
            where 1=1
              and l.interface_line_id         = e.interface_line_id
              and l.interface_line_context    ='CLL F189 INTEGRATED RCV'
              --and l.batch_source_name         = w_batch_source_name
              and l.interface_line_attribute3 = w_invoice_id
            ) loop
              j:= j+1;
              print_log('  '||j||') - '||r1.message_text);
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
      begin
        select 
          a.cust_trx_type_id, c.name, a.trx_number, a.serie_number
        into w_dev_cust_trx_type_id, w_dev_cust_trx_type_name, w_dev_trx_number, w_dev_serie_number 
        from
          xxfr_ri_vw_inf_da_nfentrada a
          ,ra_cust_trx_types_all      c
        where 1=1
          and c.end_date          is null
          and c.cust_trx_type_id  = a.cust_trx_type_id
          --and a.trx_number        = '247'
          --and warehouse_id        = 123
          and c.org_id            = g_org_id
          and a.customer_trx_id   = w_dev_customer_trx_id
        ;
      exception when others then
        print_log('** Problemas ao Recuperar NF de devolucao no AR:');
      end;
      --
      begin
        select a.registration_number
        into g_cnpj_emissor
        from 
          apps.cll_f255_establishment_v  a
          ,apps.ra_customer_trx_lines_all i
        where 1=1
          and i.org_id                    = a.operating_unit
          and a.inventory_organization_id = i.warehouse_id 
          and i.customer_trx_id           = w_dev_trx_number
          and i.org_id                    = g_org_id
          and i.line_type                 = 'LINE'
          and rownum = 1
        ;
      exception when others then
        print_log('** Problemas ao Recuperar o CNPJ-Emissor NF:');
      end;
      g_rec_retorno."registros"(i)."tipoCabecalho"          := w_dev_cust_trx_type_name; 
      g_rec_retorno."registros"(i)."codigoCabecalho"        := g_cnpj_emissor||'.'||w_dev_trx_number||'.'||w_dev_serie_number;
      --
      g_rec_retorno."registros"(i)."linhas"(1)."tipoLinha"                   := 'LINE';
      g_rec_retorno."registros"(i)."linhas"(1)."codigoLinha"                 := '1';
      g_rec_retorno."registros"(i)."linhas"(1)."tipoReferenciaLinhaOrigem"   := g_tp_referencia_origem;
      g_rec_retorno."registros"(i)."linhas"(1)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
    else
      g_rec_retorno."registros"(i)."retornoProcessamento" := 'ERRO';
    end if; 
    
    g_rec_retorno."registros"(i)."tipoReferenciaOrigem"   := g_tp_referencia_origem;
    g_rec_retorno."registros"(i)."codigoReferenciaOrigem" := g_cd_referencia_origem;
    --
    print_log(' ');
    if (ok) then
      print_log('** SUCESSO !!!');
      g_rec_retorno."retornoProcessamento"         := 'SUCESSO';
      g_rec_retorno."mensagemRetornoProcessamento" := null;
      begin
        print_log('Chamando XXFR_PCK_INTERFACE_INTEGRACAO.SUCESSO('||p_id_integracao_detalhe||')');
        xxfr_pck_interface_integracao.sucesso (
          p_id_integracao_detalhe   => p_id_integracao_detalhe,
          p_ds_dados_retorno        => g_rec_retorno
        );
      exception when others then
        print_log('Erro em [XXFR_PCK_INTERFACE_INTEGRACAO.SUCESSO]:'||sqlerrm);
        ok:=false;
      end;
      COMMIT;
    end if;
    --
    if (ok = false) then
      print_log('** ERRO !!!');
      if (isCommit) then ROLLBACK; end if;
      g_rec_retorno."retornoProcessamento"         := 'ERRO';
      g_rec_retorno."mensagemRetornoProcessamento" := l_retorno;
      begin
        --print_log('Chamando XXFR_PCK_INTERFACE_INTEGRACAO.ERRO('||p_id_integracao_detalhe||')');
        xxfr_pck_interface_integracao.erro (
          p_id_integracao_detalhe   => p_id_integracao_detalhe,
          p_ds_dados_retorno        => g_rec_retorno
        );
      exception when others then
        print_log('Erro em [XXFR_PCK_INTERFACE_INTEGRACAO.ERRO]:'||sqlerrm);
        ok:=false;
      end;
    end if;
    --
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
    print_log('XXFR_RI_PCK_INT_DEV_WORK.GERA_INTERFACE - '||to_char(sysdate,'HH24:MI:SS'));
    if (ok) then
      insere_interface_header(
        x_retorno => l_retorno
      );
      x_retorno := l_retorno;
      if (ok = false) then
        return;
      end if;
    end if;
    -- Testa se deve rodar apenas o Autoinvoice...
    if (isOnlyAR = false) then
      -- ************************************
      -- Processa a Interface do RI
      if (ok and isCommit) then
        print_log(' ');
        print_log('PROCESSA A INTERFACE - '||to_char(sysdate,'HH24:MI:SS'));
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
        print_log('Checando Msg de Erro na Interface...');
        for e1 in c1 loop
          e := e + 1;
          print_log('  Invoice Num:'||e1.invoice_num || ' - ' || e1.error_message ||' -> '||e1.invalid_value);
          g_rec_retorno."registros"(1)."mensagens"(e)."tipoMensagem" := 'ERRO';
          g_rec_retorno."registros"(1)."mensagens"(e)."mensagem"     := 'Invoice Num: '||e1.invoice_num || ' - ' || e1.error_message ||' -> '||e1.invalid_value;
          ok:=false;
          x_retorno := 'Erro ao processas a Interface';
        end loop;
        if (ok) then
          ok := getInvoiceInfo(w_interface_invoice_id);
        end if;
      end if;

      -- ************************************
      -- Devolução Fisica...
      if (w_purchase_order_num is not null) then
        if (ok) then
          XXFR_RI_PCK_INT_DEV_FISICO.INSERT_RCV_TABLES(
            p_operation_id      => w_operation_id,
            p_organization_id   => w_organization_id,
            p_dev_operation_id  => g_operation_id,
            p_escopo            => g_escopo,
            x_retorno           => l_retorno
          );
          if (l_retorno <> 'S') then        
            ok:=false;
            print_log('== FALHA NO PROCESSO NO RI ==');
          end if;
        end if;
      else
        print_log('** Devolução sem PO.');
      end if;
      
      --isCommit := false;
      --return;
      
      -- ************************************
      -- Processo de Aprovação
      if (ok and e = 0 and isCommit) then
        -- Recupera Informações da Invoice no RI
        if (w_ar_interface_flag is null) then
          ok := getInvoiceInfo(w_interface_invoice_id);
        end if;
        -- Aprova Invoice no RI
        if (isCommit and ok and p_approve = 'Y') then
          print_log('APROVA A INTERFACE - '||to_char(sysdate,'HH24:MI:SS'));
          print_log('Chamando...CLL_F189_OPEN_PROCESSES_PUB.APPROVE_INTERFACE...');
          --XXFR_F189_OPEN_PROCESSES_PUB.APPROVE_INTERFACE( 
          CLL_F189_OPEN_PROCESSES_PUB.APPROVE_INTERFACE( 
            p_organization_id => w_organization_id,
            p_operation_id    => w_operation_id,
            p_location_id     => w_location_id,
            p_gl_date         => sysdate, --w_gl_date,
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
            and source          = g_source
            and operation_id    = w_operation_id
            and organization_id = w_organization_id 
          ;
        exception when others then
          l_retorno := 'Erro ao recuperar o Status da Aprovação :'||sqlerrm;
          ok:=false;
        end;
        --
        print_log(' ');
        --
        if (w_status = 'COMPLETE') then
          print_log('== DOCUMENTO CRIADO NO RI ==');
          g_rec_retorno."registros"(1)."tipoCabecalho"          := 'RI_DEVOLUCAO'; 
          g_rec_retorno."registros"(1)."codigoCabecalho"        := w_operation_id || '.' || w_organization_code;
        else
          ok:=false;
          print_log('== FALHA NO PROCESSO NO RI ==');
          print_log('Retorno        :'||l_retorno);
        end if;
        --
      end if;
     
      print_log('Status Processo:'||w_status);
      print_log('Invoice_id     :'||w_invoice_id);
      print_log('Invoice_num    :'||w_invoice_num);
      print_log('Entity_id      :'||w_entity_id);
      print_log('Organization_id:'||w_organization_id);
      print_log('Location_id    :'||w_location_id);
      print_log('Operation_Id   :'||w_operation_id);
      print_log('Invoice_type_id:'||w_invoice_type_id); 
      print_log('Origem         :'||g_source);
    
      -- ************************************
      -- Envia para a Interface do AR
      if (ok and w_status = 'COMPLETE' and w_invoice_parent_id is not null) then
        print_log('');
        
        -- Desativado apos a aplicação do Patch da Oracle
        if (w_ar_interface_flag is null) then
          print_log('*** FORÇANDO A CHAMADA DO RI PARA A INTERFACE DO AR ***');
          print_log('Chamando CLL_F189_INTERFACE_PKG.AR...');
          cll_f189_interface_pkg.ar (w_operation_id, w_organization_id) ; 
          COMMIT;
          print_log('*******************************************************');
        end if;
        
        ok := getInvoiceInfo(w_interface_invoice_id);
        if (ok) then
          if (w_ar_interface_flag = 'Y') then
            l_retorno := 'S';
          else
            l_retorno := 'Interface do AR não populada !';
            ok:=false;
          end if;
        else
          ok:=false;
        end if;
      end if;

    end if;
    x_retorno := l_retorno;
  end;

  procedure insere_interface_header(
    x_retorno           out varchar2
  ) is

    cursor c1 is
      select distinct *
      from xxfr_ri_vw_inf_da_invoice 
      where 1=1
        and ELETRONIC_INVOICE_KEY = g_cd_chave_acesso
    ;
        
    cursor c2(p_invoice_type_id in number, p_organization_id in number) is
      select *
      from q_pc_transferencia_ar_ri_v q
      where 1=1
        and q.ec_id_tp_nf_ri    = p_invoice_type_id 
        and q.ec_id_organizacao = p_organization_id      
    ;
    
    qtd_invoice         number;
    qtd_plano_coleta    number;
    qtd_nfe             number;
    p_retorno           varchar2(3000);

  begin
    print_log(' '); 
    print_log('INSERE_INTERFACE_HEADER...');
    qtd_invoice   := 0;
    qtd_nfe       := 0;
    
    --Teste da Invoice
    begin
      SELECT count(invoice_id) into qtd_nfe 
      FROM XXFR_RI_VW_INF_DA_INVOICE 
      where 1=1
        and ELETRONIC_INVOICE_KEY = g_cd_chave_acesso
        --and primary_flag = 'Y'
      ;
      if (qtd_nfe > 1) then
        x_retorno := 'Chave de Acesso da Sefaz Duplicada !';
        print_log(x_retorno);
        ok:=false;
        goto FIM_HEADER;
      end if;
      --
      if (qtd_nfe = 0) then
        x_retorno := 'Chave de Acesso da Sefaz Não encontrada !';
        print_log(x_retorno);
        ok:=false;
        goto FIM_HEADER;
      end if;
      qtd_nfe       := 0;
    end;
    
    for r1 in c1 loop
      --Teste do Plano de coleta.
      begin
        select count(*) into qtd_plano_coleta 
        from q_pc_transferencia_ar_ri_v q
        where 1=1
          and q.ec_id_tp_nf_ri    = r1.invoice_type_id 
          and q.ec_id_organizacao = r1.organization_id      
        ;
        if (qtd_plano_coleta > 1) then
          x_retorno := 'Setup duplicado no Plano de Coleta !';
          print_log(x_retorno);
          ok:=false;
          goto FIM_HEADER;
        end if;
        --
        if (qtd_plano_coleta = 0) then
          x_retorno := 'Setup não Encontrado no Plano de Coleta !';
          print_log(x_retorno);
          ok:=false;
          goto FIM_HEADER;
        end if;
      end;    
      -- Limpa tabelas temporarias
      if (ok) then
        limpa_interface(
          p_invoice_id => r1.invoice_id,
          x_retorno    => x_retorno
        );
      end if; 
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
      exception
        when others then
          x_retorno := 'ERRO Gerando Interface_Operation_Id:'||sqlerrm;
          print_log('  '||x_retorno);
          ok:=false;
      end;
    
      r_header                        := null;
      --
      w_invoice_id                    := r1.invoice_id;
      --w_invoice_num                   := r1.invoice_num;
      g_operation_id                  := r1.operation_id;
      w_invoice_parent_id             := r1.invoice_id;
      w_invoice_parent_num            := r1.invoice_num;
      w_vendor_id                     := r1.vendor_id;
      w_vendor_site_id                := r1.vendor_site_id;
      w_terms_id                      := r1.terms_id;
      w_location_id                   := r1.location_id;
      w_organization_id               := r1.organization_id;
      w_organization_code             := r1.organization_code;
      
      for r2 in c2(r1.invoice_type_id, r1.organization_id) loop
        w_dev_invoice_type_id           := r2.ec_id_tp_nf_dev_ri;
        w_dev_invoice_type_code         := r2.ec_tp_nf_dev_ri;    
        w_invoice_type_id               := r2.ec_id_tp_nf_ri;
        w_invoice_type_code             := r2.ec_tp_nf_ri;
        w_cfop_entrada                  := r2.ec_cfop_entrada;
        w_cfop_saida                    := r2.ec_cfop_devolucao; --r2.ec_cfop_saida;
        w_icms_type                     := r2.ec_tp_icms;
        w_cst_cofins                    := r2.ec_cst_cofins;
        w_cst_icms                      := r2.ec_cst_icms;
        w_cst_ipi                       := r2.ec_cst_ipi_devolucao;
        w_cst_pis                       := r2.ec_cst_pis;
        w_fiscal_doc_model              := r2.ec_tp_doc_fiscal_ri;
        w_fiscal_utilization            := r2.ec_utilizacao_fiscal;
        w_icms_tax_code                 := r2.ec_indicador_trib_icms; 
        w_ipi_tax_code                  := r2.ec_indicador_trib_ipi;
      end loop;
      --
      w_invoice_type_lookup_code      := r1.invoice_type_lookup_code;
      w_requisition_type              := r1.requisition_type;
      w_description                   := r1.description;
      --
      w_gl_date                       := r1.invoice_date;
      w_receive_date                  := r1.invoice_date;
      --
      w_fiscal_doc_model := 'NFE';
      
      print_log('  Interface_Invoice_id  :'||w_interface_invoice_id);
      print_log('  Interface_Operation_id:'||w_interface_operation_id); 
      print_log('  Operation_id          :'||g_operation_id);
      print_log('  ID NF Pai no RI       :'||w_invoice_parent_id);
      print_log('  Num NF Pai no RI      :'||w_invoice_parent_num );
      print_log('  Organization_id       :'||w_organization_id);
      print_log('  Location_id           :'||w_location_id);
      --
      begin
        select name
        into w_terms_name
        from ap_terms
        where 1=1
          and term_id = w_terms_id
        ;
      exception when others then
        print_log('** Erro ao buscar a codição de pagamento');
        x_retorno := 'E';
        ok:=false;
        return;
      end;
      --
      print_log('  Terms_Id Pai          :'||w_terms_id);
      print_log('  Terms_Name Pai        :'||w_terms_name);
      begin
        select TERM_ID, name 
        into w_terms_id, w_terms_name
        from ap_terms
        where 1=1
          and name  = 'A VISTA'--'SEM PAGAMENTO'
          /*
          (
          select profile_option_value
          from 
            fnd_profile_options_vl    fpo,
            fnd_profile_option_values fpov
          where 1=1
            and fpo.profile_option_id   = fpov.profile_option_id
            and fpo.profile_option_name = 'XXFR_AP_COND_PGTO_REM_FIXAR'
          )
          */
          and nvl(END_DATE_ACTIVE,sysdate) >= sysdate
        ;
      exception when others then
        print_log('** Erro ao buscar a codição de pagamento padrão');
        x_retorno := 'E';
        ok:=false;
        return;
      end;
      print_log('  Terms_Id              :'||w_terms_id);
      print_log('  Terms_Name            :'||w_terms_name);
      --
      print_log('  Id Transacao Dev RI   :'||w_dev_invoice_type_id);
      print_log('  Tipo Transacao Dev RI :'||w_dev_invoice_type_code);
      print_log('  Id Transacao RI       :'||w_invoice_type_id);
      print_log('  Tipo Transacao RI     :'||w_invoice_type_code);
      print_log('  Tipo de Invoice       :'||w_description);
      print_log('  CFOP Entrada          :'||w_cfop_entrada);
      print_log('  CFOP Saida            :'||w_cfop_saida); 
      print_log('  Cst Cofins            :'||w_cst_cofins);
      print_log('  Cst ICMS              :'||w_cst_icms);
      print_log('  Cst IPI               :'||w_cst_ipi);
      print_log('  Cst PIS               :'||w_cst_pis);
      print_log('  Fiscal Document Model :'||w_fiscal_doc_model);
      print_log('  Fiscal Utilization    :'||w_fiscal_utilization);
      print_log('  Icms Type             :'||w_icms_type);
      print_log('  Icms Tax Code         :'||w_icms_tax_code);
      print_log('  IPI Tax Code          :'||w_ipi_tax_code);
      --
      --Recupera ID do CFOP de Saida
      begin      
        select o.cfo_id 
        into   w_cfop_saida_id
        from cll_f189_fiscal_operations o
        where o.cfo_code       = w_cfop_saida
        ;
      exception when others then
        x_retorno := 'ERRO ID CFOP Saida:'||sqlerrm;
        print_log('  ** '||x_retorno);
        ok := false;
        return;
      end;
      --Valida Operetion_Fiscal_Type
      begin      
        select u.operation_fiscal_type 
        into w_operation_fiscal_type
        from 
          cll_f189_cfo_utilizations  u
        where 1=1
          and u.inactive_date  is null
          and u.cfo_id         = w_cfop_saida_id
          and u.DESCRIPTION    = w_cfop_saida||' - '||w_fiscal_utilization
        ;
      exception when others then
        print_log('  ** '||'ERRO Operation_fiscal_Type:'||sqlerrm);
      end;
      
      print_log('  CFOP Saida Id         :'||w_cfop_saida_id);
      print_log('  Oper Fiscal Type      :'||w_operation_fiscal_type);
      --
      r_header.source                      := g_source;
      r_header.comments                    := '[XXFR_DEVOLUCAO_NF_FORNECEDOR]INVOICE_ID:'||w_invoice_id||';ID_INTEGRACAO_DETALHE:'||g_id_integracao_detalhe;
      r_header.document_number             := r1.document_number;
      r_header.document_type               := r1.document_type;
      r_header.interface_operation_id      := w_interface_operation_id;
      r_header.interface_invoice_id        := w_interface_invoice_id;
      r_header.process_flag                := 1;
      --
      r_header.gl_date                     := sysdate; --r1.invoice_date;
      r_header.invoice_date                := sysdate; --r1.invoice_date;
      r_header.terms_id                    := r1.terms_id;
      r_header.terms_date                  := sysdate; --r1.invoice_date;
      r_header.first_payment_date          := sysdate; --r1.invoice_date;
      --
      r_header.freight_flag                := 'N';
      r_header.entity_id                   := r1.entity_id;
      --
      r_header.invoice_id                  := null;
      r_header.invoice_parent_id           := null; --w_invoice_parent_id;
      --
      --Devolução
      r_header.invoice_num                 := null;
      begin
        select 
          rbs.global_attribute3 into r_header.series
        from 
          apps.cll_f189_invoice_types rit, 
          apps.ra_batch_sources_all   rbs
        where 1=1
          and rit.invoice_type_code = w_dev_invoice_type_code
          and rit.ar_source_id      = rbs.batch_source_id
          and rit.organization_id   = w_organization_id
        ;
      exception when others then
        r_header.series := r1.series;
      end;
      --r_header.series                      := r1.series;
      
      r_header.organization_id             := r1.organization_id;
      r_header.location_id                 := r1.location_id;
      
      begin
        select --item_number, item_id, quantity, unit_price 
          unit_price * g_qt_quantidade
        into r_header.invoice_amount
        from cll_f189_invoice_lines
        where 1=1
          and invoice_id  = w_invoice_id
          and nvl(item_number,item_id) = g_nu_linha_nota_fiscal
        order by invoice_id desc
        ;
      exception when others then
        x_retorno := 'Linha '||g_nu_linha_nota_fiscal||' da Invoice de Entrada (Invoice_Id='||w_invoice_id||') Não Encontrada !';
        print_log('** Linha não encontrada:'||g_nu_linha_nota_fiscal);
        ok:=false;
        goto FIM_HEADER;
      end;
      
      r_header.invoice_amount              := round(r_header.invoice_amount,2);  --g_qt_quantidade * r2.unit_price;
      r_header.gross_total_amount          := r_header.invoice_amount;
      
      r_header.invoice_type_code           := w_dev_invoice_type_code;
      r_header.invoice_type_id             := w_dev_invoice_type_id; 
      r_header.icms_type                   := w_icms_type;     
      --
      r_header.icms_base                   := 0;
      r_header.icms_tax                    := 0; --round(r1.tx_icms,2);
      r_header.icms_amount                 := 0; --null; --round(r1.icms,2);
      r_header.icms_st_base                := null; --round(r1.extended_amount,2);
      r_header.icms_st_amount              := null;
      r_header.icms_st_amount_recover      := null; -- Analisar
      --
      r_header.subst_icms_base             := null;
      r_header.subst_icms_amount           := null;
      r_header.diff_icms_tax               := null;
      r_header.diff_icms_amount            := 0;
      --
      r_header.ipi_amount                  := 0; --round(r1.ipi,2);

      r_header.iss_base                    := null; --round(r1.extended_amount,2);
      r_header.iss_tax                     := null; --round(r1.tx_iss,2);
      r_header.iss_amount                  := null; --round(r1.iss,2);
      r_header.ir_base                     := null; --round(r1.extended_amount,2);
      r_header.ir_tax                      := null;
      r_header.ir_amount                   := null;
      r_header.irrf_base_date              := null; -- Analisar
      r_header.inss_base                   := null;
      r_header.inss_tax                    := null;
      r_header.inss_amount                 := null;
      r_header.ir_vendor                   := r1.ir_vendor;
      r_header.ir_categ                    := null; -- Analisar
      r_header.diff_icms_amount_recover    := null; -- Analisar

      r_header.invoice_weight              := null; --r_nofi.peso_bruto;
      r_header.source_items                := null; -- Analisar
      r_header.total_fob_amount            := null; -- Analisar
      r_header.total_cif_amount            := null; -- Analisar
      r_header.fiscal_document_model       := w_fiscal_doc_model; 
      --
      r_header.source_state_id             := r1.source_state_id;
      r_header.source_state_code           := w_source_state_code;
      r_header.destination_state_id        := r1.destination_state_id;
      r_header.destination_state_code      := w_destination_state_code;
      r_header.ship_to_state_id            := r1.destination_state_id;
      --
      r_header.receive_date                := sysdate; --r1.invoice_date;
      --
      r_header.creation_date               := sysdate;
      r_header.created_by                  := fnd_profile.value('USER_ID');
      r_header.last_update_date            := sysdate;
      r_header.last_updated_by             := fnd_profile.value('USER_ID');
      r_header.last_update_login           := fnd_profile.value('LOGIN_ID');
      r_header.eletronic_invoice_key       := null; --'D'||xxfr_fnc_sequencia_unica('ELETRONIC_INVOICE_KEY')||'.'||r1.eletronic_invoice_key;
      r_header.vendor_id                   := r1.vendor_id;
      r_header.vendor_site_id              := r1.vendor_site_id;
      --
      if (ok) then
        qtd_nfe := qtd_nfe + 1;
        insert into cll_f189_invoices_interface values r_header;
        --
        if (w_invoice_parent_id is not null) then
          insere_interface_parent_header(
            x_retorno            => p_retorno
          );
          p_generate_line_compl := 'S';
        end if;
        --
        insere_interface_lines(
          x_retorno         => p_retorno
        );
        --
        print_log('  Retorno:'||p_retorno);
        x_retorno := p_retorno;
      end if;

    end loop;
    <<FIM_HEADER>>
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
    parent_header.invoice_parent_id     := w_invoice_parent_id;
    parent_header.invoice_parent_num    := w_invoice_parent_num;
    --
    parent_header.entity_id             := null; --w_entity_id;
    parent_header.invoice_date          := w_gl_date;
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
    x_retorno           out varchar2
  ) is
  
    cursor c2 is 
      select * 
      from 
        cll_f189_invoice_lines
      where 1=1
        and invoice_id  = w_invoice_parent_id
        and nvl(item_number,item_id) = g_nu_linha_nota_fiscal
    ;
    
    w_classification_id    number;
  begin
    print_log(' '); 
    print_log('  INSERE_NFE_INTERFACE_LINES...');
    w_count := 0;
    for r2 in c2 loop
      r_lines := null;
      w_count := w_count + 1;
      print_log('    Processando linha         :'||r2.invoice_line_id);

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
      w_invoice_parent_line_id               := r2.invoice_line_id;
      r_lines.interface_invoice_line_id      := w_interface_invoice_line_id;
      r_lines.interface_invoice_id           := w_interface_invoice_id;
      r_lines.line_location_id               := null;
      r_lines.item_id                        := r2.item_id;
      r_lines.item_number                    := g_nu_linha_nota_fiscal;
      r_lines.line_num                       := null; 
      r_lines.db_code_combination_id         := retorna_cc_rem_fixar(r2.item_id, r2.organization_id);
      --
      r_lines.line_location_id               := r2.line_location_id;
      w_po_line_location_id                  := r2.line_location_id;
      
      --Recupera Classificação Fiscal do Item
      print_log('    Item Id                   :'||r2.item_id);
      begin
        select i.classification_id, i.utilization_id, c.classification_code 
        into w_classification_id, w_utilization_id, w_classification_code
        from 
          cll_f189_fiscal_items i, 
          cll_f189_fiscal_class c
        where 1=1 
          and i.classification_id = c.classification_id
          and i.inventory_item_id = r2.item_id 
          and i.organization_id   = r2.organization_id
        ;
      exception
        when others then
          print_log('    Erro Informações Fiscais do Item:'||sqlerrm);
          ok:=false;
          exit;
      end;

      r_lines.classification_id              := w_classification_id;
      r_lines.utilization_id                 := w_utilization_id;
      r_lines.classification_code            := w_classification_code;
      r_lines.cfo_id                         := w_cfop_saida_id;
      
      print_log('    Unidade Medida            :'||r2.uom);
      r_lines.uom       := r2.uom;

      r_lines.quantity  := g_qt_quantidade;
      w_quantity        := g_qt_quantidade;

      print_log('    Quantidade original na NF :'||r2.quantity);
      print_log('    Quantidade a ser devolvida:'||g_qt_quantidade);

      r_lines.unit_price                     := r2.unit_price;
      r_lines.operation_fiscal_type          := w_operation_fiscal_type;
      r_lines.description                    := r2.description;
      --
      r_lines.pis_base_amount                := nvl(r2.pis_base_amount,0);
      r_lines.pis_tax_rate                   := nvl(r2.pis_tax_rate,0);
      r_lines.pis_amount                     := nvl(r2.pis_amount,0);
      r_lines.pis_amount_recover             := 0;
      --
      r_lines.cofins_base_amount             := nvl(r2.cofins_base_amount,0);
      r_lines.cofins_tax_rate                := nvl(r2.cofins_tax_rate,0);
      r_lines.cofins_amount                  := nvl(r2.cofins_amount,0);
      r_lines.cofins_amount_recover          := 0;
      --     
      r_lines.icms_tax_code                  := w_icms_tax_code;
      r_lines.icms_base                      := round(nvl(r2.icms_base,0),2);
      r_lines.icms_tax                       := round(nvl(r2.icms_tax,0),2);
      r_lines.icms_amount                    := round(nvl(r2.icms_amount,0),2);
      r_lines.icms_amount_recover            := 0;
      --
      r_lines.ipi_tax_code                   := w_ipi_tax_code;
      r_lines.ipi_base_amount                := round(nvl(r2.ipi_base_amount,0),2);
      r_lines.ipi_tax                        := round(nvl(r2.ipi_tax,0),2);
      r_lines.ipi_amount                     := round(nvl(r2.ipi_amount,0),2);
      r_lines.ipi_amount_recover             := 0;
      --
      r_lines.diff_icms_tax                  := 0;
      r_lines.diff_icms_amount               := 0;
      r_lines.diff_icms_amount_recover       := 0;
      r_lines.diff_icms_base                 := 0;
      --
      r_lines.icms_st_base                   := round(nvl(r2.icms_st_base,0),2);
      r_lines.icms_st_amount                 := round(nvl(r2.icms_st_amount,0),2);
      r_lines.icms_st_amount_recover         := 0;
      --
      r_lines.total_amount                   := g_qt_quantidade * r2.unit_price;  --r2.extended_amount + round(nvl(r2.ipi,0),2);
      r_lines.net_amount                     := g_qt_quantidade * r2.unit_price;  --r2.extended_amount + round(nvl(r2.ipi,0),2);
      r_lines.fob_amount                     := null;

      --
      r_lines.discount_amount                := 0;
      r_lines.other_expenses                 := 0;
      r_lines.freight_amount                 := 0;
      r_lines.insurance_amount               := 0;

      r_lines.creation_date                  := sysdate;
      r_lines.created_by                     := fnd_profile.value('USER_ID');
      r_lines.last_update_date               := sysdate;
      r_lines.last_updated_by                := fnd_profile.value('USER_ID');
      r_lines.last_update_login              := fnd_profile.value('LOGIN_ID');
      --
      r_lines.tributary_status_code          := w_cst_icms;
      r_lines.ipi_tributary_code             := w_cst_ipi;
      r_lines.pis_tributary_code             := w_cst_pis;
      r_lines.cofins_tributary_code          := w_cst_cofins;
      --
      r_lines.attribute_category             := 'Informações Adicionais';
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
      
      -- Avaliar...
      if (w_invoice_parent_id is null) then
        r_lines.attribute_category             := 'Numero PO:'||w_purchase_order_num;
        r_lines.purchase_order_num             := w_purchase_order_num;
        insert into cll_f189_invoice_lines_iface values r_lines;
      else
        insere_interface_parent_lines(x_retorno => x_retorno);
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
    parent_lines    cll_f189_invoice_line_par_int%rowtype;
  begin
    print_log(' ');
    print_log('    INSERE_INTERFACE_PARENT_LINES');

    --
    select cll_f189_invoice_line_par_i_s.nextval
    into w_interface_parent_line_id
    from dual;

    print_log('      Id da Interface Parent Line:'||w_interface_parent_line_id);
    print_log('      Id da Invoice   Parent     :'||w_invoice_parent_id);
    print_log('      Id da Invoice   Parent Line:'||w_invoice_parent_line_id);
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
    parent_lines.rtv_cfo_id                := w_cfop_saida_id;
    parent_lines.rtv_cfo_code              := w_cfop_saida;
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
    x_retorno := '    Erro não previsto em: INSERE_INTERFACE_PARENT_LINES ->'||sqlerrm;
    print_log(x_retorno);
  end;

  procedure limpa_interface(
    p_invoice_id   in  number,
    x_retorno           out varchar2
  ) is
    
    cursor c1 is 
      select interface_invoice_id
      from cll_f189_invoices_interface 
      where 1=1
        and source       = g_source
        and PROCESS_FLAG IN ('3','1')
        and comments     like '[XXFR_DEVOLUCAO_NF_FORNECEDOR]INVOICE_ID:'||p_invoice_id||'%'
      ;
    
  begin
    print_log(' ');
    print_log('  LIMPA_INTERFACE');
    for r1 in c1 loop
      print_log('  LIMPA INTERFACE LINES PARENT...');
      delete cll_f189_invoice_line_par_int where INTERFACE_PARENT_ID in (
        select INTERFACE_PARENT_ID from cll_f189_invoice_parents_int where 1=1 and interface_invoice_id = r1.interface_invoice_id
      );
      print_log('  LIMPA INTERFACE PARENT...');
      delete cll_f189_invoice_parents_int   where 1=1 and interface_invoice_id = r1.interface_invoice_id;
      print_log('  LIMPA INTERFACE LINES...');
      delete cll_f189_invoice_lines_iface where interface_invoice_id = r1.interface_invoice_id;
      print_log('  LIMPA INTERFACE TMP...');
      delete cll_f189_invoice_iface_tmp where interface_invoice_id = r1.interface_invoice_id;
      print_log('  LIMPA INTERFACE ERRO...');
      delete cll_f189_interface_errors where interface_invoice_id = r1.interface_invoice_id;
      print_log('  LIMPA INTERFACE...');
      delete cll_f189_invoices_interface where interface_invoice_id = r1.interface_invoice_id;
    end loop;
    COMMIT;
    print_log('  FIM LIMPA_INTERFACE');
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