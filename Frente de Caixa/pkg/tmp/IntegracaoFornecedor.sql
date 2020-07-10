/*

Pesquisar script Conta Bancária

*/

/*
select *
  from cooperado_conta2 c
 where c.cd_pessoa in (4026
                      ,4073
                      ,4130
                      ,4135
                      ,4175
                      ,4216
                      ,4448
                      ,4451
                      ,4780
                      ,4866
                      ,4905
                      ,4943)
*/

-- https://alexpagliarinioracleebs.com/2019/09/26/criar-fornecedores-via-api/
/*
select pes.cd_pessoa
      ,pes.nm_pessoa
      ,pes.cd_cpf
      ,substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(pes.cd_cgc)), 1, 8) cnpj_raiz
      ,(select count(*)
          from propriedade@ebs pro
         where pro.cd_empresa = 2
           and pro.cd_pessoa = pes.cd_pessoa
           and pro.ie_situacao = 'A') count_prop
  from estado@ebs          est
      ,municipio@ebs       mun
      ,transportador@ebs   tra
      ,pessoa_juridica@ebs pju
      ,pessoa@ebs          pes
 where est.cd_pais = mun.cd_pais
   and est.cd_estado = mun.cd_estado
      --
   and mun.cd_pais = pes.cd_pais
   and mun.cd_estado = pes.cd_estado
   and mun.cd_municipio = pes.cd_municipio
      --
   and tra.cd_empresa(+) = pes.cd_empresa
   and tra.cd_pessoa(+) = pes.cd_pessoa
      --
   and pju.cd_empresa(+) = pes.cd_empresa
   and pju.cd_pessoa(+) = pes.cd_pessoa
      --
   and pes.cd_empresa = 2
   and pes.cd_situacao_pessoa = 'A'
   and ((pes.cd_cpf <> 0 or pes.cd_cgc <> 0) or (est.sg_estado = 'EX'))
   and sys_context('USERENV', 'DB_NAME') = 'CRP1' -- Modificar Roger
      --
   and (pes.ie_cliente = 'S' or pes.ie_cooperado = 'S' or
       pes.ie_fornecedor = 'S' or pes.ie_tecnico = 'S' or
       pes.ie_terceiro = 'S')
   and (pes.ie_funcionario = 'N')
         and not exists (select 1 -- Filiais será manual (Fernando)
                           from filial@ebs fil
                          where fil.cd_empresa = pes.cd_empresa
                            and fil.cd_pessoa = pes.cd_pessoa)
   and exists
 (select 1
          from propriedade@ebs prop2
         where prop2.cd_empresa = 2
           and prop2.cd_pessoa = pes.cd_pessoa
           and prop2.ie_situacao = 'A'
           and not exists
         (select 1
                  from ap_supplier_sites_all aa
                 where aa.attribute1 = prop2.cd_pessoa
                   and aa.attribute2 = prop2.nr_propriedade))
 order by 1 desc
*/
--
/*
select * from sis_log_processo@ebs
 where cd_processo = 'XXFRCARGAPESSOA';
*/
--
-- Zerar antes da primeira carga: CARGA_EBS_CAB_FORNEC_EX
--
declare
   -- Variáveis Globais
   va_cd_processo     varchar2(30)  := 'XXFRCARGAPESSOA';
   va_ds_string       varchar2(100) := null; -- '_X10';
   p_api_version      number        := 1.0;
   p_init_msg_list    varchar2(200) := fnd_api.g_true;
   p_commit           varchar2(200) := fnd_api.g_false;
   p_validation_level number        := fnd_api.g_valid_level_full;
   ln_new_org_id      number        := 81; -- Fernando
   --------------------------
   -- Inicializaçao GLobal --
   --------------------------
   va_org_id       number;
   va_user_id      number;
   va_resp_id      number;
   va_resp_appl_id number;
   --
   -- ESTADO SG_ESTADO = 'EX'
   --
   cursor cur_pessoa is
      select count(*) over ()
            ,pes.cd_empresa
            ,pes.cd_pessoa
            ,pes.nm_pessoa vendor_name
            ,nvl(pes.nm_reduzido,pes.nm_pessoa) vendor_name_alt
            ,pes.cd_cpf
            ,pes.cd_cgc
            ,est.sg_estado
            ,pes.ie_cooperado
            ,pes.ie_cliente
            ,pes.ie_fornecedor
            ,pes.ie_transportador
            ,pes.ie_tecnico
            ,pes.ie_funcionario
            ,pes.ie_cartorio
            ,pes.ie_terceiro
            ,pes.ie_motorista
            ,nvl(pes.ie_cooperativa,'N') ie_cooperativa
            ,pju.nr_inscricao_estadual
            ,nvl((select 'S'
                    from conhec_frete_entrada@ebs cfe
                   where cfe.cd_empresa = pes.cd_empresa
                     and cfe.cd_pessoa = pes.cd_pessoa
                     and cfe.ie_estornado = 'N'
                     and rownum = 1),'N') ie_conhecimento_frete
        from estado@ebs est
            ,municipio@ebs mun
            ,transportador@ebs tra
            ,pessoa_juridica@ebs pju
            ,pessoa@ebs pes
       where est.cd_pais = mun.cd_pais
         and est.cd_estado = mun.cd_estado
          --
         and mun.cd_pais = pes.cd_pais
         and mun.cd_estado = pes.cd_estado
         and mun.cd_municipio = pes.cd_municipio
          --
         and tra.cd_empresa (+) = pes.cd_empresa
         and tra.cd_pessoa (+) = pes.cd_pessoa
          --
         and pju.cd_empresa (+) = pes.cd_empresa
         and pju.cd_pessoa (+) = pes.cd_pessoa
          --
         and pes.cd_empresa = 2
         and pes.cd_situacao_pessoa = 'A'
         and ( (pes.cd_cpf <> 0 or pes.cd_cgc <> 0) OR
               (est.sg_estado = 'EX') )
      -- and sys_context('USERENV','DB_NAME') = 'CRP1' -- Modificar Roger
      -- and sys_context('USERENV','DB_NAME') = 'CRP2' -- Modificar Roger
         and sys_context('USERENV','DB_NAME') = 'CRPHML' 
          --
         and (pes.ie_cliente = 'S' or
              pes.ie_cooperado = 'S' or
              pes.ie_fornecedor = 'S' or
              pes.ie_tecnico = 'S' or
              pes.ie_terceiro = 'S')
         and nvl(pes.cd_cpf,pes.cd_cgc) not in (78594025000158) -- Checar duplicidades 3 Matrículas
         and exists (select 1
                       from propriedade@ebs prop
                      where prop.cd_empresa = pes.cd_empresa
                        and prop.cd_pessoa = pes.cd_pessoa
                        and prop.ie_situacao = 'A'
                        and not exists
                           (select 1
                              from ap_supplier_sites_all aa
                             where aa.attribute1 = prop.cd_pessoa
                               and aa.attribute2 = prop.nr_propriedade))
         and not exists (select 1 -- Filiais será manual (Fernando)
                           from filial@ebs fil
                          where fil.cd_empresa = pes.cd_empresa
                            and fil.cd_pessoa = pes.cd_pessoa)
         and pes.cd_pessoa <= 5000 -- Garantir que Filiais não subam
       order by pes.cd_pessoa;
   --
   cursor cur_propriedade(p_cd_empresa number
                         ,p_cd_pessoa  number) is
      select pro.cd_empresa
            ,pro.cd_pessoa
            ,pro.nr_propriedade
            ,pro.nm_propriedade
            ,pes.cd_cpf
            ,pes.cd_cgc
            ,pro.nr_cgc cd_cgc_propriedade
            ,pes.ie_cooperado
            ,nvl(pes.ie_cooperativa,'N') ie_cooperativa
            ,est.sg_estado
            ,pro.cd_pessoa        attribute1
            ,pro.nr_propriedade   attribute2
            ,pro.ds_endereco      address_line1
            ,nvl(pro.nr_logradouro,'S/N') address_line2
            ,pro.nm_propriedade   address_line3
            ,mun.nm_municipio     city
            ,est.sg_estado        state
            ,pro.nr_cep           zip
            ,pai.sg_internacional country
            ,nvl(pro.nm_bairro,pro.ds_localizacao) address_line4
            ,pai.sg_internacional address_style
             --
            ,case 
                when est.sg_estado = 'EX' then
                   3 -- Outros
                when pes.cd_cpf is not null then
                   1 -- CPF
               else
                   2 -- CNPJ
             end global_attribute9
             --
            ,case 
                when est.sg_estado = 'EX' then
                   null -- Estrangeiro
                when pes.cd_cpf is not null then
                   substr(fnc_remove_caracter@ebs(fnc_mask_cpf@ebs(pes.cd_cpf)),1,9)
                else
                   '0'||substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(pro.nr_cgc)),1,8)
                end global_attribute10
             --
            ,case
                when est.sg_estado = 'EX' then
                   null -- Estrangeiro        
                when pes.cd_cpf is not null then
                   '0000'
                else
                   substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(pro.nr_cgc)),9,4)
               end global_attribute11
             --
            ,case
                when est.sg_estado = 'EX' then
                   null -- Estrangeiro
                when pes.cd_cpf is not null then
                   substr(fnc_remove_caracter@ebs(fnc_mask_cpf@ebs(pes.cd_cpf)),10,2)
                else
                   substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(pro.nr_cgc)),13,2)
             end global_attribute12
             --
            ,case
                when est.sg_estado = 'EX' then
                   null -- Estrangeiro
                when fnc_inscricao_estadual@ebs(pro.cd_empresa
                                               ,pro.cd_pessoa
                                               ,pro.nr_propriedade) = 'ISENTO' then
                   'ISENTO'
                else
                   fnc_remove_caracter@ebs(fnc_inscricao_estadual@ebs(pro.cd_empresa
                                                                     ,pro.cd_pessoa
                                                                     ,pro.nr_propriedade))
             end global_attribute13
             --
            ,null global_attribute14 -- Inscrição Municipal
             --
            ,case
                when pes.ie_cooperado = 'S' then
                   'COOPERADO'
                when pro.cd_classificacao_destinatario = 1 then -- Contribuinte
                   'CONTRIBUINTE'
                when pro.cd_classificacao_destinatario = 2 then -- Não Contribuinte
                   'NAO CONTRIBUINTE'
                else
                   'COMERCIAL'
             end global_attribute15
        from pais@ebs pai
            ,estado@ebs est
            ,municipio@ebs mun
            ,pessoa@ebs pes 
            ,propriedade@ebs pro
       where pai.cd_pais = est.cd_pais
          --
         and est.cd_pais = mun.cd_pais
         and est.cd_estado = mun.cd_estado
         --
         and mun.cd_pais = pro.cd_pais
         and mun.cd_estado = pro.cd_estado
         and mun.cd_municipio = pro.cd_municipio
         --
         and pes.cd_empresa = pro.cd_empresa
         and pes.cd_pessoa = pro.cd_pessoa
          --
         and pro.cd_empresa = p_cd_empresa
         and pro.cd_pessoa = p_cd_pessoa
         and pro.ie_situacao = 'A'
          --
         and not exists
                  (select 1
                     from ap_supplier_sites_all aa
                    where aa.attribute1 = pro.cd_pessoa
                      and aa.attribute2 = pro.nr_propriedade);
  --
  --       and pro.nr_propriedade = 198142;
  --
   function fnc_codigo_ebs(p_ie_cabecalho_local      varchar2
                          ,p_cd_pessoa               number
                          ,p_nr_propriedade          number
                          ,p_cd_cpf                  number
                          ,p_cd_cgc                  number
                          ,p_ie_cooperado            varchar2
                          ,p_ie_cooperativa          varchar2
                          ,p_ie_residencia_cooperado varchar2
                          ,p_sg_estado_fornecedor    varchar2
                          ,p_segment1                varchar2) return varchar2 is
     va_ie_pessoa_fj     varchar2(1);
     va_segment1         varchar2(30);
     va_vendor_site_code varchar2(30);
     va_codigo_ebs       varchar2(30);
   begin
     if p_ie_cabecalho_local not in ('C','L') then
        raise_application_error(-20001,'Valor inválido para '||p_ie_cabecalho_local);
     end if;
     --
     if p_cd_cpf is not null then
        va_ie_pessoa_fj := 'F';
     elsif p_cd_cgc is not null then
        va_ie_pessoa_fj := 'J';
     end if;
     ------------------------------- ******
     -- Tratamento Cabeçalho      --
     -------------------------------
     if p_ie_cabecalho_local = 'C' then
        if p_sg_estado_fornecedor = 'EX' then
           -------------------------------------------------------
           -- Pessoa Estrangeira                                --
           -- Sequencial Numérico                               --
           -- Exemplo: 1, 2, 3...                               --
           -------------------------------------------------------
           va_segment1 := fnc_sequencia_unica@ebs('CARGA_EBS_CAB_FORNEC_EX');
        elsif va_ie_pessoa_fj = 'F' then
           -------------------------------------------------------
           -- Pessoa Física                                     --
           -- CPF Completo, com zeros a esquerda, sem separador --
           -- Exemplo: 02552290973                              --
           -------------------------------------------------------
           va_segment1 := fnc_remove_caracter@ebs(fnc_mask_cpf@ebs(p_cd_cpf));
           --
        elsif va_ie_pessoa_fj = 'J' then
           -------------------------------------------------------
           -- Pessoa Jurídica                                   --
           -- Raiz do CNPJ (8 dígitos)                          --
           -- Exemplo 76107770 (Original 76.707.770.0001/08     --
           -------------------------------------------------------
           va_segment1 := substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(p_cd_cgc)),1,8);
        end if;
        --
        va_codigo_ebs := va_segment1;
        --
     end if;
     ------------------------------- ***
     -- Tratamento Endereço/Local --
     -------------------------------
     if p_ie_cabecalho_local = 'L' then
        if p_sg_estado_fornecedor = 'EX' then
           -------------------------------------------------------
           -- Pessoa Estrangeira                                --
           -- 'EX.' + Sequencial Numérico                       --
           -- Exemplo: EX.001, EX.002, reiniciando por Fornece. --
           -------------------------------------------------------
           va_vendor_site_code := 'EX.'||lpad(fnc_sequencia_unica@ebs('CARGA_EBS_CAB_FORNEC_EX_'||lpad(p_segment1,3,'0')),3,'0');
        elsif p_ie_cooperado = 'S' and p_ie_cooperativa = 'S' then
           -------------------------------------------------------
           -- Cooperado Cooperativa                             --
           -- Final do CNPJ                                     --
           -- Exemplo 0001-08 (Completo 76.707.770.0001-08      --
           -------------------------------------------------------
           va_vendor_site_code := substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(p_cd_cgc)),9,4)
                                ||'-'
                                ||substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(p_cd_cgc)),13,2);
        elsif p_ie_cooperado = 'S' and p_ie_cooperativa = 'N' then
           -------------------------------------------------------
           -- Pessoa Cooperado                                  --
           -- Se for endereço residencial (PESSOA),             --
           -- apenas o código da Pessoa                         --
           -- Exemplo: 197                                      --
           -------------------------------------------------------
          if p_ie_residencia_cooperado = 'S' then
             va_vendor_site_code := p_cd_pessoa;
          else
             va_vendor_site_code := p_cd_pessoa||'.'||p_nr_propriedade;
          end if;
          --
        elsif va_ie_pessoa_fj = 'F' then
           -------------------------------------------------------
           -- Pessoa Física                                     --
           -- Sequencial numérico, com zeros a esquerda         --
           -- Exemplo: 001, 002, 003                            --
           -------------------------------------------------------
           va_vendor_site_code := lpad(fnc_sequencia_unica@ebs('CARGA_EBS_CAB_FORNEC_LO_'||p_cd_pessoa),3,'0');
           --
        elsif va_ie_pessoa_fj = 'J' then
           -------------------------------------------------------
           -- Pessoa Jurídica                                   --
           -- Final do CNPJ                                     --
           -- Exemplo 0001-08 (Completo 76.707.770.0001-08      --
           -------------------------------------------------------
           va_vendor_site_code := substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(p_cd_cgc)),9,4)
                                ||'-'
                                ||substr(fnc_remove_caracter@ebs(fnc_mask_cnpj@ebs(p_cd_cgc)),13,2);
        end if;
        --
        va_codigo_ebs := va_vendor_site_code;
        --
     end if;
     ---------------------
     return va_codigo_ebs;
     ---------------------
   end;

   --
   function fnc_combination_id(p_concatenated_segments varchar2) return number is
     va_code_combination varchar2(250);
   begin
      begin
         select code_combination_id
           into va_code_combination
           from gl_code_combinations_kfv
          where concatenated_segments = p_concatenated_segments;
      exception
         when others then
            raise_application_error(-20001,'Erro fnc_combination_id: '||sqlerrm);
      end;
      ---------------------------
      return va_code_combination;
      ---------------------------
   end;
   
   --
   function fnc_term_id return number is
      va_term_id number;
   begin
      begin
         select ap.term_id
           into va_term_id
           from ap_terms ap
          where ap.name = 'A VISTA';
      exception
         when others then
            raise_application_error(-20001,'Erro fnc_term_id: '||sqlerrm);
      end;
      ------------------
      return va_term_id;
      ------------------
   end;
   --

   procedure prc_integra_local_fornecedor(p_cd_processo    varchar2
                                         ,p_vendor_id      number
                                         ,p_tp_propriedade cur_propriedade%rowtype
                                         ,p_segment1       varchar2
                                         ,p_string_final   varchar2) is
      --
      x_return_status          varchar2(200);
      x_msg_count              number;
      x_msg_data               varchar2(200);
      lr_sp_st                 apps.ap_vendor_pub_pkg.r_vendor_site_rec_type;
      lr_ex_sp_st              ap_supplier_sites_all%rowtype;
      x_vendor_site_id         number;
      x_party_site_id          number;
      x_location_id            number;
      l_msg                    varchar2(200);
      --
      va_ie_insert_update      varchar2(1);
      va_codigo_ebs            varchar2(30);
      va_ds_erro               varchar2(500);
   begin
      --
      begin
         select 'U' -- Se já existir, update
               ,ap.vendor_site_code
               ,ap.vendor_site_id
               ,ap.location_id
               ,ap.party_site_id
           into va_ie_insert_update
               ,lr_sp_st.vendor_site_code
               ,lr_sp_st.vendor_site_id
               ,lr_sp_st.location_id
               ,lr_sp_st.party_site_id
           from ap_supplier_sites_all ap
          where ap.vendor_id = p_vendor_id
         -- and ap.vendor_site_code = va_codigo_ebs || p_string_final;
            and ap.attribute1 = p_tp_propriedade.cd_pessoa || p_string_final
            and ap.attribute2 = p_tp_propriedade.nr_propriedade || p_string_final
            and ap.inactive_date is null;
          raise too_many_rows;
      exception
         when no_data_found then
            va_ie_insert_update      := 'I'; -- Se não existir, insert
            lr_sp_st.vendor_site_id  := null;
            lr_sp_st.location_id     := null;
            lr_sp_st.party_site_id   := null;
         when too_many_rows then
            va_ie_insert_update := 'U'; -- Se não existir, insert
      end;
      --
      -- dbms_output.put_line(p_vendor_id ||'     '|| p_tp_propriedade.cd_pessoa|| p_string_final||' # '||p_tp_propriedade.nr_propriedade||' # '|| 'Vendor_Site_Code: '||lr_sp_st.vendor_site_code||' # '||p_string_final);
      --
      if va_ie_insert_update = 'I' then
         begin
            va_codigo_ebs := fnc_codigo_ebs(p_ie_cabecalho_local      => 'L' -- Local/Propriedade do Fornecedor
                                           ,p_cd_pessoa               => p_tp_propriedade.cd_pessoa
                                           ,p_nr_propriedade          => p_tp_propriedade.nr_propriedade
                                           ,p_cd_cpf                  => p_tp_propriedade.cd_cpf -- roger voltar
                                           ,p_cd_cgc                  => p_tp_propriedade.cd_cgc_propriedade
                                           ,p_ie_cooperado            => p_tp_propriedade.ie_cooperado
                                           ,p_ie_cooperativa          => p_tp_propriedade.ie_cooperativa
                                           ,p_ie_residencia_cooperado => 'N'
                                           ,p_sg_estado_fornecedor    => p_tp_propriedade.sg_estado
                                           ,p_segment1                => p_segment1); 
            lr_sp_st.vendor_site_code := va_codigo_ebs || p_string_final;
         exception
            when others then
               raise_application_error(-20001,'Erro fnc_codigo_ebs: '||sqlerrm);
         end;
      end if;
      --
      -- dbms_output.put_line(p_vendor_id ||'     '|| p_tp_propriedade.cd_pessoa|| p_string_final||' # '||p_tp_propriedade.nr_propriedade||' # '|| 'Vendor_Site_Code: '||lr_sp_st.vendor_site_code||' # '||p_string_final);
      --
      lr_sp_st.last_update_date              := sysdate;
      lr_sp_st.last_updated_by               := 1139;
      lr_sp_st.vendor_id                     := p_vendor_id;
