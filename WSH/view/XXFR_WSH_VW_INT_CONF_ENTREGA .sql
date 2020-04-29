CREATE OR REPLACE FORCE EDITIONABLE VIEW XXFR_WSH_VW_INT_CONF_ENTREGA as
SELECT 
  -- Portaria
   d.id_integracao_cabecalho
  ,d.id_integracao_detalhe
  ,d.ie_status_processamento
  ,json_value(d.ds_dados_requisicao, '$.idTransacao')   id_transacao
  ,json_value(d.ds_dados_requisicao, '$.versaoPayload') nu_vr_payload
  ,json_value(d.ds_dados_requisicao, '$.sistemaOrigem') ds_sistema_origem
  ,json_value(d.ds_dados_requisicao, '$.codigoServico') cd_servico
  ,json_value(d.ds_dados_requisicao, '$.usuario')       usuario
  ,json_value(d.ds_dados_requisicao, '$.confirmarEntrega.idSoaComposite')           id_soa_composite
  ,json_value(d.ds_dados_requisicao, '$.confirmarEntrega.nmSoaComposite')           nu_soa_composite
  ,json_value(d.ds_dados_requisicao, '$.confirmarEntrega.codigoUnidadeOperacional') cd_unidade_operacional
  ,json_value(d.ds_dados_requisicao, '$.confirmarEntrega.codigoReferenciaOrigem')   cd_referencia_origem
  ,json_value(d.ds_dados_requisicao, '$.confirmarEntrega.tipoReferenciaOrigem')     tp_referencia_origem
  ,json_value(d.ds_dados_requisicao, '$.confirmarEntrega.nomePercurso')             nm_percurso
  ,json_value(d.ds_dados_requisicao, '$.confirmarEntrega.recalcularPreco')          ie_recalcula_preco
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
where 1=1
  and c.CD_INTERFACE            = d.CD_INTERFACE_DETALHE
  and c.ID_INTEGRACAO_CABECALHO = d.ID_INTEGRACAO_CABECALHO
  and cd_interface_detalhe      = 'CONFIRMAR_ENTREGA'
;
/


--
/*
SELECT * FROM XXFR_WSH_VW_INT_CONF_ENTREGA ;

select * from xxfr_integracao_detalhe ;

*/
