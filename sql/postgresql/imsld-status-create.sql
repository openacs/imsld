--
-- IMS-LD Status Data Model.
-- Theese tables are used to determine the status of the learner, staff or any other "IMS-LD object"
-- inside the unit of learning.
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date sept-2005
--

create table imsld_status_user (
    imsld_id                integer
                            constraint imsld_stat_imsldid_fk
                            references imsld_imslds
                            not null,
    play_id                 integer
                            constraint imsld_stat_pl_fk  
                            references imsld_plays,
    act_id                  integer
                            constraint imsld_stat_act_fk  
                            references imsld_acts,
    role_part_id            integer
                            constraint imsld_stat_rp_fk  
                            references imsld_role_parts,
    related_id              integer
                            constraint imsld_stat_aid_fk
                            references cr_revisions     -- reference to a learning_activity OR support_activity OR
                            not null,                   -- activity_structure OR environment OR role_part OR act OR play
    user_id                 integer
                            constraint imsld_stat_user_fk  
                            references users
                            not null,
    role_id                 integer
                            constraint imsld_stat_role_fk  
                            references cr_revisions,    -- imsld_roles (not implemented, add not null then)
    type                    varchar(20)
                            check (type in ('learning','support','structure','act','role-part','play','method','resource')),
    status_date             timestamptz
                            default current_timestamp
                            not null,
    status                  varchar(20)
                            check (status in ('started','finished')),
    constraint imsld_status_un
    unique (related_id,user_id,status)
);

create index imsld_stat_imsld_idx on imsld_status_user(imsld_id);
create index imsld_stat_rp_idx on imsld_status_user(role_part_id);
create index imsld_stat_comp_idx on imsld_status_user(related_id);
create index imsld_stat_user_idx on imsld_status_user(user_id);

comment on table imsld_status_user is '
This table holds the status of each user in the run of the unit of learning.
Each entry in this table says that the user referenced by user_id(role_id) has already started or completed the event referenced by _id. Extra information like the imsld_id, play_id, etc. is stored in order to avoid wasting of time.';

