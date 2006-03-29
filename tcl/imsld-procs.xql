<?xml version="1.0"?>
<queryset>



	<fullquery name="imsld::community_id_from_manifest_id.get_community_id">
		<querytext>
        select dc.community_id
        from imsld_cp_manifestsi im, acs_objects ao, dotlrn_communities dc
        where im.object_package_id = ao.package_id
        and ao.context_id = dc.package_id
        and im.manifest_id = :manifest_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::sweep_expired_activities.possible_expired_method">
		<querytext>
        select icm.manifest_id,
        ii.imsld_id,
        im.method_id, 
        ca.time_in_seconds,
        icm.creation_date
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_complete_actsi ca
        where im.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and im.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and content_revision__is_live(im.method_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::sweep_expired_activities.compre_times">
		<querytext>
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::sweep_expired_activities.user_in_class">
		<querytext>
                select app.user_id
                from dotlrn_member_rels_approved app
                where app.community_id = :community_id
                and app.member_state = 'approved'
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::sweep_expired_activities.possible_expired_plays">
		<querytext>
        select icm.manifest_id,
        ii.imsld_id,
        ip.play_id,
        ca.time_in_seconds,
        icm.creation_date
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_plays ip,
        imsld_complete_actsi ca
        where ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and ip.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and content_revision__is_live(ip.play_id) = 't'
    
		</querytext>
	</fullquery>





	<fullquery name="imsld::sweep_expired_activities.possible_expired_acts">
		<querytext>
        select icm.manifest_id,
        ii.imsld_id,
        ip.play_id,
        ia.act_id,
        ca.time_in_seconds,
        icm.creation_date
        from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
        imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, imsld_acts ia,
        imsld_complete_actsi ca
        where ia.play_id = ip.item_id
        and ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.organization_id = ico.item_id
        and ico.manifest_id = icm.item_id
        and ia.complete_act_id = ca.item_id
        and ca.time_in_seconds is not null
        and content_revision__is_live(ia.act_id) = 't'
    
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

	<fullquery name="imsld::sweep_expired_activities.get_sa_activity_info">
		<querytext>
            select icm.manifest_id,
            ii.imsld_id,
            ip.play_id,
            ia.act_id,
            icm.creation_date
            from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
            imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, 
            imsld_actsi ia, imsld_role_partsi irp
            where irp.role_part_id = :role_part_id
            and irp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and ip.method_id = im.item_id
            and im.imsld_id = ii.item_id
            and ii.organization_id = ico.item_id
            and ico.manifest_id = icm.item_id
            and content_revision__is_live(icm.manifest_id) = 't'
    
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

	<fullquery name="imsld::sweep_expired_activities.get_la_activity_info">
		<querytext>
            select icm.manifest_id,
            ii.imsld_id,
            ip.play_id,
            ia.act_id,
            icm.creation_date
            from imsld_cp_manifestsi icm, imsld_cp_organizationsi ico, 
            imsld_imsldsi ii, imsld_methodsi im, imsld_playsi ip, 
            imsld_actsi ia, imsld_role_partsi irp
            where irp.role_part_id = :role_part_id
            and irp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and ip.method_id = im.item_id
            and im.imsld_id = ii.item_id
            and ii.organization_id = ico.item_id
            and ico.manifest_id = icm.item_id
            and content_revision__is_live(icm.manifest_id) = 't'

		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_role_part_finished.role_part_info">
		<querytext>
        select item_id as role_part_item_id
        from imsld_role_partsi
        where role_part_id = :role_part_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::mark_role_part_finished.insert_role_part">
		<querytext>
        insert into imsld_status_user (imsld_id,
                                       play_id,
                                       act_id,
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :play_id,
         :act_id,
         :role_part_id,
         :user_id,
         'act',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and related_id = :role_part_id and status = 'finished')
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
                                       play_id,
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :play_id,
         :act_id,
         :user_id,
         'act',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and related_id = :act_id and status = 'finished')
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
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :play_id,
         :user_id,
         'play',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and related_id = :play_id and status = 'finished')
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
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :imsld_id,
         :user_id,
         'play',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and related_id = :imsld_id and status = 'finished')
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
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status) 
        (
         select :imsld_id,
         :method_id,
         :user_id,
         'method',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and related_id = :method_id and status = 'finished')
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
                                       :play_id,
                                       :act_id,
                                       :role_part_id,
                                       :element_id,
                                       :user_id,
                                       :type,
                                       now(),
                                       'finished'
                                       where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and related_id = :element_id and status = 'finished')
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
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_component_element.already_marked_p">
		<querytext>
