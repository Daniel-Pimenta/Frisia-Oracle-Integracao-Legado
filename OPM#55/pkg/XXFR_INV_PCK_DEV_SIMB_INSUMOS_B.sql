create or replace PACKAGE BODY XXFR_INV_PCK_DEV_SIMB_INSUMOS AS

  g_usuario                       varchar2(50);
  g_source                        varchar2(50) := 'XXFR_DEV_SIMB_INSUMOS';
  g_escopo                        varchar2(50) := 'XXFR_DEV_SIMB_INSUMOS';
  g_comments                      varchar2(50) := 'RI (Entrada) Invoice_id:';
  
  g_header_id                     number;
  g_org_id                        number;
  g_errMessage                    varchar2(3000);
  
  isCommit                        boolean      := true;
  ok                              boolean      := true;

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    --if (isConcurrent) then apps.fnd_file.put_line (apps.fnd_file.log, msg); end if;
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo ||'_'|| g_header_id
    );
  end;

  --Header
  procedure processa_header(
    p_header_tab  in XXFR_OPM_VW_DEV_SIMB_INSUMOS_H%ROWTYPE,
    x_retorno     out varchar2
  ) is
  
    l_header_id           number;
    l_line_id             number;  
    l_id_item_ingrediente number;
    l_uom_ingrediente     varchar2(20);
  begin
    g_header_id := p_header_tab.header_id;
    begin
      --INSERT
      if (p_header_tab.header_id is null) then
        print_log('PROCESSA HEADER (NEW)');
        select xxfr_seq_ret_insumos_header.nextval into l_header_id from dual;
        g_header_id := l_header_id;
        print_log('  Insert Header...');
        print_log('  Header_id        :'||l_header_id);
        print_log('  Organization_id  :'||p_header_tab.organization_id);
        print_log('  Inventory_Item_id:'||p_header_tab.inventory_item_id);
        print_log('  Quantity         :'||p_header_tab.quantity);
        print_log('  Formula_id       :'||p_header_tab.id_formula);
        --Insere Header
        insert into xxfr_dev_simb_insumos_header (
          header_id,
          organization_id,
          formula_id,
          inventory_item_id,
          reference_date,
          quantity,
          uom_code,
          status,
          segment,
          --
          last_update_date,
          last_update_by,
          creation_date,
          created_by
        )values(
          l_header_id,
          p_header_tab.organization_id,
          p_header_tab.id_formula,
          p_header_tab.inventory_item_id,
          sysdate,
          p_header_tab.quantity,
          p_header_tab.uom_code,
          'CRIADO',
          p_header_tab.organization_id||'.'||p_header_tab.id_formula||'.'||p_header_tab.inventory_item_id,
          --
          sysdate,
          fnd_profile.value('USER_ID'),
          sysdate,
          fnd_profile.value('USER_ID')
        );
        --Insere Lines
        for r1 in (
          SELECT DISTINCT ORGANIZATION_ID, LINE_NO, INVENTORY_ITEM_ID, DETAIL_UOM 
          FROM FM_MATL_DTL 
          WHERE 1=1
            AND FORMULA_ID      = P_HEADER_TAB.ID_FORMULA
            AND ORGANIZATION_ID = P_HEADER_TAB.ORGANIZATION_ID
            AND LINE_TYPE       = -1
        ) loop
          select xxfr_seq_ret_insumos_lines.nextval into l_line_id from dual;
          print_log('    Line_Id          :'||l_line_id);
          print_log('    Line_No          :'||r1.line_no);
          print_log('    Inventory_Item_id:'||r1.inventory_item_id);
          insert into xxfr_dev_simb_insumos_lines (
            header_id,
            line_id,
            inventory_item_id,
            quantity,
            uom_code,
            --
            last_update_date,
            last_update_by,
            creation_date,
            created_by
          )values(
            l_header_id,
            l_line_id,
            r1.inventory_item_id,
            0,
            r1.detail_uom,
            --
            sysdate,
            fnd_profile.value('USER_ID'),
            sysdate,
            fnd_profile.value('USER_ID')
          );
        end loop;
      end if;
      --UPDATE
      if (p_header_tab.header_id is not null) then
        print_log('PROCESSA HEADER (UPDATE)');
        print_log('  Update Header...');
        print_log('  Header_id        :'||p_header_tab.header_id);
        print_log('  Organization_id  :'||p_header_tab.organization_id);
        print_log('  Inventory_Item_id:'||p_header_tab.inventory_item_id);
        print_log('  Quantity         :'||p_header_tab.quantity);
        update xxfr_dev_simb_insumos_header 
        set 
          quantity          = p_header_tab.quantity,
          --status            = 'REGISTRADO',
          last_update_date  = SYSDATE,
          last_update_by    = fnd_profile.value('USER_ID')
        where 
          header_id = p_header_tab.header_id
        ;
      end if;
      x_retorno := 'SUCESSO';
      print_log('  Retorno:'||x_retorno);
    exception when others then
      x_retorno := sqlerrm;
      print_log('  ** Erro:'||sqlerrm);
    end;  
    print_log('FIM PROCESSA HEADER');
  end;
  --Lines
  procedure processa_lines(
    p_lines_tab   in XXFR_OPM_VW_DEV_SIMB_INSUMOS_L%ROWTYPE,
    x_retorno     out varchar2
  ) is
  
    l_header_id           number;
    l_line_id             number;  
    l_quantity            number;
    l_somatorio           number;
    
  begin
    g_header_id := p_lines_tab.header_id;
    print_log('PROCESSA LINES');
    if (nvl(p_lines_tab.quantity,0) > 0) then
      print_log('  Line_Id          :'||p_lines_tab.line_id);
      print_log('  Quantidade       :'||p_lines_tab.quantity);
      begin
        update xxfr_dev_simb_insumos_lines
        set
          quantity = p_lines_tab.quantity,
          last_update_date  = SYSDATE,
          last_update_by    = fnd_profile.value('USER_ID')
        where 1=1
          and header_id = p_lines_tab.header_id
          and line_id   = p_lines_tab.line_id
        ;
      exception when others then
        x_retorno := sqlerrm;
        goto FIM_PROCESSA_LINES;
      end;
    end if;
  
    --Processa o Status 
    select sum(decode(nvl(quantity,0),0,1,0)) 
    into l_somatorio
    from xxfr_dev_simb_insumos_lines 
    where 1=1
      and header_id = p_lines_tab.header_id
    ;
    -- Se = 0 Todos as quantidades estão preenchidas.
    if (l_somatorio = 0) then
      update xxfr_dev_simb_insumos_header 
      set 
        status           = 'REGISTRADO',
        last_update_date = SYSDATE,
        last_update_by   = fnd_profile.value('USER_ID')
      where 1=1
        and header_id = p_lines_tab.header_id
      ;
    end if;
    x_retorno := 'SUCESSO';
    <<FIM_PROCESSA_LINES>>
    print_log('FIM PROCESSA LINES');
  end;

  procedure processar(
 	  p_header_id 		in number,
	  x_retorno   		out varchar2
  ) is
  
    l_oe_header_id  number;
    l_retorno       varchar2(3000);
    
  begin
    gera_om(
      p_header_id,
      l_oe_header_id,
      l_retorno
    );
  end;

  procedure gera_om(
    p_header_id     in number,
    x_oe_header_id  out number,
    x_retorno       out varchar2
  ) is
  begin
    g_header_id := p_header_id;
    print_log('Chamando XXFR_OM_PCK_DEV_SIMB_INSUMOS.MAIN');
    XXFR_OM_PCK_DEV_SIMB_INSUMOS.main(
      p_header_id     => p_header_id,
      x_oe_header_id  => x_oe_header_id,
      x_retorno       => x_retorno
    );
    print_log('Retorno:'||x_retorno);
  end;
  
  procedure gera_ri(
    p_header_id     in number,
    x_retorno       out varchar2
  ) is
  begin
    g_header_id := p_header_id;
    print_log('Chamando XXFR_RI_PCK_DEV_SIMB_INSUMOS.MAIN...');
    XXFR_RI_PCK_DEV_SIMB_INSUMOS.main(
      p_header_id     => p_header_id,
      x_retorno       => x_retorno
    );
    print_log('Retorno:'||x_retorno);
  end;

  function f1(v1 in number, v2 in number) return varchar2 is
  begin
    return 'Ola Mundo';
  end;

END XXFR_INV_PCK_DEV_SIMB_INSUMOS;
/