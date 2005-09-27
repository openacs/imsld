--
-- IMS-LD Status Data Model.
-- Theese tables are used to determine the status of the learner, staff or any other "IMS-LD object"
-- inside the unit of learning.
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date sept-2005
--

create table imsld_status_learner (
    role_part_id            integer
                            constraint imsld_stat_rp_fk  
                            references imsld_role_parts
                            not null, 
    user_id                 integer
                            constraint imsld_stat_user_fk  
                            references users
                            not null
);

create index imsld_stat_rp_idx on imsld_status_learner(role_part_id);
create index imsld_stat_user_idx on imsld_status_learner(user_id);

comment on table imsld_status_learner is '
This table holds the status of each learner in the unit of learning.
Each entry in this table says that the learner referenced by user_id has already COMPLETED the role part referenced by role_part_id, so if we want to know what role part is the next one for any learner, we just have to see the las completed role part which is the one stored in this table.';



