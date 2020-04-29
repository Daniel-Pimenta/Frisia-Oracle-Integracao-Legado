create or replace PACKAGE BODY XXFR_WSH_PCK_INT_ENTREGA IS
-- +==========================================================================+
-- | Package para criar e manter itens do OM para integrações e processos custom.     
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

  g_versao                    varchar2(100) := '2020.04.22.016';

  cursor c1(i_id_int_det number) is 
    select distinct id_integracao_detalhe,   
      cd_unidade_operacional, ds_sistema_origem, usuario,
      --Entrega
      ie_dividir_linha, ie_conteudo_firme, ie_liberar_separacao, 
      --Percurso
      id_percurso, tp_operacao, nm_percurso, ie_ajusta_distribuicao, cd_lacre_veiculo, qt_peso_tara, qt_peso_bruto, qt_peso_embalagem_complementar, tp_frete, cd_metodo_entrega, 
      cd_referencia_origem, tp_referencia_origem, cd_endereco_estoque_granel, tp_liberacao,
      --Transportador
      cd_transportador, nm_motorista, nu_cpf_motorista, 
      --Veiculo
      cd_reg_antt, cd_reg_antt_cavalo, nu_placa1, nu_placa2, nu_placa3, nu_placa4, nu_placa5
    from xxfr_wsh_vw_int_proc_entrega 
    where 1=1
      --and ie_status_processamento = 'PENDENTE'
      and id_integracao_detalhe = i_id_int_det
  ;

  cursor c2(i_id_int_det number) is
    select distinct nm_distribuicao, cd_cliente, cd_ship_to, vl_valor_frete, cd_moeda, cd_controle_entrega_cliente, cd_lacres, ds_dados_adicionais
    from xxfr_wsh_vw_int_proc_entrega 
    where 1=1
      --and ie_status_processamento = 'PENDENTE'
      and id_cab is not null
      and id_integracao_detalhe = i_id_int_det
    order by nm_distribuicao
  ;

  cursor c3(i_id_int_det number, i_cd_cliente number, i_cd_ship_to varchar2) is
    select id_integracao_detalhe, 
      --CD_CLIENTE, NM_DISTRIBUICAO, 
      cd_tipo_ordem_venda, nu_ordem_venda, nu_linha_ordem_venda, nu_envio_linha_ordem_venda, nu_entrega, qt_quantidade, cd_un_medida, qt_volumes, cd_un_volume, cd_endereco_estoque, ds_observacoes, pr_percentual_gordura
    from xxfr_wsh_vw_int_proc_entrega
    where 1=1
      --and ie_status_processamento = 'PENDENTE'
      and (nu_ordem_venda is not null or nu_entrega is not null)
      and id_integracao_detalhe = i_id_int_det
      and cd_cliente            = i_cd_cliente 
      and cd_ship_to            = i_cd_ship_to
    order by nm_distribuicao
  ;
  --
  ok                          boolean;
  isReservar                  boolean := TRUE;
  isCommit                    boolean := TRUE;
  --
  g_id_integracao_detalhe     number;
  --
  g_org_id                    number;
  g_user_name                 varchar2(30);
  g_organization_code         varchar2(20);
  g_order_number              varchar2(20);
  g_header_id                 number;
  g_line                      varchar2(10);
  g_customer_number           varchar2(20);
  g_customer_id               number;
  --
  g_lot_number                varchar2(50);
  g_primary_quantity          number;
  g_from_subinventory_code    varchar2(50);
  g_to_subinventory_code      varchar2(50);
  g_to_locator_id             number;
  g_from_locator_id           number;
  g_transaction_id            number;
  --
  g_escopo                    varchar2(40);
  --
  g_tp_dist                   tp_dist;
  g_tp_linhas                 tp_linhas;
  g_tp_transp                 tp_transp;
  g_tp_veiculo                tp_veiculo;
  g_tp_percurso               tp_percurso;
  
  g_delivery_detail_id_tbl    wsh_delivery_details_pub.id_tab_type;

  g_rec_retorno      	        xxfr_pck_interface_integracao.rec_retorno_integracao;
  g_tab_mensagens             xxfr_pck_interface_integracao.tab_retorno_mensagens;
  g_reserva_rec_type          inv_reservation_global.mtl_reservation_rec_type;
  
  g_cd_referencia_origem      varchar2(50);
  g_tp_referencia_origem      varchar2(50);
  g_ie_manter_percurso        varchar2(10) := NULL;

  g_qtd_alocada_pedido        number;

  procedure print_out(msg   in Varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;

  function pre_validacao(p_id_integracao_detalhe number) return boolean is
    
    l_cod_tipo_ordem   varchar2(20);
    l_num_ordem        varchar2(20);
    l_num_linha_ordem  varchar2(20);
    l_status           varchar2(30);
    
    l_qtd                         number;
    
    l_id_percurso                 number; 
    l_nu_ordem_venda              varchar2(30); 
    l_nu_linha_ordem_venda        varchar2(30); 
    l_nu_envio_linha_ordem_venda  varchar2(30);
    l_cd_tipo_ordem_venda         varchar2(30);
    l_ie_status_processamento     varchar2(30);
    
    CANCELLED           number;
    CLOSED              number;
    INVOICE_INCOMPLETE  number;
    SHIPPED             number;
    AWAITING_SHIPPING   number;

    cursor c0 is
      select distinct
        id_percurso, 
        nu_ordem_venda, 
        nu_linha_ordem_venda, 
        nu_envio_linha_ordem_venda,
        cd_tipo_ordem_venda,
        ie_status_processamento
      from xxfr_wsh_vw_int_proc_entrega 
      where id_integracao_detalhe = p_id_integracao_detalhe
    ;

    cursor c1(I_TRIP_ID in number) is
      select 
        NUMERO_ORDEM, LINHA, TIPO_ORDEM, DELIVERY_ID, OE_HOLD,
        count(decode( a.flow_status_code,'CANCELLED',1,null))          as cancelled
        ,count(decode( a.flow_status_code,'CLOSED',1,null))             as closed
        ,count(decode( a.flow_status_code,'INVOICE_INCOMPLETE',1,null)) as invoice_incomplete
        ,count(decode( a.flow_status_code,'SHIPPED',1,null))            as shipped
        ,count(decode( a.flow_status_code,'AWAITING_SHIPPING',1,null))  as awaiting_shipping
      from 
        xxfr_wsh_vw_inf_da_ordem_venda a
      where 1=1 
        and a.trip_id = I_TRIP_ID
      group by  NUMERO_ORDEM, LINHA, TIPO_ORDEM, DELIVERY_ID, OE_HOLD
    ;

    cursor c2(
      I_NU_ORDEM_VENDA              in varchar2,
      I_NU_LINHA_ORDEM_VENDA        in varchar2,
      I_NU_ENVIO_LINHA_ORDEM_VENDA  in varchar2,
      I_CD_TIPO_ORDEM_VENDA         in varchar2
    ) is
      select
        NUMERO_ORDEM, LINHA, TIPO_ORDEM, DELIVERY_ID, OE_HOLD,
        count(decode( a.flow_status_code,'CANCELLED',1,null))           as cancelled
        ,count(decode( a.flow_status_code,'CLOSED',1,null))             as closed
        ,count(decode( a.flow_status_code,'INVOICE_INCOMPLETE',1,null)) as invoice_incomplete
        ,count(decode( a.flow_status_code,'SHIPPED',1,null))            as shipped
        ,count(decode( a.flow_status_code,'AWAITING_SHIPPING',1,null))  as awaiting_shipping
      from 
        xxfr_wsh_vw_inf_da_ordem_venda a
      where 1=1 
        and a.numero_ordem = I_NU_ORDEM_VENDA 
        and a.linha        = I_NU_LINHA_ORDEM_VENDA
        and a.envio        = nvl(I_NU_ENVIO_LINHA_ORDEM_VENDA,a.envio)
        and a.tipo_ordem   = I_CD_TIPO_ORDEM_VENDA 
      group by  NUMERO_ORDEM, LINHA, TIPO_ORDEM, DELIVERY_ID, OE_HOLD
    ;

  begin
    print_out('XXFR_WSH_PCK_INT_ENTREGA.PRE_VALIDACAO');
    ok:=true;
    for r0 in c0 loop
      l_id_percurso                := r0.id_percurso;
      l_nu_ordem_venda             := r0.nu_ordem_venda;
      l_nu_linha_ordem_venda       := r0.nu_linha_ordem_venda;
      l_nu_envio_linha_ordem_venda := r0.nu_envio_linha_ordem_venda;
      l_cd_tipo_ordem_venda        := r0.cd_tipo_ordem_venda;
      l_ie_status_processamento    := r0.ie_status_processamento;
      --
      if (l_nu_ordem_venda is null and l_id_percurso is not null) then
        print_out('  Validando o percurso...'||l_id_percurso);
        for r1 in c1(l_id_percurso) loop
          print_out('  OE:'||r1.numero_ordem||' '||r1.linha||' - '||r1.tipo_ordem);
          if (r1.awaiting_shipping = 0) then
            g_rec_retorno."retornoProcessamento"        := 'ERRO';
            if    (r1.cancelled > 0)          then g_rec_retorno."mensagemRetornoProcessamento":='Ordem Venda:'||l_nu_ordem_venda||' NÃO ELEGIVEL PARA ENTREGA: CANCELADA';
            elsif (r1.closed > 0)             then g_rec_retorno."mensagemRetornoProcessamento":='Ordem Venda:'||l_nu_ordem_venda||' NÃO ELEGIVEL PARA ENTREGA: FECHADA';
            elsif (r1.invoice_incomplete > 0) then g_rec_retorno."mensagemRetornoProcessamento":='Ordem Venda:'||l_nu_ordem_venda||' NÃO ELEGIVEL PARA ENTREGA: INCOMPLETA';
            elsif (r1.shipped > 0)            then g_rec_retorno."mensagemRetornoProcessamento":='Ordem Venda:'||l_nu_ordem_venda||' NÃO ELEGIVEL PARA ENTREGA: ENVIADA';
            end if;
            print_out('  '||g_rec_retorno."mensagemRetornoProcessamento");
            ok:=false;
          end if;
          if (r1.oe_hold is not null) then
            g_rec_retorno."retornoProcessamento"         := 'ERRO';
            g_rec_retorno."mensagemRetornoProcessamento" := 'Em Retenção '||check_hold(r1.delivery_id);    
            print_out('  '||g_rec_retorno."mensagemRetornoProcessamento");
            ok:=false;
          end if;
        end loop;
      end if;
      --
      if (l_id_percurso is null and l_nu_ordem_venda is not null) then
      
        select count(*) into l_qtd
        from 
          xxfr_wsh_vw_inf_da_ordem_venda a
        where 1=1 
          and a.numero_ordem = l_nu_ordem_venda 
          and a.linha        = l_nu_linha_ordem_venda
          and a.envio        = nvl(l_nu_envio_linha_ordem_venda,a.envio)
          and a.tipo_ordem   = l_cd_tipo_ordem_venda 
          and released_status <> 'C'
          and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
        ;
        if (l_qtd > 0) then 
          ok:=true;
          return ok;
        end if;
        print_out('  Validando o ordem de venda...');
        for r1 in c2(l_nu_ordem_venda,l_nu_linha_ordem_venda,l_nu_envio_linha_ordem_venda,l_cd_tipo_ordem_venda) loop
          print_out('  OE:'||l_nu_ordem_venda||' '||l_nu_linha_ordem_venda||'.'||l_nu_envio_linha_ordem_venda||' - '||l_cd_tipo_ordem_venda);
          if (r1.awaiting_shipping = 0) then
            g_rec_retorno."retornoProcessamento"        := 'ERRO';
            if    (r1.cancelled > 0)          then g_rec_retorno."mensagemRetornoProcessamento":='Ordem Venda:'||l_nu_ordem_venda||' Não Elegivel Para Entrega: CANCELADA';
            elsif (r1.closed > 0)             then g_rec_retorno."mensagemRetornoProcessamento":='Ordem Venda:'||l_nu_ordem_venda||' Não Elegivel Para Entrega: FECHADA';
            elsif (r1.invoice_incomplete > 0) then g_rec_retorno."mensagemRetornoProcessamento":='Ordem Venda:'||l_nu_ordem_venda||' Não Elegivel Para Entrega: INCOMPLETA';
            elsif (r1.shipped > 0)            then g_rec_retorno."mensagemRetornoProcessamento":='Ordem Venda:'||l_nu_ordem_venda||' Não Elegivel Para Entrega: ENVIADA';
            end if;
            print_out('  '||g_rec_retorno."mensagemRetornoProcessamento");
            ok:=false;
          end if;
          if (r1.oe_hold is not null) then
            g_rec_retorno."retornoProcessamento"         := 'ERRO';
            g_rec_retorno."mensagemRetornoProcessamento" := 'Em Retenção '||check_hold(r1.delivery_id);
            print_out('  '||g_rec_retorno."mensagemRetornoProcessamento");
            ok:=false;
          end if;
        end loop;
      end if;
    end loop;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.PRE_VALIDACAO');
    return ok;
  exception
    when others then
      g_rec_retorno."retornoProcessamento"        := 'ERRO';
      g_rec_retorno."mensagemRetornoProcessamento":= 'PRE-VALIDAÇÃO:'||sqlerrm;    
      print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.PRE_VALIDACAO');
      ok:=false;
      return ok;
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
		p_portaria              OUT array_portaria,
    p_retorno               OUT varchar2
  ) IS

    i     number :=0;
    d     number :=0;
    l     number :=0;
    ponto number :=0;

    l_portaria array_portaria;

    l_percurso tp_percurso;
    l_entrega  tp_entrega;
    l_transp   tp_transp;
    l_veiculo  tp_veiculo;
    l_dist     tp_dist;
    l_linhas   tp_linhas;

    l_retorno  varchar2(1000);

  begin 
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CARREGA_DADOS');
    l_portaria := array_portaria();
    i:=0;
    for r1 in c1(p_id_integracao_detalhe) loop 
      i := i + 1;
      -- Teste
      if (r1.nm_percurso is null) then
        l_retorno := 'Informações OBRIGATÓRIAS não encontradas';
        ok := false;
        exit;
      end if;

      print_out('Inicio:{'||i);
      l_portaria.extend;
      --
      print_out('  Entrega:{ - '||r1.cd_unidade_operacional||' - '||r1.USUARIO);
      g_user_name := r1.USUARIO;
      l_entrega.cd_unidade_operacional       := trim(r1.cd_unidade_operacional);
      g_organization_code                    := trim(r1.cd_unidade_operacional);
      l_entrega.ie_dividir_linha             := trim(r1.ie_dividir_linha);
      l_entrega.ie_conteudo_firme            := trim(r1.ie_conteudo_firme);
      l_entrega.ie_liberar_separacao         := trim(r1.ie_liberar_separacao);
      l_portaria(i).entrega := l_entrega;
      --
      -- Percurso
      print_out('    Percurso:{ Id Percurso        :'||r1.id_percurso);
      print_out('               Nome Percurso      :'||r1.nm_percurso);
      print_out('               Ajusta Distribuição:'||r1.ie_ajusta_distribuicao);
      print_out('               Endereço do Estoque:'||r1.cd_endereco_estoque_granel);
      print_out('               Tipo de Operação   :'||r1.tp_operacao);
      
      l_percurso.tp_operacao                    := r1.tp_operacao; 
      l_percurso.id_percurso                    := r1.id_percurso;
      l_percurso.nm_percurso                    := r1.nm_percurso;
      --
      l_percurso.cd_referencia_origem           := r1.cd_referencia_origem;
      l_percurso.tp_referencia_origem           := r1.tp_referencia_origem;
      g_cd_referencia_origem                    := r1.cd_referencia_origem;
      g_tp_referencia_origem                    := r1.tp_referencia_origem;
      --
      l_percurso.ie_ajusta_distribuicao         := r1.ie_ajusta_distribuicao;
      l_percurso.cd_lacre_veiculo               := r1.cd_lacre_veiculo;
      --
      l_percurso.qt_peso_tara                   := nvl(r1.qt_peso_tara,0);
      l_percurso.qt_peso_bruto                  := nvl(r1.qt_peso_bruto,0);
      l_percurso.qt_peso_embalagem_complementar := nvl(r1.qt_peso_embalagem_complementar,0);
      --
      l_percurso.tp_frete                       := r1.tp_frete;
      l_percurso.cd_metodo_entrega              := r1.cd_metodo_entrega;
      l_percurso.cd_endereco_estoque_granel     := r1.cd_endereco_estoque_granel;
      l_percurso.tp_liberacao                   := r1.tp_liberacao;
      l_portaria(i).entrega.percurso            := l_percurso;
      --
      -- Transportadora
      print_out('      Transportadora:{ Met Entrega  - '||r1.cd_metodo_entrega);
      print_out('                       Cod Transpor - '||r1.cd_transportador);
      l_transp.cd_transportador       := r1.cd_transportador;
      /*
      l_transp.nm_transportador       := r1.nm_transportador;
      l_transp.nu_cnpj_transportador  := r1.nu_cnpj_transportador;
      l_transp.ds_logradouro          := r1.ds_logradouro;
      l_transp.ds_municipio           := r1.ds_municipio;
      l_transp.ds_estado              := r1.ds_estado;
      */
      l_transp.nm_motorista                 := r1.nm_motorista;
      l_transp.nu_cpf_motorista             := r1.nu_cpf_motorista;
      l_portaria(i).entrega.percurso.transp := l_transp;
      print_out('      }');
      -- Veiculo
      print_out('      Veiculo:{ Placa - '||r1.nu_placa1);
      l_veiculo.cd_reg_antt          := r1.cd_reg_antt;
      l_veiculo.cd_reg_antt_cavalo   := r1.cd_reg_antt_cavalo;
      l_veiculo.nu_placa1            := r1.nu_placa1;
      l_veiculo.nu_placa2            := r1.nu_placa2;
      l_veiculo.nu_placa3            := r1.nu_placa3;
      l_veiculo.nu_placa4            := r1.nu_placa4;
      l_portaria(i).entrega.percurso.veiculo := l_veiculo;
      print_out('      }');
      --
      l_portaria(i).entrega.percurso.dist := array_dist();
      d := 0;
      if (ok) then
        for r2 in c2(p_id_integracao_detalhe) loop
          l_portaria(i).entrega.percurso.dist.extend;
          d := d + 1;
          -- Distribuicao
          print_out('      Distribuição :{ Cliente  :'||r2.cd_cliente);
          print_out('                      Nome Dist:'||r2.nm_distribuicao);
          ponto:= 0;
          ponto:=ponto+1; l_dist.nm_distribuicao               := r2.nm_distribuicao;
          ponto:=ponto+1; l_dist.cd_cliente                    := r2.cd_cliente;
          ponto:=ponto+1; l_dist.cd_ship_to                    := r2.cd_ship_to;
          ponto:=ponto+1; l_dist.vl_valor_frete                := r2.vl_valor_frete;
          ponto:=ponto+1; l_dist.cd_moeda                      := r2.cd_moeda;
          ponto:=ponto+1; l_dist.cd_controle_entrega_cliente   := r2.cd_controle_entrega_cliente;
          ponto:=ponto+1; l_dist.cd_lacres                     := r2.cd_lacres;
          ponto:=ponto+1; l_dist.ds_dados_adicionais           := r2.ds_dados_adicionais;
          ponto:=ponto+1; l_portaria(i).entrega.percurso.dist(d) := l_dist;
          --
          l_portaria(i).entrega.percurso.dist(d).linhas := array_linhas();
          l := 0; 
          ponto :=0;
          if (ok) then
            for r3 in c3(p_id_integracao_detalhe, r2.cd_cliente, r2.cd_ship_to) loop
              l := l + 1;
              -- Testes
              if (
                r3.cd_tipo_ordem_venda is null
                or r3.nu_ordem_venda is null
                --or r3.nu_linha_ordem_venda is null
                or nvl(r3.qt_quantidade,0) = 0
              ) then
                l_retorno := 'Informações OBRIGATÓRIAS não encontradas';
                ok := false;
                exit;
              end if;
              -- Linhas
              l_portaria(i).entrega.percurso.dist(d).linhas.extend;
              print_out('        Linhas:{ OE :'||r3.nu_ordem_venda||' '|| r3.nu_linha_ordem_venda||'.'|| r3.nu_envio_linha_ordem_venda||' / '|| r3.cd_tipo_ordem_venda||' - '|| r3.nu_entrega);
              print_out('                 QTD:'||r3.qt_quantidade);
              print_out('                 Un :'||r3.cd_un_medida);
              print_out('                 %G :'||r3.pr_percentual_gordura);
              --
              ponto:= 0;
              ponto:=ponto+1; l_linhas.cd_tipo_ordem_venda        := r3.cd_tipo_ordem_venda;
              ponto:=ponto+1; l_linhas.nu_ordem_venda             := r3.nu_ordem_venda;
              ponto:=ponto+1; l_linhas.nu_linha_ordem_venda       := trunc(replace(r3.nu_linha_ordem_venda,'.',','));
              ponto:=ponto+1; l_linhas.nu_envio_linha_ordem_venda := r3.nu_envio_linha_ordem_venda;
              ponto:=ponto+1; l_linhas.delivery_detail_id         := r3.nu_entrega;
              ponto:=ponto+1; l_linhas.qt_quantidade              := r3.qt_quantidade;
              ponto:=ponto+1; l_linhas.cd_un_medida               := r3.cd_un_medida;
              ponto:=ponto+1; l_linhas.qt_volumes                 := r3.qt_volumes;
              ponto:=ponto+1; l_linhas.cd_un_volume               := r3.cd_un_volume;
              ponto:=ponto+1; l_linhas.cd_un_medida               := r3.cd_un_medida;
              ponto:=ponto+1; l_linhas.cd_endereco_estoque        := r3.cd_endereco_estoque;
              ponto:=ponto+1; l_linhas.ds_observacoes             := r3.ds_observacoes;
              ponto:=ponto+1; l_linhas.pr_percentual_gordura      := r3.pr_percentual_gordura;
              
              l_portaria(i).entrega.percurso.dist(d).linhas(l)    := l_linhas;
              print_out('        }');
            end loop;
            if (l = 0) then
              --ok := false;
              l_retorno := 'JSON - Sem linhas ! ';
              --exit;
            end if;
          end if;
          print_out('      }');     
        end loop;
        if (d = 0) then
          --ok := false;
          l_retorno := 'JSON - Sem distribuição ! ';
          --exit;
        end if;
      end if;
      print_out('    }');
      print_out('  }');
      print_out('}');
    end loop;
    if (i = 0) then
      ok := false;
      l_retorno := 'JSON Fora da Especificação !';
    end if;
    if (ok) then l_retorno := 'S'; end if;
    p_portaria := l_portaria;
    p_retorno  := l_retorno;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.CARREGA_DADOS');
  exception 
    when others then
      l_retorno := 'Erro ao ler o JSON (JSON fora do formato esperado)('||ponto||'):'||SQLERRM;
      print_out('  '||l_retorno);
      print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.CARREGA_DADOS');
      p_retorno  := l_retorno;
  end;

  -- Chamadas para teste indicando o Commit
  procedure processar_entrega(
    p_id_integracao_detalhe IN  NUMBER,
    p_commit                IN  boolean,
    p_retorno               out clob
  ) is
  begin
    isCommit := p_commit;
    processar_entrega(p_id_integracao_detalhe, p_retorno);
  end;
  --
  procedure confirmar_entrega(
    p_id_integracao_detalhe IN  NUMBER,
    p_commit                IN  boolean,
    p_retorno               out clob
  ) is
  begin
    isCommit := p_commit;
    confirmar_entrega(p_id_integracao_detalhe, p_retorno);
  end;
  --
  procedure cancelar_entrega(
    p_id_integracao_detalhe IN  NUMBER,
    p_commit                IN  boolean,
    p_retorno               out clob
  ) is
  begin
    isCommit := p_commit;
    cancelar_entrega(p_id_integracao_detalhe, p_retorno);
  end;
  -- Fim Chamadas para teste indicando o Commit

  -- *********************************************************************
  -- Id_Integracao_Detalhe
  procedure processar_entrega(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  ) is

    a_portaria                array_portaria;
    n_qtdDistrib              number;
    n_qtdLinhas               number;
    --   
    n_ids     number;   

    l_delivery_id_tbl           WSH_UTIL_CORE.id_tab_type;
    l_new_delivery_detail_id    number;

    l_delivery_detail_id        number;
    l_qtd                       number;

    l_trip_id                   number;
    l_delivery_id               number;
    l_delivery_name             varchar2(20);
    l_lot_number                varchar2(50);
    l_retorno                   varchar2(3000);
    l_msg_retorno               varchar2(3000);
    
    l_numero_ordem              varchar2(30);
    l_linha                     varchar2(30);
    l_tipo_ordem                varchar2(30);

    cursor d1(i_trip_name varchar2) is
      select distinct wt.trip_id, wt.name, a.delivery_id, ov.flow_status_code, wt.status_code, ov.conteudo_firme, ov.percurso_firme
      from 
        wsh_trips wt,
        xxfr_wsh_vw_inf_da_ordem_venda ov,
        (
          select distinct wts.trip_id, wdl.delivery_id
          from 
            wsh_trip_stops    wts,
            wsh_delivery_legs wdl
          where 
            wts.stop_id = wdl.pick_up_stop_id
            or
            wts.stop_id = wdl.drop_off_stop_id
        ) a
      where 1=1
        and wt.trip_id = a.trip_id (+)
        and wt.trip_id = ov.trip_id (+)
        and wt.name    = i_trip_name
    ;

    l_released_status  varchar2(30);
    l_status_percurso  varchar2(30);
    
    i  number :=0;
    d  number :=0;

  begin
    ok := true;
    g_rec_retorno := NULL;
    g_rec_retorno."contexto":= 'PROCESSAR_ENTREGA';
    g_escopo := 'PROCESSAR_ENTREGA_'||p_id_integracao_detalhe;
    print_out('----------------------------------------------------------------');
    print_out('INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS')||' - Vr:'||g_versao);
    print_out('----------------------------------------------------------------');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_ENTREGA:'||p_id_integracao_detalhe);
    --
    --Somente para testes a variavel isCommit é sempre true;
    if (isCommit) then SAVEPOINT PROCESSAR_ENTREGA; end if;
    -- INICIO
    if (ok) then
      begin
        xxfr_pck_interface_integracao.andamento(p_id_integracao_detalhe => p_id_integracao_detalhe);
        -- CARGA DO JSON
        if (ok) then
          carrega_dados(
            p_id_integracao_detalhe => p_id_integracao_detalhe, 
            p_portaria              => a_portaria, 
            p_retorno               => l_retorno
          );
          if (l_retorno <> 'S') then
            ok := false;
            g_rec_retorno."retornoProcessamento"        := 'ERRO';
            g_rec_retorno."mensagemRetornoProcessamento":=l_retorno;
          end if;
        end if;
        -- FIM CARGA DO JSON
        g_rec_retorno."registros"(1)."tipoReferenciaOrigem"   := g_tp_referencia_origem;
        g_rec_retorno."registros"(1)."codigoReferenciaOrigem" := g_cd_referencia_origem;
        -- INICIALIZA AMBIENTE DO ORACLE
        if (ok) then
          begin
            xxfr_pck_variaveis_ambiente.inicializar('ONT',g_organization_code, upper(g_user_name));
          exception when others then
            l_retorno := 'Não foi possivel inicializar o ambiente Oracle:'||sqlerrm;
            xxfr_pck_variaveis_ambiente.inicializar('ONT',g_organization_code);
            print_out(l_retorno);
            --ok:=false;
          end;
        end if;
        -- NIVEL PORTARIA
        --
        if (ok) then
          for i in 1 .. a_portaria.count loop
            print_out('PORTARIA '||i);
            g_tp_percurso := a_portaria(i).entrega.percurso;
            g_rec_retorno."registros"(i)."tipoCabecalho"          := 'PERCURSO';
            g_rec_retorno."registros"(i)."codigoCabecalho"        := g_tp_percurso.nm_percurso;
            g_rec_retorno."registros"(i)."tipoReferenciaOrigem"   := g_tp_referencia_origem;
            g_rec_retorno."registros"(i)."codigoReferenciaOrigem" := g_cd_referencia_origem;
            --
            ok := pre_validacao(p_id_integracao_detalhe);
            -- CONTROLE DO NOME DO PERCURSO -------------------------------- 
            if (ok) then
              begin    
                l_trip_id := null;
                for r1 in d1(g_tp_percurso.nm_percurso) loop
                  -- Valida Percurso
                  l_trip_id := r1.trip_id;
                  if (g_tp_percurso.tp_operacao ='INCLUIR') THEN
                    begin
                      select distinct released_status, status_percurso 
                      into l_released_status, l_status_percurso
                      from xxfr_wsh_vw_inf_da_ordem_venda 
                      where 1=1
                        and nome_percurso = g_tp_percurso.nm_percurso
                      ;
                      print_out('Informação: Já existe um percurso criado com o nome Informado...');
                      if (l_released_status = 'C' and l_status_percurso = 'CL') then
                        ok:=false;
                        l_retorno := 'O percurso informado já foi processado e fechado !';
                      end if;
                      if (l_status_percurso = 'OP') then
                        ok:=false;
                        l_retorno := 'O percurso informado já esta associado a uma entrega !';
                      end if;
                    exception when no_data_found then
                      ok:=true;
                      print_out('  Checagem de nome de percurso OK !');
                    end;
                  end if;
                  --
                  if (ok and g_tp_percurso.tp_operacao ='INCLUIR' and l_trip_id is null) then
                    print_out('  OPERAÇÃO:'||g_tp_percurso.tp_operacao);
                    print_out('  PERCURSO:'||r1.name||' - ENTREGA:'||r1.delivery_id||' - STATUS:'||r1.flow_status_code);
                    print_out('  RENOMEANDO PERCURSO:'||r1.trip_id||' -> de '||g_tp_percurso.nm_percurso||' para '||r1.trip_id);
                    g_tp_percurso.nm_percurso := r1.trip_id;
                    --
                    criar_atualizar_percurso(
                      p_percurso    => g_tp_percurso, 
                      p_trip_id     => r1.trip_id,
                      p_action_code => 'UPDATE',
                      x_trip_id     => l_trip_id,
                      x_retorno     => l_retorno
                    );
                    
                    begin
                      select trip_id into l_trip_id from wsh_trips where name = g_tp_percurso.nm_percurso;
                      ok:=false;
                      l_retorno := 'O Percurso não foi renomeado !';
                      print_out(l_retorno);
                    exception when no_data_found then
                      null;
                    end ;
                    
                    g_tp_percurso := a_portaria(i).entrega.percurso;
                    if (l_retorno <> 'S') then
                      ok := false;
                      exit;
                    end if;             
                  end if;
                end loop;
              exception 
                when others then
                  print_out('ERRO OUTROS:'||SQLERRM);
                  ok := false;
                  EXIT;
              end;
            end if;          
            -- CRIAR/RESGATAR PERCURSO  
            if (ok) then        
              if (g_tp_percurso.tp_operacao = 'INCLUIR' and l_trip_id is null) then
                print_out('');
                print_out('CRIANDO PERCURSO '||g_tp_percurso.nm_percurso);
                criar_atualizar_percurso(
                  p_percurso    => a_portaria(i).entrega.percurso,
                  p_action_code => 'CREATE',
                  p_trip_id     => null,
                  x_trip_id     => l_trip_id,
                  x_retorno     => l_retorno
                );
                if (l_retorno <> 'S') then
                  ok:=false;
                end if;
              end if;
              if (g_tp_percurso.tp_operacao = 'ALTERAR') then
                print_out('');
                print_out('RESGATANDO INF. PERCURSO '||g_tp_percurso.nm_percurso);
                begin
                  select trip_id into l_trip_id 
                  from wsh_trips 
                  where name = g_tp_percurso.nm_percurso;
                  l_retorno := 'S';
                exception when no_data_found then 
                  l_retorno := 'Não encontrado o percurso:'||g_tp_percurso.nm_percurso;
                  ok:=false;
                end;
              end if;             
              if (ok = false) then
                g_rec_retorno."registros"(i)."retornoProcessamento"        := 'ERRO';
                g_rec_retorno."registros"(i)."mensagens"(1)."tipoMensagem" := 'ERRO';
                g_rec_retorno."registros"(i)."mensagens"(1)."mensagem"     := l_retorno;
                exit;
              end if;
              a_portaria(i).entrega.percurso.id_percurso := l_trip_id;
            end if;
            -- FIM CRIAR/RESGATAR PERCURSO
            -----------------------------------------------------------------------------------------------------------
            -----------------------------------------------------------------------------------------------------------
            -----------------------------------------------------------------------------------------------------------
            --  INICIO DAS DISTRIBUIÇÕES (CRIAR ENTREGA, SPLIT DE LINHA, ASS DELIVERY A LINHA, CONTEUDO FIRME, RESERVAR, PICK)
            if (ok) then
              n_ids := 0;
              l_delivery_id_tbl.delete;
              ---------------------------------------------------------------------------------------------------------
              ---------------------------------------------------------------------------------------------------------
              ---------------------------------------------------------------------------------------------------------
              -- Processo COM Distribuição no JSON
              if (a_portaria(i).entrega.percurso.dist.count > 0) then
                -- Inicio do Loop das Distribuições
                g_qtd_alocada_pedido := 0;
                for d in 1 .. a_portaria(i).entrega.percurso.dist.count loop
                  -- CRIAR ENTREGA
                  if (ok) then
                    print_out('');
                    print_out('CRIANDO ENTREGA '||d);
                    --if (l_delivery_id is null) then
                      criar_atualizar_entrega(             
                        p_percurso      => a_portaria(i).entrega.percurso,
                        p_dist          => a_portaria(i).entrega.percurso.dist(d),
                        p_delivery_id   => null,
                        p_action_code   => 'CREATE',
                        x_delivery_id   => l_delivery_id,
                        x_delivery_name => l_delivery_name,
                        x_retorno       => l_retorno
                      );
                    --end if;
                    if (l_retorno <> 'S') then
                      ok:= false;
                      g_rec_retorno."registros"(i)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'ERRO';
                      g_rec_retorno."registros"(i)."linhas"(d)."mensagens"(1)."mensagem"     := l_retorno;
                      exit;
                    else
                      a_portaria(i).entrega.percurso.dist(d).nm_distribuicao := l_delivery_name;
                      a_portaria(i).entrega.percurso.dist(d).id_distribuicao := l_delivery_id;
                      l_delivery_id_tbl(d) := l_delivery_id;
                    end if;
                  end if;
                  -- FIM CRIAR ENTREGA                    
                  -- SPLIT DA LINHA 
                  if (ok) then
                    g_delivery_detail_id_tbl.delete;
                    for l in 1 .. a_portaria(i).entrega.percurso.dist(d).linhas.count loop
                      g_tp_dist := a_portaria(i).entrega.percurso.dist(d);
                      g_tp_linhas := g_tp_dist.linhas(l);
                      print_out('INICIANDO CHECAGEM PARA SPLIT DE LINHA...');
                      controle_split(
                        p_linha                   => g_tp_linhas,
                        x_retorno                 => l_retorno
                      );
                      print_out('FIM CHECAGEM PARA SPLIT DE LINHA...');
                    end loop; 
                  end if;
                  -- FIM SPLIT DA LINHA
                  -- ASSOCIAR DELIVERY AS LINHAS
                  if (ok) then
                    associar_linha_entrega(
                      p_delivery_id         => l_delivery_id,
                      p_delivery_name       => l_delivery_name,
                      p_delivery_detail_tab => g_delivery_detail_id_tbl,
                      x_delivery_id         => l_delivery_id,
                      x_retorno             => l_retorno
                    );
                    l_delivery_id_tbl(d) := l_delivery_id;
                    
                    if (l_retorno <> 'S') then
                      g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'ASSOC.ENTREGA/LINHA';
                      g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := l_delivery_name;
                      g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := g_tp_referencia_origem;
                      g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                      g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'ERRO';
                      g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."mensagem"     := l_retorno;
                      ok:=false;
                      exit;
                    else
                      print_out('');
                      print_out('ATUALIZANDO ENTREGA '||d);
                      print_out('Informações de Transportador de demais Flex...');
                      criar_atualizar_entrega(
                        p_percurso      => a_portaria(i).entrega.percurso,
                        p_dist          => a_portaria(i).entrega.percurso.dist(d),
                        p_delivery_id   => l_delivery_id,
                        p_action_code   => 'UPDATE',
                        --
                        x_delivery_id   => l_delivery_id,
                        x_delivery_name => l_delivery_name,
                        x_retorno       => l_retorno
                      );
                      if (l_retorno <> 'S') then
                        g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'ATTRIBUTOS DA ENTREGA';
                        g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := l_delivery_name;
                        g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := g_tp_referencia_origem;
                        g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                        g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'ERRO';
                        g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."mensagem"     := l_retorno;
                        ok:= false;
                        exit;
                      --else
                      --  l_delivery_id_tbl(d) := l_delivery_id;
                      end if;
                    end if;
                  end if;
                  -- FIM ASSOCIAR DELIVERY AS LINHAS
                  -- PROCESSAR CONTEUDO FIRME
                  if (ok and a_portaria(i).entrega.ie_conteudo_firme='SIM') then             
                    processar_conteudo_firme(
                      p_delivery_id => l_delivery_id,
                      p_action_code => 'PLAN',
                      x_retorno     => l_retorno
                    );
                  end if;
                  -- CRIAR RESERVA
                  if (ok and isReservar) then       
                    for l in 1 .. a_portaria(i).entrega.percurso.dist(d).linhas.count loop
                      g_tp_dist := a_portaria(i).entrega.percurso.dist(d);
                      g_tp_linhas := a_portaria(i).entrega.percurso.dist(d).linhas(l);
                      
                      -- Aqui é feito o controle de reserva, uma vez que poderemos ter varias entregas
                      if ( nvl(g_tp_linhas.cd_endereco_estoque,a_portaria(i).entrega.percurso.cd_endereco_estoque_granel) is null) then
                        continue;
                      end if;
                      
                      print_out('');
                      print_out('Iniciando processo de Criação da Reserva...');
                      print_out('cd_endereco_estoque :'||g_tp_linhas.cd_endereco_estoque);
                      print_out('delivery_id         :'||l_delivery_id); 
                      -- Neste ponto o Percurso ainda não foi associado a entrega !!!
                      for d2 in (
                        select distinct delivery_id, numero_ordem, tipo_ordem, linha, delivery_detail_id, qtd 
                        from xxfr_wsh_vw_inf_da_ordem_venda
                        where 1=1
                          and released_status <> 'C'
                          and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
                          --and delivery_id =201032
                          and delivery_id = l_delivery_id
                      ) loop
                        print_out('delivery_detail_id  :'||d2.delivery_detail_id);
                        print_out('Quantidade          :'||d2.qtd);
                        g_tp_linhas.cd_tipo_ordem_venda := d2.tipo_ordem;
                        g_tp_linhas.nu_ordem_venda      := d2.numero_ordem;
                        g_tp_linhas.nu_linha_ordem_venda:= d2.linha;
                        g_tp_linhas.qt_quantidade       := d2.qtd;
                        g_tp_linhas.delivery_detail_id  := d2.delivery_detail_id;
                        g_tp_linhas.cd_endereco_estoque := nvl(g_tp_linhas.cd_endereco_estoque,a_portaria(i).entrega.percurso.cd_endereco_estoque_granel);
                        criar_reserva(
                          p_linhas     => g_tp_linhas, 
                          p_operacao   => 'INSERIR',
                          x_lot_number => l_lot_number,
                          x_retorno    => l_retorno 
                        );
                        if (l_retorno <> 'S') then
                          g_rec_retorno."registros"(i)."linhas"(d)."tipoLinha"                   := 'ENTREGA-'||d;
                          g_rec_retorno."registros"(i)."linhas"(d)."codigoLinha"                 := NULL;
                          g_rec_retorno."registros"(i)."linhas"(d)."tipoReferenciaLinhaOrigem"   := g_tp_referencia_origem;
                          g_rec_retorno."registros"(i)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                          g_rec_retorno."registros"(i)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'AVISO';
                          g_rec_retorno."registros"(i)."linhas"(d)."mensagens"(1)."mensagem"     := l_retorno;
                          --ok:=false;
                          --exit;
                        end if;
                      end loop;                   
                    end loop;
                  end if;
                  -- FIM RESERVA
                end loop;
                -- Fim do Loop das Distribuições
              end if;
              -- FIM Processo COM Distribuição no JSON
              ---------------------------------------------------------------------------------------------------------
              ---------------------------------------------------------------------------------------------------------
              ---------------------------------------------------------------------------------------------------------
              -- Processo SEM Distribuição no JSON (ALTERAÇÃO DO PERCURSO)
              if (a_portaria(i).entrega.percurso.dist.count = 0) then
                print_out('Informação:Distribuição (Entrega) NAO informada');
                --RESGATANDO A ENTREGA
                d:=0;
                print_out('Processando distribuições do percurso:'||l_trip_id);
                --DESATRIBUIR CONTEUDO FIRME
                for r1 in (select distinct delivery_id, conteudo_firme from XXFR_WSH_VW_INF_DA_ORDEM_VENDA where trip_id = l_trip_id) loop
                  if (ok) then 
                    processar_conteudo_firme(
                      p_delivery_id => r1.delivery_id,
                      p_action_code => 'UNPLAN',
                      x_retorno     => l_retorno
                    );
                  end if;
                end loop;
                --DESATRIBUIR PERCURSO FIRME
                if (ok) then
                  processar_percurso_firme(
                    p_trip_id     => a_portaria(i).entrega.percurso.id_percurso,
                    p_action_code => 'UNPLAN',
                    x_retorno     => l_retorno
                  );
                end if;
                -- ATUALIZAR INFORMAÇOES DO PERCURSO
                if (ok) then
                  criar_atualizar_percurso(
                    p_percurso                => a_portaria(i).entrega.percurso,
                    p_trip_id                 => a_portaria(i).entrega.percurso.id_percurso,
                    p_action_code             => 'UPDATE',
                    x_trip_id                 => l_trip_id,
                    x_retorno                 => l_retorno 
                  );
                  if (l_retorno <> 'S') then
                    ok:=false;
                  end if;
                end if;
                --
                if (a_portaria(i).entrega.percurso.cd_endereco_estoque_granel is null) then
                  isReservar := false;
                end if;
                -- SPLIT DA LINHA 
                g_tp_percurso := a_portaria(i).entrega.percurso;
                if (ok and g_tp_percurso.ie_ajusta_distribuicao = 'SIM' and g_tp_percurso.cd_endereco_estoque_granel is null) then
                  g_delivery_detail_id_tbl.delete;
                  for d1 in (select * from xxfr_wsh_vw_inf_da_ordem_venda where trip_id = g_tp_percurso.id_percurso) loop
                    g_tp_linhas.cd_tipo_ordem_venda        := d1.tipo_ordem;
                    g_tp_linhas.nu_ordem_venda             := d1.numero_ordem;
                    g_tp_linhas.nu_linha_ordem_venda       := d1.linha;
                    g_tp_linhas.nu_envio_linha_ordem_venda := d1.envio;
                    g_tp_linhas.delivery_detail_id         := d1.delivery_detail_id;
                    g_tp_linhas.qt_quantidade              := (g_tp_percurso.qt_peso_bruto - g_tp_percurso.qt_peso_tara - g_tp_percurso.qt_peso_embalagem_complementar);
                    g_tp_linhas.cd_un_medida               := 'KG';
                    print_out('INICIANDO CHECAGEM PARA SPLIT DE LINHA...');
                    controle_split(
                      p_linha                   => g_tp_linhas,
                      x_retorno                 => l_retorno
                    );
                    print_out('FIM CHECAGEM PARA SPLIT DE LINHA...');
                    if (ok) then
                      g_delivery_detail_id_tbl(1) := d1.delivery_detail_id;
                      xxfr_wsh_pck_transacoes.associar_linha_entrega(
                        p_delivery_id         => d1.delivery_id,
                        p_delivery_detail_tab => g_delivery_detail_id_tbl,
                        p_action              => 'UNASSIGN',
                        x_retorno             => l_retorno 
                      );
                    end if;
                  end loop; 
                  --ATRIBUIR CONTEUDO FIRME
                  for r1 in (select distinct delivery_id, conteudo_firme from XXFR_WSH_VW_INF_DA_ORDEM_VENDA where trip_id = g_tp_percurso.id_percurso) loop
                    if (ok) then 
                      processar_conteudo_firme(
                        p_delivery_id => r1.delivery_id,
                        p_action_code => 'PLAN',
                        x_retorno     => l_retorno
                      );
                    end if;
                  end loop;
                end if;
                -- FIM SPLIT DA LINHA
                --
                -- INICIO DO PROCESSO DE RESERVA 
                if (ok and isReservar) then
                  print_out('*** Inicio do loop das Deliveries...');
                  print_out('----------------------------------------------------------------------------------');
                  for r1 in (
                    select distinct trip_id, delivery_id, numero_ordem, tipo_ordem --, linha 
                    from xxfr_wsh_vw_inf_da_ordem_venda
                    where 1=1
                      and released_status <> 'C'
                      and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
                      and trip_id = a_portaria(i).entrega.percurso.id_percurso
                  ) loop
                    d:=d+1;
                    l_delivery_id_tbl(d) := r1.delivery_id;
                    print_out('');
                    print_out('Delivery ('||d||') - '||r1.delivery_id);
                    -- CRIAR RESERVA
                    if (ok and isReservar) then
                      print_out('');
                      print_out('Iniciando processo de Criação da Reserva...');
                      print_out('cd_endereco_estoque :'||a_portaria(i).entrega.percurso.cd_endereco_estoque_granel);
                      print_out('trip_id             :'||r1.trip_id);
                      print_out('delivery_id         :'||r1.delivery_id);
                      for r2 in (
                        select distinct delivery_id, numero_ordem, tipo_ordem, linha, delivery_detail_id, qtd 
                        from xxfr_wsh_vw_inf_da_ordem_venda
                        where 1=1
                          and released_status <> 'C'
                          and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
                          --and trip_id     = 171031 --l_trip_id
                          --and delivery_id = 172026 --r1.delivery_id
                          and trip_id     = r1.trip_id
                          and delivery_id = r1.delivery_id
                      ) loop
                        print_out('delivery_detail_id  :'||r2.delivery_detail_id);
                        print_out('Quantidade          :'||r2.qtd);
                        g_tp_linhas.cd_tipo_ordem_venda := r2.tipo_ordem;
                        g_tp_linhas.nu_ordem_venda      := r2.numero_ordem;
                        g_tp_linhas.nu_linha_ordem_venda:= r2.linha;
                        g_tp_linhas.qt_quantidade       := r2.qtd;
                        g_tp_linhas.delivery_detail_id  := r2.delivery_detail_id;
                        g_tp_linhas.cd_endereco_estoque := a_portaria(i).entrega.percurso.cd_endereco_estoque_granel;
                        --
                        if (ok ) then
                          criar_reserva(
                            p_linhas     => g_tp_linhas, 
                            p_operacao   => 'INSERIR',
                            x_lot_number => l_lot_number,
                            x_retorno    => l_retorno 
                          );
                          if (l_retorno <> 'S') then
                            g_rec_retorno."registros"(i)."linhas"(d)."tipoLinha"                   := 'ENTREGA-'||d;
                            g_rec_retorno."registros"(i)."linhas"(d)."codigoLinha"                 := NULL;
                            g_rec_retorno."registros"(i)."linhas"(d)."tipoReferenciaLinhaOrigem"   := g_tp_referencia_origem;
                            g_rec_retorno."registros"(i)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                            g_rec_retorno."registros"(i)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'AVISO';
                            g_rec_retorno."registros"(i)."linhas"(d)."mensagens"(1)."mensagem"     := l_retorno;
                            --ok:=false;
                            --exit;
                          end if;
                        end if;
                        --
                      end loop;
                    end if;
                    -- ATRIBUIR CONTEUDO FIRME
                    if (1=2) then
                      processar_conteudo_firme(
                        p_delivery_id => r1.delivery_id,
                        p_action_code => 'PLAN',
                        x_retorno     => l_retorno
                      );
                    end if;
                  end loop;
                  print_out('----------------------------------------------------------------------------------');
                  print_out('*** Fim do loop das Deliveries...');
                  if (d = 0) then
                    l_retorno := 'O Percurso Informado não esta associado a nenhuma entrega !';
                    print_out('O Percurso Informado não esta associado a nenhuma entrega !');
                    ok:=false;
                  end if;
                end if;
                -- FIM INICIO DO PROCESSO DE RESERVA 
              end if;
              -- FIM Processo SEM Distribuição no JSON (ALTERAÇÃO DO PERCURSO)
              ---------------------------------------------------------------------------------------------------------
            end if;
            --  FIM DISTRIBUIÇÕES
            -----------------------------------------------------------------------------------------------------------
            -- ASSOCIAR ENTREGAS AO PERCURSO QUANDO TIVER LINHA NO JSON        
            if (ok and a_portaria(i).entrega.percurso.dist.count > 0) then
              associar_entrega_percurso(
                p_delivery_id_tbl => l_delivery_id_tbl,
                p_trip_id         => l_trip_id,
                x_retorno         => l_retorno
              );
              if (l_retorno <> 'S') then
                for d in 1 .. l_delivery_id_tbl.count loop
                  g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'ASSOC PERCURSO/ENTREGA';
                  g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := l_delivery_id_tbl(d);
                  g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := g_tp_referencia_origem;
                  g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                  g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'ERRO';
                  g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."mensagem"     := l_retorno;
                end loop;
                ok:= false;
                exit;
              end if;
            end if;
            -- FIM ASSOCIAR ENTREGAS AO PERCURSO
            ----------------------------------------------------------------------------------------------------------- 
          end loop;
        end if;
        -- FIM NIVEL PORTARIA
        if (a_portaria(1).entrega.percurso.tp_liberacao is null) then
          print_out('Tipo de Liberação não informado, não será feito o Pick Release !');
        end if;
        -- PICK RELEASE
        if (ok and a_portaria(1).entrega.percurso.tp_liberacao is not null) then
            --ATRIBUIR CONTEUDO FIRME
            l_trip_id := a_portaria(1).entrega.percurso.id_percurso;
            for r1 in (select distinct delivery_id, conteudo_firme from XXFR_WSH_VW_INF_DA_ORDEM_VENDA where trip_id = l_trip_id) loop
              if (ok and r1.conteudo_firme = 'N') then
                processar_conteudo_firme(
                  p_delivery_id => r1.delivery_id,
                  p_action_code => 'PLAN',
                  x_retorno     => l_retorno
                );
              end if;
            end loop;
          --for r in 1 .. l_delivery_id_tbl.count loop
            proc_delivery_pick_release(
              p_delivery_id    => NULL, --l_delivery_id_tbl(r),
              p_trip_id        => a_portaria(1).entrega.percurso.id_percurso,
              p_r              => 0, --r,  -- Posição da Delivery para montagens das mensagens de erro em caso de Hold
              p_tipo_liberacao => a_portaria(1).entrega.percurso.tp_liberacao,
              x_msg_retorno    => l_msg_retorno,
              x_retorno        => l_retorno
            );
            print_out('Retorno :'||l_retorno);
            if (l_retorno <> 'S') then
              g_rec_retorno."registros"(1)."linhas"(1)."tipoLinha"                   := 'PICK RELEASE';
              --g_rec_retorno."registros"(1)."linhas"(r)."codigoLinha"                 := l_delivery_id_tbl(r);
              g_rec_retorno."registros"(1)."linhas"(1)."tipoReferenciaLinhaOrigem"   := g_tp_referencia_origem;
              g_rec_retorno."registros"(1)."linhas"(1)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
              if (l_retorno <> 'HOLD') then
                g_rec_retorno."registros"(1)."linhas"(1)."mensagens"(1)."tipoMensagem" := 'ERRO';
                g_rec_retorno."registros"(1)."linhas"(1)."mensagens"(1)."mensagem"     := l_retorno;
              end if;
              ok:= false;
              --exit;
            end if;
          --end loop;
        end if;
        -- AJUSTAR DISTRIBUIÇÃO COM ENDEREÇO DE ESTOQUE
        if (ok and a_portaria(1).entrega.percurso.ie_ajusta_distribuicao = 'SIM') then
          g_tp_percurso := a_portaria(1).entrega.percurso;
          --
          criar_atualizar_percurso(
            p_percurso     => g_tp_percurso,
            p_trip_id      => l_trip_id,
            p_action_code  => 'UPDATE',
            x_trip_id      => l_trip_id,
            x_retorno      => l_retorno
          );
          --
          if (a_portaria(1).entrega.percurso.cd_endereco_estoque_granel is not null) then
            print_out('Peso Tara   :'||g_tp_percurso.qt_peso_tara);
            print_out('Peso Bruto  :'||g_tp_percurso.qt_peso_bruto);     
            print_out('Peso Ajustar:'||(g_tp_percurso.qt_peso_bruto - g_tp_percurso.qt_peso_tara - g_tp_percurso.qt_peso_embalagem_complementar));
            print_out('Peso Embalgn:'||g_tp_percurso.qt_peso_embalagem_complementar);
            --
            criar_mov_subinventario(
              p_trip_id             => a_portaria(1).entrega.percurso.id_percurso,
              p_cd_endereco_estoque => a_portaria(1).entrega.percurso.cd_endereco_estoque_granel,
              p_qtd                 => (g_tp_percurso.qt_peso_bruto - g_tp_percurso.qt_peso_tara - g_tp_percurso.qt_peso_embalagem_complementar),
              x_retorno             => l_retorno
            );
          end if;
        end if;            
      exception
        when others then
          print_out('ERRO FIM DE PROCESSO - OUTROS:'||SQLERRM);
          ok := false;
          g_rec_retorno."retornoProcessamento"        := 'ERRO';
          g_rec_retorno."mensagemRetornoProcessamento":= SQLERRM;
      end;
      --
    end if;
    ---------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------
    if (ok = true) then
      print_out(' ');
      print_out('  SUCESSO !!!');
      --if (isCommit) then COMMIT; end if;
      g_rec_retorno."retornoProcessamento"         := 'SUCESSO';
      g_rec_retorno."mensagemRetornoProcessamento" := '';
      
      begin
        i:=0;
        for r1 in (
          select batch_id, sum(requested_quantity) total
          from wsh_trip_deliverables_v where trip_id = g_tp_percurso.id_percurso
          group by batch_id
        ) loop
          i:=i+1;
          g_rec_retorno."registros"(1)."linhas"(1)."mensagens"(i)."tipoMensagem" := 'Num.Ord.Mov: '||r1.batch_id;
          g_rec_retorno."registros"(1)."linhas"(1)."mensagens"(i)."mensagem"     := 'Qtd:'||r1.total;
        end loop;
      end;
      xxfr_pck_interface_integracao.sucesso (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    end if;
    if (ok = false) then
      print_out(' ');
      print_out('  ERRO !!!');
      if (isCommit) then 
        print_out('  Executando ROLLBACK !');
        ROLLBACK TO PROCESSAR_ENTREGA;
      end if;
      g_rec_retorno."retornoProcessamento"           := 'ERRO';
      if (g_rec_retorno."mensagemRetornoProcessamento" is null) then
        g_rec_retorno."mensagemRetornoProcessamento" := l_retorno;
      end if;
      xxfr_pck_interface_integracao.erro (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    end if;
    retornar_clob( 
      p_id_integracao_detalhe => p_id_integracao_detalhe, 
      p_retorno               => p_retorno
    );
    print_out('----------------------------------------------------------------');
    print_out('FIM DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS'));
    print_out('----------------------------------------------------------------'); 
  exception when others then
    xxfr_pck_logger.log_error('Exceção não tratada :','XXFR_WSH_PCK_INT_ENTREGA.processar_entrega');
    raise;
  end;
  -- Id_Integracao_Detalhe
  procedure confirmar_entrega (
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  ) IS

    l_nm_percurso         varchar2(20);
    l_ie_recalcula_preco  varchar2(10);
    l_trip_id             number;
    l_retorno             varchar2(3000);
    
    l_preco               number;

    cursor c1(i_nm_percurso in varchar2) is
      select distinct trip_id, nome_percurso, oe_header, oe_line, flow_status_code
      from xxfr_wsh_vw_inf_da_ordem_venda 
      where 1=1
        and nome_percurso    =  i_nm_percurso
        --and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
      ;

    n number :=0;
  begin
    ok := true;
    g_escopo := 'CONFIRMAR_ENTREGA_'||p_id_integracao_detalhe;
    --Somente para testes a variavel isCommit é sempre true;
    if (isCommit) then SAVEPOINT CONFIRMAR_ENTREGA; end if;
    print_out('----------------------------------------------------------------');
    print_out('INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS')||' - Vr:'||g_versao);
    print_out('----------------------------------------------------------------');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CONFIRMAR_ENTREGA:'||p_id_integracao_detalhe);
    g_rec_retorno := null;
    g_rec_retorno."contexto"    := 'CONFIRMAR_ENTREGA';
    ok := true;
    n := 0;
    -- Validação Inicial
    begin
      select usuario,     nm_percurso,   cd_referencia_origem,   tp_referencia_origem,   nvl(cd_unidade_operacional,'UO_FRISIA'), nvl(ie_recalcula_preco,'NAO') ie_recalcula_preco
      into   g_user_name, l_nm_percurso, g_cd_referencia_origem, g_tp_referencia_origem, g_organization_code, l_ie_recalcula_preco
      from xxfr_wsh_vw_int_conf_entrega
      where 1=1
        and id_integracao_detalhe = p_id_integracao_detalhe
      ;
      print_out('  Nome Percurso   :'||l_nm_percurso);
      print_out('  Recalcular Preço:'||l_ie_recalcula_preco);
    exception
      when too_many_rows then
        l_retorno := 'ERRO: Mais de 1 percurso encontrado para integração informada '||p_id_integracao_detalhe;
        print_out('  '||l_retorno);
        ok := false;
      when no_data_found then
        l_retorno := 'ERRO: Nenhum percurso encontrado para integração informada '||p_id_integracao_detalhe;
        print_out('  '||l_retorno);
        ok := false;
      when others then
        l_retorno := 'ERRO:'||sqlerrm;
        print_out('  '||l_retorno);
        ok := false;
    end;
    -- Inicializa ambiente
    if (ok) then
      begin
        print_out('  Usuario  :'||g_user_name);
        xxfr_pck_variaveis_ambiente.inicializar('ONT',g_organization_code, g_user_name);
      exception when others then
        l_retorno := 'Não foi possivel inicializar o ambiente Oracle:'||sqlerrm;
        print_out(l_retorno);
        ok:=false;
      end;
    end if;
    -- Inicia Pre-Processo 
    if (ok) then
      print_out('  Percurso:'||l_nm_percurso);
      for r1 in c1(l_nm_percurso) loop
        n := n + 1;
        print_out('');
        print_out('  TRIP_ID    :'||r1.trip_id);
        l_trip_id := r1.trip_id;
        if (r1.flow_status_code in ('CANCELLED','INVOICE_INCOMPLETE')) then
          l_retorno := 'O percurso não apto para Confirmação :'||r1.flow_status_code;
          ok:=false;
        elsif (r1.flow_status_code in ('SHIPPED','CLOSED')) then
          l_retorno := 'Este percurso já esta Finalizado !';
          ok:=false;
        else
          if (l_ie_recalcula_preco = 'SIM') then
            print_out('Chamando XXFR_OM_PCK_TRANSACOES.REPRECIFICAR...');
            select unit_selling_price into l_preco from oe_order_lines_all where line_id = r1.oe_line;
            print_out('  Preço antes :'||l_preco);
            XXFR_OM_PCK_TRANSACOES.reprecificar(
              p_id_ordem_venda            => r1.oe_header,
              p_id_linha_ordem_venda      => r1.oe_line, 
              p_atualizar_preco_congelado => 'S', 
              p_retorno                   => l_retorno
            );
            select unit_selling_price into l_preco from oe_order_lines_all where line_id = r1.oe_line;
            print_out('  Preço depois:'||l_preco);
            print_out('Retorno :'||l_retorno);
            if (l_retorno <> 'SUCESSO') then
              ok:=false;
            end if;
          end if;
        end if;
      end loop;
    end if;
    if n = 0 then
      l_retorno := 'Entrega não encontrada para o percurso informado !';
      print_out('  '||l_retorno);
      ok := false;
    end if;
    -- Confirma
    if (ok) then
      processar_trip_confirm(
        p_trip_id       => l_trip_id,
        p_action_code   => 'TRIP-CONFIRM',
        x_retorno       => l_retorno
      );
      if (l_retorno <> 'S') then
        print_out('  '||l_retorno);
        ok := false;
      end if;
    end if;
    --
    g_rec_retorno."registros"(1)."tipoCabecalho"               := 'CONFIRMA ENTREGA';
    g_rec_retorno."registros"(1)."codigoCabecalho"             := l_nm_percurso;
    g_rec_retorno."registros"(1)."tipoReferenciaOrigem"        := g_tp_referencia_origem;
    g_rec_retorno."registros"(1)."codigoReferenciaOrigem"      := g_cd_referencia_origem;
    --
    if (ok) then 
      g_rec_retorno."retornoProcessamento" := 'SUCESSO';
      xxfr_pck_interface_integracao.sucesso (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    else
      if (isCommit) then ROLLBACK TO CONFIRMAR_ENTREGA; end if;
      g_rec_retorno."retornoProcessamento"                  := 'ERRO';
      g_rec_retorno."mensagemRetornoProcessamento"          := l_retorno; 
      g_rec_retorno."registros"(1)."retornoProcessamento"   := 'ERRO';
      xxfr_pck_interface_integracao.erro (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    end if;
    retornar_clob( 
      p_id_integracao_detalhe => p_id_integracao_detalhe, 
      p_retorno               => p_retorno
    );
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.CONFIRMAR_ENTREGA:'||p_id_integracao_detalhe);
    print_out('----------------------------------------------------------------');
    print_out('FIM DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS'));
    print_out('----------------------------------------------------------------'); 
  exception when others then
    xxfr_pck_logger.log_error('Exceção não tratada :','XXFR_WSH_PCK_INT_ENTREGA.CONFIRMAR_ENTREGA');
    raise;
  END;
  -- Id_Integracao_Detalhe
  procedure cancelar_entrega (
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  ) IS
    l_trip_id       number;
    l_nm_percurso   varchar2(30);
    l_retorno       varchar2(3000);
  begin
    ok := true;
    g_rec_retorno := null;
    g_escopo := 'CANCELAR_ENTREGA_'||p_id_integracao_detalhe;
    print_out('----------------------------------------------------------------');
    print_out('INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS')||' - Vr:'||g_versao);
    print_out('----------------------------------------------------------------');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CANCELAR_ENTREGA:ID:'||p_id_integracao_detalhe);
    -- Resgatando o Id do percurso.
    begin
      select distinct 
        nm_percurso, 
        id_integracao_detalhe, 
        usuario, 
        cd_referencia_origem, 
        tp_referencia_origem, 
        nvl(cd_unidade_operacional,'UO_FRISIA'), 
        ie_manter_percurso
      into 
        l_nm_percurso,
        g_id_integracao_detalhe, 
        g_user_name, 
        g_cd_referencia_origem, 
        g_tp_referencia_origem, 
        g_organization_code, 
        g_ie_manter_percurso
      from xxfr_wsh_vw_int_canc_entrega
      where id_integracao_detalhe = p_id_integracao_detalhe
      ;
      --
      if (g_ie_manter_percurso is null) then
        l_retorno := 'O Indicativo de [MANTER PERCURSO  SIM/NAO] é OBRIGATORIO para esse processo';
        print_out('  '||l_retorno);
        ok:=false;
      end if;
      --
      if (ok) then
        select distinct trip_id into l_trip_id 
        from xxfr_wsh_vw_inf_da_ordem_venda 
        where 1=1
          and nome_percurso = l_nm_percurso
          and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
        ;
      end if;
      --
    exception 
      when no_data_found then
        l_retorno := 'Integração não Encontrada:'||p_id_integracao_detalhe;
        print_out('  '||l_retorno);
        ok:=false;
      when others then
        l_retorno := 'Erro não previsto:'||sqlerrm;
        print_out('  '||l_retorno);
        ok:=false;
    end;
    --
    if (ok) then 
      cancelar_entrega(l_trip_id, isCommit, l_retorno);
      if (l_retorno <> 'S') then
        ok:= false;
      end if;
    end if;

    g_rec_retorno."registros"(1)."tipoCabecalho"         := 'PERCURSO';
    g_rec_retorno."registros"(1)."codigoCabecalho"       := l_nm_percurso;
    g_rec_retorno."registros"(1)."tipoReferenciaOrigem"  := g_tp_referencia_origem;
    g_rec_retorno."registros"(1)."codigoReferenciaOrigem":= g_cd_referencia_origem;

    if (ok) then 
      g_rec_retorno."retornoProcessamento"         := 'SUCESSO';
      g_rec_retorno."mensagemRetornoProcessamento" := ''; 
      xxfr_pck_interface_integracao.sucesso (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    else
      g_rec_retorno."retornoProcessamento"                 := 'ERRO';
      g_rec_retorno."mensagemRetornoProcessamento"         := l_retorno; 
      g_rec_retorno."registros"(1)."retornoProcessamento"  := 'ERRO';
      if (isCommit) then ROLLBACK TO CANCELAR_ENTREGA; end if;
      xxfr_pck_interface_integracao.erro (
        p_id_integracao_detalhe   => p_id_integracao_detalhe,
        p_ds_dados_retorno        => g_rec_retorno
      );
    end if;
    retornar_clob( 
      p_id_integracao_detalhe => p_id_integracao_detalhe, 
      p_retorno               => p_retorno
    );
    print_out('----------------------------------------------------------------');
    print_out('FIM DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS'));
    print_out('----------------------------------------------------------------');
  exception when others then
    xxfr_pck_logger.log_error('Exceção não tratada :','XXFR_WSH_PCK_INT_ENTREGA.CANCELAR_ENTREGA');
    raise;
  END;
  
  -- Trip_Id
  procedure cancelar_entrega(
    p_trip_id IN  NUMBER,
    p_commit  in  boolean,
    x_retorno out varchar2
  ) is
  
    l_nm_percurso         varchar2(20);
    l_trip_id             number;
    l_retorno             varchar2(3000);
    l_move_order_line_id  number;
    --l_return_status       varchar2(3000);
    l_msg_count           number :=0;
    l_msg_data            varchar2(3000);
    n                     number :=0;

    cursor c1 is
      select distinct trip_id, nome_percurso, delivery_id, nome_entrega, released_status
      from xxfr_wsh_vw_inf_da_ordem_venda 
      where 1=1
        and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
        and trip_id = p_trip_id
    ;

    cursor c2 is
      select distinct trip_id, nome_percurso, delivery_id, nome_entrega, move_order_line_id, released_status 
      from xxfr_wsh_vw_inf_da_ordem_venda 
      where 1=1
        and trip_id = p_trip_id
        and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
    ;

  begin
    ok:=true;
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CANCELAR_ENTREGA:TRIP-ID:'||p_trip_id);
    isCommit := p_commit;
    --
    if (isCommit) then SAVEPOINT CANCELAR_ENTREGA; end if;
    -- Inicia ambiente Oracle
    begin
      if (g_user_name is null) then
        xxfr_pck_variaveis_ambiente.inicializar('ONT','UO_FRISIA');
        print_out('USER_ID     :'||fnd_profile.value('USER_ID'));
      else
        print_out('USUARIO JSON:'||g_user_name);
        xxfr_pck_variaveis_ambiente.inicializar('ONT', nvl(g_organization_code,'UO_FRISIA'), g_user_name);
      end if;
    exception when others then
      l_retorno := 'Não foi possivel inicializar o ambiente Oracle:'||sqlerrm;
      print_out(l_retorno);
      ok:=false;
    end;
    --
    if (not isCommit) then 
      g_ie_manter_percurso := nvl(g_ie_manter_percurso,'NAO');
    end if;
    
    if (g_ie_manter_percurso is null) then
      l_retorno := 'O Indicativo de [MANTER PERCURSO  SIM/NAO] é OBRIGATORIO para esse processo';
      print_out('  '||l_retorno);
      ok:=false;
    else
      n := 0;
      -- INV Backorder
      if (ok) then --and g_ie_manter_percurso = 'SIM') then
        print_out('Processo MoveOrder Backorder');   
        n:=0;
        for r1 in c2 loop
          n := n + 1;
          if (r1.released_status <> 'S') then
            continue;
          end if;
          print_out('');
          l_nm_percurso := r1.nome_percurso;
          if (n = 1) then
            print_out('NOME PERCURSO:'||r1.nome_percurso);
          end if;
          print_out(n||') DELIVERY_ID:'||r1.delivery_id);
          print_out('Chamando INV_MO_BACKORDER_PVT.BACKORDER...');
          print_out('Move_Order_line_Id:'||r1.move_order_line_id);
          XXFR_WSH_PCK_BACKORDER.BACKORDER(
          --INV_MO_BACKORDER_PVT.BACKORDER(
            p_line_id       => r1.move_order_line_id,
            x_return_status => l_retorno,
            x_msg_count     => l_msg_count,
            x_msg_data      => l_msg_data
          );
          l_msg_count := nvl(l_msg_count,0);
          print_out('Retorno :'||l_retorno);
          print_out('Qtd Msg :'||l_msg_count);
          if (l_retorno <> 'S') then
            ok:=false;
            for i in 1 .. l_msg_count loop
              l_msg_data := fnd_msg_pub.get( 
                p_msg_index => i, 
                p_encoded   => 'F'
              );
              print_out( i|| ') '|| l_msg_data);
            end loop;
            l_retorno := l_msg_data;
            exit;
          end if;
        end loop;
      end if;
      -- OM Backorder
      if (ok and g_ie_manter_percurso = 'NAO') then
        print_out('Processo OrderMamanger Backorder');
        for r1 in c1 loop
          n := n + 1;
          print_out('');
          print_out('Delivery:'||r1.delivery_id);
          processar_om_backorder(
            p_delivery_id => r1.delivery_id,
            p_trip_id     => r1.trip_id,
            x_retorno     => l_retorno
          );
          print_out('Retorno :'||l_retorno);
          if (ok = false) then
            exit;
          end if;
        end loop;
      end if;
      --
      if n = 0 then
        l_retorno := 'Nenhum entrega encontrada para o percurso informado !';
        print_out(l_retorno);
        ok := false;
      end if;
    end if;
    x_retorno := l_retorno;
  end;

  Procedure criar_atualizar_percurso(
		p_percurso                IN  tp_percurso,
    p_trip_id                 IN  NUMBER,
    p_action_code             IN  VARCHAR2,
    x_trip_id                 OUT NUMBER,
		x_retorno                 OUT VARCHAR2  
  ) is

    l_trip_rec        wsh_trips_pub.trip_pub_rec_type;
    l_trip_id         number;
    l_retorno         varchar2(3000);

  begin
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CRIAR_ATUALIZAR_PERCURSO('||p_action_code||')');
    l_trip_rec.trip_id    := p_trip_id;

    if (p_percurso.ie_ajusta_distribuicao <> 'SIM') then
      l_trip_rec.name               := nvl(p_percurso.nm_percurso                   ,p_trip_id);
      l_trip_rec.operator           := nvl(p_percurso.transp.nm_motorista           ,l_trip_rec.operator);
      l_trip_rec.attribute1         := nvl(p_percurso.transp.nu_cpf_motorista       ,l_trip_rec.attribute1);
      l_trip_rec.attribute5         := nvl(p_percurso.cd_lacre_veiculo              ,l_trip_rec.attribute5);
      l_trip_rec.vehicle_num_prefix := 'PR';
      l_trip_rec.vehicle_number     := nvl(p_percurso.veiculo.nu_placa1,l_trip_rec.vehicle_number);
    end if;
    --
    l_trip_rec.attribute2         := p_percurso.qt_peso_bruto;
    l_trip_rec.attribute3         := p_percurso.qt_peso_tara;
    l_trip_rec.attribute4         :=(p_percurso.qt_peso_bruto - p_percurso.qt_peso_tara - p_percurso.qt_peso_embalagem_complementar );
    l_trip_rec.attribute6         := p_percurso.qt_peso_embalagem_complementar;
    --
    xxfr_wsh_pck_transacoes.criar_atualizar_percurso(
      p_trip_rec    => l_trip_rec,
      p_action_code => p_action_code,
      x_trip_id     => l_trip_id,
      x_retorno     => l_retorno
    );
    x_trip_id := l_trip_id;
    x_retorno := l_retorno;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.CRIAR_ATUALIZAR_PERCURSO('||p_action_code||')');
  end;
  --
  Procedure criar_atualizar_entrega(
    p_percurso                IN  tp_percurso,
    p_dist                    IN  tp_dist,
    p_delivery_id             IN  NUMBER,
    p_action_code             IN  VARCHAR2,
    --
    x_delivery_id             OUT NUMBER,
    x_delivery_name           OUT VARCHAR2,   
		x_retorno                 OUT VARCHAR2
  ) is

    l_delivery_rec_typ    WSH_DELIVERIES_PUB.DELIVERY_PUB_REC_TYPE;
    l_delivery_id         number;
    l_delivery_name       varchar2(30);
    l_retorno             varchar2(1000);
    l_return_status       VARCHAR2(1000);

    --
    l_org_id                  number;
    l_organization_id         number;
    l_organization_code       varchar2(20);
    l_customer_id             number;
    l_num_cliente             varchar2(20);
    l_curr_code               varchar2(20);
    l_freight_terms_code      varchar2(20);
    l_fob_code                varchar2(20);
    l_ship_from_location_id   varchar2(20);
    l_ship_to_location_id     varchar2(20);
    l_ship_method_code        varchar2(50);
    l_carrier_id              number;
    l_gross_weight            number;
    l_service_level           varchar2(20);
    l_mode_of_transport       varchar2(20);
    l_weight_uom_code         varchar2(20);
    l_volume_uom_code         varchar2(20);
    --
    l_order_number            varchar2(20);
    --
  begin
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CRIAR_ATUALIZAR_ENTREGA');
    ok :=true;
    --
    l_delivery_rec_typ := NULL;
    l_delivery_rec_typ.delivery_id         := p_delivery_id;
    l_delivery_rec_typ.attribute_category  := fnd_profile.VALUE('ORG_ID');

    l_delivery_rec_typ.global_attribute5   := p_percurso.veiculo.cd_reg_antt;
    l_delivery_rec_typ.global_attribute8   := p_percurso.veiculo.cd_reg_antt_cavalo; 
    --
    l_delivery_rec_typ.global_attribute6   := p_percurso.veiculo.nu_placa1;
    l_delivery_rec_typ.global_attribute12  := p_percurso.veiculo.nu_placa2;
    l_delivery_rec_typ.global_attribute14  := p_percurso.veiculo.nu_placa3;
    l_delivery_rec_typ.global_attribute16  := p_percurso.veiculo.nu_placa4;
    l_delivery_rec_typ.global_attribute18  := p_percurso.veiculo.nu_placa5;
    l_delivery_rec_typ.global_attribute9   := p_percurso.cd_lacre_veiculo;  

    --
    if (p_dist.cd_cliente is not null) then
      l_delivery_rec_typ.attribute1               := p_dist.cd_controle_entrega_cliente;
      l_delivery_rec_typ.additional_shipment_info := p_dist.ds_dados_adicionais;
      l_organization_id := null;
      begin
        SELECT distinct
          oh.transactional_curr_code,
          wdd.freight_terms_code,
          wdd.fob_code,
          wdd.customer_id,
          wdd.organization_id,
          wdd.ship_from_location_id,
          wdd.ship_to_location_id,
          wdd.ship_method_code,
          wdd.carrier_id,
          wdd.service_level,
          wdd.mode_of_transport,
          wdd.weight_uom_code,
          wdd.volume_uom_code
        INTO l_curr_code, l_freight_terms_code, l_fob_code, l_customer_id, l_organization_id, l_ship_from_location_id, l_ship_to_location_id, l_ship_method_code, l_carrier_id, l_service_level, l_mode_of_transport, l_weight_uom_code, l_volume_uom_code
        from
          oe_order_headers_all           oh,
          wsh_delivery_details           wdd,
          XXFR_WSH_VW_INF_DA_ORDEM_VENDA ov
        where 1=1
          and oh.header_id              = ov.oe_header
          and oh.header_id              = wdd.source_header_id
          and wdd.delivery_detail_id    = ov.delivery_detail_id
          and ov.flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
          and ov.line_released_status_name not in ('Entregue')

          --and ov.numero_ordem           = '108'
          --and ov.tipo_ordem             = '011_VENDA'
          --and ov.linha                  = '1' 
          --and ov.envio                  = '1'
          --
          and ov.numero_ordem           = p_dist.linhas(1).nu_ordem_venda
          and ov.tipo_ordem             = p_dist.linhas(1).cd_tipo_ordem_venda
          and ov.linha                  = p_dist.linhas(1).nu_linha_ordem_venda
          and ov.envio                  = nvl(p_dist.linhas(1).nu_envio_linha_ordem_venda, ov.envio)
        ;
        l_delivery_rec_typ.organization_id := l_organization_id;
      exception
        when no_data_found then
          l_retorno := 'Entrega : '||p_dist.linhas(1).nu_ordem_venda||'-'||p_dist.linhas(1).nu_linha_ordem_venda||' / '||p_dist.linhas(1).cd_tipo_ordem_venda;
          l_retorno := l_retorno ||', não encontrada !';
          print_out(l_retorno);
          ok := false;
        when too_many_rows then
          l_retorno := 'Entrega : '||p_dist.linhas(1).nu_ordem_venda||'-'||p_dist.linhas(1).nu_linha_ordem_venda||' / '||p_dist.linhas(1).cd_tipo_ordem_venda;
          l_retorno := l_retorno ||', retorna mais de um local de coleta/destino';
          print_out(l_retorno);
          ok := false;
        when others then
          l_retorno := 'Entrega : '||p_dist.linhas(1).nu_ordem_venda||'-'||p_dist.linhas(1).nu_linha_ordem_venda||' / '||p_dist.linhas(1).cd_tipo_ordem_venda;
          l_retorno := l_retorno ||' - Erro não esperado:'||sqlerrm;
          print_out(l_retorno);
          ok := false;
      end;
    end if;
    --
    if (ok and p_action_code = 'CREATE') then
      l_delivery_rec_typ.name := p_percurso.nm_percurso || '.' || xxfr_fnc_sequencia_unica('NOME_PERCURSO');

      l_delivery_rec_typ.service_level                 := l_service_level;
      l_delivery_rec_typ.mode_of_transport             := l_mode_of_transport;
      --l_delivery_rec_typ.organization_id               := l_organization_id;
      l_delivery_rec_typ.initial_pickup_location_id    := l_ship_from_location_id;
      l_delivery_rec_typ.ultimate_dropoff_location_id  := l_ship_to_location_id;
      l_delivery_rec_typ.customer_id                   := l_customer_id;
      --l_delivery_rec_typ.intmed_ship_to_location_id := l_ship_to_location_id;
      l_delivery_rec_typ.ship_method_code              := l_ship_method_code;  
      l_delivery_rec_typ.freight_terms_code            := l_freight_terms_code;
      l_delivery_rec_typ.fob_code                      := l_fob_code;
      --l_delivery_rec_typ.currency_code                 := l_curr_code;
      l_delivery_rec_typ.ultimate_dropoff_date         := SYSDATE;
      l_delivery_rec_typ.initial_pickup_date           := SYSDATE;
      --l_delivery_rec_typ.waybill                       := 'Test Delivery';
      l_delivery_rec_typ.carrier_id                    := l_carrier_id;
      --
      l_delivery_rec_typ.gross_weight                  := p_percurso.qt_peso_bruto;
      l_delivery_rec_typ.net_weight                    := (p_percurso.qt_peso_bruto - p_percurso.qt_peso_tara);
      --l_delivery_rec_typ.weight_uom_code               := l_weight_uom_code;
      --l_delivery_rec_typ.volume_uom_code               := l_volume_uom_code;
    end if; 

    if (ok AND p_action_code = 'UPDATE') then
      --Informações do Transportador 
      print_out('');
      begin
        if (p_percurso.cd_metodo_entrega is not null) then 
          print_out('  OBTENDO INF. DA TRANSPOSTADORA');
          print_out('  Metodo Entrega:'||p_percurso.cd_metodo_entrega);
          select CARRIER_ID, SHIP_METHOD_CODE, SERVICE_LEVEL, MODE_OF_TRANSPORT 
          into 
            l_delivery_rec_typ.carrier_id, 
            l_delivery_rec_typ.SHIP_METHOD_CODE,
            l_delivery_rec_typ.SERVICE_LEVEL, 
            l_delivery_rec_typ.MODE_OF_TRANSPORT 
          from WSH_CARRIER_SERVICES_V
          where 1=1
            AND SHIP_METHOD_CODE = p_percurso.cd_metodo_entrega
          ;
        else
          print_out('  OBTENDO INF. DA TRANSPOSTADORA');
          print_out('  Cnpj Transportador:'||p_percurso.transp.cd_transportador);
          select distinct --oft.freight_code,
            wsc.CARRIER_ID, 
            null, 
            null, 
            wcs.MODE_OF_TRANSPORT
            --,(oft.global_attribute5||oft.global_attribute6||oft.global_attribute7) cnpj
            --,oft.description nome
            --,oft.freight_code 
            --,wcs.attribute3  modal
          into l_delivery_rec_typ.carrier_id, l_delivery_rec_typ.SHIP_METHOD_CODE, l_delivery_rec_typ.SERVICE_LEVEL, l_delivery_rec_typ.MODE_OF_TRANSPORT 
          from 
            org_freight_tl            oft,
            wsh_carriers              wsc,
            wsh_carrier_services      wcs
          where 1=1
            and language              = userenv('LANG') 
            and wsc.carrier_id        = wcs.carrier_id
            and wsc.freight_code      = oft.freight_code
            and (
              oft.freight_code = p_percurso.transp.cd_transportador
              --or oft.global_attribute5||oft.global_attribute6||oft.global_attribute7 = lpad(p_percurso.transp.cd_transportador,15,'0')
            )
          ;  
        end if;
        print_out('  Retorno:S');
        print_out('');
      exception
        when NO_DATA_FOUND then
          l_retorno := 'TRANSPOSTADORA NÃO ENCONTRADA ';
          ok :=false;
          print_out('  '||l_retorno);
        when TOO_MANY_ROWS then
          l_retorno := 'MAIS DE UMA TRANSPORTADORA ENCONTRADA';
          ok :=false;
          print_out('  '||l_retorno);
      end;
      --
      if (ok) then
        print_out('  WSH_UTIL_VALIDATE.VALIDATE_DELIVERY_NAME');
        wsh_util_validate.validate_delivery_name(
          p_delivery_id   => l_delivery_rec_typ.delivery_id,
          p_delivery_name => nvl(p_dist.nm_distribuicao,l_delivery_rec_typ.delivery_id),
          x_return_status => l_retorno
        );
        l_delivery_rec_typ.name := nvl(p_dist.nm_distribuicao,l_delivery_rec_typ.delivery_id);
        print_out('  Retorno :'||l_retorno);
        if (l_retorno <> 'S') then
          ok := false;
        end if;
      end if;
    end if;

    if (ok) then
      XXFR_WSH_PCK_TRANSACOES.criar_atualizar_entrega(
        p_delivery_rec_typ => l_delivery_rec_typ,
        p_action_code      => p_action_code,
        x_delivery_id      => l_delivery_id,
        x_delivery_name    => l_delivery_name,
        x_retorno          => l_retorno
      );
    end if;
    x_retorno       := l_retorno;
    x_delivery_name := l_delivery_name;
    x_delivery_id   := nvl(l_delivery_id,p_delivery_id);
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.CRIAR_ATUALIZAR_ENTREGA');
    print_out('');
  end;

  procedure dividir_linha_entrega(
    p_linhas                 IN tp_linhas,
    x_new_delivery_detail_id OUT NUMBER, 
		x_retorno                OUT VARCHAR2
  ) IS

  l_new_delivery_detail_id number;
  l_retorno                varchar2(500);
  --

  BEGIN
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.DIVIDIR_LINHA_ENTREGA');
    
    XXFR_WSH_PCK_TRANSACOES.split_linha_delivery(
      p_delivery_detail_id      => p_linhas.delivery_detail_id, 
      p_quantidade              => p_linhas.qt_quantidade,
      x_new_delivery_detail_id  => l_new_delivery_detail_id, 
      x_retorno                 => l_retorno
    );

    x_new_delivery_detail_id := l_new_delivery_detail_id;
    x_retorno := l_retorno;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.DIVIDIR_LINHA_ENTREGA');
    print_out('');
  END;

  procedure associar_entrega_percurso(
    p_delivery_id_tbl  in WSH_UTIL_CORE.id_tab_type,
    p_trip_id          in number,
    x_retorno          out varchar2
  ) is

    l_retorno      varchar2(3000);

  begin
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.ASSOCIAR_PERCURSO_ENTREGA');
    for i in 1 .. p_delivery_id_tbl.count loop
      xxfr_wsh_pck_transacoes.associar_percurso_entrega(
        p_delivery_id_tbl(i),
        p_trip_id,
        l_retorno
      );
      if (l_retorno <> 'S') then
        exit;
      end if;
    end loop;
    x_retorno := l_retorno;
  end;

  procedure associar_linha_entrega(
    p_delivery_id         in number,
    p_delivery_name       in varchar2,
    p_delivery_detail_tab in wsh_delivery_details_pub.id_tab_type,
    x_delivery_id         out number,
    x_retorno             out varchar2
  ) is
  
    l_retorno               varchar2(3000);
    l_delivery_id           number;
    l_new_delivery_id       number;
    l_delivery_detail_tab   wsh_delivery_details_pub.id_tab_type;
    
  begin
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.ASSOCIAR_LINHA_ENTREGA');
    l_new_delivery_id := p_delivery_id;
    for i in 1 .. p_delivery_detail_tab.count loop
      print_out('  '||i||') Entrega:'||p_delivery_id||' -> Linha:'||p_delivery_detail_tab(i));
      --Verifica se já existe uma delivery para a linha
      begin
        select distinct DELIVERY_ID into l_delivery_id
        from wsh_delivery_assignments 
        where DELIVERY_DETAIL_ID = p_delivery_detail_tab(i);
      exception 
        when no_data_found then 
          ok:=true;
        when others then 
          ok:=false;
          x_retorno := 'Erro de checagem das linhas:'||sqlerrm;
          return;
      end;
      if (l_delivery_id is not null) then
        print_out(' ');
        print_out('  A linha:'||p_delivery_detail_tab(i)||' já esta associada a entrega:'||l_delivery_id);
        print_out('  O processo ira desatribuir a linha desta entrega !');
        --
        processar_conteudo_firme(
          p_delivery_id => l_delivery_id,
          p_action_code => 'UNPLAN',
          x_retorno     => l_retorno
        );
        print_out(' ');
        l_delivery_detail_tab(1) := p_delivery_detail_tab(i);
        --Desassocia a Linha da Delivery
        xxfr_wsh_pck_transacoes.associar_linha_entrega(
          p_delivery_id         => l_delivery_id,
          p_delivery_detail_tab => l_delivery_detail_tab,
          p_action              => 'UNASSIGN',
          x_retorno             => l_retorno 
        );
        if (l_retorno <> 'S') then 
          ok:= false;
          x_retorno     := l_retorno;
        end if;
        print_out(' ');
      end if;
    end loop;
    if (ok) then    
      XXFR_WSH_PCK_TRANSACOES.associar_linha_entrega(
        p_delivery_id         => l_new_delivery_id,
        p_delivery_detail_tab => p_delivery_detail_tab,
        p_action              => 'ASSIGN',
        x_retorno             => l_retorno 
      );
      x_retorno     := l_retorno;
      if (l_retorno <> 'S') then 
        ok:= false;
      else
        x_delivery_id := l_new_delivery_id;
      end if;
    end if;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.ASSOCIAR_LINHA_ENTREGA');
  end;

  function check_hold(p_delivery_id in number) return number is
    cursor c1 is
      select
        'HEADER' tipo,
        --oha.org_id, oha.order_hold_id, oha.hold_source_id, 
        oha.header_id, oha.line_id, v.delivery_id,
        ohs.hold_id, ohs.hold_comment,
        ohd.name, ohd.type_code, ohd.description,
        oha.released_flag, oha.hold_release_id, ohr.release_reason_code, ohr.release_comment
      from 
        xxfr_wsh_vw_inf_da_ordem_venda v,
        oe_order_holds_all  oha,
        oe_hold_sources_all ohs,
        oe_hold_definitions ohd,
        oe_hold_releases    ohr
      where 1=1
        and oha.org_id         = ohs.org_id
        --
        and (oha.header_id = v.oe_header and oha.line_id   is null)
        --
        and oha.hold_source_id = ohs.hold_source_id
        and oha.hold_source_id = ohr.hold_source_id (+)
        and ohs.hold_id        = ohd.hold_id
        and oha.released_flag  = 'N'
        and v.delivery_id      = p_delivery_id
        and (
          oha.header_id = v.oe_header or oha.line_id = v.oe_line
        )
      union
      select
        'LINE' tipo,
        --oha.org_id, oha.order_hold_id, oha.hold_source_id, 
        oha.header_id, oha.line_id, v.delivery_id,
        ohs.hold_id, ohs.hold_comment,
        ohd.name, ohd.type_code, ohd.description,
        oha.released_flag, oha.hold_release_id, ohr.release_reason_code, ohr.release_comment
      from 
        xxfr_wsh_vw_inf_da_ordem_venda v,
        oe_order_holds_all  oha,
        oe_hold_sources_all ohs,
        oe_hold_definitions ohd,
        oe_hold_releases    ohr
      where 1=1
        and oha.org_id         = ohs.org_id
        --
        and (oha.header_id = v.oe_header and oha.line_id = v.oe_line)
        --
        and oha.hold_source_id = ohs.hold_source_id
        and oha.hold_source_id = ohr.hold_source_id (+)
        and ohs.hold_id        = ohd.hold_id
        and oha.released_flag  = 'N'
        and v.delivery_id      = p_delivery_id
        and (
          oha.header_id = v.oe_header or oha.line_id = v.oe_line
        )
    ;
    
    qtd_hold number;
  
  begin
    qtd_hold := 0;
    for r1 in c1 loop
      qtd_hold := qtd_hold+1;
      print_out('Em retencao :'||r1.hold_comment);
      g_rec_retorno."registros"(1)."linhas"(1)."mensagens"(qtd_hold)."tipoMensagem" := 'ERRO';
      g_rec_retorno."registros"(1)."linhas"(1)."mensagens"(qtd_hold)."mensagem"     := r1.hold_comment;
    end loop;
    return qtd_hold;
  end;

  procedure proc_delivery_pick_release(
    p_delivery_id    in number,
    p_trip_id        in number,
    p_r              in number,
    p_tipo_liberacao in varchar2,
    x_msg_retorno    out varchar2,
    x_retorno        out varchar2
  ) is

    l_retorno     varchar2(3000);
    l_msg_retorno varchar2(3000);
    qtd_hold      number;

  begin
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.PROC_DELIVERY_PICK_RELEASE');
    
    qtd_hold := check_hold(p_delivery_id);
    
    if (qtd_hold = 0) then
      XXFR_WSH_PCK_TRANSACOES.PICK_RELEASE(
        p_delivery_id    => p_delivery_id,
        p_trip_id        => p_trip_id,
        p_tipo_liberacao => p_tipo_liberacao,
        x_msg_retorno    => l_msg_retorno,
        x_retorno        => l_retorno
      );
      x_retorno := l_retorno;
    else
      x_retorno := 'HOLD';
      ok:=false;
    end if;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.PROC_DELIVERY_PICK_RELEASE');
    print_out(' ');
  end;

  procedure proc_trip_pick_release (
    p_trip_id        in number,
    p_action         in varchar2,
    x_msg_retorno    out varchar2,
    x_retorno        out varchar2
  ) is
  begin
    print_out('XXFR_WSH_PCK_INT_ENTREGA.PROC_TRIP_PICK_RELEASE');
    print_out('  Chamando XXFR_WSH_PCK_TRANSACOES.TRIP_PICK_RELEASE...');
    null;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.PROC_TRIP_PICK_RELEASE');
  end;

  procedure reverter_mov_inventario(
    p_delivery_id in number ,
    x_retorno     out varchar2
  ) is

    cursor c0 is
      select distinct trip_id, delivery_id, move_order_line_id, subinventory, lot_number, locator_id, transaction_id
      from xxfr_wsh_vw_inf_da_ordem_venda
      where 1=1
        and delivery_id = p_delivery_id
    ;

    cursor c1(p_move_order_line_id in number) is
      select 
        mmt.move_order_line_id,
        mso.segment1, 
        mso.segment2, 
        mmt.inventory_item_id,
        mmt.source_code,
        mmt.transaction_type_id, 
        mtt.transaction_type_name,
        mtt.transaction_action_id, 
        mtt.transaction_source_type_id,
        mmt.distribution_account_id,
        abs(mmt.transaction_quantity)  transaction_quantity,
        mmt.transaction_uom,
        --  
        min(
          case when mmt.transaction_quantity > 0 then mmt.organization_id else null end
        ) from_organization_id,
        min(
          case when mmt.transaction_quantity < 0 then mmt.organization_id else null end
        ) to_organization_id,
        --    
        min(
          case when mmt.transaction_quantity > 0 then transaction_id else null end
        ) from_transaction_id,
        min(
          case when mmt.transaction_quantity < 0 then transaction_id else null end
        ) to_transaction_id,
        --
        min(
          case when mmt.transaction_quantity > 0 then mmt.subinventory_code else null end
        ) from_subinventory_code,
        min(
          case when mmt.transaction_quantity < 0 then mmt.subinventory_code else null end
        ) to_subinventory_code,
        --    
        min(
          case when mmt.transaction_quantity > 0 then mil.concatenated_segments else null end
        ) from_subinventory,
        min(
          case when mmt.transaction_quantity < 0 then mil.concatenated_segments else null end
        ) to_subinventory,
        --  
        min(
          case when mmt.transaction_quantity > 0 then mmt.locator_id else null end
        ) from_locator_id,
        min(
          case when mmt.transaction_quantity < 0 then mmt.locator_id else null end
        ) to_locator_id
        --mmt.transaction_quantity 
      from 
        mtl_material_transactions       mmt,
        mtl_transaction_types           mtt,
        mtl_txn_source_types            mtst,
        mtl_sales_orders                mso,
      
        --mtl_onhand_quantities_detail    moqd,
        mtl_item_locations_kfv          mil
      where 1=1
        and mso.sales_order_id              = mmt.transaction_source_id
        and mmt.transaction_type_id         = mtt.transaction_type_id
        and mmt.transaction_source_type_id  = mtt.transaction_source_type_id
        and mmt.transaction_source_type_id  = mtst.transaction_source_type_id
        --
        --and moqd.ORGANIZATION_ID      = mmt.organization_id
        --and moqd.INVENTORY_ITEM_ID    = mmt.inventory_item_id
        --and moqd.LOCATOR_ID           = mmt.locator_id
        --
        and mmt.locator_id              = mil.inventory_location_id(+)
        --
        and mmt.move_order_line_id = p_move_order_line_id
      group by
        mmt.move_order_line_id,
        mso.segment1, 
        mso.segment2, 
        mmt.inventory_item_id,
        mmt.source_code,
        mmt.transaction_source_id, 
        mmt.transaction_type_id, 
        mtt.transaction_type_name,
        mtt.transaction_action_id, mtt.transaction_source_type_id,
        mmt.distribution_account_id,
        abs(mmt.transaction_quantity),
        mmt.transaction_uom
    ;

    cursor c2(i_transaction_id in number) is
      select transaction_id, lot_number, transaction_quantity, expiration_date
      from mtl_transaction_lot_val_v
      where transaction_id = i_transaction_id
    ;


    i number :=0;
    j number :=0;

    l_delivery_id         number; 
    l_move_order_line_id  number;
    l_subinventory        varchar2(50); 
    l_lot_number          varchar2(50); 
    l_locator_id          number; 
    l_transaction_id      number;

    l_retorno varchar2(3000);

    l_transacoes     xxfr_inv_pck_transacoes.tp_transacoes_tbl;
    l_lotes          xxfr_inv_pck_transacoes.tp_lotes_tbl;
    l_transacoes_ret xxfr_inv_pck_transacoes.tp_retorno_transacoes_tbl;

    l_mensagens      xxfr_pck_interface_integracao.tab_retorno_mensagens;
    l_rec_mensagem   xxfr_pck_interface_integracao.rec_retorno_mensagem;

    antes_EXP number;
    depois_EXP number;

    antes_MPG number;
    depois_MPG number;

  begin
    ok := true;
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.REVERTER_MOV_INVENTARIO');
    print_out('  delivery_id       :'||p_delivery_id);
    --
    begin
      for r0 in c0 loop
        l_delivery_id         := r0.delivery_id;
        l_move_order_line_id  := r0.move_order_line_id;
        l_subinventory        := r0.subinventory;
        l_lot_number          := r0.lot_number;
        l_locator_id          := r0.locator_id;
        l_transaction_id      := r0.transaction_id;
        print_out('');
        print_out('  move_order_line_id:'||l_move_order_line_id);
        for r1 in c1(l_move_order_line_id) loop
          -- QTD ANTES
          SELECT
            sum(case when subinventory_code = R1.FROM_SUBINVENTORY_CODE 
              then PRIMARY_TRANSACTION_QUANTITY
              else 0
            end) "FROM",
            sum(case when subinventory_code = R1.TO_SUBINVENTORY_CODE 
              then PRIMARY_TRANSACTION_QUANTITY
              else 0
            end) "TO"
            into antes_exp, antes_mpg
          from apps.mtl_onhand_quantities_detail
          where 1 = 1 
            and organization_id   = R1.FROM_ORGANIZATION_ID
            and inventory_item_id = R1.INVENTORY_ITEM_ID
            and subinventory_code in (R1.FROM_SUBINVENTORY_CODE, R1.TO_SUBINVENTORY_CODE)
          ;
          --
          i := i + 1;
          l_transacoes(i).source_code             := 'Subinventory Transfer CJU'; --r1.source_code;
          l_transacoes(i).inventory_item_id       := r1.inventory_item_id;
          l_transacoes(i).transaction_uom         := r1.transaction_uom;
          --l_transacoes(i).transaction_source_id   := r1.transaction_source_id;
          l_transacoes(i).organization_id         := r1.from_organization_id;
          l_transacoes(i).transaction_quantity    := r1.transaction_quantity;
          l_transacoes(i).transaction_type_id     := 2; --r1.transaction_type_id;
          l_transacoes(i).transaction_date        := sysdate; --r1.transaction_date;
          l_transacoes(i).transaction_reference   := null; --r1.transaction_reference;
          --
          l_transacoes(i).subinventory_code       := r1.from_subinventory_code;
          l_transacoes(i).locator_id              := r1.from_locator_id;
          --
          l_transacoes(i).to_subinventory_code    := r1.to_subinventory_code;
          l_transacoes(i).to_locator_id           := r1.to_locator_id;
          l_transacoes(i).distribution_account_id := r1.distribution_account_id;
  
          j:=0;
          for r2 in c2(r1.to_transaction_id) loop
            j := j + 1;
            l_lotes(j).lot_number      := r2.lot_number;
            l_lotes(j).quantity        := r2.transaction_quantity;
            l_lotes(j).expiration_date := r2.expiration_date;
          end loop; 
          l_transacoes(i).lotes := l_lotes;
          --
          print_out('  Chamando... XXFR_INV_PCK_TRANSACOES.TRANSACOES'); 
          xxfr_inv_pck_transacoes.transacoes(
            p_transacoes     => l_transacoes, 
            p_retorno        => l_transacoes_ret
          );
          print_out('QTD:'||l_transacoes_ret.count);
          for i in 1 .. l_transacoes_ret.count loop
            if (l_transacoes_ret(i).status = 'S') then
              print_out('  Retorno:'||l_transacoes_ret(i).status);
              -- QTD DEPOIS
              SELECT
                sum(case when subinventory_code = R1.FROM_SUBINVENTORY_CODE 
                  then PRIMARY_TRANSACTION_QUANTITY
                  else 0
                end) "FROM",
                sum(case when subinventory_code = R1.TO_SUBINVENTORY_CODE 
                  then PRIMARY_TRANSACTION_QUANTITY
                  else 0
                end) "TO"
                into depois_exp, depois_mpg
              from apps.mtl_onhand_quantities_detail
              where 1 = 1 
                and organization_id = R1.FROM_ORGANIZATION_ID
                and inventory_item_id = R1.INVENTORY_ITEM_ID
                and subinventory_code in (R1.FROM_SUBINVENTORY_CODE, R1.TO_SUBINVENTORY_CODE)
              ;
              --
              print_out('  +----------------------------------------------+');
              print_out('  |            '||R1.FROM_SUBINVENTORY||'    '||R1.TO_SUBINVENTORY||'    |');
              print_out('  +----------------------------------------------+');
              print_out('  |QTD ANTES :'||TO_CHAR(antes_exp,'999G999G999G999')||' | '||TO_CHAR(antes_mpg,'999G999G999G999')||'|');
              print_out('  |QTD DEPOIS:'||TO_CHAR(depois_exp,'999G999G999G999')||' | '||TO_CHAR(depois_mpg,'999G999G999G999')||'|');
              print_out('  +----------------------------------------------+');
            else
              print_out('  Retorno       :'||l_transacoes_ret(i).status);
              print_out('  Transaction Id:'||l_transacoes_ret(i).transaction_id);
              l_retorno := l_transacoes_ret(i).status;
              l_mensagens := l_transacoes_ret(i).mensagens;
              for k in 1 .. l_mensagens.count loop
                print_out('  Tipo Msg:'||l_mensagens(k)."tipoMensagem");
                print_out('  Msg     :'||l_mensagens(k)."mensagem");
              end loop;
              ok := false;
              exit;
            end if;
          end loop;
          if (ok = false) then
            exit;
          end if;
        end loop;
      end loop;
      print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.REVERTER_MOV_INVENTARIO');
      x_retorno := l_retorno;
    exception
      when too_many_rows then
        x_retorno := 'ERRO: Mais de 1 percurso encontrado para a delivery '|| p_delivery_id;
        print_out(x_retorno);
        ok := false;
      when no_data_found then
        x_retorno:='ERRO: Nenhum percurso encontrado para a delivery '|| p_delivery_id;
        print_out(x_retorno);
        ok := false;
      when others then
        x_retorno:='ERRO:'||sqlerrm;
        print_out(x_retorno);
        ok := false;
    end;
  end;

  procedure processar_om_backorder(
    p_delivery_id in number,
    p_trip_id     in number,
    x_retorno     out varchar2
  ) is

    l_retorno varchar2(3000);

    l_numero_ordem   varchar2(20);
    l_linha          varchar2(20);
    l_tipo_ordem     varchar2(20);
    l_qtd            number;
    i                number;
    l_action_param   wsh_trips_pub.Action_Param_Rectype;
  
  begin
    ok := true;
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_OM_BACKORDER');
    print_out('  DELIVERY_ID :'||p_delivery_id);
    --
    if (ok) then
      reverter_mov_inventario(
        p_delivery_id => p_delivery_id,
        x_retorno     => x_retorno
      );
      if (x_retorno <> 'S') then
        ok := false;
      end if;
    end if;
    --
    i:=0;
    xxfr_wsh_pck_transacoes.confirma_entrega(
      p_delivery_id  => p_delivery_id,
      p_action_code  => 'BACKORDER',
      x_retorno      => x_retorno
    );
    if (x_retorno = 'E') then
      ok := false;
    else
      l_action_param.action_code           := 'DELETE';
      xxfr_wsh_pck_transacoes.confirma_percurso(
        p_trip_id        => p_trip_id,
        p_action_param   => l_action_param,
        x_rec_retorno    => g_rec_retorno,
        x_retorno        => x_retorno
      );
      if (x_retorno <> 'S') then
        ok := false;
      end if;
    end if;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_OM_BACKORDER');
  end;

  procedure processar_trip_confirm(
    p_trip_id        in number ,
    p_action_code    in varchar2,
    x_retorno        out varchar2
  ) is

    l_retorno        varchar2(3000);
    l_action_param   wsh_trips_pub.Action_Param_Rectype;

    l_rec_retorno    xxfr_pck_interface_integracao.rec_retorno_integracao;

  begin
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_TRIP_CONFIRM('||p_action_code||')');
    l_action_param.action_code           := p_action_code;
    --l_action_param.organization_id       := ;
    --l_action_param.report_set_name       := ;
    --l_action_param.report_set_id         := ;
    --l_action_param.override_flag         := ;
    l_action_param.actual_date           := sysdate;
    l_action_param.action_flag           := 'S';
    l_action_param.autointransit_flag    := 'Y';
    l_action_param.autoclose_flag        := 'Y';
    l_action_param.stage_del_flag        := 'Y';
    l_action_param.ship_method           := null;
    l_action_param.bill_of_lading_flag   := 'Y';
    l_action_param.defer_interface_flag  := 'N';
    l_action_param.actual_departure_date := sysdate;
    begin
      --print_out('  METODO DE ENVIO INDICADO:'|| nvl(l_action_param.ship_method,'NULL') );
      --
      XXFR_WSH_PCK_TRANSACOES.confirma_percurso(
        p_trip_id       => p_trip_id,
        p_action_param  => l_action_param,
        x_rec_retorno   => l_rec_retorno,
        x_retorno       => l_retorno
      );
      
      if (l_retorno <> 'S') then
        g_rec_retorno."registros"(1)."mensagens" := l_rec_retorno."registros"(1)."mensagens";
        --
        g_rec_retorno."registros"(1)."tipoCabecalho"               := 'CONFIRMA PERCURSO';
        g_rec_retorno."registros"(1)."codigoCabecalho"             := p_trip_id;
        g_rec_retorno."registros"(1)."tipoReferenciaOrigem"        := g_tp_referencia_origem;
        g_rec_retorno."registros"(1)."codigoReferenciaOrigem"      := g_cd_referencia_origem;
        g_rec_retorno."registros"(1)."retornoProcessamento"        := 'ERRO';
        --
        ok := false;
      end if;
      --x_rec_retorno   := l_rec_retorno;
      x_retorno       := l_retorno;
    exception
      when no_data_found then
        x_retorno := 'Não encontrado Método de envio para o Percurso informado';
        print_out('  '||x_retorno);
        ok := false;
      when too_many_rows then
        x_retorno := 'Encontrado mais de 1 Método de envio para o Percurso informado';
        print_out('  Encontrado mais de 1 Método de envio para o Percurso informado');
        ok := false;
      when others then
        x_retorno := 'Procurando Método de envio:'||sqlerrm;
        print_out('  Procurando Método de envio:'||sqlerrm);
        ok := false;
    end;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_TRIP_CONFIRM('||p_action_code||')');
  end;  

  procedure processar_conteudo_firme(
    p_delivery_id in number ,
    p_action_code in varchar2,
    x_retorno     out varchar2
  ) is

    l_delivery_id    number;
    l_conteudo_firme varchar2(10);
    l_trip_name      varchar2(100);
    l_retorno        varchar2(4000);

  begin
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_CONTEUDO_FIRME('||p_action_code||')');
    l_delivery_id := p_delivery_id;
    xxfr_wsh_pck_transacoes.atribuir_conteudo_firme(
      p_delivery_id  => l_delivery_id,
      p_action_code  => p_action_code,
      x_retorno      => l_retorno
    );
    x_retorno := l_retorno;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_CONTEUDO_FIRME('||p_action_code||')');
  end;

  procedure criar_reserva(
    p_linhas                 IN tp_linhas,
    p_operacao               IN varchar2,
    x_lot_number             out varchar2,
    x_retorno                out varchar2
  ) is

    l_date_received        date;
    l_oe_header_id         number;
    l_oe_line_id           number;
    l_delivery_detail_id   number;
    l_inventory_item_id    number;
    l_organization_id      number;

    l_retorno              varchar2(3000);
    l_cd_endereco_estoque  varchar2(30);

  begin
    print_out('');
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CRIAR_RESERVA'); 
    g_reserva_rec_type := null;
    -- RESGATANDO INFOMAÇÕES DA ORDEM
    begin 
      print_out('  Delivery_Detail_id:'||p_linhas.delivery_detail_id);
      --
      select distinct oe_header, oe_line, delivery_detail_id, inventory_item_id, organization_id
      into l_oe_header_id, l_oe_line_id, l_delivery_detail_id, l_inventory_item_id, l_organization_id
      from xxfr_wsh_vw_inf_da_ordem_venda
      where 1=1
        and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
        --and numero_ordem       = p_linhas.nu_ordem_venda
        --and tipo_ordem         = p_linhas.cd_tipo_ordem_venda
        --and linha              = p_linhas.nu_linha_ordem_venda
        --and envio              = nvl(p_linhas.nu_envio_linha_ordem_venda,envio)
        and delivery_detail_id = p_linhas.delivery_detail_id
      ;
    exception 
      when others then
        ok:=false;
        x_retorno := 'Falha ao resgatar informações da Ordem:'||sqlerrm;
        print_out('  '||x_retorno);
        return;
    end;
    --
    print_out('  OE Header Id      :'||l_oe_header_id);
    print_out('  OE Line Id        :'||l_oe_line_id);
    print_out('  Organization_Id   :'||l_organization_id);
    print_out('  Inventory_Item_Id :'||l_inventory_item_id); 
    print_out('  Endereço Estoque  :'||p_linhas.cd_endereco_estoque);
    --
    l_retorno := informacoes_lote(
      p_organization_id     => l_organization_id,
      p_inventory_item_id   => l_inventory_item_id,
      p_cd_endereco_estoque => p_linhas.cd_endereco_estoque
    );
    --
    if (ok) then
      print_out('  Qtd p/ Reserva    :'||p_linhas.qt_quantidade);
      x_lot_number := g_lot_number;
      --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
      xxfr_wsh_pck_transacoes.criar_reserva(
        p_oe_header_id      => l_oe_header_id,
        p_oe_line_id        => l_oe_line_id,
        p_action            => 'CREATE',
        p_qtd               => p_linhas.qt_quantidade,
        --
        p_subinventory_code => g_from_subinventory_code,
        p_locator_id        => g_from_locator_id,
        p_lot_number        => g_lot_number,
        --
        x_retorno           => l_retorno
      );
      x_retorno := l_retorno;
    end if;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.CRIAR_RESERVA');
  end;

  procedure processar_percurso_firme (
    p_trip_id     in number,
    p_action_code in varchar2,
    x_retorno     out varchar2
  ) is
  
    l_percurso_firme  varchar2(10);
  
  begin
    print_out('XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_PERCURSO_FIRME');
    select distinct percurso_firme 
    into l_percurso_firme 
    from xxfr_wsh_vw_inf_da_ordem_venda 
    where trip_id = p_trip_id;
    --
    if (l_percurso_firme = 'Y' and p_action_code = 'PLAN') or (l_percurso_firme = 'N' and p_action_code = 'UNPLAN') then
      x_retorno := 'S';
    else
      processar_trip_confirm(
        p_trip_id     => p_trip_id,
        p_action_code => p_action_code,
        x_retorno     => x_retorno
      );
    end if;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.PROCESSAR_PERCURSO_FIRME');
  end;

  procedure controle_split(
    p_linha                   in xxfr_wsh_pck_int_entrega.tp_linhas,
    x_retorno                 out varchar2
  ) is
   
    cursor c1 is
      select 
        trip_id, 
        nome_percurso, 
        numero_ordem, 
        linha, 
        envio, 
        tipo_ordem, 
        delivery_id, 
        delivery_detail_id, 
        split_from_delivery_detail_id, 
        qtd_original, 
        qtd,
        released_status, 
        pick_status_name
      from xxfr_wsh_vw_inf_da_ordem_venda
      where 1=1
        and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
        and released_status <> 'C'
        --and status_percurso is null
        and numero_ordem     = p_linha.nu_ordem_venda
        and tipo_ordem       = p_linha.cd_tipo_ordem_venda
        and linha            = p_linha.nu_linha_ordem_venda
        and envio            = nvl(p_linha.nu_envio_linha_ordem_venda, envio)
      order by released_status, qtd
    ;
  
    l_linha                  xxfr_wsh_pck_int_entrega.tp_linhas;
    l_new_delivery_detail_id number;
  
    l_retorno               varchar2(3000);
    isSplit                 boolean := true;
    p_qtd                   number  := 10;
    i                       number  := 0;
    --
    l_item_id               number;
    l_changed_attributes    wsh_delivery_details_pub.changedAttributeTabType;
    l_organization_id       number;
    l_to_unidade            varchar2(20);
    --
  
    function check_saldo(
      oe_numero  in varchar2,
      oe_linha   in varchar2,
      oe_tipo    in varchar2,
      qtd_pedido in number
    ) return boolean is
    
      livre     integer := 0;
      alocado   integer := 0;
      backorder integer := 0;
    
    begin
      print_out('Checagem de saldo da Ordem de Venda...');
      select 
        sum(
          case 
            when released_status IN ('R','S') OR trip_id is null 
              then nvl(qtd,0)
              else 0
          end
        ) QTD_LIVRE,
        sum(
          case 
            when released_status ='Y' and trip_id is not null 
              then nvl(qtd,0)
              else 0
          end
        ) QTD_ALOCADA,
        sum(
          case 
            when released_status='B' and trip_id is not null 
              then nvl(qtd,0)
              else 0
          end
        ) QTD_ALOCADA_EM_BACKORDER
      INTO livre, alocado, backorder
      from xxfr_wsh_vw_inf_da_ordem_venda
      where 1=1
        and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
        and released_status <> 'C'
        --and status_percurso is null
        --OE:668-1.1 / 124_VENDA
        and numero_ordem     = p_linha.nu_ordem_venda
        and tipo_ordem       = p_linha.cd_tipo_ordem_venda
        and linha            = p_linha.nu_linha_ordem_venda
        and envio            = nvl(p_linha.nu_envio_linha_ordem_venda, envio)
      ;
      --
      --livre := livre - g_qtd_alocada_pedido;
      print_out('  Qtd Pedido               :'||qtd_pedido);
      print_out('  Qtd Livre                :'||livre);
      print_out('  Qtd em Backorder         :'||backorder);
      print_out('  Qtd Alocada              :'||alocado);
      print_out('  Qtd Alocada nesta entrega:'||g_qtd_alocada_pedido);
      --
      livre := livre + backorder;
      
      if (livre >= qtd_pedido) then
        print_out('Checagem Ok...');
        print_out('');
        return true;
      end if;
      
      if (livre = 0) then
        x_retorno := 'Não há saldo disponivel para a ordem:'||p_linha.nu_ordem_venda;
      elsif (livre < qtd_pedido) then
        x_retorno := 'Não há saldo suficiente disponivel para a ordem:'||p_linha.nu_ordem_venda;
      end if;
      
      if (alocado > 0) then
        x_retorno := x_retorno || '. Atenção:Existe uma entrega pendente para esse pedido !';
      end if;
      
      print_out('  '||x_retorno);
      return false;
    end;
    
  begin
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CONTROLE_SPLIT');
    l_linha := p_linha;
    p_qtd := l_linha.qt_quantidade;
    print_out('  OE:'||p_linha.nu_ordem_venda||'-'||p_linha.nu_linha_ordem_venda||'.'|| p_linha.nu_envio_linha_ordem_venda ||' / '||  p_linha.cd_tipo_ordem_venda);
    print_out('  Qtd a ser entregue:'||l_linha.qt_quantidade);
    print_out('  Unidade de medida :'||l_linha.cd_un_medida);
    -- Conversao da Unidade de Medida.
    begin
      select distinct unidade, inventory_item_id 
      into   l_to_unidade, l_item_id
      from xxfr_wsh_vw_inf_da_ordem_venda
      where 1=1
        and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
        and released_status <> 'C'
        and numero_ordem     = p_linha.nu_ordem_venda
        and tipo_ordem       = p_linha.cd_tipo_ordem_venda
        and linha            = p_linha.nu_linha_ordem_venda
        and envio            = nvl(p_linha.nu_envio_linha_ordem_venda, envio)
      ;
        
      p_qtd := inv_convert.inv_um_convert(
        item_id       => l_item_id,
        precision     => null,
        from_quantity => l_linha.qt_quantidade,
        from_unit     => l_linha.cd_un_medida,
        --
        to_unit       => l_to_unidade,
        from_name     => null,
        to_name       => null
      );
      print_out('  Convertendo para a unidade da linha do pedido...');
      print_out('  Qtd a ser entregue:'||p_qtd);
      print_out('  Unidade de medida :'||l_to_unidade);      
      print_out(' ');
    end;
    
    i := g_delivery_detail_id_tbl.count;
    
    ok := check_saldo(
      oe_numero  => p_linha.nu_ordem_venda,
      oe_linha   => p_linha.cd_tipo_ordem_venda,
      oe_tipo    => p_linha.nu_linha_ordem_venda,
      qtd_pedido => p_qtd
    );
    if (ok) then
      g_qtd_alocada_pedido := g_qtd_alocada_pedido + p_qtd;
      for r1 in c1 loop
        i := i+1;
        print_out('  Saldo disponivel para linha ('||r1.delivery_detail_id||') -> '||r1.qtd);
        if (r1.qtd > p_qtd) then
          print_out('  - Split parcial da linha ('||r1.delivery_detail_id||') Qtd:'||p_qtd);
          l_linha.qt_quantidade := p_qtd;
          l_linha.delivery_detail_id := r1.delivery_detail_id;
          p_qtd := 0;
          isSplit := true;
        elsif (r1.qtd < p_qtd) then
          print_out('  - Consumo total da linha ('||r1.delivery_detail_id||') Qtd:'||r1.qtd);
          l_linha.qt_quantidade := r1.qtd;
          p_qtd := p_qtd - r1.qtd;
          isSplit := false;
        elsif (r1.qtd = p_qtd) then
          print_out('  - Consumo total da linha('||r1.delivery_detail_id||') de '||r1.qtd);  
          p_qtd := 0;
          isSplit := false;
        end if;
        --
        if (isSplit) then
          xxfr_wsh_pck_int_entrega.dividir_linha_entrega(
            p_linhas                 => l_linha, 
            x_new_delivery_detail_id => l_new_delivery_detail_id,
            x_retorno                => l_retorno
          );
          if (l_retorno <> 'S') then
            ok:=false;
            x_retorno := l_retorno;
            return;
          end if;
          g_delivery_detail_id_tbl(i) := l_new_delivery_detail_id;
        else
          g_delivery_detail_id_tbl(i) := r1.delivery_detail_id;
          x_retorno := 'S';
        end if;

        if (x_retorno = 'S') then
          begin
            print_out('  Gravando percentual de gordura...');
            select organization_id into l_organization_id
            from wsh_delivery_details 
            where DELIVERY_DETAIL_ID = g_delivery_detail_id_tbl(i);
            
            print_out('    Delivery_Detail_Id:'||g_delivery_detail_id_tbl(i));
            print_out('    Percentual Gordura:'||l_linha.pr_percentual_gordura);
            print_out('    Organization_id   :'||l_organization_id);
            
            l_changed_attributes(1).attribute_category := l_organization_id;
            l_changed_attributes(1).attribute1         := l_linha.pr_percentual_gordura;
            l_changed_attributes(1).delivery_detail_id := g_delivery_detail_id_tbl(i);
            --
            XXFR_WSH_PCK_TRANSACOES.atualiza_delivey_detail (
              p_changed_attributes => l_changed_attributes,
              x_retorno            => l_retorno
            );
          exception when others then
            l_retorno := sqlerrm;
            ok:=false;
          end;
        end if;

        print_out('  Saldo :'||p_qtd);
        if (p_qtd = 0) then 
          exit;        
        end if;
      end loop;
      if (p_qtd <> 0) then 
        ok:=false;
        x_retorno := 'Saldo insuficiente para o pedido de entrega:'||p_linha.nu_ordem_venda||'-'||p_linha.nu_linha_ordem_venda||'.'||p_linha.nu_envio_linha_ordem_venda||'/'||p_linha.cd_tipo_ordem_venda;
        print_out('  '||x_retorno);
      end if;
    end if;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.CONTROLE_SPLIT');
    print_out('');
  end;

  procedure criar_mov_subinventario(
    p_trip_id               in number,
    p_cd_endereco_estoque   in varchar2,
    p_qtd                   in number,
    x_retorno               out varchar2
  ) is
  
    l_line_released_status_name varchar2(100);
    l_move_order_line_id        number;
    l_inventory_item_id         number;
    l_organization_id           number;
    --
    l_cd_endereco_estoque       varchar2(30);
    l_retorno                   varchar2(3000);
    --
    l_qtd                       number;
    l_primary_quantity          number;
    l_qtd_total_ordem           number;
    l_num_linhas                number;
    i                           number;
    
    cursor c0 is
      select delivery_id, count(*) num_linhas, sum(qtd) total 
      from xxfr_wsh_vw_inf_da_ordem_venda
      where trip_id = p_trip_id
      group by delivery_id
      order by sum(qtd)
    ;
    
    cursor c1(p_delivery_id in number) is
      select distinct move_order_line_id, inventory_item_id, organization_id, TRANSACTION_ID, qtd
      from xxfr_wsh_vw_inf_da_ordem_venda
      where delivery_id = p_delivery_id
      order by qtd
    ;

  begin
    print_out('XXFR_WSH_PCK_INT_ENTREGA.CRIAR_MOV_SUBINVENTARIO');    
    l_qtd := p_qtd;
    i:=0;
    for r0 in c0 loop
      for r1 in c1(r0.delivery_id) loop
        i:=i+1;
        print_out('');
        print_out('  Move_Order_Line_id('||i||'):'||r1.MOVE_ORDER_LINE_ID);
        print_out('  Cod Endereço Esqtoque:'||p_cd_endereco_estoque);

        l_retorno := informacoes_lote(
          p_organization_id     => r1.organization_id,
          p_inventory_item_id   => r1.inventory_item_id,
          p_cd_endereco_estoque => p_cd_endereco_estoque
        );

        print_out('');
        if (ok) then
          begin
            if(l_qtd_total_ordem < p_qtd and i = l_num_linhas) then
              l_primary_quantity := l_qtd;
            else     
              if    (r1.qtd < l_qtd) then
                l_primary_quantity := r1.qtd;
                l_qtd := l_qtd - r1.qtd;
              elsif (r1.qtd > l_qtd) then
                l_primary_quantity := l_qtd;
                l_qtd := 0;
              elsif (r1.qtd = l_qtd) then
                l_primary_quantity := l_qtd;
                l_qtd := 0;
              end if;
            end if;
            print_out('  Chamando XXFR_WSH_PCK_TRANSACOES.CRIAR_MOV_SUBINVENTARIO...');
            XXFR_WSH_PCK_TRANSACOES.CRIAR_MOV_SUBINVENTARIO(
              p_move_order_line_id     => r1.move_order_line_id,
              p_line_number            => null,
              p_from_locator           => g_from_locator_id,
              p_to_locator             => g_to_locator_id,
              p_lot_number             => g_lot_number,
              p_inventory_item_id      => r1.inventory_item_id,
              p_organization_id        => r1.organization_id,
              --
              p_from_subinventory_code => g_from_subinventory_code,
              p_to_subinventory_code   => g_to_subinventory_code,
              --
              p_primary_quantity       => l_primary_quantity,
              p_trx_quantity           => l_primary_quantity,
              x_retorno                => l_retorno
            );
            if (l_retorno <> 'S') then
              ok:=false;
              x_retorno := l_retorno;
              return;
            end if;
          exception 
            when others then
              print_out('  Deu Ruim aqui:'||sqlerrm);
              ok:=false;
          end;
        end if;
      end loop;    
    end loop;
    x_retorno := l_retorno;
    print_out('FIM XXFR_WSH_PCK_INT_ENTREGA.CRIAR_MOV_SUBINVENTARIO');
  end;

  function informacoes_lote(
    p_organization_id     in number,
    p_inventory_item_id   in number,
    p_cd_endereco_estoque in varchar2
  ) return varchar2 is
  
    l_retorno varchar2(3000);
  
  begin
    --LOCATOR_ID SUBINVENTORY_CODE
    begin
      select distinct inventory_location_id,  subinventory_code 
      into g_from_locator_id, g_from_subinventory_code
      from mtl_item_locations
      where 1=1
        and organization_id = p_organization_id
        and SEGMENT1||'.'||SEGMENT2||'.'||SEGMENT3||'.'||SEGMENT4 = p_cd_endereco_estoque;
    exception
      when others then
        ok := false;
        l_retorno := 'Erro ao recuperar LOCATOR_ID, SUBINVENTORY_CODE:'||sqlerrm;
        print_out('  '||l_retorno);
        return l_retorno;
    end;
    --   
    print_out('  Sub Inventário    :'||g_from_subinventory_code);
    print_out('  Locator Id        :'||g_from_locator_id);
    --LOT_NUMBER
    begin        
      select a.lot_number 
      into g_lot_number
      from (
        select moqd.lot_number 
        from 
          mtl_onhand_quantities_detail moqd,
          mtl_system_items_b           msib    
        where 1=1
          --and moqd.inventory_item_id    = '13621'
          --and moqd.locator_id           = '33722'
          --and moqd.organization_id      = '103'
          --
          and moqd.inventory_item_id    = p_inventory_item_id
          and moqd.locator_id           = g_from_locator_id
          and moqd.organization_id      = p_organization_id
          and msib.inventory_item_id    = moqd.inventory_item_id
          and msib.organization_id      = moqd.organization_id 
        order by trunc(moqd.primary_transaction_quantity) desc --trunc(moqd.date_received)
      ) a where rownum = 1;
      print_out('  Lote Number       :'||g_lot_number);
      if (g_lot_number is null) then
        l_retorno := 'Lote não encontrado para o Produto ID:('||p_inventory_item_id||') e End Estoque:('||p_cd_endereco_estoque||') informados';
        print_out('  '||l_retorno);
        ok:=false;
        return l_retorno;
      end if;
    exception
      when no_data_found then
        l_retorno :=  'Lote não encontrado para o Produto ID:('||p_inventory_item_id||') e End Estoque:('||p_cd_endereco_estoque||') informado';
        print_out('  '||l_retorno);
        ok:=false;
        return l_retorno;
      when others then
        l_retorno :=  'Lote não encontrado para o Produto ID:('||p_inventory_item_id||') e End Estoque:('||p_cd_endereco_estoque||') informados:'||sqlerrm;
        print_out('  '||l_retorno);
        ok:=false;
        return l_retorno;
    end;
    --
    print_out('  Lote              :'||g_lot_number);
    --INVETORY_LOCATION_ID, SUBINVETORY_CODE
    begin
      select distinct inventory_location_id,  subinventory_code 
      into g_to_locator_id, g_to_subinventory_code
      from mtl_item_locations
      where 1=1
        and organization_id = p_organization_id
        and segment1||'.'||segment2||'.'||segment3||'.'||segment4 = 'EXP.00.000.00';
    exception
      when others then
        l_retorno :=  'Erro ao recuperar INVETORY_LOCATION_ID, SUBINVETORY_CODE :'||sqlerrm;
        print_out('  '||l_retorno);
        ok:=false;
        return l_retorno;
    end;
    --
    return 'S';
  end;

END XXFR_WSH_PCK_INT_ENTREGA;