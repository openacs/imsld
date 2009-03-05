<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Derick Leony (derick@inv.it.uc3m.es) -->
<!-- @creation-date 2009-02-06 -->
<!-- @arch-tag: /bin/bash: uuidgen: command not found -->
<!-- @cvs-id $Id$ -->

<queryset>
  <fullquery name="item_linear_list">
    <querytext>
      
      select ii.imsld_item_id
      from imsld_items ii, imsld_activity_descs lad, imsld_learning_activitiesi la,
      cr_items cr1, cr_items cr2,
      acs_rels ar
      where la.item_id = :activity_item_id
      and content_revision__is_live(la.activity_id)
      and la.activity_description_id = cr1.item_id
      and cr1.live_revision = lad.description_id
      and ar.object_id_one = la.activity_description_id
      and ar.object_id_two = cr2.item_id
      and cr2.live_revision = ii.imsld_item_id
      
    </querytext>
  </fullquery>
    
  <fullquery name="la_nested_associated_items">
    <querytext>
      
      select icr.resource_id,
      cp.item_id as resource_item_id,
      icr.type as resource_type
      from imsld_cp_resources icr, imsld_items ii,
--      imsld_attribute_instances iai,
      cr_items ci, cr_items cp,
      acs_rels ar
      where ii.imsld_item_id = ci.live_revision
      and   ar.object_id_one = ci.item_id
      and   icr.resource_id = cp.live_revision
      and   ar.object_id_two = cp.item_id
      and   content_revision__is_live(icr.resource_id) = 't'
      and   (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
      and   tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
      or    ii.imsld_item_id = :imsld_item_id)
--      and   iai.owner_id = ii.imsld_item_id
--      and   iai.run_id = :run_id
--      and   iai.user_id = :user_id
--      and   iai.type = 'isvisible'
--      and   iai.is_visible_p = 't'
      
    </querytext>
  </fullquery>
  
</queryset>
