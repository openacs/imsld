<?xml version="1.0"?>
<queryset>
	<fullquery name="get_groups_list">
		<querytext>
        select gr.group_id, 
               gr.group_name 
        from groups gr, 
             acs_rels ar1, 
             acs_rels ar2, 
             imsld_run_users_group_ext iruge, 
             imsld_rolesi iri 
        where ar1.rel_type='imsld_roleinstance_run_rel' 
              and ar1.object_id_one=gr.group_id 
              and ar1.object_id_two=iruge.group_id 
              and iruge.run_id=:run_id
              and iri.role_id=:role
              and iri.item_id=ar2.object_id_one 
              and ar2.rel_type='imsld_role_group_rel' 
              and ar2.object_id_two=gr.group_id
		</querytext>
	</fullquery>
</queryset>
