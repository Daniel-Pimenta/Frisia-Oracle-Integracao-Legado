create or replace PACKAGE BODY xxfr_f189_interface_pkg AS

  g_escopo    varchar2(50) := 'xxfr_f189_interface_pkg';

  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;

-------------------------------------------------------------------------------
-->                              FA Interface                               <--
-------------------------------------------------------------------------------
  PROCEDURE fa (p_operation_id    IN NUMBER,
                p_organization_id IN NUMBER,
                p_created_by      IN NUMBER) AS
  BEGIN
    NULL;
  END fa;

-------------------------------------------------------------------------------
-->                             FSC Interface                               <--
-------------------------------------------------------------------------------
  PROCEDURE fsc (p_operation_id    IN NUMBER,
                 p_organization_id IN NUMBER,
                 p_created_by      IN NUMBER) AS
  BEGIN
    NULL;
  END fsc;

-------------------------------------------------------------------------------
-->                              GL Interface                               <--
-------------------------------------------------------------------------------
  PROCEDURE gl (
    p_operation_id    IN NUMBER,
    p_organization_id IN NUMBER
  ) AS
    --
    v_chart_of_accounts_id       NUMBER;
    v_period_name                VARCHAR2(15);
    v_set_of_books_id            NUMBER;
    v_set_of_books_id_alt1       NUMBER;
    v_set_of_books_id_alt2       NUMBER;
    v_trans_factor_alt1          NUMBER;
    v_trans_factor_alt2          NUMBER;
    v_currency_code              VARCHAR2(15);
    v_organization_id            NUMBER;
    v_created_by                 NUMBER;
    v_receive_date               DATE;
    v_je_descriptiongl           VARCHAR2(240);
    v_je_description1n           VARCHAR2(240);
    v_je_description1f           VARCHAR2(240);
    v_je_description2n           VARCHAR2(240);
    v_je_description2f           VARCHAR2(240);
    v_date_gl                    DATE;
    v_icms_base_line             NUMBER;
    v_icms_amount_line           NUMBER;
    v_icms_amount_recover_line   NUMBER;
    v_diff_icms_amount_line      NUMBER;
    v_ipi_amount_line            NUMBER;
    v_ipi_amount_recover_line    NUMBER;
    v_currency_code_alt1         VARCHAR2(15);
    v_currency_code_alt2         VARCHAR2(15);
    v_currency_import_accounting cll_f189_parameters.currency_import_accounting%TYPE;
    cactualflag                  VARCHAR2(1);
    nencumbrancetypeid           NUMBER;
    v_invoice_id                 NUMBER;
    x_gera_contab_sob_1          VARCHAR2(1) := 'Y';
    x_gera_contab_sob_2          VARCHAR2(1) := 'Y';
    x_count                      NUMBER;
    x_legal_entity               org_organization_definitions.legal_entity%TYPE;
    x_create_acct_entries        cst_le_cost_types.create_acct_entries%TYPE;
    x_post_to_gl                 cst_le_cost_types.post_to_gl%TYPE;
    v_group_base_day             cll_f189_parameters.group_id_base_day%TYPE;
    v_base_day                   VARCHAR2(2);
    x_module_name                CONSTANT VARCHAR2(100) := 'CLL_F189_INTERFACE_PKG.GL';
    v_gl_int_reference11         gl_interface.reference11%TYPE;
    v_distr_qty                  NUMBER;   -- Enh 7247515
    --
    v_reference_code             FND_LOOKUP_VALUES_VL.MEANING%TYPE; -- Bug 7495591 - SSimoes - 21/01/2009

    l_posted_flag cll_f189_entry_operations.posted_flag%TYPE;  -- Bug 8507278
    v_distrib_exists             NUMBER;       -- Bug 8637717 - rvicente - 06/07/09
    v_inv_dist_exists            NUMBER;       -- Bug 8637717 - rvicente - 06/07/09
    v_meaning_new                VARCHAR2(20); -- Bug 8637717 - rvicente - 07/07/09
    v_meaning_old                VARCHAR2(20); -- Bug 8637717 - rvicente - 07/07/09
    --
    v_receipt                    FND_LOOKUP_VALUES_VL.MEANING%TYPE; -- Bug 8840419 - SSimoes - 05/10/2009
    --
    -- Bug 7422494 - SSimoes - 10/06/2010 - Inicio
    -- v_state_code                 cll_f189_states.state_code%TYPE;
    v_national_state             cll_f189_states.national_state%TYPE;
    -- Bug 7422494 - SSimoes - 10/06/2010 - Fim
    --
    v_ledger_id                  NUMBER; -- Bug 10411519
    v_ledger_id_alt1             NUMBER; -- Bug 10411519
    v_ledger_id_alt2             NUMBER; -- Bug 10411519
    v_date_gl_aux                DATE;   -- Bug 10411519
    --
    -- Bug 8683821 - SSimoes - 15/07/2009 - Inicio
    --------------------------------------------------------
    -- Select FOR UPDATE all lines for operation_id from: --
    -- cll_f189_distributions                             --
    -- cll_f189_invoice_dist                              --
    --------------------------------------------------------
    CURSOR c_dist_loc IS
           SELECT rd.distribution_id
             FROM cll_f189_distributions rd
            WHERE rd.operation_id = p_operation_id
              AND rd.organization_id = p_organization_id
              FOR UPDATE;

    CURSOR c_inv_dist_loc IS
           SELECT rd.invoice_distrib_id
             FROM cll_f189_invoice_dist rd
            WHERE rd.operation_id = p_operation_id
              AND rd.organization_id = p_organization_id
              FOR UPDATE;

-- Bug 8683821 - SSimoes - 15/07/2009 - Fim
--
    -----------------------------------------------------------------------
    -- Select all lines for operation_id from cll_f189_distributions_tmp --
    -----------------------------------------------------------------------
    CURSOR c_dist IS
      SELECT rct.distribution_id,
             rct.organization_id,
             rct.location_id,
             rct.operation_id,
             rct.reference, -- Enh 8366859 - SSimoes - 09/04/2009 -- Bug 8637717
             --rct.reference reference_code, -- Enh 8366859 - SSimoes - 09/04/2009 -- Bug 8637717
             --rlc.meaning reference, -- Enh 8366859 - SSimoes - 09/04/2009 -- Bug 8637717
             rct.code_combination_id,
             rct.invoice_line_id,
             rct.po_distribution_id,
             rct.functional_dr,
             rct.functional_cr,
             rct.dollar_dr,
             rct.dollar_cr,
             rct.alt2_dr,
             rct.alt2_cr,
             rct.posted_flag,
             rct.pa_distribution_flag,
             rct.fa_distribution_flag,
             rct.creation_date,
             rct.created_by,
             rct.last_updated_by,
             rct.last_update_date,
             rct.last_update_login,
             rct.attribute_category,
             rct.attribute1,
             rct.attribute2,
             rct.attribute3,
             rct.attribute4,
             rct.attribute5,
             rct.attribute6,
             rct.attribute7,
             rct.attribute8,
             rct.attribute9,
             rct.attribute10,
             rct.attribute11,
             rct.attribute12,
             rct.attribute13,
             rct.attribute14,
             rct.attribute15,
             rct.attribute16,
             rct.attribute17,
             rct.attribute18,
             rct.attribute19,
             rct.attribute20
        FROM cll_f189_distributions_tmp rct
           , FND_LOOKUP_VALUES_VL       rlc -- Enh 8366859 - SSimoes - 09/04/2009
       WHERE rct.operation_id                   = p_operation_id
         AND rct.organization_id                = p_organization_id
         AND rlc.lookup_type                    = 'CLL_F189_REFERENCES' -- Enh 8366859 - SSimoes - 09/04/2009
         AND (rct.reference                     = rlc.lookup_code -- Enh 8366859 - SSimoes - 09/04/2009
              OR rct.reference                  = rlc.lookup_code || ' - UPDATED(NEW)'  -- Bug 8637717
              OR rct.reference                  = rlc.lookup_code || ' - UPDATED(OLD)') -- Bug 8637717
         AND NVL(rlc.end_date_active,SYSDATE+1) > SYSDATE; -- Enh 8366859 - SSimoes - 09/04/2009
    --
    -- Bug 8637717 - rvicente - 07/07/09
    --
    -----------------------------------------------------------------------
    -- Select all lines for operation_id from cll_f189_distributions_tmp --
    -----------------------------------------------------------------------
    CURSOR c_invoice_dist IS
      SELECT ridt.invoice_distrib_id,
             ridt.organization_id,
             ridt.location_id,
             ridt.operation_id,
             ridt.reference,
             ridt.code_combination_id,
             ridt.invoice_line_id,
             ridt.po_distribution_id,
             ridt.invoice_id,
             ridt.invoice_type_id,
             ridt.vendor_site_id,
             ridt.ra_address_id,
             ridt.functional_dr,
             ridt.functional_cr,
             ridt.dollar_dr,
             ridt.dollar_cr,
             ridt.alt2_dr,
             ridt.alt2_cr,
             ridt.posted_flag,
             ridt.pa_distribution_flag,
             ridt.fa_distribution_flag,
             ridt.creation_date,
             ridt.created_by,
             ridt.last_updated_by,
             ridt.last_update_date,
             ridt.last_update_login,
             ridt.attribute_category,
             ridt.attribute1,
             ridt.attribute2,
             ridt.attribute3,
             ridt.attribute4,
             ridt.attribute5,
             ridt.attribute6,
             ridt.attribute7,
             ridt.attribute8,
             ridt.attribute9,
             ridt.attribute10,
             ridt.attribute11,
             ridt.attribute12,
             ridt.attribute13,
             ridt.attribute14,
             ridt.attribute15,
             ridt.attribute16,
             ridt.attribute17,
             ridt.attribute18,
             ridt.attribute19,
             ridt.attribute20
        FROM cll_f189_invoice_dist_tmp  ridt
           , FND_LOOKUP_VALUES_VL       rlc
       WHERE ridt.operation_id                   = p_operation_id
         AND ridt.organization_id                = p_organization_id
         AND rlc.lookup_type                     = 'CLL_F189_REFERENCES'
         AND (ridt.reference                     = rlc.lookup_code
              OR ridt.reference                  = rlc.lookup_code || ' - UPDATED(NEW)'
              OR ridt.reference                  = rlc.lookup_code || ' - UPDATED(OLD)')
         AND NVL(rlc.end_date_active,SYSDATE+1) > SYSDATE;
    --
    -- Bug 8637717 - rvicente - 07/07/09 - END
    --
    -- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Inicio
    CURSOR c_distributions IS
               SELECT rd.distribution_id,
                      rd.functional_dr,
                      rd.functional_cr,
                      -- rd.reference, -- Enh 8366859 - SSimoes - 09/04/2009
                      rd.reference reference_code, -- Enh 8366859 - SSimoes - 09/04/2009
                      rlc.meaning reference, -- Enh 8366859 - SSimoes - 09/04/2009
                      rd.code_combination_id,
                      rd.dollar_dr,
                      rd.dollar_cr,
                      rd.invoice_line_id,
                      rd.po_distribution_id,
                      rd.alt2_dr,
                      rd.alt2_cr,
                      NULL invoice_id,
                      NULL invoice_type_id,
                      NULL vendor_site_id,
                      NULL ra_address_id
                 FROM cll_f189_distributions rd
                    , FND_LOOKUP_VALUES_VL   rlc -- Enh 8366859 - SSimoes - 09/04/2009
                WHERE rd.operation_id                    =  p_operation_id
                  AND rd.organization_id                 =  p_organization_id
                  AND NVL(rd.posted_flag, 'N')           <> 'Y'
                  AND NVL(rd.pa_distribution_flag,'N')   IN ('N','I')
                  AND NVL(rd.fa_distribution_flag,'N')   IN ('N','O')
                  AND (rd.reference                      = rlc.lookup_code       -- Enh 8366859 - SSimoes - 09/04/2009
                       OR rd.reference                   = rlc.lookup_code || ' - UPDATED(NEW)'  -- Bug 8637717
                       OR rd.reference                   = rlc.lookup_code || ' - UPDATED(OLD)') -- Bug 8637717
                  AND rlc.lookup_type                    = 'CLL_F189_REFERENCES' -- Enh 8366859 - SSimoes - 09/04/2009
                  AND NVL(rlc.end_date_active,SYSDATE+1) > SYSDATE               -- Enh 8366859 - SSimoes - 09/04/2009
                  AND NOT EXISTS (SELECT 'Nao contabilizar pra compra/pagamento e impostos PA compra Nacional' -- Bug 9069838
                                    FROM cll_f189_invoices ri
                                       , cll_f189_invoice_types rit
                                   WHERE ri.operation_id          = rd.operation_id
                                     AND ri.organization_id       = rd.organization_id
                                     AND rit.invoice_type_id      = ri.invoice_type_id
                                     AND (NVL(rit.contab_flag,'P') = 'P' OR
                                         (ri.source_items = 0 AND -- Bug 9069838
                                          NVL(rit.project_flag,'I') = 'I'))); -- Bug 9069838
--                  FOR UPDATE; -- Bug 8683821 - SSimoes - 15/07/2009

-- Bug 8683821 - SSimoes - 15/07/2009 - Inicio
/*

-- Cursor nao eh mais utilizado.

    CURSOR c_invoice_distributions IS
               SELECT rd.INVOICE_DISTRIB_ID    distribution_id,
                      rd.functional_dr,
                      rd.functional_cr,
--                      rd.reference, -- Enh 8366859 - SSimoes - 09/04/2009
                      rd.reference reference_code, -- Enh 8366859 - SSimoes - 09/04/2009
                      rlc.meaning reference, -- Enh 8366859 - SSimoes - 09/04/2009
                      rd.code_combination_id,
                      rd.dollar_dr,
                      rd.dollar_cr,
                      rd.invoice_line_id,
                      rd.po_distribution_id,
                      rd.alt2_dr,
                      rd.alt2_cr,
                      rd.invoice_id,
                      rd.invoice_type_id,
                      rd.vendor_site_id,
                      rd.ra_address_id
                 FROM cll_f189_invoice_dist  rd
                    , FND_LOOKUP_VALUES_VL   rlc -- Enh 8366859 - SSimoes - 09/04/2009
                WHERE rd.operation_id                    =  p_operation_id
                  AND rd.organization_id                 =  p_organization_id
                  AND NVL(rd.posted_flag, 'N')           <> 'Y'
                  AND NVL(rd.pa_distribution_flag,'N')   IN ('N','I')
                  AND NVL(rd.fa_distribution_flag,'N')   IN ('N','O')
                  AND (rd.reference                      = rlc.lookup_code       -- Enh 8366859 - SSimoes - 09/04/2009
                       OR rd.reference                   = rlc.lookup_code || ' - UPDATED(NEW)'  -- Bug 8637717
                       OR rd.reference                   = rlc.lookup_code || ' - UPDATED(OLD)') -- Bug 8637717
                  AND rlc.lookup_type                    = 'CLL_F189_REFERENCES' -- Enh 8366859 - SSimoes - 09/04/2009
                  AND NVL(rlc.end_date_active,SYSDATE+1) > SYSDATE               -- Enh 8366859 - SSimoes - 09/04/2009
                  AND NOT EXISTS (SELECT 'Nao contabilizar pra compra/pagamento'
                                    FROM cll_f189_invoices ri, cll_f189_invoice_types rit
                                   WHERE ri.operation_id          = rd.operation_id
                                     AND ri.organization_id       = rd.organization_id
                                     AND rit.invoice_type_id      = ri.invoice_type_id
                                     AND NVL(rit.contab_flag,'P') = 'P' )
                  FOR UPDATE;
*/
-- Bug 8683821 - SSimoes - 15/07/2009 - Fim

   CURSOR c_distributions_1 IS
               SELECT rd.distribution_id,
                      rd.functional_dr,
                      rd.functional_cr,
--                      rd.reference, -- Enh 8366859 - SSimoes - 09/04/2009
                      rd.reference reference_code, -- Enh 8366859 - SSimoes - 09/04/2009
                      rlc.meaning reference, -- Enh 8366859 - SSimoes - 09/04/2009
                      rd.code_combination_id,
                      rd.dollar_dr,
                      rd.dollar_cr,
                      rd.invoice_line_id,
                      rd.po_distribution_id,
                      rd.alt2_dr,
                      rd.alt2_cr,
                      NULL invoice_id,
                      NULL invoice_type_id,
                      NULL vendor_site_id,
                      NULL ra_address_id
                 FROM cll_f189_distributions rd
                    , FND_LOOKUP_VALUES_VL   rlc -- Enh 8366859 - SSimoes - 09/04/2009
                WHERE rd.operation_id                    =  p_operation_id
                  AND rd.organization_id                 =  p_organization_id
                  AND NVL(rd.posted_flag, 'N')           <> 'Y'
                --  AND NVL(rd.pa_distribution_flag,'N') =  'N'           -- Bug 9100834 --
                  AND NVL(rd.pa_distribution_flag,'N')   IN ('N','I')     -- Bug 9100834 --
                  AND NVL(rd.fa_distribution_flag,'N')   IN ('N','O')
                  AND (rd.reference                      = rlc.lookup_code       -- Enh 8366859 - SSimoes - 09/04/2009
                       OR rd.reference                   = rlc.lookup_code || ' - UPDATED(NEW)'  -- Bug 8637717
                       OR rd.reference                   = rlc.lookup_code || ' - UPDATED(OLD)') -- Bug 8637717
                  AND rlc.lookup_type                    = 'CLL_F189_REFERENCES' -- Enh 8366859 - SSimoes - 09/04/2009
                  AND NVL(rlc.end_date_active,SYSDATE+1) > SYSDATE               -- Enh 8366859 - SSimoes - 09/04/2009
                  AND NOT EXISTS (SELECT 'Nao contabilizar pra compra/pagamento e impostos PA compra Nacional' -- Bug 9069838
                                    FROM cll_f189_invoices ri
                                       , cll_f189_invoice_types rit
                                   WHERE ri.operation_id          = rd.operation_id
                                     AND ri.organization_id       = rd.organization_id
                                     AND rit.invoice_type_id      = ri.invoice_type_id
                                     AND (NVL(rit.contab_flag,'P') = 'P' OR
                                         (ri.source_items = 0 AND -- Bug 9069838
                                          NVL(rit.project_flag,'I') = 'I'))); -- Bug 9069838
--                  FOR UPDATE; -- Bug 8683821 - SSimoes - 15/07/2009

   CURSOR c_invoice_distributions_1 IS
               SELECT rd.INVOICE_DISTRIB_ID    distribution_id,
                      rd.functional_dr,
                      rd.functional_cr,
--                      rd.reference, -- Enh 8366859 - SSimoes - 09/04/2009
                      rd.reference reference_code, -- Enh 8366859 - SSimoes - 09/04/2009
                      rlc.meaning reference, -- Enh 8366859 - SSimoes - 09/04/2009
                      rd.code_combination_id,
                      rd.dollar_dr,
                      rd.dollar_cr,
                      rd.invoice_line_id,
                      rd.po_distribution_id,
                      rd.alt2_dr,
                      rd.alt2_cr,
                      rd.invoice_id,
                      rd.invoice_type_id,
                      rd.vendor_site_id,
                      rd.ra_address_id
                 FROM cll_f189_invoice_dist rd
                    , FND_LOOKUP_VALUES_VL  rlc -- Enh 8366859 - SSimoes - 09/04/2009
                WHERE rd.operation_id                    =  p_operation_id
                  AND rd.organization_id                 =  p_organization_id
                  AND NVL(rd.posted_flag, 'N')           <> 'Y'
                --  AND NVL(rd.pa_distribution_flag,'N') =  'N'           -- Bug 9100834 --
                  AND NVL(rd.pa_distribution_flag,'N')   IN ('N','I')     -- Bug 9100834 --
                  AND NVL(rd.fa_distribution_flag,'N')   IN ('N','O')
                  AND (rd.reference                      = rlc.lookup_code       -- Enh 8366859 - SSimoes - 09/04/2009
                       OR rd.reference                   = rlc.lookup_code || ' - UPDATED(NEW)'  -- Bug 8637717
                       OR rd.reference                   = rlc.lookup_code || ' - UPDATED(OLD)') -- Bug 8637717
                  AND rlc.lookup_type                    = 'CLL_F189_REFERENCES' -- Enh 8366859 - SSimoes - 09/04/2009
                  AND NVL(rlc.end_date_active,SYSDATE+1) > SYSDATE               -- Enh 8366859 - SSimoes - 09/04/2009
                  AND NOT EXISTS (SELECT 'Nao contabilizar pra compra/pagamento e impostos PA compra Nacional' -- Bug 9069838
                                    FROM cll_f189_invoices ri
                                       , cll_f189_invoice_types rit
                                   WHERE ri.operation_id          = rd.operation_id
                                     AND ri.organization_id       = rd.organization_id
                                     AND rit.invoice_type_id      = ri.invoice_type_id
                                     AND (NVL(rit.contab_flag,'P') = 'P' OR
                                         (ri.source_items = 0 AND -- Bug 9069838
                                          NVL(rit.project_flag,'I') = 'I'))); -- Bug 9069838
--                  FOR UPDATE; -- Bug 8683821 - SSimoes - 15/07/2009

    r1                c_distributions%ROWTYPE;
-- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Fim
--
  BEGIN
    print_log('  XXFR_F189_INTERFACE_PKG.GL');--
    -- Bug 8507278
    BEGIN
      SELECT NVL(posted_flag,'N')
        INTO l_posted_flag
        FROM cll_f189_entry_operations
       WHERE operation_id = p_operation_id
         AND organization_id = p_organization_id;
    EXCEPTION
      WHEN OTHERS THEN 
        l_posted_flag := 'N';
    END;
    --
    -- Bug 8637717 - rvicente - 06/07/09 BEGIN
    BEGIN
      SELECT count(*)
        INTO v_distrib_exists
        FROM cll_f189_distributions_tmp
       WHERE operation_id = p_operation_id
         AND organization_id = p_organization_id;
    EXCEPTION
      WHEN OTHERS THEN
        v_distrib_exists := 0;
    END;
    --
    BEGIN
      SELECT count(*)
        INTO v_inv_dist_exists
        FROM cll_f189_invoice_dist_tmp
       WHERE operation_id = p_operation_id
         AND organization_id = p_organization_id;
    EXCEPTION
      WHEN OTHERS THEN
        v_inv_dist_exists := 0;
    END;
    -- Bug 8637717 - rvicente - 06/07/09 END
    --
    IF (l_posted_flag = 'N') -- Bug 8507278
       OR (v_distrib_exists > 0) OR (v_inv_dist_exists > 0) THEN -- Bug 8637717
    --
    -- Bug 8637717 - rvicente - 07/07/09 - Begin
    -------------------------------------------------------------------------
    -- Get the meaning from FND_LOOKUP_VALUES_VL to concat to reference if --
    -- the account was changed: UPDATED(NEW)/UPDATED(OLD)                  --
    -------------------------------------------------------------------------
      BEGIN
        SELECT meaning
          INTO v_meaning_new
          FROM FND_LOOKUP_VALUES_VL
         WHERE lookup_type = 'CLL_F189_REFERENCES'
           AND lookup_code = ' - UPDATED (NEW)'
           AND NVL(end_date_active,SYSDATE+1) > SYSDATE;
      EXCEPTION
          WHEN OTHERS THEN
               v_meaning_new := ' - UPDATED (NEW)';
      END;
      --
      BEGIN
        SELECT meaning
          INTO v_meaning_old
          FROM FND_LOOKUP_VALUES_VL
         WHERE lookup_type = 'CLL_F189_REFERENCES'
           AND lookup_code = ' - UPDATED (OLD)'
           AND NVL(end_date_active,SYSDATE+1) > SYSDATE;
      EXCEPTION
          WHEN OTHERS THEN
               v_meaning_old := ' - UPDATED (OLD)';
      END;
      -- Bug 8637717 - rvicente - 07/07/09 - End
    --
    BEGIN
      FOR r_dist IN c_dist
      LOOP
        INSERT INTO cll_f189_distributions
          (distribution_id,
           organization_id,
           location_id,
           operation_id,
           reference,
           code_combination_id,
           invoice_line_id,
           po_distribution_id,
           functional_dr,
           functional_cr,
           dollar_dr,
           dollar_cr,
           alt2_dr,
           alt2_cr,
           posted_flag,
           pa_distribution_flag,
           fa_distribution_flag,
           creation_date,
           created_by,
           last_updated_by,
           last_update_date,
           last_update_login,
           attribute_category,
           attribute1,
           attribute2,
           attribute3,
           attribute4,
           attribute5,
           attribute6,
           attribute7,
           attribute8,
           attribute9,
           attribute10,
           attribute11,
           attribute12,
           attribute13,
           attribute14,
           attribute15,
           attribute16,
           attribute17,
           attribute18,
           attribute19,
           attribute20)
      VALUES
          (r_dist.distribution_id,
           r_dist.organization_id,
           r_dist.location_id,
           r_dist.operation_id,
           r_dist.reference,
           r_dist.code_combination_id,
           r_dist.invoice_line_id,
           r_dist.po_distribution_id,
           r_dist.functional_dr,
           r_dist.functional_cr,
           ROUND(r_dist.dollar_dr, 2), -- BUG 21304630
           ROUND(r_dist.dollar_cr,2), -- BUG 21304630
           ROUND(r_dist.alt2_dr,2), -- BUG 21304630
           ROUND(r_dist.alt2_cr,2), -- BUG 21304630
           r_dist.posted_flag,
           r_dist.pa_distribution_flag,
           r_dist.fa_distribution_flag,
           r_dist.creation_date,
           r_dist.created_by,
           r_dist.last_updated_by,
           r_dist.last_update_date,
           r_dist.last_update_login,
           r_dist.attribute_category,
           r_dist.attribute1,
           r_dist.attribute2,
           r_dist.attribute3,
           r_dist.attribute4,
           r_dist.attribute5,
           r_dist.attribute6,
           r_dist.attribute7,
           r_dist.attribute8,
           r_dist.attribute9,
           r_dist.attribute10,
           r_dist.attribute11,
           r_dist.attribute12,
           r_dist.attribute13,
           r_dist.attribute14,
           r_dist.attribute15,
           r_dist.attribute16,
           r_dist.attribute17,
           r_dist.attribute18,
           r_dist.attribute19,
           r_dist.attribute20);
      --
      END LOOP;
      --
      DELETE FROM cll_f189_distributions_tmp
       WHERE operation_id    = p_operation_id
         AND organization_id = p_organization_id;
    EXCEPTION
      WHEN others THEN
        NULL;
    END;
    --
    -- Bug 8637717 - rvicente - 07/07/09 - BEGIN
    --
    BEGIN
      FOR r_invoice_dist IN c_invoice_dist
      LOOP
        INSERT INTO cll_f189_invoice_dist
          (invoice_distrib_id,
           organization_id,
           location_id,
           operation_id,
           reference,
           code_combination_id,
           invoice_line_id,
           po_distribution_id,
           invoice_id,
           invoice_type_id,
           vendor_site_id,
           ra_address_id,
           functional_dr,
           functional_cr,
           dollar_dr,
           dollar_cr,
           alt2_dr,
           alt2_cr,
           posted_flag,
           pa_distribution_flag,
           fa_distribution_flag,
           creation_date,
           created_by,
           last_updated_by,
           last_update_date,
           last_update_login,
           attribute_category,
           attribute1,
           attribute2,
           attribute3,
           attribute4,
           attribute5,
           attribute6,
           attribute7,
           attribute8,
           attribute9,
           attribute10,
           attribute11,
           attribute12,
           attribute13,
           attribute14,
           attribute15,
           attribute16,
           attribute17,
           attribute18,
           attribute19,
           attribute20)
      VALUES
          (r_invoice_dist.invoice_distrib_id,
           r_invoice_dist.organization_id,
           r_invoice_dist.location_id,
           r_invoice_dist.operation_id,
           r_invoice_dist.reference,
           r_invoice_dist.code_combination_id,
           r_invoice_dist.invoice_line_id,
           r_invoice_dist.po_distribution_id,
           r_invoice_dist.invoice_id,
           r_invoice_dist.invoice_type_id,
           r_invoice_dist.vendor_site_id,
           r_invoice_dist.ra_address_id,
           r_invoice_dist.functional_dr,
           r_invoice_dist.functional_cr,
           ROUND(r_invoice_dist.dollar_dr,2), -- BUG 21304630
           ROUND(r_invoice_dist.dollar_cr,2), -- BUG 21304630
           ROUND(r_invoice_dist.alt2_dr,2), -- BUG 21304630
           ROUND(r_invoice_dist.alt2_cr,2), -- BUG 21304630
           r_invoice_dist.posted_flag,
           r_invoice_dist.pa_distribution_flag,
           r_invoice_dist.fa_distribution_flag,
           r_invoice_dist.creation_date,
           r_invoice_dist.created_by,
           r_invoice_dist.last_updated_by,
           r_invoice_dist.last_update_date,
           r_invoice_dist.last_update_login,
           r_invoice_dist.attribute_category,
           r_invoice_dist.attribute1,
           r_invoice_dist.attribute2,
           r_invoice_dist.attribute3,
           r_invoice_dist.attribute4,
           r_invoice_dist.attribute5,
           r_invoice_dist.attribute6,
           r_invoice_dist.attribute7,
           r_invoice_dist.attribute8,
           r_invoice_dist.attribute9,
           r_invoice_dist.attribute10,
           r_invoice_dist.attribute11,
           r_invoice_dist.attribute12,
           r_invoice_dist.attribute13,
           r_invoice_dist.attribute14,
           r_invoice_dist.attribute15,
           r_invoice_dist.attribute16,
           r_invoice_dist.attribute17,
           r_invoice_dist.attribute18,
           r_invoice_dist.attribute19,
           r_invoice_dist.attribute20);
      --
      END LOOP;
      --
      DELETE FROM cll_f189_invoice_dist_tmp
       WHERE operation_id    = p_operation_id
         AND organization_id = p_organization_id;
    EXCEPTION
      WHEN others THEN
        NULL;
    END;
    --
    -- Bug 8637717 - rvicente - 07/07/09 -
    --
    BEGIN
      SELECT organization_id,
             created_by,
             gl_date,
             receive_date
        INTO v_organization_id,
             v_created_by,
             v_date_gl,
             v_receive_date
        FROM cll_f189_entry_operations
       WHERE operation_id    = p_operation_id
         AND organization_id = p_organization_id;
    END;
    -- Selecting base date to identify GL Batch
    BEGIN
      SELECT group_id_base_day
        INTO v_group_base_day
        FROM cll_f189_parameters
       WHERE organization_id = p_organization_id;
      --
      IF v_group_base_day = 'G' THEN
        v_base_day := TO_CHAR (v_date_gl,'DD');
      ELSE
        v_base_day := TO_CHAR (v_receive_date,'DD');
      END IF;
    --
    EXCEPTION
      WHEN others THEN
        NULL;
    END;
    BEGIN   /* Selecting accountancy data */
      SELECT   gsb.chart_of_accounts_id
             , gp.period_name
             , gsb.set_of_books_id
             , gsb.currency_code
        INTO   v_chart_of_accounts_id
             , v_period_name
             , v_set_of_books_id
             , v_currency_code
        FROM   org_organization_definitions ood
             , gl_sets_of_books             gsb
             , gl_periods                   gp
       WHERE ood.organization_id       = v_organization_id
         AND ood.set_of_books_id       = gsb.set_of_books_id
         AND gsb.period_set_name       = gp.period_set_name
         AND gp.adjustment_period_flag = 'N'
         AND ood.chart_of_accounts_id  = gsb.chart_of_accounts_id
         AND TRUNC(v_date_gl) BETWEEN TRUNC(START_DATE)
                                  AND TRUNC(end_date)
         AND ROWNUM = 1;
    EXCEPTION
      WHEN no_data_found THEN
        raise_application_error (-20541, x_module_name||' - ERROR:  '|| SQLERRM ||' Selecting accountancy data.');

      WHEN others THEN
        raise_application_error (-20541, x_module_name||' - ERROR:  '|| SQLERRM ||' Selecting accountancy data.');
    END;
    v_set_of_books_id_alt1 := TO_NUMBER(fnd_profile.VALUE('CLL_F189_FIRST_ALTERNATIVE_SET_OF_BOOKS'));

    v_date_gl_aux := TRUNC(v_date_gl); -- Bug 10411519

    -- Bug 10411519 - gdasilv - 23/12/2010 - Inicio
    BEGIN
      SELECT ledger_id
        INTO v_ledger_id
        FROM gl_period_statuses
       WHERE set_of_books_id = v_set_of_books_id
         AND v_date_gl_aux BETWEEN start_date
                               AND end_date+.99999
         AND application_id = 101;
    EXCEPTION
      WHEN others THEN
        v_ledger_id := -1;
    END;
    -- Bug 10411519 - gdasilv - 23/12/2010 - Fim

    IF v_set_of_books_id_alt1 IS NOT NULL THEN
      --
      BEGIN
        SELECT gsb.currency_code
        INTO   v_currency_code_alt1
        FROM   gl_sets_of_books gsb
        WHERE  set_of_books_id = v_set_of_books_id_alt1;
        --
      EXCEPTION
        WHEN others THEN
          v_currency_code_alt1 := NULL;
      END;
      --
      SELECT count(*)
        INTO x_count
        FROM cst_cost_group_assignments
       WHERE organization_id = p_organization_id;
      IF x_count = 0 THEN
        x_gera_contab_sob_1 := 'Y';
      ELSE
        SELECT legal_entity
          INTO x_legal_entity
          FROM org_organization_definitions
         WHERE organization_id = p_organization_id;
        BEGIN
          SELECT   create_acct_entries
                 , post_to_gl
            INTO   x_create_acct_entries
                 , x_post_to_gl
            FROM cst_le_cost_types
           WHERE legal_entity = x_legal_entity
             AND set_of_books_id   = v_set_of_books_id_alt1;
          IF x_create_acct_entries = 'Y' AND x_post_to_gl='Y' THEN
            x_gera_contab_sob_1 := 'Y';
          ELSE
            x_gera_contab_sob_1 := 'N';
          END IF;
        EXCEPTION
          WHEN others THEN
            x_gera_contab_sob_1 := 'Y';
        END;
      END IF;
      --
      -- Bug 10411519 - gdasilv - 23/12/2010 - Inicio
      BEGIN
        SELECT ledger_id
          INTO v_ledger_id_alt1
          FROM gl_period_statuses
         WHERE set_of_books_id = v_set_of_books_id_alt1
           AND v_date_gl_aux BETWEEN start_date
                                 AND end_date+.99999
           AND application_id = 101;
      EXCEPTION
        WHEN others THEN
          v_ledger_id_alt1 := -1;
      END;
      -- Bug 10411519 - gdasilv - 23/12/2010 - Fim
      --
    ELSE
      x_gera_contab_sob_1 := 'N';
    END IF;

    v_set_of_books_id_alt2 := TO_NUMBER(fnd_profile.VALUE('CLL_F189_SECOND_ALTERNATIVE_SET_OF_BOOKS'));

    IF v_set_of_books_id_alt2 IS NOT NULL THEN
      BEGIN
        SELECT gsb.currency_code
          INTO v_currency_code_alt2
          FROM gl_sets_of_books gsb
         WHERE set_of_books_id = v_set_of_books_id_alt2;
      EXCEPTION
        WHEN others THEN
          v_currency_code_alt2 := NULL;
      END;
      SELECT COUNT(*)
        INTO x_count
        FROM cst_cost_group_assignments
       WHERE organization_id = p_organization_id;
      IF x_count = 0 THEN
        x_gera_contab_sob_2 := 'Y';
      ELSE
        SELECT legal_entity
          INTO x_legal_entity
          FROM org_organization_definitions
         WHERE organization_id = p_organization_id;
        BEGIN
          SELECT   create_acct_entries
                 , post_to_gl
            INTO   x_create_acct_entries
                 , x_post_to_gl
            FROM cst_le_cost_types
           WHERE legal_entity      = x_legal_entity
             AND set_of_books_id   = v_set_of_books_id_alt2;
          IF x_create_acct_entries = 'Y' AND x_post_to_gl='Y' THEN
            x_gera_contab_sob_2 := 'Y';
          ELSE
            x_gera_contab_sob_2 := 'N';
          END IF;
        EXCEPTION
          WHEN others THEN
            x_gera_contab_sob_2 := 'Y';
        END;
      END IF;
      --
      -- Bug 10411519 - gdasilv - 23/12/2010 - Inicio
      BEGIN
        SELECT ledger_id
          INTO v_ledger_id_alt2
          FROM gl_period_statuses
         WHERE set_of_books_id = v_set_of_books_id_alt2
           AND v_date_gl_aux BETWEEN start_date
                                 AND end_date+.99999
           AND application_id = 101;
      EXCEPTION
        WHEN others THEN
          v_ledger_id_alt2 := -1;
      END;
      -- Bug 10411519 - gdasilv - 23/12/2010 - Fim
      --
    ELSE
      x_gera_contab_sob_2 := 'N';
    END IF;
    -------------------------------------------------------------
    -- Selecting encumbrance_type_id if there is encumbrance   --
    -------------------------------------------------------------
    BEGIN
      SELECT fsp.purch_encumbrance_type_id
        INTO nencumbrancetypeid
        FROM financials_system_parameters fsp
           , org_organization_definitions ood
           , cll_f189_distributions rd
           , FND_LOOKUP_VALUES_VL rlc -- Bug 7495591 - SSimoes - 21/01/2009
       WHERE rd.operation_id       = p_operation_id
         AND rd.organization_id    = p_organization_id
         --  AND rd.reference          = 'ENCUMBRANCE (BUDGETS)' -- Bug 7495591 - SSimoes - 21/01/2009
         --  AND rlc.meaning = rd.reference -- Bug 7495591 - SSimoes - 21/01/2009 -- Enh 8366859 - SSimoes - 09/04/2009
         AND (rd.reference         = rlc.lookup_code -- Enh 8366859 - SSimoes - 09/04/2009
              OR rd.reference      = rlc.lookup_code || ' - UPDATED(NEW)'  -- Bug 8637717
              OR rd.reference      = rlc.lookup_code || ' - UPDATED(OLD)') -- Bug 8637717
         AND rlc.lookup_code       = 'ENCUMBRANCE (BUDGETS)' -- Bug 7495591 - SSimoes - 21/01/2009
         AND rlc.lookup_type       = 'CLL_F189_REFERENCES' -- Bug 7495591 - SSimoes - 21/01/2009
         AND NVL(rlc.end_date_active,SYSDATE+1) > SYSDATE -- Bug 7495591 - SSimoes - 21/01/2009
         AND ood.organization_id   = rd.organization_id
         AND fsp.org_id(+)         = ood.operating_unit
         AND ROWNUM                = 1;
    EXCEPTION
      WHEN others THEN
         nencumbrancetypeid    := NULL;
    END;
    --
    BEGIN  /* Inserting in Gl_Interface */
      -- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Inicio
      SELECT COUNT('1')
        INTO v_distr_qty
        FROM cll_f189_invoice_dist
       WHERE organization_id = p_organization_id
         AND operation_id    = p_operation_id;
      --
      IF v_distr_qty > 0 THEN
        OPEN c_inv_dist_loc; -- Bug 8683821 - SSimoes - 15/07/2009
        OPEN c_invoice_distributions_1;
      ELSE
        OPEN c_dist_loc; -- Bug 8683821 - SSimoes - 15/07/2009
        OPEN c_distributions_1;
      END IF;
      /*
      FOR r1 IN (SELECT   distribution_id
                      , functional_dr
                      , functional_cr
                      , reference
                      , code_combination_id
                      , dollar_dr
                      , dollar_cr
                      , invoice_line_id
                      , po_distribution_id
                      , alt2_dr
                      , alt2_cr
                 FROM cll_f189_distributions rd
                WHERE rd.operation_id                  =  p_operation_id
                  AND rd.organization_id               =  p_organization_id
                  AND NVL(rd.posted_flag, 'N')         <> 'Y'
                  AND NVL(rd.pa_distribution_flag,'N') =  'N'
                  AND NVL(rd.fa_distribution_flag,'N') IN ('N','O')
                  AND NOT EXISTS (SELECT 1
                                    FROM cll_f189_invoices ri
                                       , cll_f189_invoice_types rit
                                   WHERE ri.operation_id          = rd.operation_id
                                     AND ri.organization_id       = rd.organization_id
                                     AND rit.invoice_type_id      = ri.invoice_type_id
                                     AND NVL(rit.contab_flag,'P') = 'P' ) FOR UPDATE)
      */
      -- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Fim
      LOOP
      -- Bug 8840419 - SSimoes - 05/10/2009 - Inicio
      BEGIN
        SELECT meaning
          INTO v_receipt
          FROM FND_LOOKUP_VALUES_VL
         WHERE lookup_type = 'CLL_F189_LABELS'
           AND lookup_code = 'RECEIPT'
           AND NVL(end_date_active,SYSDATE+1) > SYSDATE;
      EXCEPTION
           WHEN OTHERS THEN
             v_receipt := NULL;
             raise_application_error (-20593,x_module_name || ' - ERROR: ' || SQLERRM);
      END;
      -- Bug 8840419 - SSimoes - 05/10/2009 - Fim
      -- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Inicio
      IF v_distr_qty > 0 THEN
        FETCH c_invoice_distributions_1 INTO r1;
        EXIT WHEN c_invoice_distributions_1%NOTFOUND;
      ELSE
        FETCH c_distributions_1 INTO r1;
        EXIT WHEN c_distributions_1%NOTFOUND;
      END IF;
      -- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Fim
      -- Bug 7495591 - SSimoes - 21/01/2009 - Inicio
      BEGIN
        SELECT lookup_code
          INTO v_reference_code
          FROM FND_LOOKUP_VALUES_VL
         WHERE lookup_type = 'CLL_F189_REFERENCES'
           -- AND meaning = r1.reference -- Enh 8366859 - SSimoes - 09/04/2009
           AND (  lookup_code                      = r1.reference_code -- Enh 8366859 - SSimoes - 09/04/2009
               OR lookup_code || ' - UPDATED(NEW)' = r1.reference_code -- Bug 8637717
               OR lookup_code || ' - UPDATED(OLD)' = r1.reference_code)-- Bug 8637717
           AND NVL(end_date_active,SYSDATE+1) > SYSDATE;
           -- Bug 8637717
           CASE
            WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(NEW)' THEN
              v_reference_code := v_reference_code || ' - UPDATED(NEW)';
            WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(OLD)' THEN
              v_reference_code := v_reference_code || ' - UPDATED(OLD)';
            ELSE
              v_reference_code := v_reference_code;
           END CASE;
      -- Bug 8637717
      EXCEPTION
           WHEN OTHERS THEN
             v_reference_code := NULL;
             raise_application_error (-20576,x_module_name || ' - ERROR: ' || SQLERRM);
      END;
      --
      -- IF ( r1.reference = 'ITEM') AND r1.invoice_line_id IS NOT NULL THEN
      -- IF ( v_reference_code = 'ITEM') -- Bug 8637717
      IF v_reference_code IN ('ITEM', 'ITEM - UPDATED(NEW)', 'ITEM - UPDATED(OLD)') -- Bug 8637717
         AND r1.invoice_line_id IS NOT NULL THEN
         -- Bug 7495591 - SSimoes - 21/01/2009 - Fim
          BEGIN
             SELECT ri.invoice_id
               INTO v_invoice_id
               FROM  cll_f189_invoices ri
                   , cll_f189_invoice_lines ril
              WHERE ri.invoice_id       = ril.invoice_id
                AND ril.invoice_line_id = r1.invoice_line_id;
          END;
          --
          BEGIN
              SELECT  SUBSTR(rit.invoice_type_code||':'||p_operation_id||'-', 1, 240)
                    , SUBSTR( ' Doc '        ||
                              --Ltrim(Decode(Ri.Invoice_Num - Trunc(Ri.Invoice_Num), 0, To_Char(Ri.Invoice_Num, '999999999999999' ), To_Char(Ri.Invoice_Num, '9999999999999d99'))) || -- Bug 9406912 -- Bug 13947775
                              Ltrim(Decode(Ri.Invoice_Num - Trunc(Ri.Invoice_Num), 0, To_Char(Ri.Invoice_Num, '9999999999999999999999' ), To_Char(Ri.Invoice_Num, '99999999999999999999d99'))) || -- Bug 13947775
                              --ri.invoice_num ||
                              ' - '          ||
                              pv.vendor_name
                            , 1, 240)
             INTO   v_je_description1n
                  , v_je_description2n
             FROM   cll_f189_invoices            ri
                  , cll_f189_invoice_types       rit
                  , cll_f189_fiscal_entities_all rfea
                  , po_vendor_sites_all          pvsa
                  , po_vendors pv
             WHERE ri.operation_id   = p_operation_id
             AND ri.organization_id  = p_organization_id
             AND ri.invoice_type_id  = rit.invoice_type_id
             AND ri.entity_id        = rfea.entity_id
             AND rfea.vendor_site_id = pvsa.vendor_site_id
             AND (rfea.org_id IS NULL OR rfea.org_id = pvsa.org_id)
             AND pvsa.vendor_id      = pv.vendor_id
             AND ri.invoice_id       = v_invoice_id
             AND ROWNUM              = 1;
          EXCEPTION
             WHEN no_data_found THEN
                v_je_description1n := NULL;
                v_je_description2n := NULL;
          END;
          --
          BEGIN
             SELECT SUBSTRB(v_je_description1N ||
                            CASE
                              WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(NEW)' THEN
                                r1.reference || v_meaning_new
                              WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(OLD)' THEN
                                r1.reference || v_meaning_old
                              ELSE
                                r1.reference
                            END
                            || v_je_description2n || ' ; ' ||
                            ril.description,1,240)
             INTO v_je_descriptiongl
             FROM cll_f189_invoice_lines ril
             WHERE ril.invoice_line_id = r1.invoice_line_id;
          EXCEPTION
              WHEN no_data_found THEN
                 NULL;
          END;
          -- Bug 7495591 - SSimoes - 21/01/2009 - Inicio
          -- ELSIF r1.reference IN ('CARRIER', 'DIFF ICMS FRT', 'ICMS RECOVER FRT', 'ICMS SUB FRT') THEN
          -- ELSIF v_reference_code IN ('CARRIER', 'DIFF ICMS FRT', 'ICMS RECOVER FRT', 'ICMS SUB FRT') THEN -- Bug 8637717
          -- Bug 7495591 - SSimoes - 21/01/2009 - Fim
       -- Bug 8637717
       ELSIF v_reference_code IN ('CARRIER', 'CARRIER - UPDATED(NEW)', 'CARRIER - UPDATED(OLD)',
                                  'DIFF ICMS FRT', 'DIFF ICMS FRT - UPDATED(NEW)', 'DIFF ICMS FRT - UPDATED(OLD)',
                                  'ICMS RECOVER FRT', 'ICMS RECOVER FRT - UPDATED(NEW)', 'ICMS RECOVER FRT - UPDATED(OLD)',
                                  'ICMS SUB FRT', 'ICMS SUB FRT - UPDATED(NEW)', 'ICMS SUB FRT - UPDATED(OLD)',
                                  'PIS RECOVER FRT', 'PIS RECOVER FRT - UPDATED(NEW)', 'PIS RECOVER FRT - UPDATED(OLD)',          -- ER 10286595
                                  'COFINS RECOVER FRT', 'COFINS RECOVER FRT - UPDATED(NEW)', 'COFINS RECOVER FRT - UPDATED(OLD)'  -- ER 10286595
                                  ) THEN
       -- Bug 8637717

          BEGIN
             -- ER 10286595 - Start
