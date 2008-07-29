# imsld/lib/imsld-chunk.tcl

set user_id [ad_conn user_id]

set elements [list imsld_title \
                  [list label "[_ imsld.IMS_LD_Name]" \
                       orderby_asc {imsld_title asc} \
                       orderby_desc {imsld_title desc} \
                       display_template {<a href="@imsld_runs.imsld_url;noquote@imsld-frameset?run_id=@imsld_runs.run_id@" title="[_ imsld.Go_to_UoL_page]">@imsld_runs.imsld_title@</a>}] \
                  user_roles \
                  [list label "[_ imsld.Roles_in_Run]" \
                       display_template {@imsld_runs.user_roles;noquote@}] \
                  status \
                  [list label "[_ imsld.Status]" \
                       orderby_asc {status asc} \
                       orderby_desc {status desc} \
                       display_template {<img src="@imsld_runs.image_path;noquote@" alt="@imsld_runs.image_alt@" title="@imsld_runs.image_title@">}] \
                  creation_date \
                  [list label "[_ imsld.Creation_Date]" \
                       orderby_asc {creation_date asc} \
                       orderby_desc {creation_date desc}]]

if { [llength $$list_of_package_ids] > 1 } {
    lappend elements community_name \
	    [list label "[_ imsld.Community]"]
}
                   
template::list::create \
    -name imsld_runs \
    -multirow imsld_runs \
    -key run_id \
    -elements $elements \
    -orderby { default_value imsld_title }


set orderby [template::list::orderby_clause -orderby -name imsld_runs]

if {[string equal $orderby ""]} {
    set orderby " order by imsld_title asc"
}

template::multirow create imsld_runs run_id imsld_title creation_date image_alt image_title image_path imsld_url community_name user_roles
 
foreach package_id $list_of_package_ids {
    
    set community_id [dotlrn_community::get_community_id_from_url -url [site_node::get_url -node_id [site_node::get_node_id_from_object_id -object_id $package_id]]]
    set community_name [dotlrn_community::get_community_name $community_id]

    set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]
    
    set imsld_package_id [site_node_apm_integration::get_child_package_id \
                              -package_id [dotlrn_community::get_package_id $community_id] \
                              -package_key "[imsld::package_key]"]
    set imsld_url "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]"

    db_foreach active_runs { *SQL* } {
        set user_roles_ids_list [imsld::roles::get_user_roles -user_id $user_id -run_id $run_id]
        if { [llength $user_roles_ids_list] } {
            switch $status {
                waiting {
                    set image_alt "[_ imsld.waiting]"
                    set image_title "[_ imsld.waiting]"
                    set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/waiting.png"
                }
                active {
                    set image_alt "[_ imsld.active]"
                    set image_title "[_ imsld.active]"
                    set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/active.png"
                }
                stopped {
                    set image_alt "[_ imsld.stopped]"
                    set image_title "[_ imsld.stopped]"
                    set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/completed.png"
                }
            }
            set role_names [imsld::roles::get_roles_names -roles_list $user_roles_ids_list]
            # remove &nbsp; added in the previous proc
            regsub -all "&nbsp;" $role_names "" $role_names
            template::multirow append imsld_runs $run_id $imsld_title $creation_date $image_alt $image_title $image_path $imsld_url $community_name [join $role_names "<br>"]
        }
    }
}


