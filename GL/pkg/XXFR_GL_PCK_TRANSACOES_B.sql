create or replace package body xxfr_gl_pck_transacoes as
  
  g_escopo  varchar2(50) := 'XXFR_GL_PCK_TRANSACOES';
  ok boolean;
  
  procedure print_out(msg   in varchar2) is
  begin
    dbms_output.put_line(msg);
    xxfr_pck_logger.log_info(	
      p_log      => msg,
			p_escopo   => g_escopo
    );
  end;

  procedure initialize is
  begin
    xxfr_pck_variaveis_ambiente.inicializar('SQLGL','UO_FRISIA');  
  end;

  /*
  procedure initialize(p_modulo in varchar2) is
    l_org_id              number := fnd_profile.value('ORG_ID');
    l_user_id             number;
    l_resp_id             number;
    l_resp_app_id         number;
  begin
    select distinct fr.responsibility_id, frx.application_id
    into l_resp_id, l_resp_app_id
    from 
      apps.fnd_responsibility frx,
      apps.fnd_responsibility_tl fr
    where 1=1
      and fr.responsibility_id = frx.responsibility_id
      and fr.responsibility_name = 'FRISIA_OM_SUPERUSUARIO'
    ;
    select user_id into l_user_id from fnd_user 
    where user_name = 'DANIEL.PIMENTA'
    ;
    fnd_global.apps_initialize (
      l_user_id
      ,l_resp_id
      ,l_resp_app_id 
      ,l_org_id
    );
    --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE= ''AMERICAN''';
    --print_out('  ORG_ID:'||l_org_id);
    mo_global.set_policy_context('S', l_org_id);
    mo_global.init(p_modulo);
  end;
  */
  
  procedure gravar_interface(
    p_gl_interface     in apps.gl_interface%rowtype,
    x_retorno          out varchar2
  ) is
   
   l_gl_interface     apps.gl_interface%rowtype;
   
  begin
    print_out('  XXFR_GL_PCK_TRANSACOES.GRAVAR_INTERFACE');
    if (FND_GLOBAL.USER_ID is null) then 
      initialize;
    end if;
    l_gl_interface             := p_gl_interface;
    l_gl_interface.created_by  := FND_GLOBAL.USER_ID;
    
    insert into gl_interface values l_gl_interface;
     x_retorno := 'S';
  exception
    when others then
      x_retorno := '  ERRO:'||sqlerrm; 
  end;

  procedure processa_interface(
    p_livro       in varchar2,
    p_numero_lote in number, 
    p_origem      in varchar2,
    x_request_id  out number,
    x_retorno     out varchar2
  )is

    l_phase              varchar2(100);
    l_status             varchar2(100);
    l_dev_phase          varchar2(100);
    l_dev_status         varchar2(100);
    l_message            varchar2(400);
    l_result             boolean;
    l_dummy				       number:=0; 

    l_error				       number:=0; 
    l_success				     number:=0; 
    l_pending				     number:=0; 
    
    l_conc_id             number;
    l_int_run_id          number;
    l_access_set_id       number;
    l_set_of_books_id     number;
    --
    l_request_id          number;
    l_group_id            number;
    
    l_user_id             number := fnd_global.user_id;
    l_resp_id             number := fnd_global.resp_id;
    l_resp_app_id         number := fnd_global.resp_appl_id;
    
    g_step     varchar2(200);
    g_err_msg  varchar2(200);
    
  begin   
    print_out('  XXFR_GL_PCK_TRANSACOES.PROCESSA_INTERFACE');
    print_out('  Livro :'||p_livro);
    print_out('  Origem:'||p_origem);
    print_out('  Lote  :'||p_numero_lote);
    initialize;
    ok := true;
    begin
      select access_set_id into l_access_set_id from gl_access_sets where name = p_livro;
      select ledger_id into l_set_of_books_id from gl_ledgers  where name = p_livro;
      select gl_journal_import_s.nextval into l_int_run_id from dual;
      
      l_group_id := p_numero_lote;
      
      print_out('  Chamando GL_JOURNAL_IMPORT_PKG.POPULATE_INTERFACE_CONTROL...');
      begin
        print_out('    GROUP_ID      :'||l_group_id);
        print_out('    SET_OF_BOOK_ID:'||l_set_of_books_id);
        print_out('    INT_RUN_ID    :'||l_int_run_id);
        apps.gl_journal_import_pkg.populate_interface_control(
        --populate_interface_control(
          user_je_source_name => p_origem,
          group_id            => l_group_id,
          set_of_books_id     => l_set_of_books_id,
          interface_run_id    => l_int_run_id
        );
      exception      
        when others then
          print_out('    ERRO:'||sqlerrm);
          ok := false;
          x_retorno := 'E';
          return;
      end;
      if (ok) then
        --INICIANDO CONCURRENT
        begin            
          print_out('  INICIANDO COCURRENTE GLLEZL - INTER_RUN_ID:'||l_int_run_id);
          l_request_id := fnd_request.submit_request(
            application    => 'SQLGL'
            ,program       => 'GLLEZL'
            ,description   => null
            ,start_time    => sysdate
            ,sub_request   => false
            ,argument1     => l_int_run_id    --interface run id
            ,argument2     => l_access_set_id --data access set_id
            ,argument3     => 'N'             --post to suspense
            ,argument4     => ''              --from date
            ,argument5     => ''              --to date
            ,argument6     => 'N'             --summary mode
            ,argument7     => 'N'             --import DFF
            ,argument8     => 'Y'             --backward mode
          );
          commit;
        exception
          when others then
            x_retorno := 'ERRO NA EXECUÇÃO DO CONCORRENT:'||sqlerrm;
            print_out(x_retorno);
            ok := false;
        end;
      end if;
      --ESPERANDO CONCURRENT TERMINAR
      if (ok) then
        if (l_request_id = 0 or l_request_id is null) then
          x_retorno := fnd_message.get;
          print_out('  ERRO:'||fnd_message.get);
          ok := false;
        else
          x_request_id := l_request_id;
          print_out('  AGUARDANDO FINALIZAÇÃO - REQUEST ID:'||l_request_id);
          loop
            l_result := fnd_concurrent.get_request_status( 
              l_request_id
              ,'' --appl_shortname
              ,'' --program
              ,l_phase
              ,l_status
              ,l_dev_phase
              ,l_dev_status
              ,l_message
            );
            if (l_dev_phase = 'COMPLETE') then
              exit;
            end if;
          end loop;
          if (l_dev_status = 'NORMAL') then
            x_retorno := 'S';
            print_out('  Saida:'||l_dev_status);          
          elsif (l_dev_status = 'WARNING') then
            x_retorno := l_message;
            print_out('  Saida:'||l_dev_status||' - '||l_message);
          else
            x_retorno := l_message;
            print_out('  Saida:'||l_dev_status||' - '||l_message);
            ok := false;
          end if;
        end if;        
      end if;
    exception
      when others then
        x_retorno := sqlerrm;
        print_out('  ERRO GENERICO:'||sqlerrm);
    end;  
  end;

  PROCEDURE populate_interface_control(
    user_je_source_name       VARCHAR2,
    group_id                  IN OUT NOCOPY   NUMBER,
    set_of_books_id           NUMBER,
    interface_run_id          IN OUT NOCOPY  NUMBER,
    table_name                VARCHAR2 DEFAULT NULL,
    processed_data_action     VARCHAR2 DEFAULT NULL
  ) IS
    je_source_name VARCHAR2(25);
  BEGIN

    BEGIN
      SELECT je_source_name
      INTO je_source_name
      FROM gl_je_sources
      WHERE user_je_source_name = populate_interface_control.user_je_source_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        print_out('INVALID_JE_SOURCE');
        ok := false;
        return;
    END;

    IF (group_id IS NULL) THEN
      SELECT gl_interface_control_s.NEXTVAL
      INTO group_id
      FROM DUAL;
    END IF;

    IF (interface_run_id IS NULL) THEN
      SELECT gl_journal_import_s.NEXTVAL
      INTO interface_run_id
      FROM DUAL;
    END IF;

    INSERT INTO gl_interface_control
    (status, je_source_name,
     group_id, set_of_books_id,
     interface_run_id, interface_table_name, processed_table_code)
    VALUES
    ('S', populate_interface_control.je_source_name,
     populate_interface_control.group_id,
     populate_interface_control.set_of_books_id,
     populate_interface_control.interface_run_id,
     table_name, processed_data_action);

  END populate_interface_control;


end xxfr_gl_pck_transacoes;