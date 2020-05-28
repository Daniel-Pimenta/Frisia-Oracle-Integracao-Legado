create or replace PACKAGE xxfr_f189_open_interface_pkg AS

  procedure print_log(msg in varchar2);

  PROCEDURE open_interface (errbuf                 OUT NOCOPY VARCHAR2
                           ,retcode                OUT NOCOPY NUMBER
                           ,p_source               IN  VARCHAR2
                           ,p_approve              IN  VARCHAR2
                           ,p_delete_line          IN  VARCHAR2
                           ,p_generate_line_compl  IN  VARCHAR2  DEFAULT 'N'
                           ,p_operating_unit       IN  NUMBER
                           ,p_interface_invoice_id IN  NUMBER DEFAULT NULL
                           );
END xxfr_f189_open_interface_pkg;
