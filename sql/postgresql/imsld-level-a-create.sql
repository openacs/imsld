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
    environment_id          integer
                            constraint imsld_serv_env_fk
                            references cr_items     --imsld_environments
                            not null,
    identifier              varchar(100)
                            not null,
    class                   varchar(4000),                  
    is_visible_p            char(1) 
                            check (is_visible_p in ('t','f')) 
                            default 't', 
    type                    varchar(100),
    parameters              varchar(4000)
);

create index imsld_lo_env_idx on imsld_learning_objects(environment_id);

comment on table imsld_learning_objects is '
Learning objects are incorporated (in dotLRN) by referencing resources through the item elements.';

comment on column imsld_learning_objects.class is '
The class attribute refers to the value of class attributes available in learning-design or content elements.';

comment on column imsld_learning_objects.type is '
The type of learning object (e.g. knowledge-object, tool-object test-object). Vocabulary used can be the one of ''learning resource type'' element from the IEEE LTSC LOM.';

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
    organization_id         integer
                            constraint imsld_org_id_fk
                            references cr_items     --imsld_cp_organizations
                            not null,
    identifier              varchar(100)
                            not null,
    version                 varchar(10),
    level                   char(1)
                            constraint imsld_level_ck 
                            check (level in ('a','b','c')),
    sequence_used_p         char(1)
                            constraint imsld_seq_ck
                            check (sequence_used_p in ('t','f'))
                            default 'f',
    learning_objective_id   integer
                            constraint imsld_lobj_id_fk
                            references cr_items,    --imsld_learning_objectives
    prerequisite_id         integer
                            constraint imsld_prereq_id_fk
                            references cr_items,    --imsld_prerequisites
    resource_handler	    varchar(100)
			    not null
);

create index imsld_imsld_orgid_idx on imsld_imslds(organization_id);
create index imsld_imsld_loid_idx on imsld_imslds(learning_objective_id);
create index imsld_imsld_pid_idx on imsld_imslds(prerequisite_id);

comment on table imsld_imslds is '
IMS-LD main table, where the imsld general information is stored.';

comment on column imsld_imslds.version is '
A version number of the document';

comment on column imsld_imslds.level is '
The level of the document. It can only be A, B or C';

comment on column imsld_imslds.sequence_used_p is '
If the value is true, IMS Simple Sequencing is included at the appropriate places in the document instance, default is false.';

comment on column imsld_imslds.resource_handler is '
Indicates which package is used to handle the resource objects for the UoL (file-storage or xowiki).';

create table imsld_learning_objectives (
    learning_objective_id  integer
                            constraint imsld_leo_fk
                            references cr_revisions
                            on delete cascade
                            constraint imsld_leo_pk
                            primary key,
    pretty_title            varchar(200)
);

comment on table imsld_learning_objectives is '
This table holds the learning objectives of the IMS-LD. 
Technically it is just a mapping table between items and the imsld_id or learning_activity_id, but this table was created to provide simplicity and clarification in the data model';

create table imsld_prerequisites (
    prerequisite_id     integer
                        constraint imsld_prereq_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_prereq_pk
                        primary key,
    pretty_title        varchar(200)
);

comment on table imsld_prerequisites is '
This table holds the prerequisites of the IMS-LD. 
Technically it is just a mapping table between items and the imsld_id or learning_activity_id, but this table was created to provide simplicity and clarification in the data model';

create table imsld_items (
    imsld_item_id   integer
                    constraint imsld_items_id_fk
                    references cr_revisions
                    on delete cascade
                    constraint imsld_items_id_pk
                    primary key,
    parent_item_id  integer
                    constraint imsld_items_pid_fk
                    references cr_items,    --imsld_items
    identifier      varchar(100),
    identifierref   varchar(100),
    is_visible_p    char(1)
                    check (is_visible_p in ('t','f'))
                    default 't',
    parameters      varchar(4000),
    -- recursive queries support
    imsld_tree_sortkey      varbit,
    imsld_max_child_sortkey varbit
);

create index imsld_items_pid_idx on imsld_items(parent_item_id);
create unique index imsld_items_tree_sortkey_un on imsld_items(imsld_tree_sortkey);

comment on table imsld_items is '
This table holds the imsld items of the unit of learning';

