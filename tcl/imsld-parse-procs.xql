<?xml version="1.0"?>
<queryset>



	<fullquery name="imsld::parse::parse_and_create_resource.redundancy_protection">
		<querytext>
        select item_id as resource_id 
        from imsld_cp_resourcesi
        where identifier = :resource_identifier
        and manifest_id = :manifest_id
    
		</querytext>
	</fullquery>

    <fullquery name="imsld::parse::parse_and_create_forum.get_allowed_parties">
		<querytext>
        select aopp.party_id 
        from acs_object_party_privilege_map aopp,
             party_names pn 
        where aopp.privilege='read' and 
              aopp.party_id=pn.party_id and 
              aopp.object_id=:acs_object_id
		</querytext>
	</fullquery>

    <fullquery name="imsld::parse::parse_and_create_resource.get_allowed_parties">
		<querytext>
        select aopp.party_id 
        from acs_object_party_privilege_map aopp,
             party_names pn 
        where aopp.privilege='read' and 
              aopp.party_id=pn.party_id and 
              aopp.object_id=:acs_object_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_service.get_component_id">
		<querytext>
        select env.component_id
        from imsld_environmentsi env
        where content_revision__is_live(env.environment_id) = 't'
        and env.item_id = :environment_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_service.get_role_id_from_ref">
		<querytext>
                select ir.item_id as role_id
                from imsld_rolesi ir
                where ir.identifier = :ref 
                and content_revision__is_live(ir.role_id) = 't' 
                and ir.component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_service.get_role_id_from_role_ref">
		<querytext>
                select item_id as role_item_id 
                from imsld_rolesi 
                where identifier = :role_ref 
                and content_revision__is_live(role_id) = 't' 
                and component_id = :component_id 
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_environment.get_env_id">
		<querytext>
                select item_id as refrenced_env_id 
                from imsld_environmentsi 
                where identifier = :ref 
                and content_revision__is_live(environment_id) = 't' 
                and component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_learning_activity.get_environment_id">
		<querytext>
                select item_id as environment_id
                from imsld_environmentsi
                where identifier = :environment_ref 
                and content_revision__is_live(environment_id) = 't' and 
                component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_support_activity.get_role_id">
		<querytext>
            select item_id as role_id 
            from imsld_rolesi 
            where identifier = :ref 
            and content_revision__is_live(role_id) = 't' 
            and component_id = :component_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_support_activity.get_environment_id">
		<querytext>
                select item_id as environment_id
                from imsld_environmentsi 
                where identifier = :environment_ref 
                and content_revision__is_live(environment_id) = 't' 
                and component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.get_environment_id">
		<querytext>
                select item_id as environment_id 
                from imsld_environmentsi
                where identifier = :environment_ref 
                and content_revision__is_live(environment_id) = 't' 
                and component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.get_learning_activity_id">
		<querytext>
                select item_id as activity_id,
                activity_id as learning_activity_id
                from imsld_learning_activitiesi
                where identifier = :learning_activity_ref 
                and content_revision__is_live(activity_id) = 't' 
                and component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.get_learning_support_activity_id">
		<querytext>
                    select item_id as activity_id,
                    activity_id as support_activity_id
                    from imsld_support_activitiesi
                    where identifier = :learning_activity_ref 
                    and content_revision__is_live(activity_id) = 't' 
                    and component_id = :component_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.get_struct_id_from_as_ref">
		<querytext>
                        select item_id as refrenced_struct_id,
                        structure_id
                        from imsld_activity_structuresi 
                        where identifier = :ref 
                        and content_revision__is_live(structure_id) = 't' 
                        and component_id = :component_id
                    
		</querytext>
	</fullquery>

	<fullquery name="imsld::parse::parse_and_create_activity_structure.get_struct_id_from_la_ref">
		<querytext>
                        select item_id as refrenced_struct_id,
                        structure_id
                        from imsld_activity_structuresi 
                        where identifier = :learning_activity_ref 
                        and content_revision__is_live(structure_id) = 't' 
                        and component_id = :component_id
                    
		</querytext>
	</fullquery>

	<fullquery name="imsld::parse::parse_and_create_activity_structure.get_struct_id_from_sa_ref">
		<querytext>
                        select item_id as refrenced_struct_id,
                        structure_id
                        from imsld_activity_structuresi 
                        where identifier = :support_activity_ref
                        and content_revision__is_live(structure_id) = 't' 
                        and component_id = :component_id
                    
		</querytext>
	</fullquery>

	<fullquery name="imsld::parse::parse_and_create_activity_structure.update_activity_structure_from_structure_id">
		<querytext>
                            update imsld_activity_structures
                            set sort_order = :sort_order
                            where structure_id = :structure_id
                        
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.update_activity_structure_from_activity_structure_ref_id">
		<querytext>
                                update imsld_activity_structures
                                set sort_order = :sort_order
                                where structure_id = (select live_revision from cr_items where item_id = :activity_structure_ref_id)
                            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.update_support_activity">
		<querytext>
                        update imsld_support_activities
                        set sort_order = :sort_order
                        where activity_id = :support_activity_id
                    
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.update_learning_activity">
		<querytext>
                    update imsld_learning_activities
                    set sort_order = :sort_order
                    where activity_id = :learning_activity_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.get_support_activity_id">
		<querytext>
                select item_id as activity_id,
                activity_id as support_activity_id
                from imsld_support_activitiesi 
                where identifier = :support_activity_ref 
                and content_revision__is_live(activity_id) ='t' 
                and component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_activity_structure.get_support_learning_activity_id">
		<querytext>
                    select item_id as activity_id,
                    activity_id as learning_activity_id
                    from imsld_learning_activitiesi
                    where identifier = :support_activity_ref 
                    and content_revision__is_live(activity_id) = 't' 
                    and component_id = :component_id
                
		</querytext>
	</fullquery>





	<fullquery name="imsld::parse::parse_and_create_role_part.get_component_id">
		<querytext>
        select cr4.item_id as component_id 
        from imsld_components ic, imsld_methods im, imsld_plays ip, imsld_acts ia,
        cr_revisions cr0, cr_revisions cr1, cr_revisions cr2, cr_revisions cr3, cr_revisions cr4
        where cr4.revision_id = ic.component_id
        and content_revision__is_live(ic.component_id) = 't'
        and ic.imsld_id = cr3.item_id
        and content_revision__is_live(cr3.revision_id) = 't'
        and cr3.item_id = im.imsld_id
        and im.method_id = cr2.revision_id
        and cr2.item_id = ip.method_id
        and ip.play_id = cr1.revision_id
        and cr1.item_id = ia.play_id
        and ia.act_id = cr0.revision_id
        and cr0.item_id = :act_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_role_id">
		<querytext>
            select ir.item_id as role_id
            from imsld_rolesi ir
            where ir.identifier = :role_ref_ref 
            and content_revision__is_live(ir.role_id) = 't' 
            and ir.component_id = :component_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_learning_activity_id">
		<querytext>
            select la.item_id as learning_activity_id
            from imsld_learning_activitiesi la
            where la.identifier = :learning_activity_ref_ref 
            and content_revision__is_live(la.activity_id) = 't' 
            and la.component_id = :component_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_learning_support_activity_id">
		<querytext>
                select item_id as support_activity_id 
                from imsld_support_activitiesi
                where identifier = :learning_activity_ref_ref 
                and content_revision__is_live(activity_id) = 't' 
                and component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_learning_activity_struct_id">
		<querytext>
                    select item_id as activity_structure_id 
                    from imsld_activity_structuresi
                    where identifier = :learning_activity_ref_ref 
                    and content_revision__is_live(structure_id) = 't' 
                    and component_id = :component_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_support_activity_id">
		<querytext>
            select sa.item_id as support_activity_id 
            from imsld_support_activitiesi sa
            where sa.identifier = :support_activity_ref_ref 
            and content_revision__is_live(sa.activity_id) = 't' 
            and sa.component_id = :component_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_support_learning_activity_id">
		<querytext>
                select item_id as learning_activity_id 
                from imsld_learning_activitiesi
                where identifier = :support_activity_ref_ref 
                and content_revision__is_live(activity_id) = 't' 
                and component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_support_activity_struct_id">
		<querytext>
                    select item_id as activity_structure_id 
                    from imsld_activity_structuresi
                    where identifier = :support_activity_ref_ref 
                    and content_revision__is_live(structure_id) = 't' 
                    and component_id = :component_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_activity_structure_id">
		<querytext>
            select ias.item_id as activity_structure_id 
            from imsld_activity_structuresi ias
            where ias.identifier = :activity_structure_ref_ref 
            and content_revision__is_live(ias.structure_id) = 't' 
            and ias.component_id = :component_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_struct_learning_activity_id">
		<querytext>
                select item_id as learning_activity_id 
                from imsld_learning_activitiesi
                where identifier = :activity_structure_ref_ref 
                and content_revision__is_live(activity_id) = 't' 
                and component_id = :component_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_struct_support_activity_id">
		<querytext>
                    select item_id as support_activity_id 
                    from imsld_support_activitiesi
                    where identifier = :activity_structure_ref_ref 
                    and content_revision__is_live(activity_id) = 't' 
                    and component_id = :component_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_role_part.get_env_id">
		<querytext>
            select env.item_id as environment_id 
            from imsld_environmentsi env
            where env.identifier = :environment_ref_ref 
            and content_revision__is_live(env.environment_id) = 't' 
            and env.component_id = :component_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_act.get_rp_id">
		<querytext>
                select item_id as role_part_id 
                from imsld_role_partsi 
                where identifier = :ref 
                and content_revision__is_live(role_part_id) = 't' 
                and act_id = :act_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_imsld_manifest.get_rp_id">
		<querytext>
                select item_id as play_id 
                from imsld_playsi 
                where identifier = :ref 
                and content_revision__is_live(play_id) = 't' 
                and method_id = :method_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::parse::parse_and_create_imsld_manifest.already_created_p">
		<querytext>
            select 1 from imsld_cp_resources where identifier = :resource_identifier and manifest_id = :manifest_id
        
		</querytext>
	</fullquery>
</queryset>

