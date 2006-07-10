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

ad_proc -public imsld::package_key { 
} { 
    returns the package_key of the IMS-LD package
} {  
    return imsld
} 

ad_proc -public imsld::object_type_image_path {
    -object_type
} { 
    returns the path to the image representing the given object_type in the imsld package
} { 
    set community_id [dotlrn_community::get_community_id]
    set imsld_package_id [site_node_apm_integration::get_child_package_id \
                              -package_id [dotlrn_community::get_package_id $community_id] \
                              -package_key "[imsld::package_key]"]
    switch $object_type {
        forums_forum {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/forums.png"
        }
        as_assessments {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/assessment.png"
        }
        sessions {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/sessions.png"
        }
        send-mail {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/send-mail.png"
        }
        ims_manifest_object {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/lors.png"
        }
        url {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/url.png"
        }
        default {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/file-storage.png"
        }
    }
    return $image_path
} 

ad_proc -public imsld::get_role_part_from_activity {
    -activity_type
    -leaf_id
} { 
    @return A the list of role_part_ids that reference the given activity_item_id (leaf_id)
} {
    switch $activity_type {
        learning {
            set role_part_list [list]
            set referncer_list [db_list la_directly_mapped { *SQL* }]
            if { [llength $referncer_list] } {
                set role_part_list [concat $role_part_list $referncer_list]
            }
            # check if the learning activity is referenced by some activity structures... digg more
            foreach la_structure_list [db_list_of_lists get_la_activity_structures { *SQL* }] {
                set stucture_id [lindex $la_structure_list 0]
                set leaf_id [lindex $la_structure_list 1]
                set referencer_list [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
                if { [llength $referencer_list] } {
                    set role_part_list [concat $role_part_list $referencer_list]
                }
            }
            return $role_part_list
        }
        support {
            set role_part_list [list]
            set referncer_list [db_list sa_directly_mapped { *SQL* }]
            if { [llength $referncer_list] } {
                set role_part_list [concat $role_part_list $referncer_list]
            }
            # check if the support activity is referenced by some activity structures... digg more
            foreach sa_structure_list [db_list_of_lists get_sa_activity_structures { *SQL* }] {
                set stucture_id [lindex $sa_structure_list 0]
                set leaf_id [lindex $sa_structure_list 1]
                set referencer_list [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
                if { [llength $referencer_list] } {
                    set role_part_list [concat $role_part_list $referencer_list]
                }
            }
            return $role_part_list
        }
        structure {
            set role_part_list [list]
            set referncer_list [db_list as_directly_mapped { *SQL* }]
            if { [llength $referncer_list] } {
                set role_part_list [concat $role_part_list $referncer_list]
            }
            # check if the activity structure is referenced by an activity structure... digg more
            foreach sa_structure_list [db_list_of_lists get_as_activity_structures { *SQL* }] {
                set stucture_id [lindex $sa_structure_list 0]
                set leaf_id [lindex $sa_structure_list 1] 
                set referencer_list [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
                if { [llength $referencer_list] } {
                    set role_part_list [concat $role_part_list $referencer_list]
                } 
            }
            return $role_part_list
        }
    }
} 

ad_proc -public imsld::community_id_from_manifest_id {
    -manifest_id:required
} { 
    returns the community_id using the manifest_id to search for it
} {  
    return [db_string get_community_id {
        select dc.community_id
        from imsld_cp_manifestsi im, acs_objects ao, dotlrn_communities dc
        where im.object_package_id = ao.package_id
        and ao.context_id = dc.package_id
        and im.manifest_id = :manifest_id
    }]
} 

ad_proc -public imsld::sweep_expired_activities { 
} { 
    Sweeps the methods, plays, acts  and activities marking as finished the ones that already have been expired according with the value of time-limit.
} {
    ns_log notice "imsld::sweep_expired_activities Sweeping methods.."
    # 1. methods
    foreach referenced_method [db_list_of_lists possible_expired_method { *SQL* }] {
        set manifest_id [lindex $referenced_method 0]
        set imsld_id [lindex $referenced_method 1]
        set method_id [lindex $referenced_method 2]
        set run_id [lindex $referenced_method 3]
        set time_in_seconds [lindex $referenced_method 4]
        set creation_date [lindex $referenced_method 5]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the method has been expired, let's mark it as finished 
            db_foreach user_in_run { *SQL* } {
                imsld::mark_method_finished -imsld_id $imsld_id \
                    -run_id $run_id \
                    -method_id $method_id \
                    -user_id $user_id
            }
        }
    }
    ns_log notice "imsld::sweep_expired_activities Sweeping plays..."
    # 2. plays
    foreach referenced_play [db_list_of_lists possible_expired_plays { *SQL* }] {
        set manifest_id [lindex $referenced_play 0]
        set imsld_id [lindex $referenced_play 1]
        set play_id [lindex $referenced_play 2]
        set time_in_seconds [lindex $referenced_play 3]
        set creation_date [lindex $referenced_play 4]
        set run_id [lindex $referenced_play 5]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the play has been expired, let's mark it as finished 
            db_foreach user_in_run { *SQL* } {
                imsld::mark_play_finished -imsld_id $imsld_id \
                    -run_id $run_id \
                    -play_id $play_id \
                    -user_id $user_id
            }
        }
    }
    ns_log notice "imsld::sweep_expired_activities Sweeping acts..."
    # 3. acts
    foreach referenced_act [db_list_of_lists possible_expired_acts { *SQL* }] {
        set manifest_id [lindex $referenced_act 0]
        set imsld_id [lindex $referenced_act 1]
        set play_id [lindex $referenced_act 2]
        set act_id [lindex $referenced_act 3]
        set time_in_seconds [lindex $referenced_act 4]
        set creation_date [lindex $referenced_act 5]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the act has been expired, let's mark it as finished 
            db_foreach user_in_run { *SQL* } {
                imsld::mark_act_finished -imsld_id $imsld_id \
                    -run_id $run_id \
                    -play_id $play_id \
                    -act_id $act_id \
                    -user_id $user_id
            }
        }
    }
    ns_log notice "imsld::sweep_expired_activities Sweeping support activities..."
    # 4. support activities
    foreach referenced_sa [db_list_of_lists referenced_sas { *SQL* }] {
        set sa_item_id [lindex $referenced_sa 0]
        set activity_id [lindex $referenced_sa 1]
        set time_in_seconds [lindex $referenced_sa 2]
        set role_part_id_list [imsld::get_role_part_from_activity -activity_type support -leaf_id $sa_item_id]
        set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
        foreach role_part_id $role_part_id_list {
            foreach referencer_list [db_list_of_lists sa_referencer { *SQL* }] {
                set manifest_id [lindex $referencer_list 0]
                set role_part_id [lindex $referencer_list 1]
                set imsld_id [lindex $referencer_list 2]
                set play_id  [lindex $referencer_list 3]
                set act_id [lindex $referencer_list 4]
                set creation_date [lindex $referencer_list 5]
                set run_id [lindex $referencer_list 6]

                if { [db_0or1row compre_times {
                    select 1
                    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
                }] } {
                    # the act has been expired, let's mark it as finished 
                    db_foreach user_in_run { *SQL* } {
                        imsld::finish_component_element -imsld_id $imsld_id \
                            -run_id $run_id \
                            -play_id $play_id \
                            -act_id $act_id \
                            -role_part_id $role_part_id \
                            -element_id $activity_id \
                            -type support \
                            -user_id $user_id \
                            -code_call
                    }
                }
            }
        }
    }
    ns_log notice "imsld::sweep_expired_activities Sweeping learning activities..."
    # 5. learning activities
    foreach referenced_la [db_list_of_lists referenced_las { *SQL* }] {
        set la_item_id [lindex $referenced_la 0]
        set activity_id [lindex $referenced_la 1]
        set time_in_seconds [lindex $referenced_la 2]
        set role_part_id_list [imsld::get_role_part_from_activity -activity_type learning -leaf_id $la_item_id]
        foreach role_part_id $role_part_id_list {
            foreach referencer_list [db_list_of_lists la_referencer { *SQL* }] {
                set manifest_id [lindex $referencer_list 0]
                set role_part_id [lindex $referencer_list 1]
                set imsld_id [lindex $referencer_list 2]
                set play_id  [lindex $referencer_list 3]
                set act_id [lindex $referencer_list 4]
                set creation_date [lindex $referencer_list 5]
                set run_id [lindex $referencer_list 6]

                if { [db_0or1row compre_times {
                    select 1
                    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
                }] } {
                    # the act has been expired, let's mark it as finished 
                    #                set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
                    db_foreach user_in_run { *SQL* } {
                        imsld::finish_component_element -imsld_id $imsld_id \
                            -run_id $run_id \
                            -play_id $play_id \
                            -act_id $act_id \
                            -role_part_id $role_part_id \
                            -element_id $activity_id \
                            -type learning \
                            -user_id $user_id \
                            -code_call
                    }
                }
            }
        }

    }
}

