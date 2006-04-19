# imsld/lib/imsld-chunk.tcl

set imsld_package_id [site_node_apm_integration::get_child_package_id \
                          -package_id [dotlrn_community::get_package_id $community_id] \
                          -package_key "[imsld::package_key]"]
set imsld_url "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]"

template::list::create \
    -name imslds \
    -multirow imslds \
    -key imsld_id \
    -elements {
        imsld_title {
            label "[_ imsld.IMS_LD_Name]"
            orderby_asc {imsld_title asc}
            orderby_desc {imsld_title desc}
            display_template {<a href="${imsld_url}imsld-frameset?imsld_id=@imslds.imsld_id@">@imslds.imsld_title@</a>}
        }
        creation_date {
            label "Creation Date"
            orderby_asc {creation_date asc}
            orderby_desc {creation_date desc}
        }
    } \
    -orderby { default_value imsld_title }


set orderby [template::list::orderby_clause -orderby -name imslds]

if {[string equal $orderby ""]} {
    set orderby " order by imsld_title asc"
}

set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

db_multirow imslds get_manifests "
        select imsld.imsld_id,
        coalesce(imsld.title, imsld.identifier) as imsld_title,
	    to_char(imsld.creation_date,'MM/DD/YYYY HH24:MI') as creation_date
        from cr_items cr1, cr_items cr2, cr_items cr3, cr_items cr4,
        imsld_cp_manifests icm, imsld_cp_organizations ico, imsld_imsldsi imsld 
        where cr1.live_revision = icm.manifest_id
        and cr1.parent_id = cr4.item_id
        and cr4.parent_id = :cr_root_folder_id
        and ico.manifest_id = cr1.item_id
        and imsld.organization_id = cr2.item_id
        and cr2.live_revision = ico.organization_id
        and cr3.live_revision = imsld.imsld_id
        $orderby
    " {}

