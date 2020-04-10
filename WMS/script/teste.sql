  procedure carrega_dados(
		p_id_integracao_detalhe IN  NUMBER,
    x_retorno               OUT varchar2
  ) IS
  
    cursor c1 is 
      select id_integracao_cabecalho, id_integracao_detalhe, ie_status_processamento, id_transacao, vr_payload, ds_sistema_origem, cd_servico, usuario, cd_unidade_operacional, cd_referencia_origem, tp_referencia_origem, cd_organizacao_inventario, destino_ordem_separacao, end_estoque_dest_separacao 
      from xxfr_wms_vw_int_proc_separacao 
      where id_integracao_detalhe = p_id_integracao_detalhe
    ;

    cursor c2 is 
      select id_integracao_cabecalho, id_integracao_detalhe, cd_referencia_origem_linha, tp_referencia_origem_linha, nu_ordem_venda, cd_tipo_ordem_venda, nu_ordem_venda_linha, tp_separacao, cd_item, vl_area_separacao, qt_separacao, vl_plantas_m2, vl_area_disp_prog_insumos, gr_area_separacao
      from xxfr_wms_vw_int_proc_separacao 
      where id_integracao_detalhe = p_id_integracao_detalhe
    ;
    
    i         number;
    p         number;
    l_linhas  array_linhas;
    
  BEGIN
    print_log('XXFR_WMS_PCK_INT_SEPARACAO.CARREGA_DADOS');
    for r1 in c1 loop
    
      print_log('{');
      print_log('  Cod Org Inventario  :'||r1.cd_organizacao_inventario);
      print_log('  Cod Unid Operacional:'||r1.cd_unidade_operacional);
      g_proc_separacao.cd_unidade_operacional := r1.cd_unidade_operacional;
      --
      g_proc_separacao.ordemSeparacao.cd_referencia_origem      := r1.cd_referencia_origem;
      g_proc_separacao.ordemSeparacao.tp_referencia_origem      := r1.tp_referencia_origem;
      g_proc_separacao.ordemSeparacao.cd_organizacao_inventario := r1.cd_organizacao_inventario;
      g_proc_separacao.ordemSeparacao.destino_ordem_separacao   := r1.destino_ordem_separacao;
      g_proc_separacao.ordemSeparacao.end_estoque_dest_separacao:= r1.end_estoque_dest_separacao;
      --
      l_linhas := array_linhas();
      --
      i:=0;
      for r2 in c2 loop
        begin
          i:=i+1;
          print_log('  {');
          print_log('     Ordem Venda:'||r2.nu_ordem_venda);
          print_log('     Tipo Venda :'||r2.cd_tipo_ordem_venda);
          print_log('     Linha Venda:'||r2.nu_ordem_venda_linha);
          --
          p:=0;
          l_linhas.extend;
          p:=p+1; l_linhas(i).cd_referencia_origem_linha := r2.cd_referencia_origem_linha;
          p:=p+1; l_linhas(i).tp_referencia_origem_linha := r2.tp_referencia_origem_linha;
          p:=p+1; l_linhas(i).nu_ordem_venda             := r2.nu_ordem_venda;
          p:=p+1; l_linhas(i).cd_tipo_ordem_venda        := r2.cd_tipo_ordem_venda;
          p:=p+1; l_linhas(i).nu_ordem_venda_linha       := r2.nu_ordem_venda_linha;
          p:=p+1; l_linhas(i).tp_separacao               := r2.tp_separacao; --AREA/QUANTIDADE
          p:=p+1; l_linhas(i).cd_item                    := r2.cd_item;
          p:=p+1; l_linhas(i).vl_area_separacao          := r2.vl_area_separacao;
          p:=p+1; l_linhas(i).qt_separacao               := r2.qt_separacao;
          p:=p+1; l_linhas(i).vl_plantas_m2              := r2.vl_plantas_m2;
          p:=p+1; l_linhas(i).vl_area_disp_prog_insumos  := r2.vl_area_disp_prog_insumos;
          p:=p+1; l_linhas(i).gr_area_separacao          := r2.gr_area_separacao;
          print_log('  }');
        exception when others then 
          print_log('  ERR Item:('||p||') - '||sqlerrm);
          x_retorno := sqlerrm;
          ok:=false;
        end;
      end loop;
      print_log('}');
      g_proc_separacao.ordemSeparacao.linhas := l_linhas;
    end loop;
    print_log('FIM XXFR_WMS_PCK_INT_SEPARACAO.CARREGA_DADOS');
    x_retorno := 'S';
    ok:=true;
  EXCEPTION WHEN OTHERS THEN
    ok := false;
    x_retorno := 'Erro não previsto :'||sqlerrm;
    print_log('  '||x_retorno);
    print_log('FIM XXFR_WMS_PCK_INT_SEPARACAO.CARREGA_DADOS');
  END;