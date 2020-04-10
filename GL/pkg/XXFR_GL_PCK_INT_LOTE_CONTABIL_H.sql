create or replace PACKAGE XXFR_GL_PCK_INT_LOTE_CONTABIL AS

  procedure print_out(msg   in Varchar2);
  
  procedure retornar_clob( 
    p_id_integracao_detalhe in xxfr.xxfr_integracao_detalhe.id_integracao_detalhe%type, 
    p_retorno             in out clob
  );

  procedure carrega_dados;
  
  procedure processar(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  );
  
  function monta_interface(r1 in XXFR_GL_VW_INT_LOTECONTABIL%rowtype) return boolean;

end XXFR_GL_PCK_INT_LOTE_CONTABIL;
/