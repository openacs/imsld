ad_page_contract {

    Presents a form to upload a IMS LD ZIP file.
    
    @author jopez@inv.it.uc3m.es
    @creation-date jul 2005
} {
    {return_url "index"}
} -properties {
    upload_file
    context:onevalue
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set page_title "<#_ New IMS-LD #>"
set context [list "<#_ New IMS-LD #>"]

set user_id [ad_conn user_id]

# form to upload an IMS LD ZIP file

ad_form -name upload_file_form -html {enctype multipart/form-data} -cancel_url $return_url -action imsld-new-2 -form {
    imsld_id:key
    {upload_file:file {label "<#_ IMS-LD ZIP File #>"}}
    {return_url:text {widget hidden} {value $return_url}}
} 


