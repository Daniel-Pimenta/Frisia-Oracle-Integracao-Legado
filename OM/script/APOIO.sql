SET SERVEROUTPUT ON;
DECLARE
  p_from_oe_line_id number := '145451'; -- Source item
  p_to_oe_line_id   number := '152658'; -- Target item
  x_retorno varchar2(3000);
BEGIN

  xxfr_pck_variaveis_ambiente.inicializar('ONT', 'UO_FRISIA' ); 
  XXFR_OM_PCK_ORDEM_VENDA_UDA.main(
    p_from_oe_line_id,
    p_to_oe_line_id,
    x_retorno
  );

END;
/

select line_id, count(*) from oe_order_lines_all_ext_b
where 1=1 
  and line_id in (
    145451, --FROM
    152658  --TO
  )
group by line_id
;

select 
  HEADER_ID, LINE_ID, LINE_NUMBER, SPLIT_FROM_LINE_ID
from oe_order_lines_all
where 1=1
  --and REFERENCE_LINE_ID is not null
  and header_id =155803
order by 3;

select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
  and upper(ds_escopo) like 'XXFR_OM_TRG_OE_UDA%'
  --and DT_CRIACAO >= sysdate -0.5
order by 
  --DT_CRIACAO desc,
  id
;


