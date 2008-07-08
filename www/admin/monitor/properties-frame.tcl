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
    valid_type -requires {type} {
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

# if the property type is of type locpers or globpers
# we first need to specify which user will be monitorized

if { [string eq $type "locpers"] || [string eq $type "globpers"] } {
    # Fetch the users that are active in the run
    set users_in_run [imsld::runtime::users_in_run -run_id $run_id]

    template::multirow create item_select item_id item_name

    # Add the frame main title depending on the type of property
    if { [string eq $type "locpers"] } {
	set frame_header "[_ imsld.lt_Local-personal_Prop]: "
    } else {
	set frame_header "[_ imsld.lt_Global-personal_Pro]: "
    }

    if { [llength $users_in_run] == 1 } {
	set user_id [lindex $users_in_run 0]
    }

    set select_name "user_id"
    set select_id "users_in_run"
    set post_text ""
    set selected_item ""
    set select_string ""

    # If no user has been given, add the option pull-down menu
    if { [string eq "" $user_id] } {
	set select_string "[_ imsld.Select]"
    } else {
	# Set variable portrait_revision if user has portrait
	if { [db_0or1row get_member_portrait {
	    select c.live_revision
	    from acs_rels a, cr_items c
	    where a.object_id_two = c.item_id
	    and a.object_id_one = :user_id
	    and a.rel_type = 'user_portrait_rel'}]} {

	    set post_text "<img style=\"height: 100px; vertical-align: middle\" src=\"/shared/portrait-bits.tcl?user_id=$user_id\" alt=\"Portrait\"/>"
	}
    }
    
    foreach user_id_in_run $users_in_run {
	template::multirow append item_select $user_id_in_run \
	    "[person::name -person_id $user_id_in_run]"
	
	if { $user_id == $user_id_in_run} {
	    set selected_item $user_id
	}
    }
} elseif { [string eq $type "locrole"] } {
    # first, the role instance must be selected
    set role_instance_ids [imsld::roles::get_role_instances \
			       -role_id $role_id \
			       -run_id $run_id]

    template::multirow create item_select item_id item_name

    set frame_header "[_ imsld.lt_Local-role_Properti]: "
    set page_title $frame_header

    if { [llength $role_instance_ids] == 1 } {
	set role_instance_id [lindex $role_instance_ids 0]
	set role_name "[db_string role_instance_name { select acs_group__name(:role_instance_id) }]"
    }

    set select_name "role_instance_id"
    set select_id "roles_in_run"
    set post_text ""
    set selected_item ""
    set select_string ""

    if { [string eq "" $role_instance_id] } {
	set select_string "[_ imsld.Select_role]"
    }
    
    foreach role_instance_id_in_role $role_instance_ids {
	template::multirow append item_select $role_instance_id_in_role \
	    "[db_string role_instance_name {select
	acs_group__name(:role_instance_id_in_role) }]" 

	if { $role_instance_id == $role_instance_id_in_role } {
	    set selected_item $role_instance_id
	}
    }

} elseif { [string eq $type "glob"] } {
    set frame_header "[_ imsld.Global_Properties]"
} elseif { [string eq $type "loc"] } {
    set frame_header "[_ imsld.Local_Properties]"
} 

# Create the table with the properties
dom createDocument table dom_doc
set table_node [$dom_doc documentElement]
$table_node setAttribute class list-table
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
    coalesce(ins.title, ins.identifier) as title,
    ins.instance_id
    from imsld_property_instancesx ins,
    cr_revisions cr,
    imsld_propertiesi prop
    where ins.property_id = prop.property_id
    and $where_clause
    and cr.revision_id = ins.instance_id
    and content_revision__is_live(ins.instance_id) = 't'
    order by title
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
    $form_node setAttribute onsubmit "return submitForm(this)"
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
    $return_url_node setAttribute value "admin/monitor/index?[ad_conn query]"
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

# Render table only if user_id or role_instance_id is set
if { ![string eq "" $user_id] || ![string eq "" $role_instance_id] 
     || [string eq $type "glob"] || [string eq $type "loc"]} {
    set table_node [$table_node asXML]
} else {
    set table_node ""
}

set page_title $frame_header