select 1 from imsld_status_user where related_id = :role_part_id and user_id = :user_id and status = 'finished'
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
                from imsld_role_parts irp
                where irp.act_id = :act_item_id
                and content_revision__is_live(irp.role_part_id) = 't'
            
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
		</querytext>
	</fullquery>


	<fullquery name="imsld::role_part_finished_p.already_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :role_part_id
        and user_id = :user_id
        and status = 'finished'
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
		</querytext>
	</fullquery>


	<fullquery name="imsld::role_part_finished_p.completed_from_sa">
		<querytext>
                select count(*) from imsld_status_user
                where related_id = content_item__get_live_revision(:support_activity_id)
                and user_id = :user_id
                and status = 'finished'
		</querytext>
	</fullquery>


	<fullquery name="imsld::role_part_finished_p.completed_from_as">
		<querytext>
                select count(*) from imsld_status_user
                where related_id = content_item__get_live_revision(:activity_structure_id)
                and user_id = :user_id
                and status = 'finished'
		</querytext>
	</fullquery>


	<fullquery name="imsld::act_finished_p.already_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :act_id
        and user_id = :user_id
        and status = 'finished'
		</querytext>
	</fullquery>


	<fullquery name="imsld::play_finished_p.play_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :play_id
        and user_id = :user_id
        and status = 'finished'
		</querytext>
	</fullquery>


	<fullquery name="imsld::method_finished_p.method_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :method_id
        and user_id = :user_id
        and status = 'finished'
		</querytext>
	</fullquery>


	<fullquery name="imsld::imsld_finished_p.imsld_marked_p">
		<querytext>
        select 1 
        from imsld_status_user
        where related_id = :imsld_id
        and user_id = :user_id
        and status = 'finished'
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_service.service_info">
		<querytext>
        select serv.service_id,
        serv.identifier,
        serv.class,
        serv.is_visible_p,
        serv.service_type
        from imsld_servicesi serv 
        where serv.item_id = :service_item_id
        and content_revision__is_live(serv.service_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_service.get_conference_info">
		<querytext>
                select conf.conference_id,
                conf.conference_type,
                conf.imsld_item_id as imsld_item_item_id,
                cr.live_revision as imsld_item_id
                from imsld_conference_services conf, cr_items cr
                where conf.service_id = :service_item_id
                and cr.item_id = conf.imsld_item_id
                and content_revision__is_live(cr.live_revision) = 't'
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_service.serv_associated_items">
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


	<fullquery name="imsld::process_environment.environment_info">
		<querytext>
        select env.title as environment_title,
        env.environment_id
        from imsld_environmentsi env
        where env.item_id = :environment_item_id
        and content_revision__is_live(env.environment_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment.get_learning_object_info">
		<querytext>
        select item_id as learning_object_item_id,
        learning_object_id,
        identifier
        from imsld_learning_objectsi
        where environment_id = :environment_item_id
        and content_revision__is_live(learning_object_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment.item_linear_list">
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


	<fullquery name="imsld::process_environment.env_nested_associated_items">
		<querytext>
        select cpr.resource_id,
        cr2.item_id as resource_item_id,
        cpr.type as resource_type
        from imsld_cp_resources cpr, imsld_items ii,
        acs_rels ar, cr_items cr1, cr_items cr2
        where ar.object_id_one = cr1.item_id
        and ar.object_id_two = cr2.item_id
        and cr1.live_revision = ii.imsld_item_id
        and cr2.live_revision = cpr.resource_id 
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)
                        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment.get_service_info">
		<querytext>
        select service_id,
        item_id as service_item_id,
        identifier,
        service_type
        from imsld_servicesi
        where environment_id = :environment_item_id
        and content_revision__is_live(service_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_environment.nested_environment">
		<querytext>
        select ar.object_id_two as nested_environment_item_id
        from acs_rels ar
        where ar.object_id_one = :environment_item_id
        and ar.rel_type = 'imsld_env_env_rel'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective.get_lo_id_from_iii">
		<querytext>
 
            select learning_objective_id as learning_objective_item_id
            from imsld_imsldsi
            where item_id = :imsld_item_id
            and content_revision__is_live(imsld_id) = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective.get_lo_id_from_aii">
		<querytext>
 
            select learning_objective_id as learning_objective_item_id
            from imsld_learning_activitiesi
            where item_id = :activity_item_id
            and content_revision__is_live(activity_id) = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective.objective_info">
		<querytext>
        select coalesce(lo.pretty_title, '') as objective_title,
        lo.learning_objective_id
        from imsld_learning_objectivesi lo
        where lo.item_id = :learning_objective_item_id
        and content_revision__is_live(lo.learning_objective_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective.item_linear_list">
		<querytext>
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :learning_objective_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_objective.lo_nested_associated_items">
		<querytext>
        select cpr.resource_id,
        cr2.item_id as resource_item_id,
        cpr.type as resource_type
        from imsld_cp_resources cpr, imsld_items ii,
        acs_rels ar, cr_items cr1, cr_items cr2
        where ar.object_id_one = cr1.item_id
        and ar.object_id_two = cr2.item_id
        and cr1.live_revision = ii.imsld_item_id
        and cr2.live_revision = cpr.resource_id 
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite.get_lo_id_from_iii">
		<querytext>
 
            select prerequisite_id as prerequisite_item_id
            from imsld_imsldsi
            where item_id = :imsld_item_id
            and content_revision__is_live(imsld_id) = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite.get_lo_id_from_aii">
		<querytext>
 
            select prerequisite_id as prerequisite_item_id
            from imsld_learning_activitiesi
            where item_id = :activity_item_id
            and content_revision__is_live(activity_id) = 't'
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite.prerequisite_info">
		<querytext>
        select pre.pretty_title as prerequisite_title,
        pre.prerequisite_id
        from imsld_prerequisitesi pre
        where pre.item_id = :prerequisite_item_id
        and content_revision__is_live(pre.prerequisite_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite.item_linear_list">
		<querytext>
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :prerequisite_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_prerequisite.prereq_nested_associated_items">
		<querytext>
        select cpr.resource_id,
        cr2.item_id as resource_item_id,
        cpr.type as resource_type
        from imsld_cp_resources cpr, imsld_items ii,
        acs_rels ar, cr_items cr1, cr_items cr2
        where ar.object_id_one = cr1.item_id
        and ar.object_id_two = cr2.item_id
        and cr1.live_revision = ii.imsld_item_id
        and cr2.live_revision = cpr.resource_id 
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_feedback.feedback_info">
		<querytext>
        select oc.feedback_title as feedback_title
        from imsld_on_completioni oc
        where oc.item_id = :on_completion_item_id
        and content_revision__is_live(oc.on_completion_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_feedback.item_linear_list">
		<querytext>
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :on_completion_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_feedback.feedback_nested_associated_items">
		<querytext>
        select cpr.resource_id,
        cr2.item_id as resource_item_id,
        cpr.type as resource_type
        from imsld_cp_resources cpr, imsld_items ii,
        acs_rels ar, cr_items cr1, cr_items cr2
        where ar.object_id_one = cr1.item_id
        and ar.object_id_two = cr2.item_id
        and cr1.live_revision = ii.imsld_item_id
        and cr2.live_revision = cpr.resource_id 
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource.get_resource_info">
		<querytext>
        select cpr.identifier,
        cpr.type as resource_type,
        cr.title as resource_title,
        acs_object_id
        from imsld_cp_resources cpr, cr_revisions cr, cr_items cri
        where cr.item_id = :resource_item_id
        and cr.revision_id = cri.live_revision
        and cr.revision_id = cpr.resource_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource.is_cr_item">
		<querytext>
            select live_revision from cr_items where item_id = :acs_object_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource.get_cr_info">
		<querytext>
 
                select acs_object__name(object_id) as object_title, object_type
                from acs_objects where object_id = :live_revision
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource.get_ao_info">
		<querytext>
 
                select acs_object__name(object_id) as object_title, object_type
                from acs_objects where object_id = :acs_object_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource.associated_files">
		<querytext>
            select cpf.imsld_file_id,
            cpf.file_name,
            cr.item_id, 
            cr.parent_id
            from imsld_cp_files cpf, cr_items cr,
            acs_rels ar
            where ar.object_id_one = :resource_item_id
            and ar.object_id_two = cr.item_id
            and cpf.imsld_file_id = cr.live_revision
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource.get_folder_path">
		<querytext>
 select content_item__get_path(:parent_id,:root_folder_id); 
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_resource.get_fs_file_url">
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


	<fullquery name="imsld::process_resource.associated_urls">
		<querytext>
            select url
            from acs_rels ar,
            cr_extlinks links
            where ar.object_id_one = :resource_item_id
            and ar.object_id_two = links.extlink_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_activity.activity_info">
		<querytext>
        select on_completion_id as on_completion_item_id,
        prerequisite_id as prerequisite_item_id,
        learning_objective_id as learning_objective_item_id,
        activity_id
        from imsld_learning_activitiesi
        where item_id = :activity_item_id
        and content_revision__is_live(activity_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_activity.la_associated_environments">
		<querytext>
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :activity_item_id
        and ar.rel_type = 'imsld_la_env_rel'
        order by ar.object_id_two
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_activity.item_linear_list">
		<querytext>
        select ii.imsld_item_id
        from imsld_items ii, imsld_activity_descs lad, imsld_learning_activities la,
        cr_items cr1, cr_items cr2, cr_items cr3,
        acs_rels ar
        where cr3.item_id = :activity_item_id
        and la.activity_description_id = cr1.item_id
        and cr1.live_revision = lad.description_id
        and ar.object_id_one = la.activity_description_id
        and ar.object_id_two = cr2.item_id
        and cr2.live_revision = ii.imsld_item_id
        and cr3.live_revision = la.activity_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_learning_activity.la_nested_associated_items">
		<querytext>
        select cpr.resource_id,
        cr2.item_id as resource_item_id,
        cpr.type as resource_type
        from imsld_cp_resources cpr, imsld_items ii,
        acs_rels ar, cr_items cr1, cr_items cr2
        where ar.object_id_one = cr1.item_id
        and ar.object_id_two = cr2.item_id
        and cr1.live_revision = ii.imsld_item_id
        and cr2.live_revision = cpr.resource_id 
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_support_activity.activity_info">
		<querytext>
        select on_completion_id as on_completion_item_id,
        activity_id
        from imsld_support_activitiesi
        where item_id = :activity_item_id
        and content_revision__is_live(activity_id) = 't'
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_support_activity.sa_associated_environments">
		<querytext>
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :activity_item_id
        and ar.rel_type = 'imsld_sa_env_rel'
        order by ar.object_id_two
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_support_activity.item_linear_list">
		<querytext>
        select ii.imsld_item_id
        from imsld_items ii, imsld_activity_descs sad, imsld_support_activities sa,
        cr_items cr1, cr_items cr2, cr_items cr3,
        acs_rels ar
        where cr3.item_id = :activity_item_id
        and sa.activity_description_id = cr1.item_id
        and cr1.live_revision = sad.description_id
        and ar.object_id_one = sa.activity_description_id
        and ar.object_id_two = cr2.item_id
        and cr2.live_revision = ii.imsld_item_id
        and cr3.live_revision = sa.activity_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_support_activity.sa_nested_associated_items">
		<querytext>
        select cpr.resource_id,
        cr2.item_id as resource_item_id,
        cpr.type as resource_type
        from imsld_cp_resources cpr, imsld_items ii,
        acs_rels ar, cr_items cr1, cr_items cr2
        where ar.object_id_one = cr1.item_id
        and ar.object_id_two = cr2.item_id
        and cr1.live_revision = ii.imsld_item_id
        and cr2.live_revision = cpr.resource_id 
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::process_activity_structure.sa_associated_environments">
		<querytext>
    
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :structure_item_id
        and ar.rel_type = 'imsld_as_env_rel'
        order by ar.object_id_two
    
    
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

                    select title as activity_title,
                    item_id as activity_item_id,
                    activity_id,
                    complete_act_id,
                    is_visible_p
                    from imsld_learning_activitiesi
                    where item_id = :object_id_two
                    and content_revision__is_live(activity_id) = 't'
                
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_structure_activities_list.completed_p">
		<querytext>

                    select 1 from imsld_status_user 
                    where related_id = :activity_id and user_id = :user_id and status = 'finished'
                
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_structure_activities_list.get_support_activity_info">
		<querytext>

                    select title as activity_title,
                    item_id as activity_item_id,
                    activity_id,
                    complete_act_id,
                    is_visible_p
                    from imsld_support_activitiesi
                    where item_id = :object_id_two
                    and content_revision__is_live(activity_id) = 't'
                
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
                    where related_id = :structure_id and user_id = :user_id and status = 'started'
                
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
        from imsld_role_partsi rp, imsld_actsi ia, imsld_playsi ip, imsld_imsldsi ii,
        imsld_methodsi im
        where  rp.act_id = ia.item_id
        and ia.play_id = ip.item_id
        and ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.imsld_id = :imsld_id
        and content_revision__is_live(rp.role_part_id) = 't'
        order by rp.sort_order
        
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_activities_tree.get_learning_activity_info">
		<querytext>

                    select title as activity_title,
                    item_id as activity_item_id,
                    activity_id,
                    is_visible_p,
                    complete_act_id
                    from imsld_learning_activitiesi
                    where activity_id = :activity_id
                    
		</querytext>
	</fullquery>

	<fullquery name="imsld::generate_activities_tree.get_support_activity_info">
		<querytext>

                    select title as activity_title,
                    item_id as activity_item_id,
                    activity_id,
                    is_visible_p,
                    complete_act_id
                    from imsld_support_activitiesi
                    where activity_id = :activity_id
                    
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
                    where related_id = :activity_id and user_id = :user_id and status = 'started'
                    
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


	<fullquery name="imsld::next_activity.get_last_entry">
		<querytext>
        select count(*)
        from imsld_status_user
        where user_id = :user_id
        and imsld_id = :imsld_id
        and type in ('learning','support','structure')
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.get_first_role_part">
		<querytext>

            select irp.role_part_id, ia.act_id, ip.play_id
            from cr_items cr0, cr_items cr1, cr_items cr2, imsld_methods im, imsld_plays ip, imsld_acts ia, imsld_role_parts irp
            where im.imsld_id = :imsld_item_id
            and ip.method_id = cr0.item_id
            and cr0.live_revision = im.method_id
            and ia.play_id = cr1.item_id
            and cr1.live_revision = ip.play_id
            and irp.act_id = cr2.item_id
            and cr2.live_revision = ia.act_id
            and content_revision__is_live(irp.role_part_id) = 't'
            and ip.sort_order = (select min(ip2.sort_order) from imsld_plays ip2 where ip2.method_id = cr0.item_id)
            and ia.sort_order = (select min(ia2.sort_order) from imsld_acts ia2 where ia2.play_id = cr1.item_id)
            and irp.sort_order = (select min(irp2.sort_order) from imsld_role_parts irp2 where irp2.act_id = cr2.item_id)
        </querytext>
	</fullquery>



	<fullquery name="imsld::next_activity.marked_activity">
		<querytext>
            select stat.related_id,
            stat.role_part_id,
            stat.type,
            rp.sort_order,
            rp.act_id,
            stat.status
            from imsld_status_user stat, imsld_role_parts rp
            where stat.imsld_id = :imsld_id
            and stat.user_id = :user_id
            and stat.role_part_id = rp.role_part_id
            and stat.type in ('learning','support','structure')
            order by stat.status_date
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.get_learning_activity_info">
		<querytext>
                        select title as activity_title,
                        item_id as activity_item_id
                        from imsld_learning_activitiesi
                        where activity_id = :related_id
                    
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.get_support_activity_info_from_isa">
		<querytext>
                        select title as activity_title,
                        item_id as activity_item_id
                        from imsld_support_activitiesi
                        where activity_id = :related_id
                    
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.get_support_activity_info_from_ias">
		<querytext>
                        select title as activity_title,
                        item_id as structure_item_id
                        from imsld_activity_structuresi
                        where structure_id = :related_id
                    
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.search_current_act">
		<querytext>
                select role_part_id
                from imsld_role_parts
                where sort_order = :sort_order + 1
                and act_id = :act_id
            
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.get_current_play_id">
		<querytext>
                    select ip.item_id as play_item_id,
                    ip.play_id,
                    ia.sort_order as act_sort_order
                    from imsld_playsi ip, imsld_acts ia, cr_items cr
                    where ip.item_id = ia.play_id
                    and ia.act_id = cr.live_revision
                    and cr.item_id = :act_id
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.search_current_play">
		<querytext>
                    select rp.role_part_id
                    from imsld_role_parts rp, imsld_actsi ia
                    where ia.play_id = :play_item_id
                    and ia.sort_order = :act_sort_order + 1
                    and rp.act_id = ia.item_id
                    and content_revision__is_live(rp.role_part_id) = 't'
                    and content_revision__is_live(ia.act_id) = 't'
                    and rp.sort_order = (select min(irp2.sort_order) from imsld_role_parts irp2 where irp2.act_id = rp.act_id)
                
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.get_current_method">
		<querytext>
                        select im.item_id as method_item_id,
                        ip.sort_order as play_sort_order
                        from imsld_methodsi im, imsld_plays ip
                        where im.item_id = ip.method_id
                        and ip.play_id = :play_id
                    
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.search_current_method">
		<querytext>
                        select rp.role_part_id
                        from imsld_role_parts rp, imsld_actsi ia, imsld_playsi ip
                        where ip.method_id = :method_item_id
                        and ia.play_id = ip.item_id
                        and rp.act_id = ia.item_id
                        and ip.sort_order = :play_sort_order + 1
                        and content_revision__is_live(rp.role_part_id) = 't'
                        and content_revision__is_live(ia.act_id) = 't'
                        and content_revision__is_live(ip.play_id) = 't'
                        and ia.sort_order = (select min(ia2.sort_order) from imsld_acts ia2 where ia2.play_id = ip.item_id)
                        and rp.sort_order = (select min(irp2.sort_order) from imsld_role_parts irp2 where irp2.act_id = ia.item_id)
                    
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.get_role_part_activity">
		<querytext>
        select case
        when learning_activity_id is not null
        then 'learning'
        when support_activity_id is not null
        then 'support'
        when activity_structure_id is not null
        then 'structure'
        else 'none'
        end as activity_type,
        case
        when learning_activity_id is not null
        then content_item__get_live_revision(learning_activity_id)
        when support_activity_id is not null
        then content_item__get_live_revision(support_activity_id)
        when activity_structure_id is not null
        then content_item__get_live_revision(activity_structure_id)
        else content_item__get_live_revision(environment_id)
        end as activity_id,
        coalesce(learning_activity_id,support_activity_id,activity_structure_id) as activity_item_id,
        environment_id as rp_environment_item_id
        from imsld_role_parts
        where role_part_id = :role_part_id
    
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.learning_activity">
		<querytext>
            select la.activity_id,
            la.item_id as activity_item_id,
            la.title as activity_title,
            la.identifier, la.component_id
            from imsld_learning_activitiesi la
            where la.activity_id = :activity_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.support_activity">
		<querytext>
            select sa.activity_id,
            sa.item_id as activity_item_id,
            sa.title as activity_title,
            sa.identifier
            from imsld_support_activitiesi sa
            where sa.activity_id = :activity_id
        
		</querytext>
	</fullquery>


	<fullquery name="imsld::next_activity.verify_not_completed">
		<querytext>
        select count(*) from imsld_status_user
        where related_id = :activity_id
        and user_id = :user_id
        and status = 'finished'
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
            where iasi.structureid=:activity_id
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
                                                related_id,
                                                user_id,
                                                type,
                                                status_date,
                                                status
                                               )
                                               (
                                                select :imsld_id,
                                                :resource_id,
                                                :user_id,
                                                'resource',
                                                now(),
                                                'finished'
                                                where not exists (select 1 from imsld_status_user where imsld_id = :imsld_id and user_id = :user_id and related_id = :resource_id and status = 'finished')
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
		</querytext>
	</fullquery>

	<fullquery name="imsld::finish_resource.already_finished">
		<querytext>
            select 1 from imsld_status_user where related_id = :activity_id and user_id = :user_id and status = 'finished'
		</querytext>
	</fullquery>


	<fullquery name="imsld::finish_resource.check_completed_resource">
		<querytext>
                select count(*)
                from imsld_status_user
                where related_id = :resource_id
                and status = 'finished'
		</querytext>
	</fullquery>


</queryset>

