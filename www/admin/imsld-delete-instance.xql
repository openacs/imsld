<?xml version="1.0"?>
<queryset>
	<fullquery name="get_rel_id">
		<querytext>
        select ar.rel_id 
        from acs_rels ar,
             imsld_rolesi iri
        where ar.object_id_one=iri.item_id
              and iri.role_id=:role
              and object_id_two=:group_id
              and rel_type='imsld_role_group_rel'
		</querytext>
	</fullquery>

</queryset>

