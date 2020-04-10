create or replace package body XXFR_PCK_SINCRONIZAR_NOTA is

  g_scope_prefix constant varchar2(100) := lower($$plsql_unit) || '.';
  g_busca_chave_natural boolean := true;
  
  ok boolean;

  procedure print_log(msg   in Varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_scope_prefix
    );
  end;

  function validar(p_nota_fiscal rec_nota_fiscal) return boolean is
    l_msg_auxiliar varchar2(300);
  begin
    print_log('  VALIDAR');
    return true;
    print_log('  FIM VALIDAR');
  end;

  function mount(
    p_sistema_origem varchar2,
    p_nota_fiscal    rec_nota_fiscal
  ) return pljson is
  
    --l_lis_ordem_venda xxfr_pljson_list;
    l_lis_itens       xxfr_pljson_list;
    --
    l_obj_processar   xxfr_pljson;
    l_obj_ordem_venda xxfr_pljson;
    l_obj_item        xxfr_pljson;
    l_obj_nota_fiscal xxfr_pljson;
    --
    l_escopo          varchar2(500) := g_scope_prefix || 'mount';
    g_user_name       varchar2(50);
  
  begin
    print_log('  MOUNT');
    
    -- Parametros do cabecacalho do servico
    l_obj_processar := xxfr_pljson();
    select user_name into g_user_name
    from fnd_user 
    where user_id = fnd_profile.value('USER_ID');

    l_obj_processar.put('idTransacao', '-1');
    l_obj_processar.put('usuario', g_user_name);
    l_obj_processar.put('versaoPayload', '1.0');
    l_obj_processar.put('sistemaOrigem', 'SIF.VEI');
    l_obj_processar.put('codigoServico', 'SINCRONIZAR_NOTA_FISCAL');
    
    --l_lis_ordem_venda := xxfr_pljson_list();
    --
    --xxfr_pljson_printer.empty_string_as_null := true;
    --xxfr_pljson_printer.empty_number_not_include := true;
    l_obj_nota_fiscal := xxfr_pljson();
    
    l_obj_nota_fiscal.put('codigounidadeOperacional'    , p_nota_fiscal."codigounidadeOperacional");
    l_obj_nota_fiscal.put('numeroCnpjFilial'            , p_nota_fiscal."numeroCnpjFilial");
    l_obj_nota_fiscal.put('nomeFilial'                  , p_nota_fiscal."nomeFilial");
    l_obj_nota_fiscal.put('numeroNotaFiscal'            , p_nota_fiscal."numeroNotaFiscal");
    l_obj_nota_fiscal.put('codigoSerie'                 , p_nota_fiscal."codigoSerie");
    l_obj_nota_fiscal.put('dataEmissao'                 , p_nota_fiscal."dataEmissao");
    l_obj_nota_fiscal.put('codigoCliente'               , p_nota_fiscal."codigoCliente");
    l_obj_nota_fiscal.put('numeroPropriedadeEntrega'    , p_nota_fiscal."numeroPropriedadeEntrega");
    l_obj_nota_fiscal.put('numeroPropriedadeFaturamento', p_nota_fiscal."numeroPropriedadeFaturamento");
    l_obj_nota_fiscal.put('observacao'                  , p_nota_fiscal."observacao");
    l_obj_nota_fiscal.put('statusSefaz'                 , p_nota_fiscal."statusSefaz");
    
    l_lis_itens := xxfr_pljson_list();
    
    for idx_lin in p_nota_fiscal."itensNotaFiscal".first .. p_nota_fiscal."itensNotaFiscal".last loop
      l_obj_item := pljson();
      l_obj_item.put('numeroLinha',   p_nota_fiscal."itensNotaFiscal"(idx_lin)."numeroLinha");
      l_obj_item.put('codigoItem',    p_nota_fiscal."itensNotaFiscal"(idx_lin)."codigoItem");
      l_obj_item.put('quantidade',    p_nota_fiscal."itensNotaFiscal"(idx_lin)."quantidade");
      l_obj_item.put('unidadeMedida', p_nota_fiscal."itensNotaFiscal"(idx_lin)."unidadeMedida");
      l_obj_item.put('valorUnitario', p_nota_fiscal."itensNotaFiscal"(idx_lin)."valorUnitario");
      l_obj_item.put('codigoMoeda',   p_nota_fiscal."itensNotaFiscal"(idx_lin)."codigoMoeda");
      l_obj_item.put('codigoLote',    p_nota_fiscal."itensNotaFiscal"(idx_lin)."codigoLote");
      l_obj_item.put('observacao',    p_nota_fiscal."itensNotaFiscal"(idx_lin)."observacao");
      
        --l_lis_ordem_venda := xxfr_pljson_list();
        l_obj_ordem_venda := xxfr_pljson();
        l_obj_ordem_venda.put('numeroOrdemVenda', p_nota_fiscal."itensNotaFiscal"(idx_lin)."ordensVenda"."numeroOrdemVenda");
        l_obj_ordem_venda.put('codigoTipoOrdemVenda', p_nota_fiscal."itensNotaFiscal"(idx_lin)."ordensVenda"."codigoTipoOrdemVenda");
        l_obj_ordem_venda.put('numeroLinha', p_nota_fiscal."itensNotaFiscal"(idx_lin)."ordensVenda"."numeroLinha");
        l_obj_ordem_venda.put('codigoReferenciaOrigem', p_nota_fiscal."itensNotaFiscal"(idx_lin)."ordensVenda"."codigoReferenciaOrigem");
        l_obj_ordem_venda.put('tipoReferenciaOrigem', p_nota_fiscal."itensNotaFiscal"(idx_lin)."ordensVenda"."tipoReferenciaOrigem");
        l_obj_ordem_venda.put('areaAtendida', p_nota_fiscal."itensNotaFiscal"(idx_lin)."ordensVenda"."areaAtendida");

        l_obj_item.put('ordemVenda', l_obj_ordem_venda);
        l_lis_itens.append(l_obj_item.to_json_value, idx_lin);
    end loop;
    
    l_obj_ordem_venda.put('itens', l_lis_itens);
  
    l_obj_processar.put('publicarNotaFiscal',l_obj_ordem_venda);
    l_obj_processar.print;
    --
    return l_obj_processar;
  exception
    when others then
      --pack_logger.log_error(p_log => 'Exceção não tratada', p_escopo => l_escopo);
      raise;
  end;
  --
  procedure registrar(
    p_sistema_origem          varchar2,
    p_nota_fiscal             rec_nota_fiscal,
    p_id_integracao_cabecalho out NUMBER,
    p_id_integracao_detalhe   out NUMBER,
    p_ie_status               out NOCOPY varchar2
  ) is
  
    l_nota_fiscal pljson;
    l_escopo      varchar2(200) := g_scope_prefix || 'registra';
    
  begin
    print_log('  XXFR_PCK_SINCRONIZAR_NOTA.REGISTRAR');
    ok := validar(p_nota_fiscal);
    if (not ok) then
      p_ie_status := 'ERRO';
      print_log('Status:'||p_ie_status);
    else
      l_nota_fiscal := mount(p_sistema_origem, p_nota_fiscal);
      --
      print_log('  Chamando XXFR_PCK_INTERFACE_INTEGRACAO.ADICIONA...');
      p_id_integracao_detalhe := xxfr_pck_interface_integracao.adiciona(
        p_cd_interface        => g_cd_servico,
        p_cd_chave_interface  => null,
        p_cd_sistema_origem   => p_sistema_origem,
        p_cd_sistema_destino  => 'EBS',
        p_ds_dados_requisicao => l_nota_fiscal,
        p_id_transacao        => null,
        p_cd_programa         => null
      );
      --
      if (p_id_integracao_detalhe is not null) then
        --
        select distinct id_integracao_cabecalho 
        into p_id_integracao_cabecalho
        from xxfr_integracao_detalhe 
        where id_integracao_detalhe = p_id_integracao_detalhe
        ;
        p_ie_status := 'SUCESSO';
      else 
        p_ie_status := 'ERRO';
      end if;
    end if;
  exception
    when others then
      p_ie_status := 'ERRO';
      print_log('Erro:'||sqlerrm);
      xxfr_pck_logger.log_error(p_log => 'Exceção não tratada', p_escopo => l_escopo);
      raise;
  end;

  procedure processar(
    p_id_integracao_cabecalho in number,
    p_ie_status               out nocopy varchar2,
    p_id_integracao_chave     out number
  ) is
  
    l_params        xxfr_pck_logger.tab_param;
    l_escopo        varchar2(300) := g_scope_prefix || 'processar';
    l_mensagem_erro varchar2(4000);
  
  begin
    print_log('  XXFR_PCK_SINCRONIZAR_NOTA.PROCESSAR');
    print_log('  Chamando XXFR_PCK_WEBSERVICE1.PROCESSAR...');
    print_log('  cab:'||p_id_integracao_cabecalho);
    xxfr_pck_webservice1.processar(
      p_id_integracao_cabecalho => p_id_integracao_cabecalho, 
      p_status                  => p_ie_status
    );
    print_log('  Status:'||p_ie_status);
    
    if p_ie_status != 'SUCESSO' then
      p_ie_status     := 'ERRO';
      
      l_mensagem_erro := 'Não foi possível processar o serviço a partir do ID_INTEGRACAO_CABECALHO ' || p_id_integracao_cabecalho || '.';
      
      print_log('  Não foi possível processar o serviço a partir do ID_INTEGRACAO_CABECALHO ' || p_id_integracao_cabecalho || '.');
      print_log('  '||xxfr_pck_global_mensagem.obtem_erros(false));
      
      xxfr_pck_logger.log_error(l_mensagem_erro);
    end if;
    
  exception
    when others then
      print_log('  Erro:'||sqlerrm);
      xxfr_pck_logger.append_param(l_params, 'p_id_integracao_cabecalho', p_id_integracao_cabecalho);
      xxfr_pck_logger.log_error(p_log => 'Exceção não tratada', p_escopo => l_escopo, p_parametros => l_params);
      p_ie_status := 'ERRO';
  end;

end XXFR_PCK_SINCRONIZAR_NOTA;
