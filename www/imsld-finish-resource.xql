<?xml version="1.0"?>
<queryset>



	<fullquery name="get_resource_id">
		<querytext>
    select resource_id
    from imsld_cp_resourcesi
    where item_id=:resource_item_id
		</querytext>
	</fullquery>


	<fullquery name="is_feedback">
		<querytext>
 select 1  
                            from acs_rels ar1,
                                 acs_rels ar2,
                                 imsld_feedback_rel_ext ifre 
                            where ifre.rel_id=ar1.rel_id and 
                                  ar1.object_id_two=ar2.object_id_one and 
                                  ar2.object_id_two=:resource_item_id 
    
		</querytext>
	</fullquery>


	<fullquery name="prerequisites_list">
		<querytext>
        select prerequisite_id
        from imsld_imslds
    
		</querytext>
	</fullquery>


	<fullquery name="objectives_list">
		<querytext>
        select learning_objective_id
        from imsld_imslds
    
		</querytext>
	</fullquery>

	<fullquery name="is_assessment">
		<querytext>
        select count(*)
        from imsld_cp_resources
        where resource_id=:resource_id and
              type='imsqti_xmlv1p0'
		</querytext>
	</fullquery>

	<fullquery name="get_identifier_resource_id">
		<querytext>
            select ar1.object_id_one as identifier 
            from acs_rels ar1, 
                 acs_rels ar2 
            where ar1.object_id_two=ar2.object_id_one 
                 and ar2.object_id_two=:resource_item_id;
    
		</querytext>
	</fullquery>
</queryset>

