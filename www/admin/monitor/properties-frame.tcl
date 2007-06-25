# packages/imsld/www/admin/monitor/properties-frame.tcl

ad_page_contract {

    Displays the properties an their values (in edit mode)

    @author jopez@inv.it.uc3m.es
    @creation-date Apr 2007
} -query {
    {run_id:integer ""}
    {role_id ""}
    {role_instance_id:integer ""}
    {user_id:integer ""}
    type:notnull
} -validate {
    valid_type {
        if { ![string eq "loc" $type] && ![string eq "locpers" $type] && ![string eq "globpers" $type] && ![string eq "locrole" $type] && ![string eq "glob" $type] } {
            ad_complain "[_ imsld.lt_Invalid_property_type]"
        }
    }
}

# Get file-storage root folder_id
set fs_package_id [site_node_apm_integration::get_child_package_id \
		       -package_id [dotlrn_community::get_package_id [dotlrn_community::get_community_id]] \
		       -package_key "file-storage"]
set root_folder_id [fs::get_root_folder -package_id $fs_package_id]

dom createDocument html dom_doc
set dom_root [$dom_doc documentElement]
set head_node [$dom_doc createElement head]
set link_node [$dom_doc createElement link]
$link_node setAttribute rel "stylesheet"
$link_node setAttribute type "text/css"
$link_node setAttribute href "/resources/acs-templating/lists.css"
$link_node setAttribute media "all"
$head_node appendChild $link_node

set script_node [$dom_doc createElement script]
$script_node appendChild [$dom_doc createTextNode {
    function confirmValue(myform){ 
        myform.submit() 
    } 
}]

$head_node appendChild $script_node
$dom_root appendChild $head_node

set body_node [$dom_doc createElement body]

# prepare final output... a little bit tedious to get it "pretty"
# using the default css of openacs

# if the property type is of type locpers or globpers
# we first need to specify which user will be monitorized

if { [string eq $type "locpers"] || [string eq $type "globpers"] } {
    set form_node [$dom_doc createElement form]
    $form_node setAttribute name "choose"
    $form_node setAttribute action ""
    set select_node [$dom_doc createElement select]
    $select_node setAttribute name "user_id"
    $select_node setAttribute id "users_in_run"
    $select_node setAttribute onChange "confirmValue(this.form)"

    if { [string eq "" $user_id] } {
	set option_node [$dom_doc createElement option]
	$option_node setAttribute value "select"
	set text [$dom_doc createTextNode "[_ imsld.Select]"]
	$option_node appendChild $text
	$select_node appendChild $option_node
    }

    foreach user_id_in_run [imsld::runtime::users_in_run -run_id $run_id] {
	set option_node [$dom_doc createElement option]
	$option_node setAttribute value $user_id_in_run
	set text [$dom_doc createTextNode "[person::name -person_id $user_id_in_run]"]
	$option_node appendChild $text

	if { $user_id == $user_id_in_run} {
	    $option_node setAttribute selected "selected"
	}
	$select_node appendChild $option_node
    }
    $form_node appendChild $select_node

    # adding hidden variables
    set type_node [$dom_doc createElement "input"]
    $type_node setAttribute name "type"
    $type_node setAttribute type "hidden"
    $type_node setAttribute value "$type"
    $form_node appendChild $type_node

    set run_id_node [$dom_doc createElement "input"]
    $run_id_node setAttribute name "run_id"
    $run_id_node setAttribute type "hidden"
    $run_id_node setAttribute value "$run_id"
    $form_node appendChild $run_id_node

    # adding the submit button
    set submit_node [$dom_doc createElement "input"]
    $submit_node setAttribute type "submit"
    $submit_node setAttribute value "ok"
    $submit_node setAttribute name "ok"
    $form_node appendChild $submit_node

    # done... add the form to the document
    $body_node appendChild $form_node

} elseif { [string eq $type "locrole"] } {

    # first, the role instance must be selected

    set form_node [$dom_doc createElement form]
    $form_node setAttribute name "choose"
    $form_node setAttribute action ""
    set select_node [$dom_doc createElement select]
    $select_node setAttribute name "role_instance_id"
    $select_node setAttribute id "roles_in_run"
    $select_node setAttribute onChange "confirmValue(this.form)"

    if { [string eq "" $role_instance_id] } {
	set option_node [$dom_doc createElement option]
	$option_node setAttribute value "select"
	set text [$dom_doc createTextNode "[_ imsld.Select_role]"]
	$option_node appendChild $text
	$select_node appendChild $option_node
    }

    foreach role_instance_id_in_role [imsld::roles::get_role_instances -role_id $role_id -run_id $run_id] {
	set option_node [$dom_doc createElement option]
	$option_node setAttribute value $role_instance_id_in_role
	set text [$dom_doc createTextNode "[db_string role_instance_name { select acs_group__name(:role_instance_id_in_role) }]"]
	$option_node appendChild $text
	
	if { $role_instance_id == $role_instance_id_in_role } {
	    $option_node setAttribute selected "selected"
	}
	$select_node appendChild $option_node
    }
    $form_node appendChild $select_node

    #adding hidden variables
    set type_node [$dom_doc createElement "input"]
    $type_node setAttribute name "type"
    $type_node setAttribute type "hidden"
    $type_node setAttribute value "$type"
    $form_node appendChild $type_node

    set run_id_node [$dom_doc createElement "input"]
    $run_id_node setAttribute name "run_id"
    $run_id_node setAttribute type "hidden"
    $run_id_node setAttribute value "$run_id"
    $form_node appendChild $run_id_node

    set role_id_node [$dom_doc createElement "input"]
    $role_id_node setAttribute name "role_id"
    $role_id_node setAttribute type "hidden"
    $role_id_node setAttribute value "$role_id"
    $form_node appendChild $role_id_node

    # adding the submit button
    set submit_node [$dom_doc createElement "input"]
    $submit_node setAttribute type "submit"
    $submit_node setAttribute value "ok"
    $submit_node setAttribute name "ok"
    $form_node appendChild $submit_node

    # done... add the form to the document
    $body_node appendChild $form_node
    
}