ad_proc -public imsld::mark_role_part_finished { 
    -role_part_id:required
    -imsld_id:required
    -run_id:required
    -play_id:required
    -act_id:required
    {-user_id ""}
} { 
    mark the role_part as finished, as well as all the referenced activities
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::role_part_finished_p -run_id $run_id -role_part_id $role_part_id -user_id $user_id] } {
        return
    }
    db_1row role_part_info { *SQL* }

    # first, verify that the role part is marked as started
    if { ![db_0or1row marked_as_started { *SQL* }] } {
        db_dml mark_role_part_started { *SQL* }
    }
    db_dml insert_role_part { *SQL* }

    # mark as finished all the referenced activities
    db_1row role_part_activity {
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
    }

    if { ![string eq $type "none"] } {
        imsld::finish_component_element -imsld_id $imsld_id \
            -run_id $run_id \
            -play_id $play_id \
            -act_id $act_id \
            -role_part_id $role_part_id \
            -element_id $activity_id \
            -type $type \
            -user_id $user_id \
            -code_call

        dom createDocument foo foo_doc
        set foo_node [$foo_doc documentElement]
        if { [string eq $$type "learning"] } {
            set resources_activities_list [imsld::process_learning_activity_as_ul -run_id $run_id -activity_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
        } elseif { [string eq $$type "support"] } {
            set resources_activities_list [imsld::process_support_activity_as_ul -run_id $run_id -activity_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
        } else {
            set resources_activities_list [imsld::process_activity_structure_as_ul -run_id $run_id -structure_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
        }
        #grant permissions for newly showed resources
        imsld::grant_permissions -resources_activities_list $resources_activities_list -user_id $user_id
    }

}

ad_proc -public imsld::mark_act_finished { 
    -act_id:required
    -imsld_id:required
    -run_id:required
    -play_id:required
    {-user_id ""}
} { 
    mark the act as finished, as well as all the referenced role_parts
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::act_finished_p -run_id $run_id -act_id $act_id -user_id $user_id] } {
        return
    }
    db_1row act_info {
        select item_id as act_item_id
        from imsld_actsi
        where act_id = :act_id
    }

    db_dml insert_act { *SQL* }

    foreach referenced_role_part [db_list_of_lists referenced_role_part {
        select rp.role_part_id
        from imsld_role_parts rp, imsld_actsi ia
        where rp.act_id = ia.item_id
        and ia.act_id = :act_id
        and content_revision__is_live(rp.role_part_id) = 't'
    }] {
        set role_part_id [lindex $referenced_role_part 0]
        imsld::mark_role_part_finished -role_part_id $role_part_id \
            -act_id $act_id \
            -play_id $play_id \
            -imsld_id $imsld_id \
            -run_id $run_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_play_finished { 
    -play_id:required
    -imsld_id:required
    -run_id:required
    {-user_id ""}
} { 
    mark the play as finished. In this case there's only need to mark the play finished and not doing anything with the referenced acts, role_parts, etc.
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::play_finished_p -run_id $run_id -play_id $play_id -user_id $user_id] } {
        return
    }
    db_dml insert_play { *SQL* }
    foreach referenced_act [db_list_of_lists referenced_act {
        select ia.act_id
        from imsld_acts ia, imsld_playsi ip
        where ia.play_id = ip.item_id
        and ip.play_id = :play_id
        and content_revision__is_live(ia.act_id) = 't'
    }] {
        set act_id [lindex $referenced_act 0]
        imsld::mark_act_finished -act_id $act_id \
            -play_id $play_id \
            -imsld_id $imsld_id \
            -run_id $run_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_imsld_finished { 
    -imsld_id:required
    -run_id:required
    {-user_id ""}
} { 
    mark the unit of learning as finished
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::imsld_finished_p -imsld_id $imsld_id -run_id $run_id -user_id $user_id] } {
        return
    }
    db_dml insert_uol { *SQL* }

    foreach referenced_play [db_list_of_lists referenced_plays {
        select ip.play_id
        from imsld_plays ip, imsld_methodsi im, imsld_imsldsi ii
        where ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.imsld_id = :imsld_id
    }] {
        set play_id [lindex $referenced_play 0]
        imsld::mark_play_finished -play_id $play_id \
            -imsld_id $imsld_id \
            -run_id $run_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_method_finished { 
    -imsld_id:required
    -run_id:required
    -method_id:required
    {-user_id ""}
} { 
    mark the method as finished
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::method_finished_p -run_id $run_id -method_id $method_id -user_id $user_id] } {
        return
    }
    db_dml insert_method { *SQL* }

    foreach referenced_play [db_list_of_lists referenced_plays {
        select ip.play_id
        from imsld_plays ip, imsld_methodsi im
        where ip.method_id = im.item_id
        and im.method_id = :method_id
    }] {
        set play_id [lindex $referenced_play 0]
        imsld::mark_play_finished -play_id $play_id \
            -imsld_id $imsld_id \
            -run_id $run_id \
            -user_id $user_id
    }
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
                             -is_live "t" \
                             -attributes $attributes \
                             -package_id $package_id]
    } else {
        set revision_id [content::revision::new -item_id $item_id \
                             -title $title \
                             -content_type $content_type \
                             -creation_user $user_id \
                             -creation_ip $creation_ip \
                             -is_live "t" \
                             -package_id $package_id]
    }
    
    return $item_id
}

ad_proc -public imsld::finish_component_element {
    -imsld_id
    -run_id
    {-play_id ""}
    {-act_id ""}
    {-role_part_id ""}
    -element_id
    -type
    -code_call:boolean
    {-user_id ""}
} {
    @param imsld_id
    @param run_id
    @option play_id
    @option act_id
    @option role_part_id
    @option element_id
    @option type
    @option code_call
    @option user_id

    Mark as finished the given component_id. This is done by adding a row in the table imsld_user_status.

    This function is called from a url, but it can also be called recursively
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { !$code_call_p } {
        # get the url to parse it and get the info
        set url [ns_conn url]
        regexp {finish-component-element-([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)-([a-z]+).imsld$} $url match imsld_id run_id play_id act_id role_part_id element_id type
    }
    if { ![db_0or1row marked_as_started { *SQL* }] } {
        # NOTE: this should not happen... UNLESS the activity is marked as finished automatically
        db_dml mark_element_started { *SQL* }
    }
    # now that we have the necessary info, mark the finished element completed and return
    db_dml insert_element_entry { *SQL* }

    switch $type {
        learning { 
            set table_name "imsld_learning_activities"
            set element_name "activity_id"
        }
        support { 
            set table_name "imsld_support_activities"
            set element_name "activity_id"
        }
        method { 
            set table_name "imsld_methods"
            set element_name "method_id"
        }
        play { 
            set table_name "imsld_plays"
            set element_name "play_id"
        }
        act { 
            set table_name "imsld_acts"
            set element_name "act_id"
        }
    }
    
    if { [info exists table_name] } {
        if { [db_0or1row get_related_on_completion_id ""] } {
            db_1row get_related_resource_id { *SQL* }
            imsld::grant_permissions -resources_activities_list $related_resource -user_id $user_id
        }
    }
    if { [string eq $type "learning"] || [string eq $type "support"] || [string eq $type "structure"] } {
        foreach referencer_structure_list [db_list_of_lists referencer_structure { *SQL* }] {
            set structure_id [lindex $referencer_structure_list 0]
            set structure_item_id [lindex $referencer_structure_list 1]
            set number_to_select [lindex $referencer_structure_list 2]
            # if this activity is part of an activity structure, let's check if the rest of referenced 
            # activities are finished too, so we can mark finished the activity structure as well
            set scturcture_finished_p 1
            set total_completed 0
            db_foreach referenced_activity {
                select content_item__get_live_revision(ar.object_id_two) as activity_id
                from acs_rels ar
                where ar.object_id_one = :structure_item_id
                and ar.rel_type in ('imsld_as_la_rel','imsld_as_sa_rel','imsld_as_as_rel')
            } {
                if { ![db_string completed_p { *SQL* }] } {
                    # there is at leas one no-completed activity, so we can't mark this activity structure yet
                    set scturcture_finished_p 0
                } else {
                    incr total_completed
                }
            }
            # FIX ME: when the tree wokrs fine, change the if condition for thisone
            # if { $scturcture_finished_p || (![string eq $number_to_select ""] && ($total_completed >= $number_to_select)) } {}
            if { $scturcture_finished_p } {
                imsld::finish_component_element -imsld_id $imsld_id \
                    -run_id $run_id \
                    -play_id $play_id \
                    -act_id $act_id \
                    -role_part_id $role_part_id \
                    -element_id $structure_id \
                    -type structure \
                    -user_id $user_id \
                    -code_call
            }
        }
    }

    # we continue with A LOT of validations (in order to support the when-xxx-finished tag of the spec 
    # -- with xxx in (role_part,act,play)):
    # 1. let's see if the finished activity triggers the ending of the role_part
    # 2. let's see if the finished role_part triggers the ending of the act which references it.
    # 3. let's see if the finished act triggers the ending the play which references it
    # 4. let's see if the finished play triggers the ending of the method which references it.
    if { [imsld::role_part_finished_p -run_id $run_id -role_part_id $role_part_id -user_id $user_id] && ![db_0or1row already_marked_p { *SQL* }] } { 
        # case number 1
        imsld::finish_component_element -imsld_id $imsld_id \
            -run_id $run_id \
            -play_id $play_id \
            -act_id $act_id \
            -role_part_id $role_part_id \
            -element_id $role_part_id \
            -type role-part \
            -user_id $user_id \
            -code_call

        db_1row get_role_part_info {
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
        }

        set completed_act_p 1 
        set rel_defined_p 0

    set user_roles_list [imsld::roles::get_user_roles -user_id $user_id -run_id $run_id]
        db_foreach referenced_role_part {
            select ar.object_id_two as role_part_item_id,
            rp.role_part_id
            from acs_rels ar, imsld_role_partsi rp
            where ar.object_id_one = :act_item_id
            and rp.item_id = ar.object_id_two
            and ar.rel_type = 'imsld_act_rp_completed_rel'
            and content_revision__is_live(rp.role_part_id) = 't'
        } {
            if { ![imsld::role_part_finished_p -run_id $run_id -role_part_id $role_part_id -user_id $user_id] } {
                set completed_act_p 0
            }
        } if_no_rows {
            # the act doesn't have any imsld_act_rp_completed_rel rel defined.
            set rel_defined_p 1
        }
        if { $rel_defined_p } {
            # check if all the role parts have been finished and mar the act as finished.
            db_foreach directly_referenced_role_part {
                select irp.role_part_id
                from imsld_role_parts irp
                where irp.act_id = :act_item_id
                and content_revision__is_live(irp.role_part_id) = 't'
            } {
                if { ![imsld::role_part_finished_p -run_id $run_id -role_part_id $role_part_id -user_id $user_id] } {
                    set completed_act_p 0
                }
            }
        }

        if { $completed_act_p } {
            # case number 2
            imsld::mark_act_finished -act_id $act_id \
                -play_id $play_id \
                -imsld_id $imsld_id \
                -run_id $run_id \
                -user_id $user_id
            
            set completed_play_p 1
            db_foreach referenced_act {
                select ia.act_id
                from imsld_acts ia, imsld_playsi ip
                where ia.play_id = :play_item_id
                and ip.item_id = ia.play_id
                and content_revision__is_live(ia.act_id) = 't'
            } {
                if { ![imsld::act_finished_p -run_id $run_id -act_id $act_id -user_id $user_id] } {
                    set completed_play_p 0
                }
            }
            if { $completed_play_p } {
                # case number 3
                imsld::mark_play_finished -play_id $play_id \
                    -imsld_id $imsld_id \
                    -run_id $run_id \
                    -user_id $user_id 
                
                set completed_unit_of_learning_p 1 
                set rel_defined_p 0
                db_foreach referenced_play {
                    select ip.play_id
                    from acs_rels ar, imsld_playsi ip
                    where ar.object_id_one = :method_item_id
                    and ip.item_id = ar.object_id_two
                    and ar.rel_type = 'imsld_mp_completed_rel'
                    and content_revision__is_live(ip.play_id) = 't'
                } {
                    if { ![imsld::play_finished_p -run_id $run_id -play_id $play_id -user_id $user_id] } {
                        set completed_unit_of_learning_p 0
                    }
                } if_no_rows {
                    # the uol doesn't have any imsld_mp_completed_rel rel defined.
                    set rel_defined_p 1
                }
                if { $rel_defined_p } {
                    # check if all the plays have been finished and mark the imsld as finished.
                    db_foreach directly_referenced_plays {
                        select ip.play_id
                        from imsld_plays ip
                        where ip.method_id = :method_item_id
                        and content_revision__is_live(ip.play_id) = 't'
                    } {
                        if { ![imsld::play_finished_p -run_id $run_id -play_id $play_id -user_id $user_id] } {
                            set completed_unit_of_learning_p 0
                        }
                    }
                }
                        
                if { $completed_unit_of_learning_p } {
                    # case number 4
                    imsld::mark_imsld_finished -imsld_id $imsld_id -run_id $run_id -user_id $user_id
                }
            }
        }
    }
    if { !$code_call_p } {
        set community_id [dotlrn_community::get_community_id]
        set imsld_package_id [site_node_apm_integration::get_child_package_id \
                                  -package_id [dotlrn_community::get_package_id $community_id] \
                                  -package_key "[imsld::package_key]"]
        ad_returnredirect "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/imsld-tree" -url { run_id }]"
    }
}