--      lr_sp_st.vendor_site_code              := va_codigo_ebs || p_string_final;
      lr_sp_st.purchasing_site_flag          := 'Y';
      lr_sp_st.rfq_only_site_flag            := 'N';
      lr_sp_st.pay_site_flag                 := 'Y';
      lr_sp_st.attention_ar_flag             := 'N';
--    lr_sp_st.party_site_name               := p_tp_propriedade.nm_propriedade;     -- Roger, deixar Comentado, gera autom. o vendor_site_code
      lr_sp_st.address_line1                 := p_tp_propriedade.address_line1;      -- Roger
      lr_sp_st.address_line2                 := p_tp_propriedade.address_line2;      -- Roger
      lr_sp_st.address_line3                 := p_tp_propriedade.address_line3;      -- Roger
      lr_sp_st.city                          := p_tp_propriedade.city;               -- Roger
      lr_sp_st.state                         := p_tp_propriedade.state;              -- Roger
      lr_sp_st.zip                           := p_tp_propriedade.zip;                -- Roger
      lr_sp_st.country                       := p_tp_propriedade.country;            -- Roger
      lr_sp_st.terms_date_basis              := 'Invoice';
      lr_sp_st.accts_pay_code_combination_id := fnc_combination_id('01.0037.210501003.0000.00.000.0.0.0'); -- CONTA FORNECEDOR
      lr_sp_st.prepay_code_combination_id    := fnc_combination_id('01.0037.111031001.0000.00.000.0.0.0'); -- PAGAMENTO ANTECIPADO 
      lr_sp_st.pay_group_lookup_code         := 'BOLETO'; -- Confirmar Regina De/Para -- Ver e-Mail Fernado 29/02/2020 
      lr_sp_st.payment_priority              := 99; -- Definido como 99 por enquanto, ajuste após carga
      lr_sp_st.terms_id                      := fnc_term_id; -- Confirmar Eliane/Pendente...(Incluído a Vista, por enquanto)
      lr_sp_st.pay_date_basis_lookup_code    := 'DISCOUNT';
      lr_sp_st.always_take_disc_flag         := 'Y';
      lr_sp_st.invoice_currency_code         := 'BRL';
      lr_sp_st.payment_currency_code         := 'BRL';
      lr_sp_st.hold_all_payments_flag        := 'N';
      lr_sp_st.hold_future_payments_flag     := 'N';
      lr_sp_st.hold_unmatched_invoices_flag  := 'N';
      lr_sp_st.ap_tax_rounding_rule          := 'N';
      lr_sp_st.amount_includes_tax_flag      := 'N';
      lr_sp_st.tax_reporting_site_flag       := 'N';
      lr_sp_st.attribute1                    := p_tp_propriedade.attribute1||p_string_final; -- Roger
      lr_sp_st.attribute2                    := p_tp_propriedade.attribute2||p_string_final; -- Roger
      lr_sp_st.validation_number             := 0;
      lr_sp_st.exclude_freight_from_discount := 'N';
      lr_sp_st.org_id                        := ln_new_org_id;                       -- Roger
      lr_sp_st.address_line4                 := p_tp_propriedade.address_line4;      -- Roger
      lr_sp_st.address_style                 := p_tp_propriedade.address_style;      -- Roger
      lr_sp_st.allow_awt_flag                := 'Y';
      lr_sp_st.global_attribute1             := 'N';
      lr_sp_st.global_attribute9             := p_tp_propriedade.global_attribute9;  -- Roger
      lr_sp_st.global_attribute10            := p_tp_propriedade.global_attribute10; -- Roger
      lr_sp_st.global_attribute11            := p_tp_propriedade.global_attribute11; -- Roger
      lr_sp_st.global_attribute12            := p_tp_propriedade.global_attribute12; -- Roger
      lr_sp_st.global_attribute13            := p_tp_propriedade.global_attribute13; -- Roger
      lr_sp_st.global_attribute14            := null;                                -- Inscrição Municipal
      lr_sp_st.global_attribute15            := p_tp_propriedade.global_attribute15; -- Roger
      lr_sp_st.global_attribute_category     := 'JL.BR.APXVDMVD.SITES';
      lr_sp_st.bank_charge_bearer            := 'I';
      lr_sp_st.pcard_site_flag               := 'N';
      lr_sp_st.match_option                  := 'P';
      lr_sp_st.country_of_origin_code        := 'BR';
      lr_sp_st.create_debit_memo_flag        := 'N';
      lr_sp_st.primary_pay_site_flag         := 'N';
      lr_sp_st.gapless_inv_num_flag          := 'N';
      ------------------------------------------
      -- Insert                               --
      -- Call the API (ap_supplier_sites_all) --
      ------------------------------------------
      if va_ie_insert_update = 'I' then
         begin
            ap_vendor_pub_pkg.create_vendor_site(p_api_version      => p_api_version        -- in
                                                ,p_init_msg_list    => p_init_msg_list      -- in
                                                ,p_commit           => p_commit             -- in
                                                ,p_validation_level => p_validation_level   -- in
                                                ,x_return_status    => x_return_status      -- out
                                                ,x_msg_count        => x_msg_count          -- out
                                                ,x_msg_data         => x_msg_data           -- out
                                                ,p_vendor_site_rec  => lr_sp_st             -- in
                                                ,x_vendor_site_id   => x_vendor_site_id     -- out
                                                ,x_party_site_id    => x_party_site_id      -- out
                                                ,x_location_id      => x_location_id);      -- out
         exception
            when others then
               raise_application_error(-20003,'Erro create_vendor_site: '||sqlerrm);
         end;
      else
         ------------------------------------------
         -- Update                               --
         -- Call the API (ap_supplier_sites_all) --
         ------------------------------------------
         begin
            lr_sp_st.vendor_site_code := null; -- Na alteração, não enviar essa informação... erro...
            ap_vendor_pub_pkg.update_vendor_site(p_api_version      => p_api_version               -- in
                                                ,p_init_msg_list    => p_init_msg_list             -- in
                                                ,p_commit           => p_commit                    -- in
                                                ,p_validation_level => p_validation_level          -- in
                                                ,x_return_status    => x_return_status             -- out
                                                ,x_msg_count        => x_msg_count                 -- out
                                                ,x_msg_data         => x_msg_data                  -- out
                                                ,p_vendor_site_rec  => lr_sp_st                    -- in
                                                ,p_vendor_site_id   => lr_sp_st.vendor_site_id);   -- in
                                             -- ,p_calling_prog     => p_calling_prog);     -- in
         exception
            when others then
               raise_application_error(-20004,'Erro update_vendor_site: '||sqlerrm);
         end;
      end if;
      --
      if (x_return_status <> fnd_api.g_ret_sts_success) then
         for i in 1 .. fnd_msg_pub.count_msg loop
            l_msg := fnd_msg_pub.get(p_msg_index => i
                                    ,p_encoded   => fnd_api.g_false);
            dbms_output.put_line(va_ie_insert_update 
                               || ' API ERROR'
                               || '; Pessoa; '           || p_tp_propriedade.cd_pessoa
                               || '; Propriedade; '      || p_tp_propriedade.nr_propriedade
                               || '; Vendor_Site_Code;'  || lr_sp_st.vendor_site_code
                               || '; Erro: '             || l_msg);
             rollback;
         end loop;
      else
         dbms_output.put_line(va_ie_insert_update 
                            || ' SUCCESS (L)'
                            || '; Pessoa; '           || p_tp_propriedade.cd_pessoa
                            || '; Propriedade; '      || p_tp_propriedade.nr_propriedade
                            || '; va_codigo_ebs; '    || lr_sp_st.vendor_site_code
                            || '; X_RETURN_STATUS; '  || x_return_status
                            || '; X_MSG_COUNT; '      || x_msg_count
                            || '; X_MSG_DATA; '       || x_msg_data
                            || '; X_VENDOR_SITE_ID; ' || x_vendor_site_id
                            || '; X_PARTY_SITE_ID; '  || x_party_site_id
                            || '; X_LOCATION_ID; '    || x_location_id
                            || '; vendor_id; '        || lr_sp_st.vendor_id
                            || '; vendor_site_id; '   || lr_sp_st.vendor_site_id
                            || '; vendor_site_code; ' || lr_sp_st.vendor_site_code
                            || '; x_vendor_site_id; ' || x_vendor_site_id);
         commit;
      end if;
   end;

   --
   
   procedure prc_integra_fornecedor(p_cd_processo   varchar2
                                   ,p_tp_pessoa     cur_pessoa%rowtype
                                   ,p_string_final  varchar2) is
      --
      x_return_status     varchar2(200);
      x_msg_count         number;
      x_msg_data          varchar2(200);
      l_msg               varchar2(200);
      lr_vend             apps.ap_vendor_pub_pkg.r_vendor_rec_type;
      x_vendor_id         number;
      x_party_id          number;
      --
      va_ie_insert_update varchar2(1);
      va_codigo_ebs       varchar2(30);
      va_vendor_name      varchar2(500);
      va_ds_erro          varchar2(500);
      va_segment1         varchar2(100);
      va_vendor_type_lookup_code varchar2(30);
   begin
      va_vendor_type_lookup_code := null;
      --
      /*
      if p_tp_pessoa.ie_cooperado = 'N' and 
         p_tp_pessoa.ie_transportador = 'S' and 
         p_tp_pessoa.nr_inscricao_estadual is not null and
         p_tp_pessoa.ie_conhecimento_frete = 'S' then
         va_vendor_type_lookup_code := 'TRANSPORTADOR'; 
      */
      if (p_tp_pessoa.ie_cooperado = 'N' and
          p_tp_pessoa.ie_conhecimento_frete = 'S') then
         va_vendor_type_lookup_code := 'TRANSPORTADOR';
      elsif p_tp_pessoa.vendor_name like 'MUNICIPIO%' then
         va_vendor_type_lookup_code := 'TAX AUTHORITY'; -- Autoridade Fiscal
      else 
         va_vendor_type_lookup_code := 'VENDOR';        -- Fornecedor
      end if;
      --
      -- dbms_output.put_line('roger 1');
      --
      begin
         select 'U' -- Se já existir, update
               ,ap.vendor_id
               ,ap.segment1
           into va_ie_insert_update
               ,x_vendor_id
               ,va_segment1
           from ap_suppliers ap
               ,ap_supplier_sites_all aps
          where ap.vendor_id = aps.vendor_id
            and aps.attribute1 = p_tp_pessoa.cd_pessoa||p_string_final;
          raise too_many_rows;
      exception
         when no_data_found then
            va_ie_insert_update := 'I'; -- Se não existir, insert
         when too_many_rows then
            va_ie_insert_update := 'U'; -- Se não existir, insert
      end;
      --
      -- dbms_output.put_line('roger 2');
      --
      if va_ie_insert_update = 'I' then
         -- dbms_output.put_line('roger 3');
         begin        
            va_codigo_ebs := fnc_codigo_ebs(p_ie_cabecalho_local      => 'C' -- Cabeçalho do Cadastro
                                           ,p_cd_pessoa               => p_tp_pessoa.cd_pessoa
                                           ,p_nr_propriedade          => null -- Quando for Cabeçalho, não passa Propriedade
                                           ,p_cd_cpf                  => p_tp_pessoa.cd_cpf
                                           ,p_cd_cgc                  => p_tp_pessoa.cd_cgc
                                           ,p_ie_cooperado            => p_tp_pessoa.ie_cooperado
                                           ,p_ie_cooperativa          => p_tp_pessoa.ie_cooperativa
                                           ,p_ie_residencia_cooperado => 'S'
                                           ,p_sg_estado_fornecedor    => p_tp_pessoa.sg_estado
                                           ,p_segment1                => null); -- Não se aplica no cabeçalho
            va_segment1    := va_codigo_ebs || p_string_final;
            va_vendor_name := p_tp_pessoa.vendor_name || p_string_final;
         exception
            when others then
               raise_application_error(-20001,'Erro fnc_codigo_ebs: '||sqlerrm);
         end;
      end if;
      --
      -- dbms_output.put_line('roger 4');
      --
      -- Hold Details
      lr_vend                                := null;
      --
      lr_vend.segment1                       := va_segment1;
      lr_vend.vendor_name                    := va_vendor_name;
      lr_vend.vendor_name_alt                := p_tp_pessoa.vendor_name_alt;
      --
      -- dbms_output.put_line(va_ie_insert_update||' # '||lr_vend.vendor_name||' # '||va_segment1);
      --
      lr_vend.summary_flag                   := 'N';         -- Roger
      lr_vend.enabled_flag                   := 'Y';         -- Roger
      lr_vend.start_date_active              := sysdate;     -- Roger
      lr_vend.vendor_type_lookup_code        := va_vendor_type_lookup_code; -- Roger
      lr_vend.one_time_flag                  := 'N';         -- Roger
      lr_vend.terms_id                       := fnc_term_id; -- Roger -- 10041 -- Erro A Condição de Pagamento está inconsistente
      lr_vend.always_take_disc_flag          := 'Y';         -- Roger
      lr_vend.pay_date_basis_lookup_code     := 'DISCOUNT';  -- Roger
      lr_vend.pay_group_lookup_code          := 'BOLETO';    -- Roger ver Evandro
      lr_vend.payment_priority               := 99;          -- Roger
      lr_vend.invoice_currency_code          := 'BRL';       -- Roger
      lr_vend.payment_currency_code          := 'BRL';       -- Roger
      lr_vend.hold_all_payments_flag         := 'N';         -- Roger
      lr_vend.hold_future_payments_flag      := 'N';         -- Roger
      lr_vend.women_owned_flag               := 'N';         -- Roger
      lr_vend.small_business_flag            := 'N';         -- Roger
      lr_vend.terms_date_basis               := 'Invoice';   -- Roger
      lr_vend.hold_unmatched_invoices_flag   := 'N';         -- Roger
      lr_vend.state_reportable_flag          := 'N';         -- Roger
      lr_vend.federal_reportable_flag        := 'N';         -- Roger
      lr_vend.auto_calculate_interest_flag   := 'Y';         -- Roger
      lr_vend.exclude_freight_from_discount  := 'N';         -- Roger
      lr_vend.allow_awt_flag                 := 'Y';         -- Roger
      lr_vend.match_option                   := 'P';         -- Roger
      lr_vend.global_attribute1              := 'N';         -- Roger
      ---------------------------------
      -- Insert                      --
      -- Call the API (ap_suppliers) --
      ---------------------------------
      if va_ie_insert_update = 'I' then
         begin
            ap_vendor_pub_pkg.create_vendor(p_api_version      => p_api_version      -- in
                                           ,p_init_msg_list    => p_init_msg_list    -- in
                                           ,p_commit           => p_commit           -- in
                                           ,p_validation_level => p_validation_level -- in
                                           ,x_return_status    => x_return_status    -- out --
                                           ,x_msg_count        => x_msg_count        -- out --
                                           ,x_msg_data         => x_msg_data         -- out --
                                           ,p_vendor_rec       => lr_vend            -- in  -- record_type
                                           ,x_vendor_id        => x_vendor_id        -- out -- Chave Primária
                                           ,x_party_id         => x_party_id);       -- out -- Chave Única
         exception
            when others then
               raise_application_error(-20001,va_ie_insert_update||' '||'Erro create_vendor: '||p_tp_pessoa.cd_pessoa||sqlerrm);
         end;
      else
         ---------------------------------
         -- Update                      --
         -- Call the API (ap_suppliers) --
         ---------------------------------
         begin
            ap_vendor_pub_pkg.update_vendor(p_api_version      => p_api_version      -- in
                                           ,p_init_msg_list    => p_init_msg_list    -- in
                                           ,p_commit           => p_commit           -- in
                                           ,p_validation_level => p_validation_level -- in
                                           ,x_return_status    => x_return_status    -- out --
                                           ,x_msg_count        => x_msg_count        -- out --
                                           ,x_msg_data         => x_msg_data         -- out --
                                           ,p_vendor_rec       => lr_vend            -- in  -- record_type
                                           ,p_vendor_id        => x_vendor_id);      -- in  -- Chave Primária
         exception
            when others then
               raise_application_error(-20002,va_ie_insert_update||' '||'Erro update_vendor: '||p_tp_pessoa.cd_pessoa||sqlerrm);
         end;
      end if;
      --
      if (x_return_status <> fnd_api.g_ret_sts_success) then
         for i in 1 .. fnd_msg_pub.count_msg loop
            l_msg := fnd_msg_pub.get(p_msg_index => i
                                    ,p_encoded   => fnd_api.g_false);
         end loop;
         dbms_output.put_line(va_ie_insert_update||' Erro pessoa: '||p_tp_pessoa.cd_pessoa||'-'||lr_vend.vendor_name||' : '||l_msg);
         rollback;
      else
         dbms_output.put_line(va_ie_insert_update||' SUCCESS (C); Pessoa; '||p_tp_pessoa.cd_pessoa||';'||p_tp_pessoa.vendor_name||'; The API call ended with SUCESSS status');
         ----------------------------------------------
         -- Integração da Propriedade/Endereço/Local --
         ----------------------------------------------
         for reg_propriedade in cur_propriedade(p_tp_pessoa.cd_empresa
                                               ,p_tp_pessoa.cd_pessoa) loop
            --
            -- dbms_output.put_line('Propriedade: '||reg_propriedade.nr_propriedade);
            --
            begin
               prc_integra_local_fornecedor(p_cd_processo    => p_cd_processo
                                           ,p_vendor_id      => x_vendor_id
                                           ,p_tp_propriedade => reg_propriedade
                                           ,p_segment1       => lr_vend.segment1
                                           ,p_string_final   => va_ds_string);
            end;
         end loop;
      end if;
   end;
   --
