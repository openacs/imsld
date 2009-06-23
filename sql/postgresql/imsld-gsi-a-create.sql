--
-- GSI Data Model (services for IMS LD)
--
-- @author lfuente@it.uc3m.es
-- @creation-date oct-2008
--



-- next two tables do not use the content repository
create table imsld_gsi_functions (
        gsi_function_id             integer
                                    constraint imsld_gsi_functions_pk
                                    primary key,
        function_name               varchar(100)
                                    not null
        );

comment on table imsld_gsi_functions is 'All functions requested to be performed in services when triggers are fired.';

create table imsld_gsi_function_params (
        gsi_function_param_id       integer
                                    constraint imsld_gsi_funcparam_pk
                                    primary key,
        gsi_function_id             integer
                                    constraint imsld_gsi_funcparam_function_fk
                                    references imsld_gsi_functions
                                    not null,
        param_name                  varchar(100)
                                    not null
        );

comment on table imsld_gsi_function_params is 'A function can be used with 0, 1 or more params, whose names are in this table';
comment on column imsld_gsi_function_params.param_name is 'The name of the param to use with the references function';


create table imsld_gsi_tools_funct_rels (
        gsi_function_id             integer
                                    constraint imsld_gsi_functid_fk
                                    references imsld_gsi_functions
                                    not null,
        gsi_tool_id                 integer
                                    constraint imsld_gsi_toolid_fk
                                    references cr_items     --imsld_gsi_tools
                                    on delete cascade
                                    not null
        );

create table imsld_gsi_triggers (
        gsi_trigger_id          integer
                                constraint imsld_gsi_trigger_pk
                                primary key,
        trigger_type            varchar(100)
                                constraint imsld_gsi_triggers_type_ck
                                check (trigger_type in ('startup-action', 'finish-action','on-complete-action','on-condition-action'))
        );

create table imsld_gsi_par_val_rels (
        gsi_function_param_id       integer
                                    constraint imsld_gsi_param_fk
                                    references imsld_gsi_function_params,
        gsi_param_value             varchar(500),
        gsi_function_usage_id       integer
                                    constraint imsld_gsi_usage_fk
                                    references cr_items     --imsld_gsi_function_usage
                                    on delete cascade
                                    not null
        );

create table imsld_gsi_trigger_params (
        gsi_trigger_param_id    integer
                                constraint imsld_gsi_trigger_param_pk
                                primary key,
        gsi_param_name          varchar(500),
        gsi_trigger_id          integer
                                constraint imsld_gsi_trigger_id_fk
                                references imsld_gsi_triggers
                                on delete cascade
                                not null
       );

create table imsld_gsi_trig_param_values (
        gsi_trig_param_val_id   integer
                                constraint imsld_gsi_trig_param_val_pk
                                primary key,
        gsi_trig_param_id       integer
                                constraint imsld_gsi_trig_param_id_fk
                                references imsld_gsi_trigger_params,     --imsld_gsi_triggers
        gsi_trig_param_value    text,
        gsi_funct_usage_id      integer
                                constraint imsld_gsi_usage_fk
                                references cr_items     --imsld_gsi_function_usage
                                on delete cascade
                                not null
       );


create table imsld_gsi_serv_instances (
        service_instance_id         integer
                                    constraint  imsld_gsi_instance_fk
                                    references imsld_attribute_instances,
        url                         varchar(500),
        url_title                   varchar(100)
        );
--la columna user_map no se pone porque es parte de cada plugin, no de la estructura principal


create table imsld_gsi_service_status (
        service_status_id           integer
                                    constraint  imsld_gsi_instance_pk
                                    primary key,
        owner_id                    integer
                                    constraint imsld_gsi_serv_status_fk
                                    references cr_revisions --imsld_gsi_service
                                    not null,
        run_id                      integer
                                    constraint imsld_gsi_run_status_fk
                                    references imsld_runs --imlsd_runs
                                    not null,
        status                      varchar(50)
                                    constraint  imsld_gsi_status_ck
                                    check (status in ('not-configured','chosen','mapped','not-found','configured')),
        plugin_URI                  varchar(500),
        last_modified               timestamptz
        );

comment on column imsld_gsi_service_status.plugin_URI is 'This column is filled only if the status is configured';


create table imsld_gsi_service_requests (
        gsi_request_id              integer
                                    constraint imsld_gsi_request_pk
                                    primary key,
        serv_status_id              integer
                                    constraint imsld_gsi_request_fk
                                    references imsld_gsi_service_status
                                    not null,
        plugin_URI                  varchar(500)
                                    not null,
        function_response           varchar(1000),
        permissions_response        varchar(1000),
        last_modified               timestamptz
        );

comment on table imsld_gsi_service_requests is 'When a request to a given service (using a given plugin) is performed, a new row is inserted here. This row will store the answer given by the service.';
comment on column imsld_gsi_service_requests.plugin_URI is 'The request is sent through a given plugin';
comment on column imsld_gsi_service_requests.serv_status_id is 'Since this ID links to the service, the information about request contents is implicitly stored here.';
comment on column imsld_gsi_service_requests.function_response is 'Service response concerning functions';
comment on column imsld_gsi_service_requests.permissions_response is 'Service response concerning permissions';



create table imsld_gsi_plugins (
        plugin_string_id        varchar(25)
                                constraint imsld_gsi_plugin_pk
                                primary key,
        plugin_URI              varchar(500)
                                not null
        );

comment on table imsld_gsi_plugins is 'Each time a plugin is installed, a new row must be inserted here. Contains a correspondence between URI (long string) and a string based unique identifier, easier to handle.'; 


-- include plugin tables, if needed

\i imsld-gsi-plugin-xowiki.sql
\i imsld-gsi-plugin-gspread.sql
