CREATE OR REPLACE FORCE EDITIONABLE VIEW XXFR_WMS_VW_INT_CANC_SEPARACAO as
SELECT distinct
   d.id_integracao_cabecalho
  ,d.id_integracao_detalhe
  ,d.ie_status_processamento
  --
  ,json_value(d.ds_dados_requisicao, '$.idTransacao')    id_transacao
  ,json_value(d.ds_dados_requisicao, '$.versaoPayload')  vr_payload
  ,json_value(d.ds_dados_requisicao, '$.sistemaOrigem')  ds_sistema_origem
  ,json_value(d.ds_dados_requisicao, '$.codigoServico')  cd_servico
  ,json_value(d.ds_dados_requisicao, '$.usuario')        usuario
  --
  ,json_value(d.ds_dados_requisicao, '$.cancelarOrdemSeparacaoSemente.codigoUnidadeOperacional')        cd_unidade_operacional
  ,json_value(d.ds_dados_requisicao, '$.cancelarOrdemSeparacaoSemente.codigoReferenciaOrigem')          cd_referencia_origem
  ,json_value(d.ds_dados_requisicao, '$.cancelarOrdemSeparacaoSemente.tipoReferenciaOrigem')            tp_referencia_origem
  ,json_value(d.ds_dados_requisicao, '$.cancelarOrdemSeparacaoSemente.numeroOrdemSeparacao')            nu_ordem_separacao
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
where 1=1
  and c.cd_interface            = d.cd_interface_detalhe
  and c.id_integracao_cabecalho = d.id_integracao_cabecalho
  and d.cd_interface_detalhe    = 'CANCELAR_ORDEM_SEPARACAO_SEMENTE'
;
/

select * from XXFR_WMS_VW_INT_CANC_SEPARACAO;