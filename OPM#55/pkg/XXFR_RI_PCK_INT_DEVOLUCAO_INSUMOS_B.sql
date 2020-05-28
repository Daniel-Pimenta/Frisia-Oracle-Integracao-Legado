create or replace PACKAGE BODY XXFR_RI_PCK_DEVOLUCAO_INSUMOS AS

  g_source                        varchar2(50) := 'XXFR_DEV_AUTO_INSUMOS';
  g_escopo                        varchar2(50) := 'DEVOLUCAO_INSUMOS';
  g_comments                      varchar2(50) := 'RI (Entrada) Invoice_id:';
  g_org_id                        number;
  g_errMessage                    varchar2(3000);
  
  isCommit                        boolean      := true;
  ok                              boolean      := true;
  
  invoice_header                  cll_f189_invoices_interface%rowtype;
  parent_header                   cll_f189_invoice_parents_int%rowtype;
  invoice_lines                   cll_f189_invoice_lines_iface%rowtype;
  parent_lines                    cll_f189_invoice_line_par_int%rowtype;
  r_cf_fret                       cll_f189_freight_inv_interface%rowtype;
  
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

  w_vendor_id                     number;
  w_vendor_site_id                number;
  w_vendor_site_code              varchar2(50);
  w_terms_id                      number;
  w_freight_terms_lookup_code     varchar2(30);
  w_transaction_reason_code       varchar2(30);
  w_location_id                   number;

  w_entity_id                     number;
  w_business_vendor_id            number;
  w_ir_vendor                     varchar2(20);
  w_invoice_id                    varchar2(30);
  w_invoice_num                   varchar2(30);
  w_invoice_date                  date;
  w_series                        varchar2(30);
  w_invoice_line_id               number;
  w_operation_id                  number;
  w_purchase_order_num            varchar2(20);
  w_purchace_invoice_id           number;
  w_po_line_location_id           number;
  w_gl_date                       date;
  w_receive_date                  date;
  w_status                        varchar2(30);
  w_quantity                      number;
  w_item_id                       number;

  w_invoice_type_lookup_code      varchar2(50);
  w_requisition_type              varchar2(50);
  w_description                   varchar2(300);

  w_organization_id               number;
  w_organization_code             varchar2(50);
  w_warehouse_id                  number;
  w_document_number               varchar2(50);
  w_document_type                 varchar2(50);
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
  w_fiscal_document_model         varchar2(50);
  w_fiscal_utilization            varchar2(50);
  w_icms_tax_code                 varchar2(50);
  w_icms_type                     varchar2(50);
  w_invoice_serie                 varchar2(50);
  w_ipi_tax_code                  varchar2(50);
  w_operation_fiscal_type         varchar2(50);
  w_eletronic_invoice_key         varchar2(200);
  w_chart_of_accounts_id          number;
  --
  w_interface_invoice_id          number;
  w_interface_invoice_line_id     number;
  w_interface_parent_id           number;
  w_interface_parent_line_id      number;
  w_interface_operation_id        number;
  
  w_invoice_parent_id             number;
  w_invoice_parent_line_id        number;
  w_invoice_parent_num            varchar(50);
  --
  w_request_id                    number;

  function getInvoiceInfo(p_interface_invoice_id number) return boolean is
    l_retorno varchar2(3000);
  begin
    select invoice_id, invoice_num,   entity_id,   organization_id,   location_id,   operation_id,  invoice_type_id, nvl(ar_interface_flag,'N')
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
    print_log('PROCESSA_AUTO_INVOICE');
    print_log('  Invoice_type_code:'||w_dev_invoice_type_code);
    print_log('  Organization_id  :'||w_organization_id);
    xxfr_pck_variaveis_ambiente.inicializar('AR','UO_FRISIA');
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
    print_log('FIM PROCESSA_AUTO_INVOICE');
    return ok;
  end;

  procedure limpa_interface(
    p_invoice_id        in  number,
    x_retorno           out varchar2
  ) is
    
    cursor c1 is 
      select interface_invoice_id
      from cll_f189_invoices_interface 
      where 1=1
        and source       = 'XXFR_DEV_AUTO_INSUMOS'
        and PROCESS_FLAG IN ('3','1')
        and comments     like '%'||g_comments || p_invoice_id ||'%'
      ;
    
  begin
    print_log(' ');
    print_log('XXFR_RI_PCK_INT_DEVOLUCAO_INSUMOS.LIMPA_INTERFACE');
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
    print_log('FIM XXFR_RI_PCK_INT_DEVOLUCAO_INSUMOS.LIMPA_INTERFACE');
  exception when others then
    ok:=false;
    rollback;
    x_retorno := 'Erro não previsto em: LIMPA_INTERFACE ->'||sqlerrm;
    print_log(x_retorno);
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
    xxfr_pck_variaveis_ambiente.inicializar('CLL','UO_FRISIA'); 
    g_org_id := fnd_profile.value('ORG_ID');
  end;

  procedure main is
    x_retorno        varchar2(3000);
    x_cod_retorno    number;
    j                number;
    
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
    -- in (53934,52928,53958) --
    w_invoice_id := 53934;
    g_escopo := 'DEVOLUCAO_INSUMOS_'||w_invoice_id;
    print_log('============================================================================');
    print_log('INICIO DO PROCESSO - DEVOLUÇÃO AUTOMATICA DE INSUMOS '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
    print_log('============================================================================');  
    --
    initialize;
    --
    limpa_interface(w_invoice_id, x_retorno);
    --
    w_item_id  := 38724;
    w_quantity := 100;
    
    insere_interface_header(
      p_invoice_id => w_invoice_id, 
      p_item_id    => w_item_id, 
      p_quantity   => w_quantity,
      x_retorno    => x_retorno
    );
    -- Processa a Interface do RI
    if (ok and isCommit) then
      commit;
      print_log(' ');
      print_log('Chamando CLL_F189_OPEN_INTERFACE_PKG.OPEN_INTERFACE('||w_interface_invoice_id||')');
      --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
      cll_f189_open_interface_pkg.open_interface (
      --xxfr_f189_open_interface_pkg.open_interface (
        p_source               => g_source, 
        p_approve              => p_approve,
        p_delete_line          => p_delete_line,
        p_generate_line_compl  => p_generate_line_compl,
        p_operating_unit       => g_org_id,
        p_interface_invoice_id => w_interface_invoice_id,
        errbuf                 => x_retorno,
        retcode                => x_cod_retorno
      );
      commit;
      --
      print_log('Retorno    :'||x_retorno);
      print_log('Cod.Retorno:'||x_cod_retorno);
      for e1 in c1 loop
        print_log('  Invoice Num:'||e1.invoice_num || ' - ' || e1.error_message ||' -> '||e1.invalid_value);        
        x_retorno := 'Erro ao processas a Interface';
        ok:=false;
      end loop;
    end if;
    -- Processo de Aprovação
    if (ok and isCommit and p_approve = 'Y' and getInvoiceInfo(w_interface_invoice_id)) then
      -- Aprova Invoice no RI
      print_log('Chamando...CLL_F189_OPEN_PROCESSES_PUB.APPROVE_INTERFACE...');
      --xxfr_f189_open_processes_pub.approve_interface( 
      cll_f189_open_processes_pub.approve_interface( 
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
      commit;
      -- Recupera Status da Aprovação
      begin
        select status into w_status 
        from cll_f189_entry_operations 
        where 1=1
          and source       = g_source
          and operation_id = w_operation_id
        ;
      exception when others then
        x_retorno := 'Erro ao recuperar o Status da Aprovação :'||sqlerrm;
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
        x_retorno := 'Processo de aprovação do RI:'||w_status;
        print_log(x_retorno);
      end if;
    end if;
    ok := getInvoiceInfo(w_interface_invoice_id);
    -- Envia para a Interface do AR
    if (ok and w_status = 'COMPLETE') then
      print_log('');
      print_log('Chamando CLL_F189_INTERFACE_PKG.AR...');
      --xxfr_f189_interface_pkg.ar(w_operation_id, w_organization_id);
      cll_f189_interface_pkg.ar(w_operation_id, w_organization_id);      
      COMMIT;
      if (getInvoiceInfo(w_interface_invoice_id)) then
        if (w_ar_interface_flag = 'Y') then
          ok := true;
        else
          x_retorno := 'Interface do AR não populada !';
          ok:=false;
        end if;
      else
        ok:=false;
      end if;
    end if;
    -- Processa o Autoinvoice do AR
    if (ok and isCommit) then
      ok := processaAutoInvoice;
      x_retorno := g_errMessage;
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
          x_retorno:= 'S';
        end loop;
        if (j=0) then
          x_retorno:='NF Devolução não gerada no AR';
          print_log(x_retorno);
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
              print_log('  '||j||') - '||r1.message_text);
          end loop;
        end if;
      end if;        
    end if;

  end;

  procedure insere_interface_header(
    p_invoice_id in number,
    p_item_id    in number, 
    p_quantity   in number,
    x_retorno    out varchar2
  ) is

    cursor c1 is 
      select *
      from cll_f189_invoices 
      where invoice_id = p_invoice_id
    ;

    qtd_invoice   number;
    qtd_nfe       number;
    l_retorno     varchar2(3000);

  begin
    print_log(' '); 
    print_log('INSERE_INTERFACE_HEADER...');
    ok := true;
    for r1 in c1 loop
      --
      w_organization_id               := r1.organization_id;
      w_invoice_id                    := r1.invoice_id;
      w_invoice_num                   := r1.invoice_num;
      w_invoice_date                  := r1.invoice_date;
      w_entity_id                     := r1.entity_id;
      w_operation_id                  := null;
      w_series                        := r1.series;
      w_location_id                   := r1.location_id;
      w_invoice_type_id               := r1.invoice_type_id;
      w_terms_id                      := r1.terms_id;
      w_ir_vendor                     := r1.ir_vendor;
      w_source_state_code             := 'PR';
      w_destination_state_code        := 'PR';
      w_source_state_id               := r1.source_state_id;
      w_destination_state_id          := r1.destination_state_id;

      w_fiscal_document_model         := r1.fiscal_document_model;
      w_eletronic_invoice_key         := r1.eletronic_invoice_key; 
      
      -- Resgata RI tipo de Entrada
      select invoice_type_code,     description 
      into   w_invoice_type_code, w_description
      from cll_f189_invoice_types 
      where 1=1
        and invoice_type_id = w_invoice_type_id
        and organization_id = w_organization_id
      ;
      print_log('  Nota de Entrada no RI');
      print_log('  Id Transacao RI       :'||w_invoice_type_id);
      print_log('  Tipo Transacao RI     :'||w_invoice_type_code);
      print_log('  Descrição             :'||w_description);
      print_log('');
      --
      -- Resgata RI tipo de Devolução
      select pc.ec_id_tp_nf_dev_ri, pc.ec_tp_nf_dev_ri, it.description
      into w_dev_invoice_type_id, w_dev_invoice_type_code, w_description
      from 
        q_pc_transferencia_ar_ri_v pc,
        cll_f189_invoice_types     it
      where 1=1
        and it.invoice_type_id   = pc.ec_id_tp_nf_dev_ri
        and pc.ec_tp_nf_ri       = w_invoice_type_code
        and pc.ec_id_tp_nf_ri    = w_invoice_type_id
        and pc.ec_id_organizacao = w_organization_id
      ;
      print_log('  Nota de Devolução no RI');
      print_log('  Id Transacao Dev RI   :'||w_dev_invoice_type_id);
      print_log('  Tipo Transacao Dev RI :'||w_dev_invoice_type_code);
      print_log('  Descrição             :'||w_description);
      print_log('');
      --
      --Recupera Informações Fiscais
      begin
        select 
          --v.ec_id_tp_nf_ri,
          --v.ec_tp_nf_ri,
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
          t.requisition_type 
          --t.description
        into 
          --w_invoice_type_id,            
          --w_invoice_type_code,       
          w_cfop_entrada, 
          w_cfop_saida,
          w_icms_type,
          w_cst_cofins,
          w_cst_icms,
          w_cst_ipi,
          w_cst_pis,
          w_fiscal_document_model,
          w_fiscal_utilization,
          --
          w_icms_tax_code,
          w_ipi_tax_code,
          --
          w_ir_vendor,
          w_invoice_type_lookup_code, 
          w_requisition_type      
          --w_description 
        from
          q_pc_transferencia_ar_ri_v v,
          cll_f189_invoice_types     t
        where 1=1
          and v.ec_id_tp_nf_ri               = t.invoice_type_id 
          and v.ec_id_organizacao            = t.organization_id
          and t.organization_id              = w_organization_id
          and v.ec_id_tp_nf_ri               = w_invoice_type_id
        ;
        print_log('  CFOP Entrada          :'||w_cfop_entrada);
        print_log('  CFOP Saida            :'||w_cfop_saida);      
        print_log('  Cst Cofins            :'||w_cst_cofins);
        print_log('  Cst ICMS              :'||w_cst_icms);
        print_log('  Cst IPI               :'||w_cst_ipi);
        print_log('  Cst PIS               :'||w_cst_pis);
        print_log('  Fiscal Document Model :'||w_fiscal_document_model);
        print_log('  Fiscal Utilization    :'||w_fiscal_utilization);
        print_log('  Icms Type             :'||w_icms_type);
        print_log('  Icms Tax Code         :'||w_icms_tax_code);
        print_log('  IPI Tax Code          :'||w_ipi_tax_code);
      exception 
        when no_data_found then
          ok:=false;
          l_retorno := 'Tipo de Transacao do RI não encontrada - '||sqlerrm;
          print_log(l_retorno);
          return;
        when others then
          ok:=false;
          l_retorno := 'Erro  - '||sqlerrm;
          print_log(l_retorno);
          return;
      end;
      --Informações do Fornecedor
      begin
        print_log('');
        print_log('  Informações do Fornecedor');
        SELECT fea.business_vendor_id, fea.document_type, fea.document_number ,fea.vendor_site_id, ass.vendor_id, ass.vendor_site_code
        into   w_business_vendor_id,   w_document_type,   w_document_number   ,w_vendor_site_id   ,w_vendor_id   ,w_vendor_site_code
        FROM 
          cll_f189_fiscal_entities_all  fea,
          cll_f189_business_vendors     bv,
          ap_supplier_sites_all         ass
        WHERE 1=1    
          and fea.vendor_site_id            = ass.vendor_site_id
          and bv.business_id                = fea.business_vendor_id 
          and fea.entity_id                 = w_entity_id
        ;
        print_log('  Vendor_id             :'||w_vendor_id);
        print_log('  Vendor_site_id        :'||w_vendor_site_id);
        print_log('  Vendor_site_code      :'||w_vendor_site_code);
      exception when others then
        x_retorno := 'ERRO Informações do Fornecedor:'||sqlerrm;
        print_log(x_retorno);
        ok := false;
      end;

      w_freight_terms_lookup_code     := null;
      w_transaction_reason_code       := null;
      --
      --Verifica NF Pai no RI!
      w_invoice_parent_id             := w_invoice_id;
      w_invoice_parent_num            := w_invoice_num;
      print_log('');
      print_log('  Invoice_parent_id     :'||w_invoice_parent_id);
      print_log('  Invoice_parent_num    :'||w_invoice_parent_num );
      print_log('');
      --Sequence Interface_invoice_id
      select cll_f189_invoices_interface_s.nextval into w_interface_invoice_id from dual;
      --Sequence Operation_invoice_id
      select cll.cll_f189_interface_operat_s.nextval into w_interface_operation_id from dual;
      --
      print_log('  Interface_Invoice_id  :'||w_interface_invoice_id); 
      print_log('  Interface_Operation_id:'||w_interface_operation_id);  
      --
      print_log('  Invoice_id (Entrada)  :'||w_invoice_id);
      print_log('  Invoice_Num(Entrada)  :'||w_invoice_num);
      print_log('  Organization_id       :'||w_organization_id);
      print_log('  Location_id           :'||w_location_id);
      print_log('  Invoice_date          :'||w_invoice_date);
      print_log('  Entity_id             :'||w_entity_id);
      print_log('  Series                :'||w_series);
      --
      invoice_header                             := null;
      invoice_header.source                      := g_source;
      invoice_header.comments                    := g_comments||w_invoice_id;
      invoice_header.interface_operation_id      := w_interface_operation_id;
      invoice_header.interface_invoice_id        := w_interface_invoice_id;
      invoice_header.document_number             := w_document_number;
      invoice_header.document_type               := w_document_type;
      invoice_header.process_flag                := 1;
      invoice_header.gl_date                     := w_invoice_date;
      w_gl_date                             := w_invoice_date;
      w_receive_date                        := w_invoice_date;
      invoice_header.freight_flag                := 'N';
      invoice_header.entity_id                   := w_entity_id;
      --
      invoice_header.invoice_id                  := null;
      invoice_header.invoice_parent_id           := null; --w_invoice_parent_id;
      invoice_header.invoice_num                 := null;
      --
      invoice_header.series                      := w_series;
      invoice_header.organization_id             := w_organization_id;
      invoice_header.location_id                 := w_location_id;
      invoice_header.invoice_amount              := round(r1.invoice_amount,2);
      invoice_header.invoice_date                := w_invoice_date;

      invoice_header.invoice_type_code           := w_dev_invoice_type_code;
      invoice_header.invoice_type_id             := w_dev_invoice_type_id; 

      invoice_header.icms_type                   := w_icms_type;     

      invoice_header.icms_base                   := 0;
      invoice_header.icms_tax                    := 0; --round(r1.tx_icms,2);
      invoice_header.icms_amount                 := 0; --null; --round(r1.icms,2);

      invoice_header.icms_st_base                := null; --round(r1.extended_amount,2);
      invoice_header.icms_st_amount              := null;
      invoice_header.icms_st_amount_recover      := null; -- Analisar
      --
      invoice_header.subst_icms_base             := null;
      invoice_header.subst_icms_amount           := null;
      invoice_header.diff_icms_tax               := null;
      invoice_header.diff_icms_amount            := 0;
      --
      invoice_header.ipi_amount                  := 0; --round(r1.ipi,2);

      invoice_header.iss_base                    := null; --round(r1.extended_amount,2);
      invoice_header.iss_tax                     := null; --round(r1.tx_iss,2);
      invoice_header.iss_amount                  := null; --round(r1.iss,2);
      invoice_header.ir_base                     := null; --round(r1.extended_amount,2);
      invoice_header.ir_tax                      := null;
      invoice_header.ir_amount                   := null;
      invoice_header.irrf_base_date              := null; -- Analisar
      invoice_header.inss_base                   := null;
      invoice_header.inss_tax                    := null;
      invoice_header.inss_amount                 := null;
      invoice_header.ir_vendor                   := w_ir_vendor;
      invoice_header.ir_categ                    := null; -- Analisar
      invoice_header.diff_icms_amount_recover    := null; -- Analisar

      invoice_header.terms_id                    := 10000; --w_terms_id;
      invoice_header.terms_date                  := w_invoice_date;
      invoice_header.first_payment_date          := w_invoice_date;
      invoice_header.invoice_weight              := null; --r_nofi.peso_bruto;
      invoice_header.source_items                := null; -- Analisar
      invoice_header.total_fob_amount            := null; -- Analisar
      invoice_header.total_cif_amount            := null; -- Analisar
      invoice_header.fiscal_document_model       := w_fiscal_document_model; 
      --
      invoice_header.gross_total_amount          := round(r1.invoice_amount,2);
      --
      invoice_header.source_state_id             := w_source_state_id;
      --invoice_header.source_state_code           := w_source_state_code;
      --
      invoice_header.destination_state_id        := w_destination_state_id;
      --invoice_header.destination_state_code      := w_destination_state_code;
      --
      invoice_header.ship_to_state_id            := w_destination_state_id;
      --
      invoice_header.receive_date                := w_invoice_date;
      invoice_header.creation_date               := sysdate;
      invoice_header.created_by                  := fnd_profile.value('USER_ID');
      invoice_header.last_update_date            := sysdate;
      invoice_header.last_updated_by             := fnd_profile.value('USER_ID');
      invoice_header.last_update_login           := fnd_profile.value('LOGIN_ID');
      invoice_header.eletronic_invoice_key       := w_eletronic_invoice_key;
      invoice_header.vendor_id                   := w_vendor_id;
      invoice_header.vendor_site_id              := w_vendor_site_id;
      qtd_nfe := 0;
      if (ok) then
        qtd_nfe := qtd_nfe + 1;
        insert into cll_f189_invoices_interface values invoice_header;
        --
        insere_interface_parent_header(
          x_retorno => l_retorno
        );
        print_log('  Retorno:'||l_retorno);
        if (l_retorno = 'S') then
          p_generate_line_compl := 'S';
        end if;
        --
        insere_interface_lines(
          x_retorno => l_retorno
        );
        print_log('  Retorno:'||l_retorno);
        --
      end if;
    end loop;
    --
    if (qtd_nfe = 0) then 
      ok:=false; 
    end if;
    if (ok) then
      print_log('  Qtd de NFEs enviadas para a Interface do RI: '||qtd_nfe);
    end if;
    print_log(' ');
    print_log('FIM INSERE_NFE_INTERFACE_HEADER');
  exception when others then
    ok:=false;
    l_retorno := 'Erro não previsto em: INSERE_NFE_INTERFACE_HEADER ->'||sqlerrm;
    print_log(l_retorno);
  end;

  procedure insere_interface_parent_header(
    x_retorno               out varchar2
  ) is

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
    parent_header.invoice_date          := w_invoice_date;
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
      print_log('    Erro ao inserir CLL_F189_INVOICE_PARENTS_INT:'||sqlerrm);
    end;
    --
    print_log('  FIM INSERE_INTERFACE_PARENT_HEADER');
    print_log(' ');
    x_retorno := 'S';
  exception when others then
    ok:=false;
    x_retorno := 'Erro não previsto em: INSERE_INTERFACE_PARENT_HEADER ->'||sqlerrm;
    print_log(x_retorno);
    print_log('  FIM INSERE_INTERFACE_PARENT_HEADER');
  end;

  procedure insere_interface_lines(
    x_retorno           out varchar2
  ) is

    cursor c2 is 
      select *
      from cll_f189_invoice_lines 
      where 1=1
        and invoice_id = w_invoice_id
        and item_id    = w_item_id
    ;

    w_classification_id    number;

  begin
    print_log(' '); 
    print_log('  INSERE_NFE_INTERFACE_LINES...');
    x_retorno := 'S';
    w_count := 0;
    for r2 in c2 loop
      invoice_lines := null;
      w_count := w_count + 1;
      print_log('    Processando linha        :'||r2.invoice_line_id);
      select cll_f189_invoice_lines_iface_s.nextval into w_interface_invoice_line_id from dual;
      print_log('    Interface_invoice_line_id:'||w_interface_invoice_line_id);
      --
      w_invoice_line_id                        := r2.invoice_line_id;
      --
      invoice_lines.interface_invoice_line_id      := w_interface_invoice_line_id;
      invoice_lines.interface_invoice_id           := w_interface_invoice_id;
      invoice_lines.line_location_id               := null;
      invoice_lines.item_id                        := r2.item_id;
      invoice_lines.item_number                    := null;  -- linha que sera devolvida
      invoice_lines.line_num                       := null;
      --invoice_lines.db_code_combination_id         := retorna_cc_rem_fixar(r2.item_id, r2.organization_id);
      --
      --invoice_lines.line_location_id               := r2.line_location_id;
      w_po_line_location_id                    := null;
      
      --Recupera Classificação Fiscal
      begin
        print_log('    Item Id                   :'||r2.item_id);
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
      print_log('    Classification_Id         :'||w_classification_id);
      print_log('    Classification_Code       :'||w_classification_code);
      print_log('    Utilization_id            :'||w_utilization_id);
      invoice_lines.classification_id              := w_classification_id;
      invoice_lines.utilization_id                 := w_utilization_id;
      invoice_lines.classification_code            := w_classification_code;
      invoice_lines.cfo_id                         := w_cfop_id;
      invoice_lines.uom                            := r2.uom;
      invoice_lines.quantity                       := w_quantity; --p_linha.qt_quantidade;
      --
      print_log('    Quantidade original na NF :'||r2.quantity);
      print_log('    Quantidade a ser devolvida:'||w_quantity);
      --
      invoice_lines.unit_price                     := r2.unit_price;
      invoice_lines.operation_fiscal_type          := w_operation_fiscal_type;
      invoice_lines.description                    := r2.description;
      --
      invoice_lines.pis_base_amount                := nvl(r2.pis_base_amount,0);
      invoice_lines.pis_tax_rate                   := nvl(r2.pis_tax_rate,0);
      invoice_lines.pis_amount                     := nvl(r2.pis_amount,0);
      invoice_lines.pis_amount_recover             := 0;
      --
      invoice_lines.cofins_base_amount             := nvl(r2.cofins_base_amount,0);
      invoice_lines.cofins_tax_rate                := nvl(r2.cofins_tax_rate,0);
      invoice_lines.cofins_amount                  := nvl(r2.cofins_amount,0);
      invoice_lines.cofins_amount_recover          := 0;
      --     
      invoice_lines.icms_tax_code                  := w_icms_tax_code;
      invoice_lines.icms_base                      := round(nvl(r2.icms_base,0),2);
      invoice_lines.icms_tax                       := round(nvl(r2.icms_tax,0),2);
      invoice_lines.icms_amount                    := round(nvl(r2.icms_amount,0),2);
      invoice_lines.icms_amount_recover            := 0;
      --
      invoice_lines.ipi_tax_code                   := w_ipi_tax_code;
      invoice_lines.ipi_base_amount                := round(nvl(r2.ipi_base_amount,0),2);
      invoice_lines.ipi_tax                        := round(nvl(r2.ipi_tax,0),2);
      invoice_lines.ipi_amount                     := round(nvl(r2.ipi_amount,0),2);
      invoice_lines.ipi_amount_recover             := 0;
      --
      invoice_lines.diff_icms_tax                  := 0;
      invoice_lines.diff_icms_amount               := 0;
      invoice_lines.diff_icms_amount_recover       := 0;
      invoice_lines.diff_icms_base                 := 0;
      --
      invoice_lines.icms_st_base                   := round(nvl(r2.icms_st_base,0),2);
      invoice_lines.icms_st_amount                 := round(nvl(r2.icms_st_amount,0),2);
      invoice_lines.icms_st_amount_recover         := 0;
      --
      invoice_lines.total_amount                   := w_quantity * r2.unit_price;  --r2.extended_amount + round(nvl(r2.ipi,0),2);
      invoice_lines.net_amount                     := w_quantity * r2.unit_price;  --r2.extended_amount + round(nvl(r2.ipi,0),2);
      invoice_lines.fob_amount                     := null;

      --
      invoice_lines.discount_amount                := 0;
      invoice_lines.other_expenses                 := 0;
      invoice_lines.freight_amount                 := 0;
      invoice_lines.insurance_amount               := 0;

      invoice_lines.creation_date                  := sysdate;
      invoice_lines.created_by                     := fnd_profile.value('USER_ID');
      invoice_lines.last_update_date               := sysdate;
      invoice_lines.last_updated_by                := fnd_profile.value('USER_ID');
      invoice_lines.last_update_login              := fnd_profile.value('LOGIN_ID');
      --
      invoice_lines.tributary_status_code          := w_cst_icms;
      invoice_lines.ipi_tributary_code             := w_cst_ipi;
      invoice_lines.pis_tributary_code             := w_cst_pis;
      invoice_lines.cofins_tributary_code          := w_cst_cofins;
      --
      invoice_lines.attribute_category             := 'Informações Adicionais';
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
        invoice_lines.attribute_category             := 'Numero PO:'||w_purchase_order_num;
        invoice_lines.purchase_order_num             := w_purchase_order_num;
        insert into cll_f189_invoice_lines_iface values invoice_lines;
      else
        insere_interface_parent_lines(x_retorno => x_retorno);
      end if;
    end loop;
    
    if (w_count = 0) then
      ok:=false;
      x_retorno := 'Não foram encontradas as linhas da Invoice !';
    end if;
    
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

  begin
    print_log(' ');
    print_log('    INSERE_INTERFACE_PARENT_LINES');
    --
    select cll_f189_invoice_line_par_i_s.nextval into w_interface_parent_line_id from dual;

    if (w_invoice_parent_id is not null) then
      w_invoice_parent_line_id := w_invoice_line_id;
    end if;

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

END XXFR_RI_PCK_DEVOLUCAO_INSUMOS;
/