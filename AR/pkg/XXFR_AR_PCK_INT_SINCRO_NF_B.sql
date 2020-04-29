create or replace package body XXFR_AR_PCK_INT_SINCRO_NF AS

  str_json     varchar2(30000);
  l            number;
  h            number;
  g_escopo     varchar2(50);
  g_user_name  varchar2(50);
  ok           boolean := true;
  
  publica                 xxfr_pck_sincronizar_nota.rec_publica;
  nota_fiscal             xxfr_pck_sincronizar_nota.rec_nota_fiscal;
  itens                   xxfr_pck_sincronizar_nota.tab_itens;
  ordem_venda             xxfr_pck_sincronizar_nota.rec_ordem_venda;
  ordem_separacao_semente xxfr_pck_sincronizar_nota.rec_ordem_separacao_semente;
  
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
        p_publica                 => publica,
        p_id_integracao_cabecalho => id_integracao_cabecalho,
        p_id_integracao_detalhe   => id_integracao_detalhe,
        p_ie_status               => ie_status
      );
      print_log('');
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
          p_id_integracao_detalhe   => id_integracao_detalhe,
          p_ie_status               => ie_status,
          p_id_integracao_chave     => id_integracao_chave
        );
        print_log('');
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
    xxfr_pck_sincronizar_nota.l_obj_processar.print;
    print_log('----------------------------------------------------------------');
    print_log('FIM DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS') || ' - CUSTOMER_TRX_ID:' || p_customer_trx_id );
    print_log('----------------------------------------------------------------');
  end;

  function monta_type(p_customer_trx_id in number) return boolean is 
  
    cursor c2 is
      select * from XXFR_AR_VW_INF_DA_NF_LINHA 
      where 1=1
        and customer_trx_id = p_customer_trx_id 
      order by "numeroLinha"
    ;
  
  begin
    print_log('XXFR_AR_PCK_INT_SINCRO_NF.MONTA_TYPE');
    h:=0;
    begin
      for r1 in (select * from xxfr_ar_vw_inf_da_nf_cabecalho where customer_trx_id = p_customer_trx_id) loop
        h:=h+1;     
        --
        print_log('  UO:'||r1."codigoUnidadeOperacional");
        publica."codigoUnidadeOperacional"        :=r1."codigoUnidadeOperacional";
        --
        print_log('  NF:'||r1."numeroNotaFiscal");
        nota_fiscal."codigoOrganizacaoInventario" :=r1."codigoOrganizacaoInventario";
        nota_fiscal."numeroCnpjFilial"            :=r1."numeroCnpjFilial";
        nota_fiscal."dataCriacao"                 :=r1."dataCriacao";
        nota_fiscal."numeroNotaFiscal"            :=r1."numeroNotaFiscal";
        nota_fiscal."codigoSerie"                 :=r1."codigoSerie";
        nota_fiscal."dataEmissao"                 :=r1."dataEmissao";
        nota_fiscal."codigoCliente"               :=r1."codigoCliente";
        nota_fiscal."numeroPropriedadeEntrega"    :=r1."numeroPropriedadeEntrega";
        nota_fiscal."numeroPropriedadeFaturamento":=r1."numeroPropriedadeFaturamento";
        nota_fiscal."observacao"                  :=r1."observacao";
        nota_fiscal."chaveNotaFiscal"             :=r1."chaveNotaFiscal";
        nota_fiscal."tipoDocumento"               :=r1."tipoDocumento";
        nota_fiscal."codigoOrigemTransacao"       :=r1."codigoOrigemTransacao";
        
        l:=0;
        for r2 in c2 loop 
          l:=l+1;
          --
          itens(l)."numeroLinha"   :=r2."numeroLinha";
          itens(l)."codigoItem"    :=r2."codigoItem";
          itens(l)."quantidade"    :=r2."quantidade";
          itens(l)."unidadeMedida" :=r2."unidadeMedida";
          itens(l)."valorUnitario" :=r2."valorUnitario";
          itens(l)."codigoMoeda"   :=r2."codigoMoeda";
          itens(l)."codigoLote"    :=r2."codigoLote";
          itens(l)."observacao"    :=r2."observacao";
          --
          ordem_venda."numeroOrdemVenda"            := r2."numeroOrdemVenda";
          ordem_venda."codigoTipoOrdemVenda"        := r2."codigoTipoOrdemVenda";
          ordem_venda."tipoReferenciaOrigem"        := r2."tipoReferenciaOrigem";
          ordem_venda."codigoReferenciaOrigem"      := r2."codigoReferenciaOrigem";
          ordem_venda."numeroLinhaOrdemVenda"       := r2."numeroLinhaOrdemVenda";
          ordem_venda."numeroEnvioLinhaOrdemVenda"  := r2."numeroEnvioLinhaOrdemVenda";
          ordem_venda."codigoTipoOrdemVendaLinha"   := r2."codigoTipoOrdemVendaLinha";
          ordem_venda."codigoReferenciaOrigemLinha" := r2."codigoReferenciaOrigemLinha";
          --
          ordem_separacao_semente."areaAtendida"    := r2."areaAtendida";
          ordem_venda."ordemSeparacaoSemente"       := ordem_separacao_semente;
          --
          itens(l)."ordemVenda" := ordem_venda;
        end loop;
        nota_fiscal."itens" := itens;
      end loop;
      publica."notaFiscal" := nota_fiscal;
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