ad_proc -public imsld::structure_next_activity {
    -activity_structure_id:required
    {-environment_list ""}
    -imsld_id
    -run_id
    -role_part_id
    {-structures_info ""}
} { 
    @return The next learning or support activity (and the type) in the activity structure. 0 if there are none (which should never happen), the next activity type and the list of the structure names of the activity structures in the path of the returned activity
} {
    set user_id [ad_conn user_id]
    set min_sort_order ""
    set next_activity_id ""
    set next_activity_type ""
    # mark structure started
    if { ![db_0or1row already_marked {
        select 1 from imsld_status_user
        where run_id = :run_id 
        and user_id = :user_id 
        and related_id = :activity_structure_id 
        and status = 'started'
    }] } {
        db_dml mark_structure_started {
            insert into imsld_status_user (imsld_id,
                                           run_id,
                                           role_part_id,
                                           related_id,
                                           user_id,
                                           type,
                                           status_date,
                                           status) 
            (
             select :imsld_id,
             :run_id,
             :role_part_id,
             :activity_structure_id,
             :user_id,
             'structure',
             now(),
             'started'
             where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :activity_structure_id and status = 'started')
             )
        }
    
        set structures_info [concat $structures_info [db_list_of_lists get_structure_info {
            select 
            coalesce(title,identifier) as structure_name,
            item_id
            from imsld_activity_structuresi
            where structure_id = :activity_structure_id
        }]]
    }

    # get referenced activities
    foreach referenced_activity [db_list_of_lists struct_referenced_activities { *SQL* }] {
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        set rel_id [lindex $referenced_activity 2]
        switch $rel_type {
            imsld_as_la_rel {
                # find out if is the next one
                db_1row get_la_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_la_rels where rel_id = :rel_id
                }
                if { ![db_string completed_p_from_la { *SQL* }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
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
                db_1row get_sort_order {
                    select sort_order from imsld_as_sa_rels where rel_id = :rel_id
                }
                if { ![db_string completed_p_from_sa { *SQL* }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $support_activity_id
                    set next_activity_type support
                }
            }
            imsld_as_as_rel {
                # recursive call?
                db_1row get_as_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_as_rels where rel_id = :rel_id
                }
                if { ![db_string completed_p { *SQL* }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $structure_id
                    set next_activity_type structure
                }
            }
            imsld_as_env_rel {
                dom createDocument foo foo_doc
                set foo_node [$foo_doc documentElement]
                if { [llength $environment_list] } {
                    set environment_list [concat [list $environment_list] [list [imsld::process_environment_as_ul -environment_item_id $object_id_two -run_id $run_id -dom_doc $foo_doc -dom_node $foo_node]]]
                } else {
                    set environment_list [imsld::process_environment_as_ul -environment_item_id $object_id_two -run_id $run_id -dom_doc $foo_doc -dom_node $foo_node]
                }
            }
        }
    } 

    if { [string eq $next_activity_type structure] } {
        set next_activity_list [imsld::structure_next_activity -activity_structure_id $next_activity_id -environment_list $environment_list -imsld_id $imsld_id -run_id $run_id -role_part_id $role_part_id -structures_info $structures_info]
        set next_activity_id [lindex $next_activity_list 0]
        set next_activity_type [lindex $next_activity_list 1]
        set environment_list [concat $environment_list [lindex $next_activity_list 2]]
        set structures_info [lindex $next_activity_list 3]
    }
    return [list $next_activity_id $next_activity_type $environment_list $structures_info]
} 

ad_proc -public imsld::structure_finished_p { 
    -structure_id:required
    -run_id
    {-user_id ""}
} { 
    @param structure_id
    @param run_id
    @option user_id
    
    @return 0 if the any activity referenced from the activity structure hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    
    set all_completed 1
    foreach referenced_activity [db_list_of_lists struct_referenced_activities {
        select ar.object_id_two,
        ar.rel_type
        from acs_rels ar, imsld_activity_structuresi ias
        where ar.object_id_one = ias.item_id
        and ias.structure_id = :structure_id
        order by ar.object_id_two
    }] {
        # get all the directly referenced activities (from the activity structure)
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        switch $rel_type {
            imsld_as_la_rel -
            imsld_as_sa_rel {
                # is the activity finished ?
                if { ![db_0or1row completed_p {
                    select 1 from imsld_status_user 
                    where related_id = content_item__get_live_revision(:object_id_two) 
                    and user_id = :user_id 
                    and status = 'finished'
                    and run_id = :run_id
                }] } {
                    set all_completed 0
                }
            }
            imsld_as_as_rel {
                # search recursively trough the referenced 
                db_1row get_activity_structure_info {
                    select structure_id
                    from imsld_activity_structuresi
                    where item_id = :object_id_two
                    and content_revision__is_live(structure_id) = 't'
                }
                # is the activity finished ?
                if { ![db_0or1row completed_p {
                    select 1 from imsld_status_user 
                    where related_id = :structure_id 
                    and user_id = :user_id 
                    and status = 'finished'
                    and run_id = :run_id
                }] } {
                    set all_completed 0
                }
                if { ![imsld::structure_finished_p -run_id $run_id -structure_id $structure_id -user_id $user_id] } {
                    set all_completed 0
                }
            }
        }
    }
    return $all_completed
} 

ad_proc -public imsld::role_part_finished_p { 
    -role_part_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param role_part_id Role Part identifier
    @param run_id
    @option user_id
    
    @return 0 if the role part hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [db_0or1row already_marked_p { *SQL* }] } {
        # simple case, already marked as finished
        return 1
    }

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
    # check if the referenced activities have been finished
    switch $type {
        learning {
            if { [db_string completed_from_la {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:learning_activity_id)
                and user_id = :user_id
                and run_id = :run_id
                and status = 'finished'
            }] } {
                return 1
            }
        }
        support {
            if { [db_string completed_from_sa {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:support_activity_id)
                and user_id = :user_id
                and run_id = :run_id
                and status = 'finished'
            }] } {
                return 1
            }
        }
        structure {
            db_1row get_sa_info {
                select structure_id
                from imsld_activity_structuresi
                where item_id = :activity_structure_id
            }
            return [imsld::structure_finished_p -run_id $run_id -structure_id $structure_id -user_id $user_id]
        }
        none {
            return 1
        }
    }
    return 0
} 

ad_proc -public imsld::run_finished_p { 
    -run_id:required
    {-user_id "" }
} { 
    @param run_id
    @oprion user_id
    
    @return 0 if all the activities in the run hasn't been finished. 1 otherwise
} {
    #get users involved in test
    if {![string eq "" $user_id]} {
        set user_id [ad_conn user_id]
    } else {
        set user_id [db_list get_users_in_run {
            select gmm.member_id 
            from group_member_map gmm,
                 imsld_run_users_group_ext iruge, 
                 acs_rels ar1 
            where iruge.run_id=:run_id
                  and ar1.object_id_two=iruge.group_id 
                  and ar1.object_id_one=gmm.group_id 
            group by member_id
        }]
    }

    #get acts in run
    set acts_list [db_list get_acts_in_run {
        select iai.act_id,
               iai.item_id 
        from imsld_runs ir, 
             imsld_imsldsi iii,
             imsld_methodsi imi,
             imsld_playsi ipi,
             imsld_actsi iai 
        where ir.run_id=:run_id
              and iii.imsld_id=ir.imsld_id 
              and imi.imsld_id=iii.item_id 
              and imi.item_id=ipi.method_id 
              and iai.play_id=ipi.item_id
    }]

    set all_finished_p 1
    foreach user $user_id {
        foreach act $acts_list {
            if {![imsld::act_finished_p -run_id $run_id -act_id $act -user_id $user]} {
                if {[imsld::user_participate_p -run_id $run_id -act_id $act -user_id $user]} {
                    set all_finished_p 0
                }
            }
        }
    }
         
    return $all_finished_p
}

ad_proc -public imsld::user_participate_p { 
    -act_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param act_id
    @param run_id
    @option user_id
    
    @return 0 if the user does not participate in the act. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set involved_roles [db_list get_roles_in_act {select irolei.role_id 
                                                  from imsld_role_parts ir, 
                                                       imsld_actsi iai, 
                                                       imsld_rolesi irolei
                                                  where iai.act_id=:act_id 
                                                        and iai.item_id=ir.act_id
                                                        and ir.role_id=irolei.item_id}]
    set involved_users [list]
    foreach role $involved_roles {
        set involved_users [concat $involved_users [imsld::roles::get_users_in_role -role_id $role -run_id $run_id ]]
    }
    if { [lsearch $involved_users $user_id] < 0 } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public imsld::act_finished_p { 
    -act_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param act_id
    @param run_id
    @oprion user_id
    
    @return 0 if the at hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row already_marked_p { *SQL* }]
} 

ad_proc -public imsld::play_finished_p { 
    -play_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param play_id
    @param run_id
    @option user_id
    
    @return 0 if the play hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row play_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :play_id
        and user_id = :user_id
        and run_id = :run_id
        and status = 'finished'
    }]
} 

ad_proc -public imsld::method_finished_p { 
    -method_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param method_id
    @param run_id
    @oprion user_id
    
    @return 0 if the method hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row method_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :method_id
        and user_id = :user_id
        and run_id = :run_id
        and status = 'finished'
    }]
} 

ad_proc -public imsld::imsld_finished_p { 
    -imsld_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param imsld_id
    @param run_id
    @option user_id
    
    @return 0 if the imsld hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row imsld_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :imsld_id
        and user_id = :user_id
        and run_id = :run_id
        and status = 'finished'
    }]
} 

ad_proc -public imsld::class_visible_p { 
    -run_id:required
    -owner_id:required
    -class_name:required
} { 
    @param run_id
    @param owner_id
    @param class_name

    @return 1 if the class of the owner_id is currently visible in the run, 0 otherwise.
} {
    return [expr ![db_0or1row class_visible_p {
        select 1
        from imsld_attribute_instances
        where run_id = :run_id
        and type = 'class'
        and identifier = :class_name
        and is_visible_p = 'f'
    }]]
}

