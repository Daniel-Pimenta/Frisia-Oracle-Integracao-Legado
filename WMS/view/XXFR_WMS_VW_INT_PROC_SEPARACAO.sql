CREATE OR REPLACE FORCE EDITIONABLE VIEW XXFR_WMS_VW_INT_PROC_SEPARACAO as
SELECT distinct
  -- Portaria
   d.id_integracao_cabecalho
  ,d.id_integracao_detalhe
  ,d.ie_status_processamento
  --
  ,json_value(d.ds_dados_requisicao, '$.idTransacao')    id_transacao
  ,json_value(d.ds_dados_requisicao, '$.versaoPayload')  vr_payload
  ,json_value(d.ds_dados_requisicao, '$.sistemaOrigem')  ds_sistema_origem
  ,json_value(d.ds_dados_requisicao, '$.codigoServico')  cd_servico
  ,json_value(d.ds_dados_requisicao, '$.usuario')        usuario

  ,json_value(d.ds_dados_requisicao, '$.processarOrdemSeparacao.codigoUnidadeOperacional')                       cd_unidade_operacional

  ,json_value(d.ds_dados_requisicao, '$.processarOrdemSeparacao.ordemSeparacao.codigoReferenciaOrigem')          cd_referencia_origem
  ,json_value(d.ds_dados_requisicao, '$.processarOrdemSeparacao.ordemSeparacao.tipoReferenciaOrigem')            tp_referencia_origem
  ,json_value(d.ds_dados_requisicao, '$.processarOrdemSeparacao.ordemSeparacao.codigoOrganizacaoInventario')     cd_organizacao_inventario
  ,json_value(d.ds_dados_requisicao, '$.processarOrdemSeparacao.ordemSeparacao.destinoOrdemSeparacao')           destino_ordem_separacao
  ,json_value(d.ds_dados_requisicao, '$.processarOrdemSeparacao.ordemSeparacao.enderecoEstoqueDestinoSeparacao') end_estoque_dest_separacao
  --
  ,linhas.*
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
  ,(
    select d1.id_integracao_cabecalho as id_cab, linhas.* 
    from 
      xxfr_integracao_detalhe d1
      ,json_table (
        d1.ds_dados_requisicao,'$.processarOrdemSeparacao.ordemSeparacao.linhas[*]' columns (
          cd_referencia_origem_linha VARCHAR2(20)  PATH '$.codigoReferenciaOrigemLinha',
          tp_referencia_origem_linha VARCHAR2(50)  PATH '$.tipoReferenciaOrigemLinha',
          nu_ordem_venda             VARCHAR2(20)  PATH '$.numeroOrdemVenda',
          cd_tipo_ordem_venda        VARCHAR2(20)  PATH '$.codigoTipoOrdemVenda',
          nu_ordem_venda_linha       VARCHAR2(20)  PATH '$.numeroOrdemVendaLinha',
          tp_separacao               VARCHAR2(20)  PATH '$.tipoSeparacao',
          cd_item                    varchar2(30)  PATH '$.codigoItem',
          vl_area_separacao          varchar2(30)  PATH '$.areaParaSeparacao',
          qt_separacao               varchar2(30)  PATH '$.quantidadeSeparacao',
          vl_plantas_m2              varchar2(30)  PATH '$.plantasMetroQuadrado',
          vl_area_disp_prog_insumos  varchar2(30)  PATH '$.areaDisponivelProgramacaoInsumos',
          gr_area_separacao          VARCHAR2(20)  PATH '$.grupoAreaSeparacao',    
          cd_receita_tratamento      VARCHAR2(20)  PATH '$.codigoReceitaTratamento',
          nu_vr_receita_tratamento   VARCHAR2(20)  PATH '$.numeroVersaoReceitaTratamento'
        )
      ) linhas
    where 
      1=1
  ) linhas
where 1=1
  and c.cd_interface            = d.cd_interface_detalhe
  and c.id_integracao_cabecalho = d.id_integracao_cabecalho
  and c.id_integracao_cabecalho = linhas.id_cab (+)
  and d.cd_interface_detalhe    = 'PROCESSAR_ORDEM_SEPARACAO_SEMENTE'
  --and d.ID_INTEGRACAO_detalhe   = 1780
;
/
--


select * --distinct usuario, cd_unidade_operacional, nu_ordem_venda, cd_tipo_ordem_venda, nu_ordem_venda_linha
from XXFR_WMS_VW_INT_PROC_SEPARACAO 
where ID_INTEGRACAO_detalhe=54914;



--select * from xxfr_integracao_detalhe where ID_INTEGRACAO_detalhe=5317;
/*
TRATAMENTO

SELECT nvl(SUM(ort.qt_area), 0)
--INTO l_area_separado
FROM xxfr_wms_ordem_separacao_tran ort
WHERE 1=1
  AND ort.id_ordem_separacao_lin = p_line_id
;


EXPEDIÇÃO

SELECT nvl(SUM(ort.qt_area), 0)
--INTO l_area_separado
FROM 
  xxfr_wms_ordem_separacao_tran  ort,
  mtl_material_transactions_temp mmtt
WHERE 1=1
  AND ort.material_transaction_temp_id = mmtt.transaction_temp_id
  AND ort.id_ordem_separacao_lin = p_line_id   
;
            
SELECT * FROM xxfr_wms_ordem_separacao_tran;
            
SELECT TABLE_NAME FROM ALL_TABLES WHERE TABLE_NAME LIKE '%ORDEM%';
            
SELECT * FROM XXFR_WMS_ORDEM_SEPARACAO_HDR;
SELECT * FROM XXFR_WMS_ORDEM_SEPARACAO_LIN;
SELECT * FROM XXFR_WMS_ORDEM_SEPARACAO_TRAN;
           
ID_ORDEM_SEPARACAO_HDR
INVENTORY_ITEM_ID
QT_AREA
QT_AREA_DISP_PROG           
   
SELECT QT_AREA,
FROM 
  XXFR_WMS_ORDEM_SEPARACAO_HDR H,
  XXFR_WMS_ORDEM_SEPARACAO_LIN L
WHERE 1=1
  AND H.ID_ORDEM_SEPARACAO_HDR = L.ID_ORDEM_SEPARACAO_HDR
  AND L.SOURCE_ORDER_LINE_ID   = 12  
  AND L.INVENTORY_ITEM_ID      = 13
            
*/