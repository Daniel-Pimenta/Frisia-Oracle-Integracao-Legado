SET SERVEROUTPUT ON
DECLARE

  p_seq_cab NUMBER := -294;
  p_seq_det NUMBER := -318;
  isNew     boolean := false;
  OK        BOOLEAN;
  
  
  --Nota de Entrada            :CMP014
  --Devolução da NF de Entrada :DCO009

  STR_JSON VARCHAR2(32000) := ('
  {
    "idTransacao": -1,
    "versaoPayload": 1,
    "sistemaOrigem": "SIF.EGR",
    "codigoServico": "PROCESSAR_NF_DEVOLUCAO_FORNECEDOR",
    "usuario": "DANIEL.PIMENTA",
    "processarNotaFiscalDevolucao": {
      "codigoUnidadeOperacional": "UO_FRISIA",
      "aprovaRequisicao": "SIM",
      "notaFiscalDevolucao": {
        "codigoChaveAcesso": "250620201608",
        "tipoReferenciaOrigem": "EGR_NOTAEMI_PROPRIEDADE",
        "codigoReferenciaOrigem": "344854.1",
        "linha": {
          "numero": 1,
          "quantidade": 1,
          "unidadeMedida": "KG"
        }
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
  
  if isNew then
    select min(ID_INTEGRACAO_CABECALHO) -1 into  p_seq_cab from xxfr_integracao_cabecalho;
    select min(ID_INTEGRACAO_DETALHE) -1 into  p_seq_det from xxfr_integracao_detalhe;
  end if;
  --
  delete xxfr_integracao_detalhe   WHERE ID_INTEGRACAO_DETALHE = p_seq_det;
  delete xxfr_integracao_cabecalho WHERE ID_INTEGRACAO_CABECALHO = p_seq_cab;
  --
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
      'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR',
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
      'PROCESSAR_NF_DEVOLUCAO_FORNECEDOR',
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
  and ID_INTEGRACAO_DETALHE = 6019
  --and CD_INTERFACE_DETALHE like '%ENTREGA%'
order by 3 desc;
*/


/*
  select * from cll_f189_invoices_interface 
  where 1=1
    and INVOICE_TYPE_CODE = 'DCO009'
    --and source like 'XXFR%'
  order by creation_date desc;
*/

--select * from cll_f189_invoice_lines_iface where interface_invoice_id in (
--select interface_invoice_id from cll_f189_invoices_interface where source like 'XXFR%');
