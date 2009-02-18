
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

if { ![info exists item_id] } {
    set item_id [content::revision::item_id -revision_id $revision_id]
}

set url_up [export_vars -base change-activity-order {item_id run_id sort_order {dir -1}}]

set bound_down [expr {$number_elements - 1}]
set url_down [export_vars -base change-activity-order {item_id run_id sort_order {dir 1}}]

set url_del [export_vars -base activity-del {{activity_id $revision_id} run_id}]
