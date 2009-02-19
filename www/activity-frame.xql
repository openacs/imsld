<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Derick Leony (derick@inv.it.uc3m.es) -->
<!-- @creation-date 2009-01-19 -->
<!-- @arch-tag: /bin/bash: uuidgen: command not found -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="get_activity_type">
    <querytext>
      select r.imsld_id,
      case
      when exists (select 1 from imsld_learning_activities where activity_id = :activity_id)
      then 'learning'
      when exists (select 1 from imsld_support_activities where activity_id = :activity_id)
      then 'support'
      when exists (select 1 from imsld_activity_structures where structure_id = :activity_id)
      then 'structure'
      end as activity_type
      from imsld_runs r
      where run_id = :run_id
    </querytext>
  </fullquery>
  
  <fullquery name="mark_activity_started">
    <querytext>
      insert into imsld_status_user (imsld_id,
      run_id,
      related_id,
      user_id,
      type,
      status_date,
      status) 
      (
      select :imsld_id,
      :run_id,
      :activity_id,
      :user_id,
      :activity_type,
      now(),
      'started'
      where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :activity_id and status = 'started')
      )
    </querytext>
  </fullquery>

  <fullquery name="referenced_from_structure_p">
    <querytext>
      select ar.object_id_one as referencer_structure_item_id
      from acs_rels ar
      where ar.object_id_two = :activity_item_id
    </querytext>
  </fullquery>

  <fullquery name="get_structure_info">
    <querytext>    
      select structure_id,
      number_to_select
      from imsld_activity_structuresi
      where item_id = :referencer_structure_item_id
      and content_revision__is_live(structure_id) = 't'
    </querytext>
  </fullquery>

  <fullquery name="already_finished">
    <querytext>
      select 1
      from imsld_status_user
      where related_id = :structure_id
      and user_id = :user_id
      and run_id = :run_id
      and status = 'finished'
    </querytext>
  </fullquery>

  <fullquery name="struct_referenced_activities">
    <querytext>
      select ar.object_id_two,
      ar.rel_type
      from acs_rels ar
      where ar.object_id_one = :referencer_structure_item_id
      order by ar.object_id_two
    </querytext>
  </fullquery>

  <fullquery name="la_completion_restriction">
    <querytext>
      select complete_act_id
      from imsld_learning_activities
      where activity_id = :referenced_activity_id
    </querytext>
  </fullquery>

  <fullquery name="la_already_started_p">
    <querytext>
      select 1
      from imsld_status_user
      where related_id = :referenced_activity_id
      and user_id = :user_id
      and run_id = :run_id
      and status = 'started'
    </querytext>
  </fullquery>

  <fullquery name="la_already_finished">
    <querytext>
      select 1
      from imsld_status_user
      where related_id = :referenced_activity_id
      and user_id = :user_id
      and run_id = :run_id
      and status = 'finished'
    </querytext>
  </fullquery>

  <fullquery name="context_info">
    <querytext>
      select acts.act_id,
      plays.play_id
      from imsld_actsi acts, imsld_playsi plays, imsld_role_parts rp
      where rp.role_part_id = :role_part_id
      and rp.act_id = acts.item_id
      and acts.play_id = plays.item_id
    </querytext>
  </fullquery>

  <fullquery name="supported_roles_list">
    <querytext>
      select iri.role_id 
      from imsld_rolesi iri, 
      acs_rels ar,  
      imsld_support_activitiesi isai 
      where iri.item_id=ar.object_id_two 
      and ar.rel_type='imsld_sa_role_rel' 
      and ar.object_id_one=isai.item_id 
      and isai.activity_id =:activity_id
    </querytext>
  </fullquery>

  <fullquery name="get_table_name">
    <querytext>
      select 
      case 
      when exists (select 1 from imsld_learning_activities where activity_id=:activity_id) 
      then 'imsld_learning_activities' 
      when exists (select 1 from imsld_support_activities where activity_id=:activity_id) 
      then 'imsld_support_activities' 
      end as table_name 
      from dual
    </querytext>
  </fullquery>

  <fullquery name="get_prerequisites_list">
    <querytext>
      select ar2.object_id_two 
      from acs_rels ar1, 
      acs_rels ar2, 
      imsld_learning_activities tn 
      where tn.activity_id=:activity_id 
      and ar1.object_id_one=tn.prerequisite_id 
      and ar1.rel_type='imsld_preq_item_rel' 
      and ar1.object_id_two=ar2.object_id_one 
      and ar2.rel_type='imsld_item_res_rel' 
    </querytext>
  </fullquery>

  <fullquery name="get_objectives_list">
    <querytext>
      select ar2.object_id_two 
      from acs_rels ar1, 
      acs_rels ar2, 
      imsld_learning_activities tn 
      where tn.activity_id=:activity_id 
      and ar1.object_id_one=tn.learning_objective_id 
      and ar1.rel_type='imsld_lo_item_rel' 
      and ar1.object_id_two=ar2.object_id_one 
      and ar2.rel_type='imsld_item_res_rel'
    </querytext>
  </fullquery>

  <fullquery name="activity_info">
    <querytext>
      select ii.imsld_item_id
      from imsld_items ii, imsld_activity_descs sad, imsld_support_activities sa,
      cr_items cr1, cr_items cr2,
      acs_rels ar
      where sa.activity_id = :activity_id
      and sa.activity_description_id = cr1.item_id
      and cr1.live_revision = sad.description_id
      and ar.object_id_one = sa.activity_description_id
      and ar.object_id_two = cr2.item_id
      and cr2.live_revision = ii.imsld_item_id
    </querytext>
  </fullquery>

  <fullquery name="support_activity_associated_item">
    <querytext>
      select cpr.resource_id,
      cpr.item_id as resource_item_id,
      cpr.type as resource_type
      from imsld_cp_resourcesi cpr, imsld_itemsi ii,
      acs_rels ar
      where ar.object_id_one = ii.item_id
      and ar.object_id_two = cpr.item_id
      and content_revision__is_live(cpr.resource_id) = 't'
      and ii.imsld_item_id = :imsld_item_id
    </querytext>
  </fullquery>

</queryset>
