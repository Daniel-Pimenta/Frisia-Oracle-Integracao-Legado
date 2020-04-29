create or replace PACKAGE XXFR_AR_PCK_GERA_RI AS
  
  procedure print_log(msg in varchar2);
  procedure initialize ;
  
  procedure processar(
    p_customer_trx_id   in number,
    x_retorno           out varchar2
  );
  
  procedure main(
    p_customer_trx_id   in number,
    p_processar         in boolean,
    p_sequencial        in varchar2 default null,
    x_retorno           out varchar2
  );
  
  procedure insere_ri_interface_header(
    p_customer_trx_id in number,
    x_retorno         out varchar2
  );
  procedure insere_ri_interface_lines(
    p_customer_trx_id in number,
    x_retorno         out varchar2
  );
  procedure recupera_inf_diversas(
    p_customer_trx_id  in number,
    p_vendor_site_id   in number,
    p_warehouse_id     in number,
    p_cust_trx_type_id in number,
    x_retorno          out varchar
  );
  procedure limpa_interface(
    x_retorno           out varchar2
  );
  
  function retorna_cc_rem_fixar(
    p_item_id         in number,
    p_organization_id in number
  ) return number;

END;
