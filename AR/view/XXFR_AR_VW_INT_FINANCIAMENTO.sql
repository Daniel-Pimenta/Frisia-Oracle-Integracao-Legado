DROP VIEW XXFR_AR_VW_INT_FINANCIAMENTO;
CREATE OR REPLACE VIEW "APPS"."XXFR_AR_VW_INT_FINANCIAMENTO" 
--("ID_INTEGRACAO_CABECALHO", "ID_INTEGRACAO_DETALHE", "CD_INTERFACE_DETALHE", "IE_STATUS_PROCESSAMENTO", "ID_TRANSACAO", "NR_VERSAO_PAYLOAD", "DS_SISTEMA_ORIGEM", "CD_CODIGO_SERVICO", "DS_USUARIO", "CD_UNIDADE_OPERACIONAL", "CD_TIPO_PROCESSO", "CD_CONTRATO", "CD_CLIENTE", "CD_ATIVIDADE", "CD_CULTURA", "CD_SAFRA", "CD_BANCO_LIBERACAO", "CD_AGENCIA_LIBERACAO", "CD_CONTA_LIBERACAO", "CD_BANCO_RECURSO", "CD_AGENCIA_RECURSO", "CD_CONTA_RECURSO", "DT_LIBERACAO", "VL_VALOR_LIBERACAO", "CD_USO_FINANCIAMENTO", "VL_FINAL_BLOQUEIO", "VL_BLOQUEIO_MAO_OBRA", "VL_RETENCAO", "CD_METODO_PAGAMENTO", "CD_CONDICAO_PAGAMENTO") 
AS 
select 
  d.id_integracao_cabecalho,
  d.id_integracao_detalhe,
  d.cd_interface_detalhe,
  d.ie_status_processamento,
  --h.*
  h.id_transacao,
  h.nr_versao_payload,
  h.ds_sistema_origem,
  h.cd_codigo_servico,
  h.ds_usuario,
  h.cd_unidade_operacional,
  --h.idx_financiamento,
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
  xxfr_fnc_convert_to_date(H.dt_liberacao)               dt_liberacao,
  fnd_number.canonical_to_number(H.vl_valor_liberacao)   vl_valor_liberacao,
  H.cd_uso_financiamento,
  fnd_number.canonical_to_number(H.vl_final_bloqueio)    vl_final_bloqueio,
  fnd_number.canonical_to_number(H.vl_bloqueio_mao_obra) vl_bloqueio_mao_obra,
  fnd_number.canonical_to_number(H.vl_retencao)          vl_retencao,
  H.cd_metodo_pagamento,
  H.cd_condicao_pagamento,
  H.cd_tipo_contrato, 
  H.cd_destinacao_recurso,
  --
  /*
  h.idx_taxa,
  H.cd_taxa, 
  fnd_number.canonical_to_number(vl_taxa)           vl_taxa, 
  --
  h.idx_parcelas,
  xxfr_fnc_convert_to_date(H.dt_parcela)            dt_parcela, 
  fnd_number.canonical_to_number(H.vl_parcela)      vl_parcela, 
  */
  --
  fnd_number.canonical_to_number(H.vl_juros)        vl_juros, 
  fnd_number.canonical_to_number(H.vl_longo_prazo)  vl_longo_prazo

