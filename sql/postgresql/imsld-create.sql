--
-- IMS-LD Package Data Model
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date jul-2005
--

create table imsld_learning_objects (
    learning_object_id      integer  
                            constraint imsld_lo_id_fk  
                            references cr_revisions  
                            on delete cascade
                            constraint imsld_lo_id_pk   
                            primary key, 
    class                   varchar(4000),                  
    environment_id          integer    
                            constraint imsld_lo_envid_fk    
                            references cr_items(item_id), --imsld_environments
    is_visible_p            char(1) 
                            check (is_visible_p in ('t','f')) 
                            default 't', 
    type                    varchar(100),
    schema_version          varchar(100),
    parameters               varchar(4000)
);

create index imsld_learning_o_env_id_idx on imsld_learning_objects(environment_id);

comment on table imsld_learning_objects is '
Learning objects are incorporated (in dotLRN) by referencing resources through the item elements.';

comment on column imsld_learning_objects.class is '
The class attribute refers to the value of class attributes available in learning-design or content elements.';

comment on column imsld_learning_objects.type is '
The type of learning object (e.g. knowledge-object, tool-object test-object). Vocabulary used can be the one of ''learning resource type'' element from the IEEE LTSC LOM.';

comment on column imsld_learning_objects.schema_version is '
Indicate the version of the schema to be used.';

comment on column imsld_learning_objects.is_visible_p is '
Initial visibility attribute';

comment on column imsld_learning_objects.parameters is '
Parameters to be passed during runtime.';

create table imsld_imslds (
    imsld_id                integer
                            constraint imsld_id_fk
                            references cr_revisions
                            on delete cascade
                            constraint imsld_id_pk 
                            primary key,
    identifier              varchar(100)
                            not null,
    version                 varchar(10),
    level                   char(1)
                            constraint imsld_level_ck 
                            check (level in ('a','b','c')),
    sequence_used_p         char(1)
                            constraint imsld_seq_ck
                            check (sequence_used_p in ('t','f'))
                            default 'f'
);

comment on table imsld_imslds is '
IMS-LD main table, where the imsld general information is stored.';

comment on column imsld_imslds.version is '
A version number of the document';

comment on column imsld_imslds.level is '
The level of the document. It can only be A, B or C';

comment on column imsld_imslds.sequence_used_p is '
If the value is true, IMS Simple Sequencing is included at the appropriate places in the document instance, default is false.';

create table imsld_learning_objectives (
    learning_object_id  integer
                        constraint imsld_leo_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_leo_pk
                        primary key,
    imsld_id            integer
                        constraint ismld_leo_imsldid_fk
                        references cr_items     --imsld_imslds
);

comment on table imsld_learning_objectives is '
This table holds the learning objectives of the IMS-LD. 
Technically it is just a mapping table between items and the imsld_id, but this table was created to provide simplicity and clarification in the data model';

create table imsld_prerequisites (
    prerequisite_id     integer
                        constraint imsld_prereq_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_prereq_pk
                        primary key,
    imsld_id            integer
                        constraint ismld_prereq_imsldid_fk
                        references cr_items     --imsld_imslds
);

comment on table imsld_prerequisites is '
This table holds the prerequisites of the IMS-LD. 
Technically it is just a mapping table between items and the imsld_id, but this table was created to provide simplicity and clarification in the data model';

create table imsld_items (
    imsld_item_id   integer
                    constraint imsld_items_id_fk
                    references cr_revisions
                    on delete cascade
                    constraint imsld_items_id_pk
                    primary key,
    identifier      varchar(100),
    identifierref   varchar(100),
    is_visible_p    char(1)
                    check (is_visible_p in ('t','f'))
                    default 't',
    parameters      varchar(4000)
);

comment on table imsld_items is '
This table holds the imsld items of the unit of learning';

comment on column imsld_items.identifier is '
Unique identifier of the item in the unit of learning';

comment on column imsld_items.is_visible_p is '
Initial visibility attribute';

comment on column imsld_items.parameters is '
Parameters to be passed during runtime.';

create table imsld_components (
    component_id        integer
                        constraint imsld_comp_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_comp_pk
                        primary key,
    imsld_id            integer
                        constraint imsld_comp_ldid_fk
                        references cr_items     --imsld_imslds
                        not null
);