set table_node [$dom_doc createElement table]
$table_node setAttribute class list
$table_node setAttribute cellpadding 3
$table_node setAttribute cellspacing 1

set tr_node [$dom_doc createElement tr]
$tr_node setAttribute class list-header

set th_node [$dom_doc createElement th]
$th_node setAttribute class list
set text [$dom_doc createTextNode "[_ imsld.Property_Name]"]
$th_node appendChild $text
$tr_node appendChild $th_node

set th_node [$dom_doc createElement th]
$th_node setAttribute class list
set text [$dom_doc createTextNode "[_ imsld.Property_Value]"]
$th_node appendChild $text
$tr_node appendChild $th_node

$table_node appendChild $tr_node

switch $type {
    loc {
	set where_clause [db_map loc_clause]
    }
    locpers {
	set where_clause [db_map locpers_clause]
    }
    locrole {
	set where_clause [db_map locrole_clause]
    }
    globpers {
	set where_clause [db_map globpers_clause]
    }
    glob {
	set where_clause [db_map glob_clause]
    }
}

set counter 0
db_foreach property "
    select ins.property_id,
    prop.datatype,
    prop.item_id as property_item_id,
    coalesce(ins.value, prop.initial_value) as value,
    ins.title,
    ins.instance_id
    from imsld_property_instancesx ins,
    cr_revisions cr,
    imsld_propertiesi prop
    where ins.property_id = prop.property_id
    and $where_clause
    and cr.revision_id = ins.instance_id
    and content_revision__is_live(ins.instance_id) = 't'
