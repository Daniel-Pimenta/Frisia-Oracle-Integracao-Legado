create or replace PACKAGE BODY XXFR_RI_PCK_DEV_SIMB_INSUMOS AS

  g_usuario                       varchar2(50);
  g_source                        varchar2(50) := 'XXFR_DEV_SIMB_INSUMOS';
  g_escopo                        varchar2(50) := 'XXFR_DEV_SIMB_INSUMOS';
  g_comments                      varchar2(50) := 'RI (Entrada) Invoice_id:';
  
  g_header_id                     number;
  g_org_id                        number;
  g_errMessage                    varchar2(3000);
  
  isCommit                        boolean      := true;
  ok                              boolean      := true;
  
  w_operation_id                  number;
  w_organization_id               number;
  w_organization_code             varchar2(50);
  
  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo||'_'||g_header_id
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
    g_usuario:= fnd_profile.value('USERNAME');
  end;
  
  procedure initialize_opm is
    l_organization_code      	varchar2(300);
    
    l_user_id									number; 
    l_user_name               varchar2(300)  := fnd_profile.value('USERNAME');
    l_responsibility_id       number;
    l_application_id          number;
    l_application_short_name  varchar2(300);
    l_responsibility_name     varchar2(300);
  
  begin
    print_log('INITIALIZE_OPM');
    print_log('  User_Name        :'||l_user_name);
    print_log('  Organization_Code:'||w_organization_code);
    begin
      select u.user_id, r.responsibility_id, r.application_id, a.application_short_name, r.responsibility_name
      into l_user_id, l_responsibility_id, l_application_id, l_application_short_name, l_responsibility_name
      from 
        fnd_user              u, 
        fnd_responsibility_tl r,
        fnd_application       a
      where 1=1
        and r.language              = 'PTB'
        and u.user_name             = l_user_name 
        and r.application_id        = a.application_id
        and a.application_short_name= 'GMD'
        and r.responsibility_name like w_organization_code||'%Desenvolvedor de Produto%'
      ;
    exception
      when others then
        print_log('Erro:'||sqlerrm);
        ok:=false;
        goto FIM;
    end;
    fnd_global.apps_initialize ( 
      user_id      => l_user_id,
      resp_id      => l_responsibility_id,
      resp_appl_id => l_application_id 
    );
    <<FIM>>
    print_log('FIM INITIALIZE_OPM');
  end;

  procedure cria_json(
    p_chave_eletronica      in varchar2,
    p_linha                 in number,
    p_quantity              in number,
    p_uom                   in varchar2,
    p_operation_id          in number   default null,  
    p_organization_code     in varchar2 default null,
    p_user_name             in varchar2 default 'GERAL_INTEGRACAO',
    x_id_integracao_detalhe out number
  ) is
  
    p_seq_cab number;
    p_seq_det number;
    isnew     boolean := true;
    ok        boolean;
  
    str_json varchar2(32000) := ('
    {
      "idTransacao": -1,
      "versaoPayload": 1,
      "sistemaOrigem": "EBS",
      "codigoServico": "PROCESSAR_NF_DEVOLUCAO_FORNECEDOR",
      "usuario": "'||p_user_name||'",
      "processarNotaFiscalDevolucao": {
        "codigoUnidadeOperacional": "UO_FRISIA",
        "aprovaRequisicao": "SIM",
        "notaFiscalDevolucao": {
          "codigoChaveAcesso": "'||p_chave_eletronica||'",
          "tipoReferenciaOrigem": "INVOICE_ENTRADA_INSUMOS",
          "codigoReferenciaOrigem": "'||p_operation_id||'.'||p_organization_code||'",
          "linha": {
            "numero": '||p_linha||',
            "quantidade": '||p_quantity||',
            "unidadeMedida": "'||p_uom||'"
          }
        }
      }
    }
  ');
  
  begin
    print_log('  Cria Json...');
    ok := true;
    
    if isnew then
      select min(id_integracao_cabecalho) -1 into  p_seq_cab from xxfr_integracao_cabecalho;
      select min(id_integracao_detalhe) -1 into  p_seq_det from xxfr_integracao_detalhe;
    end if;
    --
    --delete xxfr_integracao_detalhe   where id_integracao_detalhe = p_seq_det;
    --delete xxfr_integracao_cabecalho where id_integracao_cabecalho = p_seq_cab;
    --HEADER
    begin
      insert into xxfr_integracao_cabecalho (
        id_integracao_cabecalho, 
        dt_criacao, 
        nm_usuario_criacao, 
        cd_programa_criacao, 
        dt_atualizacao, 
        nm_usuario_atualizacao, 
        cd_programa_atualizacao, 
        cd_sistema_origem, 
        cd_sistema_destino, 
        nr_sequencia_fila, 
        cd_interface, 
        cd_chave_interface, 
        ie_status_integracao, 
        dt_conclusao_integracao
      ) values (
        p_seq_cab,
        sysdate,
        g_usuario,
        'PL/SQL Developer',
        sysdate,
        g_usuario,
        '',
        '',
        'EBS',
        1,
        'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR',
        null,
        'NOVO',
        null
      );
      print_log('  ID CABECALHO:'||p_seq_cab);
    exception
      when others then
        print_log('  ERRO CABEÇALHO OTHERS :'||sqlerrm);
        ok := false;
    end;
    --DETALHE
    begin
      insert into xxfr_integracao_detalhe (
        id_integracao_detalhe, 
        id_integracao_cabecalho, 
        dt_criacao, 
        nm_usuario_criacao, 
        dt_atualizacao, 
        nm_usuario_atualizacao, 
        cd_interface_detalhe, 
        ie_status_processamento, 
        dt_status_processamento, 
        ds_dados_requisicao, 
        ds_dados_retorno
      ) values (
        p_seq_det,
        p_seq_cab,
        sysdate,
        g_usuario,
        sysdate,
        g_usuario,
        'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR',
        'PENDENTE',
        sysdate,
        str_json,
        null
      );
      print_log('  ID DETALHE:'||p_seq_det);
    exception
      when others then
        print_log('  ERRO DETALHE OTHERS :'||sqlerrm);
        print_log('  ID DETALHE:'||p_seq_det);
        ok := false;
    end;
    --
    if (ok) then
      commit;
      x_id_integracao_detalhe := p_seq_det;
    else
      rollback;
      x_id_integracao_detalhe := null;
    end if;
    print_log('  Id_Integração_Detalhe :'||p_seq_det);
    print_log('  Fim Cria Json...');
  end;

  procedure main(
    p_header_id   in number,
    x_retorno     out varchar2
  )is
  
    x_id_integracao_detalhe   number;
    p_retorno                 clob;
    l_status                  varchar2(300);
    
    l_qtd_nf                  number;
    l_qtd_insumos             number;
    
    cursor c1 is
      select distinct
        i.organization_id, i.organization_code, i.entity_id, i.operation_id, i.invoice_id, i.invoice_num, i.eletronic_invoice_key,
        r.description2,
        ' - '  linha,
        l.item_number, l.item_id, l.quantity, l.uom, l.unit_price, l.creation_date,
        ' - ' devolucao,
        r.line_id, r.quantity2, r.uom_code2,
        m.primary_unit_of_measure,
        'FIM'  trailer
      from 
        xxfr_ri_vw_inf_da_invoice      i,
        cll_f189_invoice_lines         l,
        xxfr_opm_vw_dev_simb_insumos_r r,
        mtl_system_items               m
      where 1=1
        and i.invoice_id        = l.invoice_id
        and i.cust_acct_site_id = r.cust_acct_site_id
        and r.inventory_item_id = l.item_id
        and r.inventory_item_id = m.inventory_item_id
        and i.organization_id   = m.organization_id
        and i.invoice_type_code NOT LIKE 'D%'
        and r.header_id = p_header_id
      order by 4
      ;
    
  begin
    g_header_id := p_header_id;
    --
    select ood.organization_id, ood.organization_code 
    into w_organization_id, w_organization_code  
    from 
      XXFR_DEV_SIMB_INSUMOS_HEADER h,
      org_organization_definitions ood 
    where 1=1
      and ood.organization_id = h.organization_id
      and header_id           = p_header_id
    ;
    --
    print_log('============================================================================');
    print_log('INICIO DO PROCESSO - DEVOLUCAO DE INSUMOS RI '|| to_char(sysdate,'DD/MM/YYYY HH24:MI:SS') );
    print_log('============================================================================');
  
    initialize_opm;
    
    g_usuario:= fnd_profile.value('USERNAME');
    --    
    -- LOOP DAS DEVOLUÇÕES
    l_qtd_nf := 0;
    
    select count(*) 
    into l_qtd_insumos
    from XXFR_DEV_SIMB_INSUMOS_LINES
    where header_id = p_header_id;
    
    select count(*) 
    into l_qtd_nf
    from 
      xxfr_ri_vw_inf_da_invoice      i,
      cll_f189_invoice_lines         l,
      xxfr_opm_vw_dev_simb_insumos_r r,
      mtl_system_items               m
    where 1=1
      and i.invoice_id        = l.invoice_id
      and i.cust_acct_site_id = r.cust_acct_site_id
      and r.inventory_item_id = l.item_id
      and r.inventory_item_id = m.inventory_item_id
      and i.organization_id   = m.organization_id
      and i.invoice_type_code NOT LIKE 'D%'
      and r.header_id = p_header_id
    ;
    
    if (l_qtd_insumos = l_qtd_nf and l_qtd_nf > 0) then
      for r1 in c1 loop
        w_operation_id      := r1.operation_id;
        w_organization_code := r1.organization_code;
        print_log('  Eletronic Key    :'||r1.ELETRONIC_INVOICE_KEY);
        print_log('  Operation Id     :'||r1.operation_id);
        print_log('  Organization Code:'||r1.organization_code);
        -- CRIA O JSON (INDIVIDUAL)
        cria_json(
          p_chave_eletronica      => r1.ELETRONIC_INVOICE_KEY,
          p_linha                 => nvl(r1.item_number,r1.item_id),
          p_quantity              => r1.QUANTITY2, 
          p_uom                   => r1.PRIMARY_UNIT_OF_MEASURE,  
          p_operation_id          => w_operation_id,
          p_organization_code     => w_organization_code,
          x_id_integracao_detalhe => x_id_integracao_detalhe
        );
        -- 
        if (ok) then
          x_retorno := 'S';
          -- INICIA O PROCESSO
          
          print_log('  Chamando XXFR_RI_PCK_INT_NFDEVOLUCAO.PROCESSAR_DEVOLUCAO');
          update xxfr_dev_simb_insumos_lines 
          set
            id_integracao_detalhe = x_id_integracao_detalhe
          where line_id = r1.line_id;
          --  
          xxfr_ri_pck_int_nfdevolucao.processar_devolucao(x_id_integracao_detalhe, p_retorno);
          --xxfr_ri_pck_int_dev_work.processar_devolucao(x_id_integracao_detalhe, x_retorno);
          
          print_log(x_retorno);
          -- RESGATA O STATUS DA INTEGRAÇÃO
          begin
            print_log('  Resgata Retorno JSON...');
            select distinct ret_processamento 
            into l_status 
            from xxfr_int_vw_retorno
            where 1=1
              and cd_interface_detalhe = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
              and id_integracao_detalhe = x_id_integracao_detalhe
            ;
            -- INSERE NA TABELA DE ERROS PARA O FORMS
            if (l_status = 'ERRO') then
              for r2 in (
                select cd_cabecalho, cd_ref_origem, msg_ret_processamento, idx_msg, tp_mensagem, mensagem 
                from 
                  xxfr_int_vw_retorno 
                where 1=1
                  --and tp_mensagem is not null 
                  --and contexto = 'DEVOLUCAO_NF_FORNECEDOR'
                  and id_integracao_detalhe = x_id_integracao_detalhe
                --order by dt_processamento desc
              ) loop
                insert into xxfr_dev_simb_insumos_erro (
                  erro_id,
                  header_id,
                  line_id,
                  cd_etapa,
                  ds_mensagem,
                  cd_referencia
                ) values (
                  xxfr_seq_ret_insumos_erro.nextval,
                  p_header_id,
                  r1.line_id,
                  'DEVOLUCÃO DE INSUMOS',
                  r2.msg_ret_processamento||' - '||r2.mensagem,
                  nvl( r2.cd_ref_origem, r2.cd_cabecalho)
                );
                COMMIT;
              end loop;
              x_retorno := 'E';
              goto FIM;
            end if;
            x_retorno := 'S';
            
          exception when others then
            print_log('** Integração não criada:'||sqlerrm);
            x_retorno := 'E';
            goto FIM;
          end;
        else
          -- ERRO AO CRIAR O JSON
          x_retorno:= 'E';
          goto FIM;
        end if;
        --
        l_qtd_nf := l_qtd_nf + 1;
        --
      end loop;
    else
      x_retorno := 'E';
      insert into xxfr_dev_simb_insumos_erro (
        erro_id,
        header_id,
        line_id,
        cd_etapa,
        ds_mensagem,
        cd_referencia
      ) values (
        xxfr_seq_ret_insumos_erro.nextval,
        p_header_id,
        null,
        'DEVOLUCÃO DE INSUMOS',
        'Não encontrada NF de Entrada com os insumos para a devolução.'||chr(10)||'Qtd de Insumos:'||l_qtd_insumos||chr(10)||'Qtd de NF(Entrada):'||l_qtd_nf,
        null
      );
      COMMIT;    
    end if;    
    <<FIM>>
    return;
  end;

END XXFR_RI_PCK_DEV_SIMB_INSUMOS;
/