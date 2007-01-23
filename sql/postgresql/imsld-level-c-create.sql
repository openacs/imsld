--
-- IMS-LD Package Data Model for Level C
--
-- @author jopez@inv.it.uc3m.es
-- @creation-date oct-2006
--

create table imsld_notifications (
    notification_id     integer  
                        constraint imsld_notif_id_fk
                        references cr_revisions  
                        on delete cascade
                        constraint imsld_notif_id_pk
                        primary key, 
    imsld_id            integer
                        constraint imsld_notif_ii_fk
                        references cr_items     --imsld_imslds
                        not null,
    activity_id         integer
                        constraint imsld_notif_act_fk
                        references cr_items     --imsld_learning_activities/imsld_support_activities
                        not null,
    subject             text
);

create index imsld_notif_ii_idx on imsld_notifications(imsld_id);
create index imsld_notif_act_idx on imsld_notifications(activity_id);

comment on table imsld_notifications is '
Notifications of the on_completion elements are stored in this table. The rest of notificacions are stored along with the XML which contains them and dealed with in the running stage.';

create table imsld_notifications_history (
    run_id              integer
                        references imsld_runs,
    from_user_id        integer
                        references parties,
    notification_date   timestamptz,
    target_activity_id  integer
                        references cr_revisions,
    to_user_id          integer
                        references parties
);

comment on table imsld_notifications_history is '
Table used to keep track of the notifications';

create sequence t_imsld_rar_seq;
create view imsld_rar_seq as
select nextval('t_imsld_rar_seq') as nextval;

create table imsld_runtime_activities_rels (
    rel_id      integer
                constraint imsld_rar_rels_pk
                primary key,
    run_id      integer
                constraint imsld_rar_run_fk
                references imsld_runs,
    role_id     integer
                constraint imsld_rar_role_fk
                references cr_revisions,
    activity_id integer
                constraint imsld_rar_act_fk
                references cr_revisions
);

comment on table imsld_runtime_activities_rels is '
This table stores the relationships between run time assigned activities and roles.';

