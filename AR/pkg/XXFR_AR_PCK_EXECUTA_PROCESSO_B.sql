create or replace package body xxfr_ar_pck_executa_processo is
  
  procedure print_log(msg in varchar2) is
  begin
    XXFR_AR_PCK_INT_FINANCIAMENTO.print_log(msg);
  end;
  
  procedure executa_concorrente (error_code             out number
                                ,error_buf              out varchar2
                                ,p_id_execucao_processo in     number) is
   PRAGMA AUTONOMOUS_TRANSACTION;
     lv_request_id                 NUMBER;
  BEGIN
    print_log('chamar_concorrente');
    lv_request_id := FND_REQUEST.submit_request('XXFR'
                                               ,'XXFR_AR_EXECUTA_PROCESSO'
                                               ,NULL
                                               ,NULL
                                               ,NULL
                                               ,p_id_execucao_processo);
    print_log('request_id: '||lv_request_id);
    --
    COMMIT;
  exception
    when others then
         error_code := 2;
         error_buf  := 'Erro ao submeter concorrente do processo. Erro: '||SQLERRM;
  end executa_concorrente;

  procedure erro_evento_processo (p_exe_evento_processo in number
                                 ,p_mensagem            in varchar2) is
    l_nr_sequencia_erro   number;
  begin
    begin
      select nr_sequencia_erro+1
      into   l_nr_sequencia_erro
      from   xxfr.xxfr_ar_exe_evento_proces_erro
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    exception
      when no_data_found then
           l_nr_sequencia_erro := 1;
    end;
    --
    insert into xxfr.xxfr_ar_exe_evento_proces_erro
           (ID_EXE_EVENTO_PROCESSO_ERRO
           ,ID_EXECUCAO_EVENTO_PROCESSO
           ,nr_sequencia_erro
           ,ds_mensagem
           ,created_by
           ,creation_date
           ,last_updated_by
           ,last_update_date
           ,last_update_login)
    values (xxfr.xxfr_ar_sq_exe_evento_pro_erro.nextval
           ,p_exe_evento_processo
           ,l_nr_sequencia_erro
           ,p_mensagem
           ,fnd_profile.value('USER_ID')
           ,sysdate
           ,fnd_profile.value('USER_ID')
           ,sysdate
           ,fnd_profile.value('LOGIN_ID'));
  end erro_evento_processo;

  procedure executa_processo (error_code             in out number
                             ,error_buf              out    varchar2
                             ,p_id_execucao_processo in     number) is
    --
    l_id_execucao_processo          number;
    l_id_versao_processo            number;
    l_id_execucao_evento_processo   number;
    l_ID_STATUS_PROCESSO            number;
    l_DT_INICIO_EXECUCAO            date;
    l_DT_FIM_EXECUCAO               date;
    l_DT_TRANSACAO                  date;
    l_org_id                        number;
    l_PARAMETER_CONTEXT             varchar2(30);
    l_inicio_parametro              number;
    l_fim_parametro                 number;
    l_parametro                     varchar2(30);
    l_parametro_parcial             varchar2(500);
    l_parametro_novo                varchar2(500);
    TYPE tb_parametros              IS TABLE OF xxfr.xxfr_ar_cfg_evento_processo.parameter1%type INDEX BY varchar2(10);
    l_parametros                    tb_parametros;
    TYPE tb_attributos              IS TABLE OF xxfr.xxfr_ar_cfg_evento_processo.attribute1%type INDEX BY varchar2(10);
    l_attributos                    tb_attributos;
    l_programa                      varchar2(200);
    l_indice                        varchar2(20);
    l_status_processo               number;

  begin
    print_log('Processo');
     --
    select ID_VERSAO_PROCESSO
    ,      ID_STATUS_PROCESSO
    ,      DT_INICIO_EXECUCAO
    ,      DT_FIM_EXECUCAO
    ,      DT_TRANSACAO
    ,      ORG_ID
    ,      PARAMETER_CONTEXT
    ,      PARAMETER1
    ,      PARAMETER2
    ,      PARAMETER3
    ,      PARAMETER4
    ,      PARAMETER5
    ,      PARAMETER6
    ,      PARAMETER7
    ,      PARAMETER8
    ,      PARAMETER9
    ,      PARAMETER10
    ,      PARAMETER11
    ,      PARAMETER12
    ,      PARAMETER13
    ,      PARAMETER14
    ,      PARAMETER15
    ,      PARAMETER16
    ,      PARAMETER17
    ,      PARAMETER18
    ,      PARAMETER19
    ,      PARAMETER20
    ,      PARAMETER21
    ,      PARAMETER22
    ,      PARAMETER23
    ,      PARAMETER24
    ,      PARAMETER25
    ,      PARAMETER26
    ,      PARAMETER27
    ,      PARAMETER28
    ,      PARAMETER29
    ,      PARAMETER30
    ,      PARAMETER31
    ,      PARAMETER32
    ,      PARAMETER33
    ,      PARAMETER34
    ,      PARAMETER35
    ,      PARAMETER36
    ,      PARAMETER37
    ,      PARAMETER38
    ,      PARAMETER39
    ,      PARAMETER40
    ,      PARAMETER41
    ,      PARAMETER42
    ,      PARAMETER43
    ,      PARAMETER44
    ,      PARAMETER45
    ,      PARAMETER46
    ,      PARAMETER47
    ,      PARAMETER48
    ,      PARAMETER49
    ,      PARAMETER50
    into   l_id_versao_processo
    ,      l_ID_STATUS_PROCESSO
    ,      l_DT_INICIO_EXECUCAO
    ,      l_DT_FIM_EXECUCAO
    ,      l_DT_TRANSACAO
    ,      l_org_id
    ,      l_PARAMETER_CONTEXT
    ,      l_parametros('0.1')
    ,      l_parametros('0.2')
    ,      l_parametros('0.3')
    ,      l_parametros('0.4')
    ,      l_parametros('0.5')
    ,      l_parametros('0.6')
    ,      l_parametros('0.7')
    ,      l_parametros('0.8')
    ,      l_parametros('0.9')
    ,      l_parametros('0.10')
    ,      l_parametros('0.11')
    ,      l_parametros('0.12')
    ,      l_parametros('0.13')
    ,      l_parametros('0.14')
    ,      l_parametros('0.15')
    ,      l_parametros('0.16')
    ,      l_parametros('0.17')
    ,      l_parametros('0.18')
    ,      l_parametros('0.19')
    ,      l_parametros('0.20')
    ,      l_parametros('0.21')
    ,      l_parametros('0.22')
    ,      l_parametros('0.23')
    ,      l_parametros('0.24')
    ,      l_parametros('0.25')
    ,      l_parametros('0.26')
    ,      l_parametros('0.27')
    ,      l_parametros('0.28')
    ,      l_parametros('0.29')
    ,      l_parametros('0.30')
    ,      l_parametros('0.31')
    ,      l_parametros('0.32')
    ,      l_parametros('0.33')
    ,      l_parametros('0.34')
    ,      l_parametros('0.35')
    ,      l_parametros('0.36')
    ,      l_parametros('0.37')
    ,      l_parametros('0.38')
    ,      l_parametros('0.39')
    ,      l_parametros('0.40')
    ,      l_parametros('0.41')
    ,      l_parametros('0.42')
    ,      l_parametros('0.42')
    ,      l_parametros('0.44')
    ,      l_parametros('0.45')
    ,      l_parametros('0.46')
    ,      l_parametros('0.47')
    ,      l_parametros('0.48')
    ,      l_parametros('0.49')
    ,      l_parametros('0.50')
    from   xxfr.xxfr_ar_exe_processo
    where  id_execucao_processo = p_id_execucao_processo;
    --
    for r1 in (
        select ID_EVENTO_PROCESSO
        ,      ID_EVENTO
        ,      NR_SEQUENCIA_EVENTO
        ,      DT_INICIO_VIGENCIA
        ,      DT_FIM_VIGENCIA
        ,      CONTEXT
        ,      ATTRIBUTE1
        ,      ATTRIBUTE2
        ,      ATTRIBUTE3
        ,      ATTRIBUTE4
        ,      ATTRIBUTE5
        ,      ATTRIBUTE6
        ,      ATTRIBUTE7
        ,      ATTRIBUTE8
        ,      ATTRIBUTE9
        ,      ATTRIBUTE10
        ,      ATTRIBUTE11
        ,      ATTRIBUTE12
        ,      ATTRIBUTE13
        ,      ATTRIBUTE14
        ,      ATTRIBUTE15
        ,      PARAMETER_CONTEXT
        ,      PARAMETER1
        ,      PARAMETER2
        ,      PARAMETER3
        ,      PARAMETER4
        ,      PARAMETER5
        ,      PARAMETER6
        ,      PARAMETER7
        ,      PARAMETER8
        ,      PARAMETER9
        ,      PARAMETER10
        ,      PARAMETER11
        ,      PARAMETER12
        ,      PARAMETER13
        ,      PARAMETER14
        ,      PARAMETER15
        ,      PARAMETER16
        ,      PARAMETER17
        ,      PARAMETER18
        ,      PARAMETER19
        ,      PARAMETER20
        ,      PARAMETER21
        ,      PARAMETER22
        ,      PARAMETER23
        ,      PARAMETER24
        ,      PARAMETER25
        ,      PARAMETER26
        ,      PARAMETER27
        ,      PARAMETER28
        ,      PARAMETER29
        ,      PARAMETER30
        ,      PARAMETER31
        ,      PARAMETER32
        ,      PARAMETER33
        ,      PARAMETER34
        ,      PARAMETER35
        ,      PARAMETER36
        ,      PARAMETER37
        ,      PARAMETER38
        ,      PARAMETER39
        ,      PARAMETER40
        ,      PARAMETER41
        ,      PARAMETER42
        ,      PARAMETER43
        ,      PARAMETER44
        ,      PARAMETER45
        ,      PARAMETER46
        ,      PARAMETER47
        ,      PARAMETER48
        ,      PARAMETER49
        ,      PARAMETER50
        from    xxfr.xxfr_ar_cfg_evento_processo
        where  id_versao_processo = l_id_versao_processo
        and    l_dt_transacao between nvl(DT_INICIO_VIGENCIA,sysdate-1000) and nvl(DT_FIM_VIGENCIA,sysdate+1000)
        order by NR_SEQUENCIA_EVENTO)
    loop
      begin
        select ID_EXECUCAO_EVENTO_PROCESSO
        ,      STATUS_PROCESSO
        into   l_ID_EXECUCAO_EVENTO_PROCESSO
        ,      l_status_processo
        from   xxfr.xxfr_ar_exe_evento_processo 
        where  ID_EVENTO_PROCESSO   = r1.ID_EVENTO_PROCESSO
        and    ID_EXECUCAO_PROCESSO = p_id_execucao_processo
        and    NR_SEQUENCIA_EVENTO  = r1.NR_SEQUENCIA_EVENTO;
        --
        if l_status_processo in (1,3)
        then
           delete xxfr.xxfr_ar_exe_evento_proces_erro
           where  ID_EXECUCAO_EVENTO_PROCESSO = l_ID_EXECUCAO_EVENTO_PROCESSO;
           --
           delete xxfr.xxfr_ar_exe_evento_processo
           where  ID_EXECUCAO_EVENTO_PROCESSO = l_ID_EXECUCAO_EVENTO_PROCESSO;
        end if;
        commit;
      exception
        when no_data_found then
             l_status_processo := 0;
      end;
      --
      if l_status_processo != 2
      then
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.1')  := R1.ATTRIBUTE1;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.2')  := R1.ATTRIBUTE2;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.3')  := R1.ATTRIBUTE3;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.4')  := R1.ATTRIBUTE4;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.5')  := R1.ATTRIBUTE5;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.6')  := R1.ATTRIBUTE6;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.7')  := R1.ATTRIBUTE7;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.8')  := R1.ATTRIBUTE8;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.9')  := R1.ATTRIBUTE9;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.10') := R1.ATTRIBUTE10;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.11') := R1.ATTRIBUTE11;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.12') := R1.ATTRIBUTE12;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.13') := R1.ATTRIBUTE13;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.14') := R1.ATTRIBUTE14;
         l_attributos(r1.NR_SEQUENCIA_EVENTO||'.15') := R1.ATTRIBUTE15;
         --
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.1')  := R1.PARAMETER1;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.2')  := R1.PARAMETER2;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.3')  := R1.PARAMETER3;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.4')  := R1.PARAMETER4;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.5')  := R1.PARAMETER5;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.6')  := R1.PARAMETER6;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.7')  := R1.PARAMETER7;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.8')  := R1.PARAMETER8;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.9')  := R1.PARAMETER9;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.10') := R1.PARAMETER10;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.11') := R1.PARAMETER11;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.12') := R1.PARAMETER12;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.13') := R1.PARAMETER13;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.14') := R1.PARAMETER14;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.15') := R1.PARAMETER15;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.16') := R1.PARAMETER16;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.17') := R1.PARAMETER17;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.18') := R1.PARAMETER18;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.19') := R1.PARAMETER19;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.20') := R1.PARAMETER20;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.21') := R1.PARAMETER21;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.22') := R1.PARAMETER22;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.23') := R1.PARAMETER23;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.24') := R1.PARAMETER24;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.25') := R1.PARAMETER25;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.26') := R1.PARAMETER26;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.27') := R1.PARAMETER27;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.28') := R1.PARAMETER28;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.29') := R1.PARAMETER29;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.30') := R1.PARAMETER30;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.31') := R1.PARAMETER31;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.32') := R1.PARAMETER32;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.33') := R1.PARAMETER33;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.34') := R1.PARAMETER34;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.35') := R1.PARAMETER35;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.36') := R1.PARAMETER36;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.37') := R1.PARAMETER37;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.38') := R1.PARAMETER38;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.39') := R1.PARAMETER39;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.40') := R1.PARAMETER40;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.41') := R1.PARAMETER41;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.42') := R1.PARAMETER42;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.43') := R1.PARAMETER43;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.44') := R1.PARAMETER44;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.45') := R1.PARAMETER45;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.46') := R1.PARAMETER46;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.47') := R1.PARAMETER47;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.48') := R1.PARAMETER48;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.49') := R1.PARAMETER49;
         l_parametros(r1.NR_SEQUENCIA_EVENTO||'.50') := R1.PARAMETER50;
         --
         for m in 1..50
         loop
           begin
             print_log('Antes: '||r1.NR_SEQUENCIA_EVENTO||'.'||m);
             l_parametro_parcial := l_parametros(r1.NR_SEQUENCIA_EVENTO||'.'||m);
             print_log('l_parametro_parcial: '||l_parametro_parcial);
             l_inicio_parametro := 0;
             l_parametro_novo   := null;
             loop
               if l_parametro_parcial is null
               then
                  exit;
               end if;
               --
               l_parametro         := null;
               l_inicio_parametro := instr(l_parametro_parcial,'$');
               if l_inicio_parametro = 0
               then
                  exit;
               end if;
               --
               if l_inicio_parametro > 1
               then
                  l_parametro_novo := l_parametro_novo||substr(l_parametro_parcial,1,l_inicio_parametro-1);
               end if;
               --
               l_parametro_parcial := substr(l_parametro_parcial,l_inicio_parametro+1);
               l_fim_parametro     := instr(l_parametro_parcial,'$');
               l_parametro         := substr(l_parametro_parcial,1,l_fim_parametro-1);
               print_log('l_parametro: '||l_parametro);
               print_log('l_parametros(l_parametro): '||l_parametros(l_parametro));
               l_parametro_novo    := l_parametro_novo||l_parametros(l_parametro);
               --
               if length(l_parametro_parcial) > 1
               then
                  l_parametro_parcial := substr(l_parametro_parcial,l_fim_parametro+1);
               else
                  l_parametro_parcial := null;
               end if;
             end loop;
             --
             l_parametro_novo    := l_parametro_novo||l_parametro_parcial;
             l_indice := r1.NR_SEQUENCIA_EVENTO||'.'||m;
             l_parametros(l_indice) := l_parametro_novo;
           exception
             when no_data_found then
                  null;
           end;
         end loop;
         --
         for m in 1..15
         loop
           begin
             print_log('Antes: '||r1.NR_SEQUENCIA_EVENTO||'.'||m);
             l_parametro_parcial := l_attributos(r1.NR_SEQUENCIA_EVENTO||'.'||m);
             print_log('l_parametro_parcial: '||l_parametro_parcial);
             l_inicio_parametro := 0;
             l_parametro_novo   := null;
             loop
               if l_parametro_parcial is null
               then
                  exit;
               end if;
               --
               l_parametro         := null;
               l_inicio_parametro := instr(l_parametro_parcial,'$');
               print_log('l_inicio_parametro: '||l_inicio_parametro);
               if l_inicio_parametro = 0
               then
                  exit;
               end if;
               --
               if l_inicio_parametro > 1
               then
                  l_parametro_novo := l_parametro_novo||substr(l_parametro_parcial,1,l_inicio_parametro-1);
               end if;
               --
               l_parametro_parcial := substr(l_parametro_parcial,l_inicio_parametro+1);
               l_fim_parametro     := instr(l_parametro_parcial,'$');
               l_parametro         := substr(l_parametro_parcial,1,l_fim_parametro-1);
               print_log('Passou3: '||l_parametro);
               l_parametro_novo    := l_parametro_novo||l_parametros(l_parametro);
               print_log('l_parametro_novo: '||l_parametro_novo);
               --
               if length(l_parametro_parcial) > 1
               then
                  l_parametro_parcial := substr(l_parametro_parcial,l_fim_parametro+1);
               else
                  l_parametro_parcial := null;
               end if;
               print_log('Depois'||l_parametro_parcial);
             end loop;
             --
             l_parametro_novo    := l_parametro_novo||l_parametro_parcial;
             print_log('l_parametro_novo: '||l_parametro_novo);
             l_indice := r1.NR_SEQUENCIA_EVENTO||'.'||m;
             print_log('l_indice: '||l_indice);
             l_attributos(l_indice) := l_parametro_novo;
             print_log('l_attributos(l_indice): '||l_attributos(l_indice));
           exception
             when no_data_found then
                  print_log('Saiu');
           end;
         end loop;
         --
         select xxfr.xxfr_ar_sq_exe_evento_processo.nextval
         into l_ID_EXECUCAO_EVENTO_PROCESSO
         from dual;
         --
         print_log('grava eventos');
         --
         insert into xxfr.xxfr_ar_exe_evento_processo
                (ID_EXECUCAO_EVENTO_PROCESSO
                ,ID_EXECUCAO_PROCESSO
                ,ID_EVENTO_PROCESSO
                ,ID_EVENTO
                ,NR_SEQUENCIA_EVENTO
                ,STATUS_PROCESSO
                ,DT_INICIO_EXECUCAO
                ,DT_FIM_EXECUCAO
                ,DT_TRANSACAO
                ,ORG_ID
                ,CONTEXT
                ,ATTRIBUTE1
                ,ATTRIBUTE2
                ,ATTRIBUTE3
                ,ATTRIBUTE4
                ,ATTRIBUTE5
                ,ATTRIBUTE6
                ,ATTRIBUTE7
                ,ATTRIBUTE8
                ,ATTRIBUTE9
                ,ATTRIBUTE10
                ,ATTRIBUTE11
                ,ATTRIBUTE12
                ,ATTRIBUTE13
                ,ATTRIBUTE14
                ,ATTRIBUTE15
                ,PARAMETER_CONTEXT
                ,PARAMETER1
                ,PARAMETER2
                ,PARAMETER3
                ,PARAMETER4
                ,PARAMETER5
                ,PARAMETER6
                ,PARAMETER7
                ,PARAMETER8
                ,PARAMETER9
                ,PARAMETER10
                ,PARAMETER11
                ,PARAMETER12
                ,PARAMETER13
                ,PARAMETER14
                ,PARAMETER15
                ,PARAMETER16
                ,PARAMETER17
                ,PARAMETER18
                ,PARAMETER19
                ,PARAMETER20
                ,PARAMETER21
                ,PARAMETER22
                ,PARAMETER23
                ,PARAMETER24
                ,PARAMETER25
                ,PARAMETER26
                ,PARAMETER27
                ,PARAMETER28
                ,PARAMETER29
                ,PARAMETER30
                ,PARAMETER31
                ,PARAMETER32
                ,PARAMETER33
                ,PARAMETER34
                ,PARAMETER35
                ,PARAMETER36
                ,PARAMETER37
                ,PARAMETER38
                ,PARAMETER39
                ,PARAMETER40
                ,PARAMETER41
                ,PARAMETER42
                ,PARAMETER43
                ,PARAMETER44
                ,PARAMETER45
                ,PARAMETER46
                ,PARAMETER47
                ,PARAMETER48
                ,PARAMETER49
                ,PARAMETER50
                ,CREATED_BY
                ,CREATION_DATE
                ,LAST_UPDATED_BY
                ,LAST_UPDATE_DATE)
         values (l_id_execucao_evento_processo
                ,p_id_execucao_processo
                ,r1.id_evento_processo
                ,r1.id_evento
                ,r1.nr_sequencia_evento
                ,1 --STATUS_PROCESSO
                ,sysdate --DT_INICIO_EXECUCAO
                ,null --DT_FIM_EXECUCAO
                ,L_dt_transacao
                ,l_org_id
                ,r1.context
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.1')   --ATTRIBUTE1
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.2')   --ATTRIBUTE2
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.3')   --ATTRIBUTE3
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.4')   --ATTRIBUTE4
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.5')   --ATTRIBUTE5
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.6')   --ATTRIBUTE6
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.7')   --ATTRIBUTE7
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.8')   --ATTRIBUTE8
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.9')   --ATTRIBUTE9
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.10')  --ATTRIBUTE10
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.11')  --ATTRIBUTE11
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.12')  --ATTRIBUTE12
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.13')  --ATTRIBUTE13
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.14')  --ATTRIBUTE14
                ,l_attributos(r1.NR_SEQUENCIA_EVENTO||'.15')  --ATTRIBUTE15
                ,r1.parameter_context
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.1')   --PARAMETER1
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.2')   --PARAMETER2
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.3')   --PARAMETER3
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.4')   --PARAMETER4
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.5')   --PARAMETER5
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.6')   --PARAMETER6
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.7')   --PARAMETER7
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.8')   --PARAMETER8
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.9')   --PARAMETER9
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.10')  --PARAMETER10
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.11')  --PARAMETER11
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.12')  --PARAMETER12
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.13')  --PARAMETER13
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.14')  --PARAMETER14
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.15')  --PARAMETER15
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.16')  --PARAMETER16
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.17')  --PARAMETER17
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.18')  --PARAMETER18
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.19')  --PARAMETER19
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.20')  --PARAMETER20
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.21')  --PARAMETER21
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.22')  --PARAMETER22
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.23')  --PARAMETER23
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.24')  --PARAMETER24
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.25')  --PARAMETER25
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.26')  --PARAMETER26
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.27')  --PARAMETER27
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.28')  --PARAMETER28
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.29')  --PARAMETER29
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.30')  --PARAMETER30
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.31')  --PARAMETER31
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.32')  --PARAMETER32
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.33')  --PARAMETER33
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.34')  --PARAMETER34
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.35')  --PARAMETER35
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.36')  --PARAMETER36
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.37')  --PARAMETER37
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.38')  --PARAMETER38
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.39')  --PARAMETER39
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.40')  --PARAMETER40
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.41')  --PARAMETER41
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.42')  --PARAMETER42
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.43')  --PARAMETER43
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.44')  --PARAMETER44
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.45')  --PARAMETER45
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.46')  --PARAMETER46
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.47')  --PARAMETER47
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.48')  --PARAMETER48
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.49')  --PARAMETER49
                ,l_parametros(r1.NR_SEQUENCIA_EVENTO||'.50')  --PARAMETER50
                ,fnd_profile.value('USER_ID')                            --CREATED_BY
                ,sysdate                                                 --CREATION_DATE
                ,fnd_profile.value('USER_ID')                            --LAST_UPDATED_BY
                ,sysdate);                                               --LAST_UPDATE_DATE
         --
         begin
           print_log('recupera programa');
           --
           select 'begin '||flv.description||'(:id); end;'
           into   l_programa
           from   xxfr_ar_evento xae
           ,      fnd_lookup_values flv
           where  xae.id_evento = r1.id_evento
           and    flv.LOOKUP_TYPE = 'XXFR_PROGRAMA_EVENTO'
           and    flv.LOOKUP_CODE = xae.programa;
           --
           print_log(l_programa);
           execute immediate l_programa using l_id_execucao_evento_processo;
         exception
           when others then
                l_status_processo := 3;
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => l_id_execucao_evento_processo
                                                                  ,p_mensagem            => 'Erro chamada. '||l_programa||'. '||sqlerrm);
         end;
      --
      end if;
      --
      begin
          select PARAMETER1
          ,      PARAMETER2
          ,      PARAMETER3
          ,      PARAMETER4
          ,      PARAMETER5
          ,      PARAMETER6
          ,      PARAMETER7
          ,      PARAMETER8
          ,      PARAMETER9
          ,      PARAMETER10
          ,      PARAMETER11
          ,      PARAMETER12
          ,      PARAMETER13
          ,      PARAMETER14
          ,      PARAMETER15
          ,      PARAMETER16
          ,      PARAMETER17
          ,      PARAMETER18
          ,      PARAMETER19
          ,      PARAMETER20
          ,      PARAMETER21
          ,      PARAMETER22
          ,      PARAMETER23
          ,      PARAMETER24
          ,      PARAMETER25
          ,      PARAMETER26
          ,      PARAMETER27
          ,      PARAMETER28
          ,      PARAMETER29
          ,      PARAMETER30
          ,      PARAMETER31
          ,      PARAMETER32
          ,      PARAMETER33
          ,      PARAMETER34
          ,      PARAMETER35
          ,      PARAMETER36
          ,      PARAMETER37
          ,      PARAMETER38
          ,      PARAMETER39
          ,      PARAMETER40
          ,      PARAMETER41
          ,      PARAMETER42
          ,      PARAMETER43
          ,      PARAMETER44
          ,      PARAMETER45
          ,      PARAMETER46
          ,      PARAMETER47
          ,      PARAMETER48
          ,      PARAMETER49
          ,      PARAMETER50
          ,      status_processo
        into   l_parametros(r1.NR_SEQUENCIA_EVENTO||'.1')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.2')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.3')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.4')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.5')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.6')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.7')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.8')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.9')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.10')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.11')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.12')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.13')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.14')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.15')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.16')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.17')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.18')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.19')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.20')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.21')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.22')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.23')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.24')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.25')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.26')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.27')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.28')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.29')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.30')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.31')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.32')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.33')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.34')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.35')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.36')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.37')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.38')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.39')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.40')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.41')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.42')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.42')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.44')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.45')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.46')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.47')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.48')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.49')
        ,      l_parametros(r1.NR_SEQUENCIA_EVENTO||'.50')
        ,      l_status_processo
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = l_id_execucao_evento_processo;
    exception
      when others then
           l_status_processo := 3;
           xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => l_id_execucao_evento_processo
                                                             ,p_mensagem            => 'Erro pesquisa após execução processo. '||sqlerrm);
    end;
    if l_status_processo = 3
    then
       update xxfr.xxfr_ar_exe_processo
       set    id_status_processo = 3
       where  id_execucao_processo = p_id_execucao_processo;
       exit;
    end if;
    commit;
   end loop;
    --
    commit;
  end executa_processo;

  procedure conta_produtor (p_exe_evento_processo in number) is
    l_id_cooperado    varchar2(20);
    l_atividade       varchar2(20);
    l_cultura         varchar2(20);
    l_safra           varchar2(20);
    l_proposito       varchar2(20);
    l_conta           varchar2(50); 
    l_tipo_conta      varchar2(50);
    l_id_tipo_conta   number;
    l_dt_transacao    date;
    l_bank_account_id number;
    l_status_evento   varchar2(30);
    l_mensagem_erro   varchar2(4000);
  begin
    select PARAMETER1 id_cooperado
    ,      PARAMETER2 atividade
    ,      PARAMETER3 cultura
    ,      PARAMETER4 safra
    ,      PARAMETER5 proposito
    ,      PARAMETER6 conta
    ,      PARAMETER7 id_tipo_conta
    ,      dt_transacao
    into   l_id_cooperado
    ,      l_atividade
    ,      l_cultura
    ,      l_safra
    ,      l_proposito
    ,      l_conta
    ,      l_id_tipo_conta
    ,      l_dt_transacao
    from   xxfr.xxfr_ar_exe_evento_processo
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    --
    if l_conta is null
    then
       begin
         select XXFR_AR_PCK_OBTER_CONTA_FIN.cd_conta_fin( p_cd_atividade       => l_atividade
                                                        , p_cd_cultura         => l_cultura
                                                        , p_cd_proposito       => l_proposito
                                                        , p_id_tipo_conta      => l_id_tipo_conta
                                                        , p_dt_data            => l_dt_transacao
                                                        , p_id_conta_cooperado => l_id_cooperado)
         into l_bank_account_id
         from dual;
       exception
         when others then
              l_mensagem_erro := sqlerrm;
              l_status_evento := 'ERRO';
       end;
       --
    end if;
    --
    if l_status_evento = 'ERRO'
    then
       xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                         ,p_mensagem            => l_mensagem_erro);
    end if;
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    PARAMETER6      = nvl(trim(to_char(l_bank_account_id)),l_conta)
    ,      status_processo = decode(l_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
  end conta_produtor;

  procedure informacao_banco (p_exe_evento_processo in number) is
    vs_bank_account_num     ce_bank_accounts.bank_account_num%type;
    vs_bank_account_name    ce_bank_accounts.bank_account_name%type;
    vn_bank_id              ce_bank_accounts.bank_id%type;
    vn_bank_branch_id       ce_bank_accounts.bank_branch_id%type;
    vs_bank_number          ce_bank_branches_v.bank_number%type;
    vs_bank_name            ce_bank_branches_v.bank_name%type;
    vs_branch_number        ce_bank_branches_v.branch_number%type;
    vs_bank_branch_name     ce_bank_branches_v.bank_branch_name%type;
    l_status_evento         varchar2(30);
    l_mensagem_erro         varchar2(4000);
  begin
    for r1 in (
        select parameter1  bank_account_id
        ,      parameter2  bank_account_num
        ,      parameter3  bank_account_name
        ,      parameter4  bank_party_id
        ,      parameter5  branch_party_id
        ,      parameter6  bank_number
        ,      parameter7  bank_name
        ,      parameter8  branch_number
        ,      parameter9  branch_name
        ,      org_id
        ,      dt_transacao invoice_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      --
      begin
        select bb.branch_party_id
        ,      bb.bank_party_id
        ,      ba.bank_account_num
        ,      ba.bank_account_name
        ,      bb.bank_number
        ,      bb.bank_name
        ,      bb.branch_number
        ,      bb.bank_branch_name
        into   vn_bank_branch_id
        ,      vn_bank_id
        ,      vs_bank_account_num
        ,      vs_bank_account_name
        ,      vs_bank_number
        ,      vs_bank_name
        ,      vs_branch_number
        ,      vs_bank_branch_name
        from   ce_bank_branches_v bb
        ,      ce_bank_accounts   ba
        where  ba.bank_account_id = r1.bank_account_id
        and    ba.bank_branch_id = bb.branch_party_id;
      exception
        when no_data_found then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'ID da conta bancária '||r1.bank_account_id||' não cadastrado.';
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
        when others then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Erro ao validar o ID da conta bancária '||r1.bank_account_id||'.ERRO: '||SQLERRM;
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
      end;
    end loop;
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    PARAMETER2      = vs_bank_account_num
    ,      parameter3      = vs_bank_account_name
    ,      parameter4      = vn_bank_id
    ,      parameter5      = vn_bank_branch_id
    ,      parameter6      = vs_bank_number
    ,      parameter7      = vs_bank_name
    ,      parameter8      = vs_branch_number
    ,      parameter9      = vs_bank_branch_name
    ,      status_processo = decode(l_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    --
  end informacao_banco;

  procedure informacao_uso_financiamento (p_exe_evento_processo in number) is
    vs_nm_uso_financiamento varchar2(50);
    l_status_evento         varchar2(30);
    l_mensagem_erro         varchar2(4000);
  begin
    for r1 in (
        select parameter1  cd_uso_financiamento
        ,      parameter2  nm_uso_financiamento
        ,      org_id
        ,      dt_transacao invoice_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      begin
        select MEANING
        into   vs_nm_uso_financiamento
        from   fnd_lookup_values_vl
        where  LOOKUP_TYPE = 'XXFR_AR_USO_FINANCIAMENTO'
        and    LOOKUP_CODE = r1.cd_uso_financiamento;
      exception
        when no_data_found then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Uso do financiamento '||r1.cd_uso_financiamento||' não cadastrado.';
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
        when others then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Erro ao validar a agência do cooperado para liberação '||r1.cd_uso_financiamento||'.ERRO: '||SQLERRM;
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
       end;
    end loop;
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    PARAMETER2      = vs_nm_uso_financiamento
    ,      status_processo = decode(l_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
  end informacao_uso_financiamento;
  
  procedure informacao_cliente_fornecedor (p_exe_evento_processo in number) is
    l_status_evento         varchar2(30);
    l_mensagem_erro         varchar2(4000);
    vn_cust_account_id      number;
    vn_CUST_ACCT_SITE_ID    number;
    vn_site_use_id          number;
    vs_account_number       varchar2(50);
    vn_party_id             number;
    vn_party_site_id        number;
    vs_party_name           varchar2(240);
    vn_vendor_id            number;
    vn_vendor_site_id       number;
    vs_vendor_name          varchar2(240);
    vs_vendor_number        varchar2(150);
    vn_accts_pay_ccid       number;
    
  begin
    for r1 in (
        select parameter1  cust_account_id
        ,      parameter2  CUST_ACCT_SITE_ID
        ,      parameter3  site_use_id
        ,      parameter4  vendor_id
        ,      parameter5  vendor_site_id
        ,      parameter6  party_id
        ,      parameter7  party_site_id
        ,      parameter8  party_name
        ,      parameter9  vendor_name
        ,      parameter10 account_number
        ,      parameter11 vendor_number
        ,      parameter12 accts_pay_ccid
        ,      org_id
        ,      dt_transacao invoice_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      --
      vn_cust_account_id   := r1.cust_account_id;
      vn_CUST_ACCT_SITE_ID := r1.CUST_ACCT_SITE_ID;
      vn_site_use_id       := r1.site_use_id;
      vs_account_number    := r1.account_number;
      vn_party_id          := r1.party_id;
      vn_party_site_id     := r1.party_site_id;
      vs_party_name        := r1.party_name;
      vn_vendor_id         := r1.vendor_id;
      vn_vendor_site_id    := r1.vendor_site_id;
      vs_vendor_name       := r1.vendor_name;
      vs_vendor_number     := r1.vendor_number;
      --
      if (vn_cust_account_id is not null and vn_party_id is null) or
         (vn_cust_account_id is null and vn_party_id is not null) or
         (vs_account_number is not null and vn_cust_account_id is null and vn_party_id is null)
      then
         begin
           select hp.party_id
           ,      hp.party_name
           ,      hca.account_number
           into   vn_party_id
           ,      vs_party_name
           ,      vs_account_number
           from   hz_cust_accounts_all hca
           ,      hz_parties           hp
           where  ((hca.cust_account_id = vn_cust_account_id and
                    vn_cust_account_id is not null and
                    vn_party_id is null) or
                   (hca.party_id = vn_party_id and
                    vn_cust_account_id is null and
                    vn_party_id is not null) or
                   (hca.account_number = vs_account_number and 
                    vn_cust_account_id is null and
                    vn_party_id is null and
                    vs_account_number is not null))
           and    hp.party_id         = hca.party_id;
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'ID do Cliente '||vn_cust_account_id||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar o ID do Cliente '||vn_cust_account_id||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;
      --
      if (vn_site_use_id is null and vn_party_site_id is null and vn_cust_account_id is not null)
      then
         begin
           select hcas.party_site_id
           ,      hcas.CUST_ACCT_SITE_ID
           ,      csu.site_use_id
           into   vn_party_site_id
           ,      vn_CUST_ACCT_SITE_ID
           ,      vn_site_use_id
           from   hz_cust_site_uses_all csu
           ,      hz_cusT_ACCT_SITES_ALL HCAS
           where  hcas.cust_account_id   = vn_cust_account_id
           and    csu.CUST_ACCT_SITE_ID  = HCAS.cust_acct_site_id
           and    csu.site_use_code      = 'BILL_TO'
           and    csu.primary_flag       = 'Y';
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'ID do Uso do Local principal do Cliente '||vs_party_name||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar o ID do Uso do Local principal do Cliente '||vs_party_name||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;
      --
      if (vn_site_use_id is not null and vn_party_site_id is null) or
         (vn_site_use_id is null and vn_party_site_id is not null)
      then
         begin
           select hcas.party_site_id
           ,      hcas.CUST_ACCT_SITE_ID
           into   vn_party_site_id
           ,      vn_CUST_ACCT_SITE_ID
           from   hz_cust_site_uses_all csu
           ,      hz_cusT_ACCT_SITES_ALL HCAS
           where  ((csu.site_use_id = vn_site_use_id and
                    vn_site_use_id is not null and
                    vn_party_site_id is null) or
                   (party_site_id = vn_party_site_id and
                    vn_site_use_id is null and
                    vn_party_site_id is not null))
           and    hcas.cust_account_id   = vn_cust_account_id
           AND    HCAS.cust_acct_site_id = csu.CUST_ACCT_SITE_ID;
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'ID do Uso do Local do Cliente '||vn_site_use_id||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar o ID do Uso do Local do Cliente '||vn_site_use_id||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;
      --
      if (vn_vendor_id is not null and vn_party_id is null) or
         (vn_vendor_id is null and vn_party_id is not null) or
         (vs_vendor_number is not null and vn_vendor_id is null and vn_party_id is null)
      then
         begin
           select party_id
           ,      vendor_name
           ,      segment1
           ,      vendor_id
           into   vn_party_id
           ,      vs_vendor_name
           ,      vs_vendor_number
           ,      vn_vendor_id
           from   ap_suppliers
           where  ((vendor_id = vn_vendor_id and
                    vn_vendor_id is not null and
                    vn_party_id is null) or
                   (party_id = vn_party_id and
                    vn_vendor_id is null and
                    vn_party_id is not null) or
                   (segment1 = vs_vendor_number and
                    vn_vendor_id is null and
                    vn_party_id is null and
                    vs_vendor_number is not null));
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'ID do Fornecedor '||vn_vendor_id||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar o ID do Fornecedor '||vn_vendor_id||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;
      --
      if (vn_vendor_site_id is not null and vn_party_site_id is null) or
         (vn_vendor_site_id is null and vn_party_site_id is not null)
      then
         begin
           select party_site_id
           ,      vendor_site_id
           ,      accts_pay_code_combination_id
           into   vn_party_site_id
           ,      vn_vendor_site_id
           ,      vn_accts_pay_ccid
           from   ap_supplier_sites_all
           where  ((vendor_site_id = vn_vendor_site_id and
                    vn_vendor_site_id is not null and
                    vn_party_site_id is null) or
                   (party_site_id = vn_party_site_id and
                    vn_vendor_site_id is null and
                    vn_party_site_id is not null))
           and    vendor_id      = vn_vendor_id 
           and    org_id         = r1.org_id;
         exception
           when no_data_found then
                l_status_evento :='ERRO';
                l_mensagem_erro := 'ID do Local do Fornecedor '||vn_vendor_site_id||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar o ID do Local do Fornecedor '||vn_vendor_site_id||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;
      --
      if vn_cust_account_id is null and vn_party_id is not null
      then
         begin
           select hp.party_id
           ,      hp.party_name
           ,      hca.account_number
           into   vn_party_id
           ,      vs_party_name
           ,      vs_account_number
           from   hz_cust_accounts_all hca
           ,      hz_parties           hp
           where  hca.party_id = vn_party_id
           and    hp.party_id  = hca.party_id;
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'ID do parceiro '||vn_party_id||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar o ID do Parceiro '||vn_party_id||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;
      --
      if vn_site_use_id is null
      then
         begin
           select hcas.party_site_id
           ,      hcas.CUST_ACCT_SITE_ID
           into   vn_party_site_id
           ,      vn_CUST_ACCT_SITE_ID
           from   hz_cust_site_uses_all csu
           ,      hz_cusT_ACCT_SITES_ALL HCAS
           where  hcas.cust_account_id   = vn_cust_account_id
           AND    HCAS.cust_acct_site_id = csu.CUST_ACCT_SITE_ID
           and    csu.site_use_code      = 'BILL_TO'
           and    ((vn_party_site_id is not null and
                    hcas.party_site_id   = vn_party_site_id) or
                   (vn_party_site_id is null and
                    csu.primary_flag     = 'Y'));
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'ID do Local do Parceiro '||vn_party_id||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar o ID do Local do Parceiro '||vn_party_id||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;
      --
      if vn_vendor_site_id is null
      then
         begin
           select vendor_site_id
           ,      accts_pay_code_combination_id
           into   vn_vendor_site_id
           ,      vn_accts_pay_ccid
           from   ap_supplier_sites_all
           where  party_site_id = vn_party_site_id
           and    vendor_id      = vn_vendor_id 
           and    org_id         = r1.org_id;
         exception
           when no_data_found then
                l_status_evento :='ERRO';
                l_mensagem_erro := 'ID do Local do Fornecedor ID '||vn_party_site_id||'-'||vs_vendor_name||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar o ID do Local do Fornecedor '||vs_vendor_name||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;
      --
    end loop;  
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    PARAMETER1      = vn_cust_account_id
    ,      parameter2      = vn_CUST_ACCT_SITE_ID
    ,      parameter3      = vn_site_use_id
    ,      parameter4      = vn_vendor_id
    ,      parameter5      = vn_vendor_site_id
    ,      parameter6      = vn_party_id
    ,      parameter7      = vn_party_site_id
    ,      parameter8      = vs_party_name
    ,      parameter9      = vs_vendor_name
    ,      parameter10     = vs_account_number
    ,      parameter11     = vs_vendor_number
    ,      parameter12     = vn_accts_pay_ccid
    ,      status_processo = decode(l_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
  end informacao_cliente_fornecedor;

  procedure recupera_metodo_pagamento_ar (p_exe_evento_processo in number) is
    l_receipt_method_id    number;
    l_status_evento        varchar2(30);
    l_mensagem_erro         varchar2(4000);
  begin
    --
    for r1 in (
        select parameter1  receipt_class_id
        ,      parameter2  BANK_ACCOUNT_ID
        ,      parameter3  receipt_method_id
        ,      org_id
        ,      dt_transacao apply_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      begin
        select arm.receipt_method_id
        into   l_receipt_method_id
        from   AR_RECEIPT_CLASSES arc
        ,      AR_RECEIPT_METHODS arm
        ,      AR_RECEIPT_METHOD_ACCOUNTS armc
        ,      CE_BANK_ACCT_USES_ALL      cbau
        where  arm.receipt_class_id   = R1.receipt_class_id
        and    arm.receipt_class_id   = arc.receipt_class_id
        and    r1.apply_date          between nvl(arm.START_DATE,sysdate-1000) and nvl(arm.END_DATE,sysdate+1000)
        and    armc.receipt_method_id = arm.receipt_method_id
        and    r1.apply_date          between nvl(armc.START_DATE,sysdate-1000) and nvl(armc.END_DATE,sysdate+1000)
        and    cbau.BANK_ACCT_USE_ID  = armc.REMIT_BANK_ACCT_USE_ID
        and    cbau.BANK_ACCOUNT_ID   = r1.BANK_ACCOUNT_ID
        and    rownum                 = 1;
      exception
        when no_data_found then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Método de recebimento não cadatrado para RECEIPT_CLASS_ID '||R1.receipt_class_id||' e BANK_ACCOUNT_ID '||r1.BANK_ACCOUNT_ID||'.';
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
        when others then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Erro ao recuperar o Método de recebimento para RECEIPT_CLASS_ID '||R1.receipt_class_id||' e BANK_ACCOUNT_ID '||r1.BANK_ACCOUNT_ID||'.';
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
      end;
    end loop;
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    parameter3 = l_receipt_method_id
    ,      status_processo = decode(l_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
  end recupera_metodo_pagamento_ar;

  procedure recupera_cond_pagamento_ar_ap (p_exe_evento_processo in number) is
    l_term_id_ar           number;
    l_term_id_ap           number;
    l_status_evento        varchar2(30);
    l_mensagem_erro         varchar2(4000);
  begin
    --
    for r1 in (
        select parameter1  term_id_ar
        ,      parameter2  term_id_ap
        ,      org_id
        ,      dt_transacao apply_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      l_term_id_ar := r1.term_id_ar;
      l_term_id_ap := r1.term_id_ap;
      if l_term_id_ar is not null and l_term_id_ap is null
      then
         begin
           select attribute3
           into   l_term_id_ap
           from   RA_TERMS_VL
           where  term_id   = R1.term_id_ar
           and    attribute3 is not null;
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Condição de pagamento do AR TERM_ID '||l_term_id_ar||' não cadastrado ou não associado a condição de pagamento do AP.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar a Condição de pagamento do AR TERM_ID  '||l_term_id_ar||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;   
      --
      if l_term_id_ar is null and l_term_id_ap is not null
      then
         begin
           select term_id
           into   l_term_id_ar
           from   RA_TERMS_VL
           where  attribute3   = R1.term_id_ap;
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Condição de pagamento do AP TERM_ID '||l_term_id_ap||' não cadastrado ou não associado a condição de pagamento do AR.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro ao recuperar a Condição de pagamento do AP TERM_ID  '||l_term_id_ap||'.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      end if;   
    end loop;
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    parameter1 = l_term_id_ar
    ,      parameter2 = l_term_id_ap
    ,      status_processo = decode(l_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
  end recupera_cond_pagamento_ar_ap;

  procedure informacao_transacao_ar (p_exe_evento_processo in number) is
    l_contas_receber       number;
    l_receita              number;
    l_status_evento        varchar2(30);
    l_mensagem_erro        varchar2(4000);
    l_customer_trx_id      number;
  begin
    --
    for r1 in (
        select parameter1  customer_trx_id
        ,      parameter2  contas_receber
        ,      parameter3  receita
        ,      parameter4  ct_reference --contrato de financiamento 
        ,      org_id
        ,      dt_transacao apply_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      if r1.customer_trx_id is null and r1.ct_reference is null
      then
         l_status_evento              := 'ERRO';
         l_mensagem_erro := 'O ID da transação ou a referência da transação deve ser informado.';
         xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                           ,p_mensagem            => l_mensagem_erro);
      elsif r1.customer_trx_id is null
      then
         begin
           select customer_trx_id
           into   l_customer_trx_id
           from   ra_customer_trx_all
           where  ct_reference = r1.ct_reference;
         exception
           when no_data_found then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'A referência da transação '||r1.ct_reference||' não encontrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
           when others then
                l_status_evento              := 'ERRO';
                l_mensagem_erro := 'Erro na pesquisa da referência da transação '||r1.ct_reference||'. '||sqlerrm;
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_mensagem_erro);
         end;
      else
        l_customer_trx_id := r1.customer_trx_id;
      end if;
      --
      begin
        select code_combination_id
        into   l_contas_receber
        from   ra_cust_trx_line_gl_dist_all
        where  customer_trx_id = l_customer_trx_id
        and    account_class   = 'REC';
      exception
        when no_data_found then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Combinação contábil do contas a receber para o ID do Aviso de débito '||l_customer_trx_id||' não encontrado.';
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
        when others then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Erro ao recuperar a Combinação contábil do contas a receber para o ID do Aviso de débito '||l_customer_trx_id||'.';
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
      end;
      begin
        select code_combination_id
        into   l_receita
        from   ra_cust_trx_line_gl_dist_all
        where  customer_trx_id = l_customer_trx_id
        and    account_class   = 'REV'
        and    rownum          = 1;
      exception
        when no_data_found then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Combinação contábil da conta de recita para o ID do Aviso de débito '||l_customer_trx_id||' não encontrado.';
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
        when others then
             l_status_evento              := 'ERRO';
             l_mensagem_erro := 'Erro ao recuperar a Combinação contábil da conta de receita para o ID do Aviso de débito '||l_customer_trx_id||'.';
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => l_mensagem_erro);
      end;
    end loop;
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    parameter1 = l_customer_trx_id
    ,      parameter2 = l_contas_receber
    ,      parameter3 = l_receita
    ,      status_processo = decode(l_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
  end informacao_transacao_ar;

  procedure recebimento_diverso (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_misc_receipt_id               number;
    l_global_attribute_record       AR_RECEIPT_API_PUB.global_attribute_rec_type;
    l_attribute_record              AR_RECEIPT_API_PUB.attribute_rec_type;
    vn_count                        number;
    l_status_evento                 varchar2(30);
    --
  begin
    for r1 in (
        select context
        ,      attribute1 
        ,      attribute2 
        ,      attribute3 
        ,      attribute4 
        ,      attribute5 
        ,      attribute6 
        ,      attribute7 
        ,      attribute8 
        ,      attribute9 
        ,      attribute10 
        ,      attribute11
        ,      attribute12
        ,      attribute13
        ,      attribute14
        ,      attribute15
        ,      parameter1  receipt_number
        ,      parameter2  amount
        ,      parameter3  receivables_trx_id
        ,      parameter4  remittance_bank_account_num
        ,      parameter5  receipt_method_id
        ,      parameter6  comments
        ,      parameter7  currency_code
        ,      parameter8  exchange_rate_type
        ,      parameter9  exchange_rate
        ,      parameter10 exchange_rate_date 
        ,      parameter11 reference_type
        ,      parameter12 reference_id
        ,      parameter13 misc_receipt_id
        ,      org_id
        ,      dt_transacao receipt_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      l_attribute_record.ATTRIBUTE_CATEGORY := r1.context;
      l_attribute_record.attribute1         := r1.attribute1;
      l_attribute_record.attribute2         := r1.attribute2;
      l_attribute_record.attribute3         := r1.attribute3;
      l_attribute_record.attribute4         := r1.attribute4;
      l_attribute_record.attribute5         := r1.attribute5;
      l_attribute_record.attribute6         := r1.attribute6;
      l_attribute_record.attribute7         := r1.attribute7;
      l_attribute_record.attribute8         := r1.attribute8;
      l_attribute_record.attribute9         := r1.attribute9;
      l_attribute_record.attribute10        := r1.attribute10;
      l_attribute_record.attribute11        := r1.attribute11;
      l_attribute_record.attribute12        := r1.attribute12;
      l_attribute_record.attribute13        := r1.attribute13;
      l_attribute_record.attribute14        := r1.attribute14;
      l_attribute_record.attribute15        := r1.attribute15;
      --
      if nvl(r1.amount,0) != 0
      then
          begin
              print_log('Org.: '||r1.org_id);
              AR_RECEIPT_API_PUB.create_misc(
                -- Standard API parameters.
                  p_api_version                  => 1.0,
                  p_init_msg_list                => FND_API.G_FALSE,
                  p_commit                       => FND_API.G_FALSE,
                  p_validation_level             => FND_API.G_VALID_LEVEL_FULL,
                  x_return_status                => l_return_status,
                  x_msg_count                    => l_msg_count,
                  x_msg_data                     => l_msg_data,
                -- Misc Receipt info. parameters
                  p_usr_currency_code            => NULL, --the translated currency code
                  p_currency_code                => r1.currency_code,
                  p_usr_exchange_rate_type       => NULL,
                  p_exchange_rate_type           => r1.exchange_rate_type,
                  p_exchange_rate                => r1.exchange_rate,
                  p_exchange_rate_date           => r1.exchange_rate_date,
                  p_amount                       => r1.amount,
                  p_receipt_number               => r1.receipt_number,
                  p_receipt_date                 => r1.receipt_date,
                  p_gl_date                      => r1.receipt_date,
                  p_receivables_trx_id           => r1.receivables_trx_id,
                  p_activity                     => NULL,
                  p_misc_payment_source          => NULL,
                  p_tax_code                     => NULL,
                  p_vat_tax_id                   => NULL,
                  p_tax_rate                     => NULL,
                  p_tax_amount                   => NULL,
                  p_deposit_date                 => NULL,
                  p_reference_type               => r1.reference_type,
                  p_reference_num                => NULL,
                  p_reference_id                 => r1.reference_id,
                  p_remittance_bank_account_id   => NULL,
                  p_remittance_bank_account_num  => r1.remittance_bank_account_num,
                  p_remittance_bank_account_name => NULL,
                  p_receipt_method_id            => r1.receipt_method_id,
                  p_receipt_method_name          => NULL,
                  p_doc_sequence_value           => NULL,
                  p_ussgl_transaction_code       => NULL,
                  p_anticipated_clearing_date    => NULL,
                  p_attribute_record             => l_attribute_record,
                  p_global_attribute_record      => NULL,
                  p_comments                     => r1.comments,
                  p_org_id                       => r1.org_id,
                  p_misc_receipt_id              => l_misc_receipt_id,
                  p_called_from                  => NULL,
                  p_payment_trxn_extension_id    => NULL);
          exception
            when others then
                 l_status_evento := 'ERRO';
                 l_msg_data      := 'Erro API recebimento diverso. '||sqlerrm;
                 xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                   ,p_mensagem            => l_msg_data);
          end;
          --
          print_log('Gerou');
          if l_return_status != 'S' then
             if l_msg_count = 1 Then
                l_status_evento := 'ERRO';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_msg_data);
                print_log(l_msg_data);
             elsif l_msg_count > 1 Then
                   vn_count := 0;
                   loop
                     vn_count := vn_count + 1;
                      l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                      if l_msg_data is NULL then
                         exit;
                      end if;
                      l_status_evento := 'ERRO';
                      xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                        ,p_mensagem            => l_msg_data);
                       print_log('Mensagem (' || vn_count ||') = '||l_msg_data);
                    end loop;
             end if;
         end if;
         --
         print_log('Rec. Diversos: '||l_misc_receipt_id);
     end if;
     --
     update xxfr.xxfr_ar_exe_evento_processo
     set    parameter13 = l_misc_receipt_id
     ,      status_processo = decode(l_status_evento,'ERRO',3,2)
     where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
   end loop;
  end recebimento_diverso;

  procedure recebimento_padrao (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_cash_receipt_id               number;
    l_global_attribute_record       AR_RECEIPT_API_PUB.global_attribute_rec_type;
    l_attribute_record              AR_RECEIPT_API_PUB.attribute_rec_type;
    l_status_evento                 varchar2(30);
    vn_count                        number;
  begin
    l_status_evento := 'SUCESSO';
    --
    for r1 in (
        select context
        ,      attribute1 
        ,      attribute2 
        ,      attribute3 
        ,      attribute4 
        ,      attribute5 
        ,      attribute6 
        ,      attribute7 
        ,      attribute8 
        ,      attribute9 
        ,      attribute10 
        ,      attribute11
        ,      attribute12
        ,      attribute13
        ,      attribute14
        ,      attribute15
        ,      parameter1  receipt_number
        ,      parameter2  amount
        ,      parameter3  customer_id
        ,      parameter4  remittance_bank_account_num
        ,      parameter5  receipt_method_id
        ,      parameter6  comments
        ,      parameter7  currency_code
        ,      parameter8  exchange_rate_type
        ,      parameter9  exchange_rate
        ,      parameter10 exchange_rate_date
        ,      parameter11
        ,      parameter12
        ,      parameter13 cash_receipt_id
        ,      dt_transacao receipt_date 
        ,      org_id
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      l_attribute_record.ATTRIBUTE_CATEGORY := r1.context;
      l_attribute_record.attribute1         := r1.attribute1;
      l_attribute_record.attribute2         := r1.attribute2;
      l_attribute_record.attribute3         := r1.attribute3;
      l_attribute_record.attribute4         := r1.attribute4;
      l_attribute_record.attribute5         := r1.attribute5;
      l_attribute_record.attribute6         := r1.attribute6;
      l_attribute_record.attribute7         := r1.attribute7;
      l_attribute_record.attribute8         := r1.attribute8;
      l_attribute_record.attribute9         := r1.attribute9;
      l_attribute_record.attribute10        := r1.attribute10;
      l_attribute_record.attribute11        := r1.attribute11;
      l_attribute_record.attribute12        := r1.attribute12;
      l_attribute_record.attribute13        := r1.attribute13;
      l_attribute_record.attribute14        := r1.attribute14;
      l_attribute_record.attribute15        := r1.attribute15;
      --
      if r1.amount > 0
      then
          AR_RECEIPT_API_PUB.Create_cash(
               -- Standard API parameters.
            p_api_version                  => 1.0,
            p_init_msg_list                => FND_API.G_FALSE,
            p_commit                       => FND_API.G_FALSE,
            p_validation_level             => FND_API.G_VALID_LEVEL_FULL,
            x_return_status                => l_return_status,
            x_msg_count                    => l_msg_count,
            x_msg_data                     => l_msg_data,
          -- Misc Receipt info. parameters
            p_usr_currency_code            => NULL, --the translated currency code
            p_currency_code                => r1.currency_code,
            p_usr_exchange_rate_type       => NULL,
            p_exchange_rate_type           => r1.exchange_rate_type,
            p_exchange_rate                => r1.exchange_rate,
            p_exchange_rate_date           => r1.exchange_rate_date,
            p_amount                       => r1.amount,
            p_factor_discount_amount       => NULL,
            p_receipt_number               => r1.receipt_number,
            p_receipt_date                 => r1.receipt_date,
            p_gl_date                      => r1.receipt_date,
            p_maturity_date                => NULL,
            p_postmark_date                => NULL,
            p_customer_id                  => r1.customer_id,
            p_customer_name                => NULL,
            p_customer_number              => NULL,
            p_customer_bank_account_id     => NULL,
            p_customer_bank_account_num    => NULL,
            p_customer_bank_account_name   => NULL,
            p_payment_trxn_extension_id    => NULL, --payment uptake changes bichatte
            p_location                     => NULL,
            p_customer_site_use_id         => NULL,
            p_default_site_use             => 'Y', --bug4448307-4509459
            p_customer_receipt_reference   => NULL,
            p_override_remit_account_flag  => NULL,
            p_remittance_bank_account_id   => NULL,
            p_remittance_bank_account_num  => r1.remittance_bank_account_num,
            p_remittance_bank_account_name => NULL,
            p_deposit_date                 => NULL,
            p_receipt_method_id            => r1.receipt_method_id,
            p_receipt_method_name          => NULL,
            p_doc_sequence_value           => NULL,
            p_ussgl_transaction_code       => NULL,
            p_anticipated_clearing_date    => NULL,
            p_called_from                  => NULL,
            p_attribute_rec                => l_attribute_record,
            -- ******* Global Flexfield parameters *******
            p_global_attribute_rec         => NULL,
            p_comments                     => r1.comments,
            --   ***  Notes Receivable Additional Information  ***
            p_issuer_name                  => NULL,
            p_issue_date                   => NULL,
            p_issuer_bank_branch_id        => NULL,
            p_org_id                       => NULL,
            p_installment                  => NULL,
            --   ** OUT NOCOPY variables
            p_cr_id		                 => l_cash_receipt_id);
          --
          --
          if l_return_status != 'S' then
             if l_msg_count = 1 Then
                l_status_evento := 'ERRO';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_msg_data);
                print_log(l_msg_data);
             elsif l_msg_count > 1 Then
                   vn_count := 0;
                   loop
                     vn_count := vn_count + 1;
                      l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                      if l_msg_data is NULL then
                         exit;
                      end if;
                      l_status_evento := 'ERRO';
                      xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                        ,p_mensagem            => l_msg_data);
                       print_log('Mensagem (' || vn_count ||') = '||l_msg_data);
                    end loop;
             end if;
          end if;
      end if;
      update xxfr.xxfr_ar_exe_evento_processo
      set    parameter13 = l_cash_receipt_id
      ,      status_processo = decode(l_status_evento,'ERRO',3,2)
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    end loop;
  end recebimento_padrao;

  procedure recebimento_padrao_aplicado (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_cash_receipt_id               number;
    l_global_attribute_record       AR_RECEIPT_API_PUB.global_attribute_rec_type;
    l_attribute_record              AR_RECEIPT_API_PUB.attribute_rec_type;
    l_status_evento                 varchar2(30);
    vn_count                        number;
  begin
    for r1 in (
        select context
        ,      attribute1 
        ,      attribute2 
        ,      attribute3 
        ,      attribute4 
        ,      attribute5 
        ,      attribute6 
        ,      attribute7 
        ,      attribute8 
        ,      attribute9 
        ,      attribute10 
        ,      attribute11
        ,      attribute12
        ,      attribute13
        ,      attribute14
        ,      attribute15
        ,      parameter1  receipt_number
        ,      parameter2  amount
        ,      parameter3  customer_id
        ,      parameter4  remittance_bank_account_num
        ,      parameter5  receipt_method_id
        ,      parameter6  comments
        ,      parameter7  currency_code
        ,      parameter8  exchange_rate_type
        ,      parameter9  exchange_rate
        ,      parameter10 exchange_rate_date
        ,      parameter11 installment
        ,      parameter12 applied_payment_schedule_id
        ,      parameter13 cash_receipt_id
        ,      parameter14 amount_applied
        ,      parameter15 customer_trx_id
        ,      dt_transacao receipt_date 
        ,      org_id
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      l_attribute_record.ATTRIBUTE_CATEGORY := r1.context;
      l_attribute_record.attribute1         := r1.attribute1;
      l_attribute_record.attribute2         := r1.attribute2;
      l_attribute_record.attribute3         := r1.attribute3;
      l_attribute_record.attribute4         := r1.attribute4;
      l_attribute_record.attribute5         := r1.attribute5;
      l_attribute_record.attribute6         := r1.attribute6;
      l_attribute_record.attribute7         := r1.attribute7;
      l_attribute_record.attribute8         := r1.attribute8;
      l_attribute_record.attribute9         := r1.attribute9;
      l_attribute_record.attribute10        := r1.attribute10;
      l_attribute_record.attribute11        := r1.attribute11;
      l_attribute_record.attribute12        := r1.attribute12;
      l_attribute_record.attribute13        := r1.attribute13;
      l_attribute_record.attribute14        := r1.attribute14;
      l_attribute_record.attribute15        := r1.attribute15;
      --
      AR_RECEIPT_API_PUB.Create_and_apply(
           -- Standard API parameters.
        p_api_version                  => 1.0,
        p_init_msg_list                => FND_API.G_FALSE,
        p_commit                       => FND_API.G_FALSE,
        p_validation_level             => FND_API.G_VALID_LEVEL_FULL,
        x_return_status                => l_return_status,
        x_msg_count                    => l_msg_count,
        x_msg_data                     => l_msg_data,
        -- Receipt info. parameters
        p_usr_currency_code            => NULL, --the translated currency code
        p_currency_code                => r1.currency_code,
        p_usr_exchange_rate_type       => NULL,
        p_exchange_rate_type           => r1.exchange_rate_type,
        p_exchange_rate                => r1.exchange_rate,
        p_exchange_rate_date           => r1.exchange_rate_date,
        p_amount                       => r1.amount,
        p_factor_discount_amount       => NULL,
        p_receipt_number               => r1.receipt_number,
        p_receipt_date                 => r1.receipt_date,
        p_gl_date                      => r1.receipt_date,
        p_maturity_date                => NULL,
        p_postmark_date                => NULL,
        p_customer_id                  => r1.customer_id,
        p_customer_name                => NULL,
        p_customer_number              => NULL,
        p_customer_bank_account_id     => NULL,
      /* 6612301 */
        p_customer_bank_account_num    => NULL,
        p_customer_bank_account_name   => NULL,
        p_payment_trxn_extension_id    => NULL, --payment uptake changes bichatte
        p_location                     => NULL,
        p_customer_site_use_id         => NULL,
        p_default_site_use             => 'Y', --The default site use bug4448307-4509459.
        p_customer_receipt_reference   => NULL,
        p_override_remit_account_flag  => NULL,
        p_remittance_bank_account_id   => NULL,
        p_remittance_bank_account_num  => r1.remittance_bank_account_num,
        p_remittance_bank_account_name => NULL,
        p_deposit_date                 => NULL,
        p_receipt_method_id            => r1.receipt_method_id,
        p_receipt_method_name          => NULL,
        p_doc_sequence_value           => NULL,
        p_ussgl_transaction_code       => NULL,
        p_anticipated_clearing_date    => NULL,
        p_called_from                  => NULL,
        p_attribute_rec                => l_attribute_record,
         -- ******* Global Flexfield parameters *******
        p_global_attribute_rec         => NULL,
        p_receipt_comments             => r1.comments,
       --   ***  Notes Receivable Additional Information  ***
        p_issuer_name                  => NULL,
        p_issue_date                   => NULL,
        p_issuer_bank_branch_id        => NULL,
        --  ** OUT NOCOPY variables for Creating receipt
        p_cr_id		                   => l_cash_receipt_id,
       -- Receipt application parameters
        p_customer_trx_id              => r1.customer_trx_id,
        p_trx_number                   => NULL,
        p_installment                  => r1.installment,
        p_applied_payment_schedule_id  => r1.applied_payment_schedule_id,
        p_amount_applied               => r1.amount_applied,
        -- this is the allocated receipt amount
        p_amount_applied_from          => NULL,
        p_trans_to_receipt_rate        => NULL,
        p_discount                     => NULL,
        p_apply_date                   => r1.receipt_date,
        p_apply_gl_date                => r1.receipt_date,
        app_ussgl_transaction_code     => NULL,
        p_customer_trx_line_id	       => NULL,
        p_line_number                  => NULL,
        p_show_closed_invoices         => 'N', /* Bug fix 2462013 */
        p_move_deferred_tax            => 'Y',
        p_link_to_trx_hist_id          => NULL,
        app_attribute_rec              => NULL,
        -- ******* Global Flexfield parameters *******
        app_global_attribute_rec       => NULL,
        app_comments                   => NULL,
        -- OSTEINME 3/9/2001: added flag that indicates whether to call payment
        -- processor such as iPayments
        p_call_payment_processor       => FND_API.G_FALSE,
        p_org_id                       => r1.org_id
        -- OUT NOCOPY parameter for the Application
        );
      if l_return_status != 'S' then
         if l_msg_count = 1 Then
            l_status_evento := 'ERRO';
            xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                              ,p_mensagem            => l_msg_data);
            print_log(l_msg_data);
         elsif l_msg_count > 1 Then
               vn_count := 0;
               loop
                 vn_count := vn_count + 1;
                  l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                  if l_msg_data is NULL then
                     exit;
                  end if;
                  l_status_evento := 'ERRO';
                  xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                    ,p_mensagem            => l_msg_data);
                   print_log('Mensagem (' || vn_count ||') = '||l_msg_data);
                end loop;
         end if;
      end if;
      update xxfr.xxfr_ar_exe_evento_processo
      set    parameter13 = l_cash_receipt_id
      ,      status_processo = decode(l_status_evento,'ERRO',3,2)
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    end loop;
  end recebimento_padrao_aplicado;

  procedure aviso_debito_ar (p_exe_evento_processo in number) is
    vs_return_status                 varchar2(240);
    vn_msg_count                     number;
    vs_msg_data                      varchar2(4000);
    vs_status_evento                 varchar2(30);
    vn_customer_trx_id               number;
    vn_count                        number;
    tp_batch_source_rec             AR_INVOICE_API_PUB.batch_source_rec_type;
    tp_trx_header_tbl               AR_INVOICE_API_PUB.trx_header_tbl_type;
    tp_trx_line_tbl                 AR_INVOICE_API_PUB.trx_line_tbl_type;
    tp_trx_dist_tbl                 AR_INVOICE_API_PUB.trx_dist_tbl_type;
    tp_trx_salescredits_tbl         AR_INVOICE_API_PUB.trx_salescredits_tbl_type;
--    vr_global_attribute_record       AR_RECEIPT_API_PUB.global_attribute_rec_type;
--    vr_attribute_record              AR_RECEIPT_API_PUB.attribute_rec_type;
    vn_terms_id                      number;
    vn_h                            number := 1;
    vn_l                            number := 1;   
  begin
    vs_status_evento := 'SUCESSO';
      print_log('inicio: '||p_exe_evento_processo);
    --
    for r1 in (
        select context
        ,      attribute1 
        ,      attribute2 
        ,      attribute3 
        ,      attribute4 
        ,      attribute5 
        ,      attribute6 
        ,      attribute7 
        ,      attribute8 
        ,      attribute9 
        ,      attribute10 
        ,      attribute11
        ,      attribute12
        ,      attribute13
        ,      attribute14
        ,      attribute15
        ,      parameter1  trx_number
        ,      parameter2  batch_source_id
        ,      parameter3  cust_trx_type_id
        ,      parameter4  bill_to_customer_id
        ,      parameter5  bill_to_site_use_id
        ,      parameter6  amount
        ,      parameter7  trx_currency
        ,      parameter8  term_id
        ,      parameter9  warehouse_id
        ,      parameter10 inventory_item_id
        ,      parameter11 memo_line_id
        ,      parameter12 customer_trx_id
        ,      org_id
        ,      dt_transacao trx_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      tp_trx_header_tbl(vn_h).ATTRIBUTE_CATEGORY := r1.context;
      tp_trx_header_tbl(vn_h).attribute1         := r1.attribute1;
      tp_trx_header_tbl(vn_h).attribute2         := r1.attribute2;
      tp_trx_header_tbl(vn_h).attribute3         := r1.attribute3;
      tp_trx_header_tbl(vn_h).attribute4         := r1.attribute4;
      tp_trx_header_tbl(vn_h).attribute5         := r1.attribute5;
      tp_trx_header_tbl(vn_h).attribute6         := r1.attribute6;
      tp_trx_header_tbl(vn_h).attribute7         := r1.attribute7;
      tp_trx_header_tbl(vn_h).attribute8         := r1.attribute8;
      tp_trx_header_tbl(vn_h).attribute9         := r1.attribute9;
      tp_trx_header_tbl(vn_h).attribute10        := r1.attribute10;
      tp_trx_header_tbl(vn_h).attribute11        := r1.attribute11;
      tp_trx_header_tbl(vn_h).attribute12        := r1.attribute12;
      tp_trx_header_tbl(vn_h).attribute13        := r1.attribute13;
      tp_trx_header_tbl(vn_h).attribute14        := r1.attribute14;
      tp_trx_header_tbl(vn_h).attribute15        := r1.attribute15;
      --
       begin
          select ra_customer_trx_s.nextval
          into tp_trx_header_tbl(vn_h).trx_header_id
          from dual;
       exception
          when no_data_found then
              print_log('** Dados nao encontrados na sequence RA_CUSTOMER_TRX_S : '||SQLERRM);
          when others then
              print_log('** Erro ao buscar na sequence RA_CUSTOMER_TRX_S.'||SQLERRM);
       end;
       --
       tp_trx_header_tbl(vn_h).interface_header_attribute1 := r1.trx_number;
       tp_batch_source_rec.batch_source_id                 := r1.batch_source_id;
       tp_trx_header_tbl(vn_h).org_id                      := r1.org_id;
       tp_trx_header_tbl(vn_h).trx_date                    := r1.trx_date;
       tp_trx_header_tbl(vn_h).trx_currency                := r1.trx_currency;
       tp_trx_header_tbl(vn_h).cust_trx_type_id            := r1.cust_trx_type_id;
       tp_trx_header_tbl(vn_h).bill_to_customer_id         := r1.bill_to_customer_id;
       tp_trx_header_tbl(vn_h).bill_to_site_use_id         := r1.bill_to_site_use_id;
       tp_trx_header_tbl(vn_h).term_id                     := r1.term_id; 
       tp_trx_header_tbl(vn_h).finance_charges             := null;
       tp_trx_header_tbl(vn_h).status_trx                  := 'OP';
       tp_trx_header_tbl(vn_h).printing_option             := 'NOT';
       tp_trx_header_tbl(vn_h).comments                    := null;
--       if vs_debug = 'Y' then
          print_log('Parâmetros no type tp_trx_header_tbl (item '||vn_h||') :');
          print_log('tp_trx_header_tbl(vn_h).org_id = '||tp_trx_header_tbl(vn_h).org_id);
          print_log('tp_trx_header_tbl(vn_h).trx_date = '||tp_trx_header_tbl(vn_h).trx_date);
          print_log('tp_trx_header_tbl(vn_h).trx_currency = '||tp_trx_header_tbl(vn_h).trx_currency);
          print_log('tp_trx_header_tbl(vn_h).sold_to_customer_id = '||tp_trx_header_tbl(vn_h).sold_to_customer_id);
          print_log('tp_trx_header_tbl(vn_h).ship_to_customer_id = '||tp_trx_header_tbl(vn_h).ship_to_customer_id);
          print_log('tp_trx_header_tbl(vn_h).bill_to_customer_id = '||tp_trx_header_tbl(vn_h).bill_to_customer_id);
          print_log('tp_trx_header_tbl(vn_h).bill_to_site_use_id = '||tp_trx_header_tbl(vn_h).bill_to_site_use_id);
          print_log('tp_trx_header_tbl(vn_h).term_id = '||tp_trx_header_tbl(vn_h).term_id);
--       end if;
       --
       begin
          select ra_customer_trx_lines_s.nextval
              into tp_trx_line_tbl(vn_l).trx_line_id 
          from dual;
       exception
            when no_data_found then
               print_log('** Dados nao encontrados na sequence RA_CUSTOMER_TRX_LINES_S : '||SQLERRM);
            when others then
               print_log('** Erro ao buscar na sequence RA_CUSTOMER_TRX_LINES_S.'||SQLERRM);
       end;
       --
       tp_trx_line_tbl(vn_l).trx_header_id      := tp_trx_header_tbl(vn_h).trx_header_id;
       tp_trx_line_tbl(vn_l).line_type          := 'LINE';
       tp_trx_line_tbl(vn_l).line_number        := vn_l;
--       tp_trx_line_tbl(vn_l).description        := 'TESTE BONI';
       tp_trx_line_tbl(vn_l).memo_line_id       := r1.memo_line_id;
       tp_trx_line_tbl(vn_l).quantity_invoiced  := 1;
       tp_trx_line_tbl(vn_l).unit_selling_price := r1.amount;

--       if vs_debug = 'Y' then
          print_log('Parâmetros no type tp_trx_line_tbl (item '||vn_l||') :');
          print_log('tp_trx_line_tbl(vn_h).trx_line_id = '||tp_trx_line_tbl(vn_l).trx_line_id);
          print_log('tp_trx_line_tbl(vn_h).line_type = '||tp_trx_line_tbl(vn_l).line_type);
          print_log('tp_trx_line_tbl(vn_h).line_number = '||tp_trx_line_tbl(vn_l).line_number);
          print_log('tp_trx_line_tbl(vn_h).description = '||tp_trx_line_tbl(vn_l).description);
          print_log('tp_trx_line_tbl(vn_h).memo_line_id = '||tp_trx_line_tbl(vn_l).memo_line_id);
          print_log('tp_trx_line_tbl(vn_h).quantity_invoiced = '||tp_trx_line_tbl(vn_l).quantity_invoiced);
          print_log('tp_trx_line_tbl(vn_h).unit_selling_price = '||tp_trx_line_tbl(vn_l).unit_selling_price);
--       end if;
      
       AR_INVOICE_API_PUB.create_single_invoice(
                    p_api_version         => 1.0,
                    x_return_status       => vs_return_status,
                    x_msg_count           => vn_msg_count,
                    x_msg_data            => vs_msg_data,
                    x_customer_trx_id     => vn_customer_trx_id,
                    p_batch_source_rec    => tp_batch_source_rec,
                    p_trx_header_tbl      => tp_trx_header_tbl,
                    p_trx_lines_tbl       => tp_trx_line_tbl,
                    p_trx_dist_tbl        => tp_trx_dist_tbl,
                    p_trx_salescredits_tbl => tp_trx_salescredits_tbl
                    );
   
       --
       vs_status_evento := 'SUCESSO';
--       if vs_debug = 'Y' then
          print_log('vn_customer_trx_id = '||vn_customer_trx_id);
--       end if;
       
       if vs_return_status != 'S' then
          vs_status_evento := 'ERRO';
          if vn_msg_count = 1 Then
             xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                               ,p_mensagem            => vs_msg_data);
             print_log('** Erro ao gerar aviso de débito.'|| vs_msg_data);
          elsif vn_msg_count > 1 Then
             print_log('** Erros ao gerar aviso de débito.');
             loop
               vn_count := vn_count + 1;
               vs_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
               if vs_msg_data is NULL Then
                   exit;
               end if;
               xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                 ,p_mensagem            => vs_msg_data);
               print_log('** Message (' || vn_count ||') = '||vs_msg_data);
             end loop;
          end if; 
       end if;
       --
       FOR I IN (SELECT * FROM ar_trx_errors_gt) LOOP
           print_log('** Message (' || vn_count || ') header = '||i.trx_header_id||'.'||i.trx_line_id||' => '||i.error_message||' : '||i.invalid_value);
       END LOOP;
       print_log('** Finalizando gerar_aviso_debito.');
    end loop;
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    parameter12 = vn_customer_trx_id
    ,      status_processo = decode(vs_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
  end aviso_debito_ar;

  procedure documento_padrao_ap (p_exe_evento_processo in number) is
    vs_return_status                 varchar2(240);
    vn_msg_count                     number;
    vs_msg_data                      varchar2(4000);
    vs_status_evento                 varchar2(30);
    vn_customer_trx_id               number;
    vn_count                         number;
    vn_invoice_id                    ap_invoices_all.invoice_id%type;
    vn_set_of_book_id                gl_ledgers.ledger_id%type;
    vs_row                           rowid;
    --
    vn_legal_entity_id               xle_entity_profiles.legal_entity_id%type;
    vn_party_id                      hz_parties.party_id%type;
    vn_party_site_id                 hz_party_sites.party_site_id%type;
    vn_vendor_id                     ap_suppliers.vendor_id%type;
    vn_vendor_site_id                ap_supplier_sites_all.vendor_site_id%type;
    vn_accts_pay_ccid                ap_supplier_sites_all.accts_pay_code_combination_id%type;
    vn_dist_acct_ccid                ap_invoice_distributions_all.dist_code_combination_id%type;
--    vr_global_attribute_record       AR_RECEIPT_API_PUB.global_attribute_rec_type;
--    vr_attribute_record              AR_RECEIPT_API_PUB.attribute_rec_type;
    vn_terms_id                      number;
    vs_comments                      ar_cash_receipts_all.comments%type;
    vn_line_num                      ap_invoice_lines_all.line_number%type;
    vs_period_name                   gl_periods.PERIOD_NAME%type;
    vn_invoice_dist_id               number;
    vn_erros                         number;
  begin
    vn_erros         := 0;
    vs_status_evento := 'SUCESSO';
      print_log('inicio: '||p_exe_evento_processo);
    --
    for r1 in (
        select context
        ,      attribute1 
        ,      attribute2 
        ,      attribute3 
        ,      attribute4 
        ,      attribute5 
        ,      attribute6 
        ,      attribute7 
        ,      attribute8 
        ,      attribute9 
        ,      attribute10 
        ,      attribute11
        ,      attribute12
        ,      attribute13
        ,      attribute14
        ,      attribute15
        ,      parameter1  invoice_num
        ,      parameter2  vendor_id
        ,      parameter3  vendor_site_id
        ,      parameter4  party_id
        ,      parameter5  party_site_id
        ,      parameter6  invoice_amount
        ,      parameter7  term_id
        ,      parameter8  pay_group_lookup_code
        ,      parameter9  invoice_currency_code
        ,      parameter10 payment_currency_code
        ,      parameter11 payment_method_code
        ,      parameter12 accts_pay_code_combination_id
        ,      parameter13 dist_code_combination_id
        ,      parameter14 comments
        ,      parameter15 payment_priority
        ,      parameter16 invoice_id
        ,      org_id
        ,      dt_transacao invoice_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
--      if vs_debug = 'Y' then
      print_log('******');
      print_log('Parâmetros :');
--          print_log('p_header_id = '||p_header_id);
--          print_log('p_solicita_id = '||p_solicita_id);
      print_log('vendor_id = '||r1.vendor_id);
      print_log('vendor_site_id = '||r1.vendor_site_id);
      print_log('invoice_amount = '||r1.invoice_amount);
      print_log('term_id = '||r1.term_id);
      print_log('pay_group_lookup_code = '||r1.pay_group_lookup_code);
      print_log('invoice_currency_code = '||r1.invoice_currency_code);
      print_log('payment_currency_code = '||r1.payment_currency_code);
      print_log('org_id = '||r1.org_id);
      print_log('payment_method_code = '||r1.payment_method_code);
--      print_log('batch_id = '||p_batch_id);
      print_log('******');
--      end if;
      --
      vn_vendor_id      := r1.vendor_id;
      vn_vendor_site_id := r1.vendor_site_id;
      vn_party_id       := r1.party_id;
      vn_party_site_id  := r1.party_site_id;
      --
      if vn_vendor_id is not null and vn_party_id is null
      then
         begin
           select party_id
           into   vn_party_id
           from   ap_suppliers
           where  vendor_id = vn_vendor_id;
         exception
           when no_data_found then
             print_log('** Dados nao encontrados para o ID interno do Parceiro de Negócios.');
             vn_erros := vn_erros + 1;
         when others then
             print_log('** Erro ao buscar o ID interno do Parceiro de Negócios : '||SQLERRM);
             vn_erros := vn_erros + 1;
         end;
      end if;
      --
      if vn_vendor_site_id is not null and vn_party_site_id is null
      then
         begin
           select party_site_id, accts_pay_code_combination_id
           into   vn_party_site_id, vn_accts_pay_ccid
           from   ap_supplier_sites_all
           where  vendor_site_id = vn_vendor_site_id
           and org_id            = r1.org_id;
         exception
           when no_data_found then
             print_log('** Dados nao encontrados para o ID interno do local do Parceiro de Negócios.');
             vn_erros := vn_erros + 1;
         when others then
             print_log('** Erro ao buscar o ID interno do Local do Parceiro de Negócios : '||SQLERRM);
             vn_erros := vn_erros + 1;
         end;
      end if;
      --
      if vn_vendor_id is not null and vn_party_id is null
      then
         begin
           select vendor_id
           into   vn_vendor_id
           from   ap_suppliers
           where  party_id = vn_party_id;
         exception
           when no_data_found then
             print_log('** Dados nao encontrados para o ID interno do Fornecedor.');
             vn_erros := vn_erros + 1;
         when others then
             print_log('** Erro ao buscar o ID interno do Fornecedor.'||SQLERRM);
             vn_erros := vn_erros + 1;
         end;
      end if;
      --
      if vn_vendor_site_id is null and vn_party_site_id is not null
      then
         begin
           select vendor_site_id, accts_pay_code_combination_id
           into   vn_vendor_site_id, vn_accts_pay_ccid
           from   ap_supplier_sites_all
           where  party_site_id = vn_party_site_id
           and org_id            = r1.org_id;
         exception
           when no_data_found then
             print_log('** Dados nao encontrados para o ID interno do Local do Fornecedor.');
             vn_erros := vn_erros + 1;
         when others then
             print_log('** Erro ao buscar o ID interno do Local do Fornecedor.'||SQLERRM);
             vn_erros := vn_erros + 1;
         end;
      end if;
      --
      if r1.accts_pay_code_combination_id is not null
      then
         vn_accts_pay_ccid := r1.accts_pay_code_combination_id;
      end if;
      --
      begin
         select  ap_invoices_s.nextval
         into    vn_invoice_id
         from dual;
      exception
         when no_data_found then
             print_log('** Dados nao encontrados na sequence AP_INVOICES_S.');
             vn_erros := vn_erros + 1;
         when others then
             print_log('** Erro ao buscar na sequence AP_INVOICES_S : '||SQLERRM);
             vn_erros := vn_erros + 1;
      end;
      --
      begin
        vn_set_of_book_id := fnd_profile.value('GL_SET_OF_BKS_ID');
      end;
      --      
      begin
        SELECT xep.legal_entity_id
        INTO   vn_legal_entity_id
        FROM   xle_entity_profiles xep
        ,      hr_operating_units  hou
        WHERE xep.transacting_entity_flag =  'Y'
        AND xep.legal_entity_id           =  hou.default_legal_context_id
        and hou.organization_id           = r1.org_id;
      exception
         when no_data_found then
             print_log('** Dados nao encontrados para o Legal Entity.');
             vn_erros := vn_erros + 1;
         when others then
             print_log('** Erro ao buscar o Legal Entity : '||SQLERRM);
             vn_erros := vn_erros + 1;
      end;
      --      
      begin 
        select period_name
        into   vs_period_name
        from   gl_periods
        where  r1.invoice_date between start_date and end_date;
      exception
        when no_data_found then
             print_log('** Dados nao encontrados para o Período Contábil : '||SQLERRM);
             vn_erros := vn_erros + 1;
        when others then
             print_log('** Erro ao buscar o Período Contábil : '||SQLERRM);
             vn_erros := vn_erros + 1;
      end;  
      begin
          select ap_invoice_distributions_s.nextval
              into vn_invoice_dist_id
          from dual;
      exception
          when no_data_found then
               print_log('** Dados nao encontrados na sequence AP_INVOICE_DISTRIBUTIONS_S : '||SQLERRM);
          when others then
               print_log('** Erro ao buscar na sequence AP_INVOICE_DISTRIBUTIONS_S.'||SQLERRM);
      end;
      --
      if vn_erros = 0 then
         print_log('** Iniciando gerar_solicitacao_cabecalho.');
            AP_AI_TABLE_HANDLER_PKG.INSERT_ROW
                (p_rowid                         => vs_row
                ,p_invoice_id                    => vn_invoice_id
                ,p_last_update_date              => SYSDATE
                ,p_last_updated_by               => fnd_profile.value('USER_ID')
                ,p_vendor_id                     => vn_vendor_id
                ,p_invoice_num                   => r1.invoice_num
                ,p_invoice_amount                => r1.invoice_amount
                ,p_vendor_site_id                => vn_vendor_site_id
                ,p_amount_paid                   => 0.00
                ,p_discount_amount_taken         => 0
                ,p_invoice_date                  => r1.invoice_date
                ,p_source                        => 'Manual Invoice Entry'
                ,p_invoice_type_lookup_code      => 'STANDARD'
                ,p_description                   => r1.comments
                ,p_batch_id                      => null --p_batch_id
                ,p_amt_applicable_to_discount    => r1.invoice_amount
                ,p_terms_id                      => r1.term_id
                ,p_terms_date                    => r1.invoice_date
                ,p_goods_received_date           => NULL
                ,p_invoice_received_date         => NULL
                ,p_voucher_num                   => NULL
                ,p_approved_amount               => r1.invoice_amount
                ,p_approval_status               => NULL
                ,p_approval_description          => NULL
                ,p_pay_group_lookup_code         => r1.pay_group_lookup_code
                ,p_set_of_books_id               => vn_set_of_book_id
                ,p_accts_pay_ccid                => vn_accts_pay_ccid
                ,p_recurring_payment_id          => NULL
                ,p_invoice_currency_code         => r1.invoice_currency_code
                ,p_payment_currency_code         => r1.payment_currency_code
                ,p_exchange_rate                 => NULL
                ,p_payment_amount_total          => NULL
                ,p_payment_status_flag           => 'N'
                ,p_posting_status                => NULL
                ,p_authorized_by                 => NULL
                ,p_attribute_category            => NULL
                ,p_attribute1                    => NULL
                ,p_attribute2                    => NULL
                ,p_attribute3                    => NULL
                ,p_attribute4                    => NULL
                ,p_attribute5                    => NULL
                ,p_creation_date                 => SYSDATE
                ,p_created_by                    => fnd_profile.value('USER_ID')
                ,p_vendor_prepay_amount          => NULL
                ,p_base_amount                   => NULL
                ,p_exchange_rate_type            => NULL
                ,p_exchange_date                 => NULL
                ,p_payment_cross_rate            => 1
                ,p_payment_cross_rate_type       => NULL
                ,p_payment_cross_rate_date       => r1.invoice_date
                ,p_pay_curr_invoice_amount       => r1.invoice_amount
                ,p_last_update_login             => NULL
                ,p_original_prepayment_amount    => NULL
                ,p_earliest_settlement_date      => NULL
                ,p_attribute11                   => NULL
                ,p_attribute12                   => NULL
                ,p_attribute13                   => NULL
                ,p_attribute14                   => NULL
                ,p_attribute6                    => NULL
                ,p_attribute7                    => NULL
                ,p_attribute8                    => NULL
                ,p_attribute9                    => NULL
                ,p_attribute10                   => NULL
                ,p_attribute15                   => NULL
                ,p_cancelled_date                => NULL
                ,p_cancelled_by                  => NULL
                ,p_cancelled_amount              => NULL
                ,p_temp_cancelled_amount         => NULL
                ,p_exclusive_payment_flag        => 'Y'
                ,p_po_header_id                  => NULL
                ,p_doc_sequence_id               => NULL
                ,p_doc_sequence_value            => NULL
                ,p_doc_category_code             => NULL
                ,p_expenditure_item_date         => NULL
                ,p_expenditure_organization_id   => NULL
                ,p_expenditure_type              => NULL
                ,p_pa_default_dist_ccid          => NULL
                ,p_pa_quantity                   => NULL
                ,p_project_id                    => NULL
                ,p_task_id                       => NULL
                ,p_awt_flag                      => NULL
                ,p_awt_group_id                  => NULL
                ,p_pay_awt_group_id              => NULL
                ,p_reference_1                   => NULL
                ,p_reference_2                   => NULL
                ,p_org_id                        => r1.org_id
                ,p_global_attribute_category     => 'JL.BR.APXINWKB.AP_INVOICES'
                ,p_global_attribute1             => 'Y'
                ,p_calling_sequence              => '1'
                ,p_quick_credit                  => 'N'
                ,p_force_revalidation_flag       => 'N'
                ,p_taxation_country              => 'BR'
                ,p_gl_date                       => r1.invoice_date
                ,p_award_id                      => NULL
                ,p_approval_iteration            => 1
                ,p_approval_ready_flag           => 'Y'
                ,p_wfapproval_status             => 'NOT REQUIRED'
                ,p_payment_method_code           => r1.payment_method_code
                ,p_party_id                      => vn_party_id
                ,p_party_site_id                 => vn_party_site_id
                ,p_legal_entity_id               => vn_legal_entity_id
                ,p_net_of_retainage_flag         => 'N'
                ,p_quick_po_header_id            => NULL
               );
         print_log('** Finalizando gerar_solicitacao_cabecalho.');
      --
         print_log('** Iniciando gerar_solicitacao_linha.');
         --
         vn_line_num := 1;
         --
         AP_AIL_TABLE_HANDLER_PKG.INSERT_ROW
                (P_ROWID                             => vs_row
                ,P_INVOICE_ID                        => vn_invoice_id
                ,P_LINE_NUMBER                       => vn_line_num
                ,P_LINE_TYPE_LOOKUP_CODE             => 'ITEM'
                ,P_LINE_GROUP_NUMBER                 => NULL
                ,P_REQUESTER_ID                      => NULL
                ,P_DESCRIPTION                       => NULL
                ,P_LINE_SOURCE                       => 'IMPORTED'
                ,P_ORG_ID                            => r1.org_id
                ,P_INVENTORY_ITEM_ID                 => NULL
                ,P_ITEM_DESCRIPTION                  => r1.comments
                ,P_SERIAL_NUMBER                     => NULL
                ,P_MANUFACTURER                      => NULL
                ,P_MODEL_NUMBER                      => NULL
                ,P_WARRANTY_NUMBER                   => NULL
                ,P_GENERATE_DISTS                    => 'D'
                ,P_MATCH_TYPE                        => 'NOT_MATCHED'
                ,P_DISTRIBUTION_SET_ID               => NULL
                ,P_ACCOUNT_SEGMENT                   => NULL
                ,P_BALANCING_SEGMENT                 => NULL
                ,P_COST_CENTER_SEGMENT               => NULL
                ,P_OVERLAY_DIST_CODE_CONCAT          => NULL
                ,P_DEFAULT_DIST_CCID                 => NULL
                ,P_PRORATE_ACROSS_ALL_ITEMS          => 'N'
                ,P_ACCOUNTING_DATE                   => r1.invoice_date
                ,P_PERIOD_NAME                       => NULL
                ,P_DEFERRED_ACCTG_FLAG               => 'N'
                ,P_DEF_ACCTG_START_DATE              => NULL
                ,P_DEF_ACCTG_END_DATE                => NULL
                ,P_DEF_ACCTG_NUMBER_OF_PERIODS       => NULL
                ,P_DEF_ACCTG_PERIOD_TYPE             => NULL
                ,P_SET_OF_BOOKS_ID                   => vn_set_of_book_id
                ,P_AMOUNT                            => r1.invoice_amount
                ,P_BASE_AMOUNT                       => NULL
                ,P_ROUNDING_AMT                      => NULL
                ,P_QUANTITY_INVOICED                 => r1.invoice_amount
                ,P_UNIT_MEAS_LOOKUP_CODE             => NULL
                ,P_UNIT_PRICE                        => 1
                ,P_WFAPPROVAL_STATUS                 => 'NOT REQUIRED'
                ,P_DISCARDED_FLAG                    => 'N'
                ,P_ORIGINAL_AMOUNT                   => NULL
                ,P_ORIGINAL_BASE_AMOUNT              => NULL
                ,P_ORIGINAL_ROUNDING_AMT             => NULL
                ,P_CANCELLED_FLAG                    => 'N'
                ,P_INCOME_TAX_REGION                 => NULL
                ,P_TYPE_1099                         => NULL
                ,P_STAT_AMOUNT                       => NULL
                ,P_PREPAY_INVOICE_ID                 => NULL
                ,P_PREPAY_LINE_NUMBER                => NULL
                ,P_INVOICE_INCLUDES_PREPAY_FLAG      => NULL
                ,P_CORRECTED_INV_ID                  => NULL
                ,P_CORRECTED_LINE_NUMBER             => NULL
                ,P_PO_HEADER_ID                      => NULL
                ,P_PO_RELEASE_ID                     => NULL
                ,P_PO_LINE_LOCATION_ID               => NULL
                ,P_PO_DISTRIBUTION_ID                => NULL
                ,P_PO_LINE_ID                        => NULL
                ,P_RCV_TRANSACTION_ID                => NULL
                ,P_FINAL_MATCH_FLAG                  => NULL
                ,P_ASSETS_TRACKING_FLAG              => 'Y'
                ,P_ASSET_BOOK_TYPE_CODE              => NULL
                ,P_ASSET_CATEGORY_ID                 => NULL
                ,P_PROJECT_ID                        => NULL
                ,P_TASK_ID                           => NULL
                ,P_EXPENDITURE_TYPE                  => NULL
                ,P_EXPENDITURE_ITEM_DATE             => NULL
                ,P_EXPENDITURE_ORGANIZATION_ID       => NULL
                ,P_PA_QUANTITY                       => null
                ,P_PA_CC_AR_INVOICE_ID               => NULL
                ,P_PA_CC_AR_INVOICE_LINE_NUM         => NULL
                ,P_PA_CC_PROCESSED_CODE              => NULL
                ,P_AWARD_ID                          => NULL
                ,P_AWT_GROUP_ID                      => NULL
                ,P_PAY_AWT_GROUP_ID                  => NULL
                ,P_REFERENCE_1                       => NULL
                ,P_REFERENCE_2                       => NULL
                ,P_RECEIPT_VERIFIED_FLAG             => NULL
                ,P_RECEIPT_REQUIRED_FLAG             => NULL
                ,P_RECEIPT_MISSING_FLAG              => NULL
                ,P_JUSTIFICATION                     => NULL
                ,P_EXPENSE_GROUP                     => NULL
                ,P_START_EXPENSE_DATE                => NULL
                ,P_END_EXPENSE_DATE                  => NULL
                ,P_RECEIPT_CURRENCY_CODE             => NULL
                ,P_RECEIPT_CONVERSION_RATE           => NULL
                ,P_RECEIPT_CURRENCY_AMOUNT           => NULL
                ,P_DAILY_AMOUNT                      => NULL
                ,P_WEB_PARAMETER_ID                  => NULL
                ,P_ADJUSTMENT_REASON                 => NULL
                ,P_MERCHANT_DOCUMENT_NUMBER          => NULL
                ,P_MERCHANT_NAME                     => NULL
                ,P_MERCHANT_REFERENCE                => NULL
                ,P_MERCHANT_TAX_REG_NUMBER           => NULL
                ,P_MERCHANT_TAXPAYER_ID              => NULL
                ,P_COUNTRY_OF_SUPPLY                 => NULL
                ,P_CREDIT_CARD_TRX_ID                => NULL
                ,P_COMPANY_PREPAID_INVOICE_ID        => NULL
                ,P_CC_REVERSAL_FLAG                  => NULL
                ,P_CREATION_DATE                     => SYSDATE
                ,P_CREATED_BY                        => fnd_profile.value('USER_ID')
                ,P_LAST_UPDATED_BY                   => fnd_profile.value('USER_ID')
                ,P_LAST_UPDATE_DATE                  => SYSDATE
                ,P_LAST_UPDATE_LOGIN                 => NULL
                ,P_PROGRAM_APPLICATION_ID            => NULL
                ,P_PROGRAM_ID                        => NULL
                ,P_PROGRAM_UPDATE_DATE               => NULL
                ,P_REQUEST_ID                        => NULL
                ,P_ATTRIBUTE_CATEGORY                => NULL
                ,P_ATTRIBUTE1                        => NULL
                ,P_ATTRIBUTE2                        => NULL
                ,P_ATTRIBUTE3                        => NULL
                ,P_ATTRIBUTE4                        => NULL
                ,P_ATTRIBUTE5                        => NULL
                ,p_global_attribute_category         => 'JL.BR.APXINWKB.LINES'
                ,P_CALLING_SEQUENCE                  => '1'
                ,P_SHIP_TO_LOCATION_ID               => NULL);
         --
         print_log('** Finalizando gerar_solicitacao_linha.');
         print_log('** Iniciando gerar_solicitacao_distribuição.');
         AP_AID_TABLE_HANDLER_PKG.INSERT_ROW
            ( P_ROWID                             => vs_row
            ,P_INVOICE_ID                         => vn_invoice_id
            ,P_INVOICE_LINE_NUMBER                => vn_line_num
            ,P_DISTRIBUTION_CLASS                 => 'PERMANENT'
            ,P_INVOICE_DISTRIBUTION_ID            => vn_invoice_dist_id
            ,P_DIST_CODE_COMBINATION_ID           => r1.dist_code_combination_id
            ,P_LAST_UPDATE_DATE                   => SYSDATE
            ,P_LAST_UPDATED_BY                    => fnd_profile.value('USER_ID')
            ,P_ACCOUNTING_DATE                    => r1.invoice_date
            ,P_PERIOD_NAME                        => vs_period_name
            ,P_SET_OF_BOOKS_ID                    => vn_set_of_book_id
            ,P_AMOUNT                             => r1.invoice_amount
            ,P_DESCRIPTION                        => r1.comments
            ,P_TYPE_1099                          => NULL
            ,P_POSTED_FLAG                        => 'N'
            ,P_BATCH_ID                           => null
            ,P_QUANTITY_INVOICED                  => r1.invoice_amount
            ,P_UNIT_PRICE                         => 1
            ,P_MATCH_STATUS_FLAG                  => NULL
            ,P_ATTRIBUTE_CATEGORY                 => NULL
            ,P_ATTRIBUTE1                         => NULL
            ,P_ATTRIBUTE2                         => NULL
            ,P_ATTRIBUTE3                         => NULL
            ,P_ATTRIBUTE4                         => NULL
            ,P_ATTRIBUTE5                         => NULL
            ,P_PREPAY_AMOUNT_REMAINING            => NULL
            ,P_ASSETS_ADDITION_FLAG               => 'N'
            ,P_ASSETS_TRACKING_FLAG               => 'Y'
            ,P_DISTRIBUTION_LINE_NUMBER           => 1
            ,P_LINE_TYPE_LOOKUP_CODE              => 'ITEM'
            ,P_PO_DISTRIBUTION_ID                 => NULL
            ,P_BASE_AMOUNT                        => NULL
            ,P_PA_ADDITION_FLAG                   => NULL
            ,P_POSTED_AMOUNT                      => NULL
            ,P_POSTED_BASE_AMOUNT                 => NULL
            ,P_ENCUMBERED_FLAG                    => NULL
            ,P_ACCRUAL_POSTED_FLAG                => NULL
            ,P_CASH_POSTED_FLAG                   => NULL
            ,P_LAST_UPDATE_LOGIN                  => NULL
            ,P_CREATION_DATE                      => NULL
            ,P_CREATED_BY                         => NULL
            ,P_STAT_AMOUNT                        => NULL
            ,P_ATTRIBUTE11                        => NULL
            ,P_ATTRIBUTE12                        => NULL
            ,P_ATTRIBUTE13                        => NULL
            ,P_ATTRIBUTE14                        => NULL
            ,P_ATTRIBUTE6                         => NULL
            ,P_ATTRIBUTE7                         => NULL
            ,P_ATTRIBUTE8                         => NULL
            ,P_ATTRIBUTE9                         => NULL
            ,P_ATTRIBUTE10                        => NULL
            ,P_ATTRIBUTE15                        => NULL
            ,P_ACCTS_PAY_CODE_COMB_ID             => vn_accts_pay_ccid
            ,P_REVERSAL_FLAG                      => NULL
            ,P_PARENT_INVOICE_ID                  => NULL
            ,P_INCOME_TAX_REGION                  => NULL
            ,P_FINAL_MATCH_FLAG                   => NULL
            ,P_EXPENDITURE_ITEM_DATE              => NULL
            ,P_EXPENDITURE_ORGANIZATION_ID        => NULL
            ,P_EXPENDITURE_TYPE                   => NULL
            ,P_PA_QUANTITY                        => NULL
            ,P_PROJECT_ID                         => NULL
            ,P_TASK_ID                            => NULL
            ,P_QUANTITY_VARIANCE                  => NULL
            ,P_BASE_QUANTITY_VARIANCE             => NULL
            ,P_PACKET_ID                          => NULL
            ,P_AWT_FLAG                           => NULL
            ,P_AWT_GROUP_ID                       => NULL
            ,P_PAY_AWT_GROUP_ID                   => NULL
            ,P_AWT_TAX_RATE_ID                    => NULL
            ,P_AWT_GROSS_AMOUNT                   => NULL
            ,P_REFERENCE_1                        => NULL
            ,P_REFERENCE_2                        => NULL
            ,P_ORG_ID                             => r1.org_id
            ,P_OTHER_INVOICE_ID                   => NULL
            ,P_AWT_INVOICE_ID                     => NULL
            ,P_AWT_ORIGIN_GROUP_ID                => NULL
            ,P_PROGRAM_APPLICATION_ID             => NULL
            ,P_PROGRAM_ID                         => NULL
            ,P_PROGRAM_UPDATE_DATE                => NULL
            ,P_REQUEST_ID                         => NULL
            ,P_TAX_RECOVERABLE_FLAG               => NULL
            ,P_AWARD_ID                           => NULL
            ,P_START_EXPENSE_DATE                 => NULL
            ,P_MERCHANT_DOCUMENT_NUMBER           => NULL
            ,P_MERCHANT_NAME                      => NULL
            ,P_MERCHANT_TAX_REG_NUMBER            => NULL
            ,P_MERCHANT_TAXPAYER_ID               => NULL
            ,P_COUNTRY_OF_SUPPLY                  => NULL
            ,P_MERCHANT_REFERENCE                 => NULL
            ,P_PARENT_REVERSAL_ID                 => NULL
            ,P_RCV_TRANSACTION_ID                 => NULL
            ,P_MATCHED_UOM_LOOKUP_CODE            => NULL
            ,P_CALLING_SEQUENCE                   => '1'
            ,P_RCV_CHARGE_ADDITION_FLAG           => NULL
            );
         print_log('** Finalizando gerar_solicitacao_distribuição.');
         --
         AP_CREATE_PAY_SCHEDS_PKG.Create_Payment_Schedules
              ( P_Invoice_Id             => vn_invoice_id
              ,P_Terms_Id                => r1.term_id
              ,P_Last_Updated_By         => fnd_profile.value('USER_ID')
              ,P_Created_By              => fnd_profile.value('USER_ID')
              ,P_Payment_Priority        => r1.payment_priority
              ,P_Batch_Id                => NULL --p_batch_id
              ,P_Terms_Date              => SYSDATE
              ,P_Invoice_Amount          => r1.invoice_amount
              ,P_Pay_Curr_Invoice_Amount => r1.invoice_amount
              ,P_payment_cross_rate      => 1
              ,P_Amount_For_Discount     => NULL
              ,P_Payment_Method          => r1.payment_method_code
              ,P_Invoice_Currency        => r1.invoice_currency_code
              ,P_Payment_currency        => r1.payment_currency_code
              ,P_calling_sequence        => '1'
              );
         vs_status_evento := 'SUCESSO';
      else
          vs_status_evento := 'ERRO';
      end if;
    end loop;
    --
    update xxfr.xxfr_ar_exe_evento_processo
    set    parameter16 = vn_invoice_id
    ,      status_processo = decode(vs_status_evento,'ERRO',3,2)
    where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    print_log('** Finalizando gerar_solicitacao_cabecalho.');
  end documento_padrao_ap;

  procedure ajuste_ar (p_exe_evento_processo in number) is
    vn_return_status                 number;
    vn_msg_count                     number;
    vs_msg_data                      varchar2(4000);
    vs_status_evento                 varchar2(30);
    vs_return_status                 varchar2(30);
    vn_count                         number := 0;
    vn_old_adjustment_id             ar_adjustments.adjustment_id%type; 
    vs_called_from                   varchar2(10);
    vr_adj_rec                       ar_adjustments%rowtype;
    vt_llca_adj_trx_lines_tbl        ar_adjust_pub.llca_adj_trx_line_tbl_type; 
    vt_llca_adj_create_tbl_type      ar_adjust_pub.llca_adj_create_tbl_type;
  begin
    vs_status_evento := 'SUCESSO';
      print_log('inicio: '||p_exe_evento_processo);
    --
    for r1 in (
        select context
        ,      attribute1 
        ,      attribute2 
        ,      attribute3 
        ,      attribute4 
        ,      attribute5 
        ,      attribute6 
        ,      attribute7 
        ,      attribute8 
        ,      attribute9 
        ,      attribute10 
        ,      attribute11
        ,      attribute12
        ,      attribute13
        ,      attribute14
        ,      attribute15
        ,      parameter1  customer_trx_id
        ,      parameter2  payment_schedule_id
        ,      parameter3  vendor_site_id
        ,      parameter4  receivables_trx_id
        ,      parameter5  customer_trx_line_id
        ,      parameter6  line_amount
        ,      parameter7  comments
        ,      parameter8  reason_code
        ,      parameter7  adjustment_id
        ,      org_id
        ,      dt_transacao adjustment_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      /*------------------------------------+
      |  Setting value to input parameters  | 
      +------------------------------------*/
      --Populate vt_adj_rec  record
      vr_adj_rec.customer_trx_id     := r1.customer_trx_id;
      vr_adj_rec.type                :='LINE';
      vr_adj_rec.payment_schedule_id := r1.payment_schedule_id;
      vr_adj_rec.receivables_trx_id  := r1.receivables_trx_id;
      vr_adj_rec.apply_date          := r1.adjustment_date;
      vr_adj_rec.gl_date             := r1.adjustment_date;
      vr_adj_rec.created_from        := 'ADJ-API';
      --Populate v_llca_adj_trx_lines_tbl
      vt_llca_adj_trx_lines_tbl(1).customer_trx_line_id:= r1.customer_trx_line_id; --&customer_trx_line_id; 
      vt_llca_adj_trx_lines_tbl(1).line_amount:= r1.line_amount; --&adj_amount;
      vt_llca_adj_trx_lines_tbl(1).receivables_trx_id := r1.receivables_trx_id; --&receivables_trx_id;
      /*------------------------------------+
      |  Calling to the API       |
      +------------------------------------*/
      AR_ADJUST_PUB.create_linelevel_adjustment(
           p_api_name => 'AR_ADJUST_PUB',
           p_api_version => 1.0,
           p_msg_count => vn_msg_count ,
           p_msg_data => vs_msg_data,
           p_return_status => vn_return_status,
           p_adj_rec => vr_adj_rec,
           p_llca_adj_trx_lines_tbl => vt_llca_adj_trx_lines_tbl,
           p_move_deferred_tax  => NULL,
           p_llca_adj_create_tbl_type => vt_llca_adj_create_tbl_type,
           p_old_adjust_id => NULL,
           p_called_from  => 'ADJ-API'); 

/*------------------------------------+
|  Error handling              |
+------------------------------------*/ 
print_log('Return status ' || vn_return_status );
print_log('Message count ' || vn_msg_count);
FOR i in vt_llca_adj_create_tbl_type.FIRST..vt_llca_adj_create_tbl_type.LAST
LOOP
 print_log ('Customer Trx Line id : ' || vt_llca_adj_create_tbl_type(i).customer_trx_line_id);
 print_log ('Adjustment Number : '|| vt_llca_adj_create_tbl_type(i).adjustment_number); 
 print_log ('Adjustment Id : '|| vt_llca_adj_create_tbl_type(i).adjustment_id);
END LOOP;

IF vn_msg_count = 1 Then
  print_log('l_msg_data '||vs_msg_data);
ELSIF vn_msg_count > 1 Then
  LOOP
    vn_count := vn_count+1;
    vs_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
    IF vs_msg_data is NULL THEN
      EXIT;
    END IF;
    print_log('Message' || vn_count ||' ---'||vs_msg_data); 
  END LOOP;
END IF;
end loop;
  end ajuste_ar;

  procedure aplica_recebimento (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_status_evento                 varchar2(30);
    l_cash_receipt_id               number;
    vn_count                        number;
    l_global_attribute_record       AR_RECEIPT_API_PUB.global_attribute_rec_type;
    l_attribute_record              AR_RECEIPT_API_PUB.attribute_rec_type;
    l_applied_payment_schedule_id   number;
    l_receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE;
    l_application_ref_type          ar_receivable_applications.application_ref_type%TYPE;
    l_application_ref_id            ar_receivable_applications.application_ref_id%TYPE;
    l_application_ref_num           ar_receivable_applications.application_ref_num%TYPE;
    l_secondary_application_ref_id  ar_receivable_applications.secondary_application_ref_id%TYPE;
  begin
    l_status_evento := 'SUCESSO';
      print_log('inicio: '||p_exe_evento_processo);
    --
    for r1 in (
        select context
        ,      attribute1 
        ,      attribute2 
        ,      attribute3 
        ,      attribute4 
        ,      attribute5 
        ,      attribute6 
        ,      attribute7 
        ,      attribute8 
        ,      attribute9 
        ,      attribute10 
        ,      attribute11
        ,      attribute12
        ,      attribute13
        ,      attribute14
        ,      attribute15
        ,      parameter1  cash_receipt_id
        ,      parameter2  amount_applied
        ,      parameter3  applied_payment_schedule_id
        ,      org_id
        ,      dt_transacao apply_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      l_attribute_record.ATTRIBUTE_CATEGORY := r1.context;
      l_attribute_record.attribute1         := r1.attribute1;
      l_attribute_record.attribute2         := r1.attribute2;
      l_attribute_record.attribute3         := r1.attribute3;
      l_attribute_record.attribute4         := r1.attribute4;
      l_attribute_record.attribute5         := r1.attribute5;
      l_attribute_record.attribute6         := r1.attribute6;
      l_attribute_record.attribute7         := r1.attribute7;
      l_attribute_record.attribute8         := r1.attribute8;
      l_attribute_record.attribute9         := r1.attribute9;
      l_attribute_record.attribute10        := r1.attribute10;
      l_attribute_record.attribute11        := r1.attribute11;
      l_attribute_record.attribute12        := r1.attribute12;
      l_attribute_record.attribute13        := r1.attribute13;
      l_attribute_record.attribute14        := r1.attribute14;
      l_attribute_record.attribute15        := r1.attribute15;
      --
      print_log(r1.amount_applied);
      if r1.amount_applied > 0
      then
         AR_RECEIPT_API_PUB.Apply(
            -- Standard API parameters.
            p_api_version                  => 1.0,
            p_init_msg_list                => FND_API.G_FALSE,
            p_commit                       => FND_API.G_FALSE,
            p_validation_level             => FND_API.G_VALID_LEVEL_FULL,
            x_return_status                => l_return_status,
            x_msg_count                    => l_msg_count,
            x_msg_data                     => l_msg_data,
            --  Receipt application parameters.
            p_cash_receipt_id              => r1.cash_receipt_id,
            p_receipt_number               => NULL,
            p_customer_trx_id              => NULL,
            p_trx_number                   => NULL,
            p_installment                  => NULL,
            p_applied_payment_schedule_id  => r1.applied_payment_schedule_id,
            p_amount_applied               => r1.amount_applied,
            p_amount_applied_from          => null,
            p_trans_to_receipt_rate        => NULL,
            p_discount                     => NULL,
            p_apply_date                   => r1.apply_date,
            p_apply_gl_date                => r1.apply_date,
            p_ussgl_transaction_code       => NULL,
            p_customer_trx_line_id	       => NULL,
            p_line_number                  => NULL,
            p_show_closed_invoices         => 'N',
            p_called_from                  => NULL,
            p_move_deferred_tax            => 'Y',
            p_link_to_trx_hist_id          => NULL,
            p_attribute_rec                => l_attribute_record,
          -- ******* Global Flexfield parameters *******
            p_global_attribute_rec         => l_global_attribute_record,
            p_comments                     => NULL,
            p_payment_set_id               => NULL,
            p_application_ref_type         => NULL,
            p_application_ref_id           => NULL,
            p_application_ref_num          => NULL,
            p_secondary_application_ref_id => NULL,
            p_application_ref_reason       => NULL,
            p_customer_reference           => NULL,
            p_customer_reason              => NULL,
            p_org_id                       => r1.org_id,
            p_disable_balance_check        => 'N');

          if l_return_status != 'S' then
             if l_msg_count = 1 Then
                l_status_evento   := 'ERRO';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_msg_data);
                print_log(l_msg_data);
             elsif l_msg_count > 1 Then
                   vn_count := 0;
                   loop
                     vn_count := vn_count + 1;
                     if l_msg_data is NULL then
                        exit;
                     end if;
                     --
                     l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                     l_status_evento   := 'ERRO';
                     xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                       ,p_mensagem            => l_msg_data);
                      print_log('Mensagem (' || vn_count ||') = '||l_msg_data);
                   end loop;
             end if;
          end if;
      end if;
      --
      update xxfr.xxfr_ar_exe_evento_processo
      set    status_processo = decode(l_status_evento,'ERRO',3,2)
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    end loop;

  end aplica_recebimento;

  procedure aplica_reembolso (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_status_evento                 varchar2(30);
    l_cash_receipt_id               number;
    vn_count                        number;
    l_global_attribute_record       AR_RECEIPT_API_PUB.global_attribute_rec_type;
    l_attribute_record              AR_RECEIPT_API_PUB.attribute_rec_type;
    l_pay_group_lookup_code         varchar2(240);
    l_payment_method_code           varchar2(240);
    l_pay_alone_flag                varchar2(240);
    l_payment_reason_code           varchar2(240);
    l_payment_reason_comments       varchar2(240);
    l_party_id                      number;
    l_party_site_id                 number;
    l_bank_account_id               number;
    l_payment_priority              number;
    l_terms_id                      number;
    l_applied_payment_schedule_id   number;
    l_receivable_application_id     ar_receivable_applications.receivable_application_id%TYPE;
    l_application_ref_type          ar_receivable_applications.application_ref_type%TYPE;
    l_application_ref_id            ar_receivable_applications.application_ref_id%TYPE;
    l_application_ref_num           ar_receivable_applications.application_ref_num%TYPE;
    l_secondary_application_ref_id  ar_receivable_applications.secondary_application_ref_id%TYPE;
  begin
    l_status_evento := 'SUCESSO';
      print_log('inicio: '||p_exe_evento_processo);
    --
    for r1 in (
        select context
        ,      attribute1 
        ,      attribute2 
        ,      attribute3 
        ,      attribute4 
        ,      attribute5 
        ,      attribute6 
        ,      attribute7 
        ,      attribute8 
        ,      attribute9 
        ,      attribute10 
        ,      attribute11
        ,      attribute12
        ,      attribute13
        ,      attribute14
        ,      attribute15
        ,      parameter1  cash_receipt_id
        ,      parameter2  amount_applied
        ,      parameter3  applied_payment_schedule_id
        ,      parameter4  receivables_trx_id
        ,      parameter5  pay_group_lookup_code
        ,      parameter6  payment_method_code
        ,      parameter7  pay_alone_flag
        ,      parameter8  payment_reason_code
        ,      parameter9  payment_reason_comments
        ,      parameter10 party_id
        ,      parameter11 party_site_id
        ,      parameter12 bank_account_id
        ,      parameter13 payment_priority
        ,      parameter14 terms_id
        ,      parameter15 receivable_application_id
        ,      parameter16 application_ref_type
        ,      parameter17 application_ref_id
        ,      parameter18 application_ref_num
        ,      parameter19 secondary_application_ref_id
        ,      org_id
        ,      dt_transacao apply_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      l_attribute_record.ATTRIBUTE_CATEGORY := r1.context;
      l_attribute_record.attribute1         := r1.attribute1;
      l_attribute_record.attribute2         := r1.attribute2;
      l_attribute_record.attribute3         := r1.attribute3;
      l_attribute_record.attribute4         := r1.attribute4;
      l_attribute_record.attribute5         := r1.attribute5;
      l_attribute_record.attribute6         := r1.attribute6;
      l_attribute_record.attribute7         := r1.attribute7;
      l_attribute_record.attribute8         := r1.attribute8;
      l_attribute_record.attribute9         := r1.attribute9;
      l_attribute_record.attribute10        := r1.attribute10;
      l_attribute_record.attribute11        := r1.attribute11;
      l_attribute_record.attribute12        := r1.attribute12;
      l_attribute_record.attribute13        := r1.attribute13;
      l_attribute_record.attribute14        := r1.attribute14;
      l_attribute_record.attribute15        := r1.attribute15;
      l_application_ref_type                := r1.application_ref_type;
      l_application_ref_id                  := r1.application_ref_id;
      l_application_ref_num                 := r1.application_ref_num;
      l_secondary_application_ref_id        := r1.secondary_application_ref_id;
      --
      print_log(r1.amount_applied);
      if r1.amount_applied > 0
      then
          l_applied_payment_schedule_id := r1.applied_payment_schedule_id;
          if r1.receivables_trx_id is not null
          then
             l_applied_payment_schedule_id  := -8;
             l_pay_group_lookup_code        := r1.pay_group_lookup_code;
             l_payment_method_code          := r1.payment_method_code;
             l_pay_alone_flag               := r1.pay_alone_flag;
             l_payment_reason_code          := r1.payment_reason_code;
             l_payment_reason_comments      := r1.payment_reason_comments;
             l_party_id                     := r1.party_id;
             l_party_site_id                := r1.party_site_id;
             l_bank_account_id              := r1.bank_account_id;
             l_payment_priority             := r1.payment_priority;
             l_terms_id                     := r1.terms_id;
             l_application_ref_type         := r1.application_ref_type;
             l_application_ref_id           := r1.application_ref_id;
             l_application_ref_num          := r1.application_ref_num;
             l_secondary_application_ref_id := r1.secondary_application_ref_id;
             if l_party_id is null
             then
                select hca.party_id
                ,      hcas.party_site_id
                into   l_party_id
                ,      l_party_site_id
                from   ar_cash_receipts_all acr
                ,      hz_cust_accounts_all hca
                ,      hz_cust_site_uses_all hcsu
                ,      hz_cusT_ACCT_SITES_ALL HCAS
                where  acr.cash_receipt_id     = r1.cash_receipt_id
                and    hca.cust_account_id     = acr.PAY_FROM_CUSTOMER
                and    hcsu.site_use_id        = acr.CUSTOMER_SITE_USE_ID
                AND    HCAS.cust_acct_site_id  = hcsu.CUST_ACCT_SITE_ID;
      print_log('r1.cash_receipt_id: '||r1.cash_receipt_id);
      print_log('r1.amount_applied: '||r1.amount_applied);
      print_log('l_applied_payment_schedule_id: '||l_applied_payment_schedule_id);
      print_log('r1.apply_date: '||r1.apply_date);
      print_log('r1.receivables_trx_id: '||r1.receivables_trx_id);
      print_log('l_pay_group_lookup_code: '||l_pay_group_lookup_code);
      print_log('l_payment_method_code: '||l_payment_method_code);
      print_log('l_payment_priority: '||l_payment_priority);
      print_log('l_terms_id: '||l_terms_id);
             end if;
          end if;
      print_log('l_receivable_application_id: '||l_receivable_application_id);
          AR_RECEIPT_API_PUB.Activity_application(
          -- Standard API parameters.
            p_api_version                  => 1.0,
            p_init_msg_list                => FND_API.G_FALSE,
            p_commit                       => FND_API.G_FALSE,
            p_validation_level             => FND_API.G_VALID_LEVEL_FULL,
            x_return_status                => l_return_status,
            x_msg_count                    => l_msg_count,
            x_msg_data                     => l_msg_data,
          -- Receipt application parameters.
            p_cash_receipt_id              => r1.cash_receipt_id,
            p_receipt_number               => NULL,
            p_amount_applied               => r1.amount_applied,
            p_applied_payment_schedule_id  => l_applied_payment_schedule_id,
            p_link_to_customer_trx_id	   => NULL,
            p_receivables_trx_id           => r1.receivables_trx_id,
            p_apply_date                   => r1.apply_date,
            p_apply_gl_date                => r1.apply_date,
            p_ussgl_transaction_code       => NULL,
            p_attribute_rec                => l_attribute_record,
          -- ******* Global Flexfield parameters *******
            p_global_attribute_rec         => l_global_attribute_record,
            p_comments                     => NULL,
            p_application_ref_type         => l_application_ref_type,
            p_application_ref_id           => l_application_ref_id,
            p_application_ref_num          => l_application_ref_num,
            p_secondary_application_ref_id => l_secondary_application_ref_id,
            p_payment_set_id               => NULL,
            p_receivable_application_id    => l_receivable_application_id,
            p_customer_reference           => NULL,
            p_val_writeoff_limits_flag     => 'Y',
            p_called_from		           => NULL,
            p_netted_receipt_flag	       => 'N',
            p_netted_cash_receipt_id       => NULL,
            p_secondary_app_ref_type       => NULL,
            p_secondary_app_ref_num        => NULL,
            p_org_id                       => r1.org_id,
            p_customer_reason              => NULL,
            p_pay_group_lookup_code	       => l_pay_group_lookup_code,
            p_pay_alone_flag		       => l_pay_alone_flag,
            p_payment_method_code	       => l_payment_method_code,
            p_payment_reason_code	       => l_payment_reason_code,
            p_payment_reason_comments      => l_payment_reason_comments,
            p_delivery_channel_code	       => NULL,
            p_remittance_message1	       => NULL,
            p_remittance_message2	       => NULL,
            p_remittance_message3	       => NULL,
            p_party_id		               => l_party_id,
            p_party_site_id		           => l_party_site_id,
            p_bank_account_id		       => l_bank_account_id,
            p_payment_priority	           => l_payment_priority,
            p_terms_id		               => l_terms_id);
          --
      print_log('l_receivable_application_id: '||l_receivable_application_id);
      print_log('l_msg_data: '||l_msg_data);
      print_log('l_return_status: '||l_return_status);
          if l_return_status != 'S' then
             if l_msg_count = 1 Then
                l_status_evento   := 'ERRO';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_msg_data);
                print_log(l_msg_data);
             elsif l_msg_count > 1 Then
                   vn_count := 0;
                   loop
                     vn_count := vn_count + 1;
                     if l_msg_data is NULL then
                        exit;
                     end if;
                     --
                     l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                     l_status_evento   := 'ERRO';
                     xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                       ,p_mensagem            => l_msg_data);
                      print_log('Mensagem (' || vn_count ||') = '||l_msg_data);
                   end loop;
             end if;
          end if;
      end if;
      --
      if l_receivable_application_id is null
      then
         l_status_evento   := 'ERRO';
         xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                           ,p_mensagem            => 'Rembolso não aplicado.');
      end if;
      --
      update xxfr.xxfr_ar_exe_evento_processo
      set    parameter15 = l_receivable_application_id
      ,      parameter16 = l_application_ref_type
      ,      parameter17 = l_application_ref_id
      ,      parameter18 = l_application_ref_num
      ,      parameter19 = l_secondary_application_ref_id
      ,      status_processo = decode(l_status_evento,'ERRO',3,2)
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    end loop;
  end aplica_reembolso;

  procedure baixa_titulo_ap (p_exe_evento_processo in number) is
    w_check_id                   ap_checks.check_id%type;
    w_PAYMENT_DOCUMENT_ID        number;
    w_bank_account_id            number;
    w_invoice_num                ap_invoices.invoice_num%type;
    w_vl_saldo_parcela           ap_payment_schedules.amount_remaining%type;
    w_ultimo_cheque              ap_check_stocks.last_document_num%type;
    w_check_format_id            ap_check_stocks.check_format_id%type;
    w_bank_num                   ap_bank_branches.bank_num%type;
    w_bank_account_num           ap_bank_accounts.bank_account_num%type;
    w_bank_account_type          ap_bank_accounts.bank_account_type%type;
    w_bank_account_name          ap_bank_accounts.bank_account_name%type;
    w_vendor_id                  ap_invoices.vendor_id%type;
    w_vendor_site_id             ap_invoices.vendor_site_id%type;
    w_invoice_currency_code      ap_invoices.invoice_currency_code%type;
    w_address_line1              po_vendor_sites.address_line1%type;
    w_address_line2              po_vendor_sites.address_line2%type;
    w_address_line3              po_vendor_sites.address_line3%type;
    w_state                      po_vendor_sites.state%type;
    w_city                       po_vendor_sites.city%type;
    w_country                    po_vendor_sites.country%type;
    w_segment1                   po_vendors.segment1%type;
    w_vendor_name                po_vendors.vendor_name%type;
    w_accounting_event_id        ap_accounting_events.accounting_event_id%type;
    w_invoice_payment_id         ap_invoice_payments.invoice_payment_id%type;
    w_status                     ap_invoices_v.APPROVAL_STATUS_LOOKUP_CODE%TYPE;
    W_ERRO                       VARCHAR2(32767);
    l_invoice_type               ap_invoices.invoice_type_lookup_code%TYPE;
    l_EXCLUSIVE_PAYMENT_FLAG     ap_invoices_ready_to_pay_v.EXCLUSIVE_PAYMENT_FLAG%TYPE;
    l_ACCTS_PAY_CODE_COMBI_ID    ap_invoices_ready_to_pay_v.ACCTS_PAY_CODE_COMBI_ID%TYPE;
    l_FUTURE_DATED_PAYMENT_CCID  ap_invoices_ready_to_pay_v.FUTURE_DATED_PAYMENT_CCID%TYPE;
 
    w_base_amount                ap_invoices.base_amount%type;
    w_rate_var_gain_ccid         FINANCIALS_SYSTEM_PARAMETERS.rate_var_gain_ccid%type;
    w_rate_var_loss_ccid         FINANCIALS_SYSTEM_PARAMETERS.rate_var_loss_ccid%type;
    w_vendor_site_code           po_vendor_sites.vendor_site_code%type;
    w_address_line4              po_vendor_sites.address_line4%type;
    w_zip_code                   hz_locations.postal_code%type;
    w_legal_entity_id            ap_invoices_all.legal_entity_id%type;
    w_party_id                   ap_invoices_all.party_id%type;
    w_party_site_id              ap_invoices_all.party_site_id%type;
    w_BANK_ACCT_USE_ID           number;
    w_exchange_rate              number;
    w_exchange_rate_type         varchar2(100);
    w_exchange_date              date;

    --
    W_period_name  VARCHAR2(30);
    W_SET_OF_BKS   INTEGER;
  BEGIN
    --
    for r1 in (
        select parameter1  invoice_id
        ,      parameter2  payment_num
        ,      parameter3  PAYMENT_DOCUMENT_ID
        ,      parameter4  bank_account_id
        ,      parameter5  amount
        ,      parameter6  payment_method_code
        ,      org_id
        ,      dt_transacao check_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
    SAVEPOINT BAIXA_TITULO_AP;
    fnd_file.put_line(fnd_file.log,'Cheguei');
    --------------------------------------------------------
    --Verifica se o titulo esta aprovado
    --------------------------------------------------------
    SELECT APPROVAL_STATUS_LOOKUP_CODE, INVOICE_TYPE_LOOKUP_CODE
    INTO   w_status
          ,l_invoice_type
    FROM   ap_invoices_v
    WHERE  invoice_id = r1.invoice_id;
    --
    IF (l_invoice_type <> 'PREPAYMENT' AND w_status <> 'APPROVED') OR
       (l_invoice_type =  'PREPAYMENT' AND w_status <> 'UNPAID')   THEN
      Raise_Application_Error(-20099, 'O titulo nao esta aprovado');
    END IF;
    --------------------------------------------------------
    --Busca valores principais do fornecedor e do t¿tulo
    --------------------------------------------------------
    fnd_file.put_line(fnd_file.log,'Busca valores principais do fornecedor e do título');
    BEGIN
      --
      select a.vendor_id
      ,      a.vendor_site_id
      ,      a.invoice_currency_code
      ,      f.address1
      ,      f.address2
      ,      f.address3
      ,      f.state
      ,      f.country
      ,      f.city
      ,      d.party_name
      ,      a.invoice_num
      ,      a.base_amount
      ,      e.party_site_name
      ,      f.address4
      ,      f.postal_code
      ,      a.legal_entity_id
      ,      a.party_id
      ,      a.party_site_id
      ,      a.exchange_rate
      ,      a.exchange_rate_type
      ,      a.exchange_date
      into   w_vendor_id
      ,      w_vendor_site_id
      ,      w_invoice_currency_code
      ,      w_address_line1
      ,      w_address_line2
      ,      w_address_line3
      ,      w_state
      ,      w_country
      ,      w_city
      ,      w_vendor_name
      ,      w_invoice_num
      ,      w_base_amount
      ,      w_vendor_site_code
      ,      w_address_line4
      ,      w_zip_code
      ,      w_legal_entity_id
      ,      w_party_id
      ,      w_party_site_id
      ,      w_exchange_rate
      ,      w_exchange_rate_type
      ,      w_exchange_date
      from   ap_invoices               a
      ,      hz_parties                d
      ,      hz_party_sites            e
      ,      hz_locations              f
      where  a.invoice_id            = r1.invoice_id
      and    d.party_id              = a.party_id
      and    e.party_site_id         = a.party_site_id
      and    f.location_id           = e.location_id;
      --
      SELECT EXCLUSIVE_PAYMENT_FLAG
            ,ACCTS_PAY_CODE_COMBI_ID
            ,FUTURE_DATED_PAYMENT_CCID
      INTO   l_EXCLUSIVE_PAYMENT_FLAG
            ,l_ACCTS_PAY_CODE_COMBI_ID
            ,l_FUTURE_DATED_PAYMENT_CCID
      FROM   ap_invoices_ready_to_pay_v
      where  invoice_id  = r1.invoice_id
      AND    PAYMENT_NUM = r1.payment_num;
      --
    EXCEPTION
      WHEN No_Data_Found THEN
           Raise_Application_Error(-20001, 'Nao foi possivel localizar os dados basicos do titulo - '||SQLERRM);
    END;
    --
    BEGIN
    fnd_file.put_line(fnd_file.log,'Busca conta');
      select BANK_ACCT_USE_ID
      ,      ba.bank_account_name
      ,      ba.bank_account_num
      into   w_BANK_ACCT_USE_ID
      ,      w_bank_account_name
      ,      w_bank_account_num
      from   ce_bank_acct_uses_all bcu
      ,      ce_bank_accounts      ba
      where  ba.BANK_ACCOUNT_ID  = r1.BANK_ACCOUNT_ID
      and    bcu.BANK_ACCOUNT_ID = ba.BANK_ACCOUNT_ID;
    EXCEPTION
      WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Nao foi possivel reservar o proximo numero do documento do lote de pagamento - '||SQLERRM);
           Raise_Application_Error(-20002, 'Nao foi possivel reservar o proximo numero do documento do lote de pagamento - '||SQLERRM);
    END;
    --------------------------------------------------------
    --Reserva o pr¿ximo n¿mero do lote de documentos de pagamento
    --------------------------------------------------------
    fnd_file.put_line(fnd_file.log,'Busca documento');
    BEGIN
      select LAST_ISSUED_DOCUMENT_NUMBER + 1
      into   w_ultimo_cheque
      from   CE_PAYMENT_DOCUMENTS
      where  PAYMENT_DOCUMENT_ID   = r1.PAYMENT_DOCUMENT_ID
      for    update of LAST_ISSUED_DOCUMENT_NUMBER;
      --
      update CE_PAYMENT_DOCUMENTS
      set    LAST_ISSUED_DOCUMENT_NUMBER = w_ultimo_cheque
      where  PAYMENT_DOCUMENT_ID   = r1.PAYMENT_DOCUMENT_ID;
      --
    EXCEPTION
      WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Nao foi possivel reservar o proximo numero do documento do lote de pagamento - '||SQLERRM);
           Raise_Application_Error(-20002, 'Nao foi possivel reservar o proximo numero do documento do lote de pagamento - '||SQLERRM);
    END;
    --------------------------------------------------------
    --Cria o documento de pagamento
    --------------------------------------------------------
    DECLARE
    --
      X_Rowid  VARCHAR2(30) := NULL;
     --
    BEGIN
      --
      select ap_checks_s.nextval
      into   w_check_id
      from   dual;
      --
    fnd_file.put_line(fnd_file.log,'Insere AP_CHECKS');
      AP_CHECKS_PKG.INSERT_ROW
        (X_Rowid                      => X_Rowid
        ,X_Amount                     => r1.amount
        ,X_Ce_Bank_Acct_Use_Id        => w_bank_acct_use_id
        ,X_Bank_Account_Name          => w_bank_account_name
        ,X_Check_Date                 => r1.check_date
        ,X_Check_Id                   => w_check_id
        ,X_Check_Number               => w_ultimo_cheque
        ,X_Currency_Code              => w_invoice_currency_code
        ,X_Last_Updated_By            => FND_GLOBAL.USER_ID
        ,X_Last_Update_Date           => SYSDATE
        ,X_Payment_Type_Flag          => 'M'
        ,X_Address_Line1              => w_address_line1
        ,X_Address_Line2              => w_address_line2
        ,X_Address_Line3              => w_address_line3
        ,X_City                       => w_city
        ,X_Country                    => w_country
        ,X_Created_By                 => FND_GLOBAL.USER_ID
        ,X_Creation_Date              => SYSDATE
        ,X_Last_Update_Login          => FND_GLOBAL.LOGIN_ID
        ,X_Status_Lookup_Code         => 'NEGOTIABLE'
        ,X_Vendor_Name                => w_vendor_name
        ,X_Vendor_Site_Code           => NULL
        ,X_Vendor_Id                  => w_vendor_id
        ,X_Vendor_Site_Id             => w_vendor_site_id
 		,X_External_Bank_Account_Id   => NULL
        ,x_payment_method_code        => r1.payment_method_code
        ,x_payment_document_id        => r1.payment_document_id
        ,x_party_id                   => w_party_id
        ,x_party_site_id              => w_party_site_id
        ,x_legal_entity_id            => w_legal_entity_id
        ,X_Org_Id                     => r1.Org_Id
		,X_calling_sequence		      => '000'
        ,X_Exchange_Rate              => w_exchange_rate
        ,X_Exchange_Date              => w_exchange_date
        ,X_Exchange_Rate_Type         => w_exchange_rate_type);
        --
    fnd_file.put_line(fnd_file.log,'CHECK_ID: '||w_check_id);
    EXCEPTION
      WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Nao foi possivel criar o documento de pagamento - '||SQLERRM);
           Raise_Application_Error(-20003, 'Nao foi possivel criar o documento de pagamento - '||SQLERRM);
    END;
    --------------------------------------------------------
    --Cria registro cont¿bil do pagamento da parcela do titulo
    --------------------------------------------------------
    BEGIN
      --
    fnd_file.put_line(fnd_file.log,'Insere AP_ACCOUNTING_EVENTS');
      AP_ACCOUNTING_EVENTS_PKG.CREATE_EVENTS
      (P_Event_Type            => 'PAYMENT'
      ,p_doc_type              => 'XX'
      ,P_Doc_ID                => w_check_id
      ,P_Accounting_Date       => to_date(r1.check_date)
      ,P_Accounting_Event_ID   => w_accounting_event_id
      ,p_checkrun_name         => 'XX'
      ,P_Calling_Sequence      => '000');
      --
    fnd_file.put_line(fnd_file.log,'ACCOUNTING_EVENT: '||w_accounting_event_id);
    EXCEPTION
      WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Não foi possível criar o registro contábil do pagamento da parcela do título - '||SQLERRM);
           Raise_Application_Error(-20004, 'Não foi possível criar o registro contábil do pagamento da parcela do título - '||SQLERRM);
    END;
    --------------------------------------------------------
    --Efetua o pagamento
    --------------------------------------------------------
--    DECLARE
    --
    --
    BEGIN
      --
    fnd_file.put_line(fnd_file.log,'Recuperando Periodo contábil');
      SELECT PERIOD_NAME
      INTO   W_period_name
      FROM   GL_PERIODS
      WHERE  r1.check_date BETWEEN START_DATE AND END_DATE  --To_Date('01/06/1998', 'DD/MM/RRRR') BETWEEN START_DATE AND END_DATE
      AND    ADJUSTMENT_PERIOD_FLAG = 'N'
      AND    PERIOD_SET_NAME        = 'FRISIA'
      AND    PERIOD_TYPE            = 21;
      --
      W_SET_OF_BKS := FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
      --
      SELECT ap_invoice_payments_s.NEXTVAL
      INTO   w_invoice_payment_id
      FROM   dual;
      --
    fnd_file.put_line(fnd_file.log,'Insere AP_PAY_INVOICE');
      AP_PAY_INVOICE_PKG.AP_PAY_INVOICE
      (P_invoice_id              =>  r1.invoice_id
      ,P_check_id                =>  w_check_id
      ,P_payment_num             =>  r1.payment_num
      ,P_invoice_payment_id      =>  w_invoice_payment_id
      ,P_old_invoice_payment_id  =>  NULL
      ,P_period_name             =>  W_period_name
      ,P_invoice_type            =>  l_invoice_type
      ,P_accounting_date         =>  to_date(r1.check_date)
      ,P_amount                  =>  r1.amount
      ,P_discount_taken          =>  (w_vl_saldo_parcela - r1.amount)
	  ,P_discount_lost		     =>  NULL
	  ,P_invoice_base_amount	 =>  NULL
	  ,P_payment_base_amount	 =>  NULL
      ,P_accrual_posted_flag     =>  'N'
      ,P_cash_posted_flag        =>  'N'
      ,P_posted_flag             =>  'N'
      ,P_set_of_books_id         =>  W_SET_OF_BKS
      ,P_last_updated_by         =>  fnd_global.user_id
      ,P_last_update_login       =>  fnd_global.login_id
      ,P_currency_code           =>  w_invoice_currency_code
      ,P_base_currency_code      =>  w_invoice_currency_code
      ,P_exchange_rate           =>  w_exchange_rate
      ,P_exchange_rate_type      =>  w_exchange_rate_type
      ,P_exchange_date           =>  w_exchange_date
      ,P_ce_bank_acct_use_id     =>  w_bank_acct_use_id
      ,P_bank_account_num        =>  w_bank_account_num
      ,P_bank_account_type       =>  w_bank_account_type
      ,P_bank_num                =>  w_bank_num
      ,P_future_pay_posted_flag  =>  'N'
      ,P_exclusive_payment_flag  =>  l_exclusive_payment_flag
      ,P_accts_pay_ccid          =>  l_ACCTS_PAY_CODE_COMBI_ID
      ,P_gain_ccid	  	         =>  NULL
      ,P_loss_ccid   	  	     =>  NULL
      ,P_future_pay_ccid         =>  NULL  --l_FUTURE_DATED_PAYMENT_CCID
	  ,P_asset_ccid	  	         =>  NULL
      ,P_payment_dists_flag      =>  'N'
      ,P_payment_mode            =>  'PAY'
      ,P_replace_flag            =>  'N'
      ,P_calling_sequence        =>  '000'
      ,P_accounting_event_id     =>  w_accounting_event_id
      ,p_org_id                  =>  r1.org_id);
      --
    fnd_file.put_line(fnd_file.log,'INVOICE_PAYMENT_ID: '||w_invoice_payment_id);
      ---------------------------------------------------------------
      -- Ajuste para contabilizacao
      ---------------------------------------------------------------
    
      select 
        rate_var_gain_ccid, 
        rate_var_loss_ccid 
      into
        w_rate_var_gain_ccid, 
        w_rate_var_loss_ccid
      from FINANCIALS_SYSTEM_PARAMETERS;
    
    
    
      update AP_INVOICE_PAYMENTS
      set accts_pay_code_combination_id =  null
      ,   bank_account_num=null
      ,   bank_num=null 
      ,   exchange_rate_type = 'User'
      ,   gain_code_combination_id = w_rate_var_gain_ccid
      ,   invoice_base_amount = w_base_amount
      ,   loss_code_combination_id = w_rate_var_loss_ccid
      ,   payment_base_amount = (w_exchange_rate * r1.amount)
      where INVOICE_ID = r1.invoice_id;
    
      UPDATE AP_CHECKS_ALL
      SET  VENDOR_SITE_CODE = w_vendor_site_code
      , STATE = w_state
      , ADDRESS_LINE4=w_address_line4
      , exchange_rate_type='User'
      , base_amount = (w_exchange_rate * r1.amount)
      WHERE CHECK_ID=w_check_id;
    EXCEPTION
      WHEN OTHERS THEN
           Raise_Application_Error(-20005, 'Nao foi possivel efetuar o pagamento - '||SQLERRM);
    END;
  end loop;
  --
  update xxfr.xxfr_ar_exe_evento_processo
  set    PARAMETER7      = w_check_id
  ,      PARAMETER8      = w_invoice_payment_id
  ,      PARAMETER9      = w_accounting_event_id
  ,      status_processo = 2
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
   --
--    RETURN('OK');
    --
    EXCEPTION
      WHEN OTHERS THEN
           W_ERRO := SQLERRM;
           ROLLBACK TO BAIXA_TITULO_AP;
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => W_ERRO);
  update xxfr.xxfr_ar_exe_evento_processo
  set status_processo = 3
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
--           RETURN (W_ERRO);
  end  BAIXA_TITULO_AP;

  procedure longo_prazo_finaciamento_ar (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_status_evento                 varchar2(30);
  begin
    null;
  end longo_prazo_finaciamento_ar;

  procedure parcelas_financiamento_ar (p_exe_evento_processo in number) is
  begin
    null;
  end parcelas_financiamento_ar;

  procedure juros_financiamento_ar (p_exe_evento_processo in number) is
  begin
    null;
  end juros_financiamento_ar;

  procedure lancamento_contabil (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_status_evento                 varchar2(30);
    l_period_name                   VARCHAR2(30);
    l_SET_OF_BKS                    INTEGER;
    l_group_id                      number;
    l_reference11                   varchar2(30);
    l_cnt                           number;
    l_amount                        number;
    l_code_combination_id           number;
  BEGIN
    --
    for r1 in (
        select parameter1  ledger_id
        ,      parameter2  currency_code
        ,      parameter3  USER_JE_CATEGORY_NAME
        ,      parameter4  USER_JE_SOURCE_NAME
        ,      parameter5  amount
        ,      parameter6  reference1
        ,      parameter7  reference2
        ,      parameter8  reference3
        ,      parameter9  reference10
        ,      parameter10 reference11
        ,      parameter11 CHART_OF_ACCOUNTS_ID
        ,      parameter12 GROUP_ID
        ,      parameter13 DB_CODE_COMBINATION_ID
        ,      parameter14 CR_CODE_COMBINATION_ID
        ,      org_id
        ,      dt_transacao accounting_date
        ,      ID_EXECUCAO_PROCESSO
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      SELECT PERIOD_NAME
      INTO   l_period_name
      FROM   GL_PERIODS
      WHERE  r1.accounting_date BETWEEN START_DATE AND END_DATE  --To_Date('01/06/1998', 'DD/MM/RRRR') BETWEEN START_DATE AND END_DATE
      AND    ADJUSTMENT_PERIOD_FLAG = 'N'
      AND    PERIOD_SET_NAME        = 'FRISIA'
      AND    PERIOD_TYPE            = 1;
      --
      L_SET_OF_BKS := FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
      --
      if r1.reference11 is null
      then
         l_reference11 := r1.ID_EXECUCAO_PROCESSO;
      else
         l_reference11 := r1.reference11;
      end if;
      --
      if r1.group_id is null
      then
         l_group_id := to_char(r1.accounting_date,'RRMMDD');
      else
         l_group_id := r1.group_id;
      end if;
      --
      if nvl(r1.amount,0) != 0
      then
         l_cnt := 1;
         l_amount := r1.amount;
         --
         loop
           if l_cnt = 1
           then
              l_code_combination_id := r1.db_code_combination_id;
           else
              l_code_combination_id := r1.cr_code_combination_id;
           end if;
           --
           insert into gl_interface
                (STATUS
                ,LEDGER_ID
                ,ACCOUNTING_DATE
                ,CURRENCY_CODE
                ,DATE_CREATED
                ,CREATED_BY
                ,ACTUAL_FLAG
                ,USER_JE_CATEGORY_NAME
                ,USER_JE_SOURCE_NAME
                ,PERIOD_NAME
                ,ENTERED_DR
                ,ENTERED_CR
                ,ACCOUNTED_DR
                ,ACCOUNTED_CR
                ,TRANSACTION_DATE
                ,REFERENCE1
                ,REFERENCE2
                ,REFERENCE3
                ,REFERENCE10
                ,REFERENCE11
                ,CHART_OF_ACCOUNTS_ID
                ,CODE_COMBINATION_ID
                ,GROUP_ID
                ,SET_OF_BOOKS_ID)
           VALUES ('NEW'
                ,R1.LEDGER_ID
                ,R1.ACCOUNTING_DATE
                ,R1.CURRENCY_CODE
                ,SYSDATE
                ,FND_PROFILE.VALUE('USER_ID')
                ,'A'
                ,R1.USER_JE_CATEGORY_NAME
                ,R1.USER_JE_SOURCE_NAME
                ,L_PERIOD_NAME
                ,DECODE(SIGN(l_AMOUNT),-1,NULL,l_AMOUNT) --ENTERED_DR
                ,DECODE(SIGN(l_AMOUNT),-1,-l_AMOUNT)     --ENTERED_CR
                ,DECODE(SIGN(l_AMOUNT),-1,NULL,l_AMOUNT) --ACCOUNTED_DR
                ,DECODE(SIGN(l_AMOUNT),-1,-l_AMOUNT)     --ACCOUNTED_CR
                ,R1.ACCOUNTING_DATE                        --TRANSACTION_DATE
                ,R1.REFERENCE1
                ,R1.REFERENCE2
                ,R1.REFERENCE3
                ,R1.REFERENCE10
                ,L_REFERENCE11
                ,R1.CHART_OF_ACCOUNTS_ID
                ,L_CODE_COMBINATION_ID
                ,L_GROUP_ID
                ,L_SET_OF_BKS);                            --SET_OF_BOOKS_ID
          --
          l_cnt := l_cnt + 1;
          l_amount := -1 * l_amount;
          --
          if l_cnt > 2
          then
             exit;
          end if;
        end loop;
      end if;
      --
      update xxfr.xxfr_ar_exe_evento_processo
      set    status_processo = decode(l_status_evento,'ERRO',3,2)
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    end loop;
  end lancamento_contabil; 

  procedure informacao_atividade_ar (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_status_evento                 varchar2(30);
    l_id_atividade                  varchar2(30);
    l_id_atividade_cooperado        varchar2(30);
    l_cd_tipo_contrato              varchar2(30);
    l_cd_destino_recurso            varchar2(30);
    l_cd_lancamento                 varchar2(30);
    l_tipo_atividade                varchar2(30);
    l_db_code_combination_id        varchar2(30);
    l_cr_code_combination_id        varchar2(30);
    l_lp_code_combination_id        varchar2(30);
    l_juros_code_combination_id     varchar2(30);
    l_tipo_conta_cap_giro           varchar2(30);
    l_nome_atividade                varchar2(200);
    l_descricao_atividade           varchar2(240);
  BEGIN
    --
    for r1 in (
        select parameter1  id_atividade
        ,      parameter2  id_atividade_cooperado
        ,      parameter3  cd_tipo_contrato
        ,      parameter4  cd_destino_recurso
        ,      parameter5  cd_lancamento
        ,      parameter6  tipo_atividade
        ,      parameter7  db_code_combination_id
        ,      parameter8  cr_code_combination_id
        ,      parameter9  tipo_conta_cap_giro
        ,      parameter10 nome_atividade
        ,      parameter11 descricao_atividade
        ,      parameter12  lp_code_combination_id
        ,      parameter13  juros_code_combination_id
        ,      org_id
        ,      dt_transacao accounting_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      if r1.id_atividade is not null or r1.cd_lancamento is not null
      then
         begin
           select x.RECEIVABLES_TRX_ID  id_atividade
           ,      x.attribute1          id_atividade_cooperado
           ,      x.attribute2          cd_tipo_contrato
           ,      x.attribute3          cd_destino_recurso
           ,      x.attribute4          cd_lancamento
           ,      x.type                tipo_atividade
           ,      x.code_combination_id db_code_combination_id
           ,      x.attribute5          cr_code_combination_id
           ,      x.attribute6          tipo_conta_cap_giro
           ,      x.name                nome_atividade
           ,      x.description         descricao_atividade
           ,      x.attribute7          lp_code_combination_id
           ,      x.attribute8          juros_code_combination_id
           into   l_id_atividade
           ,      l_id_atividade_cooperado
           ,      l_cd_tipo_contrato
           ,      l_cd_destino_recurso
           ,      l_cd_lancamento
           ,      l_tipo_atividade
           ,      l_db_code_combination_id
           ,      l_cr_code_combination_id
           ,      l_tipo_conta_cap_giro
           ,      l_nome_atividade
           ,      l_descricao_atividade
           ,      l_lp_code_combination_id
           ,      l_juros_code_combination_id
           from (select 1 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                 from   AR_RECEIVABLES_TRX_ALL
                 where  attribute1       = r1.id_atividade_cooperado
                 and    attribute2       = r1.cd_tipo_contrato
                 and    attribute3       = r1.cd_destino_recurso
                 and    attribute4       = r1.cd_lancamento
                 and    type             = r1.tipo_atividade
                 and    r1.id_atividade is null
                 union
                 select 2 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                 from   AR_RECEIVABLES_TRX_ALL
                 where  attribute1       = r1.id_atividade_cooperado
                 and    attribute2      is null
                 and    attribute3       = r1.cd_destino_recurso
                 and    attribute4       = r1.cd_lancamento
                 and    type             = r1.tipo_atividade
                 and    r1.id_atividade is null
                 union
                 select 3 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                 from   AR_RECEIVABLES_TRX_ALL
                 where  attribute1       = r1.id_atividade_cooperado
                 and    attribute2       = r1.cd_tipo_contrato
                 and    attribute3      is null
                 and    attribute4       = r1.cd_lancamento
                 and    type             = r1.tipo_atividade
                 and    r1.id_atividade is null
                 union
                 select 4 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                 from   AR_RECEIVABLES_TRX_ALL
                 where  attribute1       = r1.id_atividade_cooperado
                 and    attribute2      is null
                 and    attribute3      is null
                 and    attribute4       = r1.cd_lancamento
                 and    type             = r1.tipo_atividade
                 and    r1.id_atividade is null
                 union
                 select 5 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                 from   AR_RECEIVABLES_TRX_ALL
                 where  attribute1      is null
                 and    attribute2       = r1.cd_tipo_contrato
                 and    attribute3       = r1.cd_destino_recurso
                 and    attribute4       = r1.cd_lancamento
                 and    type             = r1.tipo_atividade
                 and    r1.id_atividade is null
                 union
                 select 6 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                 from   AR_RECEIVABLES_TRX_ALL
                 where  attribute1      is null
                 and    attribute2      is null
                 and    attribute3       = r1.cd_destino_recurso
                 and    attribute4       = r1.cd_lancamento
                 and    type             = r1.tipo_atividade
                 and    r1.id_atividade is null
                 union
                 select 7 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                 from   AR_RECEIVABLES_TRX_ALL
                 where  attribute1      is null
                 and    attribute2       = r1.cd_tipo_contrato
                 and    attribute3      is null
                 and    attribute4       = r1.cd_lancamento
                 and    type             = r1.tipo_atividade
                 and    r1.id_atividade is null
                 union
                 select 8 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                 from   AR_RECEIVABLES_TRX_ALL
                 where  attribute1      is null
                 and    attribute2      is null
                 and    attribute3      is null
                 and    attribute4       = r1.cd_lancamento
                 and    type             = r1.tipo_atividade
                 and    r1.id_atividade is null
                 union
                 select 9 seq
                 ,      RECEIVABLES_TRX_ID
                 ,      attribute1
                 ,      attribute2
                 ,      attribute3
                 ,      attribute4
                 ,      type
                 ,      code_combination_id
                 ,      attribute5
                 ,      attribute6
                 ,      name
                 ,      description
                 ,      attribute7
                 ,      attribute8
                from   ar_receivables_trx_all
                where  receivables_trx_id = r1.id_atividade
                 order by 1) x
            where rownum = 1;
         exception
           when no_data_found then
                l_status_evento := 'ERRO';
                l_msg_data      := 'Atividade para o tipo de lançamento '||r1.cd_lancamento||' não cadastrado.';
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_msg_data);
           when others then
                l_status_evento := 'ERRO';
                l_msg_data      := 'Erro na pesquisa para identificação da atividade para o tipo de lançamento '||r1.cd_lancamento||'. '||sqlerrm;
                xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                  ,p_mensagem            => l_msg_data);
         end;
      end if;
         --
      update xxfr.xxfr_ar_exe_evento_processo
      set    parameter1      = l_id_atividade
      ,      parameter2      = l_id_atividade_cooperado
      ,      parameter3      = l_cd_tipo_contrato
      ,      parameter4      = l_cd_destino_recurso
      ,      parameter5      = l_cd_lancamento
      ,      parameter6      = l_tipo_atividade
      ,      parameter7      = l_db_code_combination_id
      ,      parameter8      = l_cr_code_combination_id
      ,      parameter9      = l_tipo_conta_cap_giro
      ,      parameter10     = l_nome_atividade
      ,      parameter11     = l_descricao_atividade
      ,      parameter12     = l_lp_code_combination_id
      ,      parameter13     = l_juros_code_combination_id
      ,      status_processo = decode(l_status_evento,'ERRO',3,2)
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    end loop;
  end informacao_atividade_ar; 
  
    procedure atualiza_conta_passivo_ap (p_exe_evento_processo in number) is
    l_return_status                 varchar2(240);
    l_msg_count                     number;
    l_msg_data                      varchar2(4000);
    l_status_evento                 varchar2(30);
    l_code_combination_id           varchar2(30);
  BEGIN
    --
    for r1 in (
        select parameter1  invoice_id
        ,      parameter2  concat_code_combination
        ,      org_id
        ,      dt_transacao accounting_date
        from   xxfr.xxfr_ar_exe_evento_processo
        where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo)
    loop
      if r1.invoice_id is not null and r1.concat_code_combination is not null
      then
         begin
           select CODE_COMBINATION_ID
           into   l_code_combination_id
           from   gl_code_combinations_kfv
           where  CONCATENATED_SEGMENTS = r1.concat_code_combination;
           --
           update ap_invoices_all
           set    ACCTS_PAY_CODE_COMBINATION_ID = l_code_combination_id
           where  invoice_id = r1.invoice_id;
        exception
          when no_data_found then
               l_status_evento := 'ERRO';
               l_msg_data      := 'Combinação contábil '||r1.concat_code_combination||' não cadastrada.';
               xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                 ,p_mensagem            => l_msg_data);
          when others then
               l_status_evento := 'ERRO';
               l_msg_data      := 'Erro ao pesquisar ombinação contábil '||r1.concat_code_combination||'. '||sqlerrm;
               xxfr_ar_pck_executa_processo.erro_evento_processo (p_exe_evento_processo => p_exe_evento_processo
                                                                 ,p_mensagem            => l_msg_data);
         end;          
      end if;
      --
      update xxfr.xxfr_ar_exe_evento_processo
      set    status_processo = decode(l_status_evento,'ERRO',3,2)
      where  ID_EXECUCAO_EVENTO_PROCESSO = p_exe_evento_processo;
    end loop;
  end atualiza_conta_passivo_ap; 

  procedure integra_financiamento (
    p_cd_processo                 in  varchar2
    ,p_commit_evento               in  varchar2 default 'S'         -- S-Sim N-Não
    ,p_metodo_execucao             in  varchar2 default 'CONCORRENTE'   -- ON-LINE ou CONCORRENTE
    ,p_dt_liberacao                in  date     default trunc(sysdate)
    ,p_cd_cooperado                in  varchar2
    ,p_cd_contrato                 in  varchar2
    ,p_ds_atividade_rural          in  varchar2
    ,p_nm_cultura                  in  varchar2 default null
    ,p_nm_safra                    in  varchar2 default null
    ,p_nm_proposito                in  varchar2 default null
    ,p_cd_banco_conta_liberacao    in  varchar2 default null
    ,p_cd_agencia_conta_liberacao  in  varchar2 default null
    ,p_cd_conta_liberacao          in  varchar2 default null
    ,p_cd_banco_conta_recurso      in  varchar2 default null
    ,p_cd_agencia_conta_recurso    in  varchar2 default null
    ,p_cd_conta_origem_recurso     in  varchar2 default null
    ,p_valor_liberado              in  number
    ,p_vl_retencao_custeio         in  number default 0
    ,p_condicao_pgto_custeio       in  varchar2 default null
    ,p_ds_uso_financiamento        in  varchar2 default null
    ,p_vl_uso_financiamento        in  number default 0
    ,p_vl_financiamento_mao_obra   in  number default 0
    ,p_cd_metodo_pgto_mao_obra     in  varchar2 default null
    ,p_condicao_pgto_mao_obra      in  varchar2 default null
    --
    ,p_cd_tipo_contrato            in  varchar2 default null
    ,p_cd_destinacao_recurso       in  varchar2 default null
    ,p_taxas                       in  taxas_tbl_type 
    ,p_parcelas                    in  parcelas_tbl_type 
    ,p_vl_juros                    in  number default null
    ,p_vl_longo_prazo              in  number default null
    --
    ,p_org_id                      in  number   default 81
    ,p_id_execucao_processo        in out number
    ,p_status                      out varchar2
    ,p_mensagem                    out tp_mensagens_tbl
  ) is
    l_existe                    number;
    l_id_processo               number;
    l_id_versao_processo        number;
    l_cust_account_id           number;
    l_cd_atividade_cooperado    varchar2(30);
    l_cd_uso_financiamento      varchar2(30);
    l_cd_tipo_atividade         varchar2(20);
    l_cd_cultura                varchar2(20);
    l_cd_safra                  varchar2(20);
    l_banco_cooperado           number;
    l_agencia_cooperado         number;
    l_conta_cooperado           number;
    l_banco_recurso             number;
    l_agencia_recurso           number;
    l_conta_recurso             number;
    l_grupo_pagamento           varchar2(50);
    l_payment_method_code       varchar2(50);
    l_prioridade_pagamento      varchar2(50);
    l_term_id                   number;
    l_chr                       varchar2(1);
    l_id_execucao_processo      number;
    l_error_code                number;
    l_error_buf                 varchar2(4000);
    l_cnt_msg                   number;
    l_term_id_custeio           number;
    l_cd_proposito              varchar2(30);
    l_atividade_taxa            number;
    
    l_cd_taxa1                  varchar2(50);
    l_vl_taxa1                  number;
    l_cd_taxa2                  varchar2(50);
    l_vl_taxa2                  number;
    l_cd_taxa3                  varchar2(50);
    l_vl_taxa3                  number;
    l_cd_taxa4                  varchar2(50);
    l_vl_taxa4                  number;
    l_cd_taxa5                  varchar2(50);
    l_vl_taxa5                  number;
    l_cd_taxa6                  varchar2(50);
    l_vl_taxa6                  number;
    l_cd_taxa7                  varchar2(50);
    l_vl_taxa7                  number;
    l_cd_taxa8                  varchar2(50);
    l_vl_taxa8                  number;
    l_cd_taxa9                  varchar2(50);
    l_vl_taxa9                  number;
    l_cd_taxa10                 varchar2(50);
    l_vl_taxa10                 number;
    l_atividade_giro            number;
    l_vl_giro                   number;
    l_conta_capital_giro        varchar2(10);
    l_tipo_conta_giro           varchar2(10);
    l_parcelas                  varchar2(4000);
    nr_parcelas                 number;
    l_taxas                     taxas_tbl_type;
    l_cnt                       integer;
  begin
    print_log('');
    print_log('INICIO INTEGRA_FINANCIAMENTO');
    l_chr     := null;
    p_status  := 'SUCESSO';
    l_cnt_msg := 0;
    --
    if nvl(p_commit_evento,'X') not in ('S','N')
    then 
       p_status   := 'ERRO';
       l_cnt_msg  := l_cnt_msg + 1;
       p_mensagem(l_cnt_msg) := 'O parâmetro "Salvar Evento" deve ser "S"-Sim ou "N"-Não.';
       print_log(p_mensagem(l_cnt_msg));
    end if;
    --
    if nvl(p_metodo_execucao,'X') not in ('ON-LINE','CONCORRENTE') then
       p_status              := 'ERRO';
       l_cnt_msg             := l_cnt_msg + 1;
       p_mensagem(l_cnt_msg) := 'O parâmetro "Método de Execução" estar "ON-LINE" ou "CONCORRENTE".';
       print_log(p_mensagem(l_cnt_msg));
    end if;
    --
    begin
      select id_processo
      into   l_id_processo
      from   xxfr.xxfr_ar_cfg_processo acp
      where  acp.cd_processo = p_cd_processo
      and    p_dt_liberacao between nvl(dt_inicio_vigencia,sysdate - 1000) and nvl(dt_fim_vigencia,sysdate + 1000);
    exception
      when no_data_found then
           p_status              := 'ERRO';
           l_cnt_msg             := l_cnt_msg + 1;
           p_mensagem(l_cnt_msg) := 'O processo '||p_cd_processo||' não existe ou está inativo.';
           print_log(p_mensagem(l_cnt_msg));
      when others then
           p_status              := 'ERRO';
           l_cnt_msg             := l_cnt_msg + 1;
           p_mensagem(l_cnt_msg) := 'Erro ao validar o processo '||p_cd_processo||'.ERRO: '||SQLERRM;
           print_log(p_mensagem(l_cnt_msg));
    end;
    print_log('  l_id_processo                = '||l_id_processo);
    begin
      select id_versao_processo
      into   l_id_versao_processo
      from   xxfr.xxfr_ar_cfg_versao_processo acvp
      where  acvp.id_processo = l_id_processo
      and    p_dt_liberacao between nvl(acvp.dt_inicio_vigencia,sysdate - 1000) and nvl(acvp.dt_fim_vigencia,sysdate + 1000);
    exception
      when no_data_found then
           p_status              := 'ERRO';
           l_cnt_msg             := l_cnt_msg + 1;
           p_mensagem(l_cnt_msg) := 'Não existe versão ativa para o processo '||p_cd_processo||' para a data informada.';
           print_log(p_mensagem(l_cnt_msg));
      when others then
           p_status              := 'ERRO';
           l_cnt_msg             := l_cnt_msg + 1;
           p_mensagem(l_cnt_msg) := 'Erro ao recuperar a versão para o processo '||p_cd_processo||'.ERRO: '||SQLERRM;
           print_log(p_mensagem(l_cnt_msg));
    end;
    print_log('  l_id_versao_processo         = '||l_id_versao_processo);
    begin
      select cust_account_id
      into   l_cust_account_id
      from   hz_cust_accounts_all hca
      where  hca.account_number = p_cd_cooperado
      and    hca.status         = 'A';
    exception
      when no_data_found then
           p_status              := 'ERRO';
           l_cnt_msg             := l_cnt_msg + 1;
           p_mensagem(l_cnt_msg) := 'Cooperado '||p_cd_cooperado||' não cadastrado ou inativo.';
           print_log(p_mensagem(l_cnt_msg));
      when others then
           p_status              := 'ERRO';
           l_cnt_msg             := l_cnt_msg + 1;
           p_mensagem(l_cnt_msg) := 'Erro ao validar o código do cooperado '||p_cd_cooperado||'.ERRO: '||SQLERRM;
           print_log(p_mensagem(l_cnt_msg));
    end;
    --
    print_log('  l_cust_account_id            = '||l_cust_account_id);
    print_log('  p_ds_atividade_rural         = '||p_ds_atividade_rural);
    IF p_ds_atividade_rural is not null then
       begin
         select trim(to_char(ar.cd_tipo_atividade))
         into   l_cd_tipo_atividade
         from   xxfr_vw_atividade_rural ar
         where  ar.ds_tipo_atividade  = p_ds_atividade_rural
         and    ar.ie_situacao        = 'A';
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'A atividade rural '||p_ds_atividade_rural||' não cadastrada ou inativa.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar a atividade rural '||p_ds_atividade_rural||'.ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  l_cd_tipo_atividade          = '||l_cd_tipo_atividade);
    print_log('  p_nm_cultura                 = '||p_nm_cultura);
    IF p_nm_cultura is not null
    then
       begin
         select trim(to_char(ac.cd_cultura))
         into   l_cd_cultura
         from   xxfr_sif_vw_agricola_cultura ac
         where  ac.nm_cultura  = p_nm_cultura
         and    ac.ie_situacao        = 'A';
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'A cultura '||p_nm_cultura||' não cadastrada ou inativa.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar a cultura '||p_nm_cultura||'.ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  l_cd_cultura                 = '||l_cd_cultura);
    print_log('  p_nm_safra                   = '||p_nm_safra);
    IF p_nm_safra is not null
    then
       begin
         select trim(to_char(vas.cd_safra))
         into   l_cd_safra
         from   xxfr_sif_vw_agricola_safra vas
         where  vas.nm_safra     = p_nm_safra
         and    vas.ie_situacao  = 'A';
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'A safra '||p_nm_safra||' não cadastrada ou inativa.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar a safra '||p_nm_safra||'.ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  l_cd_safra                   = '||l_cd_safra);
    print_log('  p_nm_proposito               = '||p_nm_proposito);
    IF p_nm_proposito is not null
    then
       begin
         SELECT lv.LOOKUP_CODE
         INTO   l_cd_proposito
         FROM   fnd_lookup_values_vl lv
         WHERE  lv.LOOKUP_TYPE  = 'XXFR_AR_PROPOSITOS'
         AND    lv.MEANING      = p_nm_proposito
         AND    lv.ENABLED_FLAG = 'Y';
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'O propósito '||p_nm_proposito||' não cadastrado ou inativo.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar o propósito '||p_nm_proposito||'.ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    print_log('  l_cd_proposito               = '||l_cd_proposito);
    print_log('  p_cd_banco_conta_liberacao   = '||p_cd_banco_conta_liberacao);
    print_log('  p_cd_agencia_conta_liberacao = '||p_cd_agencia_conta_liberacao);
    print_log('  p_cd_conta_liberacao         = '||p_cd_conta_liberacao);
    IF p_cd_banco_conta_liberacao   is not null and 
       p_cd_agencia_conta_liberacao is not null and
       p_cd_conta_liberacao  is not null
    then
       begin
         select b.bank_party_id
         ,      bb.branch_party_id
         ,      ba.bank_account_id
         into   l_banco_cooperado
         ,      l_agencia_cooperado
         ,      l_conta_cooperado
         from   ce_banks_v b
         ,      ce_bank_branches_v bb
         ,      ce_bank_accounts ba
         where  b.bank_number     = p_cd_banco_conta_liberacao
         and    p_dt_liberacao between nvl(b.START_DATE,sysdate - 1000) and nvl(b.END_DATE,sysdate + 1000)
         and    bb.bank_party_id     = b.bank_party_id
         and    bb.branch_number     = p_cd_agencia_conta_liberacao
         and    p_dt_liberacao between nvl(bb.START_DATE,sysdate - 1000) and nvl(bb.END_DATE,sysdate + 1000)
         and    ba.bank_id           = bb.bank_party_id
         and    ba.bank_branch_id    = bb.branch_party_id
         and    ba.bank_account_num = p_cd_conta_liberacao
         and    p_dt_liberacao between nvl(ba.START_DATE,sysdate - 1000) and nvl(ba.END_DATE,sysdate + 1000);
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'A conta cooperado para liberação '||p_cd_banco_conta_liberacao||'/'||p_cd_agencia_conta_liberacao||'/'||p_cd_conta_liberacao||' não cadastrada ou inativa.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar a conta cooperado para liberação '||p_cd_banco_conta_liberacao||'/'||p_cd_agencia_conta_liberacao||'/'||p_cd_conta_liberacao||'.ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  p_cd_banco_conta_recurso     = '||p_cd_banco_conta_recurso);
    print_log('  p_cd_agencia_conta_recurso   = '||p_cd_agencia_conta_recurso);
    print_log('  p_cd_conta_origem_recurso    = '||p_cd_conta_origem_recurso);
    IF p_cd_banco_conta_recurso   is not null and 
       p_cd_agencia_conta_recurso is not null and
       p_cd_conta_origem_recurso  is not null
    then
       begin
         select b.bank_party_id
         ,      bb.branch_party_id
         ,      ba.bank_account_id
         into   l_banco_recurso
         ,      l_agencia_recurso
         ,      l_conta_recurso
         from   ce_banks_v b
         ,      ce_bank_branches_v bb
         ,      ce_bank_accounts ba
         where  b.bank_number     = p_cd_banco_conta_recurso
         and    p_dt_liberacao between nvl(b.START_DATE,sysdate - 1000) and nvl(b.END_DATE,sysdate + 1000)
         and    bb.bank_party_id     = b.bank_party_id
         and    bb.branch_number     = p_cd_agencia_conta_recurso
         and    p_dt_liberacao between nvl(bb.START_DATE,sysdate - 1000) and nvl(bb.END_DATE,sysdate + 1000)
         and    ba.bank_id           = bb.bank_party_id
         and    ba.bank_branch_id    = bb.branch_party_id
         and    ba.bank_account_num = p_cd_conta_origem_recurso
         and    p_dt_liberacao between nvl(ba.START_DATE,sysdate - 1000) and nvl(ba.END_DATE,sysdate + 1000);
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'A conta bancária de origem do recurso '||p_cd_banco_conta_recurso||'/'||p_cd_agencia_conta_recurso||'/'||p_cd_conta_origem_recurso||' não cadastrada ou inativa.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar a conta bancária de origem de origem do recurso '||p_cd_banco_conta_recurso||'/'||p_cd_agencia_conta_recurso||'/'||p_cd_conta_origem_recurso||'.ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  p_condicao_pgto_custeio      = '||p_condicao_pgto_custeio);
    IF p_condicao_pgto_custeio is not null
    then
       begin
         select rt.term_id
         into   l_term_id_custeio
         from   RA_TERMS_VL rt
         where  rt.name     = p_condicao_pgto_custeio
         and    p_dt_liberacao between nvl(rt.START_DATE_ACTIVE,sysdate - 1000) and nvl(rt.END_DATE_ACTIVE,sysdate + 1000);
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'A condição de pagamento do custeio '||p_condicao_pgto_custeio||' não cadastrada ou inativa.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar o condição de pagamento do custeio '||p_condicao_pgto_custeio||'. ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  p_ds_uso_financiamento       = '||p_ds_uso_financiamento);
    IF p_ds_uso_financiamento is not null
    then
       begin
         select flv.LOOKUP_CODE
         into   l_cd_uso_financiamento
         from   FND_LOOKUP_VALUES_VL flv
         where  flv.LOOKUP_TYPE  = 'XXFR_AR_USO_FINANCIAMENTO'
         and    flv.MEANING  = p_ds_uso_financiamento
         and    p_dt_liberacao between nvl(flv.START_DATE_ACTIVE,sysdate - 1000) and nvl(flv.END_DATE_ACTIVE,sysdate + 1000);
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Uso de financiamento '||p_ds_uso_financiamento||' não cadastrado ou inativo.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar o uso de financiamento '||p_ds_uso_financiamento||'.ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  p_cd_metodo_pgto_mao_obra    = '||p_cd_metodo_pgto_mao_obra);
    IF p_cd_metodo_pgto_mao_obra is not null
    then
       begin
         select pm.payment_method_code
         into   l_payment_method_code
         from   iby_payment_methods_vl pm
         where  pm.payment_method_name     = p_cd_metodo_pgto_mao_obra;
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'O método de pagamento mão de obra '||p_cd_metodo_pgto_mao_obra||' não cadastrado ou inativo.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar o método de pagamento mão de obra '||p_cd_metodo_pgto_mao_obra||'.ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  p_condicao_pgto_mao_obra     = '||p_condicao_pgto_mao_obra);
    IF p_condicao_pgto_mao_obra is not null
    then
       begin
         select at.term_id
         into   l_term_id
         from   ap_terms at
         where  at.name     = p_condicao_pgto_mao_obra
         and    p_dt_liberacao between nvl(at.START_DATE_ACTIVE,sysdate - 1000) and nvl(at.END_DATE_ACTIVE,sysdate + 1000);
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'A condição de pagamento da mão de obra '||p_condicao_pgto_mao_obra||' não cadastrada ou inativa.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar o condição de pagamento da mão de obra '||p_condicao_pgto_mao_obra||'. ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    --
    print_log('  p_cd_destinacao_recurso      = '||p_cd_destinacao_recurso);
    if p_cd_destinacao_recurso is null
    then
       p_status              := 'ERRO';
       l_cnt_msg             := l_cnt_msg + 1;
       p_mensagem(l_cnt_msg) := 'O código da destinação do recurso deve ser informado.';
    else 
       begin
          null;
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'O código da destinação do recurso '||p_cd_destinacao_recurso||' não cadastrado ou inativo.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao validar o código da destinação do recurso '||p_cd_destinacao_recurso||'. ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    print_log('  p_cd_tipo_contrato           = '||p_cd_tipo_contrato);
    print_log('');
    print_log('  INICIO TAXAS E PARECELAS');
    -- INICIO TAXAS E PARCELAS
    l_taxas := p_taxas;
    --
    for i in 1..l_taxas.last loop
      print_log('  Taxa:'||i||')  ->'||l_taxas(i).cd_taxa);
      begin
        select x.attribute6
        into   l_conta_capital_giro
        from (
        select 1 seq
              ,      RECEIVABLES_TRX_ID
              ,      attribute6
              from   AR_RECEIVABLES_TRX_ALL
              where  attribute1 = l_cd_tipo_atividade
              and    attribute2 = p_cd_tipo_contrato
              and    attribute3 = p_cd_destinacao_recurso
              and    attribute4 = l_taxas(i).cd_taxa
              and    type       = 'MISCCASH'
              union
              select 2 seq
              ,      RECEIVABLES_TRX_ID
              ,      attribute6
              from   AR_RECEIVABLES_TRX_ALL
              where  attribute1 = l_cd_tipo_atividade
              and    attribute2 is null
              and    attribute3 = p_cd_destinacao_recurso
              and    attribute4 = l_taxas(i).cd_taxa
              and    type       = 'MISCCASH'
              union
              select 3 seq
              ,      RECEIVABLES_TRX_ID
              ,      attribute6
              from   AR_RECEIVABLES_TRX_ALL
              where  attribute1 = l_cd_tipo_atividade
              and    attribute2 = p_cd_tipo_contrato
              and    attribute3 is null
              and    attribute4 = l_taxas(i).cd_taxa
              and    type       = 'MISCCASH'
              union
              select 4 seq
              ,      RECEIVABLES_TRX_ID
              ,      attribute6
              from   AR_RECEIVABLES_TRX_ALL
              where  attribute1 = l_cd_tipo_atividade
              and    attribute2 is null
              and    attribute3 is null
              and    attribute4 = l_taxas(i).cd_taxa
              and    type       = 'MISCCASH'
              union
              select 5 seq
              ,      RECEIVABLES_TRX_ID
              ,      attribute6
              from   AR_RECEIVABLES_TRX_ALL
              where  attribute1 is null
              and    attribute2 = p_cd_tipo_contrato
              and    attribute3 = p_cd_destinacao_recurso
              and    attribute4 = l_taxas(i).cd_taxa
              and    type       = 'MISCCASH'
              union
              select 6 seq
              ,      RECEIVABLES_TRX_ID
              ,      attribute6
              from   AR_RECEIVABLES_TRX_ALL
              where  attribute1 is null
              and    attribute2 is null
              and    attribute3 = p_cd_destinacao_recurso
              and    attribute4 = l_taxas(i).cd_taxa
              and    type       = 'MISCCASH'
              union
              select 7 seq
              ,      RECEIVABLES_TRX_ID
              ,      attribute6
              from   AR_RECEIVABLES_TRX_ALL
              where  attribute1 is null
              and    attribute2 = p_cd_tipo_contrato
              and    attribute3 is null
              and    attribute4 = l_taxas(i).cd_taxa
              and    type       = 'MISCCASH'
              union
              select 8 seq
              ,      RECEIVABLES_TRX_ID
              ,      attribute6
              from   AR_RECEIVABLES_TRX_ALL
              where  attribute1 is null
              and    attribute2 is null
              and    attribute3 is null
              and    attribute4 = l_taxas(i).cd_taxa
              and    type       = 'MISCCASH'
              order by 1) x
        where rownum = 1;
      exception
        when no_data_found then
             p_status              := 'ERRO';
             l_cnt_msg             := l_cnt_msg + 1;
             p_mensagem(l_cnt_msg) := 'O código de taxa do legado '||p_taxas(i).cd_taxa||' não associada no EBS para atividade '||p_ds_atividade_rural||', tipo de contrato '||p_cd_tipo_contrato||', destinação '||p_cd_destinacao_recurso||'.';
             print_log(l_cnt_msg);
        when others then
             p_status              := 'ERRO';
             l_cnt_msg             := l_cnt_msg + 1;
             p_mensagem(l_cnt_msg) := 'Erro ao validar o código de taxa do legado '||p_taxas(i).cd_taxa||' para atividade '||p_ds_atividade_rural||', tipo de contrato '||p_cd_tipo_contrato||', destinação '||p_cd_destinacao_recurso||'. ERRO: '||SQLERRM;
             print_log(l_cnt_msg);
      end;
      --
      print_log('  l_conta_capital_giro         = '||l_conta_capital_giro);
      if l_conta_capital_giro is not null then
         l_atividade_giro  := p_taxas(i).cd_taxa;
         l_vl_giro         := p_taxas(i).vl_taxa;
         l_tipo_conta_giro := l_conta_capital_giro;
      elsif i = 1 then
        l_cd_taxa1 := p_taxas(i).cd_taxa;
        l_vl_taxa1 := l_taxas(i).vl_taxa;
      elsif i = 2 then
         l_cd_taxa2 := p_taxas(i).cd_taxa;
         l_vl_taxa2 := l_taxas(i).vl_taxa;
      elsif i = 3 then
         l_cd_taxa3 := p_taxas(i).cd_taxa;
         l_vl_taxa3 := l_taxas(i).vl_taxa;
      elsif i = 4 then
         l_cd_taxa4 := p_taxas(i).cd_taxa;
         l_vl_taxa4 := l_taxas(i).vl_taxa;
      elsif i = 5 then
         l_cd_taxa5 := p_taxas(i).cd_taxa;
         l_vl_taxa5 := l_taxas(i).vl_taxa;
      elsif i = 6 then
         l_cd_taxa6 := p_taxas(i).cd_taxa;
         l_vl_taxa6 := l_taxas(i).vl_taxa;
      elsif i = 7 then
         l_cd_taxa7 := p_taxas(i).cd_taxa;
         l_vl_taxa7 := l_taxas(i).vl_taxa;
      elsif i = 8 then
         l_cd_taxa8 := p_taxas(i).cd_taxa;
         l_vl_taxa8 := l_taxas(i).vl_taxa;
      elsif i = 9 then
         l_cd_taxa9 := p_taxas(i).cd_taxa;
         l_vl_taxa9 := l_taxas(i).vl_taxa;
      elsif i = 10 then
         l_cd_taxa10 := p_taxas(i).cd_taxa;
         l_vl_taxa10 := l_taxas(i).vl_taxa;
      else
         p_status              := 'ERRO';
         l_cnt_msg             := l_cnt_msg + 1;
         p_mensagem(l_cnt_msg) := 'O processo permite uma máximo de 10 taxas, o informado foi '||p_taxas.last||'.';
         print_log(l_cnt_msg);
         exit;
      end if;
      
    end loop;
    --
    l_parcelas := null;
    l_cnt := nvl(p_parcelas.last,0);
    
    nr_parcelas := 0;
    for i in 1..l_cnt loop
      print_log('  Parcela:'||i);
      nr_parcelas := nr_parcelas + 1;
      l_parcelas := l_parcelas||trim(to_char(p_parcelas(i).vl_parcela*100,'0999999999'))||to_char(p_parcelas(i).dt_parcela,'DDMMRR');
    end loop;
    print_log('  l_parcelas                   = '||l_parcelas);
    --
    if nr_parcelas > 0
    then
       begin
         select rt.term_id,      count(*) 
         into   l_term_id_custeio,      nr_parcelas
         from   ra_terms rt
         ,      ra_terms_lines rtl
         where  rt.attribute4 = 'Y'
         and    rtl.term_id   = rt.term_id
         having count(*) = nr_parcelas
         group by rt.term_id;
       exception
         when no_data_found then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Não foi identificado condição de pagamento para o financiamento com '||nr_parcelas||' parcelas.';
              print_log(p_mensagem(l_cnt_msg));
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao pesquisar condição de pagamento para o financiamento com '||nr_parcelas||' parcelas.';
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
    -- FIM TAXAS E PARCELAS
    print_log('  FIM TAXAS E PARECELAS');
    if p_status != 'ERRO' then
       select xxfr.xxfr_ar_sq_exe_processo.nextval
       into   l_id_execucao_processo
       from   dual;
       --
       begin
         print_log('l_id_versao_processo: '||l_id_versao_processo);
         insert into xxfr.xxfr_ar_exe_processo
                (ID_EXECUCAO_PROCESSO
                ,ID_VERSAO_PROCESSO
                ,ID_STATUS_PROCESSO
                ,DT_INICIO_EXECUCAO
                ,DT_FIM_EXECUCAO
                ,DT_TRANSACAO
                ,ORG_ID
                ,PARAMETER_CONTEXT
                ,PARAMETER1
                ,PARAMETER2
                ,PARAMETER3
                ,PARAMETER4
                ,PARAMETER5
                ,PARAMETER6
                ,PARAMETER7
                ,PARAMETER8
                ,PARAMETER9
                ,PARAMETER10
                ,PARAMETER11
                ,PARAMETER12
                ,PARAMETER13
                ,PARAMETER14
                ,PARAMETER15
                ,PARAMETER16
                ,PARAMETER17
                ,PARAMETER18
                ,PARAMETER19
                ,PARAMETER20
                ,PARAMETER21
                ,PARAMETER22
                ,PARAMETER23
                ,PARAMETER24
                ,PARAMETER25
                ,PARAMETER26
                ,PARAMETER27
                ,PARAMETER28
                ,PARAMETER29
                ,PARAMETER30
                ,PARAMETER31
                ,PARAMETER32
                ,PARAMETER33
                ,PARAMETER34
                ,PARAMETER35
                ,PARAMETER36
                ,PARAMETER37
                ,PARAMETER38
                ,PARAMETER39
                ,PARAMETER40
                ,PARAMETER41
                ,PARAMETER42
                ,PARAMETER43
                ,PARAMETER44
                ,PARAMETER45
                ,PARAMETER46
                ,PARAMETER47
                ,PARAMETER48
                ,PARAMETER49
                ,PARAMETER50
                ,CREATED_BY
                ,CREATION_DATE
                ,LAST_UPDATED_BY
                ,LAST_UPDATE_DATE)
         select l_id_execucao_processo
         ,      l_id_versao_processo
         ,      1                         --ID_STATUS_PROCESSO
         ,      NULL                      --DT_INICIO_EXECUCAO
         ,      NULL                      --DT_FIM_EXECUCAO
         ,      p_dt_liberacao            --DT_TRANSACAO
         ,      p_org_id
         ,      acvp.PARAMETER_CONTEXT
         ,      nvl(trim(to_char(l_cust_account_id)),acvp.PARAMETER1)
         ,      nvl(p_cd_contrato,acvp.PARAMETER2)
         ,      nvl(l_cd_tipo_atividade,acvp.PARAMETER3)
         ,      nvl(l_cd_cultura,acvp.PARAMETER4)
         ,      nvl(l_cd_safra,acvp.PARAMETER5)
         ,      nvl(l_cd_proposito,acvp.PARAMETER6)
         ,      nvl(fnd_number.number_to_canonical(l_conta_cooperado),acvp.PARAMETER7)
         ,      nvl(fnd_number.number_to_canonical(l_conta_recurso),acvp.PARAMETER8)
         ,      nvl(fnd_number.number_to_canonical(p_valor_liberado),acvp.PARAMETER9)
         ,      nvl(fnd_number.number_to_canonical(p_vl_retencao_custeio),acvp.PARAMETER10)
         ,      nvl(fnd_number.number_to_canonical(trim(to_char(l_term_id_custeio))),acvp.PARAMETER11)
         ,      nvl(l_cd_uso_financiamento,acvp.PARAMETER12)
         ,      nvl(fnd_number.number_to_canonical(p_vl_uso_financiamento),acvp.PARAMETER13)
         ,      nvl(fnd_number.number_to_canonical(p_vl_financiamento_mao_obra),acvp.PARAMETER14)
         ,      nvl(l_grupo_pagamento,acvp.PARAMETER15)
         ,      nvl(l_payment_method_code,acvp.PARAMETER16)
         ,      nvl(l_prioridade_pagamento,acvp.PARAMETER17)
         ,      nvl(trim(to_char(l_term_id)),acvp.PARAMETER18)
         ,      nvl(trim(to_char(p_cd_tipo_contrato)),acvp.PARAMETER19)
         ,      nvl(trim(to_char(p_cd_destinacao_recurso)),acvp.PARAMETER20)
         ,      nvl(trim(to_char(l_atividade_giro)),acvp.PARAMETER21)
         ,      nvl(trim(to_char(l_vl_giro)),acvp.PARAMETER22)
         ,      nvl(trim(to_char(l_cd_taxa1)),acvp.PARAMETER23)
         ,      nvl(trim(to_char(l_vl_taxa1)),acvp.PARAMETER24)
         ,      nvl(trim(to_char(l_cd_taxa2)),acvp.PARAMETER25)
         ,      nvl(trim(to_char(l_vl_taxa2)),acvp.PARAMETER26)
         ,      nvl(trim(to_char(l_cd_taxa3)),acvp.PARAMETER27)
         ,      nvl(trim(to_char(l_vl_taxa3)),acvp.PARAMETER28)
         ,      nvl(trim(to_char(l_cd_taxa4)),acvp.PARAMETER29)
         ,      nvl(trim(to_char(l_vl_taxa4)),acvp.PARAMETER30)
         ,      nvl(trim(to_char(l_cd_taxa5)),acvp.PARAMETER31)
         ,      nvl(trim(to_char(l_vl_taxa5)),acvp.PARAMETER32)
         ,      nvl(trim(to_char(l_cd_taxa6)),acvp.PARAMETER33)
         ,      nvl(trim(to_char(l_vl_taxa6)),acvp.PARAMETER34)
         ,      nvl(trim(to_char(l_cd_taxa7)),acvp.PARAMETER35)
         ,      nvl(trim(to_char(l_vl_taxa7)),acvp.PARAMETER36)
         ,      nvl(trim(to_char(l_cd_taxa8)),acvp.PARAMETER37)
         ,      nvl(trim(to_char(l_vl_taxa8)),acvp.PARAMETER38)
         ,      nvl(trim(to_char(l_cd_taxa9)),acvp.PARAMETER39)
         ,      nvl(trim(to_char(l_vl_taxa9)),acvp.PARAMETER40)
         ,      nvl(trim(to_char(l_cd_taxa10)),acvp.PARAMETER41)
         ,      nvl(trim(to_char(l_vl_taxa10)),acvp.PARAMETER42)
         ,      nvl(trim(to_char(p_vl_longo_prazo)),acvp.PARAMETER43)
         ,      nvl(trim(to_char(p_vl_juros)),acvp.PARAMETER44)
         ,      acvp.PARAMETER45
         ,      acvp.PARAMETER46
         ,      acvp.PARAMETER47
         ,      acvp.PARAMETER48
         ,      acvp.PARAMETER49
         ,      l_parcelas --acvp.PARAMETER50
         ,      fnd_profile.value('USER_ID') --CREATED_BY
         ,      sysdate                      --CREATION_DATE
         ,      fnd_profile.value('USER_ID') --LAST_UPDATED_BY
         ,      sysdate                      --LAST_UPDATE_DATE
         from   xxfr.xxfr_ar_cfg_versao_processo acvp
         where  id_versao_processo = l_id_versao_processo;
         --
         if p_metodo_execucao = 'ON-LINE'
         then
            l_error_code := 0;
            --
            print_log('ON-LINE: '||l_id_execucao_processo);
            xxfr_ar_pck_executa_processo.executa_processo(error_code             => l_error_code
                                                         ,error_buf              => l_error_buf
                                                         ,p_id_execucao_processo => l_id_execucao_processo);
            --
            if l_error_code > 0
            then
               p_status              := 'ERRO';
               l_cnt_msg             := l_cnt_msg + 1;
               p_mensagem(l_cnt_msg) := 'Erro ao executar o processo '||p_cd_processo||' '||l_error_buf;
            else
               p_status   := 'SUCESSO';
            end if;
         else
            xxfr_ar_pck_executa_processo.executa_concorrente(error_code             => l_error_code
                                                            ,error_buf              => l_error_buf
                                                            ,p_id_execucao_processo => l_id_execucao_processo);
            if l_error_code > 0
            then
               p_status              := 'ERRO';
               l_cnt_msg             := l_cnt_msg + 1;
               p_mensagem(l_cnt_msg) := 'Erro ao submeter o processo '||p_cd_processo||' '||l_error_buf;
            else
               p_status   := 'SUCESSO';
            end if;
         end if;
         p_id_execucao_processo := l_id_execucao_processo;
       exception
         when others then
              p_status              := 'ERRO';
              l_cnt_msg             := l_cnt_msg + 1;
              p_mensagem(l_cnt_msg) := 'Erro ao inserir o controle de execução do processo . ERRO: '||SQLERRM;
              print_log(p_mensagem(l_cnt_msg));
       end;
    end if;
  end integra_financiamento;
end;