/*
             SELECT SUBSTR(rit.invoice_type_code||':'||p_operation_id||'-', 1, 240)
                  , SUBSTR(' - '||pv.vendor_name, 1, 240)
*/
             SELECT SUBSTR(rit.invoice_type_code||':'||p_operation_id||'-', 1, 240)
                  , SUBSTR(' Doc '         ||
                           Ltrim(Decode(rfi.invoice_num - Trunc(rfi.invoice_num), 0, To_Char(rfi.invoice_num, '9999999999999999999999' ), To_Char(rfi.invoice_num, '99999999999999999999d99'))) ||
                           ' - '           ||
                           pv.vendor_name, 1, 240)
             -- ER 10286595 - End
             INTO   v_je_description1f
                  , v_je_description2f
             FROM   cll_f189_freight_invoices    rfi
                  , cll_f189_invoice_types       rit
                  , cll_f189_fiscal_entities_all rfea
                  , po_vendor_sites_all          pvsa
                  , po_vendors                   pv
             WHERE rfi.operation_id    = p_operation_id
               AND rfi.organization_id = p_organization_id
               AND rfi.invoice_type_id = rit.invoice_type_id
               AND rfi.entity_id       = rfea.entity_id
               AND rfea.vendor_site_id = pvsa.vendor_site_id
               AND (rfea.org_id IS NULL OR rfea.org_id = pvsa.org_id)
               AND pvsa.vendor_id      = pv.vendor_id
               AND ROWNUM              = 1;
          EXCEPTION
            WHEN no_data_found THEN
             -- Bug 5956860 - SSimoes - 04/04/2007 - Begin
              /*
                v_je_description1F := NULL;
                v_je_description2F := NULL;
              */
               BEGIN
                   SELECT   SUBSTR(rit.invoice_type_code||':'||p_operation_id||'-', 1, 240)
                          ,
                    SUBSTR(   ' Doc '       ||
                              --Ltrim(Decode(Ri.Invoice_Num - Trunc(Ri.Invoice_Num), 0, To_Char(Ri.Invoice_Num, '999999999999999' ), To_Char(Ri.Invoice_Num, '9999999999999d99'))) || -- Bug 9406912 -- Bug 13947775
                              Ltrim(Decode(Ri.Invoice_Num - Trunc(Ri.Invoice_Num), 0, To_Char(Ri.Invoice_Num, '9999999999999999999999' ), To_Char(Ri.Invoice_Num, '99999999999999999999d99'))) || -- Bug 13947775
                              --ri.invoice_num ||
                              ' - '          ||
                              pv.vendor_name, 1, 240)
                    INTO  v_je_description1f
                        , v_je_description2f
                    FROM  cll_f189_invoices ri
                        , cll_f189_invoice_types rit
                        , cll_f189_fiscal_entities_all rfea
                        , po_vendor_sites_all pvsa
                        , po_vendors pv
                   WHERE ri.operation_id    = p_operation_id
                     AND ri.organization_id = p_organization_id
                     AND ri.invoice_type_id = rit.invoice_type_id
                     AND ri.entity_id       = rfea.entity_id
                     AND rfea.vendor_site_id = pvsa.vendor_site_id
                     AND (rfea.org_id        IS NULL OR
                          rfea.org_id        = pvsa.org_id)
                     AND pvsa.vendor_id      = pv.vendor_id
                     AND ROWNUM              = 1;
               EXCEPTION
                    WHEN no_data_found THEN
                         v_je_description1f := NULL;
                         v_je_description2f := NULL;
               END;
          -- Bug 5956860 - SSimoes - 04/04/2007 - Begin
          END;
          v_je_descriptiongl:= SUBSTR(v_je_description1f ||
                                      -- Bug 8637717
                                      -- r1.reference
                                      CASE
                                        WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(NEW)' THEN
                                          r1.reference || v_meaning_new
                                        WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(OLD)' THEN
                                          r1.reference || v_meaning_old
                                        ELSE
                                          r1.reference
                                      END
                                      -- Bug 8637717
                                      || v_je_description2f,1,240);
       ELSE
          BEGIN
             SELECT   SUBSTR(rit.invoice_type_code||':'||p_operation_id||'-', 1, 240)
                    , SUBSTR(  ' Doc '         ||
                               --Ltrim(Decode(Ri.Invoice_Num - Trunc(Ri.Invoice_Num), 0, To_Char(Ri.Invoice_Num, '999999999999999' ), To_Char(Ri.Invoice_Num, '9999999999999d99'))) || -- Bug 9406912 -- Bug 13947775
                               Ltrim(Decode(Ri.Invoice_Num - Trunc(Ri.Invoice_Num), 0, To_Char(Ri.Invoice_Num, '9999999999999999999999' ), To_Char(Ri.Invoice_Num, '99999999999999999999d99'))) || -- Bug 13947775
                                --ri.invoice_num ||
                               ' - '           ||
                               pv.vendor_name, 1, 240)
             INTO   v_je_description1f
                  , v_je_description2f
             FROM   cll_f189_invoices            ri
                  , cll_f189_invoice_types       rit
                  , cll_f189_fiscal_entities_all rfea
                  , po_vendor_sites_all          pvsa
                  , po_vendors pv
             WHERE ri.operation_id    = p_operation_id
               AND ri.organization_id = p_organization_id
               AND ri.invoice_type_id = rit.invoice_type_id
               AND ri.entity_id       = rfea.entity_id
               AND rfea.vendor_site_id = pvsa.vendor_site_id
               AND (rfea.org_id        IS NULL OR
                    rfea.org_id        = pvsa.org_id)
               AND pvsa.vendor_id      = pv.vendor_id;
--               AND ROWNUM              = 1; -- ENH 4432542
          EXCEPTION
             -- ENH 4432542 - Begin
             WHEN too_many_rows THEN
                  BEGIN
                  SELECT   SUBSTR(rit.invoice_type_code||':'||p_operation_id||'-', 1, 240)
                         , SUBSTR(   ' de '       ||
                                     pv.vendor_name, 1, 240)
                  INTO   v_je_description1f
                       , v_je_description2f
                  FROM   cll_f189_invoices            ri
                       , cll_f189_invoice_types       rit
                       , cll_f189_fiscal_entities_all rfea
                       , po_vendor_sites_all          pvsa
                       , po_vendors                   pv
                  WHERE ri.operation_id    = p_operation_id
                    AND ri.organization_id = p_organization_id
                    AND ri.invoice_type_id = rit.invoice_type_id
                    AND ri.entity_id       = rfea.entity_id
                    AND rfea.vendor_site_id = pvsa.vendor_site_id
                    AND (rfea.org_id        IS NULL OR
                         rfea.org_id        = pvsa.org_id)
                    AND pvsa.vendor_id      = pv.vendor_id
                    AND ROWNUM              = 1;
                 EXCEPTION
                      WHEN no_data_found THEN
                           v_je_description1f := NULL;
                           v_je_description2f := NULL;
                 END;
                 -- ENH 4432542 - End
            WHEN no_data_found THEN
--
-- Enh 7537556 - SSimoes - 03/03/2009 - Inicio
--
-- Incluir o mesmo tratamento dado acima, para RMA
--
                 BEGIN
                   SELECT SUBSTR(rit.invoice_type_code||':'||p_operation_id||'-', 1, 240)
                        , SUBSTR(  ' Doc '         ||
                          --Ltrim(Decode(Ri.Invoice_Num - Trunc(Ri.Invoice_Num), 0, To_Char(Ri.Invoice_Num, '999999999999999' ), To_Char(Ri.Invoice_Num, '9999999999999d99'))) || -- Bug 9406912 -- Bug 13947775
                          Ltrim(Decode(Ri.Invoice_Num - Trunc(Ri.Invoice_Num), 0, To_Char(Ri.Invoice_Num, '9999999999999999999999' ), To_Char(Ri.Invoice_Num, '99999999999999999999d99'))) || -- Bug 13947775
                          --ri.invoice_num ||
                          ' - '           ||
                          SUBSTR(hp.party_name,1,50), 1, 240)
                     INTO v_je_description1F,
                          v_je_description2F
                     FROM cll_f189_invoices ri,
                          cll_f189_invoice_types rit,
                          cll_f189_fiscal_entities_all rfea,
                          hz_cust_acct_sites_all hcas,
                          hz_party_sites hps,
                          hz_parties hp
                    WHERE ri.operation_id      =  p_operation_id
                      AND ri.organization_id   =  p_organization_id
                      AND ri.invoice_type_id   = rit.invoice_type_id
                      AND ri.entity_id         = rfea.entity_id
                      AND rit.requisition_type = 'RM'
                      AND hp.status = 'A'
                      AND hp.party_id = hps.party_id
                      AND hps.party_site_id = hcas.party_site_id
                      AND rfea.cust_acct_site_id = hcas.cust_acct_site_id
                      AND rfea.entity_type_lookup_code = 'CUSTOMER_SITE';
                 EXCEPTION
                      WHEN too_many_rows THEN
                           BEGIN
                             SELECT SUBSTR(rit.invoice_type_code||':'||p_operation_id||'-', 1, 240),
                                    SUBSTR(' de '       ||
                                    SUBSTR(hp.party_name,1,50), 1, 240)
                               INTO v_je_description1F,
                                    v_je_description2F
                               FROM cll_f189_invoices ri,
                                    cll_f189_invoice_types rit,
                                    cll_f189_fiscal_entities_all rfea,
                                    hz_cust_acct_sites_all hcas,
                                    hz_party_sites hps,
                                    hz_parties hp
                              WHERE ri.operation_id      =  p_operation_id
                                AND ri.organization_id   =  p_organization_id
                                AND ri.invoice_type_id   = rit.invoice_type_id
                                AND ri.entity_id         = rfea.entity_id
                                AND rit.requisition_type = 'RM'
                                AND hp.status = 'A'
                                AND hp.party_id = hps.party_id
                                AND hps.party_site_id = hcas.party_site_id
                                AND rfea.cust_acct_site_id = hcas.cust_acct_site_id
                                AND rfea.entity_type_lookup_code = 'CUSTOMER_SITE'
                                AND ROWNUM              = 1;
                           EXCEPTION
                                WHEN no_data_found THEN
                                     v_je_description1F := NULL;
                                     v_je_description2F := NULL;
                           END;
                      WHEN no_data_found THEN

-- Enh 7537556 - SSimoes - 03/03/2009 - Fim
               v_je_description1f := NULL;
               v_je_description2f := NULL;
-- Enh 7537556 - SSimoes - 03/03/2009 - Inicio
                 END;
-- Enh 7537556 - SSimoes - 03/03/2009 - Fim
          END;

          v_je_descriptiongl:= SUBSTR(v_je_description1f ||
                                      -- Bug 8637717
                                      -- r1.reference
                                      CASE
                                        WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(NEW)' THEN
                                          r1.reference || v_meaning_new
                                        WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(OLD)' THEN
                                          r1.reference || v_meaning_old
                                        ELSE
                                          r1.reference
                                      END
                                      -- Bug 8637717
                                      || v_je_description2f,1,240);
       END IF;
        /*---*/
        ----------------------------------------------------------------
        -- Verifying the accounting entry and changing actual_flag to 'E'
        -- if is an encumbrance
        ----------------------------------------------------------------

-- Bug 7495591 - SSimoes - 21/01/2009 - Inicio
--        IF ( r1.reference IN ( 'ENCUMBRANCE (BUDGETS)', 'ENCUMBRANCE (LIABILITY TRANSITORY)') ) THEN
--        IF ( v_reference_code IN ( 'ENCUMBRANCE (BUDGETS)', 'ENCUMBRANCE (LIABILITY TRANSITORY)') ) THEN -- Bug 8637717
-- Bug 7495591 - SSimoes - 21/01/2009 - Fim
        -- Bug 8637717
        IF ( v_reference_code IN ('ENCUMBRANCE (BUDGETS)', 'ENCUMBRANCE (BUDGETS) - UPDATED(NEW)',
                                  'ENCUMBRANCE (BUDGETS) - UPDATED(OLD)',
                                  'ENCUMBRANCE (LIABILITY TRANSITORY)', 'ENCUMBRANCE (LIABILITY TRANSITORY) - UPDATED(NEW)',
                                  'ENCUMBRANCE (LIABILITY TRANSITORY) - UPDATED(OLD)')
                                  ) THEN
        -- Bug 8637717
           cactualflag := 'E';
        ELSE
           cactualflag := 'A';
        END IF;

        BEGIN
          -- Bug 8637717 - Start
          --v_gl_int_reference11 := REPLACE(fnd_message.get_string('CLL', 'CLL_F189_GL_REFERENCE'), '&REFERENCE', r1.reference);
          v_gl_int_reference11 := REPLACE(fnd_message.get_string('CLL', 'CLL_F189_GL_REFERENCE'), '&REFERENCE',
          CASE
            WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(NEW)' THEN
              r1.reference || v_meaning_new
            WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(OLD)' THEN
              r1.reference || v_meaning_old
            ELSE
              r1.reference
          END
          );
          print_log('v_gl_int_reference11 :'||v_gl_int_reference11 );
          -- Bug 8637717 - End

          -- Bug 7422494 - SSimoes - 10/06/2010 - Inicio
          --           SELECT rs.state_code
          --             INTO v_state_code
           SELECT NVL(rs.national_state,'N')
             INTO v_national_state
-- Bug 7422494 - SSimoes - 10/06/2010 - Fim
             FROM cll_f189_states              rs
                , cll_f189_fiscal_entities_all rfea
                , cll_f189_invoices            ri
            WHERE ri.operation_id    = p_operation_id
              AND ri.organization_id = p_organization_id
              AND rfea.entity_id     = ri.entity_id
              AND rs.state_id        = rfea.state_id
              AND ROWNUM             = 1;

-- Bug 7422494 - SSimoes - 10/06/2010 - Inicio
--           IF v_state_code = 'EX' THEN
           IF v_national_state = 'N' THEN
