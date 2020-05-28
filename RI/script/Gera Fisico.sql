BEGIN
  DECLARE
    
    P_RECIPT_NUM   VARCHAR2(30); -- OPERATION_ID
    --P_PO_NUMBER    VARCHAR2(30) := '13549'; 
    P_USER_NAME    VARCHAR2(30) := 'HENRIQUE.EIFERT'; -- ( USUÁRIO )
    P_UO           NUMBER := 84; -- 81 ( PEGAR INFORMACAO )
    P_QTD          NUMBER := 10; -- BUSCAR DA LINHA DO RECEBIMENTO
    P_SUBINV_CODE  VARCHAR2(30) := 'GER';
    --P_LOCATOR_CODE VARCHAR2(30) := 'TRT.00.000.00';
    --P_LOT_NUMBER   VARCHAR2(30) := 'L_TESTE';
    --P_EXP_DATE     DATE := SYSDATE + 200;
  
    L_USER_ID         NUMBER;
    L_PO_HEADER_ID    NUMBER;
    L_VENDOR_ID       NUMBER;
    L_SEGMENT1        VARCHAR2(20);
    L_ORG_ID          NUMBER;
    L_LINE_NUM        NUMBER;
    V_RCV_HEADER      RCV_HEADERS_INTERFACE%ROWTYPE;
    V_RCV_TRX         RCV_TRANSACTIONS_INTERFACE%ROWTYPE;
    V_LOT             MTL_TRANSACTION_LOTS_INTERFACE%ROWTYPE;
    L_REQUEST_ID      NUMBER;
    L_REQUEST_STATUS  BOOLEAN;
    L_PHASE           VARCHAR2(2000);
    L_WAIT_STATUS     VARCHAR2(2000);
    L_DEV_STATUS      VARCHAR2(2000);
    L_DEV_PHASE       VARCHAR2(2000);
    L_MESSAGE         VARCHAR2(2000);
    V_RCV_TXN_RECEIVE RCV_TRANSACTIONS%ROWTYPE;
    L_GROUP_ID        NUMBER;
    L_LOCATOR_ID      NUMBER;
  
  BEGIN
  
    DBMS_OUTPUT.PUT_LINE('Busca dados da PO'); -- CURSOR DAS LINHAS DO RI
    BEGIN
      SELECT PO_HEADER_ID, VENDOR_ID, SEGMENT1, ORG_ID
        INTO L_PO_HEADER_ID, L_VENDOR_ID, L_SEGMENT1, L_ORG_ID
        FROM PO_HEADERS_ALL
       WHERE SEGMENT1 = P_PO_NUMBER
         AND ORG_ID = P_UO;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao buscar dados da PO');
        RETURN;
    END;
  
    DBMS_OUTPUT.PUT_LINE('PO_HEADER_ID: ' || L_PO_HEADER_ID);
    DBMS_OUTPUT.PUT_LINE('VENDOR_ID:    ' || L_VENDOR_ID);
    DBMS_OUTPUT.PUT_LINE('SEGMENT1:     ' || L_SEGMENT1);
    DBMS_OUTPUT.PUT_LINE('ORG_ID:       ' || L_ORG_ID);
  
    DBMS_OUTPUT.PUT_LINE('Busca dados do Usuário');
    BEGIN
      SELECT USER_ID
        INTO L_USER_ID
        FROM FND_USER
       WHERE USER_NAME = P_USER_NAME;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao buscar dados do Usuário');
        RETURN;
    END;
  
    DBMS_OUTPUT.PUT_LINE('l_USER_ID:    ' || L_USER_ID);
  
    FND_GLOBAL.APPS_INITIALIZE(USER_ID      => L_USER_ID,
                               RESP_ID      => 50722, -- RESPONSABILIDADE INVENTARIO
                               RESP_APPL_ID => 385);  -- APLICACAO INVENTARIO
  
    V_RCV_HEADER                        := NULL;
    V_RCV_HEADER.HEADER_INTERFACE_ID    := RCV_HEADERS_INTERFACE_S.NEXTVAL;
    V_RCV_HEADER.GROUP_ID               := RCV_INTERFACE_GROUPS_S.NEXTVAL;
    V_RCV_HEADER.PROCESSING_STATUS_CODE := 'PENDING';
    V_RCV_HEADER.RECEIPT_SOURCE_CODE    := 'VENDOR';
    V_RCV_HEADER.TRANSACTION_TYPE       := 'NEW';
    V_RCV_HEADER.LAST_UPDATE_DATE       := SYSDATE;
    V_RCV_HEADER.LAST_UPDATED_BY        := L_USER_ID;
    V_RCV_HEADER.LAST_UPDATE_LOGIN      := 0;
    V_RCV_HEADER.VENDOR_ID              := L_VENDOR_ID;
    V_RCV_HEADER.EXPECTED_RECEIPT_DATE  := SYSDATE;
    V_RCV_HEADER.VALIDATION_FLAG        := 'Y';
  
    DBMS_OUTPUT.PUT_LINE('Inserindo dados para HEADER_INTERFACE_ID:    ' ||
                         RCV_HEADERS_INTERFACE_S.CURRVAL);
  
    L_GROUP_ID := V_RCV_HEADER.GROUP_ID;
  
    DBMS_OUTPUT.PUT_LINE('Group_id:     ' || L_GROUP_ID);
  
    INSERT INTO RCV_HEADERS_INTERFACE VALUES V_RCV_HEADER;
  
  
  -- SELECT NAS LINHAS DO RI
    FOR C1 IN (
    SELECT PL.ITEM_ID,
                      PL.PO_LINE_ID,
                      PL.LINE_NUM,
                      PLL.QUANTITY,
                      PL.UNIT_MEAS_LOOKUP_CODE,
                      MP.ORGANIZATION_CODE,
                      PLL.LINE_LOCATION_ID,
                      PLL.CLOSED_CODE,
                      PLL.QUANTITY_RECEIVED,
                      PLL.CANCEL_FLAG,
                      PLL.SHIPMENT_NUM,
                      PLL.SHIP_TO_LOCATION_ID
                 FROM PO_LINES_ALL          PL,
                      PO_LINE_LOCATIONS_ALL PLL,
                      MTL_PARAMETERS        MP
                WHERE PL.PO_HEADER_ID = 17012 --L_PO_HEADER_ID
                  AND PL.PO_LINE_ID = PLL.PO_LINE_ID
                  AND PLL.SHIP_TO_ORGANIZATION_ID = MP.ORGANIZATION_ID
                ) LOOP
    
      IF C1.CLOSED_CODE IN ('APPROVED', 'OPEN') AND
         C1.QUANTITY_RECEIVED < C1.QUANTITY AND
         NVL(C1.CANCEL_FLAG, 'N') = 'N' THEN
      
        V_RCV_TRX                          := NULL;
        V_RCV_TRX.INTERFACE_TRANSACTION_ID := RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL;
        V_RCV_TRX.GROUP_ID                 := RCV_INTERFACE_GROUPS_S.CURRVAL;
        V_RCV_TRX.LAST_UPDATE_DATE         := SYSDATE;
        V_RCV_TRX.LAST_UPDATED_BY          := L_USER_ID;
        V_RCV_TRX.CREATION_DATE            := SYSDATE;
        V_RCV_TRX.CREATED_BY               := L_USER_ID;
        V_RCV_TRX.LAST_UPDATE_LOGIN        := 0;
        V_RCV_TRX.TRANSACTION_TYPE         := 'RECEIVE';
        V_RCV_TRX.TRANSACTION_DATE         := SYSDATE;
        V_RCV_TRX.PROCESSING_STATUS_CODE   := 'PENDING';
        V_RCV_TRX.PROCESSING_MODE_CODE     := 'BATCH';
        V_RCV_TRX.TRANSACTION_STATUS_CODE  := 'PENDING';
        V_RCV_TRX.PO_HEADER_ID             := L_PO_HEADER_ID; -- TABELA DO PO
        V_RCV_TRX.PO_LINE_ID               := C1.PO_LINE_ID; -- TABELA DO PO
        V_RCV_TRX.ITEM_ID                  := C1.ITEM_ID; -- LINHA DO RI
        V_RCV_TRX.QUANTITY                 := P_QTD; -- VIR DA LINHA DO RI
        V_RCV_TRX.UNIT_OF_MEASURE          := C1.UNIT_MEAS_LOOKUP_CODE; -- LINHA DO RI
        V_RCV_TRX.PO_LINE_LOCATION_ID      := C1.LINE_LOCATION_ID; -- VIR DA LINHA DO RI
        V_RCV_TRX.AUTO_TRANSACT_CODE       := 'RECEIVE';
        V_RCV_TRX.RECEIPT_SOURCE_CODE      := 'VENDOR';
        V_RCV_TRX.TO_ORGANIZATION_CODE     := C1.ORGANIZATION_CODE; -- CABEÇALHO DO RI
        V_RCV_TRX.SOURCE_DOCUMENT_CODE     := 'PO'; -- ????
        V_RCV_TRX.HEADER_INTERFACE_ID      := RCV_HEADERS_INTERFACE_S.CURRVAL;
        V_RCV_TRX.VALIDATION_FLAG          := 'Y';
      
        DBMS_OUTPUT.PUT_LINE('Inserindo po_line_id ' || C1.PO_LINE_ID ||
                             ' Item_id ' || C1.ITEM_ID);
      
        INSERT INTO RCV_TRANSACTIONS_INTERFACE VALUES V_RCV_TRX;
      
      ELSE
        DBMS_OUTPUT.PUT_LINE('Po_line_id ' || C1.PO_LINE_ID || ' Item_id ' ||
                             C1.ITEM_ID || ' ja recebido/fechado)');
      END IF;
    
    END LOOP;
  
    COMMIT;
  
    L_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST(APPLICATION => 'PO',
                                               PROGRAM     => 'RVCTP',
                                               DESCRIPTION => NULL,
                                               START_TIME  => SYSDATE,
                                               SUB_REQUEST => FALSE,
                                               ARGUMENT1   => 'BATCH',
                                               ARGUMENT2   => V_RCV_TRX.GROUP_ID);
  
    COMMIT;
  
    DBMS_OUTPUT.PUT_LINE('L_REQUEST_ID ' || L_REQUEST_ID);
  
    L_REQUEST_STATUS := FND_CONCURRENT.WAIT_FOR_REQUEST(REQUEST_ID => L_REQUEST_ID,
                                                        INTERVAL   => 5,
                                                        MAX_WAIT   => 600,
                                                        PHASE      => L_PHASE,
                                                        STATUS     => L_WAIT_STATUS,
                                                        DEV_PHASE  => L_DEV_PHASE,
                                                        DEV_STATUS => L_DEV_STATUS,
                                                        MESSAGE    => L_MESSAGE);
  
    COMMIT;
  
    FOR C2 IN (SELECT RT.TRANSACTION_ID,
                      RT.UNIT_OF_MEASURE,
                      PLA.ITEM_ID,
                      RT.EMPLOYEE_ID,
                      PLLA.SHIP_TO_LOCATION_ID,
                      RT.VENDOR_ID,
                      RT.PO_HEADER_ID,
                      RT.PO_LINE_ID,
                      PLLA.LINE_LOCATION_ID,
                      PHA.SEGMENT1,
                      PLLA.SHIP_TO_ORGANIZATION_ID,
                      RT.SHIPMENT_HEADER_ID,
                      RT.SHIPMENT_LINE_ID
                 FROM RCV_TRANSACTIONS      RT,
                      PO_LINES_ALL          PLA,
                      PO_LINE_LOCATIONS_ALL PLLA,
                      PO_HEADERS_ALL        PHA
                WHERE GROUP_ID = L_GROUP_ID
                  AND RT.TRANSACTION_TYPE = 'RECEIVE'
                  AND RT.PO_LINE_ID = PLA.PO_LINE_ID
                  AND PLA.PO_LINE_ID = PLLA.PO_LINE_ID
                  AND RT.PO_HEADER_ID = PHA.PO_HEADER_ID) LOOP
    
 -- REPENSAR ESSE CARA   
