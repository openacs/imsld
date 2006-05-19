<?xml version="1.0"?>
<queryset>
	<fullquery name="get_groups_list">
		<querytext>
         select gr.group_id,
                gr.group_name
         from groups gr, 
              acs_rels ar, 
              imsld_run_users_group_ext iruge 
         where ar.rel_type='imsld_roleinstance_run_rel' 
               and ar.object_id_one=gr.group_id 
               and ar.object_id_two=iruge.group_id 
               and iruge.run_id=:run_id
               and  group_name like ('%' || :role || '%')
		</querytext>
	</fullquery>
</queryset>
