# imsld/lib/imsld-chunk.tcl

set imsld_package_id [site_node_apm_integration::get_child_package_id \
                          -package_id [dotlrn_community::get_package_id $community_id] \
                          -package_key "[imsld::package_key]"]
set imsld_url "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]"
set user_id [ad_conn user_id]

template::list::create \
    -name imsld_runs \
    -multirow imsld_runs \
    -key run_id \
    -elements {
        imsld_title {
            label "[_ imsld.IMS_LD_Name]"
            orderby_asc {imsld_title asc}
            orderby_desc {imsld_title desc}
            display_template {<a href="${imsld_url}imsld-frameset?run_id=@imsld_runs.run_id@">@imsld_runs.imsld_title@</a>}
        }
        creation_date {
            label "[_ imsld.Creation_Date]"
            orderby_asc {creation_date asc}
            orderby_desc {creation_date desc}
        }
    } \
    -orderby { default_value imsld_title }


set orderby [template::list::orderby_clause -orderby -name imsld_runs]

if {[string equal $orderby ""]} {
    set orderby " order by imsld_title asc"
}

set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

template::multirow create imsld_runs run_id imsld_title creation_date

db_foreach active_runs { *SQL* } {
        if { [llength [imsld::roles::get_user_roles -user_id $user_id -run_id $run_id]] } {
            template::multirow append imsld_runs $run_id $imsld_title $creation_date
        }
}


