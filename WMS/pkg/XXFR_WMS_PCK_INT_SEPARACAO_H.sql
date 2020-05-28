create or replace PACKAGE XXFR_WMS_PCK_INT_SEPARACAO IS
-- +==========================================================================+
-- |                                                                 
-- |                                                                 
-- | CRIADO POR              DATA                  REF                                          
-- |   DANIEL PIMENTA      25/10/2019            Ticket#10108885    
-- |                                                                 
-- | ALTERADO POR            DATA                  REF                        
-- |   [Nome]                [dd/mm/yyyy]          [ticket#]     
-- |      [comentários sobre a alteração]         
-- |                                  
-- +==========================================================================+

  type rec_linhas is record (
    cd_referencia_origem_linha varchar2(50),
    tp_referencia_origem_linha varchar2(50),
    nu_ordem_venda             varchar2(50),
    cd_tipo_ordem_venda        varchar2(50),
    nu_ordem_venda_linha       varchar2(50),
    tp_separacao               varchar2(50),
    cd_item                    varchar2(50),
    vl_area_separacao          varchar2(50),
    qt_separacao               varchar2(50),
    vl_plantas_m2              varchar2(50),
    vl_area_disp_prog_insumos  varchar2(50),
    gr_area_separacao          varchar2(50)
  );

  type array_linhas is varray(20) of rec_linhas;

  type rec_ordem_separacao is record (
    cd_referencia_origem        varchar2(50),
    tp_referencia_origem        varchar2(50),
    cd_organizacao_inventario   varchar2(50),
    destino_ordem_separacao     varchar2(50),
    end_estoque_dest_separacao  varchar2(50),
    linhas                      array_linhas
  );

  type rec_proc_separacao is record (  
    cd_unidade_operacional   varchar2(50),
    ordemSeparacao           rec_ordem_separacao
  );


  procedure print_log(msg   in Varchar2);

  procedure retornar_clob( 
    p_id_integracao_detalhe in xxfr.xxfr_integracao_detalhe.id_integracao_detalhe%type, 
    p_retorno             in out clob
  );

  --procedure carrega_dados(
	--	p_id_integracao_detalhe IN  NUMBER,
  --  x_retorno               OUT varchar2
  --);

  procedure main(
    p_id_integracao_detalhe IN  NUMBER,
    p_commit                in boolean,
    p_retorno               out clob
  );

  procedure processar_separacao(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  );

END XXFR_WMS_PCK_INT_SEPARACAO;
/
