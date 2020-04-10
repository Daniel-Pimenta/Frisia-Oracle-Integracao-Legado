create or replace package XXFR_AR_PCK_INT_SINCRO_NF AS
  
  procedure print_log(msg   in Varchar2);
  procedure initialize;
  procedure main(p_customer_trx_id in number);
  
  function monta_json(p_customer_trx_id in number) return boolean;
  function monta_type(p_customer_trx_id in number) return boolean;
  
end;
/

