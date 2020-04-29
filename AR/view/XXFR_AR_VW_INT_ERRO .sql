CREATE OR REPLACE FORCE EDITIONABLE VIEW XXFR_AR_VW_INT_ERRO as
select 
  d.id_transacao
  ,d.dt_criacao
  ,d.nm_usuario_criacao
  ,d.ie_status_processamento
  ,json_value(d.ds_dados_retorno, '$.status')                status
  ,json_value(d.ds_dados_retorno, '$.statusCode')            cd_status 
  ,json_value(d.ds_dados_retorno, '$.reasonPhrase')          tx_reason_phrase
  ,json_value(d.ds_dados_retorno, '$.idIntegracaoCabecalho') id_integracao_cabecalho
  ,json_value(d.ds_dados_retorno, '$.mensagem')              tx_mensagem
  ,json_value(d.ds_dados_retorno, '$.idIntegracaoDetalhe')   id_integracao_detalhe
  ,json_value(d.ds_dados_retorno, '$.payloadResponse')       tx_payload_response
  ,msg.*
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
  ,json_table(
    d.ds_dados_retorno, 
    '$.Mensagens[*]' columns (
      tp_tipo               VARCHAR2(20)  PATH '$.Tipo',
      tx_mensagens          VARCHAR2(300) PATH '$.Mensagem'
    )
  ) msg
where 1=1
  and c.cd_interface            = d.cd_interface_detalhe
  and c.id_integracao_cabecalho = d.id_integracao_cabecalho
  and cd_interface_detalhe      = 'SINCRONIZAR_NOTA_FISCAL'
  --and d.id_integracao_detalhe = 11354
;
/



--
/*

SELECT * 
FROM XXFR_AR_VW_INT_ERRO 
WHERE 1=1
  and id_integracao_detalhe = 11354
ORDER BY 2 DESC;

SELECT * FROM xxfr_integracao_detalhe;

*/
