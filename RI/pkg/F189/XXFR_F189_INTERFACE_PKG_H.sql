create or replace PACKAGE xxfr_f189_interface_pkg AUTHID CURRENT_USER AS
/* $Header: CLLVRIBS.pls 120.6 2018/03/28 17:23:11 eltgini noship $ */
  
  procedure print_log(msg in varchar2);

  PROCEDURE fa ( 
    p_operation_id      IN   NUMBER,
    p_organization_id   IN   NUMBER,
    p_created_by        IN   NUMBER
  );
  
  PROCEDURE fsc ( 
    p_operation_id      IN   NUMBER,
    p_organization_id   IN   NUMBER,
    p_created_by        IN   NUMBER
  );
  
  PROCEDURE gl (p_operation_id IN NUMBER, p_organization_id IN NUMBER);
  
  PROCEDURE ap ( 
    p_operation_id      IN   NUMBER,
    p_organization_id   IN   NUMBER,
    p_org_id            IN   NUMBER,
    p_created_by        IN   NUMBER
  );
  
  PROCEDURE ar ( 
    p_operation_id IN NUMBER,
    p_organization_id IN NUMBER
  );
  
  PROCEDURE pa ( 
    p_operation_id IN NUMBER,
    p_organization_id IN NUMBER
  );
  
  PROCEDURE count_insert_desc_ar(
    p_invoice_id IN NUMBER,
    p_count      OUT NOCOPY NUMBER,
    p_desc       OUT NOCOPY VARCHAR2
  );
  
  PROCEDURE count_insert_desc_ar_tpa ( 
    p_organization_id  IN NUMBER
    , p_operation_id     IN NUMBER
    , p_count           OUT NOCOPY NUMBER
    , p_desc            OUT NOCOPY VARCHAR2 
  ) ; -- BUG-26338366: CLL_F513 THIRD PARTY MATERIAL
  
  PROCEDURE ar_tpa ( 
    p_operation_id IN NUMBER, 
    p_organization_id IN NUMBER
  ) ; -- BUG-26338366: CLL_F513 THIRD PARTY MATERIAL

END xxfr_f189_interface_pkg;