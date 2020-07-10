create or replace PACKAGE XXFR_OM_PCK_DEV_SIMB_INSUMOS as
  
  procedure main(
    p_header_id     in  number,
    x_oe_header_id  out number,
    x_retorno       out varchar2
  );
  
end XXFR_OM_PCK_DEV_SIMB_INSUMOS;
/