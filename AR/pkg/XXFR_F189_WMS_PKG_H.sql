create or replace package xxfr_f189_wms_pkg authid current_user as


  procedure insert_rcv_tables (  errbuf             out nocopy varchar2
                               , retcode            out nocopy number
                               , p_organization_id   in number
                               , p_operation_id      in number  );

  procedure approve_receipt (  errbuf             out nocopy varchar2
                             , retcode            out nocopy number
                             , p_organization_id   in number
                             , p_operation_id      in number  );

end xxfr_f189_wms_pkg;


-- final archive indicate, do not remove