ad_proc -public imsld::process_service_as_ul {
    -service_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
} { 
    @param service_item_id
    @param run_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return a html list (in a dom tree) of the associated resources referenced from the given service.
} {
    set services_list [list]

    # get service info
    if { ![db_0or1row service_info { *SQL* }] } {
        # not visible, return
        return
    }

    switch $service_type {
        conference {
            db_1row get_conference_info { *SQL* }
            db_foreach serv_associated_items { *SQL* } {
                if {[string eq "t" $resource_mode]} {
                    lappend resource_item_list $resource_item_id
                }
                imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                    -run_id $run_id \
                    -dom_node $dom_node \
                    -dom_doc $dom_doc

                # replace the image with the conference name
                set img_nodes [$dom_node selectNodes {.//img}]
                foreach img_node $img_nodes {
                    set parent_node [$img_node parentNode]
                    set conf_title_node [$dom_doc createTextNode "$conf_title"]
                    $parent_node replaceChild $conf_title_node $img_node 
                }

            } if_no_rows {
                ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
            }
        }

        send-mail {
            # FIX ME: when roles are supported, fix this so the mail is sent to the propper role
            set resource_item_list [list]
            db_1row get_send_mail_info { *SQL* }

            set send_mail_node_li [$dom_doc createElement li]
            set a_node [$dom_doc createElement a]
            
            $a_node setAttribute href "[export_vars -base "[dotlrn_community::get_community_url [dotlrn_community::get_community_id]]imsld/imsld-sendmail" {{send_mail_id $sendmail_id} {run_id $run_id}}]"
            set service_title [$dom_doc createTextNode "$send_mail_title"]
            $a_node setAttribute target "content"
            $a_node appendChild $service_title
            $send_mail_node_li appendChild $a_node
            $dom_node appendChild $send_mail_node_li
        }
        
        monitor {
            set resource_item_list [list]
            db_1row monitor_service_info { *SQL* }

            set monitor_node_li [$dom_doc createElement li]
            set a_node [$dom_doc createElement a]
            
            $a_node setAttribute href "[export_vars -base "[dotlrn_community::get_community_url [dotlrn_community::get_community_id]]imsld/monitor-frame" { monitor_id run_id }]"
            set service_title [$dom_doc createTextNode "$monitor_service_title"]
            $a_node setAttribute target "content"
            $a_node appendChild $service_title
            $monitor_node_li appendChild $a_node
            $dom_node appendChild $monitor_node_li
        }

        default {
            ad_return_error "the service type $service_type is not implemented... yet" "Sorry, that service type ($service_type) hasn't been implemented yet. But be patience, we are working on it =)"
            ad_script_abort
        }
    }
    if {[string eq "t" $resource_mode]} {
        return [list $services_list $resource_item_list]
    }
}

ad_proc -public imsld::process_environment_as_ul {
    -environment_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node:required
    -dom_doc:required
} { 
    @param environment_item_id
    @param run_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return a html list (in a dom tree) of the associated resources, files and environments referenced from the given environment.
} {  
    # get environment info
    db_1row environment_info { *SQL* }

    set environment_node_li [$dom_doc createElement li]
    $environment_node_li setAttribute class "liOpen"
    set text [$dom_doc createTextNode "$environment_title"]
    $environment_node_li appendChild $text
    set environment_node [$dom_doc createElement ul]
    # FIX-ME: if the ul is empty, the browser show the ul incorrectly
    set text [$dom_doc createTextNode ""]    
    $environment_node appendChild $text

    set environment_learning_objects_list [list]
    foreach learning_objects_list [db_list_of_lists get_learning_object_info { *SQL* }] {
        set learning_object_item_id [lindex $learning_objects_list 0]
        set learning_object_id [lindex $learning_objects_list 1]
        set identifier [lindex $learning_objects_list 2]
        set lo_title [lindex $learning_objects_list 3]
        set class_name [lindex $learning_objects_list 4]
        if { ![imsld::class_visible_p -run_id $run_id -owner_id $learning_object_id -class_name $class_name] } {
            continue
        }
        # learning object item. get the files associated
        set linear_item_list [db_list_of_lists item_linear_list { *SQL* }]
        foreach imsld_item_id $linear_item_list {
            foreach environments_list [db_list_of_lists env_nested_associated_items { *SQL* }] {
                set resource_id [lindex $environments_list 0]
                set resource_item_id [lindex $environments_list 1]
                set resource_type [lindex $environments_list 2]
                if { [string eq "t" $resource_mode] } {
                    lappend resource_item_list $resource_item_id
                }

                set one_learning_object_list [imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                                                  -run_id $run_id \
                                                  -dom_node $environment_node \
                                                  -dom_doc $dom_doc \
                                                  -li_mode]
                
                # in order to behave like CopperCore, we decide to replace the images with the learning object title
                set img_nodes [$environment_node selectNodes {.//img}]
                foreach img_node $img_nodes {
                    set parent_node [$img_node parentNode]
                    set lo_title_node [$dom_doc createTextNode "$lo_title"]
                    $parent_node replaceChild $lo_title_node $img_node 
                }
                if { ![string eq "" $one_learning_object_list] } {
                    if { [string eq "t" $resource_mode] } { 
                     set environment_learning_objects_list [concat $environment_learning_objects_list \
                                                               [list $one_learning_object_list] \
                                                               $resource_item_list ]
                    } 
                }
            } 
        }
    }

    # services
    set environment_services_list [list]
    foreach services_list [db_list_of_lists get_service_info { *SQL* }] {
        set service_id [lindex $services_list 0]
        set service_item_id [lindex $services_list 1]
        set identifier [lindex $services_list 2]
        set service_type [lindex $services_list 3]
        set service_title [lindex $services_list 4]

        set class_name [lindex $services_list 5]
        if { ![imsld::class_visible_p -run_id $run_id -owner_id $service_id -class_name $class_name] } {
            continue
        }

        set environment_services_list [concat $environment_services_list \
                                           [list [imsld::process_service_as_ul -service_item_id $service_item_id \
                                                      -run_id $run_id \
                                                      -resource_mode $resource_mode \
                                                      -dom_node $environment_node \
                                                      -dom_doc $dom_doc]]]
        # in order to behave like CopperCore, we decide to replace the images with the service title
        set img_nodes [$environment_node selectNodes {.//img}]
        foreach img_node $img_nodes {
            set parent_node [$img_node parentNode]
            set lo_title_node [$dom_doc createTextNode "$service_title"]
            $parent_node replaceChild $lo_title_node $img_node 
        }
    }

    set nested_environment_list [list]
    # environments
    foreach nested_environment_item_id [db_list nested_environment { *SQL* }] {
        set one_nested_environment_list [imsld::process_environment_as_ul -environment_item_id $nested_environment_item_id \
                                             -run_id $run_id \
                                            -resource_mode $resource_mode \
                                            -dom_node $environment_node \
                                            -dom_doc $dom_doc]
        # the title is stored in [lindex $one_nested_environment_list 0], but is not returned for displaying porpouses
        set nested_environment_list [concat $nested_environment_list \
                                         [lindex $one_nested_environment_list 1] \
                                         [lindex $one_nested_environment_list 2] \
                                         [lindex $one_nested_environment_list 3]]
        regsub -all "{}" $nested_environment_list "" nested_environment_list
    }
    if { [string eq $resource_mode "t"] } {
        return [list $environment_title $environment_learning_objects_list $environment_services_list $nested_environment_list]
    } else {
        $environment_node_li appendChild $environment_node
        $dom_node appendChild $environment_node_li
    }
}

ad_proc -public imsld::process_learning_objective_as_ul {
    -run_id:required
    {-imsld_item_id ""}
    {-activity_item_id ""}
    {-resource_mode "f"}
    -dom_node
    -dom_doc
} {
    @param run_id
    @option imsld_item_id
    @option activity_item_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return a html list (ul, using tdom) with the objective title and the associated resources referenced from the learning objective of the given activity or ims-ld
} {  
    set learning_objective_item_id ""
    if { ![string eq "" $imsld_item_id] } {
        db_0or1row lo_id_from_imsld_item_id { *SQL* }
    } elseif { ![string eq "" $activity_item_id] } {
        db_0or1row lo_id_from_activity_item_id { *SQL* }
    } 

    if { [string eq "" $learning_objective_item_id] } {
        return -code error "IMSLD::imsld::process_learning_objective: Invalid call"
    }

    # get learning object info
    db_1row objective_info { *SQL* }

    # get the items associated with the learning objective
    set resource_item_list [list]
    set linear_item_list [db_list item_linear_list { *SQL* }]
    foreach imsld_item_id $linear_item_list {
        db_foreach lo_nested_associated_items { *SQL* } {
            if { [string eq "t" $resource_mode] } {
                lappend resource_item_list $resource_item_id
            }
            # add the associated files as items of the html list
            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $dom_node
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }
    if { [string eq "t" $resource_mode] } {
        return [list $resource_item_list]
    } 
}

ad_proc -public imsld::process_prerequisite_as_ul {
    -run_id:required
    {-imsld_item_id ""}
    {-activity_item_id ""}
    {-resource_mode "f"}
    -dom_node
    -dom_doc
} {
    @param run_id
    @option imsld_item_id
    @option activity_item_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return a html list (using tdom) of the associated resources referenced from the prerequisite of the given ims-ld or activity
} {  
    set prerequisite_item_id ""
    if { ![string eq "" $imsld_item_id] } {
        db_0or1row lo_id_from_imsld_item_id { *SQL* }
    } elseif { ![string eq "" $activity_item_id] } {
        db_0or1row lo_id_from_activity_item_id { *SQL* }
    }

    if { [string eq "" $prerequisite_item_id] } {
        return -code error "IMSLD::imsld::process_prerequisite: Invalid call"
    }

    # get prerequisite info
    db_1row prerequisite_info { *SQL* }

    # get the items associated with the learning objective
    set linear_item_list [db_list item_linear_list { *SQL* }]
    foreach imsld_item_id $linear_item_list {
        db_foreach prereq_nested_associated_items { *SQL* } { 
            if { [string eq "t" $resource_mode] } { 
                lappend resource_item_list $resource_item_id
            }
            # add the associated files as items of the html list
            set one_prerequisite_ul [imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                                         -run_id $run_id \
                                         -dom_doc $dom_doc \
                                         -dom_node $dom_node]
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }
    if { [string eq "t" $resource_mode] } {
        return [list $prerequisite_title [list] $resource_item_list]
    } 
}

ad_proc -public imsld::process_feedback_as_ul {
    -run_id:required
    {-on_completion_item_id ""}
    -dom_node
    -dom_doc
} {
    @param run_id
    @option on_completion_item_id
    @param dom_node
    @param dom_doc

    @return a html list (using tdom) with the feedback title and the associated resources referenced from the given feedback (on_completion)
} {  
    set feedback_item_id ""
    # get on completion info
    db_1row feedback_info { *SQL* }

    # get the items associated with the feedback
    set linear_item_list [db_list item_linear_list { *SQL* }]
    foreach imsld_item_id $linear_item_list {
        db_foreach feedback_nested_associated_items { *SQL* } {
            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_node $dom_node \
                -dom_doc $dom_doc
        }
    }
}

ad_proc -public imsld::process_resource_as_ul {
    -resource_item_id
    -run_id
    {-community_id ""}
    -dom_node 
    -dom_doc
    -li_mode:boolean
} {
    @param resource_item_id
    @param run_id
    @option community_id
    @param dom_node
    @param dom_doc

    @return The html ul (using tdom) of the files associated to the given resource_id
} {
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    set imsld_package_id [site_node_apm_integration::get_child_package_id \
                              -package_id [dotlrn_community::get_package_id $community_id] \
                              -package_key "[imsld::package_key]"]

    # Get file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    db_1row get_resource_info { *SQL* }
    
    set files_node [$dom_doc createElement ul]
    if { ![string eq $resource_type "webcontent"] && ![string eq $acs_object_id ""] } {
        # if the resource type is not webcontent or has an associated object_id (special cases)...
        if { [db_0or1row is_cr_item { *SQL* }] } {
            db_1row get_cr_info { *SQL* } 
        } else {
            db_1row get_ao_info { *SQL* } 
        }
        set file_url [acs_sc::invoke -contract FtsContentProvider -operation url -impl $object_type -call_args [list $acs_object_id]]
        set a_node [$dom_doc createElement a]
        $a_node setAttribute href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]"
        set img_node [$dom_doc createElement img]
        $img_node setAttribute src "[imsld::object_type_image_path -object_type $object_type]"
        $img_node setAttribute border "0"
        $img_node setAttribute alt "$object_title"
        $a_node appendChild $img_node
        if { $li_mode_p } {
            set file_node [$dom_doc createElement li]
            $file_node appendChild $a_node
            $dom_node appendChild $file_node
        } else {
            $dom_node appendChild $a_node
        }

    } elseif { [string eq $resource_type "imsldcontent"] } {
        foreach file_list [db_list_of_lists associated_files { *SQL* }] {
            set imsld_file_id [lindex $file_list 0]
            set file_name [lindex $file_list 1]
            set item_id [lindex $file_list 2]
            set parent_id [lindex $file_list 3]
            # get the fs file path
            set folder_path [db_exec_plsql get_folder_path { *SQL* }]
            set fs_file_url [db_1row get_fs_file_url { *SQL* }]
            set file_url "imsld-content-serve"
            set a_node [$dom_doc createElement a]
            $a_node setAttribute href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id resource_id $resource_id}]"
            set img_node [$dom_doc createElement img]
            $img_node setAttribute src "[imsld::object_type_image_path -object_type file-storage]"
            $img_node setAttribute border "0"
            $img_node setAttribute alt "$file_name"
            $a_node appendChild $img_node
            if { $li_mode_p } {
                set file_node [$dom_doc createElement li]
                $file_node appendChild $a_node
                $dom_node appendChild $file_node
            } else {
                $dom_node appendChild $a_node
            }
        }

    } else {
        # is webcontent, let's get the associated files
        foreach file_list [db_list_of_lists associated_files { *SQL* }] {
            set imsld_file_id [lindex $file_list 0]
            set file_name [lindex $file_list 1]
            set item_id [lindex $file_list 2]
            set parent_id [lindex $file_list 3]
           # get the fs file path
            set folder_path [db_exec_plsql get_folder_path { *SQL* }]
            set fs_file_url [db_1row get_fs_file_url { *SQL* }]
            set file_url "[apm_package_url_from_id $fs_package_id]view/${file_url}"
            set a_node [$dom_doc createElement a]
            $a_node setAttribute href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]"
            set img_node [$dom_doc createElement img]
            $img_node setAttribute src "[imsld::object_type_image_path -object_type file-storage]"
            $img_node setAttribute border "0"
            $img_node setAttribute alt "$file_name"
            $a_node appendChild $img_node
            if { $li_mode_p } {
                set file_node [$dom_doc createElement li]
                $file_node appendChild $a_node
                $dom_node appendChild $file_node
            } else {
                $dom_node appendChild $a_node
            }
        }
        # get associated urls
        db_foreach associated_urls { *SQL* } {

            set a_node [$dom_doc createElement a]
            $a_node setAttribute href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" { {file_url "[export_vars -base $url]"} resource_item_id run_id}]"
            set img_node [$dom_doc createElement img]
            $img_node setAttribute src "[imsld::object_type_image_path -object_type url]"
            $img_node setAttribute border "0"
            $img_node setAttribute alt "$url"
            $a_node appendChild $img_node
            if { $li_mode_p } {
                set file_node [$dom_doc createElement li]
                $file_node appendChild $a_node
                $dom_node appendChild $file_node
            } else {
                $dom_node appendChild $a_node
            }
        }
    }
}

ad_proc -public imsld::process_activity_as_ul { 
    -activity_item_id:required
    -run_id:required
    -dom_node:required
    -dom_doc
    {-resource_mode "f"}
} {
    @param activity_item_id
    @param run_id
    @option resource_mode default f
    @param dom_node
    @param dom_doc
    
    @return The html list (activity_name, list of associated urls, using tdom) of the activity in the IMS-LD. 
    It only works whith the learning and support activities, since it will only return the objectives, prerequistes,
    associated resources but not the environments.
} {
    if { [db_0or1row is_imsld {
        select 1 from imsld_imsldsi where item_id = :activity_item_id
    }] } {
        imsld::process_imsld_as_ul -imsld_item_id $activity_item_id \
            -resource_mode $resource_mode \
            -dom_node $dom_node \
            -dom_doc $dom_doc
    } elseif { [db_0or1row is_learning {
        select 1 from imsld_learning_activitiesi where item_id = :activity_item_id
    }] } {
        imsld::process_learning_activity_as_ul -activity_item_id $activity_item_id \
            -run_id $run_id \
            -resource_mode $resource_mode \
            -dom_node $dom_node \
            -dom_doc $dom_doc
    } elseif { [db_0or1row is_support {
        select 1 from imsld_support_activitiesi where item_id = :activity_item_id
    }] } {
        imsld::process_support_activity_as_ul -activity_item_id $activity_item_id \
            -run_id $run_id \
            -resource_mode $resource_mode \
            -dom_node $dom_node \
            -dom_doc $dom_doc
        return
    } elseif { [db_0or1row is_structure {
        select 1 from imsld_activity_structuresi where item_id = :activity_item_id
    }] } {
        imsld::process_activity_structure_as_ul -structure_item_id $activity_item_id \
            -run_id $run_id \
            -resource_mode $resource_mode \
            -dom_node $dom_node \
            -dom_doc $dom_doc
    } else {
        return -code error "IMSLD::imsld::process_activity_as_ul: Invalid call"
    }
}

ad_proc -public imsld::process_activity_environments_as_ul {
    -activity_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
} {
    @param activity_item_id
    @param run_id
    @param rel_type
    @option resource_mode default f
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
        select 1 from imsld_learning_activitiesi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_la_env_rel
    } elseif { [db_0or1row is_support {
        select 1 from imsld_support_activitiesi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_sa_env_rel
    } elseif { [db_0or1row is_structure {
        select 1 from imsld_activity_structuresi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_as_env_rel
    } else {
        return -code error "IMSLD::imsld::process_activity_environments_as_ul: Invalid call"
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
        imsld::process_environment_as_ul -environment_item_id $environment_item_id \
            -run_id $run_id \
            -dom_node $dom_node \
            -dom_doc $dom_doc
    }
}

ad_proc -public imsld::process_imsld_as_ul {
    -imsld_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
} {
    @param imsld_item_id
    @param run_id
    @option resource_mode default f
    
    @return The html list (using tdom) of the resources associated to the given imsld_id (objectives and prerequisites).
} {
    db_1row imsld_info {
        select prerequisite_id as prerequisite_item_id,
        learning_objective_id as learning_objective_item_id,
        imsld_id
        from imsld_imsldsi
        where item_id = :imsld_item_id
        and content_revision__is_live(imsld_id) = 't'
    }

    # prerequisites
    set prerequisites_node [$dom_doc createElement div]
    $prerequisites_node setAttribute class "tabbertab"
    set prerequisites_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Prerequisites]"]
    $prerequisites_head_node appendChild $text
    $prerequisites_node appendChild $prerequisites_head_node
    if { ![string eq "" $prerequisite_item_id] } {
        # add the prerequisite files as items of the list

        set prerequisites_list [imsld::process_prerequisite_as_ul -imsld_item_id $imsld_item_id \
                                    -run_id $run_id \
                                    -resource_mode $resource_mode \
                                    -dom_node $prerequisites_node \
                                    -dom_doc $dom_doc]

    }
    $dom_node appendChild $prerequisites_node

    # learning objectives
    set objectives_node [$dom_doc createElement div]
    $objectives_node setAttribute class "tabbertab"
    set objectives_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Objectives]"]
    $objectives_head_node appendChild $text
    $objectives_node appendChild $objectives_head_node
    if { ![string eq "" $learning_objective_item_id] } {
        # add the prerequisite files as items of the list

        set objectives_list [imsld::process_learning_objective_as_ul -imsld_item_id $imsld_item_id \
                                 -run_id $run_id \
                                 -resource_mode $resource_mode \
                                 -dom_node $objectives_node \
                                 -dom_doc $dom_doc]

    }
    $dom_node appendChild $objectives_node
    
    if { [string eq $resource_mode "t"] } {
        return [concat $prerequisites_list $objectives_list]
    }
}

ad_proc -public imsld::process_learning_activity_as_ul { 
    -activity_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
} {
    @param activity_item_id
    @param run_id
    @option resource_mode default f
    @param dom_node
    @param dom_doc

    
    @return The list (activity_name, list of associated urls, using tdom) of the activity in the IMS-LD.
} {
    set user_id [ad_conn user_id]
    if { ![db_0or1row activity_info { *SQL* }] } {
        # is visible is false, do not show anything
        return
    }

    # get the items associated with the activity
    set description_node [$dom_doc createElement div]
    $description_node setAttribute class "tabbertab"
    set description_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Material]"]
    $description_head_node appendChild $text
    $description_node appendChild $description_head_node
    set linear_item_list [db_list item_linear_list { *SQL* }]

    set activity_items_list [list]
    foreach imsld_item_id $linear_item_list {
        foreach la_items_list [db_list_of_lists la_nested_associated_items { *SQL* }] {
            set resource_id [lindex $la_items_list 0]
            set resource_item_id [lindex $la_items_list 1]
            set resource_type [lindex $la_items_list 2]

            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $description_node

            if { [string eq "t" $resource_mode] } { 
                lappend activity_items_list $resource_item_id
            }
        }
    }
    if { [llength $linear_item_list ] > 0 } { $dom_node appendChild $description_node }

    # prerequisites
    set prerequisites_node [$dom_doc createElement div]
    $prerequisites_node setAttribute class "tabbertab"
    set prerequisites_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Prerequisites]"]
    $prerequisites_head_node appendChild $text
    $prerequisites_node appendChild $prerequisites_head_node
    set prerequisites_list [list]
    if { ![string eq "" $prerequisite_item_id] } {
        # add the prerequisite files as items of the list

        set prerequisites_list [imsld::process_prerequisite_as_ul -activity_item_id $activity_item_id \
                                    -run_id $run_id \
                                    -resource_mode $resource_mode \
                                    -dom_node $prerequisites_node \
                                    -dom_doc $dom_doc]

        $dom_node appendChild $prerequisites_node
    }

    # learning objectives
    set objectives_node [$dom_doc createElement div]
    $objectives_node setAttribute class "tabbertab"
    set objectives_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Objectives]"]
    $objectives_head_node appendChild $text
    $objectives_node appendChild $objectives_head_node
    set objectives_list [list]
    if { ![string eq "" $learning_objective_item_id] } {
        # add the prerequisite files as items of the list

        set objectives_list [imsld::process_learning_objective_as_ul -activity_item_id $activity_item_id \
                                 -run_id $run_id \
                                 -resource_mode $resource_mode \
                                 -dom_node $objectives_node \
                                 -dom_doc $dom_doc]

        $dom_node appendChild $objectives_node
    }

    # process feedback only if the activity is finished
    set feedback_node [$dom_doc createElement div]
    $feedback_node setAttribute class "tabbertab"
    set feedback_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Feedback]"]
    $feedback_head_node appendChild $text
    $feedback_node appendChild $feedback_head_node
    if { [db_0or1row completed_activity { *SQL* }] } {
        if { ![string eq "" $on_completion_item_id] } {
            # the feedback is not processed to ckeck if all the activity resources have been finished
            # so we don't need to store the result
            imsld::process_feedback_as_ul -on_completion_item_id $on_completion_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $feedback_node
            $dom_node appendChild $feedback_node
        }
    }

    if { [string eq "t" $resource_mode] } {
        # get environments
        set environments_list [list]
        set associated_environments_list [db_list la_associated_environments { *SQL* }]
        foreach environment_item_id $associated_environments_list {
            if { [llength $environments_list] } {
                set environments_list [concat [list $environments_list] \
                                           [list [imsld::process_environment_as_ul -environment_item_id $environment_item_id -resource_mode $resource_mode -run_id $run_id -dom_node $dom_node -dom_doc $dom_doc]]]
            } else {
                set environments_list [imsld::process_environment_as_ul -environment_item_id $environment_item_id -resource_mode $resource_mode -run_id $run_id -dom_node $dom_node -dom_doc $dom_doc]
            }
        }
        
        # put in order the environments_id(s)
        set environments_ids [concat [lindex [lindex $environments_list 1] [expr [llength [lindex $environments_list 1] ] - 1 ]] \
                                     [lindex [lindex $environments_list 2] [expr [llength [lindex $environments_list 2] ] - 1 ]]]

         return [list [lindex $prerequisites_list [expr [llength $prerequisites_list] - 1]] \
                      [lindex $objectives_list [expr [llength $objectives_list ] - 1]] \
                      $environments_ids \
                      [lindex $activity_items_list [expr [llength $activity_items_list ] - 1]]]
    }
}

ad_proc -public imsld::process_support_activity_as_ul { 
    -activity_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
} {
    @param activity_item_id
    @param run_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return The list of items (resources, feedback, environments, using tdom) associated with the support activity
} {
    set user_id [ad_conn user_id]
    if { ![db_0or1row activity_info { *SQL* }] } {
        # is visible is false do not show anything
        return
    }

    # get the items associated with the activity
    set description_node [$dom_doc createElement div]
    $description_node setAttribute class "tabbertab"
    set description_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Material]"]
    $description_head_node appendChild $text
    $description_node appendChild $description_head_node
    set linear_item_list [db_list item_linear_list { *SQL* }]
    foreach imsld_item_id $linear_item_list {
        foreach sa_items_list [db_list_of_lists sa_nested_associated_items { *SQL* }] {
            set resource_id [lindex $sa_items_list 0]
            set resource_item_id [lindex $sa_items_list 1]
            set resource_type [lindex $sa_items_list 2]
            if {[string eq "t" $resource_mode] } { 
                lappend sa_resource_item_list $resource_item_id
            }
            
            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $description_node

            if { [string eq "t" $resource_mode] } { 
                lappend activity_items_list $sa_resource_item_list
            }
        }
    }
    if { [llength $linear_item_list ] > 0 } { $dom_node appendChild $description_node }

    # process feedback only if the activity is finished
    set feedback_node [$dom_doc createElement div]
    $feedback_node setAttribute class "tabbertab"
    set feedback_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Feedback]"]
    $feedback_head_node appendChild $text
    $feedback_node appendChild $feedback_head_node
    if { [db_0or1row completed_activity { *SQL* }] } {
        if { ![string eq "" $on_completion_item_id] } {
            # the feedback is not processed to ckeck if all the activity resources have been finished
            # so we don't need to store the result
            imsld::process_feedback_as_ul -on_completion_item_id $on_completion_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $feedback_node
            $dom_node appendChild $feedback_node
        }
    }

    if { [string eq "t" $resource_mode] } {
        # get environments
        set environments_list [list]
        set associated_environments_list [db_list sa_associated_environments { *SQL* }]
        foreach environment_item_id $associated_environments_list {
            if { [llength $environments_list] } {
                set environments_list [concat [list $environments_list] \
                                           [list [imsld::process_environment_as_ul -environment_item_id $environment_item_id -run_id $run_id -resource_mode $resource_mode -dom_node $dom_node -dom_doc $dom_doc]]]
            } else {
                set environments_list [imsld::process_environment_as_ul -environment_item_id $environment_item_id -run_id $run_id -resource_mode $resource_mode -dom_node $dom_node -dom_doc $dom_doc]
            }
        }

        # put in order the environments_id(s)
        set environments_ids [concat [lindex [lindex $environments_list 1] [expr [llength [lindex $environments_list 1] ] - 1 ]] \
                                     [lindex [lindex $environments_list 2] [expr [llength [lindex $environments_list 2] ] - 1 ]] ]

         return [list $environments_ids \
                      [lindex $activity_items_list [expr [llength $activity_items_list ] - 1]]]
    } 
}

