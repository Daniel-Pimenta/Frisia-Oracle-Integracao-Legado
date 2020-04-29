create or replace package body xxfr_f189_wms_pkg as

  procedure print_log (
    msg in varchar2
  ) is
  begin
    dbms_output.put_line('  '||msg);
  end;

  procedure insert_rcv_tables (
    errbuf out nocopy varchar2,
    retcode out nocopy number,
    p_organization_id   in   number,
    p_operation_id      in   number
  ) is

    cursor c_rcv_headers (
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
      and cfeo.operation_id = cfi.operation_id
      and cfeo.organization_id = cfi.organization_id
      and cfi.entity_id = cfvv.entity_id
      and nvl(cfvv.inactive_date, sysdate + 1) > sysdate
      and cfeo.operation_id = pc_operation_id
      and cfeo.organization_id = pc_organization_id;

    cursor c_rcv_transactions (
      pc_operation_id      in varchar2,
      pc_organization_id   in number
    ) is
    select
      sum(cfil.quantity) quantity,
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
    --

    l_header_interface_id        number;
    l_group_id                   number;
    l_notice_creation_date       date;
    l_transaction_type           varchar2(50);
    l_processing_status_code     varchar2(50);
    l_receipt_source_code        varchar2(50);
    l_validation_flag            varchar2(50);
    l_auto_transact_code         varchar2(50);
    l_processing_mode_code       varchar2(50);
    l_transaction_status_code    varchar2(50);
    l_interface_transaction_id   number;
    l_interface_source_code      varchar2(50);
    l_req_id                     number;
    l_po_header_id               number;
    l_po_line_id                 number;
    l_po_release_id              number;
    l_po_distribution_id         number;
    l_release_num                number := null;
    l_call_status                boolean;
    l_req_phase                  varchar2(15);
    l_request_status             varchar2(30) := null;
    l_dev_request_status         varchar2(30) := null;
    l_dev_request_phase          varchar2(30) := null;
    l_request_status_mesg        varchar2(50) := null;
    -- 21/07/2009
    l_receiving_routing_id       po_line_locations.receiving_routing_id%type;
    l_pll_quantity               po_line_locations.quantity%type;
    l_count_distr                number;
    l_quantity                   number;
    l_sum_quantity               number;
    l_reg                        number;
    l_vendor_site_id_po          number;
    v_count_linhas               number;
    v_count_site_id              number;
    v_vendor_site_id_header      number;
    --
  begin
    print_log('XXFR_F189_WMS_PKG.INSERT_RCV_TABLES');

    for r_rcv_headers in c_rcv_headers(p_operation_id, p_organization_id) loop                                                                --A
      -- Resgata o Status Code
      begin
        select
          processing_status_code,
          header_interface_id
        into
          l_processing_status_code,
          l_header_interface_id
        from
          rcv_headers_interface
        where
          shipment_num = to_char(r_rcv_headers.shipment_num)
          and ship_to_organization_id = r_rcv_headers.ship_to_organization_id
          and asn_type = 'ASN';
      exception
        when no_data_found then
          l_processing_status_code   := null;
          l_header_interface_id      := null;
      end;
      --
      --Verifica existe um processo com erro
      if l_processing_status_code = 'ERROR' or l_processing_status_code is null then
        -- Limpa a Interface
        if l_processing_status_code = 'ERROR' then
          begin
            print_log('Limpando RCV_HEADERS_INTERFACE...');
            delete from rcv_headers_interface
            where header_interface_id = l_header_interface_id;
          exception
            when others then
              print_log('Error when deleting RCV_HEADERS_INTERFACE: ' || sqlerrm);
              raise_application_error(-20001, 'Error when deleting RCV_HEADERS_INTERFACE: ' || sqlerrm);
          end;
          begin
            print_log('Limpando RCV_TRANSACTIONS_INTERFACE...');
            delete from rcv_transactions_interface
            where header_interface_id = l_header_interface_id;
          exception
            when others then
              print_log('Error when deleting RCV_TRANSACTIONS_INTERFACE: ' || sqlerrm);
              raise_application_error(-20001, 'Error when deleting RCV_TRANSACTIONS_INTERFACE: ' || sqlerrm);
          end;
        end if;
        -- Inicio BUG 19031932
        begin
          select count(*)
          into v_count_site_id
          from
            cll_f189_invoices              cfi,
            cll_f189_invoice_lines         cfil,
            cll_f189_fiscal_entities_all   cffea,
            po_line_locations_all          pll,
            po_headers_all                 ph
          where 1=1
            and cfi.invoice_id        = r_rcv_headers.invoice_id
            and cfil.invoice_id       = cfi.invoice_id
            and cffea.entity_id       = cfi.entity_id
            and cfil.line_location_id = pll.line_location_id
            and pll.po_header_id      = ph.po_header_id
            and ph.vendor_site_id     = cffea.vendor_site_id;
        exception
          when others then
            print_log('Error when count VENDOR_SITE_ID: ' || sqlerrm);
            raise_application_error(-20001, 'Error when count VENDOR_SITE_ID: ' || sqlerrm);
        end;
        if (v_count_site_id >= 0) then
          begin
            select count(*)
            into v_count_linhas
            from cll_f189_invoice_lines cfil
            where cfil.invoice_id = r_rcv_headers.invoice_id;
          exception
            when others then
              print_log('Error when count Linhas Recebimento: ' || sqlerrm);
              raise_application_error(-20001, 'Error when count Linhas Recebimento: ' || sqlerrm);
          end;
          if v_count_linhas > 1 then
            v_vendor_site_id_header := null;
          else
            v_vendor_site_id_header := r_rcv_headers.vendor_site_id;
          end if;
        else
          v_vendor_site_id_header := r_rcv_headers.vendor_site_id;
        end if;
        -- Fim BUG 19031932
        --
        select rcv_headers_interface_s.nextval
        into l_header_interface_id
        from dual;
        --
        print_log('Header_Interface_id :'||l_header_interface_id);
        select rcv_interface_groups_s.nextval
        into l_group_id
        from dual;
        print_log('Header_Interface_id :'||l_header_interface_id);
        --
        l_notice_creation_date     := sysdate;
        l_transaction_type         := 'NEW';
        l_processing_status_code   := 'PENDING';
        l_receipt_source_code      := 'VENDOR';
        l_validation_flag          := 'Y';
        l_auto_transact_code       := 'SHIP';
        --Insere na RCV_HEADERS_INTERFACE
        begin
          print_log('Insere na RCV_HEADERS_INTERFACE...');
          insert into rcv_headers_interface (
            header_interface_id                          -- 1
            ,group_id                                     -- 2
            ,processing_status_code                       -- 3
            ,receipt_source_code                          -- 4
            ,transaction_type                             -- 5
            ,auto_transact_code                           -- 6
            ,ship_to_organization_id                      -- 7
            ,notice_creation_date                         -- 8
            ,vendor_id                                    -- 9
            ,vendor_site_id                               -- 10
            ,validation_flag                              -- 11
            ,shipped_date                                 -- 12
            ,shipment_num                                 -- 13
            ,asn_type                                     -- 14
            ,last_update_date                             -- 15
            ,last_updated_by                              -- 16
            ,creation_date                                -- 17
            ,created_by                                   -- 18
            ,last_update_login                            -- 19
          ) values (
            l_header_interface_id                        -- 1
            ,l_group_id                                   -- 2
            ,l_processing_status_code                     -- 3
            ,l_receipt_source_code                        -- 4
            ,l_transaction_type                           -- 5
            ,l_auto_transact_code                         -- 6
            ,r_rcv_headers.ship_to_organization_id        -- 7
            ,l_notice_creation_date                       -- 8
            ,r_rcv_headers.vendor_id                      -- 9
            ,v_vendor_site_id_header                      -- 10
            ,l_validation_flag                            -- 11
            ,r_rcv_headers.shipped_date                   -- 12
            ,to_char(r_rcv_headers.shipment_num)          -- 13
            ,'ASN'                                        -- 14
            ,sysdate                                      -- 15
            ,fnd_global.user_id                           -- 16
            ,sysdate                                      -- 17
            ,fnd_global.user_id                           -- 18
            ,fnd_global.login_id                          -- 19
          );
        exception
          when others then
            print_log('Error when Inserting on RCV_HEADERS_INTERFACE: ' || sqlerrm);
            ok := false;
        end;
        --
        print_log('Loop das transactions...');
        if (ok) then
          for r_rcv_transactions in c_rcv_transactions(pc_operation_id => p_operation_id, pc_organization_id => p_organization_id) loop                                                           --B
            --
            l_interface_source_code     := 'CLL';
            l_transaction_type          := 'SHIP';
            l_processing_status_code    := 'PENDING';
            l_processing_mode_code      := 'BATCH';
            l_transaction_status_code   := 'PENDING';
            l_receipt_source_code       := 'VENDOR';
            l_validation_flag           := 'Y';
            l_count_distr               := 1;
            -- Resgata as Informações da PO
            begin
              select
                pll.po_header_id,
                pll.po_line_id,
                pll.po_release_id,
                pd.po_distribution_id,
                (
                  select
                    pl.release_num
                  from
                    po_releases_all pl
                  where
                    pll.po_release_id = pl.po_release_id
                    and pl.po_header_id = ph.po_header_id
                ) release_num,
                ph.vendor_site_id -- BUG 19031932
              into
                l_po_header_id,
                l_po_line_id,
                l_po_release_id,
                l_po_distribution_id,
                l_release_num,
                l_vendor_site_id_po
              from
                po_line_locations   pll,
                po_headers          ph,
                po_distributions    pd
              where
                ph.po_header_id          = pll.po_header_id
                and ph.po_header_id      = pd.po_header_id
                and pll.line_location_id = pd.line_location_id
                and pll.po_line_id       = pd.po_line_id
                and pll.line_location_id = r_rcv_transactions.po_line_location_id;
            exception
              when too_many_rows then
                select
                  pll.receiving_routing_id,
                  pll.quantity
                into
                  l_receiving_routing_id,
                  l_pll_quantity
                from
                  po_line_locations pll
                where
                  pll.line_location_id = r_rcv_transactions.po_line_location_id
                ;
                if ( l_receiving_routing_id = 3 ) then
                  select count(*)
                  into l_count_distr
                  from po_distributions_all pll
                  where pll.line_location_id = r_rcv_transactions.po_line_location_id
                  ;
                end if;
                if ( l_receiving_routing_id <> 3 ) then
                  select
                    pll.po_header_id,
                    pll.po_line_id,
                    pll.po_release_id,
                    (
                      select
                        pl.release_num
                      from
                        po_releases_all pl
                      where
                        pll.po_release_id = pl.po_release_id
                        and pl.po_header_id = ph.po_header_id
                    ) release_num
                  into
                    l_po_header_id,
                    l_po_line_id,
                    l_po_release_id,
                    l_release_num
                  from
                    po_line_locations   pll,
                    po_headers          ph
                  where
                    ph.po_header_id = pll.po_header_id
                    and pll.line_location_id = r_rcv_transactions.po_line_location_id;
                  l_po_distribution_id := null;
                end if;                                     -- 21/07/2009
              when others then
                l_po_header_id         := null;
                l_po_line_id           := null;
                l_po_release_id        := null;
                l_release_num          := null;
                l_po_distribution_id   := null;
            end;
            --
            if ( l_count_distr > 1 ) then
              l_reg            := 0;
              l_sum_quantity   := 0;
              for x in (
                select
                  quantity_ordered,
                  po_distribution_id,
                  destination_subinventory
                from
                  po_distributions_all pd
                where
                  pd.line_location_id = r_rcv_transactions.po_line_location_id
              ) loop
                l_reg := l_reg + 1;
                if ( l_reg = l_count_distr ) then
                  l_quantity := r_rcv_transactions.quantity - l_sum_quantity;
                else
                  l_quantity := x.quantity_ordered / l_pll_quantity * r_rcv_transactions.quantity;
                end if;
                l_sum_quantity   := l_sum_quantity + l_quantity; -- sum of the quantities of distribution lines
                select rcv_transactions_interface_s.nextval
                into l_interface_transaction_id
                from dual;
                -- 
                print_log('  Insere na RCV_TRANSACTIONS_INTERFACE...');
                begin
                  insert into rcv_transactions_interface (
                    interface_transaction_id             -- 01
                    ,group_id                            -- 02
                    ,lpn_group_id                        -- 03
                    ,transaction_type                    -- 04
                    ,transaction_date                    -- 05
                    ,processing_status_code              -- 06
                    ,processing_mode_code                -- 07
                    ,transaction_status_code             -- 08
                    ,quantity                            -- 09
                    ,uom_code                            -- 10
                    ,ship_to_location_id                 -- 11
                    ,vendor_item_num                     -- 12
                    ,interface_source_code               -- 13
                    ,item_num                            -- 14
                    ,receipt_source_code                 -- 15
                    ,vendor_id                           -- 16
                    ,vendor_site_id                      -- 17
                    ,po_header_id                        -- 18
                    ,po_line_id                          -- 19
                    ,po_release_id                       -- 20
                    ,release_num                         -- 21
                    ,source_document_code                -- 22
                    ,po_distribution_id                  -- 23
                    ,po_line_location_id                 -- 24
                    ,header_interface_id                 -- 25
                    ,validation_flag                     -- 26
                    ,waybill_airbill_num                 -- 27
                    ,auto_transact_code                  -- 28
                    ,last_update_date                    -- 29
                    ,last_updated_by                     -- 30
                    ,creation_date                       -- 31
                    ,created_by                          -- 32
                    ,last_update_login                   -- 33
                    ,subinventory
                    ,from_subinventory
                  ) values (
                    l_interface_transaction_id           -- 01
                    ,l_group_id                          -- 02
                    ,l_group_id                          -- 03
                    ,l_transaction_type                  -- 04
                    ,r_rcv_headers.transaction_date      -- 05
                    ,l_processing_status_code            -- 06
                    ,l_processing_mode_code              -- 07
                    ,l_transaction_status_code           -- 08
                    ,l_quantity                          -- 09
                    ,r_rcv_transactions.uom              -- 10
                    ,r_rcv_headers.location_id           -- 11
                    ,null                                -- 12
                    ,l_interface_source_code             -- 13
                    ,null                                -- 14
                    ,l_receipt_source_code               -- 15
                    ,r_rcv_headers.vendor_id             -- 16
                    ,l_vendor_site_id_po                 -- 17
                    ,l_po_header_id                      -- 18
                    ,l_po_line_id                        -- 19
                    ,l_po_release_id                     -- 20
                    ,l_release_num                       -- 21
                    ,'PO'                                -- 22
                    ,x.po_distribution_id                -- 23
                    ,r_rcv_transactions.po_line_location_id -- 24
                    ,l_header_interface_id               -- 25
                    ,l_validation_flag                   -- 26
                    ,r_rcv_transactions.waybill_airbill_num -- 27
                    ,'SHIP'                              -- 28
                    ,sysdate                             -- 29
                    ,fnd_global.user_id                  -- 30
                    ,sysdate                             -- 31
                    ,fnd_global.user_id                  -- 32
                    ,fnd_global.login_id                 -- 33    
                    ,x.destination_subinventory
                    ,x.destination_subinventory
                  );
                exception
                  when others then
                    print_log('  Error when inserting on RCV_TRANSACTIONS_INTERFACE: ' || sqlerrm);
                    ok:=false;
                end;
              end loop;
            else 
              select rcv_transactions_interface_s.nextval
              into l_interface_transaction_id
              from dual;
              begin
                print_log('  Insere na RCV_TRANSACTIONS_INTERFACE...');
                insert into rcv_transactions_interface (
                  interface_transaction_id             -- 01
                  ,group_id                            -- 02
                  ,lpn_group_id                        -- 03
                  ,transaction_type                    -- 04
                  ,transaction_date                    -- 05
                  ,processing_status_code              -- 06
                  ,processing_mode_code                -- 07
                  ,transaction_status_code             -- 08
                  ,quantity                            -- 09
                  ,uom_code                            -- 10
                  ,ship_to_location_id                 -- 11
                  ,vendor_item_num                     -- 12
                  ,interface_source_code               -- 13
                  ,item_num                            -- 14
                  ,receipt_source_code                 -- 15
                  ,vendor_id                           -- 16
                  ,vendor_site_id                      -- 17
                  ,po_header_id                        -- 18
                  ,po_line_id                          -- 19
                  ,po_release_id                       -- 20
                  ,release_num                         -- 21
                  ,source_document_code                -- 22
                  ,po_distribution_id                  -- 23
                  ,po_line_location_id                 -- 24
                  ,header_interface_id                 -- 25
                  ,validation_flag                     -- 26
                  ,waybill_airbill_num                 -- 27
                  ,auto_transact_code                  -- 28
                  ,last_update_date                    -- 29
                  ,last_updated_by                     -- 30
                  ,creation_date                       -- 31
                  ,created_by                          -- 32
                  ,last_update_login                   -- 33
                  ,subinventory
                  ,from_subinventory
                ) values (
                  l_interface_transaction_id              -- 01
                  ,l_group_id                             -- 02
                  ,l_group_id                             -- 03
                  ,l_transaction_type                     -- 04
                  ,r_rcv_headers.transaction_date         -- 05
                  ,l_processing_status_code               -- 06
                  ,l_processing_mode_code                 -- 07
                  ,l_transaction_status_code              -- 08
                  ,r_rcv_transactions.quantity            -- 09
                  ,r_rcv_transactions.uom                 -- 10
                  ,r_rcv_headers.location_id              -- 11
                  ,null                                   -- 12
                  ,l_interface_source_code                -- 13
                  ,null                                   -- 14
                  ,l_receipt_source_code                  -- 15
                  ,r_rcv_headers.vendor_id                -- 16
                  ,l_vendor_site_id_po                    -- 17
                  ,l_po_header_id                         -- 18
                  ,l_po_line_id                           -- 19
                  ,l_po_release_id                        -- 20
                  ,l_release_num                          -- 21
                  ,'PO'                                   -- 22
                  ,l_po_distribution_id                   -- 23
                  ,r_rcv_transactions.po_line_location_id -- 24
                  ,l_header_interface_id                  -- 25
                  ,l_validation_flag                      -- 26
                  ,r_rcv_transactions.waybill_airbill_num -- 27
                  ,'SHIP'                                 -- 28
                  ,sysdate                                -- 29
                  ,fnd_global.user_id                     -- 30
                  ,sysdate                                -- 31
                  ,fnd_global.user_id                     -- 32
                  ,fnd_global.login_id                    -- 33
                );
              exception
                when others then
                  print_log('  Error when inserting on RCV_TRANSACTIONS_INTERFACE: ' || sqlerrm);
                  ok:=false;
              end;
            end if;
          end loop;                                                      
        end if;
      end if;
    end loop;                                                            
    --
    commit;
    --
    print_log('Chamando Concurrent RVCTP...');
    l_req_id := fnd_request.submit_request(
      application => 'PO',
      program     => 'RVCTP',
      description => null,
      start_time  => sysdate,
      sub_request => false,
      argument1   => 'BATCH',
      argument2   => l_group_id
    );

    print_log('Request Id:'||l_req_id);
    if ( l_req_id <= 0 or l_req_id is null ) then
      print_log('Error in the concurrent program Receiving Transaction Processor');
      raise_application_error(-20005, 'Error in the concurrent program Receiving Transaction Processor');
    else
      commit work;
      l_call_status := fnd_concurrent.wait_for_request(
        l_req_id, 
        10, 
        0, 
        l_req_phase, 
        l_request_status,
        l_dev_request_phase, 
        l_dev_request_status, 
        l_request_status_mesg
      );
    end if;
    print_log('Fase      :'||l_req_phase);
    print_log('Status    :'||l_request_status);
    print_log('Req Fase  :'||l_dev_request_phase); 
    print_log('Req Status:'||l_dev_request_status); 
    print_log('Mensagem  :'||l_request_status_mesg);
  exception
    when others then
      print_log('Erro:'||sqlerrm);
      raise_application_error(-20003, ' - Fatal Error : ' || sqlerrm);
      rollback;
  end insert_rcv_tables;

  procedure approve_receipt (
    errbuf out nocopy varchar2,
    retcode out nocopy number,
    p_organization_id   in   number,
    p_operation_id      in   number
  ) is
  --

    cursor c_recebimento_ri (
      pc_organization_id   in number,
      pc_operation_id      in varchar2
    ) is
    select distinct
      cfeo.organization_id,
      cfeo.operation_id,
      cfp.qty_rcv_tolerance,
      cfp.qty_rcv_exception_code
    from
      cll_f189_entry_operations   cfeo,
      cll_f189_parameters         cfp,
      mtl_parameters              mp,
      cll_f189_invoices           cfi,
      cll_f189_invoice_types      cfit
    where
      cfeo.operation_id = cfi.operation_id
      and cfeo.organization_id = cfi.organization_id
      and cfeo.organization_id = mp.organization_id
      and cfp.organization_id = mp.organization_id
      and cfi.invoice_type_id = cfit.invoice_type_id
      and cfi.organization_id = cfit.organization_id
      and cfeo.organization_id = cfp.organization_id
      and cfeo.status in (
        'PENDING ASSOCIATION',
        'PARTIAL ASSOCIATION'
      )
      and nvl(mp.wms_enabled_flag, 'N') = 'Y'
      and nvl(cfit.wms_flag, 'N') = 'Y'
      and cfeo.operation_id = nvl(pc_operation_id, cfeo.operation_id)
      and cfeo.organization_id = nvl(pc_organization_id, cfeo.organization_id)
    order by
      2;
  
  --

    cursor c_linhas_nff (
      pc_operation_id      in number,
      pc_organization_id   in number
    ) is
    select
      cfil.line_location_id, -- cfil.uom                     -- BUG 11832721
      muomt.uom_code uom                                   -- BUG 11832721
      ,
      cfil.item_id                                           -- BUG 11832721
      ,
      sum(cfil.quantity) quantity,
      cfil.invoice_id
    from
      cll_f189_invoices         cfi,
      cll_f189_invoice_lines    cfil,
      mtl_units_of_measure_tl   muomt                         -- BUG 11832721
    where
      cfi.invoice_id = cfil.invoice_id
      and cfi.operation_id = pc_operation_id
      and cfi.organization_id = pc_organization_id
      and muomt.unit_of_measure = cfil.uom                        -- BUG 11832721
      and muomt.language = userenv('LANG')                 -- BUG 11832721
      and ( muomt.disable_date is null
            or muomt.disable_date > sysdate )                                                       -- BUG 11832721
  --         GROUP BY cfil.line_location_id, cfil.uom, cfil.invoice_id;     -- BUG 11832721
    group by
      cfil.line_location_id,
      muomt.uom_code,
      cfil.item_id,
      cfil.invoice_id; -- BUG 11832721
  
  --

    l_qty_rcv         number;
    l_uom_rcv         varchar2(50);
    l_complete_nff    varchar2(1);
    l_req_id          number;
    l_lib_manual      varchar2(1);
    l_msg_release     varchar2(50);
    l_dif_qty         number;
    l_tolerance       number;
    l_exists_rec      varchar2(1);
    l_qtd_rec_fis     number := 0;
    l_qty_rec_tot     number := 0;
    l_qty_nff_lines   number := 0;
    l_rate            number := 0; -- BUG 11832721
    l_qty_upd         number := 0; -- BUG 11741529
  --
  begin
  --
    for r_recebimento_ri in c_recebimento_ri(p_organization_id, p_operation_id) loop
  --
      l_qtd_rec_fis     := 0;
      l_qty_rec_tot     := 0;
      l_qty_nff_lines   := 0;
      l_complete_nff    := null;
  --
      begin
  --
        select
          'Y'
        into l_lib_manual
        from
          cll_f189_manual_release
        where
          organization_id = r_recebimento_ri.organization_id
          and operation_id = r_recebimento_ri.operation_id;
  --

      exception
        when no_data_found then
          l_lib_manual := 'N';
  --
      end;
  
  --

      for r_linhas_nff in c_linhas_nff(r_recebimento_ri.operation_id, r_recebimento_ri.organization_id) loop
  --
        l_qty_nff_lines   := l_qty_nff_lines + 1;
        l_qty_upd         := 0; -- BUG 11741529
  --
        begin
  --
          select
            sum(rt.primary_quantity)
  --           rt.primary_unit_of_measure, 'Y'                       -- BUG 11832721

            muomt.uom_code,
            'Y'                                   -- BUG 11832721
          into
            l_qty_rcv,
            l_uom_rcv,
            l_exists_rec
          from
            rcv_shipment_headers      rcvsh,
            po_vendors                pov,
            rcv_transactions          rt,
            mtl_units_of_measure_tl   muomt                          -- BUG 11832721
          where
            rcvsh.vendor_id = pov.vendor_id
            and rcvsh.shipment_header_id = rt.shipment_header_id
            and rcvsh.ship_to_org_id = r_recebimento_ri.organization_id
            and rcvsh.shipment_num = to_char(r_recebimento_ri.operation_id)
            and rt.po_line_location_id = r_linhas_nff.line_location_id
            and rt.transaction_type = 'RECEIVE'
            and rcvsh.receipt_source_code = 'VENDOR'
            and rcvsh.asn_type = 'ASN'
            and muomt.unit_of_measure = rt.primary_unit_of_measure      -- BUG 11832721
            and muomt.language = userenv('LANG')                 -- BUG 11832721
            and ( muomt.disable_date is null
                  or muomt.disable_date > sysdate )                                                       -- BUG 11832721
  --               GROUP BY rt.primary_unit_of_measure;                           -- BUG 11832721
          group by
            muomt.uom_code;                                         -- BUG 11832721
  --

        exception
  --
          when no_data_found then
            l_exists_rec   := 'N';
            l_qty_rcv      := 0;
            l_uom_rcv      := null;
  --
        end;
  --

        inv_convert.inv_um_conversion(r_linhas_nff.uom, l_uom_rcv, r_linhas_nff.item_id, l_rate); -- BUG 11832721
  --
  --            l_dif_qty := ABS (NVL (r_linhas_nff.quantity, 0) - l_qty_rcv);                         -- BUG 11832721
        l_dif_qty         := abs((nvl(r_linhas_nff.quantity, 0) * l_rate) - l_qty_rcv);             -- BUG 11832721

        l_tolerance       :=
  --               ABS (  NVL (r_linhas_nff.quantity, 0)                                               -- BUG 11832721

         abs((nvl(r_linhas_nff.quantity, 0) * l_rate)                                    -- BUG 11832721

         * r_recebimento_ri.qty_rcv_tolerance / 100);
  
  --

        if l_exists_rec = 'Y' then
  --
          l_qtd_rec_fis := l_qtd_rec_fis + 1;
  --
  --               IF (l_qty_rcv = r_linhas_nff.quantity                     -- BUG 11832721
          if ( l_qty_rcv = ( nvl(r_linhas_nff.quantity, 0) * l_rate ) -- BUG 11832721
  -- OR l_dif_qty = l_tolerance  --<< BUG 15960429 - Egini - 27/05/2013
           ) then
  --
            begin -- Updating Receipt Line Flag
  --
              update cll_f189_invoice_lines
              set
                receipt_flag = 'Y'
  --                     WHERE invoice_line_id = r_linhas_nff.line_location_id -- BUG 11832721
              where
                line_location_id = r_linhas_nff.line_location_id  -- BUG 11832721
                and invoice_id = r_linhas_nff.invoice_id
                and organization_id = r_recebimento_ri.organization_id;
  --

            exception
              when others then
                print_log('Error when updating CLL_F189_INVOICE_LINES.receipt_flag for the Fiscal Operation '
                                                ||(r_recebimento_ri.operation_id)
                                                || ' ,Document Number Id '
                                                || r_linhas_nff.invoice_id);
  --
            end; -- Updating Receipt Line Flag
  --

            if l_complete_nff is null then
  --
              l_qty_rec_tot    := l_qty_rec_tot + 1;
              l_complete_nff   := 'Y';
  --
            end if;
  --

          else
  --
            if l_lib_manual = 'N' then
  --
              l_complete_nff   := 'N';
              l_msg_release    := null;
  --
  -- BUG 11741529: Start
  -- If invoice has two or more lines with same PO line,
  -- and the receiving completed only some lines, update relative received_item.
              for r_qty_lines_rec in (
                select
                  invoice_line_id,
                  quantity * l_rate quantity -- conversao de medida
                from
                  cll_f189_invoice_lines
                where
                  invoice_id = r_linhas_nff.invoice_id
                  and line_location_id = r_linhas_nff.line_location_id
                order by
                  2
              ) loop
  --
               if ( l_qty_rcv - l_qty_upd ) >= r_qty_lines_rec.quantity then
  --
                begin -- Updating Receipt Line Flag
  --
                  update cll_f189_invoice_lines
                  set
                    receipt_flag = 'Y'
                  where
                    invoice_line_id = r_qty_lines_rec.invoice_line_id;
  --

                exception
                  when others then
                    print_log('Error when updating CLL_F189_INVOICE_LINES.receipt_flag for the Fiscal Operation '
                                                    ||(r_recebimento_ri.operation_id)
                                                    || ' ,Document Number Id '
                                                    || r_linhas_nff.invoice_id);
  --
                end; -- Updating Receipt Line Flag
  --

                l_qty_upd := l_qty_upd + r_qty_lines_rec.quantity;
  --
              end if;
  --
              end loop;
  -- BUG 11741529: End
  --

            else
  --
              l_msg_release    := ' manually ';
              l_complete_nff   := 'Y';
              l_qty_rec_tot    := l_qty_rec_tot + 1;
  --
            end if;
  --
          end if;
  --

        else
  --
          if l_lib_manual = 'Y' then
  --
            l_msg_release    := ' manually ';
            l_complete_nff   := 'Y';
            l_qty_rec_tot    := l_qty_rec_tot + 1;
  --
          else
  --
            l_complete_nff := 'N';
  --
          end if;
  --
        end if;
  
  --

        if l_lib_manual = 'Y' then
  --
  -- Updating Receipt Line Flag
          begin
  --
            update cll_f189_invoice_lines
            set
              receipt_flag = 'Y'
  --                   WHERE invoice_line_id = r_linhas_nff.line_location_id -- BUG 11741529
            where
              line_location_id = r_linhas_nff.line_location_id  -- BUG 11741529
              and invoice_id = r_linhas_nff.invoice_id
              and organization_id = r_recebimento_ri.organization_id;
  --

          exception
            when others then
              print_log('Error when updating CLL_F189_INVOICE_LINES.receipt_flag for the Fiscal Operation '
                                              ||(r_recebimento_ri.operation_id)
                                              || ' ,Document Number Id '
                                              || r_linhas_nff.invoice_id);
  --
          end;
  --
        end if;
  --

      end loop;
  
  --

      if l_qtd_rec_fis > 0 and l_qty_nff_lines > l_qty_rec_tot then
  --
  -- Updating Receipt Status
        begin
  --
          update cll_f189_entry_operations
          set
            status = 'PARTIAL ASSOCIATION'
          where
            operation_id = r_recebimento_ri.operation_id
            and organization_id = r_recebimento_ri.organization_id;
  --

        exception
          when others then
            print_log('Error when updating CLL_F189_ENTRY_OPERATIONS.status for the Fiscal Operation ' ||(r_recebimento_ri.operation_id));
  --
        end;
  --
      end if;
  
  --

      commit;
  
  --
      if l_complete_nff = 'Y' then
  --
        print_log('Fiscal Operation: '
                                        ||(r_recebimento_ri.operation_id)
                                        || ' - was '
                                        || l_msg_release
                                        || 'approved');
  --

        l_req_id := fnd_request.submit_request('CLL', 'CLLRIAPR', null, null, false,
                           r_recebimento_ri.operation_id, fnd_global.org_id, r_recebimento_ri.organization_id, fnd_global.user_id, 'W'                          -- WMS
               
                           chr(0));
  --

        commit;
  
  --
        if ( l_req_id <= 0 ) then
  --
          print_log('Error in the concurrent program Receiving Approval');
          raise_application_error(-20030, 'Error in the concurrent program Receiving Approval');
  --
        end if;
  --

      else
  --
        if l_qtd_rec_fis = 0 then
  --
          retcode := 1;
          print_log('Fiscal Operation: '
                                          ||(r_recebimento_ri.operation_id)
                                          || '  - There are no physical receipts.');
  --

        else
  --
          if l_qtd_rec_fis > l_qty_rec_tot then
  --
            retcode := 1;
            print_log('Fiscal Operation: '
                                            ||(r_recebimento_ri.operation_id)
                                            || '  - Partial Association');
  --

          else
  --
            print_log('Fiscal Operation: '
                                            ||(r_recebimento_ri.operation_id)
                                            || '  - Completed');
  --
          end if;
  --
        end if;
  --
      end if;
  --

    end loop;
  --
  end;

end xxfr_f189_wms_pkg;
/