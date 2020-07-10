drop table XXFR_TABC_TMP;
create table XXFR_TABC_TMP (
  invoice_id    number,
  comments      varchar2(200)
);
set SERVEROUTPUT ON;
declare
  cursor c1 is
    select 
      invoice_id, 
      dbms_lob.substr( comments, 200, 1 ) as "COMMENT" 
    from 
      cll_f189_invoices
    where 1=1
      and dbms_lob.substr( comments, 4, 1 ) in ('NF (','[NFE')
  ;
  l_comment      varchar2(200);
begin
  -- [NFE Num: 22 - Customer_trx_id:20010] [PO Num: 506]
  -- NF (Entrada) Customer_trx_id:77220 [PO Num: 643]
  -- TRX_NUMBER:33;CUSTOMER_TRX_ID:23018;PO_NUMBER:508
  for r1 in c1 loop
    l_comment := r1.comment;
    --dbms_output.put_line(l_comment);
    l_comment := replace (l_comment, 'NF (Entrada) ','');
    l_comment := replace (l_comment, 'NFE Num'        ,'TRX_NUMBER');
    l_comment := replace (l_comment, 'Customer_trx_id','CUSTOMER_TRX_ID');
    l_comment := replace (l_comment, 'PO Num'         ,'PO_NUMBER');
    l_comment := replace (l_comment, ': '             ,':');
    l_comment := replace (l_comment, ' - '            ,';');
    l_comment := replace (l_comment, ']'              ,'');
    l_comment := replace (l_comment, '['              ,'');
    l_comment := replace (l_comment, ' '              ,';');
    l_comment := '[XXFR_INT_AR_RI];' || l_comment;
    --dbms_output.put_line(l_comment);
    --dbms_output.put_line('');
    insert into XXFR_TABC_TMP values (r1.invoice_id, l_comment);
  end loop;
  commit;
end;
/

declare
  cursor c1 is
    SELECT
      invoice_id,
      REGEXP_SUBSTR(t.comments, '[^;]+', 1, 1) col_1,
      REGEXP_SUBSTR(t.comments, '[^;]+', 1, 2) col_2,
      REGEXP_SUBSTR(t.comments, '[^;]+', 1, 3) col_3,
      REGEXP_SUBSTR(t.comments, '[^;]+', 1, 4) col_4,
      REGEXP_SUBSTR(t.comments, '[^;]+', 1, 5) col_5
    FROM XXFR_TABC_TMP t
    order by 1
  ;
  
  l_txt_trx_id   varchar2(30);
  l_txt_trx_nm   varchar2(30);
  l_txt_po_num   varchar2(30);
  
  l_comment      varchar2(200);

begin
  for r1 in c1 loop
    if (substr(r1.col_2,1,3) = 'TRX') then
      if (r1.col_4 is null) then
        l_comment := r1.col_1 || r1.col_3 ||';'|| r1.col_2;
      else
        l_comment := r1.col_1 || r1.col_3 ||';'|| r1.col_2 ||';'|| r1.col_4;
      end if;
    end if;
    dbms_output.put_line(r1.invoice_id ||' - '|| l_comment);
  end loop;
end;
/