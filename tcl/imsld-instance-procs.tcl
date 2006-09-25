# /packages/imsld/tcl/imsld-instance-procs.tcl

ad_library {
    Procedures in the imsld::instance namespace.
    
    @creation-date Abr 2006
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::instance {}

ad_proc -public imsld::instance::instantiate_imsld { 
    -imsld_id:required
    {-community_id ""}
} {
    @param imsld_id the imsld_id to instantiate
    @option community_id the community to which the imsld will be instantiated into

    @return the run_id created
    
    Instantiates an imsld, i.e. creates the run.
    If community_id is given, the run is created for that community (the users associated to the run are the users of the community) 
} {
    # 1. create the run (status = 'waiting')
    set run_id [package_exec_plsql -var_list [list [list run_id ""] [list imsld_id $imsld_id] [list status "waiting"]] imsld_run new]

    # 2. create the run group
    set group_run_id [package_instantiate_object -creation_user [ad_conn user_id]  -creation_ip [ad_conn peeraddr]  -package_name imsld_run_users_group -start_with "group"  -var_list [list [list group_id ""] [list group_name "IMS-LD Run Group ($run_id)"]  [list run_id $run_id]]  imsld_run_users_group]

    # 3. if community_id is not empty, assign the community users to the run
    if { ![string eq $community_id ""] } {
        foreach user [dotlrn_community::list_users $community_id] {
            set user_id [ns_set get $user user_id]
            relation_add imsld_run_users_group_rel $group_run_id $user_id
        }
    }
    imsld::instance::instantiate_properties -run_id $run_id
    imsld::instance::instantiate_activity_attributes -run_id $run_id
    return $run_id
}

ad_proc -public imsld::instance::instantiate_properties { 
    -run_id:required
} {
    @param run_id The run_id we are instantiating
    
    Instantiates the properties for a given run_id.
} {
    # There are 5 property types
    # 1. loc-proerty: same value for every user in the run
    # 2. locpers-property: different value for every user in the run
    # 3. locrole-property: same value for every user in the same rol during the run
    # 4. globpers-property: different value for every user (run and ims-ld independent)
    # 5. glob-property: one value independent from the run, ims-ld, user or role

    db_1row context_info {
        select ic.item_id as component_item_id,
        ii.imsld_id,
        rug.group_id as run_group_id
        from imsld_componentsi ic, imsld_imsldsi ii, imsld_runs ir, imsld_run_users_group_ext rug
        where ic.imsld_id = ii.item_id
        and content_revision__is_live(ii.imsld_id) = 't'
        and ii.imsld_id = ir.imsld_id
        and rug.run_id = ir.run_id
        and ir.run_id = :run_id
    }

    # 1. loc-property: We create only one entry in the imsld_property_instances table for each property of this type
    db_foreach loc_property {
        select property_id,
        identifier,
        datatype,
        initial_value
        from imsld_properties
        where component_id = :component_item_id
        and type = 'loc'
    } {
        if { ![db_0or1row loc_already_instantiated_p {
            select 1
            from imsld_property_instances
            where property_id = :property_id
            and run_id = :run_id
        }] } {
            set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list property_id $property_id] [list identifier $identifier] [list party_id ""] [list run_id $run_id] [list value $initial_value]] imsld_property_instance new]
        }
    }

    # 2. locpers-property: Instantiate the property for each user assigned to the run
    foreach property_list [db_list_of_lists locpers_property {
        select property_id,
        identifier,
        datatype,
        initial_value
        from imsld_properties
        where component_id = :component_item_id
        and type = 'locpers'
    }] {
        set property_id [lindex $property_list 0]
        set identifier [lindex $property_list 1]
        set datatype [lindex $property_list 2]
        set initial_value [lindex $property_list 3]
        db_foreach user_in_run {
            select ar.object_id_two as party_id
            from acs_rels ar
            where ar.object_id_one = :run_group_id
            and ar.rel_type = 'imsld_run_users_group_rel'
        } { 
            if { ![db_0or1row locrole_already_instantiated_p {
                select 1
                from imsld_property_instances
                where property_id = :property_id
                and party_id = :party_id
                and run_id = :run_id
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list property_id $property_id] [list identifier $identifier] [list party_id $party_id] [list run_id $run_id] [list value $initial_value]] imsld_property_instance new]
            }
        }
    }

    # 3. locrole-property: Instantiate the property for each role associated to the run
    db_foreach locrole_property {
        select property_id,
        identifier,
        datatype,
        initial_value
        from imsld_properties
        where component_id = :component_item_id
        and type = 'locrole'
    } {
        db_foreach roles_instances_in_run {
            select ar1.object_id_two as party_id
            from acs_rels ar1, acs_rels ar2, acs_rels ar3,
            public.imsld_run_users_group_ext run_group
            where ar1.rel_type = 'imsld_role_group_rel'
            and ar1.object_id_two = ar2.object_id_one
            and ar2.rel_type = 'imsld_roleinstance_run_rel'
            and ar2.object_id_two = ar3.object_id_one
            and ar3.object_id_one = run_group.group_id
            and run_group.run_id = :run_id
        } { 
            set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list property_id $property_id] [list identifier $identifier] [list party_id $party_id] [list run_id $run_id] [list value $initial_value]] imsld_property_instance new]
        }
    }

    # 4. globpers-property: Special case. The table imsld_property_instances must hold only one entrance for these properties.
    #                       Besides, if existng href exists, the value of the property is taken from the URI. Otherwise, if
    #                       global definition is not empty, then the property is defined.
    #                       The global definition is stored in the same row of the property_id, so the initial_value of 
    #                       the global_definition is in fact the initial_value of the property
    foreach property_list [db_list_of_lists globpers_property {
        select property_id,
        identifier,
        datatype,
        initial_value,
        existing_href,
        uri
        from imsld_properties
        where component_id = :component_item_id
        and type = 'globpers'
    }] {
        set property_id [lindex $property_list 0]
        set identifier [lindex $property_list 1]
        set datatype [lindex $property_list 2]
        set initial_value [lindex $property_list 3]
        set existing_href [lindex $property_list 4]
        set uri [lindex $property_list 5]
        db_foreach user_in_run {
            select ar.object_id_two as party_id
            from acs_rels ar
            where ar.object_id_one = :run_group_id
            and ar.rel_type = 'imsld_run_users_group_rel'
        } {
            if { ![db_0or1row globpers_already_instantiated_p {
                select 1 
                from imsld_property_instances
                where identifier = :identifier
                and party_id = :party_id
            }] } {
                # not instantiated... is it already defined (existing href)? or must we use the one of the global definition?
                if { ![string eq $existing_href ""] } {
                    # it is already defined
                    # NOTE: there must be a better way to deal with this, 
                    # but by the moment we treat the href as the property value
                    set initial_value $existing_href
                } 
                # TODO: the property must be somehow instantiated in the given URI also
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list property_id $property_id] [list identifier $identifier] [list party_id $party_id] [list run_id $run_id] [list value $initial_value]] imsld_property_instance new]
            }
        }
    }

    # 5. glob-property: Special case, just like the one above but with the difference that the checking
    #                   is not done for all the users
    db_foreach global_property {
        select property_id,
        identifier,
        datatype,
        initial_value,
        existing_href,
        uri
        from imsld_properties
        where component_id = :component_item_id
        and type = 'global'
    } {
        if { ![db_0or1row global_already_instantiated_p {
            select 1 
            from imsld_property_instances
            where identifier = :identifier
        }] } {
            # not instantiated... is it already defined (existing href)? or must we use the one of the global definition?
            if { ![string eq $existing_href ""] } {
                # it is already defined
                # NOTE: there must be a better way to deal with this, but by the moment we treat the href as the property value
                set initial_value $existing_href
            } 
            # TODO: the property must be somehow instantiated in the given URI also
            set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list property_id $property_id] [list identifier $identifier] [list party_id ""] [list run_id $run_id] [list value $initial_value]] imsld_property_instance new]
        }
    }

    return
}

