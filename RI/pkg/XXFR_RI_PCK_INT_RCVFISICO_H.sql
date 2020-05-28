create or replace package XXFR_RI_PCK_INT_RCVFISICO as
  
  procedure insert_rcv_tables(
    p_operation_id    in number,
    p_organization_id in number,
    p_escopo          in varchar2 default null,
    x_retorno         out varchar2
  );
  
  procedure insert_rcv_tables(
    p_operation_id    in number,
    p_organization_id in number,
    p_process_flag    in boolean,   
    p_fase            in varchar2,
    p_group_id        in number,
    x_retorno         out varchar2
  );
  
end XXFR_RI_PCK_INT_RCVFISICO;
/