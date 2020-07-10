SET SERVEROUTPUT ON;
DECLARE
  v_api_version_number           NUMBER    := 1;
  v_return_status                VARCHAR2(2000);
  v_msg_count                    NUMBER;
  v_msg_data                     VARCHAR2(2000);
  -- IN Variables --
  v_header_rec                   oe_order_pub.header_rec_type;
  v_line_tbl                     oe_order_pub.line_tbl_type;
  v_action_request_tbl           oe_order_pub.request_tbl_type;
  v_line_adj_tbl                 oe_order_pub.line_adj_tbl_type;
  -- OUT Variables --
  v_header_rec_out               oe_order_pub.header_rec_type;
  v_header_val_rec_out           oe_order_pub.header_val_rec_type;
  v_header_adj_tbl_out           oe_order_pub.header_adj_tbl_type;
  v_header_adj_val_tbl_out       oe_order_pub.header_adj_val_tbl_type;
  v_header_price_att_tbl_out     oe_order_pub.header_price_att_tbl_type;
  v_header_adj_att_tbl_out       oe_order_pub.header_adj_att_tbl_type;
  v_header_adj_assoc_tbl_out     oe_order_pub.header_adj_assoc_tbl_type;
  v_header_scredit_tbl_out       oe_order_pub.header_scredit_tbl_type;
  v_header_scredit_val_tbl_out   oe_order_pub.header_scredit_val_tbl_type;
  v_line_tbl_out                 oe_order_pub.line_tbl_type;
  v_line_val_tbl_out             oe_order_pub.line_val_tbl_type;
  v_line_adj_tbl_out             oe_order_pub.line_adj_tbl_type;
  v_line_adj_val_tbl_out         oe_order_pub.line_adj_val_tbl_type;
  v_line_price_att_tbl_out       oe_order_pub.line_price_att_tbl_type;
  v_line_adj_att_tbl_out         oe_order_pub.line_adj_att_tbl_type;
  v_line_adj_assoc_tbl_out       oe_order_pub.line_adj_assoc_tbl_type;
  v_line_scredit_tbl_out         oe_order_pub.line_scredit_tbl_type;
  v_line_scredit_val_tbl_out     oe_order_pub.line_scredit_val_tbl_type;
  v_lot_serial_tbl_out           oe_order_pub.lot_serial_tbl_type;
  v_lot_serial_val_tbl_out       oe_order_pub.lot_serial_val_tbl_type;
  v_action_request_tbl_out       oe_order_pub.request_tbl_type;
  --
  l_organization_id             number; 
  l_inventory_item_id           number;
  l_cust_acct_site_id           number;
  l_bill_to_site_use_id         number; 
  l_order_type_id               number; 
  l_lista_precos_om             varchar2(50); 
  l_condicao_pagamento          varchar2(50); 
  l_ordered_quantity            number; 
  l_uom_code                    varchar2(50); 
  l_status                      varchar2(50);
  --
  l_sold_to_org_id              number;
  l_ship_to_org_id              number; 
  l_invoice_to_org_id           number;
  --
  l_price_list_id               number;
  --
  l_term_id                     number;
  
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting of script');

  FND_GLOBAL.APPS_INITIALIZE ( 
    user_id      => 1131,
    resp_id      => 51165,
    resp_appl_id => 552 
  );

  select 
    organization_id, inventory_item_id, id_cliente, tp_os_industrializacao, lista_precos_om, condicao_pagamento, quantity, uom_code, status
  into
    l_organization_id, 
    l_inventory_item_id, 
    l_cust_acct_site_id,
    l_order_type_id, 
    l_lista_precos_om, 
    l_condicao_pagamento, 
    l_ordered_quantity, 
    l_uom_code, 
    l_status
  from xxfr_dev_simb_insumos_header_v
  where header_id = 1;
  --
  xxfr_pck_variaveis_ambiente.inicializar('ONT','UO_FRISIA');  
  --
  -- Header Record --
  v_header_rec                        := oe_order_pub.g_miss_header_rec;
  v_header_rec.operation              := oe_globals.g_opr_create;
  v_header_rec.order_type_id          := l_order_type_id;
  --
  v_header_rec.sold_from_org_id       := 81;
  --
  select price_list_id into l_price_list_id 
  from oe_price_lists 
  where name = l_lista_precos_om
  ;
  --
  select hcas.cust_account_id, hcsu.site_use_id, hcsu.bill_to_site_use_id
  into l_sold_to_org_id, l_ship_to_org_id, l_invoice_to_org_id 
  from 
    hz_cust_accounts              hca,
    hz_cust_acct_sites_all        hcas,
    hz_cust_site_uses_all         hcsu
  where 1=1
    and hcas.cust_account_id    = hca.cust_account_id
    and hcsu.cust_acct_site_id  = hcas.cust_acct_site_id
    and hcsu.site_use_code      = 'SHIP_TO'
    and hcas.cust_acct_site_id  = l_cust_acct_site_id
  ;
  
  select term_id into l_term_id
  from ra_terms
  where 1=1
    and end_date_active is null
    and name = l_condicao_pagamento   
  ;
  
  v_header_rec.sold_to_org_id         := l_sold_to_org_id;
  v_header_rec.ship_to_org_id         := l_ship_to_org_id;
  v_header_rec.invoice_to_org_id      := l_invoice_to_org_id;
  --
  v_header_rec.order_source_id        := 0;
  v_header_rec.booked_flag            := 'N';
  v_header_rec.price_list_id          := l_price_list_id;
  v_header_rec.pricing_date           := SYSDATE;
  v_header_rec.flow_status_code       := 'ENTERED';
  v_header_rec.payment_term_id        := l_term_id;
  --v_header_rec.cust_po_number         := '99478222532';
  v_header_rec.salesrep_id            := -3;
  v_header_rec.transactional_curr_code:= 'BRL';
  
  v_action_request_tbl (1) := oe_order_pub.g_miss_request_rec;
  -- Line Record --
  v_line_tbl (1)                      := oe_order_pub.g_miss_line_rec;
  v_line_tbl (1).operation            := oe_globals.g_opr_create;
  v_line_tbl (1).inventory_item_id    := l_inventory_item_id;
  v_line_tbl (1).ordered_quantity     := l_ordered_quantity;
  v_line_tbl (1).payment_term_id      := l_term_id;
  v_line_tbl (1).unit_selling_price   := null;
  v_line_tbl (1).calculate_price_flag := 'Y';
  
  DBMS_OUTPUT.PUT_LINE('Starting of API');
  
  -- Calling the API to create an Order --
  OE_ORDER_PUB.PROCESS_ORDER (
    p_api_version_number           => v_api_version_number
    ,p_header_rec                  => v_header_rec
    ,p_line_tbl                    => v_line_tbl
    ,p_action_request_tbl          => v_action_request_tbl
    ,p_line_adj_tbl                => v_line_adj_tbl
    -- OUT variables
    ,x_header_rec                  => v_header_rec_out
    ,x_header_val_rec              => v_header_val_rec_out
    ,x_header_adj_tbl              => v_header_adj_tbl_out
    ,x_header_adj_val_tbl          => v_header_adj_val_tbl_out
    ,x_header_price_att_tbl        => v_header_price_att_tbl_out
    ,x_header_adj_att_tbl          => v_header_adj_att_tbl_out
    ,x_header_adj_assoc_tbl        => v_header_adj_assoc_tbl_out
    ,x_header_scredit_tbl          => v_header_scredit_tbl_out
    ,x_header_scredit_val_tbl      => v_header_scredit_val_tbl_out
    ,x_line_tbl                    => v_line_tbl_out
    ,x_line_val_tbl                => v_line_val_tbl_out
    ,x_line_adj_tbl                => v_line_adj_tbl_out
    ,x_line_adj_val_tbl            => v_line_adj_val_tbl_out
    ,x_line_price_att_tbl          => v_line_price_att_tbl_out
    ,x_line_adj_att_tbl            => v_line_adj_att_tbl_out
    ,x_line_adj_assoc_tbl          => v_line_adj_assoc_tbl_out
    ,x_line_scredit_tbl            => v_line_scredit_tbl_out
    ,x_line_scredit_val_tbl        => v_line_scredit_val_tbl_out
    ,x_lot_serial_tbl              => v_lot_serial_tbl_out
    ,x_lot_serial_val_tbl          => v_lot_serial_val_tbl_out
    ,x_action_request_tbl          => v_action_request_tbl_out
    ,x_return_status               => v_return_status
    ,x_msg_count                   => v_msg_count
    ,x_msg_data                    => v_msg_data
  );
  DBMS_OUTPUT.PUT_LINE('Completion of API');
  IF v_return_status = fnd_api.g_ret_sts_success THEN
      --COMMIT;
      DBMS_OUTPUT.put_line ('Order Import Success header_id: '||v_header_rec_out.header_id);
  ELSE
      DBMS_OUTPUT.put_line ('Order Import failed:'||v_msg_data);
      ROLLBACK;
      FOR i IN 1 .. v_msg_count
      LOOP
        v_msg_data := oe_msg_pub.get( p_msg_index => i, p_encoded => 'F');
        dbms_output.put_line( i|| ') '|| v_msg_data);
      END LOOP;
  END IF;