ad_proc -public imsld::instance::instantiate_activity_attributes { 
    -run_id:required
} {
    @param run_id The run_id we are instantiating
    
    There are some attributes (like isvisible or the class global attributes) which are not properties but
    have to be instantiated because the context of those attributes is the context of the run. So anytime a run
    is created, those attributes must be initialized according to the values parsed from the manifest, and not
    from the possible changed values of a previous run.
} {

    set involved_roles [imsld::roles::get_list_of_roles -imsld_id [db_string get_imsld_from_run {select imsld_id from imsld_runs where run_id=:run_id}] ]
    set involved_users [list]
    foreach role $involved_roles {
        set involved_users [concat $involved_users [imsld::roles::get_users_in_role -role_id [lindex $role 0] -run_id $run_id]]
    }
    
    foreach user_id [lsort -unique $involved_users] { 
        
        db_1row context_info {
            select ic.item_id as component_item_id,
            ii.imsld_id,
            ii.learning_objective_id as imsld_learning_objective_id,
            ii.prerequisite_id as imsld_prerequisite_id,
            ii.item_id as run_imsld_item_id,
            rug.group_id as run_group_id
            from imsld_componentsi ic, imsld_imsldsi ii, imsld_runs ir, imsld_run_users_group_ext rug
            where ic.imsld_id = ii.item_id
            and content_revision__is_live(ii.imsld_id) = 't'
            and ii.imsld_id = ir.imsld_id
            and rug.run_id = ir.run_id
            and ir.run_id = :run_id
        }
        
        # 1. items --> learning objectives, prerequisites, roles, 
        #      learning objects, activity description, information(activity structures)
        
        # 1.1 learning objectives items
        set linear_item_list [db_list item_in_imsld_loi {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_learning_objectivesi lo
            where ar.object_id_one = lo.item_id
            and ar.object_id_two = ii.item_id
            and lo.learning_objective_id = :imsld_learning_objective_id
        }]
        
        set linear_item_list [concat $linear_item_list [db_list item_in_activity_loi {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_learning_activities ia, imsld_learning_objectivesi lo
            where ar.object_id_one = lo.item_id
            and ar.object_id_two = ii.item_id
            and ia.learning_objective_id = lo.item_id
            and ia.component_id = :component_item_id
        }]]
        
        # 1.2. prerequisites
        set linear_item_list [concat $linear_item_list [db_list item_in_imsld_pre {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_prerequisitesi pre
            where ar.object_id_one = pre.item_id
            and ar.object_id_two = ii.item_id
            and pre.prerequisite_id = :imsld_prerequisite_id
        }]]
        
        set linear_item_list [concat $linear_item_list [db_list item_in_activity_pre {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_learning_activities ia, imsld_prerequisitesi pre
            where ar.object_id_one = pre.item_id
            and ar.object_id_two = ii.item_id
            and ia.prerequisite_id = pre.item_id
            and ia.component_id = :component_item_id
        }]]

        # 1.3. roles
        set linear_item_list [concat $linear_item_list [db_list item_in_role {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_rolesi ir
            where ar.object_id_one = ir.item_id
            and ar.object_id_two = ii.item_id
            and ir.component_id = :component_item_id
        }]]

        # 1.4. learning objects (environments)
        set linear_item_list [concat $linear_item_list [db_list item_in_lo {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_learning_objectsi lo, imsld_environmentsi env
            where ar.object_id_one = lo.item_id
            and ar.object_id_two = ii.item_id
            and lo.environment_id = env.item_id
            and env.component_id = :component_item_id
        }]]
        
        # 1.5. activity description (learning activities)
        set linear_item_list [concat $linear_item_list [db_list item_in_la_desc {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_learning_activitiesi la, imsld_activity_descsi ad
            where ar.object_id_one = ad.item_id
            and ar.object_id_two = ii.item_id
            and la.activity_description_id = ad.item_id
            and la.component_id = :component_item_id
        }]]

        # 1.6. activity description (support activities)
        set linear_item_list [concat $linear_item_list [db_list item_in_sa_desc {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_support_activitiesi sa, imsld_activity_descsi ad
            where ar.object_id_one = ad.item_id
            and ar.object_id_two = ii.item_id
            and sa.activity_description_id = ad.item_id
            and sa.component_id = :component_item_id
        }]]
        
        # 1.7. information(activity structures)
        set linear_item_list [concat $linear_item_list [db_list item_in_as_info {
            select ii.imsld_item_id
            from acs_rels ar, imsld_itemsi ii, imsld_activity_structuresi ast
            where ar.object_id_one = ast.item_id
            and ar.object_id_two = ii.item_id
            and ast.component_id = :component_item_id
        }]]

        foreach imsld_item_id $linear_item_list {
            db_foreach nested_associated_items {
                select ii.imsld_item_id, ii.item_id,
                coalesce(ii.is_visible_p, 't') as is_visible_p,
                ii.identifier
                from imsld_itemsi ii
                where (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                       and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                       or ii.imsld_item_id = :imsld_item_id)
            } {
                if { ![db_0or1row info_as_already_instantiated_p {
                    select 1
                    from imsld_attribute_instances
                    where owner_id = :imsld_item_id
                    and run_id = :run_id
                    and user_id = :user_id
                    and type = 'isvisible'
                }] } {
                    ns_log Notice "antes del tema: $user_id"
                    set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id $imsld_item_id] [list type "isvisible"] [list identifier $identifier] [list run_id $run_id] [list user_id $user_id] [list is_visible_p $is_visible_p] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
                    ns_log Notice "despues del tema"
                }
            }
        }

        # 2. learning activities
        db_foreach learning_activity {
            select la.activity_id,
            coalesce(la.is_visible_p, 't') as is_visible_p,
            la.identifier
            from imsld_learning_activities la
            where la.component_id = :component_item_id
        } {
            if { ![db_0or1row la_already_instantiated_p {
                select 1
                from imsld_attribute_instances
                where owner_id = :activity_id
                and run_id = :run_id
                and user_id = :user_id
                and type = 'isvisible'
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id $activity_id] [list type "isvisible"] [list identifier $identifier] [list run_id $run_id] [list user_id $user_id] [list is_visible_p $is_visible_p] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
            }
        }
        
        # 3. support activities
        db_foreach support_activity {
            select sa.activity_id,
            coalesce(sa.is_visible_p, 't') as is_visible_p,
            sa.identifier
            from imsld_support_activities sa
            where sa.component_id = :component_item_id
        } {
            if { ![db_0or1row sa_already_instantiated_p {
                select 1
                from imsld_attribute_instances
                where owner_id = :activity_id
                and run_id = :run_id
                and user_id = :user_id
                and type = 'isvisible'
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id $activity_id] [list type "isvisible"] [list identifier $identifier] [list run_id $run_id] [list user_id $user_id] [list is_visible_p $is_visible_p] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
            }
        }

        # 4. learning object (environment)
        db_foreach learning_object {
            select lo.learning_object_id,
            coalesce(lo.is_visible_p, 't') as is_visible_p,
            class,
            lo.identifier
            from imsld_learning_objects lo, imsld_environmentsi env
            where lo.environment_id = env.item_id
            and env.component_id = :component_item_id
        } {
            if { ![db_0or1row lo_already_instantiated_p {
                select 1
                from imsld_attribute_instances
                where owner_id = :learning_object_id
                and run_id = :run_id
                and user_id = :user_id
                and type = 'isvisible'
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id $learning_object_id] [list type "isvisible"] [list identifier $identifier] [list run_id $run_id] [list user_id $user_id] [list is_visible_p $is_visible_p] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
            }
            if { ![string eq "" $class] && ![db_0or1row lo_env_already_instantiated_p {
                select 1
                from imsld_attribute_instances
                where run_id = :run_id
                and user_id= :user_id
                and type = 'class'
                and identifier = :class
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id ""] [list type "class"] [list identifier $class] [list run_id $run_id] [list user_id $user_id] [list is_visible_p "t"] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
            }
        }

        # 5. service (enviroment)
        db_foreach service {
            select serv.service_id,
            coalesce(serv.is_visible_p, 't') as is_visible_p,
            class,
            serv.identifier
            from imsld_services serv, imsld_environmentsi env
            where serv.environment_id = env.item_id
            and env.component_id = :component_item_id
        } {
            if { ![db_0or1row serv_already_instantiated_p {
                select 1
                from imsld_attribute_instances
                where owner_id = :service_id
                and run_id = :run_id
                and user_id = :user_id
                and type = 'isvisible'
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id $service_id] [list type "isvisible"] [list identifier $identifier] [list run_id $run_id] [list user_id $user_id] [list is_visible_p $is_visible_p] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
            }
            if { ![string eq "" $class] && ![db_0or1row serv_env_already_instantiated_p {
                select 1
                from imsld_attribute_instances
                where run_id = :run_id
                and user_id = :user_id
                and type = 'class'
                and identifier = :class
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id ""] [list type "class"] [list identifier $class] [list run_id $run_id] [list user_id $user_id] [list is_visible_p "t"] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
            }
        }

        # 6. play
        db_foreach play {
            select play.play_id,
            coalesce(play.is_visible_p, 't') as is_visible_p,
            play.identifier
            from imsld_plays play, imsld_methodsi im
            where play.method_id = im.item_id
            and im.imsld_id = :run_imsld_item_id
        } {
            if { ![db_0or1row play_already_instantiated_p {
                select 1
                from imsld_attribute_instances
                where owner_id = :play_id
                and run_id = :run_id
                and user_id = :user_id
                and type = 'isvisible'
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id $play_id] [list type "isvisible"] [list identifier $identifier] [list run_id $run_id] [list user_id $user_id] [list is_visible_p $is_visible_p] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
            }
        }

        # 7. classes
        db_foreach class {
            select cla.class_id,
            cla.identifier
            from imsld_classesi cla, imsld_methodsi im
            where cla.method_id = im.item_id
            and im.imsld_id = :run_imsld_item_id
        } {
            if { ![db_0or1row already_instantiated {
                select 1 from imsld_attribute_instances
                where identifier = :identifier
                and run_id = :run_id
                and user_id = :user_id
            }] } {
                set instance_id [package_exec_plsql -var_list [list [list instance_id ""] [list owner_id ""] [list type "class"] [list identifier $identifier] [list run_id $run_id] [list user_id $user_id] [list is_visible_p "t"] [list title ""] [list with_control_p ""]] imsld_attribute_instance new]
            }
        }
    }
    return
}

ad_proc -public imsld::instance::delete_imsld_instance { 
    -run_id:required
} {
    @param run_id the run_id to delete

    @return 1 if successful, 0 otherwise
    
} {
    return [package_exec_plsql -var_list [list  [list run_id $run_id]] imsld_run del]
}


