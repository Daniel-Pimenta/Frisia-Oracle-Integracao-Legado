create or replace PACKAGE BODY XXFR_OM_PCK_DEV_SIMB_INSUMOS as

  g_header_id                    number;
  g_source                       varchar2(50) := 'XXFR_DEV_SIMB_INSUMOS';
  g_escopo                       varchar2(50) := 'XXFR_DEV_SIMB_INSUMOS';
  ok                             boolean;
  
  v_api_version_number           number    := 1;
  v_return_status                varchar2(2000);
  v_msg_count                    number;
  v_msg_data                     varchar2(2000);
  -- IN Variables --
  v_header_rec                   oe_order_pub.header_rec_type;
  v_line_tbl                     oe_order_pub.line_tbl_type;
  v_action_request_tbl           oe_order_pub.request_tbl_type;
  v_line_adj_tbl                 oe_order_pub.line_adj_tbl_type;
  -- OUT Variables --
  v_header_rec_out               oe_order_pub.header_rec_type;
  v_header_val_rec_out           oe_order_pub.header_val_rec_type;
  v_header_adj_tbl_out           oe_order_pub.header_adj_tbl_type;
  v_header_adj_val_tbl_out       oe_order_pub.header_adj_val_tbl_type;
  v_header_price_att_tbl_out     oe_order_pub.header_price_att_tbl_type;
  v_header_adj_att_tbl_out       oe_order_pub.header_adj_att_tbl_type;
  v_header_adj_assoc_tbl_out     oe_order_pub.header_adj_assoc_tbl_type;
  v_header_scredit_tbl_out       oe_order_pub.header_scredit_tbl_type;
  v_header_scredit_val_tbl_out   oe_order_pub.header_scredit_val_tbl_type;
  v_line_tbl_out                 oe_order_pub.line_tbl_type;
  v_line_val_tbl_out             oe_order_pub.line_val_tbl_type;
  v_line_adj_tbl_out             oe_order_pub.line_adj_tbl_type;
  v_line_adj_val_tbl_out         oe_order_pub.line_adj_val_tbl_type;
  v_line_price_att_tbl_out       oe_order_pub.line_price_att_tbl_type;
  v_line_adj_att_tbl_out         oe_order_pub.line_adj_att_tbl_type;
  v_line_adj_assoc_tbl_out       oe_order_pub.line_adj_assoc_tbl_type;
  v_line_scredit_tbl_out         oe_order_pub.line_scredit_tbl_type;
  v_line_scredit_val_tbl_out     oe_order_pub.line_scredit_val_tbl_type;
  v_lot_serial_tbl_out           oe_order_pub.lot_serial_tbl_type;
  v_lot_serial_val_tbl_out       oe_order_pub.lot_serial_val_tbl_type;
  v_action_request_tbl_out       oe_order_pub.request_tbl_type;
  --
  l_organization_id             number; 
  l_organization_code           varchar2(50);
  l_inventory_item_id           number;
  l_cust_acct_site_id           number;
  l_bill_to_site_use_id         number; 
  l_order_type_id               number; 
  l_lista_precos_om             varchar2(50); 
  l_condicao_pagamento          varchar2(50); 
  l_ordered_quantity            number; 
  l_uom_code                    varchar2(50); 
  l_status                      varchar2(50);
  --
  l_sold_to_org_id              number;
  l_ship_to_org_id              number; 
  l_invoice_to_org_id           number;
  --
  l_price_list_id               number;
  --
  l_term_id                     number;
  
  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo||'_'||g_header_id
    );
  end;
  
  procedure grava_erro(
    p_header_id   in number,
    p_cd_etapa    in varchar2,
    p_msg         in varchar2
  ) is
  begin
    print_log(p_msg);
    insert into xxfr_dev_simb_insumos_erro (
      erro_id,
      header_id,
      cd_etapa,
      ds_mensagem
    ) values (
      xxfr_seq_ret_insumos_erro.nextval,
      p_header_id,
      p_cd_etapa,
      p_msg
    );    
  end;
  
  procedure initialize_opm is
   
    l_user_id									number; 
    l_user_name               varchar2(300)  := nvl(fnd_profile.value('USERNAME'),'GERAL_INTEGRACAO');
    l_responsibility_id       number;
    l_application_id          number;
    l_application_short_name  varchar2(300);
    l_responsibility_name     varchar2(300);
  
  begin
    print_log('INITIALIZE_OPM');
    print_log('  User_Name        :'||l_user_name);
    print_log('  Organization_Code:'||l_organization_code);
    l_user_id:=1131;
    begin
      select u.user_id, u.user_name, r.responsibility_id, r.application_id, a.application_short_name, r.responsibility_name
      into l_user_id,   l_user_name, l_responsibility_id, l_application_id, l_application_short_name, l_responsibility_name
      from 
        fnd_user              u, 
        fnd_responsibility_tl r,
        fnd_application       a
      where 1=1
        and r.language              = 'PTB'
        --and u.user_name             = l_user_name
        and u.user_id               = l_user_id
        and r.application_id        = a.application_id
        and a.application_short_name= 'GMD'
        and r.responsibility_name like l_organization_code||'%Desenvolvedor de Produto%'
      ;
      print_log('  User_Name        :'||l_user_name);
      print_log('  Responsabilidade :'||l_responsibility_name);
      print_log('  Aplicação        :'||l_application_short_name);
      --
      print_log('  User Id          :'||l_user_id);
      print_log('  Resp Id          :'||l_responsibility_id);
      print_log('  Appl Id          :'||l_application_id);

      fnd_global.apps_initialize ( 
        user_id      => l_user_id,
        resp_id      => l_responsibility_id,
        resp_appl_id => l_application_id 
      );

    exception
      when others then
        print_log('Erro:'||sqlerrm);
        ok:=false;
        goto FIM;
    end;
    <<FIM>>
    print_log('FIM INITIALIZE_OPM');
  end;

  procedure main(
    p_header_id     in  number,
    x_oe_header_id  out number,
    x_retorno       out varchar2
  ) is
  
  begin
    print_log('============================================================================');
    print_log('INICIO DO PROCESSO - DEVOLUCAO DE INSUMOS OM '|| to_char(sysdate,'DD/MM/YYYY HH24:MI:SS') );
    print_log('============================================================================');
    --INFORMAÇÕES DA DEVOLUCAO
    g_header_id := p_header_id;
    --
    print_log('Header_id:'||p_header_id);
    select ood.organization_id, ood.organization_code 
    into l_organization_id, l_organization_code  
    from 
      XXFR_DEV_SIMB_INSUMOS_HEADER h,
      org_organization_definitions ood 
    where 1=1
      and ood.organization_id = h.organization_id
      and header_id           = p_header_id
    ;
    --
    
    initialize_opm; 
    
    if (ok = false) then 
      x_retorno      := 'E';
      goto FIM; 
    end if;
    
    begin   
      select 
        organization_id, inventory_item_id, id_cliente, tp_os_industrializacao, lista_precos_om, condicao_pagamento, quantity, uom_code, status
      into
        l_organization_id, 
        l_inventory_item_id, 
        l_cust_acct_site_id,
        l_order_type_id, 
        l_lista_precos_om, 
        l_condicao_pagamento, 
        l_ordered_quantity, 
        l_uom_code, 
        l_status
      from XXFR_OPM_VW_DEV_SIMB_INSUMOS_H
      where header_id = p_header_id;
    exception 
      when no_data_found then
        grava_erro(p_header_id,'OM','Nenhum registro encontrado');
        x_retorno := 'E';
        goto FIM;
      when too_many_rows then
        grava_erro(p_header_id,'OM','Registros duplicados');
        x_retorno := 'E';
        goto FIM;
      when others then
        grava_erro(p_header_id,'OM','Erro não previsto:'||sqlerrm);
        x_retorno := 'E';
        goto FIM;
    end;
    --
    xxfr_pck_variaveis_ambiente.inicializar('ONT','UO_FRISIA');  
    --
    -- Header Record --
    v_header_rec                        := oe_order_pub.g_miss_header_rec;
    v_header_rec.operation              := oe_globals.g_opr_create;
    v_header_rec.order_type_id          := l_order_type_id;
    --
    v_header_rec.sold_from_org_id       := fnd_profile.value('ORG_ID');
    
    --RECUPERA LISTA DE PREÇOS
    print_log('  Recurepando lista de preços...');
    begin
      select price_list_id into l_price_list_id 
      from oe_price_lists 
      where name = l_lista_precos_om
      ;
    exception 
      when no_data_found then
        grava_erro(p_header_id,'OM','Nenhum Lista de Preços encontrada');
        x_retorno := 'E';
        goto FIM;
      when too_many_rows then
        grava_erro(p_header_id,'OM','Lista de Preços duplicadas');
        x_retorno := 'E';
        goto FIM;
      when others then
        grava_erro(p_header_id,'OM','Lista de Preços - Erro não previsto:'||sqlerrm);
        x_retorno := 'E';
        goto FIM;
    end;
    
    --ENDEREÇOS DE FATURAMENTO E ENTREGA
    print_log('  Recurepando Endereço de Faturamento e Entrega...');
    begin
      select hcas.cust_account_id, hcsu.site_use_id, hcsu.bill_to_site_use_id
      into l_sold_to_org_id, l_ship_to_org_id, l_invoice_to_org_id 
      from 
        hz_cust_accounts              hca,
        hz_cust_acct_sites_all        hcas,
        hz_cust_site_uses_all         hcsu
      where 1=1
        and hcas.cust_account_id    = hca.cust_account_id
        and hcsu.cust_acct_site_id  = hcas.cust_acct_site_id
        and hcsu.site_use_code      = 'SHIP_TO'
        and hcas.cust_acct_site_id  = l_cust_acct_site_id
      ;
    exception 
      when no_data_found then
        grava_erro(p_header_id,'OM','Endereços de Fat e Entrega, não encontrados');
        x_retorno := 'E';
        goto FIM;
      when too_many_rows then
        grava_erro(p_header_id,'OM','Endereços de Fat e Entrega duplicados');
        x_retorno := 'E';
        goto FIM;
      when others then
        grava_erro(p_header_id,'OM','Endereços de Fat e Entrega - Erro não previsto:'||sqlerrm);
        x_retorno := 'E';
        goto FIM;
    end;

    --CONDIÇÃO DE PAGAMENTO
    print_log('  Recurepando Condição de Pagamento...');
    begin
      select term_id into l_term_id
      from ra_terms
      where 1=1
        and end_date_active is null
        and name = l_condicao_pagamento   
      ;
    exception 
      when no_data_found then
        grava_erro(p_header_id,'OM','Condição de pagamento, não encontrado');
        x_retorno := 'E';
        goto FIM;
      when too_many_rows then
        grava_erro(p_header_id,'OM','Condição de pagamento duplicado');
        x_retorno := 'E';
        goto FIM;
      when others then
        grava_erro(p_header_id,'OM','Condição de pagamento - Erro não previsto:'||sqlerrm);
        x_retorno := 'E';
        goto FIM;
    end;
    
    v_header_rec.sold_to_org_id         := l_sold_to_org_id;
    v_header_rec.ship_to_org_id         := l_ship_to_org_id;
    v_header_rec.invoice_to_org_id      := l_invoice_to_org_id;
    --
    v_header_rec.order_source_id        := 0;
    v_header_rec.booked_flag            := 'Y';
    v_header_rec.price_list_id          := l_price_list_id;
    v_header_rec.pricing_date           := sysdate;
    v_header_rec.flow_status_code       := 'ENTERED';
    v_header_rec.payment_term_id        := l_term_id;
    --v_header_rec.cust_po_number         := '99478222532';
    v_header_rec.salesrep_id            := -3;
    v_header_rec.transactional_curr_code:= 'BRL';
    
    v_action_request_tbl (1) := oe_order_pub.g_miss_request_rec;
    -- Line Record --
    v_line_tbl (1)                      := oe_order_pub.g_miss_line_rec;
    v_line_tbl (1).operation            := oe_globals.g_opr_create;
    v_line_tbl (1).inventory_item_id    := l_inventory_item_id;
    v_line_tbl (1).ordered_quantity     := l_ordered_quantity;
    v_line_tbl (1).payment_term_id      := l_term_id;
    v_line_tbl (1).unit_selling_price   := 1;
    v_line_tbl (1).calculate_price_flag := 'Y';
    
    print_log('  Chamando OE_ORDER_PUB.PROCESS_ORDER...');
    -- Calling the API to create an Order --
    savepoint PROCESSA_OM;
    fnd_msg_pub.initialize;
    oe_msg_pub.initialize;
    oe_order_pub.process_order (
      p_api_version_number           => v_api_version_number
      ,p_header_rec                  => v_header_rec
      ,p_line_tbl                    => v_line_tbl
      ,p_action_request_tbl          => v_action_request_tbl
      ,p_line_adj_tbl                => v_line_adj_tbl
      -- OUT variables
      ,x_header_rec                  => v_header_rec_out
      ,x_header_val_rec              => v_header_val_rec_out
      ,x_header_adj_tbl              => v_header_adj_tbl_out
      ,x_header_adj_val_tbl          => v_header_adj_val_tbl_out
      ,x_header_price_att_tbl        => v_header_price_att_tbl_out
      ,x_header_adj_att_tbl          => v_header_adj_att_tbl_out
      ,x_header_adj_assoc_tbl        => v_header_adj_assoc_tbl_out
      ,x_header_scredit_tbl          => v_header_scredit_tbl_out
      ,x_header_scredit_val_tbl      => v_header_scredit_val_tbl_out
      ,x_line_tbl                    => v_line_tbl_out
      ,x_line_val_tbl                => v_line_val_tbl_out
      ,x_line_adj_tbl                => v_line_adj_tbl_out
      ,x_line_adj_val_tbl            => v_line_adj_val_tbl_out
      ,x_line_price_att_tbl          => v_line_price_att_tbl_out
      ,x_line_adj_att_tbl            => v_line_adj_att_tbl_out
      ,x_line_adj_assoc_tbl          => v_line_adj_assoc_tbl_out
      ,x_line_scredit_tbl            => v_line_scredit_tbl_out
      ,x_line_scredit_val_tbl        => v_line_scredit_val_tbl_out
      ,x_lot_serial_tbl              => v_lot_serial_tbl_out
      ,x_lot_serial_val_tbl          => v_lot_serial_val_tbl_out
      ,x_action_request_tbl          => v_action_request_tbl_out
      ,x_return_status               => v_return_status
      ,x_msg_count                   => v_msg_count
      ,x_msg_data                    => v_msg_data
    );
    print_log('  Retorno:'||v_return_status);
    if v_return_status = fnd_api.g_ret_sts_success then
      print_log ('  Order Import Success Header_id: '||v_header_rec_out.header_id);
      x_retorno      := 'S';
      x_oe_header_id := v_header_rec_out.header_id;
      --
      update XXFR_DEV_SIMB_INSUMOS_HEADER
      set
        oe_header_id = x_oe_header_id
      where header_id = p_header_id;
      --
      goto FIM;
    else
      print_log ('  Order Import failed:'||v_msg_data);
      rollback to PROCESSA_OM;
      for i in 1 .. v_msg_count loop
        v_msg_data := oe_msg_pub.get( p_msg_index => i, p_encoded => 'F');
        print_log( '  '||i|| ') '|| v_msg_data);
        grava_erro(p_header_id,'OM',v_msg_data);
      end loop;
    end if;
    <<FIM>>
    print_log('============================================================================');
    print_log('FIM DO PROCESSO - DEVOLUCAO DE INSUMOS OM '|| to_char(sysdate,'DD/MM/YYYY HH24:MI:SS') );
    print_log('============================================================================');
    print_log('');
    commit;
  end;
  
end XXFR_OM_PCK_DEV_SIMB_INSUMOS;
/