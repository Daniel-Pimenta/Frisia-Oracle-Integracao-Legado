create or replace package body XXFR_OM_PCK_ORDEM_VENDA_UDA is
 
  -- Criado por : Daniel Pimenta
  -- Data       : 15/06/20207
  --
  -- ************************************************************************************************
  -- Código criado com base em: 
  --   How to Create or Update User Defined Attributes for Sales Orders at Header or Line Level using EGO_USER_ATTRS_DATA_PUB.Process_User_Attrs_Data ? (Doc ID 2109089.1)
  --   https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=370046490407231&id=2109089.1&_afrWindowMode=0&_adf.ctrl-state=fulbxvwqv_53
  --
  --   How to Copy User Defined Attributes Using EGO_USER_ATTRS_DATA_PUB (Product Hub) APIs ? (Doc ID 2426860.1)
  --   https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=396077468652903&id=2426860.1&_afrWindowMode=0&_adf.ctrl-state=v1lqmd1od_4
  --
 
  g_escopo                varchar2(300);
  l_attributes_row_table  EGO_USER_ATTR_ROW_TABLE;
  l_attributes_data_table EGO_USER_ATTR_DATA_TABLE; 
  
  l_data_level            varchar2(100) := 'ORDER_LINE';
  l_object_name	     	    varchar2(100) := 'OE_ORDER_LINES_ALL';
  l_attr_group_name       varchar2(100) := 'REFERENCIA_LINHA_ORDEM_VENDA';   
  l_attr_group_type       varchar2(100) := 'OE_LINE_ATTRIBUTES_EXT'; 
  
  l_return_status         varchar2(10);
  l_errorcode		          number;
  l_msg_count		          number;
  l_msg_data		          varchar2(255);
 
  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line (msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;
  
  procedure initialize is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('ONT', 'UO_FRISIA' ); 
  end;
 
  PROCEDURE GET_OM_LINE_UDA  (
    p_oe_line_id            IN  VARCHAR2,  
    --
    x_attributes_row_table  OUT EGO_USER_ATTR_ROW_TABLE, 
    x_attributes_data_table OUT EGO_USER_ATTR_DATA_TABLE, 
    x_return_status         OUT VARCHAR2, 
    x_errorcode             OUT NUMBER, 
    x_msg_count             OUT NUMBER, 
    x_msg_data              OUT VARCHAR2 
  )  AS
  
    l_api_version			              NUMBER                        := 1;
    l_pk_column_name_value_pairs	  EGO_COL_NAME_VALUE_PAIR_ARRAY := EGO_COL_NAME_VALUE_PAIR_ARRAY();
    l_attr_group_request_table      EGO_ATTR_GROUP_REQUEST_TABLE  := EGO_ATTR_GROUP_REQUEST_TABLE();
    l_user_privileges_on_object	    EGO_VARCHAR_TBL_TYPE          := NULL;
    l_entity_id			                NUMBER                        := NULL;
    l_entity_index			            NUMBER                        := NULL;
    l_entity_code			              VARCHAR2(1)                   := NULL;
    l_debug_level		        	      NUMBER                        := 3;
    l_init_error_handler	     	    VARCHAR2(1)                   := FND_API.G_TRUE;
    l_init_fnd_msg_list	  	        VARCHAR2(1)                   := FND_API.G_TRUE;
    l_add_errors_to_fnd_stack	      VARCHAR2(1)                   := FND_API.G_FALSE;
    l_commit			                  VARCHAR2(1)                   := FND_API.G_FALSE;   -- Do NOT set to TRUE, Verify the data and then COMMIT !
    
    --x_attributes_row_table		EGO_USER_ATTR_ROW_TABLE := EGO_USER_ATTR_ROW_TABLE();
    --x_attributes_data_table		EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
    --x_return_status		      	VARCHAR2(10);
    --x_errorcode		          	NUMBER;
    --x_msg_count		          	NUMBER;
    --x_msg_data		          	VARCHAR2(255);
    
    l_user_id		      	            NUMBER := -1;
    l_resp_id		      	            NUMBER := -1;
    l_application_id	         	    NUMBER := -1;
    
    l_inventory_item_id		          NUMBER := 0;
    l_organization_id		            NUMBER := 0;
    l_item_catalog_group_id		      NUMBER := 0;
    l_attr_group_id		      	      NUMBER := 0;
    
    l_attr_int_names_list           VARCHAR2(3000);
      
    CURSOR c1 IS
    SELECT attr_name FROM ego_attrs_v
    WHERE attr_group_name = l_attr_group_name;
  
  BEGIN
    print_log('GET_OM_LINE_UDA');
    -- Get the Attribute Group Identifiers
    SELECT attr_group_id INTO l_attr_group_id
    FROM ego_attr_groups_v
    WHERE attr_group_name = l_attr_group_name;
    print_log('Attribute Group ID: '||l_attr_group_id);
    
    FOR r1 IN c1 LOOP
      l_attr_int_names_list := l_attr_int_names_list || r1.attr_name || ',' ;            
    END LOOP;
    print_log('Attributes found: '||l_attr_int_names_list);
    
    /* Prior to 12.1.3 -- 
    l_attr_group_request_table :=
    EGO_ATTR_GROUP_REQUEST_TABLE(
      EGO_ATTR_GROUP_REQUEST_OBJ(
        l_attr_group_id,	    -- ATTR_GROUP_ID  from EGO_ATTR_GROUPS_V
        l_application_id,     -- APPLICATION_ID
        NULL,							    -- ATTR_GROUP_TYPE
        NULL,							    -- ATTR_GROUP_NAME
        NULL,							    -- DATA_LEVEL_1       
        NULL,							    -- DATA_LEVEL_2
        NULL,							    -- DATA_LEVEL_3
        l_attr_int_names_list	-- Attribute Internal Names
      )
    );
    */
    print_log('  Chamando EGO_USER_ATTRS_DATA_PUB.BUILD_ATTR_GROUP_REQUEST_TABLE...');
    l_attr_group_request_table := EGO_USER_ATTRS_DATA_PUB.BUILD_ATTR_GROUP_REQUEST_TABLE(
      p_ag_req_table          => l_attr_group_request_table
      ,p_attr_group_id        => l_attr_group_id
      ,p_application_id       => l_application_id
      ,p_attr_group_type      => NULL
      ,p_attr_group_name      => NULL
      ,p_data_level           => l_data_level --'ITEM_ORG' --'ITEM_LEVEL'   -- 12.1.1 and above
      ,p_data_level_1         => NULL
      ,p_data_level_2         => NULL
      ,p_data_level_3         => NULL
      ,p_data_level_4         => NULL
      ,p_data_level_5         => NULL
      ,p_attr_name_list       => l_attr_int_names_list
    );
    print_log('  Informando PK...');
    l_pk_column_name_value_pairs.EXTEND(1);
    l_pk_column_name_value_pairs(1) := EGO_COL_NAME_VALUE_PAIR_OBJ('LINE_ID', to_char(p_oe_line_id));
    
    -- call API to get user defined attributes
    print_log('  Chamando EGO_USER_ATTRS_DATA_PUB.GET_USER_ATTRS_DATA...');
    EGO_USER_ATTRS_DATA_PUB.GET_USER_ATTRS_DATA(
      l_api_version
      , l_object_name
      , l_pk_column_name_value_pairs
      , l_attr_group_request_table
      , l_user_privileges_on_object
      , l_entity_id
      , l_entity_index
      , l_entity_code
      , l_debug_level
      , l_init_error_handler
      , l_init_fnd_msg_list
      , l_add_errors_to_fnd_stack
      , l_commit
      , x_attributes_row_table
      , x_attributes_data_table
      , x_return_status
      , x_errorcode
      , x_msg_count
      , x_msg_data
    );
    -- Print all the attributes retrieved
    -- x_attributes_row_table  : Has the Attribute Group Details
    -- x_attributes_data_table : Has the Attribute Values for the specified Item
    /*
    FOR lin IN x_attributes_row_table.FIRST..x_attributes_row_table.LAST LOOP
      print_log('  Lin:'||lin);
      print_log('  Group Id  :'||x_attributes_row_table(lin).ATTR_GROUP_ID);
      print_log('  Group Type:'||x_attributes_row_table(lin).ATTR_GROUP_TYPE);
      print_log('  Group Name:'||x_attributes_row_table(lin).ATTR_GROUP_NAME);
      print_log('  Data Level:'||x_attributes_row_table(lin).DATA_LEVEL);
      FOR col IN x_attributes_data_table.FIRST..x_attributes_data_table.LAST LOOP
        IF x_attributes_row_table(lin).ROW_IDENTIFIER = x_attributes_data_table(col).ROW_IDENTIFIER THEN 
          print_log('    '||x_attributes_data_table(col).ATTR_NAME || ' : '|| x_attributes_data_table(col).ATTR_DISP_VALUE);
        END IF;                       
      END LOOP;
      print_log ('');
    END LOOP;
    */
    
    FOR k IN 1 .. fnd_msg_pub.count_msg LOOP
      x_msg_data := fnd_msg_pub.get (p_msg_index => k, p_encoded => 'F');
      print_log('  Error Msg: ' || x_msg_data);
    END LOOP;
    print_log('FIM GET_OM_LINE_UDA');
  EXCEPTION WHEN OTHERS THEN
    print_log('Exception occurred ! '||sqlerrm);  
    RAISE;
  END GET_OM_LINE_UDA;
 
  PROCEDURE PROCESS_OM_LINE_UDA (
    p_oe_line_id            in varchar2,
    p_attributes_row_table  in ego_user_attr_row_table,
    p_attributes_data_table in ego_user_attr_data_table,
    x_return_status         out varchar2
  ) as  
  
    l_api_version		  	          number        := 1; 
    l_attributes_row_table		    ego_user_attr_row_table       := ego_user_attr_row_table();
    l_attributes_data_table		    ego_user_attr_data_table      := ego_user_attr_data_table();
    l_pk_column_name_value_pairs	ego_col_name_value_pair_array := ego_col_name_value_pair_array();
    l_class_code_name_value_pairs	ego_col_name_value_pair_array := ego_col_name_value_pair_array();
    l_user_privileges_on_object	  ego_varchar_tbl_type          := null;
    l_entity_id		          	    number                        := null;
    l_entity_index			          number                        := null;
    l_entity_code		  	          varchar2(1)                   := null;
    l_debug_level		        	    number                        := 3;
    --
    l_init_error_handler	  	    varchar2(1) := fnd_api.g_true;
    l_write_to_concurrent_log	    varchar2(1) := fnd_api.g_true;
    l_init_fnd_msg_list		        varchar2(1) := fnd_api.g_true;
    l_log_errors		        	    varchar2(1) := fnd_api.g_true;
    l_add_errors_to_fnd_stack	    varchar2(1) := fnd_api.g_false;
    l_commit			                varchar2(1) := fnd_api.g_false;   -- Do NOT set to TRUE, Verify the data and then COMMIT !
    x_failed_row_id_list	     	  varchar2(255);
    --x_return_status			          varchar2(10);
    x_errorcode			              number;
    x_msg_count			              number;
    x_msg_data			              varchar2(255);
    x_message_list                error_handler.error_tbl_type;
    
    l_user_id			                number := -1;
    l_resp_id			                number := -1;
    l_application_id	         	  number := -1;
    l_attcnt        	      	    number := 1;
    l_cnt                         number := 1;
    
    l_inventory_item_id		        number := 0;
    l_organization_id	         	  number := 0;
    l_item_catalog_group_id		    number := 0;
    l_item_catalog_group_id2      number := 0;
    l_attr_group_type	         	  number := 0;
     
    
    p_attr_group_type             varchar2(100) := 'EGO_ITEMMGMT_GROUP';
    p_attr_group_app_id           number        := 431;
    
    l_catalog_category_s          varchar2(100); 
                    
  begin                       
    print_log('PROCESS_OM_LINE_UDA');
    
    
    l_pk_column_name_value_pairs.extend(1);
    l_pk_column_name_value_pairs(1) := ego_col_name_value_pair_obj('LINE_ID', to_char(p_oe_line_id));
  
    l_class_code_name_value_pairs.extend(1);
    l_class_code_name_value_pairs(1) := ego_col_name_value_pair_obj('ENTITY', 'ADMIN_DEFINED');
        
    -- Add in the attribute groups here, multirow attribute groups should have the same attr_group_id
    -- transaction_type can be CREATE | UPDATE | SYNC
    
    l_attributes_row_table  := p_attributes_row_table;
    l_attributes_data_table := p_attributes_data_table; 
    
    print_log('  Montando Row Table');
    for lin in l_attributes_row_table.first .. l_attributes_row_table.last loop
      l_attributes_row_table(l_cnt) := ego_user_attr_row_obj (
        l_attributes_row_table(lin).row_identifier,			    -- ROW_IDENTIFIER
        null,                                               -- ATTR_GROUP_ID from EGO_ATTR_GROUPS_V 
        l_attributes_row_table(lin).attr_group_app_id,      -- ATTR_GROUP_APP_ID
        l_attributes_row_table(lin).attr_group_type,				-- ATTR_GROUP_TYPE
        l_attributes_row_table(lin).attr_group_name,			  -- ATTR_GROUP_NAME
        l_attributes_row_table(lin).data_level,             -- DATA_LEVEL
        null,		-- DATA_LEVEL_1       (Required if attribute groups are at revision level)
        null,		-- DATA_LEVEL_2
        null,		-- DATA_LEVEL_3
        null,		-- DATA_LEVEL_4
        null,		-- DATA_LEVEL_5
        ego_user_attrs_data_pvt.g_sync_mode	-- TRANSACTION_TYPE
      );
      l_cnt :=  l_cnt + 1;
    end loop;
    
    -- call API to load UDA
    print_log('  Chamando EGO_USER_ATTRS_DATA_PUB.PROCESS_USER_ATTRS_DATA API...');        
    ego_user_attrs_data_pub.process_user_attrs_data(
      l_api_version,
      l_object_name,
      l_attributes_row_table,
      l_attributes_data_table,
      l_pk_column_name_value_pairs,
      l_class_code_name_value_pairs,
      l_user_privileges_on_object,
      l_entity_id,
      l_entity_index,
      l_entity_code,
      l_debug_level,
      l_init_error_handler,
      l_write_to_concurrent_log,
      l_init_fnd_msg_list,
      l_log_errors,
      l_add_errors_to_fnd_stack,
      l_commit,
      x_failed_row_id_list,
      x_return_status,
      x_errorcode,
      x_msg_count,
      x_msg_data
    );
    print_log('  Return Status: '||x_return_status);
    
    if (x_return_status <> fnd_api.g_ret_sts_success) then
      print_log('  Error Messages :');
      error_handler.get_message_list(x_message_list=>x_message_list);
      for i in 1..x_message_list.count loop
        print_log('    '||x_message_list(i).message_text);
      end loop;
    end if;
    print_log('FIM PROCESS_OM_LINE_UDA');
  exception when others then
    print_log('** Exception Occured :'||sqlerrm);
    x_return_status := 'E';
  end PROCESS_OM_LINE_UDA;
  
  procedure main (
    p_from_oe_line_id in number,
    p_to_oe_line_id   in number,
    p_escopo          in varchar2 default null,
    x_retorno         out varchar2
  ) is  
  begin
    g_escopo := nvl(p_escopo,'XXFR_OM_PCK_OE_UDA');
    
    get_om_line_uda(
      p_oe_line_id            => p_from_oe_line_id,  
      x_attributes_row_table  => l_attributes_row_table, 
      x_attributes_data_table => l_attributes_data_table, 
      x_return_status         => l_return_status, 
      x_errorcode             => l_errorcode, 
      x_msg_count             => l_msg_count, 
      x_msg_data              => l_msg_data
    );
    print_log('');
    if (l_return_status = 'S') then
      process_om_line_uda (
        p_oe_line_id            => p_to_oe_line_id,
        p_attributes_row_table  => l_attributes_row_table,
        p_attributes_data_table => l_attributes_data_table,
        x_return_status         => l_return_status
      );
    end if;  
    x_retorno := l_return_status;
  end;
  
end XXFR_OM_PCK_ORDEM_VENDA_UDA;
/



