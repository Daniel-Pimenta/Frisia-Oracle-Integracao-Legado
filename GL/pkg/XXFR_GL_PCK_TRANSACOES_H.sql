create or replace package xxfr_gl_pck_transacoes as
             
  procedure print_out(msg   in varchar2);

  procedure initialize;

  procedure gravar_interface(
    p_gl_interface     in apps.gl_interface%rowtype,
    x_retorno          out varchar2
  );
                             
  procedure processa_interface(
    p_livro       in varchar2,
    p_numero_lote in number, 
    p_origem      in varchar2,
    x_request_id  out number,
    x_retorno     out varchar2
  );
      
  PROCEDURE populate_interface_control(
    user_je_source_name       VARCHAR2,
    group_id                  IN OUT NOCOPY   NUMBER,
    set_of_books_id           NUMBER,
    interface_run_id          IN OUT NOCOPY  NUMBER,
    table_name                VARCHAR2 DEFAULT NULL,
    processed_data_action     VARCHAR2 DEFAULT NULL
  );
                                       
end xxfr_gl_pck_transacoes;