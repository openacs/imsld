<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Derick Leony (derick@inv.it.uc3m.es) -->
<!-- @creation-date 2009-02-06 -->
<!-- @arch-tag: /bin/bash: uuidgen: command not found -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="get_learning_activity_info">
    <querytext>
      
      select la.title as activity_title,
      la.item_id as activity_item_id,
      la.activity_id,
      la.complete_act_id
      from imsld_learning_activitiesi la
      where activity_id = :activity_id
      
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
  
  <fullquery name="struct_referenced_activities">
    <querytext>
      select ar.object_id_two,
      ar.rel_type,
      ar.rel_id,
      ir.sort_order,
      case ar.rel_type
      when 'imsld_as_la_rel'
      then 'learning'
      when 'imsld_as_sa_rel'
      then 'support'
      when 'imsld_as_as_rel'
      then 'structure'
      else 'none'
      end as activity_type
      from acs_rels ar, imsld_activity_structuresi ias,
      (select * from imsld_as_la_rels union select * from imsld_as_sa_rels union
        select * from imsld_as_as_rels) as ir
      where ar.object_id_one = ias.item_id
      and ar.rel_id = ir.rel_id
      and ias.structure_id = :structure_id
      and content_item__get_live_revision(ar.object_id_two) is not null
      order by ir.sort_order, ar.object_id_two
      
    </querytext>
  </fullquery>

  <fullquery name="structure_info">
    <querytext>
      
      select structure_id,
      structure_type
      from imsld_activity_structuresi
      where item_id = :structure_item_id
      
    </querytext>
  </fullquery>

</queryset>
