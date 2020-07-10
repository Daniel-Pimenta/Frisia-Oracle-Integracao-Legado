create or replace package body XXFR_OM_PCK_ORDEM_VENDA_UDA as 

  -- Criado por : Daniel Pimenta
  -- Data       : 15/06/20207
  --
  -- ************************************************************************************************
  -- Código criado com base em: 
  --   How to Create or Update User Defined Attributes for Sales Orders at Header or Line Level using 
  --   EGO_USER_ATTRS_DATA_PUB.Process_User_Attrs_Data ? (Doc ID 2109089.1)
  --   https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=370046490407231&id=2109089.1&_afrWindowMode=0&_adf.ctrl-state=fulbxvwqv_53
  --
  
  --Global
  g_attributes_data_table		      ego_user_attr_data_table      := ego_user_attr_data_table();

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line (msg);
  end;
  
  procedure initialize is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('ONT', 'UO_FRISIA' ); 
  end;
  
  procedure add_attribute(
    p_row_id                    in number,
    p_att_name                  in varchar2,
    p_att_val                   in varchar2,
    p_row_cnt                   in number
  ) is
  
  begin
    g_attributes_data_table.extend;
    g_attributes_data_table(p_row_cnt) := ego_user_attr_data_obj (
      p_row_id	      	    -- ROW_IDENTIFIER from above
      ,p_att_name	          -- ATTR_NAME
      ,null				          -- ATTR_VALUE_STR
      ,null				          -- ATTR_VALUE_NUM
      ,null				          -- ATTR_VALUE_DATE
      ,p_att_val      	    -- ATTR_DISP_VALUE
      ,null			      	    -- ATTR_UNIT_OF_MEASURE
      ,p_row_cnt		  	    -- USER_ROW_IDENTIFIER
    ); 
  end;

  procedure process_om_line_uda(
    p_from_oe_line_id in number,
    p_to_oe_line_id   in number,
    x_retorno         out varchar2
  ) is
  
    l_api_version		  	            number := 1;

    l_attributes_row_table		      ego_user_attr_row_table       := ego_user_attr_row_table();
    l_attributes_data_table         ego_user_attr_data_table      := ego_user_attr_data_table();
    --
    l_attr_group_request_table      ego_attr_group_request_table  := ego_attr_group_request_table();
    --
    l_pk_column_name_value_pairs	  ego_col_name_value_pair_array := ego_col_name_value_pair_array();
    l_class_code_name_value_pairs	  ego_col_name_value_pair_array := ego_col_name_value_pair_array();
    l_user_privileges_on_object	    ego_varchar_tbl_type          := null;
    
    l_entity_id		          	      number      := null;
    l_entity_index			            number      := null;
    l_entity_code		  	            varchar2(1) := null;
    l_debug_level		        	      number      := 3;
    --
    l_init_error_handler	  	      varchar2(1) := fnd_api.g_true;
    l_write_to_concurrent_log	      varchar2(1) := fnd_api.g_true;
    l_init_fnd_msg_list		          varchar2(1) := fnd_api.g_true;
    l_log_errors		        	      varchar2(1) := fnd_api.g_true;
    l_add_errors_to_fnd_stack	      varchar2(1) := fnd_api.g_false;
    l_commit			                  varchar2(1) := fnd_api.g_false;   -- Do NOT set to TRUE, Verify the data and then COMMIT !
    --
    x_failed_row_id_list	  	      varchar2(3000);
    x_return_status			            varchar2(10);
    x_errorcode			                number;
    x_msg_count			                number;
    x_msg_data			                varchar2(3000);
    x_message_list                  error_handler.error_tbl_type;
            
    l_data_level                    varchar2(100) := 'ORDER_LINE';
    l_object_name	     	            varchar2(100) := 'OE_ORDER_LINES_ALL';
    l_attr_group_name               varchar2(100) := 'REFERENCIA_LINHA_ORDEM_VENDA';   
    l_attr_group_type               varchar2(100) := 'OE_LINE_ATTRIBUTES_EXT'; 
    l_attr_group_id                 number;
    l_attr_group_app_id             number; 
    --
    l_attr_int_names_list           VARCHAR2(3000);
    --  
    l_numero_ordem                  varchar2(50); 
    l_linha                         varchar2(50);
    l_envio                         varchar2(50);
    l_tipo_ordem                    varchar2(50);
    
    l_rowcnt        	      	      number;
    l_qtd                           number;
    
    rt                              number;
    dt                              number;
  
  begin
    print_log('XXFR_OM_PCK_ORDEM_VENDA_UDA.PROCESS_OM_LINE_UDA');
    initialize;
    
    -- Testa os parametros de entrada.
    select count(*) into l_qtd from oe_order_lines_all
    where line_id in (p_from_oe_line_id, p_to_oe_line_id);
    if l_qtd <> 2 then
      x_retorno := 'Uma das linhas informadas não foi encontrada';
      print_log(x_retorno);
      goto fim;
    end if;
    
    --Recupera as Informações da Linha Pai (1).    
    select distinct numero_ordem, linha, envio, tipo_ordem
    into l_numero_ordem, l_linha, l_envio, l_tipo_ordem
    from xxfr_wsh_vw_inf_da_ordem_venda
    where oe_line = p_from_oe_line_id;
    
    print_log('  OE Line Id(1)       :'||p_from_oe_line_id);
    print_log('  OE Line Id(2)       :'||p_to_oe_line_id);
    print_log('  Attribute Group Name:'||l_attr_group_name);
    
    -- Get the Attribute Group Identifiers
    select attr_group_id, application_id
    into l_attr_group_id, l_attr_group_app_id
    from ego_attr_groups_v
    where attr_group_name = l_attr_group_name;
    
    print_log('  App Attrib Group ID :'||l_attr_group_app_id);
    print_log('  Attrib Group ID     :'||l_attr_group_id);
 
    l_pk_column_name_value_pairs.extend(1);
    l_pk_column_name_value_pairs(1) := ego_col_name_value_pair_obj('LINE_ID', p_from_oe_line_id);  
    l_pk_column_name_value_pairs.extend(2);
    l_pk_column_name_value_pairs(2) := ego_col_name_value_pair_obj('LINE_ID', p_to_oe_line_id); 
       
    l_class_code_name_value_pairs.extend(1);
    l_class_code_name_value_pairs(1) := ego_col_name_value_pair_obj('ENTITY', 'ADMIN_DEFINED');
    l_class_code_name_value_pairs.extend(2);
    l_class_code_name_value_pairs(2) := ego_col_name_value_pair_obj('ENTITY', 'ADMIN_DEFINED');

    
    for r1 in (select attr_name from ego_attrs_v where attr_group_name = l_attr_group_name) loop
      l_attr_int_names_list := l_attr_int_names_list || r1.attr_name || ',' ;            
    end loop;
    print_log('  Attributes found    :'||l_attr_int_names_list);
    
    print_log('');
    print_log('  Chamando EGO_USER_ATTRS_DATA_PUB.BUILD_ATTR_GROUP_REQUEST_TABLE...');
    l_attr_group_request_table := EGO_USER_ATTRS_DATA_PUB.Build_Attr_Group_Request_Table(
      p_ag_req_table         => l_attr_group_request_table,
      p_attr_group_id        => l_attr_group_id,
      p_application_id       => l_attr_group_app_id,
      p_attr_group_type      => l_attr_group_type,
      p_attr_group_name      => l_attr_group_name,
      p_data_level           => l_data_level, --'ITEM_ORG' --'ITEM_LEVEL'   -- 12.1.1 and above
      p_data_level_1         => NULL,
      p_data_level_2         => NULL,
      p_data_level_3         => NULL,
      p_data_level_4         => NULL,
      p_data_level_5         => NULL,
      p_attr_name_list       => l_attr_int_names_list
    );
    
    print_log('');
    print_log('  Chamando EGO_USER_ATTRS_DATA_PUB.GET_USER_ATTRS_DATA...');
    EGO_USER_ATTRS_DATA_PUB.GET_USER_ATTRS_DATA(
      p_api_version                   => l_api_version,
      p_object_name                   => l_object_name,
      p_pk_column_name_value_pairs    => l_pk_column_name_value_pairs,
      p_attr_group_request_table      => l_attr_group_request_table,
      p_user_privileges_on_object     => l_user_privileges_on_object,
      --
      p_entity_id                     => null,
      p_entity_index                  => null,
      p_entity_code                   => null,
      --
      p_debug_level                   => l_debug_level,
      p_init_error_handler            => l_init_error_handler,
      p_init_fnd_msg_list             => l_init_fnd_msg_list,
      p_add_errors_to_fnd_stack       => l_add_errors_to_fnd_stack,
      p_commit                        => l_commit,
      --
      x_attributes_row_table          => l_attributes_row_table,
      x_attributes_data_table         => l_attributes_data_table,
      x_return_status                 => x_return_status,
      x_errorcode                     => x_errorcode,
      x_msg_count                     => x_msg_count,
      x_msg_data                      => x_msg_data
    );
    print_log('  Return Status       :'||x_return_status);
    if (x_return_status <> 'S') then
      print_log('  Message Data        :'||x_msg_data);
      print_log('  Error Code          :'||x_errorcode);
      print_log('  Msg Count           :'||x_msg_count);
      print_log('  Fnd Msg Count       :'||fnd_msg_pub.count_msg);
      goto FIM;
    end if;
    print_log('  Attrib Row Table    :'||l_attributes_row_table.count);
    print_log('  Attrib Data Table   :'||l_attributes_data_table.count);
    
    FOR rt IN l_attributes_row_table.FIRST .. l_attributes_row_table.LAST LOOP
      print_log('  ['||rt||']');
      print_log('  ATTR_GROUP_ID  :'||l_attributes_row_table(rt).ATTR_GROUP_ID);
      print_log('  ATTR_GROUP_TYPE:'||l_attributes_row_table(rt).ATTR_GROUP_TYPE);
      print_log('  ATTR_GROUP_NAME:'||l_attributes_row_table(rt).ATTR_GROUP_NAME);
      print_log('  DATA_LEVEL     :'||l_attributes_row_table(rt).DATA_LEVEL);
      
      FOR dt IN l_attributes_data_table.FIRST..l_attributes_data_table.LAST LOOP
        print_log('    ['||dt||']');
        IF l_attributes_row_table(rt).ROW_IDENTIFIER = l_attributes_data_table(dt).ROW_IDENTIFIER THEN          
          print_log('    ATTR_NAME      :'||l_attributes_data_table(dt).ATTR_NAME);
          print_log('    ATTR_DISP_VALUE:'||l_attributes_data_table(dt).ATTR_DISP_VALUE);
        END IF;                       
      END LOOP;
      print_log ('');
    END LOOP;
    
    
    /*
    -- Add in the attribute groups here, multirow attribute groups should have the same attr_group_id
    -- transaction_type can be CREATE | UPDATE | SYNC  
    begin
    l_attributes_row_table := ego_user_attr_row_table (
      ego_user_attr_row_obj(
        9999							      -- ROW_IDENTIFIER
        ,null                   -- ATTR_GROUP_ID from EGO_ATTR_GROUPS_V 
        ,l_attr_group_app_id    -- ATTR_GROUP_APP_ID
        ,l_attr_group_type			-- ATTR_GROUP_TYPE
        ,l_attr_group_name			-- ATTR_GROUP_NAME
        ,l_data_level           -- NDATA_LEVEL
        ,null		                -- DATA_LEVEL_1       (Required if attribute groups are at revision level)
        ,null		                -- DATA_LEVEL_2
        ,null		                -- DATA_LEVEL_3
        ,null		                -- DATA_LEVEL_4
        ,null		                -- DATA_LEVEL_5
        ,ego_user_attrs_data_pvt.g_sync_mode			-- TRANSACTION_TYPE
      )
    );
    exception when others then
      x_retorno := 'Erro não previsto {ROW_TABLE]:'||sqlerrm;
      print_log(x_retorno);
      goto FIM;
    end;
    
    -- Add the attribute - attribute values here, for the attr groups above
    -- row_identifier is the foriegn key from the attribute group defined above
    -- user_row_identifier is used for error handling
    l_rowcnt := 1;
    add_attribute(9999,'NUMERO_ORDEM_VENDA',l_numero_ordem,l_rowcnt);
    l_rowcnt  := l_rowcnt + 1;
    add_attribute(9999,'NUMERO_LINHA'      ,l_linha       ,l_rowcnt);
    l_rowcnt  := l_rowcnt + 1;
    add_attribute(9999,'NUMERO_ENTREGA'    ,l_envio       ,l_rowcnt);
    l_rowcnt  := l_rowcnt + 1;
    add_attribute(9999,'TIPO_ORDEM_VENDA'  ,l_tipo_ordem  ,l_rowcnt);

    print_log('Chamando EGO_USER_ATTRS_DATA_PUB.PROCESS_USER_ATTRS_DATA...');        
    ego_user_attrs_data_pub.process_user_attrs_data(
      l_api_version
      , l_object_name
      , l_attributes_row_table
      , g_attributes_data_table
      , l_pk_column_name_value_pairs
      , l_class_code_name_value_pairs
      , l_user_privileges_on_object
      , l_entity_id
      , l_entity_index
      , l_entity_code
      , l_debug_level
      , l_init_error_handler
      , l_write_to_concurrent_log
      , l_init_fnd_msg_list
      , l_log_errors
      , l_add_errors_to_fnd_stack
      , l_commit
      , x_failed_row_id_list
      , x_return_status
      , x_errorcode
      , x_msg_count
      , x_msg_data
    );
    print_log('  Retorno: '||x_return_status);
    x_retorno := x_return_status;
    */
    
    <<FIM>>
    if (x_retorno <> fnd_api.g_ret_sts_success) then
      x_retorno := '';
      error_handler.get_message_list(x_message_list => x_message_list);
      for i in 1 .. x_message_list.count loop
        print_log('  '||x_message_list(i).message_text);
        x_retorno := x_retorno || x_message_list(i).message_text;
      end loop;
    end if;   
    
    print_log('FIM XXFR_OM_PCK_ORDEM_VENDA_UDA.PROCESS_OM_LINE_UDA');
  exception when others then
    x_retorno := '  ** Erro não previsto:'||sqlerrm;
    print_log(x_retorno);
  end process_om_line_uda;

end xxfr_om_pck_ordem_venda_uda;