create or replace package XXFR_FCX_PCK_CLIENTES IS
  
  type cliente_rec_type is record (  
    org_id			      number, 
    nome              varchar2(300),
    tipo_documento    varchar2(1),
    documento         varchar2(20),
    inscricao         varchar2(20),
    endereco          varchar2(300),
    numero            varchar2(20),
    complemento       varchar2(50),
    bairro            varchar2(50),
    cep               varchar2(8),
    cidade            varchar2(50),
    estado            varchar2(2),
    --
    ddd               varchar2(3),
    cel_numero        varchar2(15),
    email			        varchar2(200)
  );

  procedure criar_cliente (
    p_cliente       in cliente_rec_type,
    x_vendor_id     out number,
    x_customer_id   out number,
    x_return_status out VARCHAR2,
    x_msg_count     out NUMBER,
    x_msg_data      out VARCHAR2
  );

end XXFR_FCX_PCK_CLIENTES;