ad_proc -public imsld::process_activity_structure_as_ul {
    -structure_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
} {
    @param structure_item_id
    @param run_id
    @option resource_mode
    @param dom_node
    @param dom_doc
    
    @return The html list (using tdom) of items (information) associated with the activity structure
} {

    # get the items associated with the activity
    set info_tab_node [$dom_doc createElement li]
    set text [$dom_doc createTextNode "[_ imsld.Information]"]
    $info_tab_node appendChild $text
    set info_node [$dom_doc createElement ul]
    # FIX-ME: if the ul is empty, the browser show the ul incorrectly
    set text [$dom_doc createTextNode ""]    
    $info_node appendChild $text
    
    set linear_item_list [db_list item_linear_list { *SQL* }]

    set resource_items_list [list]
    foreach imsld_item_id $linear_item_list {
        foreach la_items_list [db_list_of_lists as_nested_associated_items { *SQL* }] {
            set resource_id [lindex $la_items_list 0]
            set resource_item_id [lindex $la_items_list 1]
            set resource_type [lindex $la_items_list 2]
            if { [string eq "t" $resource_mode] } { 
                lappend resource_items_list $resource_item_id
            }
            
            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $info_node
        }
    }
    $info_tab_node appendChild $info_node
    $dom_node appendChild $info_tab_node
    if { [string eq "t" $resource_mode] } { 
        return $resource_items_list
    }
}

