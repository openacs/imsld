<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Derick Leony (derick@inv.it.uc3m.es) -->
<!-- @creation-date 2009-02-06 -->
<!-- @arch-tag: /bin/bash: uuidgen: command not found -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="get_resource_info">
    <querytext>

      select identifier,
      resource_id,
      type as resource_type,
      title as resource_title,
      acs_object_id
      from imsld_cp_resourcesi 
      where item_id = :resource_item_id 
      and content_revision__is_live(resource_id) = 't'
      
    </querytext>
  </fullquery>


  <fullquery name="is_cr_item">
    <querytext>
      select live_revision from cr_items where item_id = :acs_object_id
      
    </querytext>
  </fullquery>


  <fullquery name="get_cr_info">
    <querytext>
      
      select acs_object__name(object_id) as object_title, object_type
      from acs_objects where object_id = :live_revision
      
    </querytext>
  </fullquery>


  <fullquery name="get_ao_info">
    <querytext>
      
      select acs_object__name(object_id) as object_title, object_type
      from acs_objects where object_id = :acs_object_id
      
    </querytext>
  </fullquery>


  <fullquery name="associated_files">
    <querytext>

      select cr.revision_id as imsld_file_id,
      cpf.file_name,
      cpf.item_id, 
      cpf.parent_id
      from imsld_cp_filesx cpf,
      acs_rels ar, imsld_res_files_rels map,
      cr_revisions cr
      where ar.object_id_one = :resource_item_id
      and ar.object_id_two = cpf.item_id
      and cpf.item_id = cr.item_id
      and ar.rel_id = map.rel_id
      and content_revision__is_live(cr.revision_id) = 't'
      and map.displayable_p = 't'

    </querytext>
  </fullquery>


  <fullquery name="associated_xo_files">
    <querytext>

      select ci.item_id as page_id, ci.name as file_name
      from acs_rels ar, imsld_res_files_rels map,
      cr_revisions cr, cr_items ci
      where ar.object_id_one = :resource_item_id
      and ar.object_id_two = cr.item_id
      and cr.item_id = ci.item_id
      and ar.rel_id = map.rel_id
      and content_revision__is_live(cr.revision_id) = 't'
      and map.displayable_p = 't'

    </querytext>
  </fullquery>


  <fullquery name="get_folder_path">
    <querytext>
      select content_item__get_path(:parent_id,:root_folder_id); 
    </querytext>
  </fullquery>


  <fullquery name="get_fs_file_url">
    <querytext>

      select 
      case 
      when :folder_path is null
      then fs.file_upload_name
      else :folder_path || '/' || fs.file_upload_name
      end as file_url
      from fs_objects fs
      where fs.live_revision = :imsld_file_id

    </querytext>
  </fullquery>


  <fullquery name="associated_urls">
    <querytext>

      select url
      from acs_rels ar,
      cr_extlinks links,
      imsld_res_files_rels map
      where ar.object_id_one = :resource_item_id
      and ar.object_id_two = links.extlink_id
      and ar.rel_id = map.rel_id
      and map.displayable_p = 't'
      
    </querytext>
  </fullquery>

</queryset>
