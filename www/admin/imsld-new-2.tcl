# /packages/imsld/www/admin/imsld-new-3.tcl

ad_page_contract {

    Parse and create the imsld in the database.
    
    @author jopez@inv.it.uc3m.es
    @creation-date jul 2005
} {
    tmp_dir
    manifest_id:integer,notnull
    return_url
} -properties {
    context:onevalue
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set page_title "[_ imsld.Creating_new_IMS-LD]"
set context [list [list "[_ imsld.New_IMS-LD]" "new-imsld"] [list "[_ imsld.lt_Creaginting_new_IMS-L]"]]

set user_id [ad_conn user_id]

# Display progress bar
ad_progress_bar_begin \
    -title "[_ imsld.Uploading_IMS_LD]" \
    -message_1 "[_ imsld.lt_Uploading_and_process]" \
    -message_2 "[_ imsld.lt_We_will_continue_auto]"

ns_write "[_ imsld.lt_h2Uploading_new_IMS_L] <blockquote>"

set community_id [dotlrn_community::get_community_id]
# Atempting to create the new IMS LD.
# The proc imsld::parse::parse_and_create_imsld_manifest return a pair of values (manifest_id and a message)
set manifest_list [imsld::parse::parse_and_create_imsld_manifest -xmlfile $tmp_dir/imsmanifest.xml \
                       -manifest_id $manifest_id \
                       -tmp_dir $tmp_dir \
                       -community_id $community_id]

set manifest_id [lindex $manifest_list 0]

if { !$manifest_id } {
    set errmsg [lindex $manifest_list 1]
    ad_return_error "[_ imsld.lt_Error_parsing_manifes]" "[_ imsld.lt_There_was_an_error_pa]"
    ad_script_abort
}

# delete the tmpdir
imsld::parse::remove_dir -dir $tmp_dir    

set warnings "[lindex $manifest_list 1]"

if { ![string eq "" $warnings] } {
    ns_write "[_ imsld.lt_br__Warnings_ul_warni]"
    ns_sleep 5
}

ns_write "</blockquote>"

#get imslds ang jump to admin members page
set imsld_id [db_list get_imslds_from_manifest {}]
ad_progress_bar_end -url [export_vars -base imsld-admin-roles {imsld_id}]


