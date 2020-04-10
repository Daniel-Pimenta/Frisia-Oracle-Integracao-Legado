--Query to Find All Tax Code and Tax Rate used in the Oracle R12

SELECT DISTINCT
a.tax_id,
a.tax tax_code,
b.tax_full_name,
a.tax_regime_code,
a.tax_type_code,
c.tax_rate_code,
d.tax_rate_name,
c.tax_status_code,
c.rate_type_code,
c.percentage_rate
--,c.DESCRIPTION,e.ENTITY_CODE,e.EVENT_CLASS_CODE,e.TRX_ID,e.TRX_NUMBER
FROM
zx_taxes_b a,
zx_taxes_tl b,
zx_rates_b c,
zx_rates_tl d,
--zx_lines_summary e,
zx_lines_v f WHERE
1 = 1
AND a.tax_id = b.tax_id
AND c.tax = a.tax
AND c.tax_rate_id = d.tax_rate_id
--and e.TAX = a.TAX
--and e.TAX_RATE_ID = c.TAX_RATE_ID
AND f.tax = a.tax
AND f.tax_rate_id = c.tax_rate_id
--and a.TAX = 'AU GST TAX'
ORDER BY
a.tax,
c.tax_rate_code;

--To Find All Tax Code and Tax Rate defined in the Oracle R12

SELECT DISTINCT
  a.tax_id,
  a.tax tax_code,
  b.tax_full_name,
  a.tax_regime_code,
  a.tax_type_code,
  c.tax_rate_code,
  d.tax_rate_name,
  c.tax_status_code,
  c.rate_type_code,
  c.percentage_rate,
  c.description
FROM
  zx_taxes_b a,
  zx_taxes_tl b,
  zx_rates_b c,
  zx_rates_tl d 
WHERE 1 = 1
  AND a.tax_id = b.tax_id
  AND c.tax = a.tax
  AND c.tax_rate_id = d.tax_rate_id
  --and a.TAX = 'AU GST TAX'
ORDER BY
  a.tax,
  c.tax_rate_code
;

/*
Relevant Tables :
b. Taxes: ZX_TAXES_B
c. Tax Status: ZX_STATUS_B
d. Tax Rates: ZX_RATES_B
e. Tax Jurisdictions: ZX_JURISDICTIONS_B
f. Tax Rules: ZX_RULES_B

select * from ZX_LINES_V where ENTITY_CODE = 'AP_INVOICE';
select * from zx_lines_summary ;
select * from ZX_TAXES_B where TAX = 'AU GST TAX';
select * from ZX_TAXES_TL where TAX_ID = 209333;
select * from ZX_RATES_B WHERE tax = 'AU GST TAX';
select * from ZX_RATES_TL;
select * from AP_TAX_CODES_ALL;
SELECT * FROM zx_regimes_b WHERE tax_regime_code = '&tax_regime_code';
SELECT * FROM zx_taxes_b WHERE DECODE('&tax_name',null,'xxx',tax) = nvl('&tax_name','xxx') AND tax_regime_code = '&tax_regime_code';
SELECT * FROM zx_status_b WHERE tax = '&tax_name' AND tax_regime_code = '&tax_regime_code';
SELECT * FROM zx_rates_b WHERE tax = '&tax_name' AND tax_regime_code = '&tax_regime_code';
SELECT * FROM zx_jurisdictions_b WHERE DECODE('&tax_name',null,'xxx',tax) = nvl('&tax_name','xxx') AND tax_regime_code = '&tax_regime_code';
SELECT * FROM zx_rules_b WHERE tax = '&tax_name' AND tax_regime_code = '&tax_regime_code';


Following are the main E-Business tax tables that will contain the transaction information that will have the tax details after tax is calculated.

a. ZX_LINES: This table will have the tax lines for associated with PO/Release schedules.
TRX_ID: Transaction ID. This is linked to the PO_HEADERS_ALL.PO_HEADER_ID
TRX_LINE_ID: Transaction Line ID. This is linked to the PO_LINE_LOCATIONS_ALL.LINE_LOCATION_ID

b. ZX_REC_NREC_DIST: This table will have the tax distributions for associated with PO/Release distributions.
TRX_ID: Transaction ID. This is linked to the PO_HEADERS_ALL.PO_HEADER_ID
TRX_LINE_ID: Transaction Line ID. This is linked to the PO_LINE_LOCATIONS_ALL.LINE_LOCATION_ID
TRX_LINE_DIST_ID: Transaction Line Distribution ID. This is linked to the PO_DISTRIBUTIONS_ALL.PO_DISTRIBUTION_ID
RECOVERABLE_FLAG: Recoverable Flag. If the distribution is recoverable then the flag will be set to Y and there will be values in the RECOVERY_TYPE_CODE and RECOVERY_RATE_CODE.

c. PO_REQ_DISTRIBUTIONS_ALL: This table will have the tax distributions for associated with Requisition distribution.
RECOVERABLE_TAX: Recoverable tax amount
NONRECOVERABLE_TAX: Non Recoverable tax amount

d. ZX_LINES_DET_FACTORS: This table holds all the information of the tax line transaction for both the requisitions as well as the purchase orders/releases.
TRX_ID: Transaction ID. This is linked to the PO_REQUISITION_HEADERS_ALL.REQUISITION_HEADER_ID / PO_HEADERS_ALL.PO_HEADER_ID
TRX_LINE_ID: Transaction Line ID. This is linked to the PO_REQUISITION_LINES_ALL.REQUISITION_LINE_ID / PO_LINE_LOCATIONS_ALL.LINE_LOCATION_ID

