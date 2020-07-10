create or replace package XXFR_AR_PCK_EXECUTA_PROCESSO is

  type tp_mensagens_tbl is table of varchar2(4000)  index by binary_integer;
  --
  TYPE taxas_rec_type IS RECORD (
        cd_taxa      varchar2(50)
       ,vl_taxa      number
  );
  --
  TYPE taxas_tbl_type IS TABLE OF taxas_rec_type
	INDEX BY BINARY_INTEGER;
  --
  TYPE parcelas_rec_type IS RECORD (
        vl_parcela   number
       ,dt_parcela   date
  );
  --
  TYPE parcelas_tbl_type IS TABLE OF parcelas_rec_type
	INDEX BY BINARY_INTEGER;

       
  procedure executa_concorrente (error_code             out number
                                ,error_buf              out varchar2
                                ,p_id_execucao_processo in     number);

  procedure executa_processo (error_code             in out number
                             ,error_buf              out    varchar2
                             ,p_id_execucao_processo in     number);

  procedure erro_evento_processo (p_exe_evento_processo in number
                                 ,p_mensagem            in varchar2);

  procedure conta_produtor (p_exe_evento_processo in number);

  procedure informacao_banco (p_exe_evento_processo in number);

  procedure informacao_uso_financiamento (p_exe_evento_processo in number);
  
  procedure informacao_cliente_fornecedor (p_exe_evento_processo in number);

  procedure recupera_metodo_pagamento_ar (p_exe_evento_processo in number);

  procedure recupera_cond_pagamento_ar_ap (p_exe_evento_processo in number);

  procedure informacao_transacao_ar (p_exe_evento_processo in number);

  procedure recebimento_diverso (p_exe_evento_processo in number);

  procedure recebimento_padrao (p_exe_evento_processo in number);

  procedure recebimento_padrao_aplicado (p_exe_evento_processo in number);

  procedure aviso_debito_ar (p_exe_evento_processo in number);

  procedure documento_padrao_ap (p_exe_evento_processo in number);

  procedure ajuste_ar (p_exe_evento_processo in number);

  procedure aplica_recebimento (p_exe_evento_processo in number);

  procedure aplica_reembolso (p_exe_evento_processo in number);

  procedure baixa_titulo_ap (p_exe_evento_processo in number);

  procedure longo_prazo_finaciamento_ar (p_exe_evento_processo in number);

  procedure parcelas_financiamento_ar (p_exe_evento_processo in number);

  procedure juros_financiamento_ar (p_exe_evento_processo in number);

  procedure lancamento_contabil (p_exe_evento_processo in number);

  procedure informacao_atividade_ar (p_exe_evento_processo in number);

  procedure atualiza_conta_passivo_ap (p_exe_evento_processo in number);
  
  procedure integra_financiamento (
    p_cd_processo                 in  varchar2
    ,p_commit_evento               in  varchar2 default 'S'         -- S-Sim N-Não
    ,p_metodo_execucao             in  varchar2 default 'CONCORRENTE'   -- ON-LINE ou CONCORRENTE
    ,p_dt_liberacao                in  date     default trunc(sysdate)
    ,p_cd_cooperado                in  varchar2
    ,p_cd_contrato                 in  varchar2
    ,p_ds_atividade_rural          in  varchar2
    ,p_nm_cultura                  in  varchar2 default null
    ,p_nm_safra                    in  varchar2 default null
    ,p_nm_proposito                in  varchar2 default null
    ,p_cd_banco_conta_liberacao    in  varchar2 default null
    ,p_cd_agencia_conta_liberacao  in  varchar2 default null
    ,p_cd_conta_liberacao          in  varchar2 default null
    ,p_cd_banco_conta_recurso      in  varchar2 default null
    ,p_cd_agencia_conta_recurso    in  varchar2 default null
    ,p_cd_conta_origem_recurso     in  varchar2 default null
    ,p_valor_liberado              in  number
    ,p_vl_retencao_custeio         in  number default 0
    ,p_condicao_pgto_custeio       in  varchar2 default null
    ,p_ds_uso_financiamento        in  varchar2 default null
    ,p_vl_uso_financiamento        in  number default 0
    ,p_vl_financiamento_mao_obra   in  number default 0
    ,p_cd_metodo_pgto_mao_obra     in  varchar2 default null
    ,p_condicao_pgto_mao_obra      in  varchar2 default null
    --
    ,p_cd_tipo_contrato            in  varchar2 default null
    ,p_cd_destinacao_recurso       in  varchar2 default null
    ,p_taxas                       in  taxas_tbl_type 
    ,p_parcelas                    in  parcelas_tbl_type 
    ,p_vl_juros                    in  number default null
    ,p_vl_longo_prazo              in  number default null
    --
    ,p_org_id                      in  number   default 81
    ,p_id_execucao_processo        in out number
    ,p_status                      out varchar2
    ,p_mensagem                    out tp_mensagens_tbl
  );

end;