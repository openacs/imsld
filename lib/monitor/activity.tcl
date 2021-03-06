set act_item_id [content::revision::item_id -revision_id $act_id]
set user_id [ad_conn user_id]

set structure_type ""
if {[info exists structure_item_id]} {
    # if the activity is in a structure, get the structure's info
    db_1row structure_info { *SQL* }
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
	
	set href [export_vars -base "activity-frame" -url {activity_item_id run_id type}]
	set div $href
	
    }
    support {
	# add the support activity to the tree
	db_1row get_support_activity_info { *SQL* }
	
	set href [export_vars -base "activity-frame" -url {activity_item_id run_id type}]
	set div $href
	
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

	set href [export_vars -base "activity-frame" -url {activity_item_id run_id type}]
	set div $href
	
	db_multirow -extend {r_activity_id} referenced_activities struct_referenced_activities { *SQL* } {
	    set r_activity_id [content::item::get_live_revision -item_id $object_id_two]
	}
	
    }
}
