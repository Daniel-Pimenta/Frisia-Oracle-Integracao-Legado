/**********************************************************
 *PURPOSE: To list customers and their sites information  *
 *AUTHOR: Shailender Thallam                              *
 **********************************************************/
 SELECT
  ----------------------
  --Customer Information
  ----------------------
  hp.party_id,
  hp.party_name "CUSTOMER_NAME",
  hca.cust_account_id,
  hca.account_number,
  hcas.org_id,
  ---------------------------
  --Customer Site Information
  ---------------------------
  hcas.cust_acct_site_id,
  hps.party_site_number,
  hcsu.site_use_code,
  -----------------------
  --Customer Site Address
  -----------------------
  hl.address1,
  hl.address2,
  hl.address3,
  hl.address4,
  hl.city,
  hl.postal_code,
  hl.state,
  hl.province,
  hl.county,
  hl.country,
  hl.address_style
FROM 
  hz_parties hp,
  hz_party_sites hps,
  hz_cust_accounts_all hca,
  hz_cust_acct_sites_all hcas,
  hz_cust_site_uses_all hcsu,
  hz_locations hl
WHERE 1=1
AND hp.party_id            = hca.party_id
AND hca.cust_account_id    = hcas.cust_account_id(+)
AND hps.party_site_id(+)   = hcas.party_site_id
AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
  --
AND hps.location_id = hl.location_id(+)
  --
--AND hp.party_type = 'ORGANIZATION' -- only ORGANIZATION Party types
--AND hp.status     = 'A'            -- only Active Parties/Customers
--AND hp.party_id = 180069
AND hp.party_name = 'TESTE CLIENTE FRENTE CAIXA 9'
ORDER BY 
  to_number(hp.party_number),
  hp.party_name,
  hca.account_number
;

Vendor Id  :58001
Customer Id:53042

select * from cll_f189_query_customers_v WHERE CUSTOMER_NAME LIKE 'TESTE%';
select * from cll_f189_query_vendors_v where vendor_id = 58001;

select * from xxfr_integracao_detalhe x where x.id_transacao in (441369);


select * from cll_f189_fiscal_entities_all 
where 1=1
  --and DOCUMENT_NUMBER = '96622233345'
order by creation_date desc
;

  SELECT hp.status, 
          rfea.entity_id, 
          hp.party_name customer_name, 
          hp.party_number customer_number,
          hp.address1, 
          hp.address2, 
          hp.address3, 
          hp.address4,
          rbv.business_code, 
          rbv.highlight_ipi_flag, 
          rbv.inss_substitute_flag,
          rbv.inss_tax, 
          rbv.funrural_contributor_flag, 
          rbv.funrural_tax,
          rbv.social_security_contrib_tax, -- ER 17551029  
          rbv.gilrat_tax,                  -- ER 17551029  
          rbv.senar_tax,                   -- ER 17551029 
          rbv.sest_senat_contributor_flag, 
          rbv.sest_senat_tax,
          rbv.icms_contributor_flag, 
          rbv.ir_vendor, 
          rbv.ir_categ, 
          rbv.ir_tax,
          rs.national_state, 
          rs.freight_icms_type, 
          rs.freight_icms_tax,
          rs.state_code, 
          rci.iss_tax, 
          rci.iss_tax_type, 
          rci.city_code,
          rfea.creation_date, 
          rfea.created_by, 
          rfea.last_update_date,
          rfea.last_updated_by, 
          rfea.last_update_login,
          rfea.entity_type_lookup_code, 
          rfea.business_vendor_id,
          rfea.state_id, 
          rfea.document_type, 
          rfea.document_number, 
          rfea.ie,
          rfea.icms_reduction_base_flag,
          rfea.city_id,
          rfea.org_id,
          rfea.cust_acct_site_id, 
          rfea.attribute_category, 
          rfea.attribute1,
          rfea.attribute2, 
          rfea.attribute3, 
          rfea.attribute4, 
          rfea.attribute5,
          rfea.attribute6, 
          rfea.attribute7, 
          rfea.attribute8, 
          rfea.attribute9,
          rfea.attribute10, 
          rfea.attribute11, 
          rfea.attribute12,
          rfea.attribute13, 
          rfea.attribute14, 
          rfea.attribute15,
          rfea.attribute16, 
          rfea.attribute17, 
          rfea.attribute18,
          rfea.attribute19, 
          rfea.attribute20, 
          rfea.inactive_date,
          rbv.sest_senat_income_code,
          rbv.funrural_income_code
     FROM hz_cust_acct_sites_all hcas,
          hz_party_sites hps,
          hz_parties hp,
          cll_f189_business_vendors rbv,
          cll_f189_cities rci,
          cll_f189_states rs,
          cll_f189_fiscal_entities_all rfea
    WHERE hp.party_id = hps.party_id
      AND hps.party_site_id = hcas.party_site_id
      AND rfea.cust_acct_site_id = hcas.cust_acct_site_id
      AND rfea.entity_type_lookup_code = 'CUSTOMER_SITE'
      AND rbv.business_id = rfea.business_vendor_id
      AND rs.state_id = rfea.state_id
      AND rci.city_id(+) = rfea.city_id 
