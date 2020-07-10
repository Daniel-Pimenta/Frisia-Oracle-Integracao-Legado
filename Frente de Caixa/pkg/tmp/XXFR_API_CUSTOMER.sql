SET SERVEROUTPUT ON;
DECLARE

  p_cust_account_rec      HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
  p_person_rec            HZ_PARTY_V2PUB.PERSON_REC_TYPE;
  p_organization_rec      HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
  
  p_customer_profile_rec  HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
  p_location_rec          HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
  p_party_site_rec        HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
  p_cust_acct_site_rec    HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
  p_cust_site_use_rec     HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
  
  --
  l_cust_account_id       NUMBER;
  l_account_number        VARCHAR2(2000) ;
  l_party_id              NUMBER;
  l_party_number          VARCHAR2(2000) ;
  l_party_site_id         number;
  l_party_site_number     number;
  l_profile_id            NUMBER;
  l_location_id           number;
  
  l_return_status         VARCHAR2(2000) ;
  l_msg_count             NUMBER;
  l_msg_data              VARCHAR2(2000) ;

  procedure initialize is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('AR', 'UO_FRISIA', 'DANIEL.PIMENTA'); 
  end;

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    /*
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
    */
  end;

BEGIN
  
  initialize;
  -- **********************************************************
  p_cust_account_rec.account_name       := 'WSB CONSULTORIA EM IT';
  p_cust_account_rec.account_number     := '35674343000116';
  p_cust_account_rec.created_by_module  := 'TCA_V2_API';
  --          
  p_person_rec.person_first_name       := 'WSB CONSULTORIA';
  p_person_rec.person_last_name        := '';
  
  p_person_rec.party_rec.party_id:= 174057;

  print_log('CREATE_CUST_ACCOUNT');
  hz_cust_account_v2pub.create_cust_account (  
    p_init_msg_list           => 'T',
    p_cust_account_rec        => p_cust_account_rec,
    --
    --p_organization_rec        => p_organization_rec,
    p_person_rec              => p_person_rec,
    --
    p_customer_profile_rec    => p_customer_profile_rec,
    p_create_profile_amt      => 'F',
    --
    x_cust_account_id         => l_cust_account_id,
    x_account_number          => l_account_number,
    x_party_id                => l_party_id,
    x_party_number            => l_party_number,
    x_profile_id              => l_profile_id,
    --
    x_return_status           => l_return_status,
    x_msg_count               => l_msg_count,
    x_msg_data                => l_msg_data
  );
  --
  print_log('Retorno       :'||l_return_status);
  --
  for i in 1 .. l_msg_count loop
    l_msg_data := fnd_msg_pub.get( 
      p_msg_index => i, 
      p_encoded   => 'F'
    );
    print_log('  '|| i|| ') '|| l_msg_data);
  end loop;
  --
  if (l_return_status <> 'S') then
    goto FIM;
  end if;

  print_log('Cust Account Id:'||l_cust_account_id);
  print_log('Account Number :'||l_account_number);
  print_log('Party Id       :'||l_party_id);
  print_log('Party Number   :'||l_party_number);
  print_log('Profile Id     :'||l_profile_id);
  -- **********************************************************
  p_location_rec.country              := 'BR';
  p_location_rec.address1             := 'AV PAULISTA';
  p_location_rec.address2             := '171';
  p_location_rec.address3             := 'SL7';
  p_location_rec.address4             := 'CENTRO';
  p_location_rec.city                 := 'SAO PAULO';
  p_location_rec.postal_code          := '00.000-000';
  p_location_rec.state                := 'SP';
  p_location_rec.province             := '';
  p_location_rec.county               := '';
  p_location_rec.created_by_module    := 'HZ_CPUI';
  p_location_rec.orig_system_reference:= NULL;
  print_log('');
  print_log('CREATE_LOCATION');
  hz_location_v2pub.create_location(
    p_init_msg_list      => fnd_api.g_false,
    p_location_rec       => p_location_rec,
    x_location_id        => l_location_id,
    x_return_status      => l_return_status,
    x_msg_count          => l_msg_count,
    x_msg_data           => l_msg_data
  );
  print_log('Retorno       :'||l_return_status);
  --
  for i in 1 .. l_msg_count loop
    l_msg_data := fnd_msg_pub.get( 
      p_msg_index => i, 
      p_encoded   => 'F'
    );
    print_log('  '|| i|| ') '|| l_msg_data);
  end loop;
  --
  if (l_return_status <> 'S') then
    goto FIM;
  end if;
  print_log('Location Id    :'||l_location_id);
  -- **********************************************************
  p_party_site_rec.identifying_address_flag  := 'Y';
  p_party_site_rec.created_by_module         := 'HZ_CPUI'; 
  p_party_site_rec.party_id                  := l_party_id;
  p_party_site_rec.location_id               := l_location_id;
  p_party_site_rec.status                    := 'A';
  print_log('');
  print_log('CREATE_PARTY_SITE');  
  hz_party_site_v2pub.create_party_site(
    p_init_msg_list          => fnd_api.g_false,
    p_party_site_rec         => p_party_site_rec,
    x_party_site_id          => l_party_site_id,
    x_party_site_number      => l_party_site_number,
    x_return_status          => l_return_status,
    x_msg_count              => l_msg_count,
    x_msg_data               => l_msg_data
  );
  print_log('Retorno       :'||l_return_status);
  --
  for i in 1 .. l_msg_count loop
    l_msg_data := fnd_msg_pub.get( 
      p_msg_index => i, 
      p_encoded   => 'F'
    );
    print_log('  '|| i|| ') '|| l_msg_data);
  end loop;
  --
  if (l_return_status <> 'S') then
    goto FIM;
  end if;
  print_log('Party Site Id  :'||l_party_site_id);
  print_log('Party Site Num :'||l_party_site_number);

  <<FIM>>
  null;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  print_log(SQLERRM);
END;
/

/*
SELECT * FROM hz_cust_accounts 
where 1=1
order by creation_date desc
;

SELECT * FROM hz_parties 
WHERE 1=1
order by creation_date desc;


select * from cll_f189_query_customers_v
where 
customer_name = '35674343000116';


*/
