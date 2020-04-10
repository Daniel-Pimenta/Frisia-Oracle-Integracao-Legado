
                      -- CHECAGEM DA QUANTIDADE DA ORDEM
                      begin
                        select distinct delivery_detail_id, qtd, line_released_status_name
                        into   l_delivery_detail_id, l_qtd, l_line_released_status_name
                        from xxfr_wsh_vw_inf_da_ordem_venda
                        where 1=1
                          and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')  
                          and line_released_status_name not in ('Entregue')
                          -- 117/011_VENDA - 1
                          --and numero_ordem     = '39'
                          --and tipo_ordem       = '22L_VENDA'
                          --and linha            = '1'
                          and numero_ordem    = linhas.nu_ordem_venda
                          and tipo_ordem      = linhas.cd_tipo_ordem_venda
                          and linha           = linhas.nu_linha_ordem_venda
                          and envio           = nvl(linhas.nu_envio_linha_ordem_venda, envio)
                          --and delivery_id     is null
                          --and trip_id         is null      
                        ;
                        print_out('Dividir linha:'||a_portaria(i).entrega.fl_dividir_linha);
                        print_out('CHECANDO PEDIDO:(Delivery_Detail_ID/Qtd/Status)'||l_delivery_detail_id ||'/'|| l_qtd ||'/'|| l_line_released_status_name);
                        if (l_line_released_status_name = 'Staged/Pick Confirmed') then
                          ok := false;
                          print_out('  A LINHA DO PEDIDO ESTA AGUARDANDO A CONFIRMAÇÃO :'||l_line_released_status_name);
                          g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'ENTREGA-'||d||' LINHA-'||d;
                          g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := a_portaria(i).entrega.percurso.dist(d).id_distribuicao;
                          g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := null;
                          g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := null;
                          g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'ERRO';
                          g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."mensagem"     := 'A linha do pedido esta aguardando confirmação (EXECUTE CONFIRMACAO OU CANCELAMENTO)';
                        end if;
                        if (l_qtd = linhas.qt_quantidade) then
                          a_portaria(i).entrega.fl_dividir_linha := 'NAO';
                          --l_delivery_detail_id_tbl(l) := l_delivery_detail_id;
                        end if;
                      exception 
                        when others then
                          ok := false;
                          print_out('  ERRO CHECAGEM DA QTD DO PEDIDO :'||sqlerrm);
                          g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'ENTREGA-'||d||' LINHA-'||d;
                          g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := a_portaria(i).entrega.percurso.dist(d).id_distribuicao;
                          g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := null;
                          g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := null;
                          g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'ERRO';
                          g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."mensagem"     := 'Erro chegagem da Qtd do pedido :'||sqlerrm;
                      end;
                      --
                      if (ok) then
                        if (a_portaria(i).entrega.fl_Dividir_Linha = 'SIM') then
                          print_out('');
                          linhas.id_delivery_detail := l_delivery_detail_id;
                          print_out('CRIANDO SPLIT DE LINHA '||l);
                          print_out('Ordem      :'||linhas.nu_ordem_venda);
                          print_out('Tipo       :'||linhas.cd_tipo_ordem_venda);
                          print_out('Linha      :'||linhas.nu_linha_ordem_venda);
                          print_out('Envio      :'||linhas.nu_envio_linha_ordem_venda);
                          print_out('Delivery ID:'||linhas.id_delivery_detail);
                          if (not ok) then
                          begin                   
                            select distinct delivery_detail_id 
                            into linhas.id_delivery_detail
                            from 
                              (
                              select delivery_detail_id
                              from  
                                XXFR_WSH_VW_INF_DA_ORDEM_VENDA 
                              where 1=1
                                and flow_status_code not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
                                and delivery_id  is null
                                and numero_ordem = linhas.nu_ordem_venda 
                                and tipo_ordem   = linhas.cd_tipo_ordem_venda 
                                and linha        = linhas.nu_linha_ordem_venda
                                and envio        = nvl(linhas.nu_envio_linha_ordem_venda,envio)
                              union all
                              select delivery_detail_id
                              from  
                                XXFR_WSH_VW_INF_DA_ORDEM_VENDA 
                              where 1=1
                                and flow_status_code   not in ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
                                --and delivery_id        is null
                                and delivery_detail_id = linhas.id_delivery_detail
                              )
                            ;
                          exception
                            when no_data_found then
                              print_out('Linha da OE não encontrada.');
                              print_out('Ordem:'||linhas.nu_ordem_venda);
                              print_out('Tipo :'||linhas.cd_tipo_ordem_venda);
                              print_out('Linha:'||linhas.nu_linha_ordem_venda);
                              print_out('Envio:'||linhas.nu_envio_linha_ordem_venda);
                              --
                              g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'ENTREGA-'||d||' LINHA-'||d;
                              g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := a_portaria(i).entrega.percurso.dist(d).id_distribuicao;
                              g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := null;
                              g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                              g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'ERRO';
                              g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."mensagem"     := 'Linha não encontrada (DETALHE)';
                              ok := false;
                              exit;
                            when too_many_rows then
                              print_out('MAIS DE UMA LINHA ENCONTRADA (DETALHE)');
                              print_out('Ordem:'||linhas.nu_ordem_venda);
                              print_out('Linha:'||linhas.nu_linha_ordem_venda);
                              print_out('Envio:'||linhas.nu_envio_linha_ordem_venda);
                              --
                              g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'ENTREGA/LINHA';
                              g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := l_delivery_name;
                              g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := null;
                              g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                              g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."tipoMensagem" := 'ERRO';
                              g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(1)."mensagem"     := 'Mais de uma linha encontrada (DETALHE)';
                              ok := false;
                              exit;
                          end;
                          end if;
                          dividir_linha_entrega(
                            p_linhas                 => linhas, 
                            x_new_delivery_detail_id => l_new_delivery_detail_id,
                            x_retorno                => l_retorno
                          );
                          if (l_retorno = 'S') then
                            a_portaria(i).entrega.percurso.dist(d).linhas(l).id_delivery_detail := l_new_delivery_detail_id;
                            l_delivery_detail_id_tbl(l)       := l_new_delivery_detail_id;
                          else
                            ok := false;                  
                            g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'SPLIT LINHA';
                            g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := l_delivery_name;
                            g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := null;
                            g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                            g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(l)."tipoMensagem" := 'ERRO';
                            g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(l)."mensagem"     := l_retorno;
                            exit;
                          end if;
                        end if;
                        if (a_portaria(i).entrega.fl_Dividir_Linha = 'NAO') then
                          print_out('');
                          print_out('LINHA '||l||' - NÃO DIVIDIR, CONSUMIR TODO O CONTEUDO'); 
                          begin
                            select distinct delivery_detail_id 
                            into l_delivery_detail_id_tbl(l)
                            from xxfr_wsh_vw_inf_da_ordem_venda
                            where 1=1
                              and numero_ordem = linhas.nu_ordem_venda
                              and linha        = linhas.nu_linha_ordem_venda
                              and envio        = nvl(linhas.nu_envio_linha_ordem_venda, envio)
                              and tipo_ordem   = linhas.cd_tipo_ordem_venda
                              AND flow_status_code NOT IN ('CANCELLED','CLOSED','INVOICE_INCOMPLETE','SHIPPED')
                              --and delivery_id is not null
                            ;
                            print_out('DELIVERY DETAIL ID:'||l_delivery_detail_id_tbl(l)); 
                            a_portaria(i).entrega.percurso.dist(d).linhas(l).id_delivery_detail := l_delivery_detail_id_tbl(l);
                          exception 
                            when no_data_found then
                              ok := false;                  
                              l_retorno := 'Não foi encontrada a linha principal';
                              print_out(l_retorno);
                              g_rec_retorno."registros"(1)."linhas"(d)."tipoLinha"                   := 'LINHA PRINIPAL';
                              g_rec_retorno."registros"(1)."linhas"(d)."codigoLinha"                 := l_delivery_name;
                              g_rec_retorno."registros"(1)."linhas"(d)."tipoReferenciaLinhaOrigem"   := null;
                              g_rec_retorno."registros"(1)."linhas"(d)."codigoReferenciaLinhaOrigem" := g_cd_referencia_origem;
                              g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(l)."tipoMensagem" := 'ERRO';
                              g_rec_retorno."registros"(1)."linhas"(d)."mensagens"(l)."mensagem"     := l_retorno;
                              exit;
                          end;
                        end if;
                      end if;
