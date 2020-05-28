create or replace package xxfr_wsh_pck_int_entrega is
-- +==========================================================================+
-- | Package para criar e manter itens do OM para integrações e processos custom.     
-- |                                                                 
-- |                                                                 
-- | CRIADO POR              DATA                  REF                                          
-- |   DANIEL PIMENTA      25/10/2019            Ticket#10108885    
-- |                                                                 
-- | ALTERADO POR            DATA                  REF                        
-- |   [Nome]                [dd/mm/yyyy]          [ticket#]     
-- |      [comentários sobre a alteração]         
-- |                                  
-- +==========================================================================+

  type tp_linhas is record (  
    cd_tipo_ordem_venda     varchar2(50),
    nu_ordem_venda          number,
    nu_linha_ordem_venda    number,
    nu_envio_linha_ordem_venda varchar2(20),
    delivery_detail_id      number,
    qt_quantidade           number,
    cd_un_medida            varchar2(10),
    qt_volumes              number,
    cd_un_volume            varchar2(10),
    cd_endereco_estoque     varchar2(20),
    ds_observacoes          varchar2(400),
    pr_percentual_gordura   varchar2(20)
  );
  type array_linhas is varray(10) of tp_linhas;
  --a_linhas array_linhas;

  type tp_veiculo is record (
    cd_reg_antt         varchar2(50),
    cd_reg_antt_cavalo  varchar2(50),
    nu_placa1           varchar2(20),
    nu_placa2           varchar2(20),
    nu_placa3           varchar2(20),
    nu_placa4           varchar2(20),
    nu_placa5           varchar2(20)
  );
  
  type tp_dist is record (
    id_distribuicao               number,
    nm_distribuicao               varchar2(20),
    cd_cliente                    varchar2(50),
    cd_ship_to                    varchar2(50),
    vl_valor_frete                number,
    cd_moeda                      varchar2(50),
    cd_controle_entrega_cliente   varchar2(50),
    cd_lacres                     varchar2(400),
    ds_dados_adicionais           varchar2(400),
    linhas                        array_linhas
  );
  type array_dist is varray(10) of tp_dist;
  --a_dist array_dist;
  
  type tp_transp  is record (
    cd_transportador       varchar2(20),
    nm_transportador       varchar2(50),
    nu_cnpj_transportador  varchar2(20),
    ds_logradouro          varchar2(50),
    ds_municipio           varchar2(20),
    ds_estado              varchar2(20),
    nm_motorista           varchar2(50),
    nu_cpf_motorista       varchar2(20)
  );
  type array_transp is varray(10) of tp_transp;
  --a_transp array_transp;
  
  type tp_percurso is record (
    tp_operacao                varchar2(20),
    id_percurso                varchar2(20),
    nm_percurso                varchar2(20),
    cd_referencia_origem       varchar2(50),
    tp_referencia_origem       varchar2(50),
    ie_ajusta_distribuicao     varchar2(20),
    cd_lacre_veiculo           varchar2(100),
    qt_peso_tara               number,
    qt_peso_bruto              number,
    qt_peso_embalagem_complementar number,
    tp_frete                   varchar2(20),
    cd_metodo_entrega          varchar2(50),
    cd_endereco_estoque_granel varchar2(50),
    tp_liberacao               varchar2(30),
    --
    transp                     tp_transp,
    veiculo                    tp_veiculo,
    dist                       array_dist
  );
  type array_percurso is varray(10) of tp_percurso;
  --a_percurso array_percurso;
  
  type tp_entrega is record (  
    cd_unidade_operacional   varchar2(50),
    ie_dividir_linha         varchar2(3),
    ie_conteudo_firme        varchar2(3),
    ie_liberar_separacao     varchar2(3),
    percurso                 tp_percurso
  );
  type array_entrega is varray(10) of tp_entrega;
  --a_entrega array_entrega;
  
  type tp_portaria is record(
    idintegracaocabecalho  varchar2(20),
    iestatusintegracao     varchar2(20),
    idintegracaodetalhe    varchar2(20),
    cdinterfacedetalhe     varchar2(50),
    iestatusprocessamento  varchar2(20),
    entrega                tp_entrega
  );
  type array_portaria is varray(10) of tp_portaria;
  --
  
  type tp_confirma_cancela is record(
    idsoacomposite           varchar2(20),
    nmsoacomposite           varchar2(20),
    versaopayload            varchar2(20),
    codigounidadeoperacional varchar2(20),
    sistemaorigem            varchar2(100),
    nm_percurso              varchar2(20)
  );
  
  procedure print_out(msg varchar2);

  procedure carrega_dados(
		p_id_integracao_detalhe in  number,
		p_portaria              out array_portaria,
    p_retorno               out varchar2
  );
  --
  procedure processar_entrega(
    p_id_integracao_detalhe IN  NUMBER,
    p_commit                IN  boolean,
    p_retorno               out clob
  );
  procedure confirmar_entrega(
    p_id_integracao_detalhe IN  NUMBER,
    p_commit                IN  boolean,
    p_retorno               out clob
  );
  procedure cancelar_entrega(
    p_id_integracao_detalhe IN  NUMBER,
    p_commit                IN  boolean,
    p_retorno               out clob
  );
  --
  procedure processar_entrega(
    p_id_integracao_detalhe in  number,
    p_retorno               out clob
  );
  procedure confirmar_entrega(
    p_id_integracao_detalhe in  number,
    p_retorno               out clob
  );
  procedure cancelar_entrega (
    p_id_integracao_detalhe in  number,
    p_retorno               out clob
  );
  procedure cancelar_entrega(
    p_trip_id in  NUMBER,
    p_commit  in  boolean,
    x_retorno out varchar2
  );
  --
  procedure dividir_linha_entrega(
    p_linhas                  in tp_linhas,
    x_new_delivery_detail_id  out number, 
		x_retorno                 out varchar2
  );
  procedure criar_atualizar_percurso(
		p_percurso                in  tp_percurso,
    p_trip_id                 in  number,
    p_action_code             in  varchar2,
    x_trip_id                 out number,
		x_retorno                 out varchar2 
  );
  procedure criar_atualizar_entrega(
    p_percurso                in  tp_percurso,
    p_dist                    in  tp_dist,
    p_delivery_id             in  number,
    p_action_code             in  varchar2,
    x_delivery_id             out number,
    x_delivery_name           out varchar2,
		x_retorno                 out varchar2
  );
  procedure associar_entrega_percurso(
    p_delivery_id_tbl  in wsh_util_core.id_tab_type,
    p_trip_id          in number,
    x_retorno          out varchar2
  );
  procedure associar_linha_entrega(
    p_delivery_id         in number,
    p_delivery_name       in varchar2,
    p_delivery_detail_tab in wsh_delivery_details_pub.id_tab_type,
    x_delivery_id         out number,
    x_retorno             out varchar2
  );
    
  procedure proc_delivery_pick_release(
    p_delivery_id    in number,
    p_trip_id        in number,
    p_r              in number,
    p_tipo_liberacao in varchar2,
    x_msg_retorno    out varchar2,
    x_retorno        out varchar2
  );
  procedure proc_trip_pick_release(
    p_trip_id        in number,
    p_action         in varchar2,
    x_msg_retorno    out varchar2,
    x_retorno        out varchar2
  );
  procedure processar_om_backorder(
    p_delivery_id             in number,
    p_trip_id                 in number,
    x_retorno                 out varchar2
  );
  procedure processar_trip_confirm(
    p_trip_id        in number ,
    p_action_code    in varchar2,
    x_retorno        out varchar2
  );
  procedure criar_reserva(
    p_linhas                 IN tp_linhas,
    p_operacao               IN varchar2,
    x_lot_number             out varchar2,
    x_retorno                out varchar2
  );

  procedure processar_conteudo_firme(
    p_delivery_id in number ,
    p_action_code in varchar2,
    x_retorno     out varchar2
  );
  procedure processar_percurso_firme (
    p_trip_id     in number,
    p_action_code in varchar2,
    x_retorno     out varchar2
  );
  
  procedure controle_split(
    p_linha                   in xxfr_wsh_pck_int_entrega.tp_linhas,
    x_retorno                 out varchar2
  );

  procedure reverter_mov_inventario(
    p_delivery_id             in number,
    x_retorno                 out varchar2
  );
  procedure criar_mov_subinventario(
    p_trip_id               in number,
    p_cd_endereco_estoque   in varchar2,
    p_qtd                   in number,
    x_retorno               out varchar2
  );

  function check_hold(
    p_delivery_id in number
    --
  ) return number;  
  function informacoes_lote(
    p_organization_id     in number,
    p_inventory_item_id   in number,
    p_cd_endereco_estoque in varchar2
  ) return varchar2;
  
end xxfr_wsh_pck_int_entrega;