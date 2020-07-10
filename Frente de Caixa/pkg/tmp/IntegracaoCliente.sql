declare
   ---------------------------------------------------------------------------------------------------
   -- Cursor para Popular Clientes (HZ_CUST_ACCOUNTS)*
   ---------------------------------------------------------------------------------------------------
   cursor cur_cliente is
      select ap.vendor_id
            ,ap.party_id
            ,ap.segment1
            ,ap.vendor_name
            ,(select to_number(ap1.attribute1)
                from ap_supplier_sites_all ap1
               where ap1.vendor_id = ap.vendor_id
                 and ap1.attribute1 is not null
                 and rownum = 1) cd_pessoa
             --
            ,nvl((select pe.ie_cooperado
                   from pessoa@ebs            pe
                       ,ap_supplier_sites_all ap2
                  where pe.cd_empresa = 2
                    and pe.cd_pessoa = to_number(ap2.attribute1)
                    and ap2.vendor_id = ap.vendor_id
                    and rownum = 1)
                ,'N') ie_cooperado
             --
            ,nvl((select pe.ie_cooperativa
                   from pessoa@ebs            pe
                       ,ap_supplier_sites_all ap3
                  where pe.cd_empresa = 2
                    and pe.cd_pessoa = to_number(ap3.attribute1)
                    and ap3.vendor_id = ap.vendor_id
                    and rownum = 1)
                ,'N') ie_cooperativa
             --
            ,(select pe.cd_cpf
                from pessoa@ebs            pe
                    ,ap_supplier_sites_all ap3
               where pe.cd_empresa = 2
                 and pe.cd_pessoa = to_number(ap3.attribute1)
                 and ap3.vendor_id = ap.vendor_id
                 and rownum = 1) cd_cpf
             --
            ,(select pe.cd_cgc
                from pessoa@ebs            pe
                    ,ap_supplier_sites_all ap3
               where pe.cd_empresa = 2
                 and pe.cd_pessoa = to_number(ap3.attribute1)
                 and ap3.vendor_id = ap.vendor_id
                 and rownum = 1) cd_cgc
             --
            ,nvl((select fnc_ie_funcionario_cliente@ebs(pe.cd_empresa
                                                      ,3
                                                      ,pe.cd_pessoa)
                   from pessoa@ebs            pe
                       ,ap_supplier_sites_all ap3
                  where pe.cd_empresa = 2
                    and pe.cd_pessoa = to_number(ap3.attribute1)
                    and ap3.vendor_id = ap.vendor_id
                    and rownum = 1)
                ,'N') ie_funcionario_cliente
        from ap_suppliers ap
       where exists (select 1
                from pessoa@ebs            pes
                    ,ap_supplier_sites_all apall
               where pes.cd_empresa = 2
                 and pes.cd_pessoa = to_number(apall.attribute1)
                 and (pes.ie_cliente = 'S' or pes.ie_cooperado = 'S' or
                     pes.ie_fornecedor = 'S')
                 and apall.vendor_id = ap.vendor_id)
          --
         and not exists (select 1
                           from hz_cust_acct_sites_all acct
                               ,ap_supplier_sites_all  apall
                          where acct.attribute19 = apall.attribute1
                            and acct.attribute20 = apall.attribute2
                            and apall.vendor_id  = ap.vendor_id) -- Que não exista a propriedade no Cliente
          --
         and not exists (select 1
                from filial@ebs            pe
                    ,ap_supplier_sites_all ap3
               where pe.cd_empresa = 2
                 and pe.cd_pessoa = to_number(ap3.attribute1)
                 and ap3.vendor_id = ap.vendor_id
                 and rownum = 1) -- Que não seja Filial
     order by 5; -- cd_pessoa
   ---------------------------------------------------------------------------------------------------
   -- Curso para Popular Locais (HZ_CUST_ACCT_SITES_ALL)
   ---------------------------------------------------------------------------------------------------
   cursor cur_local(p_vendor_id number) is
      select o.vendor_site_id
            ,o.vendor_id
            ,o.party_site_id
            ,o.vendor_site_code
            ,o.vendor_site_code_alt
            ,o.attribute2 nr_propriedade
            ,o.global_attribute9 global_attribute2
            ,o.global_attribute10 global_attribute3
            ,o.global_attribute11 global_attribute4
            ,o.global_attribute12 global_attribute5
            ,o.global_attribute13 global_attribute6
            ,case
                when fnc_remove_caracter@ebs(o.global_attribute13) is null then
                 'NAO CONTRIBUINTE'
                when fnc_remove_caracter@ebs(o.global_attribute13) =
                     'ISENTO' then
                 'NAO CONTRIBUINTE'
                else
                 'CONTRIBUINTE'
             end global_attribute8
        from ap_supplier_sites_all o
       where o.vendor_id = p_vendor_id
         and o.inactive_date is null 
         and not exists (select 1
                           from hz_cust_acct_sites_all acct
                          where acct.attribute19 = o.attribute1
                            and acct.attribute20 = o.attribute2) -- Que não exista a propriedade já gerada no Cliente...
       order by o.vendor_site_id;
   --------------------------
   -- Cliente              --
   --------------------------
   l_cust_account_rec     hz_cust_account_v2pub.cust_account_rec_type;
   l_organization_rec     hz_party_v2pub.organization_rec_type;
   l_customer_profile_rec hz_customer_profile_v2pub.customer_profile_rec_type;
   --
   l_cust_account_id   hz_cust_accounts.cust_account_id%type;
   l_account_number    hz_cust_accounts.account_number%type;
   l_party_id          hz_parties.party_id%type;
   l_party_number      hz_parties.party_number%type;
   va_nm_classe_perfil varchar2(60); -- Roger Ok
   l_profile_id        number;
   va_ie_existe_conta  varchar2(1);
   --------------------------
   -- Locais               --
   --------------------------
   l_cust_acct_site_rec    hz_cust_account_site_v2pub.cust_acct_site_rec_type;
   l_party_site_id         hz_party_sites.party_site_id%type;
   l_cust_acct_site_id     number;
   l_object_version_number number;
   va_ie_existe_local      varchar2(1);
   --------------------------
   -- Objetivos Comerciais --
   --------------------------
   l_cust_site_use_rec        hz_cust_account_site_v2pub.cust_site_use_rec_type;
   l_site_use_id_ship         hz_cust_site_uses_all.site_use_id%type;
   l_site_use_id              hz_cust_site_uses_all.site_use_id%type;
   va_ie_existe_entregar_para varchar2(1);
   va_ie_existe_faturar_para  varchar2(1);
   --------------------------
   -- Mensagens            --
   --------------------------
   l_error_message varchar2(4000);
   l_return_status varchar2(1000);
   l_msg_count     number;
   l_msg_data      varchar2(10000);
   va_ie_erro      varchar2(1);
   --------------------------
   -- Inicializaçao GLobal --
   --------------------------
   va_org_id       number;
   va_user_id      number;
   va_resp_id      number;
   va_resp_appl_id number;
   --------------------------
   -- Sincronização        --
   --------------------------
   l_request_id fnd_concurrent_requests.request_id%type;
   bcontinuar   boolean;
   bwait        boolean;
   nrequest_id  number;
   vphase       varchar2(50);
   vstatus      varchar2(50);
   vdev_phase   varchar2(50);
   vdev_status  varchar2(50);
   vmessage     varchar2(500);
   verro        varchar2(2);
   wtime_over   number := 0;
   --------------------------
   -- Controle Carga       --
   --------------------------
   va_nr_contador number;
   va_nr_parada   number := 2000;