begin
   ------------------------------------------------------------------------------
   dbms_output.put_line('Início');
   ------------------------------------------------------------------------------
   -- Deletando Log                                                            --
   ------------------------------------------------------------------------------
   pack_log_processo.prc_limpa_log_processo@ebs(p_cd_processo => va_cd_processo);
   ------------------------------------------------------------------------------
   -- Initialize apps session                                                  --
   ------------------------------------------------------------------------------
   --------------------------
   -- Inicializaçao Global --
   --------------------------
   -- Organização          --
   --------------------------
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
       where responsibility_name = 'FRISIA_AP_SUPERUSUARIO'
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
       where application_short_name = 'SQLAP';
   exception
      when others then
         raise_application_error(-20001
                                ,'Erro busca application_id: ' || sqlerrm);
   end;
   --
   fnd_global.apps_initialize(user_id      => va_user_id
                             ,resp_id      => va_resp_id
                             ,resp_appl_id => va_resp_appl_id);
   mo_global.set_policy_context(p_access_mode => 'S'
                               ,p_org_id      =>  va_org_id);
   mo_global.init('SQLAP');
   --
   -- fnd_global.apps_initialize(1139, 50833, 200);
   -- mo_global.init('SQLAP');
   -- fnd_client_info.set_org_context(101);
   ------------------------------------------------------------------------------
   for reg_pessoa in cur_pessoa loop
      --
      -- dbms_output.put_line('Pessoa '||reg_pessoa.cd_pessoa);
      --
      begin
         prc_integra_fornecedor(p_cd_processo   => va_cd_processo
                               ,p_tp_pessoa     => reg_pessoa
                               ,p_string_final  => va_ds_string);
      exception
         when others then
           dbms_output.put_line('Erro prc_integra_fornecedor: '||reg_pessoa.cd_pessoa||': '||sqlerrm);
           rollback;
      end;
      -------
      commit;
      -------
   end loop;
   ------------------------------------------------------------------------------
   dbms_output.put_line('Fim');
   ------------------------------------------------------------------------------
end;
/