create index imsld_comp_imsld_id_idx on imsld_components(imsld_id);

comment on table imsld_components is '
This table holds the components of the learning activity, which conists of activities, roles and environments.
The environments, roles and activities tables references this one since the relationship is one to many.';

create table imsld_roles (
    role_id         integer
                    constraint imsld_roles_id_fk
                    references cr_revisions
                    on delete cascade
                    constraint imsld_roles_id_pk
                    primary key,
    identifier      varchar(100),
    role_type       varchar(100)
                    not null,
    parent_role_id  integer
                    constraint imsld_roles_proleid_fk
                    references cr_items,    --imsld_roles
    create_new_p    char(1)
                    check (create_new_p in ('t','f'))
                    default 't',
    match_persons_p char(1)
                    check (match_persons_p in ('t','f')),
    max_persons     integer,
    min_persons     integer
);

create index imsld_roles_parent_id_idx on imsld_roles(parent_role_id);

comment on table imsld_roles is '
Roles of the unit of learning. Whenever possible, they are treated just like the roles in dotLRN';

comment on column imsld_roles.role_type is '
Role type to know if the role is of type learner or staff';

comment on column imsld_roles.parent_role_id is '
According to the IMS-LD spec, a role can have sub-roles, i.e. a role can have a parent role';

comment on column imsld_roles.create_new_p is '
This attribute indicates whether multiple occurrences of this role may be created during runtime. 
True means allowed and false means not-allowed';

comment on column imsld_roles.match_persons_p is '
This attribute is used when there are several sub roles (e.g. chair, secretary, member). Persons can be matched exclusively to the sub roles, meaning that a person, who has the role of chair, may not be bound to one of the other roles at the same time. When it is not exclusive, persons may be bound to more than one sub role (this is the default situation).
True means exclusively-in-roles and false means not-exlusively.';

create table imsld_learning_activities (
    activity_id             integer
                            constraint imsld_la_id_fk
                            references cr_revisions
                            on delete cascade
                            constraint imsld_la_id_pk
                            primary key,
    identifier              varchar(100),
    component_id            integer
                            constraint imsld_la_component_id_fk
                            references cr_items     --imsld_components
                            not null,
    parameters              varchar(4000),
    is_visible_p            char(1)
                            check (is_visible_p in ('t','f'))
                            default 't',
    user_choice_p           char(1)
                            check (user_choice_p in ('t','f')),
    time_limit_id           integer
                            constraint imdls_la_timelid_fk
                            references cr_items,    --imsld_time_limits
    on_completion_id        integer
                            constraint imdls_la_oncompid_fk
                            references cr_items     --imsld_on_completion
);

create index imsld_la_comp_id_idx on imsld_learning_activities(component_id);
create index imsld_la_timel_id_idx on imsld_learning_activities(time_limit_id);
create index imsld_la_oncomp_id_idx on imsld_learning_activities(on_completion_id);

comment on table imsld_learning_activities is '
This table stores the learning activitis of the component of the unit of learning.';

comment on column imsld_learning_activities.parameters is '
Parameters to be passed during runtime.';

comment on column imsld_learning_activities.user_choice_p is '
This element specifies that the user may decide him or herself when the activity is completed. This means that a control must be available in the user-interface to set the activity status to ''completed''. A user can do this once (no undo). Once he/she indicated the activity to be completed, then this activity stays completed in the run.';

comment on column imsld_learning_activities.time_limit_id is '
The time limit specifies that it is completed when a certain amount of time has passed, relative to the start of the run of the current unit of learning.
In runtime the time limit of the play overrules the time limit on act and that one on the role-parts.
This unit is curretnly treated in seconds in dotLRN.';

comment on column imsld_learning_activities.on_completion_id is '
When an activity, act, play or unit-of-learning is completed, the optional actions contained in this element are executed. In level A it contains only one element. The wrapper is available for the extensions of level B and C.';