-- Bug 7422494 - SSimoes - 10/06/2010 - Fim
             SELECT currency_import_accounting
               INTO v_currency_import_accounting
               FROM   cll_f189_parameters rp
                    , cll_f189_entry_operations reo
              WHERE rp.organization_id  = reo.organization_id
                AND reo.operation_id    = p_operation_id
                AND reo.organization_id = p_organization_id;

             IF v_currency_import_accounting = 'ALTERNATE1' THEN
               BEGIN
                 INSERT INTO gl_interface
                     (status,                         /* 01 */
                      set_of_books_id,                /* 02 */
                      accounting_date,                /* 03 */
                      currency_code,                  /* 04 */
                      date_created,                   /* 05 */
                      created_by,                     /* 06 */
                      actual_flag,                    /* 07 */
                      user_je_category_name,          /* 08 */
                      user_je_source_name,            /* 09 */
                      entered_dr,                     /* 10 */
                      accounted_dr,                   /* 11 */
                      entered_cr,                     /* 12 */
                      accounted_cr,                   /* 13 */
                      transaction_date,               /* 14 */
                      reference1,                     /* 15 */
                      reference2,                     /* 16 */
                      reference3,                     /* 17 */
                      reference10,                    /* 18 */
                      reference11,                    /* 19 */
                      period_name,                    /* 20 */
                      chart_of_accounts_id,           /* 21 */
                      code_combination_id,            /* 22 */
                      date_created_in_gl,             /* 23 */
                      group_id,                       /* 24 */
                      attribute1,                     /* 25 */
                      attribute2,                     /* 26 */
                      reference22,                    /* 27 */
                      reference23,                    /* 28 */
                      reference24,                    /* 29 */
                      encumbrance_type_id,            /* 30 */
                      reference21,                    /* 31 */ -- ENH 5680689
                      reference25,                    /* 32 */
                      reference26,                    /* 33 */
                      reference27,                    /* 34 */
                      ledger_id                       /* 35 */ -- Bug 10411519
                      )

                   VALUES
                     ('NEW',                          /* 01 */
                      v_set_of_books_id,              /* 02 */
                      v_date_gl,                      /* 03 */
                      v_currency_code_alt1,           /* 04 */
                      SYSDATE,                        /* 05 */
                      v_created_by,                   /* 06 */
                      cactualflag,                    /* 07 */
                      'REC',                          /* 08 */
                      'CLL F189 INTEGRATED RCV',      /* 09 */
                    --r1.dollar_dr,                   /* 10 */ -- 21304630
                      round(r1.dollar_dr,2),          /* 10 */ -- 21304630
                      r1.functional_dr,               /* 11 */
                    --r1.dollar_cr,                   /* 12 */ -- 21304630
                      round(r1.dollar_cr,2),          /* 12 */ -- 21304630
                      r1.functional_cr,               /* 13 */
                      v_receive_date,                 /* 14 */
                      v_organization_id,              /* 15 */
                      p_operation_id,                 /* 16 */
                      r1.po_distribution_id,          /* 17 */
                      v_je_descriptiongl,             /* 18 */
                      v_gl_int_reference11,           /* 19 */
                      v_period_name,                  /* 20 */
                      v_chart_of_accounts_id,         /* 21 */
                      r1.code_combination_id,         /* 22 */
                      SYSDATE,                        /* 23 */
                      v_base_day,                     /* 24 */
                      NULL,                           /* 25 */
                      NULL,                           /* 26 */
                      p_operation_id,                 /* 27 */
                      r1.invoice_line_id,             /* 28 */
                      r1.po_distribution_id,          /* 29 */
                      DECODE(cactualflag, 'E', nencumbrancetypeid, NULL), /* 30 */
                      v_organization_id,              /* 31 */ -- ENH 5680689
                      r1.vendor_site_id,               /* 32 */
                      r1.ra_address_id,                /* 33 */
                      r1.invoice_id,                   /* 34 */
                      v_ledger_id                      /* 35 */ -- Bug 10411519
                      );

                  EXCEPTION
                    WHEN no_data_found THEN
                      raise_application_error (-20542, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE.');
                    WHEN others THEN
                      raise_application_error (-20542, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE.');
               END;
             ELSE
               BEGIN
                 INSERT INTO gl_interface
                     (status,                         /* 01 */
                      set_of_books_id,                /* 02 */
                      accounting_date,                /* 03 */
                      currency_code,                  /* 04 */
                      date_created,                   /* 05 */
                      created_by,                     /* 06 */
                      actual_flag,                    /* 07 */
                      user_je_category_name,          /* 08 */
                      user_je_source_name,            /* 09 */
                      entered_dr,                     /* 10 */
                      accounted_dr,                   /* 11 */
                      entered_cr,                     /* 12 */
                      accounted_cr,                   /* 13 */
                      transaction_date,               /* 14 */
                      reference1,                     /* 15 */
                      reference2,                     /* 16 */
                      reference3,                     /* 17 */
                      reference10,                    /* 18 */
                      reference11,                    /* 19 */
                      period_name,                    /* 20 */
                      chart_of_accounts_id,           /* 21 */
                      code_combination_id,            /* 22 */
                      date_created_in_gl,             /* 23 */
                      group_id,                       /* 24 */
                      attribute1,                     /* 25 */
                      attribute2,                     /* 26 */
                      reference22,                    /* 27 */
                      reference23,                    /* 28 */
                      reference24,                    /* 29 */
                      encumbrance_type_id,            /* 30 */
                      reference21,                    /* 31 */ -- Enh 5680689
                      reference25,                    /* 32 */
                      reference26,                    /* 33 */
                      reference27,                    /* 34 */
                      ledger_id                       /* 35 */ -- Bug 10411519
                     )

                   VALUES
                     ('NEW',                          /* 01 */
                      v_set_of_books_id,              /* 02 */
                      v_date_gl,                      /* 03 */
                      v_currency_code,                /* 04 */
                      SYSDATE,                        /* 05 */
                      v_created_by,                   /* 06 */
                      cactualflag,                    /* 07 */
                      'REC',                          /* 08 */
                      'CLL F189 INTEGRATED RCV',      /* 09 */
                      r1.functional_dr,               /* 10 */
                      r1.functional_dr,               /* 11 */
                      r1.functional_cr,               /* 12 */
                      r1.functional_cr,               /* 13 */
                      v_receive_date,                 /* 14 */
                      v_organization_id,              /* 15 */
                      p_operation_id,                 /* 16 */
                      r1.po_distribution_id,          /* 17 */
                      v_je_descriptiongl,             /* 18 */
                      v_gl_int_reference11,           /* 19 */
                      v_period_name,                  /* 20 */
                      v_chart_of_accounts_id,         /* 21 */
                      r1.code_combination_id,         /* 22 */
                      SYSDATE,                        /* 23 */
                      v_base_day,                     /* 24 */
                      NULL,                           /* 25 */
                      NULL,                           /* 26 */
                      p_operation_id,                 /* 27 */
                      r1.invoice_line_id,             /* 28 */
                      r1.po_distribution_id,          /* 29 */
                      DECODE(cactualflag, 'E', nencumbrancetypeid, NULL), /* 30 */
                      v_organization_id,             /* 31 */ -- Enh 5680689
                      r1.vendor_site_id,             /* 32 */
                      r1.ra_address_id,              /* 33 */
                      r1.invoice_id,                 /* 34 */
                      v_ledger_id                    /* 35 */ -- Bug 10411519
                      );

                  EXCEPTION
                    WHEN no_data_found THEN
                      raise_application_error (-20543, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE.');
                    WHEN others THEN
                      raise_application_error (-20543, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE.');
               END;
             END IF;
           ELSE
             BEGIN
               INSERT INTO gl_interface
                   (status,                         /* 01 */
                    set_of_books_id,                /* 02 */
                    accounting_date,                /* 03 */
                    currency_code,                  /* 04 */
                    date_created,                   /* 05 */
                    created_by,                     /* 06 */
                    actual_flag,                    /* 07 */
                    user_je_category_name,          /* 08 */
                    user_je_source_name,            /* 09 */
                    entered_dr,                     /* 10 */
                    accounted_dr,                   /* 11 */
                    entered_cr,                     /* 12 */
                    accounted_cr,                   /* 13 */
                    transaction_date,               /* 14 */
                    reference1,                     /* 15 */
                    reference2,                     /* 16 */
                    reference3,                     /* 17 */
                    reference10,                    /* 18 */
                    reference11,                    /* 19 */
                    period_name,                    /* 20 */
                    chart_of_accounts_id,           /* 21 */
                    code_combination_id,            /* 22 */
                    date_created_in_gl,             /* 23 */
                    group_id,                       /* 24 */
                    attribute1,                     /* 25 */
                    attribute2,                     /* 26 */
                    reference22,                    /* 27 */
                    reference23,                    /* 28 */
                    reference24,                    /* 29 */
                    encumbrance_type_id,            /* 30 */
                    reference21,                    /* 31 */ -- Enh 5680689
                    reference25,                    /* 32 */
                    reference26,                    /* 33 */
                    reference27,                    /* 34 */
                    ledger_id                       /* 35 */ -- Bug 10411519
                   )

                VALUES
                   ('NEW',                          /* 01 */
                    v_set_of_books_id,              /* 02 */
                    v_date_gl,                      /* 03 */
                    v_currency_code,                /* 04 */
                    SYSDATE,                        /* 05 */
                    v_created_by,                   /* 06 */
                    cactualflag,                    /* 07 */
                    'REC',                          /* 08 */
                    'CLL F189 INTEGRATED RCV',      /* 09 */
                    r1.functional_dr,               /* 10 */
                    r1.functional_dr,               /* 11 */
                    r1.functional_cr,               /* 12 */
                    r1.functional_cr,               /* 13 */
                    v_receive_date,                 /* 14 */
                    v_organization_id,              /* 15 */
                    p_operation_id,                 /* 16 */
                    r1.po_distribution_id,          /* 17 */
                    v_je_descriptiongl,             /* 18 */
                    v_gl_int_reference11,           /* 19 */
                    v_period_name,                  /* 20 */
                    v_chart_of_accounts_id,         /* 21 */
                    r1.code_combination_id,         /* 22 */
                    SYSDATE,                        /* 23 */
                    v_base_day,                     /* 24 */
                    NULL,                           /* 25 */
                    NULL,                           /* 26 */
                    p_operation_id,                 /* 27 */
                    r1.invoice_line_id,             /* 28 */
                    r1.po_distribution_id,          /* 29 */
                    DECODE(cactualflag, 'E', nencumbrancetypeid, NULL), /* 30 */
                    v_organization_id,              /* 31 */ -- Enh 5680689
                    r1.vendor_site_id,              /* 32 */
                    r1.ra_address_id,               /* 33 */
                    r1.invoice_id,                  /* 34 */
                    v_ledger_id                     /* 35 */ -- Bug 10411519
                    );

                EXCEPTION
                  WHEN no_data_found THEN
                    raise_application_error (-20544, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE.');
                  WHEN others THEN
                    raise_application_error (-20544, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE.');


             END;
           END IF;
       END;
        /*---*/
        IF x_gera_contab_sob_1 = 'Y' THEN
          BEGIN
           INSERT INTO gl_interface
              (status,                        /* 01 */
               set_of_books_id,               /* 02 */
               accounting_date,               /* 03 */
               currency_code,                 /* 04 */
               date_created,                  /* 05 */
               created_by,                    /* 06 */
               actual_flag,                   /* 07 */
               user_je_category_name,         /* 08 */
               user_je_source_name,           /* 09 */
               entered_dr,                    /* 10 */
               accounted_dr,                  /* 11 */
               entered_cr,                    /* 12 */
               accounted_cr,                  /* 13 */
               transaction_date,              /* 14 */
               reference1,                    /* 15 */
               reference2,                    /* 16 */
               reference3,                    /* 17 */
               reference10,                   /* 18 */
               reference11,                   /* 19 */
               period_name,                   /* 20 */
               chart_of_accounts_id,          /* 21 */
               code_combination_id,           /* 22 */
               date_created_in_gl,            /* 23 */
               group_id,                      /* 24 */
               attribute1,                    /* 25 */
               attribute2,                    /* 26 */
               reference22,                   /* 27 */
               reference23,                   /* 28 */
               reference24,                   /* 29 */
               encumbrance_type_id,           /* 30 */
               reference21,                   /* 31 */ -- Enh 5680689
               reference25,                   /* 32 */
               reference26,                   /* 33 */
               reference27,                   /* 34 */
               ledger_id                      /* 35 */ -- Bug 10411519
             )

           VALUES
              ('NEW',                           /* 01 */
               v_set_of_books_id_alt1,          /* 02 */
               v_date_gl,                       /* 03 */
               v_currency_code,                 /* 04 */
               SYSDATE,                         /* 05 */
               v_created_by,                    /* 06 */
               cactualflag,                     /* 07 */
               'REC',                           /* 08 */
               'CLL F189 INTEGRATED RCV',       /* 09 */
               r1.functional_dr,                /* 10 */
             --r1.dollar_dr,                    /* 11 */ -- 21304630
               round(r1.dollar_dr,2),           /* 11 */ -- 21304630
               r1.functional_cr,                /* 12 */
             --r1.dollar_cr,                    /* 13 */ -- 21304630
               round(r1.dollar_cr,2),           /* 13 */ -- 21304630
               v_receive_date,                  /* 14 */
               v_organization_id,               /* 15 */
               p_operation_id,                  /* 16 */
               r1.po_distribution_id,           /* 17 */
               v_je_descriptiongl,              /* 18 */
-- Bug 8840419 - SSimoes - 05/10/2009 - Inicio
--               'Receipt - '||
               v_receipt||' '||
-- Bug 8840419 - SSimoes - 05/10/2009 - Fim
               -- Bug 8637717
               -- r1.reference
               CASE
                 WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(NEW)' THEN
                   r1.reference || v_meaning_new
                 WHEN SUBSTR(r1.reference_code, -15) LIKE ' - UPDATED(OLD)' THEN
                   r1.reference || v_meaning_old
                 ELSE
                   r1.reference
               END,
               -- Bug 8637717                   /* 19 */
               v_period_name,                   /* 20 */
               v_chart_of_accounts_id,          /* 21 */
               r1.code_combination_id,          /* 22 */
               SYSDATE,                         /* 23 */
               v_base_day,                      /* 24 */
               NULL,                            /* 25 */
               NULL,                            /* 26 */
               p_operation_id,                  /* 27 */
               r1.invoice_line_id,              /* 28 */
               r1.po_distribution_id,           /* 29 */
               DECODE(cActualFlag, 'E', nencumbrancetypeid, NULL), /* 30 */
               v_organization_id,              /* 31 */ -- Enh 5680689
               r1.vendor_site_id,              /* 32 */
               r1.ra_address_id,               /* 33 */
               r1.invoice_id,                  /* 34 */
               v_ledger_id_alt1                /* 35 */ -- Bug 10411519
            );

           EXCEPTION
             WHEN no_data_found THEN
               raise_application_error (-20545, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE (Alternative 1).');

             WHEN others THEN
               raise_application_error (-20545, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE (Alternative 1).');
          END;
        END IF;
        /*---*/
        IF x_gera_contab_sob_2 = 'Y' THEN
          BEGIN
           INSERT INTO gl_interface
              (status,                        /* 01 */
               set_of_books_id,               /* 02 */
               accounting_date,               /* 03 */
               currency_code,                 /* 04 */
               date_created,                  /* 05 */
               created_by,                    /* 06 */
               actual_flag,                   /* 07 */
               user_je_category_name,         /* 08 */
               user_je_source_name,           /* 09 */
               entered_dr,                    /* 10 */
               accounted_dr,                  /* 11 */
               entered_cr,                    /* 12 */
               accounted_cr,                  /* 13 */
               transaction_date,              /* 14 */
               reference1,                    /* 15 */
               reference2,                    /* 16 */
               reference3,                    /* 17 */
               reference10,                   /* 18 */
               reference11,                   /* 19 */
               period_name,                   /* 20 */
               chart_of_accounts_id,          /* 21 */
               code_combination_id,           /* 22 */
               date_created_in_gl,            /* 23 */
               group_id,                      /* 24 */
               attribute1,                    /* 25 */
               attribute2,                    /* 26 */
               reference22,                   /* 27 */
               reference23,                   /* 28 */
               reference24,                   /* 29 */
               encumbrance_type_id,           /* 30 */
               reference21,                   /* 31 */ -- Enh 5680689
               reference25,                   /* 32 */
               reference26,                   /* 33 */
               reference27,                   /* 34 */
               ledger_id                      /* 35 */ -- Bug 10411519
              )

           VALUES
              ('NEW',                         /* 01 */
               v_set_of_books_id_alt2,        /* 02 */
               v_date_gl,                     /* 03 */
               v_currency_code,               /* 04 */
               SYSDATE,                       /* 05 */
               v_created_by,                  /* 06 */
               cactualflag,                   /* 07 */
               'REC',                         /* 08 */
               'CLL F189 INTEGRATED RCV',     /* 09 */
               r1.functional_dr,              /* 10 */
             --r1.alt2_dr,                    /* 11 */ -- 21304630
               round(r1.alt2_dr,2),           /* 11 */ -- 21304630
               r1.functional_cr,              /* 12 */
             --r1.alt2_cr,                    /* 13 */ -- 21304630
               round(r1.alt2_cr,2),           /* 13 */ -- 21304630
               v_receive_date,                /* 14 */
               v_organization_id,             /* 15 */
               p_operation_id,                /* 16 */
               r1.po_distribution_id,         /* 17 */
               v_je_descriptiongl,            /* 18 */
               v_gl_int_reference11,          /* 19 */
               v_period_name,                 /* 20 */
               v_chart_of_accounts_id,        /* 21 */
               r1.code_combination_id,        /* 22 */
               SYSDATE,                       /* 23 */
               v_base_day,                    /* 24 */
               NULL,                          /* 25 */
               NULL,                          /* 26 */
               p_operation_id,                /* 27 */
               r1.invoice_line_id,            /* 28 */
               r1.po_distribution_id,         /* 29 */
               DECODE(cactualflag, 'E',nencumbrancetypeid, NULL), /* 30 */
               v_organization_id,            /* 31 */ -- Enh 5680689
               r1.vendor_site_id,             /* 32 */
               r1.ra_address_id,              /* 33 */
               r1.invoice_id,                 /* 34 */
               v_ledger_id_alt2               /* 35 */ -- Bug 10411519
              );
               --
           EXCEPTION
             WHEN no_data_found THEN
               raise_application_error (-20546, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE (Alternative 2).');

             WHEN others THEN
               raise_application_error (-20546, x_module_name||' - ERROR:  '|| SQLERRM ||' Inserting in GL_INTERFACE (Alternative 2).');
          END;
        END IF;
        /*---*/
-- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Inicio
/*
        UPDATE cll_f189_distributions
           SET posted_flag = 'Y'
         WHERE distribution_id = r1.distribution_id;
*/

        IF v_distr_qty > 0 THEN
          UPDATE cll_f189_invoice_dist
             SET posted_flag = 'Y'
           WHERE INVOICE_DISTRIB_ID = r1.distribution_id;
        ELSE
          UPDATE cll_f189_distributions
             SET posted_flag = 'Y'
           WHERE distribution_id = r1.distribution_id;
        END IF;
-- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Fim

       -- Bug 5229618 AIrmer 02/06/2006
          UPDATE cll_f189_entry_operations reo
          SET    reo.posted_flag     = 'Y'
          WHERE  reo.operation_id    = p_operation_id
            AND  reo.organization_id = p_organization_id
                                    AND  NVL(reo.posted_flag,'N')  = 'N';
        --
        /*---*/
      END LOOP;

-- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Inicio
      IF v_distr_qty > 0 THEN
        CLOSE c_invoice_distributions_1;
        CLOSE c_inv_dist_loc; -- Bug 8683821 - SSimoes - 15/07/2009
      ELSE
        CLOSE c_distributions_1;
        CLOSE c_dist_loc; -- Bug 8683821 - SSimoes - 15/07/2009
      END IF;
-- Enh 7247515 - SPED Contabil - SSimoes - 18/08/2008 - Fim

    END;
   END IF;  -- Bug 8507278
    print_log('  FIM XXFR_F189_INTERFACE_PKG.GL');
  END GL;

-------------------------------------------------------------------------------
-->                              AP Interface                               <--
-------------------------------------------------------------------------------
  PROCEDURE ap (
    p_operation_id     IN  NUMBER,
    p_organization_id  IN  NUMBER,
    p_org_id           IN  NUMBER,
    p_created_by       IN  NUMBER
  ) IS

  BEGIN
    print_log('  CLL_F189_INTERFACE_PKG.AP');
    -- Bug 9316255 - CLLVRIBB.PLS CREATION BRANCH PROCEDURE AP - Inicio
    print_log('  Chamando CLL_F189_INTERFACE_AP_PKG.AP...');
    cll_f189_interface_ap_pkg.ap (
      p_operation_id,
      p_organization_id,
      p_org_id,
      p_created_by
    );
    -- Bug 9316255 - CLLVRIBB.PLS CREATION BRANCH PROCEDURE AP - Fim
    print_log('  FIM CLL_F189_INTERFACE_PKG.AP');
  END ap;

-------------------------------------------------------------------------------
-->                               AR Interface                              <--
-------------------------------------------------------------------------------
  PROCEDURE ar (
    p_operation_id    IN NUMBER,
    p_organization_id IN NUMBER
  ) AS
  --
    CURSOR c1 IS
      SELECT 
        ri.organization_id              organization_id,
        ri.operation_id                 operation_id,
        ri.invoice_id                   invoice_id,
        ri.source_items                 source_items,
        ri.terms_id                     terms_id,
        --
        ltrim(TO_CHAR(ri.ipi_amount,
        '999,999,999.99'),' ')          ri_ipi_amount,
        --
        NVL(ri.ipi_amount,0)            ipi_amount_header, -- Bug 8335230 (Item 5) - SSimoes - 30/03/2009 (new validation)
        NVL(ri.additional_amount,0)     additional_amount_header,               -- Bug 10086670 --
        --
        rit.ar_transaction_type_id      ar_transaction_type_id,
        rit.ar_cred_icms_category_id    ar_cred_icms_category_id,
        rit.ar_cred_icms_st_category_id ar_cred_icms_st_category_id,
        rit.ar_cred_ipi_category_id     ar_cred_ipi_category_id,
        rit.ar_deb_icms_category_id     ar_deb_icms_category_id,
        rit.ar_deb_icms_st_category_id  ar_deb_icms_st_category_id,
        rit.ar_deb_ipi_category_id      ar_deb_ipi_category_id,
        rbsa.NAME                       rbsa_name,
        rctt.post_to_gl                 post_to_gl,
        rctt.NAME                       rctt_name,
        rctt.default_term               ctt_default_term,
        raa.cust_acct_site_id           address_id, -- raa.address_id
        raa.cust_account_id             customer_id, -- raa.customer_id
        ril.invoice_line_id             invoice_line_id,
        ril.creation_date               creation_date,
        ril.created_by                  created_by,
        ril.last_update_date            last_update_date,
        ril.last_updated_by             last_updated_by,
        ril.last_update_login           last_update_login,
        ril.description                 ril_description,
        ril.item_id                     item_id,
        ril.quantity                    quantity,
        ril.unit_price                  unit_price,
        NVL(ril.discount_amount,0)      discount_amount,
        muom.uom_code                   uom,
        NVL(ril.icms_amount,0)          icms_amount,
        NVL(ril.icms_st_amount,0)       icms_st_amount,
        NVL(ril.ipi_amount,0)           ipi_amount,
        NVL(ril.icms_tax,0)             icms_tax,
        NVL(ril.ipi_tax,0)              ipi_tax,
        -- Bug 9729845 - SSimoes - 04/06/2010 - Inicio
        -- NVL(ril.icms_st_amount / ril.icms_st_base * 100, 0)      icms_st_tax,
        NVL(ril.icms_st_amount / DECODE(ril.icms_st_base,0,1,ril.icms_st_base) * 100, 0)      icms_st_tax,
        -- Bug 9729845 - SSimoes - 04/06/2010 - Fim
        ril.ipi_base_amount             ipi_base_amount,
        ril.net_amount                  net_amount,     -- Bug 10086670 --
        --ril.ipi_tax_code                ipi_tax_code, -- Bug 8511032 AIrmer 19/05/2009
        DECODE(NVL(rit.ipi_tributary_code_flag, 'N'), 'N', ril.ipi_tax_code, ril.ipi_tributary_code) ipi_tax_code,-- Bug 8511032 AIrmer 19/05/2009
        ril.icms_tax_code               icms_tax_code,
        rfo.cfo_code                    cfo_code,
        rfc.classification_code         classification_code,
        riu.utilization_code            utilization_code,
        muom.unit_of_measure            uom_name,
        ril.icms_base                   icms_base,
        ril.icms_st_base                icms_st_base, -- Bug 5962449 - SSimoes - 04/04/2007
        -- ril.tributary_status_code       sit_trib_est, -- (0007) -- BUG: 8304334
        substr(ril.tributary_status_code,1,1) sit_trib_code,      -- Bug 16850244
        substr(ril.tributary_status_code,2,2) sit_trib_est,       -- BUG: 8304334
        rfea.salesrep_id                salesrep_id,
        NVL(ri.freight_amount,0)        freight_amount_header, -- Bug 8577461 - SSimoes - 09/06/2009
        NVL(ril.freight_amount,0)       freight_amount_line    -- Bug 8577461 - SSimoes - 09/06/2009
        -- ,ri.simplified_br_tax_flag                              -- ER 9289619
        ,NVL(ri.insurance_amount,0)      insurance_amount_header  -- Bug 14582853
        ,NVL(ril.insurance_amount,0)     insurance_amount_line    -- Bug 14582853
        ,NVL(ri.other_expenses,0)        other_expenses_header    -- Bug 14582853
        ,NVL(ril.other_expenses,0)       other_expenses_line      -- Bug 14582853
        -- Inicio BUG 19495468
        ,RAA.GLOBAL_ATTRIBUTE_CATEGORY   global_attr_categ_site
        ,RAA.GLOBAL_ATTRIBUTE15          fiscal_doc_model
        ,RCTT.GLOBAL_ATTRIBUTE_CATEGORY  global_attr_categ_type
        ,RCTT.GLOBAL_ATTRIBUTE6          buyer_presence_ind
        -- Fim BUG 19495468
      FROM   
        cll_f189_invoices                      ri,
        cll_f189_invoice_types                 rit,
        org_organization_definitions           ood,
        ra_batch_sources_all                   rbsa,
        ra_cust_trx_types_all                  rctt,
        cll_f189_fiscal_entities_all           rfea,
        hz_cust_acct_sites_all                 raa, -- ra_addresses_all raa,
        cll_f189_invoice_lines                 ril,
        cll_f189_fiscal_operations             rfo,
        cll_f189_fiscal_class                  rfc,
        cll_f189_item_utilizations             riu,
        mtl_units_of_measure                   muom
      WHERE  1=1
        and ri.organization_id                   = 123 --p_organization_id
        and ri.operation_id                      = 126 --p_operation_id
        and rit.invoice_type_id                  = ri.invoice_type_id
        and NVL(rit.generate_return_invoice,'N') = 'Y'
        and ood.organization_id                  = 123 --p_organization_id
        and rbsa.org_id                          = ood.operating_unit
        and rbsa.batch_source_id                 = rit.ar_source_id
        and rctt.org_id                          = ood.operating_unit -- SSimoes - 01/04/2009
        and rctt.cust_trx_type_id                = rit.ar_transaction_type_id
        and rfea.entity_id                       = ri.entity_id
        and raa.cust_acct_site_id (+)            = rfea.cust_acct_site_id --rfea.ret_cust_acct_site_id AND -- raa.address_id (+) = rfea.ret_cust_acct_site_id -- AIrmer 26/05/2008
        and muom.unit_of_measure                 = ril.uom 
        and riu.utilization_id                   = ril.utilization_id 
        and rfc.classification_id                = ril.classification_id 
        and rfo.cfo_id                           = ril.cfo_id 
        and ril.invoice_id                       = ri.invoice_id 
        and NVL(ri.ar_interface_flag,'N')        = 'N'
      ORDER BY ri.organization_id, ri.operation_id, ri.invoice_id, ril.invoice_line_id
    ;
    --
    --  x_description               cll_f189_invoice_lines.description%TYPE; -- BUG 7150760 --
    x_operating_unit            org_organization_definitions.operating_unit%TYPE;
    x_set_of_books_id           gl_sets_of_books.set_of_books_id%TYPE;
    x_currency_code             gl_sets_of_books.currency_code%TYPE;
    x_invoice_id_ant            cll_f189_invoices.invoice_id%TYPE := 0;
    x_ra_term_id                ra_terms.term_id%TYPE;
    x_global_attribute_category mtl_system_items.global_attribute_category%TYPE;
    --  x_global_attribute1         mtl_system_items.global_attribute1%TYPE; -- Bug 6778641 AIrmer 29/01/2008
    v_category_concat_segs      mtl_item_categories_v.category_concat_segs%TYPE; -- Bug 6778641 AIrmer 29/01/2008
    x_global_attribute2         mtl_system_items.global_attribute2%TYPE;
    x_global_attribute3         mtl_system_items.global_attribute3%TYPE;
    x_global_attribute4         mtl_system_items.global_attribute4%TYPE;
    --  x_global_attribute5         mtl_system_items.global_attribute5%TYPE; -- Bug 4486071 AIrmer 19/08/2005
    x_global_attribute6         mtl_system_items.global_attribute6%TYPE;
    x_global_attribute7         mtl_system_items.global_attribute7%TYPE;
    x_tax_code                  ar_vat_tax_vl.tax_code%TYPE;
    x_sit_trib_est              VARCHAR2(3);
    x_mensagem                  VARCHAR2(450);
    x_mensagem_aux              VARCHAR2(500);
    x_count_ar                  NUMBER;         -- Bug 14642712
    x_desc_ar                   VARCHAR2(4000); -- Bug 14642712
    x_literal                   VARCHAR2(6);
    x_inf_nf                    VARCHAR2(450);
    x_module_name               CONSTANT VARCHAR2(100) := 'CLL_F189_INTERFACE_PKG.AR';
    x_fob_point                 VARCHAR2(10); -- Enh 6860943 - SSimoes - 03/03/2008
    x_unit_selling_price        NUMBER; -- BUG Equal 6667766 - rvicente 14/05/2008
    v_salesrep_required_flag    VARCHAR2(1); -- Bug 7560411 - rvicente 26/05/2009
    c_sales_credit_type_id      NUMBER; -- Bug 7560411 - rvicente 26/05/2009
    --
    l_gl_precision              NUMBER; -- Bug 14400588
    --
    -- Inicio BUG 19495468
    v_col_exist                 NUMBER :=0; -- BUG 19495468
    v_qty_invoice_dev           NUMBER :=0;
    v_invoice_line_id_dev       NUMBER;
    v_invoice_line_id_par       NUMBER;
    v_qty_parent                NUMBER :=0;
    arr                         NUMBER (1);
    v_rowid                     ROWID;
    v_perc_returned_goods       NUMBER :=0;
    v_fiscal_doc_model          VARCHAR2(30);
    v_buyer_presence_ind        VARCHAR2(30);
    v_insert_string             VARCHAR2(3000);
    -- Fim BUG 19495468
    i                           number;
  BEGIN
    print_log('');
    print_log('  CLL_F189_INTERFACE_PKG.AR');
    print_log('  Operation_id   :'||p_operation_id);
    print_log('  Organization_id:'||p_organization_id);
    i:=0;
    FOR r1 IN c1 LOOP
      i:=i+1;
      print_log('i = '||i);
      IF r1.invoice_id <> x_invoice_id_ant THEN
        -- Bug 8335230 (Item 5) - SSimoes - 13/03/2009 - Inicio
        -- IF NVL(r1.ri_ipi_amount,0) = 0 THEN -- Bug 8335230 (Item 5) - SSimoes - 30/03/2009 (new validation)
        IF r1.ipi_amount_header = 0 THEN -- Bug 8335230 (Item 5) - SSimoes - 30/03/2009 (new validation)
           x_mensagem     :=  fnd_message.get_string ('CLL', 'CLL_F189_DOC_RETURN');
        ELSE
           x_mensagem     :=  fnd_message.get_string ('CLL', 'CLL_F189_IPI_RECOVER')||': '||r1.ri_ipi_amount||'. '||fnd_message.get_string ('CLL', 'CLL_F189_DOC_RETURN');
        END IF;
        print_log('  x_mensagem:'||x_mensagem);
        -- Bug 8335230 (Item 5) - SSimoes - 13/03/2009 - Fim
        --
        --Bug 14642712 - Egini - 20/09/2012 - Inicio
        /*
        x_mensagem_aux := x_mensagem;
        x_literal      := ' Doc ';
        --
        --  FOR r2 IN (SELECT ri.invoice_num || -- Bug 8335230 (Item 4) - SSimoes - 19/03/2009
        FOR r2 IN (SELECT DECODE(INSTR(REPLACE(ri.invoice_num,',','.'),'.'),0,ri.invoice_num,SUBSTR(ri.invoice_num,1,INSTR(REPLACE(ri.invoice_num,',','.'),'.') -1 )) ||  -- Bug 8335230 (Item 4) - SSimoes - 19/03/2009
                          ', '||fnd_message.get_string ('CLL', 'CLL_F189_SERIE')||' '||ri.series||', Dt. '||TO_CHAR(ri.invoice_date,'dd/mm/yy') inf_nf
                     FROM cll_f189_invoices         ri
                         ,cll_f189_invoice_parents  rip
                    WHERE ri.invoice_id = rip.invoice_parent_id
                      AND rip.invoice_id = r1.invoice_id) LOOP
          --
          x_inf_nf := x_literal || r2.inf_nf;
          x_mensagem_aux := x_mensagem_aux || x_inf_nf;
          --
         IF LENGTH(x_mensagem_aux) <= 450 THEN
            x_mensagem := x_mensagem || x_inf_nf;
         -- Bug 9809231 - SSimoes - 23/06/2010 - Inicio
         ELSE
            EXIT;
         -- Bug 9809231 - SSimoes - 23/06/2010 - Fim
         END IF;
         x_literal := ' -Doc '; -- ' - Doc '  AIrmer  24/04/2008 - This variable is varchar(6)
        END LOOP;
        --
        IF LENGTH(x_mensagem_aux) < 450 THEN
          x_mensagem := x_mensagem || '.';
        END IF; */
        --
        cll_f189_interface_pkg.count_insert_desc_ar(
          p_invoice_id => r1.invoice_id
          , p_count      => x_count_ar
          , p_desc       => x_desc_ar
        );
        --
        x_mensagem := x_desc_ar;
        --Bug 14642712 - Egini - 20/09/2012 - Fim
      END IF;
      --
      BEGIN
        SELECT 
          ood.set_of_books_id
          ,ood.operating_unit
          ,gsb.currency_code
        INTO x_set_of_books_id, x_operating_unit, x_currency_code
        FROM 
          org_organization_definitions ood
          ,gl_sets_of_books             gsb
        WHERE 1=1
          and ood.organization_id = r1.organization_id
          AND gsb.set_of_books_id = ood.set_of_books_id;
      EXCEPTION
        WHEN others THEN
          raise_application_error(-20548, x_module_name||' - ERROR:  '||SQLERRM ||' Selecting operating unit data and currency code.');
      END;
      --
      -- Bug 14400588 - Start
      BEGIN
        SELECT NVL(precision, 2) INTO l_gl_precision
        FROM fnd_currencies_vl
        WHERE currency_code = x_currency_code;
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20548, x_module_name||' - ERROR:  '||SQLERRM ||' Selecting currency precision.');
      END;
      -- Bug 14400588 - End
      --
      BEGIN
        SELECT ra.term_id
        INTO x_ra_term_id
        FROM 
          ra_terms ra
          ,ap_terms ap
        WHERE 1=1
          and UPPER(ra.NAME) = UPPER(ap.NAME)
          AND ap.term_id     = r1.terms_id;
      EXCEPTION
        WHEN others THEN
          IF r1.ctt_default_term IS NULL THEN
            BEGIN
              SELECT payment_term_id
              INTO x_ra_term_id
              FROM hz_cust_accounts -- ra_customers
              WHERE cust_account_id = r1.customer_id; -- WHERE customer_id = r1.customer_id;
            EXCEPTION
              WHEN others THEN
                x_ra_term_id := NULL;
            END;
          ELSE
            x_ra_term_id := r1.ctt_default_term;
          END IF;
      END;
      --
      x_sit_trib_est := r1.sit_trib_est;
      --
      IF x_sit_trib_est IS NULL THEN
        IF r1.icms_tax_code = 1 THEN
          -- x_sit_trib_est := SUBSTR(r1.source_items,1) || '00';    -- BUG: 8304334
          x_sit_trib_est := '00';                                   -- BUG: 8304334
        ELSIF r1.icms_tax_code = 2 THEN
          -- x_sit_trib_est := SUBSTR(r1.source_items,1) || '40'; -- BUG: 8304334
          x_sit_trib_est := '40';                                -- BUG: 8304334
        ELSIF r1.icms_tax_code = 3 THEN
          -- x_sit_trib_est := SUBSTR(r1.source_items,1) || '90'; -- BUG: 8304334
          x_sit_trib_est := '90';                                -- BUG: 8304334
        END IF;
      END IF;
      --
      BEGIN
        SELECT 
          --description -- BUG 7150760 --
          global_attribute_category
          --,global_attribute1 -- Bug 6778641 AIrmer 29/01/2008
          ,global_attribute2
          ,global_attribute3
          ,global_attribute4
          -- ,global_attribute5 -- Bug 4486071 AIrmer 19/08/2005
          ,global_attribute6
          ,global_attribute7
        INTO 
          --x_description -- BUG 7150760 --
          x_global_attribute_category
          --,x_global_attribute1 -- Bug 6778641 AIrmer 29/01/2008
          ,x_global_attribute2
          ,x_global_attribute3
          ,x_global_attribute4
          -- ,x_global_attribute5 -- Bug 4486071 AIrmer 19/08/2005
          ,x_global_attribute6
          ,x_global_attribute7
        FROM mtl_system_items
        WHERE 1=1
          and inventory_item_id = r1.item_id
          AND organization_id   = r1.organization_id;
      EXCEPTION
        WHEN others THEN
          raise_application_error(-20549, x_module_name||' - ERROR:  '||SQLERRM||' Selecting item data.');
      END;
      /* BUG 10355568: Start
        -- Bug 6778641 AIrmer 29/01/2008
         BEGIN
           SELECT category_concat_segs
            INTO  v_category_concat_segs
           FROM   mtl_item_categories_v
           WHERE  inventory_item_id = r1.item_id
             AND  organization_id   = r1.organization_id
             AND structure_id = 4; -- hardcoded to Fiscal Classification
         EXCEPTION
          WHEN OTHERS THEN
               raise_application_error
                 (-20558, x_module_name||' - ERROR:  '||SQLERRM||' Selecting item Fiscal Classification.');
         END;
        --
      BUG 10355568: End    */
      --
      -- BUG Equal 6667766 - rvicente - 14/05/2008 - Begin
      IF r1.additional_amount_header = 0 AND               -- Bug 10086670 --
          r1.discount_amount = 0 THEN                       -- Bug 10086670 --
          x_unit_selling_price := r1.unit_price;
      ELSE
          --x_unit_selling_price := (round((r1.ipi_base_amount - r1.discount_amount),2)/r1.quantity); -- Bug 10127287
          -- x_unit_selling_price := (round((r1.ipi_base_amount - (r1.discount_amount*r1.quantity)),2)/r1.quantity); -- Bug 10127287 -- Bug 10086670 --
          x_unit_selling_price := ROUND(r1.net_amount,2) /    -- Bug 10086670 --
                                  r1.quantity;                -- Bug 10086670 --
      END IF;
      -- BUG Equal 6667766 - rvicente - 14/05/2008 - End
      --
      -- Enh 6860943 - SSimoes - 03/03/2008 - Inicio
      BEGIN
        --SELECT DECODE(reo.freight_flag,'C','CIF','F','FOB',NULL)
        SELECT DECODE(reo.freight_flag,'C','1','F','2',NULL) -- Enh 7019481
          INTO x_fob_point
          FROM cll_f189_entry_operations reo
         WHERE reo.organization_id = r1.organization_id
           AND reo.operation_id = r1.operation_id;
      EXCEPTION
         WHEN OTHERS THEN
           x_fob_point := NULL;
      END;
      -- Enh 6860943 - SSimoes - 03/03/2008 - Fim
      --
      -- Bug 7560411 - rvicente 11/05/09 - Begin
      BEGIN
        SELECT nvl(salesrep_required_flag,'N')
          INTO v_salesrep_required_flag
          FROM ar_system_parameters_all
         WHERE org_id = x_operating_unit;
      EXCEPTION WHEN others THEN
        v_salesrep_required_flag := 'N';
      END;
      --
      --
      IF (v_salesrep_required_flag = 'Y') THEN
          BEGIN
            SELECT sales_credit_type_id
              INTO c_sales_credit_type_id
              FROM ra_salesreps_all
             WHERE salesrep_id = -3
               AND org_id = x_operating_unit;
          EXCEPTION WHEN others THEN
              c_sales_credit_type_id := 1;
          END;
      END IF;
      -- Bug 7560411 - rvicente 11/05/09 - End
      -- Incio BUG 19495468
      BEGIN
        SELECT count(*)
          INTO v_col_exist
          FROM sys.all_tab_columns
         WHERE table_name  = 'JL_BR_INTERFACE_LINES_EXTS'
           AND column_name = 'FISCAL_DOC_MODEL';
      EXCEPTION 
        WHEN others THEN
        v_col_exist := 0;
      END;
      --
      BEGIN
        SELECT cil.quantity, cil.invoice_line_id,
               (SELECT cil1.invoice_line_id
                  FROM cll_f189_invoice_lines cil1
                 WHERE cil1.invoice_line_id = cflp.invoice_parent_line_id) inv_line_id   ,
               (SELECT cil1.quantity
                  FROM cll_f189_invoice_lines cil1
                 WHERE cil1.invoice_line_id = cflp.invoice_parent_line_id) qty_parent
          INTO v_qty_invoice_dev,
               v_invoice_line_id_dev,
               v_invoice_line_id_par,
               v_qty_parent
          FROM cll_f189_invoice_line_parents cflp
              ,cll_f189_invoice_parents      cfip
              ,cll_f189_invoice_lines        cil
         WHERE cflp.invoice_line_id = r1.invoice_line_id
           AND cflp.parent_id       = cfip.parent_id
           AND cflp.invoice_line_id   = cil.invoice_line_id;
      EXCEPTION WHEN others THEN
        v_qty_invoice_dev      :=0;
        v_invoice_line_id_dev  :=0;
        v_invoice_line_id_par  :=0;
        v_qty_parent           :=0;
      END;
      --
      arr := 2;
      --
      IF  NVL(v_qty_invoice_dev,0) = nvl(v_qty_parent,0) THEN
          v_perc_returned_goods := 100;
      ELSIF  NVL(v_qty_invoice_dev,0) <> nvl(v_qty_parent,0) THEN
          v_perc_returned_goods := ROUND ((NVL(v_qty_invoice_dev,0) / nvl(v_qty_parent,0)) * 100,arr);
      END IF;
      --
      IF r1.global_attr_categ_site = 'JL.BR.ARXCUDCI.Additional' THEN
         v_fiscal_doc_model := r1.fiscal_doc_model;
      ELSIF r1.global_attr_categ_site <> 'JL.BR.ARXCUDCI.Additional' THEN
            v_fiscal_doc_model := NULL;
      END IF;
      --
      IF r1.global_attr_categ_site = 'JL.BR.RAXSUCTT.Globalization' THEN
         v_buyer_presence_ind := r1.buyer_presence_ind;
      ELSIF r1.global_attr_categ_site <> 'JL.BR.RAXSUCTT.Globalization' THEN
         v_buyer_presence_ind := NULL;
      END IF;
      -- Fim BUG 19495468
      --
      print_log('  Insere na Interface Lines...');
      INSERT INTO ra_interface_lines_all
                 (interface_line_id
                 ,amount_includes_tax_flag
                 ,interface_line_context
                 ,interface_line_attribute1
                 ,interface_line_attribute2
                 ,interface_line_attribute3
                 ,interface_line_attribute4
                 ,interface_line_attribute5
                 ,batch_source_name
                 ,set_of_books_id
                 ,line_type
                 ,description
                 ,currency_code
                 ,amount
                 ,cust_trx_type_id
                 ,orig_system_bill_customer_id
                 ,orig_system_bill_address_id
                 ,orig_system_ship_customer_id
                 ,orig_system_ship_address_id
                 ,conversion_type
                 ,conversion_rate
                 ,gl_date
                 ,quantity
                 ,unit_selling_price
                 ,inventory_item_id
                 ,uom_code
                 ,uom_name
                 ,created_by
                 ,creation_date
                 ,last_updated_by
                 ,last_update_date
                 ,last_update_login
                 ,org_id
                 ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                 ,header_gdf_attribute10 -- Bug 14582853
                 ,header_gdf_attribute11 -- Bug 14582853
                 ,header_gdf_attr_category
                 ,line_gdf_attr_category
                 ,line_gdf_attribute1
                 ,line_gdf_attribute2
                 ,line_gdf_attribute3
                 ,line_gdf_attribute4
                 ,line_gdf_attribute5
                 ,line_gdf_attribute6
                 ,line_gdf_attribute7
                 ,line_gdf_attribute8
                 ,line_gdf_attribute9
                 ,line_gdf_attribute10
                 ,warehouse_id
                 ,term_id
                 ,primary_salesrep_id
                 ,fob_point) -- Enh 6860943
        VALUES
                 (NULL                                              -- interface_line_id
                 ,'N'                                               -- amount_includes_tax_flag
                 ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                 ,r1.operation_id                                   -- interface_line_attribute1
                 ,r1.organization_id                                -- interface_line_attribute2
                 ,r1.invoice_id                                     -- interface_line_attribute3
                 ,r1.invoice_line_id                                -- interface_line_attribute4
                 ,0                                                 -- interface_line_attribute5
                 ,r1.rbsa_name                                      -- batch_source_name
                 ,x_set_of_books_id                                 -- set_of_books_id
                 ,'LINE'                                            -- line_type
                 -- x_description,                                     -- description -- BUG 7150760 --
                 ,r1.ril_description                                -- description of cll_f189_invoice_lines -- BUG 7150760 --
                 ,x_currency_code                                   -- currency_code
                 -- ,r1.ipi_base_amount - r1.discount_amount          -- amount -- BUG 4027666
                 -- ,ROUND((r1.ipi_base_amount - r1.discount_amount),2) -- amount -- BUG 4027666 -- Bug 8577461 - SSimoes - 09/06/2009
                 -- ,ROUND((r1.ipi_base_amount - r1.discount_amount - r1.freight_amount_line),2) -- amount -- Bug 8577461 - SSimoes - 09/06/2009 -- Bug 10127287
                 -- ,ROUND((r1.ipi_base_amount - (r1.discount_amount * r1.quantity) - r1.freight_amount_line),2) -- amount -- Bug 10127287 -- Bug 10086670 --
                 --
                 -- Bug 14582853 - Start
                 -- ,ROUND((r1.net_amount - r1.freight_amount_line),2) -- amount -- Bug 10086670 --
                 ,ROUND(r1.net_amount -
                        r1.freight_amount_line -
                        r1.insurance_amount_line -  -- Bug 20646467 ASaraiva 04/05/2015
                        r1. other_expenses_line     -- Bug 20646467 ASaraiva 04/05/2015
                 --  ,2)
                       ,l_gl_precision)                             --amount -- Bug 14400588
                 -- Bug 14582853 - End
                 --
                 ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                 ,r1.customer_id                                    -- orig_system_bill_customer_id
                 ,r1.address_id                                     -- orig_system_bill_address_id
                 ,r1.customer_id                                    -- orig_system_ship_customer_id
                 ,r1.address_id                                     -- orig_system_ship_address_id
                 ,'User'                                            -- conversion_type
                 ,1                                                 -- conversion_rate
                 ,NULL                                              -- gl_date
                 ,r1.quantity                                       -- quantity
                 -- ,(r1.ipi_base_amount - r1.discount_amount)/
                 -- r1.quantity                                    -- unit_selling_price -- BUG 4027666
                 -- BUG 5371443 - Begin
                 -- ,ROUND(((r1.ipi_base_amount - r1.discount_amount)/
                 -- r1.quantity),2)                           -- unit_selling_price -- BUG 4027666
                 ,x_unit_selling_price -- BUG Equal 6667766 (ROUND((r1.ipi_base_amount - r1.discount_amount),2)/r1.quantity) -- unit_selling_price -- BUG 5371443
                 -- BUG 5371443 - End
                 ,r1.item_id                                        -- inventory_item_id
                 ,r1.uom                                            -- uom_code
                 ,r1.uom_name                                       -- uom_name
                 ,r1.created_by                                     -- created_by
                 ,r1.creation_date                                  -- creation_date
                 ,r1.last_updated_by                                -- last_updated_by
                 ,r1.last_update_date                               -- last_update_date
                 ,r1.last_update_login                              -- last_update_login
                 ,x_operating_unit                                  -- org_id
                 /*
                 ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                 ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                 ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                 */
                 ,fnd_number.number_to_canonical(
                             ROUND( r1.freight_amount_header
                                  , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                 ,fnd_number.number_to_canonical(
                             ROUND( r1.insurance_amount_header
                                  , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                 ,fnd_number.number_to_canonical(
                             ROUND( r1.other_expenses_header
                                  , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                 --
                 -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- header_gdf_attr_category   -- Bug 5371080 --
                 ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                       -- Bug 5371080 --
                 -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- line_gdf_attr_category     -- Bug 5371080 --
                 ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                         -- Bug 5371080 --
                 ,r1.cfo_code                                       -- line_gdf_attribute1
                 -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2   -- Bug 6778641 AIrmer 29/01/2008
                 -- ,NVL(r1.classification_code,v_category_concat_segs)  -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008  -- BUG 10355568
                 ,r1.classification_code                                -- line_gdf_attribute2 -- BUG 10355568
                 ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                 -- ,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                 ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                 ,x_global_attribute4                               -- line_gdf_attribute5
                 -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                 ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                 ,x_sit_trib_est                                    -- line_gdf_attribute7
                 -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                 ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                 -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                 ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                 -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                 ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                 ,r1.organization_id                                -- warehouse_id
                 ,x_ra_term_id                                      -- term_id
                 ,r1.salesrep_id
                 ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
      --
      -- Bug 7560411 - rvicente 11/05/09 - Begin
      -- Incio BUG 19495468
      SELECT ROWID
      INTO V_ROWID
      FROM ra_interface_lines_all
      WHERE 1=1
        and interface_line_attribute4 = TO_CHAR(r1.invoice_line_id)
        AND line_type = 'LINE'
        AND interface_line_context = 'CLL F189 INTEGRATED RCV';  -- BUG 25118794
      --
      IF v_col_exist <> 0 THEN
        --
        print_log('  Insere na jl_br_interface_lines_exts');
        EXECUTE IMMEDIATE 
          'INSERT INTO jl_br_interface_lines_exts( 
          jl_br_interface_link_id,
          fiscal_doc_model,
          buyer_presence_ind,
          perc_returned_goods,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login)
          VALUES ('''||V_ROWID||''','||
          NVL(v_fiscal_doc_model, 'Null')||','||
          NVL(v_buyer_presence_ind, 'Null')||','||
          --<< BUG 20930680 - 07/05/15 - Start -->>
          --v_perc_returned_goods||','||
          ltrim(to_char(round(v_perc_returned_goods,5),'9999999999D99999',
          'NLS_NUMERIC_CHARACTERS = ''.,'''))||','||
          --<<  BUG 20930680 - 07/05/15 - End -->>
          r1.created_by||','||
          'sysdate'||','||
          r1.last_updated_by||','||
          'sysdate'||','||
          NVL(r1.last_update_login, FND_GLOBAL.LOGIN_ID)||')'; 
          -- 29908009
          --r1.last_update_login||')';                           -- 29908009
      END IF;
      -- Fim BUG 19495468
      IF (v_salesrep_required_flag = 'Y') THEN
        print_log('  Insere na ra_interface_salescredits_all');
        INSERT INTO ra_interface_salescredits_all(
          interface_line_context         -- 01
          ,interface_line_attribute1      -- 02
          ,interface_line_attribute2      -- 03
          ,interface_line_attribute3      -- 04
          ,interface_line_attribute4      -- 05
          ,interface_line_attribute5      -- 06
          ,salesrep_id                    -- 07
          ,sales_credit_type_id           -- 08
          ,sales_credit_percent_split     -- 09
          ,created_by                     -- 10
          ,creation_date                  -- 11
          ,last_updated_by                -- 12
          ,last_update_date               -- 13
          ,last_update_login              -- 14
          ,org_id                         -- 15
        )VALUES(
          'CLL F189 INTEGRATED RCV'      -- 01 interface_line_context
          ,r1.operation_id                -- 02 interface_line_attribute1
          ,r1.organization_id             -- 03 interface_line_attribute2
          ,r1.invoice_id                  -- 04 interface_line_attribute3
          ,r1.invoice_line_id             -- 05 interface_line_attribute4
          ,0                              -- 06 interface_line_attribute5
          --Inicio BUG 18906577
          --,-3                             -- 07 fixo '-3' porque representa o 'no sales credit'
          ,r1.salesrep_id
          --Fim BUG 18906577
          ,c_sales_credit_type_id         -- 08
          ,100                            -- 09 percentual
          ,r1.created_by                  -- 10
          ,r1.creation_date               -- 11
          ,r1.last_updated_by             -- 12
          ,r1.last_update_date            -- 13
          ,r1.last_update_login           -- 14
          ,x_operating_unit               -- 15
        );
      END IF;
      -- Bug 7560411 - rvicente 11/05/09 - End
      --
      x_mensagem     := NULL;
      x_mensagem_aux := NULL;
      --
      IF r1.icms_amount > 0 THEN
        IF r1.ar_cred_icms_category_id IS NOT NULL THEN
          BEGIN
            SELECT avt.tax_code
              INTO x_tax_code
              FROM jl_zz_ar_tx_categ_all jza,
                   ar_vat_tax_vl         avt
             WHERE jza.tax_category_id   = r1.ar_cred_icms_category_id
               AND jza.org_id            = x_operating_unit
               AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
               -- 21842498 - Start
               AND avt.enabled_flag     = 'Y'
               AND avt.start_date <= sysdate
               AND nvl(avt.end_date, sysdate + 1) > sysdate
               -- 21842498 - End
               AND ROWNUM                = 1;
          EXCEPTION
            WHEN others THEN
              raise_application_error (-20550, x_module_name||' - ERROR:  '||SQLERRM||' Selecting ICMS tax code.');
          END;
          --
          INSERT INTO ra_interface_lines_all
                     (interface_line_id
                     ,amount_includes_tax_flag
                     ,interface_line_context
                     ,interface_line_attribute1
                     ,interface_line_attribute2
                     ,interface_line_attribute3
                     ,interface_line_attribute4
                     ,interface_line_attribute5
                     ,batch_source_name
                     ,link_to_line_context
                     ,link_to_line_attribute1
                     ,link_to_line_attribute2
                     ,link_to_line_attribute3
                     ,link_to_line_attribute4
                     ,link_to_line_attribute5
                     ,set_of_books_id
                     ,line_type
                     ,description
                     ,currency_code
                     ,amount
                     ,cust_trx_type_id
                     ,orig_system_bill_customer_id
                     ,orig_system_bill_address_id
                     ,orig_system_ship_customer_id
                     ,orig_system_ship_address_id
                     ,conversion_type
                     ,conversion_rate
                     ,gl_date
                     ,tax_rate
                     --,tax_code BUG 7715719 - rvicente - 21/01/2009
                     ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,org_id
                     ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,header_gdf_attribute10 -- Bug 14582853
                     ,header_gdf_attribute11 -- Bug 14582853
                     ,header_gdf_attr_category
                     ,line_gdf_attr_category
                     ,line_gdf_attribute1
                     ,line_gdf_attribute2
                     ,line_gdf_attribute3
                     ,line_gdf_attribute4
                     ,line_gdf_attribute5
                     ,line_gdf_attribute6
                     ,line_gdf_attribute7
                     ,line_gdf_attribute8
                     ,line_gdf_attribute9
                     ,line_gdf_attribute10
                     ,term_id
                     ,line_gdf_attribute11
                     ,line_gdf_attribute19
                     ,line_gdf_attribute20
                     ,primary_salesrep_id
                     ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
               VALUES
                     (NULL                                               -- interface_line_id
                     ,'N'                                                -- amount_includes_tax_flag
                     ,'CLL F189 INTEGRATED RCV'                          -- interface_line_context
                     ,r1.operation_id                                    -- interface_line_attribute1
                     ,r1.organization_id                                 -- interface_line_attribute2
                     ,r1.invoice_id                                      -- interface_line_attribute3
                     ,r1.invoice_line_id                                 -- interface_line_attribute4
                     ,1                                                  -- interface_line_attribute5
                     ,r1.rbsa_name                                       -- batch_source_name
                     ,'CLL F189 INTEGRATED RCV'                          -- link_to_line_context
                     ,r1.operation_id                                    -- link_to_line_attribute1
                     ,r1.organization_id                                 -- link_to_line_attribute2
                     ,r1.invoice_id                                      -- link_to_line_attribute3
                     ,r1.invoice_line_id                                 -- link_to_line_attribute4
                     ,'0'                                                -- link_to_line_attribute5
                     ,x_set_of_books_id                                  -- set_of_books_id
                     ,'TAX'                                              -- line_type
                     ,'ICMS'                                             -- description
                     ,x_currency_code                                    -- currency_code
                     ,ROUND(r1.icms_amount, l_gl_precision)              -- amount -- Bug 14400588
                     -- ,r1.icms_amount                                     -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     -- NULL,                                               -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     ,r1.ar_transaction_type_id                          -- cust_trx_type_id
                     ,r1.customer_id                                     -- orig_system_bill_customer_id
                     ,NULL                                               -- orig_system_bill_address_id
                     ,r1.customer_id                                     -- orig_system_ship_customer_id
                     ,NULL                                               -- orig_system_ship_address_id
                     ,'User'                                             -- conversion_type
                     ,1                                                  -- conversion_rate
                     ,NULL                                               -- gl_date
                     ,r1.icms_tax                                        -- tax_rate
                     ,x_tax_code                                         -- tax_code
                     ,r1.created_by                                      -- created_by
                     ,r1.creation_date                                   -- creation_date
                     ,r1.last_updated_by                                 -- last_updated_by
                     ,r1.last_update_date                                -- last_update_date
                     ,r1.last_update_login                               -- last_update_login
                     ,x_operating_unit                                   -- org_id
                     /*
                     ,r1.freight_amount_header                           -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,r1.insurance_amount_header                         -- header_gdf_attribute10 -- Bug 14582853
                     ,r1.other_expenses_header                           -- header_gdf_attribute11 -- Bug 14582853
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.freight_amount_header
                                      , l_gl_precision ))                -- header_gdf_attribute9  -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.insurance_amount_header
                                      , l_gl_precision ))                -- header_gdf_attribute10 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.other_expenses_header
                                      , l_gl_precision ))                -- header_gdf_attribute11 -- Bug 14400588
                     --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- header_gdf_attr_category   -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                   -- header_gdf_attr_category                      -- Bug 5371080 --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- line_gdf_attr_category     -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                   -- line_gdf_attr_category                        -- Bug 5371080 --
                     ,r1.cfo_code                                        -- line_gdf_attribute1
                     -- ,NVL(r1.classification_code,x_global_attribute1)    -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                     -- ,NVL(r1.classification_code,v_category_concat_segs) -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008  BUG 10355568
                     ,r1.classification_code                               -- line_gdf_attribute2 -- BUG 10355568
                     ,NVL(r1.utilization_code,x_global_attribute2)       -- line_gdf_attribute3
                   --,NVL(r1.source_items,x_global_attribute3)           -- line_gdf_attribute4 -- Bug 16850244
                     ,NVL(r1.sit_trib_code, x_global_attribute3)         -- line_gdf_attribute4 -- Bug 16850244
                     ,x_global_attribute4                                -- line_gdf_attribute5
                     -- ,x_global_attribute5                                -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,r1.ipi_tax_code                                    -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,x_sit_trib_est                                     -- line_gdf_attribute7
                     -- ,SUBSTR(x_mensagem,1,150)                          -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,1,150)                          -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,151,150)                        -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,151,150)                        -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,301,150)                        -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,301,150)                        -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,x_ra_term_id                                       -- term_id
                     /*
                     ,r1.icms_base                                       -- line_gdf_attribute11
                     ,r1.icms_amount                                     -- line_gdf_attribute19
                     ,r1.icms_amount   --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     --,r1.ipi_amount  --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG 4044106  -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_base
                                      , l_gl_precision ))                -- line_gdf_attribute11 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_amount
                                      , l_gl_precision ))                -- line_gdf_attribute19 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_amount
                                      , l_gl_precision ))                -- line_gdf_attribute20 -- Bug 14400588
                     --
                     ,r1.salesrep_id
                     ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
          --
        END IF;
        --
        IF r1.ar_deb_icms_category_id IS NOT NULL THEN
          BEGIN
            SELECT avt.tax_code
              INTO x_tax_code
              FROM jl_zz_ar_tx_categ_all jza,
                   ar_vat_tax_vl         avt
             WHERE jza.tax_category_id   = r1.ar_deb_icms_category_id
               AND jza.org_id            = x_operating_unit
               AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
               -- 21842498 - Start
               AND avt.enabled_flag     = 'Y'
               AND avt.start_date <= sysdate
               AND nvl(avt.end_date, sysdate + 1) > sysdate
               -- 21842498 - End
               AND ROWNUM                = 1;
          EXCEPTION
            WHEN others THEN
              raise_application_error (-20551, x_module_name||' - ERROR:  '||SQLERRM||' Selecting ICMS tax code.');
          END;
          --
          INSERT INTO ra_interface_lines_all
                     (interface_line_id
                     ,amount_includes_tax_flag
                     ,interface_line_context
                     ,interface_line_attribute1
                     ,interface_line_attribute2
                     ,interface_line_attribute3
                     ,interface_line_attribute4
                     ,interface_line_attribute5
                     ,batch_source_name
                     ,link_to_line_context
                     ,link_to_line_attribute1
                     ,link_to_line_attribute2
                     ,link_to_line_attribute3
                     ,link_to_line_attribute4
                     ,link_to_line_attribute5
                     ,set_of_books_id
                     ,line_type
                     ,description
                     ,currency_code
                     ,amount
                     ,cust_trx_type_id
                     ,orig_system_bill_customer_id
                     ,orig_system_bill_address_id
                     ,orig_system_ship_customer_id
                     ,orig_system_ship_address_id
                     ,conversion_type
                     ,conversion_rate
                     ,gl_date
                     ,tax_rate
                     --,tax_code BUG 7715719 - rvicente - 21/01/2009
                     ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,org_id
                     ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,header_gdf_attribute10 -- Bug 14582853
                     ,header_gdf_attribute11 -- Bug 14582853
                     ,header_gdf_attr_category
                     ,line_gdf_attr_category
                     ,line_gdf_attribute1
                     ,line_gdf_attribute2
                     ,line_gdf_attribute3
                     ,line_gdf_attribute4
                     ,line_gdf_attribute5
                     ,line_gdf_attribute6
                     ,line_gdf_attribute7
                     ,line_gdf_attribute8
                     ,line_gdf_attribute9
                     ,line_gdf_attribute10
                     ,term_id
                     ,line_gdf_attribute11
                     ,line_gdf_attribute19
                     ,line_gdf_attribute20
                     ,primary_salesrep_id
                     ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
               VALUES
                     (NULL                                              -- interface_line_id
                     ,'N'                                               -- amount_includes_tax_flag
                     ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                     ,r1.operation_id                                   -- interface_line_attribute1
                     ,r1.organization_id                                -- interface_line_attribute2
                     ,r1.invoice_id                                     -- interface_line_attribute3
                     ,r1.invoice_line_id                                -- interface_line_attribute4
                     ,2                                                 -- interface_line_attribute5
                     ,r1.rbsa_name                                      -- batch_source_name
                     ,'CLL F189 INTEGRATED RCV'                         -- link_to_line_context
                     ,r1.operation_id                                   -- link_to_line_attribute1
                     ,r1.organization_id                                -- link_to_line_attribute2
                     ,r1.invoice_id                                     -- link_to_line_attribute3
                     ,r1.invoice_line_id                                -- link_to_line_attribute4
                     ,'0'                                               -- link_to_line_attribute5
                     ,x_set_of_books_id                                 -- set_of_books_id
                     ,'TAX'                                             -- line_type
                     ,'ICMS'                                            -- description
                     ,x_currency_code                                   -- currency_code
                     ,ROUND(r1.icms_amount *-1, l_gl_precision)         -- amount -- Bug 14400588
                     -- ,r1.icms_amount *-1                                -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     -- NULL,                                              -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                     ,r1.customer_id                                    -- orig_system_bill_customer_id
                     ,NULL                                              -- orig_system_bill_address_id
                     ,r1.customer_id                                    -- orig_system_ship_customer_id
                     ,NULL                                              -- orig_system_ship_address_id
                     ,'User'                                            -- conversion_type
                     ,1                                                 -- conversion_rate
                     ,NULL                                              -- gl_date
                     ,r1.icms_tax * -1                                  -- tax_rate
                     ,x_tax_code                                        -- tax_code
                     ,r1.created_by                                     -- created_by
                     ,r1.creation_date                                  -- creation_date
                     ,r1.last_updated_by                                -- last_updated_by
                     ,r1.last_update_date                               -- last_update_date
                     ,r1.last_update_login                              -- last_update_login
                     ,x_operating_unit                                  -- org_id
                     /*
                     ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                     ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.freight_amount_header
                                      , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.insurance_amount_header
                                      , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.other_expenses_header
                                      , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                     --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- header_gdf_attr_category   -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                        -- Bug 5371080 --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- line_gdf_attr_category     -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                          -- Bug 5371080 --
                     ,r1.cfo_code                                       -- line_gdf_attribute1
                     -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                     -- ,NVL(r1.classification_code,v_category_concat_segs)-- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008  BUG 10355568
                     ,r1.classification_code                             -- line_gdf_attribute2 -- BUG 10355568
                     ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                     --,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                     ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                     ,x_global_attribute4                               -- line_gdf_attribute5
                     -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,x_sit_trib_est                                    -- line_gdf_attribute7
                     -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,x_ra_term_id                                      -- term_id
                     /*
                     ,r1.icms_base *-1                                  -- line_gdf_attribute11
                     ,r1.icms_amount *-1                                -- line_gdf_attribute19
                     ,r1.icms_amount *-1  --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     --(++) Rantonio, 27/08/2007; BUG 6322784 --,r1.ipi_amount *-1 -- line_gdf_attribute20 -- BUG 4044106 -- BUG 6 Equaliz 6774760 - rvicente - 25/01/2008
                     */
  
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_base *-1
                                      , l_gl_precision ))               -- line_gdf_attribute11 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_amount *-1
                                      , l_gl_precision ))               -- line_gdf_attribute19 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_amount *-1
                                      , l_gl_precision ))               -- line_gdf_attribute20 -- Bug 14400588
                     --
                     ,r1.salesrep_id
                     ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
          --
        END IF;
        --
      END IF;
      IF r1.icms_st_amount > 0 THEN
        --    IF r1.icms_st_amount > 0 AND nvl(r1.simplified_br_tax_flag,'N') = 'N' THEN -- ER 9289619
        IF r1.ar_cred_icms_st_category_id IS NOT NULL THEN
          BEGIN
            SELECT avt.tax_code
              INTO x_tax_code
              FROM jl_zz_ar_tx_categ_all jza,
                   ar_vat_tax_vl         avt
             WHERE jza.tax_category_id   = r1.ar_cred_icms_st_category_id
               AND jza.org_id            = x_operating_unit
               AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
               -- 21842498 - Start
               AND avt.enabled_flag     = 'Y'
               AND avt.start_date <= sysdate
               AND nvl(avt.end_date, sysdate + 1) > sysdate
               -- 21842498 - End
               AND ROWNUM                = 1;
          EXCEPTION
            WHEN others THEN
              raise_application_error
                   (-20552, x_module_name||' - ERROR:  '||SQLERRM||' Selecting ICMS ST tax code.');
          END;
          --
          INSERT INTO ra_interface_lines_all
                     (interface_line_id
                     ,amount_includes_tax_flag
                     ,interface_line_context
                     ,interface_line_attribute1
                     ,interface_line_attribute2
                     ,interface_line_attribute3
                     ,interface_line_attribute4
                     ,interface_line_attribute5
                     ,batch_source_name
                     ,link_to_line_context
                     ,link_to_line_attribute1
                     ,link_to_line_attribute2
                     ,link_to_line_attribute3
                     ,link_to_line_attribute4
                     ,link_to_line_attribute5
                     ,set_of_books_id
                     ,line_type
                     ,description
                     ,currency_code
                     ,amount
                     ,cust_trx_type_id
                     ,orig_system_bill_customer_id
                     ,orig_system_bill_address_id
                     ,orig_system_ship_customer_id
                     ,orig_system_ship_address_id
                     ,conversion_type
                     ,conversion_rate
                     ,gl_date
                     ,tax_rate
                     --,tax_code BUG 7715719 - rvicente - 21/01/2009
                     ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,org_id
                     ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,header_gdf_attribute10 -- Bug 14582853
                     ,header_gdf_attribute11 -- Bug 14582853
                     ,header_gdf_attr_category
                     ,line_gdf_attr_category
                     ,line_gdf_attribute1
                     ,line_gdf_attribute2
                     ,line_gdf_attribute3
                     ,line_gdf_attribute4
                     ,line_gdf_attribute5
                     ,line_gdf_attribute6
                     ,line_gdf_attribute7
                     ,line_gdf_attribute8
                     ,line_gdf_attribute9
                     ,line_gdf_attribute10
                     ,term_id
                     ,line_gdf_attribute11
                     ,line_gdf_attribute19
                     ,line_gdf_attribute20
                     ,primary_salesrep_id
                     ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
             VALUES
                     (NULL                                              -- interface_line_id
                     ,'N'                                               -- amount_includes_tax_flag
                     ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                     ,r1.operation_id                                   -- interface_line_attribute1
                     ,r1.organization_id                                -- interface_line_attribute2
                     ,r1.invoice_id                                     -- interface_line_attribute3
                     ,r1.invoice_line_id                                -- interface_line_attribute4
                     ,3                                                 -- interface_line_attribute5
                     ,r1.rbsa_name                                      -- batch_source_name
                     ,'CLL F189 INTEGRATED RCV'                         -- link_to_line_context
                     ,r1.operation_id                                   -- link_to_line_attribute1
                     ,r1.organization_id                                -- link_to_line_attribute2
                     ,r1.invoice_id                                     -- link_to_line_attribute3
                     ,r1.invoice_line_id                                -- link_to_line_attribute4
                     ,'0'                                               -- link_to_line_attribute5
                     ,x_set_of_books_id                                 -- set_of_books_id
                     ,'TAX'                                             -- line_type
                     ,'ICMS ST'                                         -- description
                     ,x_currency_code                                   -- currency_code
                     ,ROUND(r1.icms_st_amount, l_gl_precision)          -- amount -- Bug 14400588
                     -- ,r1.icms_st_amount                                 -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     --(++),NULL                                              -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                     ,r1.customer_id                                    -- orig_system_bill_customer_id
                     ,NULL                                              -- orig_system_bill_address_id
                     ,r1.customer_id                                    -- orig_system_ship_customer_id
                     ,NULL                                              -- orig_system_ship_address_id
                     ,'User'                                            -- conversion_type
                     ,1                                                 -- conversion_rate
                     ,NULL                                              -- gl_date
                     --,r1.icms_st_tax                                    -- tax_rate -- Bug 16395868
                     ,round(r1.icms_st_tax, l_gl_precision)             -- tax_rate -- Bug 16395868
                     ,x_tax_code                                        -- tax_code
                     ,r1.created_by                                     -- created_by
                     ,r1.creation_date                                  -- creation_date
                     ,r1.last_updated_by                                -- last_updated_by
                     ,r1.last_update_date                               -- last_update_date
                     ,r1.last_update_login                              -- last_update_login
                     ,x_operating_unit                                  -- org_id
                     /*
                     ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                     ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.freight_amount_header
                                      , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.insurance_amount_header
                                      , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.other_expenses_header
                                      , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                     --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- header_gdf_attr_category   -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                        -- Bug 5371080 --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- line_gdf_attr_category     -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                          -- Bug 5371080 --
                     ,r1.cfo_code                                       -- line_gdf_attribute1
                     -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                     -- ,NVL(r1.classification_code,v_category_concat_segs)-- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008 -- BUG 10355568
                     ,r1.classification_code                            -- line_gdf_attribute2 -- BUG 10355568
                     ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                     --,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                     ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                     ,x_global_attribute4                               -- line_gdf_attribute5
                     -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,x_sit_trib_est                                    -- line_gdf_attribute7
                     -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,x_ra_term_id                                      -- term_id
                     /*
                     -- ,r1.icms_base                                      -- line_gdf_attribute11 -- Bug 5962449 - SSimoes - 04/04/2007
                     -- ,r1.icms_amount                                    -- line_gdf_attribute19 -- Bug 5962449 - SSimoes - 04/04/2007
                     ,r1.icms_st_base                                   -- line_gdf_attribute11 -- Bug 5962449 - SSimoes - 04/04/2007
                     ,r1.icms_st_amount                                 -- line_gdf_attribute19 -- Bug 5962449 - SSimoes - 04/04/2007
                     ,r1.icms_st_amount --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     --,r1.ipi_amount   --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG 4044106 -- BUG 6774760 - rvicente - 25/01/2008
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_st_base
                                      , l_gl_precision ))               -- line_gdf_attribute11 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_st_amount
                                      , l_gl_precision ))               -- line_gdf_attribute19 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_st_amount
                                      , l_gl_precision ))               -- line_gdf_attribute20 -- Bug 14400588
                     --
                     ,r1.salesrep_id
                     ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
          --
        END IF;
        --
        IF r1.ar_deb_icms_st_category_id IS NOT NULL THEN
          BEGIN
            SELECT avt.tax_code
              INTO x_tax_code
              FROM jl_zz_ar_tx_categ_all jza,
                   ar_vat_tax_vl         avt
             WHERE jza.tax_category_id   = r1.ar_deb_icms_st_category_id
               AND jza.org_id            = x_operating_unit
               AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
               -- 21842498 - Start
               AND avt.enabled_flag     = 'Y'
               AND avt.start_date <= sysdate
               AND nvl(avt.end_date, sysdate + 1) > sysdate
               -- 21842498 - End
               AND ROWNUM                = 1;
          EXCEPTION
            WHEN others THEN
              raise_application_error (-20553, x_module_name||' - ERROR:  '|| SQLERRM ||' Selecting ICMS ST tax code.');
          END;
          --
          INSERT INTO ra_interface_lines_all
                     (interface_line_id
                     ,amount_includes_tax_flag
                     ,interface_line_context
                     ,interface_line_attribute1
                     ,interface_line_attribute2
                     ,interface_line_attribute3
                     ,interface_line_attribute4
                     ,interface_line_attribute5
                     ,batch_source_name
                     ,link_to_line_context
                     ,link_to_line_attribute1
                     ,link_to_line_attribute2
                     ,link_to_line_attribute3
                     ,link_to_line_attribute4
                     ,link_to_line_attribute5
                     ,set_of_books_id
                     ,line_type
                     ,description
                     ,currency_code
                     ,amount
                     ,cust_trx_type_id
                     ,orig_system_bill_customer_id
                     ,orig_system_bill_address_id
                     ,orig_system_ship_customer_id
                     ,orig_system_ship_address_id
                     ,conversion_type
                     ,conversion_rate
                     ,gl_date
                     ,tax_rate
                     --,tax_code BUG 7715719 - rvicente - 21/01/2009
                     ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,org_id
                     ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,header_gdf_attribute10 -- Bug 14582853
                     ,header_gdf_attribute11 -- Bug 14582853
                     ,header_gdf_attr_category
                     ,line_gdf_attr_category
                     ,line_gdf_attribute1
                     ,line_gdf_attribute2
                     ,line_gdf_attribute3
                     ,line_gdf_attribute4
                     ,line_gdf_attribute5
                     ,line_gdf_attribute6
                     ,line_gdf_attribute7
                     ,line_gdf_attribute8
                     ,line_gdf_attribute9
                     ,line_gdf_attribute10
                     ,term_id
                     ,line_gdf_attribute11
                     ,line_gdf_attribute19
                     ,line_gdf_attribute20
                     ,primary_salesrep_id
                     ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
               VALUES
                     (NULL                                              -- interface_line_id
                     ,'N'                                               -- amount_includes_tax_flag
                     ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                     ,r1.operation_id                                   -- interface_line_attribute1
                     ,r1.organization_id                                -- interface_line_attribute2
                     ,r1.invoice_id                                     -- interface_line_attribute3
                     ,r1.invoice_line_id                                -- interface_line_attribute4
                     ,4                                                 -- interface_line_attribute5
                     ,r1.rbsa_name                                      -- batch_source_name
                     ,'CLL F189 INTEGRATED RCV'                         -- link_to_line_context
                     ,r1.operation_id                                   -- link_to_line_attribute1
                     ,r1.organization_id                                -- link_to_line_attribute2
                     ,r1.invoice_id                                     -- link_to_line_attribute3
                     ,r1.invoice_line_id                                -- link_to_line_attribute4
                     ,'0'                                               -- link_to_line_attribute5
                     ,x_set_of_books_id                                 -- set_of_books_id
                     ,'TAX'                                             -- line_type
                     ,'ICMS ST'                                         -- description
                     ,x_currency_code                                   -- currency_code
                     ,ROUND(r1.icms_st_amount *-1, l_gl_precision)      -- amount -- Bug 14400588
                     -- ,r1.icms_st_amount *-1                             -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     -- ,NULL                                              -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                     ,r1.customer_id                                    -- orig_system_bill_customer_id
                     ,NULL                                              -- orig_system_bill_address_id
                     ,r1.customer_id                                    -- orig_system_ship_customer_id
                     ,NULL                                              -- orig_system_ship_address_id
                     ,'User'                                            -- conversion_type
                     ,1                                                 -- conversion_rate
                     ,NULL                                              -- gl_date
                     --,r1.icms_st_tax * -1                               -- tax_rate -- Bug 16395868
                     ,round(r1.icms_st_tax, l_gl_precision) * -1        -- tax_rate -- Bug 16395868
                     ,x_tax_code                                        -- tax_code
                     ,r1.created_by                                     -- created_by
                     ,r1.creation_date                                  -- creation_date
                     ,r1.last_updated_by                                -- last_updated_by
                     ,r1.last_update_date                               -- last_update_date
                     ,r1.last_update_login                              -- last_update_login
                     ,x_operating_unit                                  -- org_id
                     /*
                     ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                     ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.freight_amount_header
                                      , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.insurance_amount_header
                                      , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.other_expenses_header
                                      , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                     --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- header_gdf_attr_category   -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                        -- Bug 5371080 --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- line_gdf_attr_category     -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                          -- Bug 5371080 --
                     ,r1.cfo_code                                       -- line_gdf_attribute1
                     -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                     -- ,NVL(r1.classification_code,v_category_concat_segs)-- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008 -- BUG 10355568
                     ,r1.classification_code                              -- line_gdf_attribute2 -- BUG 10355568
                     ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                     --,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                     ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                     ,x_global_attribute4                               -- line_gdf_attribute5
                     -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,x_sit_trib_est                                    -- line_gdf_attribute7
                     -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,x_ra_term_id                                      -- term_id
                     /*
                     -- ,r1.icms_base *-1                                  -- line_gdf_attribute11 -- Bug 5962449 - SSimoes - 04/04/2007
                     -- ,r1.icms_amount *-1                                -- line_gdf_attribute19 -- Bug 5962449 - SSimoes - 04/04/2007
                     ,r1.icms_st_base *-1                               -- line_gdf_attribute11 -- Bug 5962449 - SSimoes - 04/04/2007
                     ,r1.icms_st_amount *-1                             -- line_gdf_attribute19 -- Bug 5962449 - SSimoes - 04/04/2007
                     ,r1.icms_st_amount *-1 --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     --,r1.ipi_amount *-1   --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG 4044106 -- BUG 6774760 - rvicente - 25/01/2008
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_st_base *-1
                                      , l_gl_precision ))               -- line_gdf_attribute11 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_st_amount *-1
                                      , l_gl_precision ))               -- line_gdf_attribute19 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.icms_st_amount *-1
                                      , l_gl_precision ))               -- line_gdf_attribute20 -- Bug 14400588
                     --
                     ,r1.salesrep_id
                     ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
          --
        END IF;
      END IF;
      --
      IF r1.ipi_amount > 0 THEN
        IF r1.ar_cred_ipi_category_id IS NOT NULL THEN
          BEGIN
            SELECT avt.tax_code
              INTO x_tax_code
              FROM jl_zz_ar_tx_categ_all jza,
                   ar_vat_tax_vl         avt
             WHERE jza.tax_category_id   = r1.ar_cred_ipi_category_id
               AND jza.org_id            = x_operating_unit
               AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
               -- 21842498 - Start
               AND avt.enabled_flag     = 'Y'
               AND avt.start_date <= sysdate
               AND nvl(avt.end_date, sysdate + 1) > sysdate
               -- 21842498 - End
               AND ROWNUM                = 1;
          EXCEPTION
            WHEN others THEN
              raise_application_error (-20554, x_module_name||' - ERROR:  '|| SQLERRM ||' Selecting IPI tax code.');
          END;
          --
          INSERT INTO ra_interface_lines_all
                     (interface_line_id
                     ,amount_includes_tax_flag
                     ,interface_line_context
                     ,interface_line_attribute1
                     ,interface_line_attribute2
                     ,interface_line_attribute3
                     ,interface_line_attribute4
                     ,interface_line_attribute5
                     ,batch_source_name
                     ,link_to_line_context
                     ,link_to_line_attribute1
                     ,link_to_line_attribute2
                     ,link_to_line_attribute3
                     ,link_to_line_attribute4
                     ,link_to_line_attribute5
                     ,set_of_books_id
                     ,line_type
                     ,description
                     ,currency_code
                     ,amount
                     ,cust_trx_type_id
                     ,orig_system_bill_customer_id
                     ,orig_system_bill_address_id
                     ,orig_system_ship_customer_id
                     ,orig_system_ship_address_id
                     ,conversion_type
                     ,conversion_rate
                     ,gl_date
                     ,tax_rate
                     --,tax_code BUG 7715719 - rvicente - 21/01/2009
                     ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,org_id
                     ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,header_gdf_attribute10 -- Bug 14582853
                     ,header_gdf_attribute11 -- Bug 14582853
                     ,header_gdf_attr_category
                     ,line_gdf_attr_category
                     ,line_gdf_attribute1
                     ,line_gdf_attribute2
                     ,line_gdf_attribute3
                     ,line_gdf_attribute4
                     ,line_gdf_attribute5
                     ,line_gdf_attribute6
                     ,line_gdf_attribute7
                     ,line_gdf_attribute8
                     ,line_gdf_attribute9
                     ,line_gdf_attribute10
                     ,term_id
                     ,line_gdf_attribute11
                     ,line_gdf_attribute19
                     ,line_gdf_attribute20
                     ,primary_salesrep_id
                     ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
               VALUES
                     (NULL                                              -- interface_line_id
                     ,'N'                                               -- amount_includes_tax_flag
                     ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                     ,r1.operation_id                                   -- interface_line_attribute1
                     ,r1.organization_id                                -- interface_line_attribute2
                     ,r1.invoice_id                                     -- interface_line_attribute3
                     ,r1.invoice_line_id                                -- interface_line_attribute4
                     ,5                                                 -- interface_line_attribute5
                     ,r1.rbsa_name                                      -- batch_source_name
                     ,'CLL F189 INTEGRATED RCV'                         -- link_to_line_context
                     ,r1.operation_id                                   -- link_to_line_attribute1
                     ,r1.organization_id                                -- link_to_line_attribute2
                     ,r1.invoice_id                                     -- link_to_line_attribute3
                     ,r1.invoice_line_id                                -- link_to_line_attribute4
                     ,'0'                                               -- link_to_line_attribute5
                     ,x_set_of_books_id                                 -- set_of_books_id
                     ,'TAX'                                             -- line_type
                     ,'IPI'                                             -- description
                     ,x_currency_code                                   -- currency_code
                     ,ROUND(r1.ipi_amount, l_gl_precision)              -- amount -- Bug 14400588
                     -- ,r1.ipi_amount                                     -- amount -- (++) Rantonio, 22/08/2007;BUG 6322784 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     -- ,NULL                                              -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                     ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                     ,r1.customer_id                                    -- orig_system_bill_customer_id
                     ,NULL                                              -- orig_system_bill_address_id
                     ,r1.customer_id                                    -- orig_system_ship_customer_id
                     ,NULL                                              -- orig_system_ship_address_id
                     ,'User'                                            -- conversion_type
                     ,1                                                 -- conversion_rate
                     ,NULL                                              -- gl_date
                     ,r1.ipi_tax                                        -- tax_rate
                     ,x_tax_code                                        -- tax_code
                     ,r1.created_by                                     -- created_by
                     ,r1.creation_date                                  -- creation_date
                     ,r1.last_updated_by                                -- last_updated_by
                     ,r1.last_update_date                               -- last_update_date
                     ,r1.last_update_login                              -- last_update_login
                     ,x_operating_unit                                  -- org_id
                     /*
                     ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                     ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                     ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.freight_amount_header
                                      , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.insurance_amount_header
                                      , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.other_expenses_header
                                      , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                     --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- header_gdf_attr_category    -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                        -- Bug 5371080 --
                     -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- line_gdf_attr_category      -- Bug 5371080 --
                     ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                          -- Bug 5371080 --
                     ,r1.cfo_code                                       -- line_gdf_attribute1
                     -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                     -- ,NVL(r1.classification_code,v_category_concat_segs)-- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008 -- BUG 10355568
                     ,r1.classification_code                            -- line_gdf_attribute2 -- BUG 10355568
                     ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                     --,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                     ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                     ,x_global_attribute4                               -- line_gdf_attribute5
                     -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                     ,x_sit_trib_est                                    -- line_gdf_attribute7
                     -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                     -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                     ,x_ra_term_id                                      -- term_id
                     /*
                     ,r1.ipi_base_amount -- line_gdf_attribute11 --(++) Rantonio, 18/09/2007; -- line_gdf_attribute11 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     --,r1.icms_base     -- line_gdf_attribute11 --(++) Rantonio, 18/09/2007; -- line_gdf_attribute11 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     ,r1.ipi_amount      -- line_gdf_attribute19 --(++) Rantonio, 18/09/2007; -- line_gdf_attribute11 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     --,r1.icms_amount   -- line_gdf_attribute20 --(++) Rantonio, 18/09/2007; -- line_gdf_attribute11 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                     ,r1.ipi_amount                                     -- line_gdf_attribute20 -- BUG 4044106
                     */
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.ipi_base_amount
                                      , l_gl_precision ))               -- line_gdf_attribute11 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.ipi_amount
                                      , l_gl_precision ))               -- line_gdf_attribute19 -- Bug 14400588
                     ,fnd_number.number_to_canonical(
                                 ROUND( r1.ipi_amount
                                      , l_gl_precision ))               -- line_gdf_attribute20 -- Bug 14400588
                     --
                     ,r1.salesrep_id
                     ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
            --
          END IF;
        END IF;
      --
      -- Bug 8577461 - SSimoes - 09/06/2009 - Inicio
      --
      IF r1.invoice_id <> x_invoice_id_ant AND r1.freight_amount_header > 0 THEN
        print_log('  Insere na ra_interface_lines_all');
        INSERT INTO ra_interface_lines_all(
          interface_line_id
          ,amount_includes_tax_flag
          ,interface_line_context
          ,interface_line_attribute1
          ,interface_line_attribute2
          ,interface_line_attribute3
          ,interface_line_attribute4
          ,interface_line_attribute5
          ,batch_source_name
          ,set_of_books_id
          ,line_type
          ,description
          ,currency_code
          ,amount
          ,cust_trx_type_id
          ,orig_system_bill_customer_id
          ,orig_system_bill_address_id
          ,orig_system_ship_customer_id
          ,orig_system_ship_address_id
          ,conversion_type
          ,conversion_rate
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,org_id
          ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 19/06/2009
          ,header_gdf_attribute10 -- Bug 14582853
          ,header_gdf_attribute11 -- Bug 14582853
          ,header_gdf_attr_category
          ,line_gdf_attr_category
          ,warehouse_id
          ,term_id
          ,primary_salesrep_id
          ,fob_point
        )VALUES(
          NULL                                              -- interface_line_id
          ,'N'                                               -- amount_includes_tax_flag
          ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
          ,r1.operation_id                                   -- interface_line_attribute1
          ,r1.organization_id                                -- interface_line_attribute2
          ,r1.invoice_id                                     -- interface_line_attribute3
          ,r1.invoice_line_id                                -- interface_line_attribute4
          ,6                                                 -- interface_line_attribute5
          ,r1.rbsa_name                                      -- batch_source_name
          ,x_set_of_books_id                                 -- set_of_books_id
          ,'FREIGHT'                                         -- line_type
          ,'Freight'                                         -- description
          ,x_currency_code                                   -- currency_code
          ,ROUND(r1.freight_amount_header
              + r1.insurance_amount_header                  -- Bug 20646467 ASaraiva 04/05/2015
              + r1.other_expenses_header                    -- Bug 20646467 ASaraiva 04/05/2015
             , l_gl_precision)   -- amount -- Bug 14400588
          --               ,r1.freight_amount_header                          -- amount
          ,r1.ar_transaction_type_id                         -- cust_trx_type_id
          ,r1.customer_id                                    -- orig_system_bill_customer_id
          ,r1.address_id                                     -- orig_system_bill_address_id
          ,r1.customer_id                                    -- orig_system_ship_customer_id
          ,r1.address_id                                     -- orig_system_ship_address_id
          ,'User'                                            -- conversion_type
          ,1                                                 -- conversion_rate
          ,r1.created_by                                     -- created_by
          ,r1.creation_date                                  -- creation_date
          ,r1.last_updated_by                                -- last_updated_by
          ,r1.last_update_date                               -- last_update_date
          ,r1.last_update_login                              -- last_update_login
          ,x_operating_unit                                  -- org_id
          /*
          ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 19/06/2009
          ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
          ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
          */
          ,fnd_number.number_to_canonical(
                     ROUND( r1.freight_amount_header
                          , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
          ,fnd_number.number_to_canonical(
                     ROUND( r1.insurance_amount_header
                          , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
          ,fnd_number.number_to_canonical(
                     ROUND( r1.other_expenses_header
                          , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
          --
          ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category
          ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category
          ,r1.organization_id                                -- warehouse_id
          ,x_ra_term_id                                      -- term_id
          ,r1.salesrep_id                                    -- primary_salesrep_id
          ,x_fob_point                                       -- fob_point
        );                                     
        --
      END IF;
      --
      -- Bug 8577461 - SSimoes - 09/06/2009 - Fim
      --
      x_mensagem       := NULL;
      x_mensagem_aux   := NULL;
      x_invoice_id_ant := r1.invoice_id;
      --
      UPDATE cll_f189_invoices
      SET ar_interface_flag = 'Y'
      WHERE invoice_id = r1.invoice_id;
      --
    END LOOP;
    print_log('  FIM CLL_F189_INTERFACE_PKG.AR');
  END ar;
  -----------------------------------------------------------------------------
  --->                             PA Interface                            <---
  -----------------------------------------------------------------------------
  PROCEDURE pa (p_operation_id     IN  NUMBER,
                p_organization_id  IN  NUMBER) IS
    ---------------------------------------------------------------------------
    -- Procedure for generate PA Interface. This procedure is generating only
    -- information not included in AP by COMEX.
    -- In this version, are generated information about ICMS, IPI, international
    -- Freight and international Insurance.
    ---------------------------------------------------------------------------
    v_operation_id           cll_f189_entry_operations.operation_id%TYPE;
    v_expenditure_type       po_distributions_all.expenditure_type%TYPE;
    v_flag_insere_frete      VARCHAR2(1) := NVL(fnd_profile.VALUE('CLL_F189_ADD_FRT_TO_IPI_FLAG'),'N');
    v_flag_insere_seguro     VARCHAR2(1) := NVL(fnd_profile.VALUE('CLL_F189_ADD_INSUR_TO_IPI_FLAG'),'N');
    v_proporcao              NUMBER      := 0;
    v_exp_cycle_end_day_code NUMBER      := 1;
    v_exp_cycle_end_date     DATE;
    v_ac_valor_ipi           NUMBER      := 0;
    v_ac_valor_icms          NUMBER      := 0;
    v_ac_valor_imp_tax       NUMBER      := 0;
    v_ac_valor_imp_exp       NUMBER      := 0;
    v_ac_valor_imp_frt       NUMBER      := 0;
    v_ac_valor_imp_ins       NUMBER      := 0;
    v_valor_ipi              NUMBER;
    v_valor_icms             NUMBER;
    v_valor_imp_tax          NUMBER;
    v_valor_imp_exp          NUMBER;
    v_valor_imp_frt          NUMBER;
    v_valor_imp_ins          NUMBER;
    v_qtde_dias              NUMBER;
    x_module_name                CONSTANT VARCHAR2(100) := 'CLL_F189_INTERFACE_PKG.PA';
    --
    v_fed_withholding_tax_flag    cll_f189_parameters.federal_withholding_tax_flag%TYPE; -- Enh 8633459 --

    CURSOR c1 IS
      SELECT ril.unit_price                                                     unit_price
            ,ril.quantity                                                       quantity
            ,ril.line_location_id                                               line_location_id
            ,ril.freight_ap_flag                                                freight_ap_flag
            ,ri.additional_tax                                                  additional_tax
            ,riu.diff_icms_flag                                                 diff_icms_flag
            ,ril.created_by                                                     created_by
            ,ril.creation_date                                                  creation_date
            ,ril.last_updated_by                                                last_updated_by
            ,ril.last_update_date                                               last_update_date
            ,NVL(ril.diff_icms_amount,0)                                        diff_icms_amount
            ,NVL(ril.other_expenses,0)                                          other_expenses
            ,DECODE(v_flag_insere_frete, 'Y', NVL(ril.freight_amount,0),0)      freight_amount
            ,DECODE(v_flag_insere_seguro, 'Y', NVL(ril.insurance_amount,0),0)   insurance_amount
            ,NVL(riu.icms_differed_type,'n')                                    icms_differed_type
            ,NVL(ril.icms_amount,0)                                             icms_amount
            ,NVL(ril.ipi_amount,0)                                              ipi_amount
            ,NVL(ril.pis_amount_recover,0)                                      pis_amount_recover
            ,NVL(ril.ipi_amount_recover,0)                                      ipi_amount_recover
            ,rit.import_icms_flag                                               import_icms_flag
            ,NVL(ril.icms_amount_recover,0)                                     icms_amount_recover
            ,NVL(ril.icms_st_amount,0)                                          icms_st_amount
            ,NVL(ril.icms_st_amount_recover,0)                                  icms_st_amount_recover
            ,NVL(ril.importation_tax_amount,0)                                  imp_tax_amount
            ,NVL(ril.importation_expense_func,0)                                imp_exp_amount
            ,NVL(ril.freight_internacional,0)                                   imp_frt_amount
            ,NVL(ril.importation_insurance_amount,0)                            imp_ins_amount
            -- Enh 8633459 - SSimoes - 19/08/2009 - Inicio
            -- ,NVL(rbv.inss_substitute_flag,'n')                                 inss_substitute_flag
            ,DECODE(NVL(v_fed_withholding_tax_flag,'C'),'I',
                        NVL(rit.inss_substitute_flag,'n'),
                        NVL(rbv.inss_substitute_flag,'n'))                      inss_substitute_flag
            -- Enh 8633459 - SSimoes - 19/08/2009 - Fim
            ,NVL(ri.inss_amount,0)                                              inss_amount
            ,rit.credit_debit_flag                                              credit_debit_flag
            ,NVL(rit.ipi_code_combination_id, 0)                                ipi_ccid
            ,NVL(rit.icms_code_combination_id, 0)                               icms_ccid
            ,NVL(rit.cr_code_combination_id, 0)                                 cr_ccid
            ,NVL(rit.import_tax_ccid, 0)                                        imp_tax_ccid
            ,NVL(rit.import_expense_ccid, 0)                                    imp_exp_ccid
            ,NVL(rit.import_freight_ccid, 0)                                    imp_frt_ccid
            ,NVL(rit.import_insurance_ccid, 0)                                  imp_ins_ccid
        FROM cll_f189_invoices ri,
             cll_f189_invoice_lines ril,
             cll_f189_item_utilizations riu,
             cll_f189_business_vendors rbv,
             cll_f189_fiscal_entities_all rfea,
             cll_f189_invoice_types rit
       WHERE ri.operation_id               = p_operation_id
         AND ri.organization_id            = p_organization_id
         AND rfea.entity_id                = ri.entity_id
         AND rbv.business_id               = rfea.business_vendor_id
         AND ril.invoice_id                = ri.invoice_id
         AND riu.utilization_id            = ril.utilization_id
         AND rit.invoice_type_id           = ri.invoice_type_id
         AND NVL(rit.project_flag, 'N')    = 'I'
         AND NVL(ri.pa_interface_flag,'N') = 'N'
         AND rit.return_customer_flag      = 'N';

    r1                   c1%ROWTYPE;

    ------------------------------------------
    -- Selecting physical quantities received
    -----------------------------------------
    CURSOR c2 IS
      SELECT rt.quantity                        quantity_received
            ,rt.transaction_date                transaction_date
            ,TO_CHAR(rt.transaction_date,'D')   transaction_date_weekday
            ,rt.currency_code                   currency_code
            ,pda.project_id                     project_id
            ,pda.task_id                        task_id
            ,pda.expenditure_type               expenditure_type
            ,nvl(mtp.wms_enabled_flag,'N')      wms_enabled_flag  -- Enh 7540459 - Amaciel
       FROM  mtl_parameters       mtp                             -- Enh 7540459 - Amaciel
            ,rcv_transactions     rt
            ,po_distributions_all pda
       WHERE mtp.organization_id    = rt.organization_id          -- Enh 7540459 - Amaciel
         AND rt.po_line_location_id = r1.line_location_id
         AND rt.transaction_type    = 'RECEIVE'
         AND rt.organization_id     = p_organization_id
         AND rt.shipment_header_id  IN (SELECT shipment_header_id
                                          FROM rcv_shipment_headers
                                         WHERE -- Enh 7540459 - Amaciel - Start
                                               --receipt_num     = TO_CHAR(v_operation_id))
                                               decode(wms_enabled_flag, 'Y', shipment_num,receipt_num)  =  TO_CHAR(v_operation_id))
                                               -- Enh 7540459 - Amaciel - End
         AND pda.po_distribution_id = rt.po_distribution_id;

    r2                   c2%ROWTYPE;

    -----------------------------------
    -- Selecting receiving information
    -----------------------------------
    CURSOR c3 IS
      SELECT 'RI'||TO_CHAR(reo.receive_date,'YYYY')
                 ||TO_CHAR(reo.receive_date,'MM')
                 ||TO_CHAR(reo.receive_date,'DD')             batch_name
            ,reo.gl_date                                      gl_date
            ,reo.receive_date                                 receive_date
-- Enh 7146913 - SSimoes - 17/06/2008 - Inicio
--            ,TO_CHAR(reo.receive_date,'D')                    receive_date_weekday
          , decode(TO_CHAR(reo.receive_date,'DY'),'SUN',1
                                                 ,'DOM',1
                                                 ,'MON',2
                                                 ,'SEG',2
                                                 ,'TUE',3
                                                 ,'TER',3
                                                 ,'WED',4
                                                 ,'QUA',4
                                                 ,'THU',5
                                                 ,'QUI',5
                                                 ,'FRI',6
                                                 ,'SEX',6
                                                 ,'SAT',7
                                                 ,'SAB',7) receive_date_weekday
-- Enh 7146913 - SSimoes - 17/06/2008 - Fim
        FROM cll_f189_entry_operations  reo
       WHERE reo.organization_id = p_organization_id
         AND reo.operation_id    = p_operation_id;

    r3                   c3%ROWTYPE;

    ----------------------------------------------------------------------------------
    -- Selecting organization name and the week day that the expenditure cycle begins
    ----------------------------------------------------------------------------------
    CURSOR c4 IS
      SELECT TO_NUMBER(pia.exp_cycle_start_day_code)         exp_cycle_start_day_code
            ,ood.organization_name                           organization_name
        FROM pa_implementations_all               pia
            ,org_organization_definitions         ood
       WHERE pia.org_id          = ood.operating_unit
         AND ood.organization_id = p_organization_id;

    r4                   c4%ROWTYPE;

    -----------------------------------
    -- Selecting project information --
    -----------------------------------
    CURSOR c5 IS
      SELECT ppa.project_currency_code                  project_currency_code
            ,ppa.org_id                                 org_id
            ,ppa.segment1                               project_name
            ,pt.task_number                             task_number
        FROM pa_projects_all    ppa
            ,pa_tasks           pt
       WHERE ppa.project_id = r2.project_id
         AND pt.project_id  = r2.project_id
         AND pt.task_id     = r2.task_id;

    r5                   c5%ROWTYPE;

    ------------------------------------
    -- Selecting supplier information --
    ------------------------------------
    CURSOR c6 IS
      SELECT pha.vendor_id        vendor_id
            ,pv.segment1          vendor_number
        FROM po_distributions_all pda
            ,po_headers_all       pha
            ,po_vendors           pv
       WHERE pda.project_id   = r2.project_id
         AND pha.po_header_id = pda.po_header_id
         AND pv.vendor_id     = pha.vendor_id;

    r6                   c6%ROWTYPE;

    --------------------------------------------------
    -- Selecting receipt num for reversion receipt --
    --------------------------------------------------
    CURSOR c7 IS
      SELECT operation_id
        FROM cll_f189_invoices ri1
       WHERE EXISTS (SELECT 'a'
                       FROM cll_f189_invoices ri2
                      WHERE ri2.invoice_parent_id = ri1.invoice_id
                        AND ri2.organization_id   = p_organization_id
                        AND ri2.operation_id      = p_operation_id);

    r7                   c7%ROWTYPE;

    -------------------------------------------------------------------------
    -- Selecting physical quantity received by line location and receipt num
    -------------------------------------------------------------------------
    CURSOR c8 IS
      SELECT SUM(rt.quantity)                       total_quantity_received
           , nvl(mtp.wms_enabled_flag,'N')          wms_enabled_flag     -- Enh 7540459 - Amaciel
        FROM  mtl_parameters      mtp                                    -- Enh 7540459 - Amaciel
            ,rcv_transactions     rt
            ,po_distributions_all pda
       WHERE mtp.organization_id    = rt.organization_id                 -- Enh 7540459 - Amaciel
         AND rt.po_line_location_id = r1.line_location_id
         AND rt.transaction_type    = 'RECEIVE'
         AND rt.organization_id     = p_organization_id
         AND rt.shipment_header_id  IN (SELECT shipment_header_id
                                          FROM rcv_shipment_headers
                                         WHERE -- Enh 7540459 - Amaciel - Start
                                              --receipt_num     = TO_CHAR(v_operation_id))
                                              decode(wms_enabled_flag, 'Y', shipment_num,receipt_num) =  TO_CHAR(v_operation_id))
                                              -- Enh 7540459 - Amaciel - End
         AND pda.po_distribution_id = rt.po_distribution_id;

    r8                   c8%ROWTYPE;



  BEGIN

-- Enh 8633459 - SSimoes - 19/08/2009 - Inicio
    BEGIN
      SELECT NVL(rp.federal_withholding_tax_flag,'C')
        INTO v_fed_withholding_tax_flag
        FROM cll_f189_parameters rp
       WHERE rp.organization_id = p_organization_id;
    EXCEPTION
         WHEN others THEN
              v_fed_withholding_tax_flag := NULL;
    END;
-- Enh 8633459 - SSimoes - 19/08/2009 - Fim


    OPEN c1;
    FETCH c1 INTO r1;
    IF c1%FOUND THEN
      OPEN c3;
      FETCH c3 INTO r3;
      CLOSE c3;

      ---------------------------------------------
      -- Final date for current expenditure cycle
      ---------------------------------------------
      OPEN c4;
      FETCH c4 INTO r4;
      IF r4.exp_cycle_start_day_code = 1 THEN
        v_exp_cycle_end_day_code := 7;
      ELSE
        v_exp_cycle_end_day_code := r4.exp_cycle_start_day_code - 1;
      END IF;
      IF v_exp_cycle_end_day_code >= r3.receive_date_weekday THEN
        v_qtde_dias := v_exp_cycle_end_day_code - r3.receive_date_weekday;
      ELSE
        v_qtde_dias := 7 + v_exp_cycle_end_day_code - r3.receive_date_weekday;
      END IF;
      v_exp_cycle_end_date := r3.receive_date + v_qtde_dias;
      CLOSE c4;

      LOOP

        IF r1.credit_debit_flag = 'C' THEN
          OPEN c7;
          FETCH c7 INTO r7;
          IF c7%NOTFOUND THEN
            raise_application_error(-20555, x_module_name||' - ERROR:  '||SQLERRM||' Not found Reverted Invoice information.');
          END IF;
          CLOSE c7;
          v_operation_id := r7.operation_id;
        ELSE
          v_operation_id := p_operation_id;
        END IF;

        OPEN c8;
        FETCH c8 INTO r8;
        IF c8%NOTFOUND THEN
          raise_application_error(-20556, x_module_name||' - ERROR:  '||SQLERRM||' Not found RCV_TRANSACTION information.');
        END IF;

        OPEN c2;
        FETCH c2 INTO r2;
        IF c2%NOTFOUND THEN
          raise_application_error(-20557, x_module_name||' - ERROR:  '||SQLERRM|| ' Not found RCV_SHIPMENT_LINES information.');
        END IF;

        v_ac_valor_ipi       := 0;
        v_ac_valor_icms      := 0;
        v_ac_valor_imp_tax   := 0;
        v_ac_valor_imp_exp   := 0;
        v_ac_valor_imp_frt   := 0;
        v_ac_valor_imp_ins   := 0;

        LOOP
          v_proporcao        := r2.quantity_received / r8.total_quantity_received;
          IF r1.credit_debit_flag = 'C' THEN
            v_proporcao := -v_proporcao;
          END IF;
          v_valor_ipi        := cll_f189_format_mask_pkg.currency((r1.ipi_amount - r1.ipi_amount_recover) * v_proporcao);
          v_valor_icms       := cll_f189_format_mask_pkg.currency((r1.icms_amount - r1.icms_amount_recover) * v_proporcao);
          v_valor_imp_tax    := cll_f189_format_mask_pkg.currency(r1.imp_tax_amount * v_proporcao);
          v_valor_imp_exp    := cll_f189_format_mask_pkg.currency(r1.imp_exp_amount * v_proporcao);
          v_valor_imp_frt    := cll_f189_format_mask_pkg.currency(r1.imp_frt_amount * v_proporcao);
          v_valor_imp_ins    := cll_f189_format_mask_pkg.currency(r1.imp_ins_amount * v_proporcao);
          v_expenditure_type := r2.expenditure_type;

          OPEN c5;
          FETCH c5 INTO r5;
          CLOSE c5;

          OPEN c6;
          FETCH c6 INTO r6;
          CLOSE c6;

          FETCH c2 INTO r2;
          IF c2%NOTFOUND THEN

            IF r1.ipi_amount - r1.ipi_amount_recover > 0 AND
               v_expenditure_type IS NOT NULL THEN
              IF r1.credit_debit_flag = 'C' THEN
                v_valor_ipi := -r1.ipi_amount + r1.ipi_amount_recover - v_ac_valor_ipi;
              ELSE
                v_valor_ipi := r1.ipi_amount - r1.ipi_amount_recover - v_ac_valor_ipi;
              END IF;
              INSERT INTO pa_transaction_interface_all
                         (transaction_source
                         ,batch_name
                         ,expenditure_ending_date
                         ,organization_name
                         ,expenditure_item_date
                         ,project_number
                         ,task_number
                         ,expenditure_type
                         ,dr_code_combination_id
                         ,cr_code_combination_id
                         ,quantity
                         ,raw_cost
                         ,acct_raw_cost
                         ,denom_burdened_cost
                         ,denom_raw_cost
                         ,expenditure_comment
                         ,transaction_status_code
                         ,orig_transaction_reference
                         ,org_id
                         ,gl_date
                         ,system_linkage
                         ,user_transaction_source
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_update_date
                         ,project_currency_code
                         ,project_rate_date
                         ,vendor_number)
                          VALUES
                         ('CLL F189 INTEGRATED RCV' -- transaction_source
                         ,r3.batch_name             -- batch_name
                         ,v_exp_cycle_end_date      -- expenditure_ending_date
                         ,r4.organization_name      -- organization_name
                         ,r3.receive_date           -- expenditure_item_date
                         ,r5.project_name           -- project_number
                         ,r5.task_number            -- task_number
                         ,v_expenditure_type        -- expenditure_type
                         ,r1.ipi_ccid               -- dr_code_combination_id
                         ,r1.cr_ccid                -- cr_code_combination_id
                         ,v_valor_ipi               -- quantity
                         ,v_valor_ipi               -- raw_cost
                         ,v_valor_ipi               -- acct_raw_cost
                         ,v_valor_ipi               -- denom_burdened_cost
                         ,v_valor_ipi               -- denom_raw_cost
                         ,'IPI'                     -- expenditure_comment
                         ,'P'                       -- transaction_status_code
                         ,'RI'                      -- orig_transaction_reference
                         ,r5.org_id                 -- org_id
                         ,r3.gl_date                -- gl_date
                         ,'VI'                      -- system_linkage
                         ,'CLL F189 INTEGRATED RCV' -- user_transaction_source
                         ,r1.created_by             -- created_by
                         ,r1.creation_date          -- creation_date
                         ,r1.last_updated_by        -- last_updated_by
                         ,r1.last_update_date       -- last_update_date
                         ,r5.project_currency_code  -- project_currency_code
                         ,r3.receive_date           -- project_rate_date
                         ,r6.vendor_number);        -- vendor_number
            END IF;

            IF r1.icms_amount - r1.icms_amount_recover > 0 AND
               v_expenditure_type IS NOT NULL THEN
              IF r1.credit_debit_flag = 'C' THEN
                v_valor_icms := -r1.icms_amount + r1.icms_amount_recover - v_ac_valor_icms;
              ELSE
                v_valor_icms := r1.icms_amount - r1.icms_amount_recover - v_ac_valor_icms;
              END IF;
              INSERT INTO pa_transaction_interface_all
                         (transaction_source
                         ,batch_name
                         ,expenditure_ending_date
                         ,organization_name
                         ,expenditure_item_date
                         ,project_number
                         ,task_number
                         ,expenditure_type
                         ,dr_code_combination_id
                         ,cr_code_combination_id
                         ,quantity
                         ,raw_cost
                         ,acct_raw_cost
                         ,denom_burdened_cost
                         ,denom_raw_cost
                         ,expenditure_comment
                         ,transaction_status_code
                         ,orig_transaction_reference
                         ,org_id
                         ,gl_date
                         ,system_linkage
                         ,user_transaction_source
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_update_date
                         ,project_currency_code
                         ,project_rate_date
                         ,vendor_number)
                          VALUES
                         ('CLL F189 INTEGRATED RCV'  -- transaction_source
                         ,r3.batch_name              -- batch_name
                         ,v_exp_cycle_end_date       -- expenditure_ending_date
                         ,r4.organization_name       -- organization_name
                         ,r3.receive_date            -- expenditure_item_date
                         ,r5.project_name            -- project_number
                         ,r5.task_number             -- task_number
                         ,v_expenditure_type         -- expenditure_type
                         ,r1.icms_ccid               -- dr_code_combination_id
                         ,r1.cr_ccid                 -- cr_code_combination_id
                         ,v_valor_icms               -- quantity
                         ,v_valor_icms               -- raw_cost
                         ,v_valor_icms               -- acct_raw_cost
                         ,v_valor_icms               -- denom_burdened_cost
                         ,v_valor_icms               -- denom_raw_cost
                         ,'ICMS'                     -- expenditure_comment
                         ,'P'                        -- transaction_status_code
                         ,'RI'                       -- orig_transaction_reference
                         ,r5.org_id                  -- org_id
                         ,r3.gl_date                 -- gl_date
                         ,'VI'                       -- system_linkage
                         ,'CLL F189 INTEGRATED RCV'  -- user_transaction_source
                         ,r1.created_by              -- created_by
                         ,r1.creation_date           -- creation_date
                         ,r1.last_updated_by         -- last_updated_by
                         ,r1.last_update_date        -- last_update_date
                         ,r5.project_currency_code   -- project_currency_code
                         ,r3.receive_date            -- project_rate_date
                         ,r6.vendor_number);         -- vendor_number
            END IF;

            IF r1.imp_tax_amount > 0 AND
               v_expenditure_type IS NOT NULL THEN
              IF r1.credit_debit_flag = 'C' THEN
                v_valor_imp_tax := -r1.imp_tax_amount - v_ac_valor_imp_tax;
              ELSE
                v_valor_imp_tax := r1.imp_tax_amount - v_ac_valor_imp_tax;
              END IF;
              INSERT INTO pa_transaction_interface_all
                         (transaction_source
                         ,batch_name
                         ,expenditure_ending_date
                         ,organization_name
                         ,expenditure_item_date
                         ,project_number
                         ,task_number
                         ,expenditure_type
                         ,dr_code_combination_id
                         ,cr_code_combination_id
                         ,quantity
                         ,raw_cost
                         ,acct_raw_cost
                         ,denom_burdened_cost
                         ,denom_raw_cost
                         ,expenditure_comment
                         ,transaction_status_code
                         ,orig_transaction_reference
                         ,org_id
                         ,gl_date
                         ,system_linkage
                         ,user_transaction_source
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_update_date
                         ,project_currency_code
                         ,project_rate_date
                         ,vendor_number)
                          VALUES
                         ('CLL F189 INTEGRATED RCV'-- transaction_source
                         ,r3.batch_name            -- batch_name
                         ,v_exp_cycle_end_date     -- expenditure_ending_date
                         ,r4.organization_name     -- organization_name
                         ,r3.receive_date          -- expenditure_item_date
                         ,r5.project_name          -- project_number
                         ,r5.task_number           -- task_number
                         ,v_expenditure_type       -- expenditure_type
                         ,r1.imp_tax_ccid          -- dr_code_combination_id
                         ,r1.cr_ccid               -- cr_code_combination_id
                         ,v_ac_valor_imp_tax       -- quantity
                         ,v_ac_valor_imp_tax       -- raw_cost
                         ,v_ac_valor_imp_tax       -- acct_raw_cost
                         ,v_ac_valor_imp_tax       -- denom_burdened_cost
                         ,v_ac_valor_imp_tax       -- denom_raw_cost
                         ,'II'                     -- expenditure_comment
                         ,'P'                      -- transaction_status_code
                         ,'RI'                     -- orig_transaction_reference
                         ,r5.org_id                -- org_id
                         ,r3.gl_date               -- gl_date
                         ,'VI'                     -- system_linkage
                         ,'CLL F189 INTEGRATED RCV' -- user_transaction_source
                         ,r1.created_by            -- created_by
                         ,r1.creation_date         -- creation_date
                         ,r1.last_updated_by       -- last_updated_by
                         ,r1.last_update_date      -- last_update_date
                         ,r5.project_currency_code -- project_currency_code
                         ,r3.receive_date          -- project_rate_date
                         ,r6.vendor_number);       -- vendor_number
            END IF;

            IF r1.imp_exp_amount > 0 AND
               v_expenditure_type IS NOT NULL THEN
              IF r1.credit_debit_flag = 'C' THEN
                v_valor_imp_exp := -r1.imp_exp_amount - v_ac_valor_imp_exp;
              ELSE
                v_valor_imp_exp := r1.imp_exp_amount - v_ac_valor_imp_exp;
              END IF;
              INSERT INTO pa_transaction_interface_all
                         (transaction_source
                         ,batch_name
                         ,expenditure_ending_date
                         ,organization_name
                         ,expenditure_item_date
                         ,project_number
                         ,task_number
                         ,expenditure_type
                         ,dr_code_combination_id
                         ,cr_code_combination_id
                         ,quantity
                         ,raw_cost
                         ,acct_raw_cost
                         ,denom_burdened_cost
                         ,denom_raw_cost
                         ,expenditure_comment
                         ,transaction_status_code
                         ,orig_transaction_reference
                         ,org_id
                         ,gl_date
                         ,system_linkage
                         ,user_transaction_source
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_update_date
                         ,project_currency_code
                         ,project_rate_date
                         ,vendor_number)
                          VALUES
                         ('CLL F189 INTEGRATED RCV' -- transaction_source
                         ,r3.batch_name             -- batch_name
                         ,v_exp_cycle_end_date      -- expenditure_ending_date
                         ,r4.organization_name      -- organization_name
                         ,r3.receive_date           -- expenditure_item_date
                         ,r5.project_name           -- project_number
                         ,r5.task_number            -- task_number
                         ,v_expenditure_type        -- expenditure_type
                         ,r1.imp_exp_ccid           -- dr_code_combination_id
                         ,r1.cr_ccid                -- cr_code_combination_id
                         ,v_valor_imp_exp           -- quantity
                         ,v_valor_imp_exp           -- raw_cost
                         ,v_valor_imp_exp           -- acct_raw_cost
                         ,v_valor_imp_exp           -- denom_burdened_cost
                         ,v_valor_imp_exp           -- denom_raw_cost
                         ,fnd_message.get_string('CLL', 'CLL_F189_OTHER_EXP')
                         ,'P'                       -- transaction_status_code
                         ,'RI'                      -- orig_transaction_reference
                         ,r5.org_id                 -- org_id
                         ,r3.gl_date                -- gl_date
                         ,'VI'                      -- system_linkage
                         ,'CLL F189 INTEGRATED RCV' -- user_transaction_source
                         ,r1.created_by             -- created_by
                         ,r1.creation_date          -- creation_date
                         ,r1.last_updated_by        -- last_updated_by
                         ,r1.last_update_date       -- last_update_date
                         ,r5.project_currency_code  -- project_currency_code
                         ,r3.receive_date           -- project_rate_date
                         ,r6.vendor_number);        -- vendor_number
            END IF;

            IF r1.imp_frt_amount  >  0 AND
               v_expenditure_type IS NOT NULL AND
               r1.freight_ap_flag = 'N' THEN
              IF r1.credit_debit_flag = 'C' THEN
                v_valor_imp_frt := -r1.imp_frt_amount - v_ac_valor_imp_frt;
              ELSE
                v_valor_imp_frt := r1.imp_frt_amount - v_ac_valor_imp_frt;
              END IF;
              INSERT INTO pa_transaction_interface_all
                         (transaction_source
                         ,batch_name
                         ,expenditure_ending_date
                         ,organization_name
                         ,expenditure_item_date
                         ,project_number
                         ,task_number
                         ,expenditure_type
                         ,dr_code_combination_id
                         ,cr_code_combination_id
                         ,quantity
                         ,raw_cost
                         ,acct_raw_cost
                         ,denom_burdened_cost
                         ,denom_raw_cost
                         ,expenditure_comment
                         ,transaction_status_code
                         ,orig_transaction_reference
                         ,org_id
                         ,gl_date
                         ,system_linkage
                         ,user_transaction_source
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_update_date
                         ,project_currency_code
                         ,project_rate_date
                         ,vendor_number)
                          VALUES
                         ('CLL F189 INTEGRATED RCV'   -- transaction_source
                         ,r3.batch_name               -- batch_name
                         ,v_exp_cycle_end_date        -- expenditure_ending_date
                         ,r4.organization_name        -- organization_name
                         ,r3.receive_date             -- expenditure_item_date
                         ,r5.project_name             -- project_number
                         ,r5.task_number              -- task_number
                         ,v_expenditure_type          -- expenditure_type
                         ,r1.imp_frt_ccid             -- dr_code_combination_id
                         ,r1.cr_ccid                  -- cr_code_combination_id
                         ,v_valor_imp_frt             -- quantity
                         ,v_valor_imp_frt             -- raw_cost
                         ,v_valor_imp_frt             -- acct_raw_cost
                         ,v_valor_imp_frt             -- denom_burdened_cost
                         ,v_valor_imp_frt             -- denom_raw_cost
                         ,fnd_message.get_string('CLL', 'CLL_F189_INT_FREIGHT')
                         ,'P'                         -- transaction_status_code
                         ,'RI'                        -- orig_transaction_reference
                         ,r5.org_id                   -- org_id
                         ,r3.gl_date                  -- gl_date
                         ,'VI'                        -- system_linkage
                         ,'CLL F189 INTEGRATED RCV'   -- user_transaction_source
                         ,r1.created_by               -- created_by
                         ,r1.creation_date            -- creation_date
                         ,r1.last_updated_by          -- last_updated_by
                         ,r1.last_update_date         -- last_update_date
                         ,r5.project_currency_code    -- project_currency_code
                         ,r3.receive_date             -- project_rate_date
                         ,r6.vendor_number);          -- vendor_number
            END IF;

            IF r1.imp_ins_amount > 0 AND
               v_expenditure_type IS NOT NULL THEN
              IF r1.credit_debit_flag = 'C' THEN
                v_valor_imp_ins := -r1.imp_ins_amount - v_ac_valor_imp_ins;
              ELSE
                v_valor_imp_ins := r1.imp_ins_amount - v_ac_valor_imp_ins;
              END IF;
              INSERT INTO pa_transaction_interface_all
                         (transaction_source
                         ,batch_name
                         ,expenditure_ending_date
                         ,organization_name
                         ,expenditure_item_date
                         ,project_number
                         ,task_number
                         ,expenditure_type
                         ,dr_code_combination_id
                         ,cr_code_combination_id
                         ,quantity
                         ,raw_cost
                         ,acct_raw_cost
                         ,denom_burdened_cost
                         ,denom_raw_cost
                         ,expenditure_comment
                         ,transaction_status_code
                         ,orig_transaction_reference
                         ,org_id
                         ,gl_date
                         ,system_linkage
                         ,user_transaction_source
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_update_date
                         ,project_currency_code
                         ,project_rate_date
                         ,vendor_number)
                          VALUES
                         ('CLL F189 INTEGRATED RCV'    -- transaction_source
                         ,r3.batch_name                -- batch_name
                         ,v_exp_cycle_end_date         -- expenditure_ending_date
                         ,r4.organization_name         -- organization_name
                         ,r3.receive_date              -- expenditure_item_date
                         ,r5.project_name              -- project_number
                         ,r5.task_number               -- task_number
                         ,v_expenditure_type           -- expenditure_type
                         ,r1.imp_ins_ccid              -- dr_code_combination_id
                         ,r1.cr_ccid                   -- cr_code_combination_id
                         ,v_valor_imp_ins              -- quantity
                         ,v_valor_imp_ins              -- raw_cost
                         ,v_valor_imp_ins              -- acct_raw_cost
                         ,v_valor_imp_ins              -- denom_burdened_cost
                         ,v_valor_imp_ins              -- denom_raw_cost
                         ,fnd_message.get_string('CLL', 'CLL_F189_INT_INSURANCE')
                         ,'P'                          -- transaction_status_code
                         ,'RI'                         -- orig_transaction_reference
                         ,r5.org_id                    -- org_id
                         ,r3.gl_date                   -- gl_date
                         ,'VI'                         -- system_linkage
                         ,'CLL F189 INTEGRATED RCV'    -- user_transaction_source
                         ,r1.created_by                -- created_by
                         ,r1.creation_date             -- creation_date
                         ,r1.last_updated_by           -- last_updated_by
                         ,r1.last_update_date          -- last_update_date
                         ,r5.project_currency_code     -- project_currency_code
                         ,r3.receive_date              -- project_rate_date
                         ,r6.vendor_number);           -- vendor_number
            END IF;

            EXIT;

          ELSE

            IF r1.ipi_amount - r1.ipi_amount_recover > 0 AND
               v_expenditure_type IS NOT NULL THEN
              INSERT INTO pa_transaction_interface_all
                         (transaction_source
                         ,batch_name
                         ,expenditure_ending_date
                         ,organization_name
                         ,expenditure_item_date
                         ,project_number
                         ,task_number
                         ,expenditure_type
                         ,dr_code_combination_id
                         ,cr_code_combination_id
                         ,quantity
                         ,raw_cost
                         ,acct_raw_cost
                         ,denom_burdened_cost
                         ,denom_raw_cost
                         ,expenditure_comment
                         ,transaction_status_code
                         ,orig_transaction_reference
                         ,org_id
                         ,gl_date
                         ,system_linkage
                         ,user_transaction_source
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_update_date
                         ,project_currency_code
                         ,project_rate_date
                         ,vendor_number)
                          VALUES
                         ('CLL F189 INTEGRATED RCV'   -- transaction_source
                         ,r3.batch_name               -- batch_name
                         ,v_exp_cycle_end_date        -- expenditure_ending_date
                         ,r4.organization_name        -- organization_name
                         ,r3.receive_date             -- expenditure_item_date
                         ,r5.project_name             -- project_number
                         ,r5.task_number              -- task_number
                         ,v_expenditure_type          -- expenditure_type
                         ,r1.ipi_ccid                 -- dr_code_combination_id
                         ,r1.cr_ccid                  -- cr_code_combination_id
                         ,v_valor_ipi                 -- quantity
                         ,v_valor_ipi                 -- raw_cost
                         ,v_valor_ipi                 -- acct_raw_cost
                         ,v_valor_ipi                 -- denom_burdened_cost
                         ,v_valor_ipi                 -- denom_raw_cost
                         ,'IPI'                       -- expenditure_comment
                         ,'P'                         -- transaction_status_code
                         ,'RI'                        -- orig_transaction_reference
                         ,r5.org_id                   -- org_id
                         ,r3.gl_date                  -- gl_date
                         ,'VI'                        -- system_linkage
                         ,'CLL F189 INTEGRATED RCV'   -- user_transaction_source
                         ,r1.created_by               -- created_by
                         ,r1.creation_date            -- creation_date
                         ,r1.last_updated_by          -- last_updated_by
                         ,r1.last_update_date         -- last_update_date
                         ,r5.project_currency_code    -- project_currency_code
                         ,r3.receive_date             -- project_rate_date
                         ,r6.vendor_number);          -- vendor_number

              v_ac_valor_ipi := v_ac_valor_ipi + v_valor_ipi;

            END IF;

            IF r1.icms_amount - r1.icms_amount_recover > 0 AND
               v_expenditure_type IS NOT NULL THEN
              INSERT INTO pa_transaction_interface_all
                         (transaction_source
                         ,batch_name
                         ,expenditure_ending_date
                         ,organization_name
                         ,expenditure_item_date
                         ,project_number
                         ,task_number
                         ,expenditure_type
                         ,dr_code_combination_id
                         ,cr_code_combination_id
                         ,quantity
                         ,raw_cost
                         ,acct_raw_cost
                         ,denom_burdened_cost
                         ,denom_raw_cost
                         ,expenditure_comment
                         ,transaction_status_code
                         ,orig_transaction_reference
                         ,org_id
                         ,gl_date
                         ,system_linkage
                         ,user_transaction_source
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_update_date
                         ,project_currency_code
                         ,project_rate_date
                         ,vendor_number)
                          VALUES
                         ('CLL F189 INTEGRATED RCV'   -- transaction_source
                         ,r3.batch_name               -- batch_name
                         ,v_exp_cycle_end_date        -- expenditure_ending_date
                         ,r4.organization_name        -- organization_name
                         ,r3.receive_date             -- expenditure_item_date
                         ,r5.project_name             -- project_number
                         ,r5.task_number              -- task_number
                         ,v_expenditure_type          -- expenditure_type
                         ,r1.icms_ccid                -- dr_code_combination_id
                         ,r1.cr_ccid                  -- cr_code_combination_id
                         ,v_valor_icms                -- quantity
                         ,v_valor_icms                -- raw_cost
                         ,v_valor_icms                -- acct_raw_cost
                         ,v_valor_icms                -- denom_burdened_cost
                         ,v_valor_icms                -- denom_raw_cost
                         ,'ICMS'                      -- expenditure_comment
                         ,'P'                         -- transaction_status_code
                         ,'RI'                        -- orig_transaction_reference
                         ,r5.org_id                   -- org_id
                         ,r3.gl_date                  -- gl_date
                         ,'VI'                        -- system_linkage
                         ,'CLL F189 INTEGRATED RCV'   -- user_transaction_source
                         ,r1.created_by               -- created_by
                         ,r1.creation_date            -- creation_date
                         ,r1.last_updated_by          -- last_updated_by
                         ,r1.last_update_date         -- last_update_date
                         ,r5.project_currency_code    -- project_currency_code
                         ,r3.receive_date             -- project_rate_date
                         ,r6.vendor_number);          -- vendor_number

              v_ac_valor_icms := v_ac_valor_icms + v_valor_icms;

            END IF;

            IF r1.imp_tax_amount > 0 AND
              v_expenditure_type IS NOT NULL THEN
              --
              INSERT INTO pa_transaction_interface_all (
                transaction_source,
                batch_name,
                expenditure_ending_date,
                organization_name,
                expenditure_item_date,
                project_number,
                task_number,
                expenditure_type,
                dr_code_combination_id,
                cr_code_combination_id,
                quantity,
                raw_cost,
                acct_raw_cost,
                denom_burdened_cost,
                denom_raw_cost,
                expenditure_comment,
                transaction_status_code,
                orig_transaction_reference,
                org_id,
                gl_date,
                system_linkage,
                user_transaction_source,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                project_currency_code,
                project_rate_date,
                vendor_number)
                --
              VALUES (
                'CLL F189 INTEGRATED RCV', -- transaction_source
                r3.batch_name,            -- batch_name
                v_exp_cycle_end_date,     -- expenditure_ending_date
                r4.organization_name,     -- organization_name
                r3.receive_date,          -- expenditure_item_date
                r5.project_name,          -- project_number
                r5.task_number,           -- task_number
                v_expenditure_type,       -- expenditure_type
                r1.imp_tax_ccid,          -- dr_code_combination_id
                r1.cr_ccid,               -- cr_code_combination_id
                v_valor_imp_tax,          -- quantity
                v_valor_imp_tax,          -- raw_cost
                v_valor_imp_tax,          -- acct_raw_cost
                v_valor_imp_tax,          -- denom_burdened_cost
                v_valor_imp_tax,          -- denom_raw_cost
                'II',                     -- expenditure_comment
                'P',                      -- transaction_status_code
                'RI',                     -- orig_transaction_reference
                r5.org_id,                -- org_id
                r3.gl_date,               -- gl_date
                'VI',                     -- system_linkage
                'CLL F189 INTEGRATED RCV', -- user_transaction_source
                r1.created_by,            -- created_by
                r1.creation_date,         -- creation_date
                r1.last_updated_by,       -- last_updated_by
                r1.last_update_date,      -- last_update_date
                r5.project_currency_code, -- project_currency_code
                r3.receive_date,          -- project_rate_date
                r6.vendor_number);        -- vendor_number
              --
              v_ac_valor_imp_tax := v_ac_valor_imp_tax  + v_valor_imp_tax;
              --
            END IF;

            IF r1.imp_exp_amount > 0 AND
              v_expenditure_type IS NOT NULL THEN
              --
              INSERT INTO pa_transaction_interface_all (
                transaction_source,
                batch_name,
                expenditure_ending_date,
                organization_name,
                expenditure_item_date,
                project_number,
                task_number,
                expenditure_type,
                dr_code_combination_id,
                cr_code_combination_id,
                quantity,
                raw_cost,
                acct_raw_cost,
                denom_burdened_cost,
                denom_raw_cost,
                expenditure_comment,
                transaction_status_code,
                orig_transaction_reference,
                org_id,
                gl_date,
                system_linkage,
                user_transaction_source,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                project_currency_code,
                project_rate_date,
                vendor_number)
                --
              VALUES (
                'CLL F189 INTEGRATED RCV', -- transaction_source
                r3.batch_name,            -- batch_name
                v_exp_cycle_end_date,     -- expenditure_ending_date
                r4.organization_name,     -- organization_name
                r3.receive_date,          -- expenditure_item_date
                r5.project_name,          -- project_number
                r5.task_number,           -- task_number
                v_expenditure_type,       -- expenditure_type
                r1.imp_exp_ccid,          -- dr_code_combination_id
                r1.cr_ccid,               -- cr_code_combination_id
                v_valor_imp_exp,          -- quantity
                v_valor_imp_exp,          -- raw_cost
                v_valor_imp_exp,          -- acct_raw_cost
                v_valor_imp_exp,          -- denom_burdened_cost
                v_valor_imp_exp,          -- denom_raw_cost
                fnd_message.get_string('CLL', 'CLL_F189_OTHER_EXP'),
                'P',                      -- transaction_status_code
                'RI',                     -- orig_transaction_reference
                r5.org_id,                -- org_id
                r3.gl_date,               -- gl_date
                'VI',                     -- system_linkage
                'CLL F189 INTEGRATED RCV', -- user_transaction_source
                r1.created_by,            -- created_by
                r1.creation_date,         -- creation_date
                r1.last_updated_by,       -- last_updated_by
                r1.last_update_date,      -- last_update_date
                r5.project_currency_code, -- project_currency_code
                r3.receive_date,          -- project_rate_date
                r6.vendor_number);        -- vendor_number
              --
              v_ac_valor_imp_exp := v_ac_valor_imp_exp + v_valor_imp_exp;
              --
            END IF;
            --
            IF r1.imp_frt_amount  >  0 AND
              v_expenditure_type IS NOT NULL AND
              r1.freight_ap_flag = 'N' THEN
              --
              INSERT INTO pa_transaction_interface_all (
                transaction_source,
                batch_name,
                expenditure_ending_date,
                organization_name,
                expenditure_item_date,
                project_number,
                task_number,
                expenditure_type,
                dr_code_combination_id,
                cr_code_combination_id,
                quantity,
                raw_cost,
                acct_raw_cost,
                denom_burdened_cost,
                denom_raw_cost,
                expenditure_comment,
                transaction_status_code,
                orig_transaction_reference,
                org_id,
                gl_date,
                system_linkage,
                user_transaction_source,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                project_currency_code,
                project_rate_date,
                vendor_number)
                --
              VALUES (
                'CLL F189 INTEGRATED RCV', -- transaction_source
                r3.batch_name,            -- batch_name
                v_exp_cycle_end_date,     -- expenditure_ending_date
                r4.organization_name,     -- organization_name
                r3.receive_date,          -- expenditure_item_date
                r5.project_name,          -- project_number
                r5.task_number,           -- task_number
                v_expenditure_type,       -- expenditure_type
                r1.imp_frt_ccid,          -- dr_code_combination_id
                r1.cr_ccid,               -- cr_code_combination_id
                v_valor_imp_frt,          -- quantity
                v_valor_imp_frt,          -- raw_cost
                v_valor_imp_frt,          -- acct_raw_cost
                v_valor_imp_frt,          -- denom_burdened_cost
                v_valor_imp_frt,          -- denom_raw_cost
                fnd_message.get_string('CLL', 'CLL_F189_INT_FREIGHT'),
                'P',                      -- transaction_status_code
                'RI',                     -- orig_transaction_reference
                r5.org_id,                -- org_id
                r3.gl_date,               -- gl_date
                'VI',                     -- system_linkage
                'CLL F189 INTEGRATED RCV',  -- user_transaction_source
                r1.created_by,            -- created_by
                r1.creation_date,         -- creation_date
                r1.last_updated_by,       -- last_updated_by
                r1.last_update_date,      -- last_update_date
                r5.project_currency_code, -- project_currency_code
                r3.receive_date,          -- project_rate_date
                r6.vendor_number);        -- vendor_number
              --
              v_ac_valor_imp_frt  := v_ac_valor_imp_frt  + v_valor_imp_frt;
              --
            END IF;
            --
            IF r1.imp_ins_amount > 0 AND
              v_expenditure_type IS NOT NULL THEN
              --
              INSERT INTO pa_transaction_interface_all (
                transaction_source,
                batch_name,
                expenditure_ending_date,
                organization_name,
                expenditure_item_date,
                project_number,
                task_number,
                expenditure_type,
                dr_code_combination_id,
                cr_code_combination_id,
                quantity,
                raw_cost,
                acct_raw_cost,
                denom_burdened_cost,
                denom_raw_cost,
                expenditure_comment,
                transaction_status_code,
                orig_transaction_reference,
                org_id,
                gl_date,
                system_linkage,
                user_transaction_source,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                project_currency_code,
                project_rate_date,
                vendor_number)
                --
              VALUES (
                'CLL F189 INTEGRATED RCV',  -- transaction_source
                r3.batch_name,            -- batch_name
                v_exp_cycle_end_date,     -- expenditure_ending_date
                r4.organization_name,     -- organization_name
                r3.receive_date,          -- expenditure_item_date
                r5.project_name,          -- project_number
                r5.task_number,           -- task_number
                v_expenditure_type,       -- expenditure_type
                r1.imp_ins_ccid,          -- dr_code_combination_id
                r1.cr_ccid,               -- cr_code_combination_id
                v_valor_imp_ins,          -- quantity
                v_valor_imp_ins,          -- raw_cost
                v_valor_imp_ins,          -- acct_raw_cost
                v_valor_imp_ins,          -- denom_burdened_cost
                v_valor_imp_ins,          -- denom_raw_cost
                fnd_message.get_string('CLL', 'CLL_F189_INT_INSURANCE'),
                'P',                      -- transaction_status_code
                'RI',                     -- orig_transaction_reference
                r5.org_id,                -- org_id
                r3.gl_date,               -- gl_date
                'VI',                     -- system_linkage
                'CLL F189 INTEGRATED RCV',  -- user_transaction_source
                r1.created_by,            -- created_by
                r1.creation_date,         -- creation_date
                r1.last_updated_by,       -- last_updated_by
                r1.last_update_date,      -- last_update_date
                r5.project_currency_code, -- project_currency_code
                r3.receive_date,          -- project_rate_date
                r6.vendor_number);        -- vendor_number
              --
              v_ac_valor_imp_ins := v_ac_valor_imp_ins  + v_valor_imp_ins;
              --
            END IF;
            --
          END IF;
          --
        END LOOP;
        --
        CLOSE c2;
        CLOSE c8;
        --
        FETCH c1 INTO r1;
        --
        IF c1%NOTFOUND THEN
          EXIT;
        END IF;
        --
      END LOOP;
      --
      UPDATE cll_f189_invoices
         SET pa_interface_flag = 'Y'
       WHERE organization_id = p_organization_id
         AND operation_id = p_operation_id;
      --
    END IF;
  END pa;

  -- BUG 14642712 - Egini - Inicio
  PROCEDURE count_insert_desc_ar(p_invoice_id IN NUMBER,
                                  p_count      OUT NOCOPY NUMBER,
                                  p_desc       OUT NOCOPY VARCHAR2) AS

  CURSOR c1 IS
      SELECT ri.invoice_num ||
            ', serie ' ||ri.series ||', data ' ||
            TO_CHAR(ri.invoice_date,'dd/mm/rr') inf_nf
      FROM   cll_f189_invoices ri, cll_f189_invoice_parents rip
      WHERE  ri.invoice_id = rip.invoice_parent_id
      AND    rip.invoice_id = p_invoice_id;

      --
      x_mensagem_aux varchar2(5000);
      x_inf_nf       varchar2(5000);
      x_carac_nf     number;
      x_literal varchar2(10) := ' NF ';
      --
      BEGIN
      --
      FOR l1 IN c1 LOOP
          --
          BEGIN
              --
              x_mensagem_aux := x_mensagem_aux || x_literal ||l1.inf_nf;
              --
          END;
      --
      END LOOP;
      --
      x_carac_nf := length(RTRIM(LTRIM(x_mensagem_aux))); -- -- BUG 20411190
      --
      p_count := (x_carac_nf);
      p_desc  := RTRIM(LTRIM(x_mensagem_aux)); -- BUG 20411190
      --
  --
  END count_insert_desc_ar;
  -- BUG 14642712 - Egini - Fim
  -------------------------------------------------------------------------------
  -->                      count_insert_desc_ar_tpa                           <--
  -->  BUG-26338366: CLL_F513 THIRD PARTY MATERIAL                            <--
  -------------------------------------------------------------------------------
  PROCEDURE count_insert_desc_ar_tpa ( p_organization_id  IN NUMBER
                                     , p_operation_id     IN NUMBER
                                     , p_count           OUT NOCOPY NUMBER
                                     , p_desc            OUT NOCOPY VARCHAR2 ) AS

  CURSOR c1 IS
    SELECT DISTINCT 1 sequencia, 'Devolucao Fisica de Materiais Recebidos pelas Notas Fiscais : ' inf_nf
      FROM cll_f513_tpa_devolutions_ctrl cftd
         , cll_f513_tpa_receipts_control cftr
     WHERE cftr.tpa_receipts_control_id  = cftd.tpa_receipts_control_id
       AND cftd.organization_id          = p_organization_id
       AND cftd.devolution_operation_id  = p_operation_id
       AND cftd.symbolic_devolution_flag = 'N'
     UNION
    SELECT DISTINCT 2 sequencia, DECODE(INSTR( REPLACE(cftr.invoice_number, ',', '.'), '.'), 0, cftr.invoice_number, SUBSTR(cftr.invoice_number, 1, INSTR(REPLACE(cftr.invoice_number, ',', '.'), '.') -1 )) ||
             ', '||fnd_message.get_string ('CLL', 'CLL_F189_SERIE')||' '||cftr.invoice_series||', Dt. '||TO_CHAR(cftr.invoice_date, 'DD/MM/YY') inf_nf
      FROM cll_f513_tpa_devolutions_ctrl cftd
         , cll_f513_tpa_receipts_control cftr
     WHERE cftr.tpa_receipts_control_id  = cftd.tpa_receipts_control_id
       AND cftd.organization_id          = p_organization_id
       AND cftd.devolution_operation_id  = p_operation_id
       AND cftd.symbolic_devolution_flag = 'N'
     UNION
    SELECT DISTINCT 3 sequencia,'Devolucao Simbolica de Materiais Recebidos pelas Notas Fiscais : ' inf_nf
      FROM cll_f513_tpa_devolutions_ctrl cftd
         , cll_f513_tpa_receipts_control cftr
     WHERE cftr.tpa_receipts_control_id  = cftd.tpa_receipts_control_id
       AND cftd.organization_id          = p_organization_id
       AND cftd.devolution_operation_id  = p_operation_id
       AND cftd.symbolic_devolution_flag = 'Y'
     UNION
    SELECT DISTINCT 4 sequencia, DECODE(INSTR( REPLACE(cftr.invoice_number, ',', '.'), '.'), 0, cftr.invoice_number, SUBSTR(cftr.invoice_number, 1, INSTR(REPLACE(cftr.invoice_number, ',', '.'), '.') -1 )) ||
             ', '||fnd_message.get_string ('CLL', 'CLL_F189_SERIE')||' '||cftr.invoice_series||', Dt. '||TO_CHAR(cftr.invoice_date, 'DD/MM/YY') inf_nf
      FROM cll_f513_tpa_devolutions_ctrl cftd
         , cll_f513_tpa_receipts_control cftr
     WHERE cftr.tpa_receipts_control_id  = cftd.tpa_receipts_control_id
       AND cftd.organization_id          = p_organization_id
       AND cftd.devolution_operation_id  = p_operation_id
       AND cftd.symbolic_devolution_flag = 'Y'
    UNION
    SELECT 5 sequencia, description  inf_nf
      FROM cll_f189_invoices
     WHERE operation_id    = p_operation_id
       AND organization_id = p_organization_id
     ORDER BY 1 ;
  --
  x_literal      VARCHAR2(10) := ' ' ;
  x_mensagem_aux VARCHAR2(5000) ;
  x_inf_nf       VARCHAR2(5000) ;
  x_carac_nf     NUMBER ;
  --
  BEGIN
    --
    FOR l1 IN c1 LOOP
        --
        BEGIN
            --
            IF l1.sequencia = 5 AND x_mensagem_aux IS NOT NULL THEN
               x_mensagem_aux := x_mensagem_aux || ' -' ;
            END IF ;
            --
            x_mensagem_aux := x_mensagem_aux || x_literal ||l1.inf_nf;
            --
        END;
    --
    END LOOP;
    --
    x_carac_nf := length(RTRIM(LTRIM(x_mensagem_aux))); -- -- BUG 20411190
    --
    p_count := (x_carac_nf);
    p_desc  := RTRIM(LTRIM(x_mensagem_aux)); -- BUG 20411190
    --
  END count_insert_desc_ar_tpa ;
  -------------------------------------------------------------------------------
  -->                            AR TPA Interface                             <--
  -->  BUG-26338366: CLL_F513 THIRD PARTY MATERIAL                            <--
  -------------------------------------------------------------------------------
  PROCEDURE ar_tpa (p_operation_id    IN NUMBER
                 ,p_organization_id IN NUMBER) AS
  --
  CURSOR c1 IS
  SELECT ri.organization_id              organization_id,
         ri.operation_id                 operation_id,
         ri.invoice_id                   invoice_id,
         ri.source_items                 source_items,
         ri.terms_id                     terms_id,
         --
         ltrim(TO_CHAR(ri.ipi_amount,
         '999,999,999.99'),' ')          ri_ipi_amount,
         --
         NVL(ri.ipi_amount,0)            ipi_amount_header, -- Bug 8335230 (Item 5) - SSimoes - 30/03/2009 (new validation)
         NVL(ri.additional_amount,0)     additional_amount_header,               -- Bug 10086670 --
         --
         rit.ar_transaction_type_id      ar_transaction_type_id,
         rit.ar_cred_icms_category_id    ar_cred_icms_category_id,
         rit.ar_cred_icms_st_category_id ar_cred_icms_st_category_id,
         rit.ar_cred_ipi_category_id     ar_cred_ipi_category_id,
         rit.ar_deb_icms_category_id     ar_deb_icms_category_id,
         rit.ar_deb_icms_st_category_id  ar_deb_icms_st_category_id,
         rit.ar_deb_ipi_category_id      ar_deb_ipi_category_id,
         rbsa.NAME                       rbsa_name,
         rctt.post_to_gl                 post_to_gl,
         rctt.NAME                       rctt_name,
         rctt.default_term               ctt_default_term,
         raa.cust_acct_site_id           address_id, -- raa.address_id
         raa.cust_account_id             customer_id, -- raa.customer_id
         ril.invoice_line_id             invoice_line_id,
         ril.creation_date               creation_date,
         ril.created_by                  created_by,
         ril.last_update_date            last_update_date,
         ril.last_updated_by             last_updated_by,
         ril.last_update_login           last_update_login,
         ril.description                 ril_description,
         ril.item_id                     item_id,
         ril.quantity                    quantity,
         ril.unit_price                  unit_price,
         NVL(ril.discount_amount,0)      discount_amount,
         muom.uom_code                   uom,
         NVL(ril.icms_amount,0)          icms_amount,
         NVL(ril.icms_st_amount,0)       icms_st_amount,
         NVL(ril.ipi_amount,0)           ipi_amount,
         NVL(ril.icms_tax,0)             icms_tax,
         NVL(ril.ipi_tax,0)              ipi_tax,
         -- Bug 9729845 - SSimoes - 04/06/2010 - Inicio
         -- NVL(ril.icms_st_amount / ril.icms_st_base * 100, 0)      icms_st_tax,
         NVL(ril.icms_st_amount / DECODE(ril.icms_st_base,0,1,ril.icms_st_base) * 100, 0)      icms_st_tax,
         -- Bug 9729845 - SSimoes - 04/06/2010 - Fim
         ril.ipi_base_amount             ipi_base_amount,
         ril.net_amount                  net_amount,     -- Bug 10086670 --
         --ril.ipi_tax_code                ipi_tax_code, -- Bug 8511032 AIrmer 19/05/2009
         DECODE(NVL(rit.ipi_tributary_code_flag, 'N'), 'N', ril.ipi_tax_code, ril.ipi_tributary_code) ipi_tax_code,-- Bug 8511032 AIrmer 19/05/2009
         ril.icms_tax_code               icms_tax_code,
         rfo.cfo_code                    cfo_code,
         rfc.classification_code         classification_code,
         riu.utilization_code            utilization_code,
         muom.unit_of_measure            uom_name,
         ril.icms_base                   icms_base,
         ril.icms_st_base                icms_st_base, -- Bug 5962449 - SSimoes - 04/04/2007
         -- ril.tributary_status_code       sit_trib_est, -- (0007) -- BUG: 8304334
         substr(ril.tributary_status_code,1,1) sit_trib_code,      -- Bug 16850244
         substr(ril.tributary_status_code,2,2) sit_trib_est,       -- BUG: 8304334
         rfea.salesrep_id                salesrep_id,
         NVL(ri.freight_amount,0)        freight_amount_header, -- Bug 8577461 - SSimoes - 09/06/2009
         NVL(ril.freight_amount,0)       freight_amount_line    -- Bug 8577461 - SSimoes - 09/06/2009
         -- ,ri.simplified_br_tax_flag                              -- ER 9289619
        ,NVL(ri.insurance_amount,0)      insurance_amount_header  -- Bug 14582853
        ,NVL(ril.insurance_amount,0)     insurance_amount_line    -- Bug 14582853
        ,NVL(ri.other_expenses,0)        other_expenses_header    -- Bug 14582853
        ,NVL(ril.other_expenses,0)       other_expenses_line      -- Bug 14582853
        -- Inicio BUG 19495468
        ,RAA.GLOBAL_ATTRIBUTE_CATEGORY   global_attr_categ_site
        ,RAA.GLOBAL_ATTRIBUTE15          fiscal_doc_model
        ,RCTT.GLOBAL_ATTRIBUTE_CATEGORY  global_attr_categ_type
        ,RCTT.GLOBAL_ATTRIBUTE6          buyer_presence_ind
        -- Fim BUG 19495468
  FROM   cll_f189_invoices                      ri,
         cll_f189_invoice_types                 rit,
         org_organization_definitions           ood,
         ra_batch_sources_all                   rbsa,
         ra_cust_trx_types_all                  rctt,
         cll_f189_fiscal_entities_all           rfea,
         hz_cust_acct_sites_all                 raa, -- ra_addresses_all raa,
         cll_f189_invoice_lines                 ril,
         cll_f189_fiscal_operations             rfo,
         cll_f189_fiscal_class                  rfc,
         cll_f189_item_utilizations             riu,
         mtl_units_of_measure                   muom
  WHERE  ri.organization_id                   = p_organization_id AND
         ri.operation_id                      = p_operation_id AND
         rit.invoice_type_id                  = ri.invoice_type_id AND
         NVL(rit.generate_return_invoice,'N') = 'Y' AND
         ood.organization_id                  = p_organization_id AND
         rbsa.org_id                          = ood.operating_unit AND
         rbsa.batch_source_id                 = rit.ar_source_id AND
         rctt.org_id                          = ood.operating_unit AND -- SSimoes - 01/04/2009
         rctt.cust_trx_type_id                = rit.ar_transaction_type_id AND
         rfea.entity_id                       = ri.entity_id AND
         raa.cust_acct_site_id (+)            = rfea.cust_acct_site_id AND--rfea.ret_cust_acct_site_id AND -- raa.address_id (+) = rfea.ret_cust_acct_site_id -- AIrmer 26/05/2008
         muom.unit_of_measure                 = ril.uom AND
         riu.utilization_id                   = ril.utilization_id AND
         rfc.classification_id                = ril.classification_id AND
         rfo.cfo_id                           = ril.cfo_id AND
         ril.invoice_id                       = ri.invoice_id AND
         NVL(ri.ar_interface_flag,'N')        = 'N'
  ORDER BY ri.organization_id, ri.operation_id, ri.invoice_id, ril.invoice_line_id;
  --
  --  x_description               cll_f189_invoice_lines.description%TYPE; -- BUG 7150760 --
  x_operating_unit            org_organization_definitions.operating_unit%TYPE;
  x_set_of_books_id           gl_sets_of_books.set_of_books_id%TYPE;
  x_currency_code             gl_sets_of_books.currency_code%TYPE;
  x_invoice_id_ant            cll_f189_invoices.invoice_id%TYPE := 0;
  x_ra_term_id                ra_terms.term_id%TYPE;
  x_global_attribute_category mtl_system_items.global_attribute_category%TYPE;
  --  x_global_attribute1         mtl_system_items.global_attribute1%TYPE; -- Bug 6778641 AIrmer 29/01/2008
  v_category_concat_segs      mtl_item_categories_v.category_concat_segs%TYPE; -- Bug 6778641 AIrmer 29/01/2008
  x_global_attribute2         mtl_system_items.global_attribute2%TYPE;
  x_global_attribute3         mtl_system_items.global_attribute3%TYPE;
  x_global_attribute4         mtl_system_items.global_attribute4%TYPE;
  --  x_global_attribute5         mtl_system_items.global_attribute5%TYPE; -- Bug 4486071 AIrmer 19/08/2005
  x_global_attribute6         mtl_system_items.global_attribute6%TYPE;
  x_global_attribute7         mtl_system_items.global_attribute7%TYPE;
  x_tax_code                  ar_vat_tax_vl.tax_code%TYPE;
  x_sit_trib_est              VARCHAR2(3);
  x_mensagem                  VARCHAR2(450);
  x_mensagem_aux              VARCHAR2(500);
  x_count_ar                  NUMBER;         -- Bug 14642712
  x_desc_ar                   VARCHAR2(4000); -- Bug 14642712
  x_literal                   VARCHAR2(6);
  x_inf_nf                    VARCHAR2(450);
  x_module_name               CONSTANT VARCHAR2(100) := 'CLL_F189_INTERFACE_PKG.AR';
  x_fob_point                 VARCHAR2(10); -- Enh 6860943 - SSimoes - 03/03/2008
  x_unit_selling_price        NUMBER; -- BUG Equal 6667766 - rvicente 14/05/2008
  v_salesrep_required_flag    VARCHAR2(1); -- Bug 7560411 - rvicente 26/05/2009
  c_sales_credit_type_id      NUMBER; -- Bug 7560411 - rvicente 26/05/2009
  --
  l_gl_precision              NUMBER; -- Bug 14400588
  --
  -- Inicio BUG 19495468
  v_col_exist                 NUMBER :=0; -- BUG 19495468
  v_qty_invoice_dev           NUMBER :=0;
  v_invoice_line_id_dev       NUMBER;
  v_invoice_line_id_par       NUMBER;
  v_qty_parent                NUMBER :=0;
  arr                         NUMBER (1);
  v_rowid                     ROWID;
  v_perc_returned_goods       NUMBER :=0;
  v_fiscal_doc_model          VARCHAR2(30);
  v_buyer_presence_ind        VARCHAR2(30);
  v_insert_string             VARCHAR2(3000);
  -- Fim BUG 19495468
  --
BEGIN
  FOR r1 IN c1 LOOP
    IF r1.invoice_id <> x_invoice_id_ant THEN
      -- Bug 8335230 (Item 5) - SSimoes - 13/03/2009 - Inicio
      -- IF NVL(r1.ri_ipi_amount,0) = 0 THEN -- Bug 8335230 (Item 5) - SSimoes - 30/03/2009 (new validation)
      IF r1.ipi_amount_header = 0 THEN -- Bug 8335230 (Item 5) - SSimoes - 30/03/2009 (new validation)
         x_mensagem     :=  fnd_message.get_string ('CLL', 'CLL_F189_DOC_RETURN');
      ELSE
         x_mensagem     :=  fnd_message.get_string ('CLL', 'CLL_F189_IPI_RECOVER')||': '||r1.ri_ipi_amount||'. '||fnd_message.get_string ('CLL', 'CLL_F189_DOC_RETURN');
      END IF;
      -- Bug 8335230 (Item 5) - SSimoes - 13/03/2009 - Fim
      --
      --Bug 14642712 - Egini - 20/09/2012 - Inicio
      /*
      x_mensagem_aux := x_mensagem;
      x_literal      := ' Doc ';
      --
      --  FOR r2 IN (SELECT ri.invoice_num || -- Bug 8335230 (Item 4) - SSimoes - 19/03/2009
      FOR r2 IN (SELECT DECODE(INSTR(REPLACE(ri.invoice_num,',','.'),'.'),0,ri.invoice_num,SUBSTR(ri.invoice_num,1,INSTR(REPLACE(ri.invoice_num,',','.'),'.') -1 )) ||  -- Bug 8335230 (Item 4) - SSimoes - 19/03/2009
                        ', '||fnd_message.get_string ('CLL', 'CLL_F189_SERIE')||' '||ri.series||', Dt. '||TO_CHAR(ri.invoice_date,'dd/mm/yy') inf_nf
                   FROM cll_f189_invoices         ri
                       ,cll_f189_invoice_parents  rip
                  WHERE ri.invoice_id = rip.invoice_parent_id
                    AND rip.invoice_id = r1.invoice_id) LOOP
        --
        x_inf_nf := x_literal || r2.inf_nf;
        x_mensagem_aux := x_mensagem_aux || x_inf_nf;
        --
       IF LENGTH(x_mensagem_aux) <= 450 THEN
          x_mensagem := x_mensagem || x_inf_nf;
       -- Bug 9809231 - SSimoes - 23/06/2010 - Inicio
       ELSE
          EXIT;
       -- Bug 9809231 - SSimoes - 23/06/2010 - Fim
       END IF;
       x_literal := ' -Doc '; -- ' - Doc '  AIrmer  24/04/2008 - This variable is varchar(6)
      END LOOP;
      --
      IF LENGTH(x_mensagem_aux) < 450 THEN
        x_mensagem := x_mensagem || '.';
      END IF; */
      --
      cll_f189_interface_pkg.count_insert_desc_ar_tpa ( p_organization_id => r1.organization_id
                                                      , p_operation_id    => r1.operation_id
                                                      , p_count           => x_count_ar
                                                      , p_desc            => x_desc_ar ) ;
      --
      x_mensagem := x_desc_ar;
      --Bug 14642712 - Egini - 20/09/2012 - Fim
    END IF;
    --
    BEGIN
      SELECT ood.set_of_books_id
            ,ood.operating_unit
            ,gsb.currency_code
        INTO x_set_of_books_id
            ,x_operating_unit
            ,x_currency_code
        FROM org_organization_definitions ood
            ,gl_sets_of_books             gsb
       WHERE ood.organization_id = r1.organization_id
         AND gsb.set_of_books_id = ood.set_of_books_id;
    EXCEPTION
      WHEN others THEN
        raise_application_error
             (-20548, x_module_name||' - ERROR:  '||SQLERRM ||' Selecting operating unit data and currency code.');
    END;
    --
    -- Bug 14400588 - Start
    BEGIN
      --
      SELECT NVL(precision, 2)
        INTO l_gl_precision
        FROM fnd_currencies_vl
       WHERE currency_code = x_currency_code;
      --
    EXCEPTION
      WHEN OTHERS THEN
        raise_application_error
             (-20548, x_module_name||' - ERROR:  '||SQLERRM ||' Selecting currency precision.');
    END;
    -- Bug 14400588 - End
    --
    BEGIN
      SELECT ra.term_id
        INTO x_ra_term_id
        FROM ra_terms ra
            ,ap_terms ap
       WHERE UPPER(ra.NAME) = UPPER(ap.NAME)
         AND ap.term_id     = r1.terms_id;
    EXCEPTION
      WHEN others THEN
        IF r1.ctt_default_term IS NULL THEN
          BEGIN
            SELECT payment_term_id
              INTO x_ra_term_id
              FROM hz_cust_accounts -- ra_customers
             WHERE cust_account_id = r1.customer_id; -- WHERE customer_id = r1.customer_id;
          EXCEPTION
            WHEN others THEN
              x_ra_term_id := NULL;
          END;
        ELSE
          x_ra_term_id := r1.ctt_default_term;
        END IF;
    END;
    --
    x_sit_trib_est := r1.sit_trib_est;
    --
    IF x_sit_trib_est IS NULL THEN
       IF r1.icms_tax_code = 1 THEN
          -- x_sit_trib_est := SUBSTR(r1.source_items,1) || '00';    -- BUG: 8304334
          x_sit_trib_est := '00';                                   -- BUG: 8304334
       ELSIF r1.icms_tax_code = 2 THEN
             -- x_sit_trib_est := SUBSTR(r1.source_items,1) || '40'; -- BUG: 8304334
             x_sit_trib_est := '40';                                -- BUG: 8304334
       ELSIF r1.icms_tax_code = 3 THEN
             -- x_sit_trib_est := SUBSTR(r1.source_items,1) || '90'; -- BUG: 8304334
             x_sit_trib_est := '90';                                -- BUG: 8304334
       END IF;
    END IF;
    --
    BEGIN
      SELECT --description -- BUG 7150760 --
             global_attribute_category
             --,global_attribute1 -- Bug 6778641 AIrmer 29/01/2008
            ,global_attribute2
            ,global_attribute3
            ,global_attribute4
            -- ,global_attribute5 -- Bug 4486071 AIrmer 19/08/2005
            ,global_attribute6
            ,global_attribute7
       INTO --x_description -- BUG 7150760 --
            x_global_attribute_category
            --,x_global_attribute1 -- Bug 6778641 AIrmer 29/01/2008
            ,x_global_attribute2
            ,x_global_attribute3
            ,x_global_attribute4
            -- ,x_global_attribute5 -- Bug 4486071 AIrmer 19/08/2005
            ,x_global_attribute6
            ,x_global_attribute7
       FROM mtl_system_items
      WHERE inventory_item_id = r1.item_id
        AND organization_id   = r1.organization_id;
    EXCEPTION
      WHEN others THEN
        raise_application_error
          (-20549, x_module_name||' - ERROR:  '||SQLERRM||' Selecting item data.');
    END;
    /* BUG 10355568: Start
      -- Bug 6778641 AIrmer 29/01/2008
       BEGIN
         SELECT category_concat_segs
          INTO  v_category_concat_segs
         FROM   mtl_item_categories_v
         WHERE  inventory_item_id = r1.item_id
           AND  organization_id   = r1.organization_id
           AND structure_id = 4; -- hardcoded to Fiscal Classification
       EXCEPTION
        WHEN OTHERS THEN
             raise_application_error
               (-20558, x_module_name||' - ERROR:  '||SQLERRM||' Selecting item Fiscal Classification.');
       END;
      --
    BUG 10355568: End    */
    --
    -- BUG Equal 6667766 - rvicente - 14/05/2008 - Begin
    IF r1.additional_amount_header = 0 AND               -- Bug 10086670 --
        r1.discount_amount = 0 THEN                       -- Bug 10086670 --
        x_unit_selling_price := r1.unit_price;
    ELSE
        --x_unit_selling_price := (round((r1.ipi_base_amount - r1.discount_amount),2)/r1.quantity); -- Bug 10127287
        -- x_unit_selling_price := (round((r1.ipi_base_amount - (r1.discount_amount*r1.quantity)),2)/r1.quantity); -- Bug 10127287 -- Bug 10086670 --
        x_unit_selling_price := ROUND(r1.net_amount,2) /    -- Bug 10086670 --
                                r1.quantity;                -- Bug 10086670 --
    END IF;
    -- BUG Equal 6667766 - rvicente - 14/05/2008 - End
    --
    -- Enh 6860943 - SSimoes - 03/03/2008 - Inicio
    BEGIN
      --SELECT DECODE(reo.freight_flag,'C','CIF','F','FOB',NULL)
      SELECT DECODE(reo.freight_flag,'C','1','F','2',NULL) -- Enh 7019481
        INTO x_fob_point
        FROM cll_f189_entry_operations reo
       WHERE reo.organization_id = r1.organization_id
         AND reo.operation_id = r1.operation_id;
    EXCEPTION
       WHEN OTHERS THEN
         x_fob_point := NULL;
    END;
    -- Enh 6860943 - SSimoes - 03/03/2008 - Fim
    --
    -- Bug 7560411 - rvicente 11/05/09 - Begin
    BEGIN
      SELECT nvl(salesrep_required_flag,'N')
        INTO v_salesrep_required_flag
        FROM ar_system_parameters_all
       WHERE org_id = x_operating_unit;
    EXCEPTION WHEN others THEN
      v_salesrep_required_flag := 'N';
    END;
    --
    --
    IF (v_salesrep_required_flag = 'Y') THEN
        BEGIN
          SELECT sales_credit_type_id
            INTO c_sales_credit_type_id
            FROM ra_salesreps_all
           WHERE salesrep_id = -3
             AND org_id = x_operating_unit;
        EXCEPTION WHEN others THEN
            c_sales_credit_type_id := 1;
        END;
    END IF;
    -- Bug 7560411 - rvicente 11/05/09 - End
    -- Incio BUG 19495468
    BEGIN
      SELECT count(*)
        INTO v_col_exist
        FROM sys.all_tab_columns
       WHERE table_name  = 'JL_BR_INTERFACE_LINES_EXTS'
         AND column_name = 'FISCAL_DOC_MODEL';
    EXCEPTION WHEN others THEN
      v_col_exist := 0;
    END;
    --
    BEGIN
      SELECT cil.quantity, cil.invoice_line_id,
             (SELECT cil1.invoice_line_id
                FROM cll_f189_invoice_lines cil1
               WHERE cil1.invoice_line_id = cflp.invoice_parent_line_id) inv_line_id   ,
             (SELECT cil1.quantity
                FROM cll_f189_invoice_lines cil1
               WHERE cil1.invoice_line_id = cflp.invoice_parent_line_id) qty_parent
        INTO v_qty_invoice_dev,
             v_invoice_line_id_dev,
             v_invoice_line_id_par,
             v_qty_parent
        FROM cll_f189_invoice_line_parents cflp
            ,cll_f189_invoice_parents      cfip
            ,cll_f189_invoice_lines        cil
       WHERE cflp.invoice_line_id = r1.invoice_line_id
         AND cflp.parent_id       = cfip.parent_id
         AND cflp.invoice_line_id   = cil.invoice_line_id;
    EXCEPTION WHEN others THEN
      v_qty_invoice_dev      :=0;
      v_invoice_line_id_dev  :=0;
      v_invoice_line_id_par  :=0;
      v_qty_parent           :=0;
    END;
    --
    arr := 2;
    --
    IF  NVL(v_qty_invoice_dev,0) = nvl(v_qty_parent,0) THEN
        v_perc_returned_goods := 100;
    ELSIF  NVL(v_qty_invoice_dev,0) <> nvl(v_qty_parent,0) THEN
        v_perc_returned_goods := ROUND ((NVL(v_qty_invoice_dev,0) / nvl(v_qty_parent,0)) * 100,arr);
    END IF;
    --
    IF r1.global_attr_categ_site = 'JL.BR.ARXCUDCI.Additional' THEN
       v_fiscal_doc_model := r1.fiscal_doc_model;
    ELSIF r1.global_attr_categ_site <> 'JL.BR.ARXCUDCI.Additional' THEN
          v_fiscal_doc_model := NULL;
    END IF;
    --
    IF r1.global_attr_categ_site = 'JL.BR.RAXSUCTT.Globalization' THEN
       v_buyer_presence_ind := r1.buyer_presence_ind;
    ELSIF r1.global_attr_categ_site <> 'JL.BR.RAXSUCTT.Globalization' THEN
       v_buyer_presence_ind := NULL;
    END IF;
    -- Fim BUG 19495468
    --
    INSERT INTO ra_interface_lines_all
               (interface_line_id
               ,amount_includes_tax_flag
               ,interface_line_context
               ,interface_line_attribute1
               ,interface_line_attribute2
               ,interface_line_attribute3
               ,interface_line_attribute4
               ,interface_line_attribute5
               ,batch_source_name
               ,set_of_books_id
               ,line_type
               ,description
               ,currency_code
               ,amount
               ,cust_trx_type_id
               ,orig_system_bill_customer_id
               ,orig_system_bill_address_id
               ,orig_system_ship_customer_id
               ,orig_system_ship_address_id
               ,conversion_type
               ,conversion_rate
               ,gl_date
               ,quantity
               ,unit_selling_price
               ,inventory_item_id
               ,uom_code
               ,uom_name
               ,created_by
               ,creation_date
               ,last_updated_by
               ,last_update_date
               ,last_update_login
               ,org_id
               ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
               ,header_gdf_attribute10 -- Bug 14582853
               ,header_gdf_attribute11 -- Bug 14582853
               ,header_gdf_attr_category
               ,line_gdf_attr_category
               ,line_gdf_attribute1
               ,line_gdf_attribute2
               ,line_gdf_attribute3
               ,line_gdf_attribute4
               ,line_gdf_attribute5
               ,line_gdf_attribute6
               ,line_gdf_attribute7
               ,line_gdf_attribute8
               ,line_gdf_attribute9
               ,line_gdf_attribute10
               ,warehouse_id
               ,term_id
               ,primary_salesrep_id
               ,fob_point) -- Enh 6860943
      VALUES
               (NULL                                              -- interface_line_id
               ,'N'                                               -- amount_includes_tax_flag
               ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
               ,r1.operation_id                                   -- interface_line_attribute1
               ,r1.organization_id                                -- interface_line_attribute2
               ,r1.invoice_id                                     -- interface_line_attribute3
               ,r1.invoice_line_id                                -- interface_line_attribute4
               ,0                                                 -- interface_line_attribute5
               ,r1.rbsa_name                                      -- batch_source_name
               ,x_set_of_books_id                                 -- set_of_books_id
               ,'LINE'                                            -- line_type
               -- x_description,                                     -- description -- BUG 7150760 --
               ,r1.ril_description                                -- description of cll_f189_invoice_lines -- BUG 7150760 --
               ,x_currency_code                                   -- currency_code
               -- ,r1.ipi_base_amount - r1.discount_amount          -- amount -- BUG 4027666
               -- ,ROUND((r1.ipi_base_amount - r1.discount_amount),2) -- amount -- BUG 4027666 -- Bug 8577461 - SSimoes - 09/06/2009
               -- ,ROUND((r1.ipi_base_amount - r1.discount_amount - r1.freight_amount_line),2) -- amount -- Bug 8577461 - SSimoes - 09/06/2009 -- Bug 10127287
               -- ,ROUND((r1.ipi_base_amount - (r1.discount_amount * r1.quantity) - r1.freight_amount_line),2) -- amount -- Bug 10127287 -- Bug 10086670 --
               --
               -- Bug 14582853 - Start
               -- ,ROUND((r1.net_amount - r1.freight_amount_line),2) -- amount -- Bug 10086670 --
               ,ROUND(r1.net_amount -
                      r1.freight_amount_line -
                      r1.insurance_amount_line -  -- Bug 20646467 ASaraiva 04/05/2015
                      r1. other_expenses_line     -- Bug 20646467 ASaraiva 04/05/2015
               --  ,2)
                     ,l_gl_precision)                             --amount -- Bug 14400588
               -- Bug 14582853 - End
               --
               ,r1.ar_transaction_type_id                         -- cust_trx_type_id
               ,r1.customer_id                                    -- orig_system_bill_customer_id
               ,r1.address_id                                     -- orig_system_bill_address_id
               ,r1.customer_id                                    -- orig_system_ship_customer_id
               ,r1.address_id                                     -- orig_system_ship_address_id
               ,'User'                                            -- conversion_type
               ,1                                                 -- conversion_rate
               ,NULL                                              -- gl_date
               ,r1.quantity                                       -- quantity
               -- ,(r1.ipi_base_amount - r1.discount_amount)/
               -- r1.quantity                                    -- unit_selling_price -- BUG 4027666
               -- BUG 5371443 - Begin
               -- ,ROUND(((r1.ipi_base_amount - r1.discount_amount)/
               -- r1.quantity),2)                           -- unit_selling_price -- BUG 4027666
               ,x_unit_selling_price -- BUG Equal 6667766 (ROUND((r1.ipi_base_amount - r1.discount_amount),2)/r1.quantity) -- unit_selling_price -- BUG 5371443
               -- BUG 5371443 - End
               ,r1.item_id                                        -- inventory_item_id
               ,r1.uom                                            -- uom_code
               ,r1.uom_name                                       -- uom_name
               ,r1.created_by                                     -- created_by
               ,r1.creation_date                                  -- creation_date
               ,r1.last_updated_by                                -- last_updated_by
               ,r1.last_update_date                               -- last_update_date
               ,r1.last_update_login                              -- last_update_login
               ,x_operating_unit                                  -- org_id
               /*
               ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
               ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
               ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
               */
               ,fnd_number.number_to_canonical(
                           ROUND( r1.freight_amount_header
                                , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
               ,fnd_number.number_to_canonical(
                           ROUND( r1.insurance_amount_header
                                , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
               ,fnd_number.number_to_canonical(
                           ROUND( r1.other_expenses_header
                                , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
               --
               -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- header_gdf_attr_category   -- Bug 5371080 --
               ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                       -- Bug 5371080 --
               -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- line_gdf_attr_category     -- Bug 5371080 --
               ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                         -- Bug 5371080 --
               ,r1.cfo_code                                       -- line_gdf_attribute1
               -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2   -- Bug 6778641 AIrmer 29/01/2008
               -- ,NVL(r1.classification_code,v_category_concat_segs)  -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008  -- BUG 10355568
               ,r1.classification_code                                -- line_gdf_attribute2 -- BUG 10355568
               ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
               -- ,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
               ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
               ,x_global_attribute4                               -- line_gdf_attribute5
               -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
               ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
               ,x_sit_trib_est                                    -- line_gdf_attribute7
               -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
               ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
               -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
               ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
               -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
               ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
               ,r1.organization_id                                -- warehouse_id
               ,x_ra_term_id                                      -- term_id
               ,r1.salesrep_id
               ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
               --
               -- Bug 7560411 - rvicente 11/05/09 - Begin
    -- Incio BUG 19495468
      SELECT ROWID
        INTO V_ROWID
        FROM ra_interface_lines_all
       WHERE interface_line_attribute4 = TO_CHAR(r1.invoice_line_id)
         AND line_type = 'LINE'
         AND interface_line_context = 'CLL F189 INTEGRATED RCV';  -- BUG 25118794
    --
    IF v_col_exist <> 0 THEN
       --
       EXECUTE IMMEDIATE 'INSERT INTO jl_br_interface_lines_exts
                                ( jl_br_interface_link_id,
                                  fiscal_doc_model,
                                  buyer_presence_ind,
                                  perc_returned_goods,
                                  created_by,
                                  creation_date,
                                  last_updated_by,
                                  last_update_date,
                                  last_update_login)
                                VALUES ('''||V_ROWID||''','||
                                             NVL(v_fiscal_doc_model, 'Null')||','||
                                             NVL(v_buyer_presence_ind, 'Null')||','||
                                             --<< BUG 20930680 - 07/05/15 - Start -->>
                                             --v_perc_returned_goods||','||
                                             ltrim(to_char(round(v_perc_returned_goods,5),'9999999999D99999',
                                             'NLS_NUMERIC_CHARACTERS = ''.,'''))||','||
                                             --<<  BUG 20930680 - 07/05/15 - End -->>
                                             r1.created_by||','||
                                             'sysdate'||','||
                                             r1.last_updated_by||','||
                                             'sysdate'||','||
                                             NVL(r1.last_update_login, FND_GLOBAL.LOGIN_ID)||')'; -- BUG 30772520
                                           --r1.last_update_login||')';                           -- BUG 30772520
       --
    END IF;
    -- Fim BUG 19495468
    IF (v_salesrep_required_flag = 'Y') THEN
        INSERT INTO ra_interface_salescredits_all
                  (interface_line_context         -- 01
                  ,interface_line_attribute1      -- 02
                  ,interface_line_attribute2      -- 03
                  ,interface_line_attribute3      -- 04
                  ,interface_line_attribute4      -- 05
                  ,interface_line_attribute5      -- 06
                  ,salesrep_id                    -- 07
                  ,sales_credit_type_id           -- 08
                  ,sales_credit_percent_split     -- 09
                  ,created_by                     -- 10
                  ,creation_date                  -- 11
                  ,last_updated_by                -- 12
                  ,last_update_date               -- 13
                  ,last_update_login              -- 14
                  ,org_id                         -- 15
                  )
              VALUES
                 ('CLL F189 INTEGRATED RCV'      -- 01 interface_line_context
                  ,r1.operation_id                -- 02 interface_line_attribute1
                  ,r1.organization_id             -- 03 interface_line_attribute2
                  ,r1.invoice_id                  -- 04 interface_line_attribute3
                  ,r1.invoice_line_id             -- 05 interface_line_attribute4
                  ,0                              -- 06 interface_line_attribute5
                  --Inicio BUG 18906577
                  --,-3                             -- 07 fixo '-3' porque representa o 'no sales credit'
                  ,r1.salesrep_id
                  --Fim BUG 18906577
                  ,c_sales_credit_type_id         -- 08
                  ,100                            -- 09 percentual
                  ,r1.created_by                  -- 10
                  ,r1.creation_date               -- 11
                  ,r1.last_updated_by             -- 12
                  ,r1.last_update_date            -- 13
                  ,r1.last_update_login           -- 14
                  ,x_operating_unit               -- 15
                  );
    END IF;
    -- Bug 7560411 - rvicente 11/05/09 - End
    --
    x_mensagem     := NULL;
    x_mensagem_aux := NULL;
    --
    IF r1.icms_amount > 0 THEN
      IF r1.ar_cred_icms_category_id IS NOT NULL THEN
        BEGIN
          SELECT avt.tax_code
            INTO x_tax_code
            FROM jl_zz_ar_tx_categ_all jza,
                 ar_vat_tax_vl         avt
           WHERE jza.tax_category_id   = r1.ar_cred_icms_category_id
             AND jza.org_id            = x_operating_unit
             AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
             -- 21842498 - Start
             AND avt.enabled_flag     = 'Y'
             AND avt.start_date <= sysdate
             AND nvl(avt.end_date, sysdate + 1) > sysdate
             -- 21842498 - End
             AND ROWNUM                = 1;
        EXCEPTION
          WHEN others THEN
            raise_application_error (-20550, x_module_name||' - ERROR:  '||SQLERRM||' Selecting ICMS tax code.');
        END;
        --
        INSERT INTO ra_interface_lines_all
                   (interface_line_id
                   ,amount_includes_tax_flag
                   ,interface_line_context
                   ,interface_line_attribute1
                   ,interface_line_attribute2
                   ,interface_line_attribute3
                   ,interface_line_attribute4
                   ,interface_line_attribute5
                   ,batch_source_name
                   ,link_to_line_context
                   ,link_to_line_attribute1
                   ,link_to_line_attribute2
                   ,link_to_line_attribute3
                   ,link_to_line_attribute4
                   ,link_to_line_attribute5
                   ,set_of_books_id
                   ,line_type
                   ,description
                   ,currency_code
                   ,amount
                   ,cust_trx_type_id
                   ,orig_system_bill_customer_id
                   ,orig_system_bill_address_id
                   ,orig_system_ship_customer_id
                   ,orig_system_ship_address_id
                   ,conversion_type
                   ,conversion_rate
                   ,gl_date
                   ,tax_rate
                   --,tax_code BUG 7715719 - rvicente - 21/01/2009
                   ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                   ,created_by
                   ,creation_date
                   ,last_updated_by
                   ,last_update_date
                   ,last_update_login
                   ,org_id
                   ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,header_gdf_attribute10 -- Bug 14582853
                   ,header_gdf_attribute11 -- Bug 14582853
                   ,header_gdf_attr_category
                   ,line_gdf_attr_category
                   ,line_gdf_attribute1
                   ,line_gdf_attribute2
                   ,line_gdf_attribute3
                   ,line_gdf_attribute4
                   ,line_gdf_attribute5
                   ,line_gdf_attribute6
                   ,line_gdf_attribute7
                   ,line_gdf_attribute8
                   ,line_gdf_attribute9
                   ,line_gdf_attribute10
                   ,term_id
                   ,line_gdf_attribute11
                   ,line_gdf_attribute19
                   ,line_gdf_attribute20
                   ,primary_salesrep_id
                   ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
             VALUES
                   (NULL                                               -- interface_line_id
                   ,'N'                                                -- amount_includes_tax_flag
                   ,'CLL F189 INTEGRATED RCV'                          -- interface_line_context
                   ,r1.operation_id                                    -- interface_line_attribute1
                   ,r1.organization_id                                 -- interface_line_attribute2
                   ,r1.invoice_id                                      -- interface_line_attribute3
                   ,r1.invoice_line_id                                 -- interface_line_attribute4
                   ,1                                                  -- interface_line_attribute5
                   ,r1.rbsa_name                                       -- batch_source_name
                   ,'CLL F189 INTEGRATED RCV'                          -- link_to_line_context
                   ,r1.operation_id                                    -- link_to_line_attribute1
                   ,r1.organization_id                                 -- link_to_line_attribute2
                   ,r1.invoice_id                                      -- link_to_line_attribute3
                   ,r1.invoice_line_id                                 -- link_to_line_attribute4
                   ,'0'                                                -- link_to_line_attribute5
                   ,x_set_of_books_id                                  -- set_of_books_id
                   ,'TAX'                                              -- line_type
                   ,'ICMS'                                             -- description
                   ,x_currency_code                                    -- currency_code
                   ,ROUND(r1.icms_amount, l_gl_precision)              -- amount -- Bug 14400588
                   -- ,r1.icms_amount                                     -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   -- NULL,                                               -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   ,r1.ar_transaction_type_id                          -- cust_trx_type_id
                   ,r1.customer_id                                     -- orig_system_bill_customer_id
                   ,NULL                                               -- orig_system_bill_address_id
                   ,r1.customer_id                                     -- orig_system_ship_customer_id
                   ,NULL                                               -- orig_system_ship_address_id
                   ,'User'                                             -- conversion_type
                   ,1                                                  -- conversion_rate
                   ,NULL                                               -- gl_date
                   ,r1.icms_tax                                        -- tax_rate
                   ,x_tax_code                                         -- tax_code
                   ,r1.created_by                                      -- created_by
                   ,r1.creation_date                                   -- creation_date
                   ,r1.last_updated_by                                 -- last_updated_by
                   ,r1.last_update_date                                -- last_update_date
                   ,r1.last_update_login                               -- last_update_login
                   ,x_operating_unit                                   -- org_id
                   /*
                   ,r1.freight_amount_header                           -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,r1.insurance_amount_header                         -- header_gdf_attribute10 -- Bug 14582853
                   ,r1.other_expenses_header                           -- header_gdf_attribute11 -- Bug 14582853
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.freight_amount_header
                                    , l_gl_precision ))                -- header_gdf_attribute9  -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.insurance_amount_header
                                    , l_gl_precision ))                -- header_gdf_attribute10 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.other_expenses_header
                                    , l_gl_precision ))                -- header_gdf_attribute11 -- Bug 14400588
                   --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- header_gdf_attr_category   -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                   -- header_gdf_attr_category                      -- Bug 5371080 --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- line_gdf_attr_category     -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                   -- line_gdf_attr_category                        -- Bug 5371080 --
                   ,r1.cfo_code                                        -- line_gdf_attribute1
                   -- ,NVL(r1.classification_code,x_global_attribute1)    -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                   -- ,NVL(r1.classification_code,v_category_concat_segs) -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008  BUG 10355568
                   ,r1.classification_code                               -- line_gdf_attribute2 -- BUG 10355568
                   ,NVL(r1.utilization_code,x_global_attribute2)       -- line_gdf_attribute3
                 --,NVL(r1.source_items,x_global_attribute3)           -- line_gdf_attribute4 -- Bug 16850244
                   ,NVL(r1.sit_trib_code, x_global_attribute3)         -- line_gdf_attribute4 -- Bug 16850244
                   ,x_global_attribute4                                -- line_gdf_attribute5
                   -- ,x_global_attribute5                                -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,r1.ipi_tax_code                                    -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,x_sit_trib_est                                     -- line_gdf_attribute7
                   -- ,SUBSTR(x_mensagem,1,150)                          -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,1,150)                          -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,151,150)                        -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,151,150)                        -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,301,150)                        -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,301,150)                        -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,x_ra_term_id                                       -- term_id
                   /*
                   ,r1.icms_base                                       -- line_gdf_attribute11
                   ,r1.icms_amount                                     -- line_gdf_attribute19
                   ,r1.icms_amount   --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   --,r1.ipi_amount  --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG 4044106  -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_base
                                    , l_gl_precision ))                -- line_gdf_attribute11 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_amount
                                    , l_gl_precision ))                -- line_gdf_attribute19 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_amount
                                    , l_gl_precision ))                -- line_gdf_attribute20 -- Bug 14400588
                   --
                   ,r1.salesrep_id
                   ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
        --
      END IF;
      --
      IF r1.ar_deb_icms_category_id IS NOT NULL THEN
        BEGIN
          SELECT avt.tax_code
            INTO x_tax_code
            FROM jl_zz_ar_tx_categ_all jza,
                 ar_vat_tax_vl         avt
           WHERE jza.tax_category_id   = r1.ar_deb_icms_category_id
             AND jza.org_id            = x_operating_unit
             AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
             -- 21842498 - Start
             AND avt.enabled_flag     = 'Y'
             AND avt.start_date <= sysdate
             AND nvl(avt.end_date, sysdate + 1) > sysdate
             -- 21842498 - End
             AND ROWNUM                = 1;
        EXCEPTION
          WHEN others THEN
            raise_application_error (-20551, x_module_name||' - ERROR:  '||SQLERRM||' Selecting ICMS tax code.');
        END;
        --
        INSERT INTO ra_interface_lines_all
                   (interface_line_id
                   ,amount_includes_tax_flag
                   ,interface_line_context
                   ,interface_line_attribute1
                   ,interface_line_attribute2
                   ,interface_line_attribute3
                   ,interface_line_attribute4
                   ,interface_line_attribute5
                   ,batch_source_name
                   ,link_to_line_context
                   ,link_to_line_attribute1
                   ,link_to_line_attribute2
                   ,link_to_line_attribute3
                   ,link_to_line_attribute4
                   ,link_to_line_attribute5
                   ,set_of_books_id
                   ,line_type
                   ,description
                   ,currency_code
                   ,amount
                   ,cust_trx_type_id
                   ,orig_system_bill_customer_id
                   ,orig_system_bill_address_id
                   ,orig_system_ship_customer_id
                   ,orig_system_ship_address_id
                   ,conversion_type
                   ,conversion_rate
                   ,gl_date
                   ,tax_rate
                   --,tax_code BUG 7715719 - rvicente - 21/01/2009
                   ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                   ,created_by
                   ,creation_date
                   ,last_updated_by
                   ,last_update_date
                   ,last_update_login
                   ,org_id
                   ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,header_gdf_attribute10 -- Bug 14582853
                   ,header_gdf_attribute11 -- Bug 14582853
                   ,header_gdf_attr_category
                   ,line_gdf_attr_category
                   ,line_gdf_attribute1
                   ,line_gdf_attribute2
                   ,line_gdf_attribute3
                   ,line_gdf_attribute4
                   ,line_gdf_attribute5
                   ,line_gdf_attribute6
                   ,line_gdf_attribute7
                   ,line_gdf_attribute8
                   ,line_gdf_attribute9
                   ,line_gdf_attribute10
                   ,term_id
                   ,line_gdf_attribute11
                   ,line_gdf_attribute19
                   ,line_gdf_attribute20
                   ,primary_salesrep_id
                   ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
             VALUES
                   (NULL                                              -- interface_line_id
                   ,'N'                                               -- amount_includes_tax_flag
                   ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                   ,r1.operation_id                                   -- interface_line_attribute1
                   ,r1.organization_id                                -- interface_line_attribute2
                   ,r1.invoice_id                                     -- interface_line_attribute3
                   ,r1.invoice_line_id                                -- interface_line_attribute4
                   ,2                                                 -- interface_line_attribute5
                   ,r1.rbsa_name                                      -- batch_source_name
                   ,'CLL F189 INTEGRATED RCV'                         -- link_to_line_context
                   ,r1.operation_id                                   -- link_to_line_attribute1
                   ,r1.organization_id                                -- link_to_line_attribute2
                   ,r1.invoice_id                                     -- link_to_line_attribute3
                   ,r1.invoice_line_id                                -- link_to_line_attribute4
                   ,'0'                                               -- link_to_line_attribute5
                   ,x_set_of_books_id                                 -- set_of_books_id
                   ,'TAX'                                             -- line_type
                   ,'ICMS'                                            -- description
                   ,x_currency_code                                   -- currency_code
                   ,ROUND(r1.icms_amount *-1, l_gl_precision)         -- amount -- Bug 14400588
                   -- ,r1.icms_amount *-1                                -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   -- NULL,                                              -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                   ,r1.customer_id                                    -- orig_system_bill_customer_id
                   ,NULL                                              -- orig_system_bill_address_id
                   ,r1.customer_id                                    -- orig_system_ship_customer_id
                   ,NULL                                              -- orig_system_ship_address_id
                   ,'User'                                            -- conversion_type
                   ,1                                                 -- conversion_rate
                   ,NULL                                              -- gl_date
                   ,r1.icms_tax * -1                                  -- tax_rate
                   ,x_tax_code                                        -- tax_code
                   ,r1.created_by                                     -- created_by
                   ,r1.creation_date                                  -- creation_date
                   ,r1.last_updated_by                                -- last_updated_by
                   ,r1.last_update_date                               -- last_update_date
                   ,r1.last_update_login                              -- last_update_login
                   ,x_operating_unit                                  -- org_id
                   /*
                   ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                   ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.freight_amount_header
                                    , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.insurance_amount_header
                                    , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.other_expenses_header
                                    , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                   --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- header_gdf_attr_category   -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                        -- Bug 5371080 --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- line_gdf_attr_category     -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                          -- Bug 5371080 --
                   ,r1.cfo_code                                       -- line_gdf_attribute1
                   -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                   -- ,NVL(r1.classification_code,v_category_concat_segs)-- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008  BUG 10355568
                   ,r1.classification_code                             -- line_gdf_attribute2 -- BUG 10355568
                   ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                   --,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                   ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                   ,x_global_attribute4                               -- line_gdf_attribute5
                   -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,x_sit_trib_est                                    -- line_gdf_attribute7
                   -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,x_ra_term_id                                      -- term_id
                   /*
                   ,r1.icms_base *-1                                  -- line_gdf_attribute11
                   ,r1.icms_amount *-1                                -- line_gdf_attribute19
                   ,r1.icms_amount *-1  --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   --(++) Rantonio, 27/08/2007; BUG 6322784 --,r1.ipi_amount *-1 -- line_gdf_attribute20 -- BUG 4044106 -- BUG 6 Equaliz 6774760 - rvicente - 25/01/2008
                   */

                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_base *-1
                                    , l_gl_precision ))               -- line_gdf_attribute11 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_amount *-1
                                    , l_gl_precision ))               -- line_gdf_attribute19 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_amount *-1
                                    , l_gl_precision ))               -- line_gdf_attribute20 -- Bug 14400588
                   --
                   ,r1.salesrep_id
                   ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
        --
      END IF;
      --
    END IF;
    IF r1.icms_st_amount > 0 THEN
      --    IF r1.icms_st_amount > 0 AND nvl(r1.simplified_br_tax_flag,'N') = 'N' THEN -- ER 9289619
      IF r1.ar_cred_icms_st_category_id IS NOT NULL THEN
        BEGIN
          SELECT avt.tax_code
            INTO x_tax_code
            FROM jl_zz_ar_tx_categ_all jza,
                 ar_vat_tax_vl         avt
           WHERE jza.tax_category_id   = r1.ar_cred_icms_st_category_id
             AND jza.org_id            = x_operating_unit
             AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
             -- 21842498 - Start
             AND avt.enabled_flag     = 'Y'
             AND avt.start_date <= sysdate
             AND nvl(avt.end_date, sysdate + 1) > sysdate
             -- 21842498 - End
             AND ROWNUM                = 1;
        EXCEPTION
          WHEN others THEN
            raise_application_error
                 (-20552, x_module_name||' - ERROR:  '||SQLERRM||' Selecting ICMS ST tax code.');
        END;
        --
        INSERT INTO ra_interface_lines_all
                   (interface_line_id
                   ,amount_includes_tax_flag
                   ,interface_line_context
                   ,interface_line_attribute1
                   ,interface_line_attribute2
                   ,interface_line_attribute3
                   ,interface_line_attribute4
                   ,interface_line_attribute5
                   ,batch_source_name
                   ,link_to_line_context
                   ,link_to_line_attribute1
                   ,link_to_line_attribute2
                   ,link_to_line_attribute3
                   ,link_to_line_attribute4
                   ,link_to_line_attribute5
                   ,set_of_books_id
                   ,line_type
                   ,description
                   ,currency_code
                   ,amount
                   ,cust_trx_type_id
                   ,orig_system_bill_customer_id
                   ,orig_system_bill_address_id
                   ,orig_system_ship_customer_id
                   ,orig_system_ship_address_id
                   ,conversion_type
                   ,conversion_rate
                   ,gl_date
                   ,tax_rate
                   --,tax_code BUG 7715719 - rvicente - 21/01/2009
                   ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                   ,created_by
                   ,creation_date
                   ,last_updated_by
                   ,last_update_date
                   ,last_update_login
                   ,org_id
                   ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,header_gdf_attribute10 -- Bug 14582853
                   ,header_gdf_attribute11 -- Bug 14582853
                   ,header_gdf_attr_category
                   ,line_gdf_attr_category
                   ,line_gdf_attribute1
                   ,line_gdf_attribute2
                   ,line_gdf_attribute3
                   ,line_gdf_attribute4
                   ,line_gdf_attribute5
                   ,line_gdf_attribute6
                   ,line_gdf_attribute7
                   ,line_gdf_attribute8
                   ,line_gdf_attribute9
                   ,line_gdf_attribute10
                   ,term_id
                   ,line_gdf_attribute11
                   ,line_gdf_attribute19
                   ,line_gdf_attribute20
                   ,primary_salesrep_id
                   ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
           VALUES
                   (NULL                                              -- interface_line_id
                   ,'N'                                               -- amount_includes_tax_flag
                   ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                   ,r1.operation_id                                   -- interface_line_attribute1
                   ,r1.organization_id                                -- interface_line_attribute2
                   ,r1.invoice_id                                     -- interface_line_attribute3
                   ,r1.invoice_line_id                                -- interface_line_attribute4
                   ,3                                                 -- interface_line_attribute5
                   ,r1.rbsa_name                                      -- batch_source_name
                   ,'CLL F189 INTEGRATED RCV'                         -- link_to_line_context
                   ,r1.operation_id                                   -- link_to_line_attribute1
                   ,r1.organization_id                                -- link_to_line_attribute2
                   ,r1.invoice_id                                     -- link_to_line_attribute3
                   ,r1.invoice_line_id                                -- link_to_line_attribute4
                   ,'0'                                               -- link_to_line_attribute5
                   ,x_set_of_books_id                                 -- set_of_books_id
                   ,'TAX'                                             -- line_type
                   ,'ICMS ST'                                         -- description
                   ,x_currency_code                                   -- currency_code
                   ,ROUND(r1.icms_st_amount, l_gl_precision)          -- amount -- Bug 14400588
                   -- ,r1.icms_st_amount                                 -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   --(++),NULL                                              -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                   ,r1.customer_id                                    -- orig_system_bill_customer_id
                   ,NULL                                              -- orig_system_bill_address_id
                   ,r1.customer_id                                    -- orig_system_ship_customer_id
                   ,NULL                                              -- orig_system_ship_address_id
                   ,'User'                                            -- conversion_type
                   ,1                                                 -- conversion_rate
                   ,NULL                                              -- gl_date
                   --,r1.icms_st_tax                                    -- tax_rate -- Bug 16395868
                   ,round(r1.icms_st_tax, l_gl_precision)             -- tax_rate -- Bug 16395868
                   ,x_tax_code                                        -- tax_code
                   ,r1.created_by                                     -- created_by
                   ,r1.creation_date                                  -- creation_date
                   ,r1.last_updated_by                                -- last_updated_by
                   ,r1.last_update_date                               -- last_update_date
                   ,r1.last_update_login                              -- last_update_login
                   ,x_operating_unit                                  -- org_id
                   /*
                   ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                   ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.freight_amount_header
                                    , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.insurance_amount_header
                                    , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.other_expenses_header
                                    , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                   --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- header_gdf_attr_category   -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                        -- Bug 5371080 --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- line_gdf_attr_category     -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                          -- Bug 5371080 --
                   ,r1.cfo_code                                       -- line_gdf_attribute1
                   -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                   -- ,NVL(r1.classification_code,v_category_concat_segs)-- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008 -- BUG 10355568
                   ,r1.classification_code                            -- line_gdf_attribute2 -- BUG 10355568
                   ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                   --,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                   ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                   ,x_global_attribute4                               -- line_gdf_attribute5
                   -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,x_sit_trib_est                                    -- line_gdf_attribute7
                   -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,x_ra_term_id                                      -- term_id
                   /*
                   -- ,r1.icms_base                                      -- line_gdf_attribute11 -- Bug 5962449 - SSimoes - 04/04/2007
                   -- ,r1.icms_amount                                    -- line_gdf_attribute19 -- Bug 5962449 - SSimoes - 04/04/2007
                   ,r1.icms_st_base                                   -- line_gdf_attribute11 -- Bug 5962449 - SSimoes - 04/04/2007
                   ,r1.icms_st_amount                                 -- line_gdf_attribute19 -- Bug 5962449 - SSimoes - 04/04/2007
                   ,r1.icms_st_amount --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   --,r1.ipi_amount   --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG 4044106 -- BUG 6774760 - rvicente - 25/01/2008
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_st_base
                                    , l_gl_precision ))               -- line_gdf_attribute11 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_st_amount
                                    , l_gl_precision ))               -- line_gdf_attribute19 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_st_amount
                                    , l_gl_precision ))               -- line_gdf_attribute20 -- Bug 14400588
                   --
                   ,r1.salesrep_id
                   ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
        --
      END IF;
      --
      IF r1.ar_deb_icms_st_category_id IS NOT NULL THEN
        BEGIN
          SELECT avt.tax_code
            INTO x_tax_code
            FROM jl_zz_ar_tx_categ_all jza,
                 ar_vat_tax_vl         avt
           WHERE jza.tax_category_id   = r1.ar_deb_icms_st_category_id
             AND jza.org_id            = x_operating_unit
             AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
             -- 21842498 - Start
             AND avt.enabled_flag     = 'Y'
             AND avt.start_date <= sysdate
             AND nvl(avt.end_date, sysdate + 1) > sysdate
             -- 21842498 - End
             AND ROWNUM                = 1;
        EXCEPTION
          WHEN others THEN
            raise_application_error (-20553, x_module_name||' - ERROR:  '|| SQLERRM ||' Selecting ICMS ST tax code.');
        END;
        --
        INSERT INTO ra_interface_lines_all
                   (interface_line_id
                   ,amount_includes_tax_flag
                   ,interface_line_context
                   ,interface_line_attribute1
                   ,interface_line_attribute2
                   ,interface_line_attribute3
                   ,interface_line_attribute4
                   ,interface_line_attribute5
                   ,batch_source_name
                   ,link_to_line_context
                   ,link_to_line_attribute1
                   ,link_to_line_attribute2
                   ,link_to_line_attribute3
                   ,link_to_line_attribute4
                   ,link_to_line_attribute5
                   ,set_of_books_id
                   ,line_type
                   ,description
                   ,currency_code
                   ,amount
                   ,cust_trx_type_id
                   ,orig_system_bill_customer_id
                   ,orig_system_bill_address_id
                   ,orig_system_ship_customer_id
                   ,orig_system_ship_address_id
                   ,conversion_type
                   ,conversion_rate
                   ,gl_date
                   ,tax_rate
                   --,tax_code BUG 7715719 - rvicente - 21/01/2009
                   ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                   ,created_by
                   ,creation_date
                   ,last_updated_by
                   ,last_update_date
                   ,last_update_login
                   ,org_id
                   ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,header_gdf_attribute10 -- Bug 14582853
                   ,header_gdf_attribute11 -- Bug 14582853
                   ,header_gdf_attr_category
                   ,line_gdf_attr_category
                   ,line_gdf_attribute1
                   ,line_gdf_attribute2
                   ,line_gdf_attribute3
                   ,line_gdf_attribute4
                   ,line_gdf_attribute5
                   ,line_gdf_attribute6
                   ,line_gdf_attribute7
                   ,line_gdf_attribute8
                   ,line_gdf_attribute9
                   ,line_gdf_attribute10
                   ,term_id
                   ,line_gdf_attribute11
                   ,line_gdf_attribute19
                   ,line_gdf_attribute20
                   ,primary_salesrep_id
                   ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
             VALUES
                   (NULL                                              -- interface_line_id
                   ,'N'                                               -- amount_includes_tax_flag
                   ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                   ,r1.operation_id                                   -- interface_line_attribute1
                   ,r1.organization_id                                -- interface_line_attribute2
                   ,r1.invoice_id                                     -- interface_line_attribute3
                   ,r1.invoice_line_id                                -- interface_line_attribute4
                   ,4                                                 -- interface_line_attribute5
                   ,r1.rbsa_name                                      -- batch_source_name
                   ,'CLL F189 INTEGRATED RCV'                         -- link_to_line_context
                   ,r1.operation_id                                   -- link_to_line_attribute1
                   ,r1.organization_id                                -- link_to_line_attribute2
                   ,r1.invoice_id                                     -- link_to_line_attribute3
                   ,r1.invoice_line_id                                -- link_to_line_attribute4
                   ,'0'                                               -- link_to_line_attribute5
                   ,x_set_of_books_id                                 -- set_of_books_id
                   ,'TAX'                                             -- line_type
                   ,'ICMS ST'                                         -- description
                   ,x_currency_code                                   -- currency_code
                   ,ROUND(r1.icms_st_amount *-1, l_gl_precision)      -- amount -- Bug 14400588
                   -- ,r1.icms_st_amount *-1                             -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   -- ,NULL                                              -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                   ,r1.customer_id                                    -- orig_system_bill_customer_id
                   ,NULL                                              -- orig_system_bill_address_id
                   ,r1.customer_id                                    -- orig_system_ship_customer_id
                   ,NULL                                              -- orig_system_ship_address_id
                   ,'User'                                            -- conversion_type
                   ,1                                                 -- conversion_rate
                   ,NULL                                              -- gl_date
                   --,r1.icms_st_tax * -1                               -- tax_rate -- Bug 16395868
                   ,round(r1.icms_st_tax, l_gl_precision) * -1        -- tax_rate -- Bug 16395868
                   ,x_tax_code                                        -- tax_code
                   ,r1.created_by                                     -- created_by
                   ,r1.creation_date                                  -- creation_date
                   ,r1.last_updated_by                                -- last_updated_by
                   ,r1.last_update_date                               -- last_update_date
                   ,r1.last_update_login                              -- last_update_login
                   ,x_operating_unit                                  -- org_id
                   /*
                   ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                   ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.freight_amount_header
                                    , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.insurance_amount_header
                                    , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.other_expenses_header
                                    , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                   --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- header_gdf_attr_category   -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                        -- Bug 5371080 --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')   -- line_gdf_attr_category     -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                          -- Bug 5371080 --
                   ,r1.cfo_code                                       -- line_gdf_attribute1
                   -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                   -- ,NVL(r1.classification_code,v_category_concat_segs)-- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008 -- BUG 10355568
                   ,r1.classification_code                              -- line_gdf_attribute2 -- BUG 10355568
                   ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                   --,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                   ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                   ,x_global_attribute4                               -- line_gdf_attribute5
                   -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,x_sit_trib_est                                    -- line_gdf_attribute7
                   -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,x_ra_term_id                                      -- term_id
                   /*
                   -- ,r1.icms_base *-1                                  -- line_gdf_attribute11 -- Bug 5962449 - SSimoes - 04/04/2007
                   -- ,r1.icms_amount *-1                                -- line_gdf_attribute19 -- Bug 5962449 - SSimoes - 04/04/2007
                   ,r1.icms_st_base *-1                               -- line_gdf_attribute11 -- Bug 5962449 - SSimoes - 04/04/2007
                   ,r1.icms_st_amount *-1                             -- line_gdf_attribute19 -- Bug 5962449 - SSimoes - 04/04/2007
                   ,r1.icms_st_amount *-1 --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   --,r1.ipi_amount *-1   --(++) Rantonio, 27/08/2007; BUG 6322784 -- line_gdf_attribute20 -- BUG 4044106 -- BUG 6774760 - rvicente - 25/01/2008
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_st_base *-1
                                    , l_gl_precision ))               -- line_gdf_attribute11 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_st_amount *-1
                                    , l_gl_precision ))               -- line_gdf_attribute19 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.icms_st_amount *-1
                                    , l_gl_precision ))               -- line_gdf_attribute20 -- Bug 14400588
                   --
                   ,r1.salesrep_id
                   ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
        --
      END IF;
    END IF;
    --
    IF r1.ipi_amount > 0 THEN
      IF r1.ar_cred_ipi_category_id IS NOT NULL THEN
        BEGIN
          SELECT avt.tax_code
            INTO x_tax_code
            FROM jl_zz_ar_tx_categ_all jza,
                 ar_vat_tax_vl         avt
           WHERE jza.tax_category_id   = r1.ar_cred_ipi_category_id
             AND jza.org_id            = x_operating_unit
             AND avt.global_attribute1 = TO_CHAR(jza.tax_category_id) -- BUG 7666730 rvicente 06/01/09
             -- 21842498 - Start
             AND avt.enabled_flag     = 'Y'
             AND avt.start_date <= sysdate
             AND nvl(avt.end_date, sysdate + 1) > sysdate
             -- 21842498 - End
             AND ROWNUM                = 1;
        EXCEPTION
          WHEN others THEN
            raise_application_error (-20554, x_module_name||' - ERROR:  '|| SQLERRM ||' Selecting IPI tax code.');
        END;
        --
        INSERT INTO ra_interface_lines_all
                   (interface_line_id
                   ,amount_includes_tax_flag
                   ,interface_line_context
                   ,interface_line_attribute1
                   ,interface_line_attribute2
                   ,interface_line_attribute3
                   ,interface_line_attribute4
                   ,interface_line_attribute5
                   ,batch_source_name
                   ,link_to_line_context
                   ,link_to_line_attribute1
                   ,link_to_line_attribute2
                   ,link_to_line_attribute3
                   ,link_to_line_attribute4
                   ,link_to_line_attribute5
                   ,set_of_books_id
                   ,line_type
                   ,description
                   ,currency_code
                   ,amount
                   ,cust_trx_type_id
                   ,orig_system_bill_customer_id
                   ,orig_system_bill_address_id
                   ,orig_system_ship_customer_id
                   ,orig_system_ship_address_id
                   ,conversion_type
                   ,conversion_rate
                   ,gl_date
                   ,tax_rate
                   --,tax_code BUG 7715719 - rvicente - 21/01/2009
                   ,tax_rate_code -- BUG 7715719 - rvicente - 21/01/2009
                   ,created_by
                   ,creation_date
                   ,last_updated_by
                   ,last_update_date
                   ,last_update_login
                   ,org_id
                   ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,header_gdf_attribute10 -- Bug 14582853
                   ,header_gdf_attribute11 -- Bug 14582853
                   ,header_gdf_attr_category
                   ,line_gdf_attr_category
                   ,line_gdf_attribute1
                   ,line_gdf_attribute2
                   ,line_gdf_attribute3
                   ,line_gdf_attribute4
                   ,line_gdf_attribute5
                   ,line_gdf_attribute6
                   ,line_gdf_attribute7
                   ,line_gdf_attribute8
                   ,line_gdf_attribute9
                   ,line_gdf_attribute10
                   ,term_id
                   ,line_gdf_attribute11
                   ,line_gdf_attribute19
                   ,line_gdf_attribute20
                   ,primary_salesrep_id
                   ,fob_point)                                     -- Enh 6860943 - SSimoes - 03/03/2008
             VALUES
                   (NULL                                              -- interface_line_id
                   ,'N'                                               -- amount_includes_tax_flag
                   ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
                   ,r1.operation_id                                   -- interface_line_attribute1
                   ,r1.organization_id                                -- interface_line_attribute2
                   ,r1.invoice_id                                     -- interface_line_attribute3
                   ,r1.invoice_line_id                                -- interface_line_attribute4
                   ,5                                                 -- interface_line_attribute5
                   ,r1.rbsa_name                                      -- batch_source_name
                   ,'CLL F189 INTEGRATED RCV'                         -- link_to_line_context
                   ,r1.operation_id                                   -- link_to_line_attribute1
                   ,r1.organization_id                                -- link_to_line_attribute2
                   ,r1.invoice_id                                     -- link_to_line_attribute3
                   ,r1.invoice_line_id                                -- link_to_line_attribute4
                   ,'0'                                               -- link_to_line_attribute5
                   ,x_set_of_books_id                                 -- set_of_books_id
                   ,'TAX'                                             -- line_type
                   ,'IPI'                                             -- description
                   ,x_currency_code                                   -- currency_code
                   ,ROUND(r1.ipi_amount, l_gl_precision)              -- amount -- Bug 14400588
                   -- ,r1.ipi_amount                                     -- amount -- (++) Rantonio, 22/08/2007;BUG 6322784 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   -- ,NULL                                              -- amount -- (++) Rantonio, 03/07/2007;BUG 6114236 -- BUG Equaliz 6771456 - rvicente - 25/01/2008
                   ,r1.ar_transaction_type_id                         -- cust_trx_type_id
                   ,r1.customer_id                                    -- orig_system_bill_customer_id
                   ,NULL                                              -- orig_system_bill_address_id
                   ,r1.customer_id                                    -- orig_system_ship_customer_id
                   ,NULL                                              -- orig_system_ship_address_id
                   ,'User'                                            -- conversion_type
                   ,1                                                 -- conversion_rate
                   ,NULL                                              -- gl_date
                   ,r1.ipi_tax                                        -- tax_rate
                   ,x_tax_code                                        -- tax_code
                   ,r1.created_by                                     -- created_by
                   ,r1.creation_date                                  -- creation_date
                   ,r1.last_updated_by                                -- last_updated_by
                   ,r1.last_update_date                               -- last_update_date
                   ,r1.last_update_login                              -- last_update_login
                   ,x_operating_unit                                  -- org_id
                   /*
                   ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 29/06/2009
                   ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
                   ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.freight_amount_header
                                    , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.insurance_amount_header
                                    , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.other_expenses_header
                                    , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
                   --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- header_gdf_attr_category    -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category                        -- Bug 5371080 --
                   -- ,NVL(x_global_attribute_category,'JL.BR.ARXTWMAI.Additional Info')  -- line_gdf_attr_category      -- Bug 5371080 --
                   ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category                          -- Bug 5371080 --
                   ,r1.cfo_code                                       -- line_gdf_attribute1
                   -- ,NVL(r1.classification_code,x_global_attribute1)   -- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008
                   -- ,NVL(r1.classification_code,v_category_concat_segs)-- line_gdf_attribute2 -- Bug 6778641 AIrmer 29/01/2008 -- BUG 10355568
                   ,r1.classification_code                            -- line_gdf_attribute2 -- BUG 10355568
                   ,NVL(r1.utilization_code,x_global_attribute2)      -- line_gdf_attribute3
                   --,NVL(r1.source_items,x_global_attribute3)          -- line_gdf_attribute4 -- Bug 16850244
                   ,NVL(r1.sit_trib_code, x_global_attribute3)        -- line_gdf_attribute4 -- Bug 16850244
                   ,x_global_attribute4                               -- line_gdf_attribute5
                   -- ,x_global_attribute5                               -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,r1.ipi_tax_code                                   -- line_gdf_attribute6 -- Bug 4486071 AIrmer 19/08/2005
                   ,x_sit_trib_est                                    -- line_gdf_attribute7
                   -- ,SUBSTR(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,1,150)                         -- line_gdf_attribute8 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,151,150)                       -- line_gdf_attribute9 -- Bug 7233280 SSimoes 29/09/2008
                   -- ,SUBSTR(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,SUBSTRB(x_mensagem,301,150)                       -- line_gdf_attribute10 -- Bug 7233280 SSimoes 29/09/2008
                   ,x_ra_term_id                                      -- term_id
                   /*
                   ,r1.ipi_base_amount -- line_gdf_attribute11 --(++) Rantonio, 18/09/2007; -- line_gdf_attribute11 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   --,r1.icms_base     -- line_gdf_attribute11 --(++) Rantonio, 18/09/2007; -- line_gdf_attribute11 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   ,r1.ipi_amount      -- line_gdf_attribute19 --(++) Rantonio, 18/09/2007; -- line_gdf_attribute11 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   --,r1.icms_amount   -- line_gdf_attribute20 --(++) Rantonio, 18/09/2007; -- line_gdf_attribute11 -- BUG Equaliz 6774760 - rvicente - 25/01/2008
                   ,r1.ipi_amount                                     -- line_gdf_attribute20 -- BUG 4044106
                   */
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.ipi_base_amount
                                    , l_gl_precision ))               -- line_gdf_attribute11 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.ipi_amount
                                    , l_gl_precision ))               -- line_gdf_attribute19 -- Bug 14400588
                   ,fnd_number.number_to_canonical(
                               ROUND( r1.ipi_amount
                                    , l_gl_precision ))               -- line_gdf_attribute20 -- Bug 14400588
                   --
                   ,r1.salesrep_id
                   ,x_fob_point);                                     -- Enh 6860943 - SSimoes - 03/03/2008
          --
        END IF;
      END IF;
      --
      -- Bug 8577461 - SSimoes - 09/06/2009 - Inicio
      --
      IF r1.invoice_id <> x_invoice_id_ant AND
         r1.freight_amount_header > 0 THEN
         --
         INSERT INTO ra_interface_lines_all
               (interface_line_id
               ,amount_includes_tax_flag
               ,interface_line_context
               ,interface_line_attribute1
               ,interface_line_attribute2
               ,interface_line_attribute3
               ,interface_line_attribute4
               ,interface_line_attribute5
               ,batch_source_name
               ,set_of_books_id
               ,line_type
               ,description
               ,currency_code
               ,amount
               ,cust_trx_type_id
               ,orig_system_bill_customer_id
               ,orig_system_bill_address_id
               ,orig_system_ship_customer_id
               ,orig_system_ship_address_id
               ,conversion_type
               ,conversion_rate
               ,created_by
               ,creation_date
               ,last_updated_by
               ,last_update_date
               ,last_update_login
               ,org_id
               ,header_gdf_attribute9 -- Bug 8577461 - SSimoes - 19/06/2009
               ,header_gdf_attribute10 -- Bug 14582853
               ,header_gdf_attribute11 -- Bug 14582853
               ,header_gdf_attr_category
               ,line_gdf_attr_category
               ,warehouse_id
               ,term_id
               ,primary_salesrep_id
               ,fob_point)
         VALUES
               (NULL                                              -- interface_line_id
               ,'N'                                               -- amount_includes_tax_flag
               ,'CLL F189 INTEGRATED RCV'                         -- interface_line_context
               ,r1.operation_id                                   -- interface_line_attribute1
               ,r1.organization_id                                -- interface_line_attribute2
               ,r1.invoice_id                                     -- interface_line_attribute3
               ,r1.invoice_line_id                                -- interface_line_attribute4
               ,6                                                 -- interface_line_attribute5
               ,r1.rbsa_name                                      -- batch_source_name
               ,x_set_of_books_id                                 -- set_of_books_id
               ,'FREIGHT'                                         -- line_type
               ,'Freight'                                         -- description
               ,x_currency_code                                   -- currency_code
               ,ROUND(r1.freight_amount_header
                    + r1.insurance_amount_header                  -- Bug 20646467 ASaraiva 04/05/2015
                    + r1.other_expenses_header                    -- Bug 20646467 ASaraiva 04/05/2015
                   , l_gl_precision)   -- amount -- Bug 14400588
               --               ,r1.freight_amount_header                          -- amount
               ,r1.ar_transaction_type_id                         -- cust_trx_type_id
               ,r1.customer_id                                    -- orig_system_bill_customer_id
               ,r1.address_id                                     -- orig_system_bill_address_id
               ,r1.customer_id                                    -- orig_system_ship_customer_id
               ,r1.address_id                                     -- orig_system_ship_address_id
               ,'User'                                            -- conversion_type
               ,1                                                 -- conversion_rate
               ,r1.created_by                                     -- created_by
               ,r1.creation_date                                  -- creation_date
               ,r1.last_updated_by                                -- last_updated_by
               ,r1.last_update_date                               -- last_update_date
               ,r1.last_update_login                              -- last_update_login
               ,x_operating_unit                                  -- org_id
               /*
               ,r1.freight_amount_header                          -- header_gdf_attribute9 -- Bug 8577461 - SSimoes - 19/06/2009
               ,r1.insurance_amount_header                        -- header_gdf_attribute10 -- Bug 14582853
               ,r1.other_expenses_header                          -- header_gdf_attribute11 -- Bug 14582853
               */
               ,fnd_number.number_to_canonical(
                           ROUND( r1.freight_amount_header
                                , l_gl_precision ))               -- header_gdf_attribute9  -- Bug 14400588
               ,fnd_number.number_to_canonical(
                           ROUND( r1.insurance_amount_header
                                , l_gl_precision ))               -- header_gdf_attribute10 -- Bug 14400588
               ,fnd_number.number_to_canonical(
                           ROUND( r1.other_expenses_header
                                , l_gl_precision ))               -- header_gdf_attribute11 -- Bug 14400588
               --
               ,'JL.BR.ARXTWMAI.Additional Info'                  -- header_gdf_attr_category
               ,'JL.BR.ARXTWMAI.Additional Info'                  -- line_gdf_attr_category
               ,r1.organization_id                                -- warehouse_id
               ,x_ra_term_id                                      -- term_id
               ,r1.salesrep_id                                    -- primary_salesrep_id
               ,x_fob_point);                                     -- fob_point
        --
      END IF;
      --
      -- Bug 8577461 - SSimoes - 09/06/2009 - Fim
      --
      x_mensagem       := NULL;
      x_mensagem_aux   := NULL;
      x_invoice_id_ant := r1.invoice_id;
      --
      UPDATE cll_f189_invoices
         SET ar_interface_flag = 'Y'
       WHERE invoice_id = r1.invoice_id;
      --
    END LOOP;
END ar_tpa ;
--
END xxfr_f189_interface_pkg;