comment on column imsld_items.parent_item_id is '
In case it is a nested item.';

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
    component_id    integer
                    constraint imsld_roles_comp_id_fk
                    references cr_items     --imsld_components
                    not null,
    identifier      varchar(100),
    role_type       varchar(7)
                    check (role_type in ('learner','staff'))
                    not null,
    parent_role_id  integer
                    constraint imsld_roles_proleid_fk
                    references cr_items,    --imsld_roles
    create_new_p    char(1)
                    check (create_new_p in ('t','f'))
                    default 't',
    match_persons_p char(1)
                    check (match_persons_p in ('t','f'))
                    default 'f',
    max_persons     integer,
    min_persons     integer,
    href            varchar(2000)
);

create index imsld_roles_parent_id_idx on imsld_roles(parent_role_id);
create index imsld_roles_comp_id_idx on imsld_roles(component_id);

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

create table imsld_activity_descs (
    description_id      integer
                        constraint imsld_act_desc_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_act_desc_pk
                        primary key,
    pretty_title        varchar(200)
);

comment on table imsld_activity_descs is '
This table holds the description of a learning activity.
Technically it is just a mapping table between items and the learning activity, but this table was created to provide simplicity and clarification in the data model';

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
    activity_description_id integer
                            constraint imsld_la_desc_id_fk
                            references cr_items     --imsld_activity_descs
                            not null,
    parameters              varchar(4000),
    is_visible_p            char(1)
                            check (is_visible_p in ('t','f'))
                            default 't',
    complete_act_id         integer
                            constraint imdls_la_compa_fk
                            references cr_items,    --imsld_complete_acts
    on_completion_id        integer
                            constraint imdls_la_oncompid_fk
                            references cr_items,    --imsld_on_completion
    learning_objective_id   integer
                            constraint imsld_la_lobjid_fk
                            references cr_items,    --imsld_learning_objectives
    prerequisite_id         integer
                            constraint imsld_la_prereqid_fk
                            references cr_items,    --imsld_prerequisites
    sort_order              integer
                            default 0 
);

create index imsld_la_comp_id_idx on imsld_learning_activities(component_id);
create index imsld_la_ad_id_idx on imsld_learning_activities(activity_description_id);
create index imsld_la_timel_id_idx on imsld_learning_activities(complete_act_id);
create index imsld_la_oncomp_id_idx on imsld_learning_activities(on_completion_id);
create index imsld_la_lo_id_idx on imsld_learning_activities(learning_objective_id);
create index imsld_la_prereq_id_idx on imsld_learning_activities(prerequisite_id);

comment on table imsld_learning_activities is '
This table stores the learning activitis of the component of the unit of learning.';

comment on column imsld_learning_activities.parameters is '
Parameters to be passed during runtime.';

comment on column imsld_learning_activities.complete_act_id is '
References to the complete_act table. This table holds the information about the possible conditions that may set the activity as finished.';

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
    activity_description_id     integer
                                constraint imsld_sa_desc_id_fk
                                references cr_items     --imsld_activity_descs
                                not null,
    identifier                  varchar(100),
    is_visible_p                char(1)
                                check (is_visible_p in ('t','f'))
                                default 't',
    parameters                  varchar(4000),
    complete_act_id             integer 
                                constraint imdls_sa_compa_fk 
                                references cr_items,    --imsld_complete_acts
    on_completion_id            integer 
                                constraint imdls_sa_oncompid_fk 
                                references cr_items,    --imsld_on_completion
    sort_order                  integer
                               default 0 
);

create index imsld_sa_comp_id_idx on imsld_support_activities(component_id);
create index imsld_sa_ad_id_idx on imsld_support_activities(activity_description_id);
create index imsld_sa_timel_id_idx on imsld_support_activities(complete_act_id);
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
                                check (structure_type in ('selection','sequence')),
    sort                        varchar(16)
                                check (sort in ('as-is','visibility-order'))
                                default 'as-is',
    sort_order                  integer
                                default 0 
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

create table imsld_services (
    service_id      integer
                    constraint imsld_serv_fk
                    references cr_revisions
                    on delete cascade
                    constraint imsld_serv_pk
                    primary key,
    environment_id  integer
                    constraint imsld_serv_env_fk
                    references cr_items     --imsld_environments
                    not null,
    identifier      varchar(100),
    class           varchar(4000),
    is_visible_p    char(1) 
                    check (is_visible_p in ('t','f')) 
                    default 't',
    parameters      varchar(4000),
    service_type    varchar(10)
                    constraint imsld_serv_type_ck
                    check (service_type in ('send-mail','conference'))
);

create index imsld_serv_env_id_idx on imsld_services(environment_id);

comment on table imsld_services is '
This table stores all the services that are found in the IMS-LD.
The services are supposed to use the other .LRN packages (because that is how
the service is provided) but we also hold the information in this table.';

