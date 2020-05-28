--drop trigger xxfr_ri_trg_nfentrada;
create or replace trigger XXFR_RI_TRG_NFENTRADA
after update on JL_BR_CUSTOMER_TRX_EXTS 
for each row
declare 
  g_escopo              varchar2(50) := 'XXFR_RI_TRG_NFENTRADA';
  l_customer_trx_id     number;
  l_attrib_category     varchar2(50);
  l_attribute15         varchar2(50);
  l_tipo_operacao       varchar2(50);
  l_retorno             varchar2(300);
  l_request_id          number;
  l_boolean             boolean;
  
  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => upper(g_escopo)||'_'||l_customer_trx_id
    );
  end;
  
begin
  if (:new.electronic_inv_status = 2) then
    l_customer_trx_id := :old.customer_trx_id;
    begin
      print_log('============================================================================');
      print_log('INICIO DO PROCESSO (TRIGGER) - NFE AR -> RI '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
      print_log('============================================================================');
      print_log('Iniciando consulta a NF ID:'||l_customer_trx_id);
      select   
        rct.attribute_category, 
        rct.attribute15,
        rctt.global_attribute2 tipo_operacao
      into l_attrib_category, l_attribute15, l_tipo_operacao
      from 
        ra_customer_trx_all rct,
        ra_cust_trx_types   rctt
      where 1=1
        and rct.cust_trx_type_id = rctt.cust_trx_type_id
        and rct.customer_trx_id  = l_customer_trx_id
      ;
    exception when others then
      print_log('  Erro ao resgatar a NF:'||sqlerrm);
    end;
    if (l_tipo_operacao = 'ENTRY') then
      print_log('  Nota de ENTRADA.');
      if (l_attribute15 is null) then
        l_boolean := FND_REQUEST.set_mode(TRUE);
        l_request_id := FND_REQUEST.submit_request(
          application => 'XXFR',
          program     => 'XXFR_AR_GERA_RI',
          description => null,
          start_time  => sysdate,
          sub_request => false,
          argument1   => l_customer_trx_id
        );
        print_log('  Request Id     :'||l_request_id);
      else
        print_log('  A NF Id:('||l_customer_trx_id||') já foi integrada ao RI');
      end if;
    end if;
  end if;
  print_log('============================================================================');
  print_log('FIM DO PROCESSO (TRIGGER) - NFE AR -> RI '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
  print_log('============================================================================');
end XXFR_RI_TRG_NFENTRADA;
/

