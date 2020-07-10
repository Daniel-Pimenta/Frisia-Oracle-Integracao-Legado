create or replace package XXFR_RI_PCK_INT_DEV_FISICO as
  
  procedure insert_rcv_tables(
    p_operation_id      in number,
    p_organization_id   in number,
    p_dev_operation_id  in number   default null,
    p_escopo            in varchar2 default null,
    x_retorno           out varchar2
  );
  
end XXFR_RI_PCK_INT_DEV_FISICO;
/