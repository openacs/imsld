ad_page_contract {
}

set page_title {#imsld.units-of-learning#}
set context {}

template::list::create \
    -name imslds \
    -multirow imslds \
    -key imsld_id \
    -elements {
        imsld_title {
            label "[_ imsld.IMS_LD_Name]"
            orderby_asc {imsld_title asc}
            orderby_desc {imsld_title desc}
	    display_template {<a href="imsld-frameset?imsld_id=@imslds.imsld_id@">@imslds.imsld_title@</a>}
        }
    }

set orderby [template::list::orderby_clause -orderby -name imslds]

if {[string equal $orderby ""]} {
    set orderby " order by imsld_title asc"
}

set community_id [dotlrn_community::get_community_id]
set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

db_multirow imslds get_manifests { *SQL* } {
}
