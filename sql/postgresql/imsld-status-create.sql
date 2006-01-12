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
    role_part_id            integer
                            constraint imsld_stat_rp_fk  
                            references imsld_role_parts
                            not null,
    completed_id            integer
                            constraint imsld_stat_aid_fk
                            references cr_revisions     -- reference to an learning_activity OR support_activity OR a
                            not null,                   -- ctivity_structure OR environment
    user_id                 integer
                            constraint imsld_stat_user_fk  
                            references users
                            not null,
    type                    varchar(20)
                            check (type in ('learning','support','structure','resource')),
    finished_date           timestamptz
                            default current_timestamp
                            not null
);

create index imsld_stat_imsld_idx on imsld_status_user(imsld_id);
create index imsld_stat_rp_idx on imsld_status_user(role_part_id);
create index imsld_stat_comp_idx on imsld_status_user(completed_id);
create index imsld_stat_user_idx on imsld_status_user(user_id);

comment on table imsld_status_user is '
This table holds the status of each user in the unit of learning.
Each entry in this table says that the user referenced by user_id has already COMPLETED the role part referenced by role_part_id, so if we want to know what role part is the next one for any user, we have to see the las completed role part and find out which one is next.';

