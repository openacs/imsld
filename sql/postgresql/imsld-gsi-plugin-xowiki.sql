--
-- Tables required by GSI plugins
--
-- @author lfuente@it.uc3m.es
-- @creation-date dic-2008
--

create table imsld_gsi_p_xow_usersmap (
    user_id              integer
                         not null,
    run_id               integer
                         not null,
    external_user        varchar(100),
    external_credentials varchar(500)
);