from 
  xxfr_integracao_detalhe d,
  json_table(
    d.ds_dados_requisicao, '$' columns (
      id_transacao                VARCHAR2(50)  PATH '$.idTransacao',
      nr_versao_payload           VARCHAR2(50)  PATH '$.versaoPayload',
      ds_sistema_origem           VARCHAR2(50)  PATH '$.sistemaOrigem',
      cd_codigo_servico           VARCHAR2(50)  PATH '$.codigoServico',
      ds_usuario                  VARCHAR2(50)  PATH '$.usuario',
      nested path  '$.processarFinanciamento' columns (
        cd_unidade_operacional   VARCHAR2(50)  PATH '$.codigoUnidadeOperacional',
        nested path  '$.financiamento' columns (
          --idx_financiamento     FOR ORDINALITY,
          cd_tipo_processo      VARCHAR2(50)  PATH '$.tipoProcesso',
          cd_contrato           VARCHAR2(50)  PATH '$.codigoFinanciamento',
          cd_cliente            VARCHAR2(50)  PATH '$.codigoCliente',
          cd_atividade          VARCHAR2(50)  PATH '$.codigoAtividadeRural',
          cd_cultura            VARCHAR2(50)  PATH '$.codigoCultura',
          cd_safra              VARCHAR2(50)  PATH '$.codigoSafra',
          cd_banco_liberacao    VARCHAR2(50)  PATH '$.bancoContaLiberacao',
          cd_agencia_liberacao  VARCHAR2(50)  PATH '$.agenciaContaLiberacao',
          cd_conta_liberacao    VARCHAR2(50)  PATH '$.contaLiberacao',
          cd_banco_recurso      VARCHAR2(50)  PATH '$.bancoContaOrigemRecurso',
          cd_agencia_recurso    VARCHAR2(50)  PATH '$.agenciaContaOrigemRecurso',
          cd_conta_recurso      VARCHAR2(50)  PATH '$.contaOrigemRecurso',
          dt_liberacao          VARCHAR2(50)  PATH '$.dataLiberacao',
          vl_valor_liberacao    VARCHAR2(50)  PATH '$.valorLiberacao',
          cd_uso_financiamento  VARCHAR2(50)  PATH '$.usoFinanciamento',
          vl_final_bloqueio     VARCHAR2(50)  PATH '$.valorFinalidadeBloqueio',
          vl_bloqueio_mao_obra  VARCHAR2(50)  PATH '$.valorBloqueioMaoObra',
          vl_retencao           VARCHAR2(50)  PATH '$.valorRetencao',
          cd_metodo_pagamento   VARCHAR2(50)  PATH '$.codigoMetodoPagamentoMaoObra',
          cd_condicao_pagamento VARCHAR2(50)  PATH '$.codigoCondicaoPagamentoMaoObra',
          -- Incluido em 30/06/2020 - Daniel Pimenta
          cd_tipo_contrato      VARCHAR2(50)  PATH '$.codigoTipoContrato',
          cd_destinacao_recurso VARCHAR2(50)  PATH '$.codigoDestinacaoRecurso',
          --
          nested path  '$.taxas[*]' columns (
            idx_taxa            FOR ORDINALITY,
            cd_taxa             VARCHAR2(50)  PATH '$.codigo',
            vl_taxa             VARCHAR2(50)  PATH '$.valor'
          ),
          --
          nested path  '$.parcelas[*]' columns (
            idx_parcelas        FOR ORDINALITY,
            dt_parcela          VARCHAR2(50)  PATH '$.dataParcela',
            vl_parcela          VARCHAR2(50)  PATH '$.valorParcela'
          ),
          --
          vl_juros              VARCHAR2(50)  PATH '$.valorJuros',
          vl_longo_prazo        VARCHAR2(50)  PATH '$.valorLongoPrazo'
        )
      )
    )
  ) h
where 1=1
  and cd_interface_detalhe in ( 'PROCESSAR_FINANCIAMENTO' )
order by 1
;
/

--select * from xxfr_integracao_detalhe where ID_INTEGRACAO_DETALHE=25088;

--

select IDX_PARCELAS, DT_PARCELA, VL_PARCELA 
from XXFR_AR_VW_INT_FINANCIAMENTO
where ID_INTEGRACAO_DETALHE=-381;


select distinct ID_INTEGRACAO_DETALHE, IDX_TAXA, CD_TAXA, VL_TAXA, IDX_PARCELAS, DT_PARCELA, VL_PARCELA 
from XXFR_AR_VW_INT_FINANCIAMENTO
where ID_INTEGRACAO_DETALHE=-381
order by IDX_TAXA, idx_parcelas
;