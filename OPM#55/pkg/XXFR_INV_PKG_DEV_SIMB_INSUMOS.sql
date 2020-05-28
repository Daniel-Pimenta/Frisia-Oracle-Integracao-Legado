create or replace PACKAGE XXFR_INV_PKG_DEV_SIMB_INSUMOS AS
  --TYPE header_type  xxfr_dev_simb_insumos_header_v%ROWTYPE;
  procedure processa(
    p_header_tab  in  xxfr_dev_simb_insumos_header_v%ROWTYPE,
    x_retorno     out varchar2
  );

  procedure processa(
    p_lines_tab  in  xxfr_dev_simb_insumos_lines_v%ROWTYPE,
    x_retorno     out varchar2
  );
  
  procedure devolver(
    p_header_id   in  number,
    x_retorno     out varchar2
  );
  
  function f1(v1 in number, v2 in number) return varchar2;

END XXFR_INV_PKG_DEV_SIMB_INSUMOS;
/


create or replace PACKAGE BODY XXFR_INV_PKG_DEV_SIMB_INSUMOS AS
  --Header
  procedure processa(
    p_header_tab  in xxfr_dev_simb_insumos_header_v%ROWTYPE,
    x_retorno     out varchar2
  ) is
  
    l_header_id           number;
    l_line_id             number;  
    l_id_item_ingrediente number;
    l_uom_ingrediente     varchar2(20);
  begin
    -- INSERT
    if (p_header_tab.header_id is null) then
      begin
      select xxfr_seq_ret_insumos_header.nextval into l_header_id from dual;
      insert into xxfr_dev_simb_insumos_header (
        header_id,
        organization_id,
        inventory_item_id,
        reference_date,
        quantity,
        uom_code,
        status,
        --
        last_update_date,
        last_update_by,
        creation_date,
        created_by
      )values(
        l_header_id,
        p_header_tab.organization_id,
        p_header_tab.inventory_item_id,
        sysdate,
        p_header_tab.quantity,
        p_header_tab.uom_code,
        'REGISTRADO',
        --
        sysdate,
        -1,
        sysdate,
        -1
      );
      for r1 in (
        select INVENTORY_ITEM_ID, ORGANIZATION_ID, DETAIL_UOM 
        from fm_matl_dtl 
        where 1=1
          and formula_id      = p_header_tab.id_formula
          and organization_id = p_header_tab.organization_id
          and LINE_TYPE       = -1
      ) loop
        select xxfr_seq_ret_insumos_lines.nextval into l_line_id from dual;
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
          r1.INVENTORY_ITEM_ID,
          0,
          r1.DETAIL_UOM,
          --
          sysdate,
          -1,
          sysdate,
          -1
        );
      end loop;
      x_retorno := 'SUCESSO';
      exception when others then
        x_retorno := sqlerrm;
      end;
    end if;    
  end;
  --Lines
  procedure processa(
    p_lines_tab   in xxfr_dev_simb_insumos_lines_v%ROWTYPE,
    x_retorno     out varchar2
  ) is
  
    l_header_id           number;
    l_line_id             number;  
    l_quantity            number;
  begin
    -- INSERT
    if (nvl(p_lines_tab.quantity,0) > 0) then
      begin
        update xxfr_dev_simb_insumos_lines
        set
          quantity = p_lines_tab.quantity
        where 1=1
          and header_id = p_lines_tab.header_id
          and line_id   = p_lines_tab.line_id
        ;
        x_retorno := 'SUCESSO';
      exception when others then
        x_retorno := sqlerrm;
      end;
    end if;    
  end;

  procedure devolver(
    p_header_id   in  number,
    x_retorno     out varchar2
  ) is
  begin
    x_retorno := 'SUCESSO';
  end;

  function f1(v1 in number, v2 in number) return varchar2 is
  begin
    return 'Ola Mundo';
  end;

END XXFR_INV_PKG_DEV_SIMB_INSUMOS;
/