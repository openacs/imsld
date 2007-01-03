-- upgrade script from 0.01d to 1.0d

create function inline_0 ()
returns integer as'
declare
  sel_rec record;
begin
  for sel_rec in select serv.username_property_id, serv.email_property_id, data.data_id 
    from imsld_send_mail_data data, imsld_send_mail_servicesi serv 
	where data.send_mail_id = serv.item_id
    and content_revision__is_live(serv.mail_id) = ''t''
  loop 
    update imsld_send_mail_data 
    set email_property_id = sel_rec.email_property_id,
    username_property_id = sel_rec.username_property_id
    where data_id = sel_rec.data_id;
  end loop;
return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


drop index imsld_sm_data_sm_id_idx;
alter table imsld_send_mail_data drop column send_mail_id cascade;
select content_type__drop_attribute('imsld_send_mail_data','send_mail_id','f');

alter table imsld_send_mail_services drop column email_property_id cascade;
select content_type__drop_attribute('imsld_send_mail_service','email_property_id','f');

alter table imsld_send_mail_services drop column username_property_id cascade;
select content_type__drop_attribute('imsld_send_mail_service','username_property_id','f');

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

\i ../imsld-level-c-create.sql
