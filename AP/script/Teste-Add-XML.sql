set SERVEROUTPUT ON;
declare
  
  ok         boolean;
  l_xml      xmltype;

begin
  xxfr_pck_variaveis_ambiente.inicializar('SQLAP','UO_FRISIA');
  
  l_xml := XXFR_IBY_EXTRACT_EXT_PUB.get_pmt_ext_agg(121008);
  --dbms_output.put_line('XML Payment:');
  --dbms_output.put_line(l_xml.getstringval());
  dbms_output.put_line('');
    
  l_xml := XXFR_IBY_EXTRACT_EXT_PUB.get_ins_ext_agg(12465);
  --dbms_output.put_line('XML Instruction:');
  --dbms_output.put_line(l_xml.getstringval());  

end;
/

