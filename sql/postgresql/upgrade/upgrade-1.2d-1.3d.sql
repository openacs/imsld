-- 
-- 
-- 
-- @author Derick Leony (derick@inv.it.uc3m.es)
-- @creation-date 2008-05-27
-- @arch-tag: d0c4be23-0d6b-401b-86cb-05cffab500e4
-- @cvs-id $Id$
--

create table imsld_scheduled_time_limits (
    activity_id	integer
                constraint imsld_sche_tl_act_id_fk
            	references cr_revisions
                constraint imsld_sche_tl_act_id_pk
		primary key,
    time	integer,
    due_date	date
);

comment on table imsld_scheduled_time_limits is '
This table stores the schedule time of time_lmit for the different structures.';

