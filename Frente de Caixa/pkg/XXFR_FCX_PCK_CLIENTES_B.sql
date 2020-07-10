create or replace package body XXFR_FCX_PCK_CLIENTES IS

  --GLOBAL
  w_cliente               XXFR_FCX_PCK_CLIENTES.cliente_rec_type;  
  w_ou_name				        varchar2(100);
  
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
  --
  ok                      boolean := true;
  --
  w_return_status         VARCHAR2(300);
  w_msg_count             NUMBER;
  w_msg_data              VARCHAR2(1000);

  procedure limpa_variaveis is
  begin
    w_vendor_id         := null;
    w_party_id          := null;
    w_vendor_site_id    := null;
    w_party_site_id     := null;
    w_location_id       := null;
    --
    w_cust_account_id   := null;
    w_account_number    := null;
    w_party_number      := null;
    w_party_site_number := null;
    w_profile_id        := null;
    w_cust_acct_site_id := null;
    w_site_use_id       := null;
    --
    ok                  := true;
    --
    w_return_status     := null;
    w_msg_count         := null;
    w_msg_data          := null;
  end;

  procedure initialize_po is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('PO', w_ou_name, fnd_profile.value('USER_NAME')); 
  end;

  procedure initialize_ar is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('AR', w_ou_name, fnd_profile.value('USER_NAME')); 
  end;

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => 'XXFR_FCX_PCK_CLIENTES_'||w_cliente.documento
    );
  end;

  procedure create_vendor is

    l_vendor_rec      ap_vendor_pub_pkg.r_vendor_rec_type;
    l_vendor_site_rec ap_vendor_pub_pkg.r_vendor_site_rec_type;

  begin
    initialize_po;
    -- ************************************************************
    print_log('INICIO CREATE VENDOR');
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
    fnd_msg_pub.initialize;
    print_log('Chamando POS_VENDOR_PUB_PKG.CREATE_VENDOR...');
    pos_vendor_pub_pkg.create_vendor(    
      -- Input Parameters
      p_vendor_rec      => l_vendor_rec,
      -- Output Parameters
      x_return_status   => w_return_status,
      x_msg_count       => w_msg_count,
      x_msg_data        => w_msg_data,
      x_vendor_id       => w_vendor_id,
      x_party_id        => w_party_id
    );
    print_log('  Retorno       :'||w_return_status);
    print_log('  Vendor Id     :'||w_vendor_id);
    print_log('  Party Id      :'||w_party_id);
    --
    for i in 1 .. w_msg_count loop
      w_msg_data := fnd_msg_pub.get( 
        p_msg_index => i, 
        p_encoded   => 'F'
      );
      print_log('  '|| i|| ') '|| w_msg_data);
    end loop;
    --
    if (w_return_status <> 'S') then
      --rollback to inicio;
      ok:=false;
      if (w_vendor_id is not null) then
        w_return_status := 'Já existe um Cliente com esses dados cadastrados.';
      end if;
      goto fim;
    end if;
    --
    -- ************************************************************
    print_log('');
    l_vendor_site_rec.vendor_id                   := w_vendor_id;
    l_vendor_site_rec.vendor_site_code            := '001';--l_vendor_rec.segment1;
    l_vendor_site_rec.area_code                   := w_cliente.ddd;
    l_vendor_site_rec.phone                       := w_cliente.cel_numero;
    l_vendor_site_rec.address_line1               := w_cliente.endereco;
    l_vendor_site_rec.address_line2               := w_cliente.numero;
    l_vendor_site_rec.address_line3               := w_cliente.complemento;        --COMPLEMENTO
    l_vendor_site_rec.address_line4               := w_cliente.bairro;  --BAIRRO
    l_vendor_site_rec.city                        := w_cliente.cidade;
    l_vendor_site_rec.state                       := w_cliente.estado;
    l_vendor_site_rec.zip                         := w_cliente.cep;
    l_vendor_site_rec.email_address               := w_cliente.email;
    l_vendor_site_rec.country                     := 'BR';
    l_vendor_site_rec.org_id                      := w_cliente.org_id;

    l_vendor_site_rec.address_style               := 'BR';
    l_vendor_site_rec.pay_date_basis_lookup_code  := 'DISCOUNT';
    l_vendor_site_rec.country_of_origin_code      := 'BR';
    l_vendor_site_rec.create_debit_memo_flag      := 'N';
    l_vendor_site_rec.global_attribute1           := 'N'; 
    
    l_vendor_site_rec.global_attribute9           := w_cliente.tipo_documento; 
    if(w_cliente.tipo_documento = '2') then                                    --CNPJ    
      l_vendor_site_rec.global_attribute10        := substr(w_cliente.documento, 1, 8); 
      l_vendor_site_rec.global_attribute11        := substr(w_cliente.documento, 9, 4); 
      l_vendor_site_rec.global_attribute12        := substr(w_cliente.documento,13, 2);
      l_vendor_site_rec.global_attribute13        := w_cliente.inscricao;
    else
      l_vendor_site_rec.global_attribute10        := substr(w_cliente.documento, 1, 9); 
      l_vendor_site_rec.global_attribute11        := null; 
      l_vendor_site_rec.global_attribute12        := substr(w_cliente.documento, 10, 2);  
      l_vendor_site_rec.global_attribute13        := 'ISENTO';
    end if;
    
    --l_vendor_site_rec.GLOBAL_ATTRIBUTE6           := w_cliente.inscricao;  --I Estadual.
    --l_vendor_site_rec.GLOBAL_ATTRIBUTE7           := INSCRICAO_MUNICIPAL;
    
    l_vendor_site_rec.global_attribute15          := 'COMERCIAL';

    l_vendor_site_rec.purchasing_site_flag        := 'Y';
    l_vendor_site_rec.pay_site_flag               := 'Y';
    l_vendor_site_rec.rfq_only_site_flag          := 'N';
    --
    --l_vendor_site_rec.CUSTOMER_NUM          :=
    --l_vendor_site_rec.SHIP_TO_LOCATION_ID   :=
    --l_vendor_site_rec.BILL_TO_LOCATION_ID   := 
    --
    fnd_msg_pub.initialize;
    print_log('Chamando POS_VENDOR_PUB_PKG.CREATE_VENDOR_SITE...');
    pos_vendor_pub_pkg.create_vendor_site (
      p_vendor_site_rec => l_vendor_site_rec,
      --
      x_vendor_site_id  => w_vendor_site_id,
      x_party_site_id   => w_party_site_id,
      x_location_id     => w_location_id,
      --
      x_return_status   => w_return_status,
      x_msg_count       => w_msg_count,
      x_msg_data        => w_msg_data
    );
    print_log('  Retorno       :'||w_return_status);
    print_log('  Vendor Site Id:'||w_vendor_site_id);
    print_log('  Party Site Id :'||w_party_site_id);
    print_log('  Locations Id  :'||w_location_id);
    
    for i in 1 .. w_msg_count loop
      w_msg_data := fnd_msg_pub.get( 
        p_msg_index => i, 
        p_encoded   => 'F'
      );
      print_log('  '|| i|| ') '|| w_msg_data);
    end loop;
    --
    if (w_return_status <> 'S') then
      --rollback to inicio;
	    ok:=false;
      goto fim;
    end if;

    --  return;
    <<fim>>
    print_log('FIM CREATE VENDOR');null;
  exception when others then
    --rollback to inicio;
    ok:=false;
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
    
    l_classe_cliente        varchar2(100);
    
  begin
    --initialize_ar;
    print_log('INICIO CREATE CUSTOMER');
    
    -- **********************************************************************************
    -- CREATE_CUST_ACCOUNT 
    p_cust_account_rec.account_name                     := w_cliente.nome;
    p_cust_account_rec.account_number                   := w_cliente.documento;
    p_cust_account_rec.orig_system_reference            := w_party_id;
    p_cust_account_rec.created_by_module                := 'HZ_CPUI'; --'TCA_V2_API';
    --             
    p_organization_rec.party_rec.party_id               := w_party_id;
    p_organization_rec.party_rec.orig_system_reference  := w_party_id;
    -- Busca Classe do Contribuinte
    begin
      if(w_cliente.tipo_documento = '2') then --CNPJ
        l_classe_cliente := 'Pessoa Juridica Varejo';
      else
        l_classe_cliente := 'Pessoa Fisica';
      end if;  
      
      select PROFILE_CLASS_ID 
      into p_customer_profile_rec.profile_class_id
      from hz_cust_profile_classes 
      where 1=1
        and STATUS = 'A'
        and NAME = l_classe_cliente
      ;
    exception when others then
      ok:=false;
      --rollback to inicio;
      l_return_status := 'Erro ao buscar Classe do Contribuinte:'||sqlerrm;
      print_log('  **'||l_return_status);
      goto fim;
    end;
    --Condição de pagamento 'A VISTA'
    p_customer_profile_rec.standard_terms   := 1000;
    print_log('');
    print_log('Chamando HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT...');
    fnd_msg_pub.initialize;
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
    print_log('  Retorno        :'||l_return_status);
    print_log('  Cust Account Id:'||w_cust_account_id);
    print_log('  Account Number :'||w_account_number);
    print_log('  Party Id       :'||w_party_id);
    print_log('  Party Number   :'||w_party_number);
    print_log('  Profile Id     :'||w_profile_id);
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
      --rollback to inicio;
      ok := false;
      goto fim;
    end if;
    -- **********************************************************************************
    -- CREATE_CUST_ACCT_SITE    
    p_cust_acct_site_rec.cust_account_id   := w_cust_account_id;
    p_cust_acct_site_rec.party_site_id     := w_party_site_id; 
    p_cust_acct_site_rec.created_by_module := 'HZ_CPUI';  --'TCA_V2_API';
    p_cust_acct_site_rec.global_attribute2 := w_cliente.tipo_documento;
    p_cust_acct_site_rec.global_attribute_category := 'JL.BR.ARXCUDCI.Additional';

    if(w_cliente.tipo_documento = '2') then --CNPJ
      p_cust_acct_site_rec.global_attribute8 := 'PJ NAO CONTRIBUINTE';
      p_cust_acct_site_rec.global_attribute3 := '0'||substr(w_cliente.documento, 1, 8); 
      p_cust_acct_site_rec.global_attribute4 := substr(w_cliente.documento, 9, 4); 
      p_cust_acct_site_rec.global_attribute5 := substr(w_cliente.documento,13, 2);      
    else
      p_cust_acct_site_rec.global_attribute8 := 'PF NAO CONTRIBUINTE';
      p_cust_acct_site_rec.global_attribute3 := substr(w_cliente.documento, 1, 9); 
      p_cust_acct_site_rec.global_attribute4 := null;
      p_cust_acct_site_rec.global_attribute5 := substr(w_cliente.documento,10, 2);  
    end if;
    --
    print_log('');
    print_log('Chamando HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE...');
    fnd_msg_pub.initialize;
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE(
      p_init_msg_list         => FND_API.G_TRUE,
      p_cust_acct_site_rec    => p_cust_acct_site_rec,
      x_cust_acct_site_id     => w_cust_acct_site_id,
      x_return_status         => l_return_status,
      x_msg_count             => l_msg_count,
      x_msg_data              => l_msg_data
    );
    print_log('  Retorno          :'||l_return_status);
    print_log('  Cust Acct Site Id:'||w_cust_acct_site_id);
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
      ok:=false;
      --rollback to inicio;
      goto fim;
    end if;
    
    -- **********************************************************************************
    -- CREATE_CUST_SITE_USE 
    p_cust_site_use_rec.cust_acct_site_id := w_cust_acct_site_id;
    p_cust_site_use_rec.location          := w_account_number;
    p_cust_site_use_rec.created_by_module := 'HZ_CPUI';
    print_log('');
    print_log('Chamando HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE... (BILL_TO)');
    p_cust_site_use_rec.site_use_code     := 'BILL_TO';
    fnd_msg_pub.initialize;
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
    print_log('  Retorno       :'||l_return_status);
    print_log('  Site Use Id   :'||w_site_use_id);
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
      ok:=false;
      --rollback to inicio;
      goto fim;
    end if;
    -- **********************************************************
    print_log('');
    print_log('Chamando HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE... (SHIP_TO)');
    p_cust_site_use_rec.site_use_code     := 'SHIP_TO';
    fnd_msg_pub.initialize;
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
    print_log('  Retorno       :'||l_return_status);
    print_log('  Site Use Id   :'||w_site_use_id);
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
      ok:=false;
      --rollback to inicio;
      goto fim;
    end if;
    <<fim>>
    w_return_status := l_return_status;
    w_msg_count     := l_msg_count;
    w_msg_data      := l_msg_data;
    print_log('FIM CREATE CUSTOMER');
  exception when others then
    --rollback to inicio;
    ok:=false;
    print_log(sqlerrm);
  end;

  procedure criar_cliente (
    p_cliente       in cliente_rec_type,
    x_vendor_id     out number,
    x_customer_id   out number,
    x_return_status out VARCHAR2,
    x_msg_count     out NUMBER,
    x_msg_data      out VARCHAR2
  ) is

  BEGIN
    SAVEPOINT Inicio;
    w_cliente := p_cliente;
    print_log('---------------------------------------------------------------------------');
    print_log('INICIO DO PROCESSO CLI FRENTE DE CAIXA '||TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));
    print_log('---------------------------------------------------------------------------');
    limpa_variaveis;
    begin
    select name
      into w_ou_name
      from hr_operating_units
      where organization_id=w_cliente.org_id
    ;	
    exception when others then
      x_return_status := 'Erro ao buscar a Unidade Operacional:'||w_cliente.org_id;
      ok:=false;
      goto fim;
    end;
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
    print_log('Email         :'||w_cliente.email);
    --
    print_log('');
    
    create_vendor;
    if (ok) then 
      create_customer;
      if (ok) then
        w_return_status := 'S';
      else
        ROLLBACK to Inicio;
      end if;
    end if;

    x_return_status := w_return_status;
    x_msg_count     := w_msg_count;
    x_msg_data      := w_msg_data;

    x_vendor_id     := w_vendor_id;
    x_customer_id   := w_cust_account_id;

    <<fim>>

    print_log('---------------------------------------------------------------------------');
    print_log('FIM DO PROCESSO CLI FRENTE DE CAIXA '||TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));
    print_log('---------------------------------------------------------------------------');
  exception when others then
    rollback to inicio;
    x_return_status := sqlerrm;
  end;

END XXFR_FCX_PCK_CLIENTES;