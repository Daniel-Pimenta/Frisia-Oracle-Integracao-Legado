declare 
begin
  xxfr_pck_variaveis_ambiente.inicializar('ONT','UO_FRISIA');
  select fnd_profile.value('USER_ID') from dual;
end;
/

select 
  fu.user_name, 
  fr.responsibility_name, 
  fu.user_id, 
  fr.responsibility_id               resp_id, 
  furg.responsibility_application_id resp_appl_id, 
  furg.security_group_id             sec_group_id
from 
  fnd_user_resp_groups  furg, 
  fnd_user              fu, 
  fnd_responsibility_vl fr
where 1=1
  and furg.user_id = fu.user_id
  and fu.user_id   = 1511 --fnd_profile.value('USER_ID')
  and furg.responsibility_id = fr.responsibility_id
order by 1, 3;

exec fnd_global.apps_initialize ('1511', '22883', '552', '0');



    -- Buscar tipo de interface
    select cd_interface_detalhe,
           json_value(d.ds_dados_requisicao, '$.*.codigoUnidadeOperacional'),
           json_value(d.ds_dados_requisicao, '$.*.usuario')
      into v_cd_interface_detalhe,
           v_cd_unidade_operacional,
           v_cd_usuario
      from xxfr_integracao_detalhe d
     where d.id_integracao_detalhe = p_id_integracao_detalhe;
  
    log_info_processo('Interface: ' || v_cd_interface_detalhe, 'CARREGAR DADOS {' || p_id_integracao_detalhe || '}');
  
    if v_cd_unidade_operacional is null then
      p_retorno."retornoProcessamento"         := 'ERRO';
      p_retorno."mensagemRetornoProcessamento" := 'Código da Unidade Operacional não informado';
      goto fim;
    end if;
  
    if v_cd_usuario is not null then
      -- Se foi definido usuário deve executar por este usuário, se não foi informado vai pelo padrão
      v_user_id := xxfr_fnd_pck_obter_usuario.id_usuario(p_cd_usuario => v_cd_usuario, p_somente_ativo => 'S');
      if v_user_id is null then
        p_retorno."retornoProcessamento"         := 'ERRO';
        p_retorno."mensagemRetornoProcessamento" := 'Usuário informado <' || v_cd_usuario || '> não está ativo no Oracle EBS.';
        goto fim;
      end if;
    end if;
  
    -- Inicializar variáveis de contexto EBS
    xxfr_pck_variaveis_ambiente.inicializar(p_application_short_name => 'ONT',
                                            p_operation_unit_name    => v_cd_unidade_operacional,
                                            p_user_name              => v_cd_usuario);
      -- Buscar tipo de interface




    select cd_interface_detalhe,
           json_value(d.ds_dados_requisicao, '$.*.codigoUnidadeOperacional'),
           json_value(d.ds_dados_requisicao, '$.*.usuario')
      into v_cd_interface_detalhe,
           v_cd_unidade_operacional,
           v_cd_usuario
      from xxfr_integracao_detalhe d
     where d.id_integracao_detalhe = p_id_integracao_detalhe;
  
    log_info_processo('Interface: ' || v_cd_interface_detalhe, 'CARREGAR DADOS {' || p_id_integracao_detalhe || '}');
  
    if v_cd_unidade_operacional is null then
      p_retorno."retornoProcessamento"         := 'ERRO';
      p_retorno."mensagemRetornoProcessamento" := 'Código da Unidade Operacional não informado';
      goto fim;
    end if;
  
    if v_cd_usuario is not null then
      -- Se foi definido usuário deve executar por este usuário, se não foi informado vai pelo padrão
      v_user_id := xxfr_fnd_pck_obter_usuario.id_usuario(p_cd_usuario => v_cd_usuario, p_somente_ativo => 'S');
      if v_user_id is null then
        p_retorno."retornoProcessamento"         := 'ERRO';
        p_retorno."mensagemRetornoProcessamento" := 'Usuário informado <' || v_cd_usuario || '> não está ativo no Oracle EBS.';
        goto fim;
      end if;
    end if;
  
    -- Inicializar variáveis de contexto EBS
    xxfr_pck_variaveis_ambiente.inicializar(p_application_short_name => 'ONT',
                                            p_operation_unit_name    => v_cd_unidade_operacional,
                                            p_user_name              => v_cd_usuario);
  