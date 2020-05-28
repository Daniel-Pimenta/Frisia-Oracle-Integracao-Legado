DROP TABLE XXFR_DEV_SIMB_INSUMOS_HEADER;
CREATE TABLE XXFR_DEV_SIMB_INSUMOS_HEADER(			
  HEADER_ID  	      NUMBER,
  ORGANIZATION_ID   NUMBER,       --Organizacao de Invent�rio
  INVENTORY_ITEM_ID NUMBER,       --C�digo Produto Acabado
  REFERENCE_DATE    DATE,         --Data de Refer�ncia
  QUANTITY         	NUMBER,       --Quantidade Produzida
  UOM_CODE        	VARCHAR2(20), --Unidade de Medida Prim�ria PA
  STATUS            VARCHAR2(20), --Status de Processamento
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
  INVENTORY_ITEM_ID NUMBER,       --C�digo Item Componente
  QUANTITY         	NUMBER,       --Quantidade Item Componente
  UOM_CODE        	VARCHAR2(20), --Unidade de Medida Prim�ria Item Componente
  --
  LAST_UPDATE_DATE	DATE,
  LAST_UPDATE_BY    NUMBER,
  CREATION_DATE     DATE,
  CREATED_BY        NUMBER
);
/
drop sequence XXFR_SEQ_RET_INSUMOS_HEADER;
CREATE SEQUENCE XXFR_SEQ_RET_INSUMOS_HEADER;
drop sequence XXFR_SEQ_RET_INSUMOS_LINES;
CREATE SEQUENCE XXFR_SEQ_RET_INSUMOS_LINES;
--
--select * from XXFR_DEV_SIMB_INSUMOS_LINES;