create table imsld_support_activities (
    activity_id                 integer
                                constraint imsld_sa_fk
                                references cr_revisions
                                on delete cascade
                                constraint imsld_sa_pk
                                primary key,
    component_id                integer
                                constraint imsld_sa_componenid_fk
                                references cr_items     --imsld_components
                                not null,
    identifier                  varchar(100),
    is_visible_p                char(1)
                                check (is_visible_p in ('t','f'))
                                default 't',
    parameters                  varchar(4000),
    user_choice_p                 char(1) 
                                check (user_choice_p in ('t','f')), 
    time_limit_id               integer 
                                constraint imdls_sa_timelid_fk 
                                references cr_items,    --imsld_time_limits
    on_completion_id            integer 
                                constraint imdls_sa_oncompid_fk 
                                references cr_items     --imsld_on_completion
);

create index imsld_sa_comp_id_idx on imsld_support_activities(component_id);
create index imsld_sa_timel_id_idx on imsld_support_activities(time_limit_id);
create index imsld_sa_oncomp_id_idx on imsld_support_activities(on_completion_id);

comment on table imsld_support_activities is ' 
This table stores the support activitis of the component of the unit of learning.
For comments on specific fields see the table imsld_learning_activities.
The talbes imsld_learning_activities and imsld_support_activities are treated separatedly
because it was too confusing using only one, because there are references to only learning activities
and to only support activities, besides, a support activity can have roles mapped to it.';

create table imsld_activity_structures (
    structure_id                integer
                                constraint imsld_as_fk
                                references cr_revisions
                                on delete cascade
                                constraint imsld_as_pk
                                primary key,
    component_id                integer 
                                constraint imsld_as_component_id_fk 
                                references cr_items     --imsld_components
                                not null,
    identifier                  varchar(100),
    number_to_select            integer,
    structure_type              char(9)
                                check (structure_type in ('selection','sequence'))
);

create index imsld_as_comp_id_idx on imsld_activity_structures(component_id);

comment on table imsld_activity_structures is '
The activity structures of a component determine the sets and order of activities in the unit of learning, as well as the
structure type of such sets';

comment on column imsld_activity_structures.number_to_select is '
When the attribute ''number-to-select'' is set, the activity-structure is completed when the number of activities completed equals the number set. The number-to-select must be the same as or smaller than the number of activities (including unit-of-learnings) which are at the immediate child level. When the number-to-select isn''t set, the activity-structure is completed when all the activities in the structure are completed.
The field ''information'' (specified in the IMS-LD spec) is just a set of items, maped to this table trhough a mapping table.';

comment on column imsld_activity_structures.structure_type is '
Indicates whether the activity-structure represents a sequence or a selection.';

create table imsld_environments (
    environment_id      integer
                        constraint imsld_env_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_env_pk
                        primary key,
    component_id        integer
                        constraint imsld_env_compid_fk
                        references cr_items     --imsld_components
                        not null,
    identifier          varchar(100)
);

create index imsld_envs_comp_id_idx on imsld_environments(component_id);

comment on table imsld_environments is '
The environments are learning objects, services or more environments that complement a given activity.
The learning objects and services are mapped to this table through those tables 
and the nested environments are mapped through a mapping table.';

create table imsld_send_mail_services (
    mail_id         integer 
                    constraint imsld_emailserv_fk 
                    references cr_revisions 
                    on delete cascade
                    constraint imsld_emailserv_pk 
                    primary key, 
    environment_id  integer
                    constraint imsld_emailsevr_env_fk
                    references cr_items     --imsld_environments
                    not null,
    recipients      char(11)
                    check (recipients in ('all-in-role','selection')),
    is_visible_p    char(1) 
                    check (is_visible_p in ('t','f')) 
                    default 't',
    parameters      varchar(4000)
);

create index imsld_send_m_env_id_idx on imsld_send_mail_services(environment_id);

comment on column imsld_send_mail_services.recipients is '
Fixed choice: ''all-in-role'' or ''selection''. With the first choice, the user agent only allows messages to be sent to the role, indicating that all persons in the role get the message. With the second choice, the user agent allows a user to select one or more individuals within the specified role to send the message to';

comment on column imsld_send_mail_services.is_visible_p is '
Initial visibility attribute';

create table imsld_send_mail_data (
    data_id         integer  
                    constraint imsld_semaildata_fk  
                    references cr_revisions  
                    on delete cascade
                    constraint imsld_semaildata_pk  
                    primary key,  
    send_mail_id    integer
                    constraint imsld_semaildata_smailid_fk
                    references cr_items     --imsld_send_mail_services
                    not null,
    role_id         integer
                    constraint imsld_semaildata_roleid_fk
                    references cr_items     --imsld_roles
                    not null,
    mail_data       text
);

