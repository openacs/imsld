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
    # if there are no users assigned to the run, we mark it as waiting, otherwise mark it active
    if { ![llength [imsld::runtime::users_in_run -run_id $set_run_id_live]] } {
	db_dml make_run_waiting { *SQL* }
    } else {
	db_dml make_run_live { *SQL* }
    }
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set page_title "[_ imsld.Admin_IMS_LD]"
set context [list "[_ imsld.Admin_IMS_LD]"]

set user_id [ad_conn user_id]
set manifest_id [db_nextval acs_object_id_seq]

# form to upload an IMS LD ZIP file

ad_form -name upload_file_form -html {enctype multipart/form-data} -action imsld-new -form {
    {upload_file:file {label "[_ imsld.lt_Import_IMS-LD_ZIP_Fil]"}}
    {return_url:text {widget hidden} {value $return_url}}
    {manifest_id:integer {widget hidden} {value $manifest_id}}
} 

template::list::create \
    -name imslds \
    -multirow imslds \
    -key imsld_id \
    -pass_properties { return_url } \
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
            display_template {<if @imslds.live_revision@ not nil>
		<a href="run-new?run_imsld_id=@imslds.imsld_id@&amp;return_url=@return_url@" title="[_ imsld.create_new_run]"> [_ imsld.create_new_run] </a>
		</if>} 
        }
        export {
            label {}
            sub_class narrow
            display_template {
              <a href="imsld-export?imsld_id=@imslds.imsld_id@"><img src="/resources/imsld/export.png" title="Export" alt="Export" ></a>
            }
        }
        delete {
            label {}
            sub_class narrow
            display_template {<if @imslds.live_revision@ nil>
		<span class="alert" style="display:inline;">[_ imsld.Deleted]</span> <a href="index?set_imsld_id_live=@imslds.item_id@" title="[_ imsld.Make_it_live]">[_ imsld.Make_it_live]</a>
		</if>
		<else>
		<a href="imsld-delete?imsld_id=@imslds.imsld_id@&amp;return_url=@return_url@" title="[_ imsld.Delete]"><img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" alt="[_ imsld.Delete]" title="[_ imsld.Delete]"></a>
		</else>} 
            link_html { title "[_ imsld.Delete_IMS_LD]" }
        }
    }

set imsld_orderby [template::list::orderby_clause -orderby -name imslds]

set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

db_multirow -extend { delete_template create_run } imslds  get_imslds { *SQL* } {}

set imsld_package_id [site_node_apm_integration::get_child_package_id \
                          -package_id [dotlrn_community::get_package_id $community_id] \
                          -package_key "[imsld::package_key]"]
set imsld_url "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]"

template::list::create \
    -name imsld_runs \
    -multirow imsld_runs \
    -pass_properties { return_url } \
    -key run_id \
    -elements {
        imsld_title {
            label "[_ imsld.Run_IMS-LD_Name]"
            orderby_asc {imsld_title asc}
            orderby_desc {imsld_title desc}
	    link_url_eval {[export_vars -base "../imsld-divset" {run_id}]}
        }
        status {
            label "[_ imsld.Status]"
            orderby_asc {status asc}
            orderby_desc {status desc}
            display_template {<if @imsld_runs.status@ ne "deleted">
		<img src="@imsld_runs.image_path;noquote@" alt="@imsld_runs.image_alt@" title="@imsld_runs.image_title@">
	    </if>}
        }
        creation_date {
            label "[_ imsld.Creation_Date]"
            orderby_asc {creation_date asc}
            orderby_desc {creation_date desc}
        }
        manage {
            label {}
            display_template {<if @imsld_runs.status@ eq "active" or @imsld_runs.status@ eq "stopped">
		<a href="imsld-view-roles?run_id=@imsld_runs.run_id@" title="[_ imsld.View_members]">[_ imsld.View_members]</a> | <a href="monitor?run_id=@imsld_runs.run_id@" title="[_ imsld.Cockpit]">[_ imsld.Cockpit]</a>
		</if>
		<else>
		 <if @imsld_runs.status@ eq "waiting">
		  <a href="imsld-admin-roles?run_id=@imsld_runs.run_id@" title="[_ imsld.Manage_Members]">[_ imsld.Manage_Members]</a>
 		 </if>
		 <if @imsld_runs.status@ eq "waitingservices">
		  <a href="gsi/imsld-gsi-serviceslist?run_id=@imsld_runs.run_id@" title="Configure Services">Configure Services</a>
 		 </if>
		</else>}
        }
        delete {
            label {}
            sub_class narrow
            display_template {<if @imsld_runs.status@ eq "deleted">
		<span class="alert" style="display:inline;">[_ imsld.Deleted]</span> <a href="index?set_run_id_live=@imsld_runs.run_id@" title="[_ imsld.Make_it_live]">[_ imsld.Make_it_live]</a>
		</if>
		<else>
		<a href="run-delete?run_id=@imsld_runs.run_id@&amp;return_url=@return_url@" title="[_ imsld.Delete]"><img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" alt="[_ imsld.Delete]" title="[_ imsld.Delete]"></a>
		</else>}
            link_html { title "[_ imsld.Delete_Run]" }
        }
    } \
    -orderby_name run_orderby \
    -orderby { default_value creation_date desc }


set run_orderby [template::list::orderby_clause -orderby -name imsld_runs]

set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]

db_multirow -extend { manage delete_template image_path image_alt image_title } imsld_runs get_runs { *SQL* } {
    switch $status {
        active {
            set image_alt "[_ imsld.active]"
            set image_title "[_ imsld.active]"
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/active.png"
        }
        waitingservices -
        waiting {
            set image_alt "[_ imsld.waiting]"
            set image_title "[_ imsld.waiting]"
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/waiting.png"
        }
        stopped {
            set image_alt "[_ imsld.stopped]"
            set image_title "[_ imsld.stopped]"
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/completed.png"
        }
    }    
}

