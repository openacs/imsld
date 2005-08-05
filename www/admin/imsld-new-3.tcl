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

set page_title "<#_ Creating new IMS-LD... #>"
set context [list [list "<#_ New IMS-LD #>" "new-imsld"] [list "<#_ Creaginting new IMS-LD #>"]]

set user_id [ad_conn user_id]

# Display progress bar
# ad_progress_bar_begin \
#     -title "<#_ Uploading IMS LD #>" \
#     -message_1 "<#_ Uploading and processing your course, please wait... #>" \
#     -message_2 "<#_ We will continue automatically when processing is complete. #>"


# Atempting to create the new IMS LD.
# The proc imsld::parse::parse_and_create_imsld_manifest return a pair of values (manifest_id and a message)
set manifest_list [imsld::parse::parse_and_create_imsld_manifest -xmlfile $tmp_dir/imsmanifest.xml \
                    -manifest_id $manifest_id \
                    -tmp_dir $tmp_dir \
                    -community_id 2040]

set manifest_id [lindex $manifest_list 0]

if { !$manifest_id } {
    set errmsg [lindex $manifest_list 1]
    ad_return_error "<#_ Error parsing manifest. #>" "<#_ There was an error parsing the manifest. Please correct it and try again. <br /><code>$errmsg %</code> #>"
    ad_script_abort
}

# delete the tmpdir
imsld::parse::remove_dir -dir $tmp_dir    