/*      BEGIN
        SELECT MIL.INVENTORY_LOCATION_ID
          INTO L_LOCATOR_ID
          FROM MTL_ITEM_LOCATIONS_KFV MIL
         WHERE MIL.ORGANIZATION_ID = C2.SHIP_TO_ORGANIZATION_ID
           AND MIL.CONCATENATED_SEGMENTS = P_LOCATOR_CODE;
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Erro ao buscar dados do local de estoque');
          RETURN;
      END;*/
    
      V_RCV_TRX                          := NULL;
      V_RCV_TRX.INTERFACE_TRANSACTION_ID := RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL;
      V_RCV_TRX.GROUP_ID                 := RCV_INTERFACE_GROUPS_S.NEXTVAL;
      V_RCV_TRX.PARENT_TRANSACTION_ID    := C2.TRANSACTION_ID;
      V_RCV_TRX.TRANSACTION_TYPE         := 'DELIVER';
      V_RCV_TRX.TRANSACTION_DATE         := SYSDATE;
      V_RCV_TRX.PROCESSING_STATUS_CODE   := 'PENDING';
      V_RCV_TRX.PROCESSING_MODE_CODE     := 'BATCH';
      V_RCV_TRX.TRANSACTION_STATUS_CODE  := 'PENDING';
      V_RCV_TRX.QUANTITY                 := P_QTD;
      V_RCV_TRX.UNIT_OF_MEASURE          := C2.UNIT_OF_MEASURE;
      V_RCV_TRX.ITEM_ID                  := C2.ITEM_ID;
      V_RCV_TRX.EMPLOYEE_ID              := C2.EMPLOYEE_ID;
      V_RCV_TRX.AUTO_TRANSACT_CODE       := 'DELIVER';
      V_RCV_TRX.SHIP_TO_LOCATION_ID      := C2.SHIP_TO_LOCATION_ID;
      V_RCV_TRX.RECEIPT_SOURCE_CODE      := 'VENDOR';
      V_RCV_TRX.VENDOR_ID                := C2.VENDOR_ID;
      V_RCV_TRX.SOURCE_DOCUMENT_CODE     := 'PO';
      V_RCV_TRX.PO_HEADER_ID             := C2.PO_HEADER_ID;
      V_RCV_TRX.PO_LINE_ID               := C2.PO_LINE_ID;
      V_RCV_TRX.PO_LINE_LOCATION_ID      := C2.LINE_LOCATION_ID;
      V_RCV_TRX.DESTINATION_TYPE_CODE    := 'INVENTORY';
      V_RCV_TRX.INSPECTION_STATUS_CODE   := 'NOT INSPECTED';
      V_RCV_TRX.ROUTING_HEADER_ID        := 1;
      V_RCV_TRX.DELIVER_TO_PERSON_ID     := C2.EMPLOYEE_ID;
      V_RCV_TRX.LOCATION_ID              := C2.SHIP_TO_LOCATION_ID;
      V_RCV_TRX.DELIVER_TO_LOCATION_ID   := C2.SHIP_TO_LOCATION_ID;
      V_RCV_TRX.DOCUMENT_NUM             := C2.SEGMENT1;
      V_RCV_TRX.TO_ORGANIZATION_ID       := C2.SHIP_TO_ORGANIZATION_ID;
      V_RCV_TRX.VALIDATION_FLAG          := 'Y';
      V_RCV_TRX.SHIPMENT_HEADER_ID       := C2.SHIPMENT_HEADER_ID;
      V_RCV_TRX.SHIPMENT_LINE_ID         := C2.SHIPMENT_LINE_ID;
      V_RCV_TRX.SUBINVENTORY             := P_SUBINV_CODE;
      V_RCV_TRX.LOCATOR_ID               := L_LOCATOR_ID;
      V_RCV_TRX.LAST_UPDATE_DATE         := SYSDATE;
      V_RCV_TRX.LAST_UPDATED_BY          := L_USER_ID;
      V_RCV_TRX.CREATION_DATE            := SYSDATE;
      V_RCV_TRX.CREATED_BY               := L_USER_ID;
      V_RCV_TRX.LAST_UPDATE_LOGIN        := 0;
    
      DBMS_OUTPUT.PUT_LINE('Inserindo dados do Delivery');
    

