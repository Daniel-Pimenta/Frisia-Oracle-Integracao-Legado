create or replace PACKAGE BODY "XXFR_AR_PCK_INT_FINANCIAMENTO" as

  g_escopo                  varchar2(50) := 'PROCESSAR_FINANCIAMENTO';
  g_id_integracao_detalhe   number;

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    --if (isConcurrent) then apps.fnd_file.put_line (apps.fnd_file.log, msg); end if;
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => upper(g_escopo)||'_'||g_id_integracao_detalhe
    );
  end;

    procedure obter_gravacao_padrao( p_gravacao    out  varchar2
                                   , p_registro in out  xxfr_pck_interface_integracao.rec_retorno_integracao ) is
    begin
        select fnd_profile.value('XXFR_AR_CONFIRMAR_GRAVACAO_PADRAO')
             into p_gravacao
        from dual;
    exception
    when no_data_found then
          p_gravacao                                := null;
          p_registro."retornoProcessamento"         := 'ERRO';
          p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Gravação dos Dados Padrão.';
    when others then
          p_gravacao                                := null;
          p_registro."retornoProcessamento"         := 'ERRO';
          p_registro."mensagemRetornoProcessamento" := 'Erro ao buscar  Gravação dos Dados Padrão.';
    end;
    --    
    procedure obter_metodo_padrao( p_metodo_processamento    out  varchar2
                                 , p_registro             in out  xxfr_pck_interface_integracao.rec_retorno_integracao ) is
    begin
        select fnd_profile.value('XXFR_AR_METODO_PROCESSAMENTO_PADRAO')
             into p_metodo_processamento
        from dual;
    exception
    when no_data_found then
          p_metodo_processamento                    := null;
          p_registro."retornoProcessamento"         := 'ERRO';
          p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Metodo de Processamento Padrão.';
    when others then
          p_metodo_processamento                    := null;
          p_registro."retornoProcessamento"         := 'ERRO';
          p_registro."mensagemRetornoProcessamento" := 'Erro ao buscar Metodo de Processamento Padrão.';
    end;
    --    
    procedure obter_processo_padrao( p_tipo     in      varchar2
                                   , p_processo    out  varchar2 
                                   , p_registro in out  xxfr_pck_interface_integracao.rec_retorno_integracao ) is
    begin
        select fnd_profile.value(p_tipo)
             into p_processo
        from dual;
    exception
    when no_data_found then
          p_processo                               := null;
          p_registro."retornoProcessamento"         := 'ERRO';
          p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Processo Padrão de Liberação.';
    when others then
          p_processo                               := null;
          p_registro."retornoProcessamento"         := 'ERRO';
          p_registro."mensagemRetornoProcessamento" := 'Erro ao buscar Processo Padrão de Liberação.';
    end;
    --
    procedure montar_retorno ( p_rec_contrato          in      tp_cabecalho_tbl
                             , p_mensagens             in      xxfr_ar_pck_executa_processo.tp_mensagens_tbl 
                             , p_rec_retorno           in out  xxfr_pck_interface_integracao.rec_retorno_integracao) is
        m                       number;
        va_quantidade_erro_reg  number := 0;
    begin
      print_log('MONTA_RETORNO');
          --
          for h in 1..p_rec_contrato.count loop
              --dbms_output.put_line('h count = '||p_rec_nota.count);
              p_rec_retorno."registros"(h)."tipoCabecalho"         := p_rec_contrato(h).tipo_cabecalho;
              p_rec_retorno."registros"(h)."codigoCabecalho"       := p_rec_contrato(h).numero_processo;
              p_rec_retorno."registros"(h)."retornoProcessamento"  := p_rec_contrato(h).status_processamento;
              p_rec_retorno."registros"(h)."tipoReferenciaOrigem"  := p_rec_contrato(h).tipo_referencia;
              p_rec_retorno."registros"(h)."codigoReferenciaOrigem":= p_rec_contrato(h).codigo_referencia; 

              if p_mensagens.count != 0 then  
                 for m in p_mensagens.first..p_mensagens.last loop
                     va_quantidade_erro_reg := va_quantidade_erro_reg + 1;      
                     p_rec_retorno."registros"(h)."mensagens"(m)."mensagem"     := p_mensagens(m);
                     p_rec_retorno."registros"(h)."mensagens"(m)."tipoMensagem" := 'ERRO';
                 end loop;
              end if; 
              --
          end loop;
          --        
          if va_quantidade_erro_reg = 0 then 
             p_rec_retorno."retornoProcessamento" := 'SUCESSO';      
          else 
             p_rec_retorno."retornoProcessamento" := 'ERRO';  
          end if;
          --dbms_output.put_line('status = '||p_rec_retorno."retornoProcessamento");
          --
          if p_rec_retorno."mensagemRetornoProcessamento" is null and  p_rec_retorno."retornoProcessamento" = 'ERRO' then
             p_rec_retorno."mensagemRetornoProcessamento" := 'Existem '||va_quantidade_erro_reg||' erro(s) no processamento da integração de Liberação de Contratos';
          end if;
    end;
    --
    procedure cancelar_dados( 
      p_id_integracao_detalhe in number,
      p_rec_contrato          in out  tp_cabecalho_tbl,
      p_mensagens             in out  xxfr_ar_pck_executa_processo.tp_mensagens_tbl,
      p_registro              in out  xxfr_pck_interface_integracao.rec_retorno_integracao 
    ) is

        vs_cd_interface_detalhe          xxfr_integracao_detalhe.cd_interface_detalhe%type;
        vs_cd_unidade_operacional        hr_operating_units.name%type;
        vs_user_name                     fnd_user.user_name%type;
        vs_sistema_origem                varchar2(100);
        vs_status_code                   varchar2(50);
        vs_processo                      varchar2(50);
        vs_metodo_processamento          varchar2(50);
        vs_gravacao                      varchar2(50);
        --
        vn_user_id                       fnd_user.user_id%type;
        --vn_org_id                        hr_operating_units.organization_id%type;
        vn_id_execucao                   number := 0;
        vn_erros                         number := 0;
        vn_h                             number := 0;
        --
        p_taxas                          xxfr_ar_pck_executa_processo.taxas_tbl_type;
        p_parcelas                       xxfr_ar_pck_executa_processo.parcelas_tbl_type;
    begin
        g_id_integracao_detalhe := p_id_integracao_detalhe; 
        p_registro:=null;
        p_registro."contexto" := 'CONTRATO FINANCIAMENTO';
        p_registro."retornoProcessamento" := null;

        -- Buscar tipo de interface
        select distinct   cd_interface_detalhe 
                        , cd_unidade_operacional
                        , ds_sistema_origem
                        , ds_usuario
             into   vs_cd_interface_detalhe 
                  , vs_cd_unidade_operacional
                  , vs_sistema_origem
                  , vs_user_name
        from xxfr_ar_vw_int_financ_cancela c
        where c.id_integracao_detalhe = p_id_integracao_detalhe;
        --
        vn_user_id := XXFR_FND_PCK_OBTER_USUARIO.id_usuario(p_cd_usuario => NVL(vs_user_name, 'GERAL_INTEGRACAO'), p_somente_ativo => 'S');
        if vn_user_id is null then
            vn_erros                                  := vn_erros + 1;
            p_registro."retornoProcessamento"         := 'ERRO';
            p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Usuario <'||vs_user_name||'>.';             
        end if;
        --      
        if vs_cd_interface_detalhe in ( 'CANCELAR_FINANCIAMENTO' )  
          and vn_user_id is not null then
              --               
              obter_processo_padrao( P_tipo     => 'XXFR_AR_PROCESSO_PADRAO_CANCELA_CONTRATO'
                                   , p_processo => vs_processo
                                   , p_registro => p_registro);
              if vs_processo is null then
                  vn_erros                                  := vn_erros + 1;
                  p_registro."retornoProcessamento"         := 'ERRO';
                  p_registro."mensagemRetornoProcessamento" := 'Perfil nao encontrado para Processo Padrão.';                             
              end if;
              --
              obter_metodo_padrao( p_metodo_processamento => vs_metodo_processamento
                                 , p_registro => p_registro);
              if vs_metodo_processamento is null then
                  vn_erros                                  := vn_erros + 1;
                  p_registro."retornoProcessamento"         := 'ERRO';
                  p_registro."mensagemRetornoProcessamento" := 'Perfil nao encontrado para Método Processamento.';                             
              end if;
              --              
              obter_gravacao_padrao( p_gravacao => vs_gravacao
                                   , p_registro => p_registro);
              if vs_gravacao is null then
                  vn_erros                                  := vn_erros + 1;
                  p_registro."retornoProcessamento"         := 'ERRO';
                  p_registro."mensagemRetornoProcessamento" := 'Perfil nao encontrado para Gravação Automática.';                             
              end if;
              --
              if vn_erros = 0 then
                  for r_header in cur_cancela(p_id_integracao_detalhe => p_id_integracao_detalhe) loop

                      vn_h := vn_h + 1;
                      p_rec_contrato(vn_h).tipo_cabecalho           := 'CONTRATO FINANCIAMENTO';
                      p_rec_contrato(vn_h).numero_processo          := r_header.nr_processo;
                      p_rec_contrato(vn_h).numero_contrato          := r_header.cd_contrato;
                      p_rec_contrato(vn_h).tipo_referencia          := 'CONTRATO CANCELAMENTO';

                      xxfr_ar_pck_executa_processo.integra_financiamento(
                        p_cd_processo                 => vs_processo
                        ,p_commit_evento               => vs_gravacao
                        ,p_metodo_execucao             => vs_metodo_processamento
                        ,p_dt_liberacao                => null
                        ,p_cd_cooperado                => null
                        ,p_cd_contrato                 => null
                        ,p_ds_atividade_rural          => null
                        ,p_nm_cultura                  => null
                        ,p_nm_safra                    => null
                        ,p_cd_banco_conta_liberacao    => null
                        ,p_cd_agencia_conta_liberacao  => null
                        ,p_cd_conta_liberacao          => null
                        ,p_cd_banco_conta_recurso      => null
                        ,p_cd_agencia_conta_recurso    => null
                        ,p_cd_conta_origem_recurso     => null
                        ,p_valor_liberado              => null
                        ,p_ds_uso_financiamento        => null
                        ,p_vl_uso_financiamento        => null
                        ,p_vl_financiamento_mao_obra   => null
                        ,p_vl_retencao_custeio         => null
                        ,p_cd_metodo_pgto_mao_obra     => null
                        ,p_condicao_pgto_mao_obra      => null
                        --
                        ,p_taxas                       => p_taxas
                        ,p_parcelas                    => p_parcelas 
                        --
                        ,p_org_id                      => null
                        ,p_id_execucao_processo        => r_header.nr_processo
                        ,p_status                      => vs_status_code
                        ,p_mensagem                    => p_mensagens
                      );
                      p_rec_contrato(vn_h).numero_processo          := vn_id_execucao;
                      p_rec_contrato(vn_h).codigo_referencia        := vn_id_execucao;
                      p_rec_contrato(vn_h).status_processamento     := vs_status_code;
                  end loop;
              end if;    
              --  
        end if;
    end;
    --
    procedure carregar_dados( 
        p_id_integracao_detalhe in      number
      , p_rec_contrato          in out  tp_cabecalho_tbl
      , p_mensagens             in out  xxfr_ar_pck_executa_processo.tp_mensagens_tbl
      , p_registro              in out  xxfr_pck_interface_integracao.rec_retorno_integracao 
    ) is

        vs_cd_interface_detalhe          xxfr_integracao_detalhe.cd_interface_detalhe%type;
        vs_cd_unidade_operacional        hr_operating_units.name%type;
        vs_user_name                     fnd_user.user_name%type;
        vs_sistema_origem                varchar2(100);
        vs_status_code                   varchar2(50);
        vs_processo                      varchar2(50);
        vs_metodo_processamento          varchar2(50);
        vs_gravacao                      varchar2(50);
        --
        vn_user_id                       fnd_user.user_id%type;
        vn_org_id                        hr_operating_units.organization_id%type;
        vn_id_execucao                   number;
        vn_erros                         number := 0;
        vn_h                             number := 0;
        --
        p_taxas                          xxfr_ar_pck_executa_processo.taxas_tbl_type;
        p_parcelas                       xxfr_ar_pck_executa_processo.parcelas_tbl_type;
        i  number;
        --
    begin 
      print_log('CARREGA_DADOS');
        p_registro:=null;
        p_registro."contexto" := 'CONTRATO FINANCIAMENTO';
        p_registro."retornoProcessamento" := null;

        -- Buscar tipo de interface
        print_log('  Busca tipo da Interface');
        select distinct   cd_interface_detalhe 
                        , cd_unidade_operacional
                        , ds_sistema_origem
                        , ds_usuario
             into   vs_cd_interface_detalhe 
                  , vs_cd_unidade_operacional
                  , vs_sistema_origem
                  , vs_user_name
        from xxfr_ar_vw_int_financiamento c
        where c.id_integracao_detalhe = p_id_integracao_detalhe;
        --
        vn_user_id := XXFR_FND_PCK_OBTER_USUARIO.id_usuario(p_cd_usuario => NVL(vs_user_name, 'GERAL_INTEGRACAO'), p_somente_ativo => 'S');
        if vn_user_id is null then
            vn_erros                                  := vn_erros + 1;
            p_registro."retornoProcessamento"         := 'ERRO';
            p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Usuario <'||vs_user_name||'>.';             
        end if;
        --      
        if vs_cd_interface_detalhe in ( 'PROCESSAR_FINANCIAMENTO' )  
          and vn_user_id is not null then
              --
              vn_org_id := XXFR_HR_PCK_OBTER_UNID_OPER.id_unidade_operacional(p_name => vs_cd_unidade_operacional);
              if vn_org_id is null then
                  vn_erros                                  := vn_erros + 1;
                  p_registro."retornoProcessamento"         := 'ERRO';
                  p_registro."mensagemRetornoProcessamento" := 'Dados nao encontrados para Unidade Operacional <'||vs_cd_unidade_operacional||'>.';             
              end if;
              --               
              /*obter_processo_padrao( P_tipo     => 'XXFR_AR_PROCESSO_PADRAO_LIBERA_CONTRATO'
                                   , p_processo => vs_processo
                                   , p_registro => p_registro);
              if vs_processo is null then
                  vn_erros                                  := vn_erros + 1;
                  p_registro."retornoProcessamento"         := 'ERRO';
                  p_registro."mensagemRetornoProcessamento" := 'Perfil nao encontrado para Processo Padrão.';                             
              end if;*/
              --
              obter_metodo_padrao( p_metodo_processamento => vs_metodo_processamento
                                 , p_registro => p_registro);
              if vs_metodo_processamento is null then
                  vn_erros                                  := vn_erros + 1;
                  p_registro."retornoProcessamento"         := 'ERRO';
                  p_registro."mensagemRetornoProcessamento" := 'Perfil nao encontrado para Método Processamento.';                             
              end if;
              --              
              obter_gravacao_padrao( p_gravacao => vs_gravacao
                                   , p_registro => p_registro);
              if vs_gravacao is null then
                  vn_erros                                  := vn_erros + 1;
                  p_registro."retornoProcessamento"         := 'ERRO';
                  p_registro."mensagemRetornoProcessamento" := 'Perfil nao encontrado para Gravação Automática.';                             
              end if;
              --
              if vn_erros = 0 then
                  for r_header in cur_header(p_id_integracao_detalhe => p_id_integracao_detalhe) loop

                      vn_h := vn_h + 1;
                      p_rec_contrato(vn_h).tipo_cabecalho           := 'CONTRATO FINANCIAMENTO';
                      p_rec_contrato(vn_h).numero_contrato          := r_header.cd_contrato;
                      p_rec_contrato(vn_h).tipo_referencia          := 'CONTRATO LIBERACAO';
                      i:=0;
                      print_log('  Recuper as Taxas');
                      for t1 in (
                        select distinct 
                          idx_taxa, cd_taxa, vl_taxa
                        from xxfr_ar_vw_int_financiamento
                        where 1=1
                          and id_integracao_detalhe=p_id_integracao_detalhe
                          and idx_taxa is not null
                        order by idx_taxa
                      ) loop
                        i:= i+1;
                        print_log('  '||i||') '||t1.cd_taxa||'->'||t1.vl_taxa);
                        p_taxas(i).cd_taxa := t1.cd_taxa;
                        p_taxas(i).vl_taxa := t1.vl_taxa;
                      end loop;
                      --
                      i:=0;
                      print_log('  Recuper as Parcelas');
                      for p1 in (
                        select distinct 
                          idx_parcelas, dt_parcela, vl_parcela 
                        from xxfr_ar_vw_int_financiamento
                        where 1=1
                          and id_integracao_detalhe=p_id_integracao_detalhe
                          and idx_parcelas is not null
                        order by idx_parcelas
                      ) loop
                        i:= i+1;
                        print_log('  '||i||') '||p1.dt_parcela||'->'||p1.vl_parcela);
                        p_parcelas(i).dt_parcela := p1.dt_parcela;
                        p_parcelas(i).vl_parcela := p1.vl_parcela;
                      end loop;
                      --
                      print_log('Chamando XXFR_AR_PCK_EXECUTA_PROCESSO.INTEGRA_FINANCIAMENTO...');
                      xxfr_ar_pck_executa_processo.integra_financiamento(
                        p_cd_processo                  => r_header.cd_tipo_processo --vs_processo
                        ,p_commit_evento               => vs_gravacao               -- S-Sim N-Não
                        ,p_metodo_execucao             => vs_metodo_processamento   -- ON-LINE ou CONCORRENTE
                        ,p_dt_liberacao                => r_header.dt_liberacao
                        ,p_cd_cooperado                => r_header.cd_cliente
                        ,p_cd_contrato                 => r_header.cd_contrato
                        ,p_ds_atividade_rural          => r_header.cd_atividade
                        ,p_nm_cultura                  => r_header.cd_cultura
                        ,p_nm_safra                    => r_header.cd_safra
                        ,p_nm_proposito                => null
                        ,p_cd_banco_conta_liberacao    => r_header.cd_banco_liberacao
                        ,p_cd_agencia_conta_liberacao  => r_header.cd_agencia_liberacao
                        ,p_cd_conta_liberacao          => r_header.cd_conta_liberacao
                        ,p_cd_banco_conta_recurso      => r_header.cd_banco_recurso
                        ,p_cd_agencia_conta_recurso    => r_header.cd_agencia_recurso
                        ,p_cd_conta_origem_recurso     => r_header.cd_conta_recurso
                        ,p_valor_liberado              => r_header.vl_valor_liberacao    
                        ,p_vl_retencao_custeio         => r_header.vl_retencao
                        ,p_condicao_pgto_custeio       => null
                        ,p_ds_uso_financiamento        => r_header.cd_uso_financiamento
                        ,p_vl_uso_financiamento        => r_header.vl_final_bloqueio
                        ,p_vl_financiamento_mao_obra   => r_header.vl_bloqueio_mao_obra
                        ,p_cd_metodo_pgto_mao_obra     => r_header.cd_metodo_pagamento
                        ,p_condicao_pgto_mao_obra      => r_header.cd_condicao_pagamento
                        -- Incluido em 30/06/2020  - Daniel Pimenta
                        ,p_cd_tipo_contrato            => r_header.cd_condicao_pagamento
                        ,p_cd_destinacao_recurso       => r_header.cd_destinacao_recurso
                        ,p_taxas                       => p_taxas
                        ,p_parcelas                    => p_parcelas
                        ,p_vl_juros                    => r_header.vl_juros
                        ,p_vl_longo_prazo              => r_header.vl_longo_prazo                                                               
                        --                        
                        ,p_org_id                      => vn_org_id
                        ,p_id_execucao_processo        => vn_id_execucao
                        ,p_status                      => vs_status_code
                        ,p_mensagem                    => p_mensagens
                      );
                      print_log('Retorno :'||vs_status_code);
                      p_rec_contrato(vn_h).numero_processo          := vn_id_execucao;
                      p_rec_contrato(vn_h).codigo_referencia        := vn_id_execucao;
                      p_rec_contrato(vn_h).status_processamento     := vs_status_code;
                  end loop;
              end if;    
              --  
        end if;
    end;
    --
    procedure CANCELAR_FINANCIAMENTO ( p_id_integracao_detalhe   in   number
                                     , p_retorno                 out  clob)  is  PRAGMA AUTONOMOUS_TRANSACTION;

      -- Retorno
      rec_retorno                      xxfr_pck_interface_integracao.rec_retorno_integracao;
      tbl_mensagens                    xxfr_ar_pck_executa_processo.tp_mensagens_tbl;
      rec_contrato                     tp_cabecalho_tbl;
      --
    begin
        g_id_integracao_detalhe := p_id_integracao_detalhe;
        
        cancelar_dados( p_id_integracao_detalhe => p_id_integracao_detalhe
                       , p_rec_contrato          => rec_contrato
                       , p_mensagens             => tbl_mensagens
                       , p_registro			         => rec_retorno);

        -- Montar retorno do processo da API
        --
        montar_retorno( p_rec_contrato    => rec_contrato
                      , p_mensagens       => tbl_mensagens
                      , p_rec_retorno     => rec_retorno);
        --
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
        XXFR_AR_PCK_TRANSACOES.retornar_clob( p_id_integracao_detalhe => p_id_integracao_detalhe
                                            , p_retorno               => p_retorno);
    exception
        when others then
          rollback;
          xxfr_pck_logger.log_error;
          rec_retorno."retornoProcessamento"         := 'ERRO';
          rec_retorno."mensagemRetornoProcessamento" := '(201) Erro ao carregar dados para Liberação de Contrato de Financiamento : '||SQLERRM;

          xxfr_pck_interface_integracao.erro( p_id_integracao_detalhe  => p_id_integracao_detalhe,
                                              p_ds_dados_retorno       => rec_retorno  );

          XXFR_AR_PCK_TRANSACOES.retornar_clob( p_id_integracao_detalhe => p_id_integracao_detalhe
                                                  , p_retorno               => p_retorno);

    end;

    procedure PROCESSAR_LIBERA_FINANCIAMENTO ( 
      p_id_integracao_detalhe   in   number,
      p_retorno                 out  clob
    ) is  
      --PRAGMA AUTONOMOUS_TRANSACTION;
      -- Retorno
      rec_retorno                      xxfr_pck_interface_integracao.rec_retorno_integracao;
      tbl_mensagens                    xxfr_ar_pck_executa_processo.tp_mensagens_tbl;
      rec_contrato                     tp_cabecalho_tbl;
      --
    begin
      print_log('============================================================================');
      print_log('INICIO DO PROCESSO - FINANCIAMENTO '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
      print_log('============================================================================');
        carregar_dados( p_id_integracao_detalhe => p_id_integracao_detalhe
                       , p_rec_contrato          => rec_contrato
                       , p_mensagens             => tbl_mensagens
                       , p_registro			         => rec_retorno
        );
        -- Montar retorno do processo da API
        --
        montar_retorno( p_rec_contrato    => rec_contrato
                      , p_mensagens       => tbl_mensagens
                      , p_rec_retorno     => rec_retorno);
        --
        if rec_retorno."retornoProcessamento" = 'SUCESSO' then
            commit;
            xxfr_pck_interface_integracao.sucesso( 
              p_id_integracao_detalhe   => p_id_integracao_detalhe,
              p_ds_dados_retorno        => rec_retorno  
            );
        else
            rollback;
            xxfr_pck_interface_integracao.erro( 
              p_id_integracao_detalhe  => p_id_integracao_detalhe,
              p_ds_dados_retorno       => rec_retorno  
            );
        end if;
        --
        XXFR_AR_PCK_TRANSACOES.retornar_clob( 
          p_id_integracao_detalhe => p_id_integracao_detalhe,
          p_retorno               => p_retorno
        );
      print_log('============================================================================');
      print_log('FIM DO PROCESSO - FINANCIAMENTO '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
      print_log('============================================================================');
    exception
        when others then
          rollback;
          xxfr_pck_logger.log_error;
          rec_retorno."retornoProcessamento"         := 'ERRO';
          rec_retorno."mensagemRetornoProcessamento" := '(201) Erro ao carregar dados para Liberação de Contrato de Financiamento : '||SQLERRM;
          --
          xxfr_pck_interface_integracao.erro( 
            p_id_integracao_detalhe  => p_id_integracao_detalhe,
            p_ds_dados_retorno       => rec_retorno  
          );
          XXFR_AR_PCK_TRANSACOES.retornar_clob( 
            p_id_integracao_detalhe => p_id_integracao_detalhe,
            p_retorno               => p_retorno
          );
    end;
end;

