create or replace package body XXFR_RI_PCK_INT_DEV_FISICO as

  ok                  boolean;
  g_operation_id      number; 
  g_organization_id   number;
  g_escopo            varchar2(300) := 'RECEBIMENTO_FISICO';

  cursor c1 (
    pc_operation_id      in varchar2,
    pc_organization_id   in number
  ) is
    select
      cfi.operation_id,
      cfi.organization_id,
      --
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
      and cfeo.organization_id = pc_organization_id
    ;

  cursor c2 (
    pc_operation_id      in varchar2,
    pc_organization_id   in number
  ) is
  select
    cfi.invoice_num         waybill_airbill_num,
    cfil.line_location_id   po_line_location_id,
    muom.uom_code           uom,
    sum(cfil.quantity)      cll_quantity
  from
    cll_f189_entry_operations   cfeo,
    cll_f189_invoices           cfi,
    cll_f189_invoice_lines      cfil,
    mtl_units_of_measure        muom
  where 1 = 1
    and cfeo.operation_id    = cfi.operation_id
    and cfeo.organization_id = cfi.organization_id
    and cfi.invoice_id       = cfil.invoice_id
    and cfi.organization_id  = cfil.organization_id
    and cfil.uom             = muom.unit_of_measure
    and cfeo.operation_id    = pc_operation_id
    and cfeo.organization_id = pc_organization_id
  group by
    cfil.line_location_id,
    muom.uom_code,
    cfi.invoice_num
  ;

  cursor c3(p_operation_id in number, p_organization_id in number, p_transaction_type in varchar2) is
    select distinct
      --rt.transaction_type,
      --rt.transaction_id,
      rt.shipment_header_id,
      rt.shipment_line_id,
      rt.vendor_id,
      rt.po_header_id,
      pha.segment1,
      rt.po_line_id,
      plla.line_location_id,
      pla.item_id,
      rt.quantity,
      rt.unit_of_measure,
      rt.employee_id,
      plla.ship_to_location_id,
      plla.ship_to_organization_id
    from 
      rcv_transactions        rt,
      cll_f189_invoices       ri,
      cll_f189_invoice_lines  ril,
      po_lines_all            pla,
      po_line_locations_all   plla,
      po_headers_all          pha
    where 1=1
      and rt.po_line_id           = pla.po_line_id
      and pla.po_line_id          = plla.po_line_id
      and rt.po_header_id         = pha.po_header_id
      and ril.invoice_id          = ri.invoice_id
      and ril.shipment_header_id  = rt.shipment_header_id
      --
      and ri.operation_id         = p_operation_id
      and ri.organization_id      = p_organization_id
      and rt.transaction_type     = p_transaction_type
      --and rt.group_id             = p_group_id
  ;

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => upper(g_escopo)
    );
  end;

  procedure insert_rcv_tables(
    p_operation_id      in number,
    p_organization_id   in number,
    p_dev_operation_id  in number   default null,
    p_escopo            in varchar2 default null,
    x_retorno           out varchar2
  ) is
  
    v_rcv_header      rcv_headers_interface%rowtype;
    v_rcv_trx         rcv_transactions_interface%rowtype;
    v_mtl_lot         mtl_transaction_lots_interface%rowtype;
  
    l_header_interface_id   number;
    l_group_id              number;
    l_group_id2             number;
    
    l_invoice_id            number;
    l_transaction_date      date;
    l_line_location_id      number;
    l_po_header_id          number;
    l_po_line_id            number;
    l_po_quantity           number; 
    l_quantity              number;
    l_quantity_received     number;
    l_description           varchar2(300);
    l_unit_meas_lookup_code varchar2(50);
    l_ship_to_location_id   number;
    l_approved_flag         varchar2(10);

    l_interface_transaction_id  number;

    l_interface_source_code     varchar2(50);
    l_transaction_type          varchar2(50);
    l_processing_status_code    varchar2(50);
    l_processing_mode_code      varchar2(50);
    l_transaction_status_code   varchar2(50);
    l_receipt_source_code       varchar2(50);
    l_validation_flag           varchar2(50);
    l_count_distr               number;
    l_item_id                   number;
    l_line_num                  number;
    l_organization_code         varchar2(50);
    l_closed_code               varchar2(50);
    l_cancel_flag               varchar2(50);
    l_shipment_num              varchar2(50);
    l_shipment_header_id        number;
    --
    l_request_id                number;
    l_phase                     varchar2(20);
    l_wait_status               varchar2(20);
    l_dev_phase                 varchar2(20);
    l_dev_status                varchar2(20);
    l_message                   varchar2(3000);
    --
    
    i                           number;
    j                           number;
    k                           number;
    l_user_name                 varchar2(50);
    --
    l_locator_id                number;
    l_subinv_code               varchar2(30);
    l_locator_code              varchar2(30);
    l_lot_number                varchar2(30);
    l_exp_date                  date;
    
  begin
    if (p_escopo is not null) then 
      g_escopo := p_escopo;
    else
      g_escopo := upper(g_escopo)||'_'||p_organization_id||'.'||p_operation_id;
    end if;
    print_log('============================================================================');
    print_log('INICIO DO PROCESSO - REC/DEV FISICO '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS')  );
    print_log('============================================================================');   
    print_log('Organization_id           :'||p_organization_id);
    print_log('Operation_id   (Devolucao):'||p_operation_id);
    print_log('Operation_id   (Entrada)  :'||p_dev_operation_id);
  
    select user_name into l_user_name 
    from fnd_user 
    where user_id = fnd_profile.value('USER_ID')
    ;
    print_log('Usuario Logado:'||l_user_name );
    print_log('');
    
    i:=0;
    ok:= true;
    x_retorno := 'S';
    
    -- TRANSACTIONS
    -- ** RECEIVE / RETURN TO RECEIVING
    if (ok) then
      j :=0; k :=0;
      print_log('');
      print_log('  RCV_TRANSACTIONS_INTERFACE(RECEIVE / RETURN TO RECEIVING)...');
      for r2 in c2(nvl(p_dev_operation_id, p_operation_id), p_organization_id) loop
        print_log('  Invoice_num             :'||r2.waybill_airbill_num);
        print_log('  Po_line_location_id     :'||r2.po_line_location_id);
        -- Resgatando informações da PO
        begin
          select 
            cfi.invoice_id,
            cfi.invoice_date,
            ph.po_header_id, 
            pl.po_line_id,
            pl.line_num,
            pll.line_location_id, 
            --cfil.item_id, cfil.quantity, 
            pl.item_id,  pll.quantity,
            cfil.description,
            --
            pll.quantity_received, 
            pll.unit_meas_lookup_code, 
            --
            pll.ship_to_location_id, 
            pll.approved_flag,
            mp.organization_code,
            pll.closed_code,
            pll.cancel_flag,
            pll.shipment_num,
            pll.ship_to_location_id
          into
            l_invoice_id,
            l_transaction_date,
            l_po_header_id, 
            l_po_line_id,
            l_line_num,
            l_line_location_id, 
            l_item_id,
            l_po_quantity, 
            l_description,
            l_quantity_received, 
            l_unit_meas_lookup_code, 
            l_ship_to_location_id, 
            l_approved_flag,
            l_organization_code,
            l_closed_code,
            l_cancel_flag,
            l_shipment_num,
            l_ship_to_location_id
          from
            cll_f189_invoices              cfi,
            cll_f189_invoice_lines         cfil,
            cll_f189_fiscal_entities_all   cffea,
            po_headers_all                 ph,
            po_lines_all                   pl,
            po_line_locations_all          pll,
            mtl_parameters                 mp
          where 1=1
            and cfil.invoice_id       = cfi.invoice_id
            and cffea.entity_id       = cfi.entity_id
            and cfil.line_location_id = pll.line_location_id
            and cffea.vendor_site_id  = ph.vendor_site_id 
            --and pll.closed_code       in ('APPROVED', 'OPEN')
            and ph.po_header_id       = pll.po_header_id
            and ph.po_header_id       = pl.po_header_id
            and pl.po_line_id         = pll.po_line_id
            --
            and pll.ship_to_organization_id = mp.organization_id
            --
            and pll.line_location_id  = r2.po_line_location_id
            and cfi.organization_id   = p_organization_id
            and cfi.operation_id      = p_operation_id
          ;
        exception
          when others then
            x_retorno := 'Erro ao resgatar informacoes da PO:'|| sqlerrm;
            print_log('  ** '||x_retorno);
            ok := false;
        end;
        --
        if (ok) then
          l_interface_source_code     := 'CLL';
          l_transaction_type          := 'SHIP';
          l_processing_status_code    := 'PENDING';
          l_processing_mode_code      := 'BATCH';
          l_transaction_status_code   := 'PENDING';
          l_validation_flag           := 'Y';
          l_count_distr               := 1;
          --
          select l.quantity into l_quantity 
          from 
            cll_f189_invoices     i,
            cll_f189_invoice_lines l
          where 1=1 
          and i.operation_id    = p_operation_id 
          and i.organization_id = p_organization_id
          and i.invoice_id      = l.invoice_id;
          
          print_log('  Status                  :'||l_closed_code);
          print_log('  Item_id                 :'||l_item_id);
          print_log('  Descricao do Item       :'||l_description);
          print_log('  Quantity Entrada        :'||r2.cll_quantity);
          print_log('  Quantity Devolucao      :'||l_quantity);
          print_log('  PO Quantity             :'||l_po_quantity);
          print_log('  Quantity_received       :'||l_quantity_received);
          print_log('  Cancel_flag             :'||nvl(l_cancel_flag, 'N'));
          --      
          if (l_closed_code in ('APPROVED', 'OPEN') and l_quantity_received < l_po_quantity and nvl(l_cancel_flag, 'N') = 'N') then
            j:=j+1;
            select rcv_transactions_interface_s.nextval into l_interface_transaction_id from dual;
            --
            v_rcv_trx                          := null;
            --
            v_rcv_trx.transaction_type         := 'RETURN TO RECEIVING';
            v_rcv_trx.auto_transact_code       := 'RETURN TO RECEIVING';
            --
            select rcv_interface_groups_s.nextval  into l_group_id from dual;
            --v_rcv_trx.from_subinventory        := 'GER';
            begin                
              select ril.shipment_header_id into v_rcv_trx.header_interface_id
              from 
                cll_f189_invoices       ri,
                cll_f189_invoice_lines  ril
              where 1=1
                and ril.invoice_id          = ri.invoice_id
                and ri.operation_id         = p_dev_operation_id
                and ri.organization_id      = p_organization_id
              ;
              v_rcv_trx.header_interface_id := null;
              --
              select rt.TRANSACTION_ID
              into v_rcv_trx.parent_transaction_id
              from 
                rcv_transactions     rt,
                PO_DISTRIBUTIONS_ALL pd
              where 1=1
                and rt.TRANSACTION_TYPE    = 'RECEIVE'
                and rt.PO_DISTRIBUTION_ID  = pd.PO_DISTRIBUTION_ID 
                and rt.po_line_location_id = pd.line_location_id 
                and rt.po_line_location_id = r2.po_line_location_id 
              ;
            exception when others then
              print_log('  **ERRO :'||sqlerrm);
            end;
            --
            print_log('  Interface_Transaction_Id:'||l_interface_transaction_id);
            print_log('  Group_id                :'||l_group_id);
            print_log('  Transaction Type        :'||v_rcv_trx.transaction_type);
            --
            v_rcv_trx.interface_transaction_id := l_interface_transaction_id;
            v_rcv_trx.group_id                 := l_group_id;
            v_rcv_trx.last_update_date         := sysdate;
            v_rcv_trx.last_updated_by          := fnd_profile.value('USER_ID');
            v_rcv_trx.creation_date            := sysdate;
            v_rcv_trx.created_by               := fnd_profile.value('USER_ID');
            v_rcv_trx.last_update_login        := 0;
            --
            v_rcv_trx.transaction_date         := sysdate;
            --
            v_rcv_trx.processing_status_code   := 'PENDING';
            v_rcv_trx.processing_mode_code     := 'BATCH';
            v_rcv_trx.transaction_status_code  := 'PENDING';
            v_rcv_trx.po_header_id             := l_po_header_id;           -- TABELA DO PO
            v_rcv_trx.po_line_id               := l_po_line_id;             -- TABELA DO PO
            v_rcv_trx.item_id                  := l_item_id;                -- LINHA DO RI
            v_rcv_trx.quantity                 := l_quantity;               -- VIR DA LINHA DO RI
            v_rcv_trx.unit_of_measure          := l_unit_meas_lookup_code;  -- LINHA DO RI
            v_rcv_trx.po_line_location_id      := r2.po_line_location_id;   -- VIR DA LINHA DO RI

            v_rcv_trx.receipt_source_code      := 'VENDOR';
            v_rcv_trx.to_organization_code     := l_organization_code;      -- CABEÇALHO DO RI
            v_rcv_trx.source_document_code     := 'PO'; -- ????
            --
            v_rcv_trx.validation_flag          := 'Y';
            --
            if (ok) then
              print_log('  Inserindo na RCV_TRANSACTIONS_INTERFACE');
              insert into rcv_transactions_interface values v_rcv_trx;
              commit;
              k:=k+1;
            end if;
          else
            print_log('  ** Po_line_location_id ' || r2.po_line_location_id || ' Item_id ' ||l_item_id || ' ja recebido/fechado)');
          end if;
  
        end if;
      end loop;
      --
      print_log('');
      if (j=0) then
        x_retorno := 'Itens ja recebidos/fechado !!!';
        print_log('  ** '||x_retorno);
        ok:=false;
      elsif (k=0) then
        x_retorno := 'Nenhuma linha inserida na TRANSACTION !!!';
        print_log('  ** '||x_retorno);
        ok:=false;
      else
        print_log('  Qtd de Linhas          :'||k);
      end if;
      print_log('  FIM RCV_TRANSACTIONS_INTERFACE(RECEIVE / RETURN TO RECEIVING)');
    END if;
    -- PROCESSAMENTO 1
    if (ok) then
      commit;
      print_log('');
      print_log('  Caregando a Interface. Iniciando Concurrent RVCTP...');
      print_log('  Processador da Transação de Recebimento');
      l_request_id := fnd_request.submit_request(
        application => 'PO',
        program     => 'RVCTP',
        description => null,
        start_time  => sysdate,
        sub_request => false,
        argument1   => 'BATCH',
        argument2   => l_group_id
      );
      commit;
      print_log('  Request Id              :' || l_request_id);
      
      ok := fnd_concurrent.wait_for_request(
        request_id => l_request_id,
        interval   => 5,
        max_wait   => 1200,
        phase      => l_phase,
        status     => l_wait_status,
        dev_phase  => l_dev_phase,
        dev_status => l_dev_status,
        message    => l_message
      );
      print_log('  Fase do Concurrent      :' || l_dev_phase);
      print_log('  Status do Concurrent    :' || l_dev_status);
      print_log('  Mensagem                :' || l_message);
      
      if (l_dev_status = 'NORMAL') then
        i:=0;
        for e1 in (
          select INTERFACE_TRANSACTION_ID, COLUMN_NAME, ERROR_MESSAGE 
          from po_interface_errors 
          where 1=1
            and request_id = l_request_id
        ) loop
          i:=i+1;
          print_log('  ERRO: Coluna:'||e1.COLUMN_NAME||' - '||e1.error_message);
          x_retorno := 'E';
          
          XXFR_RI_PCK_INT_DEV_WORK.g_rec_retorno."registros"(1)."mensagens"(i)."tipoMensagem" := 'ERRO';
          XXFR_RI_PCK_INT_DEV_WORK.g_rec_retorno."registros"(1)."mensagens"(i)."mensagem"     := e1.error_message;
          
          ok:=false;
        end loop;
      else
        ok:=false;
        GOTO FIM;
      end if;
    else
      ok:=false;
      goto FIM;
    end if;

    -- ** DELIVER / RETURN TO VENDOR
    if (ok) then   
      i:=0; j:=0; k:=0;
      print_log('');
      print_log('  RCV_TRANSACTIONS_INTERFACE(DELIVER / RETURN TO VENDOR)...');
      for r1 in c1(nvl(p_dev_operation_id, p_operation_id), p_organization_id) loop
        i:=i+1;   
        print_log('  Group_id                :'||l_group_id);
        print_log('  Transaction Type        :'||v_rcv_trx.transaction_type);
        select rcv_transactions_interface_s.nextval into l_interface_transaction_id from dual;
        print_log('  Transaction_interface_id:'||l_interface_transaction_id);
          
        for r3 in c3(p_dev_operation_id, p_operation_id, v_rcv_trx.transaction_type) loop
          j:=j+1;
          print_log('  Po_line_location_id     :'||r3.line_location_id);
          print_log('  Ship_to_Organization_id :'||r3.ship_to_organization_id);
          print_log('  Shipment_header_id      :'||r3.shipment_header_id);
          print_log('  Item_id                 :'||r3.item_id);
          l_shipment_header_id := r3.shipment_header_id;
          --Resgatando informações do Lote
          /*
          begin  
            l_locator_id    := null;            
            l_subinv_code   := 'GER';
            --l_locator_code  := 'TRT.00.000.00';
            --l_lot_number    := 'L_TESTE';
            l_exp_date      := sysdate + 200;
            select mil.inventory_location_id into l_locator_id
            from mtl_item_locations_kfv mil
            where 1=1
              and mil.organization_id       = r3.ship_to_organization_id
              and mil.concatenated_segments = l_locator_code
            ;
          exception when others then
            print_log('  ** Erro ao buscar dados do local de estoque');
          end;
          */
        
          v_rcv_trx                          := NULL;
          v_rcv_trx.interface_transaction_id := l_interface_transaction_id;
          v_rcv_trx.GROUP_ID                 := l_group_id2;
          v_rcv_trx.transaction_date         := sysdate;
          v_rcv_trx.processing_status_code   := 'PENDING';
          v_rcv_trx.processing_mode_code     := 'BATCH';
          v_rcv_trx.transaction_status_code  := 'PENDING';
          v_rcv_trx.quantity                 := r3.quantity;
          v_rcv_trx.unit_of_measure          := r3.unit_of_measure;
          v_rcv_trx.item_id                  := r3.item_id;
          v_rcv_trx.employee_id              := r3.employee_id;
          v_rcv_trx.ship_to_location_id      := r3.ship_to_location_id;
          --
          v_rcv_trx.transaction_type         := 'RETURN TO VENDOR';
          v_rcv_trx.receipt_source_code      := 'VENDOR';
          v_rcv_trx.auto_transact_code       := 'RETURN TO VENDOR';
          begin                
            select rt.TRANSACTION_ID 
            into v_rcv_trx.parent_transaction_id
            from 
              rcv_transactions     rt,
              PO_DISTRIBUTIONS_ALL pd
            where 1=1
              and rt.TRANSACTION_TYPE    = 'DELIVER'
              and rt.PO_DISTRIBUTION_ID  = pd.PO_DISTRIBUTION_ID 
              and rt.po_line_location_id = pd.line_location_id 
              and rt.po_line_location_id = r3.line_location_id 
            ;
          exception when others then
            null;
          end;
          --
          v_rcv_trx.vendor_id                := r3.vendor_id;
          v_rcv_trx.source_document_code     := 'PO';
          v_rcv_trx.po_header_id             := r3.po_header_id;
          v_rcv_trx.po_line_id               := r3.po_line_id;
          v_rcv_trx.po_line_location_id      := r3.line_location_id;
          v_rcv_trx.destination_type_code    := 'INVENTORY';
          v_rcv_trx.inspection_status_code   := 'NOT INSPECTED';
          v_rcv_trx.routing_header_id        := 1;
          v_rcv_trx.deliver_to_person_id     := r3.employee_id;
          v_rcv_trx.location_id              := r3.ship_to_location_id;
          v_rcv_trx.deliver_to_location_id   := r3.ship_to_location_id;
          v_rcv_trx.document_num             := r3.segment1;
          v_rcv_trx.to_organization_id       := r3.ship_to_organization_id;
          v_rcv_trx.validation_flag          := 'Y';
          v_rcv_trx.shipment_header_id       := r3.shipment_header_id;
          v_rcv_trx.shipment_line_id         := r3.shipment_line_id;
          v_rcv_trx.subinventory             := l_subinv_code;
          v_rcv_trx.locator_id               := l_locator_id;
          v_rcv_trx.last_update_date         := sysdate;
          v_rcv_trx.last_updated_by          := fnd_profile.value('USER_ID');
          v_rcv_trx.creation_date            := sysdate;
          v_rcv_trx.created_by               := fnd_profile.value('USER_ID');
          v_rcv_trx.last_update_login        := 0;
          if (ok) then
            insert into rcv_transactions_interface values v_rcv_trx;
            k:=k+1;
          end if;
          print_log('FIM RCV_TRANSACTIONS_INTERFACE(DELIVER / RETURN TO VENDOR)');
        end loop;
        print_log('');
        if (j=0) then
          x_retorno := 'Itens ja recebidos/fechado !!!';
          print_log('  ** '||x_retorno);
          ok:=false;
        elsif (k=0) then
          x_retorno := 'Nenhuma linha inserida na TRANSACTION !!!';
          print_log('  ** '||x_retorno);
          ok:=false;
        else
          print_log('  Qtd de Linhas          :'||k);
        end if;
      end loop;
      --
    end if;
    -- PROCESSAMENTO 2
    if (ok) then
      commit;
      print_log('');
      print_log('Caregando a Interface. Iniciando Concurrent RVCTP...');
      print_log('Processador da Transação de Recebimento');
      l_request_id := fnd_request.submit_request(
        application => 'PO',
        program     => 'RVCTP',
        description => null,
        start_time  => sysdate,
        sub_request => false,
        argument1   => 'BATCH',
        argument2   => l_group_id2
      );
      commit;
      print_log('Request Id              :' || l_request_id);
      ok := fnd_concurrent.wait_for_request(
        request_id => l_request_id,
        interval   => 5,
        max_wait   => 1200,
        phase      => l_phase,
        status     => l_wait_status,
        dev_phase  => l_dev_phase,
        dev_status => l_dev_status,
        message    => l_message
      );
      commit;
      print_log('Fase do Concurrent      :' || l_dev_phase);
      print_log('Status do Concurrent    :' || l_dev_status);
      print_log('Mensagem                :' || l_message);
      --
      if (l_dev_status = 'NORMAL') then
        begin
          select decode( count(*), 0, 'SUCCESS', 'ERROR') STATUS into l_processing_status_code
          from po_interface_errors 
          where 1=1
            and request_id = l_request_id
          ;
        exception when others then
          print_log('** Erro ao resgatar PO_INTERFACE_ERRORS:'||sqlerrm);
        end;
        print_log('Status do processamento :' || l_processing_status_code);
        if (l_processing_status_code = 'ERROR') then
          ok:=false;
          for re in (
            select 
              batch_id, interface_header_id, interface_line_id, interface_transaction_id, 
              table_name, error_message_name, column_name, error_message
            from po_interface_errors 
            where 1=1
              --and interface_type = 'RCV-856'
              and request_id          = l_request_id
              --and interface_header_id = l_header_interface_id
          ) loop
            ok:=false;
            print_log('Tipo Erro:'||re.ERROR_MESSAGE_NAME||' - Coluna:'||re.COLUMN_NAME);
          end loop;
          x_retorno := 'Erro: Verficar mensagens da Interface de Erros';
        end if;
      else
        ok:=false;
      end if;
    end if;
    --
    <<FIM>>
    
    print_log('============================================================================');
    print_log('FIM DO PROCESSO - RECEBIMENTO/DEVOLUCAO FISICO '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS')  );
    print_log('============================================================================');
    
  end;

end XXFR_RI_PCK_INT_DEV_FISICO;
/