-- IR NO CADASTRO DO ITEM VALIDAR SE ITEM TEM CONTROLE DE LOTE PARA EXECUTAR OU NAO ESSA PARTE
      INSERT INTO RCV_TRANSACTIONS_INTERFACE VALUES V_RCV_TRX;
    
      IF P_LOT_NUMBER IS NOT NULL THEN
        V_LOT.TRANSACTION_INTERFACE_ID := MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL;
        V_LOT.LOT_NUMBER               := P_LOT_NUMBER;
        V_LOT.LOT_EXPIRATION_DATE      := P_EXP_DATE;
        V_LOT.TRANSACTION_QUANTITY     := P_QTD;
        V_LOT.PRIMARY_QUANTITY         := P_QTD;
        V_LOT.PRODUCT_CODE             := 'RCV';
        V_LOT.PRODUCT_TRANSACTION_ID   := V_RCV_TRX.INTERFACE_TRANSACTION_ID;
        V_LOT.LAST_UPDATE_DATE         := SYSDATE;
        V_LOT.LAST_UPDATED_BY          := L_USER_ID;
        V_LOT.CREATION_DATE            := SYSDATE;
        V_LOT.CREATED_BY               := L_USER_ID;
        V_LOT.LAST_UPDATE_LOGIN        := 0;
      
        INSERT INTO MTL_TRANSACTION_LOTS_INTERFACE VALUES V_LOT;
      END IF;
      -- FIM LOTE
    
    END LOOP;
  
    COMMIT;
  
    L_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST(APPLICATION => 'PO',
                                               PROGRAM     => 'RVCTP',
                                               DESCRIPTION => NULL,
                                               START_TIME  => SYSDATE,
                                               SUB_REQUEST => FALSE,
                                               ARGUMENT1   => 'BATCH',
                                               ARGUMENT2   => V_RCV_TRX.GROUP_ID);
  
    COMMIT;
  
    DBMS_OUTPUT.PUT_LINE('L_REQUEST_ID ' || L_REQUEST_ID);
  
    L_REQUEST_STATUS := FND_CONCURRENT.WAIT_FOR_REQUEST(REQUEST_ID => L_REQUEST_ID,
                                                        INTERVAL   => 5,
                                                        MAX_WAIT   => 600,
                                                        PHASE      => L_PHASE,
                                                        STATUS     => L_WAIT_STATUS,
                                                        DEV_PHASE  => L_DEV_PHASE,
                                                        DEV_STATUS => L_DEV_STATUS,
                                                        MESSAGE    => L_MESSAGE);
  
    COMMIT;
    
    UPDATE CLL_F189_INVOICE_LINES 
    SET SHIPMENT_HEADER_ID = XXXXXX
    WHERE INVOICE_ID = XXXXXX;
    
    COMMIT;
    
  END;
END;
