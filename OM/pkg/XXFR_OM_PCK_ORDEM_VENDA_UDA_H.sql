create or replace package XXFR_OM_PCK_ORDEM_VENDA_UDA as 

  PROCEDURE main(
    p_from_oe_line_id in number,
    p_to_oe_line_id   in number,
    p_escopo          in varchar2 default null,
    x_retorno         out varchar2
  );

end XXFR_OM_PCK_ORDEM_VENDA_UDA;