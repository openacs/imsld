<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Derick Leony (derick@inv.it.uc3m.es) -->
<!-- @creation-date 2008-12-02 -->
<!-- @arch-tag:  -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <fullquery name="select_imsld_info">
    <querytext>
      select imsld_id
      from imsld_runs
      where run_id = :run_id
    </querytext>
  </fullquery>

  <fullquery name="select_parent_group">
    <querytext>
      select object_id_one as group_id
      from acs_rels ar
      where ar.rel_type = 'composition_rel'
      and ar.object_id_two = :group_id
    </querytext>
  </fullquery>

</queryset>
