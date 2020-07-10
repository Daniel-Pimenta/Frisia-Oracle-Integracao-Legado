set SERVEROUTPUT ON
declare

  p_cliente               XXFR_FCX_PCK_CLIENTES.cliente_rec_type;
  p_vendor_id             number;
  p_customer_id           number;
  l_return_status         VARCHAR2(300);
  l_msg_count             NUMBER;
  l_msg_data              VARCHAR2(1000);

begin
  p_cliente.org_id          := 81;
  p_cliente.nome            := 'TESTE PJ F.CAIXA-'||xxfr_fnc_sequencia_unica('FCAIXA-PJ');
  p_cliente.tipo_documento  := '2';
  p_cliente.documento       := to_char(SYSDATE,'YYYYMMDDHH24MISS');
  p_cliente.inscricao       := '123123122';
  p_cliente.endereco        := 'AV DOS PIONEIROS';
  p_cliente.numero          := '123';
  p_cliente.complemento     := 'CASA 8';
  p_cliente.bairro          := 'CENTRO';
  p_cliente.cep             := '00000000';
  p_cliente.cidade          := 'CARAMBEI';
  p_cliente.estado          := 'PR';
  --
  p_cliente.ddd             := '00';
  p_cliente.cel_numero      := '999999999';
  p_cliente.email           := 'fulano@frisia.com.br';

  XXFR_FCX_PCK_CLIENTES.criar_cliente(
    p_cliente       => p_cliente,
    x_vendor_id     => p_vendor_id,
    x_customer_id   => p_customer_id,
    x_return_status => l_return_status,
    x_msg_count     => l_msg_count,
    x_msg_data      => l_msg_data
  );
  dbms_output.put_line('Retorno:'||l_return_status);
  if (l_return_status = 'S') then
    dbms_output.put_line('Vendor Id  :'||p_vendor_id);
    dbms_output.put_line('Customer Id:'||p_customer_id);
    --commit;
    null;
  else
    for i in 1 .. l_msg_count loop
      l_msg_data := fnd_msg_pub.get( 
        p_msg_index => i, 
        p_encoded   => 'F'
      );
      dbms_output.put_line('  '|| i|| ') '|| l_msg_data);
    end loop;
  end if;
end;
/


/*
SELECT * FROM hz_parties WHERE PARTY_NAME='DANIEL SOARES PIMENTA';
SELECT * FROM hz_party_sites WHERE PARTY_SITE_ID = 90030;
SELECT * FROM hz_locations WHERE LOCATION_ID = 30934;
SELECT * FROM hz_cust_accounts_all WHERE Cust_Account_Id=47051;

SELECT * FROM hz_cust_acct_sites_all 
--WHERE Cust_Account_Id=47051
order by creation_date desc
;

select * from po_vendor_sites_all;

SELECT * FROM hz_cust_site_uses_all 
--WHERE CUST_ACCT_SITE_ID=54040
order by creation_date desc
;

select id, DS_ESCOPO, DS_LOG  
from xxfr_logger_log
where 1=1 
  and dt_criacao >= sysdate -1
  and upper(DS_ESCOPO) like 'XXFR_FCX_PCK_CLIENTES_%'
order by 
id
;


select global_attribute8
from hz_cust_acct_sites_all cli
where cli.cust_acct_site_id = p_cust_acct_site_id


*/