END;
/

SELECT * FROM oe_order_headers_all WHERE header_id=166809;
SELECT * FROM oe_order_lines_all where header_id = 45077;

SELECT * FROM XXFR_RI_VW_INF_DA_INVOICE 
where 1=1
  --and ACCOUNT_NUMBER='076107770'
  and CUST_ACCOUNT_ID=9045    	 -> sold_to_org_id
  and SITE_USE_ID=10045          -> ship_to_org_id
  and BILL_TO_SITE_USE_ID=10042  -> invoice_to_org_id
;

select * 
from cll_f189_query_customers_v 
where 1=1
  and customer_number = 9045
  and CUST_ACCT_SITE_ID in (9045,10045,10042);
  
--cll_f189_query_vendors_v      v,


  select 
    organization_id, inventory_item_id, id_cliente, tp_os_industrializacao, lista_precos_om, condicao_pagamento, quantity, uom_code, status
  from xxfr_dev_simb_insumos_header_v
  where header_id = 1;


select 
  hca.cust_account_id, hca.party_id, hca.account_number, hca.customer_type, hca.account_name,
  hcas.cust_acct_site_id, hcas.party_site_id, hcas.attribute19, hcas.attribute20, hcas.global_attribute2, hcas.global_attribute3, hcas.global_attribute4, hcas.global_attribute5, hcas.global_attribute6, hcas.global_attribute8,
  hcsu.site_use_id, hcsu.site_use_code, hcsu.primary_flag, hcsu.location, hcsu.bill_to_site_use_id, hcsu.orig_system_reference,
  'FIM' trailer
from 
  hz_cust_accounts              hca,
  hz_cust_acct_sites_all        hcas,
  hz_cust_site_uses_all         hcsu
where 1=1
  and hcas.cust_account_id    = hca.cust_account_id
  and hcsu.cust_acct_site_id  = hcas.cust_acct_site_id
  --and hcsu.site_use_code      = 'SHIP_TO'
  --and SITE_USE_ID = 24839
  and hca.account_number = '53369435'
;














select transaction_type_id, name 
from oe_transaction_types_tl 
where 1=1 
  and LANGUAGE='PTB' 
  --AND NAME LIKE '%SERVICO_INDUSTRIALIZACAO'
  and transaction_type_id = 3597
;

select * from xxfr_integracao_detalhe x where x.id_transacao = 408069;