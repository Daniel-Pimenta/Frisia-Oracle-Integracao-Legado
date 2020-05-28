create or replace PACKAGE BODY XXFR_WSH_PCK_TRANSACOES as
-- +==========================================================================+
-- | Package para criar e manter itens do OM para integrações e processos custom.     
-- |                                                                 
-- |                                                                 
-- | CRIADO POR              DATA                  REF                                          
-- |   DANIEL PIMENTA        13/10/2019              
-- |                                                                 
-- | ALTERADO POR            DATA                  REF                        
-- |   [Nome]                [dd/mm/yyyy]          [ticket#]     
-- +==========================================================================+

  ok        boolean := true;
  g_escopo  varchar2(40) := 'XXFR_WSH_PCK_TRANSACOES';

  procedure print_out(msg varchar2) is
  begin
    --DBMS_OUTPUT.PUT_LINE (msg);
    xxfr_wsh_pck_int_entrega.print_out(msg);
    /*
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
    */
  end;

  procedure initialize(p_aplicacao in varchar2) is
    l_aplicacao varchar2(10);
  begin
    if (p_aplicacao is null) then
      l_aplicacao := 'ONT';
    else
      l_aplicacao := p_aplicacao;
    end if;
    if (fnd_profile.value('USER_ID') is null) then
      xxfr_pck_variaveis_ambiente.inicializar(l_aplicacao, 'UO_FRISIA'); 
    end if;
  end;

  procedure limpa_msg is
  begin
    fnd_msg_pub.initialize;
  END;

  procedure criar_atualizar_percurso(
    p_trip_rec    IN WSH_TRIPS_PUB.Trip_Pub_Rec_Type,
    p_action_code IN VARCHAR2,
    x_trip_id     OUT number,
    x_retorno     OUT VARCHAR2
  ) IS       
  
    l_trip_info             WSH_TRIPS_PUB.trip_pub_rec_type;
    l_trip_name             VARCHAR2(200);
    l_return_status         VARCHAR2(200);
    l_msg_count             NUMBER; 
    l_msg_data              VARCHAR2(2000);  
    l_trip_id               NUMBER; 
    --
  BEGIN
    print_out('  XXFR_WSH_PCK_TRANSACOES.CRIAR_ATUALIZAR_PERCURSO');
    initialize(null);
    --
    l_trip_info  := p_trip_rec;
    print_out('  Chamando... WSH_TRIPS_PUB.CREATE_UPDATE_TRIP');
    print_out('    ACAO:'||p_action_code);
    print_out('    Id  :'||l_trip_info.trip_id);
    print_out('    Name:'||l_trip_info.name);
    
    limpa_msg;
    
    WSH_TRIPS_PUB.Create_Update_Trip( 
      p_api_version_number => 1.0,
      p_init_msg_list      => FND_API.g_false,
      x_return_status      => l_return_status,
      x_msg_count          => l_msg_count,
      x_msg_data           => l_msg_data,
      p_action_code        => p_action_code,
      p_trip_info          => l_trip_info,
      p_trip_name          => l_trip_info.name,
      x_trip_id            => l_trip_id,
      x_trip_name          => l_trip_name
    );   
    print_out('  Saida:'||l_return_status);
    if (l_return_status = 'S') then
      print_out('    Id  :'||l_trip_id);
      print_out('    Name:'||l_trip_name);
      x_retorno := 'S';
      x_trip_id := l_trip_id;
    end if;
    --
    for i in 1 .. l_msg_count loop
      l_msg_data := fnd_msg_pub.get( 
        p_msg_index => i, 
        p_encoded   => 'F'
      );
      print_out('  '|| i|| ') '|| l_msg_data);
    end loop;
    
    if (l_msg_count > 0) then
      x_retorno := l_msg_data;
    end if;
    
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.CRIAR_ATUALIZAR_PERCURSO');
  END;

  procedure criar_distribuicao_percurso(
    p_delivery_det_id_tbl   IN  WSH_UTIL_CORE.id_tab_type,
    x_trip_id               OUT NUMBER,
    x_delivery_id_rows_tbl  OUT WSH_UTIL_CORE.id_tab_type,
    x_retorno               OUT VARCHAR2
  ) IS

    l_delivery_id_rows_tbl  WSH_UTIL_CORE.id_tab_type;
    --
    l_return_status         varchar2(50);
    l_msg_data              varchar2(500);
    l_msg_count             number;
    l_trip_id               number;
    l_trip_name             varchar2(20);
    i                       NUMBER;
    --

  BEGIN
    print_out('  XXFR_WSH_PCK_TRANSACOES.CRIAR_DISTRIBUICAO_PERCURSO');
    initialize(null);
    print_out('  Chamando... WSH_DELIVERY_DETAILS_PUB.AUTOCREATE_DEL_TRIP');
    wsh_delivery_details_pub.autocreate_del_trip (
      p_api_version_number  => 1.0 ,
      p_init_msg_list       => fnd_api.g_false,
      p_commit              => fnd_api.g_false,
      x_return_status       => l_return_status,
      x_msg_count           => l_msg_count,
      x_msg_data            => l_msg_data,
      --
      p_line_rows           => p_delivery_det_id_tbl,  --lista com os Delivery_detail_id
      --
      x_del_rows            => l_delivery_id_rows_tbl,
      x_trip_id             => l_trip_id,
      x_trip_name           => l_trip_name 
    );
    if (l_return_status = 'S') then
      --
      print_out('    PERCURSO CRIADO (Trip_id)   :'||l_trip_id);
      for i in 1 .. l_delivery_id_rows_tbl.count loop  
        print_out('    DISTRIBUIÇÃO (Delivery_ID)  :'||l_delivery_id_rows_tbl(i));
      end loop;
      for i in 1 .. p_delivery_det_id_tbl.count loop  
        print_out('    DETALHE (Delivery_Detail_Id):'||p_delivery_det_id_tbl (i));
      end loop;
      x_trip_id              := l_trip_id;
      x_delivery_id_rows_tbl := l_delivery_id_rows_tbl;
      x_retorno              := 'S';
    else
      for i in 1 .. l_msg_count loop
        l_msg_data := fnd_msg_pub.get( 
          p_msg_index => i, 
          p_encoded   => 'T'
        );
        print_out( i|| ') '|| l_msg_data);
      end loop;
      x_retorno := l_msg_data;
    end if;
    print_out('  Saida:'||l_return_status);
  END;

  procedure associar_percurso_entrega(
    p_delivery_id  in number,
    p_trip_id      in number,
    x_retorno      out varchar2
  ) is
  
    l_return_status  varchar2(10);
    l_msg_count      number;
    l_msg_data       varchar2(3000);
    --
    l_trip_id        number;
    l_trip_name      varchar2(20);
    
    i                number;
    
  begin
    initialize(null);
    print_out('  XXFR_WSH_PCK_TRANSACOES.ASSOCIAR_PERCURSO_ENTREGA');
    print_out('  Chamando... WSH_DELIVERIES_PUB.DELIVERY_ACTION');
    print_out('    Delivery_Id:'||p_delivery_id);
    print_out('    Trip_Id    :'||p_trip_id);
    limpa_msg;
    l_msg_count :=0;
    wsh_deliveries_pub.delivery_action ( 
      p_api_version_number       => 1.0,
      p_init_msg_list            => fnd_api.g_false,
      p_action_code              => 'ASSIGN-TRIP',
      p_delivery_id              => p_delivery_id,
      p_delivery_name            => null,
      p_asg_trip_id              => p_trip_id,
      p_asg_trip_name            => null,
      x_trip_id                  => l_trip_id,
      x_trip_name                => l_trip_name,
      x_return_status            => l_return_status,
      x_msg_count                => l_msg_count,
      x_msg_data                 => l_msg_data
    );
    print_out('  Retorno:'||l_return_status);
    print_out('    Trip_id  :'||l_trip_id);
    print_out('    Trip_name:'||l_trip_name);
    if (l_return_status = 'S') then
      null;
    else
      i:=0;
      for i in 1 .. l_msg_count loop
        l_msg_data := fnd_msg_pub.get( 
          p_msg_index => i, 
          p_encoded   => 'T'
        );
        print_out( i|| ') '|| l_msg_data);
      end loop;
      x_retorno := l_msg_data;
    end if;
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.ASSOCIAR_PERCURSO_ENTREGA');
  end;

  procedure associar_linha_entrega(
    p_delivery_id         in number,
    p_delivery_detail_tab in wsh_delivery_details_pub.id_tab_type,
    p_action              in varchar2,
    x_retorno             out varchar2
  ) is
    l_return_status  varchar2(10);
    l_msg_count      number;
    l_msg_data       varchar2(3000);
    l_msg_summary    varchar2(3000);
    l_msg_details    varchar2(3000);
  begin
    initialize(null);
    print_out('  XXFR_WSH_PCK_TRANSACOES.ASSOCIAR_LINHA_ENTREGA');
    print_out('  Chamando... WSH_DELIVERY_DETAILS_PUB.DETAIL_TO_DELIVERY');
    print_out('    Delivery_Id     :'||p_delivery_id);
    print_out('    Action          :'||p_action);
    print_out('    Qtd de linhas   :'||p_delivery_detail_tab.count);
    
    for i in 1 .. p_delivery_detail_tab.count loop
      print_out('    Delivery_detail :'||p_delivery_detail_tab(i));
    end loop;
    --
    limpa_msg;
    --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
    WSH_DELIVERY_DETAILS_PUB.detail_to_delivery(
      -- Standard parameters
      p_api_version        => 1.0,
      p_init_msg_list      => FND_API.G_FALSE,
      p_commit             => FND_API.G_FALSE,
      p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
      -- program specific parameters
      p_TabOfDelDets       => p_delivery_detail_tab,
      p_action             => p_action,
      p_delivery_id        => p_delivery_id,
      p_delivery_name      => null,
      --
      x_return_status      => l_return_status,
      x_msg_count          => l_msg_count,
      x_msg_data           => l_msg_data
    );
    print_out('  Saida:'||l_return_status);
    if (l_msg_count = 0) then
      x_retorno := l_return_status;
    else
      x_retorno := '';
      for i in 1 .. l_msg_count loop
        l_msg_data := fnd_msg_pub.get( 
          p_msg_index => i, 
          p_encoded   => 'F'
        );
        print_out( '  '||i|| ') '|| l_msg_data);
        x_retorno := x_retorno || '  '||i|| ') '|| l_msg_data || chr(13);
      end loop;
    end if;
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.ASSOCIAR_LINHA_ENTREGA');
  end;

  procedure split_linha_delivery(
    p_delivery_detail_id    in number, 
    p_quantidade             in number, 
    x_new_delivery_detail_id out number, 
    x_retorno                out varchar2
  ) is
  
    l_return_status       Varchar2(20);
    l_msg_count           Number;
    l_msg_data            Varchar2(400);
    l_from_detail_id      Number;
    l_new_detail_id       Number;
    l_split_quantity      Number;
    l_split_quantity2     Number;
    
    l_msg_summary       VARCHAR2(3000);
    l_msg_details       VARCHAR2(3000);
  
  BEGIN
    print_out('  XXFR_WSH_PCK_TRANSACOES.SPLIT_LINHA_DELIVERY');
    --
    initialize(null);
    limpa_msg;
    --
    l_from_detail_id := p_delivery_detail_id;
    l_split_quantity := p_quantidade;
    --
    print_out('  CHAMANDO... WSH_DELIVERY_DETAILS_PUB.SPLIT_LINE');
    
    WSH_DELIVERY_DETAILS_PUB.SPLIT_LINE(  
      p_api_version        => '1',
      p_init_msg_list      => FND_API.G_FALSE,
      p_commit             => FND_API.G_FALSE,
      p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
      x_return_status      => l_return_status,
      x_msg_count          => l_msg_count,
      x_msg_data           => l_msg_data,
      p_from_detail_id     => l_from_detail_id,
      x_new_detail_id      => l_new_detail_id,
      x_split_quantity     => l_split_quantity,
      x_split_quantity2    => l_split_quantity2
    );
    --
    if (l_return_status = 'S') then
      print_out('    From Delivery_detail_id:'||l_from_detail_id);
      print_out('    New Delivery_detail_id :'||l_new_detail_id);
      print_out('    Qtd 1                  :'||l_split_quantity);
      print_out('    Qtd 2                  :'||l_split_quantity2);
      x_new_delivery_detail_id := l_new_detail_id;
      x_retorno := 'S';
    else
      print_out('    From Delivery_detail_id:'||l_from_detail_id);
      WSH_UTIL_CORE.get_messages('Y', l_msg_summary, l_msg_details, l_msg_count);
      if l_msg_count > 1 then
        l_msg_data := l_msg_summary || l_msg_details;
        print_out('    Message : '||l_msg_data);
      else
        l_msg_data := l_msg_summary;
        print_out('    Message : '||l_msg_data);
      end if;
      x_retorno := l_msg_data;
    end if;
    print_out('    Saida:'||l_return_status);
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.SPLIT_LINHA_DELIVERY');
  END;

  procedure criar_atualizar_entrega(
    p_delivery_rec_typ in  wsh_deliveries_pub.delivery_pub_rec_type,
    p_action_code      in  varchar2,
    x_delivery_id      out number,
    x_delivery_name    out varchar2,
    x_retorno          out varchar2
  ) is
  
    --l_changed_attributes   WSH_DELIVERY_DETAILS_PUB.ChangedAttributeTabType;
  
    l_delivery_rec_typ     WSH_DELIVERIES_PUB.DELIVERY_PUB_REC_TYPE;
    l_delivery_name        VARCHAR2(100);
    l_return_status        varchar2(10);
    l_msg_count            number;
    l_msg_data             varchar2(2000);
    l_delivery_id          NUMBER;  
    
    l_msg_details          VARCHAR2(3000);
    l_msg_summary          VARCHAR2(3000);
  
  begin
    print_out('  XXFR_WSH_PCK_TRANSACOES.CRIAR_ATUALIZAR_ENTREGA');
    initialize(null);
    
    l_delivery_rec_typ := p_delivery_rec_typ;
    l_delivery_id      := null;
    l_delivery_name    := null;
    
    print_out('  Chamando... WSH_DELIVERIES_PUB.CREATE_UPDATE_DELIVERY');
    print_out('    Ação         :'||p_action_code);
    print_out('    Delivery_id  :'||l_delivery_rec_typ.delivery_id);
    print_out('    Delivery_name:'||l_delivery_rec_typ.name);
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
    limpa_msg;
    WSH_DELIVERIES_PUB.CREATE_UPDATE_DELIVERY(
      p_api_version_number  => 1.0, 
      p_init_msg_list       => fnd_api.g_false, 
      x_return_status       => l_return_status, 
      x_msg_count           => l_msg_count, 
      x_msg_data            => l_msg_data, 
      p_action_code         => p_action_code, 
      p_delivery_info       => l_delivery_rec_typ, 
      p_delivery_name       => l_delivery_rec_typ.name, 
      --
      x_delivery_id         => l_delivery_id, 
      x_name                => l_delivery_name
    );
    print_out('  Saida:'||l_return_status);
    print_out('    Delivery_id  :'||l_delivery_id);
    print_out('    Delivery_name:'||l_delivery_name);
    if (l_return_status <> 'S') then
      --
      for i in 1 .. l_msg_count loop
        l_msg_data := fnd_msg_pub.get( 
          p_msg_index => i, 
          p_encoded   => 'F'
        );
        print_out( i|| ') '|| l_msg_data);
      end loop;
      --
      x_retorno       := l_msg_data;
      x_delivery_id   := null;
      x_delivery_name := null;
    else
      x_retorno       := 'S';
      x_delivery_id   := l_delivery_id;
      x_delivery_name := l_delivery_name;
    end if;
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''BRAZILIAN PORTUGUESE''';
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.CRIAR_ATUALIZAR_ENTREGA');
  end;

  procedure pick_release(
    p_delivery_id    in  number,
    p_trip_id        in  number,
    p_tipo_liberacao in  varchar2,
    x_msg_retorno    out varchar2,
    x_retorno        out varchar2
  ) is
   
    px_request_id             NUMBER;
    px_msg                    VARCHAR2(4000);
    px_release_status         VARCHAR2(4000);
    vx_msg_count              NUMBER;
    vx_msg_data               VARCHAR2(2000) := NULL;
    v_msg_count               NUMBER;
    v_msg_data                VARCHAR2(1000);
    v_message                 VARCHAR2(32767) := NULL;
    v_release_rule_id         NUMBER;
    v_release_rule            VARCHAR2(50);
    v_release_rule_lookup     VARCHAR2(50);
    v_success_msg             VARCHAR2(2000) := NULL;
    v_return_status           VARCHAR2(1);
    p_count                   NUMBER(15);
    p_new_batch_id            NUMBER;
    v_rule_id                 NUMBER;
    v_rule_name               VARCHAR2(50);
    v_auto_pick_confirm_flag  VARCHAR2(10);
    v_autodetail_pr_flag      VARCHAR2(10);
    
    
    v_batch_prefix        VARCHAR2(2000);
    v_batch_info_rec      wsh_picking_batches_pub.batch_info_rec;
    v_header_id           NUMBER;
    v_customer_id         NUMBER;
    v_organization_id     NUMBER;
    v_ship_date_count     NUMBER := 0;
    v_released_count      NUMBER := 0;
    vx_request_id         NUMBER;
    v_order_type_id       oe_order_headers_all.order_type_id%TYPE;
    --
    e_erro                EXCEPTION;
    
    l_org_id              number;
    l_organization_id     number;
    l_organization_code   varchar2(30);
    l_order_type_id       number;
    
    ok boolean :=true;   
    
  begin
    print_out('  XXFR_WSH_PCK_TRANSACOES.PICK_RELEASE');
    
    if (p_delivery_id is null) then
      print_out('    Trip_id     :'||p_trip_id);
    else
      print_out('    Delivery_id :'||p_delivery_id);
    end if;
    
    initialize(null);
    vx_request_id := null;
    
    select distinct
      org_id   ,organization_id   ,organization_code   ,id_tipo_ordem
    into
      l_org_id ,l_organization_id ,l_organization_code ,l_order_type_id
    from xxfr_wsh_vw_inf_da_ordem_venda
    where 1=1
      and released_status <> 'C'
      and delivery_id  = nvl(p_delivery_id,delivery_id)
      and trip_id      = nvl(p_trip_id    ,trip_id)
      and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
    ;  
    if (p_tipo_liberacao is not null) then
      print_out('    ----------------------------------------------');
      print_out('    Procurando regra:'||l_organization_code||'.'||p_tipo_liberacao);
      --RESGATA REGRAS DE PICKING
      begin
        select distinct 
             wpr.picking_rule_id, wpr.picking_rule_name --, flv.description, wpr.auto_pick_confirm_flag, wpr.autodetail_pr_flag
        into v_release_rule_id,   v_release_rule       --, v_auto_pick_confirm_flag,   v_autodetail_pr_flag
        from 
          wsh_picking_rules_v wpr,
          fnd_lookup_values   flv
        where 1=1
          and flv.language     = 'PTB'
          and flv.lookup_type  = 'XXFR_INT_LKP_REGRAS_LIBERACAO'
          and flv.ENABLED_FLAG = 'Y' 
          and (
            upper(wpr.picking_rule_name)      = upper(flv.description)
            or 
            upper(wpr.picking_rule_name)      = upper(lookup_code)
          )
          --
          and nvl(wpr.end_date_active,sysdate) >= sysdate
          and wpr.warehouse_code               = l_organization_code
          and upper(flv.lookup_code)           = upper(l_organization_code||'.'||p_tipo_liberacao)
          and rownum = 1
        ;      
      exception
        when no_data_found then
          x_retorno := 'Regra de liberação não encontrada para a organização :' ||l_organization_code||'.'||p_tipo_liberacao||' -  Verifcar o cadastro da lookup:XXFR_INT_LKP_REGRAS_LIBERACAO';
          print_out('    '||x_retorno);
          ok := false;
        when too_many_rows then
          x_retorno := 'Mais de uma regra de liberação encontrada para a organização :' ||l_organization_code;
          print_out('    '||x_retorno);
          ok:= false;
      end;
    end if;
    --
    if (ok) then
      print_out('    Regra de liberação: Id:'||v_release_rule_id||' - Cod:'||v_release_rule);
      vx_msg_data := null;

      /*  ------ 20200227 MARCEL 
      v_batch_info_rec.customer_id              := r1.customer_id;
      v_batch_info_rec.order_header_id          := r1.header_id;
      v_batch_info_rec.order_type_id            := r1.order_type_id;
      v_batch_info_rec.to_scheduled_ship_date   := p_ship_date + 1;
      v_batch_info_rec.organization_id          := r1.organization_id;
      */
      --      
      if (v_release_rule_id is null) then
        --v_batch_info_rec.backorders_only_flag     := 'E';
        v_batch_info_rec.existing_rsvs_only_flag  := 'N';
        v_batch_info_rec.include_planned_lines    := 'Y';
        v_batch_info_rec.autocreate_delivery_flag := 'N';
        --v_batch_info_rec.allocation_method        := 'I';
        v_batch_info_rec.pick_from_locator_id     := null;
        v_batch_info_rec.auto_pick_confirm_flag   := 'Y';
        v_batch_info_rec.autodetail_pr_flag       := 'Y';
        v_batch_info_rec.autopack_flag            := 'N';
      end if;
      --
      v_batch_info_rec.delivery_id              := p_delivery_id;
      v_batch_info_rec.trip_id                  := p_trip_id;
      --
      v_rule_id                                 := v_release_rule_id;
      v_rule_name                               := v_release_rule;
      v_batch_prefix                            := null;
      --
      /*
      IF (v_auto_pick_confirm_flag = 'N' AND v_autodetail_pr_flag = 'N') then
        null;
      end if;
      */
      print_out('    Chamando... WSH_PICKING_BATCHES_PUB.CREATE_BATCH');
      wsh_picking_batches_pub.create_batch(
        p_api_version   => 1.0,
        p_init_msg_list => fnd_api.g_false,
        p_commit        => fnd_api.g_false,  
        p_rule_id       => v_rule_id,
        p_rule_name     => v_rule_name,
        p_batch_rec     => v_batch_info_rec,
        --
        p_batch_prefix  => v_batch_prefix,
        --
        x_batch_id      => p_new_batch_id,
        x_return_status => v_return_status,
        x_msg_count     => v_msg_count,
        x_msg_data      => v_msg_data
      );
      print_out('    Retorno:' ||v_return_status);
      x_retorno := v_return_status;
      
      if v_return_status = 'S' then
        print_out('    Pick Release Batch Got Created Sucessfully ' ||p_new_batch_id);
      else
        for i in 1 .. v_msg_count loop
          v_msg_data := fnd_msg_pub.get( 
            p_msg_index => i, 
            p_encoded   => 'T'
          );
          print_out('    '||i|| ') '|| v_msg_data);
        end loop;
        ok := false;
      end if;
    end if;
    --
    if (ok) then
      print_out(' ');
      print_out('    Chamando... WSH_PICKING_BATCHES_PUB.RELEASE_BATCH');
      wsh_picking_batches_pub.release_batch(
        p_api_version    => 1.0,
        p_init_msg_list  => fnd_api.g_true,
        p_commit         => fnd_api.g_false,
        p_batch_id       => p_new_batch_id,
        p_batch_name     => null,
        p_log_level      => 1,
        --p_release_mode  => 'CONCURRENT',
        p_release_mode   => 'ONLINE', 
        x_return_status  => v_return_status,
        x_msg_count      => v_msg_count,
        x_msg_data       => v_msg_data,
        x_request_id     => vx_request_id
      );
      x_retorno := v_return_status;
      print_out('    Retorno:' ||v_return_status);
      print_out(' ');
      --
      if (v_return_status = 'S') then
        print_out('    Pick Selection List Generation :' ||vx_request_id);
        print_out('    Mensagens:');
        for i in 1 .. v_msg_count loop
          v_msg_data := fnd_msg_pub.get( 
            p_msg_index => i, 
            p_encoded   => 'F'
          );
          print_out('    '||i||')-'|| v_msg_data);
        end loop;
      end if;
      if (v_return_status = 'E') then
        ok:=false;
        print_out('    Mensagens:');
        for i in 1 .. v_msg_count loop
          v_msg_data := fnd_msg_pub.get( 
            p_msg_index => i, 
            p_encoded   => 'F'
          );
          print_out('    '||i||')-'|| v_msg_data);
        end loop;
      end if;
      --
      if (ok) then
        if (v_return_status = 'W') then
          for r1 in (
            select distinct delivery_detail_id, line_released_status_name
            from xxfr_wsh_vw_inf_da_ordem_venda
            where 1=1
              and released_status <> 'C'
              and delivery_id     = nvl(p_delivery_id,delivery_id)
              and trip_id         = nvl(p_trip_id    ,trip_id)
              and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
          ) loop
            print_out('    Delivery_detail:'||r1.delivery_detail_id);
            IF (r1.line_released_status_name in ('Preparação/Separação Confirmada')) then
              print_out('    '||r1.line_released_status_name);
              x_retorno := 'S';
            elsif (r1.line_released_status_name = 'Com Backorder') then
              x_retorno := 'Verificar regra de separação do WMS:'||v_release_rule||' (Entrega em Backorder)';
              print_out('    '||x_retorno);
            elsif (r1.line_released_status_name = 'Pronto para Liberação') then
              x_retorno := 'A Liberação para Separação On-line foi finalizada com uma Advertência';
            elsif (r1.line_released_status_name = 'Liberado para Depósito') then
              print_out('    '||r1.line_released_status_name);
              x_retorno := 'S';
            end if;
          end loop;
        else
          x_retorno := 'S';
        end if;
      end if;
    end if;
    print_out('    ----------------------------------------------');
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.PICK_RELEASE');
  exception
    when others then
      print_out('    Erro não previsto :'||sqlerrm);
      x_retorno := sqlerrm;
      print_out('  FIM XXFR_WSH_PCK_TRANSACOES.DELIVERY_PICK_RELEASE');
  end;

  procedure confirma_entrega(
    p_delivery_id   in  number,
    p_action_code   IN varchar2,
    x_retorno       out varchar2
  ) is
    --Standard Parameters.
    p_api_version             NUMBER;
    p_init_msg_list           VARCHAR2(30);
    p_commit                  VARCHAR2(30);
    --p_delivery_id NUMBER;
    p_delivery_name           VARCHAR2(30);
    p_asg_trip_id             NUMBER;
    p_asg_trip_name           VARCHAR2(30);
    p_asg_pickup_stop_id      NUMBER;
    p_asg_pickup_loc_id       NUMBER;
    p_asg_pickup_loc_code     VARCHAR2(30);
    p_asg_pickup_arr_date     DATE;
    p_asg_pickup_dep_date     DATE;
    p_asg_dropoff_stop_id     NUMBER;
    p_asg_dropoff_loc_id      NUMBER;
    p_asg_dropoff_loc_code    VARCHAR2(30);
    p_asg_dropoff_arr_date    DATE;
    p_asg_dropoff_dep_date    DATE;
    p_sc_action_flag          VARCHAR2(10);
    p_sc_close_trip_flag      VARCHAR2(10);
    p_sc_create_bol_flag      VARCHAR2(10);
    p_sc_stage_del_flag       VARCHAR2(10);
    p_sc_trip_ship_method     VARCHAR2(30);
    p_sc_actual_dep_date      VARCHAR2(30);
    p_sc_report_set_id        NUMBER;
    p_sc_report_set_name      VARCHAR2(60);
    p_wv_override_flag        VARCHAR2(10);
    p_sc_defer_interface_flag VARCHAR2(1);
    --
    l_trip_id                 VARCHAR2(30);
    l_trip_name               VARCHAR2(30);
    --out parameters
    l_return_status           VARCHAR2(10);
    l_msg_count               NUMBER;
    l_msg_data                VARCHAR2(2000);
    l_msg_details             VARCHAR2(3000);
    l_msg_summary             VARCHAR2(3000);
    --
    fail_api                  EXCEPTION;
    
    l_action_code             VARCHAR2(30);
    
  BEGIN
    -- Initialize return status
    l_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
    
    -- Call this procedure to initialize applications parameters
    initialize(null);
    -- Values for Ship Confirming the delivery
    
    --
    l_action_code := p_action_code;
    IF (l_action_code = 'BACKORDER') then
      p_sc_action_flag          := 'C'; -- C Ship entered quantity.
      p_sc_close_trip_flag      := 'Y';
    else
      p_sc_action_flag          := 'S'; 
      p_sc_close_trip_flag      := 'Y'; -- Close the trip after ship confirm
    end if;
    l_action_code             := 'CONFIRM';
    p_sc_stage_del_flag       := 'N';
    
    -- Call to WSH_DELIVERIES_PUB.Delivery_Action.
    print_out('  XXFR_WSH_PCK_TRANSACOES.CONFIRMA_ENTREGA('||p_action_code||')');
    print_out('  Chamando... WSH_DELIVERIES_PUB.DELIVERY_ACTION');
    print_out('    Delivery_id:'||p_delivery_id);
    limpa_msg;
    WSH_DELIVERIES_PUB.Delivery_Action(
      p_api_version_number      => 1.0,
      p_init_msg_list           => p_init_msg_list,
      p_action_code             => l_action_code,
      p_delivery_id             => p_delivery_id,
      p_delivery_name           => p_delivery_name,
      --
      p_asg_trip_id             => p_asg_trip_id,
      p_asg_trip_name           => p_asg_trip_name,
      p_asg_pickup_stop_id      => p_asg_pickup_stop_id,
      p_asg_pickup_loc_id       => p_asg_pickup_loc_id,
      p_asg_pickup_loc_code     => p_asg_pickup_loc_code,
      p_asg_pickup_arr_date     => p_asg_pickup_arr_date,
      p_asg_pickup_dep_date     => p_asg_pickup_dep_date,
      --
      p_asg_dropoff_stop_id     => p_asg_dropoff_stop_id,
      p_asg_dropoff_loc_id      => p_asg_dropoff_loc_id,
      p_asg_dropoff_loc_code    => p_asg_dropoff_loc_code,
      p_asg_dropoff_arr_date    => p_asg_dropoff_arr_date,
      p_asg_dropoff_dep_date    => p_asg_dropoff_dep_date,
      --
      p_sc_action_flag          => p_sc_action_flag,
      p_sc_close_trip_flag      => p_sc_close_trip_flag,
      p_sc_stage_del_flag       => p_sc_stage_del_flag,
      
      p_sc_create_bol_flag      => p_sc_create_bol_flag,
      p_sc_trip_ship_method     => p_sc_trip_ship_method,
      p_sc_actual_dep_date      => p_sc_actual_dep_date,
      p_sc_report_set_id        => p_sc_report_set_id,
      p_sc_report_set_name      => p_sc_report_set_name,
      p_wv_override_flag        => p_wv_override_flag,
      p_sc_defer_interface_flag => p_sc_defer_interface_flag ,

      x_trip_id                 => l_trip_id,
      x_trip_name               => l_trip_name,
      x_return_status           => l_return_status,
      x_msg_count               => l_msg_count,
      x_msg_data                => l_msg_data
    );
    print_out('  Retorno:'||l_return_status);
    print_out('    Trip_id  :'||l_trip_id);
    print_out('    Trip_name:'||l_trip_name);
    if (l_return_status <> 'S') then
      for i in 1 .. l_msg_count loop
        l_msg_data := fnd_msg_pub.get( 
          p_msg_index => i, 
          p_encoded   => 'F'
        );
        print_out('    '||i|| ') '|| l_msg_data);
      end loop; 
    end if;
    x_retorno := l_return_status;
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.CONFIRMA_ENTREGA('||p_action_code||')');
  END;

  procedure confirma_percurso(
    p_trip_id        in  number,
    p_action_param   in  WSH_TRIPS_PUB.Action_Param_Rectype,
    x_rec_retorno    out xxfr_pck_interface_integracao.rec_retorno_integracao,
    x_retorno        out varchar2
  ) is

    l_return_status           VARCHAR2(10);
    l_msg_count               NUMBER;
    l_msg_data                VARCHAR2(4000);
    l_msg_details             VARCHAR2(4000);
    l_msg_summary             VARCHAR2(4000);
    
    qtd_confirm_percurso      number;
    
    l_msg_index_out number;
    l_error_message varchar2(4000);
    i               number :=0;
    
    cursor c1(I_TRIP_ID IN NUMBER) is
      select trip_id, nome_percurso, delivery_id DELIVERY_NAME, pick_status_name,  flow_status_code, status_percurso
      from xxfr_wsh_vw_inf_da_ordem_venda
      where 1=1  
        and trip_id = i_trip_id
    ;
    
  begin
    print_out('  XXFR_WSH_PCK_TRANSACOES.CONFIRMA_PERCURSO('||p_action_param.action_code||')');
    print_out('  Chamando... WSH_TRIPS_PUB.TRIP_ACTION');
    initialize(null);
    limpa_msg;
    WSH_TRIPS_PUB.trip_action ( 
      p_api_version_number     => 1.0,
      p_init_msg_list          => FND_API.G_TRUE,
      p_commit                 => FND_API.G_FALSE,
      p_action_param_rec       => p_action_param,
      p_trip_id                => p_trip_id,
      p_trip_name              => null,
      p_dock_door_alias        => null,
      p_dock_door_id           => null,
      p_equipment_id           => null,
      x_return_status          => l_return_status,
      x_msg_count              => l_msg_count,
      x_msg_data               => l_msg_data
    );
    print_out('    Retorno:'||l_return_status);
    x_retorno := l_return_status;
    if (l_msg_count > 0) then
      for i in 1 .. l_msg_count loop
        FND_MSG_PUB.Get (
          p_msg_index       => i,
          p_encoded         => 'F',
          p_data            => l_msg_details,
          p_msg_index_OUT   => l_msg_index_out
        );
        if (substr(l_msg_details,1,1) = 'A') then
          x_rec_retorno."registros"(1)."mensagens"(i)."tipoMensagem" := 'ADVERTENCIA';
        else
          x_rec_retorno."registros"(1)."mensagens"(i)."tipoMensagem" := 'ERRO';
          ok := false;
        end if;
        
        l_msg_details := REPLACE(l_msg_details, 'Weight
nulo', 'Weight NULL');
        l_msg_details := REPLACE(l_msg_details, CHR(13)||CHR(10), '');
        l_msg_details := REPLACE(l_msg_details, CHR(10), '');
        l_msg_details := REPLACE(l_msg_details, CHR(13), '');

        print_out('    '||i|| ') '|| l_msg_details);
        x_rec_retorno."registros"(1)."mensagens"(i)."mensagem" := l_msg_details;
      end loop; 
    end if;
    --
    i:=0;
    if (p_action_param.action_code = 'TRIP-CONFIRM') then
      for r1 in c1(p_trip_id) loop
        i:=i+1;
        print_out('');
        print_out('    Delivery('||i||'):'||r1.delivery_name||' - '||r1.PICK_STATUS_NAME||' - '||r1.FLOW_STATUS_CODE);
        if    (r1.PICK_STATUS_NAME = 'Entregue' and r1.FLOW_STATUS_CODE = 'INVOICE_INCOMPLETE' and r1.status_percurso = 'CL') then
          x_rec_retorno."mensagemRetornoProcessamento" := 'ENTREGA '||r1.delivery_name||'- PROCESSADA E ENVIADA PARA INTERFACE (COM ADVERTENCIAS)';
          ok := true;
        elsif (r1.PICK_STATUS_NAME = 'Entregue' and r1.FLOW_STATUS_CODE = 'CLOSED' and r1.status_percurso = 'CL') then
          x_rec_retorno."mensagemRetornoProcessamento" := 'ENTREGA '||r1.delivery_name||'- PROCESSADA E ENTREGUE (COM ADVERTENCIAS)';
          ok := true;
        elsif (r1.PICK_STATUS_NAME = 'Entregue' and r1.FLOW_STATUS_CODE = 'AWAITING_SHIPPING' and r1.status_percurso = 'CL') then
          x_rec_retorno."mensagemRetornoProcessamento" := 'ENTREGA '||r1.delivery_name||'- PROCESSADA (COM ADVERTENCIAS)';
          ok := true;
        else
          ok := false;
          x_retorno := 'A Confirmação do Percurso falhou !';
          print_out(' ');
          print_out('    '||x_retorno);
          print_out(' ');
        end if;
      end loop;
      if (i=0) then 
        ok := false;
        x_retorno := 'A Confirmação do Percurso falhou !';
        print_out(' ');
        print_out('    '||x_retorno);
        print_out(' ');
      end if;
    end if;
    if (ok and p_action_param.action_code = 'TRIP-CONFIRM' and i > 0) then
      print_out('  ******************************');
      print_out('  PERCURSO E ENTREGA CONFIRMADOS');
      print_out('  ******************************');
      x_retorno := 'S';
    end if;
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.CONFIRMA_PERCURSO('||p_action_param.action_code||')');
  end;

  procedure atribuir_conteudo_firme(
    p_delivery_id in number ,
    p_action_code in varchar2,
    x_retorno     out varchar2
  ) is
  
    l_trip_name     varchar2(100);
    l_return_status varchar2(2);
    l_msg_data      varchar2(4000);
    l_msg_count     number;
    l_trip_id       number;
    
  begin
    print_out('  XXFR_WSH_PCK_TRANSACOES.ATRIBUIR_CONTEUDO_FIRME');
    print_out('  Chamando... WSH_DELIVERIES_PUB.DELIVERY_ACTION');
    print_out('    Ação         :'||p_action_code);
    print_out('    Delivery_id  :'||P_delivery_id);
    initialize(null);
    limpa_msg;
    wsh_deliveries_pub.delivery_action(
      p_api_version_number => 1.0,
      p_init_msg_list      => fnd_api.g_false,
      x_return_status      => l_return_status,
      x_msg_count          => l_msg_count,
      x_msg_data           => l_msg_data,
      p_action_code        => p_action_code,
      p_delivery_id        => p_delivery_id,
      x_trip_id            => l_trip_id,
      x_trip_name          => l_trip_name
    );
    print_out('  Retorno:'||l_return_status);
    print_out('    Trip_id  :'||l_trip_id);
    print_out('    Trip_name:'||l_trip_name);
    for i in 1 .. l_msg_count loop
      l_msg_data := fnd_msg_pub.get( 
        p_msg_index => i, 
        p_encoded   => 'F'
      );
      print_out('    '||i|| ') '|| l_msg_data);
    end loop;
    if (l_return_status <> 'S') then
      x_retorno := l_msg_data;
    else
      x_retorno := l_return_status;
    end if;
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.ATRIBUIR_CONTEUDO_FIRME');
  end;

  procedure criar_reserva(
    p_oe_header_id      in number,
    p_oe_line_id        in number,
    p_action            in varchar2,
    p_qtd               in number,
    p_subinventory_code in varchar2,
    p_locator_id        in number,
    p_lot_number        in  varchar2,
    x_retorno           out varchar2
  ) is

    l_msg_data       varchar2(240);
    l_msg_count      number;
    l_status         varchar2(1);
    l_rsv            inv_reservation_global.mtl_reservation_rec_type;
    l_dummy_sn       inv_reservation_global.serial_number_tbl_type;
    l_qtd            number;
    l_rsv_id         number;
    l_sales_order_id number;
    l_header_id      number;
    l_line_id        number;
  
    cursor cur is
      select distinct
        ool.request_date,
        ool.ship_from_org_id,
        ool.inventory_item_id,
        ool.header_id,
        ool.line_id,
        ool.order_quantity_uom,
        ool.ordered_quantity,
        msi.primary_uom_code,
        inv_convert.inv_um_convert(
          msi.inventory_item_id,
          null,
          ool.ordered_quantity,
          ool.order_quantity_uom,
          msi.primary_uom_code,
          null,
          null
        ) prim_qty
      from 
        oe_order_lines_all ool, 
        mtl_system_items_b msi
      where 1=1
        and ool.header_id         = l_header_id
        and ool.line_id           = l_line_id
        and ool.flow_status_code NOT IN ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
        and ool.ship_from_org_id  = msi.organization_id
        and ool.inventory_item_id = msi.inventory_item_id
    ;
  begin
    print_out('  XXFR_WSH_PCK_TRANSACOES.RESERVA');
    l_header_id := p_oe_header_id;
    l_line_id   := p_oe_line_id;
    begin
      select mso.sales_order_id
      into l_sales_order_id
      from 
        mtl_sales_orders        mso,
        oe_order_headers_all    ooh,
        oe_transaction_types_tl ott
      where 1=1
        and mso.segment1            = ooh.order_number
        and ott.transaction_type_id = ooh.order_type_id
        and mso.segment2            = ott.name
        and ott.language            = 'PTB'
        and ooh.header_id           = l_header_id
        and segment3                = 'ORDER ENTRY';
    exception
      when no_data_found then
        x_retorno := 'Erro ao buscar SALES_ORDER_ID';
        print_out('  '||x_retorno);
        return;
    end;
    --
    for c1 in cur loop
      --
      print_out('  inventory_item_id:'||c1.inventory_item_id);
      --
      l_rsv.reservation_id               := null;
      l_rsv.requirement_date             := c1.request_date;
      l_rsv.organization_id              := c1.ship_from_org_id;
      l_rsv.inventory_item_id            := c1.inventory_item_id;
      l_rsv.demand_source_type_id        := inv_reservation_global.g_source_type_oe;
      l_rsv.demand_source_name           := null;
      l_rsv.demand_source_header_id      := l_sales_order_id;
      l_rsv.demand_source_line_id        := c1.line_id;
      l_rsv.primary_uom_code             := c1.primary_uom_code;
      l_rsv.primary_uom_id               := null;
      l_rsv.reservation_uom_code         := c1.order_quantity_uom;
      l_rsv.reservation_uom_id           := null;
      l_rsv.reservation_quantity         := p_qtd;
      l_rsv.primary_reservation_quantity := p_qtd;
      l_rsv.autodetail_group_id          := null;
      l_rsv.external_source_code         := null;
      l_rsv.external_source_line_id      := null;
      l_rsv.supply_source_type_id        := inv_reservation_global.g_source_type_inv;
      l_rsv.supply_source_header_id      := null;
      l_rsv.supply_source_line_id        := null;
      l_rsv.supply_source_name           := null;
      l_rsv.supply_source_line_detail    := null;
      l_rsv.revision                     := null;
      l_rsv.subinventory_id              := null;
      l_rsv.subinventory_code            := p_subinventory_code;
      l_rsv.locator_id                   := p_locator_id;
      l_rsv.lot_number                   := p_lot_number;
      l_rsv.lot_number_id                := null;
      l_rsv.pick_slip_number             := null;
      l_rsv.lpn_id                       := null;
      l_rsv.attribute_category           := null;
      l_rsv.attribute1                   := null;
      l_rsv.attribute2                   := null;
      l_rsv.attribute3                   := null;
      l_rsv.attribute4                   := null;
      l_rsv.attribute5                   := null;
      l_rsv.attribute6                   := null;
      l_rsv.attribute7                   := null;
      l_rsv.attribute8                   := null;
      l_rsv.attribute9                   := null;
      l_rsv.attribute10                  := null;
      l_rsv.attribute11                  := null;
      l_rsv.attribute12                  := null;
      l_rsv.attribute13                  := null;
      l_rsv.attribute14                  := null;
      l_rsv.attribute15                  := null;
      l_rsv.ship_ready_flag              := null;
      l_rsv.demand_source_delivery       := null;
      --
      print_out('  Chamando INV_RESERVATION_PUB.CREATE_RESERVATION...');
      inv_reservation_pub.create_reservation(
        p_api_version_number       => 1.0,
        p_init_msg_lst             => fnd_api.g_true,
        x_return_status            => l_status,
        x_msg_count                => l_msg_count,
        x_msg_data                 => l_msg_data,
        p_rsv_rec                  => l_rsv,
        p_serial_number            => l_dummy_sn,
        x_serial_number            => l_dummy_sn,
        p_partial_reservation_flag => fnd_api.g_false -- g_true
        ,
        p_force_reservation_flag   => fnd_api.g_false,
        p_validation_flag          => fnd_api.g_true,
        x_quantity_reserved        => l_qtd,
        x_reservation_id           => l_rsv_id
      );
      x_retorno := l_status;
      print_out('    Retorno:' || l_status);
      if l_status <> 'S' then
        x_retorno := '';
        for j in 1 .. l_msg_count loop
          l_msg_data := fnd_msg_pub.get(j, 'F');
          print_out('    Erro:' || l_msg_data);
          x_retorno := x_retorno || j ||')-'||l_msg_data || ' ';
        end loop;
      end if;
    end loop;
  end;

  procedure criar_mov_subinventario(
    p_move_order_line_id in  varchar2,
    p_line_number        in  varchar2,
    p_from_locator       in  varchar2,
    p_to_locator         in  varchar2,
    p_lot_number         in  varchar2,
    p_inventory_item_id  in  number,
    p_organization_id    in  number,
    --
    p_from_subinventory_code in varchar2,
    p_to_subinventory_code   in varchar2,
    --
    p_primary_quantity   in  number,
    p_trx_quantity       in  number,
    x_retorno            out varchar2
  ) is
  
    l_lines                 mtl_txn_request_lines%rowtype;
    l_return                number;
    l_return_status         varchar2(20);
    l_msg_count             number;
    l_trans_count           number;

    l_msg_data              varchar2(4000);
    l_proc_msg              varchar2(4000);
    
    l_trx_tmp_id            number;
    l_ser_trx_id            number;
    
    p_from_lpn_number       varchar2(30);
    p_sec_trx_quantity      number;
    
    l_trolin_tbl    inv_move_order_pub.trolin_tbl_type;
    l_mold_tbl      inv_mo_line_detail_util.g_mmtt_tbl_type;
    l_mmtt_tbl      inv_mo_line_detail_util.g_mmtt_tbl_type;
    lx_trolin_tbl   inv_move_order_pub.trolin_tbl_type;
  
    cursor c1 is
      select distinct
        mtrh.header_id,
        mtrl.inventory_item_id,
        mtrl.organization_id,
        mtrl.txn_source_id,
        mtrl.txn_source_line_id,
        mtrh.request_number       move_order_number,
        mtrl.line_id              move_order_line_id,
        mtrl.line_number          line_number,
        mtt.transaction_action_id,
        mtrl.transaction_type_id,
        mtrl.transaction_source_type_id,
        msi.primary_uom_code,
        msi.secondary_uom_code
      from 
        mtl_txn_request_headers   mtrh,
        mtl_txn_request_lines     mtrl,
        mtl_transaction_types     mtt,
        mtl_system_items_b        msi
      where 1=1
        and mtrh.header_id           = mtrl.header_id
        and mtrl.transaction_type_id = mtt.transaction_type_id
        and mtrl.organization_id     = msi.organization_id
        and mtrl.inventory_item_id   = msi.inventory_item_id
        --
        and msi.inventory_item_id    = p_inventory_item_id
        and msi.organization_id      = p_organization_id
        and mtrl.line_id             = p_move_order_line_id
      ;
    
  begin
    initialize('INV');
    print_out('  XXFR_WSH_PCK_TRANSACOES.CRIAR_MOV_SUBINVETARIO');
    for r1 in c1 loop
      l_return := 0;
      --
      print_out('    Inventory_item_id  :'||p_inventory_item_id);
      print_out('    Organization_id    :'||p_organization_id);
      print_out('    Move_order_line_id :'||p_move_order_line_id);
      print_out('    Lot_Number         :'||p_lot_number);
      
      print_out('    From_locator       :'||p_from_locator);
      print_out('    To_locator         :'||p_to_locator);
      
      print_out('    From_sub_invetory  :'||p_from_subinventory_code);
      print_out('    To_sub_inventory   :'||p_to_subinventory_code);
      
      print_out('    from_lpn_number    :'||p_from_lpn_number);
      print_out('    -------------------------------------------');
      --Passo 1
      if (l_return = 0) then
        print_out('    Chamando INV_TRX_UTIL_PUB.INSERT_LINE_TRX...');
        l_return := inv_trx_util_pub.insert_line_trx(
          p_trx_hdr_id              => r1.header_id,
          p_item_id                 => r1.inventory_item_id,
          --P_REVISION                =>,
          p_org_id                  => r1.organization_id,
          p_trx_action_id           => r1.transaction_action_id,
          p_subinv_code             => p_from_subinventory_code,
          p_tosubinv_code           => p_to_subinventory_code,
          p_locator_id              => p_from_locator,
          p_tolocator_id            => p_to_locator,
          --P_XFR_ORG_ID              =>,
          p_trx_type_id             => r1.transaction_type_id,
          p_trx_src_type_id         => r1.transaction_source_type_id,
          p_trx_qty                 => p_trx_quantity,
          p_pri_qty                 => p_primary_quantity,
          p_uom                     => r1.primary_uom_code,
          p_date                    => sysdate,
          --P_REASON_ID               =>,
          p_user_id                 => fnd_profile.value('USER_ID'), -- buscar da sessão
          --P_FRT_CODE                =>,
          --P_SHIP_NUM                =>,
          --P_DIST_ID                 =>,
          --P_WAY_BILL                =>,
          --P_EXP_ARR                 =>,
          --P_COST_GROUP              =>,
          p_from_lpn_id             => null,
          --P_CNT_LPN_ID              =>,
          --P_XFR_LPN_ID              =>,
          p_trx_src_id              => r1.txn_source_id,
          --P_XFR_COST_GROUP          =>,
          --P_COMPLETION_TRX_ID       =>,
          --P_FLOW_SCHEDULE           =>,
          --P_TRX_COST                =>,
          --P_PROJECT_ID              =>,
          --P_TASK_ID                 =>,
          --P_COST_OF_TRANSFER        =>,
          --P_COST_OF_TRANSPORTATION  =>,
          --P_TRANSFER_PERCENTAGE     =>,
          --P_TRANSPORTATION_COST_ACCOUNT =>,
          p_planning_org_id           => null,
          p_planning_tp_type          => null,
          p_owning_org_id             => null,
          p_owning_tp_type            => null,
          p_trx_src_line_id           => r1.txn_source_line_id,
          p_secondary_trx_qty         => p_sec_trx_quantity,
          p_secondary_uom             => r1.secondary_uom_code,
          p_move_order_line_id        => r1.move_order_line_id,
          p_posting_flag              => 'Y',
          p_move_order_header_id      => r1.header_id,
          p_serial_allocated_flag     => null,
          p_transaction_status        => 2,
          --P_PROCESS_FLAG              =>,
          p_ship_to_location_id       => null,
          p_relieve_reservations_flag => null,
          p_opm_org_in_xfer           => null,
          x_trx_tmp_id                => l_trx_tmp_id,
          x_proc_msg                  => l_proc_msg
        );
        --
        print_out('    Retorno   :'||l_return);
        print_out('    Trx_Tmp_id:'||l_trx_tmp_id);
        print_out('    Msg       :'||l_proc_msg);
        x_retorno := nvl(l_proc_msg,'S');
        print_out('    -------------------------------------------');
      end if;
      --Passo 2
      if nvl(l_trx_tmp_id, 0) > 0 then
        print_out('    Chamando INV_TRX_UTIL_PUB.INSERT_LOT_TRX...');
        l_return := inv_trx_util_pub.insert_lot_trx(
          p_trx_tmp_id => l_trx_tmp_id,
          p_user_id    => fnd_profile.value('USER_ID'), -- buscar da sessão
          p_lot_number => p_lot_number,
          p_trx_qty    => p_primary_quantity,
          p_pri_qty    => p_primary_quantity,
          --    
          x_ser_trx_id => l_ser_trx_id,
          x_proc_msg   => l_proc_msg
        );
        print_out('    Retorno   :'||l_return);
        print_out('    Ser_Trx_id:'||l_ser_trx_id);
        print_out('    Msg       :'||l_proc_msg);
        x_retorno := nvl(l_proc_msg,'S');
        print_out('    -------------------------------------------');
      end if;
      --Passo 3
      if (l_return = 0) then
        l_mold_tbl := apps.inv_mo_line_detail_util.query_rows(p_line_detail_id => l_trx_tmp_id); -- MTL_MATERIAL_TRANSACTIONS_TEMP.TRANSACTION_TEMP_ID
        print_out('    transaction_temp_id :'||l_mold_tbl(1).transaction_temp_id);
        print_out('    Chamando INV_PICK_WAVE_PICK_CONFIRM_PUB.PICK_CONFIRM...');
        limpa_msg;
        inv_pick_wave_pick_confirm_pub.pick_confirm(
          p_api_version_number => 1.0,
          p_init_msg_list      => fnd_api.g_true,
          p_commit             => fnd_api.g_false,
          --P_MOVE_ORDER_TYPE    => 3, -- ordem de venda
          p_move_order_type    => 1,
          p_transaction_mode   => 1,
          p_trolin_tbl         => l_trolin_tbl,
          p_mold_tbl           => l_mold_tbl,
          p_transaction_date   => sysdate,
          x_return_status      => l_return_status,
          x_msg_count          => l_msg_count,
          x_msg_data           => l_msg_data,
          x_mmtt_tbl           => l_mmtt_tbl,
          x_trolin_tbl         => lx_trolin_tbl
        );
        --print_out('    Retorno      :'||l_return);
        print_out('    Ret Status   :'||l_return_status);
        print_out('    Msg          :'||l_msg_data);
        print_out('    -------------------------------------------');
        --
        x_retorno := nvl(l_msg_data,'S');
        IF fnd_msg_pub.count_msg > 0 THEN
          FOR h IN 1 .. fnd_msg_pub.count_msg LOOP
            print_out('    Msg '||h ||')-'|| fnd_msg_pub.get(
              p_msg_index => h, 
              p_encoded   => fnd_api.g_false)
            );
          END LOOP;
        END IF;
        --
      end if;
      -- NÃO UTILIZAR MAIS ESSA PKG
      if (l_return = 9) then
        limpa_msg;
        print_out('    Chamando INV_TXN_MANAGER_PUB.PROCESS_TRANSACTIONS...');
        l_return := inv_txn_manager_pub.process_transactions(
          p_api_version      => 1.0,
          p_init_msg_list    => fnd_api.g_true,
          p_commit           => fnd_api.g_false,
          p_validation_level => fnd_api.g_valid_level_full,
          p_table            => 1,
          p_header_id        => l_trx_tmp_id,
          --
          x_return_status    => l_return_status,
          x_msg_count        => l_msg_count,
          x_msg_data         => l_msg_data,
          x_trans_count      => l_trans_count
        );
        print_out('    Retorno      :'||l_return);
        print_out('    Ret Status   :'||l_return_status);
        print_out('    Msg          :'||l_msg_data);
        print_out('    l_trans_count:'||l_trans_count);
        print_out('    -------------------------------------------');
        x_retorno := l_return_status;
        
        for j in 1 .. l_msg_count loop
          l_msg_data := fnd_msg_pub.get(j, 'F');
          print_out('    Erro:' || l_msg_data);
          x_retorno := x_retorno || j ||')-'||l_msg_data || ' ';
        end loop;
        --
        IF fnd_msg_pub.count_msg > 0 THEN
          FOR h IN 1 .. fnd_msg_pub.count_msg LOOP
            print_out('    Msg '||h ||')-'|| fnd_msg_pub.get(p_msg_index => h, p_encoded   => fnd_api.g_false));
          END LOOP;
        END IF;
        --
        FOR a IN (SELECT error_message FROM mtl_interface_errors  WHERE transaction_id = l_trx_tmp_id) LOOP
          print_out('    Msg: '||a.error_message);
        END LOOP;
        
      end if;
      --
    end loop;
    print_out('  FIM XXFR_WSH_PCK_TRANSACOES.CRIAR_MOVIMENTACAO_SUBINVETARIO');
  end;

  procedure atualiza_delivey_detail(
    p_changed_attributes  in WSH_DELIVERY_DETAILS_PUB.ChangedAttributeTabType,
    x_retorno             out varchar2
  ) is 
  
    l_changed_attributes  WSH_DELIVERY_DETAILS_PUB.ChangedAttributeTabType;
    l_return_status       varchar2(10);
    l_msg_count           number;
    l_msg_data            varchar2(3000);
  
  begin

    fnd_msg_pub.initialize;
    
    l_changed_attributes := p_changed_attributes;
   
    WSH_DELIVERY_DETAILS_PUB.Update_Shipping_Attributes (
      p_api_version_number  => 1.0,
      p_init_msg_list       => FND_API.G_FALSE,
      p_commit              => FND_API.G_FALSE,
      p_changed_attributes  => l_changed_attributes,
      p_source_code         => 'OE',
      p_container_flag      => '',
      x_return_status       => l_return_status,
      x_msg_count           => l_msg_count,
      x_msg_data            => l_msg_data
    );
    print_out('  Saida:'||l_return_status);
    for i in 1 .. l_msg_count loop
      l_msg_data := fnd_msg_pub.get( 
        p_msg_index => i, 
        p_encoded   => 'F'
      );
      print_out('  '|| i|| ') '|| l_msg_data);
    end loop;
    x_retorno := l_return_status;
  end;

end XXFR_WSH_PCK_TRANSACOES;
