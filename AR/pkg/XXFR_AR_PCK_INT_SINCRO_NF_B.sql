create or replace package body XXFR_AR_PCK_INT_SINCRO_NF AS

  str_json      varchar2(30000);
  l             number;
  h             number;
  k             number;
  g_request_id  number;
  g_escopo      varchar2(50);
  g_user_name   varchar2(50);
  ok            boolean := true;
  isCommit      boolean := true;
  isConcurrent  boolean := false;
  
  procedure print_log(msg   in Varchar2) is
  begin
    dbms_output.put_line(msg);
    if (isConcurrent) then apps.fnd_file.put_line (apps.fnd_file.log, msg); end if;
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
      print_log('Erro Inicializacao do Ambiente Oracle:'||sqlerrm);
  end; 
  -- Executado pelo concurrent.
  procedure main2(
    errbuf              out varchar2,
    retcode             out number,
    p_customer_trx_id   in  varchar2
  ) is
  begin
    isConcurrent := true;
    g_request_id      := nvl(fnd_global.conc_request_id,-1);
    main(
      p_customer_trx_id   => p_customer_trx_id
    );
    if (ok) then
      retcode     := 0;
    else
      retcode     := 2;
    end if;
  end;
  
  procedure main(p_customer_trx_id in number) is
  
    id_integracao_cabecalho number;
    id_integracao_detalhe   number;
    id_integracao_chave     number;
    ie_status               varchar2(200);
    l_publica    xxfr_pck_sincronizar_nota.rec_publica;
  
  begin
    g_escopo := 'SINCRONIZAR_NOTA_FISCAL_'||p_customer_trx_id;
    print_log('----------------------------------------------------------------');
    print_log('INICIO DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS') || ' - CUSTOMER_TRX_ID:' || p_customer_trx_id );
    print_log('----------------------------------------------------------------');
    if (g_request_id is not null) then
      print_log('Iniciando pela Trigger...');
      print_log('Customer_trx_id:'||p_customer_trx_id);
      print_log('Request Id     :'||g_request_id);
    end if;
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
        print_log('  Usuario:'||g_user_name);
        l_publica := null;
        l_publica := monta_type(p_customer_trx_id);
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
        p_publica                 => l_publica,
        p_id_integracao_cabecalho => id_integracao_cabecalho,
        p_id_integracao_detalhe   => id_integracao_detalhe,
        p_ie_status               => ie_status
      );
      print_log('');
      print_log('Id Integração Cab:'||id_integracao_cabecalho);
      print_log('Id Integração Det:'||id_integracao_detalhe);
      print_log('Status           :'||ie_status);
      --
      if (ie_status='SUCESSO' and isCommit) then
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
      UPDATE ra_customer_trx_all 
      SET interface_header_attribute15 = 'Y'
      WHERE customer_trx_id = p_customer_trx_id;
      commit;
    else
      rollback;
    end if;

    print_log('----------------------------------------------------------------');
    --if (ok) then xxfr_pck_sincronizar_nota.w_obj_processar.print; end if;
    xxfr_pck_sincronizar_nota.w_obj_processar.print;
    print_log('----------------------------------------------------------------');
    print_log('FIM DO PROCESSO:'||TO_CHAR(SYSDATE,'DD/MM/YYYY - HH24:MI:SS') || ' - CUSTOMER_TRX_ID:' || p_customer_trx_id );
    print_log('----------------------------------------------------------------');
  end;

  function monta_type(p_customer_trx_id in number) return xxfr_pck_sincronizar_nota.rec_publica is 
  
    cursor c2 is
      select distinct 
        "numeroLinha", "codigoItem", "quantidade", "unidadeMedida", "valorUnitario", "codigoMoeda", "observacao",
        "numeroOrdemVenda","codigoTipoOrdemVenda","tipoReferenciaOrigem","codigoReferenciaOrigem",
        "numeroLinhaOrdemVenda","numeroEnvioLinhaOrdemVenda","codigoTipoOrdemVendaLinha",
        --lot_number,
        "codigoReferenciaOrigemLinha","tipoReferenciaOrigemLinha",
        oe_reference_line, header_id, line_id
      from XXFR_AR_VW_INF_DA_NF_LINHA 
      where 1=1
        and customer_trx_id = p_customer_trx_id  --74224 
      order by "numeroOrdemVenda", "numeroLinha", "numeroEnvioLinhaOrdemVenda"
    ;

    cursor c3a (p_order_line_id in number) is
      select distinct
        l.source_order_line_id, 
        h.delivery_id, 
        l.id_ordem_separacao_hdr, 
        l.id_ordem_separacao_lin, 
        l.inventory_item_id, 
        t.primary_quantity, 
        t.lot_number, 
        t.qt_area
      from 
        xxfr_wms_ordem_separacao_hdr  h,
        xxfr_wms_ordem_separacao_lin  l,
        xxfr_wms_ordem_separacao_tran t
      where 1=1
        and h.id_ordem_separacao_hdr = l.id_ordem_separacao_hdr
        and t.id_ordem_separacao_lin = l.id_ordem_separacao_lin
        and l.source_order_line_id   = p_order_line_id
    ;
  
    cursor c3b (p_order_line_id in number) is
      select distinct  
        delivery_detail_id, 
        inventory_item_id, 
        lot_number,
        --
        quantity_invoiced, 
        uom_code, 
        --
        nvl(
        case
          when uom_code = requested_quantity_uom 
          then requested_quantity
          else requested_quantity2
        end
        , quantity_invoiced) quantity,
        --
        requested_quantity, 
        requested_quantity_uom, 
        requested_quantity2, 
        src_requested_quantity_uom2,
        null qt_area
      from xxfr_ar_vw_inf_da_nf_linha
      where 1=1
        and line_id = p_order_line_id
    ;
  
  
    l_itens                   xxfr_pck_sincronizar_nota.tab_itens;
    l_lotes                   xxfr_pck_sincronizar_nota.tab_lotes;
    l_oe_referencia           xxfr_pck_sincronizar_nota.tab_oe_referencia;
  
    l_publica                 xxfr_pck_sincronizar_nota.rec_publica;
    l_nota_fiscal             xxfr_pck_sincronizar_nota.rec_nota_fiscal;
    l_percurso                xxfr_pck_sincronizar_nota.rec_percurso; 
    l_ordem_venda             xxfr_pck_sincronizar_nota.rec_ordem_venda;
    l_ordem_separacao_semente xxfr_pck_sincronizar_nota.rec_ordem_separacao_semente;
  
    ind_ref  number;
  
  begin
    print_log('XXFR_AR_PCK_INT_SINCRO_NF.MONTA_TYPE');
    h:=0;
    
    l_publica := null;
    l_nota_fiscal := null;
    l_percurso    := null;
    l_ordem_venda := null;
    l_ordem_separacao_semente := null;
    
    l_itens.delete();
    l_lotes.delete();
    l_oe_referencia.delete();
    
    begin
      for r1 in (select * from xxfr_ar_vw_inf_da_nf_cabecalho where customer_trx_id = p_customer_trx_id) loop
        h:=h+1;     
        --
        print_log('  UO         :'||r1."codigoUnidadeOperacional");
        print_log('  NF         :'||r1."numeroNotaFiscal");
        print_log('  Serie      :'||r1."codigoSerie");
        print_log('  Origem     :'||r1."codigoOrganizacaoInventario");
        begin
          l_publica."codigoUnidadeOperacional"        :=r1."codigoUnidadeOperacional";
          --NOTA FISCAL
          begin
            l_nota_fiscal."codigoOrganizacaoInventario" :=r1."codigoOrganizacaoInventario";
            l_nota_fiscal."numeroCnpjFilial"            :=r1."numeroCnpjFilial";
            l_nota_fiscal."dataCriacao"                 :=r1."dataCriacao";
            l_nota_fiscal."numeroNotaFiscal"            :=r1."numeroNotaFiscal";
            l_nota_fiscal."codigoSerie"                 :=r1."numeroSerie";
            l_nota_fiscal."dataEmissao"                 :=r1."dataEmissao";
            l_nota_fiscal."codigoCliente"               :=r1."codigoCliente";
            l_nota_fiscal."numeroPropriedadeEntrega"    :=r1."numeroPropriedadeEntrega";
            l_nota_fiscal."numeroPropriedadeFaturamento":=r1."numeroPropriedadeFaturamento";
            l_nota_fiscal."observacao"                  :=r1."observacao";
            l_nota_fiscal."chaveNotaFiscal"             :=r1."chaveNotaFiscal";
            l_nota_fiscal."tipoDocumento"               :=r1."tipoDocumento";
            l_nota_fiscal."codigoOrigemTransacao"       :=r1."codigoOrigemTransacao";
            --ITENS
            begin
              l:=0;
              for r2 in c2 loop 
                l:=l+1;
                print_log('    NF        :'||r1."numeroNotaFiscal");
                print_log('    Linha NF  :'||r2."numeroLinha");
                print_log('    OE Line_Id:'||r2.line_id);
                l_itens(l)."numeroLinha"   :=r2."numeroLinha";
                l_itens(l)."codigoItem"    :=r2."codigoItem";
                l_itens(l)."quantidade"    :=r2."quantidade";
                l_itens(l)."unidadeMedida" :=r2."unidadeMedida";
                l_itens(l)."valorUnitario" :=r2."valorUnitario";
                l_itens(l)."codigoMoeda"   :=r2."codigoMoeda";
                l_itens(l)."observacao"    :=r2."observacao";
                -- LOTES
                print_log('      Lotes');
                begin
                  k:=0;
                  l_lotes.delete();
                  for r3 in c3a(r2.line_id) loop
                    k:=k+1;
                    l_lotes(k)."codigo"     := r3.lot_number;
                    l_lotes(k)."quantidade" := r3.primary_quantity;
                    -- SEPARACAO SEMENTES
                    begin
                      l_ordem_separacao_semente."areaAtendida"    := r3.qt_area;
                    end;
                    print_log('      '||k||'A - Lote:'||l_lotes(k)."codigo"||' - '||l_lotes(k)."quantidade");
                    l_lotes(k)."ordemSeparacaoSemente"  := l_ordem_separacao_semente;
                  end loop;
                  
                  if (k = 0) then
                    for r3 in c3b(r2.line_id) loop
                      k:=k+1;
                      l_lotes(k)."codigo"     := r3.lot_number;
                      l_lotes(k)."quantidade" := r3.quantity;
                      -- SEPARACAO SEMENTES
                      begin
                        l_ordem_separacao_semente."areaAtendida"    := r3.qt_area;
                      end;
                      print_log('      '||k||'B - Lote:'||l_lotes(k)."codigo"||' - '||l_lotes(k)."quantidade");
                      l_lotes(k)."ordemSeparacaoSemente"  := l_ordem_separacao_semente;
                    end loop;
                  end if;
                  
                  if (k=1 and l_lotes(1)."codigo" is null) then
                    k:=0;
                  end if;
                  /*
                    if (nvl(r2.requested_quantity,0) = 0) then
                      l_lotes(k)."quantidade" := r3.primary_quantity;
                    else
                      l_lotes(k)."quantidade" := inv_convert.inv_um_convert(
                        item_id       => r2.inventory_item_id,
                        precision     => null,
                        from_quantity => r2.requested_quantity,
                        from_unit     => r2.requested_quantity_uom,
                        --
                        to_unit       => r2."unidadeMedida",
                        from_name     => null,
                        to_name       => null
                      );
                    end if;
                    */
                  if (k > 0) then
                    l_itens(l)."lotes" := l_lotes;
                  end if;
                end;
                -- PERCURSO
                print_log('      Percurso');
                begin                    
                  select distinct t.attribute14, t.name, t.attribute12, t.attribute13   
                  into 
                    l_percurso."codigoCarregamento",
                    l_percurso."numeroRomaneio",
                    l_percurso."codRefOrigemLinhaEntrega",
                    l_percurso."tipoRefOrigemLinhaEntrega"
                  from 
                    XXFR_WSH_VW_INF_DA_ORDEM_VENDA v,
                    wsh_trips                      t
                  where 1=1
                    and t.trip_id            = v.trip_id
                    and v.oe_line            = r2.line_id
                  ;               
                  print_log('      Cod Carregamento        :'||l_percurso."codigoCarregamento");
                  print_log('      Nome Romaneio           :'||l_percurso."numeroRomaneio");
                  print_log('      Cod Ref Orig Lin Entrega:'||l_percurso."codRefOrigemLinhaEntrega");
                  print_log('      Typ Ref Orig Lin Entrega:'||l_percurso."tipoRefOrigemLinhaEntrega");
                exception 
                  when no_data_found then
                    print_log('      --');
                  when others then
                    print_log('      ** Percurso:'||sqlerrm);
                    ok:=false;
                    goto fim;
                end;
                -- ORDEM VENDA
                print_log('      Ordem de Venda');
                print_log('        Numero :'||r2."numeroOrdemVenda");
                print_log('        Tipo   :'||r2."codigoTipoOrdemVenda");
                print_log('        Linha  :'||r2."numeroLinhaOrdemVenda");
                print_log('        Entrega:'||r2."numeroEnvioLinhaOrdemVenda");
                begin
                  l_ordem_venda."numeroOrdemVenda"            := r2."numeroOrdemVenda";
                  l_ordem_venda."codigoTipoOrdemVenda"        := r2."codigoTipoOrdemVenda";
                  l_ordem_venda."tipoReferenciaOrigem"        := r2."tipoReferenciaOrigem";
                  l_ordem_venda."codigoReferenciaOrigem"      := r2."codigoReferenciaOrigem";
                  l_ordem_venda."numeroLinhaOrdemVenda"       := r2."numeroLinhaOrdemVenda";
                  l_ordem_venda."numeroEnvioLinhaOrdemVenda"  := r2."numeroEnvioLinhaOrdemVenda";
                  l_ordem_venda."codigoTipoOrdemVendaLinha"   := r2."codigoTipoOrdemVendaLinha";
                  l_ordem_venda."tipoReferenciaOrigemLinha"   := r2."tipoReferenciaOrigemLinha";
                  l_ordem_venda."codigoReferenciaOrigemLinha" := r2."codigoReferenciaOrigemLinha";
                  -- REFERENCIA ORDEM VENDA
                  l_oe_referencia.delete();
                  ind_ref := 0;
                  for e1 in (
                    select 
                      e.n_ext_attr1 oe_numero, e.n_ext_attr2 oe_linha, e.n_ext_attr3 oe_entrega, e.c_ext_attr1 oe_tipo, v.cd_tipo_ordem_venda_linha,
                      e.extension_id, e.line_id, e.data_level_id, e.entity
                    from 
                      oe_order_lines_all_ext_b   e,
                      xxfr_om_vw_ordem_venda_lin v
                    where 1=1
                      and entity = 'ADMIN_DEFINED' 
                      and e.n_ext_attr1 = v.nr_ordem_venda
                      and e.n_ext_attr2 = v.nr_linha_ordem_venda
                      and e.n_ext_attr3 = v.nr_entrega_linha_ordem_venda
                      and e.c_ext_attr1 = v.cd_tipo_ordem_venda
                      and line_id = r2.line_id
                  ) loop
                    ind_ref := ind_ref +1;
                    l_oe_referencia(ind_ref)."numeroOrdemVenda"           := e1.oe_numero;
                    l_oe_referencia(ind_ref)."codigoTipoOrdemVenda"       := e1.oe_tipo;
                    l_oe_referencia(ind_ref)."numeroLinhaOrdemVenda"      := e1.oe_linha;
                    l_oe_referencia(ind_ref)."numeroEnvioLinhaOrdemVenda" := e1.oe_entrega;
                    l_oe_referencia(ind_ref)."codigoTipoOrdemVendaLinha"  := e1.cd_tipo_ordem_venda_linha;
                  end loop;
                  
                  l_ordem_venda."percurso"                    := l_percurso;
                  l_ordem_venda."oeReferencia"                := l_oe_referencia;
                end;
                --
                l_itens(l)."ordemVenda" := l_ordem_venda;
                
              end loop;
            end;
            l_nota_fiscal."itens" := l_itens;
          end;
        end;
      end loop;
      <<fim>>
      l_publica."notaFiscal" := l_nota_fiscal;
    exception when others then
      ok:=false;
      print_log('  Erro:'||sqlerrm);
    end;
    
    if (ok and h > 0) then
      ok:= true;
    else
      print_log('  NF ou Informações da NF não encontrados !!!'); 
      ok:= false;
    end if;
    print_log('FIM XXFR_AR_PCK_INT_SINCRO_NF.MONTA_TYPE');
    print_log('');
    return l_publica;
  end monta_type;

end;
/
