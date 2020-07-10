create or replace package XXFR_OM_PKG_DEVOLUCAO_SACARIA is
  procedure main(p_trip_id in number);
end;
/

create or replace package body XXFR_OM_PKG_DEVOLUCAO_SACARIA is
-- +==========================================================================+
-- | Package para criar e manter itens do OM para integrações e processos custom.     
-- |                                                                 
-- |                                                                 
-- | CRIADO POR              DATA                  REF                                          
-- |   DANIEL PIMENTA      02/06/2020              OM05    
-- |                                                                 
-- | ALTERADO POR            DATA                  REF                        
-- |   [Nome]                [dd/mm/yyyy]          [ticket#]     
-- |      [comentários sobre a alteração]         
-- |                                  
-- +==========================================================================+


  g_escopo                        varchar2(150);
  v_api_version_number            number  := 1;
  v_return_status                 varchar2 (2000);
  v_msg_count                     number;
  v_msg_data                      varchar2 (2000);
  
  -- IN Variables --
  v_header_rec                    oe_order_pub.header_rec_type;
  v_line_tbl                      oe_order_pub.line_tbl_type;
  v_action_request_tbl            oe_order_pub.request_tbl_type;
  v_line_adj_tbl                  oe_order_pub.line_adj_tbl_type;
  
  -- OUT Variables --
  v_header_rec_out                oe_order_pub.header_rec_type;
  v_header_val_rec_out            oe_order_pub.header_val_rec_type;
  v_header_adj_tbl_out            oe_order_pub.header_adj_tbl_type;
  v_header_adj_val_tbl_out        oe_order_pub.header_adj_val_tbl_type;
  v_header_price_att_tbl_out      oe_order_pub.header_price_att_tbl_type;
  v_header_adj_att_tbl_out        oe_order_pub.header_adj_att_tbl_type;
  v_header_adj_assoc_tbl_out      oe_order_pub.header_adj_assoc_tbl_type;
  v_header_scredit_tbl_out        oe_order_pub.header_scredit_tbl_type;
  v_header_scredit_val_tbl_out    oe_order_pub.header_scredit_val_tbl_type;
  v_line_tbl_out                  oe_order_pub.line_tbl_type;
  v_line_val_tbl_out              oe_order_pub.line_val_tbl_type;
  v_line_adj_tbl_out              oe_order_pub.line_adj_tbl_type;
  v_line_adj_val_tbl_out          oe_order_pub.line_adj_val_tbl_type;
  v_line_price_att_tbl_out        oe_order_pub.line_price_att_tbl_type;
  v_line_adj_att_tbl_out          oe_order_pub.line_adj_att_tbl_type;
  v_line_adj_assoc_tbl_out        oe_order_pub.line_adj_assoc_tbl_type;
  v_line_scredit_tbl_out          oe_order_pub.line_scredit_tbl_type;
  v_line_scredit_val_tbl_out      oe_order_pub.line_scredit_val_tbl_type;
  v_lot_serial_tbl_out            oe_order_pub.lot_serial_tbl_type;
  v_lot_serial_val_tbl_out        oe_order_pub.lot_serial_val_tbl_type;
  v_action_request_tbl_out        oe_order_pub.request_tbl_type;
  
  v_msg_index                     number;
  v_data                          varchar2 (2000);
  v_loop_count                    number;
  v_debug_file                    varchar2 (200);
  b_return_status                 varchar2 (200);
  b_msg_count                     number;
  b_msg_data                      varchar2 (2000);
  --
  l_organization_id               number;
  l_sacaria_item                  number; 
  l_sacaria_qtd                   number; 
  l_sacaria_cliente_remessa       number;
  l_sacaria_endereco              number;
  --
  l_segment1                      varchar2(15);
  l_description                   varchar2(150);
  l_primary_uom_code              varchar2(15);
  l_list_price_per_unit           number;
  l_oe_header                     number;
  l_transaction_type_id           number;
  
  
  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => replace(msg,CHR(0),' '),
			p_escopo   => g_escopo
    );
  end;
  
  procedure main(p_trip_id in number) is
    l_qtd   number;
  begin
    g_escopo := 'DEVOLUCAO_SACARIA_'||p_trip_id;
    print_log('----------------------------------------------------------------');
    print_log('INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS'));
    print_log('----------------------------------------------------------------');    
    
    fnd_msg_pub.initialize;
    oe_msg_pub.initialize;
    
    print_log('Resgatando Informações do PERCURSO:'||p_trip_id);
    begin
      select distinct organization_id, oe_header, sacaria_item, sacaria_qtd, sacaria_cliente_remessa, sacaria_endereco 
      into l_organization_id, l_oe_header, l_sacaria_item, l_sacaria_qtd, l_sacaria_cliente_remessa, l_sacaria_endereco
      from xxfr_wsh_vw_inf_da_ordem_venda 
      where trip_id = p_trip_id
      ;
    exception when others then
      print_log('** ERRO:'||sqlerrm); 
      goto FIM;
    end;
    print_log('  Oranization id      :'||l_organization_id);
    print_log('  OE Header Id        :'||l_oe_header);
    print_log('  Invetory Item Id    :'||l_sacaria_item); 
    print_log('  Quatidade           :'||l_sacaria_qtd);
    print_log('  Customer Id         :'||l_sacaria_cliente_remessa); 
    print_log('  Customer Site Use Id:'||l_sacaria_endereco);
    
    select count(*) into l_qtd
    from oe_order_lines_all 
    WHERE 1=1
      and HEADER_ID = l_oe_header
      and inventory_item_id = l_sacaria_item
    ;
    if (l_qtd > 0) then
      print_log('** JA EXISTE UMA LINHA DE DEVOLUÇÃO CRIADA !!!');
      goto FIM;
    end if;
    
    print_log('Resgatando Informações do ITEM:');
    begin
      select segment1, description, primary_uom_code, list_price_per_unit
      into l_segment1, l_description, l_primary_uom_code, l_list_price_per_unit
      from mtl_system_items_b
      where 1=1
        and inventory_item_id = l_sacaria_item
        and organization_id   = l_organization_id
      ;
    exception when others then
      print_log('** ERRO:'||sqlerrm); 
      goto FIM;
    end;
    print_log('  Cod Item            :'||l_segment1);
    print_log('  Descricao           :'||l_description);
    print_log('  Unidade Medida      :'||l_primary_uom_code);
    print_log('  Preço Unitario      :'||l_list_price_per_unit);
    
    print_log('Resgatando Informações da TRANSACAO:');
    begin
      select distinct transaction_type_id
      into l_transaction_type_id
      from oe_transaction_types_all
      where 1=1
        and attribute1                          = 'REMESSA EMBALAGEM'
        and transaction_type_code               = 'LINE'
        and nvl(warehouse_id,l_organization_id) = l_organization_id
      ;
    exception when others then
      print_log('** ERRO:'||sqlerrm); 
      goto FIM;
    end;
    print_log('  Transaction Type Id :'||l_transaction_type_id);
    print_log('  Descricao           :REMESSA EMBALAGEM');
    
    v_action_request_tbl (1) := oe_order_pub.g_miss_request_rec;
    -- Line Record --
    v_line_tbl (1)                      := oe_order_pub.g_miss_line_rec;
    
    v_line_tbl (1).operation            := oe_globals.g_opr_create;
    v_line_tbl (1).header_id            := l_oe_header;
    --v_line_tbl (1).line_id              := 141575;
  
    v_line_tbl (1).inventory_item_id        := l_sacaria_item; 
    v_line_tbl (1).line_type_id             := l_transaction_type_id;
    v_line_tbl (1).ordered_quantity         := l_sacaria_qtd;
    v_line_tbl (1).order_quantity_uom       := l_primary_uom_code;
    v_line_tbl (1).unit_selling_price       := l_list_price_per_unit;
    v_line_tbl (1).unit_list_price          := l_list_price_per_unit;
    v_line_tbl (1).calculate_price_flag     := 'Y';
    v_line_tbl (1).end_customer_id          := l_sacaria_cliente_remessa; 
    v_line_tbl (1).end_customer_site_use_id := l_sacaria_endereco;
  
    print_log('Chamando OE_ORDER_PUB.PROCESS_ORDER...');
    --execute immediate 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
    
    oe_order_pub.process_order (
      p_api_version_number            => v_api_version_number
      , p_header_rec                  => v_header_rec
      , p_line_tbl                    => v_line_tbl
      , p_action_request_tbl          => v_action_request_tbl
      , p_line_adj_tbl                => v_line_adj_tbl
      -- OUT variables
      , x_header_rec                  => v_header_rec_out
      , x_header_val_rec              => v_header_val_rec_out
      , x_header_adj_tbl              => v_header_adj_tbl_out
      , x_header_adj_val_tbl          => v_header_adj_val_tbl_out
      , x_header_price_att_tbl        => v_header_price_att_tbl_out
      , x_header_adj_att_tbl          => v_header_adj_att_tbl_out
      , x_header_adj_assoc_tbl        => v_header_adj_assoc_tbl_out
      , x_header_scredit_tbl          => v_header_scredit_tbl_out
      , x_header_scredit_val_tbl      => v_header_scredit_val_tbl_out
      , x_line_tbl                    => v_line_tbl_out
      , x_line_val_tbl                => v_line_val_tbl_out
      , x_line_adj_tbl                => v_line_adj_tbl_out
      , x_line_adj_val_tbl            => v_line_adj_val_tbl_out
      , x_line_price_att_tbl          => v_line_price_att_tbl_out
      , x_line_adj_att_tbl            => v_line_adj_att_tbl_out
      , x_line_adj_assoc_tbl          => v_line_adj_assoc_tbl_out
      , x_line_scredit_tbl            => v_line_scredit_tbl_out
      , x_line_scredit_val_tbl        => v_line_scredit_val_tbl_out
      , x_lot_serial_tbl              => v_lot_serial_tbl_out
      , x_lot_serial_val_tbl          => v_lot_serial_val_tbl_out
      , x_action_request_tbl          => v_action_request_tbl_out
      , x_return_status               => v_return_status
      , x_msg_count                   => v_msg_count
      , x_msg_data                    => v_msg_data
    );
    --
    print_log('Retorno:'||v_return_status);
    if (v_return_status <> 'S') then
      for i in 1 .. v_msg_count loop
        --v_msg_data := fnd_msg_pub.get(p_msg_index => i, p_encoded   => 'F');
        v_msg_data := oe_msg_pub.get(p_msg_index => i, p_encoded   => 'F');
        print_log(i|| ') '|| v_msg_data);
      end loop;
    end if;
    --
    if v_return_status = fnd_api.g_ret_sts_success then
      --COMMIT;
      null;
    else
      --ROLLBACK;
      null;
    end if;
    <<FIM>>
    print_log('----------------------------------------------------------------');
    print_log('FIM INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS'));
    print_log('----------------------------------------------------------------');
  end;

end;
/
