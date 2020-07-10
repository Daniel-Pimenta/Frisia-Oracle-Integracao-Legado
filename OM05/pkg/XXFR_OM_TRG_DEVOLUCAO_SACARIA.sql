--drop trigger XXFR_OM_TRG_DEVOLUCAO_SACARIA;
create or replace trigger XXFR_OM_TRG_DEVOLUCAO_SACARIA
after update on WSH_TRIPS 
for each row
declare 

  g_escopo              varchar2(50) := 'XXFR_OM_TRG_DEVOLUCAO_SACARIA';
  
  l_attribute8          varchar2(50);
  l_attribute9          varchar2(50);
  l_attribute10         varchar2(50);
  l_attribute11         varchar2(50);
  
  l_old_qtd number;
  l_new_qtd number;
  
  procedure print_log(msg in varchar2) is
  begin
    dbms_output.put_line(msg);
  end;
  
begin
  
  --print_log('============================================================================');
  --print_log('INICIO DO PROCESSO (TRIGGER) - DEVOLUCAO SACARIA '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
  --print_log('============================================================================'); 
  print_log('-- ANTES ------------- DEPOIS --');
  print_log('['||:old.ATTRIBUTE8  || ']->' || :new.ATTRIBUTE8);
  print_log('['||:old.ATTRIBUTE9  || ']->' || :new.ATTRIBUTE9);
  print_log('['||:old.ATTRIBUTE10 || ']->' || :new.ATTRIBUTE10);
  print_log('['||:old.ATTRIBUTE11 || ']->' || :new.ATTRIBUTE11);
  
  l_old_qtd:=0;
  if (:old.ATTRIBUTE8  is not null) then l_old_qtd:=l_old_qtd+1; end if;
  if (:old.ATTRIBUTE9  is not null) then l_old_qtd:=l_old_qtd+1; end if;
  if (:old.ATTRIBUTE10 is not null) then l_old_qtd:=l_old_qtd+1; end if;
  if (:old.ATTRIBUTE11 is not null) then l_old_qtd:=l_old_qtd+1; end if;

  l_new_qtd:=0;
  if (:new.ATTRIBUTE8  is not null) then l_new_qtd:=l_new_qtd+1; end if;
  if (:new.ATTRIBUTE9  is not null) then l_new_qtd:=l_new_qtd+1; end if;
  if (:new.ATTRIBUTE10 is not null) then l_new_qtd:=l_new_qtd+1; end if;
  if (:new.ATTRIBUTE11 is not null) then l_new_qtd:=l_new_qtd+1; end if;  

  if (l_old_qtd < 4) then
    if (l_new_qtd = 4) then
      XXFR_OM_PKG_DEVOLUCAO_SACARIA.main(
        :new.trip_id,
        :new.ATTRIBUTE8,
        :new.ATTRIBUTE9,
        :new.ATTRIBUTE10,
        :new.ATTRIBUTE11
      );
    end if;
  end if;
  --print_log('============================================================================');
  --print_log('FIM DO PROCESSO (TRIGGER) - DEVOLUCAO SACARIA '|| to_char(sysdate,'DD/MM/YYYY - HH24:MI:SS') );
  --print_log('============================================================================');
end XXFR_OM_TRG_DEVOLUCAO_SACARIA;
/

