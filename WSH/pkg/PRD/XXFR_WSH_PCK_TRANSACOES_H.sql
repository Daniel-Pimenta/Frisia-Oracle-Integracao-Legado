create or replace package xxfr_wsh_pck_transacoes as
 
  --DANIEL PIMENTA 25/09/2019
  -- 
  procedure criar_atualizar_percurso(
    p_trip_rec    in wsh_trips_pub.trip_pub_rec_type,
    p_action_code in varchar2,
    x_trip_id     out number,
    x_retorno     out varchar2
  );
  
  procedure split_linha_delivery(
    p_delivery_detail_id     in number, 
    p_quantidade             in number, 
    x_new_delivery_detail_id out number, 
    x_retorno                out varchar2
  );

  procedure criar_distribuicao_percurso(
    p_delivery_det_id_tbl   in  wsh_util_core.id_tab_type,
    x_trip_id               out number,
    x_delivery_id_rows_tbl  out wsh_util_core.id_tab_type,
    x_retorno               out varchar2
  );

  procedure criar_atualizar_entrega(
    p_delivery_rec_typ in   wsh_deliveries_pub.delivery_pub_rec_type,
    p_action_code      in  varchar2,
    x_delivery_id      out number,
    x_delivery_name    out varchar2,
    x_retorno          out varchar2
  );

  procedure associar_percurso_entrega(
    p_delivery_id  in number,
    p_trip_id      in number,
    x_retorno      out varchar2
  );
  
  procedure associar_linha_entrega(
    p_delivery_id         in number,
    p_delivery_detail_tab in wsh_delivery_details_pub.id_tab_type,
    p_action              in varchar2,
    x_retorno             out varchar2
  );
  
  procedure pick_release(
    p_delivery_id    in  number,
    p_trip_id        in  number,
    p_tipo_liberacao in  varchar2,
    x_msg_retorno    out varchar2,
    x_retorno        out varchar2
  );
   
  procedure confirma_entrega(
    p_delivery_id   in  number,
    p_action_code   in varchar2,
    x_retorno       out varchar2
  );
  
  procedure confirma_percurso(
    p_trip_id        in  number,
    p_action_param   in  WSH_TRIPS_PUB.Action_Param_Rectype,
    x_rec_retorno    out xxfr_pck_interface_integracao.rec_retorno_integracao,
    x_retorno        out varchar2
  );
  
  procedure atribuir_conteudo_firme(
    p_delivery_id in number ,
    p_action_code in varchar2,
    x_retorno     out varchar2
  );
  
  procedure criar_reserva(
    p_oe_header_id      in  number,
    p_oe_line_id        in  number,
    p_action            in  varchar2,
    p_qtd               in  number,
    p_subinventory_code in  varchar2,
    p_locator_id        in  number,
    p_lot_number        in  varchar2,
    x_retorno           out varchar2
  );
  
  procedure criar_mov_subinventario(
    p_move_order_line_id in  varchar2,
    p_line_number        in  varchar2,
    p_from_locator       in  varchar2,
    p_to_locator         in  varchar2,
    p_lot_number         in  varchar2,
    p_inventory_item_id  in  number,
    p_organization_id    in  number,
    --
    p_from_subinventory_code in varchar2,
    p_to_subinventory_code   in varchar2,
    --
    p_primary_quantity   in  number,
    p_trx_quantity       in  number,
    x_retorno            out varchar2
  );
  
  procedure atualiza_delivey_detail(
    p_changed_attributes  in WSH_DELIVERY_DETAILS_PUB.ChangedAttributeTabType,
    x_retorno             out varchar2
  );
  
end xxfr_wsh_pck_transacoes;