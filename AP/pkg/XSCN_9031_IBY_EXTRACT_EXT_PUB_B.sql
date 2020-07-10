create or replace PACKAGE xscn_9031_iby_extract_ext_pub AS
  /* XSCN COPY OF: cll_f033_exts.pls 120.9 2013/04/23 18:58:48 vdzana noship $ */
  --
  -- $Header: XSCN_9031_IBY_EXTRACT_EXT_PUBS.pls 120.9.1 2013/04/23 18:58:48 ninecon noship $
  -- +=================================================================+
  -- |      NINECON CONSULTORES ASSOCIADOS, Sao Paulo, Brasil          |
  -- |                       All rights reserved.                      |
  -- +=================================================================+
  -- | FILENAME                                                        |
  -- |   XSCN_9031_IBY_EXTRACT_EXT_PUBS.pls                            |
  -- |                                                                 |
  -- | PURPOSE                                                         |
  -- |   SCN - Solucoes Complementares Ninecon                         |
  -- |                                                                 |
  -- | DESCRIPTION                                                     |
  -- |   AP - Pagamento Eletronico de NFFs em Moeda Estrangeira        |
  -- |                                                                 |
  -- | CREATED BY                                                      |
  -- |   Ninecon                                          2013/11/11   |
  -- |                                                                 |
  -- | ALTERED BY                                                      |
  -- |   Daniel Pimenta                                   2020/04/02   |
  -- |                                                                 |
  -- +=================================================================+
  --
  g_return_id       NUMBER;
  g_doc_attribute1  VARCHAR2(100);
  g_doc_attribute2  VARCHAR2(100);
  g_doc_attribute3  VARCHAR2(100);
  g_doc_attribute4  VARCHAR2(100);
  g_doc_attribute5  VARCHAR2(100);
  g_doc_attribute6  VARCHAR2(100);
  g_doc_attribute7  VARCHAR2(100);
  g_doc_attribute8  VARCHAR2(100);
  g_doc_attribute9  VARCHAR2(100);
  g_doc_attribute10 VARCHAR2(100);

  FUNCTION get_jl_barcode(p_bank_collection_id IN jl_br_ap_collection_docs_all.bank_collection_id%TYPE) RETURN VARCHAR2;

  FUNCTION get_bar_code(p_document_payable_id NUMBER) RETURN VARCHAR2;

  PROCEDURE generate_collection_returns(p_payment_id     NUMBER DEFAULT NULL
                                       ,p_doc_payable_id NUMBER DEFAULT NULL
                                       ,p_type           VARCHAR2 DEFAULT NULL
                                       ,p_return_id      OUT NOCOPY NUMBER);

  FUNCTION get_ins_ext_agg(p_payment_instruction_id IN NUMBER) RETURN xmltype;

  FUNCTION get_pmt_ext_agg(p_payment_id IN NUMBER) RETURN xmltype;

  FUNCTION get_doc_ext_agg(p_document_payable_id IN NUMBER) RETURN xmltype;

  -- Bug 16536302 - Start
  PROCEDURE get_pay_supplier_inf(p_doc_payable_id   IN NUMBER
                                ,p_pay_sup_doc_type OUT NOCOPY VARCHAR2
                                ,p_pay_sup_doc_num  OUT NOCOPY VARCHAR2
                                ,p_pay_sup_name     OUT NOCOPY VARCHAR2);
  --
  PROCEDURE get_inv_supplier_inf(p_doc_payable_id   IN NUMBER
                                ,p_inv_sup_doc_type OUT NOCOPY VARCHAR2
                                ,p_inv_sup_doc_num  OUT NOCOPY VARCHAR2
                                ,p_inv_sup_name     OUT NOCOPY VARCHAR2);
  -- Bug 16536302 - End
  FUNCTION xscn_get_pay_func_amount(p_payment_id IN NUMBER) RETURN NUMBER;

END xscn_9031_iby_extract_ext_pub;