ad_proc -public imsld::generate_structure_activities_list {
    -imsld_id
    -run_id
    -structure_item_id
    -user_id
    -role_part_id
    -play_id
    -act_id
    {-next_activity_id_list ""}
    -dom_node
    -dom_doc
} {
    @param imsld_id
    @param run_id
    @param structure_item_id
    @param user_id
    @param role_part_id
    @param play_id
    @param act_id

    @return A list of lists of the activities referenced from the activity structure
} {
    # auxiliary list to store the activities
    set completed_list [list]
    # get the structure info
    db_1row structure_info { *SQL* }
    # get the referenced activities which are referenced from the structure
    foreach referenced_activity [db_list_of_lists struct_referenced_activities { *SQL* }] {
        # get all the directly referenced activities (from the activity structure)
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        set rel_id [lindex $referenced_activity 2]
        switch $rel_type {
            imsld_as_la_rel {
                # add the activiti to the TCL list
                db_1row get_learning_activity_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_la_rels where rel_id = :rel_id
                }
                set completed_p [db_0or1row completed_p { *SQL* }]
                # show the activity only if:
                # 1. it has been already completed
                # 2. if the structure-type is "selection"
                # 3. if it is the next activity to be done (and structure-type is "sequence") 
                if { $completed_p || [string eq $complete_act_id ""] || [string eq $structure_type "selection"] || ([string eq $is_visible_p "t"] && [lsearch -exact $next_activity_id_list $activity_id] != -1) } {
                    set activity_node [$dom_doc createElement li]
                    $activity_node setAttribute class "liOpen"

                    set a_node [$dom_doc createElement a]
                    $a_node setAttribute href "[export_vars -base "activity-frame" -url {activity_id run_id}]"
                    $a_node setAttribute target "content"
                    set text [$dom_doc createTextNode "$activity_title"]
                    $a_node appendChild $text
                    $activity_node appendChild $a_node

                    set text [$dom_doc createTextNode " "]
                    $activity_node appendChild $text

                    if { !$completed_p } {
                        set input_node [$dom_doc createElement input]
                        $input_node setAttribute type "checkbox"
                        $input_node setAttribute style "vertical-align: bottom;"
                        $input_node setAttribute onclick "window.location=\"finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-learning.imsld\""
                        $activity_node appendChild $input_node
                    } else {
                        set input_node [$dom_doc createElement input]
                        $input_node setAttribute type "checkbox"
                        $input_node setAttribute checked "true"
                        $input_node setAttribute disabled "true"
                        $activity_node appendChild $input_node
                    }

                    set completed_list [linsert $completed_list $sort_order [$activity_node asList]]
                }
            }
            imsld_as_sa_rel {
                # add the activiti to the TCL list
                db_1row get_support_activity_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_sa_rels where rel_id = :rel_id
                }
                set completed_p [db_0or1row completed_p { *SQL* }]
                # show the activity only if:
                # 1. it has been already completed
                # 2. if the structure-type is "selection"
                # 3. if it is the next activity to be done (and structure-type is "sequence") 
                if { $completed_p || [string eq $complete_act_id ""] || [string eq $structure_type "selection"] || ([string eq $is_visible_p "t"] && [lsearch -exact $next_activity_id_list $activity_id] != -1) } {
                    set activity_node [$dom_doc createElement li]
                    $activity_node setAttribute class "liOpen"
                    set a_node [$dom_doc createElement a]
                    $a_node setAttribute href "[export_vars -base "activity-frame" -url {activity_id run_id}]"
                    $a_node setAttribute target "content"
                    set text [$dom_doc createTextNode "$activity_title"]
                    $a_node appendChild $text
                    $activity_node appendChild $a_node

                    set text [$dom_doc createTextNode " "]
                    $activity_node appendChild $text
                    
                    if { !$completed_p } {
                        set input_node [$dom_doc createElement input]
                        $input_node setAttribute type "checkbox"
                        $input_node setAttribute style "vertical-align: bottom;"
                        $input_node setAttribute onclick "window.location=\"finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-support.imsld\""
                        $activity_node appendChild $input_node
                    } else {
                        set input_node [$dom_doc createElement input]
                        $input_node setAttribute type "checkbox"
                        $input_node setAttribute checked "true"
                        $input_node setAttribute disabled "true"
                        $activity_node appendChild $input_node
                    }

                    set completed_list [linsert $completed_list $sort_order [$activity_node asList]]
                }
            }
            imsld_as_as_rel {
                # add the structure to the list only if:
                # 1. the structure has already been started or finished
                # 2. the referencer structure-type is "selection"
                # (if it is the next activity to be done then it should had been marked as started 
                #  in the "structure_next_activity" function. which is the case when structure-type is "sequence")
                db_1row get_activity_structure_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_as_rels where rel_id = :rel_id
                }
                set started_p [db_0or1row as_completed_p { *SQL* }]
                if { $started_p || [string eq $structure_type "selection"] } {
                    set structure_node [$dom_doc createElement li]
                    $structure_node setAttribute class "liOpen"
                    set a_node [$dom_doc createElement a]
                    $a_node setAttribute href "[export_vars -base "activity-frame" -url {{activity_id $structure_id} run_id}]"
                    $a_node setAttribute target "content"
                    set text [$dom_doc createTextNode "$activity_title"]
                    $a_node appendChild $text
                    $structure_node appendChild $a_node

                    set nested_activities_list [imsld::generate_structure_activities_list -imsld_id $imsld_id \
                                                    -run_id $run_id \
                                                    -structure_item_id $structure_item_id \
                                                    -user_id $user_id \
                                                    -next_activity_id_list $next_activity_id_list \
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
    }
    return $completed_list
}

ad_proc -public imsld::generate_activities_tree {
    -run_id:required
    -user_id
    {-next_activity_id_list ""}
    -dom_node
    -dom_doc
} {
    @param run_id
    @param user_id

    @return A list of lists of the activities 
} {
    db_1row imsld_info {
        select imsld_id 
        from imsld_runs
        where run_id = :run_id
    }
    # start with the role parts

    set user_roles_list [imsld::roles::get_user_roles -user_id $user_id -run_id $run_id]
    foreach role_part_list [db_list_of_lists referenced_role_parts { *SQL* }] {
        set type [lindex $role_part_list 0]
        set activity_id [lindex $role_part_list 1]
        set role_part_id [lindex $role_part_list 2]
        set act_id [lindex $role_part_list 3]        
        set play_id [lindex $role_part_list 4]
        switch $type {
            learning {
                # add the learning activity to the tree
                db_1row get_learning_activity_info { *SQL* }
                set completed_activity_p [db_0or1row already_completed {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'finished'
                }]
                if { $completed_activity_p || [lsearch -exact $next_activity_id_list $activity_id] != -1 && ([string eq $complete_act_id ""] || [string eq $is_visible_p "t"]) } {
                    set activity_node [$dom_doc createElement li]
                    $activity_node setAttribute class "liOpen"
                    set a_node [$dom_doc createElement a]
                    $a_node setAttribute href "[export_vars -base "activity-frame" -url {activity_id run_id}]"
                    $a_node setAttribute target "content"
                    set text [$dom_doc createTextNode "$activity_title"]
                    $a_node appendChild $text
                    $activity_node appendChild $a_node

                    set text [$dom_doc createTextNode " "]
                    $activity_node appendChild $text
                        
                    if { !$completed_activity_p } {
                        set input_node [$dom_doc createElement input]
                        $input_node setAttribute type "checkbox"
                        $input_node setAttribute style "vertical-align: bottom;"
                        $input_node setAttribute onclick "window.location=\"finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-learning.imsld\""
                        $activity_node appendChild $input_node
                    } else {
                        set input_node [$dom_doc createElement input]
                        $input_node setAttribute type "checkbox"
                        $input_node setAttribute checked "true"
                        $input_node setAttribute disabled "true"
                        $activity_node appendChild $input_node
                    }

                    $dom_node appendChild $activity_node
                }
            }
            support {
                # add the support activity to the tree
                db_1row get_support_activity_info { *SQL* }
                set completed_activity_p [db_0or1row already_completed {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'finished'
                }]
                if { $completed_activity_p || [lsearch -exact $next_activity_id_list $activity_id] != -1 && ([string eq $complete_act_id ""] || [string eq $is_visible_p "t"]) } {
                    set activity_node [$dom_doc createElement li]
                    $activity_node setAttribute class "liOpen"
                    set a_node [$dom_doc createElement a]
                    $a_node setAttribute href "[export_vars -base "activity-frame" -url {activity_id run_id}]"
                    $a_node setAttribute target "content"
                    set text [$dom_doc createTextNode "$activity_title"]
                    $a_node appendChild $text
                    $activity_node appendChild $a_node

                    set text [$dom_doc createTextNode " "]
                    $activity_node appendChild $text
                    
                    if { !$completed_activity_p } {
                        set input_node [$dom_doc createElement input]
                        $input_node setAttribute type "checkbox"
                        $input_node setAttribute style "vertical-align: bottom;"
                        $input_node setAttribute onclick "window.location=\"finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-support.imsld\""
                        $activity_node appendChild $input_node
                    } else {
                        set input_node [$dom_doc createElement input]
                        $input_node setAttribute type "checkbox"
                        $input_node setAttribute checked "true"
                        $input_node setAttribute disabled "true"
                        $activity_node appendChild $input_node
                    }

                    $dom_node appendChild $activity_node
                }
            }
            structure {
                # this is a special case since there are some conditions to check
                # in order to determine if the referenced activities have to be shown
                # because of that the proc generate_structure_activities_list is called,
                # which returns a tcl list in tDOM format.
                
                # anyway, we add the structure to the tree only if:
                # 1. the structure has already been started or finished
                # 2. the referencer structure-type is "selection"
                # (if it is the next activity to be done then it should had been marked as started 
                #  in the "structure_next_activity" function. which is the case when structure-type is "sequence")
                db_1row get_activity_structure_info { *SQL* }
                set started_p [db_0or1row as_completed_p { *SQL* }]
                if { $started_p || [string eq $structure_type "selection"] } {
                    set structure_node [$dom_doc createElement li]
                    $structure_node setAttribute class "liOpen"
                    set a_node [$dom_doc createElement a]
                    $a_node setAttribute href "[export_vars -base "activity-frame" -url {{activity_id $structure_id} run_id}]"
                    $a_node setAttribute target "content"
                    set text [$dom_doc createTextNode "$activity_title"]
                    $a_node appendChild $text
                    $structure_node appendChild $a_node
                    set nested_list [imsld::generate_structure_activities_list -imsld_id $imsld_id \
                                         -run_id $run_id \
                                         -structure_item_id $structure_item_id \
                                         -user_id $user_id \
                                         -next_activity_id_list $next_activity_id_list \
                                         -role_part_id $role_part_id \
                                         -play_id $play_id \
                                         -act_id $act_id \
                                         -dom_doc $dom_doc \
                                         -dom_node $dom_node]
                    # the nested finished activities are returned as a tcl list in tDOM format
                    $structure_node appendFromList [list ul [list] [concat [list] $nested_list]]
                    $dom_node appendChild $structure_node
                }
            }
        }
    }
}

ad_proc -public imsld::get_next_activity_list { 
    -run_id:required
    {-user_id ""}
} {
    @param imsld_item_id
    @param run_id
    @option user_id default [ad_conn user_id]
    
    @return The list of next activity_ids of each role_part and play in the IMS-LD.
} {

    # get the imsld info
    db_1row get_ismld_info {
        select ii.imsld_id, ii.item_id as imsld_item_id
        from imsld_imsldsi ii, imsld_runs run
        where ii.imsld_id = run.imsld_id
        and run.run_id = :run_id
    }
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set next_act_item_id_list [list]

    # search trough each play
    foreach play_list [db_list_of_lists imsld_plays {
        select ip.play_id,
        ip.item_id
        from imsld_playsi ip, imsld_methodsi im
        where ip.method_id = im.item_id
        and im.imsld_id = :imsld_item_id
        and content_revision__is_live(ip.play_id) = 't'
    }] {
        set play_id [lindex $play_list 0]
        set play_item_id [lindex $play_list 1]
        # get the act_id of the last completed activity,
        # search for the last completed act in the play
        if { ![db_0or1row get_last_completed {
            select stat.related_id,
            stat.role_part_id,
            stat.type,
            stat.act_id
            from imsld_status_user stat
            where stat.user_id = :user_id
            and run_id = :run_id
            and stat.play_id = :play_id
            and stat.type in ('learning','support','structure')
            order by stat.status_date desc
            limit 1
        }] } {
            # if there is no completed activity for the act, it hasn't been started yet. get the first act_id
            lappend next_act_item_id_list [db_string first_act {
                select ia.item_id as act_item_id
                from imsld_actsi ia
                where ia.play_id = :play_item_id
                and ia.sort_order = (select min(ia2.sort_order) from imsld_acts ia2 where ia2.play_id = :play_item_id)
            }]
            continue
        }
        if { ![imsld::act_finished_p -run_id $run_id -act_id $act_id -user_id $user_id] } {
            lappend next_act_item_id_list [content::revision::item_id -revision_id $act_id]
            continue
        }
        # if we reached this point, we have to search for the next act in the play
        db_1row act_info {
            select sort_order as act_sort_order
            from imsld_acts
            where act_id = :act_id
        }
        if { [db_0or1row search_current_play {
            select ia.item_id as act_item_id
            from imsld_actsi ia
            where ia.play_id = :play_item_id
            and ia.sort_order = :act_sort_order + 1
        }] } {
            # get the current play_id's sort_order and sarch in the next play in the current method_id
            set all_users_finished 1
            #the act is only showed as next activity when all users in roles has finished the previous act
            
            if {[db_0or1row get_last_act { select ia2.act_id as last_act_id from imsld_actsi ia1, imsld_acts ia2 where ia1.item_id=:act_item_id and ia2.sort_order=(ia1.sort_order -1) and ia1.play_id=ia2.play_id}]
                } {
                #get list of involved roles
                set roles_list [imsld::roles::get_list_of_roles -imsld_id $imsld_id]
                    
                #get list of involved users
                set users_list [list]
                foreach role $roles_list {
                    set users_in_role [imsld::roles::get_users_in_role -role_id [lindex $role 0] -run_id $run_id]
                    set users_list [concat $users_list $users_in_role]
                }

                #check if all has finished the act
                foreach user $users_list {
                    if {![imsld::act_finished_p -act_id $last_act_id -run_id $run_id -user_id $user]} {
                        set all_users_finished 0
                    }
                }
            }

            if {$all_users_finished} {
                lappend next_act_item_id_list $act_item_id
            }
        }
    }


    # 1. for each act in the next_act_id_list
    # 1.2. for each role_part in the act
    # 1.2.1 find the next activity referenced by the role_part
    #       (learning_activity, support_activity, activity_structure)  
    # 1.2.1.1 if it is a learning or support activity, no problem, find the associated files and return the lists
    # 2.2.1.2 if it is an activity structure we have verify which activities are already completed and return the next
    #         activity in the activity structure, handling the case when the next activity is also an activity structure


    set user_roles_list [imsld::roles::get_user_roles -user_id $user_id -run_id $run_id]
    set next_activity_id_list [list]
    foreach act_item_id $next_act_item_id_list {
        foreach role_part_id [db_list act_role_parts "
            select irp.role_part_id 
                   from imsld_role_parts irp,
                   imsld_rolesi iri 
            where content_revision__is_live(irp.role_part_id)='t' 
                  and irp.act_id=:act_item_id 
                  and irp.role_id=iri.item_id 
                   and iri.role_id in ([join $user_roles_list ","])
        "] {
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
                end as next_activity_id,
                environment_id as rp_environment_item_id
                from imsld_role_parts
                where role_part_id = :role_part_id
            }
            # activity structure
            if { [string eq $activity_type structure] } {
                # activity structure. we have to look for the next learning or support activity
                set activity_list [imsld::structure_next_activity -activity_structure_id $next_activity_id -imsld_id $imsld_id -run_id $run_id -role_part_id $role_part_id]
                set next_activity_id [lindex $activity_list 0]
            }
            lappend next_activity_id_list $next_activity_id
        }
    }
    # return the next_activity_id_list
    return $next_activity_id_list
}

