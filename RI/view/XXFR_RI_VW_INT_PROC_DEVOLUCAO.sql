drop view xxfr_ri_vw_int_proc_devolucao;
create or replace force editionable view xxfr_ri_vw_int_proc_devolucao as
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
  ,linhas.*
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
  ,json_table( d.ds_dados_requisicao, '$.processarNotaFiscalDevolucao.notaFiscalDevolucao[*]' columns (
    cd_tipo_recebimento       varchar2(50)  path '$.codigoTipoRecebimento',
    cd_fornecedor             varchar2(50)  path '$.codigoFornecedor',
    nu_propriedade_fornecedor varchar2(50)  path '$.numeroPropriedadeFornecedor',
    tp_referencia_origem      varchar2(50)  path '$.tipoReferenciaOrigem',
    cd_referencia_origem      varchar2(50)  path '$.codigoReferenciaOrigem',
    nested path '$.linhas[*]' columns ( 
      cd_referencia_origem_linha    varchar2(20)  path '$.codigoReferenciaOrigemLinha',
      tp_referencia_origem_linha    varchar2(40)  path '$.tipoReferenciaOrigemLinha',
      nu_linha_devolucao            varchar2(20)  path '$.numeroLinhaDevolucao',
      nu_cnpj_emissor               varchar2(20)  path '$.cnpjEmissor',
      nu_nota_fiscal                varchar2(20)  path '$.numeroNotaFiscal',
      cd_serie                      varchar2(3)   path '$.codigoSerie',
      nu_linha_nota_fiscal          varchar2(20)  path '$.numeroLinhaNotaFiscal',
      qt_quantidade                 number        path '$.quantidade',
      cd_unidade_medida             varchar2(10)  path '$.unidadeMedida'
    )
  )) linhas
where 1=1
  and c.cd_interface            = d.cd_interface_detalhe
  and c.id_integracao_cabecalho = d.id_integracao_cabecalho
  and d.cd_interface_detalhe    = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
;
/

select * from xxfr_integracao_detalhe 
where 1=1
  and cd_interface_detalhe = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
  and NM_USUARIO_ATUALIZACAO = 'APPS'
;
--
select * from XXFR_RI_VW_INT_PROC_DEVOLUCAO where ID_INTEGRACAO_detalhe = 2520;
--
select * from xxfr_integracao_detalhe 
where 1=1
  and CD_INTERFACE_DETALHE = 'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR'
  --and ID_INTEGRACAO_detalhe=-168
order by DT_CRIACAO desc
;
