<?xml version="1.0"?>
<queryset>



	<fullquery name="imsld::community_id_from_manifest_id.get_community_id">
		<querytext>
        select dc.community_id
        from imsld_cp_manifestsi im, dotlrn_communities dc, acs_objects ao, acs_objects ao2
        where im.item_id = ao.object_id 
        and ao.context_id = ao2.object_id
        and ao2.context_id = dc.package_id
        and im.manifest_id = :manifest_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::sweep_expired_activities.possible_expired_method">
		<querytext>
        select icm.manifest_id,
        ii.imsld_id,
        im.method_id,
        ir.run_id,
        ca.time_in_seconds,
        ao.creation_date
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_complete_actsi ca, imsld_runs ir, acs_objects ao
        where im.imsld_id = ii.item_id
        and ii.imsld_id = ir.imsld_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and im.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and ao.object_id = ir.run_id
        and content_revision__is_live(ii.imsld_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::sweep_expired_activities.compre_times">
		<querytext>
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::sweep_expired_activities.user_in_run">
		<querytext>
        select u.user_id
        from users u,
             acs_rels ar,
             imsld_run_users_group_ext r_map
        where u.user_id > 0
              and u.user_id=ar.object_id_two
              and ar.object_id_one = r_map.group_id
              and r_map.run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::sweep_expired_activities.possible_expired_plays">
		<querytext>
        select icm.manifest_id,
        ii.imsld_id,
        ip.play_id,
        ca.time_in_seconds,
        ao.creation_date,
        ir.run_id
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_plays ip,
        imsld_complete_actsi ca, imsld_runs ir, acs_objects ao
        where ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and ip.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and ao.object_id = ir.run_id
        and content_revision__is_live(ii.imsld_id) = 't'
        and ii.imsld_id = ir.imsld_id    

		</querytext>
	</fullquery>

	<fullquery name="imsld::sweep_expired_activities.possible_expired_acts">
		<querytext>
        select icm.manifest_id,
        ii.imsld_id,
        ip.play_id,
        ia.act_id,
        ca.time_in_seconds,
        icm.creation_date,
        ir.run_id
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, imsld_acts ia,
        imsld_complete_actsi ca, imsld_runs ir, acs_objects ao
        where ia.play_id = ip.item_id
        and ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and ia.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and ao.object_id = ir.run_id
        and content_revision__is_live(ii.imsld_id) = 't'
        and ii.imsld_id = ir.imsld_id    

		</querytext>
	</fullquery>

	<fullquery name="imsld::sweep_expired_activities.referenced_sas">
		<querytext>
        select sa.item_id as sa_item_id,
        sa.activity_id,
        ca.time_in_seconds
        from imsld_support_activitiesi sa,
        imsld_complete_actsi ca
        where sa.complete_act_id = ca.item_id
        and content_revision__is_live(ca.complete_act_id) = 't'
        and ca.time_in_seconds is not null
    
		</querytext>
	</fullquery>

	<fullquery name="imsld::sweep_expired_activities.sa_referencer">
		<querytext>
            select icm.manifest_id,
            irp.role_part_id,
            ii.imsld_id,
            ip.play_id,
            ia.act_id,
            ao.creation_date,
            ir.run_id
            from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
            imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, 
            imsld_actsi ia, imsld_role_partsi irp, imsld_runs ir, acs_objects ao
            where irp.support_activity_id = :sa_item_id
            and irp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and ip.method_id = im.item_id
            and im.imsld_id = ii.item_id
            and ii.organization_id = ico.item_id
            and ii.imsld_id = ir.imsld_id
            and ao.object_id = ir.run_id
            and ico.manifest_id = icm.item_id
            and content_revision__is_live(ii.imsld_id) = 't'

		</querytext>
	</fullquery>

	<fullquery name="imsld::sweep_expired_activities.referenced_las">
		<querytext>
        select la.item_id as la_item_id,
        la.activity_id,
        ca.time_in_seconds
        from imsld_learning_activitiesi la,
        imsld_complete_actsi ca
        where la.complete_act_id = ca.item_id
        and content_revision__is_live(ca.complete_act_id) = 't'
        and ca.time_in_seconds is not null
    
		</querytext>
	</fullquery>

	<fullquery name="imsld::sweep_expired_activities.la_referencer">
		<querytext>

            select icm.manifest_id,
            irp.role_part_id,
            ii.imsld_id,
            ip.play_id,
            ia.act_id,
            ao.creation_date,
            ir.run_id
            from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
            imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, 
            imsld_actsi ia, imsld_role_partsi irp, imsld_runs ir, acs_objects ao
            where irp.role_part_id = :role_part_id
            and irp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and ip.method_id = im.item_id
            and im.imsld_id = ii.item_id
            and ii.organization_id = ico.item_id
            and ii.imsld_id = ir.imsld_id
            and ao.object_id = ir.run_id
            and ico.manifest_id = icm.item_id
            and content_revision__is_live(ii.imsld_id) = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_role_part_finished.role_part_info">
		<querytext>
        select item_id as role_part_item_id
        from imsld_role_partsi
        where role_part_id = :role_part_id
    
		</querytext>
	</fullquery>

	<fullquery name="imsld::mark_role_part_finished.marked_as_started">
		<querytext>

        select 1
        from imsld_status_user
        where run_id = :run_id
        and user_id = :user_id
        and status = 'started'
        and act_id = :act_id
        and related_id = :role_part_id
            
		</querytext>
	</fullquery>

	<fullquery name="imsld::mark_role_part_finished.mark_role_part_started">
		<querytext>

            insert into imsld_status_user (imsld_id,
                                           run_id,
                                           play_id,
                                           act_id,
                                           related_id,
                                           user_id,
                                           type,
                                           status_date,
                                           status) 
            (
             select :imsld_id,
             :run_id,
             :play_id,
             :act_id,
             :role_part_id,
             :user_id,
             'act',
             now(),
             'started'
             where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :role_part_id and status = 'started')
             )
            
		</querytext>
	</fullquery>

	<fullquery name="imsld::mark_role_part_finished.insert_role_part">
		<querytext>
        insert into imsld_status_user (imsld_id,
                                       run_id,
                                       play_id,
                                       act_id,
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :run_id,
         :play_id,
         :act_id,
         :role_part_id,
         :user_id,
         'act',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :role_part_id and status = 'finished')
         )
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_role_part_finished.role_part_activity">
		<querytext>
        select case
        when learning_activity_id is not null
        then 'learning'
        when support_activity_id is not null
        then 'support'
        when activity_structure_id is not null
        then 'structure'
        else 'none'
        end as type,
        content_item__get_live_revision(coalesce(learning_activity_id,support_activity_id,activity_structure_id)) as activity_id,
        coalesce(learning_activity_id, support_activity_id, activity_structure_id) as activity_item_id
        from imsld_role_parts
        where role_part_id = :role_part_id

		</querytext>
	</fullquery>

    <fullquery name="imsld::grant_permissions.is_forum">
		<querytext>
        select 1 
        from forums_forums ff 
        where ff.forum_id=:the_object_id 
		</querytext>
	</fullquery>

	<fullquery name="imsld::grant_permissions.get_object_from_resource">
		<querytext>
        select acs_object_id as the_object_id
        from imsld_cp_resourcesi
        where item_id = :the_resource_id and 
              acs_object_id is not null

		</querytext>
	</fullquery>

	<fullquery name="imsld::grant_permissions.get_cr_item_from_resource">
		<querytext>
            select ar.object_id_two as related_cr_items 
            from acs_rels ar 
            where ar.object_id_one=:the_resource_id and
                  ar.rel_type='imsld_res_files_rel'
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_act_finished.act_info">
		<querytext>
        select item_id as act_item_id
        from imsld_actsi
        where act_id = :act_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_act_finished.insert_act">
		<querytext>
        insert into imsld_status_user (imsld_id,
                                       run_id,
                                       play_id,
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :run_id,
         :play_id,
         :act_id,
         :user_id,
         'act',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :act_id and status = 'finished')
         )
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_act_finished.referenced_role_part">
		<querytext>
        select rp.role_part_id
        from imsld_role_parts rp, imsld_actsi ia
        where rp.act_id = ia.item_id
        and ia.act_id = :act_id
        and content_revision__is_live(rp.role_part_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_play_finished.insert_play">
		<querytext>
        insert into imsld_status_user (imsld_id,
                                       run_id,
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :run_id,
         :play_id,
         :user_id,
         'play',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :play_id and status = 'finished')
         )
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_play_finished.referenced_act">
		<querytext>
        select ia.act_id
        from imsld_acts ia, imsld_playsi ip
        where ia.play_id = ip.item_id
        and ip.play_id = :play_id
        and content_revision__is_live(ia.act_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_imsld_finished.insert_uol">
		<querytext>
        insert into imsld_status_user (imsld_id,
                                       run_id,
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :run_id,
         :imsld_id,
         :user_id,
         'play',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :imsld_id and status = 'finished')
         )
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_imsld_finished.referenced_plays">
		<querytext>
        select ip.play_id
        from imsld_plays ip, imsld_methodsi im, imsld_imsldsi ii
        where ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.imsld_id = :imsld_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_method_finished.insert_method">
		<querytext>
        insert into imsld_status_user (imsld_id,
                                       run_id,
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :run_id,
         :method_id,
         :user_id,
         'method',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :method_id and status = 'finished')
         )
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_method_finished.referenced_plays">
		<querytext>
        select ip.play_id
        from imsld_plays ip, imsld_methodsi im
        where ip.method_id = im.item_id
        and im.method_id = :method_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::rel_type_delete.select_type_info">
		<querytext>
        select t.table_name 
        from acs_object_types t
        where t.object_type = :rel_type
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::rel_type_delete.select_rel_ids">
		<querytext>
        select r.rel_id
        from acs_rels r
        where r.rel_type = :rel_type
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::rel_type_delete.drop_relationship_type">
		<querytext>
            BEGIN
            acs_rel_type.drop_type( rel_type  => :rel_type,
                                    cascade_p => 't' );
            END;
        
		</querytext>
	</fullquery>

    <fullquery name="imsld::finish_component_element.marked_as_started">
		<querytext>

        select 1
        from imsld_status_user
        where run_id = :run_id
        and user_id = :user_id
        and status = 'started'
        and related_id = :element_id
        and imsld_id = :imsld_id
        and play_id = :play_id
        and role_part_id = :role_part_id
                
		</querytext>
	</fullquery>

    <fullquery name="imsld::finish_component_element.mark_element_started">
		<querytext>


            insert into imsld_status_user (
                                           imsld_id,
                                           run_id,
                                           play_id,
                                           act_id,
                                           role_part_id,
                                           related_id,
                                           user_id,
                                           type,
                                           status_date,
                                           status
                                           )
            (
             select :imsld_id,
             :run_id,
             :play_id,
             :act_id,
             :role_part_id,
             :element_id,
             :user_id,
             :type,
             now(),
             'started'
             where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :element_id and status = 'started')
             )
        
		</querytext>
	</fullquery>

    <fullquery name="imsld::finish_component_element.get_related_on_completion_id">
		<querytext>
            select on_completion_id as related_on_completion
            from $table_name
            where $element_name=:element_id and 
                  on_completion_id is not null
            
		</querytext>
	</fullquery>

    <fullquery name="imsld::finish_component_element.get_related_resource_id">
		<querytext>
         select ar2.object_id_two as related_resource
         from acs_rels ar1,
              acs_rels ar2 
         where ar2.object_id_one=ar1.object_id_two and 
               ar2.rel_type='imsld_item_res_rel' and 
               ar1.rel_type='imsld_feedback_rel' and  
               ar1.object_id_one=:related_on_completion
  		</querytext>
	</fullquery>

    <fullquery name="imsld::finish_component_element.insert_element_entry">
		<querytext>
                insert into imsld_status_user (
                                                imsld_id,
                                                run_id,
                                                play_id,
                                                act_id,
                                                role_part_id,
                                                related_id,
                                                user_id,
                                                type,
                                                status_date,
                                                status
                                               )
                                               (
                                       select :imsld_id,
                                       :run_id,
                                       :play_id,
                                       :act_id,
                                       :role_part_id,
                                       :element_id,
                                       :user_id,
                                       :type,
                                       now(),
                                       'finished'
                                       where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :element_id and status = 'finished')
                                       )
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.referencer_structure">
		<querytext>
            select ias.structure_id,
            ias.item_id as structure_item_id,
            ias.number_to_select
            from acs_rels ar, imsld_activity_structuresi ias, cr_items cri
            where ar.object_id_one = ias.item_id
            and ar.object_id_two = cri.item_id
            and cri.live_revision = :element_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.referenced_activity">
		<querytext>
                select content_item__get_live_revision(ar.object_id_two) as activity_id
                from acs_rels ar
                where ar.object_id_one = :structure_item_id
                and ar.rel_type in ('imsld_as_la_rel','imsld_as_sa_rel','imsld_as_as_rel')
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.completed_p">
		<querytext>
                    select count(*) from imsld_status_user 
                    where related_id = :activity_id
                    and user_id = :user_id
                    and status = 'finished'
                    and run_id = :run_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.already_marked_p">
		<querytext>
        select 1 from imsld_status_user 
        where related_id = :role_part_id 
        and user_id = :user_id 
        and status = 'finished'
        and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.get_role_part_info">
		<querytext>
            select ii.imsld_id,
            ip.play_id,
            ip.item_id as play_item_id,
            ia.act_id,
            ia.item_id as act_item_id,
            ica.when_last_act_completed_p,
            im.method_id,
            im.item_id as method_item_id
            from imsld_imsldsi ii, imsld_actsi ia, imsld_role_parts irp, 
               imsld_methodsi im, imsld_playsi ip left outer join imsld_complete_actsi ica on (ip.complete_act_id = ica.item_id)
            where irp.role_part_id = :role_part_id
            and irp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and ip.method_id = im.item_id
            and im.imsld_id = ii.item_id
            and content_revision__is_live(ii.imsld_id) = 't';
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.referenced_role_part">
		<querytext>
            select ar.object_id_two as role_part_item_id,
            rp.role_part_id
            from acs_rels ar, imsld_role_partsi rp
            where ar.object_id_one = :act_item_id
            and rp.item_id = ar.object_id_two
            and ar.rel_type = 'imsld_act_rp_completed_rel'
            and content_revision__is_live(rp.role_part_id) = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.directly_referenced_role_part">
		<querytext>

            select irp.role_part_id 
            from imsld_role_parts irp,
                 imsld_rolesi iri 
            where content_revision__is_live(irp.role_part_id)='t' 
                  and irp.act_id=:act_item_id 
                  and irp.role_id=iri.item_id 
                  and iri.role_id in ([join $user_roles_list ","])
	</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.referenced_act">
		<querytext>
                select ia.act_id
                from imsld_acts ia, imsld_playsi ip
                where ia.play_id = :play_item_id
                and ip.item_id = ia.play_id
                and content_revision__is_live(ia.act_id) = 't'
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.referenced_play">
		<querytext>
                    select ip.play_id
                    from acs_rels ar, imsld_playsi ip
                    where ar.object_id_one = :method_item_id
                    and ip.item_id = ar.object_id_two
                    and ar.rel_type = 'imsld_mp_completed_rel'
                    and content_revision__is_live(ip.play_id) = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.directly_referenced_plays">
		<querytext>
                        select ip.play_id
                        from imsld_plays ip
                        where ip.method_id = :method_item_id
                        and content_revision__is_live(ip.play_id) = 't'
                    
		</querytext>
	</fullquery>


	<fullquery name="imsld::structure_next_activity.struct_referenced_activities">
		<querytext>
        select ar.object_id_two,
        ar.rel_type,
        ar.rel_id
        from acs_rels ar, imsld_activity_structuresi ias
        where ar.object_id_one = ias.item_id
        and ias.structure_id = :activity_structure_id
        order by ar.object_id_two
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::structure_next_activity.get_la_info">
		<querytext>
    
                    select la.activity_id as learning_activity_id
                    from imsld_learning_activitiesi la
                    where la.item_id = :object_id_two
                    and content_revision__is_live(la.activity_id) = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::structure_next_activity.completed_p_from_la">
		<querytext>
                    select count(*)
                    from imsld_status_user
                    where related_id = :learning_activity_id
                    and user_id = :user_id
                    and status = 'finished'
                    and run_id = :run_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::structure_next_activity.get_sa_info">
		<querytext>
                    select activity_id as support_activity_id
                    from imsld_support_activitiesi
                    where item_id = :object_id_two
                    and content_revision__is_live(activity_id) = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::structure_next_activity.completed_p_from_sa">
		<querytext>
                    select count(*)
                    from imsld_status_user
                    where related_id = :support_activity_id
                    and user_id = :user_id
                    and status = 'finished'
                    and run_id = :run_id                
		</querytext>
	</fullquery>


	<fullquery name="imsld::structure_next_activity.get_as_info">
		<querytext>

                    select structure_id, title,
                    item_id
                    from imsld_activity_structuresi
                    where item_id = :object_id_two
                    and content_revision__is_live(structure_id) = 't'
                                
		</querytext>
	</fullquery>


	<fullquery name="imsld::structure_next_activity.completed_p">
		<querytext>
 
                    select count(*)
                    from imsld_status_user 
                    where related_id = :structure_id
                    and user_id = :user_id
                    and status = 'finished'
                    and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::role_part_finished_p.already_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :role_part_id
        and user_id = :user_id
        and status = 'finished'
        and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::role_part_finished_p.get_role_part_activity">
		<querytext>
        select case
        when learning_activity_id is not null
        then 'learning'
        when support_activity_id is not null
        then 'support'
        when activity_structure_id is not null
        then 'structure'
        else 'none'
        end as type,
        learning_activity_id,
        support_activity_id,
        activity_structure_id
        from imsld_role_parts
        where role_part_id = :role_part_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::role_part_finished_p.completed_from_la">
		<querytext>
                select count(*) from imsld_status_user
                where related_id = content_item__get_live_revision(:learning_activity_id)
                and user_id = :user_id
                and status = 'finished'
                and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::role_part_finished_p.completed_from_sa">
		<querytext>
                select count(*) from imsld_status_user
                where related_id = content_item__get_live_revision(:support_activity_id)
                and user_id = :user_id
                and status = 'finished'
                and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::role_part_finished_p.completed_from_as">
		<querytext>
                select count(*) from imsld_status_user
                where related_id = content_item__get_live_revision(:activity_structure_id)
                and user_id = :user_id
                and status = 'finished'
                and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::act_finished_p.already_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :act_id
        and user_id = :user_id
        and status = 'finished'
        and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::play_finished_p.play_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :play_id
        and user_id = :user_id
        and status = 'finished'
        and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::method_finished_p.method_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :method_id
        and user_id = :user_id
        and status = 'finished'
        and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::imsld_finished_p.imsld_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :imsld_id
        and user_id = :user_id
        and status = 'finished'
        and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_service_as_ul.service_info">
		<querytext>

        select serv.service_id,
        serv.identifier,
        serv.service_type,
        serv.title as service_title
        from imsld_servicesi serv
        where serv.item_id = :service_item_id
        and content_revision__is_live(serv.service_id) = 't'
    		</querytext>
	</fullquery>


	<fullquery name="imsld::process_service_as_ul.get_conference_info">
		<querytext>

                select conf.conference_id,
                conf.conference_type,
                conf.imsld_item_id as imsld_item_item_id,
                cr.live_revision as imsld_item_id, 
                conf.title as conf_title
                from imsld_conference_servicesi conf, cr_items cr
                where conf.service_id = :service_item_id
                and cr.item_id = conf.imsld_item_id
                and content_revision__is_live(cr.live_revision) = 't'
                        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_service_as_ul.serv_associated_items">
		<querytext>

                select cpr.resource_id,
                cpr.item_id as resource_item_id,
                cpr.type as resource_type
                from imsld_cp_resourcesi cpr, imsld_itemsi ii,
                acs_rels ar
                where ar.object_id_one = ii.item_id
                and ar.object_id_two = cpr.item_id
                and content_revision__is_live(cpr.resource_id) = 't'
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)

         </querytext>
	</fullquery>

    <fullquery name="imsld::process_service_as_ul.get_send_mail_info">
		<querytext>

                select sm.title as send_mail_title, sm.mail_id as sendmail_id
                from imsld_send_mail_servicesi sm
                where sm.service_id = :service_item_id
                and content_revision__is_live(sm.mail_id) = 't'
            
   		</querytext>
	</fullquery>

	<fullquery name="imsld::process_service_as_ul.monitor_service_info">
		<querytext>

                select ims.title as monitor_service_title,
                ims.monitor_id,
                ims.item_id as monitor_item_id,
                ims.self_p,
                ims.role_id,
                cr.live_revision as imsld_item_id
                from imsld_monitor_servicesi ims, cr_items cr
                where ims.service_id = :service_item_id
                and cr.item_id = ims.imsld_item_id
                and content_revision__is_live(cr.live_revision) = 't'
                        
		</querytext>
	</fullquery>

	<fullquery name="imsld::process_service_as_ul.monitor_associated_items">
		<querytext>

                select cpr.resource_id,
                cpr.item_id as resource_item_id,
                cpr.type as resource_type
                from imsld_cp_resourcesi cpr, imsld_itemsi ii,
                acs_rels ar, imsld_res_files_rels map
                where ar.object_id_one = ii.item_id
                and ar.object_id_two = cpr.item_id
                and content_revision__is_live(cpr.resource_id) = 't'
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)
                and ar.rel_id = map.rel_id
                and map.displayable_p = 't'

         </querytext>
	</fullquery>
    
	<fullquery name="imsld::process_environment_as_ul.environment_info">
		<querytext>

        select env.title as environment_title,
        env.environment_id
        from imsld_environmentsi env
        where env.item_id = :environment_item_id
        and content_revision__is_live(env.environment_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment_as_ul.get_learning_object_info">
		<querytext>

        select lo.item_id as learning_object_item_id,
        lo.learning_object_id,
        lo.identifier,
        coalesce(lo.title,lo.identifier) as lo_title,
        lo.class
        from imsld_learning_objectsi lo, imsld_attribute_instances attr
        where lo.environment_id = :environment_item_id
        and content_revision__is_live(lo.learning_object_id) = 't'
        and attr.owner_id = lo.learning_object_id
        and attr.run_id = :run_id
        and attr.type = 'isvisible'
        and attr.is_visible_p = 't'
        order by lo.creation_date
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment_as_ul.item_linear_list">
		<querytext>
 
            select ii.imsld_item_id
            from imsld_items ii,
            cr_items cr,
            acs_rels ar
            where ar.object_id_one = :learning_object_item_id
            and ar.object_id_two = cr.item_id
            and cr.live_revision = ii.imsld_item_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment_as_ul.env_nested_associated_items">
		<querytext>


                select cpr.resource_id,
                cr2.item_id as resource_item_id,
                cpr.type as resource_type
                from imsld_cp_resources cpr, imsld_items ii, imsld_attribute_instances attr,
                acs_rels ar, cr_items cr1, cr_items cr2
                where ar.object_id_one = cr1.item_id
                and ar.object_id_two = cr2.item_id
                and cr1.live_revision = ii.imsld_item_id
                and cr2.live_revision = cpr.resource_id 
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)
                and attr.owner_id = ii.imsld_item_id
                and attr.run_id = :run_id
                and attr.type = 'isvisible'
                and attr.is_visible_p = 't'
                        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment_as_ul.get_service_info">
		<querytext>

        select ise.service_id,
        ise.item_id as service_item_id,
        ise.identifier,
        ise.service_type,
        ise.title as service_title,
        ise.class
        from imsld_servicesi ise, imsld_attribute_instances attr
        where ise.environment_id = :environment_item_id
        and content_revision__is_live(ise.service_id) = 't'
        and attr.owner_id = ise.service_id
        and attr.run_id = :run_id
        and attr.type = 'isvisible'
        and attr.is_visible_p = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment_as_ul.nested_environment">
		<querytext>

        select ar.object_id_two as nested_environment_item_id
        from acs_rels ar
        where ar.object_id_one = :environment_item_id
        and ar.rel_type = 'imsld_env_env_rel'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective_as_ul.lo_id_from_imsld_item_id">
		<querytext>

            select learning_objective_id as learning_objective_item_id
            from imsld_imsldsi
            where item_id = :imsld_item_id
            and content_revision__is_live(imsld_id) = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective_as_ul.lo_id_from_activity_item_id">
		<querytext>
  
            select learning_objective_id as learning_objective_item_id
            from imsld_learning_activitiesi
            where item_id = :activity_item_id
            and content_revision__is_live(activity_id) = 't'

		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective_as_ul.objective_info">
		<querytext>

        select lo.pretty_title as objective_title,
        lo.learning_objective_id
        from imsld_learning_objectivesi lo
        where lo.item_id = :learning_objective_item_id
        and content_revision__is_live(lo.learning_objective_id) = 't'

   		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective_as_ul.item_linear_list">
		<querytext>

        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :learning_objective_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective_as_ul.lo_nested_associated_items">
		<querytext>

            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii, imsld_attribute_instances attr,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
            and attr.owner_id = ii.imsld_item_id
            and attr.run_id = :run_id
            and attr.type = 'isvisible'
            and attr.is_visible_p = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite_as_ul.lo_id_from_imsld_item_id">
		<querytext>
 
             select prerequisite_id as prerequisite_item_id
            from imsld_imsldsi
            where item_id = :imsld_item_id
            and content_revision__is_live(imsld_id) = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite_as_ul.lo_id_from_activity_item_id">
		<querytext>

            select prerequisite_id as prerequisite_item_id
            from imsld_learning_activitiesi
            where item_id = :activity_item_id
            and content_revision__is_live(activity_id) = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite_as_ul.prerequisite_info">
		<querytext>

        select coalesce(pre.pretty_title, '') as prerequisite_title,
        pre.prerequisite_id
        from imsld_prerequisitesi pre
        where pre.item_id = :prerequisite_item_id
        and content_revision__is_live(pre.prerequisite_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite_as_ul.item_linear_list">
		<querytext>

        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :prerequisite_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite_as_ul.prereq_nested_associated_items">
		<querytext>

            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii, imsld_attribute_instances attr,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
            and attr.owner_id = ii.imsld_item_id
            and attr.run_id = :run_id
            and attr.type = 'isvisible'
            and attr.is_visible_p = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_feedback_as_ul.feedback_info">
		<querytext>

        select coalesce(oc.feedback_title, oc.title) as feedback_title
        from imsld_on_completioni oc
        where oc.item_id = :on_completion_item_id
        and content_revision__is_live(oc.on_completion_id) = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_feedback_as_ul.item_linear_list">
		<querytext>

        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :on_completion_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_feedback_as_ul.feedback_nested_associated_items">
		<querytext>

            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii, imsld_attribute_instances attr,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
            and attr.owner_id = ii.imsld_item_id
            and attr.run_id = :run_id
            and attr.type = 'isvisible'
            and attr.is_visible_p = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource_as_ul.get_resource_info">
		<querytext>

        select identifier,
        type as resource_type,
        title as resource_title,
        acs_object_id
        from imsld_cp_resourcesi 
        where item_id = :resource_item_id 
        and content_revision__is_live(resource_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource_as_ul.is_cr_item">
		<querytext>
            select live_revision from cr_items where item_id = :acs_object_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource_as_ul.get_cr_info">
		<querytext>
 
                select acs_object__name(object_id) as object_title, object_type
                from acs_objects where object_id = :live_revision
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource_as_ul.get_ao_info">
		<querytext>
 
                select acs_object__name(object_id) as object_title, object_type
                from acs_objects where object_id = :acs_object_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource_as_ul.associated_files">
		<querytext>

            select cpf.imsld_file_id,
            cpf.file_name,
            cpf.item_id, 
            cpf.parent_id
            from imsld_cp_filesx cpf,
            acs_rels ar, imsld_res_files_rels map
            where ar.object_id_one = :resource_item_id
            and ar.object_id_two = cpf.item_id
            and ar.rel_id = map.rel_id
            and content_revision__is_live(cpf.imsld_file_id) = 't'
            and map.displayable_p = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource_as_ul.get_folder_path">
		<querytext>
 select content_item__get_path(:parent_id,:root_folder_id); 
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource_as_ul.get_fs_file_url">
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


	<fullquery name="imsld::process_resource_as_ul.associated_urls">
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


	<fullquery name="imsld::process_learning_activity_as_ul.activity_info">
		<querytext>

        select la.on_completion_id as on_completion_item_id,
        la.prerequisite_id as prerequisite_item_id,
        la.learning_objective_id as learning_objective_item_id,
        la.activity_id,
        la.title as activity_title
        from imsld_learning_activitiesi la, imsld_attribute_instances attr
        where la.item_id = :activity_item_id
        and content_revision__is_live(la.activity_id) = 't'
        and attr.owner_id = la.activity_id
        and attr.run_id = :run_id
        and attr.type = 'isvisible'
        and attr.is_visible_p = 't'
        
		</querytext>
	</fullquery>

	<fullquery name="imsld::process_learning_activity_as_ul.item_linear_list">
		<querytext>

        select ii.imsld_item_id
        from imsld_items ii, imsld_activity_descs lad, imsld_learning_activitiesi la,
        cr_items cr1, cr_items cr2,
        acs_rels ar
        where la.item_id = :activity_item_id
        and la.activity_description_id = cr1.item_id
        and cr1.live_revision = lad.description_id
        and ar.object_id_one = la.activity_description_id
        and ar.object_id_two = cr2.item_id
        and cr2.live_revision = ii.imsld_item_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_activity_as_ul.la_nested_associated_items">
		<querytext>

            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii, imsld_attribute_instances attr,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
            and attr.owner_id = ii.imsld_item_id
            and attr.run_id = :run_id
            and attr.type = 'isvisible'
            and attr.is_visible_p = 't'

		</querytext>
	</fullquery>

	<fullquery name="imsld::process_learning_activity_as_ul.completed_activity">
		<querytext>
    
        select 1
        from imsld_status_user
        where user_id = :user_id
        and related_id = :activity_id
        and run_id = :run_id
        and status = 'finished'

   		</querytext>
	</fullquery>

	<fullquery name="imsld::process_learning_activity_as_ul.la_associated_environments">
		<querytext>

            select ar.object_id_two as environment_item_id
            from acs_rels ar
            where ar.object_id_one = :activity_item_id
            and ar.rel_type = 'imsld_la_env_rel'
            order by ar.object_id_two
    
		</querytext>
	</fullquery>



	<fullquery name="imsld::process_support_activity_as_ul.activity_info">
		<querytext>

        select isa.on_completion_id as on_completion_item_id,
        isa.activity_id,
        attr.is_visible_p
        from imsld_support_activitiesi isa, imsld_attribute_instances attr
        where isa.item_id = :activity_item_id
        and content_revision__is_live(isa.activity_id) = 't'
        and attr.owner_id = isa.activity_id
        and attr.run_id = :run_id
        and attr.type = 'isvisible'
        and attr.is_visible_p = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_support_activity_as_ul.item_linear_list">
		<querytext>

        select ii.imsld_item_id
        from imsld_items ii, imsld_activity_descs sad, imsld_support_activitiesi sa,
        cr_items cr1, cr_items cr2,
        acs_rels ar
        where sa.item_id = :activity_item_id
        and sa.activity_description_id = cr1.item_id
        and cr1.live_revision = sad.description_id
        and ar.object_id_one = sa.activity_description_id
        and ar.object_id_two = cr2.item_id
        and cr2.live_revision = ii.imsld_item_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_support_activity_as_ul.sa_nested_associated_items">
		<querytext>

            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii, imsld_attribute_instances attr,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
            and attr.owner_id = ii.imsld_item_id
            and attr.run_id = :run_id
            and attr.type = 'isvisible'
            and attr.is_visible_p = 't'
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_support_activity_as_ul.completed_activity">
		<querytext>

        select 1
        from imsld_status_user
        where user_id = :user_id
        and related_id = :activity_id
        and run_id = :run_id
        and status = 'finished'        

		</querytext>
	</fullquery>

	<fullquery name="imsld::process_support_activity_as_ul.sa_associated_environments">
		<querytext>

            select ar.object_id_two as environment_item_id
            from acs_rels ar
            where ar.object_id_one = :activity_item_id
            and ar.rel_type = 'imsld_sa_env_rel'
            order by ar.object_id_two
        
		</querytext>
	</fullquery>

	<fullquery name="imsld::process_activity_structure_as_ul.item_linear_list">
		<querytext>

        select ii.imsld_item_id
        from imsld_itemsi ii, acs_rels ar
        where ar.object_id_one = :structure_item_id
        and ar.rel_type = 'imsld_as_info_i_rel'
        and ar.object_id_two = ii.item_id
        and content_revision__is_live(ii.imsld_item_id) = 't'
            
		</querytext>
	</fullquery>

	<fullquery name="imsld::process_activity_structure_as_ul.as_nested_associated_items">
		<querytext>


            select cpr.resource_id,
            cpr.item_id as resource_item_id,
            cpr.type as resource_type
            from imsld_cp_resourcesi cpr, imsld_itemsi ii, imsld_attribute_instances attr,
            acs_rels ar
            where ar.object_id_one = ii.item_id
            and ar.object_id_two = cpr.item_id
            and content_revision__is_live(cpr.resource_id) = 't'
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
            and attr.owner_id = ii.imsld_item_id
            and attr.run_id = :run_id
            and attr.type = 'isvisible'
            and attr.is_visible_p = 't'
            
		</querytext>
	</fullquery>

    <fullquery name="imsld::generate_structure_activities_list.structure_info">
        <querytext>
    

        select structure_id,
        structure_type
        from imsld_activity_structuresi
        where item_id = :structure_item_id
        
        </querytext>
    </fullquery>

	<fullquery name="imsld::generate_structure_activities_list.struct_referenced_activities">
		<querytext>

        select ar.object_id_two,
        ar.rel_type,
        ar.rel_id
        from acs_rels ar, imsld_activity_structuresi ias
        where ar.object_id_one = ias.item_id
        and ias.structure_id = :structure_id
        order by ar.object_id_two
        
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_structure_activities_list.get_learning_activity_info">
		<querytext>

                    select la.title as activity_title,
                    la.item_id as activity_item_id,
                    la.activity_id,
                    la.complete_act_id,
                    attr.is_visible_p
                    from imsld_learning_activitiesi la, imsld_attribute_instances attr
                    where la.item_id = :object_id_two
                    and content_revision__is_live(la.activity_id) = 't'
                    and attr.owner_id = la.activity_id
                    and attr.run_id = :run_id
                    and attr.type = 'isvisible'


		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_structure_activities_list.completed_p">
		<querytext>

                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and status = 'finished'
                    and run_id = :run_id
                
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_structure_activities_list.get_support_activity_info">
		<querytext>

                    select sa.title as activity_title,
                    sa.item_id as activity_item_id,
                    sa.activity_id,
                    sa.complete_act_id,
                    attr.is_visible_p
                    from imsld_support_activitiesi sa, imsld_attribute_instances attr
                    where sa.item_id = :object_id_two
                    and content_revision__is_live(sa.activity_id) = 't'
                    and attr.owner_id = sa.activity_id
                    and attr.run_id = :run_id
                    and attr.type = 'isvisible'
                
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_structure_activities_list.get_activity_structure_info">
		<querytext>

                    select title as activity_title,
                    item_id as structure_item_id,
                    structure_id,
                    structure_type
                    from imsld_activity_structuresi
                    where item_id = :object_id_two
                    and content_revision__is_live(structure_id) = 't'
                
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_structure_activities_list.as_completed_p">
		<querytext>

                    select 1 from imsld_status_user
                    where related_id = :structure_id 
                    and user_id = :user_id 
                    and status = 'started'
                    and run_id = :run_id
                
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_activities_tree.referenced_role_parts">
		<querytext>

        select case
        when rp.learning_activity_id is not null
        then 'learning'
        when rp.support_activity_id is not null
        then 'support'
        when rp.activity_structure_id is not null
        then 'structure'
        else 'none'
        end as type,
        content_item__get_live_revision(coalesce(rp.learning_activity_id,rp.support_activity_id,rp.activity_structure_id)) as activity_id,
        rp.role_part_id,
        ia.act_id,
        ip.play_id
        from imsld_role_partsi rp, imsld_actsi ia, imsld_playsi ip, imsld_imsldsi ii, imsld_attribute_instances attr,
        imsld_methodsi im,imsld_rolesi iri
        where  rp.act_id = ia.item_id
        and ia.play_id = ip.item_id
        and ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.imsld_id = :imsld_id
        and rp.role_id = iri.item_id
        and iri.role_id in ([join $user_roles_list ","])
        and content_revision__is_live(rp.role_part_id) = 't'
        and attr.owner_id = ip.play_id
        and attr.run_id = :run_id
        and attr.type = 'isvisible'
        and attr.is_visible_p = 't'
        order by ip.sort_order, ia.sort_order, rp.sort_order
        
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_activities_tree.get_learning_activity_info">
		<querytext>

                    select la.title as activity_title,
                    la.item_id as activity_item_id,
                    la.activity_id,
                    attr.is_visible_p,
                    la.complete_act_id
                    from imsld_learning_activitiesi la, imsld_attribute_instances attr
                    where activity_id = :activity_id
                    and attr.owner_id = la.activity_id
                    and attr.run_id = :run_id
                    and attr.type = 'isvisible'
                    
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_activities_tree.get_support_activity_info">
		<querytext>

                    select sa.title as activity_title,
                    sa.item_id as activity_item_id,
                    sa.activity_id,
                    attr.is_visible_p,
                    sa.complete_act_id
                    from imsld_support_activitiesi sa, imsld_attribute_instances attr
                    where sa.activity_id = :activity_id
                    and attr.owner_id = sa.activity_id
                    and attr.run_id = :run_id
                    and attr.type = 'isvisible'
                    
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_activities_tree.get_activity_structure_info">
		<querytext>

                    select title as activity_title,
                    item_id as structure_item_id,
                    structure_id,
                    structure_type
                    from imsld_activity_structuresi
                    where structure_id = :activity_id
                    
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_activities_tree.as_completed_p">
		<querytext>

                    select 1 from imsld_status_user
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and status = 'started'
                    and run_id = :run_id
                    
		</querytext>
	</fullquery>

	<fullquery name="imsld::next_activity.is_assessment">
		<querytext>
        select acs_object_id as assessment_id 
        from imsld_cp_resourcesi 
        where type='imsqti_xmlv1p0'
              and item_id=:resource_activity
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.get_as_site_node">
		<querytext>
            select sn.node_id as node_id 
            from acs_objects ao,
                 site_nodes sn 
            where ao.package_id=sn.object_id 
                  and ao.object_id=:assessment_id;
        </querytext>
	</fullquery>



	<fullquery name="imsld::next_activity.get_ismld_info">
		<querytext>
        select imsld_id
        from imsld_imsldsi
        where item_id = :imsld_item_id
        and content_revision__is_live(imsld_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.learning_activity_resource">
		<querytext>
        select ila.activity_id,
        ila.item_id as activity_item_id
        from imsld_cp_resourcesi icri,
        acs_rels ar1,
        acs_rels ar2,
        imsld_learning_activitiesi ila 
        where ar2.object_id_two=icri.item_id 
        and ar1.object_id_two=ar2.object_id_one 
        and ila.activity_description_id=ar1.object_id_one 
        and icri.resource_id= :resource_id
    
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_activity_from_resource.support_activity_resource">
		<querytext>
        select isa.activity_id,
        isa.item_id as activity_item_id
        from imsld_cp_resourcesi icri,
        acs_rels ar1,
        acs_rels ar2,
        imsld_support_activitiesi isa 
        where ar2.object_id_two=icri.item_id 
        and ar1.object_id_two=ar2.object_id_one 
        and isa.activity_description_id=ar1.object_id_one 
        and icri.resource_id= :resource_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.get_imsld_item_id">
		<querytext>
        select ar1.object_id_one as imsld_item_item_id 
        from imsld_cp_resourcesi icri,
        acs_rels ar1 
        where icri.item_id=ar1.object_id_two 
        and icri.resource_id= :resource_id

		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.is_conference_service">
		<querytext>
    select 1 from imsld_conference_services where imsld_item_id=:imsld_item_item_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.get_environment_id_from_cs">
		<querytext>
                select isi.environment_id as environment_item_id 
                from imsld_conference_services ics,
                     imsld_servicesi isi 
                where isi.item_id=ics.service_id 
                      and ics.imsld_item_id=:imsld_item_item_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.get_learning_activities_from_environment">
		<querytext>
            select ila.activity_id,
            ila.item_id as activity_item_id,
            'learning'
            from acs_rels ar,
            imsld_learning_activitiesi ila 
            where ila.item_id=ar.object_id_one 
            and ar.object_id_two=:environment_item_id

		</querytext>
	</fullquery>

	<fullquery name="imsld::get_activity_from_resource.get_support_activities_from_environment">
		<querytext>
            select isa.activity_id,
            isa.item_id as activity_item_id,
            'learning'
            from acs_rels ar,
            imsld_support_activitiesi isa 
            where isa.item_id=ar.object_id_one 
            and ar.object_id_two=:environment_item_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.is_learning_object">
		<querytext>
    select 1 from acs_rels where rel_type='imsld_l_object_item_rel' and object_id_two=:imsld_item_item_id 
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.get_environment_id_from_lo">
		<querytext>
                select iloi.environment_id as environment_item_id 
                from imsld_learning_objectsi iloi,
                     acs_rels ar 
                where iloi.item_id=ar.object_id_one
                     and ar.object_id_two=:imsld_item_item_id
            
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_activity_from_resource.get_activity_from_resource">
		<querytext>
 
            select ar1.object_id_one as resource_element_id
            from acs_rels ar1,
                 acs_rels ar2,
                 imsld_cp_resourcesi icr 
            where ar1.object_id_two=ar2.object_id_one 
                 and ar2.object_id_two=icr.item_id 
                 and icr.resource_id = :resource_id;
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.is_prerequisite">
		<querytext>
 select 1 from imsld_prerequisitesi where item_id=:resource_element_id 
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.get_activity_id_from_prerequisite">
		<querytext>
            select activity_id,
            item_id as activity_item_id 
            from imsld_learning_activitiesi 
            where prerequisite_id=:resource_element_id 
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.is_learning_objective">
		<querytext>
 select 1 from imsld_learning_objectivesi where item_id=:resource_element_id 
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_activity_from_resource.get_activity_id_from_objective">
		<querytext>
            select activity_id,
            item_id as activity_item_id
            from imsld_learning_activitiesi
            where learning_objective_id=:resource_element_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_role_part_from_activity.la_directly_mapped">
		<querytext>
    
                select role_part_id
                from imsld_role_parts
                where learning_activity_id = :leaf_id
            
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_role_part_from_activity.sa_directly_mapped">
		<querytext>
    
                select role_part_id
                from imsld_role_parts
                where support_activity_id = :leaf_id
            
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_role_part_from_activity.as_directly_mapped">
		<querytext>
    
                select role_part_id
                from imsld_role_partsi
                where activity_structure_id = :leaf_id
            
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_role_part_from_activity.get_la_activity_structures">
		<querytext>
    
                select ias.structure_id, ias.item_id as leaf_id
                from imsld_activity_structuresi ias, acs_rels ar, imsld_learning_activitiesi la
                where ar.object_id_one = ias.item_id
                and ar.object_id_two = la.item_id
                and content_revision__is_live(ias.structure_id) = 't'
                and la.item_id = :leaf_id

		</querytext>
	</fullquery>

	<fullquery name="imsld::get_role_part_from_activity.get_sa_activity_structures">
		<querytext>

                select ias.structure_id, ias.item_id as leaf_id
                from imsld_activity_structuresi ias, acs_rels ar, imsld_support_activitiesi sa
                where ar.object_id_one = ias.item_id
                and ar.object_id_two = sa.item_id
                and content_revision__is_live(ias.structure_id) = 't'
                and sa.item_id = :leaf_id
                
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_role_part_from_activity.get_as_activity_structures">
		<querytext>
    
                select ias.structure_id, ias.item_id as leaf_id
                from imsld_activity_structuresi ias, acs_rels ar
                where ar.object_id_one = ias.item_id
                and ar.object_id_two = :leaf_id
                and content_revision__is_live(ias.structure_id) = 't'
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::get_imsld_from_activity.get_imsld_from_la_activity">
		<querytext>
            select iii.imsld_id as imsld_id
            from imsld_imsldsi iii,
                 cr_items cr,
                 cr_items cr2,
                 imsld_learning_activitiesi ilai 
            where ilai.activity_id=:activity_id
                 and ilai.item_id=cr.item_id 
                 and cr2.parent_id=cr.parent_id 
                 and cr2.content_type='imsld_imsld' 
                 and iii.item_id=cr2.item_id
    
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_imsld_from_activity.get_imsld_from_sa_activity">
		<querytext>
            select iii.imsld_id as imsld_id
            from imsld_imsldsi iii,
                 cr_items cr,
                 cr_items cr2,
                 imsld_support_activitiesi isai 
            where isai.activity_id=:activity_id
                 and isai.item_id=cr.item_id 
                 and cr2.parent_id=cr.parent_id 
                 and cr2.content_type='imsld_imsld' 
                 and iii.item_id=cr2.item_id
    
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_imsld_from_activity.get_imsld_from_as_activity">
		<querytext>
            select iii.imsld_id as imsld_id
            from imsld_imsldsi iii,
                 cr_items cr,
                 cr_items cr2,
                 imsld_activity_structuresi iasi 
            where iasi.structure_id=:activity_id
                 and iasi.item_id=cr.item_id 
                 and cr2.parent_id=cr.parent_id 
                 and cr2.content_type='imsld_imsld' 
                 and iii.item_id=cr2.item_id
    
		</querytext>
	</fullquery>

	<fullquery name="imsld::get_resource_from_object.get_resource">
		<querytext>
        select resource_id
        from imsld_cp_resources
        where acs_object_id = :object_id
    
		</querytext>
	</fullquery>

	<fullquery name="imsld::finish_resource.insert_completed_resource">
		<querytext>
                insert into imsld_status_user (
                                                imsld_id,
                                                run_id,
                                                related_id,
                                                user_id,
                                                type,
                                                status_date,
                                                status
                                               )
                                               (
                                                select :imsld_id,
                                                :run_id,
                                                :resource_id,
                                                :user_id,
                                                'resource',
                                                now(),
                                                'finished'
                                                where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :resource_id and status = 'finished')
                                               )
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_resource.resource_finished_p">
		<querytext>
                    select 1 
                    from imsld_status_user stat, imsld_cp_resourcesi icr
                    where icr.item_id = :res_id
                    and icr.resource_id = stat.related_id
                    and user_id = :user_id
                    and status = 'finished'
                    and run_id = :run_id
		</querytext>
	</fullquery>

	<fullquery name="imsld::finish_resource.already_finished">
		<querytext>
            select 1 from imsld_status_user 
            where related_id = :activity_id 
            and user_id = :user_id 
            and status = 'finished'
            and run_id = :run_id
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_resource.check_completed_resource">
		<querytext>
                select count(*)
                from imsld_status_user
                where related_id = :resource_id
                and status = 'finished'
                and run_id = :run_id
		</querytext>
	</fullquery>


</queryset>

