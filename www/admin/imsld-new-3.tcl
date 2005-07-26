# /packages/imsld/www/admin/imsld-new-3.tcl

ad_page_contract {

    Parse and create the imsld in the database.
    
    @author jopez@inv.it.uc3m.es
    @creation-date jul 2005
} {
    tmp_dir
    imsld_id:integer,notnull
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
ad_progress_bar_begin \
    -title "<#_ Uploading IMS LD #>" \
    -message_1 "<#_ Uploading and processing your course, please wait... #>" \
    -message_2 "<#_ We will continue automatically when processing is complete. #>"


# Atempting to create the new IMS LD.
# The proc imsld::parse::parse_and_create_imsldl return a pair of values (success_p and a message)
set create_ismld_atempt_list [imsld::parse::parse_and_create_imsld -xmlfile $tmp_dir/imsmanifest.xml -imsld_id $imsld_id]

set success_p [lindex $create_ismld_atempt_list 0]
set message [lindex $create_ismld_atempt_list 1]

if { $success_p } {
    # Hats off!
} else {
    # Error
}