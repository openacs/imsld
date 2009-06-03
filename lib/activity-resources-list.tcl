set dom_doc [dom createDocument root]

if { ![info exists monitor_p] } {
    set monitor_p 0
}

set linear_item_list [db_list item_linear_list { *SQL* }]

multirow create resources resource_item_id

foreach imsld_item_id $linear_item_list {
    foreach sa_items_list [db_list_of_lists la_nested_associated_items { *SQL* }] {
	set resource_id [lindex $sa_items_list 0]
	set resource_item_id [lindex $sa_items_list 1]
	set resource_type [lindex $sa_items_list 2]

	multirow append resources $resource_item_id

# temporal commented:	
# 	imsld::process_resource_as_ul -resource_item_id $resource_item_id \
# 	    -run_id $run_id \
# 	    -dom_doc $dom_doc \
# 	    -dom_node $list_node \
# 	    -li_mode \
# 	    -monitor=$monitor_p
	
    }
}

if { $monitor_p } {
    set li_node [$dom_doc createElement li]
    set choose_node [$dom_doc createElement a]
    $choose_node appendChild [$dom_doc createTextNode "Add"]
    $choose_node setAttribute href {\#}
    $li_node appendChild [$dom_doc createTextNode {[}]
			  $li_node appendChild $choose_node
			  $li_node appendChild [$dom_doc createTextNode {]}]
}
