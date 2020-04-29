set SERVEROUTPUT ON;
declare

  l_changed_attributes  WSH_DELIVERY_DETAILS_PUB.ChangedAttributeTabType;
  l_return_status       varchar2(10);
  l_msg_count           number;
  l_msg_data            varchar2(3000);

  procedure print_out(msg varchar2) is
  begin
    DBMS_OUTPUT.PUT_LINE (msg);
  end;

begin

  xxfr_pck_variaveis_ambiente.inicializar('ONT', 'UO_FRISIA'); 
  fnd_msg_pub.initialize;

  l_changed_attributes(1).delivery_detail_id := 289075;
  l_changed_attributes(1).attribute1 := '666';

  WSH_DELIVERY_DETAILS_PUB.Update_Shipping_Attributes (
    p_api_version_number  => 1.0,
    p_init_msg_list       => FND_API.G_FALSE,
    p_commit              => FND_API.G_FALSE,
    p_changed_attributes  => l_changed_attributes,
    p_source_code         => 'OE',
    p_container_flag      => '',
    x_return_status       => l_return_status,
    x_msg_count           => l_msg_count,
    x_msg_data            => l_msg_data
  );
  print_out('  Saida:'||l_return_status);
  for i in 1 .. l_msg_count loop
    l_msg_data := fnd_msg_pub.get( 
      p_msg_index => i, 
      p_encoded   => 'F'
    );
    print_out('  '|| i|| ') '|| l_msg_data);
  end loop;

end;
/