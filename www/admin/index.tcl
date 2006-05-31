ad_page_contract {

    Presents a form to upload a IMS LD ZIP file.
    
    @author jopez@inv.it.uc3m.es
    @creation-date jul 2005
} {
    {return_url "index"}
    {set_imsld_id_live ""}
    {set_run_id_live ""}
    {run_imsld_id ""}
    {run_orderby ""}
    {imsld_orderby ""}
} -properties {
    upload_file
    context:onevalue
}

set community_id [dotlrn_community::get_community_id]

# check action...
if { ![string eq "" $set_imsld_id_live] } {
    content::item::set_live_revision -revision_id [content::item::get_best_revision -item_id $set_imsld_id_live]
}
if { ![string eq "" $set_run_id_live] } {
    db_dml make_run_live { *SQL* }
}
if { ![string eq "" $run_imsld_id] } {
    imsld::instance::instantiate_imsld -imsld_id $run_imsld_id -community_id $community_id
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set page_title "[_ imsld.Admin_IMS_LD]"
set context [list "[_ imsld.Admin_IMS_LD]"]

set user_id [ad_conn user_id]
set manifest_id [db_nextval acs_object_id_seq]

# form to upload an IMS LD ZIP file

ad_form -name upload_file_form -html {enctype multipart/form-data} -cancel_url $return_url -action imsld-new -form {
    {upload_file:file {label "[_ imsld.lt_Import_IMS-LD_ZIP_Fil]"}}
    {return_url:text {widget hidden} {value $return_url}}
    {manifest_id:integer {widget hidden} {value $manifest_id}}
} 

template::list::create \
    -name imslds \
    -multirow imslds \
    -key imsld_id \
    -orderby_name imsld_orderby \
    -orderby { default_value imsld_title } \
    -elements {
        imsld_title {
            label "[_ imsld.IMS_LD_Name]"
            orderby_asc {imsld_title asc}
            orderby_desc {imsld_title desc}
        }
        creation_date {
            label "[_ imsld.Creation_Date]"
            orderby_asc {creation_date asc}
            orderby_desc {creation_date desc}
        }
        create_run {
            label {}
            display_template {@imslds.create_run;noquote@} 
        }
        delete {
            label {}
            sub_class narrow
            display_template {@imslds.delete_template;noquote@} 
            link_html { title "[_ imsld.Delete_IMS_LD]" }
        }
    }

set imsld_orderby [template::list::orderby_clause -orderby -name imslds]

set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

db_multirow -extend { delete_template create_run } imslds  get_imslds { *SQL* } {

    if { [empty_string_p $live_revision] } {
        set delete_template "<span style=\"font-style: italic; color: red; font-size: 9pt;\">[_ imsld.Deleted]</span> <a href=[export_vars -base "index" { {set_imsld_id_live $item_id} }]>[_ imsld.Make_it_live]</a>"
        set create_run ""
    } else {
        set delete_template "<a href=\"[export_vars -base "imsld-delete" { imsld_id return_url }]\"><img src=\"/resources/acs-subsite/Delete16.gif\" width=\"16\" height=\"16\" border=\"0\"></a>"
        set create_run "<a href=\"[export_vars -base "index" { {run_imsld_id $imsld_id} return_url }]\"> [_ imsld.create_new_run] </a>"
    }
}

set imsld_package_id [site_node_apm_integration::get_child_package_id \
                          -package_id [dotlrn_community::get_package_id $community_id] \
                          -package_key "[imsld::package_key]"]
set imsld_url "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]"

template::list::create \
    -name imsld_runs \
    -multirow imsld_runs \
    -key run_id \
    -elements {
        imsld_title {
            label "[_ imsld.Run_IMS-LD_Name]"
            orderby_asc {imsld_title asc}
            orderby_desc {imsld_title desc}
            display_template {@imsld_runs.imsld_title@}
        }
        status {
            label "[_ imsld.Status]"
            orderby_asc {status asc}
            orderby_desc {status desc}
        }
        creation_date {
            label "[_ imsld.Creation_Date]"
            orderby_asc {creation_date asc}
            orderby_desc {creation_date desc}
        }
        manage {
            label ""
            display_template {@imsld_runs.manage;noquote@}
        }
        delete {
            label {}
            sub_class narrow
            display_template {@imsld_runs.delete_template;noquote@} 
            link_html { title "[_ imsld.Delete_Run]" }
        }
    } \
    -orderby_name run_orderby \
    -orderby { default_value creation_date desc }


set run_orderby [template::list::orderby_clause -orderby -name imsld_runs]

set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

db_multirow -extend { manage delete_template } imsld_runs get_runs { *SQL* } {
    
    if { [string eq $status "deleted"] || [string eq $status active]} {
        set delete_template "<span style=\"font-style: italic; color: red; font-size: 9pt;\">[_ imsld.Deleted]</span> <a href=[export_vars -base "index" { {set_run_id_live $run_id} }]>[_ imsld.Make_it_live]</a>"
        set manage ""
    } else {
        set delete_template "<a href=\"[export_vars -base "run-delete" { run_id return_url }]\"><img src=\"/resources/acs-subsite/Delete16.gif\" width=\"16\" height=\"16\" border=\"0\"></a>"
        set create_run "<a href=\"[export_vars -base "index" { {run_imsld_id $imsld_id} return_url }]\"> [_ imsld.create_new_run] </a>"
        set manage "<a href=\"[export_vars -base "imsld-admin-roles" { run_id }]\">[_ imsld.Manage_Members]</a>" 
    }
}
