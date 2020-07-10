create or replace PACKAGE XXFR_GL_PCK_INT_LOTE_CONTABIL AS

  type gl_movimento_rec is record(
    tipoReferenciaOrigem    varchar2(50),     -- "UBS_GERACAO_COBRANCA",
    codigoReferenciaOrigem  varchar2(50),     -- "26",
    tipoTransacao           varchar2(50),     -- "DEBITO",
    chaveContabil           varchar2(50),     -- "01.0001.100000000.0000.00.000.0.0.0",
    valor                   number,       -- 735,
    descricao               varchar2(200) -- "PRESTACAO DE SERVICOS DA UBS/LAS"
  );
  type tab_movimento is table of gl_movimento_rec index by binary_integer;

  type gl_rec is record (
    livroContabil         varchar2(50),   -- "FRISIA_FISCAL",
    dataCriacao           varchar2(10),   -- "2020-06-09",
    dataContabil          varchar2(10),   -- "2020-06-09",
    moeda                 varchar2(3),    -- "BRL",
    categoriaLancamento   varchar2(50),   -- "XXFR_UBL3701",
    origemLancamento      varchar2(50),   -- "XXFR_UBL",
    descricao             varchar2(200),  -- "COBRANCA DO LAS",  
    movimento             tab_movimento
  );

  procedure monta_json (
    p_gl_rec                in  XXFR_GL_PCK_INT_LOTE_CONTABIL.gl_rec,
    x_id_integracao_detalhe out number
  );

  procedure print_log(msg   in Varchar2);
  
  procedure retornar_clob( 
    p_id_integracao_detalhe in xxfr.xxfr_integracao_detalhe.id_integracao_detalhe%type, 
    p_retorno             in out clob
  );

  procedure carrega_dados;
  
  procedure main(
    p_gl_rec                in  xxfr_gl_pck_int_lote_contabil.gl_rec,
    x_id_integracao_detalhe out number,
    x_retorno               out varchar2
  );
  
  procedure processar(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  );
  
  function monta_interface(r1 in XXFR_GL_VW_INT_LOTECONTABIL%rowtype) return boolean;

end XXFR_GL_PCK_INT_LOTE_CONTABIL;
/