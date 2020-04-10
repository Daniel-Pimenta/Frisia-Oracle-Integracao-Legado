create or replace package XXFR_PCK_SINCRONIZAR_NOTA is

  -- Author  : RENATO.SAMPAIO
  -- Created : 29/01/2020 07:54:50
  -- Purpose : 

  g_versao_payload constant varchar2(5) := '1.0';
  g_cd_servico     constant varchar2(100) := 'PUBLICAR_NOTA_FISCAL';

  type rec_ordem_venda is record(
    "numeroOrdemVenda"       varchar2(50),
    "codigoTipoOrdemVenda"   varchar2(50),
    "numeroLinha"            varchar2(50),
    "tipoReferenciaOrigem"   varchar2(50),
    "codigoReferenciaOrigem" varchar2(50),
    "areaAtendida"           number
  );
  
  --type tab_ordem_venda is table of rec_ordem_venda index by binary_integer;

  type rec_item_nota_fiscal is record(
    "numeroLinha"   varchar2(20),
    "codigoItem"    varchar2(20),
    "quantidade"    varchar2(20),
    "unidadeMedida" varchar2(20),
    "valorUnitario" number,
    "codigoMoeda"   varchar2(30),
    "codigoLote"    varchar2(50),
    "observacao"    varchar2(4000),
    --"ordensVenda"   tab_ordem_venda,
    "ordensVenda"   rec_ordem_venda
  );
  type tab_item_nota_fiscal is table of rec_item_nota_fiscal index by binary_integer;

  type rec_nota_fiscal is record(
    "codigounidadeOperacional"     varchar2(50),
    "numeroCnpjFilial"             varchar2(50),
    "nomeFilial"                   varchar2(50),
    "dataCriacao"                  varchar2(50),
    "numeroNotaFiscal"             varchar2(50),
    "codigoSerie"                  varchar2(50),
    "dataEmissao"                  varchar2(50),
    "codigoCliente"                varchar2(50),
    "numeroPropriedadeEntrega"     number,
    "numeroPropriedadeFaturamento" number,
    "observacao"                   varchar2(4000),
    "statusSefaz"                  varchar2(10),
    "codigoChaveAcessoSefaz"       varchar2(50),
    "itensNotaFiscal"              tab_item_nota_fiscal
  );
  
  procedure print_log(msg   in Varchar2);
  
  procedure registrar(
    p_sistema_origem          varchar2,
    p_nota_fiscal             rec_nota_fiscal,
    p_id_integracao_cabecalho out NUMBER,
    p_id_integracao_detalhe   out NUMBER,
    p_ie_status               out NOCOPY varchar2
  );

  procedure processar(
    p_id_integracao_cabecalho in number,
    p_ie_status               out nocopy varchar2,
    p_id_integracao_chave     out number
  );

  function mount(
    p_sistema_origem varchar2,
    p_nota_fiscal    rec_nota_fiscal
  ) return pljson;
  
end XXFR_PCK_SINCRONIZAR_NOTA;
