create or replace package XXFR_PCK_SINCRONIZAR_NOTA is

  -- Author  : DANIEL PIMENTA
  -- Created : 29/01/2020 07:54:50
  -- Purpose : 

  g_versao_payload constant varchar2(5) := '1.0';
  g_cd_servico     constant varchar2(100) := 'SINCRONIZAR_NOTA_FISCAL';

  type rec_percurso is record(
    "codigoCarregamento"                  varchar2(20),
    "numeroRomaneio"                      varchar2(20),
    "tipoRefOrigemLinhaEntrega"           varchar2(50),
    "codRefOrigemLinhaEntrega"            varchar2(20)
  );
  
  type rec_oe_referencia is record(
    "numeroOrdemVenda"            varchar2(20),
    "codigoTipoOrdemVenda"        varchar2(20),
    "numeroLinhaOrdemVenda"       varchar2(20),
    "numeroEnvioLinhaOrdemVenda"  varchar2(20),
    "codigoTipoOrdemVendaLinha"   varchar2(20),
    "tipoReferenciaOrigemLinha"   varchar2(50),
    "codigoReferenciaOrigemLinha" varchar2(20)
  );
  type tab_oe_referencia is table of rec_oe_referencia index by binary_integer;

  type rec_ordem_separacao_semente is record(
    "areaAtendida"                  number
  );

  type rec_ordem_venda is record(
    "numeroOrdemVenda"                        varchar2(50),
    "codigoTipoOrdemVenda"                    varchar2(50),
    "tipoReferenciaOrigem"                    varchar2(50),
    "codigoReferenciaOrigem"                  varchar2(50),
    --
    "numeroLinhaOrdemVenda"                   varchar2(50),
    "numeroEnvioLinhaOrdemVenda"              varchar2(50),
    "codigoTipoOrdemVendaLinha"               varchar2(50),
    "tipoReferenciaOrigemLinha"               varchar2(50),    
    "codigoReferenciaOrigemLinha"             varchar2(50),
    --
    "percurso"                                rec_percurso,
    "oeReferencia"                            tab_oe_referencia
  );
  --type tab_ordem_venda is table of rec_ordem_venda index by binary_integer;

  type rec_lotes is record(
    "codigo"        varchar2(50),
    "quantidade"    number,
    "ordemSeparacaoSemente"                   rec_ordem_separacao_semente
  );
  type tab_lotes is table of rec_lotes index by binary_integer;

  type rec_itens is record(
    "numeroLinha"   varchar2(50),
    "codigoItem"    varchar2(50),
    "quantidade"    number,
    "unidadeMedida" varchar2(50),
    "valorUnitario" number,
    "codigoMoeda"   varchar2(50),
    "observacao"    varchar2(400),
    "lotes"         tab_lotes,
    "ordemVenda"    rec_ordem_venda
  );
  type tab_itens is table of rec_itens index by binary_integer;

  type rec_nota_fiscal is record(
    "codigoOrganizacaoInventario"   varchar2(50),
    "numeroCnpjFilial"              varchar2(50),
    "dataCriacao"                   varchar2(50),
    "numeroNotaFiscal"              varchar2(50),
    "codigoSerie"                   varchar2(50),
    "dataEmissao"                   varchar2(50),
    "codigoCliente"                 varchar2(50),
    "numeroPropriedadeEntrega"      number,
    "numeroPropriedadeFaturamento"  number,
    "observacao"                    varchar2(400),
    "chaveNotaFiscal"               varchar2(50),
    "tipoDocumento"                 varchar2(50),
    "codigoOrigemTransacao"         varchar2(50),
    "itens"                         tab_itens
  );
  
  type rec_publica is record(
    "codigoUnidadeOperacional"  varchar2(50),
    "notaFiscal"                rec_nota_fiscal
  );
  
  w_obj_processar               xxfr_pljson;
  
  procedure print_log(msg   in Varchar2);
  
  procedure registrar(
    p_sistema_origem          varchar2,
    p_publica                 rec_publica,
    p_id_integracao_cabecalho out NUMBER,
    p_id_integracao_detalhe   out NUMBER,
    p_ie_status               out NOCOPY varchar2
  );

  procedure processar(
    p_id_integracao_cabecalho in number,
    p_id_integracao_detalhe   in number,
    p_ie_status               out nocopy varchar2,
    p_id_integracao_chave     out number
  );

  function mount(
    p_sistema_origem varchar2,
    p_publica    rec_publica
  ) return xxfr_pljson;
  
end XXFR_PCK_SINCRONIZAR_NOTA;
