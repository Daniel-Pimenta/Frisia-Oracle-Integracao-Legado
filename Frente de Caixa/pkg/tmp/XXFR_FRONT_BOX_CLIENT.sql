create or replace package body XXFR_FCX_PCK_CLIENTES IS

  --GLOBAL
  w_vendor_id             number;
  w_party_id              number;
  w_vendor_site_id        number;
  w_party_site_id         number;
  w_location_id           number;
  --
  w_cust_account_id       number;
  w_account_number        varchar2(2000) ;
  w_party_number          varchar2(2000) ;
  w_party_site_number     number;
  w_profile_id            number;
  w_cust_acct_site_id     number;
  w_site_use_id           number;
  
  w_cliente               XXFR_FCX_PCK_CLIENTES.front_box_client_rec_type;
  
  procedure initialize_po is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('PO', 'UO_FRISIA', 'DANIEL.PIMENTA'); 
  end;

  procedure initialize_ar is
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

  procedure create_vendor is
    l_return_status   VARCHAR2(10);
    l_msg_count       NUMBER;
    l_msg_data        VARCHAR2(1000);
  
    l_vendor_rec      ap_vendor_pub_pkg.r_vendor_rec_type;
    --
    l_vendor_site_rec ap_vendor_pub_pkg.r_vendor_site_rec_type;
    
  begin
    initialize_po;
    -- ************************************************************
    print_log('CREATE VENDOR');
    l_vendor_rec.segment1                   := w_cliente.documento;
    l_vendor_rec.vendor_name                := w_cliente.nome;
    l_vendor_rec.vendor_name_alt            := w_cliente.nome;
    l_vendor_rec.vendor_type_lookup_code    := 'VENDOR';
    l_vendor_rec.always_take_disc_flag      := 'Y'; 
    l_vendor_rec.pay_date_basis_lookup_code := 'DISCOUNT';
    l_vendor_rec.pay_group_lookup_code      := 'BOLETO';
    l_vendor_rec.allow_awt_flag             := 'Y'; 
    l_vendor_rec.global_attribute1          := 'N';
    l_vendor_rec.match_option               := 'R'; --'P'
    --
    pos_vendor_pub_pkg.create_vendor(    
      -- Input Parameters
      p_vendor_rec      => l_vendor_rec,
      -- Output Parameters
      x_return_status   => l_return_status,
      x_msg_count       => l_msg_count,
      x_msg_data        => l_msg_data,
      x_vendor_id       => w_vendor_id,
      x_party_id        => w_party_id
    );
    print_log('  Retorno       :'||l_return_status);
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
      ROLLBACK;
      goto fim;
    end if;
  
    print_log('  Vendor Id     :'||w_vendor_id);
    print_log('  Party Id      :'||w_party_id);
    --
    -- ************************************************************
    print_log('');
    print_log('CREATE VENDOR_SITE');
    l_vendor_site_rec.vendor_id                   := w_vendor_id;
    l_vendor_site_rec.vendor_site_code            := l_vendor_rec.segment1;
    l_vendor_site_rec.area_code                   := w_cliente.ddd;
    l_vendor_site_rec.phone                       := w_cliente.cel_numero;
    l_vendor_site_rec.address_line1               := w_cliente.endereco;
    l_vendor_site_rec.address_line2               := w_cliente.numero;
    l_vendor_site_rec.address_line3               := w_cliente.complemento;        --COMPLEMENTO
    l_vendor_site_rec.address_line4               := w_cliente.bairro;  --BAIRRO
    l_vendor_site_rec.city                        := w_cliente.cidade;
    l_vendor_site_rec.state                       := w_cliente.estado;
    l_vendor_site_rec.zip                         := w_cliente.cep;
    l_vendor_site_rec.country                     := 'BR';
    l_vendor_site_rec.org_id                      := '81';
    
    l_vendor_site_rec.address_style               := 'BR';
    l_vendor_site_rec.pay_date_basis_lookup_code  := 'DISCOUNT';
    l_vendor_site_rec.country_of_origin_code      := 'BR';
    l_vendor_site_rec.create_debit_memo_flag      := 'N';
    
    l_vendor_site_rec.global_attribute1           := 'N'; 
    l_vendor_site_rec.global_attribute9           := w_cliente.tipo_documento; --CNPJ,
    
    if(w_cliente.tipo_documento = '2') then --CNPJ    
      l_vendor_site_rec.global_attribute10          := substr(w_cliente.documento, 1, 8); 
      l_vendor_site_rec.global_attribute11          := substr(w_cliente.documento, 9, 4); 
      l_vendor_site_rec.global_attribute12          := substr(w_cliente.documento,13, 2); 
    else
      l_vendor_site_rec.global_attribute10          := substr(w_cliente.documento, 1, 9); 
      l_vendor_site_rec.global_attribute11          := null; 
      l_vendor_site_rec.global_attribute12          := substr(w_cliente.documento, 10, 2);     
    end if;
    l_vendor_site_rec.global_attribute13          := 'ISENTO';
    l_vendor_site_rec.global_attribute15          := 'COMERCIAL';
    
    l_vendor_site_rec.purchasing_site_flag        := 'Y';
    l_vendor_site_rec.pay_site_flag               := 'Y';
    l_vendor_site_rec.rfq_only_site_flag          := 'N';
    --
    --l_vendor_site_rec.CUSTOMER_NUM          :=
    --l_vendor_site_rec.SHIP_TO_LOCATION_ID   :=
    --l_vendor_site_rec.BILL_TO_LOCATION_ID   := 
    --
    pos_vendor_pub_pkg.create_vendor_site (
      p_vendor_site_rec => l_vendor_site_rec,
      --
      x_vendor_site_id  => w_vendor_site_id,
      x_party_site_id   => w_party_site_id,
      x_location_id     => w_location_id,
      --
      x_return_status   => l_return_status,
      x_msg_count       => l_msg_count,
      x_msg_data        => l_msg_data
    );
    
    print_log('  Retorno       :'||l_return_status);
    for i in 1 .. l_msg_count loop
      l_msg_data := fnd_msg_pub.get( 
        p_msg_index => i, 
        p_encoded   => 'F'
      );
      print_log('  '|| i|| ') '|| l_msg_data);
    end loop;
    --
    if (l_return_status <> 'S') then
      ROLLBACK;
      goto fim;
    end if;
    --
    print_log('  Vendor Site Id:'||w_vendor_site_id);
    print_log('  Party Site Id :'||w_party_site_id);
    print_log('  Locations Id  :'||w_location_id);
    
    <<fim>>
    null;
  exception when others then
    rollback;
    print_log(sqlerrm);
  end;

  procedure create_customer is
  
    p_cust_account_rec      HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    p_person_rec            HZ_PARTY_V2PUB.PERSON_REC_TYPE;
    p_organization_rec      HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    
    p_customer_profile_rec  HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
    p_location_rec          HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    p_party_site_rec        HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
    --
    p_cust_acct_site_rec    HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
    p_cust_site_use_rec     HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    
    --
    l_return_status         VARCHAR2(2000) ;
    l_msg_count             NUMBER;
    l_msg_data              VARCHAR2(2000) ;
  begin
    
    --initialize_ar;
    -- **********************************************************
    p_cust_account_rec.account_name       := w_cliente.nome;
    p_cust_account_rec.account_number     := w_cliente.documento;
    p_cust_account_rec.created_by_module  := 'HZ_CPUI'; --'TCA_V2_API';
    --             
    p_organization_rec.party_rec.party_id               := w_party_id;
    --p_organization_rec.party_rec.orig_system_reference  := w_party_id;
  
    --p_customer_profile_rec.profile_class_id :=
    p_customer_profile_rec.standard_terms   := 1000;
    print_log('');
    print_log('CREATE_CUST_ACCOUNT');
    hz_cust_account_v2pub.create_cust_account (  
      p_init_msg_list           => 'T',
      p_cust_account_rec        => p_cust_account_rec,
      --
      p_organization_rec        => p_organization_rec,
      --p_person_rec              => p_person_rec,
      --
      p_customer_profile_rec    => p_customer_profile_rec,
      p_create_profile_amt      => 'F',
      --
      x_cust_account_id         => w_cust_account_id,
      x_account_number          => w_account_number,
      x_party_id                => w_party_id,
      x_party_number            => w_party_number,
      x_profile_id              => w_profile_id,
      --
      x_return_status           => l_return_status,
      x_msg_count               => l_msg_count,
      x_msg_data                => l_msg_data
    );
    --
    print_log('  Retorno       :'||l_return_status);
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
      ROLLBACK;
      goto fim;
    end if;
  
    print_log('  Cust Account Id:'||w_cust_account_id);
    print_log('  Account Number :'||w_account_number);
    print_log('  Party Id       :'||w_party_id);
    print_log('  Party Number   :'||w_party_number);
    print_log('  Profile Id     :'||w_profile_id);
    /*
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
    p_location_rec.orig_system_reference:= null;
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
      goto fim;
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
      goto fim;
    end if;
    print_log('Party Site Id  :'||l_party_site_id);
    print_log('Party Site Num :'||l_party_site_number);
    */
    p_cust_acct_site_rec.cust_account_id   := w_cust_account_id;
    p_cust_acct_site_rec.party_site_id     := w_party_site_id; 
    --p_cust_acct_site_rec.created_by_module := 'TCA_V2_API';
    p_cust_acct_site_rec.created_by_module := 'HZ_CPUI'; 
    --
    print_log('');
    print_log('CREATE_CUST_ACCT_SITE');
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE(
      p_init_msg_list         => FND_API.G_TRUE,
      p_cust_acct_site_rec    => p_cust_acct_site_rec,
      x_cust_acct_site_id     => w_cust_acct_site_id,
      x_return_status         => l_return_status,
      x_msg_count             => l_msg_count,
      x_msg_data              => l_msg_data
    );
    print_log('  Retorno       :'||l_return_status);
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
      goto fim;
    end if;
    print_log('  Cust Acct Site Id:'||w_cust_acct_site_id);
    -- **********************************************************
    p_cust_site_use_rec.cust_acct_site_id := w_cust_acct_site_id;
    p_cust_site_use_rec.location          := w_account_number;
    p_cust_site_use_rec.created_by_module := 'HZ_CPUI';
    print_log('');
    print_log('CREATE_CUST_SITE_USE (BILL_TO)');
    p_cust_site_use_rec.site_use_code     := 'BILL_TO';
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE(
      p_init_msg_list         => FND_API.G_TRUE,
      p_cust_site_use_rec     => p_cust_site_use_rec,
      p_customer_profile_rec  => p_customer_profile_rec,
      p_create_profile        => FND_API.G_TRUE,
      p_create_profile_amt    => FND_API.G_TRUE,
      x_site_use_id           => w_site_use_id,
      x_return_status         => l_return_status,
      x_msg_count             => l_msg_count,
      x_msg_data              => l_msg_data
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
      goto fim;
    end if;
    print_log('Site Use Id   :'||w_site_use_id);
    -- **********************************************************
    print_log('');
    print_log('CREATE_CUST_SITE_USE (SHIP_TO)');
    p_cust_site_use_rec.site_use_code     := 'SHIP_TO';
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE(
      p_init_msg_list         => FND_API.G_TRUE,
      p_cust_site_use_rec     => p_cust_site_use_rec,
      p_customer_profile_rec  => p_customer_profile_rec,
      p_create_profile        => FND_API.G_TRUE,
      p_create_profile_amt    => FND_API.G_TRUE,
      x_site_use_id           => w_site_use_id,
      x_return_status         => l_return_status,
      x_msg_count             => l_msg_count,
      x_msg_data              => l_msg_data
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
      goto fim;
    end if;
    print_log('Site Use Id   :'||w_site_use_id);

    <<fim>>
    null;
  exception when others then
    rollback;
    print_log(sqlerrm);
  end;

  procedure main (
    p_cliente     in front_box_client_rec_type,
    x_vendor_id   out number,
    x_customer_id out number,
    x_retorno     out varchar2
  ) is
  
  BEGIN
    print_log('---------------------------------------------------------------------------');
    print_log('INICIO DO PROCESSO CLI FRENTE DE CAIXA '||TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));
    print_log('---------------------------------------------------------------------------');
    w_cliente := p_cliente;
    --   
    print_log('Nome          :'||w_cliente.nome);
    print_log('Tipo Documento:'||w_cliente.tipo_documento);
    print_log('Nu, Documento :'||w_cliente.documento);
    print_log('Inscricao     :'||w_cliente.inscricao);
    print_log('Endereço      :'||w_cliente.endereco);
    print_log('Numero        :'||w_cliente.numero);
    print_log('Complemento   :'||w_cliente.complemento);
    print_log('Bairro:       :'||w_cliente.bairro);
    print_log('Cep           :'||w_cliente.cep);
    print_log('Cidade        :'||w_cliente.cidade);
    print_log('Estado        :'||w_cliente.estado);
    --
    print_log('Cod Area (00) :'||w_cliente.ddd);
    print_log('Celular       :'||w_cliente.cel_numero);
    --
    create_vendor;
    print_log('');
    create_customer;
    print_log('---------------------------------------------------------------------------');
    print_log('FIM DO PROCESSO CLI FRENTE DE CAIXA '||TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));
    print_log('---------------------------------------------------------------------------');
  end;

END XXFR_FCX_PCK_CLIENTES;
/