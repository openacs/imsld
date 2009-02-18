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
      when rp.learning_activity_id is not null
      then 'learning'
      when rp.support_activity_id is not null
      then 'support'
      when rp.activity_structure_id is not null
      then 'structure'
      else 'none'
      end as type,
      content_item__get_live_revision(coalesce(rp.learning_activity_id,rp.support_activity_id,rp.activity_structure_id)) as activity_id,
      rp.role_part_id,
      ia.act_id,
      ip.play_id
      from imsld_role_partsi rp, imsld_actsi ia, imsld_playsi ip, imsld_imsldsi ii,
      imsld_methodsi im
      where  rp.act_id = ia.item_id
      and ia.play_id = ip.item_id
      and ip.method_id = im.item_id
      and im.imsld_id = ii.item_id
      and ii.imsld_id = :imsld_id
      and content_revision__is_live(rp.role_part_id) = 't'
      and content_item__get_live_revision(coalesce(rp.learning_activity_id,rp.support_activity_id,rp.activity_structure_id))
      is not null
      order by ip.sort_order, ia.sort_order, rp.sort_order
      
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