create or replace PACKAGE BODY xscn_9031_iby_extract_ext_pub AS
  /* XSCN COPY OF: cll_f033_extb.pls 120.62 2013/06/27 18:31:23 vdzana noship $ */
  --
  -- $Header: XSCN_9031_IBY_EXTRACT_EXT_PUBB.pls 120.62.1 2013/06/27 18:31:23 ninecon noship $
  -- +=================================================================+
  -- |      NINECON CONSULTORES ASSOCIADOS, Sao Paulo, Brasil          |
  -- |                       All rights reserved.                      |
  -- +=================================================================+
  -- | FILENAME                                                        |
  -- |   XSCN_9031_IBY_EXTRACT_EXT_PUBB.pls                            |
  -- |                                                                 |
  -- | PURPOSE                                                         |
  -- |   SCN - Solucoes Complementares Ninecon                         |
  -- |                                                                 |
  -- | DESCRIPTION                                                     |
  -- |   AP - Pagamento Eletronico de NFFs em Moeda Estrangeira        |
  -- |                                                                 |
  -- | CREATED BY                                                      |
  -- |   Ninecon                                          2013/11/11   |
  -- |                                                                 |
  -- | ALTERED BY                                                      |
  -- |   Daniel Pimenta                                   2020/04/02   |
  -- |                                                                 |
  -- +=================================================================+
  --
  
  g_pay_exchange_rate     number := 1;  -- Daniel Pimenta - 27/04/2020
  
  FUNCTION get_cll_f033_bank_s(p_internal_bank_account_id NUMBER) RETURN NUMBER IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_return NUMBER;
  BEGIN
    SELECT acct_ext.attribute1
      INTO v_return
      FROM cll_f033_ce_bank_accounts_ext acct_ext
     WHERE acct_ext.bank_account_id = p_internal_bank_account_id
       FOR UPDATE;

    UPDATE cll_f033_ce_bank_accounts_ext acct_ext
       SET acct_ext.attribute1 = to_number(v_return) + 1
     WHERE acct_ext.bank_account_id = p_internal_bank_account_id;

    COMMIT;

    RETURN v_return;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_cll_f033_bank_s;

  PROCEDURE init_doc_attributes IS
  BEGIN
    g_doc_attribute1  := NULL;
    g_doc_attribute2  := NULL;
    g_doc_attribute3  := NULL;
    g_doc_attribute4  := NULL;
    g_doc_attribute5  := NULL;
    g_doc_attribute6  := NULL;
    g_doc_attribute7  := NULL;
    g_doc_attribute8  := NULL;
    g_doc_attribute9  := NULL;
    g_doc_attribute10 := NULL;
  END init_doc_attributes;

  FUNCTION get_jl_barcode(p_bank_collection_id IN jl_br_ap_collection_docs_all.bank_collection_id%TYPE) RETURN VARCHAR2 IS
    v_barcode VARCHAR2(100);
  BEGIN
    BEGIN
      EXECUTE IMMEDIATE 'SELECT BARCODE FROM JL_BR_AP_COLLECTION_DOCS_ALL WHERE BANK_COLLECTION_ID = ' ||
                        p_bank_collection_id
        INTO v_barcode;

      IF (v_barcode IS NULL) THEN
        RAISE no_data_found;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          EXECUTE IMMEDIATE 'SELECT ATTRIBUTE1 FROM CLL_F033_JL_BR_AP_COL_DOC_EXT WHERE BANK_COLLECTION_ID = ' ||
                            p_bank_collection_id
            INTO v_barcode;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
    END;

    RETURN v_barcode;

  END get_jl_barcode;

  FUNCTION get_bar_code(p_document_payable_id NUMBER) RETURN VARCHAR2 IS

    v_our_number    VARCHAR2(20);
    v_bar_code      VARCHAR2(100);
    v_aux           VARCHAR2(100);
    v_pe_branch_num VARCHAR2(100) := NULL;
    v_pe_acct_num   VARCHAR2(100) := NULL;

    v_method_type VARCHAR2(100) := NULL; -- ADDED BY GWISZNIE FOR REAL BANK BRAZIL - 2009/05/06 -

    r iby_docs_payable_all%ROWTYPE;
    p iby_payments_all%ROWTYPE;

  BEGIN
    init_doc_attributes;

    BEGIN
      SELECT *
        INTO r
        FROM iby_docs_payable_all idpa
       WHERE idpa.document_payable_id = p_document_payable_id;

      SELECT *
        INTO p
        FROM iby_payments_all ip
       WHERE ip.payment_id = r.payment_id;

      BEGIN
        IF (instr(p.ext_branch_number, '-') > 0) THEN
          v_pe_branch_num := substr(p.ext_branch_number, 1, instr(p.ext_branch_number, '-') - 1);
        ELSE
          v_pe_branch_num := p.ext_branch_number;
        END IF;

        SELECT iba.bank_account_num
          INTO p.ext_bank_account_number
          FROM iby_ext_bank_accounts iba
         WHERE iba.ext_bank_account_id = p.external_bank_account_id;

        IF (instr(p.ext_bank_account_number, '-') > 0) THEN
          v_pe_acct_num := substr(p.ext_bank_account_number, 1, instr(p.ext_bank_account_number, '-') - 1);
        ELSE
          v_pe_acct_num := p.ext_bank_account_number;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    BEGIN
      v_method_type := 'METHOD_TYPE_NULL';

      SELECT nvl(ipme.attribute1, 'METHOD_TYPE_NULL')
        INTO v_method_type
        FROM cll_f033_iby_payment_mtd_ext ipme
       WHERE ipme.payment_method_code = r.payment_method_code;
    EXCEPTION
      WHEN OTHERS THEN
        v_method_type := 'METHOD_TYPE_NULL';
    END;
    -- START BUG 13899031 LMEDEIROS
    /*
    SELECT GET_JL_BARCODE(JBAC.BANK_COLLECTION_ID)
          ,SUBSTR(JBAC.OUR_NUMBER,1,11) OUR_NUMBER
      INTO V_AUX
          ,V_OUR_NUMBER
      FROM JL_BR_AP_COLLECTION_DOCS_ALL JBAC
     WHERE JBAC.INVOICE_ID = R.CALLING_APP_DOC_UNIQUE_REF2
       AND JBAC.PAYMENT_NUM = R.CALLING_APP_DOC_UNIQUE_REF3;
     */
    SELECT get_jl_barcode(jbac.bank_collection_id)
          ,substr(jbac.our_number, 1, 11) our_number
      INTO v_aux
          ,v_our_number
      FROM jl_br_ap_collection_docs_all jbac
          ,ap_payment_schedules_all     apsa
     WHERE jbac.invoice_id = r.calling_app_doc_unique_ref2
       AND jbac.payment_num = r.calling_app_doc_unique_ref3
       AND jbac.bank_collection_id = apsa.global_attribute11
       AND jbac.invoice_id = apsa.invoice_id
       AND jbac.payment_num = apsa.payment_num;
    -- END BUG 13899031 LMEDEIROS
    g_doc_attribute10 := v_aux;
    v_bar_code        := REPLACE(v_aux, '.');

    IF p.int_bank_number = 237 THEN
      -- BRADESCO
      IF instr(v_aux, '.') <> 0 THEN
        -- MANUAL

        v_aux := substr(REPLACE(v_aux, '.', ''), 1, 80);

        IF substr(v_aux, 1, 3) = '237' THEN
          v_bar_code := lpad(substr(nvl(v_aux, '0'), 5, 4), 4, '0') || lpad(substr(nvl(v_aux, '0'), 9, 1), 1, '0') ||
                        lpad(substr(nvl(v_aux, '0'), 11, 1), 1, '0') || lpad(substr(nvl(v_aux, '0'), 12, 9), 9, '0') ||
                        lpad(substr(nvl(v_aux, '0'), 22, 2), 2, '0') || lpad(substr(nvl(v_aux, '0'), 24, 7), 7, '0') || '0' ||
                        lpad(substr(nvl(v_aux, '0'), 33, 1), 1, '0') || lpad(substr(nvl(v_aux, '0'), 4, 1), 1, '0') ||
                        lpad(' ', 13, ' ');

          g_doc_attribute1 := substr(nvl(v_aux, '0'), 38, 10);
          g_doc_attribute2 := substr(nvl(v_aux, '0'), 34, 4);
          g_doc_attribute3 := lpad(substr(nvl(v_aux, '0'), 5, 4), 4, '0'); -- BRANCH_NUM
          g_doc_attribute4 := lpad(substr(nvl(v_aux, '0'), 24, 7), 7, '0'); -- ACCT_NUM
          g_doc_attribute5 := lpad(substr(nvl(v_aux, '0'), 12, 9), 9, '0') ||
                              lpad(substr(nvl(v_aux, '0'), 22, 2), 2, '0');
          g_doc_attribute6 := lpad(substr(nvl(v_aux, '0'), 9, 1), 1, '0') ||
                              lpad(substr(nvl(v_aux, '0'), 11, 1), 1, '0');

        ELSIF substr(v_aux, 1, 3) <> '237' THEN
          --
          IF v_method_type = 'CONCESSIONER'
             AND length(v_aux) = 48 THEN
            -- BUG 10169588: Start
            --
            v_bar_code := substr(v_aux, 1, 11) || substr(v_aux, 13, 11) || substr(v_aux, 25, 11) ||
                          substr(v_aux, 37, 11); -- BUG 10169588: End
          ELSE
            --
            v_bar_code := lpad(substr(nvl(v_aux, '0'), 5, 5), 5, '0') || lpad(substr(nvl(v_aux, '0'), 11, 10), 10, '0') ||
                          lpad(substr(nvl(v_aux, '0'), 22, 10), 10, '0') ||
                          lpad(substr(nvl(v_aux, '0'), 33, 1), 1, '0') || lpad(substr(nvl(v_aux, '0'), 4, 1), 1, '0') ||
                          lpad(' ', 12, ' ');

            g_doc_attribute1 := substr(nvl(v_aux, '0'), 38, 10);
            g_doc_attribute2 := substr(nvl(v_aux, '0'), 34, 4);
            --
          END IF;
          --
        END IF;
      ELSE
        IF substr(v_aux, 1, 3) = '237' THEN
          v_bar_code := lpad(substr(nvl(v_aux, '0'), 20, 4), 4, '0') || lpad(substr(nvl(v_aux, '0'), 24, 2), 2, '0') ||
                        lpad(substr(nvl(v_aux, '0'), 26, 11), 11, '0') || lpad(substr(nvl(v_aux, '0'), 37, 7), 7, '0') || '0' ||
                        lpad(substr(nvl(v_aux, '0'), 5, 1), 1, '0') || lpad(substr(nvl(v_aux, '0'), 4, 1), 1, '0') ||
                        lpad(' ', 13, ' ');

          g_doc_attribute1 := substr(nvl(v_aux, '0'), 10, 10);
          g_doc_attribute2 := substr(nvl(v_aux, '0'), 6, 4);
          g_doc_attribute3 := lpad(substr(nvl(v_aux, '0'), 20, 4), 4, '0'); -- BRANCH_NUM
          g_doc_attribute4 := lpad(substr(nvl(v_aux, '0'), 37, 7), 7, '0'); -- ACCT_NUM
          g_doc_attribute5 := lpad(substr(nvl(v_aux, '0'), 26, 11), 11, '0');
          g_doc_attribute6 := lpad(substr(nvl(v_aux, '0'), 24, 2), 2, '0');
        ELSE
          IF v_method_type = 'CONCESSIONER'
             AND length(v_aux) = 48 THEN
            v_bar_code := substr(v_aux, 1, 11) || substr(v_aux, 13, 11) || substr(v_aux, 25, 11) ||
                          substr(v_aux, 37, 11);
          ELSIF v_method_type = 'CONCESSIONER'
                AND length(v_aux) = 44 THEN
            v_bar_code := v_aux;
          ELSE
            -- BUG 10409872
            v_bar_code := lpad(substr(nvl(v_aux, '0'), 20, 25), 25, '0') || lpad(substr(nvl(v_aux, '0'), 5, 1), 1, '0') ||
                          lpad(substr(nvl(v_aux, '0'), 4, 1), 1, '0') || lpad(' ', 13, ' ');

            g_doc_attribute1 := substr(nvl(v_aux, '0'), 10, 10);
            g_doc_attribute2 := substr(nvl(v_aux, '0'), 6, 4);
          END IF;
        END IF;
      END IF;

      BEGIN
        SELECT MOD((to_number(substr(g_doc_attribute3, 1, 1)) * 5) + (to_number(substr(g_doc_attribute3, 2, 1)) * 4) +
                   (to_number(substr(g_doc_attribute3, 3, 1)) * 3) + (to_number(substr(g_doc_attribute3, 4, 1)) * 2),
                   11) branch
              ,MOD((to_number(substr(g_doc_attribute4, 7, 1)) * 2) + (to_number(substr(g_doc_attribute4, 6, 1)) * 3) +
                   (to_number(substr(g_doc_attribute4, 5, 1)) * 4) + (to_number(substr(g_doc_attribute4, 4, 1)) * 5) +
                   (to_number(substr(g_doc_attribute4, 3, 1)) * 6) + (to_number(substr(g_doc_attribute4, 2, 1)) * 7) +
                   (to_number(substr(g_doc_attribute4, 1, 1)) * 2),
                   11) acct
          INTO g_doc_attribute7
              ,g_doc_attribute8
          FROM dual;
      EXCEPTION
        WHEN OTHERS THEN
          g_doc_attribute7 := 0;
          g_doc_attribute8 := 0;
      END;

      IF nvl(g_doc_attribute7, 0) IN (0, 1) THEN
        g_doc_attribute7 := '0';
      ELSE
        g_doc_attribute7 := 11 - (nvl(g_doc_attribute7, 0));
      END IF;

      IF nvl(g_doc_attribute8, 0) IN (0, 1) THEN
        g_doc_attribute8 := '0';
      ELSE
        g_doc_attribute8 := 11 - nvl(g_doc_attribute8, 0);
      END IF;

    ELSIF p.int_bank_number = 341 THEN
      IF instr(v_aux, '.') <> 0 THEN
        v_aux := REPLACE(v_aux, '.', '');
        --
        v_bar_code := lpad(nvl(substr(v_aux, 1, 3), '0'), 3, '0') || lpad(nvl(substr(v_aux, 4, 1), '0'), 1, '0') ||
                      lpad(nvl(substr(v_aux, 33, 1), '0'), 1, '0') || lpad(nvl(substr(v_aux, 34, 14), '0'), 14, '0') ||
                      lpad(nvl(substr(v_aux, 5, 5), '0'), 5, '0') || lpad(nvl(substr(v_aux, 11, 10), '0'), 10, '0') ||
                      lpad(nvl(substr(v_aux, 22, 10), '0'), 10, '0');
        --
      ELSE
        v_bar_code := v_aux;
      END IF;
    ELSIF p.int_bank_number = 399 THEN
      --
      IF instr(v_aux, '.') <> 0 THEN
        --MANUAL
        v_aux      := REPLACE(v_aux, '.', '');
        v_bar_code := lpad(nvl(substr(v_aux, 1, 3), '0'), 3, '0') || lpad(nvl(substr(v_aux, 4, 1), '0'), 1, '0') ||
                      lpad(nvl(substr(v_aux, 33, 1), '0'), 1, '0') || lpad(nvl(substr(v_aux, 34, 14), '0'), 14, '0') ||
                      lpad(nvl(substr(v_aux, 5, 5), '0'), 5, '0') || lpad(nvl(substr(v_aux, 11, 10), '0'), 10, '0') ||
                      lpad(nvl(substr(v_aux, 22, 9), '0'), 9, '0') || lpad(nvl(substr(v_aux, 31, 1), '0'), 1, '0');
      ELSE
        v_bar_code := lpad(nvl(substr(v_aux, 1, 3), '0'), 3, '0') || lpad(nvl(substr(v_aux, 4, 1), '0'), 1, '0') ||
                      lpad(nvl(substr(v_aux, 5, 1), '0'), 1, '0') || lpad(nvl(substr(v_aux, 6, 14), '0'), 14, '0') ||
                      lpad(nvl(substr(v_aux, 20, 7), '0'), 7, '0') || lpad(nvl(substr(v_aux, 27, 13), '0'), 13, '0') ||
                      lpad(nvl(substr(v_aux, 40, 4), '0'), 4, '0') || lpad(nvl(substr(v_aux, 44, 1), '0'), 1, '0');
      END IF;
    ELSIF p.int_bank_number = 001 THEN
      --BRASIL
      IF instr(v_aux, '.') <> 0 THEN
        v_aux      := REPLACE(v_aux, '.', '');
        v_bar_code := lpad(nvl(substr(v_aux, 1, 3), '0'), 3, '0') || lpad(nvl(substr(v_aux, 4, 1), '0'), 1, '0') ||
                      lpad(nvl(substr(v_aux, 33, 1), '0'), 1, '0') || lpad(nvl(substr(v_aux, 34, 14), '0'), 14, '0') ||
                      lpad(nvl(substr(v_aux, 5, 5), '0'), 5, '0') || lpad(nvl(substr(v_aux, 11, 10), '0'), 10, '0') ||
                      lpad(nvl(substr(v_aux, 22, 10), '0'), 10, '0');
      ELSE
        v_bar_code := v_aux;
      END IF;
    ELSIF p.int_bank_number = 409 THEN
      --UNIBANCO
      IF instr(v_aux, '.') <> 0 THEN
        v_bar_code := REPLACE(v_aux, '.');
      ELSE
        v_bar_code := 'CDB' || REPLACE(v_aux, '.');
      END IF;

      g_doc_attribute2 := v_our_number;

      --CHECK HORIZONTAL
      IF substr(v_aux, 1, 3) <> 409 THEN
        g_doc_attribute1 := to_char(((lpad(substr(v_aux, 1, 3), 4, '0') || '00000000000000') + (r.payment_amount * 100)) * 5);
      ELSE
        g_doc_attribute1 := lpad(substr(v_aux, 1, 3), 4, '0') || lpad(substr(v_pe_branch_num, 1, 4), 4, '0') ||
                            lpad(substr(nvl(v_pe_acct_num, '0'), 1, 10), 10, '0');

        g_doc_attribute1 := to_char(g_doc_attribute1 + (r.payment_amount * 100)) * 5;
      END IF;

    ELSIF p.int_bank_number IN (353, 033) THEN
      --SANTANDER

      -- Bug 14836225 - Start
      IF v_method_type = 'CONCESSIONER' THEN
        IF length(v_aux) = 48 THEN
          v_bar_code := substr(v_aux, 1, 11) || substr(v_aux, 13, 11) || substr(v_aux, 25, 11) || substr(v_aux, 37, 11);
        ELSE
          v_bar_code := v_aux;
        END IF;
      ELSE
        -- Bug 14836225 - End

        IF instr(v_aux, '.') <> 0 THEN
          v_aux      := REPLACE(v_aux, '.');
          v_bar_code := lpad(nvl(substr(v_aux, 1, 3), '0'), 3, '0') || lpad(nvl(substr(v_aux, 4, 1), '0'), 1, '0') ||
                        lpad(nvl(substr(v_aux, 33, 1), '0'), 1, '0') || lpad(nvl(substr(v_aux, 34, 14), '0'), 14, '0') ||
                        lpad(nvl(substr(v_aux, 5, 5), '0'), 5, '0') || lpad(nvl(substr(v_aux, 11, 10), '0'), 10, '0') ||
                        lpad(nvl(substr(v_aux, 22, 10), '0'), 10, '0');
        ELSE
          v_bar_code := v_aux;
        END IF;

      END IF; -- Bug 14836225

    ELSIF p.int_bank_number = 356 THEN

      IF v_method_type = 'CONCESSIONER' THEN
        IF length(v_aux) = 48 THEN
          v_bar_code := substr(v_aux, 1, 11) || substr(v_aux, 13, 11) || substr(v_aux, 25, 11) || substr(v_aux, 37, 11);
        ELSE
          v_bar_code := v_aux;
        END IF;
      END IF;
      --
      -- Bug 14774739 - Start
    ELSIF p.int_bank_number = 104 THEN
      -- CEF
      --
      IF instr(v_aux, '.') <> 0 THEN
        --
        v_aux      := REPLACE(v_aux, '.', '');
        v_bar_code := lpad(nvl(substr(v_aux, 1, 3), '0'), 3, '0') || lpad(nvl(substr(v_aux, 4, 1), '0'), 1, '0') ||
                      lpad(nvl(substr(v_aux, 33, 1), '0'), 1, '0') || lpad(nvl(substr(v_aux, 34, 14), '0'), 14, '0') ||
                      lpad(nvl(substr(v_aux, 5, 5), '0'), 5, '0') || lpad(nvl(substr(v_aux, 11, 10), '0'), 10, '0') ||
                      lpad(nvl(substr(v_aux, 22, 9), '0'), 9, '0') || lpad(nvl(substr(v_aux, 31, 1), '0'), 1, '0');
        --
      ELSE
        --
        v_bar_code := v_aux;
        --
      END IF;
      -- Bug 14774739 - End
      --
    END IF;

    RETURN v_bar_code;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_bar_code;

  PROCEDURE generate_collection_returns(p_payment_id     NUMBER DEFAULT NULL
                                       ,p_doc_payable_id NUMBER DEFAULT NULL
                                       ,p_type           VARCHAR2 DEFAULT NULL
                                       ,p_return_id      OUT NOCOPY NUMBER) IS

    v_collect_type VARCHAR2(2) := NULL;
    r              iby_payments_all%ROWTYPE;
    l              iby_docs_payable_all%ROWTYPE;
    l_reg_exist    VARCHAR2(1); -- BUG 9857481

  BEGIN
    --
    BEGIN
      -- BUG 9857481: Start
      --
      SELECT 'Y'
            ,return_id
        INTO l_reg_exist
            ,p_return_id
        FROM cll_f033_pay_return_lines
       WHERE (payment_id = p_payment_id AND p_doc_payable_id IS NULL)
          OR (payment_id = p_payment_id AND document_payable_id = p_doc_payable_id);
      --
    EXCEPTION
      WHEN no_data_found THEN
        l_reg_exist := 'N';
      WHEN too_many_rows THEN
        l_reg_exist := 'Y';
        --
    END; -- BUG 9857481: End
    --
    IF l_reg_exist = 'N' THEN
      -- BUG 9857481
      --
      IF (p_doc_payable_id IS NULL) THEN
        --
        SELECT *
          INTO r
          FROM iby_payments_all ip
         WHERE ip.payment_id = p_payment_id;
        --
        SELECT cll_f033_pay_return_s.NEXTVAL
          INTO p_return_id
          FROM dual;
        --
        cll_f033_utilities_pkg.insert_ret_header(p_return_id    => p_return_id,
                                                 p_payment_id   => r.payment_id,
                                                 p_collect_type => p_type);
        --
        FOR rl IN (SELECT idp.document_payable_id
                     FROM iby_docs_payable_all idp
                    WHERE idp.payment_id = r.payment_id)
        --
        LOOP
          --
          cll_f033_utilities_pkg.insert_ret_line(p_return_id           => p_return_id,
                                                 p_payment_id          => r.payment_id,
                                                 p_document_payable_id => rl.document_payable_id);
          --
        END LOOP;
        --
      ELSE
        --
        SELECT *
          INTO l
          FROM iby_docs_payable_all idp
         WHERE idp.document_payable_id = p_doc_payable_id;
        --
        SELECT cll_f033_pay_return_s.NEXTVAL
          INTO p_return_id
          FROM dual;
        --
        cll_f033_utilities_pkg.insert_ret_header(p_return_id    => p_return_id,
                                                 p_payment_id   => l.payment_id,
                                                 p_collect_type => p_type);
        --
        cll_f033_utilities_pkg.insert_ret_line(p_return_id           => p_return_id,
                                               p_payment_id          => l.payment_id,
                                               p_document_payable_id => p_doc_payable_id);
        --
      END IF;
      --
    END IF; -- BUG 9857481
    --
  END generate_collection_returns;

  FUNCTION get_ins_ext_agg(p_payment_instruction_id IN NUMBER) RETURN xmltype IS

    l_ext_agg xmltype;

    v_count_cr_cc        NUMBER := 0;
    v_count_cr_cc_tit    NUMBER := 0;
    v_count_cr_cp        NUMBER := 0;
    v_count_cr_cp_tit    NUMBER := 0;
    v_count_cr_cc_rt     NUMBER := 0; -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    v_count_cr_cc_tit_rt NUMBER := 0; -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    v_count_cr_cp_rt     NUMBER := 0; -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    v_count_cr_cp_tit_rt NUMBER := 0; -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    v_count_doc_d        NUMBER := 0;
    v_count_doc_c        NUMBER := 0;
    v_count_ted_ot       NUMBER := 0;
    v_count_ted_mt       NUMBER := 0;
    v_count_cheque       NUMBER := 0;
    v_count_ordem        NUMBER := 0;
    v_count_tit_cobr     NUMBER := 0;
    v_count_tit_concess  NUMBER := 0; -- ADDED BY GWISZNIE FOR CONCESSIONER - 2009/05/06 -
    v_count_tit_cobr_ob  NUMBER := 0;
    v_count_all          NUMBER := 0;
    v_count_null_barcode NUMBER := 0;

    v_sum_cr_cc        NUMBER := 0;
    v_sum_cr_cc_tit    NUMBER := 0;
    v_sum_cr_cp        NUMBER := 0;
    v_sum_cr_cp_tit    NUMBER := 0;
    v_sum_cr_cc_rt     NUMBER := 0; -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    v_sum_cr_cc_tit_rt NUMBER := 0; -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    v_sum_cr_cp_rt     NUMBER := 0; -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    v_sum_cr_cp_tit_rt NUMBER := 0; -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    v_sum_doc_d        NUMBER := 0;
    v_sum_doc_c        NUMBER := 0;
    v_sum_ted_ot       NUMBER := 0;
    v_sum_ted_mt       NUMBER := 0;
    v_sum_cheque       NUMBER := 0;
    v_sum_ordem        NUMBER := 0;
    v_sum_tit_concess  NUMBER := 0; -- ADDED BY GWISZNIE FOR CONCESSIONER - 2009/05/06 -
    v_sum_tit_cobr     NUMBER := 0;
    v_sum_tit_cobr_ob  NUMBER := 0;
    v_sum_all          NUMBER := 0;

    v_count_tit_cobr_aux    NUMBER := 0;
    v_sum_tit_cobr_aux      NUMBER := 0;
    v_count_tit_cobr_ob_aux NUMBER := 0;
    v_sum_tit_cobr_ob_aux   NUMBER := 0;

    v_pr_branch_num VARCHAR2(100) := NULL;
    v_pr_branch_dgt VARCHAR2(100) := NULL;
    v_pr_acct_num   VARCHAR2(100) := NULL;
    v_pr_acct_dgt   VARCHAR2(100) := NULL;

    v_method_type        VARCHAR2(100) := NULL;
    v_payment_type_limit NUMBER := 0;
    v_cll_f033_bank_s    NUMBER := 0;
    v_cll_comp_acct      VARCHAR2(100) := NULL;
    v_cll_ou_reg_num     VARCHAR2(100) := NULL;

    v_error VARCHAR2(300) := NULL;

    r_instr iby_pay_instructions_all%ROWTYPE;

    l_reg_number_payee NUMBER; -- BUG 7426668
    l_reg_number_payer NUMBER; -- BUG 7426668

    l_movement_type   VARCHAR2(1) := NULL; -- BUG 9346543
    l_movement_code   VARCHAR2(2) := NULL; -- BUG 9694536
    v_send_details    VARCHAR2(2) := '0';
    l_sum_doc_ted     NUMBER := 0; -- BUG 10022107
    v_commitment_supl VARCHAR2(50) := NULL; --(++) Rantonio, BUG 13641139
    v_commitment_auto VARCHAR2(50) := NULL; --(++) Rantonio, BUG 13641139
    r_acct_ext        cll_f033_ce_bank_accounts_ext%ROWTYPE;
    --(++) Rantonio, BUG 14256985   v_hist_collect      VARCHAR2(20000) := NULL;

    CURSOR c_cursor IS
      SELECT ip.org_id
            ,ip.ext_bank_number
            ,ip.int_bank_number
            ,ip.payment_amount
            ,ip.payee_party_id
            ,ip.payer_party_id
            ,ip.payment_id
            ,ip.payment_method_code
            ,ip.internal_bank_account_id
            ,ip.int_bank_account_number
            ,ip.int_bank_branch_party_id
            ,ip.int_bank_branch_number
            ,ip.ext_bank_account_type
            ,ip.supplier_site_id
        FROM iby_payments_all ip
       WHERE ip.payment_instruction_id = p_payment_instruction_id
         AND ip.payment_status <> 'REMOVED_PAYMENT_STOPPED';

    r c_cursor%ROWTYPE;

  BEGIN
    --
    SELECT pi.*
      INTO r_instr
      FROM iby_pay_instructions_all pi
     WHERE pi.payment_instruction_id = p_payment_instruction_id;
    --
    --(++) Rantonio, BUG 13641139 (BEGIN)
    --
    IF r_instr.internal_bank_account_id IS NULL THEN
      BEGIN
        SELECT internal_bank_account_id
          INTO r_instr.internal_bank_account_id
          FROM iby_payments_all
         WHERE payment_instruction_id = r_instr.payment_instruction_id
           AND internal_bank_account_id IS NOT NULL
           AND rownum = 1;
      EXCEPTION
        WHEN OTHERS THEN
          r_instr.internal_bank_account_id := NULL;
      END;
    END IF;
    --
    BEGIN
      SELECT *
        INTO r_acct_ext
        FROM cll_f033_ce_bank_accounts_ext
       WHERE bank_account_id = r_instr.internal_bank_account_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    --
    v_commitment_supl := nvl(r_acct_ext.attribute8, '0001');
    v_commitment_auto := nvl(r_acct_ext.attribute9, '0002');
    --
    IF (r_acct_ext.attribute3 IS NOT NULL) THEN
      --
      BEGIN
        SELECT xe.registration_number
          INTO v_cll_ou_reg_num
          FROM xle_establishment_v xe
         WHERE xe.establishment_id = r_acct_ext.attribute3;
      EXCEPTION
        WHEN OTHERS THEN
          v_cll_ou_reg_num := NULL;
      END;
      --
    END IF;
    --
    BEGIN
      --
      v_cll_comp_acct   := r_acct_ext.attribute2;
      v_cll_f033_bank_s := get_cll_f033_bank_s(r_instr.internal_bank_account_id);
      l_movement_type   := r_acct_ext.attribute4; -- bug 9346543
      l_movement_code   := r_acct_ext.attribute5; -- bug 9694536
      v_send_details    := nvl(r_acct_ext.attribute6, '0');
      --
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    --
    /*
    Rantonio, 24/07/2012 (BEGIN)
         SELECT attribute8,
                attribute9
           INTO v_commitment_supl,
                v_commitment_auto
           FROM cll_f033_ce_bank_accounts_ext
          WHERE bank_account_id = r_instr.internal_bank_account_id;
       EXCEPTION WHEN OTHERS THEN
         v_commitment_supl := '0001';
         v_commitment_auto := '0002';
       END;
    Rantonio, 24/07/2012 (BEGIN)
    */

    --
    --(++) Rantonio, BUG 13641139 (END)
    --
    IF (jg_zz_shared_pkg.get_country(r_instr.org_id, NULL, NULL) <> 'BR') THEN
      raise_application_error(-20070, 'INVALID COUNTRY CODE');
    END IF;
    --
    SELECT ibi.format_value
      INTO v_payment_type_limit
      FROM iby_bank_instructions_b ibi
     WHERE ibi.bank_instruction_code = 'CLL_F033_PAYMENT_TYPE_LIMIT';
    --
    v_sum_all   := 0;
    v_count_all := 0;
    --
    OPEN c_cursor;
    FETCH c_cursor
      INTO r;
    --
    IF c_cursor%FOUND THEN
      --
      LOOP
        
        /* XSCN Begin - Functional Amount (Ledger Currency) */
        r.payment_amount := nvl(xscn_get_pay_func_amount(r.payment_id), r.payment_amount);
        /* XSCN END - Functional Amount (Ledger Currency) */
        
        BEGIN
          SELECT to_number(lpad(substr(nvl(global_attribute10, '0'), 1, 9), 9, '0'))
            INTO l_reg_number_payee
            FROM ap_supplier_sites_all
           WHERE vendor_site_id = r.supplier_site_id;
        EXCEPTION
          WHEN OTHERS THEN
            -- CAUSE INFORMATION SHOULD BE WITH CHARACTERS ALPHA
            l_reg_number_payee := 0;
        END;
        --
        BEGIN
          SELECT to_number(substr(lpad(le_registration_number, 14, 0), 1, 9))
            INTO l_reg_number_payer
            FROM iby_ext_fd_payer_1_0_v
           WHERE party_id = r.payer_party_id;
        EXCEPTION
          WHEN OTHERS THEN
            -- Cause information should be with characters alpha
            l_reg_number_payer := 0;
        END;
        --
        IF (v_count_all = 0) THEN
          --
          v_pr_acct_dgt := NULL;
          --
          SELECT cba.bank_account_num
                ,cba.check_digits
            INTO r.int_bank_account_number
                ,v_pr_acct_dgt
            FROM ce_bank_accounts cba
           WHERE cba.bank_account_id = r.internal_bank_account_id;
          --
          IF (instr(r.int_bank_account_number, '-') > 0) THEN
            --
            v_pr_acct_num := substr(r.int_bank_account_number, 1, instr(r.int_bank_account_number, '-') - 1);
            --
            IF (v_pr_acct_dgt IS NULL) THEN
              v_pr_acct_dgt := substr(r.int_bank_account_number, instr(r.int_bank_account_number, '-') + 1);
            END IF;
            --
          ELSE
            v_pr_acct_num := r.int_bank_account_number;
          END IF;
          --
          IF (instr(r.int_bank_branch_number, '-') > 0) THEN
            v_pr_branch_num := substr(r.int_bank_branch_number, 1, instr(r.int_bank_branch_number, '-') - 1);
            v_pr_branch_dgt := substr(r.int_bank_branch_number, instr(r.int_bank_branch_number, '-') + 1);
          ELSE
            v_pr_branch_num := r.int_bank_branch_number;
          END IF;
          --
          BEGIN
            IF (v_pr_branch_dgt IS NULL) THEN
              SELECT hpe.attribute1
                INTO v_pr_branch_dgt
                FROM cll_f033_hz_parties_ext hpe
               WHERE hpe.party_id = r.int_bank_branch_party_id;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              v_pr_branch_dgt := NULL;
          END;
          --
        END IF;
        --
        BEGIN
          --
          v_method_type := 'METHOD_TYPE_NULL';
          --
          SELECT nvl(ipme.attribute1, 'METHOD_TYPE_NULL')
            INTO v_method_type
            FROM cll_f033_iby_payment_mtd_ext ipme
           WHERE ipme.payment_method_code = r.payment_method_code;
        EXCEPTION
          WHEN OTHERS THEN
            v_method_type := 'METHOD_TYPE_NULL';
        END;
        --
        /*CR CC-CP*/
        IF ((l_reg_number_payee <> l_reg_number_payer) AND -- BUG 7426668
           (r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'ELECTRONIC')) THEN
          IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
            v_count_cr_cp := v_count_cr_cp + 1;
            v_sum_cr_cp   := v_sum_cr_cp + r.payment_amount;
          ELSE
            v_count_cr_cc := v_count_cr_cc + 1;
            v_sum_cr_cc   := v_sum_cr_cc + r.payment_amount;
          END IF;
        ELSIF ((l_reg_number_payee <> l_reg_number_payer) AND -- BUG 7426668
              (r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'REAL_TIME')) THEN
          IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
            v_count_cr_cp_rt := v_count_cr_cp_rt + 1;
            v_sum_cr_cp_rt   := v_sum_cr_cp_rt + r.payment_amount;
          ELSE
            v_count_cr_cc_rt := v_count_cr_cc_rt + 1;
            v_sum_cr_cc_rt   := v_sum_cr_cc_rt + r.payment_amount;
          END IF;
          /*CR CC-CP TIT*/
        ELSIF ((l_reg_number_payee = l_reg_number_payer) AND -- BUG 7426668
              (r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'ELECTRONIC')) THEN
          IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
            v_count_cr_cp_tit := v_count_cr_cp_tit + 1;
            v_sum_cr_cp_tit   := v_sum_cr_cp_tit + r.payment_amount;
          ELSE
            v_count_cr_cc_tit := v_count_cr_cc_tit + 1;
            v_sum_cr_cc_tit   := v_sum_cr_cc_tit + r.payment_amount;
          END IF;
          /*CR CC-CP TIT RT*/ -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        ELSIF ((l_reg_number_payee = l_reg_number_payer) AND -- BUG 7426668
              (r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'REAL_TIME')) THEN
          IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
            v_count_cr_cp_tit_rt := v_count_cr_cp_tit_rt + 1;
            v_sum_cr_cp_tit_rt   := v_sum_cr_cp_tit_rt + r.payment_amount;
          ELSE
            v_count_cr_cc_tit_rt := v_count_cr_cc_tit_rt + 1;
            v_sum_cr_cc_tit_rt   := v_sum_cr_cc_tit_rt + r.payment_amount;
          END IF;
          /*DOC D*/
        ELSIF ((l_reg_number_payee = l_reg_number_payer) AND -- BUG 7426668
              (r.ext_bank_number <> r.int_bank_number) AND (r.payment_amount < v_payment_type_limit) AND
              (v_method_type = 'ELECTRONIC')) THEN
          v_count_doc_d := v_count_doc_d + 1;
          v_sum_doc_d   := v_sum_doc_d + r.payment_amount;
          /*DOC C*/
        ELSIF ((l_reg_number_payee <> l_reg_number_payer) AND -- BUG 7426668
              (r.ext_bank_number <> r.int_bank_number) AND (r.payment_amount < v_payment_type_limit) AND
              (v_method_type = 'ELECTRONIC')) THEN
          v_count_doc_c := v_count_doc_c + 1;
          v_sum_doc_c   := v_sum_doc_c + r.payment_amount;
          /*TED OT*/
        ELSIF ((l_reg_number_payee <> l_reg_number_payer) AND -- BUG 7426668
              (r.ext_bank_number <> r.int_bank_number) AND (r.payment_amount >= v_payment_type_limit) AND
              ((v_method_type = 'ELECTRONIC') OR (v_method_type LIKE 'TED%'))) THEN
          v_count_ted_ot := v_count_ted_ot + 1;
          v_sum_ted_ot   := v_sum_ted_ot + r.payment_amount;
          /*TED MT*/
        ELSIF ((l_reg_number_payee = l_reg_number_payer) AND -- BUG 7426668
              (r.ext_bank_number <> r.int_bank_number) AND (r.payment_amount >= v_payment_type_limit) AND
              ((v_method_type = 'ELECTRONIC') OR (v_method_type LIKE 'TED%'))) THEN
          v_count_ted_mt := v_count_ted_mt + 1;
          v_sum_ted_mt   := v_sum_ted_mt + r.payment_amount;
          /*CHEQUE*/
        ELSIF (v_method_type = 'CHECK') THEN
          v_count_cheque := v_count_cheque + 1;
          v_sum_cheque   := v_sum_cheque + r.payment_amount;
          /*ORDEM*/
        ELSIF (v_method_type = 'PAYMENT_ORDER') THEN
          v_count_ordem := v_count_ordem + 1;
          v_sum_ordem   := v_sum_ordem + r.payment_amount;
          /* TIT - CONCESS */
        ELSIF (v_method_type IN ('COLLECT_DOC', 'CONCESSIONER')) THEN
          v_count_tit_cobr_aux    := 0;
          v_sum_tit_cobr_aux      := 0;
          v_count_tit_cobr_ob_aux := 0;
          v_sum_tit_cobr_ob_aux   := 0;
          v_count_null_barcode    := 0;

          --(++) Rantonio, BUG 12972244 (BEGIN)
          /*
        SELECT NVL(SUM(DECODE(R.INT_BANK_NUMBER,SUBSTR(GET_JL_BARCODE(JBAC.BANK_COLLECTION_ID),1,3),1,0)),0) COUNT_SB
              ,NVL(SUM(DECODE(R.INT_BANK_NUMBER,SUBSTR(GET_JL_BARCODE(JBAC.BANK_COLLECTION_ID),1,3),IDPA.PAYMENT_AMOUNT,0)),0) SUM_SB
              ,NVL(SUM(DECODE(R.INT_BANK_NUMBER,SUBSTR(GET_JL_BARCODE(JBAC.BANK_COLLECTION_ID),1,3),0,1)),0) COUNT_OB
              ,NVL(SUM(DECODE(R.INT_BANK_NUMBER,SUBSTR(GET_JL_BARCODE(JBAC.BANK_COLLECTION_ID),1,3),0,IDPA.PAYMENT_AMOUNT)),0) SUM_OB
              ,NVL(SUM(DECODE(GET_JL_BARCODE(JBAC.BANK_COLLECTION_ID),NULL,1,0)),0)
          INTO V_COUNT_TIT_COBR_AUX
              ,V_SUM_TIT_COBR_AUX
              ,V_COUNT_TIT_COBR_OB_AUX
              ,V_SUM_TIT_COBR_OB_AUX
              ,V_COUNT_NULL_BARCODE
          FROM JL_BR_AP_COLLECTION_DOCS_ALL JBAC
              ,IBY_DOCS_PAYABLE_ALL IDPA
         WHERE JBAC.INVOICE_ID(+) = IDPA.CALLING_APP_DOC_UNIQUE_REF2
           AND JBAC.PAYMENT_NUM(+) = IDPA.CALLING_APP_DOC_UNIQUE_REF3
           AND IDPA.PAYMENT_ID = R.PAYMENT_ID;
          */

          DECLARE
            CURSOR docs IS
              SELECT jbac.bank_collection_id
                    ,idpa.payment_amount
                    ,idpa.ext_payee_id
                    ,idpa.payee_party_id
                    ,idpa.org_id
                    ,idpa.calling_app_doc_ref_number
                FROM jl_br_ap_collection_docs_all jbac
                    ,iby_docs_payable_all         idpa
               WHERE jbac.invoice_id(+) = idpa.calling_app_doc_unique_ref2
                 AND jbac.payment_num(+) = idpa.calling_app_doc_unique_ref3
                 AND idpa.payment_id = r.payment_id
                 AND idpa.document_type NOT IN ('INTEREST')
                    /* -- Bug 16687207
            --(++) Rantonio, BUG 14304795 (BEGIN)
              AND jbac.bank_collection_id IN
                  (SELECT apsa.global_attribute11
                     FROM ap_payment_schedules_all apsa
                    WHERE apsa.invoice_id  = jbac.invoice_id
                      AND apsa.payment_num = jbac.payment_num);
            --(++) Rantonio, BUG 14304795 (END)
            */
                 AND ((jbac.bank_collection_id IN
                      (SELECT apsa.global_attribute11
                          FROM ap_payment_schedules_all apsa
                         WHERE apsa.invoice_id = jbac.invoice_id
                           AND apsa.payment_num = jbac.payment_num)) OR (jbac.bank_collection_id IS NULL));
            -- Bug 16687207
            --
            r_doc      docs%ROWTYPE;
            v_bar_code VARCHAR2(200) := NULL;
            v_interest NUMBER := 0;
            v_step     NUMBER;
            --
          BEGIN
            v_step := 1;
            OPEN docs;
            LOOP
              FETCH docs
                INTO r_doc;
              EXIT WHEN docs%NOTFOUND;
              v_step := 2;
              --
              v_bar_code := nvl(get_jl_barcode(r_doc.bank_collection_id), 'X');
              --
              v_step := 3;
              --
              IF v_bar_code = 'X' THEN
                --
                v_step := 4;
                --
                v_count_null_barcode := nvl(v_count_null_barcode, 0) + 1;
                v_step               := 5;
                --
              ELSE
                --
                v_step := 6;
                --
                BEGIN
                  SELECT nvl(SUM(payment_amount), 0)
                    INTO v_interest
                    FROM iby_docs_payable_all
                   WHERE calling_app_doc_ref_number LIKE r_doc.calling_app_doc_ref_number || '-INT%' --(++) Rantonio, BUG 13641139
                     AND document_type = 'INTEREST'
                     AND document_status = 'PAYMENT_CREATED'
                     AND payment_id = r.payment_id
                     AND ext_payee_id = r_doc.ext_payee_id
                     AND payee_party_id = r_doc.payee_party_id
                     AND org_id = r_doc.org_id;
                  v_step := 7;
                EXCEPTION
                  WHEN OTHERS THEN
                    v_step     := 8;
                    v_interest := 0;
                END;
                --
                /* Rantonio, BUG 14256985 (BEGIN)
                   BEGIN
                     --
                     IF v_hist_collect IS NULL THEN
                       v_hist_collect := r_doc.calling_app_doc_ref_number||':'||
                                         SUBSTR(v_bar_code,1,3)||':'||
                                         v_interest||':'||
                                         r_doc.payment_amount;
                     ELSE
                       v_hist_collect := v_hist_collect||' / '||
                                         r_doc.calling_app_doc_ref_number||':'||
                                         SUBSTR(v_bar_code,1,3)||':'||
                                         v_interest||':'||
                                         r_doc.payment_amount;
                     END IF;
                     --
                   EXCEPTION WHEN OTHERS THEN
                     v_hist_collect := 'ERROR: '||SQLERRM;
                   END;
                Rantonio, BUG 14256985 (END) */
                --
                v_step               := 9;
                r_doc.payment_amount := nvl(r_doc.payment_amount, 0) + nvl(v_interest, 0);
                v_step               := 10;
                --
                IF substr(v_bar_code, 1, 3) = r.int_bank_number THEN
                  --
                  v_step               := 11;
                  v_count_tit_cobr_aux := nvl(v_count_tit_cobr_aux, 0) + 1;
                  v_sum_tit_cobr_aux   := nvl(v_sum_tit_cobr_aux, 0) + nvl(r_doc.payment_amount, 0);
                  v_step               := 12;
                  --
                ELSE
                  --
                  v_step                  := 13;
                  v_count_tit_cobr_ob_aux := nvl(v_count_tit_cobr_ob_aux, 0) + 1;
                  v_sum_tit_cobr_ob_aux   := nvl(v_sum_tit_cobr_ob_aux, 0) + nvl(r_doc.payment_amount, 0);
                  v_step                  := 14;
                  --
                END IF;
                --
                v_step := 15;
              END IF;
              --
            END LOOP;
            CLOSE docs;
            --
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log, 'ERRO Recup SUM COLLECTION DOC, passo ' || v_step);
              raise_application_error(-20000, '');
          END;
          --(++) Rantonio, BUG 12972244 (END)
          IF ((v_count_null_barcode > 0) AND (nvl(fnd_profile.VALUE('CLL_F033_ENABLE_BARCODE_VALIDATION'), 'N') = 'Y')) THEN
            RAISE no_data_found;
          END IF;
          IF v_method_type = 'COLLECT_DOC' THEN
            v_count_tit_cobr    := v_count_tit_cobr + v_count_tit_cobr_aux;
            v_count_tit_cobr_ob := v_count_tit_cobr_ob + v_count_tit_cobr_ob_aux;
            v_sum_tit_cobr    := v_sum_tit_cobr + v_sum_tit_cobr_aux;
            v_sum_tit_cobr_ob := v_sum_tit_cobr_ob + v_sum_tit_cobr_ob_aux;
          ELSIF v_method_type = 'CONCESSIONER' THEN
            v_count_tit_concess := v_count_tit_concess + v_count_tit_cobr_aux + v_count_tit_cobr_ob_aux;
            v_sum_tit_concess := v_sum_tit_concess + v_sum_tit_cobr_aux + v_sum_tit_cobr_ob_aux;
          END IF;
        END IF;

        FETCH c_cursor
          INTO r;
        EXIT WHEN c_cursor%NOTFOUND;
      END LOOP;

      l_sum_doc_ted := v_sum_doc_d + v_sum_doc_c + v_sum_ted_ot + v_sum_ted_mt; -- BUG 10022107

      v_sum_all := v_sum_cr_cc + v_sum_cr_cc_tit + v_sum_cr_cp + v_sum_cr_cp_tit + v_sum_cr_cc_rt + -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                   v_sum_cr_cc_tit_rt + -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                   v_sum_cr_cp_rt + -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                   v_sum_cr_cp_tit_rt + -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                   v_sum_doc_d + v_sum_doc_c + v_sum_ted_ot + v_sum_ted_mt + v_sum_cheque + v_sum_ordem +
                   v_sum_tit_cobr + v_sum_tit_cobr_ob + v_sum_tit_concess; -- Added by GWisznie for Concessioner - 2009/05/06 -

      v_count_all := v_count_cr_cc + v_count_cr_cc_tit + v_count_cr_cp + v_count_cr_cp_tit + v_count_cr_cc_rt + -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                     v_count_cr_cc_tit_rt + -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                     v_count_cr_cp_rt + -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                     v_count_cr_cp_tit_rt + -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                     v_count_doc_d + v_count_doc_c + v_count_ted_ot + v_count_ted_mt + v_count_cheque + v_count_ordem +
                     v_count_tit_cobr + v_count_tit_cobr_ob + v_count_tit_concess; -- Added by GWisznie for Concessioner - 2009/05/06 -

    END IF;
    CLOSE c_cursor;

    SELECT xmlconcat(
      xmlelement(
        "XSCN9031",
        xmlelement("XSCN_PAYER_BRANCH_NUM",   v_pr_branch_num),
        xmlelement("XSCN_PAYER_BRANCH_DGT",   v_pr_branch_dgt),
        xmlelement("XSCN_PAYER_ACCT_NUM",     v_pr_acct_num),
        xmlelement("XSCN_PAYER_ACCT_DGT",     v_pr_acct_dgt),
        xmlelement("XSCN_F033_BANK_S",        v_cll_f033_bank_s),
        xmlelement("XSCN_COMPLEMENT_ACCT",    v_cll_comp_acct),
        xmlelement("XSCN_OU_REG_NUMBER",      v_cll_ou_reg_num),
        xmlelement("XSCN_MOVEMENT_TYPE",      l_movement_type), -- BUG 9346543
        xmlelement("XSCN_MOVEMENT_CODE",      l_movement_code), -- BUG 9694536
        xmlelement("XSCN_SEND_DETAILS",       v_send_details), -- BUG 9694536
        xmlelement("XSCN_COMMITMENT_SUPL",    v_commitment_supl), --(++) Rantonio, BUG 13641139
        xmlelement("XSCN_COMMITMENT_AUTO",    v_commitment_auto), --(++) Rantonio, BUG 13641139
        xmlelement("XSCN_COUNT_CR_CC",        v_count_cr_cc),
        xmlelement("XSCN_COUNT_CR_CC_TIT",    v_count_cr_cc_tit),
        xmlelement("XSCN_COUNT_CR_CP",        v_count_cr_cp),
        xmlelement("XSCN_COUNT_CR_CP_TIT",    v_count_cr_cp_tit),
        xmlelement("XSCN_COUNT_CR_CC_RT",     v_count_cr_cc_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        xmlelement("XSCN_COUNT_CR_CC_TIT_RT", v_count_cr_cc_tit_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        xmlelement("XSCN_COUNT_CR_CP_RT",     v_count_cr_cp_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        xmlelement("XSCN_COUNT_CR_CP_TIT_RT", v_count_cr_cp_tit_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        xmlelement("XSCN_COUNT_DOC_D",        v_count_doc_d),
        xmlelement("XSCN_COUNT_DOC_C",        v_count_doc_c),
        xmlelement("XSCN_COUNT_TED_OT",       v_count_ted_ot),
        xmlelement("XSCN_COUNT_TED_MT",       v_count_ted_mt),
        xmlelement("XSCN_COUNT_CHEQUE",       v_count_cheque),
        xmlelement("XSCN_COUNT_ORDEM",        v_count_ordem),
        xmlelement("XSCN_COUNT_TIT_COBR",     v_count_tit_cobr),
        xmlelement("XSCN_COUNT_TIT_COBR_OB",  v_count_tit_cobr_ob),
        xmlelement("XSCN_COUNT_TIT_CONCESS",  v_count_tit_concess), -- ADDED BY GWISZNIE FOR CONCESSIONER - 2009/05/06 -
        xmlelement("XSCN_COUNT_ALL",          v_count_all),
        --
        xmlelement("XSCN_SUM_CR_CC",          v_sum_cr_cc),
        xmlelement("XSCN_SUM_CR_CC_TIT",      v_sum_cr_cc_tit),
        xmlelement("XSCN_SUM_CR_CP",          v_sum_cr_cp),
        xmlelement("XSCN_SUM_CR_CP_TIT",      v_sum_cr_cp_tit),
        xmlelement("XSCN_SUM_CR_CC_RT",       v_sum_cr_cc_rt),     -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        xmlelement("XSCN_SUM_CR_CC_TIT_RT",   v_sum_cr_cc_tit_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        xmlelement("XSCN_SUM_CR_CP_RT",       v_sum_cr_cp_rt),     -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        xmlelement("XSCN_SUM_CR_CP_TIT_RT",   v_sum_cr_cp_tit_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
        xmlelement("XSCN_SUM_DOC_D",          v_sum_doc_d),
        xmlelement("XSCN_SUM_DOC_C",          v_sum_doc_c),
        xmlelement("XSCN_SUM_TED_OT",         v_sum_ted_ot),
        xmlelement("XSCN_SUM_TED_MT",         v_sum_ted_mt),
        xmlelement("XSCN_SUM_CHEQUE",         v_sum_cheque),
        xmlelement("XSCN_SUM_ORDEM",          v_sum_ordem),
        xmlelement("XSCN_SUM_TIT_COBR",       v_sum_tit_cobr),
        xmlelement("XSCN_SUM_TIT_COBR_OB",    v_sum_tit_cobr_ob),
        xmlelement("XSCN_SUM_TIT_CONCESS",    v_sum_tit_concess),            -- ADDED by GWisznie for Concessioner - 2009/05/06 -
        xmlelement("XSCN_SUM_DOC_TED",        l_sum_doc_ted),                -- BUG 10022107
        xmlelement("XSCN_SUM_ALL",            v_sum_all),
        xmlelement("XSCN_PAY_EXCHANGE_RATE",  nvl(g_pay_exchange_rate,1)),  -- Daniel Pimenta - 27/04/2020
        xmlelement("XSCN_VERSION",            '120.62.1')
        --(++) Rantonio, BUG 14256985      ,xmlelement("XSCN_HIST_COLLECT"     ,v_hist_collect)
      ))
    INTO l_ext_agg
    FROM dual;

    RETURN l_ext_agg;

  EXCEPTION
    WHEN no_data_found THEN
      IF ((v_count_null_barcode > 0) AND (nvl(fnd_profile.VALUE('CLL_F033_ENABLE_BARCODE_VALIDATION'), 'N') = 'Y')) THEN
        fnd_file.put_line(fnd_file.output,
                          '------------------------------------------------------------------------------------------------------------------------------------------------');
        fnd_file.put_line(fnd_file.output, 'CLL - Latin America Add-On Localizations Alert');
        fnd_file.put_line(fnd_file.output,
                          '------------------------------------------------------------------------------------------------------------------------------------------------');
        fnd_file.put_line(fnd_file.output, '');
        fnd_file.put_line(fnd_file.output, fnd_message.get_string('CLL', 'CLL_F033_BARCODE_REQUIRED'));
        fnd_file.put_line(fnd_file.output,
                          '------------------------------------------------------------------------------------------------------------------------------------------------');
        fnd_file.put_line(fnd_file.output, '');

        FOR r IN (SELECT idpa.calling_app_doc_ref_number
                        ,idpa.calling_app_doc_unique_ref3
                    FROM iby_docs_payable_all         idpa
                        ,iby_payments_all             ip
                        ,cll_f033_iby_payment_mtd_ext ipme
                   WHERE NOT EXISTS (SELECT 'X'
                            FROM jl_br_ap_collection_docs_all jbac
                           WHERE jbac.invoice_id = idpa.calling_app_doc_unique_ref2
                             AND jbac.payment_num = idpa.calling_app_doc_unique_ref3
                             AND cll_f033_iby_extract_ext_pub.get_jl_barcode(jbac.bank_collection_id) IS NOT NULL)
                     AND idpa.payment_id = ip.payment_id
                     AND ip.payment_instruction_id = p_payment_instruction_id
                     AND ip.payment_method_code = ipme.payment_method_code
                     AND ipme.attribute1 IN ('COLLECT_DOC', 'CONCESSIONER')
                   ORDER BY 1
                           ,2)
        LOOP
          fnd_file.put_line(fnd_file.output,
                            ' NFF: ' || r.calling_app_doc_ref_number || ' - ' || r.calling_app_doc_unique_ref3);
        END LOOP;

        fnd_file.put_line(fnd_file.output, '');
        fnd_file.put_line(fnd_file.output,
                          '------------------------------------------------------------------------------------------------------------------------------------------------');
        fnd_file.put_line(fnd_file.output,
                          '------------------------------------------------------------------------------------------------------------------------------------------------');

        raise_application_error(-20000, '');
      END IF;
    WHEN OTHERS THEN
      v_error := substr(SQLERRM, 1, 300);

      SELECT xmlconcat(xmlelement("XSCN9031", xmlelement("XSCN_ERROR", v_error)))
        INTO l_ext_agg
        FROM dual;

      RETURN l_ext_agg;
  END get_ins_ext_agg;

  FUNCTION get_pmt_ext_agg(p_payment_id IN NUMBER) RETURN xmltype IS

    l_ext_agg xmltype;

    v_cr_cc        VARCHAR2(1) := 'N';
    v_cr_cc_tit    VARCHAR2(1) := 'N';
    v_cr_cp        VARCHAR2(1) := 'N';
    v_cr_cp_tit    VARCHAR2(1) := 'N';
    v_cr_cc_rt     VARCHAR2(1) := 'N'; -- Added by Cristina Faria - 27/04/09 (CR_CC REAL TIME)
    v_cr_cc_tit_rt VARCHAR2(1) := 'N'; -- Added by Cristina Faria - 27/04/09 (CR_CC REAL TIME)
    v_cr_cp_rt     VARCHAR2(1) := 'N'; -- Added by Cristina Faria - 27/04/09 (CR_CC REAL TIME)
    v_cr_cp_tit_rt VARCHAR2(1) := 'N'; -- Added by Cristina Faria - 27/04/09 (CR_CC REAL TIME)
    v_doc_d        VARCHAR2(1) := 'N';
    v_doc_c        VARCHAR2(1) := 'N';
    v_ted_ot       VARCHAR2(1) := 'N';
    v_ted_mt       VARCHAR2(1) := 'N';
    v_cheque       VARCHAR2(1) := 'N';
    v_ordem        VARCHAR2(1) := 'N';
    v_tit_cobr     VARCHAR2(1) := 'N';
    v_tit_cobr_ob  VARCHAR2(1) := 'N';
    v_tit_concess  VARCHAR2(1) := 'N'; -- ADDED BY GWISZNIE FOR CONCESSIONER - 2009/05/06 -

    v_method_type        VARCHAR2(100) := NULL;
    v_payment_type_limit NUMBER := 0;
    v_pe_branch_num      VARCHAR2(100) := NULL;
    v_pe_branch_dgt      VARCHAR2(100) := NULL;
    v_pe_acct_num        VARCHAR2(100) := NULL;
    v_pe_acct_dgt        VARCHAR2(100) := NULL;

    v_rep_registration_number VARCHAR2(20) := NULL;
    v_registration_type_code  VARCHAR2(10) := NULL;
    v_check_horizontal        VARCHAR2(50) := NULL;
    v_future_pay_due_date     VARCHAR2(10) := NULL;

    v_type_code VARCHAR2(10) := NULL;

    v_branch_id NUMBER;
    v_return_id NUMBER;

    v_error VARCHAR2(300) := NULL;
    v_type  VARCHAR2(20) := NULL;

    r iby_payments_all%ROWTYPE;

    l_reg_number_payee NUMBER; -- BUG 7426668
    l_reg_number_payer NUMBER; -- BUG 7426668

    v_acct_type     VARCHAR2(50) := NULL; --(++) Rantonio, BUG 13334814
    v_cc_cp         VARCHAR2(10) := '1'; --(++) Rantonio, BUG 13693473
    v_inf_compl     VARCHAR2(100) := NULL; --(++) Rantonio, BUG 13693473
    v_compl_374_374 VARCHAR2(50) := NULL; --(++) Rantonio, BUG 13693473
    v_compl_375_380 VARCHAR2(50) := NULL; --(++) Rantonio, BUG 13693473
    v_compl_381_382 VARCHAR2(50) := NULL; --(++) Rantonio, BUG 13693473
    v_compl_383_384 VARCHAR2(50) := NULL; --(++) Rantonio, BUG 13693473

    l_length_pe_acct_dgt NUMBER; -- Bug 15948357

  BEGIN

    BEGIN
      SELECT *
        INTO r
        FROM iby_payments_all ip
       WHERE ip.payment_id = p_payment_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    /* XSCN Begin - Functional Amount (Ledger Currency) */
    r.payment_amount := nvl(xscn_get_pay_func_amount(r.payment_id), r.payment_amount);
    /* XSCN END - Functional Amount (Ledger Currency) */
    IF (jg_zz_shared_pkg.get_country(r.org_id, NULL, NULL) <> 'BR') THEN
      raise_application_error(-20070, 'INVALID COUNTRY CODE');
    END IF;

    BEGIN
      SELECT ibi.format_value
        INTO v_payment_type_limit
        FROM iby_bank_instructions_vl ibi
       WHERE ibi.bank_instruction_code = 'CLL_F033_PAYMENT_TYPE_LIMIT';
    EXCEPTION
      WHEN OTHERS THEN
        v_payment_type_limit := 0;
    END;

    BEGIN
      SELECT aca.future_pay_due_date
        INTO v_future_pay_due_date
        FROM ap_checks_all aca
       WHERE aca.payment_id = r.payment_id;
    EXCEPTION
      WHEN OTHERS THEN
        v_future_pay_due_date := NULL;
    END;

    BEGIN
      SELECT decode(ss.global_attribute9, '1', 'CPF', '2', 'CNPJ', 'OTHERS') registration_type_code
            ,to_number(decode(ss.global_attribute9,
                              '1',
                              lpad(substr(nvl(ss.global_attribute10, '0'), 1, 9), 9, '0') ||
                              lpad(nvl(ss.global_attribute12, '0'), 2, '0'),
                              lpad(substr(nvl(ss.global_attribute10, '0'), 1, 9), 9, '0') ||
                              lpad(nvl(ss.global_attribute11, '0'), 4, '0') ||
                              lpad(nvl(ss.global_attribute12, '0'), 2, '0'))) registration_number
            ,to_number(lpad(substr(nvl(ss.global_attribute10, '0'), 1, 9), 9, '0')) -- BUG 7426668
        INTO v_registration_type_code
            ,v_rep_registration_number
            ,l_reg_number_payee
        FROM ap_supplier_sites_all ss
       WHERE ss.vendor_site_id = r.supplier_site_id
         AND ss.org_id = r.org_id;
    EXCEPTION
      WHEN OTHERS THEN
        v_rep_registration_number := NULL;
        v_registration_type_code  := NULL;
    END;

    BEGIN
      SELECT to_number(substr(lpad(le_registration_number, 14, 0), 1, 9))
        INTO l_reg_number_payer
        FROM iby_ext_fd_payer_1_0_v
       WHERE party_id = r.payer_party_id;
    EXCEPTION
      WHEN OTHERS THEN
        -- Cause information should be with characters alpha
        l_reg_number_payer := 0;
    END;

    BEGIN
      IF (instr(r.ext_branch_number, '-') > 0) THEN
        v_pe_branch_num := substr(r.ext_branch_number, 1, instr(r.ext_branch_number, '-') - 1);
        v_pe_branch_dgt := substr(r.ext_branch_number, instr(r.ext_branch_number, '-') + 1);
      ELSE
        v_pe_branch_num := r.ext_branch_number;
      END IF;

      SELECT iba.bank_account_num
            ,iba.check_digits
            ,iba.bank_account_type --(++) Rantonio, BUG 13334814
        INTO r.ext_bank_account_number
            ,v_pe_acct_dgt
            ,v_acct_type --(++) Rantonio, BUG 13334814
        FROM iby_ext_bank_accounts iba
       WHERE iba.ext_bank_account_id = r.external_bank_account_id;

      IF (instr(r.ext_bank_account_number, '-') > 0) THEN
        v_pe_acct_num := substr(r.ext_bank_account_number, 1, instr(r.ext_bank_account_number, '-') - 1);

        IF (v_pe_acct_dgt IS NULL) THEN
          v_pe_acct_dgt := substr(r.ext_bank_account_number, instr(r.ext_bank_account_number, '-') + 1);
        END IF;
      ELSE
        v_pe_acct_num := r.ext_bank_account_number;
      END IF;

      -- Bug 15948357 - Start
      l_length_pe_acct_dgt := length(v_pe_acct_dgt);
      --
      IF r.int_bank_number = '033' THEN
        --
        IF r.ext_bank_number = '399' THEN
          --
          IF l_length_pe_acct_dgt > 1 THEN
            --
            v_pe_acct_num := v_pe_acct_num || substr(v_pe_acct_dgt, 1, l_length_pe_acct_dgt - 1);
            v_pe_acct_dgt := substr(v_pe_acct_dgt, l_length_pe_acct_dgt, 1);
            --
          END IF;
          --
        END IF;
        --
      END IF;
      -- Bug 15948357 - End

      IF (v_pe_branch_dgt IS NULL) THEN
        SELECT hpe.attribute1
          INTO v_pe_branch_dgt
          FROM cll_f033_hz_parties_ext hpe
         WHERE hpe.party_id = r.ext_bank_branch_party_id;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    BEGIN
      --
      v_method_type := 'METHOD_TYPE_NULL';
      --
      SELECT nvl(ipme.attribute1, 'METHOD_TYPE_NULL')
        INTO v_method_type
        FROM cll_f033_iby_payment_mtd_ext ipme
       WHERE ipme.payment_method_code = r.payment_method_code;
    EXCEPTION
      WHEN OTHERS THEN
        v_method_type := 'METHOD_TYPE_NULL';
    END;

    /*CR CC-CP*/
    IF ((l_reg_number_payee <> l_reg_number_payer) AND -- BUG 7426668
       (r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'ELECTRONIC')) THEN
      IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
        v_cr_cp := 'Y';
      ELSE
        v_cr_cc := 'Y';
      END IF;

      /*CR CC-CP RT*/ -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    ELSIF ((l_reg_number_payee <> l_reg_number_payer) AND -- BUG 7426668
          (r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'REAL_TIME')) THEN
      IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
        v_cr_cp_rt := 'Y';
      ELSE
        v_cr_cc_rt := 'Y';
      END IF;

      /*CR CC-CP TIT*/
    ELSIF ((l_reg_number_payee = l_reg_number_payer) AND -- BUG 7426668
          (r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'ELECTRONIC')) THEN
      IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
        v_cr_cp_tit := 'Y';
      ELSE
        v_cr_cc_tit := 'Y';
      END IF;

      /*CR CC-CP TIT RT*/ -- Added by Cristina Faria - 27/04/09 (REAL TIME)
    ELSIF ((l_reg_number_payee = l_reg_number_payer) AND -- BUG 7426668
          (r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'REAL_TIME')) THEN
      IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
        v_cr_cp_tit_rt := 'Y';
      ELSE
        v_cr_cc_tit_rt := 'Y';
      END IF;

      /*DOC D*/
    ELSIF ((l_reg_number_payee = l_reg_number_payer) AND -- BUG 7426668
          (r.ext_bank_number <> r.int_bank_number) AND (r.payment_amount < v_payment_type_limit) AND
          (v_method_type = 'ELECTRONIC')) THEN
      v_doc_d := 'Y';

      /*DOC C*/
    ELSIF ((l_reg_number_payee <> l_reg_number_payer) AND -- BUG 7426668
          (r.ext_bank_number <> r.int_bank_number) AND (r.payment_amount < v_payment_type_limit) AND
          (v_method_type = 'ELECTRONIC')) THEN
      v_doc_c := 'Y';

      /*TED OT*/
    ELSIF ((l_reg_number_payee <> l_reg_number_payer) AND -- BUG 7426668
          (r.ext_bank_number <> r.int_bank_number) AND (r.payment_amount >= v_payment_type_limit) AND
          ((v_method_type = 'ELECTRONIC') OR (v_method_type LIKE 'TED%'))) THEN
      v_ted_ot := 'Y';

      /*TED MT*/
    ELSIF ((l_reg_number_payee = l_reg_number_payer) AND -- BUG 7426668 ELSIF ((R.PAYEE_PARTY_ID  =   R.PAYER_PARTY_ID)
          (r.ext_bank_number <> r.int_bank_number) AND (r.payment_amount >= v_payment_type_limit) AND
          ((v_method_type = 'ELECTRONIC') OR (v_method_type LIKE 'TED%'))) THEN
      v_ted_mt := 'Y';

      /*CHEQUE*/
    ELSIF (v_method_type = 'CHECK') THEN
      v_cheque := 'Y';

      /*ORDEM*/
    ELSIF (v_method_type = 'PAYMENT_ORDER') THEN
      v_ordem := 'Y';
      -- Bug 14461264 - Valeria Zana - Begin
      IF (instr(r.int_bank_branch_number, '-') > 0) THEN
        v_pe_branch_num := substr(r.int_bank_branch_number, 1, instr(r.int_bank_branch_number, '-') - 1);
        v_pe_branch_dgt := substr(r.int_bank_branch_number, instr(r.int_bank_branch_number, '-') + 1);
      ELSE
        v_pe_branch_num := r.int_bank_branch_number;
      END IF;
      -- Bug 14461264 - Valeria Zana - End

      /*TIT*/
    ELSIF (v_method_type = 'COLLECT_DOC') THEN
      v_tit_cobr := 'Y';

      /* CONCESS */
    ELSIF (v_method_type = 'CONCESSIONER') THEN
      v_tit_concess := 'Y';
      --
    END IF;

    IF (v_cr_cp = 'Y') THEN
      v_type := 'CR_CP';
    ELSIF (v_cr_cp_rt = 'Y') THEN
      v_type := 'CR_CP_RT';
    ELSIF (v_cr_cc = 'Y') THEN
      v_type := 'CR_CC';
    ELSIF (v_cr_cc_rt = 'Y') THEN
      v_type := 'CR_CC_RT';
    ELSIF (v_cr_cp_tit = 'Y') THEN
      v_type := 'CR_CP_TIT';
    ELSIF (v_cr_cp_tit_rt = 'Y') THEN
      v_type := 'CR_CP_TIT_RT';
    ELSIF (v_cr_cc_tit = 'Y') THEN
      v_type := 'CR_CC_TIT';
    ELSIF (v_cr_cc_tit_rt = 'Y') THEN
      v_type := 'CR_CC_TIT_RT';
    ELSIF (v_doc_d = 'Y') THEN
      v_type := 'DOC_D';
    ELSIF (v_doc_c = 'Y') THEN
      v_type := 'DOC_C';
    ELSIF (v_ted_ot = 'Y') THEN
      v_type := 'TED_OT';
    ELSIF (v_ted_mt = 'Y') THEN
      v_type := 'TED_MT';
    ELSIF (v_cheque = 'Y') THEN
      v_type := 'CHEQUE';
    ELSIF (v_ordem = 'Y') THEN
      v_type := 'ORDEM';
    END IF;

    IF (v_method_type NOT IN ('COLLECT_DOC', 'CONCESSIONER')) -- Modified by GWisznie for Concessioner - 2009/05/06 -
     THEN
      generate_collection_returns(p_payment_id => p_payment_id, p_return_id => v_return_id, p_type => v_type);
    END IF;

    IF (r.int_bank_number = '237') THEN

      /* XSCN Begin */
      IF ((r.ext_bank_number = r.int_bank_number) AND (v_method_type = 'ELECTRONIC')) THEN
        v_cr_cc_rt := 'Y';
      END IF;
      /* XSCN End */

      -- Alter by Cristina Faria - 27/04/09
      --IF (V_METHOD_TYPE LIKE '%REAL_TIME%') THEN
      IF ('Y' IN (v_cr_cc_rt, v_cr_cc_tit_rt, v_cr_cp_rt, v_cr_cp_tit_rt)) THEN
        v_type_code := '05';
        --
        -- Alter by Cristina Faria - 27/04/09
        --ELSIF ('Y' IN (V_CR_CC,V_CR_CC_TIT)) THEN
      ELSIF ('Y' IN (v_cr_cc, v_cr_cc_tit, v_cr_cp, v_cr_cp_tit)) THEN
        v_type_code := '01';
        --
      ELSIF ('Y' IN (v_doc_d, v_doc_c)) THEN
        v_type_code := '03';
      ELSIF ('Y' IN (v_ted_ot, v_ted_mt)) THEN
        --         IF (V_METHOD_TYPE = 'TED_STR') THEN -- Bug 10213702
        v_type_code := '08';
        --         ELSE                                -- Bug 10213702
        --            V_TYPE_CODE := '07';             -- Bug 10213702
        --         END IF;                             -- Bug 10213702
      ELSIF ('Y' IN (v_cheque, v_ordem)) THEN
        v_type_code := '02';
      ELSIF (v_tit_cobr = 'Y') THEN
        v_type_code := 'NULL';
      ELSIF (v_tit_cobr_ob = 'Y') THEN
        v_type_code := 'NULL';
      END IF;
      --
    ELSIF (r.int_bank_number IN ('275', '356')) THEN
      --
      IF ('Y' IN (v_cr_cc, v_cr_cc_tit, v_cr_cp, v_cr_cp_tit, v_ordem)) THEN
        v_type_code := '2';
      ELSIF ('Y' IN (v_doc_d, v_doc_c, v_ted_mt, v_ted_ot)) THEN
        v_type_code := '4';
      ELSIF ('Y' IN (v_cheque)) THEN
        v_type_code := '1';
      ELSIF ('Y' IN (v_tit_cobr, v_tit_cobr_ob)) THEN
        v_type_code := '6';
      END IF;
      --
    ELSIF (r.int_bank_number = '409') THEN
      --
      IF (v_method_type LIKE '%TED%') THEN
        v_type_code := '8';
      ELSIF (('Y' IN (v_ted_mt, v_ted_ot)) OR (v_method_type = 'TIR')) THEN
        v_type_code := '7';
      ELSE
        v_type_code := '5';
      END IF;
      --
      v_check_horizontal := lpad(r.ext_bank_number, 4, '0') || lpad(substr(to_number(v_pe_branch_num), 1, 4), 4, '0') ||
                            lpad(substr(nvl(v_pe_acct_num, '0'), 1, 10), 10, '0');
      --
      v_check_horizontal := to_char(v_check_horizontal + (r.payment_amount * 100)) * v_type_code;
      --
      v_check_horizontal := lpad(substr(lpad(v_check_horizontal, 18, '0'),
                                        (length(lpad(v_check_horizontal, 18, '0')) - 18 + 1)),
                                 18,
                                 '0');
      --
    END IF;

    --
    --(++) Rantonio, BUG 13693473 (BEGIN)
    --
    IF v_type_code IN ('01', '05')
       AND (v_cr_cp = 'Y' OR v_cr_cp_rt = 'Y' OR v_cr_cp_tit = 'Y' OR v_cr_cp_tit_rt = 'Y') THEN
      --
      v_cc_cp := '2';
      --
    ELSE
      --
      v_cc_cp := '1';
      --
    END IF;
    --
    IF v_type_code IN ('03', '08') THEN
      --
      IF l_reg_number_payee <> l_reg_number_payer THEN
        --
        v_compl_374_374 := 'C';
        --
        IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
          --
          v_compl_381_382 := '11'; /* DOC/TED Poupanca */
          --
        ELSE
          --
          v_compl_381_382 := '01'; /* Cred Conta Corrente */
          --
        END IF;
        --
      ELSE
        --
        v_compl_374_374 := 'D';
        v_compl_381_382 := '01';
        --
      END IF;
      --
      v_compl_375_380 := '000000';
      --
      IF (nvl(r.ext_bank_account_type, 'CC') = 'POUPANCA') THEN
        --
        v_compl_383_384 := '02';
        --
      ELSE
        --
        v_compl_383_384 := '01';
        --
      END IF;
      --
      v_inf_compl := v_compl_374_374 || v_compl_375_380 || v_compl_381_382 || v_compl_383_384;
      --
    END IF;
    --
    --(++) Rantonio, BUG 13693473 (END)
    --

    --
    --(++) Rantonio, BUG 13334814 (BEGIN)
    --
    IF r.int_bank_number IN ('104') THEN
      --
      v_return_id := substr(lpad(v_return_id, 20, '0'), 15, 6);
      --
    END IF;
    --
    --(++) Rantonio, BUG 13334814 (END)
    --

    SELECT xmlconcat(xmlelement("XSCN9031",
                                xmlelement("XSCN_PAYEE_BRANCH_NUM", v_pe_branch_num),
                                xmlelement("XSCN_PAYEE_BRANCH_DGT", v_pe_branch_dgt),
                                xmlelement("XSCN_PAYEE_ACCT_NUM", v_pe_acct_num),
                                xmlelement("XSCN_PAYEE_ACCT_DGT", v_pe_acct_dgt),
                                xmlelement("XSCN_MOVEMENT_CODE", v_acct_type), --(++) Rantonio, BUG 13334814
                                xmlelement("XSCN_CC_CP", v_cc_cp), --(++) Rantonio, BUG 13693473
                                xmlelement("XSCN_INF_COMPL", v_inf_compl), --(++) Rantonio, BUG 13693473
                                xmlelement("XSCN_CR_CC", v_cr_cc),
                                xmlelement("XSCN_CR_CC_TIT", v_cr_cc_tit),
                                xmlelement("XSCN_CR_CP", v_cr_cp),
                                xmlelement("XSCN_CR_CP_TIT", v_cr_cp_tit),
                                xmlelement("XSCN_CR_CC_RT", v_cr_cc_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                                xmlelement("XSCN_CR_CC_TIT_RT", v_cr_cc_tit_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                                xmlelement("XSCN_CR_CP_RT", v_cr_cp_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                                xmlelement("XSCN_CR_CP_TIT_RT", v_cr_cp_tit_rt), -- Added by Cristina Faria - 27/04/09 (REAL TIME)
                                xmlelement("XSCN_DOC_D", v_doc_d),
                                xmlelement("XSCN_DOC_C", v_doc_c),
                                xmlelement("XSCN_TED_OT", v_ted_ot),
                                xmlelement("XSCN_TED_MT", v_ted_mt),
                                xmlelement("XSCN_CHEQUE", v_cheque),
                                xmlelement("XSCN_ORDEM", v_ordem),
                                xmlelement("XSCN_TIT_COBR", v_tit_cobr),
                                xmlelement("XSCN_TIT_COBR_OB", v_tit_cobr_ob),
                                xmlelement("XSCN_TIT_CONCESS", v_tit_concess), -- ADDED BY GWISZNIE FOR CONCESSIONER - 2009/05/06 -
                                xmlelement("XSCN_REP_REGISTRATION_NUMBER",  v_rep_registration_number),
                                xmlelement("XSCN_REGISTRATION_TYPE_CODE",   v_registration_type_code),
                                xmlelement("XSCN_FUTURE_PAY_DUE_DATE",      v_future_pay_due_date),
                                xmlelement("XSCN_RETURN_ID",                v_return_id),
                                xmlelement("XSCN_TYPE_CODE",                v_type_code),
                                xmlelement("XSCN_CHECK_HORIZONTAL",         v_check_horizontal),
                                xmlelement("XSCN_METHOD_TYPE",              v_method_type),
                                xmlelement("XSCN_FUNCIONAL_AMOUNT",         r.payment_amount),
                                xmlelement("XSCN_PAY_EXCHANGE_RATE",        nvl(g_pay_exchange_rate,1))  -- Daniel Pimenta - 27/04/2020
                                ))
      INTO l_ext_agg
      FROM dual;

    RETURN l_ext_agg;

  EXCEPTION
    WHEN OTHERS THEN
      v_error := substr(SQLERRM, 1, 300);

      SELECT xmlconcat(xmlelement("XSCN9031", xmlelement("XSCN_ERROR", v_error)))
        INTO l_ext_agg
        FROM dual;

      RETURN l_ext_agg;
  END get_pmt_ext_agg;
  --
  --
  FUNCTION get_doc_ext_agg(p_document_payable_id IN NUMBER) RETURN xmltype IS
    --
    r iby_docs_payable_all%ROWTYPE;
    --
    l_ext_agg              xmltype;
    v_bar_code             VARCHAR2(150) := NULL;
    v_check_id             NUMBER;
    v_tit_cobr             VARCHAR2(1) := 'N';
    v_tit_cobr_ob          VARCHAR2(1) := 'N';
    v_ext_bank_number      VARCHAR2(5) := NULL;
    v_int_bank_number      VARCHAR2(5) := NULL;
    v_method_type          VARCHAR2(100) := NULL;
    v_return_id            NUMBER;
    v_error                VARCHAR2(300) := NULL;
    v_type                 VARCHAR2(2) := NULL;
    v_tit_concess          VARCHAR2(1) := 'N'; -- ADDED BY GWISZNIE FOR CONCESSIONER - 2009/05/06 -
    v_interest             NUMBER := 0; --(++) Rantonio, BUG 13805036
    v_pay_sup_doc_type     VARCHAR2(150) := NULL;
    v_pay_sup_doc_num      VARCHAR2(150) := NULL;
    v_pay_sup_name         VARCHAR2(150) := NULL;
    v_inv_sup_doc_type     VARCHAR2(150) := NULL;
    v_inv_sup_doc_num      VARCHAR2(150) := NULL;
    v_inv_sup_name         VARCHAR2(150) := NULL;
    l_j52_seg_active_value VARCHAR2(80) := NULL; -- Bug 16536302
    v_j52_active           VARCHAR2(1) := 'N'; -- Bug 16536302
    --

  BEGIN
    --
    BEGIN
      SELECT *
        INTO r
        FROM iby_docs_payable_all idpa
       WHERE idpa.document_payable_id = p_document_payable_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    r.payment_amount := nvl(xscn_get_pay_func_amount(r.payment_id), r.payment_amount); -- Daniel Pimenta  02/06/2020
    --
    -- Bug 16536302 - Start
    BEGIN
      SELECT ibi.format_value
        INTO l_j52_seg_active_value
        FROM iby_bank_instructions_vl ibi
       WHERE ibi.bank_instruction_code = 'CLL_F033_J52_SEG_ACTIVE_VALUE';
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- Bug 16536302 - End;
    --
    IF (jg_zz_shared_pkg.get_country(r.org_id, NULL, NULL) <> 'BR') THEN
      raise_application_error(-20070, 'INVALID COUNTRY CODE');
    END IF;
    --
    init_doc_attributes;
    --
    BEGIN
      --
      v_method_type := 'METHOD_TYPE_NULL';
      --
      SELECT nvl(ipme.attribute1, 'METHOD_TYPE_NULL')
        INTO v_method_type
        FROM cll_f033_iby_payment_mtd_ext ipme
       WHERE ipme.payment_method_code = r.payment_method_code;
      --
    EXCEPTION
      WHEN OTHERS THEN
        v_method_type := 'METHOD_TYPE_NULL';
    END;
    --
    BEGIN
      --
      IF (v_method_type IN ('COLLECT_DOC', 'CONCESSIONER')) THEN
        --
        SELECT ip.int_bank_number --IP.EXT_BANK_NUMBER  -- Commented by Cristina Faria - 25/05/09
          INTO v_int_bank_number --V_EXT_BANK_NUMBER -- Commented by Cristina Faria - 25/05/09
          FROM iby_payments_all ip
         WHERE ip.payment_id = r.payment_id;
        --
        v_bar_code := get_bar_code(p_document_payable_id);
        --
        --V_EXT_BANK_NUMBER := SUBSTR(V_BAR_CODE),1,3); -- Alter by Cristina Faria - 25/05/09 Bug 8546611
        v_ext_bank_number := substr(REPLACE(v_bar_code, 'CDB'), 1, 3);
        --
        IF v_method_type = 'COLLECT_DOC' THEN

          --
          /*TIT SAME BANK*/
          IF (v_int_bank_number = nvl(v_ext_bank_number, '999')) THEN
            v_tit_cobr := 'Y';
            /*TIT OTHER BANK*/
          ELSE
            v_tit_cobr_ob := 'Y';
          END IF;
          --
          --(++) Rantonio, BUG 12972244 (BEGIN)
          --
          IF r.document_type = 'INTEREST' THEN
            --
            v_tit_cobr    := 'N';
            v_tit_cobr_ob := 'N';
            --
          END IF;
          --
          --(++) Rantonio, BUG 12972244 (END)
          --
          --
          --(++) Rantonio, BUG 13805036 (BEGIN)
          --
          BEGIN
            SELECT nvl(SUM(payment_amount), 0)
              INTO v_interest
              FROM iby_docs_payable_all
             WHERE calling_app_doc_ref_number LIKE r.calling_app_doc_ref_number || '-INT%'
               AND document_type = 'INTEREST'
               AND document_status = 'PAYMENT_CREATED'
               AND payment_id = r.payment_id
               AND ext_payee_id = r.ext_payee_id
               AND payee_party_id = r.payee_party_id
               AND org_id = r.org_id;
          EXCEPTION
            WHEN OTHERS THEN
              v_interest := 0;
          END;
          --
          --(++) Rantonio, BUG 13805036 (END)
          --
          -- Bug 16536302 - Start
          IF r.payment_amount + v_interest >= nvl(l_j52_seg_active_value, r.payment_amount + v_interest + 1) THEN
            v_j52_active := 'Y';
          END IF;
          -- Bug 16536302 - End
          --
        ELSIF v_method_type = 'CONCESSIONER' THEN
          -- ADDED BY GWISZNIE FOR CONCESSIONER - 2009/05/06 -
          v_tit_concess := 'Y';
        END IF;
        --
        -- IF (v_tit_cobr = 'Y') THEN -- Modified by GWisznie for Concessioner - 2009/05/06 -
        IF ('Y' IN (v_tit_cobr, v_tit_concess)) THEN
          v_type := 'SB';
        ELSE
          v_type := 'OB';
        END IF;
        --
        generate_collection_returns(p_doc_payable_id => p_document_payable_id,
                                    p_payment_id     => r.payment_id, -- Bug 14473974
                                    p_return_id      => v_return_id,
                                    p_type           => v_type);
        --
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    --
    --(++) Rantonio, BUG 13641139 (BEGIN)
    --
    IF v_int_bank_number IN ('104') THEN
      --
      v_return_id := substr(lpad(v_return_id, 20, '0'), 15, 6);
      --
    END IF;
    --
    --(++) Rantonio, BUG 13641139 (END)
    --

    -- Bug 16536302 - Start
    get_pay_supplier_inf(p_doc_payable_id   => p_document_payable_id,
                         p_pay_sup_doc_type => v_pay_sup_doc_type,
                         p_pay_sup_doc_num  => v_pay_sup_doc_num,
                         p_pay_sup_name     => v_pay_sup_name);
    --
    get_inv_supplier_inf(p_doc_payable_id   => p_document_payable_id,
                         p_inv_sup_doc_type => v_inv_sup_doc_type,
                         p_inv_sup_doc_num  => v_inv_sup_doc_num,
                         p_inv_sup_name     => v_inv_sup_name);
    -- Bug 16536302 - End.

    SELECT xmlconcat(xmlelement("XSCN9031",
                                xmlelement("XSCN_BAR_CODE", v_bar_code),
                                xmlelement("XSCN_TIT_COBR", v_tit_cobr),
                                xmlelement("XSCN_TIT_COBR_OB", v_tit_cobr_ob),
                                xmlelement("XSCN_J52_ACTIVE", v_j52_active), -- Bug 16536302
                                xmlelement("XSCN_TIT_CONCESS", v_tit_concess),
                                xmlelement("XSCN_RETURN_ID", v_return_id),
                                xmlelement("XSCN_DOC_ATTRIBUTE1", g_doc_attribute1),
                                xmlelement("XSCN_DOC_ATTRIBUTE2", g_doc_attribute2),
                                xmlelement("XSCN_DOC_ATTRIBUTE3", g_doc_attribute3),
                                xmlelement("XSCN_DOC_ATTRIBUTE4", g_doc_attribute4),
                                xmlelement("XSCN_DOC_ATTRIBUTE5", g_doc_attribute5),
                                xmlelement("XSCN_DOC_ATTRIBUTE6", g_doc_attribute6),
                                xmlelement("XSCN_DOC_ATTRIBUTE7", g_doc_attribute7),
                                xmlelement("XSCN_DOC_ATTRIBUTE8", g_doc_attribute8),
                                xmlelement("XSCN_DOC_ATTRIBUTE9", g_doc_attribute9),
                                xmlelement("XSCN_DOC_ATTRIBUTE10", g_doc_attribute10),
                                xmlelement("XSCN_INTEREST_AMT", v_interest) --(++) Rantonio, BUG 13805036
                                -- Bug 16536302 - Start
                                ,
                                xmlelement("XSCN_INV_SUP_REG_TYPE_CODE", v_inv_sup_doc_type),
                                xmlelement("XSCN_INV_SUP_REG_NUMBER", v_inv_sup_doc_num),
                                xmlelement("XSCN_INV_SUP_NAME", v_inv_sup_name),
                                xmlelement("XSCN_PAY_SUP_REG_TYPE_CODE", v_pay_sup_doc_type),
                                xmlelement("XSCN_PAY_SUP_REG_NUMBER", v_pay_sup_doc_num),
                                xmlelement("XSCN_PAY_SUP_NAME", v_pay_sup_name),
                                -- Bug 16536302 - End.
                                xmlelement("XSCN_FUNCIONAL_AMOUNT", r.payment_amount) --DANIEL PIMENTA 06/06/2020
                                ))
      INTO l_ext_agg
      FROM dual;

    RETURN l_ext_agg;

  EXCEPTION
    WHEN OTHERS THEN
      --
      v_error := substr(SQLERRM, 1, 300);
      --
      SELECT xmlconcat(xmlelement("XSCN9031", xmlelement("XSCN_ERROR", v_error)))
        INTO l_ext_agg
        FROM dual;
      --
      RETURN l_ext_agg;
      --
  END get_doc_ext_agg;
  --
  -- Bug 16536302 - Start
  PROCEDURE get_pay_supplier_inf(p_doc_payable_id   IN NUMBER
                                ,p_pay_sup_doc_type OUT NOCOPY VARCHAR2
                                ,p_pay_sup_doc_num  OUT NOCOPY VARCHAR2
                                ,p_pay_sup_name     OUT NOCOPY VARCHAR2) IS

    r iby_docs_payable_all%ROWTYPE;

  BEGIN

    -- Retorna informacoes sobre o pagamento
    BEGIN
      SELECT *
        INTO r
        FROM iby_docs_payable_all idpa
       WHERE idpa.document_payable_id = p_doc_payable_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    -- Retorna Tipo de Doc, Numero de Doc e Nome do Fornecedor do Pagamento
    BEGIN
      SELECT supsite.global_attribute9 -- Transferor Document Type
            ,supsite.global_attribute10 || supsite.global_attribute11 || supsite.global_attribute12 -- Transferor Document Number
            ,sup.vendor_name -- Transferor Name
        INTO p_pay_sup_doc_type
            ,p_pay_sup_doc_num
            ,p_pay_sup_name
        FROM ap_supplier_sites_all supsite
            ,ap_suppliers          sup
       WHERE supsite.vendor_site_id = r.supplier_site_id
         AND sup.vendor_id = supsite.vendor_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END get_pay_supplier_inf;
  --
  PROCEDURE get_inv_supplier_inf(p_doc_payable_id   IN NUMBER
                                ,p_inv_sup_doc_type OUT NOCOPY VARCHAR2
                                ,p_inv_sup_doc_num  OUT NOCOPY VARCHAR2
                                ,p_inv_sup_name     OUT NOCOPY VARCHAR2) IS
    --
    r iby_docs_payable_all%ROWTYPE;

    same_payee_doc_supplier EXCEPTION;
    --
  BEGIN

    -- Retorna informacoes sobre o pagamento
    BEGIN
      SELECT *
        INTO r
        FROM iby_docs_payable_all idpa
       WHERE idpa.document_payable_id = p_doc_payable_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    IF r.supplier_site_id = r.inv_supplier_site_id THEN
      --
      RAISE same_payee_doc_supplier;
      --
    END IF;

    -- Retorna Tipo de Doc, Numero de Doc e Nome do Fornecedor da NF
    BEGIN
      SELECT supsite.global_attribute9 -- Guarantor Document Type
            ,supsite.global_attribute10 || supsite.global_attribute11 || supsite.global_attribute12 -- Guarantor Document Number
            ,sup.vendor_name -- Guarantor Name
        INTO p_inv_sup_doc_type
            ,p_inv_sup_doc_num
            ,p_inv_sup_name
        FROM ap_supplier_sites_all supsite
            ,ap_suppliers          sup
       WHERE supsite.vendor_site_id = r.inv_supplier_site_id
         AND sup.vendor_id = supsite.vendor_id;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

  EXCEPTION
    WHEN same_payee_doc_supplier THEN
      p_inv_sup_doc_type := NULL;
      p_inv_sup_doc_num  := NULL;
      p_inv_sup_name     := NULL;
    WHEN OTHERS THEN
      NULL;
  END get_inv_supplier_inf;
  -- Bug 16536302 - End.

  FUNCTION xscn_get_pay_func_amount(p_payment_id IN NUMBER) RETURN NUMBER IS
    --
    l_npayment_amount apps.iby_payments_all.payment_amount%TYPE;
    l_nexchange_rate  apps.ap_user_exchange_rates.exchange_rate%TYPE;
    --
  BEGIN
    --
    l_npayment_amount := NULL;
    --
    FOR x IN (SELECT ipa.payment_currency_code
                    ,gl.currency_code ledger_currency_code
                    ,ipa.payment_amount
                    ,ipa.payment_process_request_name
                    ,ipa.org_id
                FROM apps.iby_payments_all   ipa
                    ,apps.hr_operating_units hou
                    ,apps.gl_ledgers         gl
               WHERE ipa.org_id = hou.organization_id
                 AND hou.set_of_books_id = gl.ledger_id
                 AND ipa.payment_id = p_payment_id)
    --
    LOOP
      --
      IF x.payment_currency_code <> x.ledger_currency_code THEN
        --
        -- Pagamento feito lote
        --
        BEGIN
          --
          SELECT asia.payment_exchange_rate
            INTO l_nexchange_rate
            FROM apps.ap_selected_invoices_all asia
                ,apps.gl_ledgers               gl
           WHERE asia.set_of_books_id = gl.ledger_id
             AND asia.checkrun_name = x.payment_process_request_name
             AND asia.payment_currency_code = x.payment_currency_code
             AND gl.currency_code = x.ledger_currency_code
             AND nvl(asia.org_id, x.org_id) = x.org_id
           GROUP BY asia.payment_exchange_rate;
          --
          g_pay_exchange_rate := nvl(l_nexchange_rate,1);  -- Daniel Pimenta - 27/04/2020
          l_npayment_amount   := round(x.payment_amount * l_nexchange_rate, 2);
          --
        EXCEPTION
          WHEN no_data_found THEN
            --
            -- Pagamento feito pela tela rapida
            --
            BEGIN
              SELECT aca.base_amount
                    ,aca.exchange_rate
                INTO l_npayment_amount
                    ,l_nexchange_rate
                FROM apps.ap_checks_all aca
               WHERE aca.payment_id = p_payment_id;
               g_pay_exchange_rate := nvl(l_nexchange_rate,1);  -- Daniel Pimenta - 27/04/2020
            EXCEPTION
              WHEN no_data_found THEN
                NULL;
            END;
        END;
        --
      END IF;
      --
      RETURN(l_npayment_amount);
      --
    END LOOP;
  END xscn_get_pay_func_amount;

END xscn_9031_iby_extract_ext_pub;