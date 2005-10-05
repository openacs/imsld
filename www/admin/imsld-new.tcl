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

set page_title "[_ imsld.New_IMS-LD]"
set context [list "[_ imsld.New_IMS-LD]"]

set user_id [ad_conn user_id]
set manifest_id [db_nextval acs_object_id_seq]

# form to upload an IMS LD ZIP file

ad_form -name upload_file_form -html {enctype multipart/form-data} -cancel_url $return_url -action imsld-new-2 -form {
    {upload_file:file {label "[_ imsld.IMS-LD_ZIP_File]"}}
    {return_url:text {widget hidden} {value $return_url}}
    {manifest_id:integer {widget hidden} {value $manifest_id}}
} 