ad_proc -public imsld::get_activity_from_environment { 
   -environment_item_id
   
} { 
    @return The a list of lists of the activity_id, activity_item_id and activity_type from which the environment is being referenced
} {
    set activities_list [list]
    foreach environment_list [db_list_of_lists get_env_info {
        select ar.object_id_one,
        ar.rel_type
        from acs_rels ar
        where ar.object_id_two = :environment_item_id
    }] {
        set object_id_one [lindex $environment_list 0]
        set rel_type [lindex $environment_list 1]
        # the enviroment may be referenced froma learning activity, support activity or from an enviroment!
        if { [string eq $rel_type imsld_la_env_rel] } {
            set activities_list [concat $activities_list [db_list_of_lists learning_env_ref {
                select la.activity_id,
                la.item_id,
                'learning'
                from imsld_learning_activitiesi la
                where la.item_id = :object_id_one
            }]]
        }
        if { [string eq $rel_type imsld_sa_env_rel] } {
            set activities_list [concat $activities_list [db_list_of_lists support_env_ref {
                select sa.activity_id,
                sa.item_id,
                'support'
                from imsld_support_activitiesi sa
                where sa.item_id = :object_id_one
            }]]
        }
        if { [string eq $rel_type imsld_env_env_rel] } {
            # the environment is referenced fron another environment.
            # we get the referencer environment and call this function again (recursivity is our friend =)
            # and besides, the environment may be referenced from more than one environment!
            set activities_list_nested [list]
            foreach referenced_environment [db_list_of_lists get_referencer_env_info {
                select ar.object_id_one as env_referencer_id
                from acs_rels ar
                where ar.object_id_two = :object_id_one
            }] {
                set referencer_env_item_id [lindex $referenced_environment 0]
                set activities_list_nested [concat $activities_list_nested [imsld::get_activity_from_environment -environment_item_id $referencer_env_item_id]]
            }
            set activities_list [concat $activities_list $$activities_list]
        }
    }
    return $activities_list
}

