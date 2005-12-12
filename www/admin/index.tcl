ad_page_contract {

    Presents a form to upload a IMS LD ZIP file.
    
    @author jopez@inv.it.uc3m.es
    @creation-date jul 2005
} {
    {return_url "index"}
    {set_imsld_id_live ""}
} -properties {
    upload_file
    context:onevalue
}

if { ![string eq "" $set_imsld_id_live] } {
    content::item::set_live_revision -revision_id [content::item::get_best_revision -item_id $set_imsld_id_live]
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set page_title "Admin IMS LD"
set context [list "Admin IMS LD"]

set user_id [ad_conn user_id]
set manifest_id [db_nextval acs_object_id_seq]

# form to upload an IMS LD ZIP file

ad_form -name upload_file_form -html {enctype multipart/form-data} -cancel_url $return_url -action imsld-new -form {
    {upload_file:file {label "Import IMS-LD ZIP File"}}
    {return_url:text {widget hidden} {value $return_url}}
    {manifest_id:integer {widget hidden} {value $manifest_id}}
} 


template::list::create \
    -name imslds \
    -multirow imslds \
    -key imsld_id \
    -elements {
        imsld_title {
            label "IMS LD Name"
            orderby_asc {imsld_title asc}
            orderby_desc {imsld_title desc}
        }
        delete {
            label {}
            sub_class narrow
            display_template {@imslds.delete_template;noquote@} 
            link_html { title "Delete IMS LD" }
        }
    }

set orderby [template::list::orderby_clause -orderby -name imslds]

if {[string equal $orderby ""]} {
    set orderby " order by imsld_title asc"
}

set community_id [dotlrn_community::get_community_id]
set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

db_multirow  -extend { delete_template } imslds  get_imslds {
    select imsld.imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title,
    cr3.item_id,
    cr3.live_revision
    from cr_items cr1, cr_items cr2, cr_items cr3, cr_items cr4,
    imsld_cp_manifests icm, imsld_cp_organizations ico, imsld_imsldsi imsld 
    where cr1.live_revision = icm.manifest_id
    and cr1.parent_id = cr4.item_id
    and cr4.parent_id = :cr_root_folder_id
    and ico.manifest_id = cr1.item_id
    and imsld.organization_id = cr2.item_id
    and cr2.live_revision = ico.organization_id
    and cr3.item_id = imsld.item_id
} {
    if { [empty_string_p $live_revision] } {
        set delete_template "<span style=\"font-style: italic; color: red; font-size: 9pt;\">Deleted</span> <a href=[export_vars -base "index" { {set_imsld_id_live $item_id} }]>Make it live</a>"
    } else {
        set delete_template "<a href=\"[export_vars -base "imsld-delete" { imsld_id return_url }]\"><img src=\"/resources/acs-subsite/Delete16.gif\" width=\"16\" height=\"16\" border=\"0\"></a>"
    }
}
