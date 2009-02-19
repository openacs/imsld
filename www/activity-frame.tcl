# packages/imsld/www/activity-frame.tcl

ad_page_contract {

    This is the frame that contains the associated URLs of an activity

    @author Eduardo Pérez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    run_id:integer,notnull
    activity_id:integer,notnull
    {role_id ""}
    {supported_user_id ""}
    {user_id ""}
}

set user_id [expr { [string eq $user_id ""] ? [ad_conn user_id] : $user_id }]

set iframe_activity_url ""

set roles_template_p 0
db_1row get_activity_type { *SQL* }

# make sure the activity is marked as started for this user
db_dml mark_activity_started { *SQL* }

set activity_item_id [content::revision::item_id -revision_id $activity_id]

set referencer_structure_item_id ""

if { [string eq $activity_type "learning"] } {
    if { [string eq "" [db_string completion_restriction {select complete_act_id from imsld_learning_activities where activity_id = :activity_id}]] } {
	# the learning activity has been visited and doesn't have any completion restriction.
	# if it is referenced from an activity structure, verify if every referenced activity have been visted
	db_0or1row referenced_from_structure_p { *SQL* }
    }
} elseif { [string eq $activity_type "support"] } {
    if { [string eq "" [db_string completion_restriction {select complete_act_id from imsld_support_activities where activity_id = :activity_id}]] } {
	# the learning activity has been visited and doesn't have any completion restriction.
	# if it is referenced from an activity structure, verify if every referenced activity have been visted
	db_0or1row referenced_from_structure_p { *SQL* }
    }
}

if { ![string eq "" $referencer_structure_item_id] } {
    db_1row get_structure_info { *SQL* }

    # if the structure hasn't been finished
    if { ![db_0or1row already_finished { *SQL* }] } {
	set mark_structure_finished_p 1
	set total_completed 0
	foreach referenced_activity [db_list_of_lists struct_referenced_activities { *SQL* }] {
	    set object_id_two [lindex $referenced_activity 0]
	    set rel_type [lindex $referenced_activity 1]
	    switch $rel_type {
		imsld_as_la_rel {
		    # if the activity doesn't have any completrion restriction 
		    # and it hasn't been started, cancel the completion of the structure
		    set referenced_activity_id [content::item::get_live_revision -item_id $object_id_two]
		    set la_completion_restriction [db_string la_completion_restriction { *SQL* }]
		    if { ([db_0or1row la_already_started_p { *SQL* }] && [string eq "" $la_completion_restriction]) \
			     || [db_0or1row la_already_finished { *SQL* }] } {
			# the activity has been visited
			incr total_completed
		    } else {
			set mark_structure_finished_p 0
			continue
		    }
		}
		imsld_as_sa_rel {
		    # if the activity doesn't have any completrion restriction 
		    # and it hasn't been started, cancel the completion of the structure
		    set referenced_activity_id [content::item::get_live_revision -item_id $object_id_two]
		    if { ([db_0or1row la_already_started_p { *SQL* }] && [string eq "" $sa_completion_restriction]) \
			     || [db_0or1row la_already_finished { *SQL* }] } {
			# the activity has been visited
			incr total_completed
		    } else {
			set mark_structure_finished_p 0
			continue
		    }
		} imsld_as_as_rel {
		    # if the referenced activity structure hasn't been finished, don't finish the activity structure
		    set structure_id [content::item::get_live_revision -item_id $object_id_two]
		    if { ![db_0or1row la_already_finished_p { *SQL* }] } {
			set mark_structure_finished_p 0
			continue
		    } else {
			incr total_completed
		    }
		}
	    }
	}
	if { $mark_structure_finished_p || (![string eq $number_to_select ""] && ($total_completed >= $number_to_select)) } {
	    # mark the structure as finished

	    set role_part_id_list [imsld::get_role_part_from_activity -activity_type structure -leaf_id $referencer_structure_item_id]
	    foreach role_part_id $role_part_id_list {
		db_1row context_info { *SQL* }
		
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
}

set supported_roles [db_list supported_roles_list { *SQL* }]

if {[llength $supported_roles]} {
    set roles_template_p 1 
}

if { !$roles_template_p } {

    dom createDocument div doc
    set dom_root [$doc documentElement]
    $dom_root setAttribute class "tabber"
    
    set activity_item_id [content::revision::item_id -revision_id $activity_id]
    imsld::process_activity_as_ul -activity_item_id $activity_item_id -run_id $run_id -dom_doc $doc -dom_node $dom_root
    
    if { ![string eq $activity_id ""] && [db_0or1row get_table_name { *SQL* }] && ![string eq "" $table_name] } {
        #grant permissions to resources in activity
        set resources_list [db_list get_resources_from_activity "
                        select ar2.object_id_two 
                        from $table_name ila,
                        acs_rels ar1,
                        acs_rels ar2 
                        where activity_id=:activity_id
                        and ar1.object_id_one=ila.activity_description_id 
                        and ar1.rel_type='imsld_actdesc_item_rel' 
                        and ar1.object_id_two=ar2.object_id_one 
                        and ar2.rel_type='imsld_item_res_rel'
    "]
        
        if {[string eq 'imsld_learning_activities' $table_name]} {
            
            set prerequisites_list [db_list get_prerequisites_list { *SQL* }]
            set objectives_list [db_list get_objectives_list { *SQL* }]
        } else {
            set prerequisites_list [list]
            set objectives_list [list]
        }
        set resources_list [concat $resources_list [concat $prerequisites_list $objectives_list]]
        imsld::grant_permissions -resources_activities_list $resources_list -user_id $user_id -run_id $run_id
    }

    set nodeList [$dom_root selectNodes {descendant::a}]
    set activity_url ""

    foreach node $nodeList {
	set href [$node getAttribute href]
	if { $href ne "" && ![string match {*\#*} $href] } {
	    set iframe_activity_url $href
	    break
	}
    }
    
    set activities [$dom_root asXML] 

} else {
    # a user has been selected to be supported
    # get the associated resource of the support activity
    db_1row activity_info { *SQL* }
    
    db_1row support_activity_associated_item { *SQL* }
    
    set activities [export_vars -base "imsld-content-serve" -url { run_id resource_item_id role_id {owner_user_id $supported_user_id} }]

    set iframe_activity_url $activities
}

set page_title {}
set context [list]
