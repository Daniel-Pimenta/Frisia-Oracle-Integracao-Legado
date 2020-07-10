create or replace PACKAGE "XXFR_AP_PCK_INT_ADIANTAMENTOS" is

   PROCEDURE PROCESSAR_ADIANTAMENTO( p_id_integracao_detalhe   in   number
                                   , p_retorno                 out  clob);

end XXFR_AP_PCK_INT_ADIANTAMENTOS;

