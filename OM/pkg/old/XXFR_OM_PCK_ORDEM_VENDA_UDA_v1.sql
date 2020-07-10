create or replace PACKAGE BODY XXFR_OM_PCK_ORDEM_VENDA_UDA AS 
  -- Marcel Fabris 
  -- Código criado com base em: How to Copy User Defined Attributes Using EGO_USER_ATTRS_DATA_PUB (Product Hub) APIs ? (Doc ID 2426860.1)

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line (msg);
  end;
  
  procedure initialize is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('ONT', 'UO_FRISIA' ); 
  end;

  PROCEDURE GET_UDA  (
    p_oe_line_id            IN  VARCHAR2,
    p_organization_code     IN  VARCHAR2,
    p_attr_group_name       IN  VARCHAR2,
    p_data_level            in VARCHAR2,
    x_attributes_row_table  OUT EGO_USER_ATTR_ROW_TABLE,
    x_attributes_data_table OUT EGO_USER_ATTR_DATA_TABLE,
    x_return_status         OUT VARCHAR2,
    x_errorcode             OUT NUMBER,
    x_msg_count             OUT NUMBER,
    x_msg_data              OUT VARCHAR2 
  )  IS
  
    l_api_version			              NUMBER := 1;
    l_object_name		        	      VARCHAR2(30) := 'OE_ORDER_LINES_ALL';
    l_pk_column_name_value_pairs	  EGO_COL_NAME_VALUE_PAIR_ARRAY :=  EGO_COL_NAME_VALUE_PAIR_ARRAY();
    l_attr_group_request_table      EGO_ATTR_GROUP_REQUEST_TABLE  := EGO_ATTR_GROUP_REQUEST_TABLE();
    l_user_privileges_on_object	    EGO_VARCHAR_TBL_TYPE := NULL;
    l_entity_id			                NUMBER := NULL;
    l_entity_index			            NUMBER := NULL;
    l_entity_code			              VARCHAR2(1) := NULL;
    l_debug_level		        	      NUMBER := 3;
    l_init_error_handler	     	    VARCHAR2(1) := FND_API.G_TRUE;
    l_init_fnd_msg_list	  	        VARCHAR2(1) := FND_API.G_TRUE;
    l_add_errors_to_fnd_stack	      VARCHAR2(1) := FND_API.G_FALSE;
    l_commit			                  VARCHAR2(1) := FND_API.G_FALSE;   -- Do NOT set to TRUE, Verify the data and then COMMIT !

  
    l_user_id		      	            NUMBER := -1;
    l_resp_id		      	            NUMBER := -1;
    l_application_id	         	    NUMBER := -1;
    
    l_inventory_item_id		          NUMBER := 0;
    l_organization_id		            NUMBER := 0;
    l_item_catalog_group_id		      NUMBER := 0;
    l_attr_group_id		      	      NUMBER := 0;
    
    l_attr_int_names_list           VARCHAR2(3000);
    
  
    CURSOR csr_attrs IS
      SELECT attr_name 
      FROM ego_attrs_v
      WHERE attr_group_name = p_attr_group_name
    ;
    
    l_numero_ordem  varchar2(50); 
    l_linha         varchar2(50);
    l_envio         varchar2(50);
    l_tipo_ordem    varchar2(50);

  BEGIN
    print_log('XXFR_OM_PCK_ORDEM_VENDA_UDA.GET_UDA');
    initialize;
    print_log('  Line Id             :'||p_oe_line_id);
    print_log('  Organization Code   :'||p_organization_code);
    print_log('  Attribute Group Name:'||p_attr_group_name);
    
    
    -- Get the Attribute Group Identifiers
    SELECT attr_group_id 
    INTO l_attr_group_id
    FROM ego_attr_groups_v
    WHERE attr_group_name = p_attr_group_name;
    print_log('  Attribute Group ID  :'||l_attr_group_id);

    FOR attr IN csr_attrs LOOP
      l_attr_int_names_list := l_attr_int_names_list || attr.attr_name || ',' ;            
    END LOOP;
    print_log('  Attributes found    :'||l_attr_int_names_list);
    
    print_log('');
    print_log('  Chamando EGO_USER_ATTRS_DATA_PUB.Build_Attr_Group_Request_Table...');
    l_attr_group_request_table := EGO_USER_ATTRS_DATA_PUB.Build_Attr_Group_Request_Table(
      p_ag_req_table         => l_attr_group_request_table,
      p_attr_group_id        => l_attr_group_id,
      p_application_id       => l_application_id,
      p_attr_group_type      => NULL,
      p_attr_group_name      => NULL,
      p_data_level           => p_data_level, --'ITEM_ORG' --'ITEM_LEVEL'   -- 12.1.1 and above
      p_data_level_1         => NULL,
      p_data_level_2         => NULL,
      p_data_level_3         => NULL,
      p_data_level_4         => NULL,
      p_data_level_5         => NULL,
      p_attr_name_list       => l_attr_int_names_list
    );

    l_pk_column_name_value_pairs.EXTEND(1);
    l_pk_column_name_value_pairs(1) := EGO_COL_NAME_VALUE_PAIR_OBJ('LINE_ID', to_char(p_oe_line_id));

    print_log('');
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

    print_log('  Return Status       :'||x_return_status);
    print_log('  Message Data        :'||x_msg_data);
    print_log('  Error Code          :'||x_errorcode);
    print_log('  Msg Count           :'||x_msg_count);
    print_log('  Count               :'||fnd_msg_pub.count_msg);
    print_log('  Attrib Row Table    :'||x_attributes_row_table.count);
    print_log('  Attrib Data Table   :'||x_attributes_data_table.count);
    
    FOR ag_row IN x_attributes_row_table.FIRST..x_attributes_row_table.LAST LOOP
      print_log('  ['||ag_row||']');
      print_log('  ATTR_GROUP_ID  :'||x_attributes_row_table(ag_row).ATTR_GROUP_ID);
      print_log('  ATTR_GROUP_TYPE:'||x_attributes_row_table(ag_row).ATTR_GROUP_TYPE);
      print_log('  ATTR_GROUP_NAME:'||x_attributes_row_table(ag_row).ATTR_GROUP_NAME);
      print_log('  DATA_LEVEL     :'||x_attributes_row_table(ag_row).DATA_LEVEL);
    
      select numero_ordem, linha, envio, tipo_ordem
      into l_numero_ordem, l_linha, l_envio, l_tipo_ordem
      from xxfr_wsh_vw_inf_da_ordem_venda
      where oe_line = p_oe_line_id;
    
      FOR at_row IN x_attributes_data_table.FIRST..x_attributes_data_table.LAST LOOP
        print_log('    ['||at_row||']');
        IF x_attributes_row_table(ag_row).ROW_IDENTIFIER = x_attributes_data_table(at_row).ROW_IDENTIFIER THEN    
          if (x_attributes_data_table(at_row).ATTR_NAME = 'TIPO_ORDEM_VENDA') then
            x_attributes_data_table(at_row).ATTR_DISP_VALUE := l_tipo_ordem;
          end if;
          if (x_attributes_data_table(at_row).ATTR_NAME = 'NUMERO_LINHA') then
            x_attributes_data_table(at_row).ATTR_DISP_VALUE := l_linha;
          end if;
          if (x_attributes_data_table(at_row).ATTR_NAME = 'NUMERO_ENTREGA') then
            x_attributes_data_table(at_row).ATTR_DISP_VALUE := l_envio;
          end if;
          if (x_attributes_data_table(at_row).ATTR_NAME = 'NUMERO_ORDEM_VENDA') then
            x_attributes_data_table(at_row).ATTR_DISP_VALUE := l_numero_ordem;
          end if;        
          print_log('    ATTR_NAME      :'||x_attributes_data_table(at_row).ATTR_NAME);
          print_log('    ATTR_DISP_VALUE:'||x_attributes_data_table(at_row).ATTR_DISP_VALUE);
        END IF;                       
      END LOOP;
      print_log ('');
    END LOOP;
    
    
    FOR k IN 1 .. fnd_msg_pub.count_msg LOOP
      x_msg_data := fnd_msg_pub.get (p_msg_index => k, p_encoded => 'F');
      print_log('** Error Msg: ' || x_msg_data);
    END LOOP;
    
    <<FIM>>
    print_log('FIM XXFR_OM_PCK_ORDEM_VENDA_UDA.GET_UDA');
  EXCEPTION WHEN OTHERS THEN
    print_log('Exception occurred ! '||sqlerrm);  
    xxfr_pck_logger.log_error(
      p_log=>'Exceção não tratada', 
      p_escopo=>$$PLSQL_UNIT||'.GET_UDA'
    );
    RAISE;
  END;
  
  PROCEDURE PROCESS_UDA_COMPLETE (  
    p_oe_line_id            IN  VARCHAR2,
    p_organization_code     IN  VARCHAR2,
    p_attr_group_name       IN  VARCHAR2, 
    p_data_level            IN VARCHAR2,
    p_item_cat_grp_name     IN VARCHAR2,
    p_attributes_row_table  IN EGO_USER_ATTR_ROW_TABLE,
    p_attributes_data_table IN EGO_USER_ATTR_DATA_TABLE 
  ) IS  
    
    L_Api_Version		  	          NUMBER := 1;
    l_object_name		        	    VARCHAR2(30) := 'OE_ORDER_LINES_ALL';
    l_attributes_row_table		    EGO_USER_ATTR_ROW_TABLE := EGO_USER_ATTR_ROW_TABLE();
    l_attributes_data_table		    EGO_USER_ATTR_DATA_TABLE := EGO_USER_ATTR_DATA_TABLE();
    l_pk_column_name_value_pairs	EGO_COL_NAME_VALUE_PAIR_ARRAY :=  EGO_COL_NAME_VALUE_PAIR_ARRAY();
    l_class_code_name_value_pairs	EGO_COL_NAME_VALUE_PAIR_ARRAY :=  EGO_COL_NAME_VALUE_PAIR_ARRAY();
    L_User_Privileges_On_Object	  Ego_Varchar_Tbl_Type := Null;
    L_Entity_Id		          	    NUMBER := Null;
    L_Entity_Index			          NUMBER := Null;
    L_Entity_Code		  	          VARCHAR2(1) := Null;
    L_Debug_Level		        	    NUMBER := 3;
    l_init_error_handler	  	    VARCHAR2(1) := FND_API.G_TRUE;
    L_Write_To_Concurrent_Log	    VARCHAR2(1) := Fnd_Api.G_True;
    L_Init_Fnd_Msg_List		        VARCHAR2(1) := Fnd_Api.G_True;
    l_log_errors		        	    VARCHAR2(1) := FND_API.G_TRUE;
    L_Add_Errors_To_Fnd_Stack	    VARCHAR2(1) := Fnd_Api.G_False;
    L_Commit			                VARCHAR2(1) := Fnd_Api.G_False;   -- Do NOT set to TRUE, Verify the data and then COMMIT !
    X_Failed_Row_Id_List	     	  VARCHAR2(3000);
    X_Return_Status			          VARCHAR2(10);
    X_Errorcode			              NUMBER;
    X_Msg_Count			              NUMBER;
    x_msg_data			              VARCHAR2(3000);
    x_message_list                Error_Handler.Error_Tbl_Type;
    
    L_User_Id			                NUMBER := -1;
    L_Resp_Id			                NUMBER := -1;
    L_Application_Id	         	  NUMBER := -1;
    l_attcnt        	      	    NUMBER := 1;
    l_cnt                         NUMBER := 1;
    
    L_Inventory_Item_Id		        NUMBER := 0;
    l_organization_id	         	  NUMBER := 0;
    L_Item_Catalog_Group_Id		    NUMBER := 0;
    l_item_catalog_group_id2      NUMBER := 0;
    L_Attr_Group_Type	         	  NUMBER := 0;
    
    P_Attr_Group_Type             VARCHAR2(100) := 'OE_LINE_ATTRIBUTES_EXT';
    P_Attr_Group_App_Id           NUMBER        := 660;
    
    l_catalog_category_s           VARCHAR2(100); 
        
  BEGIN   
    print_log('');
    print_log('XXFR_OM_PCK_ORDEM_VENDA_UDA.PROCESS_UDA_COMPLETE');
    
    l_pk_column_name_value_pairs.EXTEND(1);
    l_pk_column_name_value_pairs(1) := EGO_COL_NAME_VALUE_PAIR_OBJ('LINE_ID', to_char(p_oe_line_id));
    
    l_class_code_name_value_pairs.EXTEND(1);
    l_class_code_name_value_pairs(1) := EGO_COL_NAME_VALUE_PAIR_OBJ('ENTITY', 'ADMIN_DEFINED');
      
    
    -- Add in the attribute groups here, multirow attribute groups should have the same attr_group_id
    -- transaction_type can be CREATE | UPDATE | SYNC
    
    l_attributes_row_table  := p_attributes_row_table;
    l_attributes_data_table := p_attributes_data_table; 
  
    print_log('  OE Line ID     :'||p_oe_line_id);
    print_log('  Attribute Group:'||p_attr_group_name);
    print_log('  AG Rows        :'||l_attributes_row_table.count);
    print_log('  AT rows        :'||l_attributes_data_table.count);
    print_log('');
    
    print_log('  Inicio do Loop...');
    l_cnt := 0;
    FOR ag_row IN l_attributes_row_table.FIRST..l_attributes_row_table.LAST LOOP
      print_log('  Ocorrencia:'||ag_row);
      l_cnt :=  l_cnt + 1;
      
      l_attributes_row_table(l_cnt) := Ego_User_Attr_Row_Obj(
        l_attributes_row_table(ag_row).row_identifier,		 -- ROW_IDENTIFIER
        Null,                                              -- ATTR_GROUP_ID from EGO_ATTR_GROUPS_V 
        l_attributes_row_table(ag_row).Attr_Group_App_Id,  -- ATTR_GROUP_APP_ID
        l_attributes_row_table(ag_row).Attr_Group_Type,		 -- ATTR_GROUP_TYPE
        l_attributes_row_table(ag_row).Attr_Group_Name,		 -- ATTR_GROUP_NAME
        l_attributes_row_table(ag_row).Data_level,         -- DATA_LEVEL
        NULL,		                                           -- DATA_LEVEL_1       (Required if attribute groups are at revision level)
        NULL,		                                           -- DATA_LEVEL_2
        Null,		                                           -- DATA_LEVEL_3
        NULL,		                                           -- DATA_LEVEL_4
        NULL,		                                           -- DATA_LEVEL_5
        Ego_User_Attrs_Data_Pvt.G_Create_Mode              -- TRANSACTION_TYPE
      );
      
      FOR at_row IN l_attributes_data_table.FIRST..l_attributes_data_table.LAST LOOP
        print_log('    ['||at_row||']');
        IF l_attributes_row_table(l_cnt).ROW_IDENTIFIER = l_attributes_data_table(at_row).ROW_IDENTIFIER THEN          
          print_log('    ATTR_NAME      :'||l_attributes_data_table(at_row).ATTR_NAME);
          print_log('    ATTR_DISP_VALUE:'||l_attributes_data_table(at_row).ATTR_DISP_VALUE);
        END IF;                       
      END LOOP;
  
    END LOOP;
    print_log('  Fim Inicio do Loop...');
    print_log('');
    
    -- call API to load UDA

    print_log('  Chamando EGO_USER_ATTRS_DATA_PUB.PROCESS_USER_ATTRS_DATA...');        
    EGO_USER_ATTRS_DATA_PUB.PROCESS_USER_ATTRS_DATA(
      l_api_version
      , l_object_name
      , l_attributes_row_table
      , l_attributes_data_table
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
    print_log('  Return Status: '||x_return_status);
    
    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      print_log('  Error Messages :');
      Error_Handler.GET_MESSAGE_LIST(x_message_list=>x_message_list);
      FOR i IN 1..x_message_list.COUNT LOOP
        print_log(x_message_list(i).message_text);
      END LOOP;
    END IF;
    <<FIM>>
    print_log('FIM XXFR_OM_PCK_ORDEM_VENDA_UDA.PROCESS_UDA_COMPLETE');
  EXCEPTION WHEN OTHERS THEN
    print_log('Exception Occured :');
    print_log(SQLCODE ||':'||SQLERRM);
    print_log('========================================'); 
    xxfr_pck_logger.log_error(
      p_log     => 'Exceção não tratada', 
      p_escopo  => $$PLSQL_UNIT||'.PROCESS_UDA_COMPLETE'
    );
  END;

  PROCEDURE PROCESS_OM_LINE_UDA(
    p_from_oe_line_id in number,
    p_to_oe_line_id   in number
  ) is
  
    l_api_version		  	      number := 1;

    l_attributes_row_table		      ego_user_attr_row_table       := ego_user_attr_row_table();
    l_attributes_data_table		      ego_user_attr_data_table      := ego_user_attr_data_table();
    l_pk_column_name_value_pairs	  ego_col_name_value_pair_array :=  ego_col_name_value_pair_array();
    l_class_code_name_value_pairs	  ego_col_name_value_pair_array :=  ego_col_name_value_pair_array();
    l_user_privileges_on_object	    ego_varchar_tbl_type := null;
    
    l_entity_id		          	number := null;
    l_entity_index			      number := null;
    l_entity_code		  	      varchar2(1) := null;
    l_debug_level		        	number := 3;
    l_init_error_handler	  	varchar2(1) := fnd_api.g_true;
    l_write_to_concurrent_log	varchar2(1) := fnd_api.g_true;
    l_init_fnd_msg_list		    varchar2(1) := fnd_api.g_true;
    l_log_errors		        	varchar2(1) := fnd_api.g_true;
    l_add_errors_to_fnd_stack	varchar2(1) := fnd_api.g_false;
    l_commit			            varchar2(1) := fnd_api.g_false;   -- Do NOT set to TRUE, Verify the data and then COMMIT !
    x_failed_row_id_list	  	varchar2(3000);
    x_return_status			      varchar2(10);
    x_errorcode			          number;
    x_msg_count			          number;
    x_msg_data			          varchar2(3000);
    x_message_list            error_handler.error_tbl_type;
    
    l_organization_id	       	number := 0;
            
    l_object_name	     	      varchar2(20)   := 'OE_ORDER_LINES_ALL';
    l_attr_group_name         varchar2(100) := 'REFERENCIA_LINHA_ORDEM_VENDA';   
    l_attr_group_type         varchar2(100) := 'OE_LINE_ATTRIBUTES_EXT'; 
    l_attr_group_id           number;
    l_attr_group_app_id       number        := 660;
    l_data_level              varchar2(100) := 'ORDER_LINE';   
      
    l_numero_ordem  varchar2(50); 
    l_linha         varchar2(50);
    l_envio         varchar2(50);
    l_tipo_ordem    varchar2(50);
    
    l_rowcnt        	      	NUMBER       := 1;
  
  
  BEGIN
  
    print_log('XXFR_OM_PCK_ORDEM_VENDA_UDA.PROCESS_OM_LINE_UDA');
    initialize;
    
    select numero_ordem, linha, envio, tipo_ordem
    into l_numero_ordem, l_linha, l_envio, l_tipo_ordem
    from xxfr_wsh_vw_inf_da_ordem_venda
    where oe_line = p_from_oe_line_id;
    
    print_log('  OE Line Id(1)       :'||p_from_oe_line_id);
    print_log('  OE Line Id(2)       :'||p_to_oe_line_id);
    print_log('  Attribute Group Name:'||l_attr_group_name);
    
    -- Get the Attribute Group Identifiers
    SELECT attr_group_id, APPLICATION_ID
    INTO l_attr_group_id, l_attr_group_app_id
    FROM ego_attr_groups_v
    WHERE attr_group_name = l_attr_group_name;
    
    print_log('  App Attrib Group ID :'||l_attr_group_app_id);
    print_log('  Attrib Group ID     :'||l_attr_group_id);
  
    l_pk_column_name_value_pairs.EXTEND(1);
    l_pk_column_name_value_pairs(1) := EGO_COL_NAME_VALUE_PAIR_OBJ('LINE_ID', p_to_oe_line_id);  
       
    l_class_code_name_value_pairs.EXTEND(1);
    l_class_code_name_value_pairs(1) := EGO_COL_NAME_VALUE_PAIR_OBJ('ENTITY', 'ADMIN_DEFINED');
    
    -- Add in the attribute groups here, multirow attribute groups should have the same attr_group_id
    -- transaction_type can be CREATE | UPDATE | SYNC
    l_attributes_row_table := Ego_User_Attr_Row_Table (
      Ego_User_Attr_Row_Obj(
        9991							                -- ROW_IDENTIFIER
        ,Null                             -- ATTR_GROUP_ID from EGO_ATTR_GROUPS_V 
        ,l_Attr_Group_App_Id             	-- ATTR_GROUP_APP_ID
        ,l_Attr_Group_Type				    		-- ATTR_GROUP_TYPE
        ,l_Attr_Group_Name			      		-- ATTR_GROUP_NAME
        ,l_data_level                 		-- NDATA_LEVEL
        ,NULL		-- DATA_LEVEL_1       (Required if attribute groups are at revision level)
        ,NULL		-- DATA_LEVEL_2
        ,Null		-- DATA_LEVEL_3
        ,NULL		-- DATA_LEVEL_4
        ,NULL		-- DATA_LEVEL_5
        ,Ego_User_Attrs_Data_Pvt.G_Sync_Mode			-- TRANSACTION_TYPE
      )
    );
    
    -- Add the attribute - attribute values here, for the attr groups above
    -- row_identifier is the foriegn key from the attribute group defined above
    -- user_row_identifier is used for error handling


    l_attributes_data_table.EXTEND;
    l_attributes_data_table(l_rowcnt) := Ego_User_Attr_Data_Obj (
      9991			      	    -- ROW_IDENTIFIER from above
      ,'NUMERO_ORDEM_VENDA'	-- ATTR_NAME
      ,Null				          -- ATTR_VALUE_STR
      ,Null				          -- ATTR_VALUE_NUM
      ,NULL				          -- ATTR_VALUE_DATE
      ,l_numero_ordem  	    -- ATTR_DISP_VALUE
      ,Null			      	    -- ATTR_UNIT_OF_MEASURE
      ,l_rowcnt			   	    -- USER_ROW_IDENTIFIER
    );    
    
    l_rowcnt  := l_rowcnt + 1;    
    l_attributes_data_table.EXTEND;
    l_attributes_data_table(l_rowcnt) := Ego_User_Attr_Data_Obj (
      9991			      	-- ROW_IDENTIFIER from above
      ,'NUMERO_LINHA'		-- ATTR_NAME
      ,Null				      -- ATTR_VALUE_STR
      ,Null				      -- ATTR_VALUE_NUM
      ,NULL				      -- ATTR_VALUE_DATE
      ,l_linha        	-- ATTR_DISP_VALUE
      ,Null			      	-- ATTR_UNIT_OF_MEASURE
      ,l_rowcnt			  	-- USER_ROW_IDENTIFIER
    );  
    
    l_rowcnt  := l_rowcnt + 1;
    l_attributes_data_table.EXTEND;
    l_attributes_data_table(l_rowcnt) := Ego_User_Attr_Data_Obj (
      9991			      	-- ROW_IDENTIFIER from above
      ,'NUMERO_ENTREGA'			-- ATTR_NAME
      ,Null				      -- ATTR_VALUE_STR
      ,Null				      -- ATTR_VALUE_NUM
      ,NULL				      -- ATTR_VALUE_DATE
      ,l_envio        	-- ATTR_DISP_VALUE
      ,Null			      	-- ATTR_UNIT_OF_MEASURE
      ,l_rowcnt			  	-- USER_ROW_IDENTIFIER
    );
    
    l_rowcnt  := l_rowcnt + 1;
    l_attributes_data_table.EXTEND;
    l_attributes_data_table(l_rowcnt) := Ego_User_Attr_Data_Obj (
      9991				            -- ROW_IDENTIFIER from above
      ,'TIPO_ORDEM_VENDA'   	-- ATTR_NAME
      ,Null			             	-- ATTR_VALUE_STR
      ,Null			            	-- ATTR_VALUE_NUM
      ,Null			            	-- ATTR_VALUE_DATE
      ,l_tipo_ordem         	-- ATTR_DISP_VALUE
      ,Null				            -- ATTR_UNIT_OF_MEASURE
      ,l_rowcnt				        -- USER_ROW_IDENTIFIER
    );

    print_log('Chamando EGO_USER_ATTRS_DATA_PUB.PROCESS_USER_ATTRS_DATA...');        
    EGO_USER_ATTRS_DATA_PUB.PROCESS_USER_ATTRS_DATA(
      l_api_version
      , l_object_name
      , l_attributes_row_table
      , l_attributes_data_table
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
    
    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      Error_Handler.GET_MESSAGE_LIST(x_message_list=>x_message_list);
      FOR i IN 1..x_message_list.COUNT LOOP
        print_log('  '||x_message_list(i).message_text);
      END LOOP;
    END IF;       
  
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro não previsto:'||SQLERRM);
  END PROCESS_OM_LINE_UDA;

END XXFR_OM_PCK_ORDEM_VENDA_UDA;