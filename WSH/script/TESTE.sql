SET SERVEROUTPUT ON
DECLARE

  p_seq_det NUMBER := -153;
  p_seq_cab NUMBER := -80;
  isNew     boolean := false;
  OK        BOOLEAN;

  STR_JSON VARCHAR2(32000) := ('
{
"idTransacao" : "-1",
"versaoPayload" : "1.0",
"sistemaOrigem" : "SIF.LEI.ROMANEIO",
"codigoServico" : "PROCESSAR_ENTREGA",
"usuario" : "joel",
"processarEntrega" : {
"codigoUnidadeOperacional" : "UO_FRISIA",
"dividirLinha" : "SIM",
"conteudoFirme" : "SIM",
"liberarSeparacao" : "SIM",
"percurso" : [{
"operacao" : "INCLUIR",
"nomePercurso" : "22L_371846",
"codigoReferenciaOrigem" : "371846",
"tipoReferenciaOrigem" : "LEI_ROMANEIO",
"ajustaDistribuicao" : "SIM",
"lacresVeiculo" : "31",
"pesoTara" : 10000,
"pesoBruto" : 11100,
"codigoCarregamento" : null,
"tipoFrete" : null,
"codigoMetodoEntrega" : null,
"codigoEnderecoEstoqueGranel" : null,
"tipoLiberacao" : "AUTOPICK",
"transportador" : {
"codigoTransportador" : "76107440000104",
"nomeMotorista" : "ABEL VITOR PEREIRA",
"cpfMotorista" : 9104482646
},
"veiculo" : {
"codigoRegistroANTT" : "NES01010101",
"codigoRegistroANTTCavalo" : null,
"codigoPlaca1" : "NES0T00",
"codigoPlaca2" : null,
"codigoPlaca3" : null,
"codigoPlaca4" : null,
"codigoPlaca5" : null
},
"distribuicao" : [{
"nomeDistribuicao" : null,
"codigoCliente" : "60409075",
"codigoLocalEntregaCliente" : null,
"codigoMoeda" : null,
"codigoControleEntregaCliente" : null,
"codigosLacres" : null,
"dadosAdicionais" : null,
"linhasEntrega" : [{
"codigoTipoOrdemVenda" : "22L_VENDA",
"numeroOrdemVenda" : 59,
"numeroLinhaOrdemVenda" : "1",
"numeroEnvioLinhaOrdemVenda" : null,
"quantidade" : 1066,
"codigoUnidadeMedida" : "L",
"codigoEnderecoEstoque" : "MPG.00.001.00",
"observacao" : null,
"percentualGordura" : 3.2
}]
}]
}]
}
}
');

  procedure print_out(msg varchar2) is
  begin
    DBMS_OUTPUT.PUT_LINE(msg);
  end;

BEGIN
  OK := TRUE;
  
  BEGIN
    if (isNew) then
      select min(ID_INTEGRACAO_CABECALHO) -1 into  p_seq_cab from xxfr_integracao_cabecalho;
      select min(ID_INTEGRACAO_DETALHE) -1   into  p_seq_det from xxfr_integracao_detalhe;
    end if;
    
    print_out('Limpando detalhe...');
    delete xxfr_integracao_detalhe   WHERE ID_INTEGRACAO_DETALHE = p_seq_det;
    print_out('Limpando cab...');
    delete xxfr_integracao_cabecalho WHERE ID_INTEGRACAO_CABECALHO = p_seq_cab;
    insert into xxfr_integracao_cabecalho (
      ID_INTEGRACAO_CABECALHO, 
      DT_CRIACAO, 
      NM_USUARIO_CRIACAO, 
      CD_PROGRAMA_CRIACAO, 
      DT_ATUALIZACAO, 
      NM_USUARIO_ATUALIZACAO, 
      CD_PROGRAMA_ATUALIZACAO, 
      CD_SISTEMA_ORIGEM, 
      CD_SISTEMA_DESTINO, 
      NR_SEQUENCIA_FILA, 
      CD_INTERFACE, 
      CD_CHAVE_INTERFACE, 
      IE_STATUS_INTEGRACAO, 
      DT_CONCLUSAO_INTEGRACAO
    ) values (
      p_seq_cab,
      SYSDATE,
      'DANIEL.PIMENTA',
      'PL/SQL Developer',
      SYSDATE,
      'DANIEL.PIMENTA',
      'PL/SQL Developer',
      'SIF.LEI.ROMANEIO',
      'EBS',
      1,
      'PROCESSAR_ENTREGA',
      NULL,
      'NOVO',
      NULL
    );
    PRINT_OUT('ID CABECALHO:'||p_seq_cab);
  EXCEPTION
    WHEN OTHERS THEN
      PRINT_OUT('ERRO CABEÇALHO :'||SQLERRM);
      OK := FALSE;
  END;
  BEGIN
    INSERT INTO xxfr_integracao_detalhe (
      ID_INTEGRACAO_DETALHE, 
      ID_INTEGRACAO_CABECALHO, 
      DT_CRIACAO, 
      NM_USUARIO_CRIACAO, 
      DT_ATUALIZACAO, 
      NM_USUARIO_ATUALIZACAO, 
      CD_INTERFACE_DETALHE, 
      IE_STATUS_PROCESSAMENTO, 
      DT_STATUS_PROCESSAMENTO, 
      --ID_SOA_COMPOSITE, 
      --NM_SOA_COMPOSITE, 
      DS_DADOS_REQUISICAO, 
      DS_DADOS_RETORNO
    ) VALUES (
      p_seq_det,
      p_seq_cab,
      SYSDATE,
      'DANIEL.PIMENTA',
      SYSDATE,
      'DANIEL.PIMENTA',
      'PROCESSAR_ENTREGA',
      'PENDENTE',
      SYSDATE,
      --NULL,
      --NULL,
      STR_JSON,
      NULL
    );
    PRINT_OUT('ID DETALHE:'||p_seq_det);
  EXCEPTION
    WHEN OTHERS THEN
      PRINT_OUT('ERRO DETALHE OTHERS :'||SQLERRM);
      PRINT_OUT('  ID DETALHE:'||p_seq_det);
      OK := FALSE;
  END;
  IF OK THEN
    COMMIT;
  ELSE
    ROLLBACK;
  END IF;
END;
/




SELECT * FROM xxfr_integracao_detalhe 
WHERE 1=1
  and ID_INTEGRACAO_DETALHE = 2717
and CD_INTERFACE_DETALHE like '%ENTREGA%'
order by 3 desc;


select distinct 
  mil.INVENTORY_ITEM_ID,
  mil.inventory_location_id,
  mil.INVENTORY_LOCATION_TYPE,
  mil.subinventory_code, 
  msi.subinventory_type, 
  mil.DESCRIPTION,
  msi.DESCRIPTION,
  msi.DEFAULT_COST_GROUP_ID,
  msib.LOT_CONTROL_CODE,
  moqd.lot_number, 
  trunc(moqd.date_received) date_received,
  (mil.SEGMENT1||'.'||mil.SEGMENT2||'.'||mil.SEGMENT3||'.'||mil.SEGMENT4) end_estoque 
from
  mtl_secondary_inventories    msi,
  mtl_item_locations           mil,
  mtl_system_items_b           msib,
  mtl_onhand_quantities_detail moqd
where 1=1
  and msi.organization_id          = mil.organization_id
  and msib.organization_id         = mil.organization_id
  and msib.inventory_item_id       = mil.inventory_item_id
  and msi.secondary_inventory_name = mil.segment1
  --
  and mil.inventory_location_id    = moqd.locator_id
  and msib.inventory_item_id       = moqd.inventory_item_id 
  and msi.organization_id          = moqd.organization_id 
  --
  and msib.LOT_CONTROL_CODE        = '2'
  --and mil.organization_id          =  '103'
  and mil.INVENTORY_ITEM_ID        = 46166
  --and (mil.SEGMENT1||'.'||mil.SEGMENT2||'.'||mil.SEGMENT3||'.'||mil.SEGMENT4) = 'PAG.00.000.00'
  --and rownum = 1
order by trunc(moqd.date_received)
;


select 
  ORGANIZATION_ID, 
  INVENTORY_ITEM_ID, 
  SUBINVENTORY_CODE,
  LOCATOR_ID, 
  COST_GROUP_ID,
  LOT_NUMBER, 
  PRIMARY_TRANSACTION_QUANTITY, 
  TRANSACTION_UOM_CODE, 
  TRANSACTION_QUANTITY, 
  LPN_ID  
from mtl_onhand_quantities_detail
where 1=1
  and INVENTORY_ITEM_ID = 46166
order by 1,2,3,4,5
;





SELECT   
  msi.concatenated_segments           item,
  mmt.inventory_item_id,
  REPLACE (msi.description, '~', '-') item_description,
  mtl.lot_number                      lot_number,
  mmt.subinventory_code               subinventory,
  TRUNC (mtl.transaction_date)        transaction_date,
  mmt.transaction_id                  transaction_number,
  mmt.transaction_set_id              transaction_set,
  mmt.transfer_transaction_id         transfer_transaction_number,
  mtl.creation_date                   creation_date,
  oap.period_name                     gl_period,
  oap.period_start_date               gl_period_start_date,
  DECODE (mmt.transaction_source_type_id, 11, mmt.new_cost - mmt.prior_cost, mmt.actual_cost) item_cost,
  mmt.revision                        item_revision,
  milt.concatenated_segments          transfer_stock_locators,
  ppa.NAME                            project_name,
  ppa.segment1                        project_number,
  DECODE (mut.serial_number,NULL,
    DECODE (mtl.lot_number,NULL,
      DECODE (mmt.transaction_source_type_id,11, mmt.quantity_adjusted, mmt.primary_quantity)
      ,mtl.primary_quantity
    )
    ,1
  ) quantity,
  mtr.reason_name reason,
  mut.serial_number serial_number,
  pt.task_name task_name,
  pt.task_number task_number,
  DECODE (mut.serial_number, NULL,
    DECODE (mtl.lot_number, NULL,
      DECODE (mmt.transaction_source_type_id, 11, mmt.quantity_adjusted, mmt.transaction_quantity) 
      ,mtl.transaction_quantity
    )
    ,1
  ) transaction_quantity,
  mmt.transaction_reference transaction_reference,
  mtl.transaction_source_name transaction_source_name,
  mts.transaction_source_type_name,
  mtt.transaction_type_name transaction_type,
  mmt.transaction_uom transaction_unit_of_measure,
  mmt.transfer_subinventory transfer_subinventory,
  ood.organization_name transfer_to_from,
  msi.primary_unit_of_measure unit_of_measure,
  DECODE (mmt.costed_flag, 'N', 'No', NVL (mmt.costed_flag, 'Yes')) valued_flag,
  mtt.transaction_type_id,
  milt.inventory_location_id TRANSFER_INV_LOCATION_ID,
  mil.inventory_location_id,
  mil.concatenated_segments stock_locator,
  oap.acct_period_id,
  pt.task_id,
  ppa.project_id,
  msi.inventory_item_id,
  mtr.reason_id,
  mtl.transaction_source_id,
  mtl.serial_transaction_id,
  mtl.vendor_name,
  mtl.supplier_lot_number,
  msi.organization_id,
  haou.NAME inv_org_name,
  mmt.transaction_source_type_id,
  mmt.transaction_action_id,
  mmt.department_id,
  mmt.error_explanation,
  mmt.vendor_lot_number supplier_lot,
  mmt.source_line_id,
  mmt.parent_transaction_id,
  mmt.shipment_number shipment_number,
  mmt.waybill_airbill waybill_airbill,
  mmt.freight_code freight_code,
  mmt.number_of_containers,
  mmt.rcv_transaction_id,
  mmt.move_transaction_id,
  mmt.completion_transaction_id,
  mmt.operation_seq_num opertion_sequence,
  mmt.expenditure_type,
  mmt.transaction_set_id,
  mmt.transaction_uom,
  mmt.transfer_transaction_id,
  ROUND ( (mmt.primary_quantity * mmt.actual_cost),fnd_profile.VALUE ('REPORT_QUANTITY_PRECISION')) VALUE,
  MIL.ORGANIZATION_ID MIL_ORGANIZATION_ID,
  MILT.ORGANIZATION_ID MILT_ORGANIZATION_ID,
  ood.organization_id OOD_ORGANIZATION_ID
FROM   
  mtl_transaction_types mtt,
  mtl_item_locations_kfv milt,
  mtl_item_locations_kfv mil,
  org_acct_periods oap,
  pa_tasks pt,
  pa_projects ppa,
  mtl_system_items_kfv msi,
  mtl_material_transactions mmt,
  mtl_unit_transactions mut,
  mtl_transaction_lot_numbers mtl,
  mtl_parameters mp,
  mtl_transaction_reasons mtr,
  hr_all_organization_units haou,
  org_organization_definitions ood,
  mtl_txn_source_types mts
WHERE 1=1       
  and msi.organization_id             = mp.organization_id
  AND mmt.transaction_id              = mtl.transaction_id
  AND mmt.inventory_item_id           = mtl.inventory_item_id
  AND mmt.organization_id             = mtl.organization_id
  AND mtl.serial_transaction_id       = mut.transaction_id(+)
  AND mmt.organization_id             = mp.organization_id
  AND mmt.inventory_item_id           = msi.inventory_item_id
  AND oap.organization_id(+)          = mmt.organization_id
  AND oap.acct_period_id(+)           = mmt.acct_period_id
  AND mmt.project_id                  = ppa.project_id(+)
  AND mmt.task_id                     = pt.task_id(+)
  AND mmt.locator_id                  = mil.inventory_location_id(+)
  AND mil.organization_id(+)          = mmt.organization_id
  AND mmt.transfer_locator_id         = milt.inventory_location_id(+)
  AND milt.organization_id(+)         = mmt.organization_id
  AND mmt.transaction_type_id         = mtt.transaction_type_id(+)
  AND mtr.reason_id(+)                = mmt.reason_id
  AND haou.organization_id            = msi.organization_id
  AND mmt.transfer_organization_id    = ood.organization_id(+)
  AND mts.transaction_source_type_id  = mmt.transaction_source_type_id
  --
  --and msi.organization_id = 103
  and msi.inventory_item_id in (46166)
;


select trunc(sysdate) - to_date('08-jan-2020','dd-mm-yyyy') dias from dual;





