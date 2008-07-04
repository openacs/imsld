-- 
-- 
-- 
-- @author Derick Leony (derick@inv.it.uc3m.es)
-- @creation-date 2008-06-10
-- @arch-tag: 822367a3-8d73-4ea7-b1ff-763d1f47903a
-- @cvs-id $Id$
--

alter table imsld_complete_acts add time_string varchar(30);

alter table imsld_scheduled_time_limits drop column due_date;
alter table imsld_scheduled_time_limits drop constraint imsld_sche_tl_act_id_pk;
alter table imsld_scheduled_time_limits drop constraint imsld_sche_tl_act_id_fk;
alter table imsld_scheduled_time_limits add constraint imsld_sche_tl_act_id_fk foreign key (activity_id) references cr_items;
