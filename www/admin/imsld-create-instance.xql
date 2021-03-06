<?xml version="1.0"?>
<queryset>
	<fullquery name="get_imsld_role_info">
		<querytext>
        select max_persons,min_persons,create_new_p,match_persons_p
        from imsld_roles
        where role_id=:role
		</querytext>
	</fullquery>

	<fullquery name="get_related_groups">
		<querytext>
        select ar.object_id_two as groups
        from acs_rels ar,
             acs_rels ar2,
             imsld_rolesi iri
        where ar.object_id_one=iri.item_id
              and iri.role_id=:role
              and ar.rel_type='imsld_role_group_rel'
              and ar.object_id_two=ar2.object_id_one
              and ar2.rel_type='imsld_roleinstance_run_rel'
              and ar2.object_id_two=:run_id
		</querytext>
	</fullquery>
	<fullquery name="get_possible_parents_list">
		<querytext>
        select g.group_name as parent_name,
               g.group_id as parent_id
        from groups g,
             imsld_rolesi iri,
             acs_rels ar,
             acs_rels ar2,
             imsld_run_users_group_ext iruge
        where iri.role_id=:role
              and ar.object_id_one=iri.parent_role_id 
              and ar.rel_type='imsld_role_group_rel' 
              and g.group_id=ar.object_id_two
              and ar2.rel_type='imsld_roleinstance_run_rel'
              and ar2.object_id_one=g.group_id
              and ar2.object_id_two=iruge.group_id
              and iruge.run_id=:run_id
        </querytext>
	</fullquery>

	<fullquery name="has_role_parent_p">
		<querytext>
            select role_id
            from imsld_roles
            where role_id=:role
                  and parent_role_id>0
        </querytext>
	</fullquery>

    
</queryset>

