SET SERVEROUTPUT ON;
DECLARE

  l_return_status   VARCHAR2(10);
  l_msg_count       NUMBER;
  l_msg_data        VARCHAR2(1000);

  l_vendor_rec      ap_vendor_pub_pkg.r_vendor_rec_type;
  l_vendor_id       NUMBER;
  l_party_id        NUMBER;
  --
  l_vendor_site_rec ap_vendor_pub_pkg.r_vendor_site_rec_type;
  l_vendor_site_id  NUMBER;
  l_party_site_id   NUMBER;
  l_location_id     NUMBER;
  

  procedure initialize is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('PO', 'UO_FRISIA', 'DANIEL.PIMENTA'); 
  end;

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    /*
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
    */
  end;

BEGIN
  
  initialize;

  -- ************************************************************
  print_log('CREATE VENDOR');
  l_vendor_rec.segment1                   := '35674343000116';
  l_vendor_rec.vendor_name                := 'WSB CONSULTORIA EM TI';
  l_vendor_rec.VENDOR_NAME_ALT            := 'WSB CONSULTORIA EM TI';
  l_vendor_rec.VENDOR_TYPE_LOOKUP_CODE    := 'VENDOR';
  l_vendor_rec.ALWAYS_TAKE_DISC_FLAG      := 'Y'; 
  l_vendor_rec.PAY_DATE_BASIS_LOOKUP_CODE := 'DISCOUNT';
  l_vendor_rec.PAY_GROUP_LOOKUP_CODE      := 'BOLETO';
  l_vendor_rec.ALLOW_AWT_FLAG             := 'Y'; 
  l_vendor_rec.GLOBAL_ATTRIBUTE1          := 'N';
  l_vendor_rec.match_option               := 'P'; --'R'
  --
  pos_vendor_pub_pkg.create_vendor(    
    -- Input Parameters
    p_vendor_rec      => l_vendor_rec,
    -- Output Parameters
    x_return_status   => l_return_status,
    x_msg_count       => l_msg_count,
    x_msg_data        => l_msg_data,
    x_vendor_id       => l_vendor_id,
    x_party_id        => l_party_id
  );
  print_log('Retorno       :'||l_return_status);
  --
  for i in 1 .. l_msg_count loop
    l_msg_data := fnd_msg_pub.get( 
      p_msg_index => i, 
      p_encoded   => 'F'
    );
    print_log('  '|| i|| ') '|| l_msg_data);
  end loop;
  --
  if (l_return_status <> 'S') then
    goto FIM;
  end if;

  print_log('Vendor Id     :'||l_vendor_id);
  print_log('Party Id      :'||l_party_id);
  --
  -- ************************************************************
  print_log('');
  print_log('CREATE VENDOR_SITE');
  l_vendor_site_rec.vendor_id             := l_vendor_id;
  l_vendor_site_rec.vendor_site_code      := l_vendor_rec.segment1;
  l_vendor_site_rec.AREA_CODE             := '21';
  l_vendor_site_rec.PHONE                 := '991598700';
  l_vendor_site_rec.address_line1         := 'AV PAULISTA';
  l_vendor_site_rec.address_line2         := '171';
  l_vendor_site_rec.address_line3         := 'SL 7';        --COMPLEMENTO
  l_vendor_site_rec.address_line4         := 'CENTRO';  --BAIRRO
  l_vendor_site_rec.city                  := 'SAO PAULO';
  l_vendor_site_rec.state                 := 'SP';
  l_vendor_site_rec.zip                   := '00000000';
  l_vendor_site_rec.country               := 'BR';
  l_vendor_site_rec.org_id                := '81';
  
  l_vendor_site_rec.ADDRESS_STYLE         := 'BR';
  l_vendor_site_rec.PAY_DATE_BASIS_LOOKUP_CODE := 'DISCOUNT';
  l_vendor_site_rec.COUNTRY_OF_ORIGIN_CODE:= 'BR';
  l_vendor_site_rec.CREATE_DEBIT_MEMO_FLAG:= 'N';
  
  l_vendor_site_rec.GLOBAL_ATTRIBUTE1     := 'N'; 
  l_vendor_site_rec.GLOBAL_ATTRIBUTE9     := '2'; --CNPJ, 
  l_vendor_site_rec.GLOBAL_ATTRIBUTE10    := '35674343'; 
  l_vendor_site_rec.GLOBAL_ATTRIBUTE11    := '0001';
  l_vendor_site_rec.GLOBAL_ATTRIBUTE12    := '16'; 
  l_vendor_site_rec.GLOBAL_ATTRIBUTE13    := 'ISENTO';
  l_vendor_site_rec.GLOBAL_ATTRIBUTE15    := 'COMERCIAL';
  
  --l_vendor_site_rec.STATE_REPORTABLE_FLAG := 'N';
  l_vendor_site_rec.purchasing_site_flag  := 'Y';
  l_vendor_site_rec.pay_site_flag         := 'Y';
  l_vendor_site_rec.rfq_only_site_flag    := 'N';
  --
  --l_vendor_site_rec.CUSTOMER_NUM          :=
  --l_vendor_site_rec.SHIP_TO_LOCATION_ID   :=
  --l_vendor_site_rec.BILL_TO_LOCATION_ID   := 
  --
  pos_vendor_pub_pkg.create_vendor_site (
    p_vendor_site_rec => l_vendor_site_rec,
    --
    x_vendor_site_id  => l_vendor_site_id,
    x_party_site_id   => l_party_site_id,
    x_location_id     => l_location_id,
    --
    x_return_status   => l_return_status,
    x_msg_count       => l_msg_count,
    x_msg_data        => l_msg_data
  );
  
  ap_vendor_pub_pkg.create_vendor_site(
    p_api_version      => p_api_version,        -- in
    p_init_msg_list    => p_init_msg_list,      -- in
    p_commit           => p_commit,             -- in
    p_validation_level => p_validation_level,   -- in
    p_vendor_site_rec  => lr_sp_st,             -- in
    x_vendor_site_id   => x_vendor_site_id,     -- out
    x_party_site_id    => x_party_site_id,      -- out
    x_location_id      => x_location_id,
    x_return_status    => x_return_status,      -- out
    x_msg_count        => x_msg_count,          -- out
    x_msg_data         => x_msg_data           -- out
  );   
  
  
  print_log('Retorno       :'||l_return_status);
  for i in 1 .. l_msg_count loop
    l_msg_data := fnd_msg_pub.get( 
      p_msg_index => i, 
      p_encoded   => 'F'
    );
    print_log('  '|| i|| ') '|| l_msg_data);
  end loop;
  --
  if (l_return_status <> 'S') then
    goto FIM;
  end if;
  --
  print_log('Vendor Site Id:'||l_vendor_site_id);
  print_log('Party Site Id :'||l_party_site_id);
  print_log('Locations Id  :'||l_party_site_id);
  
  <<FIM>>
  null;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  print_log(SQLERRM);