comment on column imsld_services.is_visible_p is '
Initial visibility attribute';

comment on column imsld_services.service_type is '
Service type. Currently only send-mail and conference service types are supported
and their respective information is sotred in the tables imsld_send_mail_services and imsld_conference_services, respectively.';

create table imsld_send_mail_services (
    mail_id         integer 
                    constraint imsld_emailserv_fk 
                    references cr_revisions 
                    on delete cascade
                    constraint imsld_emailserv_pk 
                    primary key, 
    service_id      integer
                    constraint imsld_emailsevr_service_fk
                    references cr_items     --imsld_services
                    not null,
    recipients      varchar(11)
                    check (recipients in ('all-in-role','selection'))
);

create index imsld_send_m_serv_id_idx on imsld_send_mail_services(service_id);

comment on column imsld_send_mail_services.recipients is '
Fixed choice: ''all-in-role'' or ''selection''. With the first choice, the user agent only allows messages to be sent to the role, indicating that all persons in the role get the message. With the second choice, the user agent allows a user to select one or more individuals within the specified role to send the message to';

create table imsld_send_mail_data (
    data_id         integer  
                    constraint imsld_semaildata_fk  
                    references cr_revisions  
                    on delete cascade
                    constraint imsld_semaildata_pk  
                    primary key,  
    role_id         integer
                    constraint imsld_semaildata_roleid_fk
                    references cr_items     --imsld_roles
                    not null,
    mail_data       text
);

create index imsld_sm_data_role_id_idx on imsld_send_mail_data(role_id);

create table imsld_conference_services (
    conference_id       integer   
                        constraint imsld_confs_fk   
                        references cr_revisions   
                        on delete cascade
                        constraint imsld_confs_pk   
                        primary key,   
    service_id          integer
                        constraint imsld_emailsevr_service_fk
                        references cr_items     --imsld_services
                        not null,
    conference_type     char(12)
                        check (conference_type in ('synchronous','asynchronous','announcement')),
    imsld_item_id       integer
                        constraint imsld_confs_item_itemid_fk
                        references cr_items,    --imsld_items
    moderator_id        integer 
                        constraint imsld_confs_moderator_fk 
                        references cr_items     --imsld_roles
);

create index imsld_confs_serv_id on imsld_conference_services(service_id);
create index imsld_confs_item_id on imsld_conference_services(imsld_item_id);
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
    complete_act_id     integer
                        constraint imsld_methods_compa_fk
                        references cr_items,    --imsld_complete_acts
    on_completion_id    integer
                        constraint imsld_methods_oncomp_fk
                        references cr_items     --imsld_on_completion
);

create index imsld_methods_imsld_id_idx on imsld_methods(imsld_id);
create index imsld_methods_timel_id_idx on imsld_methods(complete_act_id);
create index imsld_methods_oncomp_id_idx on imsld_methods(on_completion_id);

comment on table imsld_methods is '
This table holds the methods of the unit of learning.
The methods are the ones that specifies the sequence of activities. 
Theese activities are grouped with their corresponding roles and form a play, which is mapped to the method.
The method is completed when all the ''plays to complete method'' mapped to this table are completed or
when the time indicated by time_limit has been completed, and may be completed by some contidions explained
in the level B of the spec';

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
    complete_act_id             integer
                                constraint imsld_plays_compa_fk
                                references cr_items,    --imsld_complete_acts
    on_completion_id            integer 
                                constraint imsld_plays_oncomp_fk 
                                references cr_items,    --imsld_on_completion
    sort_order                  integer
);

create index imsld_plays_meth_id_idx on imsld_plays(method_id);
create index imsld_plays_timel_id_idx on imsld_plays(complete_act_id);
create index imsld_plays_oncomp_id_idx on imsld_plays(on_completion_id);

