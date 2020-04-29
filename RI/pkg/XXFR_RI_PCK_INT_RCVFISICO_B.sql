create or replace package xxfr_ri_pck_int_rcvfisico as
  procedure insert_rcv_tables(
    p_organization_id   in   number,
    p_operation_id      in   number,
    x_retorno           out nocopy varchar2
  );
end;
/
create or replace package body xxfr_ri_pck_int_rcvfisico as

  p_recipt_num   varchar2(30); -- OPERATION_ID
  --P_PO_NUMBER    VARCHAR2(30) := '13549'; 
  p_user_name    varchar2(30) := 'HENRIQUE.EIFERT'; -- ( USUÁRIO )
  p_uo           number := 84; -- 81 ( PEGAR INFORMACAO )
  p_qtd          number := 10; -- BUSCAR DA LINHA DO RECEBIMENTO
  p_subinv_code  varchar2(30) := 'GER';
  --P_LOCATOR_CODE VARCHAR2(30) := 'TRT.00.000.00';
  --P_LOT_NUMBER   VARCHAR2(30) := 'L_TESTE';
  --P_EXP_DATE     DATE := SYSDATE + 200;
  
  l_user_id         number;
  l_po_header_id    number;
  l_vendor_id       number;
  l_segment1        varchar2(20);
  l_org_id          number;
  l_line_num        number;
  v_rcv_header      rcv_headers_interface%rowtype;
  v_rcv_trx         rcv_transactions_interface%rowtype;
  v_lot             mtl_transaction_lots_interface%rowtype;
  l_request_id      number;
  l_request_status  boolean;
  l_phase           varchar2(2000);
  l_wait_status     varchar2(2000);
  l_dev_status      varchar2(2000);
  l_dev_phase       varchar2(2000);
  l_message         varchar2(2000);
  v_rcv_txn_receive rcv_transactions%rowtype;
  l_group_id        number;
  l_locator_id      number;

  cursor crh (
    pc_operation_id      in varchar2,
    pc_organization_id   in number
  ) is
  select
    cfeo.organization_id   ship_to_organization_id,
    cfeo.operation_id      shipment_num,
    cfeo.location_id       location_id,
    cfeo.gl_date           transaction_date,
    cfeo.receive_date      expected_receipt_date,
    cfeo.receive_date      shipped_date,
    cfeo.location_id       ship_to_location_id,
    cfvv.vendor_id,
    cfvv.vendor_site_id,
    cfi.invoice_id -- BUG 19031932
  from
    cll_f189_entry_operations   cfeo,
    cll_f189_invoices           cfi,
    cll_f189_vendors_v          cfvv
  where
    1 = 1
    and cfeo.operation_id    = cfi.operation_id
    and cfeo.organization_id = cfi.organization_id
    and cfi.entity_id        = cfvv.entity_id
    and nvl(cfvv.inactive_date, sysdate + 1) > sysdate
    and cfeo.operation_id    = pc_operation_id
    and cfeo.organization_id = pc_organization_id;

  cursor crt (
    pc_operation_id      in varchar2,
    pc_organization_id   in number
  ) is
  select
    sum(cfil.quantity)      quantity,
    cfil.line_location_id   po_line_location_id,
    muom.uom_code           uom,
    cfi.invoice_num         waybill_airbill_num
  from
    cll_f189_entry_operations   cfeo,
    cll_f189_invoices           cfi,
    cll_f189_invoice_lines      cfil,
    mtl_units_of_measure        muom
  where
    1 = 1
    and cfeo.operation_id = cfi.operation_id
    and cfeo.organization_id = cfi.organization_id
    and cfi.invoice_id = cfil.invoice_id
    and cfi.organization_id = cfil.organization_id
    and cfil.uom = muom.unit_of_measure
    and cfeo.operation_id = pc_operation_id
    and cfeo.organization_id = pc_organization_id
  group by
    cfil.line_location_id,
    muom.uom_code,
    cfi.invoice_num;

  procedure print_log (
    msg in varchar2
  ) is
  begin
    dbms_output.put_line('  '||msg);
  end;

  procedure insert_rcv_tables(
    p_organization_id   in   number,
    p_operation_id      in   number,
    x_retorno           out nocopy varchar2
  ) is
  
  begin 
    print_log('XXFR_RI_PCK_INT_RCVFISICO.INSERT_RCV_TABLES');
    print_log('Busca dados da PO'); -- CURSOR DAS LINHAS DO RI
    begin
      select po_header_id, vendor_id, segment1, org_id
      into l_po_header_id, l_vendor_id, l_segment1, l_org_id
      from po_headers_all
      where segment1 = p_po_number
      and org_id = p_uo;
    exception when others then
      print_log('Erro ao buscar dados da PO');
      return;
    end;

    print_log('PO_HEADER_ID: ' || l_po_header_id);
    print_log('VENDOR_ID:    ' || l_vendor_id);
    print_log('SEGMENT1:     ' || l_segment1);
    print_log('ORG_ID:       ' || l_org_id);
    
    print_log('Busca dados do Usuário');
    begin
      select user_id into l_user_id
      from fnd_user
      where user_name = p_user_name;
    exception when others then
      print_log('Erro ao buscar dados do Usuário');
      return;
    end;

    print_log('l_USER_ID:    ' || l_user_id);
    fnd_global.apps_initialize(
      user_id      => l_user_id,
      resp_id      => 50722, -- RESPONSABILIDADE INVENTARIO
      resp_appl_id => 385    -- APLICACAO INVENTARIO
    );
    v_rcv_header                        := null;
    v_rcv_header.header_interface_id    := rcv_headers_interface_s.nextval;
    v_rcv_header.group_id               := rcv_interface_groups_s.nextval;
    v_rcv_header.processing_status_code := 'PENDING';
    v_rcv_header.receipt_source_code    := 'VENDOR';
    v_rcv_header.transaction_type       := 'NEW';
    v_rcv_header.last_update_date       := sysdate;
    v_rcv_header.last_updated_by        := l_user_id;
    v_rcv_header.last_update_login      := 0;
    v_rcv_header.vendor_id              := l_vendor_id;
    v_rcv_header.expected_receipt_date  := sysdate;
    v_rcv_header.validation_flag        := 'Y';

    print_log('Inserindo dados para HEADER_INTERFACE_ID:    ' ||
    rcv_headers_interface_s.currval);
    
    l_group_id := v_rcv_header.group_id;
    
    print_log('Group_id:     ' || l_group_id);
    insert into rcv_headers_interface values v_rcv_header;

    -- SELECT NAS LINHAS DO RI
    for c1 in (
      select 
        pl.item_id,
        pl.po_line_id,
        pl.line_num,
        pll.quantity,
        pl.unit_meas_lookup_code,
        mp.organization_code,
        pll.line_location_id,
        pll.closed_code,
        pll.quantity_received,
        pll.cancel_flag,
        pll.shipment_num,
        pll.ship_to_location_id
      from 
        po_lines_all          pl,
        po_line_locations_all pll,
        mtl_parameters        mp
      where 1=1
        and pl.po_header_id = l_po_header_id
        and pl.po_line_id = pll.po_line_id
        and pll.ship_to_organization_id = mp.organization_id
    ) loop
    
      if c1.closed_code in ('APPROVED', 'OPEN') and c1.quantity_received < c1.quantity and nvl(c1.cancel_flag, 'N') = 'N' then
        v_rcv_trx                          := null;
        v_rcv_trx.interface_transaction_id := rcv_transactions_interface_s.nextval;
        v_rcv_trx.group_id                 := rcv_interface_groups_s.currval;
        v_rcv_trx.last_update_date         := sysdate;
        v_rcv_trx.last_updated_by          := l_user_id;
        v_rcv_trx.creation_date            := sysdate;
        v_rcv_trx.created_by               := l_user_id;
        v_rcv_trx.last_update_login        := 0;
        v_rcv_trx.transaction_type         := 'RECEIVE';
        v_rcv_trx.transaction_date         := sysdate;
        v_rcv_trx.processing_status_code   := 'PENDING';
        v_rcv_trx.processing_mode_code     := 'BATCH';
        v_rcv_trx.transaction_status_code  := 'PENDING';
        v_rcv_trx.po_header_id             := l_po_header_id; -- TABELA DO PO
        v_rcv_trx.po_line_id               := c1.po_line_id; -- TABELA DO PO
        v_rcv_trx.item_id                  := c1.item_id; -- LINHA DO RI
        v_rcv_trx.quantity                 := p_qtd; -- VIR DA LINHA DO RI
        v_rcv_trx.unit_of_measure          := c1.unit_meas_lookup_code; -- LINHA DO RI
        v_rcv_trx.po_line_location_id      := c1.line_location_id; -- VIR DA LINHA DO RI
        v_rcv_trx.auto_transact_code       := 'RECEIVE';
        v_rcv_trx.receipt_source_code      := 'VENDOR';
        v_rcv_trx.to_organization_code     := c1.organization_code; -- CABEÇALHO DO RI
        v_rcv_trx.source_document_code     := 'PO'; -- ????
        v_rcv_trx.header_interface_id      := rcv_headers_interface_s.currval;
        v_rcv_trx.validation_flag          := 'Y';
        print_log('Inserindo po_line_id ' || c1.po_line_id ||' Item_id ' || c1.item_id);
        insert into rcv_transactions_interface values v_rcv_trx;
      else
        print_log('Po_line_id ' || c1.po_line_id || ' Item_id ' ||c1.item_id || ' ja recebido/fechado)');
      end if;
    
    end loop;
    commit;
    
    l_request_id := fnd_request.submit_request(
      application => 'PO',
      program     => 'RVCTP',
      description => null,
      start_time  => sysdate,
      sub_request => false,
      argument1   => 'BATCH',
      argument2   => v_rcv_trx.group_id
    );
    
    commit;
    print_log('L_REQUEST_ID ' || l_request_id);
    l_request_status := fnd_concurrent.wait_for_request(
      request_id => l_request_id,
      interval   => 5,
      max_wait   => 600,
      phase      => l_phase,
      status     => l_wait_status,
      dev_phase  => l_dev_phase,
      dev_status => l_dev_status,
      message    => l_message
    );
    
    commit;
    
    for c2 in (
      select 
        rt.transaction_id,
        rt.unit_of_measure,
        pla.item_id,
        rt.employee_id,
        plla.ship_to_location_id,
        rt.vendor_id,
        rt.po_header_id,
        rt.po_line_id,
        plla.line_location_id,
        pha.segment1,
        plla.ship_to_organization_id,
        rt.shipment_header_id,
        rt.shipment_line_id
      from 
        rcv_transactions      rt,
        po_lines_all          pla,
        po_line_locations_all plla,
        po_headers_all        pha
      where 1=1
        and group_id = l_group_id
        and rt.transaction_type = 'RECEIVE'
        and rt.po_line_id = pla.po_line_id
        and pla.po_line_id = plla.po_line_id
        and rt.po_header_id = pha.po_header_id
    ) loop
    
    -- REPENSAR ESSE CARA   
    /*      BEGIN
    SELECT MIL.INVENTORY_LOCATION_ID
    INTO L_LOCATOR_ID
    FROM MTL_ITEM_LOCATIONS_KFV MIL
    WHERE MIL.ORGANIZATION_ID = C2.SHIP_TO_ORGANIZATION_ID
    AND MIL.CONCATENATED_SEGMENTS = P_LOCATOR_CODE;
    EXCEPTION
    WHEN OTHERS THEN
    print_log('Erro ao buscar dados do local de estoque');
    RETURN;
    END;*/
    
    v_rcv_trx                          := null;
    v_rcv_trx.interface_transaction_id := rcv_transactions_interface_s.nextval;
    v_rcv_trx.group_id                 := rcv_interface_groups_s.nextval;
    v_rcv_trx.parent_transaction_id    := c2.transaction_id;
    v_rcv_trx.transaction_type         := 'DELIVER';
    v_rcv_trx.transaction_date         := sysdate;
    v_rcv_trx.processing_status_code   := 'PENDING';
    v_rcv_trx.processing_mode_code     := 'BATCH';
    v_rcv_trx.transaction_status_code  := 'PENDING';
    v_rcv_trx.quantity                 := p_qtd;
    v_rcv_trx.unit_of_measure          := c2.unit_of_measure;
    v_rcv_trx.item_id                  := c2.item_id;
    v_rcv_trx.employee_id              := c2.employee_id;
    v_rcv_trx.auto_transact_code       := 'DELIVER';
    v_rcv_trx.ship_to_location_id      := c2.ship_to_location_id;
    v_rcv_trx.receipt_source_code      := 'VENDOR';
    v_rcv_trx.vendor_id                := c2.vendor_id;
    v_rcv_trx.source_document_code     := 'PO';
    v_rcv_trx.po_header_id             := c2.po_header_id;
    v_rcv_trx.po_line_id               := c2.po_line_id;
    v_rcv_trx.po_line_location_id      := c2.line_location_id;
    v_rcv_trx.destination_type_code    := 'INVENTORY';
    v_rcv_trx.inspection_status_code   := 'NOT INSPECTED';
    v_rcv_trx.routing_header_id        := 1;
    v_rcv_trx.deliver_to_person_id     := c2.employee_id;
    v_rcv_trx.location_id              := c2.ship_to_location_id;
    v_rcv_trx.deliver_to_location_id   := c2.ship_to_location_id;
    v_rcv_trx.document_num             := c2.segment1;
    v_rcv_trx.to_organization_id       := c2.ship_to_organization_id;
    v_rcv_trx.validation_flag          := 'Y';
    v_rcv_trx.shipment_header_id       := c2.shipment_header_id;
    v_rcv_trx.shipment_line_id         := c2.shipment_line_id;
    v_rcv_trx.subinventory             := p_subinv_code;
    v_rcv_trx.locator_id               := l_locator_id;
    v_rcv_trx.last_update_date         := sysdate;
    v_rcv_trx.last_updated_by          := l_user_id;
    v_rcv_trx.creation_date            := sysdate;
    v_rcv_trx.created_by               := l_user_id;
    v_rcv_trx.last_update_login        := 0;
    
    print_log('Inserindo dados do Delivery');
    
    -- IR NO CADASTRO DO ITEM VALIDAR SE ITEM TEM CONTROLE DE LOTE PARA EXECUTAR OU NAO ESSA PARTE
    insert into rcv_transactions_interface values v_rcv_trx;
    
    if p_lot_number is not null then
      v_lot.transaction_interface_id := mtl_material_transactions_s.nextval;
      v_lot.lot_number               := p_lot_number;
      v_lot.lot_expiration_date      := p_exp_date;
      v_lot.transaction_quantity     := p_qtd;
      v_lot.primary_quantity         := p_qtd;
      v_lot.product_code             := 'RCV';
      v_lot.product_transaction_id   := v_rcv_trx.interface_transaction_id;
      v_lot.last_update_date         := sysdate;
      v_lot.last_updated_by          := l_user_id;
      v_lot.creation_date            := sysdate;
      v_lot.created_by               := l_user_id;
      v_lot.last_update_login        := 0;
      insert into mtl_transaction_lots_interface values v_lot;
    end if;
    -- FIM LOTE
    
    end loop; 
    commit;
    l_request_id := fnd_request.submit_request(
      application => 'PO',
      program     => 'RVCTP',
      description => null,
      start_time  => sysdate,
      sub_request => false,
      argument1   => 'BATCH',
      argument2   => v_rcv_trx.group_id
    );
    
    commit;
    print_log('L_REQUEST_ID ' || l_request_id);
    l_request_status := fnd_concurrent.wait_for_request(
      request_id => l_request_id,
      interval   => 5,
      max_wait   => 600,
      phase      => l_phase,
      status     => l_wait_status,
      dev_phase  => l_dev_phase,
      dev_status => l_dev_status,
      message    => l_message
    );
    
    commit;
    
    update cll_f189_invoice_lines 
    set shipment_header_id = xxxxxx
    where invoice_id = xxxxxx;
    
    commit;
    print_log('FIM XXFR_RI_PCK_INT_RCVFISICO.INSERT_RCV_TABLES');
  end insert_rcv_tables;
  
end xxfr_ri_pck_int_rcvfisico;
/
