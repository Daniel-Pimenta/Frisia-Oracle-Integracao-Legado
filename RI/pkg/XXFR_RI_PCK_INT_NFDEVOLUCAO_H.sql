--DROP PACKAGE XXFR_RI_PCK_INTEGRACAO_AR;
create or replace PACKAGE XXFR_RI_PCK_INT_NFDEVOLUCAO AS
  
  procedure print_log(msg in varchar2);
  procedure initialize ;

  procedure limpa_interface(
    p_invoice_id   in  number,
    x_retorno           out varchar2
  );

  procedure gera_interface(
    x_retorno           out varchar2
  );
  procedure insere_interface_header(
    x_retorno           out varchar2
  );
  procedure insere_interface_lines (
    x_retorno           out varchar2
  );
  procedure insere_interface_parent_header(
    x_retorno               out varchar2
  );
  procedure insere_interface_parent_lines(
    x_retorno           out varchar2
  ); 
  procedure retornar_clob( 
    p_id_integracao_detalhe in xxfr.xxfr_integracao_detalhe.id_integracao_detalhe%type, 
    p_retorno             in out clob
  );
  
  procedure auto_invoice(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  );
  
  procedure processar_devolucao(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  );
  
  procedure main(
    p_cd_chave_acesso in varchar2,
    x_retorno         out varchar2
  );
  
  function retorna_cc_rem_fixar(
    p_item_id         in number,
    p_organization_id in number
  ) return number;

END;
/
