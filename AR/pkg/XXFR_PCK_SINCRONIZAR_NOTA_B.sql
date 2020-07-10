create or replace package body XXFR_PCK_SINCRONIZAR_NOTA is

  g_scope_prefix        constant varchar2(100) := lower($$plsql_unit) || '.';
  g_busca_chave_natural boolean := true;
  ok                    boolean := true;

  procedure print_log(msg   in Varchar2) is
  begin
    XXFR_AR_PCK_INT_SINCRO_NF.print_log(msg);
    /*
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_scope_prefix
    );
    */
  end;

  function validar(p_publica rec_publica) return boolean is
    l_msg_auxiliar varchar2(300);
  begin
    print_log('VALIDAR');
    return true;
    print_log('FIM VALIDAR');
  end;

  function mount(
    p_sistema_origem varchar2,
    p_publica        rec_publica
  ) return xxfr_pljson is
    --
    l_escopo                      varchar2(500) := g_scope_prefix || 'mount';
    g_user_name                   varchar2(50);
    p_nota_fiscal                 rec_nota_fiscal;
    ponto                         number;
    
    l_lis_oe_referencia           xxfr_pljson_list;
    l_lis_itens                   xxfr_pljson_list;
    l_lis_lotes                   xxfr_pljson_list;
    --
    l_obj_processar               xxfr_pljson;
    --
    l_obj_ordem_separacao_semente xxfr_pljson := null;
    l_obj_percurso                xxfr_pljson := null;
    l_obj_oe_referencia           xxfr_pljson := null;
    l_obj_ordem_venda             xxfr_pljson := null;
    l_obj_item                    xxfr_pljson := null;
    l_obj_lotes                   xxfr_pljson := null;                
    l_obj_nota_fiscal             xxfr_pljson := null;
    l_obj_publica                 xxfr_pljson := null;
    
    l_ini  number;
    l_fim  number;
  
  begin
    print_log('  XXFR_PCK_SINCRONIZAR_NOTA.MOUNT');
    -- Parametros do cabecacalho do servico
    
    p_nota_fiscal := null;
    
    select user_name into g_user_name
    from fnd_user 
    where user_id = fnd_profile.value('USER_ID');

    print_log('    Cabeçalho do JSON');
    l_obj_processar := xxfr_pljson();
    l_obj_processar.put('idTransacao', '-1');
    l_obj_processar.put('versaoPayload', g_versao_payload);
    l_obj_processar.put('sistemaOrigem', 'EBS');
    l_obj_processar.put('codigoServico', g_cd_servico);
    l_obj_processar.put('usuario', g_user_name);
    
    l_obj_publica := xxfr_pljson();
    l_obj_publica.put('codigoUnidadeOperacional'    , p_publica."codigoUnidadeOperacional");
    --
    p_nota_fiscal    := p_publica."notaFiscal";
    --
    print_log('    UO:'||p_publica."codigoUnidadeOperacional");
    --xxfr_pljson_printer.empty_string_as_null := true;
    --xxfr_pljson_printer.empty_number_not_include := true;
    l_obj_nota_fiscal := xxfr_pljson();
    print_log('    NF:'||p_nota_fiscal."numeroNotaFiscal");
    ponto:=0;
    l_obj_nota_fiscal.put('codigoOrganizacaoInventario' , p_nota_fiscal."codigoOrganizacaoInventario");
    l_obj_nota_fiscal.put('numeroCnpjFilial'            , p_nota_fiscal."numeroCnpjFilial");
    l_obj_nota_fiscal.put('dataCriacao'                 , p_nota_fiscal."dataCriacao");
    l_obj_nota_fiscal.put('numeroNotaFiscal'            , p_nota_fiscal."numeroNotaFiscal");
    l_obj_nota_fiscal.put('codigoSerie'                 , p_nota_fiscal."codigoSerie");
    l_obj_nota_fiscal.put('dataEmissao'                 , p_nota_fiscal."dataEmissao");
    l_obj_nota_fiscal.put('codigoCliente'               , p_nota_fiscal."codigoCliente");
    l_obj_nota_fiscal.put('numeroPropriedadeEntrega'    , p_nota_fiscal."numeroPropriedadeEntrega");
    l_obj_nota_fiscal.put('numeroPropriedadeFaturamento', p_nota_fiscal."numeroPropriedadeFaturamento");
    l_obj_nota_fiscal.put('observacao'                  , p_nota_fiscal."observacao");
    l_obj_nota_fiscal.put('chaveNotaFiscal'             , p_nota_fiscal."chaveNotaFiscal");
    l_obj_nota_fiscal.put('tipoDocumento'               , p_nota_fiscal."tipoDocumento");
    l_obj_nota_fiscal.put('codigoOrigemTransacao'       , p_nota_fiscal."codigoOrigemTransacao");
    --
    l_lis_itens := xxfr_pljson_list();    
    for idx_lin in p_nota_fiscal."itens".first .. p_nota_fiscal."itens".last loop
      l_obj_item := xxfr_pljson(); 
      print_log('    Linha:'||p_nota_fiscal."itens"(idx_lin)."numeroLinha");
      l_obj_item.put('numeroLinha',   p_nota_fiscal."itens"(idx_lin)."numeroLinha");
      l_obj_item.put('codigoItem',    p_nota_fiscal."itens"(idx_lin)."codigoItem");
      l_obj_item.put('quantidade',    p_nota_fiscal."itens"(idx_lin)."quantidade");
      l_obj_item.put('unidadeMedida', p_nota_fiscal."itens"(idx_lin)."unidadeMedida");
      l_obj_item.put('valorUnitario', p_nota_fiscal."itens"(idx_lin)."valorUnitario");
      l_obj_item.put('codigoMoeda',   p_nota_fiscal."itens"(idx_lin)."codigoMoeda");
      l_obj_item.put('observacao',    p_nota_fiscal."itens"(idx_lin)."observacao");
      
      --LOTES
      l_lis_lotes := xxfr_pljson_list();
      print_log('    Iniciando Lotes...');
      if (p_nota_fiscal."itens"(idx_lin)."lotes".count > 0) then
        for idx_lotes in p_nota_fiscal."itens"(idx_lin)."lotes".first .. p_nota_fiscal."itens"(idx_lin)."lotes".last loop
          print_log('      Lote:'||p_nota_fiscal."itens"(idx_lin)."lotes"(idx_lotes)."codigo");
          l_obj_lotes := xxfr_pljson(); 
          l_obj_lotes.put('codigo',     p_nota_fiscal."itens"(idx_lin)."lotes"(idx_lotes)."codigo");  ponto:=ponto+1;
          l_obj_lotes.put('quantidade', p_nota_fiscal."itens"(idx_lin)."lotes"(idx_lotes)."quantidade");  ponto:=ponto+1;
          
          -- SEPARACAO DE SEMENTE
          print_log('    Iniciando Separacao Sementes...');
          l_obj_ordem_separacao_semente := xxfr_pljson();
          l_obj_ordem_separacao_semente.put('areaAtendida',    p_nota_fiscal."itens"(idx_lin)."lotes"(idx_lotes)."ordemSeparacaoSemente"."areaAtendida"); ponto:=ponto+1;
          l_obj_lotes.put('ordemSeparacaoSemente', l_obj_ordem_separacao_semente); ponto:=ponto+1;
          
          l_lis_lotes.append(l_obj_lotes.to_json_value, idx_lotes);
        end loop;
        l_obj_item.put('lotes',    l_lis_lotes);
      end if;
      --
        --ORDEM DE VENDA
        --l_lis_ordem_venda := xxfr_pljson_list();
        l_obj_ordem_venda := xxfr_pljson();
        l_obj_ordem_venda.put('numeroOrdemVenda',            p_nota_fiscal."itens"(idx_lin)."ordemVenda"."numeroOrdemVenda"); ponto:=ponto+1;
        l_obj_ordem_venda.put('codigoTipoOrdemVenda',        p_nota_fiscal."itens"(idx_lin)."ordemVenda"."codigoTipoOrdemVenda"); ponto:=ponto+1;
        l_obj_ordem_venda.put('tipoReferenciaOrigem',        p_nota_fiscal."itens"(idx_lin)."ordemVenda"."tipoReferenciaOrigem"); ponto:=ponto+1;
        l_obj_ordem_venda.put('codigoReferenciaOrigem',      p_nota_fiscal."itens"(idx_lin)."ordemVenda"."codigoReferenciaOrigem"); ponto:=ponto+1;
        l_obj_ordem_venda.put('numeroLinhaOrdemVenda',       p_nota_fiscal."itens"(idx_lin)."ordemVenda"."numeroLinhaOrdemVenda"); ponto:=ponto+1;
        l_obj_ordem_venda.put('numeroEnvioLinhaOrdemVenda',  p_nota_fiscal."itens"(idx_lin)."ordemVenda"."numeroEnvioLinhaOrdemVenda"); ponto:=ponto+1;
        l_obj_ordem_venda.put('codigoTipoOrdemVendaLinha',   p_nota_fiscal."itens"(idx_lin)."ordemVenda"."codigoTipoOrdemVendaLinha"); ponto:=ponto+1;
        l_obj_ordem_venda.put('tipoReferenciaOrigemLinha',   p_nota_fiscal."itens"(idx_lin)."ordemVenda"."tipoReferenciaOrigemLinha"); ponto:=ponto+1;
        l_obj_ordem_venda.put('codigoReferenciaOrigemLinha', p_nota_fiscal."itens"(idx_lin)."ordemVenda"."codigoReferenciaOrigemLinha"); ponto:=ponto+1;
        --
        /* Retirado em 26/06/2020
        l_obj_ordem_venda.put('numeroOrdemVendaReferencia',             p_nota_fiscal."itens"(idx_lin)."ordemVenda"."numeroOrdemVendaRef");
        l_obj_ordem_venda.put('codigoTipoOrdemVendaReferencia',         p_nota_fiscal."itens"(idx_lin)."ordemVenda"."codigoTipoOrdemVendaRef");
        l_obj_ordem_venda.put('numeroLinhaOrdemVendaReferencia',        p_nota_fiscal."itens"(idx_lin)."ordemVenda"."nuLinhaOrdemVendaReferencia");
        l_obj_ordem_venda.put('numeroEntregaLinhaOrdemVendaReferencia', p_nota_fiscal."itens"(idx_lin)."ordemVenda"."nuEntregaLinhaOrdemVendaRef");
        l_obj_ordem_venda.put('codigoTipoOrdemVendaLinhaReferencia',    p_nota_fiscal."itens"(idx_lin)."ordemVenda"."cdTipoOrdemVendaLinhaRef");
        */
        --Incluido em 26/06/2020
        --PERCURSO
        print_log('    Iniciando Percurso...');
        l_obj_percurso := xxfr_pljson();
        l_obj_percurso.put('codigoCarregamento'                 ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."percurso"."codigoCarregamento"); ponto:=ponto+1;
        l_obj_percurso.put('nomePercurso'                       ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."percurso"."numeroRomaneio"); ponto:=ponto+1;
        l_obj_percurso.put('tipoReferenciaOrigemLinhaEntrega'   ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."percurso"."tipoRefOrigemLinhaEntrega"); ponto:=ponto+1;
        l_obj_percurso.put('codigoReferenciaOrigemLinhaEntrega' ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."percurso"."codRefOrigemLinhaEntrega"); ponto:=ponto+1;
        l_obj_ordem_venda.put('percurso', l_obj_percurso);
        
        -- Incluido em 26/06/2020
        -- REFERENCIA ORDEM DE VENDA.
        print_log('    Iniciando Referencia...');
        print_log('    Ponto:'||ponto); --15
        --
        if (p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia".count > 0) then
          l_ini := nvl(p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia".first,0);
          l_fim := nvl(p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia".last,0);
          --
          print_log('    Ini:'||l_ini);
          print_log('    Fim:'||l_fim);
          l_lis_oe_referencia := xxfr_pljson_list();
          for idx_oeRef in l_ini .. l_fim loop
            print_log('      Ind:'||idx_oeRef);
            l_obj_oe_referencia := xxfr_pljson();
            l_obj_oe_referencia.put('numeroOrdemVenda'           ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia"(idx_oeRef)."numeroOrdemVenda"); ponto:=ponto+1;
            l_obj_oe_referencia.put('codigoTipoOrdemVenda'       ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia"(idx_oeRef)."codigoTipoOrdemVenda"); ponto:=ponto+1;
            l_obj_oe_referencia.put('numeroLinhaOrdemVenda'      ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia"(idx_oeRef)."numeroLinhaOrdemVenda"); ponto:=ponto+1;
            l_obj_oe_referencia.put('numeroEnvioLinhaOrdemVenda' ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia"(idx_oeRef)."numeroEnvioLinhaOrdemVenda"); ponto:=ponto+1;
            l_obj_oe_referencia.put('codigoTipoOrdemVendaLinha'  ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia"(idx_oeRef)."codigoTipoOrdemVendaLinha"); ponto:=ponto+1;
            l_obj_oe_referencia.put('tipoReferenciaOrigemLinha'  ,p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia"(idx_oeRef)."tipoReferenciaOrigemLinha"); ponto:=ponto+1;
            l_obj_oe_referencia.put('codigoReferenciaOrigemLinha',p_nota_fiscal."itens"(idx_lin)."ordemVenda"."oeReferencia"(idx_oeRef)."codigoReferenciaOrigemLinha"); ponto:=ponto+1;
            print_log('    Ponto:'||ponto);
            l_lis_oe_referencia.append(l_obj_oe_referencia.to_json_value, idx_oeRef); ponto:=ponto+1;
          end loop;
        /*
        else
          l_obj_oe_referencia := xxfr_pljson(); ponto:=ponto+1;
          l_lis_oe_referencia.append(l_obj_oe_referencia.to_json_value, 1); ponto:=ponto+1;
        */
          l_obj_ordem_venda.put('ordensVendaReferencia', l_lis_oe_referencia); ponto:=ponto+1;
        end if;

        --
        l_obj_item.put('ordemVenda', l_obj_ordem_venda);
        l_lis_itens.append(l_obj_item.to_json_value, idx_lin);
    end loop;
    
    l_obj_nota_fiscal.put('itens', l_lis_itens);
    
    l_obj_publica.put('notaFiscal',l_obj_nota_fiscal);
    
    l_obj_processar.put('publicarNotaFiscal',l_obj_publica);
    
    --l_obj_processar.print;
    print_log('  FIM XXFR_PCK_SINCRONIZAR_NOTA.MOUNT');
    return l_obj_processar;
  exception
    when others then
      print_log('Erro ponto:'||ponto||' - '||sqlerrm);
      raise;
  end;
  --
  procedure registrar(
    p_sistema_origem          varchar2,
    p_publica                 rec_publica,
    p_id_integracao_cabecalho out NUMBER,
    p_id_integracao_detalhe   out NUMBER,
    p_ie_status               out NOCOPY varchar2
  ) is
  
    l_escopo      varchar2(200) := g_scope_prefix || 'registra';
    
  begin
    print_log('XXFR_PCK_SINCRONIZAR_NOTA.REGISTRAR');
    --ok := validar(p_publica);
    if (ok) then
      w_obj_processar := mount(p_sistema_origem, p_publica);
      --
      print_log('  Chamando XXFR_PCK_INTERFACE_INTEGRACAO.ADICIONA...');
      p_id_integracao_detalhe := xxfr_pck_interface_integracao.adiciona(
        p_cd_interface        => g_cd_servico,
        p_cd_chave_interface  => null,
        p_cd_sistema_origem   => p_sistema_origem,
        p_cd_sistema_destino  => 'EBS',
        p_ds_dados_requisicao => w_obj_processar,
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
    print_log('FIM XXFR_PCK_SINCRONIZAR_NOTA.REGISTRAR');
  exception
    when others then
      p_ie_status := 'ERRO';
      print_log('Erro:'||sqlerrm);
      print_log('FIM XXFR_PCK_SINCRONIZAR_NOTA.REGISTRAR');
      xxfr_pck_logger.log_error(p_log => 'Exceção não tratada', p_escopo => l_escopo);
      --raise;
  end;

  procedure processar(
    p_id_integracao_cabecalho in number,
    p_id_integracao_detalhe   in number,
    p_ie_status               out nocopy varchar2,
    p_id_integracao_chave     out number
  ) is
  
    l_params        xxfr_pck_logger.tab_param;
    l_escopo        varchar2(300) := g_scope_prefix || 'processar';
    l_mensagem_erro varchar2(4000);
  
  begin
    print_log('XXFR_PCK_SINCRONIZAR_NOTA.PROCESSAR');
    print_log('  Chamando XXFR_PCK_WEBSERVICE.PROCESSAR...');
    print_log('  Det:'||p_id_integracao_detalhe);
    --
    xxfr_pck_webservice.processar(
      p_id_integracao_detalhe => p_id_integracao_detalhe, 
      p_status                => p_ie_status
    );
    print_log('  Status:'||p_ie_status);
    if (p_ie_status != 'SUCESSO') then
      p_ie_status     := 'ERRO';
      l_mensagem_erro := 'Não foi possível processar o serviço a partir do ID_INTEGRACAO_CABECALHO ' || p_id_integracao_cabecalho || '.';
      --
      print_log('  Retorno:'||l_mensagem_erro|| p_id_integracao_detalhe);
      print_log('  Msg    :'||xxfr_pck_global_mensagem.obtem_erros(false));
      xxfr_pck_logger.log_error(l_mensagem_erro);
    end if;
    print_log('FIM XXFR_PCK_SINCRONIZAR_NOTA.PROCESSAR');
  exception
    when others then
      print_log('  Erro:'||sqlerrm);
      xxfr_pck_logger.append_param(l_params, 'p_id_integracao_cabecalho', p_id_integracao_cabecalho);
      xxfr_pck_logger.log_error   (p_log => 'Exceção não tratada', p_escopo => l_escopo, p_parametros => l_params);
      p_ie_status := 'ERRO';
      print_log('FIM XXFR_PCK_SINCRONIZAR_NOTA.PROCESSAR');
  end;

end XXFR_PCK_SINCRONIZAR_NOTA;