create index imsld_sm_data_sm_id_idx on imsld_send_mail_data(send_mail_id);
create index imsld_sm_data_role_id_idx on imsld_send_mail_data(role_id);

create table imsld_conference_services (
    conference_id       integer   
                        constraint imsld_confs_fk   
                        references cr_revisions   
                        on delete cascade
                        constraint imsld_confs_pk   
                        primary key,   
    environment_id      integer 
                        constraint imsld_confs_env_fk 
                        references cr_items     --imsld_environments
                        not null, 
    conference_type     char(12)
                        check (conference_type in ('synchronous','asynchronous','announcement')),
    is_visible_p        char(1)  
                        check (is_visible_p in ('t','f'))  
                        default 't', 
    imsld_item_id       integer
                        constraint imsld_confs_item_itemid_fk
                        references cr_items,    --imsld_items
    manager_id          integer
                        constraint imsld_confs_manager_fk
                        references cr_items,    --imsld_roles
    moderator_id        integer 
                        constraint imsld_confs_moderator_fk 
                        references cr_items,    --imsld_roles
    parameters          varchar(4000)
);

create index imsld_confs_env_id on imsld_conference_services(environment_id);
create index imsld_confs_item_id on imsld_conference_services(imsld_item_id);
create index imsld_confs_manag_id on imsld_conference_services(manager_id);
create index imsld_confs_moder_id on imsld_conference_services(moderator_id);

comment on table imsld_conference_services is '
Conferences in the unit of learning. The conference can be synchronous (chat), asynchronous (forum) or announcement (notice).
The conference has a manager and a moderator associate to it. Besides, there are the participants, 
which are mapped to the conference through a mapping table.';

comment on column imsld_conference_services.imsld_item_id is '
A node in a structure, referring to a resource.';

-- TO DO: INDEX SEARCH SERVICE

create table imsld_methods (
    method_id           integer
                        constraint imsld_methods_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_methods_pk 
                        primary key,
    imsld_id            integer
                        constraint imsld_methods_imsldid_fk
                        references cr_items,    --imsld_imslds
    time_limit_id       integer
                        constraint imsld_methods_timel_fk
                        references cr_items,    --imsld_time_limits
    on_completion_id    integer
                        constraint imsld_methods_oncomp_fk
                        references cr_items     --imsld_on_completion
);

create index imsld_methods_imsld_id_idx on imsld_methods(imsld_id);
create index imsld_methods_timel_id_idx on imsld_methods(time_limit_id);
create index imsld_methods_oncomp_id_idx on imsld_methods(on_completion_id);

comment on table imsld_methods is '
This table holds the methods of the unit of learning.
The methods are the ones that specifies the sequence of activities. 
Theese activities are grouped with their corresponding roles and form a play, which is mapped to the method.
The method is completed when all the ''plays to complete method'' mapped to this table are completed or
when the time indicated by time_limit has been completed.';

create table imsld_plays (
    play_id                     integer
                                constraint imsld_plays_fk
                                references cr_revisions
                                on delete cascade
                                constraint imsld_plays_pk
                                primary key,
    method_id                   integer 
                                constraint imsld_plays_methodid_fk 
                                references cr_items,    --imsld_methods
    is_visible_p                char(1)   
                                check (is_visible_p in ('t','f'))   
                                default 't',  
    identifier                  varchar(100),
    when_last_act_completed_id  integer
                                constraint imsld_plays_lastact_fk
                                references cr_items,    --imsld_acts
    time_limit_id               integer
                                constraint imsld_plays_timelid_fk
                                references cr_items,    --imsld_time_limits
    on_completion_id            integer 
                                constraint imsld_plays_oncomp_fk 
                                references cr_items     --imsld_on_completion
);

create index imsld_plays_meth_id_idx on imsld_plays(method_id);
create index imsld_plays_act_id_idx on imsld_plays(when_last_act_completed_id);
create index imsld_plays_timel_id_idx on imsld_plays(time_limit_id);
create index imsld_plays_oncomp_id_idx on imsld_plays(on_completion_id);

