ad_page_contract {
    Export Uol
    
    @author cvalencia@inv.it.uc3m.es
    @creation-date Feb 2008
} {
    imsld_id:integer
} 

#Get package_id to check if user has admin privileges
set package_id [ad_conn package_id]
permission::require_permission \
  -object_id $package_id \
  -privilege admin

#Delete files from tmp directory
exec rm -fr "[acs_package_root_dir imsld]/www/tmp/*"

#Get UoL name
db_1row get_imsld_identifier {select title from cr_revisions where revision_id = :imsld_id}
set aux_export_url "&uol_name=$title&include_all=Yes"
if {$title == ""} {
  set title "Unknown name"
}

#Set page messages
set heading "[_ imsld.export_heading]: $title"
set intro "[_ imsld.export_intro] "
set export_url "./imsld-export-2.tcl?imsld_id=$imsld_id"
set anchor_msg "export"

db_1row get_file_type {select resource_handler from imsld_imslds where imsld_id = :imsld_id}
if {$resource_handler == "xowiki"} {
  ad_returnredirect "./imsld-export-xo.tcl?imsld_id=$imsld_id"
} else { set get_files get_fs_files }

template::list::create \
  -name resource_files \
  -multirow $get_files \
  -elements {
    path_to_file {
      label "[_ imsld.export_files]"
    }
    warning {
      label "[_ imsld.export_warnings]"
    }
}

set this_imsld $imsld_id
#Choose query for db_multirow
if {[db_0or1row get_next_imsld {select organization_id from imsld_imslds where imsld_id > :this_imsld limit 1}] == 1} {
  set next_imsld $organization_id
  set get_files get_files_1
} else {
  set get_files get_files_2
}



set number_of_files 0
db_multirow -local \
  -extend {warning item_id name} \
  get_fs_files $get_files {} {
  if {[db_0or1row get_file_resource {select object_id_one from acs_rels, cr_items where latest_revision = :imsld_file_id and item_id = object_id_two and rel_type = 'imsld_res_files_rel' limit 1}] == 1} {
    set warning "OK"
  } else {set warning "[_ imsld.export_warning_msg1]"}
}


#Where are the resources of this UoL stored?
#First, we need the manifest_id
db_1row get_manifest {select manifest_id from imsld_cp_organizations, cr_items cr1 where organization_id = cr1.latest_revision and cr1.item_id = imsld_imslds.organization_id and imsld_imslds.imsld_id = :imsld_id}


#Create Export button
ad_form -name export_button \
  -form {
     {imsld_id:integer(hidden)}
     {name:text {label "[_ imsld.export_uol_name]"} {html {size 30}}}
     {include_all:text(radio) {label "[_ imsld.export_resources_question]"} {options {{"[_ imsld.export_yes]" "Yes"} {"[_ imsld.export_no]" "No"}}}}
  } \
  -on_request {
    set name $title
    set include_all "Yes"
  } \
  -on_submit {
    ad_returnredirect "${export_url}&uol_name=${name}&include_all=${include_all}&manifest_id=${manifest_id}"
    ad_script_abort
}
