SET SERVEROUTPUT ON
DECLARE

  p_seq_det NUMBER  := -139;
  p_seq_cab NUMBER  := -66;
  isNew     boolean := false;
  
  OK        BOOLEAN;

  STR_JSON VARCHAR2(32000) := ('
{
  "idTransacao": -1,
  "versaoPayload": 1.0,
  "sistemaOrigem": "SIF.EGR",
  "codigoServico": "PROCESSAR_ORDEM_SEPARACAO_SEMENTE",
  "usuario": null,
  "processarOrdemSeparacao": {
    "codigoUnidadeOperacional": "UO_FRISIA",
    "ordemSeparacao": {
      "codigoReferenciaOrigem": "515126",
      "tipoReferenciaOrigem": "SIF.DAT.SOLICITACAO_RETIRADA",
      "codigoOrganizacaoInventario": "029S",
      "destinoOrdemSeparacao": "E",
      "enderecoEstoqueDestinoSeparacao": null,  
      "linhas": [
        {
          "codigoReferenciaOrigemLinha": "515126.1", 
          "tipoReferenciaOrigemLinha" : "SIF.DAT.ITEM_SOLICITACAO_RETIRADA",
          "numeroOrdemVenda": 180,
          "codigoTipoOrdemVenda": "124_VENDA",
          "numeroOrdemVendaLinha": "1.1",
          "tipoSeparacao": "A", 
          "codigoItem": "150151",
          "areaParaSeparacao": 100.5,
          "quantidadeSeparacao": 14000,
          "plantasMetroQuadrado": 10,
          "areaDisponivelProgramacaoInsumos": 200,
          "grupoAreaSeparacao": 1414
        },
        {  
          "codigoReferenciaOrigemLinha": "515126.2", 
          "tipoReferenciaOrigemLinha" : "SIF.DAT.ITEM_SOLICITACAO_RETIRADA",
          "numeroOrdemVenda": 92,
          "codigoTipoOrdemVenda": "011_VENDA",
          "numeroOrdemVendaLinha": "1.1",
          "tipoSeparacao": "A", 
          "codigoItem": "27974",
          "areaParaSeparacao": 100.5,
          "quantidadeSeparacao": 1000,
          "plantasMetroQuadrado": 10,
          "areaDisponivelProgramacaoInsumos": 200,
          "grupoAreaSeparacao": 1414
        }
      ]
    }
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
      print_out('Gerando novos Id"s...');
      select min(ID_INTEGRACAO_CABECALHO) -1 into p_seq_cab from xxfr_integracao_cabecalho;
      select min(ID_INTEGRACAO_DETALHE) -1   into p_seq_det from xxfr_integracao_detalhe;
    else
      print_out('Limpando detalhe...');
      delete xxfr_integracao_detalhe   WHERE ID_INTEGRACAO_DETALHE = p_seq_det;
      print_out('Limpando cab...');
      delete xxfr_integracao_cabecalho WHERE ID_INTEGRACAO_CABECALHO = p_seq_cab;
    end if;
    
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
      'SIF.DAT',
      'EBS',
      1,
      'PROCESSAR_ORDEM_SEPARACAO_SEMENTE',
      NULL,
      'NOVO',
      NULL
    );
    PRINT_OUT('ID CABECALHO:'||p_seq_cab);
  EXCEPTION
    WHEN OTHERS THEN
      PRINT_OUT('ERRO CABEÇALHO :'||SQLERRM);
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
      'PROCESSAR_ORDEM_SEPARACAO_SEMENTE',
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
--and ID_INTEGRACAO_DETALHE = 6115
and CD_INTERFACE_DETALHE = 'PROCESSAR_ORDEM_SEPARACAO_SEMENTE'
order by 3 desc;
*/


--select * from XXFR_WMS_ORDEM_SEPARACAO_HDR
--select * from XXFR_WMS_ORDEM_SEPARACAO_LIN;
--XXFR_WMS_PCK_ORDEM_SEPARACAO