ad_proc -public imsld::get_activity_from_resource { 
   -resource_id
} { 
    @return The a list of lists of the activity_id, activity_item_id and activity_type from which the resource is being referenced
} {
    set activities_list [list]
    # find out the rel_type in order to know from which activity the resource is being referenced
    foreach object_list [db_list_of_lists directly_mapped_info {
        select ar.rel_type,
        ar.object_id_one
        from acs_rels ar, imsld_cp_resourcesi icr 
        where icr.resource_id = :resource_id 
        and ar.object_id_two = icr.item_id
    }] {
        set rel_type [lindex $object_list 0]
        set object_id_one [lindex $object_list 1]
        if { [string eq $rel_type imsld_item_res_rel] } {
            # get item info
            foreach nested_object_list [db_list_of_lists get_nested_info {
                select ar.rel_type as rel_type_nested,
                ar.object_id_one as object_id_nested
                from acs_rels ar
                where ar.object_id_two = :object_id_one
            }] {
                set rel_type_nested [lindex $nested_object_list 0]
                set object_id_nested [lindex $nested_object_list 1]
                if { [string eq $rel_type_nested imsld_preq_item_rel] } {
                    # get the learning_activity_id and return it
                    set activities_list [concat $activities_list [db_list_of_lists get_prereq_activity {
                        select la.activity_id,
                        la.item_id as activity_item_id,
                        'learning'
                        from imsld_learning_activitiesi la,
                        imsld_prerequisitesi prereq
                        where prereq.item_id = :object_id_nested
                        and la.prerequisite_id = prereq.item_id
                    }]]
                }
                if { [string eq $rel_type_nested imsld_lo_item_rel] } {
                    # get the learning_activity_id and return it
                        set activities_list [concat $activities_list [db_list_of_lists get_lobjective_activity {
                        select la.activity_id,
                        la.item_id as activity_item_id,
                        'learning'
                        from imsld_learning_activitiesi la,
                        imsld_learning_objectivesi lobjectives
                        where lobjectives.item_id = :object_id_nested
                        and la.learning_objective_id = lobjectives.item_id
                        }]]
                }
                if { [string eq $rel_type_nested imsld_actdesc_item_rel] } {
                    # get the learning or support activity and return it
                    if { [db_0or1row learning_activity_ref {
                        select la.activity_id,
                        la.item_id as activity_item_id,
                        'learning'
                        from imsld_learning_activitiesi la,
                        imsld_activity_descsi ades
                        where ades.item_id = :object_id_nested
                        and la.activity_description_id = ades.item_id
                    }] } {
                        set activities_list [concat $activities_list [list [list $activity_id $activity_item_id learning]]]
                    } else {
                        set activities_list [concat $activities_list [db_list_of_lists support_activity_ref {
                            select sa.activity_id,
                            sa.item_id as activity_item_id,
                            'support'
                            from imsld_support_activitiesi sa,
                            imsld_activity_descsi ades
                            where ades.item_id = :object_id_nested
                            and sa.activity_description_id = ades.item_id
                        }]]
                    }
                }
                if { [string eq $rel_type_nested imsld_as_info_i_rel] } {
                    # get the activity_structure_id and return it
                    set activities_list [concat $activities_list [db_list_of_lists activity_structure_ref {
                        select structure_id as activity_id,
                        item_id as activity_item_id,
                        'structure'
                        from imsld_activity_structuresi
                        where item_id = :object_id_nested
                    }]]
                }
                if { [string eq $rel_type_nested imsld_l_object_item_rel] } {
                    # item referenced from a learning object, which it's referenced fron an environment
                    # get the environment
                    db_1row get_env_lo_info {
                        select lo.environment_id as environment_item_id
                        from imsld_learning_objectsi lo
                        where lo.item_id = :object_id_nested
                    }
                    set activities_list [concat $activities_list [imsld::get_activity_from_environment -environment_item_id $environment_item_id]]
                }
            }
            # if we reached this point, the resource may be reference fron a conference service
            # which is referenced from an environment
            if { [db_0or1row get_env_serv_info {
                select serv.environment_id as environment_item_id
                from imsld_conference_servicesi ecs,
                imsld_servicesi serv
                where ecs.item_id = :object_id_one
                and ecs.service_id = serv.item_id
            }] } {
                set activities_list [concat $activities_list [imsld::get_activity_from_environment -environment_item_id $environment_item_id]]
            }
        }        
    }
    return $activities_list
}

ad_proc -public imsld::get_imsld_from_activity { 
   -activity_id
    -activity_type
} { 
    @return The imsld_id from which the activity is being used.
} {
    switch $activity_type {
        learning {
            db_1row get_imsld_from_la_activity { *SQL* }
        }
        support {
            db_1row get_imsld_from_sa_activity { *SQL* }
        }
        structure {
            db_1row get_imsld_from_as_activity { *SQL* }
        }
    }
    return $imsld_id
}

ad_proc -public imsld::get_resource_from_object {
    -object_id
} {
    <p>Get the object which is asociated with an acs_object_id</p>
    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
    db_1row get_resource {
        select resource_id
        from imsld_cp_resources
        where acs_object_id = :object_id
    }
    return $resource_id
}

ad_proc -public imsld::finish_resource {
    -resource_id
    -run_id
} {
    <p>Tag a resource as finished into an activity. Return true if success, false otherwise</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {


    #look for the asociated activities
    set activities_list [imsld::get_activity_from_resource -resource_id $resource_id]
    # process each activity
    foreach activity_list $activities_list {
        if { !([llength $activity_list] == 3) } {
            # it's not refrenced from an activity, skip it
            break
        }
        # set the activity_id, activity_item_id and activity_type
        set activity_id [lindex $activity_list 0]
        set activity_item_id [lindex $activity_list 1]
        set activity_type [lindex $activity_list 2]
        
        #get info
        set role_part_id_list [imsld::get_role_part_from_activity -activity_type $activity_type -leaf_id $activity_item_id]
        set imsld_id [imsld::get_imsld_from_activity -activity_id $activity_id -activity_type $activity_type]
        set user_id [ad_conn user_id]
        
        #if not done yet, tag the resource as finished
        if { ![db_string check_completed_resource { *SQL* }] } {
            db_dml insert_completed_resource { *SQL* }
        }
        #find all the resouces in the same activity 

        dom createDocument foo foo_doc
        set foo_node [$foo_doc documentElement]
        switch $activity_type {
            learning {
                set first_resources_item_list [imsld::process_learning_activity_as_ul -run_id $run_id -activity_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
            }
            support {
                set first_resources_item_list [imsld::process_support_activity_as_ul -run_id $run_id -activity_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
            }
            structure {
                set first_resources_item_list [imsld::process_activity_structure_as_ul -run_id $run_id -structure_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
            }
        }

        #only the learning_activities must be finished
        set resources_item_list [lindex $first_resources_item_list 3]
        if { [llength $resources_item_list] == 0 } {
            set resources_item_list [lindex $first_resources_item_list 2]
        }
        
        set all_finished_p 1
        foreach resource_item_id $resources_item_list { 
            foreach res_id $resource_item_id {
                if { ![db_0or1row resource_finished_p {
                    select 1 
                    from imsld_status_user stat, imsld_cp_resourcesi icr
                    where icr.item_id = :res_id
                    and icr.resource_id = stat.completed_id
                    and user_id = :user_id
                    and run_id = :run_id
                    and status = 'finished'
                }] } {
                    # if the resource is not in the imsld_status_user, then the resource is not finished
                    set all_finished_p 0
                    break
                }
            }
        }

        #if all are finished, tag the activity as finished
        if { $all_finished_p && ![db_0or1row already_finished { *SQL* }] } {
            foreach role_part_id $role_part_id_list {
                db_1row context_info {
                    select acts.act_id,
                    plays.play_id
                    from imsld_actsi acts, imsld_playsi plays, imsld_role_parts rp
                    where rp.role_part_id = :role_part_id
                    and rp.act_id = acts.item_id
                    and acts.play_id = plays.item_id
                }
                imsld::finish_component_element -imsld_id $imsld_id  \
                    -run_id $run_id \
                    -play_id $play_id \
                    -act_id $act_id \
                    -role_part_id $role_part_id \
                    -element_id $activity_id \
                    -type $activity_type\
                    -code_call
            }
        }
    }
}

ad_proc -public imsld::get_property_id {
    -identifier:required
    -imsld_id:required
} {
    <p>Get the property_id from the property_identifier in a imsld_id</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {

    return
    return [db_string get_property_id {
        select ip.property_id 
        from imsld_properties ip, 
        imsld_componentsi ici,
        imsld_imsldsi iii
        where ip.component_id=ici.item_id 
        and ici.imsld_id=iii.item_id
        and iii.imsld_id=:imsld_id
        and ip.identifier=:identifier
       }]
}


ad_proc -public imsld::grant_permissions {
    -resources_activities_list
    -user_id
} {
    <p>Grant permissions to imsld files related to imsld resources</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
        foreach the_resource_id [join $resources_activities_list] {

            if {![db_0or1row get_object_from_resource {}]} {
            
                set related_cr_items [db_list get_cr_item_from_resource {} ]
                
                foreach the_object_id $related_cr_items {
                    permission::grant -party_id $user_id -object_id $the_object_id  -privilege "read"
                }
            } else {
                if {[db_0or1row is_forum {}]} {
                    permission::grant -party_id $user_id -object_id $the_object_id  -privilege "forum_moderate"
                } 

                permission::grant -party_id $user_id -object_id $the_object_id  -privilege "read"
            }
   }
}
ad_register_proc GET /finish-component-element* imsld::finish_component_element
ad_register_proc POST /finish-component-elementx* imsld::finish_component_element
