CREATE OR REPLACE FORCE EDITIONABLE VIEW XXFR_WSH_VW_INT_CANC_ENTREGA as
SELECT 
  -- Portaria
   d.id_integracao_cabecalho
  ,d.id_integracao_detalhe
  ,d.IE_STATUS_PROCESSAMENTO
  ,null tp_referencia_origem
  ,null cd_referencia_origem
  ,json_value(d.ds_dados_requisicao, '$.idTransacao')     id_transacao
  ,json_value(d.ds_dados_requisicao, '$.versaoPayload')   nu_vr_payload 
  ,json_value(d.ds_dados_requisicao, '$.sistemaOrigem')   ds_sistema_origem
  ,json_value(d.ds_dados_requisicao, '$.codigoServico')   cd_sistema_origem
  ,json_value(d.ds_dados_requisicao, '$.usuario')         usuario
  ,json_value(d.ds_dados_requisicao, '$.cancelarEntrega.codigoUnidadeOperacional') cd_unidade_operacional
  ,json_value(d.ds_dados_requisicao, '$.cancelarEntrega.nomePercurso')             nm_percurso
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
where 1=1
  and c.cd_interface            = d.cd_interface_detalhe
  and c.id_integracao_cabecalho = d.id_integracao_cabecalho
  and cd_interface_detalhe      = 'CANCELAR_ENTREGA'
;
/
--
/*

SELECT * FROM XXFR_WSH_VW_INT_CANC_ENTREGA;

select * from xxfr_integracao_detalhe where  cd_interface_detalhe      = 'CANCELAR_ENTREGA';

*/
