create or replace PACKAGE XXFR_RI_PCK_DEV_SIMB_INSUMOS AS
    
  procedure print_log(msg in varchar2);
  
  procedure initialize;
  
  procedure cria_json(
    p_chave_eletronica      in varchar2,
    p_linha                 in number,
    p_quantity              in number,
    p_uom                   in varchar2,
    p_operation_id          in number   default null,  
    p_organization_code     in varchar2 default null,
    p_user_name             in varchar2 default 'GERAL_INTEGRACAO',
    x_id_integracao_detalhe out number
  );
  
  procedure main(
    p_header_id   in number,
    x_retorno     out varchar2
  );
  
END XXFR_RI_PCK_DEV_SIMB_INSUMOS;
/
