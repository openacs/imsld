if {![info exists user_id]} {
    set user_id [ad_conn user_id]
}

if {![info exists monitor_p]} {
    set monitor_p 0
}

if {![info exists community_id]} {
    set community_id [dotlrn_community::get_community_id]
}

set imsld_package_id [site_node_apm_integration::get_child_package_id \
			  -package_id [dotlrn_community::get_package_id $community_id] \
			  -package_key "[imsld::package_key]"]

# Get file-storage root folder_id
set fs_package_id [site_node_apm_integration::get_child_package_id \
		       -package_id [dotlrn_community::get_package_id $community_id] \
		       -package_key "file-storage"]

set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
db_1row get_resource_info { *SQL* }

if { ![string eq $resource_type "webcontent"] && ![string eq $acs_object_id ""] } {

    # if the resource type is not webcontent or has an associated object_id (special cases)...
    if { [db_0or1row is_cr_item { *SQL* }] } {
	db_1row get_cr_info { *SQL* } 
    } else {
	db_1row get_ao_info { *SQL* } 
    }

    set file_url [acs_sc::invoke -contract FtsContentProvider -operation url -impl $object_type -call_args [list $acs_object_id]]

    set href [export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]
    set img_src [imsld::object_type_image_path -object_type $object_type]

} elseif { [string eq $resource_type "imsldcontent"] } {

    db_1row get_imsld {
	select i.imsld_id, i.resource_handler
	from imsld_runs r, imsld_imslds i
	where r.run_id = :run_id
	and r.imsld_id = i.imsld_id
    }
    
    set associated_files_query "associated_files"
    if { $resource_handler eq "xowiki" } {
	set associated_files_query "associated_xo_files"
    }

    multirow create files href file_name

    set img_src "[imsld::object_type_image_path -object_type file-storage]"
    foreach file_list [db_list_of_lists $associated_files_query { *SQL* }] {
	if { $resource_handler eq "xowiki" } {
	    set page_id [lindex $file_list 0]
	    set file_name [lindex $file_list 1]
	    set fs_file_url [export_vars -base [imsld::xowiki::page_url -item_id $page_id] {{template_file "/packages/imsld/lib/wiki-default"}}]
	} else {
	    set imsld_file_id [lindex $file_list 0]
	    set file_name [lindex $file_list 1]
	    set item_id [lindex $file_list 2]
	    set parent_id [lindex $file_list 3]
	    # get the fs file path
	    set folder_path [db_exec_plsql get_folder_path { *SQL* }]
	    db_0or1row get_fs_file_url { *SQL* }
	    set fs_file_url $file_url
	}

	set file_url "imsld-content-serve"
	set href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]"

	multirow append files $href $file_name

    }

} else {
    # is webcontent, let's get the associated files

    db_1row get_imsld {
	select i.imsld_id, i.resource_handler
	from imsld_runs r, imsld_imslds i
	where r.run_id = :run_id
	and r.imsld_id = i.imsld_id
    }
    
    set associated_files_query "associated_files"
    if { $resource_handler eq "xowiki" } {
	set associated_files_query "associated_xo_files"
    }

    multirow create files href title img_src
    
    foreach file_list [db_list_of_lists $associated_files_query { *SQL* }] {
	if { $resource_handler eq "xowiki" } {
	    set page_id [lindex $file_list 0]
	    set file_name [lindex $file_list 1]
	    set file_url [export_vars -base [imsld::xowiki::page_url -item_id $page_id] {{template_file "/packages/imsld/lib/wiki-default"}}]
	} else {
	    set imsld_file_id [lindex $file_list 0]
	    set file_name [lindex $file_list 1]
	    set item_id [lindex $file_list 2]
	    set parent_id [lindex $file_list 3]
	    # get the fs file path
	    set folder_path [db_exec_plsql get_folder_path { *SQL* }]
	    set fs_file_url [db_1row get_fs_file_url { *SQL* }]
	    set file_url "[apm_package_url_from_id $fs_package_id]view/${file_url}"
	}
	set href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]"
	set img_src "[imsld::object_type_image_path -object_type file-storage]"

	multirow append files $href $file_name $img_src

    }
    # get associated urls
    
    db_foreach associated_urls { *SQL* } {
	set href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" { {file_url "[export_vars -base $url]"} resource_item_id run_id}]"
	set img_src "[imsld::object_type_image_path -object_type url]"
	
	multirow append files $href $url $img_src	
    }
}
