create or replace force editionable view xxfr_ri_vw_int_proc_devolucao2 as
select 
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
  ,json_value(d.ds_dados_requisicao, '$.processarNotaFiscalDevolucao.codigoUnidadeOperacional') cd_unidade_operacional
  ,json_value(d.ds_dados_requisicao, '$.processarNotaFiscalDevolucao.aprovaRequisicao')         ie_aprova_requisicao
  ,linha.*
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
  ,json_table( d.ds_dados_requisicao, '$.processarNotaFiscalDevolucao.notaFiscalDevolucao[*]' columns (
    cd_chave_acesso           varchar2(50)  path '$.codigoChaveAcesso',
    tp_referencia_origem      varchar2(50)  path '$.tipoReferenciaOrigem',
    cd_referencia_origem      varchar2(50)  path '$.codigoReferenciaOrigem',
    nested path '$.linha[*]' columns ( 
      nu_linha_nota_fiscal          varchar2(20)  path '$.numero',
      qt_quantidade                 number        path '$.quantidade',
      cd_unidade_medida             varchar2(10)  path '$.unidadeMedida'
    )
  )) linha
where 1=1
  and c.cd_interface            = d.cd_interface_detalhe
  and c.id_integracao_cabecalho = d.id_integracao_cabecalho
  and d.cd_interface_detalhe    = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
;
/

--
select * from XXFR_RI_VW_INT_PROC_DEVOLUCAO2 where ID_INTEGRACAO_detalhe = -318;
--
select * from xxfr_integracao_detalhe 
where 1=1
  and CD_INTERFACE_DETALHE = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
  --and ID_INTEGRACAO_detalhe=-168
order by DT_CRIACAO desc
;
