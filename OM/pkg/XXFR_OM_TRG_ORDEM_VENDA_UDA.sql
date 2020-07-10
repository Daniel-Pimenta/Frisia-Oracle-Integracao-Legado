create or replace trigger XXFR_OM_TRG_ORDEM_VENDA_UDA
after insert on OE_ORDER_LINES_ALL 
for each row
declare 
  g_escopo              varchar2(50) := 'XXFR_OM_TRG_OE_UDA';
  l_boolean             boolean;
  x_retorno             varchar2(300);
  
  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;
  
begin
  if (:new.split_from_line_id is not null) then
    begin
      g_escopo := upper(g_escopo)||'_'||:new.line_id;
      print_log('============================================================================');
      print_log('INICIO DO PROCESSO (TRIGGER) - OE LINE UDA '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
      print_log('============================================================================');
      XXFR_OM_PCK_ORDEM_VENDA_UDA.main(
        :new.split_from_line_id,
        :new.line_id,
        g_escopo,
        x_retorno
      );
    exception when others then
      print_log('  Erro não previsto:'||sqlerrm);
    end;
    print_log('============================================================================');
    print_log('FIM DO PROCESSO (TRIGGER) - OE LINE UDA '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
    print_log('============================================================================');
  end if;
end XXFR_OM_TRG_ORDEM_VENDA_UDA;
/

