create or replace PACKAGE xxfr_f189_check_holds_pkg AUTHID CURRENT_USER AS
  /* $Header: CLLVRIHS.pls 120.5 2019/08/05 14:17:45 sasimoes noship $ */
  FUNCTION func_check_holds(p_organization_id      IN NUMBER,
                            p_location_id          IN NUMBER,
                            p_operation_id         IN NUMBER,
                            p_freight_flag         IN VARCHAR2,
                            p_total_freight_weight IN NUMBER,
                            p_interface            IN VARCHAR2 DEFAULT 'N',
                            p_interface_invoice_id IN NUMBER DEFAULT NULL
                            ) RETURN NUMBER;

  PROCEDURE incluir_erro(p_invoice_id             IN NUMBER,
                         p_interface_operation_id IN NUMBER,
                         error_code               IN VARCHAR2,
                         p_invoice_line_id        IN NUMBER DEFAULT NULL);

  PROCEDURE incluir_erro_hold(p_operation_id    IN NUMBER,
                              p_organization_id IN NUMBER,
                              p_location_id     IN NUMBER,
                              p_hold_code       IN VARCHAR2,
                              p_invoice_id      IN NUMBER,
                              p_invoice_line_id IN NUMBER);
  --
END xxfr_f189_check_holds_pkg;
