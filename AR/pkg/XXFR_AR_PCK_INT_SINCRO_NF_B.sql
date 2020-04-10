create or replace package body XXFR_AR_PCK_INT_SINCRO_NF AS

  str_json     varchar2(30000);
  l            number;
  h            number;
  g_escopo     varchar2(50);
  g_user_name  varchar2(50);
  ok           boolean := true;
  
  nota_fiscal        XXFR_PCK_SINCRONIZAR_NOTA.rec_nota_fiscal;
  item_nota_fiscal   XXFR_PCK_SINCRONIZAR_NOTA.tab_item_nota_fiscal;
  ordem_venda        XXFR_PCK_SINCRONIZAR_NOTA.rec_ordem_venda;
  
  procedure print_log(msg   in Varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;
  
  procedure initialize is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('AR','UO_FRISIA');
  exception
    when others then
      ok := false;
      print_log('  '||sqlerrm);
  end;
  
  procedure main(p_customer_trx_id in number) is
  
    id_integracao_cabecalho number;
    id_integracao_detalhe   number;
    id_integracao_chave     number;
    ie_status               varchar2(200);
  
  begin
    g_escopo := 'SINCRONIZAR_NOTA_FISCAL_'||p_customer_trx_id;
    print_log('----------------------------------------------------------------');
    print_log('INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS') || ' - CUSTOMER_TRX_ID:' || p_customer_trx_id );
    print_log('----------------------------------------------------------------');
    --
    ok := true;
    initialize;
    --
    if (ok) then
      begin
        select user_name into g_user_name
        from fnd_user 
        where user_id = fnd_profile.value('USER_ID');
        --
        ok := monta_type(p_customer_trx_id);
        --
      exception
        when others then
          print_log('  Problemas ao inicializar variaveis de ambiente Oracle');
          ok := false;
      end;
    end if;
    if (ok) then   
      print_log('Chamando XXFR_PCK_SINCRONIZAR_NOTA.REGISTRAR...');
      XXFR_PCK_SINCRONIZAR_NOTA.registrar(
        p_sistema_origem          => 'XXX',
        p_nota_fiscal             => nota_fiscal,
        p_id_integracao_cabecalho => id_integracao_cabecalho,
        p_id_integracao_detalhe   => id_integracao_detalhe,
        p_ie_status               => ie_status
      );
      print_log('Id Integração Cab:'||id_integracao_cabecalho);
      print_log('Id Integração Det:'||id_integracao_detalhe);
      print_log('Status           :'||ie_status);
      --
      if (ie_status='SUCESSO') then
        print_log('');
        print_log('Chamando XXFR_PCK_SINCRONIZAR_NOTA.PROCESSAR...');
        --
        xxfr_pck_sincronizar_nota.processar(
          p_id_integracao_cabecalho => id_integracao_cabecalho,
          p_ie_status               => ie_status,
          p_id_integracao_chave     => id_integracao_chave
        );
        print_log('Id Integração Chv:'||id_integracao_chave);
        print_log('Status           :'||ie_status);
        if (ie_status='SUCESSO') then
          ok := true;
        else
          ok := false;
        end if;
      else
        ok := false;
      end if;    
    end if;
    
    if (ok) then
      commit;
    else
      rollback;
    end if;
    
    print_log('----------------------------------------------------------------');
    print_log('FIM DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS') || ' - CUSTOMER_TRX_ID:' || p_customer_trx_id );
    print_log('----------------------------------------------------------------');
  end;

  function monta_json(p_customer_trx_id in number) return boolean is
  begin
    h:=0;
    for r1 in (select * from XXFR_AR_VW_INF_DA_NF_CABECALHO where customer_trx_id = p_customer_trx_id) loop
      str_json := '{' || chr(13);
      str_json := str_json || '  "idTransacao": -1,'|| chr(13);
      str_json := str_json || '  "versaoPayload": 1.0,'|| chr(13);
      str_json := str_json || '  "sistemaOrigem": "SIF.VEI",'|| chr(13);
      str_json := str_json || '  "codigoServico": "SINCRONIZAR_NOTA_FISCAL",'|| chr(13);
      str_json := str_json || '  "usuario": "' || g_user_name || '",'|| chr(13);
      str_json := str_json || '  "publicarNotaFiscal": {  '|| chr(13);
      str_json := str_json || '    "codigounidadeOperacional" : "'||r1."codigoUnidadeOperacional"||'",' || chr(13);
      str_json := str_json || '    "numeroCnpjFilial" : "'||r1."numeroCnpjFilial"||'",' || chr(13);
      str_json := str_json || '    "nomeFilial" : "'||r1."nomeFilial"||'",' || chr(13);
      str_json := str_json || '    "dataCriacao" : "'||r1."dataCriacao"||'",' || chr(13);
      str_json := str_json || '    "numeroNotaFiscal" : "'||r1."numeroNotaFiscal"||'",' || chr(13);
      str_json := str_json || '    "codigoSerie" : "'||r1."codigoSerie"||'",' || chr(13);
      str_json := str_json || '    "dataEmissao" : "'||r1."dataEmissao"||'",' || chr(13);
      str_json := str_json || '    "codigoCliente" : "'||r1."codigoCliente"||'",' || chr(13);
      str_json := str_json || '    "numeroPropriedadeEntrega" : "'||r1."numeroPropriedadeEntrega"||'",' || chr(13);
      str_json := str_json || '    "numeroPropriedadeFaturamento" : "'||r1."numeroPropriedadeFaturamento"||'",' || chr(13);
      str_json := str_json || '    "observacao" : "'||r1."observacao"||'",' || chr(13);
      str_json := str_json || '    "statusSefaz" : "'||r1."statusSefaz"||'",' || chr(13);
      str_json := str_json || '    "codigoChaveAcessoSefaz" : "'||r1."codigoChaveAcessoSefaz"||'",' || chr(13);
      str_json := str_json || '    "itemNotaFiscal": [' || chr(13);
      h := h +1;
      l := 0;
      for r2 in (select * from XXFR_AR_VW_INF_DA_NF_LINHA where customer_trx_id = p_customer_trx_id) loop
        if (l > 0) then
          str_json := str_json || '      ,' || chr(13);
        end if;
        str_json := str_json || '      {' || chr(13);
        str_json := str_json || '        "numeroLinha": "'||r2."numeroLinha"||'",' || chr(13);
        str_json := str_json || '        "codigoItem": "'||r2."codigoItem"||'",' || chr(13);
        str_json := str_json || '        "quantidade": "'||r2."quantidade"||'",' || chr(13);
        str_json := str_json || '        "unidadeMedida": "'||r2."unidadeMedida"||'",' || chr(13);
        str_json := str_json || '        "valorUnitario": "'||r2."valorUnitario"||'",' || chr(13);
        str_json := str_json || '        "codigoMoeda": "'||r2."codigoMoeda"||'",' || chr(13);
        str_json := str_json || '        "codigoLote": "'||r2."codigoLote"||'",' || chr(13);
        str_json := str_json || '        "observacao": "'||r2."observacao"||'"' || chr(13);
        str_json := str_json || '        "ordemVenda": {' || chr(13);
        str_json := str_json || '          "numeroOrdemVenda": "'||r2."numeroOrdemVenda"||'"' || chr(13);
        str_json := str_json || '          "codigoTipoOrdemVenda": "'||r2."codigoTipoOrdemVenda"||'"' || chr(13);
        str_json := str_json || '          "numeroLinha": "'||r2."numeroLinha"||'"' || chr(13);
        str_json := str_json || '          "tipoReferenciaOrigem": "'||r2."tipoReferenciaOrigem"||'"' || chr(13);
        str_json := str_json || '          "areaAtendida": "'||r2."areaAtendida"||'"' || chr(13);   
        str_json := str_json || '        }' || chr(13);
        str_json := str_json || '      }' || chr(13);
        l := l+1;
      end loop;
      str_json := str_json || '    ]' || chr(13);
    end loop;
    if (h > 0) then
      str_json := str_json || '  }' || chr(13);
      str_json := str_json || '}' || chr(13);
      print_log('----------------------------- JSON -----------------------------');
      print_log(str_json);
      return true;
    else
      print_log('  NOTA NÃO ENCONTRADA !!!');    
    end if;
    return false;
  end monta_json;

  function monta_type(p_customer_trx_id in number) return boolean is
  
  begin
    print_log('XXFR_AR_PCK_INT_SINCRO_NF.MONTA_TYPE');
    h:=0;
    begin
    for r1 in (select * from XXFR_AR_VW_INF_DA_NF_CABECALHO where customer_trx_id = p_customer_trx_id) loop
      h:=h+1;
      nota_fiscal."codigounidadeOperacional"      :=r1."codigoUnidadeOperacional";
      nota_fiscal."numeroCnpjFilial"              :=r1."numeroCnpjFilial";
      nota_fiscal."nomeFilial"                    :=r1."nomeFilial";
      nota_fiscal."dataCriacao"                   :=r1."dataCriacao";
      nota_fiscal."numeroNotaFiscal"              :=r1."numeroNotaFiscal";
      nota_fiscal."codigoSerie"                   :=r1."codigoSerie";
      nota_fiscal."dataEmissao"                   :=r1."dataEmissao";
      nota_fiscal."codigoCliente"                 :=r1."codigoCliente";
      nota_fiscal."numeroPropriedadeEntrega"      :=r1."numeroPropriedadeEntrega";
      nota_fiscal."numeroPropriedadeFaturamento"  :=r1."numeroPropriedadeFaturamento";
      nota_fiscal."observacao"                    :=r1."observacao";
      nota_fiscal."statusSefaz"                   :=r1."statusSefaz";
      nota_fiscal."codigoChaveAcessoSefaz"        :=r1."codigoChaveAcessoSefaz";
      
      l:=0;
      for r2 in (select * from XXFR_AR_VW_INF_DA_NF_LINHA where customer_trx_id = '39001') loop 
        l:=l+1;
        
        item_nota_fiscal(l)."numeroLinha"   :=r2."numeroLinha";
        item_nota_fiscal(l)."codigoItem"    :=r2."codigoItem";
        item_nota_fiscal(l)."quantidade"    :=r2."quantidade";
        item_nota_fiscal(l)."unidadeMedida" :=r2."unidadeMedida";
        item_nota_fiscal(l)."valorUnitario" :=r2."valorUnitario";
        item_nota_fiscal(l)."codigoMoeda"   :=r2."codigoMoeda";
        item_nota_fiscal(l)."codigoLote"    :=r2."codigoLote";
        item_nota_fiscal(l)."observacao"    :=r2."observacao";
          
        ordem_venda."numeroOrdemVenda"      := r2."numeroOrdemVenda";
        ordem_venda."codigoTipoOrdemVenda"  := r2."codigoTipoOrdemVenda";
        ordem_venda."numeroLinha"           := r2."numeroLinha";
        ordem_venda."tipoReferenciaOrigem"  := r2."tipoReferenciaOrigem";
        ordem_venda."codigoReferenciaOrigem":= r2."codigoReferenciaOrigem";
        ordem_venda."areaAtendida"          := r2."areaAtendida";
        
        item_nota_fiscal(l)."ordensVenda" := ordem_venda;
      end loop;
      nota_fiscal."itensNotaFiscal" := item_nota_fiscal;
    end loop;
    exception when others then
      ok:=false;
      print_log('  Erro:'||sqlerrm);
    end;
    if (h > 0) then
      ok:= true;
    else
      print_log('  NOTA NÃO ENCONTRADA !!!'); 
      ok:= false;
    end if;
    print_log('FIM XXFR_AR_PCK_INT_SINCRO_NF.MONTA_TYPE');
    print_log('');
    return ok;
  end monta_type;

end;
/
