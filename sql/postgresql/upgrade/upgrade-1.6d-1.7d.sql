-- 
-- 
-- 
-- @author Derick Leony (derick@inv.it.uc3m.es)
-- @creation-date 2009-04-27
-- @arch-tag: 71efafb2-68bc-455e-a38a-4682102251bd
-- @cvs-id $Id$
--

alter table imsld_scheduled_time_limits drop constraint imsld_sche_tl_act_id_fk;
alter table imsld_scheduled_time_limits add constraint imsld_sche_tl_act_id_fk foreign key (activity_id) references cr_items;
