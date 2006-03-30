<?xml version="1.0"?>
 <queryset>
    <fullquery name="other_subroles_members">
		<querytext>
        select gmm.member_id 
        from imsld_roles ir1, 
             imsld_rolesi ir2,
             acs_rels ar,
             group_member_map gmm 
        where ir1.role_id=:role and 
              ir1.parent_role_id=ir2.parent_role_id and 
              ir2.role_id!=ir1.role_id and 
              ar.object_id_one=ir2.item_id and 
              ar.rel_type='imsld_role_group_rel' and 
              gmm.group_id=ar.object_id_two and
              member_id in ([join $members_list ","])
        group by member_id
        </querytext>
	</fullquery>
</queryset>

