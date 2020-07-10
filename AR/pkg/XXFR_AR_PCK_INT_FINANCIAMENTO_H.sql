create or replace PACKAGE "XXFR_AR_PCK_INT_FINANCIAMENTO" as
    
    type tp_cabecalho is record
        ( tipo_cabecalho           varchar2(50)
        , numero_contrato          varchar2(50)
        , numero_processo          varchar2(50)
        , status_processamento     varchar2(50)
        , tipo_referencia          varchar2(50)
        , codigo_referencia        varchar2(50) );

    type tp_cabecalho_tbl is table of tp_cabecalho index by binary_integer; 
    --
    cursor cur_header(p_id_integracao_detalhe in number) is
    select distinct      
      ID_INTEGRACAO_CABECALHO, ID_INTEGRACAO_DETALHE, CD_INTERFACE_DETALHE, IE_STATUS_PROCESSAMENTO, 
      ID_TRANSACAO, NR_VERSAO_PAYLOAD, DS_SISTEMA_ORIGEM, CD_CODIGO_SERVICO, DS_USUARIO,
      CD_UNIDADE_OPERACIONAL, CD_TIPO_PROCESSO, CD_CONTRATO, CD_CLIENTE, CD_ATIVIDADE, 
      CD_CULTURA, CD_SAFRA, CD_BANCO_LIBERACAO, CD_AGENCIA_LIBERACAO, CD_CONTA_LIBERACAO, 
      CD_BANCO_RECURSO, CD_AGENCIA_RECURSO, CD_CONTA_RECURSO, DT_LIBERACAO, VL_VALOR_LIBERACAO, 
      CD_USO_FINANCIAMENTO, VL_FINAL_BLOQUEIO, VL_BLOQUEIO_MAO_OBRA, VL_RETENCAO, 
      CD_METODO_PAGAMENTO, 
      CD_CONDICAO_PAGAMENTO, 
      CD_TIPO_CONTRATO, 
      CD_DESTINACAO_RECURSO, 
      VL_JUROS, 
      VL_LONGO_PRAZO
      /*
      h.id_integracao_cabecalho,
      h.id_integracao_detalhe,
      h.cd_interface_detalhe,
      h.ie_status_processamento,
      h.id_transacao,
      h.cd_unidade_operacional,
      h.cd_tipo_processo,
      h.cd_contrato, 
      h.cd_cliente,
      h.cd_atividade,
      h.cd_cultura,
      h.cd_safra,
      h.cd_banco_liberacao,
      h.cd_agencia_liberacao,
      h.cd_conta_liberacao,
      h.cd_banco_recurso,
      h.cd_agencia_recurso,
      h.cd_conta_recurso,
      h.dt_liberacao,
      h.vl_valor_liberacao,
      h.cd_uso_financiamento,
      h.vl_final_bloqueio,
      h.vl_bloqueio_mao_obra,
      h.vl_retencao,
      h.cd_metodo_pagamento,
      h.cd_condicao_pagamento
      */
    from xxfr_ar_vw_int_financiamento h
    where id_integracao_detalhe = p_id_integracao_detalhe;
    --
    
    cursor cur_cancela(p_id_integracao_detalhe in number) is
    select h.id_integracao_cabecalho,
            h.id_integracao_detalhe,
            h.cd_interface_detalhe,
            h.ie_status_processamento,
            h.id_transacao,
            h.nr_versao_payload,
            h.ds_sistema_origem,
            h.cd_codigo_servico,
            h.ds_usuario,
            h.cd_unidade_operacional,
            h.nr_processo,
            h.cd_contrato
    from xxfr_ar_vw_int_financ_cancela h
    where id_integracao_detalhe = p_id_integracao_detalhe;

    procedure print_log(msg in varchar2);

    procedure PROCESSAR_LIBERA_FINANCIAMENTO ( p_id_integracao_detalhe   in   number
                                             , p_retorno                 out  clob);

    procedure CANCELAR_FINANCIAMENTO ( p_id_integracao_detalhe   in   number
                                     , p_retorno                 out  clob);
end;