comment on table imsld_plays is '
This table stores the plays of the method in the unit of learning.
The play is completed when the act (in imsld_acts) referenced by ''when_last_act_completed_id'' is completed or
when the time indicated by ''time_limit_id'' has fihished (it may also be completed according to
some conditions explained in the level B of the spec). If theese two fields are empty, the play is ''ulimited.''';

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
    complete_act_id     integer 
                        constraint imsld_acts_compa_fk 
                        references cr_items,    --imsld_complete_acts
    identifier          varchar(100),
    on_completion_id    integer  
                        constraint imsld_acts_oncomp_fk  
                        references cr_items,    --imsld_on_completion
    sort_order          integer
);

create index imsld_acts_play_id_idx on imsld_acts(play_id);
create index imsld_acts_timel_id_idx on imsld_acts(complete_act_id);
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
    act_id                  integer 
                            constraint imsld_rp_aid_fk
                            references cr_items     --imsld_acts
                            not null,
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
    activity_structure_id   integer
                            constraint imsld_rp_asid_fk  
                            references cr_items,    --imsld_activity_structures
    environment_id          integer
                            constraint imsld_rp_envid_fk   
                            references cr_items,    --imsld_environments
    sort_order              integer
);

create index imsld_rp_act_id_idx on imsld_role_parts(act_id);
create index imsld_rp_role_id_idx on imsld_role_parts(role_id);
create index imsld_rp_la_id_idx on imsld_role_parts(learning_activity_id);
create index imsld_rp_sa_id_idx on imsld_role_parts(support_activity_id);
create index imsld_rp_as_id_idx on imsld_role_parts(activity_structure_id);
create index imsld_rp_env_id_idx on imsld_role_parts(environment_id);

comment on table imsld_role_parts is '
This table holds the actual mapping bewteen activities and roles.
There are also mappings between roles and environments or units of learning';

create table imsld_complete_acts (
    complete_act_id             integer  
                                constraint imsld_compa_fk  
                                references cr_revisions  
                                on delete cascade
                                constraint imsld_compa_pk   
                                primary key, 
    time_in_seconds             integer,
    time_string	 		varchar(30),
    user_choice_p               char(1) 
                                check (user_choice_p in ('t','f')),
    when_last_act_completed_p   char(1)   
                                check (when_last_act_completed_p in ('t','f'))   
                                default 't'
);

comment on table imsld_complete_acts is '
Contains a choice of elements to specify when an activity is completed. 
When this element does not occur, the activity is set to ''completed''.';

comment on column imsld_complete_acts.user_choice_p is '
This element specifies that the user may decide him or herself when the activity is completed. This means that a control must be available in the user-interface to set the activity status to ''completed''. A user can do this once (no undo). Once he/she indicated the activity to be completed, then this activity stays completed in the run.';

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
    feedback_title          varchar(200)
);

comment on table imsld_on_completion is '
The underlying item elements point to a resource (of type webcontent or imsldcontent), where the feedback description can be found. After completion (of the component pointing to this row) this text becomes visible.

Feedback are items that are mapped to this table with the imsld_feedback_rel.';

create table imsld_classes (
    class_id        integer 
                    constraint imsld_cla_fk 
                    references cr_revisions 
                    on delete cascade
                    constraint imsld_cla_pk
                    primary key,
    method_id       integer 
                    constraint imsld_cla_methodid_fk 
                    references cr_items,    --imsld_methods
    identifier      varchar(200)
);

comment on table imsld_classes is '
Classes (global elements) which are referenced trough the imsld-content resources, and which visibility may be modified in the conditions.';

-- Rel Tables

create table imsld_as_la_rels (
    rel_id      integer
                constraint imsld_as_la_rels_fk
                references acs_rels
                constraint imsld_as_la_rels_pk
                primary key
);

comment on table imsld_as_la_rels is '
This table stores the information of the relationship between the activity structures and the learning activities.';

create table imsld_as_sa_rels (
    rel_id      integer
                constraint imsld_as_sa_rels_fk
                references acs_rels
                constraint imsld_as_sa_rels_pk
                primary key
);

comment on table imsld_as_sa_rels is '
This table stores the information of the relationship between the activity structures and the support activities.';

create table imsld_as_as_rels (
    rel_id      integer
                constraint imsld_as_as_rels_fk
                references acs_rels
                constraint imsld_as_as_rels_pk
                primary key
);

comment on table imsld_as_as_rels is '
This table stores the information of the relationship between the activity structures (between them).';

create table imsld_res_xowiki_rels (
    rel_id      integer
                constraint imsld_res_xowiki_rels_fk
                references acs_rels
                constraint imsld_res_xowiki_rels_pk
                primary key
);

comment on table imsld_res_xowiki_rels is '
This table stores the relationships between resources and xowiki Pages.';

create table imsld_res_files_rels (
    rel_id      integer
                constraint imsld_res_files_rels_fk
                references acs_rels
                constraint imsld_res_files_rels_pk
                primary key
);

comment on table imsld_res_files_rels is '
This table stores the relationships between resources and files.';


create table imsld_scheduled_time_limits (
    activity_id	integer
                constraint imsld_sche_tl_act_id_fk
            	references cr_items,
    time	integer
);

comment on table imsld_scheduled_time_limits is '
This table stores the schedule time of time_lmit for the different structures.';
