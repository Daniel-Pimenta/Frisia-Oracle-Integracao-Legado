CREATE OR REPLACE FORCE EDITIONABLE VIEW XXFR_GL_VW_INT_LOTECONTABIL as
SELECT                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  -- Portaria
   d.id_integracao_cabecalho
  ,d.id_integracao_detalhe
  ,d.ie_status_processamento
  --
  ,json_value(d.ds_dados_requisicao, '$.idTransacao')    id_transacao
  ,json_value(d.ds_dados_requisicao, '$.versaoPayload')  vr_payload
  ,json_value(d.ds_dados_requisicao, '$.sistemaOrigem')  sistema_origem
  ,json_value(d.ds_dados_requisicao, '$.codigoServico')  cd_servico
  ,json_value(d.ds_dados_requisicao, '$.usuario')        usuario
  -- processarContabilizacao
  ,json_value(d.ds_dados_requisicao, '$.processarContabilizacao.livroContabil')       livro_contabil
  ,json_value(d.ds_dados_requisicao, '$.processarContabilizacao.dataCriacao')         data_criacao
  ,json_value(d.ds_dados_requisicao, '$.processarContabilizacao.dataContabil')        data_contabil
  ,json_value(d.ds_dados_requisicao, '$.processarContabilizacao.moeda')               moeda
  ,json_value(d.ds_dados_requisicao, '$.processarContabilizacao.categoriaLancamento') categoria_lancamento
  ,json_value(d.ds_dados_requisicao, '$.processarContabilizacao.origemLancamento')    origem_lancamento
  ,json_value(d.ds_dados_requisicao, '$.processarContabilizacao.descricao')           descricao                                       
  --
  ,movimento.tipo_referencia_origem
  ,movimento.codigo_referencia_origem
  ,movimento.tipo_transacao
  ,fnd_number.canonical_to_number(movimento.valor) valor
  --,to_number(replace(movimento.valor,'.',',')) valor
  ,movimento.chave_contabil
  ,substr(movimento.chave_contabil,1 ,2) segment1
  ,substr(movimento.chave_contabil,4 ,4) segment2
  ,substr(movimento.chave_contabil,9 ,9) segment3
  ,substr(movimento.chave_contabil,19,4) segment4
  ,substr(movimento.chave_contabil,24,2) segment5
  ,substr(movimento.chave_contabil,27,3) segment6
  ,substr(movimento.chave_contabil,31,1) segment7
  ,substr(movimento.chave_contabil,33,1) segment8
  ,substr(movimento.chave_contabil,35,1) segment9
  ,movimento.descricao_lancamento 
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
  --
  ,json_table(
    d.ds_dados_requisicao, 
    '$.processarContabilizacao.movimentosContabeis[*]' columns (
        tipo_referencia_origem   VARCHAR2(20)  PATH '$.tipoReferenciaOrigem',
        codigo_referencia_origem VARCHAR2(20)  PATH '$.codigoReferenciaOrigem',
        tipo_transacao           VARCHAR2(20)  PATH '$.tipoTrasacao',
        chave_contabil           VARCHAR2(100) PATH '$.chaveContabil',
        valor                    VARCHAR2(20)  PATH '$.valor',
        descricao_lancamento     VARCHAR2(100) PATH '$.descricao'
    )
  ) movimento
where 1=1
  and c.CD_INTERFACE            = d.CD_INTERFACE_DETALHE
  and c.ID_INTEGRACAO_CABECALHO = d.ID_INTEGRACAO_CABECALHO
  and cd_interface_detalhe      = 'PROCESSAR_CONTABILIZACAO'
;
/


--
select * from XXFR_GL_VW_INT_LOTECONTABIL
order by 2 desc;

