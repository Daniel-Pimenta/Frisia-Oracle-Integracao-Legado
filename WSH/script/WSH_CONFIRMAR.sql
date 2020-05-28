SET SERVEROUTPUT ON
DECLARE

  p_seq_det NUMBER :=-175;
  p_seq_cab NUMBER :=-97;
  OK        BOOLEAN;
  isNew     boolean := true;

  STR_JSON VARCHAR2(32000) := ('
{
  "idTransacao" : -1,
  "versaoPayload" : 1.0,
  "sistemaOrigem" : "SIF.TRI.ROMANEIO",
  "codigoServico" : "CONFIRMAR_ENTREGA",
  "usuario" : null,
  "confirmarEntrega" : {
    "nomePercurso" : "SOL.813893"
  }
} 
');

  procedure print_out(msg varchar2) is
  begin
    DBMS_OUTPUT.PUT_LINE(msg);
  end;

BEGIN
  OK := TRUE;
  BEGIN
    if (isNew) then
      select min(ID_INTEGRACAO_CABECALHO) -1 into  p_seq_cab from xxfr_integracao_cabecalho;
      select min(ID_INTEGRACAO_DETALHE) -1   into  p_seq_det from xxfr_integracao_detalhe;
    end if;
    
    print_out('Limpando detalhe...');
    delete xxfr_integracao_detalhe   WHERE ID_INTEGRACAO_DETALHE = p_seq_det;
    print_out('Limpando cab...');
    delete xxfr_integracao_cabecalho WHERE ID_INTEGRACAO_CABECALHO = p_seq_cab;
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
      P_SEQ_CAB,
      SYSDATE,
      'DANIEL.PIMENTA',
      'PL/SQL Developer',
      SYSDATE,
      'DANIEL.PIMENTA',
      'PL/SQL Developer',
      'SIF.DAT',
      'EBS',
      1,
      'CONFIRMAR_ENTREGA',
      NULL,
      'NOVO',
      NULL
    );
    PRINT_OUT('ID CABECALHO:'||p_seq_cab);
  EXCEPTION
    WHEN OTHERS THEN
      PRINT_OUT('ERRO CABEÇALHO OTHERS :'||SQLERRM);
      OK := FALSE;
  END;
  BEGIN
    --
    --select min(ID_INTEGRACAO_DETALHE) -1 into  p_seq_det from xxfr_integracao_detalhe;
    --
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
      'CONFIRMAR_ENTREGA',
      'PENDENTE',
      SYSDATE,
      --NULL,
      --NULL,
      STR_JSON,
      NULL
    );
    PRINT_OUT('ID DETALHE:'||p_seq_det);
  EXCEPTION
    WHEN OTHERS THEN
      PRINT_OUT('ERRO DETALHE OTHERS :'||SQLERRM);
      PRINT_OUT('ID DETALHE:'||p_seq_det);
      OK := FALSE;
  END;
  IF OK THEN
    COMMIT;
  ELSE
    ROLLBACK;
  END IF;
END;
/

--SELECT * FROM xxfr_integracao_detalhe ORDER BY 1;

