create or replace PACKAGE BODY "XXFR_AP_PCK_INT_ADIANTAMENTOS" is
   procedure carregar_dados_adiantamento( p_id_integracao_detalhe in      number
                                        , p_rec_headers           in out  xxfr_ap_pck_transacoes.tp_adiantamento_cabecalho_tbl
                                        , p_registro              in out  xxfr_pck_interface_integracao.rec_retorno_integracao ) is
 
        --                                  
        cursor cur_header_adiantamento(p_id_integracao_detalhe in number) is
        select h.id_integracao_cabecalho,
                  h.id_integracao_detalhe,
                  h.cd_interface_detalhe,
                  h.ie_status_processamento,
                  h.id_transacao,
                  h.nr_versao_payload,
                  h.ds_sistema_origem,
                  h.cd_codigo_servico,
                  h.ds_usuario,
                  h.cd_unidade_operacional,
                  h.ds_aprova_titulos,
                  h.cd_tipo_documento,
                  h.dt_adiantamento,
                  h.ds_descricao,
                  h.cd_origem_titulo,
                  h.cd_moeda_titulo,
                  h.cd_moeda_pagamento,
                  h.nr_valor,
                  h.cd_fornecedor,
                  h.cd_local_fornecedor,
                  h.cd_propriedade,
                  h.nr_ordem_compra,
                  h.cd_termo_pagamento,
                  h.dt_termo_pagamento,
                  --h.cd_metodo_pagamento,
                  h.cd_referencia_origem,
                  h.tp_referencia_origem,
                  h.ds_observacoes
        from xxfr_ap_vw_int_adi_cabecalho h
        where id_integracao_detalhe = p_id_integracao_detalhe;
        --
        cursor cur_line_adiantamento (p_id_integracao_detalhe in number
                                     ,p_cd_referencia_origem  in varchar2
                                     ,p_tp_referencia_origem  in varchar2) is
          select l.id_integracao_cabecalho,
                l.id_integracao_detalhe,
                l.cd_interface_detalhe,
                l.ie_status_processamento,
                l.id_transacao,
                FND_NUMBER.CANONICAL_TO_NUMBER(l.nr_versao_payload) nr_versao_payload,
                l.ds_sistema_origem,
                l.cd_codigo_servico,
                l.ds_usuario,
                l.cd_unidade_operacional,
                DECODE(l.cd_tipo_documento, 'Padrão', 'STANDARD', 'Adiantamento', 'PREPAYMENT') cd_tipo_documento,
                l.nr_titulo,
                l.cd_tipo_linha,
                l.nr_linha,
                l.cd_organizacao_inventario,
                l.cd_item,
                l.ds_item,
                l.cd_uom_code,
                --l.nr_quantidade,
                --l.nr_preco_unit,
                l.cd_referencia_origem_linha,
                l.cd_referencia_origem,
                l.tp_referencia_origem
          from XXFR_AP_VW_INT_ADI_LINHAS l
           where id_integracao_detalhe = p_id_integracao_detalhe
           and cd_referencia_origem = p_cd_referencia_origem
           and tp_referencia_origem  = p_tp_referencia_origem;

        --                                  
        vs_cd_interface_detalhe          xxfr_integracao_detalhe.cd_interface_detalhe%type;
        vs_cd_unidade_operacional        hr_operating_units.name%type;
        vs_user_name                     fnd_user.user_name%type;
        vs_tipo_documento                ap_invoices_all.invoice_type_lookup_code%type;
        vs_ds_aprova_titulos             ap_invoices_all.wfapproval_status%type;
        --
        vn_user_id                       fnd_user.user_id%type;
        vn_org_id                        hr_operating_units.organization_id%type;
        vn_erros                         number := 0;
        vn_h                             number := 1;             
        vn_l                             number := 1;             
        --vn_d                             number := 1; 
   begin
        p_registro:=null;
        p_registro."contexto" := 'ADIANTAMENTO CONTAS PAGAR';
        p_registro."retornoProcessamento" := 'SUCESSO';
        dbms_output.put_line('p_id_integracao_detalhe = '||p_id_integracao_detalhe);
        -- Buscar tipo de interface
        begin

        select distinct   cd_interface_detalhe 
                        , cd_unidade_operacional
                        , ds_aprova_titulos
                        , ds_usuario
                        , cd_tipo_documento
             into   vs_cd_interface_detalhe 
                  , vs_cd_unidade_operacional
                  , vs_ds_aprova_titulos
                  , vs_user_name
                  , vs_tipo_documento
        from xxfr_ap_vw_int_adi_cabecalho c
        where c.id_integracao_detalhe = p_id_integracao_detalhe;
        exception
           when others then
              vn_erros                                  := vn_erros + 1;
              p_registro."retornoProcessamento"         := 'ERRO';
              p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Integração ID <'||p_id_integracao_detalhe||'>. '||SQLERRM;             
        end;        
        --
        vn_user_id := XXFR_FND_PCK_OBTER_USUARIO.id_usuario(p_cd_usuario => NVL(vs_user_name, 'GERAL_INTEGRACAO'), p_somente_ativo => 'S');
        if vn_user_id is null then
            vn_erros                                  := vn_erros + 1;
            p_registro."retornoProcessamento"         := 'ERRO';
            p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Usuario <'||vs_user_name||'>.';             
        end if;
        --
        if vs_cd_interface_detalhe = 'PROCESSAR_TITULO_ADIANTAMENTO' 
          and vn_user_id is not null then
              --
              begin
                  select organization_id
                       into vn_org_id
                  from hr_operating_units
                  where name = vs_cd_unidade_operacional;
              exception
              when no_data_found then
                    vn_erros                                  := vn_erros + 1;
                    vn_org_id                                 := null;
                    p_registro."retornoProcessamento"         := 'ERRO';
                    p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Organizacao <'||vs_cd_unidade_operacional||'>.';
              when others then
                    vn_erros                                  := vn_erros + 1;
                    vn_org_id                                 := null;
                    p_registro."retornoProcessamento"         := 'ERRO';
                    p_registro."mensagemRetornoProcessamento" := 'Erro ao buscar Organizacao <'||vs_cd_unidade_operacional||'>.';
              end;
              --
              if vn_erros = 0 then
                 for r_header_nota in cur_header_adiantamento(p_id_integracao_detalhe => p_id_integracao_detalhe) loop
                      --
                      begin

                          select XXFR_AP_PREPAYMENT_S.NEXTVAL
                              into p_rec_headers(vn_h).nr_titulo
                          from dual;
                      exception
                      when no_data_found then
                            vn_erros                                  := vn_erros + 1;
                            vn_org_id                                 := null;
                            p_registro."retornoProcessamento"         := 'ERRO';
                            p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para XXFR_AP_PREPAYMENT_S.NEXTVAL.';
                      when others then
                            vn_erros                                  := vn_erros + 1;
                            vn_org_id                                 := null;
                            p_registro."retornoProcessamento"         := 'ERRO';
                            p_registro."mensagemRetornoProcessamento" := 'Erro ao buscar XXFR_AP_PREPAYMENT_S.NEXTVAL.';
                      end;
                      --
                      p_rec_headers(vn_h).tipo_cabecalho             := r_header_nota.cd_codigo_servico;
                      p_rec_headers(vn_h).invoice_id                 := null;
                      p_rec_headers(vn_h).org_id                     := vn_org_id;
                      p_rec_headers(vn_h).cd_unidade_operacional     := vs_cd_unidade_operacional;
                      p_rec_headers(vn_h).ds_aprova_titulos          := vs_ds_aprova_titulos;
                      p_rec_headers(vn_h).cd_tipo_documento          := r_header_nota.cd_tipo_documento;
                      p_rec_headers(vn_h).dt_adiantamento            := r_header_nota.dt_adiantamento;                      
                      p_rec_headers(vn_h).ds_descricao               := r_header_nota.ds_descricao;
                      p_rec_headers(vn_h).cd_origem_titulo           := r_header_nota.cd_origem_titulo;
                      p_rec_headers(vn_h).cd_moeda_titulo            := r_header_nota.cd_moeda_titulo;
                      p_rec_headers(vn_h).cd_moeda_pagamento         := r_header_nota.cd_moeda_pagamento;
                      p_rec_headers(vn_h).nr_valor                   := r_header_nota.nr_valor;
                      p_rec_headers(vn_h).cd_fornecedor              := r_header_nota.cd_fornecedor;
                      p_rec_headers(vn_h).cd_local_fornecedor        := r_header_nota.cd_local_fornecedor;
                      p_rec_headers(vn_h).cd_propriedade             := r_header_nota.cd_propriedade;
                      p_rec_headers(vn_h).nr_ordem_compra            := r_header_nota.nr_ordem_compra;
                      p_rec_headers(vn_h).cd_termo_pagamento         := r_header_nota.cd_termo_pagamento;
                      p_rec_headers(vn_h).dt_termo_pagamento         := r_header_nota.dt_termo_pagamento;
                      --p_rec_headers(vn_h).cd_metodo_pagamento        := r_header_nota.cd_metodo_pagamento;
                      p_rec_headers(vn_h).ds_observacoes             := r_header_nota.ds_observacoes;
                      p_rec_headers(vn_h).tipo_referencia            := r_header_nota.tp_referencia_origem;
                      p_rec_headers(vn_h).codigo_referencia          := r_header_nota.cd_referencia_origem; 
                      if p_rec_headers(vn_h).nr_tax_rate is null then 
                         p_rec_headers(vn_h).nr_tax_rate := 1;               
                      end if;           
                      --
                      xxfr_ap_pck_transacoes.carregar_dados_header(  p_adiantamento => p_rec_headers(vn_h)
                                                                  ,  p_registro     => p_registro);

                      if p_registro."retornoProcessamento"  = 'SUCESSO' then

                          for r_linha_nota in cur_line_adiantamento(p_id_integracao_detalhe   => p_id_integracao_detalhe
                                                                     ,p_cd_referencia_origem  => r_header_nota.cd_referencia_origem
                                                                     ,p_tp_referencia_origem  => r_header_nota.tp_referencia_origem) loop

                                p_rec_headers(vn_h).linhas(vn_l).cd_organizacao := r_linha_nota.cd_organizacao_inventario;                                             
                                p_rec_headers(vn_h).linhas(vn_l).numero_linha              := r_linha_nota.nr_linha;
                                p_rec_headers(vn_h).linhas(vn_l).tipo_linha                := r_linha_nota.cd_tipo_linha;
                                p_rec_headers(vn_h).linhas(vn_l).cd_item                   := r_linha_nota.cd_item;
                                p_rec_headers(vn_h).linhas(vn_l).ds_item                   := r_linha_nota.ds_item;
                                p_rec_headers(vn_h).linhas(vn_l).cd_uom_code               := r_linha_nota.cd_uom_code;
                                --p_rec_headers(vn_h).linhas(vn_l).nr_quantidade             := r_linha_nota.nr_quantidade;
                                --p_rec_headers(vn_h).linhas(vn_l).nr_preco_unit             := r_linha_nota.nr_preco_unit;
                                p_rec_headers(vn_h).linhas(vn_l).tipo_referencia_linha     := r_linha_nota.tp_referencia_origem;
                                p_rec_headers(vn_h).linhas(vn_l).codigo_referencia_linha   := r_linha_nota.cd_referencia_origem_linha;           

                                xxfr_ap_pck_transacoes.carregar_dados_line(  p_linha_numero       => vn_l
                                                                           , p_adiantamento_linha => p_rec_headers(vn_h)
                                                                           , p_registro           => p_registro);

                                vn_l := vn_l + 1;
                          end loop;
                      end if;
                      vn_h := vn_h + 1;
                 end loop;
              end if;            
              --
              if p_registro."retornoProcessamento"  = 'SUCESSO' then
                 xxfr_ap_pck_transacoes.criar_adiantamento(  p_org_id       => vn_org_id
                                                           , p_usuario      => vn_user_id
                                                           , p_adiantamento => p_rec_headers
                                                           , p_registro     => p_registro );
              end if;
        end if;         
    exception
        when others then
          p_registro."retornoProcessamento"         := 'ERRO';
          p_registro."mensagemRetornoProcessamento" := 'Erro em carregar_dados_adiantamento : '||SQLERRM;
   end; 

   PROCEDURE PROCESSAR_ADIANTAMENTO( p_id_integracao_detalhe   in   number
                                   , p_retorno                 out  clob) is PRAGMA AUTONOMOUS_TRANSACTION;

      -- Retorno
      rec_retorno 					   xxfr_pck_interface_integracao.rec_retorno_integracao;
      rec_adiantamento                 xxfr_ap_pck_transacoes.tp_adiantamento_cabecalho_tbl;

   begin

        -- Marcar registro para processamento
        xxfr_pck_interface_integracao.andamento(p_id_integracao_detalhe => p_id_integracao_detalhe);
        -- Finaliza processo com resultado do processamento
        carregar_dados_adiantamento( p_id_integracao_detalhe => p_id_integracao_detalhe
                                   , p_rec_headers           => rec_adiantamento
                                   , p_registro              => rec_retorno); 

        -- Montar retorno do processo da API 
        xxfr_ap_pck_transacoes.montar_retorno( p_adiantamento=> rec_adiantamento
                                             , p_rec_retorno => rec_retorno);

        if rec_retorno."retornoProcessamento" = 'SUCESSO' then
            commit;
            xxfr_pck_interface_integracao.sucesso( p_id_integracao_detalhe   => p_id_integracao_detalhe,
                                                   p_ds_dados_retorno        => rec_retorno  );
        else 
            rollback;
            xxfr_pck_interface_integracao.erro( p_id_integracao_detalhe  => p_id_integracao_detalhe,
                                                p_ds_dados_retorno       => rec_retorno  );
        end if;
        --
        xxfr_ap_pck_transacoes.retornar_clob( p_id_integracao_detalhe => p_id_integracao_detalhe
                                            , p_retorno               => p_retorno);
    exception
        when others then
          rollback;
          rec_retorno."retornoProcessamento"         := 'ERRO';
          rec_retorno."mensagemRetornoProcessamento" := 'Erro ao carregar dados para criar Adiantamento : '||SQLERRM;

          xxfr_pck_interface_integracao.erro( p_id_integracao_detalhe  => p_id_integracao_detalhe,
                                              p_ds_dados_retorno       => rec_retorno  );

          xxfr_ap_pck_transacoes.retornar_clob( p_id_integracao_detalhe => p_id_integracao_detalhe
                                              , p_retorno               => p_retorno);

    end;

end XXFR_AP_PCK_INT_ADIANTAMENTOS;

