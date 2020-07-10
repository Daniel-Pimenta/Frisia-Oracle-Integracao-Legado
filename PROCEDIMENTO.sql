SET SERVEROUTPUT ON;
DECLARE
  p_from_oe_line_id    number         := '145451';        -- Source item
  p_to_oe_line_id      number         := '152656';        -- Target item
  x_retorno            varchar2(3000);
BEGIN
  
  XXFR_OM_PCK_ORDEM_VENDA_UDA.PROCESS_OM_LINE_UDA(
    p_from_oe_line_id,
    p_to_oe_line_id,
    x_retorno
  );
  
END;
/

/*
SELECT * FROM OE_ORDER_LINES_ALL_EXT_VL 
WHERE 1=1 
  and line_id in (145451, 152656)
;
select * from oe_order_lines_all;

*/
