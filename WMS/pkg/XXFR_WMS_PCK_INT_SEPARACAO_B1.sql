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

  g_escopo                  varchar2(40);
  ok                        boolean;
  iscommit                  boolean := true;
  g_usuario                 varchar2(50);
  g_cd_unidade_operacional  varchar2(20);
  --
  g_rec_retorno      	      xxfr_pck_interface_integracao.rec_retorno_integracao;
  g_tab_mensagens           xxfr_pck_interface_integracao.tab_retorno_mensagens;
  
  g_proc_separacao   xxfr_wms_pck_int_separacao.rec_proc_separacao;

  procedure print_log(msg   in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;

  procedure initialize is
  begin
    xxfr_pck_variaveis_ambiente.inicializar(
      'GME',
      nvl(g_cd_unidade_operacional,'UO_FRISIA'), 
      g_usuario 
    ); 
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

  procedure init_retorno is
  begin
    g_rec_retorno."contexto"                                              := null;
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

  procedure main(
    p_id_integracao_detalhe in number,
    p_commit                in boolean,
    p_retorno               out clob
  ) is
  begin
    iscommit := p_commit;
    processar_separacao(p_id_integracao_detalhe, p_retorno);
  end;
  
  procedure processar_separacao(
    p_id_integracao_detalhe in  number,
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
    l_nr_ordem_separacao    number;
    x_message               varchar2(3000);
    
    h                       number;
    l                       number;
    --
    cursor c0 is
      select distinct s.id_integracao_detalhe,
        s.cd_referencia_origem, s.tp_referencia_origem, s.cd_organizacao_inventario, s.destino_ordem_separacao, s.end_estoque_dest_separacao, 
        ov.delivery_id, ov.organization_id
        --s.nu_ordem_venda, s.cd_tipo_ordem_venda, s.nu_ordem_venda_linha 
        --,cd_receita_tratamento ,nu_vr_receita_tratamento
      from 
        xxfr_wms_vw_int_proc_separacao s,
        xxfr_wsh_vw_inf_da_ordem_venda ov
      where 1=1
        and ov.numero_ordem         = s.nu_ordem_venda
        and ov.tipo_ordem           = s.cd_tipo_ordem_venda
        and ov.linha||'.'||ov.envio = s.nu_ordem_venda_linha
        and delivery_id             is not null
        and id_integracao_detalhe   = p_id_integracao_detalhe
    ;
    --
    cursor c1 is 
      select 
        a.*, 
        b.inventory_item_id, b.organization_id, o.organization_name,
        ov.oe_line, ov.move_order_line_id
      from 
        xxfr_wms_vw_int_proc_separacao a,
        mtl_system_items_b             b,
        org_organization_definitions   o,
        xxfr_wsh_vw_inf_da_ordem_venda ov
      where 1=1
        and b.segment1              = a.cd_item
        and a.nu_ordem_venda        = ov.numero_ordem 
        and a.cd_tipo_ordem_venda   = ov.tipo_ordem
        and ov.linha||'.'||ov.envio = a.nu_ordem_venda_linha
        and b.organization_id       = o.organization_id
        and o.organization_code     = a.cd_organizacao_inventario
        and ov.delivery_id          = p_delivery_id
        and a.id_integracao_detalhe = p_id_integracao_detalhe
    ;
  
  begin
    g_rec_retorno := null;
    
    init_retorno;
    
    g_rec_retorno."contexto"                     := 'PROCESSAR_SEPARACAO_SEMENTES';
    g_rec_retorno."retornoProcessamento"         := null;
    g_rec_retorno."mensagemRetornoProcessamento" := null;
    g_escopo := 'PROCESSAR_SEPARACAO_SEMENTES_'||p_id_integracao_detalhe;
    
    print_log('----------------------------------------------------------------');
    print_log('INICIO DO PROCESSO:'||to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') || ' - ID INTEGRACAO:'||p_id_integracao_detalhe );
    print_log('----------------------------------------------------------------');

    select distinct usuario, cd_unidade_operacional
    into g_usuario, g_cd_unidade_operacional
    from xxfr_wms_vw_int_proc_separacao
    where id_integracao_detalhe = p_id_integracao_detalhe
    ;
    initialize;
    if (iscommit) then savepoint separacao_sementes; end if;
    
    ok:=true;
    h:=0;
    for r0 in c0 loop
      h:=h+1;
      g_rec_retorno."registros"(h)."tipoReferenciaOrigem"        := r0.tp_referencia_origem;
      g_rec_retorno."registros"(h)."codigoReferenciaOrigem"      := r0.cd_referencia_origem;
      --
      print_log(' ');
      p_delivery_id     := r0.delivery_id; 
      p_organization_id := r0.organization_id;
      print_log('Processando Delivery:'||p_delivery_id);  
      if (ok=false) then
        print_log(l_retorno);
        g_rec_retorno."registros"(h)."retornoProcessamento"        := 'ERRO';
        g_rec_retorno."registros"(h)."mensagens"(1)."tipoMensagem" := 'ERRO';
        g_rec_retorno."registros"(h)."mensagens"(1)."mensagem"     := l_retorno;
        ok:=false;
        exit;
      end if;
      --
      -- INSERE HERADER
      if (ok) then
        p_status          := 'P';
        p_destino         := r0.destino_ordem_separacao;
        p_tipo_referencia := r0.tp_referencia_origem;
        p_reference       := r0.cd_referencia_origem;
        p_to_locator_id   := r0.end_estoque_dest_separacao;
        print_log('Chamando XXFR_WMS_PCK_ORDEM_SEPARACAO.INSERT_HEADER...');
        print_log('  Delivery_id:'||p_delivery_id);
        print_log('  Destino    :'||p_destino);
        xxfr_wms_pck_ordem_separacao.insert_header(
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
        else
          g_rec_retorno."registros"(h)."tipoCabecalho"               := 'HEADER';
          g_rec_retorno."registros"(h)."codigoCabecalho"             := x_header_id;
          g_rec_retorno."registros"(h)."retornoProcessamento"        := 'ERRO';
          g_rec_retorno."registros"(h)."mensagens"(1)."tipoMensagem" := 'ERRO';
          g_rec_retorno."registros"(h)."mensagens"(1)."mensagem"     := l_retorno;
          ok:=false;
          exit;          
        end if;
        --LOOP DAS LINHAS
        l:=0;
        print_log('  INICIANDO LOOP DE LINHAS ==================');
        for r1 in c1 loop
          l:=l+1;
          print_log('    Linha            :'||l);
          print_log('    Processando OE   :'||r1.nu_ordem_venda||'-'||r1.nu_ordem_venda_linha||'  '||r1.cd_tipo_ordem_venda);
          p_nu_ordem_venda      := r1.nu_ordem_venda;
          p_cd_tipo_ordem_venda := r1.cd_tipo_ordem_venda; 
          p_nu_ordem_venda_linha:= r1.nu_ordem_venda_linha;
          p_oe_line_id          := r1.oe_line;
          p_move_order_line_id  := r1.move_order_line_id;
          --RECUPERA RECEITA DE TRATAMENTO
          if (p_destino = 'T') then 
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
                print_log('  **'||l_retorno);
                ok:=false;
              when too_many_rows then
                l_retorno := 'Foi encontrada mais de uma Receita de Tratamento';
                print_log('  **'||l_retorno);
                ok:=false;
              when others then
                l_retorno := 'Erro não previsto ao resgatar a Receita de Tratamento:'||sqlerrm;
                print_log('  **'||l_retorno);
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
              exit;
            end if;
          end if;
          print_log('    Area de Separação:'||fnd_number.canonical_to_number(r1.vl_area_separacao));
          print_log('    Cod Item         :'||r1.cd_item);
          print_log('    Qtd Separação    :'||r1.qt_separacao);
          print_log('    Planta em M2     :'||fnd_number.canonical_to_number(r1.vl_plantas_m2));
          print_log('    Area de Separacao:'||r1.gr_area_separacao);
          print_log('    Area disponivel  :'||fnd_number.canonical_to_number(r1.vl_area_disp_prog_insumos));
          print_log('    PO Line Id       :'||p_oe_line_id);
          print_log('    Move Ordr Line Id:'||p_move_order_line_id);
          print_log('    Recipt Val RuleId:'||p_recipe_validity_rule_id);        
          --INSERE LINHA
          begin
            print_log('    Chamando XXFR_WMS_PCK_ORDEM_SEPARACAO.INSERT_LINE...');
            apps.xxfr_wms_pck_ordem_separacao.insert_line(
              p_header_id               => x_header_id,
              p_organization_id         => p_organization_id,
              p_status                  => 'P',
              p_tipo_referencia         => r1.tp_referencia_origem_linha,
              p_reference               => r1.cd_referencia_origem_linha,
              p_tipo                    => r1.tp_separacao,
              
              p_item_id                 => r1.inventory_item_id,
              p_area                    => fnd_number.canonical_to_number(r1.vl_area_separacao),
              p_quantidade              => r1.qt_separacao,
              p_padrao_pesomil          => null,
              p_padrao_germinacao       => null,
              p_plantasm2               => fnd_number.canonical_to_number(r1.vl_plantas_m2),
              p_grupo                   => r1.gr_area_separacao,
              p_area_disp_prog          => fnd_number.canonical_to_number(r1.vl_area_disp_prog_insumos),
              p_source_order_line_id    => p_oe_line_id,
              p_move_order_line_id      => p_move_order_line_id,
              p_recipe_validity_rule_id => p_recipe_validity_rule_id,
              x_line_id                 => x_line_id,
              x_message                 => l_retorno
            );
            l_retorno := nvl(l_retorno,'S');
            if (x_line_id is null) then
              l_retorno := 'Linha não foi gerada !!!';
            end if;
            print_log('  Retorno');
            print_log('    Line_id          :'||x_line_id);
            print_log('    Msg              :'||l_retorno);
          exception when others then
            l_retorno := 'Erro não previsto:'||sqlerrm;
            print_log('    '||l_retorno);
            ok:=false;
          end;
          if (l_retorno <> 'S') then
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
            exit;          
          end if;
        end loop;
        --Sinaliza o Num da ordem de Movimentação no Retorno.
        if (ok) then 
          select nr_ordem_separacao into l_nr_ordem_separacao 
          from xxfr_wms_ordem_separacao_hdr
          where id_ordem_separacao_hdr = x_header_id;
          
          g_rec_retorno."registros"(h)."tipoCabecalho"               := null; --'NUM_ORDEM_MOVIMENTACAO';
          g_rec_retorno."registros"(h)."codigoCabecalho"             := l_nr_ordem_separacao;
        end if;
      end if;
    end loop;
    --
      
    if (ok) then    
      print_log('');
      print_log('SUCESSO !!!');
      if (iscommit) then commit; end if;
      g_rec_retorno."retornoProcessamento"         := 'SUCESSO';
      g_rec_retorno."mensagemRetornoProcessamento" := null;
      xxfr_pck_interface_integracao.sucesso (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    else
      print_log('');
      print_log('  ERRO !!!');
      if (iscommit) then rollback to separacao_sementes; end if;
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
    print_log('FIM INICIO DO PROCESSO:'||to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') || ' - ID INTEGRACAO:'||p_id_integracao_detalhe );
    print_log('----------------------------------------------------------------');
  end;

END XXFR_WMS_PCK_INT_SEPARACAO;