END;
/


/*
30890	88026

SELECT * FROM hz_parties WHERE PARTY_ID = 178061; 
SELECT * FROM hz_party_sites WHERE PARTY_SITE_ID = 88026; 

select * from po_vendors where segment1 in ('85425249772','35674343000116');
select * 
from po_vendor_sites_all 
where 1=1
  AND GLOBAL_ATTRIBUTE9 = '2'
ORDER BY CREATION_DATE DESC;
  AND Vendor_Id in (
  select vendor_id from po_vendors where segment1 in ('85425249772','35674343000116')
);

select * from cll_f189_query_customers_v WHERE CUSTOMER_NAME = 'HELMUTH SCHMIDT';
select * from cll_f189_query_vendors_v where vendor_NAME = 'HELMUTH SCHMIDT';

select 'VENDOR' T, VENDOR_ID       id, VENDOR_NAME  nome,  SEGMENT1       cod, PARTY_ID, PARTY_NUMBER from po_vendors where vendor_id = 17250
union
SELECT 'CUSTOMER' T, CUST_ACCOUNT_ID id, ACCOUNT_NAME nome,  ACCOUNT_NUMBER cod, PARTY_ID, null         FROM hz_cust_accounts where CUST_ACCOUNT_ID=13289
;

SELECT * FROM hz_parties WHERE PARTY_ID = 41294;

select ap.*
  --ap.vendor_id, ap.vendor_site_code, ap.vendor_site_id, ap.location_id, ap.party_site_id
from ap_supplier_sites_all ap
where 1=1
  and ap.vendor_id = 51006
;



  SELECT rfea.entity_id, pv.segment1, pv.vendor_name, pv.vendor_type_lookup_code,
          pv.enabled_flag, rfea.vendor_site_id, pvsa.vendor_site_code,
          rfea.document_number, pvsa.address_line1, pvsa.address_line2,
          pvsa.address_line3, rs.state_code, rc.city_code, rc.iss_tax_type,
          rc.iss_tax, rfea.document_type, pvsa.vendor_id, rfea.city_id,
          rfea.state_id, rs.freight_icms_type, rs.freight_icms_tax,
          rfea.business_vendor_id, rbv.business_code, rbv.highlight_ipi_flag,
          rs.national_state, rfea.org_id, pvsa.terms_id, rbv.ir_vendor,
          rbv.ir_categ, rbv.ir_tax, rbv.inss_substitute_flag, rbv.inss_tax,
          rfea.icms_reduction_base_flag, rbv.funrural_contributor_flag,
          rbv.funrural_tax, 
          rbv.social_security_contrib_tax, rbv.gilrat_tax, rbv.senar_tax, -- ER 17551029 
          rbv.sest_senat_contributor_flag,
          rbv.sest_senat_tax, pvsa.inactive_date,
          rbv.sest_senat_income_code,
          rbv.funrural_income_code
     FROM cll_f189_fiscal_entities_all rfea,
          po_vendor_sites_all pvsa,
          cll_f189_cities rc,
          cll_f189_states rs,
          cll_f189_business_vendors rbv,
          po_vendors pv
    WHERE rfea.entity_type_lookup_code = 'VENDOR_SITE'
      AND rfea.org_id = pvsa.org_id
      AND pvsa.vendor_site_id = rfea.vendor_site_id
      AND pvsa.pay_site_flag = 'Y'
      AND pv.vendor_id = pvsa.vendor_id
      AND rc.city_id(+) = rfea.city_id
      AND rc.state_id(+) = rfea.state_id
      AND rs.state_id = rfea.state_id
      AND rbv.business_id = rfea.business_vendor_id
      and pv.segment1 in ('85425249772','35674343000116')
    ;


*/