--
-- IMS-LD Package Data Model for Level B
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date jan-2006
--

create table imsld_properties (
    property_id             integer  
                            constraint imsld_pro_id_fk
                            references cr_revisions  
                            on delete cascade
                            constraint imsld_pro_id_pk
                            primary key, 
    component_id            integer
                            constraint imsld_pro_comp_fk
                            references cr_items     --imsld_components
                            not null,
    identifier              varchar(100)
                            not null,
    type                    varchar(20)
                            check (type in ('loc','locpers','locrole','globpers','global')),
    datatype                varchar(20)
                            check (datatype in ('boolean','integer','real','string','file','uri','datetime','duration','text','other')),
    initial_value           varchar(4000),
    role_id                 integer
                            constraint imsld_pro_rid_fk
                            references cr_items,    --imsld_roles
    existing_href           varchar(2000),          --the href of the existing properties 
    uri                     varchar(2000)           --for global_definition elements: the uri
);

create index imsld_prop_comp_idx on imsld_properties(component_id);

comment on table imsld_properties is '
Properties are introduced in the level B of the IMS-LD spec, and are stored in this table (the definition, because the instantiantion for each user/role is stored in the imsld_property_instanced table).

The global definitions of the globpers and global property types are stored in this table also, because they share all but one fields.';

create table imsld_property_groups (
    property_group_id   integer  
                        constraint imsld_pgr_id_fk
                        references cr_revisions  
                        on delete cascade
                        constraint imsld_pgr_id_pk
                        primary key, 
    component_id        integer
                        constraint imsld_pro_comp_fk
                        references cr_items     --imsld_components
                        not null,
    identifier          varchar(100)
                        not null
);

create index imsld_pgr_comp_idx on imsld_property_groups(component_id);

comment on table imsld_property_groups is '
Used to group properties (using the rels: imsld_gprop_prop_rel and )';

create table imsld_restrictions (
    restriction_id      integer  
                        constraint imsld_rest_id_fk
                        references cr_revisions  
                        on delete cascade
                        constraint imsld_rest_id_pk
                        primary key, 
    property_id         integer
                        constraint imsld_rest_prop_fk
                        references cr_items     --imsld_properties
                        not null,
    restriction_type    varchar(20)
                        check (restriction_type in ('length','minlength','maxlength','enumeration','maxinclusive','mininclusive','maxexclusive','minexclusive','totaldigits','fractiondigits','whitespace','pattern')),
    value               varchar(4000)
);

create index imsld_rest_idx on imsld_restrictions(property_id);

comment on table imsld_restrictions is '
Restrictions of the properties. Defined in the IMS-LD spec';

create table imsld_properties_values (
    property_value_id   integer
                        constraint imsld_propv_id_fk
                        references cr_revisions
                        on delete cascade
                        constraint imsld_propv_id_pk
                        primary key,
    property_id         integer
                        constraint imsld_propv_prop_fk
                        references cr_items     --imsld_properties
                        not null,
    langstring          varchar(400),
    calculate_id        integer
                        constraint imsld_propv_calc_fk
                        references cr_items,    --imsld_expressions
    property_value_ref  integer
                        constraint imsld_prop_ref_fk
                        references cr_items     --imsld_properties_values
);

comment on table imsld_properties_values is '
Table used to store the values of the properties for the ''when_property_value_is set'' and ''change_property_value''.';

create table imsld_monitor_services (
    monitor_id      integer 
                    constraint imsld_monserv_fk 
                    references cr_revisions 
                    on delete cascade
                    constraint imsld_monserv_pk 
                    primary key, 
    service_id      integer
                    constraint imsld_monsevr_service_fk
                    references cr_items     --imsld_services
                    not null,
    role_id         integer
                    constraint imsld_monserv_role_fk
                    references cr_items,    --imsld_roles
    self_p          char(1)
                    check (self_p in ('t','f'))
                    default 'f',
    imsld_item_id   integer
                    constraint imsld_monserv_item_fk
                    references cr_items     --imsld_items
);

create index imsld_monserv_serv_id_idx on imsld_monitor_services(service_id);
create index imsld_monserv_role_id_idx on imsld_monitor_services(role_id);
create index imsld_monserv_iitem_id_idx on imsld_monitor_services(imsld_item_id);

comment on table imsld_monitor_services is '
The monitor service provides a facility for users to look at their own properties or that of others in a structured way. A monitor uses global properties in resources of type ''imsldcontent'' to view the properties of one-self or of all users in a role.';

create table imsld_when_condition_true (
    when_condition_true_id  integer 
                            constraint imsld_when_fk 
                            references cr_revisions 
                            on delete cascade
                            constraint imsld_when_pk 
                            primary key, 
    role_id                 integer
                            constraint imsld_then_ref_fk
                            references cr_items     --imsld_roles
                            not null,
    expression_id           integer
                            constraint imsld_then_cpv_fk
                            references cr_items     --imsld_properties_values
                            not null
);

create index imsld_when_role_idx on imsld_when_condition_true(role_id);
create index imsld_when_exp_idx on imsld_when_condition_true(expression_id);

comment on table imsld_when_condition_true is '
Simple expression for a condition. This condition applies to all the individual users mentioned in the containing role-ref. When the contained expression is true for all users in the specified roles, this condition is true.';

alter table imsld_send_mail_services add column email_property_id integer constraint imsld_emailprop_fk references cr_items;    --imsld_properties
alter table imsld_send_mail_services add column username_property_id integer constraint imsld_unameprop_fk references cr_items; --imsld_properties

alter table imsld_complete_acts add column time_property_id integer constraint imsld_compa_timepropv_fk references cr_items;        --imsld_properties
alter table imsld_complete_acts add column when_prop_val_is_set_id integer constraint imsld_compa_wpvis_fk references cr_items;     --imsld_properties_values
alter table imsld_complete_acts add column when_condition_true_id integer constraint imsld_compa_whencondt_fk references cr_items;  --imsld_properties


alter table imsld_services drop constraint imsld_serv_type_ck;
alter table imsld_services add constraint imsld_serv_type_ck check (service_type in ('send-mail','conference','monitor'));



create table imsld_conditions (
    condition_id    integer 
                    constraint imsld_cond_fk 
                    references cr_revisions 
                    on delete cascade
                    constraint imsld_cond_pk 
                    primary key, 
    method_id       integer
                    constraint imsld_cond_method_fk
                    references cr_items     --imsld_methods
                    not null,
    condition_xml   text
);

create index imsld_cond_methodid_idx on imsld_conditions(method_id);

comment on table imsld_conditions is '
All conditions are pre-conditions and must be evaluated: - when entering the run of a unit of learning (new session); - every time when the value of a property has been changed.';