begin
   --------------------------
   -- Inicializaçao Global --
   --------------------------
   -- Organização          --
   --------------------------
   dbms_output.put_line('Início');
   --
   begin
      select organization_id
        into va_org_id
        from hr_operating_units;
   exception
      when others then
         raise_application_error(-20001
                                ,'Erro busca organization_id: ' || sqlerrm);
   end;
   --------------------------
   -- Usuário              --
   --------------------------
   begin
      select user_id
        into va_user_id
        from fnd_user
       where user_name = 'DIOGO.MENDES';
   exception
      when others then
         raise_application_error(-20001, 'Erro busca user_id: ' || sqlerrm);
   end;
   --------------------------
   -- Responsabilidade     --
   --------------------------
   begin
      select responsibility_id
        into va_resp_id
        from fnd_responsibility_tl
       where responsibility_name = 'FRISIA_AR_SUPERUSUARIO'
         and language = 'PTB';
   exception
      when others then
         raise_application_error(-20001
                                ,'Erro busca responsibility_id: ' ||
                                 sqlerrm);
   end;
   --------------------------
   -- Aplicação            --
   --------------------------
   begin
      select application_id
        into va_resp_appl_id
        from fnd_application
       where application_short_name = 'AR';
   exception
      when others then
         raise_application_error(-20001
                                ,'Erro busca application_id: ' || sqlerrm);
   end;
   --
   fnd_global.apps_initialize(user_id      => va_user_id
                             ,resp_id      => va_resp_id
                             ,resp_appl_id => va_resp_appl_id);
   mo_global.set_policy_context('S', va_org_id);
   mo_global.init('AR');
   --
   for reg_cliente in cur_cliente
   loop
      va_nr_contador := nvl(va_nr_contador,0) + 1;
      dbms_output.put_line('Pessoa: ' || reg_cliente.cd_pessoa || '-' ||
                           reg_cliente.vendor_name);
      ---------------------------------------------------------------------------------------------------
      -- Criação Cabeçalho Cliente (HZ_CUST_ACCOUNTS)
      ---------------------------------------------------------------------------------------------------
      --
      va_ie_erro                         := 'N';
      l_object_version_number            := null;
      l_cust_account_id                  := null; -- Teste Roger
      l_cust_account_rec                 := null; -- Teste Roger
      l_cust_account_rec.cust_account_id := null;
      --
      if reg_cliente.ie_cooperado = 'S' and
         reg_cliente.ie_cooperativa = 'N' then
         l_cust_account_rec.account_number := reg_cliente.cd_pessoa;
       --l_cust_account_rec.account_name   := reg_cliente.vendor_name;
      else
         l_cust_account_rec.account_number := reg_cliente.segment1;
       --l_cust_account_rec.account_name   := reg_cliente.vendor_name;
      end if;
      --
      l_cust_account_rec.status              := 'A';
      l_cust_account_rec.customer_type       := 'R';
      l_cust_account_rec.customer_class_code := null;
      l_cust_account_rec.created_by_module   := 'HZ_CPUI';
      l_cust_account_rec.application_id      := va_resp_appl_id;
      l_cust_account_rec.attribute19         := reg_cliente.cd_pessoa;
      --
      l_organization_rec                    := null; -- Teste Roger
      l_organization_rec.party_rec.party_id := reg_cliente.party_id;
      l_organization_rec.organization_name  := reg_cliente.vendor_name;
      --
      if reg_cliente.ie_cooperado = 'S' then
         va_nm_classe_perfil := 'COOPERADO';
      elsif reg_cliente.ie_funcionario_cliente = 'S' then
         va_nm_classe_perfil := 'FUNCIONARIO';
      elsif reg_cliente.cd_cpf is not null then
         va_nm_classe_perfil := 'PESSOA FISICA';
      elsif reg_cliente.cd_cgc is not null then
         va_nm_classe_perfil := 'Pessoa Juridica Varejo';
      else
         va_nm_classe_perfil := 'DEFAULT';
      end if;
      --
      l_customer_profile_rec                   := null; -- Teste Roger
      l_customer_profile_rec.created_by_module := 'HZ_CPUI';
      --
      /* Novo 13/03/2020 Se Precisar...
      l_customer_profile_rec.credit_rating     := l_class_credito;
      l_customer_profile_rec.risk_code         := l_codigo_risco;
      l_customer_profile_rec.credit_checking   := 'Y';
      if C1.tipo_venda = 'APRAZO' then  
         l_customer_profile_rec.credit_hold    := 'Y';
      elsif C1.tipo_venda = 'AVISTA' then
         l_customer_profile_rec.credit_hold    := 'N';
      end if;
      */
      --
      begin
         select profile_class_id
               ,global_attribute_category
               ,global_attribute1
               ,global_attribute2
               ,global_attribute3
               ,global_attribute4
               ,global_attribute5
               ,global_attribute6
               ,global_attribute7
           into l_customer_profile_rec.profile_class_id
               ,l_customer_profile_rec.global_attribute_category
               ,l_customer_profile_rec.global_attribute1
               ,l_customer_profile_rec.global_attribute2
               ,l_customer_profile_rec.global_attribute3
               ,l_customer_profile_rec.global_attribute4
               ,l_customer_profile_rec.global_attribute5
               ,l_customer_profile_rec.global_attribute6
               ,l_customer_profile_rec.global_attribute7
           from hz_cust_profile_classes
          where upper(name) = upper(va_nm_classe_perfil);
      exception
         when others then
            rollback;
            raise_application_error(-20001,'Erro busca hz_cust_profile_classes: '||sqlerrm);
      end;
      --   
      begin
         select 'S'
               ,h.cust_account_id
               ,h.object_version_number
           into va_ie_existe_conta
               ,l_cust_account_id
               ,l_object_version_number
           from hz_cust_accounts h
          where h.orig_system_reference = reg_cliente.cd_pessoa;
         --
         l_cust_account_rec.cust_account_id := l_cust_account_id; -- Se existirm utilizar o id para o update
         --
      exception
         when no_data_found then
            va_ie_existe_conta                       := 'N';
            l_cust_account_rec.orig_system_reference := reg_cliente.cd_pessoa;
         when others then
            rollback;
            raise_application_error(-20001
                                   ,'Erro busca hz_cust_accounts: ' ||
                                    sqlerrm);
      end;
      --
      l_return_status := null;
      l_msg_count     := null;
      l_msg_data      := null;
      l_error_message := null;
      --
      dbms_output.put_line('va_ie_existe_conta: '||va_ie_existe_conta);
      --
      if va_ie_existe_conta = 'N' then
         begin
            apps.hz_cust_account_v2pub.create_cust_account(p_init_msg_list        => fnd_api.g_true
                                                          ,p_cust_account_rec     => l_cust_account_rec
                                                          ,p_organization_rec     => l_organization_rec
                                                          ,p_customer_profile_rec => l_customer_profile_rec
                                                          ,p_create_profile_amt   => fnd_api.g_false
                                                          ,x_cust_account_id      => l_cust_account_id
                                                          ,x_account_number       => l_account_number
                                                          ,x_party_id             => l_party_id
                                                          ,x_party_number         => l_party_number
                                                          ,x_profile_id           => l_profile_id
                                                          ,x_return_status        => l_return_status
                                                          ,x_msg_count            => l_msg_count
                                                          ,x_msg_data             => l_msg_data);
         end;
      else
         begin
            apps.hz_cust_account_v2pub.update_cust_account(p_init_msg_list         => fnd_api.g_true
                                                          ,p_cust_account_rec      => l_cust_account_rec
                                                          ,p_object_version_number => l_object_version_number
                                                          ,x_return_status         => l_return_status
                                                          ,x_msg_count             => l_msg_count
                                                          ,x_msg_data              => l_msg_data);
         end;
      end if;
      --
      if l_return_status <> apps.fnd_api.g_ret_sts_success then
         l_error_message := 'Erro1 na execução da API create_cust_account:';
         for i in 1 .. l_msg_count
         loop
            l_msg_data      := fnd_msg_pub.get(i, 'F');
            l_error_message := l_error_message ||
                               substr(l_msg_data, 1, 255);
         end loop;
         dbms_output.put_line(l_error_message);
         va_ie_erro := 'S';
      end if;
      ---------------------------------------------------------------------------------------------------
      -- Criação Locais (HZ_CUST_ACCT_SITES_ALL) (CNPJ/CPF/INSCRICAO)
      ---------------------------------------------------------------------------------------------------
      if nvl(l_return_status, 'S') = 'S' then
         for reg_local in cur_local(reg_cliente.vendor_id)
         loop
            --
            l_object_version_number                        := null;
            l_cust_acct_site_rec                           := null; -- Teste Roger
            l_cust_acct_site_rec.cust_account_id           := l_cust_account_id;
            l_cust_acct_site_rec.party_site_id             := reg_local.party_site_id;
            l_cust_acct_site_rec.created_by_module         := 'HZ_CPUI';
            l_cust_acct_site_rec.global_attribute_category := 'JL.BR.ARXCUDCI.Additional';
            l_cust_acct_site_rec.global_attribute2         := reg_local.global_attribute2;
            l_cust_acct_site_rec.global_attribute3         := reg_local.global_attribute3;
            l_cust_acct_site_rec.global_attribute4         := reg_local.global_attribute4;
            l_cust_acct_site_rec.global_attribute5         := reg_local.global_attribute5;
            l_cust_acct_site_rec.global_attribute6         := reg_local.global_attribute6;
            l_cust_acct_site_rec.global_attribute8         := reg_local.global_attribute8;
            l_cust_acct_site_rec.attribute19               := reg_cliente.cd_pessoa;
            l_cust_acct_site_rec.attribute20               := reg_local.nr_propriedade;
            l_cust_acct_site_rec.application_id            := va_resp_appl_id;
            l_cust_acct_site_rec.org_id                    := va_org_id;
            --
            begin
               select 'S'
                     ,h.cust_acct_site_id
                     ,h.object_version_number
                 into va_ie_existe_local
                     ,l_cust_acct_site_rec.cust_acct_site_id
                     ,l_object_version_number
                 from hz_cust_acct_sites_all h
                where h.cust_account_id = l_cust_account_id
                  and h.party_site_id = reg_local.party_site_id;
                -- Não pode Atualizar
                l_cust_acct_site_rec.application_id := null; -- Novo 15/04/2020;
                --
            exception
               when no_data_found then
                  va_ie_existe_local := 'N';
               when others then
                  rollback;
                  raise_application_error(-20001
                                         ,'Erro busca HZ_CUST_ACCT_SITES_ALL: ' ||
                                          sqlerrm);
            end;
            --
            l_return_status := null;
            l_msg_count     := null;
            l_msg_data      := null;
            l_error_message := null;
            --
            if va_ie_existe_local = 'N' then
               begin
                  apps.hz_cust_account_site_v2pub.create_cust_acct_site(p_init_msg_list      => fnd_api.g_true
                                                                       ,p_cust_acct_site_rec => l_cust_acct_site_rec
                                                                       ,x_cust_acct_site_id  => l_cust_acct_site_id
                                                                       ,x_return_status      => l_return_status
                                                                       ,x_msg_count          => l_msg_count
                                                                       ,x_msg_data           => l_msg_data);
               end;
            else
               begin
                  apps.hz_cust_account_site_v2pub.update_cust_acct_site(p_init_msg_list         => fnd_api.g_true
                                                                       ,p_cust_acct_site_rec    => l_cust_acct_site_rec
                                                                       ,p_object_version_number => l_object_version_number
                                                                       ,x_return_status         => l_return_status
                                                                       ,x_msg_count             => l_msg_count
                                                                       ,x_msg_data              => l_msg_data);
               end;
            end if;
            --
            dbms_output.put_line('CustAcctSiteId (CNPJ/CPF): '||nvl(l_cust_acct_site_id,l_cust_acct_site_rec.cust_acct_site_id));
            --
            if l_return_status <> apps.fnd_api.g_ret_sts_success then
               l_error_message := 'Erro2 na execução da API create_cust_acct_site';
               for i in 1 .. l_msg_count
               loop
                  l_msg_data      := fnd_msg_pub.get(i, 'F');
                  l_error_message := l_error_message ||
                                     substr(l_msg_data, 1, 255);
               end loop;
               dbms_output.put_line(l_error_message);
               va_ie_erro := 'S';
            end if;
            ---------------------------------------------------------------------------------------------------
            -- Criação Objetivos Comerciais (HZ_CUST_SITE_USES_ALL) (Faturar Para)
            ---------------------------------------------------------------------------------------------------
            if nvl(l_return_status, 'S') = 'S' then
               l_cust_site_use_rec                     := null; -- Teste Roger
               l_cust_site_use_rec.cust_acct_site_id   := nvl(l_cust_acct_site_id
                                                             ,l_cust_acct_site_rec.cust_acct_site_id);
               l_cust_site_use_rec.site_use_code       := 'BILL_TO';
               l_cust_site_use_rec.primary_flag        := 'Y';
               l_cust_site_use_rec.bill_to_site_use_id := null;
               l_cust_site_use_rec.gl_id_rec           := null; -- Conta GL -- Não Precisa -- Confirmado Eduardo
               l_cust_site_use_rec.gl_id_rev           := null; -- Conta GL -- Não Precisa -- Confirmado Eduardo
               l_cust_site_use_rec.created_by_module   := 'HZ_CPUI';
               l_cust_site_use_rec.location            := reg_local.vendor_site_code;
               l_cust_site_use_rec.application_id      := va_resp_appl_id;
               l_cust_site_use_rec.org_id              := va_org_id;
               --
               begin
                  select 'S'
                    into va_ie_existe_faturar_para
                    from hz_cust_site_uses_all hcsu
                   where hcsu.site_use_code = 'BILL_TO'
                     and nvl(hcsu.status, 'A') = 'A'
                     and hcsu.cust_acct_site_id =
                         l_cust_site_use_rec.cust_acct_site_id;
               exception
                  when no_data_found then
                     va_ie_existe_faturar_para                 := 'N';
                     l_cust_site_use_rec.orig_system_reference := reg_local.nr_propriedade;
                  when others then
                     rollback;
                     raise_application_error(-20001
                                            ,'Erro busca hz_cust_site_uses_all: ' ||
                                             sqlerrm);
               end;
               --
               l_return_status := null;
               l_msg_count     := null;
               l_msg_data      := null;
               l_error_message := null;
               --
               if va_ie_existe_faturar_para = 'N' then
                  begin
                     apps.hz_cust_account_site_v2pub.create_cust_site_use(p_init_msg_list        => fnd_api.g_true
                                                                         ,p_cust_site_use_rec    => l_cust_site_use_rec
                                                                         ,p_customer_profile_rec => l_customer_profile_rec
                                                                         ,p_create_profile       => null
                                                                         ,p_create_profile_amt   => null
                                                                         ,x_site_use_id          => l_site_use_id_ship
                                                                         ,x_return_status        => l_return_status
                                                                         ,x_msg_count            => l_msg_count
                                                                         ,x_msg_data             => l_msg_data);
                  end;
                  --
                  dbms_output.put_line('Objetivo Comercial BILL_TO: '||reg_local.vendor_site_code);
                  --
               end if;
               --
               if l_return_status <> apps.fnd_api.g_ret_sts_success then
                  l_error_message := 'Erro3 na execução da API create_cust_acct_site';
                  for i in 1 .. l_msg_count
                  loop
                     l_msg_data      := fnd_msg_pub.get(i, 'F');
                     l_error_message := l_error_message ||
                                        substr(l_msg_data, 1, 255);
                  end loop;
                  dbms_output.put_line(l_error_message);
                  va_ie_erro := 'S';
               end if;
               ---------------------------------------------------------------------------------------------------
               -- Criação Objetivos Comerciais (HZ_CUST_SITE_USES_ALL) (Entregar Para)
               ---------------------------------------------------------------------------------------------------
               if nvl(l_return_status, 'S') = 'S' then
                  l_cust_site_use_rec                     := null;
                  l_cust_site_use_rec.cust_acct_site_id   := nvl(l_cust_acct_site_id
                                                                ,l_cust_acct_site_rec.cust_acct_site_id);
                  l_cust_site_use_rec.site_use_code       := 'SHIP_TO';
                  l_cust_site_use_rec.primary_flag        := 'Y';
                  l_cust_site_use_rec.bill_to_site_use_id := l_site_use_id_ship;
                  l_cust_site_use_rec.gl_id_rec           := null; -- Conta GL -- Não Precisa -- Confirmado Eduardo
                  l_cust_site_use_rec.gl_id_rev           := null; -- Conta GL -- Não Precisa -- Confirmado Eduardo
                  l_cust_site_use_rec.created_by_module   := 'HZ_CPUI';
                  l_cust_site_use_rec.location            := reg_local.vendor_site_code;
                  l_cust_site_use_rec.application_id      := va_resp_appl_id;
                  l_cust_site_use_rec.org_id              := va_org_id;
                  --
                  begin
                     select 'S'
                       into va_ie_existe_entregar_para
                       from hz_cust_site_uses_all hcsu
                      where hcsu.site_use_code = 'SHIP_TO'
                        and nvl(hcsu.status, 'A') = 'A'
                        and hcsu.cust_acct_site_id =
                            l_cust_site_use_rec.cust_acct_site_id;
                  exception
                     when no_data_found then
                        va_ie_existe_entregar_para                := 'N';
                        l_cust_site_use_rec.orig_system_reference := reg_local.nr_propriedade;
                     when others then
                        rollback;
                        raise_application_error(-20001
                                               ,'Erro busca hz_cust_site_uses_all: ' ||
                                                sqlerrm);
                  end;
                  --
                  l_return_status := null;
                  l_msg_count     := null;
                  l_msg_data      := null;
                  l_error_message := null;
                  --
                  if va_ie_existe_entregar_para = 'N' then
                     begin
                        apps.hz_cust_account_site_v2pub.create_cust_site_use(p_init_msg_list        => fnd_api.g_true
                                                                            ,p_cust_site_use_rec    => l_cust_site_use_rec
                                                                            ,p_customer_profile_rec => l_customer_profile_rec
                                                                            ,p_create_profile       => null
                                                                            ,p_create_profile_amt   => null
                                                                            ,x_site_use_id          => l_site_use_id_ship
                                                                            ,x_return_status        => l_return_status
                                                                            ,x_msg_count            => l_msg_count
                                                                            ,x_msg_data             => l_msg_data);
                     end;
                     --
                     dbms_output.put_line('Objetivo Comercial SHIP_TO: '||reg_local.vendor_site_code);
                     --
                  end if;
                  --
                  if l_return_status <> apps.fnd_api.g_ret_sts_success then
                     l_error_message := 'Erro4 na execução da API create_cust_acct_site';
                     for i in 1 .. l_msg_count
                     loop
                        l_msg_data      := fnd_msg_pub.get(i, 'F');
                        l_error_message := l_error_message ||
                                           substr(l_msg_data, 1, 255);
                     end loop;
                     dbms_output.put_line(l_error_message);
                     va_ie_erro := 'S';
                  end if;
               end if; -- if sucesso Objetivo Comercial (BILL_TO)
            end if; -- if sucesso Local
         end loop;
      end if; -- if sucesso Conta
      -----------------------------------------------------------------------------------
      -- Se ocorrer erro em qualquer ponto da carga do Cliente, desfaz tudo do cliente --
      -----------------------------------------------------------------------------------
      if va_ie_erro = 'N' then
         commit;
      else
         rollback;
      end if;
      --
      exit when va_nr_contador = va_nr_parada;
   end loop;
   /*
   -------------------------------------------------------------------------------------
   -- PÓS PROCESSAMENTO Chama o concorrente DQM para sincronizacao                    --
   -------------------------------------------------------------------------------------
   dbms_output.put_line('Vai chamar o concorrente para sincronizacao (DQM)');
   l_request_id := fnd_request.submit_request(application => 'AR'
                                             ,program     => 'ARHDQSYN'
                                             ,start_time  => sysdate
                                             ,sub_request => false
                                             ,argument1   => 2 -- Nr de Workers
                                             ,argument2   => 'N');
   -- recebem valores default e nao sao exibidos na chamada do concorrente
   dbms_output.put_line('Request_id:' || to_char(l_request_id));
   --
   if l_request_id = 0 then
      rollback;
      dbms_output.put_line('Erro ao chamar concorrente de sincronizacao.');
   else
      commit;
   end if;
   --
   bcontinuar := true;
   --
   while bcontinuar
   loop
      --
      wtime_over := nvl(wtime_over, 0) + 1;
      --
      dbms_lock.sleep(3);
      --
      bwait := fnd_concurrent.get_request_status(l_request_id
                                                ,''
                                                ,''
                                                ,vphase
                                                ,vstatus
                                                ,vdev_phase
                                                ,vdev_status
                                                ,vmessage);
      --
      if not bwait then
         dbms_output.put_line('Erro ao aguardar termino do concorrente de sincronizacao.');
      end if;
      --
      if vdev_phase = 'COMPLETE' then
         dbms_output.put_line('Completo');
         bcontinuar := false;
      end if;
      --
      if wtime_over > 5000 then
         bcontinuar := false;
         dbms_output.put_line('Erro ao aguardar termino do concorrente de sincronizacao: Timeout do processo.');
      end if;
      --
      commit; -- ***** NAO RETIRAR ESTE COMMIT!!!
   --
   end loop;
   --
   */
   dbms_output.put_line('Fim');
   dbms_output.put_line('Registros processados: '||va_nr_contador);
end;
/
