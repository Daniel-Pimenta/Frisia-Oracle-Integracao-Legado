create or replace package body IBY_FD_EXTRACT_EXT_PUB as
  /* $Header: ibyfdxeb.pls 120.2 2006/09/20 18:52:12 frzhang noship $ */

 
  --
  -- This API is called once only for the payment instruction.
  -- Implementor should construct the extract extension elements at the payment instruction level as a SQLX XML Aggregate
  -- and return the aggregate.
  --
  -- Below is an example implementation:
  /*
    FUNCTION Get_Ins_Ext_Agg(p_payment_instruction_id IN NUMBER)
    RETURN XMLTYPE
    IS
      l_ins_ext_agg XMLTYPE;

      CURSOR l_ins_ext_csr (p_payment_instruction_id IN NUMBER) IS
      SELECT XMLConcat(
               XMLElement("Extend",
                 XMLElement("Name",  ext_table.attr_name1),
                 XMLElement("Value", ext_table.attr_value1)),
               XMLElement("Extend",
                 XMLElement("Name",  ext_table.attr_name2),
                 XMLElement("Value", ext_table.attr_value2))
             )
        FROM your_pay_instruction_lvl_table ext_table
       WHERE ext_table.payment_instruction_id = p_payment_instruction_id;

    BEGIN
      OPEN l_ins_ext_csr (p_payment_instruction_id);
      FETCH l_ins_ext_csr INTO l_ins_ext_agg;
      CLOSE l_ins_ext_csr;
      RETURN l_ins_ext_agg;
    END Get_Ins_Ext_Agg;
  */
  function get_ins_ext_agg(p_payment_instruction_id in number) return xmltype is
  begin
    --(++) CLL_F033 Code Start
    declare
      l_ext_agg    xmltype;
      l_xxfr_agg   xmltype;
      l_org_id     iby_pay_instructions_all.org_id%type;
    begin
      begin
        select nvl(ipi.org_id, ip.org_id)
        into l_org_id
        from 
          iby_pay_instructions_all ipi
          ,iby_payments_all        ip
        where 1=1
          and ipi.payment_instruction_id = p_payment_instruction_id
          and ipi.payment_instruction_id = ip.payment_instruction_id(+)
          and rownum = 1;
      end;
      if (jg_zz_shared_pkg.get_country(l_org_id, null, null) = 'BR') then
        /* XSCN e XXFR Begin */
        -- l_ext_agg := cll_f033_iby_extract_ext_pub.get_ins_ext_agg(p_payment_instruction_id);
        SELECT xmlconcat(
          cll_f033_iby_extract_ext_pub.get_ins_ext_agg(p_payment_instruction_id)
          ,xscn_9031_iby_extract_ext_pub.get_ins_ext_agg(p_payment_instruction_id)
          --,xxfr_iby_extract_ext_pub.get_ins_ext_agg(p_payment_instruction_id)
        )
        INTO l_ext_agg
        FROM dual;
        /* XSCN e XXFR End */
        if (l_ext_agg is not null) then
          return l_ext_agg;
        end if;
      end if;
    end;
    --(++) CLL_F033 Code End
    return null;
  end get_ins_ext_agg;

  --
  -- This API is called once per payment.
  -- Implementor should construct the extract extension elements at the payment level as a SQLX XML Aggregate
  -- and return the aggregate.
  --
  function get_pmt_ext_agg(p_payment_id in number) return xmltype is
  begin
    --(++) CLL_F033 Code Start
    declare
      l_ext_agg xmltype;
      l_xxfr_agg   xmltype;
      l_org_id  iby_payments_all.org_id%type;
    begin
      begin
        select org_id
        into l_org_id
        from iby_payments_all
        where payment_id = p_payment_id;
      end;
      --
      if (jg_zz_shared_pkg.get_country(l_org_id, null, null) = 'BR') then
        /* XSCN e XXFR Begin */
        -- l_ext_agg := cll_f033_iby_extract_ext_pub.get_pmt_ext_agg(p_payment_id);        
        select xmlconcat(
          cll_f033_iby_extract_ext_pub.get_pmt_ext_agg(p_payment_id)
          ,xscn_9031_iby_extract_ext_pub.get_pmt_ext_agg(p_payment_id)
          --,xxfr_iby_extract_ext_pub.get_pmt_ext_agg(p_payment_id)
        )
        into l_ext_agg
        from dual;
        /* XSCN e XXFR End */
        if (l_ext_agg is not null) then
          return l_ext_agg;
        end if;
      end if;
      --
    end;
    --(++) CLL_F033 Code End
    return null;
  end get_pmt_ext_agg;

  --
  -- This API is called once per document payable.
  -- Implementor should construct the extract extension elements at the document level as a SQLX XML Aggregate
  -- and return the aggregate.
  --
  function get_doc_ext_agg(p_document_payable_id in number) return xmltype is
  begin
    --(++) CLL_F033 Code Start
    declare
      l_ext_agg xmltype;
      l_org_id  iby_docs_payable_all.org_id%type;
    begin
      begin
        select org_id
        into l_org_id
        from iby_docs_payable_all
        where document_payable_id = p_document_payable_id;
      end;
      if (jg_zz_shared_pkg.get_country(l_org_id, null, null) = 'BR') then
        /* XSCN Begin */
        -- l_ext_agg := cll_f033_iby_extract_ext_pub.get_doc_ext_agg(p_document_payable_id);
        select xmlconcat(
          cll_f033_iby_extract_ext_pub.get_doc_ext_agg(p_document_payable_id),
          xscn_9031_iby_extract_ext_pub.get_doc_ext_agg(p_document_payable_id)
        )
        into l_ext_agg
        from dual;
        /* XSCN End */
        if (l_ext_agg is not null) then
          return l_ext_agg;
        end if;
      end if;
    end;
    --(++) CLL_F033 Code End
    return null;
  end get_doc_ext_agg;

  --
  -- This API is called once per document payable line.
  -- Implementor should construct the extract extension elements at the doc line level as a SQLX XML Aggregate
  -- and return the aggregate.
  --
  -- Parameters:
  --   p_document_payable_id: primary key of IBY iby_docs_payable_all table
  --   p_line_number: calling app doc line number. For AP this is ap_invoice_lines_all.line_number.
  --
  -- The combination of p_document_payable_id and p_line_number can uniquely locate a document line.
  -- For example if the calling product of a doc is AP p_document_payable_id can locate
  -- iby_docs_payable_all/ap_documents_payable.calling_app_doc_unique_ref2, which is ap_invoice_all.invoice_id. 
  -- The combination of invoice_id and p_line_number will uniquely identify the doc line.
  --
  function get_docline_ext_agg(
    p_document_payable_id in number,
    p_line_number         in number
  ) return xmltype is
  begin
    return null;
  end get_docline_ext_agg;

  --
  -- This API is called once only for the payment process request.
  -- Implementor should construct the extract extension elements at the payment request level as a SQLX XML Aggregate
  -- and return the aggregate.
  --
  function get_ppr_ext_agg(p_payment_service_request_id in number) return xmltype is
  begin
    return null;
  end get_ppr_ext_agg;

end IBY_FD_EXTRACT_EXT_PUB;