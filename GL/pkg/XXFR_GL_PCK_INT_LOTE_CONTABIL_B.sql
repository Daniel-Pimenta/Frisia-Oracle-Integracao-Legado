create or replace package body XXFR_GL_PCK_INT_LOTE_CONTABIL as

  ok                      boolean;
  g_escopo                varchar2(50) := 'XXFR_GL_PCK_INT_LOTE_CONTABIL';
  g_id_integracao_detalhe number;
  
  g_group_id              number;
  g_livro                 varchar2(50);
  g_origem                varchar2(100);
  
  
  g_gl_interface          gl_interface%rowtype;
  g_erro_msg              varchar2(200);
  g_step                  varchar2(200);
  
  g_rec_retorno      	xxfr_pck_interface_integracao.rec_retorno_integracao;
  g_tab_mensagens     xxfr_pck_interface_integracao.tab_retorno_mensagens;

  procedure monta_json (
    p_gl_rec                in  XXFR_GL_PCK_INT_LOTE_CONTABIL.gl_rec,
    x_id_integracao_detalhe out number
  ) is
  
    p_seq_cab number;
    p_seq_det number;
    isnew     boolean := true;
    ok        boolean;
  
    str_json varchar2(32000) := ('
{
  "idTransacao": -1,
  "versaoPayload": 1.0,
  "sistemaOrigem": "SIF.VEI",
  "codigoServico": "PROCESSAR_CONTABILIZACAO",
  "usuario": "'||fnd_profile.value('USERNAME')||'",
  "processarContabilizacao": {
    "livroContabil": "'||p_gl_rec.livroContabil||'",
    "dataCriacao": "'||p_gl_rec.dataCriacao||'",
    "dataContabil": "'||p_gl_rec.dataContabil||'",
    "moeda": "'||p_gl_rec.moeda||'",
    "categoriaLancamento": "'||p_gl_rec.categoriaLancamento||'",
    "origemLancamento": "'||p_gl_rec.origemLancamento||'",
    "descricao":"'||p_gl_rec.descricao||'",                                                  
    "movimentosContabeis": [
      {
        "codigoReferenciaOrigem": "'||p_gl_rec.movimento(1).codigoReferenciaOrigem||'",
        "tipoReferenciaOrigem": "'||p_gl_rec.movimento(1).tipoReferenciaOrigem||'", 
        "tipoTrasacao": "'||p_gl_rec.movimento(1).tipoTransacao||'",
        "chaveContabil": "'||p_gl_rec.movimento(1).chaveContabil||'",
        "valor": '||p_gl_rec.movimento(1).valor||',
        "descricao":"'||p_gl_rec.movimento(1).descricao||'"                                                 
      },
      {
        "codigoReferenciaOrigem": "'||p_gl_rec.movimento(2).codigoReferenciaOrigem||'",
        "tipoReferenciaOrigem": "'||p_gl_rec.movimento(2).tipoReferenciaOrigem||'", 
        "tipoTrasacao": "'||p_gl_rec.movimento(2).tipoTransacao||'",
        "chaveContabil": "'||p_gl_rec.movimento(2).chaveContabil||'",
        "valor": '||p_gl_rec.movimento(2).valor||',
        "descricao":"'||p_gl_rec.movimento(2).descricao||'"    
      }                                            
    ]
  }
}
  ');
  begin
    print_log('  Cria Json...');
    ok := true;
    
    if isnew then
      select min(id_integracao_cabecalho) -1 into  p_seq_cab from xxfr_integracao_cabecalho;
      select min(id_integracao_detalhe) -1 into  p_seq_det from xxfr_integracao_detalhe;
    end if;
    --
    --delete xxfr_integracao_detalhe   where id_integracao_detalhe = p_seq_det;
    --delete xxfr_integracao_cabecalho where id_integracao_cabecalho = p_seq_cab;
    --HEADER
    begin
      insert into xxfr_integracao_cabecalho (
        id_integracao_cabecalho, 
        dt_criacao, 
        nm_usuario_criacao, 
        cd_programa_criacao, 
        dt_atualizacao, 
        nm_usuario_atualizacao, 
        cd_programa_atualizacao, 
        cd_sistema_origem, 
        cd_sistema_destino, 
        nr_sequencia_fila, 
        cd_interface, 
        cd_chave_interface, 
        ie_status_integracao, 
        dt_conclusao_integracao
      ) values (
        p_seq_cab,
        sysdate,
        fnd_profile.value('USERNAME'),
        'PL/SQL Developer',
        sysdate,
        fnd_profile.value('USERNAME'),
        '',
        '',
        'EBS',
        1,
        'PROCESSAR_CONTABILIZACAO',
        null,
        'NOVO',
        null
      );
      print_log('  ID CABECALHO:'||p_seq_cab);
    exception
      when others then
        print_log('  ERRO CABE�ALHO OTHERS :'||sqlerrm);
        ok := false;
    end;
    --DETALHE
    begin
      insert into xxfr_integracao_detalhe (
        id_integracao_detalhe, 
        id_integracao_cabecalho, 
        dt_criacao, 
        nm_usuario_criacao, 
        dt_atualizacao, 
        nm_usuario_atualizacao, 
        cd_interface_detalhe, 
        ie_status_processamento, 
        dt_status_processamento, 
        ds_dados_requisicao, 
        ds_dados_retorno
      ) values (
        p_seq_det,
        p_seq_cab,
        sysdate,
        fnd_profile.value('USERNAME'),
        sysdate,
        fnd_profile.value('USERNAME'),
        'PROCESSAR_CONTABILIZACAO',
        'PENDENTE',
        sysdate,
        str_json,
        null
      );
      print_log('  ID DETALHE:'||p_seq_det);
    exception
      when others then
        print_log('  ERRO DETALHE OTHERS :'||sqlerrm);
        print_log('  ID DETALHE:'||p_seq_det);
        ok := false;
    end;
    --
    if (ok) then
      commit;
      x_id_integracao_detalhe := p_seq_det;
    else
      rollback;
      x_id_integracao_detalhe := null;
    end if;
    print_log('  Id_Integra��o_Detalhe :'||p_seq_det);
    print_log('  Fim Cria Json...');
  end;

  procedure print_log(msg   in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo ||'_' || g_id_integracao_detalhe
    );
  end;

  function pre_validacao return boolean is
    l_d number;
    l_c number;
  begin
    select 
      sum(decode(TIPO_TRANSACAO,'DEBITO', VALOR *(-1),0)) D, 
      sum(decode(TIPO_TRANSACAO,'CREDITO',VALOR,0))       C
    into l_d, l_c
    from xxfr_gl_vw_int_lotecontabil
    WHERE ID_INTEGRACAO_DETALHE = g_id_integracao_detalhe;
    if ((l_d + l_c) = 0) then
      return true;
    end if;
    return false;
  exception 
    when no_data_found then
      print_log('ERRO NA PRE-VALIDA��O:'||sqlerrm);
      return false;
  end;

  procedure retornar_clob( 
    p_id_integracao_detalhe in xxfr.xxfr_integracao_detalhe.id_integracao_detalhe%type, 
    p_retorno               in out clob
  ) is
  begin
    select ds_dados_retorno into p_retorno 
    from xxfr.xxfr_integracao_detalhe t
    where id_integracao_detalhe = p_id_integracao_detalhe;
    exception
      when others then
        p_retorno := null;
  end;

  procedure carrega_dados is
  begin
    null;
  end;
  
  procedure main(
    p_gl_rec                in  xxfr_gl_pck_int_lote_contabil.gl_rec,
    x_id_integracao_detalhe out number,
    x_retorno               out varchar2
  ) is
  
    x_clob_retorno               clob;
    l_id_integracao_detalhe      number;
  
  begin
    if (fnd_profile.value('USERNAME') is null) then
      xxfr_gl_pck_transacoes.initialize;
    end if;
    monta_json(p_gl_rec, l_id_integracao_detalhe);
    --
    processar(l_id_integracao_detalhe, x_clob_retorno);
    --
    x_id_integracao_detalhe := l_id_integracao_detalhe;
    if (ok) then
      x_retorno := 'S';
    else
      x_retorno := g_rec_retorno."mensagemRetornoProcessamento";
    end if;
  end;
  
  procedure processar(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  ) IS
  
    linha            number;
    i                number;
    l_request_id     number;
    w_je_source_name varchar2(250);
     
    cursor c1 is 
      select *
      from xxfr_gl_vw_int_lotecontabil
      where id_integracao_detalhe = g_id_integracao_detalhe;
  
  begin
    g_id_integracao_detalhe := p_id_integracao_detalhe;
    print_log('============================================================================');
    print_log('GERANDO OPEN INTERFACE GL...  INICIANDO O LOOP - '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS'));
    print_log('============================================================================');
    begin
      if (pre_validacao) then 
        g_group_id := xxfr_fnc_sequencia_unica('PROCESSAR_LOTE_CONTABIL');
        --
        print_log('ID INTEGRACAO:'||g_id_integracao_detalhe);
        print_log('NUMERO LOTE  :'||g_group_id);
        --
        p_retorno := NULL;
        linha := 0;
        
        g_rec_retorno := NULL;
        g_rec_retorno."contexto":= 'PROCESSAR_LOTE_CONTABIL';
        
        ok := true;
        i:= 0;
        print_log('INICIO DO LOOP...');
        
        for r1 in c1 loop
          linha := linha + 1;
          print_log('');
          print_log('Lan�amento:'||linha);
          begin
            select je_source_name into w_je_source_name from gl_je_sources where user_je_source_name = r1.origem_lancamento;
            print_log('Origem    :'||r1.origem_lancamento);
            print_log('Origem GL :'||w_je_source_name);
          exception
            when no_data_found then
              print_log('  ORIGEM INVALIDA:'|| r1.origem_lancamento);
              ok := false;
          end;
          if (ok and monta_interface(r1) = false) then
            i := i+1;
            g_rec_retorno."registros"(i)."tipoCabecalho"               := 'LAN�AMENTO '||linha;
            g_rec_retorno."registros"(i)."codigoCabecalho"             := null;
            g_rec_retorno."registros"(i)."tipoReferenciaOrigem"        := 'GL_INTERFACE';
            g_rec_retorno."registros"(i)."codigoReferenciaOrigem"      := '';
            g_rec_retorno."registros"(i)."retornoProcessamento"        := 'ERRO';
            g_rec_retorno."registros"(i)."mensagens"(1)."tipoMensagem" := 'ERRO';
            g_rec_retorno."registros"(i)."mensagens"(1)."mensagem"     := g_erro_msg;
            ok := false; 
          end if;
          -- GRAVA NA INTERFACE
          if (ok) then
            xxfr_gl_pck_transacoes.gravar_interface(
              p_gl_interface  =>  g_gl_interface,
              x_retorno       =>  p_retorno
            );
            print_log('  Retorno:'||p_retorno);
            if (p_retorno <> 'S') then
              ok := false;
              i := i+1;
              g_rec_retorno."registros"(i)."tipoCabecalho"               := 'LAN�AMENTO '||linha;
              g_rec_retorno."registros"(i)."codigoCabecalho"             := null;
              g_rec_retorno."registros"(i)."tipoReferenciaOrigem"        := 'GL_INTERFACE';
              g_rec_retorno."registros"(i)."codigoReferenciaOrigem"      := '';
              g_rec_retorno."registros"(i)."retornoProcessamento"        := 'ERRO';
              g_rec_retorno."registros"(i)."mensagens"(1)."tipoMensagem" := 'ERRO';
              g_rec_retorno."registros"(i)."mensagens"(1)."mensagem"     := p_retorno;
            end if;
          end if;
        end loop;
        print_log('FIM DO LOOP');
        print_log('');
        
        print_log('PROCESSA_INTERFACE...');
        if (ok) then
          COMMIT;
          XXFR_GL_PCK_TRANSACOES.PROCESSA_INTERFACE(
            p_livro       => g_livro,
            p_numero_lote => g_group_id, 
            p_origem      => g_origem,
            x_request_id  => l_request_id,
            x_retorno     => p_retorno
          );
          print_log('Retorno:'||p_retorno);
          if (p_retorno <> 'S') then
            print_log(' ');
            print_log('  ERRO !!!');
            ROLLBACK;
            g_rec_retorno."retornoProcessamento"        := 'ERRO';
            g_rec_retorno."mensagemRetornoProcessamento":= 'FALHA NO PROCESSAMENTO DA INTERFACE';
            
            if (nvl(l_request_id,0) > 0) then
              for r2 in (select je_line_num, status from gl_interface where request_id = l_request_id) loop
              
                g_rec_retorno."registros"(1)."tipoCabecalho"               := 'FALHA DO CONCURRENT';
                g_rec_retorno."registros"(1)."codigoCabecalho"             := 'REQUEST-ID:'||l_request_id;
                g_rec_retorno."registros"(1)."tipoReferenciaOrigem"        := 'GLLEZL';
                g_rec_retorno."registros"(1)."codigoReferenciaOrigem"      := '';
                g_rec_retorno."registros"(1)."retornoProcessamento"        := 'ERRO';
                g_rec_retorno."registros"(1)."mensagens"(r2.je_line_num)."tipoMensagem" := 'LINHA:'||r2.je_line_num||' - CODIGO:'||r2.status;
                g_rec_retorno."registros"(1)."mensagens"(r2.je_line_num)."mensagem"     := p_retorno;
                print_log(r2.je_line_num||' - '||r2.status);
              end loop;
            else
              g_rec_retorno."registros"(1)."tipoCabecalho"               := 'FALHA DO CONCURRENT';
              g_rec_retorno."registros"(1)."codigoCabecalho"             := null;
              g_rec_retorno."registros"(1)."tipoReferenciaOrigem"        := 'GLLEZL';
              g_rec_retorno."registros"(1)."mensagens"(1)."tipoMensagem" := 'ERRO';
              g_rec_retorno."registros"(1)."mensagens"(1)."mensagem"     := p_retorno;
            end if;
            --
            xxfr_pck_interface_integracao.erro (
              p_id_integracao_detalhe   => p_id_integracao_detalhe,
              p_ds_dados_retorno        => g_rec_retorno
            );
          else
            print_log(' ');
            print_log('  SUCESSO !!!');
            COMMIT;
            g_rec_retorno."retornoProcessamento"         := 'SUCESSO';
            g_rec_retorno."mensagemRetornoProcessamento" := '';
            xxfr_pck_interface_integracao.sucesso (
              p_id_integracao_detalhe   => p_id_integracao_detalhe,
              p_ds_dados_retorno        => g_rec_retorno
            );
          end if;
        else
          print_log(' ');
          print_log('  ERRO !!!');
          ROLLBACK;
          g_rec_retorno."retornoProcessamento"        := 'ERRO';
          g_rec_retorno."mensagemRetornoProcessamento":= 'FALHA NA MONTAGEM DA INTERFACE';
          xxfr_pck_interface_integracao.erro (
            p_id_integracao_detalhe   => p_id_integracao_detalhe,
            p_ds_dados_retorno        => g_rec_retorno
          );
        end if;
        print_log('FIM PROCESSAR INTERFACE');
  
        print_log('');
        retornar_clob( 
          p_id_integracao_detalhe => p_id_integracao_detalhe, 
          p_retorno               => p_retorno
        );
      else
        ROLLBACK;
        g_rec_retorno."retornoProcessamento"        := 'ERRO';
        g_rec_retorno."mensagemRetornoProcessamento":= 'FALHA NA VALIDA��O INICIAL (SEGMENTOS N�O BALANCEADOS)';
        xxfr_pck_interface_integracao.erro (
          p_id_integracao_detalhe   => p_id_integracao_detalhe,
          p_ds_dados_retorno        => g_rec_retorno
        );
      end if;
    exception
      when others then
        ROLLBACK;
        g_rec_retorno."retornoProcessamento"        := 'ERRO';
        g_rec_retorno."mensagemRetornoProcessamento":= 'ERRO N�O PREVISTO:'||sqlerrm;
        xxfr_pck_interface_integracao.erro (
          p_id_integracao_detalhe   => p_id_integracao_detalhe,
          p_ds_dados_retorno        => g_rec_retorno
        );
    end;
    retornar_clob(g_id_integracao_detalhe, p_retorno);
    print_log(p_retorno);
    print_log('----------------------------------------------------------------');
    print_log('FIM DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS'));
    print_log('----------------------------------------------------------------'); 
  end;
  
  function monta_interface(r1 XXFR_GL_VW_INT_LOTECONTABIL%rowtype) return boolean is
  
    l_segment         varchar2(20);
    l_conta_descricao varchar2(200);
    l_ok              boolean;
    
  begin
    l_ok := true;
    print_log('XXFR_GL_PCK_INT_LOTE_CONTABIL.MONTA_INTERFACE');
    --SIMPLES
    begin 
      --l_n := l_n +1;
      g_gl_interface := null;
      g_gl_interface.status          := 'NEW';
      g_gl_interface.accounting_date := to_date(r1.data_contabil,'YYYY-MM-DD');
      g_gl_interface.currency_code   := r1.moeda;
      g_gl_interface.date_created    := to_date(r1.data_criacao,'YYYY-MM-DD');
      g_gl_interface.actual_flag     := 'A';
      --
      g_gl_interface.group_id        := g_group_id;
      --
      print_log('  ORIGEM:'||r1.origem_lancamento);
      g_origem := r1.origem_lancamento;
      g_livro  := r1.livro_contabil;
      
      g_gl_interface.user_je_category_name         := r1.categoria_lancamento;
      g_gl_interface.user_je_source_name           := r1.origem_lancamento;
      g_gl_interface.currency_conversion_date      := null;
      g_gl_interface.encumbrance_type_id           := null;
      g_gl_interface.budget_version_id             := null;
      g_gl_interface.user_currency_conversion_type := null;
      g_gl_interface.currency_conversion_rate      := null;
      g_gl_interface.average_journal_flag          := null;
      g_gl_interface.originating_bal_seg_value     := null;
      --
      g_gl_interface.segment1 := null;
      g_gl_interface.segment2 := null;
      g_gl_interface.segment3 := null;
      g_gl_interface.segment4 := null;
      g_gl_interface.segment5 := null;
      g_gl_interface.segment6 := null;
      g_gl_interface.segment7 := null;
      g_gl_interface.segment8 := null;
      g_gl_interface.segment9 := null;
      g_gl_interface.segment10 := null;
      g_gl_interface.segment11 := null;
      g_gl_interface.segment12 := null;
      g_gl_interface.segment13 := null;
      g_gl_interface.segment14 := null;
      g_gl_interface.segment15 := null;
      g_gl_interface.segment16 := null;
      g_gl_interface.segment17 := null;
      g_gl_interface.segment18 := null;
      g_gl_interface.segment19 := null;
      g_gl_interface.segment20 := null;
      g_gl_interface.segment21 := null;
      g_gl_interface.segment22 := null;
      g_gl_interface.segment23 := null;
      g_gl_interface.segment24 := null;
      g_gl_interface.segment25 := null;
      g_gl_interface.segment26 := null;
      g_gl_interface.segment27 := null;
      g_gl_interface.segment28 := null;
      g_gl_interface.segment29 := null;
      g_gl_interface.segment30 := null;
      --
      if r1.tipo_transacao = 'DEBITO' then
        g_gl_interface.entered_dr   := r1.valor;
        g_gl_interface.accounted_dr := r1.valor;
      else
        g_gl_interface.entered_cr   := r1.valor;
        g_gl_interface.accounted_cr := r1.valor;
      end if;
      --
      g_gl_interface.transaction_date := null; --to_date(r1.data_contabil,'YYYY-MM-DD');
      --
      g_gl_interface.date_created_in_gl           := null; --to_date(r1.data_contabil,'YYYY-MM-DD');
      g_gl_interface.warning_code                 := null;
      g_gl_interface.status_description           := null;
      g_gl_interface.stat_amount                  := null;
      --
      g_gl_interface.request_id                   := null;
      --
      g_gl_interface.subledger_doc_sequence_id    := null;
      g_gl_interface.subledger_doc_sequence_value := null;
      --
      g_gl_interface.attribute1       := null;
      g_gl_interface.attribute2       := null;
      g_gl_interface.attribute3       := null;
      g_gl_interface.attribute4       := null;
      g_gl_interface.attribute5       := null;
      g_gl_interface.attribute6       := null;
      g_gl_interface.attribute7       := null;
      g_gl_interface.attribute8       := null;
      g_gl_interface.attribute9       := null;
      g_gl_interface.attribute10      := null;
      g_gl_interface.attribute11      := null;
      g_gl_interface.attribute12      := null;
      g_gl_interface.attribute13      := null;
      g_gl_interface.attribute14      := null;
      g_gl_interface.attribute15      := null;
      g_gl_interface.attribute16      := null;
      g_gl_interface.attribute17      := null;
      g_gl_interface.attribute18      := null;
      g_gl_interface.attribute19      := null;
      g_gl_interface.attribute20      := null;
      g_gl_interface.context          := null;
      g_gl_interface.context2         := null;
      g_gl_interface.invoice_date     := null;
      g_gl_interface.tax_code         := null;
      g_gl_interface.gl_sl_link_id    := null;
      g_gl_interface.gl_sl_link_table := null;
      --
      --g_gl_interface.invoice_identifier := r1.no_nf;
      --
      g_gl_interface.invoice_amount           := null;
      g_gl_interface.context3                 := null;
      g_gl_interface.ussgl_transaction_code   := null;
      g_gl_interface.descr_flex_error_message := null;
      g_gl_interface.jgzz_recon_ref           := null;
      g_gl_interface.reference_date           := null;
      
      g_gl_interface.balancing_segment_value  := null;
      g_gl_interface.management_segment_value := null;
      g_gl_interface.funds_reserved_flag      := null;
      g_gl_interface.code_combination_id      := null;  
      
      g_gl_interface.reference1 := r1.tipo_referencia_origem;
      g_gl_interface.reference2 := r1.codigo_referencia_origem;
      g_gl_interface.reference3 := null;
      g_gl_interface.reference4 := null;
      g_gl_interface.reference5 := null;
      g_gl_interface.reference6 := null;
      g_gl_interface.reference7 := null;
      g_gl_interface.reference8 := null;
      g_gl_interface.reference9 := null;
      g_gl_interface.reference10:= r1.descricao_lancamento;
      g_gl_interface.reference11:= null;
      g_gl_interface.reference12:= null;
      g_gl_interface.reference13:= null;
      g_gl_interface.reference14:= null;
      g_gl_interface.reference15:= null;
      g_gl_interface.reference16:= null;
      g_gl_interface.reference17:= null;
      g_gl_interface.reference18:= null;
      g_gl_interface.reference19:= null;
      g_gl_interface.reference20:= null;
      g_gl_interface.reference21:= null;
      g_gl_interface.reference22:= null;
      g_gl_interface.reference23:= null;
      g_gl_interface.reference24:= null;
      g_gl_interface.reference25:= null;
      g_gl_interface.reference26:= null;
      g_gl_interface.reference27:= null;
      g_gl_interface.reference28:= null;
      g_gl_interface.reference29:= null;
      g_gl_interface.reference30:= null;
      --
      g_gl_interface.je_batch_id  := null;
      g_gl_interface.je_header_id := null;
      g_gl_interface.je_line_num  := null;
      --
      g_gl_interface.period_name := to_char(to_date(r1.data_contabil,'YYYY-MM-DD'),'MM-YYYY');
      --
      --
      g_gl_interface.functional_currency_code := r1.moeda;
    exception 
      when others then
        g_erro_msg := g_step || ' - '||sqlerrm;
        print_log('  Erro:'||g_erro_msg);
        l_ok:=false;
    end;
    --PASSIVEL DE ERRO
    if (l_ok) then
      begin
        g_step := 'INFORMA��ES DO LIVRO CONTABIL :'||r1.livro_contabil;
        select
          LEDGER_ID, LEDGER_ID --,chart_of_accounts_id 
          into g_GL_INTERFACE.SET_OF_BOOKS_ID, g_GL_INTERFACE.LEDGER_ID --,g_gl_interface.chart_of_accounts_id
        from gl_ledgers 
        where name = r1.livro_contabil;
        --
        g_step := 'RECUP. DESC.CONTA :'||r1.segment3;
        select a.flex_value_meaning||'-'||a.description
        into l_conta_descricao
        from  
          apps.fnd_flex_values_tl   a
          ,apps.fnd_flex_value_sets b
          ,apps.fnd_flex_values     c
        where 1=1
          --and b.flex_value_set_id    =  '1017655'
          and b.flex_value_set_id    =  c.flex_value_set_id 
          and c.flex_value_id        =  a.flex_value_id     
          --AND source_lang = 'PTB'
          and language               = 'US'
          and a.flex_value_meaning   = r1.segment3
        ;
        --
        g_step := 'RECUP. COD.COMBINATION_ID - CC:'||r1.chave_contabil;
        select distinct code_combination_id 
        into g_gl_interface.code_combination_id
        from gl_code_combinations
        where 1=1 
          and segment1=r1.segment1 
          and segment2=r1.segment2 
          and segment3=r1.segment3 
          and segment4=r1.segment4
          and segment5=r1.segment5 
          and segment6=r1.segment6 
          and segment7=r1.segment7 
          and segment8=r1.segment8 
          and segment9=r1.segment9
        ;
      exception 
        when no_data_found then
          g_erro_msg := g_step || ' - NAO ENCONTRADO';
          print_log('  ERRO:'||g_erro_msg);
          l_ok:=false;
        when others then
          g_erro_msg := g_step || ' - '||sqlerrm;
          print_log('  ERRO:'||g_erro_msg);
          l_ok:=false;
      end;
    end if;
    print_log('FIM XXFR_GL_PCK_INT_LOTE_CONTABIL.MONTA_INTERFACE');
    return l_ok;
  end;

end XXFR_GL_PCK_INT_LOTE_CONTABIL;
/