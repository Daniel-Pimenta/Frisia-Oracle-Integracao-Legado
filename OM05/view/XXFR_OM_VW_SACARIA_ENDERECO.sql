CREATE OR REPLACE VIEW XXFR_OM_VW_SACARIA_ENDERECO AS 
select distinct
  cust_acc.cust_account_id,
  cust_acc.account_number,
  ship_pa.party_id,
  ship_pa.party_number,
  ship_pa.party_name,
  upper(
  ship_loc.address1 ||' '|| ship_loc.address2 || ', ' || ship_loc.address4 ||', '|| ship_loc.city   ||' - '||  ship_loc.postal_code ||' - '||   ship_loc.state 
  ) ds_endereco,
  sups.attribute2 nr_propriedade,
  ship_ps.party_site_id,
  ship_su.cust_acct_site_id,
  ship_su.site_use_id
from 
  hz_locations            ship_loc,
  hz_parties              ship_pa,
  hz_party_sites          ship_ps,
  hz_cust_acct_sites_all  ship_cas,
  hz_cust_site_uses_all   ship_su,
  hz_cust_accounts        cust_acc,
  ra_territories          terr,
  fnd_lookup_values       customer_class,
  ap_supplier_sites_all   sups
where 1=1
  and ship_su.cust_acct_site_id     = ship_cas.cust_acct_site_id
  and ship_cas.party_site_id        = ship_ps.party_site_id
  and ship_loc.location_id          = ship_ps.location_id
  and ship_ps.party_id              = ship_pa.party_id
  and ship_pa.party_id              = cust_acc.party_id
  and ship_cas.cust_account_id      = cust_acc.cust_account_id
  and sups.party_site_id	   (+)    = ship_ps.party_site_id
  and ship_su.territory_id          = terr.territory_id(+)
  and cust_acc.customer_class_code  = customer_class.lookup_code(+)
  and customer_class.lookup_type(+) = 'CUSTOMER CLASS'
  and ship_su.site_use_code         = 'SHIP_TO'
  and customer_class.language(+)    = 'PTB'
;
/

select * from XXFR_OM_VW_SACARIA_ENDERECO 
where 1=1
  and CUST_ACCOUNT_ID=42425
;
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
create or replace view XXFR_OM_VW_SACARIA_ITEM AS
select distinct
  msi.organization_id, 
  oeh.header_id,
  msi.inventory_item_id, 
  msi.segment1, 
  msi.description, 
  msi.primary_unit_of_measure, 
  msi.primary_uom_code, 
  msi.list_price_per_unit
from 
  mtl_system_items_b   msi,
  oe_order_headers_all oeh,
  qp_list_lines_v      l
where 1=1
  and msi.enabled_flag = 'Y'
  and msi.organization_id = oeh.ship_from_org_id
  and l.product_id        = msi.inventory_item_id
  and l.list_header_id    = oeh.price_list_id
  --and oeh.header_id       = 143906 --:DLVB.SOURCE_HEADER_ID
  --and msi.organization_id = 105 --nvl(:DLVB.ORGANIZATION_ID,organization_id)
;
/

select * from XXFR_OM_VW_SACARIA_ITEM;

