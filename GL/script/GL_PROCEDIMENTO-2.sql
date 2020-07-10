set SERVEROUTPUT ON;
declare
  p_gl_rec                  XXFR_GL_PCK_INT_LOTE_CONTABIL.gl_rec;
  x_id_integracao_detalhe   number;
  x_retorno                 varchar2(3000);
begin
  p_gl_rec.livroContabil         := 'FRISIA_FISCAL';
  p_gl_rec.dataCriacao           := '2020-07-06';
  p_gl_rec.dataContabil          := '2020-07-06';
  p_gl_rec.moeda                 := 'BRL';
  p_gl_rec.categoriaLancamento   := 'XXFR_UBL3701';
  p_gl_rec.origemLancamento      := 'XXFR_UBL';
  p_gl_rec.descricao             := 'COBRANCA DO LAS'; 
  --
  p_gl_rec.movimento(1).tipoReferenciaOrigem    :='UBS_GERACAO_COBRANCA';
  p_gl_rec.movimento(1).codigoReferenciaOrigem  :='26';
  p_gl_rec.movimento(1).tipoTransacao           :='DEBITO';
  p_gl_rec.movimento(1).chaveContabil           :='01.0001.100000000.0000.00.000.0.0.0';
  p_gl_rec.movimento(1).valor                   :=735;
  p_gl_rec.movimento(1).descricao               :='PRESTACAO DE SERVICOS DA UBS/LAS';
  -- 
  p_gl_rec.movimento(2).tipoReferenciaOrigem    :='UBS_GERACAO_COBRANCA';
  p_gl_rec.movimento(2).codigoReferenciaOrigem  :='26';
  p_gl_rec.movimento(2).tipoTransacao           :='CREDITO';
  p_gl_rec.movimento(2).chaveContabil           :='01.0001.100000000.0000.00.000.0.0.0';
  p_gl_rec.movimento(2).valor                   :=735;
  p_gl_rec.movimento(2).descricao               :='PRESTACAO DE SERVICOS DA UBS/LAS';
  
  XXFR_GL_PCK_INT_LOTE_CONTABIL.main(
    p_gl_rec,
    x_id_integracao_detalhe,
    x_retorno
  );
  
end;
/
-- Aqui vc pode ver as mensagens de erro 
SELECT RETORNO_PROCESSAMENTO, IDX_MSG, TP_MENSAGEM, MENSAGEM FROM XXFR_INT_VW_RETORNO
WHERE 1=1
  and id_integracao_detalhe = -388
;
