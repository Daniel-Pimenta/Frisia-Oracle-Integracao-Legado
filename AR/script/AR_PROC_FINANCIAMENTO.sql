SET SERVEROUTPUT ON
DECLARE

--8288	57590
  p_seq_cab NUMBER := -357;
  p_seq_det NUMBER := -381;

  isNew     boolean := true;
  p_servico varchar2(200) := 'PROCESSAR_FINANCIAMENTO';
  OK        BOOLEAN;
  
  x_retorno clob; 

  STR_JSON VARCHAR2(32000) := ('
{
  "idTransacao" : "481714",
  "versaoPayload" : "1.0",
  "sistemaOrigem" : "SIF.FIN",
  "codigoServico" : "PROCESSAR_FINANCIAMENTO",
  "usuario" : null,
  "processarFinanciamento" : {
    "codigoUnidadeOperacional" : "UO_FRISIA",
    "financiamento" : {
      "tipoProcesso" : "FIN AGRIC BANCO INSUMO E MOB",
      "codigoFinanciamento" : "6236",
      "codigoCliente" : "1397",
      "codigoAtividadeRural" : "AGRICULTURA",
      "codigoCultura" : "TRIGO",
      "codigoSafra" : "2020/2020",
      "valorLiberacao" : 33155375,
      "contaLiberacao" : null,
      "contaOrigemRecurso" : "8001",
      "dataLiberacao" : "2020-04-15",
      "usoFinanciamento" : "INSUMO",
      "valorFinalidadeBloqueio" : 700,
      "valorBloqueioMaoObra" : 300,
      "valorRetencao" : 1100,
      "codigoMetodoPagamentoMaoObra" : "999.CONTA.MOVIMENTO",
      "codigoCondicaoPagamentoMaoObra" : "A VISTA",
      "codigoTipoContrato" : "2.COOPERADO",
      "codigoDestinacaoRecurso" : "RACAO",
      "taxas" : [ {
        "codigo" : "TAXA ADM",
        "valor" : 15
      } ],
      "parcelas" : [ {
        "dataParcela" : "2020-06-30",
        "valorParcela" : 1000
      } ],
      "valorJuros" : 14,
      "valorLongoPrazo" : 0
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
      p_seq_cab,
      SYSDATE,
      'DANIEL.PIMENTA',
      'PL/SQL Developer',
      SYSDATE,
      'DANIEL.PIMENTA',
      'PL/SQL Developer',
      'TESTE',
      'EBS',
      1,
      p_servico,
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
      p_servico,
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
    XXFR_AR_PCK_INT_FINANCIAMENTO.PROCESSAR_LIBERA_FINANCIAMENTO ( 
      p_id_integracao_detalhe   => p_seq_det,
      p_retorno                 => x_retorno
    );
    PRINT_OUT(x_retorno);
  ELSE
    ROLLBACK;
  END IF;
  
END;
/




/*

select * from xxfr_integracao_detalhe 
where 1=1
  and CD_INTERFACE_DETALHE='PROCESSAR_FINANCIAMENTO'
order by 
  DT_CRIACAO desc
;
  
select ds_escopo, nvl(ds_log,' ') log
from xxfr_logger_log
where 1=1
  --and upper(ds_escopo) like '%FINANCIAMENTO%'
  and DT_CRIACAO >= sysdate -0.25
order by 
  DT_CRIACAO desc
;

*/

