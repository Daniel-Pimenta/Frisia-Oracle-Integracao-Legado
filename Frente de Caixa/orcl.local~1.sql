set serveroutput on
declare
  
  conn         utl_tcp.connection;
  
  retval       binary_integer;
  
  l_response   varchar2(3000);
  l_text       varchar2(3000);
  
  ok           boolean := true;

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
  end;
  
begin
  print_log('*** INICIO '||to_char(sysdate ,'DD/MM/YYYY - HH24:MI:SS'));
  begin
    print_log('Conectando...');
    conn := utl_tcp.open_connection(
        remote_host   => 'echo.websocket.org',
        remote_port   => 80,
        tx_timeout    => 10,
        charset       => 'UTF-8'
    );
    print_log('Conectado a '||conn.remote_host);
  exception
    when others then
      print_log(sqlerrm);
      ok:=false;
  end;
  -- Write to Socket
  if (ok) then
    print_log('Enviando msg...');
    l_text := '{"operacao":"112","valorTransacao":"4579"}';
    retval := utl_tcp.write_line(conn, l_text);
    utl_tcp.flush(conn);
  end if;
  -- CHECK AND READ RESPONSE FROM SOCKET
  if (ok) then
    begin
      print_log('Checando msg...'||utl_tcp.available(conn,10));
      while utl_tcp.available(conn,10) > 0 loop
        l_response := l_response ||  utl_tcp.get_line(conn, false);
      end loop;
      print_log('Response from Socket Server : ' || l_response);
      utl_tcp.close_connection(conn);
    exception
      when utl_tcp.end_of_input then
        utl_tcp.close_connection(conn);
    end;
  end if; 
  print_log('*** FIM '||to_char(sysdate ,'DD/MM/YYYY - HH24:MI:SS'));
end;