create or replace PACKAGE BODY XXFR_WMS_PCK_INT_SEPARACAO IS
-- +==========================================================================+
-- |                                                                 
-- |                                                                 
-- | CRIADO POR              DATA                  REF                                          
-- |   DANIEL PIMENTA      25/10/2019            Ticket#10108885    
-- |                                                                 
-- | ALTERADO POR            DATA                  REF                        
-- |   [Nome]                [dd/mm/yyyy]          [ticket#]     
-- |      [comentários sobre a alteração]         
-- |                                  
-- +==========================================================================+

  g_escopo            varchar2(40);
  ok                  boolean;
  isCommit            boolean := TRUE;
  --
  g_rec_retorno      	xxfr_pck_interface_integracao.rec_retorno_integracao;
  g_tab_mensagens     xxfr_pck_interface_integracao.tab_retorno_mensagens;
  
  g_proc_separacao   XXFR_WMS_PCK_INT_SEPARACAO.rec_proc_separacao;

  procedure print_log(msg   in Varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;

  procedure initialize is
  begin
    if (fnd_profile.value('USER_ID') is null) then
      xxfr_pck_variaveis_ambiente.inicializar('GME','UO_FRISIA'); 
    end if;
  end;

  procedure retornar_clob( 
    p_id_integracao_detalhe in xxfr.xxfr_integracao_detalhe.id_integracao_detalhe%type, 
    p_retorno             in out clob
  ) is
  begin
    select ds_dados_retorno into p_retorno 
    from xxfr.xxfr_integracao_detalhe t
    where id_integracao_detalhe = p_id_integracao_detalhe;
  exception when others then
    p_retorno := null;
  end; 

  procedure processar_separacao(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  ) is
  
    l_retorno               varchar2(3000);
    p_nu_ordem_venda        varchar2(50);
    p_nu_ordem_venda_linha  varchar2(50);
    p_cd_tipo_ordem_venda   varchar2(50);
    p_status                varchar2(50);
    p_organization_id       number;
    p_destino               varchar2(50);
    p_tipo_referencia       varchar2(50);
    p_reference             varchar2(50);
    p_delivery_id           number;
    p_inventory_item_id     number;
    p_to_subinventory       varchar2(50);
    p_to_locator_id         number;
    
    p_move_order_line_id    number;
    p_oe_line_id            number;
    
    p_recipe_validity_rule_id number;
    
    x_header_id             number;
    x_line_id               number;
    x_message               varchar2(3000);
    
    h                       number;
    l                       number;
    
    cursor c1 is 
      select a.*
      from xxfr_wms_vw_int_proc_separacao a
      where 1=1
        and a.id_integracao_detalhe = p_id_integracao_detalhe
        and a.nu_ordem_venda        = p_nu_ordem_venda 
        and a.cd_tipo_ordem_venda   = p_cd_tipo_ordem_venda
    ;
  
  begin
    g_rec_retorno := NULL;
    g_rec_retorno."contexto"                     := 'PROCESSAR_SEPARACAO_SEMENTES';
    g_rec_retorno."retornoProcessamento"         := null;
    g_rec_retorno."mensagemRetornoProcessamento" := null;
    g_escopo := 'PROCESSAR_SEPARACAO_SEMENTES_'||p_id_integracao_detalhe;
    
    if (isCommit) then SAVEPOINT SEPARACAO_SEMENTES; end if;
    
    print_log('----------------------------------------------------------------');
    print_log('INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS') || ' - ID INTEGRACAO:'||p_id_integracao_detalhe );
    print_log('----------------------------------------------------------------');

    initialize;
    
    ok:=true;
    h:=0;
    for r0 in (
      select distinct
      cd_referencia_origem, tp_referencia_origem, cd_organizacao_inventario, destino_ordem_separacao, end_estoque_dest_separacao, nu_ordem_venda, cd_tipo_ordem_venda, nu_ordem_venda_linha --,cd_receita_tratamento ,nu_vr_receita_tratamento
      from xxfr_wms_vw_int_proc_separacao
      where id_integracao_detalhe = p_id_integracao_detalhe
    ) loop
      h:=h+1;
      print_log(' ');
      print_log('Processando OE:'||r0.nu_ordem_venda||'-'||r0.nu_ordem_venda_linha||'  '||r0.cd_tipo_ordem_venda);
      p_nu_ordem_venda      := r0.nu_ordem_venda;
      p_cd_tipo_ordem_venda := r0.cd_tipo_ordem_venda; 
      p_nu_ordem_venda_linha:= r0.nu_ordem_venda_linha;  
      --Resgata Informações da Delivery
      begin
        select oe_line,      move_order_line_id,   delivery_id,   organization_id
        into   p_oe_line_id, p_move_order_line_id, p_delivery_id, p_organization_id
        from xxfr_wsh_vw_inf_da_ordem_venda
        where 1=1
          --402-1.1  124_VENDA
          and numero_ordem      = r0.nu_ordem_venda
          and tipo_ordem        = r0.cd_tipo_ordem_venda
          and linha||'.'||envio = r0.nu_ordem_venda_linha
          and delivery_id is not null
        ;
        l_retorno := 'S';
      exception 
        when no_data_found then 
          l_retorno := 'Distribuição não encontrada para OE:'||r0.nu_ordem_venda||'-'||r0.nu_ordem_venda_linha||' / '||r0.cd_tipo_ordem_venda;
          ok:=false;
        when too_many_rows then
          l_retorno := 'Mais de 1 Distribuição encontrada para OE:'||r0.nu_ordem_venda||'-'||r0.nu_ordem_venda_linha||' / '||r0.cd_tipo_ordem_venda;
          ok:=false;
        when others then
          l_retorno := 'Erro não previsto ao resgatar a Distribuição da OE:'||r0.nu_ordem_venda||'-'||r0.nu_ordem_venda_linha||' / '||r0.cd_tipo_ordem_venda||' : '||sqlerrm;
          ok:=false;
      end;
      if (l_retorno <> 'S') then
        print_log(l_retorno);
        g_rec_retorno."registros"(h)."tipoReferenciaOrigem"        := r0.tp_referencia_origem;
        g_rec_retorno."registros"(h)."codigoReferenciaOrigem"      := r0.cd_referencia_origem;
        g_rec_retorno."registros"(h)."retornoProcessamento"        := 'ERRO';
        g_rec_retorno."registros"(h)."mensagens"(1)."tipoMensagem" := 'ERRO';
        g_rec_retorno."registros"(h)."mensagens"(1)."mensagem"     := l_retorno;
        ok:=false;
        continue;
      end if;
      --
      p_status          := 'P';
      p_destino         := r0.destino_ordem_separacao;
      p_tipo_referencia := r0.tp_referencia_origem;
      p_reference       := r0.cd_referencia_origem;
      p_to_locator_id   := r0.end_estoque_dest_separacao;
      -- INSERE HERADER
      print_log('Chamando XXFR_WMS_PCK_ORDEM_SEPARACAO.INSERT_HEADER...');
      print_log('  Delivery_id:'||p_delivery_id);
      XXFR_WMS_PCK_ORDEM_SEPARACAO.insert_header(
        p_status          => p_status, -- P = Pendente, C = Cancelado, F = Finalizado
        p_organization_id => p_organization_id,
        p_destino         => p_destino, --"destinoOrdemSeparacao" E = Expedição, T = Tratamento
        p_tipo_referencia => p_tipo_referencia,
        p_reference       => p_reference,
        p_delivery_id     => p_delivery_id,
        p_to_subinventory => p_to_subinventory,
        p_to_locator_id   => p_to_locator_id,
        x_header_id       => x_header_id,
        x_message         => l_retorno
      );
      print_log('  Header_id :'||x_header_id);
      print_log('  Msg       :'||l_retorno);
      if (l_retorno is null) then
        l_retorno := 'S';
        --g_rec_retorno."registros"(h)."tipoCabecalho"               := 'HEADER';
        --g_rec_retorno."registros"(h)."codigoCabecalho"             := x_header_id;
        --g_rec_retorno."registros"(h)."retornoProcessamento"        := 'SUCESSO';
      else
        g_rec_retorno."registros"(h)."tipoCabecalho"               := 'HEADER';
        g_rec_retorno."registros"(h)."codigoCabecalho"             := x_header_id;
        g_rec_retorno."registros"(h)."retornoProcessamento"        := 'ERRO';
        g_rec_retorno."registros"(h)."mensagens"(1)."tipoMensagem" := 'ERRO';
        g_rec_retorno."registros"(h)."mensagens"(1)."mensagem"     := l_retorno;
        ok:=false;
        continue;          
      end if;
      --LOOP DAS LINHAS
      l:=0;
      print_log('  INICIANDO LOOP DE LINHAS ==================');
      for r1 in c1 loop
        l:=l+1;
        print_log('    Linha   :'||l);     
        print_log('    Chamando XXFR_WMS_PCK_ORDEM_SEPARACAO.INSERT_LINE...');
        --RECUPERA RECEITA DE TRATAMENTO
        begin
          select recipe_id
          into p_recipe_validity_rule_id 
          from gmd_recipes_b 
          where 1=1
            and recipe_no      = r1.cd_receita_tratamento
            and recipe_version = r1.nu_vr_receita_tratamento
          ;
          l_retorno := 'S';
        exception
          when no_data_found then
            l_retorno := 'Receita de Tratamento não encontrada';
            print_log('    '||l_retorno);
            ok:=false;
          when too_many_rows then
            l_retorno := 'Foi encontrada mais de uma Receita de Tratamento';
            print_log('    '||l_retorno);
            ok:=false;
          when others then
            l_retorno := 'Erro não previsto ao resgatar a Receita de Tratamento:'||sqlerrm;
            print_log('    '||l_retorno);
            ok:=false;
        end;
        if (l_retorno <> 'S') then
          g_rec_retorno."registros"(h)."linhas"(l)."tipoReferenciaLinhaOrigem"   := r1.tp_referencia_origem_linha;
          g_rec_retorno."registros"(h)."linhas"(l)."codigoReferenciaLinhaOrigem" := r1.cd_referencia_origem_linha;   
          g_rec_retorno."registros"(h)."linhas"(l)."tipoLinha"                   := 'LINES';
          g_rec_retorno."registros"(h)."linhas"(l)."codigoLinha"                 := x_line_id;
          g_rec_retorno."registros"(h)."linhas"(l)."mensagens"(1)."tipoMensagem" := 'ERRO';
          g_rec_retorno."registros"(h)."linhas"(l)."mensagens"(1)."mensagem"     := l_retorno;
          ok:=false;
          continue;
        end if;
        --INSERE LINHA
        begin
          xxfr_wms_pck_ordem_separacao.insert_line(
            p_header_id               => x_header_id,
            p_organization_id         => p_organization_id,
            p_status                  => 'P',
            p_tipo_referencia         => r1.tp_referencia_origem_linha,
            p_reference               => r1.cd_referencia_origem_linha,
            p_tipo                    => r1.tp_separacao,
            p_item_id                 => r1.cd_item,
            p_area                    => fnd_number.canonical_to_number(r1.vl_area_separacao),
            p_quantidade              => r1.qt_separacao,
            p_padrao_pesomil          => NULL,
            p_padrao_germinacao       => NULL,
            p_plantasm2               => r1.vl_plantas_m2,
            p_grupo                   => r1.gr_area_separacao,
            p_area_disp_prog          => r1.vl_area_disp_prog_insumos,
            p_source_order_line_id    => p_oe_line_id,
            p_move_order_line_id      => p_move_order_line_id,
            p_recipe_validity_rule_id => p_recipe_validity_rule_id,
            x_line_id                 => x_line_id,
            x_message                 => l_retorno
          );
          print_log('    Line_id :'||x_line_id);
          print_log('    Msg     :'||l_retorno);
        exception when others then
          l_retorno := 'Erro não previsto:'||sqlerrm;
          print_log('    '||l_retorno);
          ok:=false;
        end;
        if (l_retorno is null) then
          l_retorno := 'S';
        else
          g_rec_retorno."registros"(h)."tipoReferenciaOrigem"        := r0.tp_referencia_origem;
          g_rec_retorno."registros"(h)."codigoReferenciaOrigem"      := r0.cd_referencia_origem;
          g_rec_retorno."registros"(h)."retornoProcessamento"        := null;
        
          g_rec_retorno."registros"(h)."linhas"(l)."tipoReferenciaLinhaOrigem"   := r1.tp_referencia_origem_linha;
          g_rec_retorno."registros"(h)."linhas"(l)."codigoReferenciaLinhaOrigem" := r1.cd_referencia_origem_linha;   
          g_rec_retorno."registros"(h)."linhas"(l)."tipoLinha"                   := 'LINES';
          g_rec_retorno."registros"(h)."linhas"(l)."codigoLinha"                 := x_line_id;
          g_rec_retorno."registros"(h)."linhas"(l)."mensagens"(1)."tipoMensagem" := 'ERRO';
          g_rec_retorno."registros"(h)."linhas"(l)."mensagens"(1)."mensagem"     := l_retorno;
          ok:=false;
          continue;          
        end if;

      end loop;
    end loop;
    --
    if (ok) then
      print_log('');
      print_log('SUCESSO !!!');
      if (isCommit) then COMMIT; end if;
      g_rec_retorno."retornoProcessamento"         := 'SUCESSO';
      g_rec_retorno."mensagemRetornoProcessamento" := null;
      xxfr_pck_interface_integracao.sucesso (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    else
      print_log('');
      print_log('  ERRO !!!');
      if (isCommit) then ROLLBACK TO SEPARACAO_SEMENTES; end if;
      g_rec_retorno."retornoProcessamento" := 'ERRO';
      xxfr_pck_interface_integracao.erro (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    end if;  
    retornar_clob( 
      p_id_integracao_detalhe => p_id_integracao_detalhe, 
      p_retorno               => p_retorno
    );
    print_log('----------------------------------------------------------------');
    print_log('FIM INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS') || ' - ID INTEGRACAO:'||p_id_integracao_detalhe );
    print_log('----------------------------------------------------------------');
  end;

END XXFR_WMS_PCK_INT_SEPARACAO;