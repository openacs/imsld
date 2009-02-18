<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Derick Leony (derick@inv.it.uc3m.es) -->
<!-- @creation-date 2009-02-06 -->
<!-- @arch-tag: /bin/bash: uuidgen: command not found -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <fullquery name="current_role">
    <querytext>
      
      select map.active_role_id as user_role_id
      from imsld_run_users_group_rels map,
      acs_rels ar,
      imsld_run_users_group_ext iruge
      where ar.rel_id = map.rel_id
      and ar.object_id_one = iruge.group_id
      and ar.object_id_two = :user_id
      and iruge.run_id = :run_id
      
    </querytext>
  </fullquery>
  
  <fullquery name="referenced_role_parts">
    <querytext>
      
      select case
      when irp.learning_activity_id is not null
      then 'learning'
      when irp.support_activity_id is not null
      then 'support'
      when irp.activity_structure_id is not null
      then 'structure'
      else 'none'
      end as type,
      content_item__get_live_revision(coalesce(irp.learning_activity_id, irp.support_activity_id, irp.activity_structure_id)) as activity_id,
      irp.role_part_id,
      ia.act_id,
      ca.item_id as act_item_id,
      ip.play_id
      from imsld_role_parts irp, imsld_acts ia, imsld_plays ip, imsld_imslds ii, imsld_attribute_instances iai,
      imsld_methods im, imsld_roles ir, cr_items ca, cr_items cp, cr_items cm, cr_items ci, cr_items cr
      where irp.act_id = ca.item_id
      and ca.live_revision = ia.act_id
      and ia.play_id = cp.item_id
      and cp.live_revision = ip.play_id
      and ip.method_id = cm.item_id
      and cm.live_revision = im.method_id
      and im.imsld_id = ci.item_id
      and ci.live_revision = ii.imsld_id
      and ii.imsld_id = :imsld_id
      and irp.role_id = cr.item_id
      and cr.live_revision = ir.role_id
      and ir.role_id = :user_role_id
      and content_revision__is_live(irp.role_part_id) = 't'
      and iai.owner_id = ip.play_id
      and iai.run_id = :run_id
      and iai.user_id = :user_id
      and iai.type = 'isvisible'
      and iai.is_visible_p = 't'
      and content_item__get_live_revision(coalesce(irp.learning_activity_id,irp.support_activity_id,irp.activity_structure_id))
      is not null
      order by ip.sort_order, ia.sort_order, irp.sort_order
      
    </querytext>
  </fullquery>
  
  <fullquery name="get_support_activity_info">
    <querytext>
      
      select sa.title as activity_title,
      sa.item_id as activity_item_id,
      sa.activity_id,
      attr.is_visible_p,
      sa.complete_act_id
      from imsld_support_activitiesi sa, imsld_attribute_instances attr
      where sa.activity_id = :activity_id
      and attr.owner_id = sa.activity_id
      and attr.run_id = :run_id
      and attr.user_id = :user_id
      and attr.type = 'isvisible'
      
    </querytext>
  </fullquery>
  
  <fullquery name="get_activity_structure_info">
    <querytext>
      
      select title as activity_title,
      item_id as structure_item_id,
      structure_id,
      structure_type
      from imsld_activity_structuresi
      where structure_id = :activity_id
      
    </querytext>
  </fullquery>
  
  <fullquery name="as_started_p">
    <querytext>
      
      select 1 from imsld_status_user
      where related_id = :activity_id 
      and user_id = :user_id 
      and status = 'started'
      and run_id = :run_id
      
    </querytext>
  </fullquery>

  <fullquery name="as_completed_p">
    <querytext>

      select 1 from imsld_status_user
      where related_id = :activity_id 
      and user_id = :user_id 
      and status = 'finished'
      and run_id = :run_id
      
    </querytext>
  </fullquery>

</queryset>
