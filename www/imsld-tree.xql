<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Derick Leony (derick@inv.it.uc3m.es) -->
<!-- @creation-date 2009-01-08 -->
<!-- @arch-tag: /bin/bash: uuidgen: command not found -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <fullquery name="generated_activities_p">
    <querytext>
      select count(*)
      from imsld_runtime_activities_rels
      where role_id = :current_role_id
      and run_id = :run_id
    </querytext>
  </fullquery>
    
</queryset>
