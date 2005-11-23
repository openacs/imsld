# /packages/imsld/tcl/imsld-procs.tcl

ad_library {
    Procedures in the imsld namespace.
    
    @creation-date Aug 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}

ad_proc -public imsld::safe_url_name { 
    -name:required
} { 
    returns the filename replacing some characters
} {  
    regsub -all {[<>:\"|/@\\\#%&+\\ ,\?]} $name {_} name
    return $name
} 

ad_proc -public imsld::rel_type_delete { 
    -rel_type:required
} { 
    Deletes a rel type (since the rel_types does not have a delete proc)
} {  

    db_1row select_type_info {
        select t.table_name 
        from acs_object_types t
        where t.object_type = :rel_type
    }
    
    set rel_id_list [db_list select_rel_ids {
        select r.rel_id
        from acs_rels r
        where r.rel_type = :rel_type
    }]
    
    # delete all relations and drop the relationship
    # type. 
    
    db_transaction {
        foreach rel_id $rel_id_list {
            relation_remove $rel_id
        }
        
        db_exec_plsql drop_relationship_type {
            BEGIN
            acs_rel_type.drop_type( rel_type  => :rel_type,
                                    cascade_p => 't' );
            END;
        }
    } on_error {
        ad_return_error "Error deleting relationship type" "We got the following error trying to delete this relationship type:<pre>$errmsg</pre>"
        ad_script_abort
    }
    # If we successfully dropped the relationship type, drop the table.
    # Note that we do this outside the transaction as it commits all
    # transactions anyway
    if { [db_table_exists $table_name] } {
        db_exec_plsql drop_type_table "drop table $table_name"
    }
} 

ad_proc -public imsld::item_revision_new {
    {-attributes ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -content_type
    -edit:boolean
    -parent_id
} {
    Creates a new revision of a content item, calling the cr functions. 
    If editing, only a new revision is created, otherwise an item is created too.

    @option attributes A list of lists of pairs of additional attributes and their values.
    @option title 
    @option package_id 
    @option user_id 
    @option creation_ip 
    @option creation_date 
    @option edit Are we editing the manifest?
    @param parent_id Identifier of the parent folder
} {

    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [string eq "" $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [string eq "" $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [string eq "" $package_id] ? [ad_conn package_id] : $package_id }]
    set item_id [expr { [string eq "" $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]

    set item_name "${item_id}_content_type"
    set title [expr { [string eq "" $title] ? $item_name : $title }]
    
    if { !$edit_p } {
        # create
        set item_id [content::item::new -item_id $item_id \
                         -name $item_name \
                         -content_type $content_type \
                         -parent_id $parent_id \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -context_id $package_id]
    }
    
    if { ![string eq "" $attributes] } {
        set revision_id [content::revision::new -item_id $item_id \
                             -title $title \
                             -content_type $content_type \
                             -creation_user $user_id \
                             -creation_ip $creation_ip \
                             -item_id $item_id \
                             -is_live "t" \
                             -attributes $attributes]
    } else {
        set revision_id [content::revision::new -item_id $item_id \
                             -title $title \
                             -content_type $content_type \
                             -creation_user $user_id \
                             -creation_ip $creation_ip \
                             -item_id $item_id \
                             -is_live "t"]
    }
    
    return $item_id
}

ad_proc -public imsld::finish_component_element {
    -imsld_id
    -role_part_id
    -element_id
    -type
    -recursive_call:boolean
} {
    @option imsld_id
    @option role_part_id
    @option element_id
    @option type
    @option recursive_call

    Mark as finished the given component_id. This is done by adding a row in the table insert_entry.

    This function is called from a url, but it can also be called recursively
} {

    if { !$recursive_call_p } {
        # get the url for parse it and get the info
        set url [ns_conn url]
        regexp {finish-component-element-([0-9]+)-([0-9]+)-([0-9]+)-([a-z]+).imsld$} $url match imsld_id role_part_id element_id type
        regsub {/finish-component-element.*} $url "" return_url 
    }
    set user_id [ad_conn user_id]
    # now that we have the necessary info, mark the finished element completed and return
    db_dml insert_entry {
        insert into imsld_status_user
        values (
                :imsld_id,
                :role_part_id,
                :element_id,
                :user_id,
                :type,
                now()
                )
    }

    if { [db_0or1row referenced_p {
        select ias.structure_id,
        ias.item_id as structure_item_id
        from acs_rels ar, imsld_activity_structuresi ias, cr_items cri
        where ar.object_id_one = ias.item_id
        and ar.object_id_two = cri.item_id
        and cri.live_revision = :element_id
    }] } {
        # if this activity is part of an activity structure, let's check if the rest of referenced 
        # activities are finished too, so we can mark finished the activity structure as well
        set scturcture_finished_p 1
        db_foreach referenced_activity {
            select content_item__get_live_revision(ar.object_id_two) as activity_id
            from acs_rels ar
            where ar.object_id_one = :structure_item_id
            and ar.rel_type in ('imsld_as_la_rel','imsld_as_sa_rel','imsld_as_as_rel')
        } {
            if { ![db_string completed_p {
                select count(*) from imsld_status_user where completed_id = :activity_id
            }] } {
                # there is at leas one no-completed activity, so we can't mark this activity structure yet
                set scturcture_finished_p 0
            }
        }
        if { $scturcture_finished_p } {
            imsld::finish_component_element -imsld_id $imsld_id \
                -role_part_id $role_part_id \
                -element_id $structure_id \
                -type structure \
                -recursive_call
        }
    }
    if { !$recursive_call_p } {
        ad_returnredirect "${return_url}"
    }
} 

# ad_proc -public imsld::root_activity {
#     -activity_type
#     -leaf_id
# } { 
#     @return The root activity for the nested activity (referenced by leaf_id)
# } {
#     switch $activity_type {
#         learning {
#             # the learning activity is referenced by an activity structure... digg more
#             db_1row get_la_activity_structure {
#                 select as.structure_id, as.item_id as structure_item_id
#                 from imsld_activity_strucutresi as, acs_rels ar, imsld_learning_activitiesi la
#                 where ar.object_id_one = as.item_id
#                 and ar.object_id_two = la.item_id
#                 and content_revision__is_live(la.activity_id) = 't'
#                 and content_revision__is_live(as.structure_id) = 't'
#                 and la.activity_id = :leaf_id
#             }
#         }
#         support {
#         }
#         structure {
#             # the activity structure is referenced by an activity structure... digg more
#             db_1row get_as_activity_structure {
#                 select as.structure_id, as.item_id as structure_item_id
#                 from imsld_activity_strucutresi as, acs_rels ar, imsld_activity_structuresi as_leaf
#                 where ar.object_id_one = as.item_id
#                 and ar.object_id_two = as_leaf.item_id
#                 and content_revision__is_live(as_leaf.structure_id) = 't'
#                 and content_revision__is_live(as.structure_id) = 't'
#                 and as_leaf.structure_id = :leaf_id
#             }
#         }
#     }
#     if { [db_string is_referenced_p {
#         select count(*) 
#         from imsld_role_parts irp, imsld_activity_structures as
#         where irp.learning_activity_id = :structure_item_id
#         and as.activity_id = :sructure_id
#     }] } {
#         # the activity is referenced from this role part, so it is the root activity, the one we are looking for
#         return $structure_id 
#     } else {
#         # nested activity, try again
#         return [imsld::root_activity -activity_type structure -leaf_id $structure_id]
#     }
# } 

ad_proc -public imsld::structure_next_activity {
    -activity_structure_id:required
    {-environment_list ""}
} { 
    @return The next learning or support activity (and the type) in the activity structure. 0 if there are none (which should never happen)
} {
    set min_sort_order ""
    set next_activity_id ""
    set next_activity_type ""
    # get referenced activities
    foreach referenced_activity [db_list_of_lists struct_referenced_activities {
        select ar.object_id_two,
        ar.rel_type
        from acs_rels ar, imsld_activity_structuresi ias
        where ar.object_id_one = ias.item_id
        and ias.structure_id = :activity_structure_id
        order by ar.object_id_two
    }] {
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        switch $rel_type {
            imsld_as_la_rel {
                # find out if is the next one
                db_1row get_la_info {
                    select sort_order, 
                    activity_id as learning_activity_id
                    from imsld_learning_activitiesi
                    where item_id = :object_id_two
                    and content_revision__is_live(activity_id) = 't'
                }
                if { ![db_0or1row completed_p {
                    select 1
                    from imsld_status_user
                    where completed_id = :learning_activity_id
                }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $learning_activity_id
                    set next_activity_type learning
                }
            }
            imsld_as_sa_rel {
                # find out if is the next one
                db_1row get_sa_info {
                    select sort_order, 
                    activity_id as support_activity_id
                    from imsld_support_activitiesi
                    where item_id = :object_id_two
                    and content_revision__is_live(activity_id) = 't'
                }
                if { ![db_0or1row completed_p {
                    select 1
                    from imsld_status_user
                    where completed_id = :support_activity_id
                }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $support_activity_id
                    set next_activity_type support
                }
            }
            imsld_as_as_rel {
                # recursive call?

                db_1row get_as_info {
                    select sort_order, structure_id, item_id
                    from imsld_activity_structuresi
                    where item_id = :object_id_two
                    and content_revision__is_live(structure_id) = 't'
                }

                if { ![db_0or1row completed_p { 
                    select 1 
                    from imsld_status_user 
                    where completed_id = :structure_id
                }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set activity_id $structure_id
                    set next_activity_type structure
                }
            }
            imsld_as_env_rel {
                if { [llength $environment_list] } {
                    set environment_list [concat [list $environment_list] [list [imsld::process_environment -environment_item_id $object_id_two]]]
                } else {
                    set environment_list [imsld::process_environment -environment_item_id $object_id_two]
                }
            }
        }
    } 
#     if { [string eq "" $next_activity_id] } {
#         ad_return_error "<#_ No referenced activities #>" "<#_ No referenced activities for activity_structure $activity_structure_id. This should never happen."
#         ad_script_abort
#     }

    if { [string eq $next_activity_type structure] } {
        set next_activity_list [imsld::structure_next_activity -activity_structure_id $activity_id -environment_list $environment_list]
        set next_activity_id [lindex $next_activity_list 0]
        set next_activity_type [lindex $next_activity_list 1]
        set environment_list [concat $environment_list [lindex $next_activity_list 2]]
    }
    return [list $next_activity_id $next_activity_type $environment_list]
} 

ad_proc -public imsld::role_part_finished_p { 
    -role_part_id:required
} { 
    @param role_part_id Role Part identifier
    
    @return 0 or 1
} {
    db_1row get_role_part_activity {
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
    }
    switch $type {
        learning {
            if { [db_string completed {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:learning_activity_id)
            }] } {
                return 1
            }
        }
        support {
            if { [db_string completed {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:support_activity_id)
            }] } {
                return 1
            }
        }
        structure {
            if { [db_string completed {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:activity_structure_id)
            }] } {
                return 1
            }
        }
        none {
            return 1
        }
    }
    return 0
} 

ad_proc -public imsld::process_service {
    -service_item_id:required
} { 
    returns a list of the associated resources referenced from the given service.
} {
    set services_list [list]

    # get service info
    db_1row service_info {
        select serv.service_id,
        serv.identifier,
        serv.class,
        serv.is_visible_p,
        serv.service_type
        from imsld_servicesi serv 
        where serv.item_id = :service_item_id
        and content_revision__is_live(serv.service_id) = 't'
    }

    switch $service_type {
        conference {
            db_1row get_conference_info {
                select conf.conference_id,
                conf.conference_type,
                conf.imsld_item_id as imsld_item_item_id,
                cr.live_revision as imsld_item_id
                from imsld_conference_services conf, cr_items cr
                where conf.service_id = :service_item_id
                and cr.item_id = conf.imsld_item_id
                and content_revision__is_live(cr.live_revision) = 't'
            }
            db_foreach serv_associated_items {
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
            } {
                append one_service_url "[imsld::process_resource -resource_item_id $resource_item_id]"
                if { [string eq "" $one_service_url] } {
                    lappend services_list "[_ imsld.lt_li_desc_no_file_assoc]"
                } else {
                    set services_list [concat [list $services_list] [list $one_service_url]]
                }
            } if_no_rows {
                ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
            }
        }
        default {
            return "not_implemented_yet"
        }
    }
    return "$services_list"
}

ad_proc -public imsld::process_environment {
    -environment_item_id:required
    {-community_id ""}
} { 
    returns a list of the associated resources, files and environments referenced from the given environment.
} {  
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]

    # get environment info
    db_1row environment_info {
        select env.identifier as environment_title,
        env.environment_id
        from imsld_environmentsi env
        where env.item_id = :environment_item_id
        and content_revision__is_live(env.environment_id) = 't'
    }

    set environment_learning_objects_list [list]
    if { [db_0or1row get_learning_object_info {
        select item_id as learning_object_item_id,
        learning_object_id,
        identifier
        from imsld_learning_objectsi
        where environment_id = :environment_item_id
        and content_revision__is_live(learning_object_id) = 't'
    }] } {
        # learning object item. get the files associated
        set linear_item_list [db_list item_linear_list {
            select ii.imsld_item_id
            from imsld_items ii,
            cr_items cr,
            acs_rels ar
            where ar.object_id_one = :learning_object_item_id
            and ar.object_id_two = cr.item_id
            and cr.live_revision = ii.imsld_item_id
        }]
        foreach imsld_item_id $linear_item_list {
            db_foreach env_nested_associated_items {
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
            } {
                set one_learning_object_list [imsld::process_resource -resource_item_id $resource_item_id]
                if { [string eq "" $one_learning_object_list] } {
                    lappend environment_learning_objects_list "[_ imsld.lt_li_desc_no_file_assoc]"
                } else {
                    set environment_learning_objects_list [concat [list $environment_learning_objects_list] \
                                                               [list $one_learning_object_list]]
                }
            } if_no_rows {
                ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
            }
        }
    }
    # services
    set environment_services_list [list]
    if { [db_0or1row get_service_info {
        select service_id,
        item_id as service_item_id,
        identifier,
        service_type
        from imsld_servicesi
        where environment_id = :environment_item_id
        and content_revision__is_live(service_id) = 't'
    }] } {
        set environment_services_list [imsld::process_service -service_item_id $service_item_id]
    }

    set nested_environment_list [list]
    # environments
    db_foreach nested_environment {
        select ar.object_id_two as nested_environment_item_id
        from acs_rels ar
        where ar.object_id_one = :environment_item_id
        and ar.rel_type = 'imsld_env_env_rel'
    } {
        set one_nested_environment_list [imsld::process_environment -environment_item_id $nested_environment_item_id]
        set nested_environment_list [concat [list $nested_environment_list] \
                                         [list "Nested Environment: [lindex $one_nested_environment_list 0]" \
                                              [lindex $one_nested_environment_list 1] \
                                              [lindex $one_nested_environment_list 2] \
                                              [lindex $one_nested_environment_list 3]]]
    }
    return [list $environment_title $environment_learning_objects_list $environment_services_list $nested_environment_list]
}

ad_proc -public imsld::process_learning_objective {
    {-imsld_item_id ""}
    {-activity_item_id ""}
    {-community_id ""}
} {
    returns a list with the objective title and the associated resources, files and environments referenced from the learning objective of the given activity or ims-ld
} {  
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    # Gets file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    
    set learning_objective_item_id ""
    if { ![string eq "" $imsld_item_id] } {
        db_0or1row get_lo_id { 
            select learning_objective_id as learning_objective_item_id
            from imsld_imsldsi
            where item_id = :imsld_item_id
            and content_revision__is_live(imsld_id) = 't'
        }
    } elseif { ![string eq "" $activity_item_id] } {
        db_0or1row get_lo_id { 
            select learning_objective_id as learning_objective_item_id
            from imsld_learning_activitiesi
            where item_id = :activity_item_id
            and content_revision__is_live(activity_id) = 't'
        }
    } else {
        return -code error "IMSLD::imsld::process_learning_objective: Invalid call"
    }

    if { [string eq "" $learning_objective_item_id] } {
        return ""
    }

    # get learning object info
    db_1row objective_info {
        select coalesce(lo.pretty_title, lo.title) as objective_title,
        lo.learning_objective_id
        from imsld_learning_objectivesi lo
        where lo.item_id = :learning_objective_item_id
        and content_revision__is_live(lo.learning_objective_id) = 't'
    }
    set objective_items_list [list]

    # get the items associated with the learning objective
    set linear_item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :learning_objective_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach lo_nested_associated_items {
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
        } {
            set one_objective_urls "[imsld::process_resource -resource_item_id $resource_item_id]"
            if { [string eq "" $one_objective_urls] } {
                lappend objective_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                set objective_items_list [concat [list $objective_items_list] [list $one_objective_urls]]
            }
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }
    return [list $objective_title $objective_items_list]
}

ad_proc -public imsld::process_prerequisite {
    {-imsld_item_id ""}
    {-activity_item_id ""}
    {-community_id ""}
} {
    returns a list of the associated resources, files and environments referenced from the prerequisite of the given ims-ld or activity
} {  
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    # Gets file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    
    set prerequisite_item_id ""
    if { ![string eq "" $imsld_item_id] } {
        db_0or1row get_lo_id { 
            select prerequisite_id as prerequisite_item_id
            from imsld_imsldsi
            where item_id = :imsld_item_id
            and content_revision__is_live(imsld_id) = 't'
        }
    } elseif { ![string eq "" $activity_item_id] } {
        db_0or1row get_lo_id { 
            select prerequisite_id as prerequisite_item_id
            from imsld_learning_activitiesi
            where item_id = :activity_item_id
            and content_revision__is_live(activity_id) = 't'
        }
    } else {
        return -code error "IMSLD::imsld::process_prerequisite: Invalid call"
    }

    if { [string eq "" $prerequisite_item_id] } {
        return ""
    }

    # get prerequisite info
    db_1row prerequisite_info {
        select coalesce(pre.pretty_title, pre.title) as prerequisite_title,
        pre.prerequisite_id
        from imsld_prerequisitesi pre
        where pre.item_id = :prerequisite_item_id
        and content_revision__is_live(pre.prerequisite_id) = 't'
    }

    set prerequisite_items_list [list]

    # get the items associated with the learning objective
    set linear_item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :prerequisite_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach prereq_nested_associated_items {
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
        } {
            set one_prerequisite_urls "[imsld::process_resource -resource_item_id $resource_item_id]"
            if { [string eq "" $one_prerequisite_urls] } {
                lappend prerequisite_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                set prerequisite_items_list [concat [list $prerequisite_items_list] [list $one_prerequisite_urls]]
            }
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }
    return [list $prerequisite_title $prerequisite_items_list]
}

ad_proc -public imsld::process_feedback {
    {-on_completion_item_id ""}
    {-community_id ""}
} {
    returns a list with the feedback title and the associated resources, files and environments referenced from the on_completion element.
} {  
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    # Gets file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    
    set feedback_item_id ""

    # get on completion info
    db_1row feedback_info {
        select coalesce(oc.feedback_title, oc.title) as feedback_title
        from imsld_on_completioni oc
        where oc.item_id = :on_completion_item_id
        and content_revision__is_live(oc.on_completion_id) = 't'
    }

    set feedback_items_list [list]
    # get the items associated with the feedback
    set linear_item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr, acs_rels ar
        where ar.object_id_one = :on_completion_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach feedback_nested_associated_items {
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
        } {
            set one_feedback_urls [imsld::process_resource -resource_item_id $resource_item_id]
            if { [string eq "" $one_feedback_urls] } {
                lappend feedback_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                set feedback_items_list [concat [list $feedback_items_list] [list $one_feedback_urls]]
            }
        }
    }
    return [list $feedback_title $feedback_items_list]
}

ad_proc -public imsld::process_resource { 
    -resource_item_id
    {-community_id ""}
} {
    @param resource_item_id

    @return The list (li) of files associated to the given resource_id
} {
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    db_1row get_resource_info {
        select identifier,
        type as resource_type,
        title as resource_title,
        acs_object_id
        from imsld_cp_resourcesi 
        where item_id = :resource_item_id 
        and content_revision__is_live(resource_id) = 't'
    }
    set files_lis ""
    switch $resource_type {
        forum {
            # forums package call
            set forums_package_id [site_node_apm_integration::get_child_package_id \
                                   -package_id [dotlrn_community::get_package_id $community_id] \
                                   -package_key "forums"]
            set file_url "[apm_package_url_from_id $forums_package_id]forum-view?[ad_export_vars { { forum_id $acs_object_id } }]"
            set forum_title [db_exec_plsql get_froum_title {
                select acs_object__name(:acs_object_id)
            }]
            append files_lis "<a href=${file_url} target=\"_blank\"> $forum_title </a> "
        }
        imsqti_xmlv1p0 {
            # assessment package call
            set assessment_package_id [site_node_apm_integration::get_child_package_id \
                                           -package_id [dotlrn_community::get_package_id $community_id] \
                                           -package_key "assessment"]
            set file_url "[apm_package_url_from_id $assessment_package_id]assessment?[ad_export_vars { { assessment_id $acs_object_id } }]"
            set assessment_title [db_string get_assessment_title {
                select title from as_assessmentsi 
                where item_id = :acs_object_id
                and content_revision__is_live(assessment_id) = 't'
            }]
            append files_lis "<a href=${file_url} target=\"_blank\"> $assessment_title </a> "
        }
        webcontent -
        default {
            # Gets file-storage root folder_id
            set fs_package_id [site_node_apm_integration::get_child_package_id \
                                   -package_id [dotlrn_community::get_package_id $community_id] \
                                   -package_key "file-storage"]
            set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
            db_foreach associated_files {
                select cpf.imsld_file_id,
                cpf.file_name,
                cpf.item_id, cpf.parent_id
                from imsld_cp_filesx cpf,
                acs_rels ar
                where ar.object_id_one = :resource_item_id
                and ar.object_id_two = cpf.item_id
                and content_revision__is_live(cpf.imsld_file_id) = 't'
            } {
                # get the fs file path
                set folder_path [db_exec_plsql get_folder_path { select content_item__get_path(:parent_id,:root_folder_id); }]
                set fs_file_url [db_1row get_fs_file_url {
                    select 
                    case 
                    when :folder_path is null
                    then fs.file_upload_name
                    else :folder_path || '/' || fs.file_upload_name
                    end as file_url
                    from fs_objects fs
                    where fs.live_revision = :imsld_file_id
                }]
                set file_url "[apm_package_url_from_id $fs_package_id]view/${file_url}"
                append files_lis "<a href=[export_vars -base $file_url] target=\"_blank\"> $file_name </a> "
            } 
        }
    }
    return $files_lis
}

ad_proc -public imsld::process_learning_activity { 
    -activity_item_id:required
    {-community_id ""}
} {
    @param 
    @option user_id default [ad_conn user_id]
    
    @return The list (activity_name, list of associated urls) of the next activity for the user in the IMS-LD.
} {
    db_1row activity_info {
        select on_completion_id as on_completion_item_id,
        prerequisite_id as prerequisite_item_id,
        learning_objective_id as learning_objective_item_id,
        activity_id
        from imsld_learning_activitiesi
        where item_id = :activity_item_id
        and content_revision__is_live(activity_id) = 't'
    }

    # get environments
    set environments_list [list]
    set associated_environments_list [db_list la_associated_environments {
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :activity_item_id
        and ar.rel_type = 'imsld_la_env_rel'
        order by ar.object_id_two
    }]
    foreach environment_item_id $associated_environments_list {
        if { [llength $environments_list] } {
            set environments_list [concat [list $environments_list] \
                                       [list [imsld::process_environment -environment_item_id $environment_item_id]]]
        } else {
            set environments_list [imsld::process_environment -environment_item_id $environment_item_id]
        }
    }

    # prerequisites
    set prerequisites_list [list]
    if { ![string eq "" $prerequisite_item_id] } {
        set prerequisites_list [imsld::process_prerequisite -activity_item_id $activity_item_id]
    }
    
    # learning objectives
    set objectives_list [list]
    if { ![string eq "" $learning_objective_item_id] } {
        set objectives_list [imsld::process_learning_objective -activity_item_id $activity_item_id]
    }

    set activity_items_list [list]
    # get the items associated with the activity
    set linear_item_list [db_list item_linear_list {
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
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach la_nested_associated_items {
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
        } {
            set one_activity_urls "[imsld::process_resource -resource_item_id $resource_item_id]"
            if { [string eq "" $one_activity_urls] } {
                lappend activity_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                set activity_items_list [concat [list $activity_items_list] [list $one_activity_urls]]
            }
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }

    # feedback
    set feedbacks_list [list]
    if { ![string eq "" $on_completion_item_id] } {
        set feedbacks_list [imsld::process_feedback -on_completion_item_id $on_completion_item_id]
    }
    return [list $prerequisites_list \
                $objectives_list \
                $environments_list \
                $activity_items_list \
                $feedbacks_list]
}

ad_proc -public imsld::process_support_activity { 
    -activity_item_id:required
    {-community_id ""}
} {
    @param activity_item_id
    
    @return The list of items (resources, feedback, environments) associated with the support activity
} {
    db_1row activity_info {
        select on_completion_id as on_completion_item_id,
        activity_id
        from imsld_support_activitiesi
        where item_id = :activity_item_id
        and content_revision__is_live(activity_id) = 't'
    }

    # get environments
    set environments_list [list]
    set associated_environments_list [db_list sa_associated_environments {
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :activity_item_id
        and ar.rel_type = 'imsld_sa_env_rel'
        order by ar.object_id_two
    }]
    foreach environment_item_id $associated_environments_list {
        if { [llength $environments_list] } {
            set environments_list [concat [list $environments_list] \
                                       [list [imsld::process_environment -environment_item_id $environment_item_id]]]
        } else {
            set environments_list [imsld::process_environment -environment_item_id $environment_item_id]
        }
    }

    set activity_items_list [list]
    # get the items associated with the activity
    set linear_item_list [db_list item_linear_list {
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
    }]
    foreach imsld_item_id $linear_item_list {
        db_foreach sa_nested_associated_items {
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
        } {
            set one_activity_urls "[imsld::process_resource -resource_item_id $resource_item_id]"
            if { [string eq "" $one_activity_urls] } {
                lappend activity_items_list "[_ imsld.lt_li_desc_no_file_assoc]"
            } else {
                set activity_items_list [concat [list $activity_items_list] [list $one_activity_urls]]
            }
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }

    # feedback
    set feedbacks_list [list]
    if { ![string eq "" $on_completion_item_id] } {
        set feedbacks_list [imsld::process_feedback -on_completion_item_id $on_completion_item_id]
    }
    return [list $environments_list \
                $activity_items_list \
                $feedbacks_list]
}

ad_proc -public imsld::process_activity_structure {
    -structure_item_id:required
} {
    @param structure_item_id
    
    @return The list of items (environments) associated with the activity structure
} {
    # get environments
    set environments_list [list]
    set associated_environments_list [db_list sa_associated_environments {
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :structure_item_id
        and ar.rel_type = 'imsld_as_env_rel'
        order by ar.object_id_two
    }]
    foreach environment_item_id $associated_environments_list {
        if { [llength $environments_list] } {
            set environments_list [concat [list $environments_list] \
                                       [list [imsld::process_environment -environment_item_id $environment_item_id]]]
        } else {
            set environments_list [imsld::process_environment -environment_item_id $environment_item_id]
        }
    }
    return [list $environments_list]
}

ad_proc -public imsld::next_activity { 
    -imsld_item_id:required
    {-user_id ""}
    {-community_id ""}
    -return_url
    imsld_multirow
} {
    @param imsld_item_id
    @option user_id default [ad_conn user_id]
    @option community_id
    @param return_url url to return in the action links
    
    @return The list (activity_name, list of associated urls) of the next activity for the user in the IMS-LD.
} {
    template::multirow create imsld_multirow prerequisites objectives environments activities_titles activities_files feedbacks status
    # environments
    set environments_titles ""
    set environments_files ""

    db_1row get_ismld_info {
        select imsld_id
        from imsld_imsldsi
        where item_id = :imsld_item_id
        and content_revision__is_live(imsld_id) = 't'
    }
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
   
    # global prerequisites and learning objectives
    set prerequisites_list [imsld::process_prerequisite -imsld_item_id $imsld_item_id]
    set prerequisites ""
    if { [llength $prerequisites_list] } {
        set prerequisites "<ul>[lindex $prerequisites_list 0]"
        append prerequisites "<li>[join [lindex $prerequisites_list 1] "</li><li>"]"
        append prerequisites "</li></ul>"
        regsub -all {<li>[ ]*</li>} $prerequisites "" prerequisites
    }
    set objectives_list [imsld::process_learning_objective -imsld_item_id $imsld_item_id]
    set objectives ""
    if { [llength $objectives_list] } {
        set objectives "<ul>[lindex $objectives_list 0]"
        append objectives "<li>[join [lindex $objectives_list 1] "</li><li>"]"
        append objectives "</li></ul>"
        regsub -all {<li>[ ]*</li>} $objectives "" objectives
    }
    if { [string length "${prerequisites}${objectives}"] } {
        template::multirow append imsld_multirow $prerequisites $objectives {} {} {} {} {}
    }
    
    if { ![db_string get_last_entry {
        select count(*)
        from imsld_status_user
        where user_id = :user_id
        and imsld_id = :imsld_id
    }] } {
        # special case: the user has no entry, the ims-ld hasn't started yet for that user
        set first_p 1
        db_1row get_first_role_part {
            select irp.role_part_id
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
        }
    } else {
        # get the completed activities in order to display them
        # save the last one (the last role_part_id of the last completed activity) because we will use it latter

        # JOPEZ: need to split the db_foreach from the body because of db pools
        foreach completed_activity [db_list_of_lists completed_activity {
            select stat.completed_id,
            stat.role_part_id,
            stat.type,
            rp.sort_order,
            rp.act_id
            from imsld_status_user stat, imsld_role_parts rp
            where stat.imsld_id = :imsld_id
            and stat.user_id = :user_id
            and stat.role_part_id = rp.role_part_id
            order by stat.finished_date
        }] {
            set completed_id [lindex $completed_activity 0]
            set role_part_id [lindex $completed_activity 1]
            set type [lindex $completed_activity 2]
            set sort_order [lindex $completed_activity 3]
            set act_id [lindex $completed_activity 4]
            # environments
            set environment_list [list]
            set environments ""
            switch $type {
                learning {
                    db_1row get_learning_activity_info {
                        select coalesce(title,identifier) as activity_title,
                        item_id as activity_item_id
                        from imsld_learning_activitiesi
                        where activity_id = :completed_id
                    }
                    set activities_list [imsld::process_learning_activity -activity_item_id $activity_item_id]
                    set prerequisites ""
                    if { [llength [lindex $activities_list 0]] } {
                        set prerequisites "<ul>[lindex [lindex $activities_list 0] 0]"
                        append prerequisites "<li>[join [lindex [lindex $activities_list 0] 1] "</li><li>"]"
                        append prerequisites "</li></ul>"
                        regsub -all {<li>[ ]*</li>} $prerequisites "" prerequisites
                    }
                    set objectives ""
                    if { [llength [lindex $activities_list 1]] } {
                        set objectives "<ul>[lindex [lindex $activities_list 1] 0]"
                        append objectives "<li>[join [lindex [lindex $activities_list 1] 1] "</li><li>"]"
                        append objectives "</li></ul>"
                        regsub -all {<li>[ ]*</li>} $objectives "" objectives
                    }

                    if { [llength [lindex $activities_list 2]] } {
                        set environments "<ul>[lindex [lindex $activities_list 2] 0]"
                        append environments "<li>[join [lindex [lindex $activities_list 2] 1] "</li><li>"]"
                        append environments "</li><li>[join [lindex [lindex $activities_list 2] 2] "</li><li>"]"
                        append environments "</li><li>[join [lindex [lindex $activities_list 2] 3] "</li><li>"]"
                        append environments "</li></ul>"
                        regsub -all {<li>[ ]*</li>} $environments "" environments
                        #             foreach nested_environment {
                        #                 append environments_files [expr { [llength [lindex [lindex $activities_list 2] 3]] ? [join [lindex [lindex $activities_list 2] 2] "<br />"] : "" }]
                        #             }
                    }

                    set feedbacks ""
                    if { [llength [lindex $activities_list 4]] } {
                        set feedbacks "<ul>[lindex [lindex $activities_list 4] 0]"
                        append feedbacks "<li>[join [lindex [lindex $activities_list 4] 1] "</li><li>"]"
                        append feedbacks "</li></ul>"
                        regsub -all {<li>[ ]*</li>} $feedbacks "" feedbacks
                    }
                    template::multirow append imsld_multirow $prerequisites \
                        $objectives \
                        $environments \
                        $activity_title \
                        [join [lindex $activities_list 3] "<br />"] \
                        $feedbacks \
                        finished
                }
                support {
                    db_1row get_support_activity_info {
                        select coalesce(title,identifier) as activity_title,
                        item_id as activity_item_id
                        from imsld_support_activitiesi
                        where activity_id = :completed_id
                    }
                    set activities_list [imsld::process_support_activity -activity_item_id $activity_item_id]

                    if { [llength [lindex $activities_list 0]] } {
                        set environments "<ul>[lindex [lindex $activities_list 0] 0]"
                        append environments "<li>[join [lindex [lindex $activities_list 0] 1] "</li><li>"]"
                        append environments "</li><li>[join [lindex [lindex $activities_list 0] 2] "</li><li>"]"
                        append environments "</li><li>[join [lindex [lindex $activities_list 0] 3] "</li><li>"]"
                        append environments "</li></ul>"
                        regsub -all {<li>[ ]*</li>} $environments "" environments
                    }

                    set feedbacks ""
                    if { [llength [lindex $activities_list 2]] } {
                        set feedbacks "<ul>[lindex [lindex $activities_list 2] 0]"
                        append feedbacks "<li>[join [lindex [lindex $activities_list 2] 1] "</li><li>"]"
                        append feedbacks "</li></ul>"
                        regsub -all {<li>[ ]*</li>} $feedbacks "" feedbacks
                    }
                    template::multirow append imsld_multirow {} \
                        {} \
                        $environments \
                        $activity_title \
                        [join [lindex $activities_list 1] "<br />"] \
                        $feedbacks \
                        finished
                }
                structure {
                    db_1row get_support_activity_info {
                        select coalesce(title,identifier) as activity_title,
                        item_id as structure_item_id
                        from imsld_activity_structuresi
                        where structure_id = :completed_id
                    }
                    set structure_list [imsld::process_activity_structure -structure_item_id $structure_item_id]
                    if { [llength [lindex $structure_list 0]] } {
                        set environments "<ul>[lindex [lindex $structure_list 0] 0]"
                        append environments "<li>[join [lindex [lindex $structure_list 0] 1] "</li><li>"]"
                        append environments "</li><li>[join [lindex [lindex $structure_list 0] 2] "</li><li>"]"
                        append environments "</li><li>[join [lindex [lindex $structure_list 0] 3] "</li><li>"]"
                        append environments "</li></ul>"
                        regsub -all {<li>[ ]*</li>} $environments "" environments
                    }
                    template::multirow append imsld_multirow {} {} $environments $activity_title {} {} finished
                }
            }
        }
        
        # the last completed is now stored in completed_id, let's find out the next role_part_id that the user has to work on.
        # Procedure (knowing that the info of the last role_part are stored in the last iteration vars):
        # 0. check if all the activities referenced by the current role_part_id are finished
        # 0.1 if all of them are not finished yet, skip this section and preserve the last role_part_id, otherwise, continue
        # 1. get the next role_part from imsld_role_parts according to sort_number, first 
        #    search in the current act_id, then in the current play_id, then in the next play_id and so on...
        # 1.1 if there are no more role_parts then this is the last one
        # 1.2 if we find a "next role_part", it will be treated latter, we just have to set the next role_part_id var

        if { [imsld::role_part_finished_p -role_part_id $role_part_id] } {
            # search in the current act_id
            if { ![db_0or1row search_current_act {
                select role_part_id
                from imsld_role_parts
                where sort_order = :sort_order + 1
                and act_id = :act_id
            }] } {
                # get current act_id's sort_order and search in the next act in the current play_id
                db_1row get_current_play_id {
                    select ip.item_id as play_item_id,
                    ip.play_id,
                    ia.sort_order as act_sort_order
                    from imsld_playsi ip, imsld_acts ia, cr_items cr
                    where ip.item_id = ia.play_id
                    and ia.act_id = cr.live_revision
                    and cr.item_id = :act_id
                }
                if { ![db_0or1row search_current_play {
                    select rp.role_part_id
                    from imsld_role_parts rp, imsld_actsi ia
                    where ia.play_id = :play_item_id
                    and ia.sort_order = :act_sort_order + 1
                    and rp.act_id = ia.item_id
                    and content_revision__is_live(rp.role_part_id) = 't'
                    and content_revision__is_live(ia.act_id) = 't'
                    and rp.sort_order = (select min(irp2.sort_order) from imsld_role_parts irp2 where irp2.act_id = rp.act_id)
                }] } {
                    # get the current play_id's sort_order and sarch in the next play in the current method_id
                    db_1row get_current_method {
                        select im.item_id as method_item_id,
                        ip.sort_order as play_sort_order
                        from imsld_methodsi im, imsld_plays ip
                        where im.item_id = ip.method_id
                        and ip.play_id = :play_id
                    }
                    if { ![db_0or1row search_current_method {
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
                    }] } {
                        # there is no more to search, we reached the end of the unit of learning
                        template::multirow append imsld_multirow {} {} {} {} {} {} {IMS LD finished}
                        return [template::multirow size imsld_multirow]
                    }
                }
            }
        }
    }
    # find the next activity referenced by the role_part
    # (learning_activity, support_activity, activity_structure)  
    # 1. if it is a learning or support activity, no problem, find the associated files and return the lists
    # 2. if it is an activity structure we have verify which activities are already completed and return the next
    #    activity in the activity structure, handling the case when the next activity is also an activity structure

    db_1row get_role_part_activity {
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
        environment_id as rp_environment_item_id
        from imsld_role_parts
        where role_part_id = :role_part_id
    }

    # environments
    set environment_list [list]
    set environments ""
    # get the environments associated to the role_part
    if { ![string eq "" $rp_environment_item_id] } {
        set environment_list [concat [list $environment_list] [imsld::process_environment -environment_item_id $rp_environment_item_id]]
    }
    
    # activity structure
    if { [string eq $activity_type structure] } {
        # activity structure. we have to look for the next learning or support activity
        set activity_list [imsld::structure_next_activity -activity_structure_id $activity_id -environment_list $environment_list]
        set activity_id [lindex $activity_list 0]
        set activity_type [lindex $activity_list 1]
        if { [llength $environment_list] } {
            set environment_list [concat [list $environment_list] [lindex $activity_list 2]]
        } else {
            set environment_list [lindex $activity_list 2]
        }
    }
    if { [llength $environment_list] } {
        set environments "<ul>[lindex $environment_list 0]"
        append environments "<li>[join [lindex $environment_list 1] "</li><li>"]"
        append environments "</li><li>[join [lindex $environment_list 2] "</li><li>"]"
        append environments "</li><li>[join [lindex $environment_list 3] "</li><li>>"]"
        append environments "</li></ul>"
        regsub -all {<li>[ ]*</li>} $environments "" environments
    }
    
    # learning activity
    if { [string eq $activity_type learning] } {
        db_1row learning_activity {
            select la.activity_id,
            la.item_id as activity_item_id,
            la.title as activity_title,
            la.identifier,
            la.user_choice_p
            from imsld_learning_activitiesi la
            where la.activity_id = :activity_id
        }
        set activities_list [imsld::process_learning_activity -activity_item_id $activity_item_id]
        set prerequisites ""
        if { [llength [lindex $activities_list 0]] } {
            set prerequisites "<ul>[lindex [lindex $activities_list 0] 0]"
            append prerequisites "<li>[join [lindex [lindex $activities_list 0] 1] "</li><li>"]"
            append prerequisites "</li></ul>"
            regsub -all {<li>[ ]*</li>} $prerequisites "" prerequisites
        }
        set objectives ""
        if { [llength [lindex $activities_list 1]] } {
            set objectives "<ul>[lindex [lindex $activities_list 1] 0]"
            append objectives "<li>[join [lindex [lindex $activities_list 1] 1] "</li><li>"]"
            append objectives "</li></ul>"
            regsub -all {<li>[ ]*</li>} $objectives "" objectives
        }
        if { [llength [lindex $activities_list 2]] } {
            set environments "<ul>[lindex [lindex $activities_list 2] 0]"
            append environments "<li>[join [lindex [lindex $activities_list 2] 1] "</li><li>"]"
            append environments "</li><li>[join [lindex [lindex $activities_list 2] 2] "</li><li>"]"
            append environments "</li><li>[join [lindex [lindex $activities_list 2] 3] "</li><li>>"]"
            append environments "</li></ul>"
            regsub -all {<li>[ ]*</li>} $environments "" environments
        }

        template::multirow append imsld_multirow $prerequisites \
            $objectives \
            $environments \
            $activity_title \
            [join [lindex $activities_list 3] "<br />"] \
            {} \
            "<a href=finish-component-element-${imsld_id}-${role_part_id}-${activity_id}-learning.imsld>finish</a>"
    }

    # support activity
    if { [string eq $activity_type support] } {
        db_1row support_activity {
            select sa.activity_id,
            sa.item_id as activity_item_id,
            sa.title as activity_title,
            sa.identifier,
            sa.user_choice_p
            from imsld_support_activitiesi sa
            where sa.activity_id = :activity_id
        }
        set activities_list [imsld::process_support_activity -activity_item_id $activity_item_id]
        
        if { [llength [lindex $activities_list 0]] } {
            set environments "<ul>[lindex [lindex $activities_list 0] 0]"
            append environments "<li>[join [lindex [lindex $activities_list 0] 1] "</li><li>"]"
            append environments "</li><li>[join [lindex [lindex $activities_list 0] 2] "</li><li>"]"
            append environments "</li><li>[join [lindex [lindex $activities_list 0] 3] "</li><li>"]"
            append environments "</li></ul>"
            regsub -all {<li>[ ]*</li>} $environments "" environments
        }
        
        template::multirow append imsld_multirow {} \
            {} \
            $environments \
            $activity_title \
            [join [lindex $activities_list 1] "<br />"] \
            {} \
            "<a href=finish-component-element-${imsld_id}-${role_part_id}-${activity_id}-support.imsld>finish</a>"
    }
        
    # this should never happen, but in case the next activiy is already finished, let's throw an error
    # instead of not doing anything.
    if { [db_string verify_not_completed {
        select count(*) from imsld_status_user
        where completed_id = :activity_id
    }] } {
        return -code error "IMSLD::imsld::nex_activity: Returning a completed activity!"
        ad_script_abort
    }
    
    # first parameter: activity name
    return [template::multirow size imsld_multirow]
}

ad_register_proc GET /finish-component-element* imsld::finish_component_element
ad_register_proc POST /finish-component-element* imsld::finish_component_element
