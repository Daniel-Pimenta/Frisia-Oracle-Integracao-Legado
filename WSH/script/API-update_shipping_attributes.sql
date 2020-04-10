set SERVEROUTPUT ON;
declare

  l_changed_attributes wsh_delivery_details_pub.changedattributetabtype;

  x_return_status VARCHAR2 (3);
  x_msg_count NUMBER;
  x_msg_data VARCHAR2 (3000);

begin
  
  XXFR_WSH_PCK_INT_ENTREGA.processar_conteudo_firme(
    p_delivery_id => 211043,
    p_action_code => 'UNPLAN',
    x_retorno     => x_return_status
  );

  fnd_msg_pub.initialize;
  
  EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
  
  l_changed_attributes (1).delivery_detail_id := 253105;
  l_changed_attributes (1).shipped_quantity   := 2995;
  --
  wsh_delivery_details_pub.update_shipping_attributes(
    p_api_version_number  => 1.0,
    p_init_msg_list       => fnd_api.g_false,
    p_commit              => fnd_api.g_false,
    p_changed_attributes  => l_changed_attributes,
    p_source_code         => 'OE',
    x_return_status       => x_return_status,
    x_msg_count           => x_msg_count,
    x_msg_data            => x_msg_data
  );
  dbms_output.put_line('Retorno :'||x_return_status);
  for i in 1 .. x_msg_count loop
    x_msg_data := fnd_msg_pub.get( 
      p_msg_index => i, 
      p_encoded   => 'T'
    );
    dbms_output.put_line('  '||i|| ') '|| x_msg_data);
  end loop;
  --
end;
/