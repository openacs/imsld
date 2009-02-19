set act_item_id [content::revision::item_id -revision_id $act_id]
set user_id [ad_conn user_id]

set structure_type ""
set completion_restriction 1
if {[info exists structure_item_id]} {
    # if the activity is in a structure, get the structure's info
    db_1row structure_info { *SQL* }
    set completion_restriction [imsld::structure_completion_resctriction_p -run_id $run_id -structure_item_id $structure_item_id]
}

if {![info exists sort_order]} {
    set sort_order 0
}
if {![info exists siblings_number]} {
    set siblings_number 0
}

switch $type {
    learning {
	# add the learning activity to the tree
	
	db_1row get_learning_activity_info { *SQL* }
	
	set user_choice_p [db_string user_choice_p {
	    select user_choice_p
	    from imsld_complete_actsi
	    where item_id = :complete_act_id
	    and content_revision__is_live(complete_act_id) = 't'
	} -default "f"]

	set href [export_vars -base "activity-frame" -url {activity_id run_id type}]
	set div $href
	
    }
    support {
	# add the support activity to the tree
	db_1row get_support_activity_info { *SQL* }
	set started_activity_p [db_0or1row already_started {
	    select 1 from imsld_status_user 
	    where related_id = :activity_id 
	    and user_id = :user_id 
	    and run_id = :run_id
	    and status = 'started'
	}]
	set completed_activity_p [db_0or1row already_completed {
	    select 1 from imsld_status_user 
	    where related_id = :activity_id 
	    and user_id = :user_id 
	    and run_id = :run_id
	    and status = 'finished'
	}]

	set user_choice_p [db_string user_choice_p {select user_choice_p from imsld_complete_actsi where item_id = :complete_act_id and content_revision__is_live(complete_act_id) = 't'} -default "f"]

	if { $completed_activity_p 
	     || ($structure_type eq "selection")
	     || (!$completion_restriction)
	     || ([lsearch -exact $next_activity_id_list $activity_id] != -1)
	     || ([string eq $complete_act_id ""] && [string eq $is_visible_p "t"]
		 && [lsearch -exact $active_acts_list $act_item_id] != -1) } {

	    set activity_node [$dom_doc createElement li]
	    $activity_node setAttribute class "liOpen"
	    if { !$started_activity_p && [string eq $is_visible_p "t"] } {
		# bold letters
		set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
		set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]

		set class "liOpen has_focus"
	    } else {
		set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
		set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]

		set class "liOpen"
	    }

	    set finish_href "finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-support.imsld"

	}
    }
    structure {
	# this is a special case since there are some conditions to check
	# in order to determine if the referenced activities have to be shown.
	# because of that the proc generate_structure_activities_list is called,
	# which returns a tcl list in tDOM format.
	
	# anyway, we add the structure to the tree only if:
	# 1. the structure has already been started or finished
	# 2. the referencer structure-type is "selection"
	# (if it is the next activity to be done then it should had been marked as started 
	#  in the "structure_next_activity" function. which is the case when structure-type is "sequence")
	db_1row get_activity_structure_info { *SQL* }

	set href [export_vars -base "activity-frame" -url {activity_id run_id type}]
	set div $href
	
	db_multirow -extend {r_activity_id} referenced_activities struct_referenced_activities { *SQL* } {
	    set r_activity_id [content::item::get_live_revision -item_id $object_id_two]
	}
	
    }
}