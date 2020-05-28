--drop view XXFR_WSH_VW_INT_PROC_ENTREGA;
CREATE OR REPLACE FORCE EDITIONABLE VIEW XXFR_WSH_VW_INT_PROC_ENTREGA as
SELECT distinct
  -- Portaria
   d.id_integracao_cabecalho
  ,d.id_integracao_detalhe
  ,d.ie_status_processamento
  ,d.dt_criacao
  ,d.dt_atualizacao
  --
  ,json_value(d.ds_dados_requisicao, '$.idTransacao')    id_transacao
  ,json_value(d.ds_dados_requisicao, '$.versaoPayload')  vr_payload
  ,json_value(d.ds_dados_requisicao, '$.sistemaOrigem')  ds_sistema_origem
  ,json_value(d.ds_dados_requisicao, '$.codigoServico')  cd_servico
  ,json_value(d.ds_dados_requisicao, '$.usuario')        usuario
  -- Entegra
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.codigoUnidadeOperacional')                       cd_unidade_operacional
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.dividirLinha')                                   ie_dividir_linha
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.conteudoFirme')                                  ie_conteudo_firme
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.liberaSeparacao')                                ie_liberar_separacao
  -- Percurso
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.operacao')                              tp_operacao
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.idPercurso')                            id_percurso
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.nomePercurso')                          nm_percurso
  --
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.codigoReferenciaOrigem')                cd_referencia_origem
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.tipoReferenciaOrigem')                  tp_referencia_origem
  --  
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.ajustaDistribuicao')                    ie_ajusta_distribuicao
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.lacresVeiculo')                         cd_lacre_veiculo
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.pesoTara')                              qt_peso_tara
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.pesoBruto')                             qt_peso_bruto
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.pesoEmbalagemComplementar')             qt_peso_embalagem_complementar
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.tipoFrete')                             tp_frete
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.codigoMetodoEntrega')                   cd_metodo_entrega
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.codigoEnderecoEstoqueGranel')           cd_endereco_estoque_granel
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.tipoLiberacao')                         tp_liberacao
  -- Transportador
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.transportador.codigoTransportador')     cd_transportador
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.transportador.nomeMotorista')           nm_motorista
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.transportador.cpfMotorista')            nu_cpf_motorista
  -- Veiculo
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.veiculo.codigoRegistroANTT')            cd_reg_antt
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.veiculo.codigoRegistroANTTCavalo')      cd_reg_antt_cavalo
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.veiculo.codigoPlaca1')                  nu_placa1
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.veiculo.codigoPlaca2')                  nu_placa2
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.veiculo.codigoPlaca3')                  nu_placa3
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.veiculo.codigoPlaca4')                  nu_placa4
  ,json_value(d.ds_dados_requisicao, '$.processarEntrega.percurso.veiculo.codigoPlaca5')                  nu_placa5
  --
  ,distrib.*
from
   xxfr_integracao_cabecalho c
  ,xxfr_integracao_detalhe   d
  ,(
    select 
      d1.id_integracao_cabecalho as id_cab, 
      distrib.* 
    from 
      xxfr_integracao_detalhe d1
      ,json_table(
        d1.ds_dados_requisicao, 
        '$.processarEntrega.percurso.distribuicao[*]' columns (
          idx_distribuicao                            FOR ORDINALITY,
          nm_distribuicao               VARCHAR2(20)  PATH '$.nomeDistribuicao',
          cd_cliente                    VARCHAR2(20)  PATH '$.codigoCliente',
          cd_ship_to                    VARCHAR2(20)  PATH '$.codigoLocalEntregaCliente',
          vl_valor_frete                NUMBER        PATH '$.valorFrete',
          cd_moeda                      VARCHAR2(10)  PATH '$.codigoMoeda',
          cd_controle_entrega_cliente   VARCHAR2(50)  PATH '$.codigoControleEntregaCliente',
          cd_lacres                     VARCHAR2(400) PATH '$.codigosLacres',
          ds_dados_adicionais           VARCHAR2(400) PATH '$.dadosAdicionais',      
          nested path '$.linhasEntrega[*]' columns (  
            idx_linha                                   FOR ORDINALITY,
            cd_tipo_ordem_venda           VARCHAR2(50)  PATH '$.codigoTipoOrdemVenda',
            nu_ordem_venda                VARCHAR2(10)  PATH '$.numeroOrdemVenda',
            nu_linha_ordem_venda          VARCHAR2(10)  PATH '$.numeroLinhaOrdemVenda',
            nu_envio_linha_ordem_venda    VARCHAR2(10)  PATH '$.numeroEnvioLinhaOrdemVenda',
            nu_entrega                    VARCHAR2(20)  PATH '$.numeroEntrega',
            qt_quantidade                 NUMBER        PATH '$.quantidade',
            cd_un_medida                  VARCHAR2(50)  PATH '$.codigoUnidadeMedida',
            qt_volumes                    NUMBER        PATH '$.quantidadeVolumes',
            cd_un_volume                  VARCHAR2(50)  PATH '$.codigoUnidadeMedidaVolume',
            cd_endereco_estoque           VARCHAR2(20)  PATH '$.codigoEnderecoEstoque',                  
            ds_observacoes                VARCHAR2(400) PATH '$.observacoes', 
            pr_percentual_Gordura         VARCHAR2(20)  PATH '$.percentualGordura'
          )
        ) 
      ) distrib
    where 
      1=1
  ) distrib
where 1=1
  and c.cd_interface            = d.cd_interface_detalhe
  and c.id_integracao_cabecalho = d.id_integracao_cabecalho
  and c.id_integracao_cabecalho = distrib.id_cab (+)
  and d.cd_interface_detalhe    = 'PROCESSAR_ENTREGA'
;
/
/*
select * from XXFR_WSH_VW_INT_PROC_ENTREGA 
where 1=1
  --and nu_ordem_venda = '51'
  --AND CD_TIPO_ORDEM_VENDA = '124_VENDA'
  --and ID_INTEGRACAO_cabecalho=-90
  and ID_INTEGRACAO_detalhe=1879
  --and nm_percurso = 'SOL.790020'
;


select * from xxfr_integracao_detalhe 
where 1=1
  --and ID_INTEGRACAO_detalhe=4051
  and CD_INTERFACE_DETALHE = 'PROCESSAR_ENTREGA'
order by dt_atualizacao desc;
*/