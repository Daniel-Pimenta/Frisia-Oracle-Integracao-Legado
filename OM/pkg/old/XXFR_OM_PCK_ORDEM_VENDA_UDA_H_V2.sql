create or replace package XXFR_OM_PCK_ORDEM_VENDA_UDA as 

  PROCEDURE PROCESS_OM_LINE_UDA(
    p_from_oe_line_id in number,
    p_to_oe_line_id   in number,
    x_retorno         out varchar2
  );

end XXFR_OM_PCK_ORDEM_VENDA_UDA;