" {
    # if the property is of type file, we must provide a file-upload field
    set input_text_node ""
    set select_node ""
    set input_file_node ""
    switch $datatype {
	file {
	    set input_file_node [$dom_doc createElement "input"]
	    $input_file_node setAttribute type "file"
	    $input_file_node setAttribute name "instances_ids.$instance_id"
	}
	default {	    
	    # get the restrictions and translate them to HTML
	    # currently, in HTML we can only deal with the restriction types: length, 
	    # maxlength, enumeration and totaldigits. 
	    # the rest are checked after submission
	    set restriction_nodes [list]
	    db_foreach restriction {
		select restriction_type,
		value as restriction_value
		from imsld_restrictions
		where property_id = :property_item_id
		and (restriction_type='length' or  restriction_type='maxlength' or restriction_type='totaldigits' or restriction_type='enumeration')
	    } {
		switch $restriction_type {
		    length -
		    maxlength -
		    totaldigits {
			if { [string eq "" $input_text_node] } {
			    set input_text_node [$dom_doc createElement "input"]
			    $input_text_node setAttribute type "text"
			    $input_text_node setAttribute name "instances_ids.$instance_id"
			}
			$input_text_node setAttribute maxlength $restriction_value
			$input_text_node setAttribute value "$value"
		    }
		    enumeration {
			if { [string eq "" $select_node] } {
			    set select_node [$dom_doc createElement "select"]
			    $select_node setAttribute name "instances_ids.$instance_id"
			}
			set option_node [$dom_doc createElement "option"]
			$option_node setAttribute value "$restriction_value"
			if { [string eq $value $restriction_value] } {
			    $option_node setAttribute selected "selected"
			}
			$option_node appendChild [$dom_doc createTextNode "$restriction_value"]
			$select_node appendChild $option_node
		    }
		}
	    } if_no_rows {
		# no restrictions
		set input_text_node [$dom_doc createElement "input"]
		$input_text_node setAttribute type "text"
		$input_text_node setAttribute name "instances_ids.$instance_id"
		$input_text_node setAttribute value "$value"
	    }
	}
    }

    set tr_node [$dom_doc createElement tr]
    expr { [string eq 0 [expr { $counter % 2} ]] ? [set class list-even] : [set class list-odd] }
    incr counter
    $tr_node setAttribute class $class

    set td_node [$dom_doc createElement td]
    $td_node setAttribute class list
    $td_node appendChild [$dom_doc createTextNode "$title"]
    
    $tr_node appendChild $td_node 

    # Prepare replacement
    set form_node [$dom_doc createElement "form"]
    $form_node setAttribute name "set-properties"
    $form_node setAttribute enctype "multipart/form-data"
    set url_prefix [ns_conn url]
    regexp (.*)/ $url_prefix url_prefix
    $form_node setAttribute action "${url_prefix}../../properties-value-set"
    $form_node setAttribute method "post"

    if { ![string eq "" $select_node] } {
	$form_node appendChild $select_node
    } elseif { ![string eq "" $input_text_node] } {
	$form_node appendChild $input_text_node
    } else {
	$form_node appendChild $input_file_node
    }

    # adding owner info
    set owner_node [$dom_doc createElement "input"]
    $owner_node setAttribute name "owner_id"
    $owner_node setAttribute type "hidden"
    $owner_node setAttribute value "$user_id"
    $form_node appendChild $owner_node

    if { ![string eq "" $role_instance_id] } {
	set role_instance_node [$dom_doc createElement "input"]
	$role_instance_node setAttribute name "role_instance_id"
	$role_instance_node setAttribute type "hidden"
	$role_instance_node setAttribute value "$role_instance_id"
	$form_node appendChild $role_instance_node
    }

    # adding hidden variables
    set run_id_node [$dom_doc createElement "input"]
    $run_id_node setAttribute name "run_id"
    $run_id_node setAttribute type "hidden"
    $run_id_node setAttribute value "$run_id"
    $form_node appendChild $run_id_node

    # adding return url
    set return_url_node [$dom_doc createElement "input"]
    $return_url_node setAttribute name "return_url"
    $return_url_node setAttribute type "hidden"
    $return_url_node setAttribute value "[ad_conn url]?[ad_conn query]"
    $form_node appendChild $return_url_node

    # adding the submit button
    set submit_node [$dom_doc createElement "input"]
    $submit_node setAttribute type "submit"
    $submit_node setAttribute value "ok"
    $form_node appendChild $submit_node
    # done... add the form to the table
    set td_node [$dom_doc createElement td] 
    $td_node setAttribute class list
    $td_node appendChild $form_node
    
    $tr_node appendChild $td_node
    $table_node  appendChild $tr_node
} if_no_rows {
    set tr_node [$dom_doc createElement tr]
    $tr_node setAttribute class list-even

    set td_node [$dom_doc createElement td]
    $td_node setAttribute class list
    $td_node setAttribute colspan 2
    $td_node appendChild [$dom_doc createTextNode "[_ imsld.No_properties_found]"]

    $tr_node appendChild $td_node
    $table_node  appendChild $tr_node
}

$body_node appendChild $table_node
$dom_root appendChild $body_node

set script_node [$dom_doc createElement script]
$script_node appendChild [$dom_doc createTextNode {document.forms['choose'].elements['ok'].style.display="none"}]

$dom_root appendChild $script_node

set xmloutput {<?xml version="1.0" encoding="UTF-8"?>}
append xmloutput [$dom_root asXML]
ns_return 200 text/html $xmloutput
