CREATE OR REPLACE VIEW XXFR_INT_VW_RETORNO AS
SELECT DISTINCT 
  d.id_integracao_detalhe,
  d.CD_INTERFACE_DETALHE,
  d.DT_STATUS_PROCESSAMENTO dt_processamento,
  json_value(d.DS_DADOS_RETORNO, '$.idTransacao') id_transacao,
  json_value(d.DS_DADOS_RETORNO, '$.contexto')    contexto,
  json_value(d.DS_DADOS_RETORNO, '$.retornoProcessamento') ret_processamento,
  json_value(d.DS_DADOS_RETORNO, '$.mensagemRetornoProcessamento') msg_ret_processamento,
  l.*
from 
  xxfr_integracao_detalhe d,
  json_table(
    d.DS_DADOS_RETORNO, 
    '$.registros[*]' columns (
      idx_reg FOR ORDINALITY,
      tp_cabecalho          VARCHAR2(20)  PATH '$.tipoCabecalho',
      cd_cabecalho          VARCHAR2(20)  PATH '$.codigoCabecalho',
      tp_ref_origem         VARCHAR2(20)  PATH '$.tipoReferenciaOrigem',
      cd_ref_origem         VARCHAR2(20)  PATH '$.codigoReferenciaOrigem',
      retorno_processamento VARCHAR2(20)  PATH '$.retornoProcessamento',     
      nested path '$.mensagens[*]' columns (  
        idx_msg FOR ORDINALITY,
        tp_mensagem           VARCHAR2(50)  PATH '$.tipoMensagem',
        mensagem              VARCHAR2(300)  PATH '$.mensagem'
      ),
      nested path '$.linhas[*]' columns (  
        idx_lin FOR ORDINALITY,
        tp_linha              VARCHAR2(50)  PATH '$.tipoLinha',
        cd_linha              VARCHAR2(50)  PATH '$.codigoLinha',
        tp_ref_linha_origem   VARCHAR2(50)  PATH '$.tipoReferenciaLinhaOrigem',
        cd_ref_linha_origem   VARCHAR2(50)  PATH '$.codigoReferenciaLinhaOrigem',
        nested path '$.mensagens[*]' columns (
          idx_msg2 FOR ORDINALITY,
          tp_mensagem_linha   VARCHAR2(50)   PATH '$.tipoMensagem',
          mensagem_linha      VARCHAR2(300)  PATH '$.mensagem'
        )
      )
    ) 
  ) l
where 1=1
  --AND d.ID_INTEGRACAO_DETALHE = -372
  --AND D.CD_INTERFACE_DETALHE = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
;
/


select * from xxfr_integracao_detalhe;

SELECT * FROM XXFR_INT_VW_RETORNO
WHERE ID_INTEGRACAO_DETALHE = -376;


{
  "idTransacao": null,
  "contexto": "DEVOLUCAO_NF_FORNECEDOR",
  "retornoProcessamento": "ERRO",
  "mensagemRetornoProcessamento": "NF Devolução não gerada no AR",
  "registros": [
    {
      "tipoCabecalho": null,
      "codigoCabecalho": null,
      "tipoReferenciaOrigem": null,
      "codigoReferenciaOrigem": null,
      "retornoProcessamento": "ERRO",
      "mensagens": [
        {
          "tipoMensagem": "ERRO",
          "mensagem": "Informe uma Situação Tributária Federal válida para a linha de transação."
        }
      ],
      "linhas": [
        {
          "tipoLinha": null,
          "codigoLinha": null,
          "tipoReferenciaLinhaOrigem": null,
          "codigoReferenciaLinhaOrigem": null,
          "mensagens": [
            {
              "tipoMensagem": null,
              "mensagem": null
            }
          ]
        }
      ]
    }
  ]
}