comment on table imsld_plays is '
This table stores the plays of the method in the unit of learning.
The play is completed when the act (in imsld_acts) referenced by ''when_last_act_completed_id'' is completed or
when the time indicated by ''time_limit_id'' has fihished. If theese two fields are empty, the play is ''ulimited.''';

create table imsld_acts (
    act_id              integer 
                        constraint imsld_acts_fk 
                        references cr_revisions 
                        on delete cascade
                        constraint imsld_acts_pk 
                        primary key, 
    play_id             integer 
                        constraint imsld_plays_itemid_fk 
                        references cr_items     --imsld_plays
                        not null,
    time_limit_id       integer 
                        constraint imsld_acts_timelid_fk 
                        references cr_items,    --imsld_time_limits 
    identifier          varchar(100),
    on_completion_id    integer  
                        constraint imsld_acts_oncomp_fk  
                        references cr_items     --imsld_on_completion
);

create index imsld_acts_play_id_idx on imsld_acts(play_id);
create index imsld_acts_timel_id_idx on imsld_acts(time_limit_id);
create index imsld_acts_oncomp_id_idx on imsld_acts(on_completion_id);

comment on table imsld_acts is '
The mapping of activities and roles is done in the table ''imsld_role_parts''.
This table is the wrapper of the role parts of the unit of learning.';

create table imsld_role_parts (
    role_part_id            integer  
                            constraint imsld_rp_fk  
                            references cr_revisions  
                            on delete cascade
                            constraint imsld_rp_pk  
                            primary key,  
    identifier              varchar(100),
    role_id                 integer
                            constraint imsld_rp_roleid_fk
                            references cr_items,    --imsld_roles
    learning_activity_id    integer
                            constraint imsld_rp_laid_fk 
                            references cr_items,    --imsld_learning_activities
    support_activity_id     integer
                            constraint imsld_rp_said_fk  
                            references cr_items,    --imsld_support_activities
    unit_of_learning_id     integer
                            constraint imsld_rp_imslds_fk  
                            references cr_items,    --imsld_imslds
    activity_structure_id   integer
                            constraint imsld_rp_asid_fk  
                            references cr_items,    --imsld_activity_structures
    environment_id          integer
                            constraint imsld_rp_envid_fk   
                            references cr_items     --imsld_environments
);

create index imsld_rp_role_id_idx on imsld_role_parts(role_id);
create index imsld_rp_la_id_idx on imsld_role_parts(learning_activity_id);
create index imsld_rp_sa_id_idx on imsld_role_parts(support_activity_id);
create index imsld_rp_imsld_id_idx on imsld_role_parts(unit_of_learning_id);
create index imsld_rp_as_id_idx on imsld_role_parts(activity_structure_id);
create index imsld_rp_env_id_idx on imsld_role_parts(environment_id);

comment on table imsld_role_parts is '
This table holds the actual mapping bewteen activities and roles.
There are also mappings between roles and environments or units of learning';

create table imsld_time_limits (
    time_limit_id       integer  
                        constraint imsld_time_limits_fk  
                        references cr_revisions  
                        on delete cascade
                        constraint imsld_time_limits__pk   
                        primary key, 
    time_in_seconds     integer
                        not null
);

comment on table imsld_time_limits is '
The time limit specifies that an activity  is completed when a certain amount of time has passed, 
relative to the start of the run of the current unit of learning.
This unit is curretnly treated in seconds in dotLRN. 
Note: This table will be modificated when implementing level B.';

create table imsld_on_completion (
    on_completion_id        integer 
                            constraint imsld_oncomp_id_fk 
                            references cr_revisions 
                            on delete cascade
                            constraint imsld_oncomp_id_pk  
                            primary key, 
    feedback_id             integer             -- a feedback is an imsld_item
                            constraint imsld_oncomp_feedbid_fk   
                            references cr_items(item_id)
                            not null
);

create index imsld_oncomp_feedb_id_idx on imsld_on_completion(feedback_id);

comment on table imsld_on_completion is'
The underlying item elements point to a resource (of type webcontent or imsldcontent), where the feedback description can be found. After completion (of the component pointing to this row) this text becomes visible.';

comment on column imsld_on_completion.feedback_id is '
Reference to the item that holds the feedback.';

\i imsld-cp-create.sql