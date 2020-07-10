DROP TABLE XXFR_DEV_SIMB_INSUMOS_ERRO;
CREATE TABLE XXFR_DEV_SIMB_INSUMOS_ERRO(
  ERRO_ID           NUMBER,
  HEADER_ID         NUMBER,
  LINE_ID           NUMBER,
  CD_ETAPA          VARCHAR2(300),
  DS_MENSAGEM       VARCHAR2(3000),
  CD_REFERENCIA     VARCHAR2(50)
);
--
-- *******************************************************************************
--
DROP TABLE XXFR_DEV_SIMB_INSUMOS_HEADER;
CREATE TABLE XXFR_DEV_SIMB_INSUMOS_HEADER(			
  HEADER_ID  	      NUMBER,
  ORGANIZATION_ID   NUMBER,       --Organizacao de Inventário
  FORMULA_ID        NUMBER,
  INVENTORY_ITEM_ID NUMBER,       --Código Produto Acabado
  REFERENCE_DATE    DATE,         --Data de Referência
  QUANTITY         	NUMBER,       --Quantidade Produzida
  UOM_CODE        	VARCHAR2(20), --Unidade de Medida Primária PA
  STATUS            VARCHAR2(20), --Status de Processamento
  SEGMENT           VARCHAR2(50),
  --
  REQUEST_ID        NUMBER,
  OE_HEADER_ID      NUMBER,
  --
  LAST_UPDATE_DATE	DATE,
  LAST_UPDATE_BY    NUMBER,
  CREATION_DATE     DATE,
  CREATED_BY        NUMBER
);
/
--
-- *******************************************************************************
--
DROP TABLE XXFR_DEV_SIMB_INSUMOS_LINES;
CREATE TABLE XXFR_DEV_SIMB_INSUMOS_LINES (
  HEADER_ID  	      NUMBER,
  LINE_ID           NUMBER,
  INVENTORY_ITEM_ID NUMBER,       --Código Item Componente
  QUANTITY         	NUMBER,       --Quantidade Item Componente
  UOM_CODE        	VARCHAR2(20), --Unidade de Medida Primária Item Componente
  -- Informações da Devolucao.
  ID_INTEGRACAO_DETALHE NUMBER,
  INVOICE_ID            NUMBER,
  OPERATION_ID          NUMBER,
  --
  LAST_UPDATE_DATE	DATE,
  LAST_UPDATE_BY    NUMBER,
  CREATION_DATE     DATE,
  CREATED_BY        NUMBER
);
/
drop sequence XXFR_SEQ_RET_INSUMOS_ERRO;
CREATE SEQUENCE XXFR_SEQ_RET_INSUMOS_ERRO;
drop sequence XXFR_SEQ_RET_INSUMOS_HEADER;
CREATE SEQUENCE XXFR_SEQ_RET_INSUMOS_HEADER;
drop sequence XXFR_SEQ_RET_INSUMOS_LINES;
CREATE SEQUENCE XXFR_SEQ_RET_INSUMOS_LINES;
--




--select * from XXFR_DEV_SIMB_INSUMOS_LINES;
--select * from XXFR_DEV_SIMB_INSUMOS_HEADER;

XXFR_DEV_SIMB_INSUMOS_HEADER
--select cd_etapa, ds_mensagem, cd_referencia from xxfr_dev_simb_insumos_erro where header_id=1;
