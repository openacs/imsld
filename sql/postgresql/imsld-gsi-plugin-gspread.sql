--
-- Tables required by GSI plugins
--
-- @author lfuente@it.uc3m.es
-- @creation-date dic-2008
--

create table imsld_gsi_p_gspread_usersmap (
    user_id              integer
                         not null,
    run_id               integer
                         not null,
    external_user        varchar(100),
    external_credentials varchar(500),
    spreadsheet_url varchar(500),
    formkey varchar(500),
    form_url varchar(500)
);

insert into imsld_gsi_plugins values ('gspread','www.it.uc3m.es/lfuente/gsi/plugins/googleSpreadsheet');
