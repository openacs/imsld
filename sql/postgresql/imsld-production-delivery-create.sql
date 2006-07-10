--
-- IMS-LD Status Data Model.
-- Theese tables are used to determine the status of the learner, staff or any other "IMS-LD object"
-- inside the unit of learning.
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date sept-2005
--

create table imsld_runs (
    run_id          integer
                    constraint imsld_run_fk
                    references acs_objects
                    on delete cascade
                    constraint imsld_run_pk
                    primary key,
    imsld_id        integer
                    constraint imsld_run_imsld_id_fk
                    references imsld_imslds
                    not null,
    status          varchar(15),
    creation_date   timestamptz
                    not null,
    status_date     timestamptz
                    default current_timestamp
                    not null
);

create index imsld_run_imsld_idx on imsld_runs(imsld_id);

comment on table imsld_runs is '
This table holds the runs of a UoL as suggested in the specification. In this case a run is just an identifier mapped to the UoL, and the users, roles, properties and status will be mapped to the run_id, allowing multiple instances of the same UoL.';

create table imsld_status_user (
    imsld_id        integer
                    constraint imsld_stat_imsldid_fk
                    references imsld_imslds
                    not null,
    run_id          integer
                    constraint imsld_stat_rn_fk  
                    references imsld_runs,
    play_id         integer
                    constraint imsld_stat_pl_fk  
                    references imsld_plays,
    act_id          integer
                    constraint imsld_stat_act_fk  
                    references imsld_acts,
    role_part_id    integer
                    constraint imsld_stat_rp_fk  
                    references imsld_role_parts,
    related_id      integer
                    constraint imsld_stat_aid_fk
                    references cr_revisions     -- reference to a learning_activity OR support_activity OR
                    not null,                   -- activity_structure OR environment OR role_part OR act OR play
    user_id         integer
                    constraint imsld_stat_user_fk  
                    references users
                    not null,
    role_id         integer
                    constraint imsld_stat_role_fk  
                    references cr_revisions,    -- imsld_roles (not implemented, add not null then)
    type            varchar(20)
                    check (type in ('learning','support','structure','act','role-part','play','method','resource')),
    status_date     timestamptz
                    default current_timestamp
                    not null,
    status          varchar(20)
                    check (status in ('started','finished')),
    constraint imsld_status_un
    unique (run_id,related_id,user_id,status)
);

create index imsld_stat_imsld_idx on imsld_status_user(imsld_id);
create index imsld_stat_run_idx on imsld_status_user(run_id);
create index imsld_stat_rp_idx on imsld_status_user(role_part_id);
create index imsld_stat_comp_idx on imsld_status_user(related_id);
create index imsld_stat_user_idx on imsld_status_user(user_id);

comment on table imsld_status_user is '
This table holds the status of each user in the run of the unit of learning.
Each entry in this table says that the user referenced by user_id(role_id) has already started or completed the event referenced by _id. Extra information like the imsld_id, play_id, etc. is stored as cache purposes.';

create table imsld_property_instances (
    instance_id     integer
                    constraint imsld_pin_pk
                    primary key,
    property_id     integer
                    constraint imsld_pin_pro_fk
                    references imsld_properties -- since this table will only be used during run time, and because
                    not null,                   -- of performance issues, the reference is directly to the imsld_properties table.
    identifier      varchar(100)                -- the same identifier that the corresponding propert (cache)
                    not null,                   
    party_id        integer
                    references parties,         -- for the property of type loc, locpers, locrole or globpers
    run_id          integer
                    constraint imsld_pin_rn_fk  
                    references imsld_runs,
    value           varchar(4000)
);

create index imsld_prop_pin_pro_idx on imsld_property_instances(property_id);
create index imsld_prop_pin_party_idx on imsld_property_instances(party_id);
create index imsld_prop_pin_run_idx on imsld_property_instances(run_id);

comment on table imsld_property_instances is '
This table holds the property instance values of the unit of learning.
The property may refer to a role (role instance, which is a group) or a single user, using the party_id field.';

create table imsld_attribute_instances (
    instance_id     integer
                    constraint imsld_attri_pk
                    primary key,
    owner_id        integer
                    constraint imsld_atri_own_fk
                    references cr_revisions,            -- learning or support acctivity, item, play, learning object or service
    type            varchar(10)                         -- isvissible or class
                    check (type in ('isvisible','class')),
    identifier      varchar(100),                       -- class name or owner identifier
    run_id          integer
                    constraint imsld_pin_rn_fk  
                    references imsld_runs,
    is_visible_p    char(1)
                    check (is_visible_p in ('t','f')),  
    title           varchar(100),                       -- title for the class
    with_control_p  char(1) 
                    check (with_control_p in ('t','f')) -- class attribute according to the spec
);

create index imsld_attri_own_idx on imsld_attribute_instances(owner_id);
create index imsld_attri_run_idx on imsld_attribute_instances(run_id);

comment on table imsld_attribute_instances is '
This table holds the attribute instances for those attributes like isvisible or class (by the 
moment only used to indicate if the activity, play or whatever is visible or not)
which scope is the current run. So every time a run is created, those attributes can be
initializated according to the initial parsed values from the manifest, not being affected
by a previous run.';

