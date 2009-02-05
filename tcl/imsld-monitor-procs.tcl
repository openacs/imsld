# /packages/imsld/tcl/imsld-monitor-procs.tcl

ad_library {
    Procedures in the imsld::monitor namespace.
    
    @creation-date Nov 2006
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld::monitor {}

ad_proc -public imsld::monitor::add_activity_sorting {
    -item_id:required
    -run_id:required
    -dom_doc:required
    -dom_node:required
    {-sort_order:required 1}
    -number_elements
} {
    @param item_id
    @param run_id
    @param dom_doc
    @param dom_node
    @param sort_order
    @param number_elements
    @return 
    
    @error 
} {
    if { $sort_order > 0 } {
	set url [export_vars -base change-activity-order {item_id run_id sort_order {dir -1}}]
	set up_node [$dom_doc createElement a]
	set img_node [$dom_doc createElement img]
	$img_node setAttribute src "/resources/imsld/arrow_up.png"
	$img_node setAttribute alt "Up"
	$up_node appendChild $img_node
	$up_node setAttribute href {\#}
	$up_node setAttribute onclick "return loadTree('$url')"
	$dom_node appendChild $up_node
    }
    if { $sort_order < ($number_elements - 1)} {
	set url [export_vars -base change-activity-order {item_id run_id sort_order {dir 1}}]
	set down_node [$dom_doc createElement a]
	set img_node [$dom_doc createElement img]
	$img_node setAttribute src "/resources/imsld/arrow_down.png"
	$img_node setAttribute alt "Down"
	$down_node appendChild $img_node
	$down_node setAttribute href {\#}
	$down_node setAttribute onclick "return loadTree('$url')"
	$dom_node appendChild $down_node
    }
}

ad_proc -public imsld::monitor::structure_activities_list {
    -imsld_id
    -run_id
    -structure_item_id
    -role_part_id
    -play_id
    -act_id
    -dom_node
    -dom_doc
} {
    @param imsld_id
    @param run_id
    @param structure_item_id
    @param role_part_id
    @param play_id
    @param act_id

    @return A list of lists of the activities referenced from the activity structure
} {
    # auxiliary list to store the activities
    set completed_list [list]
    # get the structure info
    db_1row structure_info { 
        select structure_id,
        structure_type
        from imsld_activity_structuresi
        where item_id = :structure_item_id
    }
    # get the referenced activities which are referenced from the
    # structure
    set activities_list [db_list_of_lists struct_referenced_activities {
        select ar.object_id_two,
        ar.rel_type,
        ar.rel_id,
	ir.sort_order
        from acs_rels ar, imsld_activity_structuresi ias,
	(select * from imsld_as_la_rels union select * from imsld_as_sa_rels union
	 select * from imsld_as_as_rels) as ir
        where ar.object_id_one = ias.item_id
	and ar.rel_id = ir.rel_id
        and ias.structure_id = :structure_id
        order by ir.sort_order, ar.object_id_two
    }]

    set activities_number [llength $activities_list]

    foreach referenced_activity $activities_list {
        # get all the directly referenced activities (from the activity structure)
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        set rel_id [lindex $referenced_activity 2]
        set sort_order [lindex $referenced_activity 3]
        switch $rel_type {
            imsld_as_la_rel {
                # add the activiti to the TCL list
                db_1row get_learning_activity_info {
                    select la.title as activity_title,
                    la.item_id as activity_item_id,
                    la.activity_id,
                    la.complete_act_id
                    from imsld_learning_activitiesi la
                    where la.item_id = :object_id_two
                    and content_revision__is_live(la.activity_id) = 't'
                }

                set activity_node [imsld::monitor::link_to_visitors_info \
				       -dom_doc $dom_doc \
				       -title "$activity_title" \
				       -href "[export_vars -base "activity-frame" -url {activity_id run_id {type "learning"}}]" \
				       -onclick "return loadContent('[export_vars -base "activity-frame" -url {activity_id run_id {type "learning"}}]')" \
				       -run_id $run_id \
				       -revision_id $activity_id \
				       -type "activity" \
				       -sort \
				       -sort_order $sort_order \
				       -number_elements $activities_number]

                set completed_list [linsert $completed_list \
					$sort_order [$activity_node asList]]
            }
            imsld_as_sa_rel {
                # add the activity to the TCL list
                db_1row get_support_activity_info {
                    select sa.title as activity_title,
                    sa.item_id as activity_item_id,
                    sa.activity_id,
                    sa.complete_act_id
                    from imsld_support_activitiesi sa
                    where sa.item_id = :object_id_two
                    and content_revision__is_live(sa.activity_id) = 't'
                }

                set activity_node [imsld::monitor::link_to_visitors_info \
				       -dom_doc $dom_doc \
				       -title $activity_title \
				       -href "[export_vars -base "activity-frame" -url {activity_id run_id {type "support"}}]" \
				       -onclick "return loadContent('[export_vars -base "activity-frame" -url {activity_id run_id {type "support"}}]')" \
				       -run_id $run_id \
				       -revision_id $activity_id \
				       -type "activity" \
				       -sort
				       -sort_order $sort_order \
				       -number_elements $activities_number]

                set completed_list [linsert $completed_list $sort_order [$activity_node asList]]
            }
            imsld_as_as_rel {
                db_1row get_activity_structure_info {
                    select title as activity_title,
                    item_id as structure_item_id,
                    structure_id,
                    structure_type
                    from imsld_activity_structuresi
                    where item_id = :object_id_two
                    and content_revision__is_live(structure_id) = 't'
                }

                set structure_node [imsld::monitor::link_to_visitors_info \
					-dom_doc $dom_doc \
					-title $activity_title \
					-href "[export_vars -base "activity-frame" \
                              -url {{activity_id "$structure_id"} run_id {type "structure"}}]" \
				       -onclick "return loadContent('[export_vars -base "activity-frame" -url {activity_id run_id {type "structure"}}]')" \
					-run_id $run_id \
					-revision_id $structure_id \
					-type "activity" \
					-sort \
					-sort_order $sort_order \
					-number_elements $activities_number]
				    

                set nested_activities_list [imsld::monitor::structure_activities_list -imsld_id $imsld_id \
                                                -run_id $run_id \
                                                -structure_item_id $structure_item_id \
                                                -role_part_id $role_part_id \
                                                -play_id $play_id \
                                                -act_id $act_id \
                                                -dom_node $structure_node \
                                                -dom_doc $dom_doc]
		set ul_node [$dom_doc createElement ul]	    
		foreach nested_activity $nested_activities_list {
		    $ul_node appendFromList $nested_activity
		}
		$structure_node appendChild $ul_node
                set completed_list [linsert $completed_list $sort_order [$structure_node asList]]
            }
        }
    }
    return $completed_list
}

ad_proc -public imsld::monitor::activities_tree {
    -run_id:required
    -dom_node
    -dom_doc
} {
    @param run_id
    @param dom_node
    @param dom_doc

    @return A list of lists of all the activities in the run
} {
    db_1row imsld_info {
        select imsld_id 
        from imsld_runs
        where run_id = :run_id
    }

    # get the referenced role parts
    foreach role_part_list [db_list_of_lists referenced_role_parts {
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
        order by ip.sort_order, ia.sort_order, rp.sort_order
    }] {
        set type [lindex $role_part_list 0]
        set activity_id [lindex $role_part_list 1]
        set role_part_id [lindex $role_part_list 2]
        set act_id [lindex $role_part_list 3]        
        set play_id [lindex $role_part_list 4]
        switch $type {
            learning {
                # add the learning activity to the tree
                db_1row get_learning_activity_info {
                    select la.title as activity_title,
                    la.item_id as activity_item_id,
                    la.activity_id,
                    la.complete_act_id
                    from imsld_learning_activitiesi la
                    where activity_id = :activity_id
                }
                set activity_node [imsld::monitor::link_to_visitors_info \
				       -dom_doc $dom_doc \
				       -title $activity_title \
				       -href "[export_vars -base "activity-frame" \
                              -url {activity_id run_id {type "learning"}}]" \
				       -onclick "return loadContent('[export_vars -base "activity-frame" -url {activity_id run_id {type "learning"}}]')" \
				       -run_id $run_id \
				       -revision_id $activity_id \
				       -type "activity"]
                
                $dom_node appendChild $activity_node
            }
            support {
                # add the support activity to the tree
                db_1row get_support_activity_info {
                    select sa.title as activity_title,
                    sa.item_id as activity_item_id,
                    sa.activity_id,
                    sa.complete_act_id
                    from imsld_support_activitiesi sa
                    where sa.activity_id = :activity_id
                }
                set activity_node [imsld::monitor::link_to_visitors_info \
				       -dom_doc $dom_doc \
				       -title $activity_title \
				       -href "[export_vars -base "activity-frame" \
                              -url {activity_id run_id {type "support"}}]"\
				       -onclick "return loadContent('[export_vars -base "activity-frame" -url {activity_id run_id {type "support"}}]')" \
				       -run_id $run_id \
				       -revision_id $activity_id \
				       -type "activity"]
                
                $dom_node appendChild $activity_node
            }
            structure {
                db_1row get_activity_structure_info {
                    select title as activity_title,
                    item_id as structure_item_id,
                    structure_id,
                    structure_type
                    from imsld_activity_structuresi
                    where structure_id = :activity_id
                }

                set structure_node [imsld::monitor::link_to_visitors_info \
					-dom_doc $dom_doc \
					-title $activity_title \
					-href "[export_vars -base "activity-frame" \
                                -url {activity_id run_id {type "structure"}}]" \
					-onclick "return loadContent('[export_vars -base "activity-frame" -url {activity_id run_id {type "structure"}}]')" \
					-run_id $run_id \
					-revision_id $structure_id \
					-type "activity"]

                set nested_list [imsld::monitor::structure_activities_list -imsld_id $imsld_id \
                                     -run_id $run_id \
                                     -structure_item_id $structure_item_id \
                                     -role_part_id $role_part_id \
                                     -play_id $play_id \
                                     -act_id $act_id \
                                     -dom_doc $dom_doc \
                                     -dom_node $dom_node]
                # the nested finished activities are returned as a tcl list in tDOM format
		if {[llength $nested_list]} {
		    $structure_node appendFromList [list ul [list] [concat [list] $nested_list]]
		}
                $dom_node appendChild $structure_node
            }
        }
    }
}

ad_proc -public imsld::monitor::properties_tree {
    -run_id:required
    -dom_node
    -dom_doc
} {
    @param run_id
    @param dom_node
    @param dom_doc

    @return A list of lists of all the properties associated with the run (and the global properties)
} {
    db_1row imsld_info {
        select imsld_id 
        from imsld_runs
        where run_id = :run_id
    }

    # 1. local properties: associated to the run

    set local_node [$dom_doc createElement li]
    $local_node setAttribute class "liOpen"
    set a_node [$dom_doc createElement a]
    $a_node setAttribute href "[export_vars -base "properties-frame" -url {run_id {type "loc"}}]"
    $a_node setAttribute onclick "return loadContent('[export_vars -base "properties-frame" -url {run_id {type "loc"}}]')"
    set text [$dom_doc createTextNode "1. [_ imsld.Local_Properties]"]
    $a_node appendChild $text
    $local_node appendChild $a_node

    $dom_node appendChild $local_node

    # 2. loc-pers properties: associated to each user in the run

    set locpers_node [$dom_doc createElement li]
    $locpers_node setAttribute class "liOpen"
    set a_node [$dom_doc createElement a]
    $a_node setAttribute href "[export_vars -base "properties-frame" -url {run_id {type "locpers"}}]"
    $a_node setAttribute onclick "return loadContent('[export_vars -base "properties-frame" -url {run_id {type "locpers"}}]')"
    set text [$dom_doc createTextNode "2. [_ imsld.lt_Local-personal_Prop]"]
    $a_node appendChild $text
    $locpers_node appendChild $a_node

    $dom_node appendChild $locpers_node

    # 3. loc-role properties: associated to each role in the run

    set locrole_node [$dom_doc createElement li]
    $locrole_node setAttribute class "liOpen"
    set text [$dom_doc createTextNode "3. [_ imsld.lt_Local-role_Properti]"]
    $a_node appendChild $text
    $locrole_node appendChild $text

    set locrole_ul [$dom_doc createElement ul]

    foreach role_id_list [imsld::roles::get_list_of_roles -imsld_id $imsld_id] {
	set role_id [lindex $role_id_list 0]
	set role_node [$dom_doc createElement li]
	$role_node setAttribute class "liOpen"
	set a_node [$dom_doc createElement a]
	$a_node setAttribute href "[export_vars -base "properties-frame" -url {run_id role_id {type "locrole"}}]"
	$a_node setAttribute onclick "return loadContent('[export_vars -base "properties-frame" -url {run_id role_id {type "locrole"}}]')"
	set text [$dom_doc createTextNode "[content::item::get_title -item_id [content::revision::item_id -revision_id $role_id]]"]
	$a_node appendChild $text
	$role_node appendChild $a_node
	
	$locrole_ul appendChild $role_node
    }

    $locrole_node appendChild $locrole_ul
    $dom_node appendChild $locrole_node

    # 4. glob-pers properties: associated with the users

    set globpers_node [$dom_doc createElement li]
    $globpers_node setAttribute class "liOpen"
    set a_node [$dom_doc createElement a]
    $a_node setAttribute href "[export_vars -base "properties-frame" -url {run_id {type "globpers"}}]"
    $a_node setAttribute onclick "return loadContent('[export_vars -base "properties-frame" -url {run_id {type "globpers"}}]')"
    set text [$dom_doc createTextNode "4. [_ imsld.lt_Global-personal_Pro]"]
    $a_node appendChild $text
    $globpers_node appendChild $a_node

    $dom_node appendChild $globpers_node

    # 5. global: global properties

    set globpers_node [$dom_doc createElement li]
    $globpers_node setAttribute class "liOpen"
    set a_node [$dom_doc createElement a]
    $a_node setAttribute href "[export_vars -base "properties-frame" -url {run_id {type "glob"}}]"
    $a_node setAttribute onclick "return loadContent('[export_vars -base "properties-frame" -url {run_id {type "glob"}}]')"
    set text [$dom_doc createTextNode "5. [_ imsld.Global_Properties]"]
    $a_node appendChild $text
    $globpers_node appendChild $a_node

    $dom_node appendChild $globpers_node
}

ad_proc -public imsld::monitor::runtime_assigned_activities_tree {
    -run_id:required
    -dom_node
    -dom_doc
} {
    @param run_id
    @param dom_node
    @param dom_doc

    @return A list of lists of the activities 
} {
    # context info
    db_1row imsld_info {
        select imsld_id 
        from imsld_runs
        where run_id = :run_id
    }
    
    # 1. get any related activities to the rurn with the rel imsld_run_time_activities_rel
    # 2. get the info of those activities (role_part_id, act_id, play_id) and generate the list
    #    NOTE: the activity will be shown only once, no matter from how many role parts it is referenced

    # get the referenced activities to the run, assigned at runtime (notifications, level C)

    foreach activity_id [db_list runtime_activities {
        select distinct(activity_id) as activity_id
        from imsld_runtime_activities_rels
        where run_id = :run_id
    } ] {
        # get the activity_type
        if { [db_0or1row learning_activity_p {
            select 1
            from imsld_learning_activities
            where activity_id = :activity_id
        }] } {
            set activity_type learning
        } else {
            set activity_type support
        }
        set role_part_id [imsld::get_role_part_from_activity -activity_type $activity_type -leaf_id [content::revision::item_id -revision_id $activity_id]]
        
        # role_part context info
        db_1row role_part_context {
            select ia.act_id,
            ip.play_id
            from imsld_role_parts rp,
            imsld_actsi ia,
            imsld_playsi ip
            where rp.act_id = ia.item_id
            and ia.play_id = ip.item_id
            and rp.role_part_id = :role_part_id
            and content_revision__is_live(ip.play_id) = 't'
        }

        switch $activity_type {
            learning {
                # add the learning activity to the tree
                db_1row get_learning_activity_info {
                    select la.title as activity_title,
                    la.item_id as activity_item_id,
                    la.activity_id,
                    la.complete_act_id
                    from imsld_learning_activitiesi la
                    where activity_id = :activity_id
                }

                set activity_node [imsld::monitor::link_to_visitors_info \
				       -dom_doc $dom_doc \
				       -title $activity_title \
				       -href "[export_vars -base "activity-frame" \
                              -url {activity_id run_id {type "learning"}}]"\
				       -run_id $run_id \
				       -revision_id $activity_id \
				       -type "activity"]

                $dom_node appendChild $activity_node
            }
            support {
                # add the support activity to the tree
                db_1row get_support_activity_info {
                    select sa.title as activity_title,
                    sa.item_id as activity_item_id,
                    sa.activity_id,
                    sa.complete_act_id
                    from imsld_support_activitiesi sa
                    where sa.activity_id = :activity_id
                }

                set activity_node [imsld::monitor::link_to_visitors_info \
				       -dom_doc $dom_doc \
				       -title $activity_title \
				       -href "[export_vars -base "activity-frame" \
                               -url {activity_id run_id {type "support"}}]"\
				       -run_id $run_id \
				       -revision_id $activity_id \
				       -type "activity"]
                
                $dom_node appendChild $activity_node
            }
        }
    }
}

ad_proc -public imsld::monitor::environment_as_ul {
    {-activity_id 0}
    -environment_item_id:required
    -run_id:required
    -dom_node:required
    -dom_doc:required
} { 
    @param environment_item_id
    @param run_id
    @param dom_node
    @param dom_doc

    @return a html list (in a dom tree) of the associated resources, files and environments referenced from the given environment.
} {  
    # get environment info
    db_1row environment_info {
        select env.title as environment_title,
        env.environment_id
        from imsld_environmentsi env
        where env.item_id = :environment_item_id
        and content_revision__is_live(env.environment_id) = 't'
    }

    set environment_node_li [$dom_doc createElement li]
    $environment_node_li setAttribute class "liOpen"
    set text [$dom_doc createTextNode "$environment_title"]
    $environment_node_li appendChild $text
    set environment_node [$dom_doc createElement ul]
    # FIX-ME: if the ul is empty, the browser shows the ul incorrectly
    set text [$dom_doc createTextNode ""]    
    $environment_node appendChild $text

    foreach learning_objects_list [db_list_of_lists get_learning_object_info {
        select lo.item_id as learning_object_item_id,
        lo.learning_object_id,
        lo.identifier,
        coalesce(lo.title,lo.identifier) as lo_title,
        lo.class
        from imsld_learning_objectsi lo
        where lo.environment_id = :environment_item_id
        and content_revision__is_live(lo.learning_object_id) = 't'
        order by lo.creation_date
    }] {
        set learning_object_item_id [lindex $learning_objects_list 0]
        set learning_object_id [lindex $learning_objects_list 1]
        set identifier [lindex $learning_objects_list 2]
        set lo_title [lindex $learning_objects_list 3]
        set class_name [lindex $learning_objects_list 4]

        # learning object item. get the files associated
        set linear_item_list [db_list_of_lists item_linear_list {
            select ii.imsld_item_id
            from imsld_items ii,
            cr_items cr,
            acs_rels ar
            where ar.object_id_one = :learning_object_item_id
            and ar.object_id_two = cr.item_id
            and cr.live_revision = ii.imsld_item_id
        }]
        foreach imsld_item_id $linear_item_list {
            foreach environments_list [db_list_of_lists env_nested_associated_items {
                select cpr.resource_id,
                cr2.item_id as resource_item_id,
                cpr.type as resource_type,
		cpr.href as resource_href
                from imsld_cp_resources cpr, imsld_items ii,
                acs_rels ar, cr_items cr1, cr_items cr2
                where ar.object_id_one = cr1.item_id
                and ar.object_id_two = cr2.item_id
                and cr1.live_revision = ii.imsld_item_id
                and cr2.live_revision = cpr.resource_id 
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)
            }] {
                set resource_id [lindex $environments_list 0]
                set resource_item_id [lindex $environments_list 1]
                set resource_type [lindex $environments_list 2]
                set resource_href [lindex $environments_list 3]

                set lo_node [imsld::monitor::link_to_visitors_info \
				 -dom_doc $dom_doc \
				 -title $lo_title \
				 -href "[export_vars -base "activity-frame" \
                           -url {run_id learning_object_id {type learning_object}}]"\
				 -onclick "return loadContent('[export_vars -base "activity-frame" \
                           -url {run_id learning_object_id {type learning_object}}]')"\
				 -run_id $run_id \
				 -revision_id $learning_object_id \
				 -item_id $learning_object_item_id \
				 -type "learning_object"]
                
		set del_node [$dom_doc createElement a]
		$del_node setAttribute onclick "return loadEnvironment('[export_vars -base environment-edit {run_id activity_id environment_id {item_id $learning_object_item_id}}]')"
		$del_node setAttribute href "#no"
		$del_node setAttribute title "[_ imsld.Delete_URL]"

		set del_icon [$dom_doc createElement img]
		$del_node appendChild $del_icon
		$del_icon setAttribute src "/resources/acs-subsite/Delete16.gif"
		$del_icon setAttribute alt "[_ imsld.Delete]"
		$lo_node insertBefore $del_node [$lo_node firstChild]

		set edit_node [$dom_doc createElement a]
		$edit_node setAttribute onclick "return editEnvironment(this.parentNode,$run_id,$activity_id,$environment_id,$learning_object_item_id,\'$lo_title\',\'$resource_href\')"
		$edit_node setAttribute href "#no"
		$edit_node setAttribute title "[_ imsld.Edit_URL]"

		set edit_icon [$dom_doc createElement img]
		$edit_node appendChild $edit_icon
		$edit_icon setAttribute src "/resources/acs-subsite/Edit16.gif"
		$edit_icon setAttribute alt "[_ imsld.Edit]"
		$edit_icon setAttribute border "0"
		$lo_node insertBefore $edit_node [$lo_node firstChild]

                $environment_node appendChild $lo_node
            } 
        }
	
    }

    # services
    foreach services_list [db_list_of_lists get_service_info {
        select ise.service_id,
        ise.item_id as service_item_id,
        ise.identifier,
        ise.service_type,
        ise.title as service_title,
        ise.class
        from imsld_servicesi ise
        where ise.environment_id = :environment_item_id
        and content_revision__is_live(ise.service_id) = 't'
    }] {
        set service_id [lindex $services_list 0]
        set service_item_id [lindex $services_list 1]
        set identifier [lindex $services_list 2]
        set service_type [lindex $services_list 3]
        set service_title [expr { [string eq [lindex $services_list 4] ""] ? $environment_title : [lindex $services_list 4] }]
        set class_name [lindex $services_list 5]

        set service_node [imsld::monitor::link_to_visitors_info \
			      -dom_doc $dom_doc \
			      -title $service_title \
			      -href "[export_vars -base "activity-frame" \
                       -url {run_id service_id {type service}}]" \
			      -onclick "return loadContent('[export_vars -base "activity-frame" \
                       -url {run_id service_id {type service}}]')" \
			      -run_id $run_id \
			      -revision_id $service_id \
			      -type "service"]
        
	set del_node [$dom_doc createElement a]
	$del_node setAttribute onclick "return loadEnvironment('[export_vars -base environment-edit {run_id activity_id environment_id {item_id $service_id}}]')"
	$del_node setAttribute href "#no"
	set text [$dom_doc createTextNode "DEL"]
	$del_node appendChild $text
	$service_node appendChild [$dom_doc createTextNode " \["]
	$service_node appendChild $del_node
	$service_node appendChild [$dom_doc createTextNode "]"]

	$environment_node appendChild $service_node
	
    }

    # environments
    foreach nested_environment_item_id [db_list nested_environment {
        select ar.object_id_two as nested_environment_item_id
        from acs_rels ar
        where ar.object_id_one = :environment_item_id
        and ar.rel_type = 'imsld_env_env_rel'
    }] {
        imsld::monitor::environment_as_ul \
	    -environment_item_id $nested_environment_item_id \
            -run_id $run_id \
            -dom_node $environment_node \
            -dom_doc $dom_doc
    }
    $environment_node_li appendChild $environment_node

    set div_node [$dom_doc createElement div]
    set add_node [$dom_doc createElement a]
    $add_node setAttribute href "#"
    $add_node setAttribute onclick "return addEnvironment(this.parentNode, $environment_id, $run_id, $activity_id)"
    $add_node setAttribute title "[_ imsld.Add_URL]"

    set add_icon [$dom_doc createElement img]
    $add_node appendChild $add_icon
    $add_icon setAttribute src "/resources/acs-subsite/Add16.gif"
    $add_icon setAttribute alt "[_ imsld.Add_URL]"
    $add_icon setAttribute border "0"

    set text [$dom_doc createTextNode "[_ imsld.Add_URL]"]
    $add_node appendChild $text
    $div_node appendChild $add_node

#     set form_node [$dom_doc createElement form]
#     $form_node setAttribute action "environment-edit"
#     $form_node setAttribute onsubmit "return submitForm(this, 'environment')"

#     if { $activity_id } {
# 	set input_node [$dom_doc createElement input]
# 	$input_node setAttribute type "hidden"
# 	$input_node setAttribute name "activity_id"
# 	$input_node setAttribute value $activity_id
# 	$form_node appendChild $input_node
#     }

#     set input_node [$dom_doc createElement input]
#     $input_node setAttribute type "hidden"
#     $input_node setAttribute name "environment_id"
#     $input_node setAttribute value $environment_id
#     $form_node appendChild $input_node
#     set input_node [$dom_doc createElement input]
#     $input_node setAttribute type "hidden"
#     $input_node setAttribute name "run_id"
#     $input_node setAttribute value $run_id
#     $form_node appendChild $input_node
#     set text [$dom_doc createTextNode "URL:"]
#     $form_node appendChild $text
#     set input_node [$dom_doc createElement input]
#     $input_node setAttribute type "text"
#     $input_node setAttribute name "url"
#     $form_node appendChild $input_node
#     set input_node [$dom_doc createElement input]
#     $input_node setAttribute type "submit"
#     $input_node setAttribute value "Add"
#     $form_node appendChild $input_node

    $environment_node_li appendChild $div_node

    $dom_node appendChild $environment_node_li
}

ad_proc -public imsld::monitor::activity_environments_tree {
    -activity_item_id:required
    -run_id:required
    -dom_node
    -dom_doc
} {
    @param activity_item_id
    @param run_id
    @param rel_type
    @param dom_node
    @param dom_doc
    
    @return The html list (using tdom) of resources (learning objects and services) associated to the activity's environment(s)
} {
    # get the rel_type
    if { [db_0or1row is_imsld {
        select 1 from imsld_imsldsi where item_id = :activity_item_id
    }] } {
        return ""
    } elseif { [db_0or1row is_learning {
        select distinct 1 from imsld_learning_activitiesi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_la_env_rel
    } elseif { [db_0or1row is_support {
        select distinct 1 from imsld_support_activitiesi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_sa_env_rel
    } elseif { [db_0or1row is_structure {
        select distinct 1 from imsld_activity_structuresi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_as_env_rel
    } else {
        return -code error "IMSLD::imsld::monitor::activity_environments_tree: Invalid call"
    }
    # get environments
    set environments_list [list]
    set associated_environments_list [db_list la_associated_environments {
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :activity_item_id
        and ar.rel_type = :rel_type
        order by ar.object_id_two
    }]
    foreach environment_item_id $associated_environments_list {
        imsld::monitor::environment_as_ul -environment_item_id $environment_item_id \
	    -activity_id [content::item::get_live_revision -item_id $activity_item_id] \
            -run_id $run_id \
            -dom_node $dom_node \
            -dom_doc $dom_doc
    }
}

ad_proc -public imsld::monitor::number_of_visitors {
    -run_id:required
    -revision_id:required
    -item_id
    -type
} {
    @param revision_id
    @param item_id
    @param type
    
    @return The number of visitors of the activity/environment
} {
    set number_of_visitors 0

    switch $type {
        activity {
            set number_of_visitors [db_string visitors_count {
                select count(distinct(user_id))
                from imsld_status_user
                where status = 'started'
                and run_id = :run_id
                and related_id = :revision_id
            } -default 0]
        }
        learning_object {
            set item_list [db_list item_linear_list {
                select ii.imsld_item_id
                from imsld_items ii,
                cr_items cr,
                acs_rels ar
                where ar.object_id_one = :item_id
                and ar.object_id_two = cr.item_id
                and cr.live_revision = ii.imsld_item_id}]
            
            foreach imsld_item_id $item_list {
                lappend related_resources [db_list resources_list {
                    select cpr.resource_id
                    from imsld_cp_resources cpr, imsld_items ii,
                    acs_rels ar, cr_items cr1, cr_items cr2
                    where ar.object_id_one = cr1.item_id
                    and ar.object_id_two = cr2.item_id
                    and cr1.live_revision = ii.imsld_item_id
                    and cr2.live_revision = cpr.resource_id 
                    and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                         and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                         or ii.imsld_item_id = :imsld_item_id)}]
            }
            
            foreach resource_id $related_resources {
                incr number_of_visitors [db_string get_visitors {
                    select count(distinct(stat.user_id))
                    from imsld_status_user stat
                    where stat.run_id = :run_id
                    and related_id = :resource_id
                    and stat.status = 'finished'
                }]
            }
        }
        service {
            
            db_1row service_info {
                select service_type,
                item_id as service_item_id
                from imsld_servicesi
                where service_id = :revision_id
            }

            switch $service_type {
                conference {
                    db_1row conference_info {
                        select conf.conference_id,
                        conf.imsld_item_id as imsld_item_item_id,
                        cr.live_revision as imsld_item_id, 
                        conf.title as conf_title
                        from imsld_conference_servicesi conf, cr_items cr
                        where conf.service_id = :service_item_id
                        and cr.item_id = conf.imsld_item_id
                        and content_revision__is_live(cr.live_revision) = 't'
                    }

                    set related_resources [db_list conf_resources_list {
                        select cpr.resource_id
                        from imsld_cp_resourcesi cpr, imsld_itemsi ii,
                        acs_rels ar
                        where ar.object_id_one = ii.item_id
                        and ar.object_id_two = cpr.item_id
                        and content_revision__is_live(cpr.resource_id) = 't'
                        and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                             and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                             or ii.imsld_item_id = :imsld_item_id)
                    }]
                    set resources_count [llength $related_resources]

                    set number_of_visitors [llength [db_list count_visitors "
                        select count(user_id)
                        from imsld_status_user
                        where related_id in ([join $related_resources ","])
                        and status = 'finished'
                        and run_id = :run_id
                        group by user_id
                        having count(*) = [llength $related_resources]
                    "]]
                    
                } monitor {
                    db_1row monitor_info {
                        select ims.monitor_id,
                        ims.item_id as monitor_item_id,
                        cr.live_revision as imsld_item_id
                        from imsld_monitor_servicesi ims, cr_items cr
                        where ims.service_id = :service_item_id
                        and cr.item_id = ims.imsld_item_id
                        and content_revision__is_live(cr.live_revision) = 't'
                    }
                    
                    set related_resources [db_list conf_resources_list {
                        select cpr.resource_id
                        from imsld_cp_resourcesi cpr, imsld_itemsi ii,
                        acs_rels ar
                        where ar.object_id_one = ii.item_id
                        and ar.object_id_two = cpr.item_id
                        and content_revision__is_live(cpr.resource_id) = 't'
                        and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                             and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                             or ii.imsld_item_id = :imsld_item_id)
                    }]

                    set number_of_visitors [llength [db_list count_visitors "
                        select count(user_id)
                        from imsld_status_user
                        where related_id in ([join $related_resources ","])
                        and status = 'finished'
                        and run_id = :run_id
                        group by user_id
                        having count(*) = [llength $related_resources]
                    "]]

                } send-mail {
                    # 1. get the users associated to the run
                    # 2. get the users IN the run who have sent a bulk-mail message

                    # NOTE: The bulk mail package has a bug when storing the send_date (it's stored in YYYY-MM-DD format, withot the hour)
                    #       that's  why we have to do a little trick with the dates when comparing them, even though it's not 100% accurate
                    set number_of_visitors [db_string count_visitors {
                        select count(distinct(gmm.member_id))
                        from group_member_map gmm,
                        imsld_run_users_group_ext iruge, 
                        acs_rels ar1,
                        imsld_runs ir,
                        acs_objects ao,
                        bulk_mail_messages bm
                        where iruge.run_id=:run_id
                        and iruge.run_id = ir.run_id
                        and ar1.object_id_two=iruge.group_id 
                        and ar1.object_id_one=gmm.group_id 
                        and ao.object_id = bm.bulk_mail_id
                        and ao.creation_user = gmm.member_id
                        and to_date(bm.send_date,'YYYY-MM-DD') >= to_date(ir.creation_date,'YYYY-MM-DD')
                    } -default 0]
                }
            }
        }
    }
    return $number_of_visitors
}

ad_proc -public imsld::monitor::link_to_visitors_info {
    -dom_doc:required
    -title:required
    -href:required
    -run_id:required
    -revision_id:required
    -type:required
    -item_id
    -sort:boolean
    -sort_order
    -number_elements
    {-onclick ""}
} {
    @param dom_doc:required
    @param href:required
    @param run_id:required
    @param revision_id:required
    @param type:required
    @param item_id
    @param onclick
    @param sort:boolean
    @param sort_order
    @param number_elements

    <p>
    Adds to the given lo_node a link to the number of users visiting the
    activity in activity_id/run_id
    </p>
} {
    set result [$dom_doc createElement li]

    set a_node [$dom_doc createElement a]
    $a_node setAttribute href $href
    if { $onclick ne "" } {
	$a_node setAttribute onclick $onclick
    }
    $result appendChild $a_node

    set text [$dom_doc createTextNode "$title "]
    $a_node appendChild $text

    if { $type eq "learning_object" } {
	set visitors [imsld::monitor::number_of_visitors \
			  -run_id $run_id \
			  -revision_id $revision_id \
			  -item_id $item_id \
			  -type $type]
    } else {
	set visitors [imsld::monitor::number_of_visitors \
			  -run_id $run_id \
			  -revision_id $revision_id \
			  -type $type]
    }

    if { $visitors > 1 } {
	set text [$dom_doc createTextNode "($visitors  [_ imsld.users ])"]
    } elseif { $visitors > 0 } {
	set text [$dom_doc createTextNode "($visitors  [_ imsld.user ])"]
    } else {
	set text [$dom_doc createTextNode "([_ imsld.No_users ])"]
    }

    $result appendChild $text

    if { $sort_p } {
	if { ![info exists item_id] } {
	    set item_id [content::revision::item_id -revision_id $revision_id]
	}
	imsld::monitor::add_activity_sorting -item_id $item_id -run_id $run_id -dom_doc $dom_doc -dom_node $result \
	    -sort_order $sort_order -number_elements $number_elements
    }

    set activity_item_id [content::revision::item_id -revision_id $revision_id]
    set user_id [ad_conn user_id]
    imsld::generate_resources_tree -activity_item_id $activity_item_id -user_id $user_id -run_id $run_id -dom_node $result -dom_doc $dom_doc -monitor

    return $result
}
