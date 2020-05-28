--DROP PACKAGE XXFR_RI_PCK_INTEGRACAO_AR;
create or replace PACKAGE XXFR_RI_PCK_DEVOLUCAO_INSUMOS AS
  
  type tp_linha is record (  
    cd_referencia_origem_linha  varchar2(20), 
    tp_referencia_origem_linha  varchar2(100),
    --
    nu_linha_devolucao          varchar2(20), 
    nu_cnpj_emissor             varchar2(20), 
    nu_nota_fiscal              varchar2(20), 
    cd_serie                    varchar2(20), 
    nu_linha_nota_fiscal        varchar2(20), 
    qt_quantidade               number,
    cd_unidade_medida           varchar2(20)
  );
  type array_linha is varray(20) of tp_linha;

  type tp_nf_devolucao is record (  
    cd_referencia_origem        varchar2(20), 
    tp_referencia_origem        varchar2(100),  
    --
    cd_fornecedor               varchar2(50), 
    cd_local_fornecedor         varchar2(20), 
    nu_propriedade_fornecedor   varchar2(20), 
    cd_tipo_recebimento         varchar2(20), 
    linha                       array_linha
  );
  type array_nf_devolucao is varray(20) of tp_nf_devolucao;

  type tp_proc_devolucao is record (  
    cd_unidade_operacional varchar2(20),
    nf_devolucao           array_nf_devolucao
  );
  
  procedure print_log(msg in varchar2);
  
  procedure initialize ;
  procedure main;
  procedure insere_interface_header(
    p_invoice_id in number,
    p_item_id    in number, 
    p_quantity   in number,
    x_retorno    out varchar2
  );
  procedure insere_interface_parent_header(x_retorno out varchar2);
  procedure insere_interface_lines(x_retorno out varchar2);
  procedure insere_interface_parent_lines(x_retorno out varchar2); 
  /*
  procedure limpa_interface(
    x_retorno           out varchar2
  );
  
  procedure retornar_clob( 
    p_id_integracao_detalhe in xxfr.xxfr_integracao_detalhe.id_integracao_detalhe%type, 
    p_retorno             in out clob
  );
  
  procedure processar_devolucao(
    p_id_integracao_detalhe IN  NUMBER,
    p_retorno               out clob
  );
  
  procedure gera_interface(
    p_nf_devolucao      in tp_nf_devolucao,
    x_retorno           out varchar2
  );
  
  procedure insere_interface_parent_lines(
    x_retorno           out varchar2
  ); 
  
  procedure recupera_inf_diversas(
    p_customer_trx_id  in number,
    p_vendor_site_id   in number,
    p_warehouse_id     in number,
    p_cust_trx_type_id in number,
    x_retorno          out varchar
  );

  function retorna_cc_rem_fixar(
    p_item_id         in number,
    p_organization_id in number
  ) return number;  
  */
  
END XXFR_RI_PCK_DEVOLUCAO_INSUMOS;
/
