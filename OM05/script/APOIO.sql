 set SERVEROUTPUT ON;
declare
begin
  xxfr_pck_variaveis_ambiente.inicializar('ONT', 'UO_FRISIA');
  --XXFR_OM_PKG_DEVOLUCAO_SACARIA.main(p_trip_id => 53043);
  
  UPDATE wsh_trips 
  set 
    ATTRIBUTE8 = 7549,
    ATTRIBUTE9 = 2,
    ATTRIBUTE10 = 42425,	
    ATTRIBUTE11 = 80821
  where trip_id= 53043;
  
  --ROLLBACK;
  
end;
/



/*
Informações Adicionais sobre o Percurso

select * from qp_secu_list_headers_v where NAME like '22L_LISTA%';
SELECT * FROM qp_list_lines_v  WHERE LIST_HEADER_ID = 11041;

SELECT * FROM oe_order_HEADERS_all WHERE HEADER_ID = 143906;
SELECT * FROM oe_order_lines_all WHERE HEADER_ID = 143906;

SELECT * --TRANSACTION_TYPE_ID, ATTRIBUTE1, WAREHOUSE_ID, TRANSACTION_TYPE_CODE 
FROM oe_transaction_types_all
WHERE 1=1
  AND ATTRIBUTE1            = 'REMESSA EMBALAGEM'
  AND TRANSACTION_TYPE_CODE = 'LINE'
  AND WAREHOUSE_ID          = 105
;

select * from oe_transaction_types_tl where 1=1 and LANGUAGE='PTB' and transaction_type_id = 4351;
select * from ra_cust_trx_types_all where CUST_TRX_TYPE_ID=5357;

select * from oe_transaction_types_pkg

select hca.account_number, hp.party_name, hca.cust_account_id
from 
  hz_cust_accounts_all hca, 
  hz_parties hp
where 
1=1
and hp.party_id = hca.party_id
;

--XXFR - Solucoes Frisia
--XXFR_AR_CV_CLIENTES_OBJ_ENTREGA

;

*/