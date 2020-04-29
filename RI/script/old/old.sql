      -- 
      print_log('Processando :'||r1.batch_source_id);
      print_log('Montando Request Set XXFR_AR_IMPORTA_INTEFACE_TRANS...');
      ok := fnd_submit.set_request_set('XXFR','XXFR_AR_IMPORTA_INTEFACE_TRANS');
      if (ok) then
        print_log('Chamando XXFR_AR_PRE_PROCESSO...');
        ok := fnd_submit.submit_program ('XXFR','XXFR_AR_PCK_PRE_PROCESSO_NF', 'XXFR_AR_PRE_PROCESSO', CHR(0));
        if (ok) then
          begin
          print_log('Chamando XXFR_PROGRAMA_MESTRE...');
          ok := fnd_submit.submit_program(
            application => 'AR',
            program     => 'RAXMTR', 
            stage       => 'XXFR_PROGRAMA_MESTRE',
            argument1   => '1',
            argument2   => g_org_id,
            argument3   => r1.batch_source_id,
            argument4   => r1.name,
            argument5   => to_char(sysdate,'DD/MM/YYYY HH:MI:SS'),
            argument6   => '',
            argument7   => '',
            argument8   => '',
            argument9   => '',
            argument10  => '',
            argument11  => '',
            argument12  => '',-- trunc(sysdate),
            argument13  => '',-- trunc(sysdate)+0.9999,
            argument14  => '',
            argument15  => '',
            argument16  => '',
            argument17  => '',
            argument18  => '', --:B_VENDA.NR_ORDEM_VENDA ,
            argument19  => '', --:B_VENDA.NR_ORDEM_VENDA,
            argument20  => '',--trunc(sysdate),
            argument21  => '',--trunc(sysdate)+0.9999,
            argument22  => '',
            argument23  => '',
            argument24  => '',
            argument25  => '',
            argument26  => 'Y',
            argument27  => ''
          );
          end;
          if (ok) then
            print_log('Chamando XXFR_AR_POS_PROCESSO...');
            ok := fnd_submit.submit_program('XXFR', 'XXFR_AR_PCK_POS_PROCESSO_NF', 'XXFR_AR_POS_PROCESSO', CHR(0));
            if (ok) then
              print_log('Submetendo Request Set...');
              l_request_id := fnd_submit.submit_set(null, FALSE);                    
              commit;
              print_log('Request Id:'||l_request_id);
              if l_request_id != 0 then
                ok := fnd_concurrent.wait_for_request(
                  l_request_id
                  ,1
                  ,0
                  ,vs_phase1
                  ,vs_status1
                  ,vs_dev_phase1
                  ,vs_dev_status1
                  ,vs_message1
                );
                commit;
                print_log('Finalizado importação de NF');   
              else
                print_log('Falha na importação de NF');   
              end if;
              print_log('vs_phase1     :'||vs_phase1);
              print_log('vs_status1    :'||vs_status1);
              print_log('vs_dev_phase1 :'||vs_dev_phase1);
              print_log('vs_dev_status1:'||vs_dev_status1);
              print_log('vs_message1   :'||vs_message1);
            end if;
          end if;
        end if;
      end if;
