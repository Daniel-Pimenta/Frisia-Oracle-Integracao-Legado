                                                                                                                  SET SERVEROUTPUT ON
DECLARE

  p_seq_det NUMBER := -166;
  p_seq_cab NUMBER := -72;
  OK        BOOLEAN;

        --> GL_INTERFACE.REFERENCE1,
        --> GL_INTERFACE.REFERENCE2,

  STR_JSON VARCHAR2(32000) := ('
{
  "idTransacao": -1,
  "versaoPayload": 1.0,
  "sistemaOrigem": "SIF.VEI",
  "codigoServico": "PROCESSAR_CONTABILIZACAO",
  "usuario": "renato.sampaio",
  "processarContabilizacao": {
    "livroContabil": "FRISIA_FISCAL",
    "dataCriacao": "2019-12-10",
    "dataContabil": "2019-12-10",
    "moeda": "BRL",
    "categoriaLancamento": "XXFR_VEI0080",
    "origemLancamento": "XXFR_VEI",
    "descricao":"*** INFORMAÇÕES DO LOTE",                                                  
    "movimentosContabeis": [
      {
        "codigoReferenciaOrigem": "415415",
        "tipoReferenciaOrigem": "UTILIZACAO_VEICULO", 
        "tipoTrasacao": "DEBITO",
        "chaveContabil": "01.0012.111004099.0075.00.000.0.0.0",
        "valor": 15.15,
        "descricao":"*** INFORMAÇÕES DO LANCAMENTO"                                                 
      },
      {
        "codigoReferenciaOrigem": "415415",
        "tipoReferenciaOrigem": "UTILIZACAO_VEICULO",
        "tipoTrasacao": "CREDITO",
        "chaveContabil": "01.0012.111004099.0075.00.000.0.0.0",
        "valor": 15.15,
        "descricao":"*** INFORMAÇÕES DO LANCAMENTO"
      }                                            
    ]
  }
}
');

  procedure print_out(msg varchar2) is
  begin
    DBMS_OUTPUT.PUT_LINE(msg);
  end;

BEGIN
  OK := TRUE;
  
  --select min(ID_INTEGRACAO_CABECALHO) -1 into p_seq_cab from xxfr_integracao_cabecalho;
  --select min(ID_INTEGRACAO_DETALHE) -1 into  p_seq_det from xxfr_integracao_detalhe;
  
  delete xxfr_integracao_detalhe   WHERE ID_INTEGRACAO_DETALHE = p_seq_det;
  delete xxfr_integracao_cabecalho WHERE ID_INTEGRACAO_CABECALHO = p_seq_cab;
  
  BEGIN
    insert into xxfr_integracao_cabecalho (
      ID_INTEGRACAO_CABECALHO, 
      DT_CRIACAO, 
      NM_USUARIO_CRIACAO, 
      CD_PROGRAMA_CRIACAO, 
      DT_ATUALIZACAO, 
      NM_USUARIO_ATUALIZACAO, 
      CD_PROGRAMA_ATUALIZACAO, 
      CD_SISTEMA_ORIGEM, 
      CD_SISTEMA_DESTINO, 
      NR_SEQUENCIA_FILA, 
      CD_INTERFACE, 
      CD_CHAVE_INTERFACE, 
      IE_STATUS_INTEGRACAO, 
      DT_CONCLUSAO_INTEGRACAO
    ) values (
      p_seq_cab,
      SYSDATE,
      'DANIEL.PIMENTA',
      'PL/SQL Developer',
      SYSDATE,
      'DANIEL.PIMENTA',
      'PL/SQL Developer',
      'SIF.VEI',
      'EBS',
      1,
      'PROCESSAR_CONTABILIZACAO',
      NULL,
      'NOVO',
      NULL
    );
    PRINT_OUT('ID CABECALHO CRIADO:'||p_seq_cab);
  EXCEPTION
    WHEN OTHERS THEN
      PRINT_OUT('ERRO CABEÇALHO OTHERS :'||SQLERRM);
      OK := FALSE;
  END;
  BEGIN
    INSERT INTO xxfr_integracao_detalhe (
      ID_INTEGRACAO_DETALHE, 
      ID_INTEGRACAO_CABECALHO, 
      DT_CRIACAO, 
      NM_USUARIO_CRIACAO, 
      DT_ATUALIZACAO, 
      NM_USUARIO_ATUALIZACAO, 
      CD_INTERFACE_DETALHE, 
      IE_STATUS_PROCESSAMENTO, 
      DT_STATUS_PROCESSAMENTO, 
      --ID_SOA_COMPOSITE, 
      --NM_SOA_COMPOSITE, 
      DS_DADOS_REQUISICAO, 
      DS_DADOS_RETORNO
    ) VALUES (
      p_seq_det,
      p_seq_cab,
      SYSDATE,
      'DANIEL.PIMENTA',
      SYSDATE,
      'DANIEL.PIMENTA',
      'PROCESSAR_CONTABILIZACAO',
      'PENDENTE',
      SYSDATE,
      --NULL,
      --NULL,
      STR_JSON,
      NULL
    );
    PRINT_OUT('ID DETALHE CRIADO:'||p_seq_det);
  EXCEPTION
    WHEN OTHERS THEN
      PRINT_OUT('ERRO DETALHE OTHERS :'||SQLERRM);
      PRINT_OUT('  ID DETALHE:'||p_seq_det);
      OK := FALSE;
  END;
  IF OK THEN
    COMMIT;
  ELSE
    ROLLBACK;
  END IF;
END;
/

/*
SELECT * FROM xxfr_integracao_detalhe 
WHERE 1=1
  --and ID_INTEGRACAO_DETALHE = -166
  and CD_INTERFACE_DETALHE = 'PROCESSAR_CONTABILIZACAO'
order by 3 desc;
*/

delete xxfr_integracao_detalhe where CD_INTERFACE_DETALHE = 'PROCESSAR_CONTABILIZACAO';
delete xxfr_integracao_cabecalho where CD_INTERFACE = 'PROCESSAR_CONTABILIZACAO';
