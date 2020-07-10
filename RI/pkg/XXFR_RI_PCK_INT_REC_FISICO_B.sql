create or replace package body XXFR_RI_PCK_INT_REC_FISICO as

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

  cursor c3(pc_group_id in number) is
    select 
      group_id,
      rt.transaction_id,
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
      plla.ship_to_organization_id,
      rt.shipment_header_id,
      rt.shipment_line_id
    from 
      rcv_transactions      rt,
      po_lines_all          pla,
      po_line_locations_all plla,
      po_headers_all        pha
    where 1=1
      and rt.transaction_type = 'RECEIVE'
      and rt.po_line_id       = pla.po_line_id
      and pla.po_line_id      = plla.po_line_id
      and rt.po_header_id     = pha.po_header_id
      --
      and group_id            = pc_group_id
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
    p_operation_id    in number,
    p_organization_id in number,
    p_escopo          in varchar2 default null,
    x_retorno         out varchar2
  ) is
  begin
    if (p_escopo is not null) then 
      g_escopo := p_escopo;
    else
      g_escopo := upper(g_escopo)||'_'||p_organization_id||'.'||p_operation_id;
    end if;
    insert_rcv_tables(
      p_operation_id    => p_operation_id, 
      p_organization_id => p_organization_id,
      p_process_flag    => true,   
      p_fase            => null,
      p_group_id        => null,
      x_retorno         => x_retorno
    );
  end;

  procedure insert_rcv_tables(
    p_operation_id    in number,
    p_organization_id in number,
    p_process_flag    in boolean,   
    p_fase            in varchar2,
    p_group_id        in number,
    x_retorno         out varchar2
  ) is 
  
    v_rcv_header      rcv_headers_interface%rowtype;
    v_rcv_trx         rcv_transactions_interface%rowtype;
    v_mtl_lot         mtl_transaction_lots_interface%rowtype;
  
    l_header_interface_id   number;
    l_group_id              number;
    l_group_id2             number;
    
    l_invoice_id            number;
    l_line_location_id      number;
    l_po_header_id          number;
    l_po_line_id            number;
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
    print_log('============================================================================');
    print_log('INICIO DO PROCESSO - RECEBIMENTO FISICO '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS')  );
    print_log('============================================================================');
    --xxfr_pck_variaveis_ambiente.inicializar('CLL','UO_FRISIA'); --,'DANIEL.PIMENTA');
    
    g_operation_id    := p_operation_id; 
    g_organization_id := p_organization_id;
    
    select user_name into l_user_name 
    from fnd_user 
    where user_id = fnd_profile.value('USER_ID')
    ;
    print_log('Usuario pra culpar     :'||l_user_name );
    print_log('');
    
    i:=0;
    ok:= true;
    x_retorno := 'S';
    -- **************************************************************************************************************
    -- ***********  RECEIVE
    if (nvl(p_fase,'1') = '1') then
      for r1 in c1(p_operation_id, p_organization_id) loop
        print_log('RCV_HEADERS_INTERFACE...');
        -- Resgata o Status Code
        begin
          print_log('Shipment_num            :'||r1.shipment_num);
          print_log('Ship_to_organization_id :'||r1.ship_to_organization_id);
          select distinct
            processing_status_code,
            header_interface_id
          into
            l_processing_status_code,
            l_header_interface_id
          from
            rcv_headers_interface
          where 1=1
            and shipment_num            = r1.shipment_num
            and ship_to_organization_id = r1.ship_to_organization_id
            --and asn_type = 'ASN'
          ;
        exception
          when no_data_found then
            l_processing_status_code   := null;
            l_header_interface_id      := null;
        end;
        --
        if (l_processing_status_code = 'ERROR') then
          begin
            print_log('Limpando RCV_HEADERS_INTERFACE...');
            delete from rcv_headers_interface
            where header_interface_id = l_header_interface_id;
          exception
            when others then
              ok:=false;
              print_log('** Erro ao limpar RCV_HEADERS_INTERFACE: ' || sqlerrm);
          end;
          begin
            print_log('Limpando RCV_TRANSACTIONS_INTERFACE...');
            delete from rcv_transactions_interface
            where header_interface_id = l_header_interface_id;
          exception
            when others then
              ok:=false;
              print_log('** Erro ao limpar RCV_TRANSACTIONS_INTERFACE: ' || sqlerrm);
          end;
          print_log('');
        end if;
      
        i:=i+1;
        print_log('Invoice_id              :'||r1.invoice_id);
        print_log('Vendor_id               :'||r1.vendor_id);
        print_log('Vendor_site_id          :'||r1.vendor_site_id);
        select rcv_headers_interface_s.nextval into l_header_interface_id from dual;
        select rcv_interface_groups_s.nextval  into l_group_id from dual;
        print_log('Header_interface_id     :' || l_header_interface_id);
        print_log('Group_id                :' || l_group_id);
  
        v_rcv_header                        := null;
        v_rcv_header.header_interface_id    := l_header_interface_id;
        v_rcv_header.group_id               := l_group_id;
        v_rcv_header.processing_status_code := 'PENDING';
        v_rcv_header.receipt_source_code    := 'VENDOR';
        v_rcv_header.transaction_type       := 'NEW';
        v_rcv_header.auto_transact_code     := 'SHIP';
        
        v_rcv_header.asn_type               := null; --'ASN';
        v_rcv_header.ship_to_organization_id:= null; --r1.ship_to_organization_id;
        v_rcv_header.shipment_num           := r1.shipment_num;
        v_rcv_header.shipped_date           := null; --r1.shipped_date;
        v_rcv_header.expected_receipt_date  := null; --sysdate;
        --
        v_rcv_header.creation_date          := sysdate;
        v_rcv_header.created_by             := fnd_profile.value('USER_ID');
        --
        v_rcv_header.last_update_date       := sysdate;
        v_rcv_header.last_updated_by        := fnd_profile.value('USER_ID');
        v_rcv_header.last_update_login      := fnd_profile.value('USER_ID');
        --
        v_rcv_header.vendor_id              := r1.vendor_id;
        v_rcv_header.validation_flag        := 'Y';
        --
        insert into rcv_headers_interface values v_rcv_header;    
        --
        j :=0;
        k :=0;
        for r2 in c2(p_operation_id, p_organization_id) loop
          print_log('');
          print_log('  RCV_TRANSACTIONS_INTERFACE(RECEIVE)...');
          print_log('  Invoice_num             :'||r2.waybill_airbill_num);
          print_log('  Po_line_location_id     :'||r2.po_line_location_id);
          
          -- Resgatando informações da PO
          begin
            select 
              cfi.invoice_id,
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
              l_po_header_id, 
              l_po_line_id,
              l_line_num,
              l_line_location_id, 
              l_item_id,
              l_quantity, 
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
              
              and pll.ship_to_organization_id = mp.organization_id
              --
              and pll.line_location_id  = r2.po_line_location_id
              and cfi.invoice_id        = r1.invoice_id
            ;
          exception
            when others then
              x_retorno := 'Erro ao resgatar informacoes da PO:'|| sqlerrm;
              print_log('  ** '||x_retorno);
              ok := false;
          end;
          
          if (ok) then
            l_interface_source_code     := 'CLL';
            l_transaction_type          := 'SHIP';
            l_processing_status_code    := 'PENDING';
            l_processing_mode_code      := 'BATCH';
            l_transaction_status_code   := 'PENDING';
            l_receipt_source_code       := 'VENDOR';
            l_validation_flag           := 'Y';
            l_count_distr               := 1;
            --
            print_log('  Status                  :'||l_closed_code);
            print_log('  Item_id                 :'||l_item_id);
            print_log('  Descricao do Item       :'||l_description);
            print_log('  Cll Quantity            :'||r2.cll_quantity);
            print_log('  PO Quantity             :'||l_quantity);
            print_log('  Quantity_received       :'||l_quantity_received);
            print_log('  Cancel_flag             :'||nvl(l_cancel_flag, 'N'));
            --      
            if (l_closed_code in ('APPROVED', 'OPEN') and l_quantity_received < l_quantity and nvl(l_cancel_flag, 'N') = 'N') then
              j:=j+1;
              select rcv_transactions_interface_s.nextval into l_interface_transaction_id from dual;
              print_log('  Transaction_interface_id:'||l_interface_transaction_id);
              --
              v_rcv_trx                          := null;
              v_rcv_trx.interface_transaction_id := l_interface_transaction_id;
              v_rcv_trx.group_id                 := l_group_id;
              v_rcv_trx.last_update_date         := sysdate;
              v_rcv_trx.last_updated_by          := fnd_profile.value('USER_ID');
              v_rcv_trx.creation_date            := sysdate;
              v_rcv_trx.created_by               := fnd_profile.value('USER_ID');
              v_rcv_trx.last_update_login        := 0;
              v_rcv_trx.transaction_type         := 'RECEIVE';
              v_rcv_trx.transaction_date         := r1.TRANSACTION_DATE; --sysdate;
              v_rcv_trx.processing_status_code   := 'PENDING';
              v_rcv_trx.processing_mode_code     := 'BATCH';
              v_rcv_trx.transaction_status_code  := 'PENDING';
              v_rcv_trx.po_header_id             := l_po_header_id; -- TABELA DO PO
              v_rcv_trx.po_line_id               := l_po_line_id; -- TABELA DO PO
              v_rcv_trx.item_id                  := l_item_id; -- LINHA DO RI
              v_rcv_trx.quantity                 := r2.cll_quantity; -- VIR DA LINHA DO RI
              v_rcv_trx.unit_of_measure          := l_unit_meas_lookup_code; -- LINHA DO RI
              v_rcv_trx.po_line_location_id      := r2.po_line_location_id; -- VIR DA LINHA DO RI
              v_rcv_trx.auto_transact_code       := 'RECEIVE';
              v_rcv_trx.receipt_source_code      := 'VENDOR';
              v_rcv_trx.to_organization_code     := l_organization_code; -- CABEÇALHO DO RI
              v_rcv_trx.source_document_code     := 'PO'; -- ????
              v_rcv_trx.header_interface_id      := rcv_headers_interface_s.currval;
              v_rcv_trx.validation_flag          := 'Y';
              --
              if (ok) then
                insert into rcv_transactions_interface values v_rcv_trx;
                k:=k+1;
              end if;
            else
              print_log('  ** Po_line_location_id ' || r2.po_line_location_id || ' Item_id ' ||l_item_id || ' ja recebido/fechado)');
            end if;
    
          end if;
          print_log('  FIM RCV_TRANSACTIONS_INTERFACE(RECEIVE)');
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
        print_log('FIM RCV_HEADERS_INTERFACE');
      end loop;
      --
      if (i=0) then
        x_retorno := 'Nenhum Recebimento encontrado !!!';
        print_log('  ** '||x_retorno);
        ok:=false;
      end if;
      -- PROCESSAMENTO DA INTERFACE RECEIVE...
      if (ok and p_process_flag) then
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
          argument2   => l_group_id
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
        print_log('Fase do Concurrent      :' || l_dev_phase);
        print_log('Status do Concurrent    :' || l_dev_status);
        print_log('Mensagem                :' || l_message);
        
        if (l_dev_status = 'NORMAL') then
        
          select PROCESSING_STATUS_CODE into l_processing_status_code
          from rcv_headers_interface 
          where Header_interface_id = l_header_interface_id
          ;
          print_log('Status do processamento :' || l_processing_status_code);
          if (l_processing_status_code = 'ERROR') then
            ok:=false;
            for re in (
              select 
                batch_id, interface_header_id, interface_line_id, interface_transaction_id, 
                table_name, error_message_name, column_name, error_message
              from po_interface_errors 
              where 1=1
                and interface_type = 'RCV-856'
                and interface_header_id = l_header_interface_id
            ) loop
              
              print_log('Tipo Erro:'||re.ERROR_MESSAGE_NAME||' - Coluna:'||re.COLUMN_NAME);
            end loop;
            x_retorno := 'Erro: Verficar mensagens da Interface de Erros';
          else
            commit;
          end if;
        else
          ok:=false;
        end if;
        
      end if;
    end if; 

    -- **************************************************************************************************************
    -- ***********  DELIVER 
    if (nvl(p_fase,'2') = '2') then   
      i:=0;
      j:=0;
      k:=0;
      l_group_id := nvl(p_group_id,l_group_id);
      for r1 in c1(p_operation_id, p_organization_id) loop
        i:=i+1;
        select rcv_interface_groups_s.nextval  into l_group_id2 from dual;
        for r3 in c3(l_group_id) loop
          j:=j+1;
          print_log('');
          print_log('  RCV_TRANSACTIONS_INTERFACE(DELIVER)...');
          print_log('  Po_line_location_id     :'||r3.line_location_id);
          print_log('  Ship_to_Organization_id :'||r3.ship_to_organization_id);
          print_log('  Shipment_header_id      :'||r3.shipment_header_id);
          print_log('  Item_id                 :'||r3.item_id);
          l_shipment_header_id := r3.shipment_header_id;
          --Resgatando informações do Lote
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
        
          select rcv_transactions_interface_s.nextval into l_interface_transaction_id from dual;
          print_log('  Transaction_interface_id:'||l_interface_transaction_id);
        
          v_rcv_trx                          := NULL;
          v_rcv_trx.interface_transaction_id := l_interface_transaction_id;
          v_rcv_trx.GROUP_ID                 := l_group_id2;
          v_rcv_trx.parent_transaction_id    := r3.transaction_id;
          v_rcv_trx.transaction_type         := 'DELIVER';
          v_rcv_trx.transaction_date         := sysdate;
          v_rcv_trx.processing_status_code   := 'PENDING';
          v_rcv_trx.processing_mode_code     := 'BATCH';
          v_rcv_trx.transaction_status_code  := 'PENDING';
          v_rcv_trx.quantity                 := r3.quantity;
          v_rcv_trx.unit_of_measure          := r3.unit_of_measure;
          v_rcv_trx.item_id                  := r3.item_id;
          v_rcv_trx.employee_id              := r3.employee_id;
          v_rcv_trx.auto_transact_code       := 'DELIVER';
          v_rcv_trx.ship_to_location_id      := r3.ship_to_location_id;
          v_rcv_trx.receipt_source_code      := 'VENDOR';
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
          print_log('  FIM RCV_TRANSACTIONS_INTERFACE(DELIVER)');
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
      -- PROCESSAMENTO DA INTERFACE DELIVER...
      if (ok and p_process_flag) then
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
        if (l_dev_status = 'NORMAL') then
          select decode( count(*), 0, 'SUCCESS', 'ERROR') STATUS into l_processing_status_code
          from po_interface_errors 
          where 1=1
            and request_id = l_request_id
          ;
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
    end if;

    if (ok) then
      begin
        update cll_f189_invoice_lines 
        set 
          shipment_header_id = l_shipment_header_id,
          receipt_flag       = 'Y'
        where invoice_id = l_invoice_id
        ;
        x_retorno := 'S';
        commit;
      exception when others then
        x_retorno := 'Erro ao atualizar CLL_F189_INVOICE_LINES:'||sqlerrm;
      end;
    end if;

    print_log('============================================================================');
    print_log('FIM DO PROCESSO - RECEBIMENTO FISICO '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS')  );
    print_log('============================================================================');
  END;    
END XXFR_RI_PCK_INT_REC_FISICO;
/