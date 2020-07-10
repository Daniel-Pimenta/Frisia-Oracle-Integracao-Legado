create or replace PACKAGE XXFR_INV_PCK_DEV_SIMB_INSUMOS AS
  --TYPE header_type  xxfr_dev_simb_insumos_header_v%ROWTYPE;
  
  procedure processa_header(
    p_header_tab  in  XXFR_OPM_VW_DEV_SIMB_INSUMOS_H%ROWTYPE,
    x_retorno     out varchar2
  );

  procedure processa_lines(
    p_lines_tab  in  XXFR_OPM_VW_DEV_SIMB_INSUMOS_L%ROWTYPE,
    x_retorno     out varchar2
  );

  procedure processar(
 	  p_header_id 		in number,
	  x_retorno   		out varchar2
  );  

  procedure gera_om (
    p_header_id     in number,
    x_oe_header_id  out number,
    x_retorno       out varchar2
  );
  
  procedure gera_ri(
    p_header_id     in number,
    x_retorno       out varchar2
  );
  
  function f1(v1 in number, v2 in number) return varchar2;

END XXFR_INV_PCK_DEV_SIMB_INSUMOS;
/