# packages/imsld/www/imsld-content-serve.tcl

ad_page_contract {
    Process an imsldcontent resource, changing the view and set properties tags
    with their respective HTML

    @creation-date Jun 2006
    @author jopez@inv.it.uc3m.s
    @cvs-id $Id$
} {
    run_id:integer,notnull
    {owner_user_id:integer ""}
    resource_item_id
    {role_id ""}
    upload_file:trim,optional
    upload_file.tmpfile:tmpfile,optional
}
if { [string eq $owner_user_id ""] } {
    set owner_user_id [ad_conn user_id]
}

# If no role_id is given, take the active role
if { [string eq $role_id ""] } {
    #get the user active role
    db_1row get_active_role {
	select iruns.active_role_id as role_id
	from imsld_run_users_group_rels iruns,
	acs_rels ar,
	imsld_run_users_group_ext iruge 
	where iruge.run_id=:run_id 
	and ar.object_id_one=iruge.group_id 
	and ar.object_id_two=:owner_user_id 
	and ar.rel_type='imsld_run_users_group_rel' 
	and ar.rel_id=iruns.rel_id
    }
}

# get file info
db_1row get_info {
    select cr.revision_id, cr.item_id,
    cpf.item_id,
    cpf.file_name,
    cr.mime_type
    from imsld_cp_filesx cpf,
    acs_rels ar, imsld_res_files_rels map, cr_revisions cr
    where ar.object_id_one = :resource_item_id
    and ar.object_id_two = cpf.item_id
    and ar.object_id_two = cr.item_id
    and cr.item_id = cpf.item_id
    and ar.rel_id = map.rel_id
    and content_revision__is_live(cr.revision_id) = 't'
    and map.displayable_p = 't'
}

set xml_string [cr_write_content -string -revision_id $revision_id]

# set xml_string "<body>[imsld::xowiki::page_content -item_id $item_id]</body>"

# context info
db_1row context_info {
    select ic.item_id as component_item_id,
    ii.imsld_id,
    rug.group_id as run_group_id
    from imsld_componentsi ic, 
    imsld_imsldsi ii, 
    imsld_runs ir, 
    imsld_run_users_group_ext rug
    where ic.imsld_id = ii.item_id
    and content_revision__is_live(ii.imsld_id) = 't'
    and ii.imsld_id = ir.imsld_id
    and rug.run_id = ir.run_id
    and ir.run_id = :run_id
}

# Get file-storage root folder_id
set fs_package_id [site_node_apm_integration::get_child_package_id \
		       -package_id [dotlrn_community::get_package_id \
					[dotlrn_community::get_community_id]] \
		       -package_key "file-storage"]

# Parser
# XML => DOM document
if { [catch {dom parse $xml_string dom_doc} errmsg] } {
    ns_log notice "IMSLD-CONTENT-SERVE:: ERROR: Not a valid XML file, serving without parsing!"
    # the docuemnt is not an xml file, just return it
    ns_return 200 $mime_type $xml_string
    ad_script_abort
} 
# DOM document => DOM root
$dom_doc documentElement dom_root

# procedure:
# currently we only deliver properties of one user at the same time in one
# given role
# 1. replace the view-property tags with the property title(optional) and value
# 2. replace the view-property-group tags with the properties titles(optional)
# and value of all the referenced properties
# 3. replace the set-property tags with input fields depending on the property
# type
# 4. replace the set-groperty-group tags with one input field per each
# referenced property in the group 
# 5. if there was at least one set-property* tag, add a submit button (FIX ME:
# currently for each set-property* a new form is added)
# 6. for each class, check the visibility value in the database

# 1. view-property nodes
set view_property_nodes [$dom_root selectNodes {//*[local-name()='view-property']}]
foreach view_property_node $view_property_nodes {
    # get requested info
    set identifier [$view_property_node getAttribute ref]
    set view [$view_property_node getAttribute view "value"]
    set property_of [$view_property_node getAttribute property-of "self"]

    # get the value, depending on the property type.  the only different case
    # is when viewing the proprty in the context of the role
    set role_instance_id 0

    # get property info
    db_1row property_info {
        select type,
        property_id
        from imsld_properties
        where component_id = :component_item_id
        and identifier = :identifier
    }

    if { ![string eq $property_of "self"] ||
	 [string eq $type "locrole"] } {
        # find the role instance which the user belongs to
        set role_instance_id \
	    [imsld::roles::get_user_role_instance \
		 -run_id $run_id \
		 -role_id $role_id \
		 -user_id $owner_user_id]
        if { !$role_instance_id } {
            # runtime error... the user doesn't belong to any role instance
            ns_log notice "User does not belong to any role instance"
            continue
        }
    }

    db_1row get_property_value {
        select ins.property_id,
        prop.datatype,
        coalesce(ins.value, prop.initial_value) as value,
        coalesce(ins.title, ins.identifier) as title,
	content_revision__get_content(cr.revision_id) as content, 
	ins.instance_id,
	ins.object_id,
	ins.parent_id,
	prop.type as property_type
        from imsld_property_instancesx ins,
	cr_revisions cr,
	imsld_propertiesi prop
        where ins.property_id = prop.property_id
	and prop.property_id = :property_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and 
		 ins.run_id = :run_id and ins.party_id = :owner_user_id)
             or (prop.type = 'locrole' and 
		 ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :owner_user_id))
	and cr.revision_id = ins.instance_id
	and content_revision__is_live(ins.instance_id) = 't'
    }

    # prepare replacement by the moment, the only different case are the
    # properties of type file
    switch $datatype {
	file {
	    set a_node ""
	    if { ![string eq "" $content] } {
		# This is incorrect for global properties. It only works for
		# local ones because root_folder_id is always obtained for the
		# package
		if { [string eq $property_type "global"] ||
		     [string eq $property_type "globpers"] } {
		    # global or globpers properties
		    set root_folder_id [dotlrn_fs::get_dotlrn_root_folder_id]
		    set url_prefix \
			[site_node_object_map::get_url \
			     -object_id $root_folder_id]
		} else {
		    set root_folder_id \
			[fs::get_root_folder -package_id $fs_package_id]
		    set url_prefix [apm_package_url_from_id $fs_package_id]
		}

		set folder_path \
		    [content::item::get_path -item_id $parent_id \
			 -root_folder_id $root_folder_id]

		db_1row get_fs_file_url {
		    select 
		    case 
		    when :folder_path is null
		    then fs.file_upload_name
		    else :folder_path || '/' || fs.file_upload_name
		    end as file_url,
		    file_upload_name
		    from fs_objects fs
		    where fs.live_revision = :instance_id
		}
		set file_url "${url_prefix}view/${file_url}"
		set a_node [$dom_doc createElement a]
		$a_node setAttribute href [export_vars -base "$file_url"]
		$a_node appendChild [$dom_doc createTextNode "[_ imsld.view_file]"]

	    } else {
		set a_node [$dom_doc createTextNode ""]
	    }
	    # prepare a link to the file 
	    if { [string eq $view "value"] } {
		# display just the value
		set view_property_new_node $a_node
	    } else {
		# its a value-title reference, display both
		set view_property_new_node [$dom_doc createElement p] 
		$view_property_new_node appendChild [$dom_doc createTextNode "$title:"]
		$view_property_new_node appendChild $a_node
	    }
	}
	default {
	    if { [string eq $view "value"] } {
		# display just the value
		set view_property_new_node [$dom_doc createTextNode "$value"]
	    } else {
		# its a value-title reference, display both
		set view_property_new_node [$dom_doc createTextNode "$title: $value"]
	    }
	}
    }
    
    # done... replace the node
    set parent_node [$view_property_node parentNode]
    $parent_node replaceChild $view_property_new_node $view_property_node
}

# 2. view-property-group nodes
set view_property_group_nodes [$dom_root selectNodes {//*[local-name()='view-property-group']}]
set view_property_group_new_node [$dom_doc createElement p]
foreach view_property_group_node $view_property_group_nodes {
    # get requested info
    set identifier [$view_property_group_node getAttribute ref]
    set view [$view_property_group_node getAttribute view "value"]
    set property_of [$view_property_group_node getAttribute property-of "self"]

    # add group title (according to the spec)
    set group_title [$dom_doc createTextNode "$identifier"]
    $view_property_group_new_node appendChild $group_title

    # get group property info
    db_1row group_property_info {
        select property_group_id,
        item_id as property_group_item_id
        from imsld_property_groupsi
        where component_id = :component_item_id
        and identifier = :identifier
    }

    # get the info in order to take the properties value, depending on the property type. 
    # the only different case is when viewing the proprty in the context of the role
    set role_instance_id 0
    if { ![string eq $property_of "self"] } {
        # find the role instance which the user belongs to
        set role_instance_id [imsld::roles::get_user_role_instance -run_id $run_id -role_id $role_id -user_id $owner_user_id]
        if { !$role_instance_id } {
            # runtime error... the user doesn't belong to any role instance
            ns_log notice "User does not belong to any role instance"
            continue
        }
    }

    db_foreach properties_in_group {
        select ins.property_id,
        prop.datatype,
        coalesce(ins.value, prop.initial_value) as value,
        coalesce(ins.title, ins.identifier) as title,
	content_revision__get_content(cr.revision_id) as content, 
	ins.instance_id,
	ins.object_id,
	ins.parent_id
        from imsld_property_instancesx ins,
	cr_revisions cr,
        acs_rels map,
	imsld_propertiesi prop
        where ins.property_id = prop.property_id
        and map.object_id_one = :property_group_item_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :owner_user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :owner_user_id))
        and map.object_id_two = prop.item_id
        and map.rel_type = 'imsld_gprop_prop_rel'
        and prop.component_id = :component_item_id
	and cr.revision_id = ins.instance_id
	and content_revision__is_live(ins.instance_id) = 't'
    } {
	# by the moment, the only different case are the properties of type file	
	switch $datatype {
	    file {
	    set a_node ""
		if { ![string eq "" $content] } {
		    set folder_path [db_exec_plsql get_folder_path {
			select content_item__get_path(:parent_id,:root_folder_id); 
		    }]
		    db_1row get_fs_file_url {
			select 
			case 
			when :folder_path is null
			then fs.file_upload_name
			else :folder_path || '/' || fs.file_upload_name
			end as file_url,
			file_upload_name
			from fs_objects fs
			where fs.live_revision = :instance_id
		    }
		    set file_url "[apm_package_url_from_id $fs_package_id]view/${file_url}"
		    set a_node [$dom_doc createElement a]
		    $a_node setAttribute href [export_vars -base "$file_url"]
		    $a_node appendChild [$dom_doc createTextNode "[_ imsld.view_file]"]
		    
		} else {
		    set a_node [$dom_doc createTextNode ""]
		}
		
		# prepare a link to the file 
		if { [string eq $view "value"] } {
		    # display just the value
		    set view_property_new_node $a_node
		} else {
		    # its a value-title reference, display both
		    set view_property_new_node [$dom_doc createElement p] 
		    $view_property_new_node appendChild [$dom_doc createTextNode "$title:"]
		    $view_property_new_node appendChild $a_node
		}
	    }
	    default {
		if { [string eq $view "value"] } {
		    # display only the value
		    set view_property_new_node [$dom_doc createTextNode "$value"]
		} else {
		    # its a value-title reference, display both
		    set view_property_new_node [$dom_doc createTextNode "$title: $value"]
		}
	    }
	}
	# prepare replacement
	$view_property_group_new_node appendChild [$dom_doc createElement p]
	$view_property_group_new_node appendChild $view_property_new_node
    }
    # done... replace the node
    set parent_node [$view_property_group_node parentNode]
    $parent_node replaceChild $view_property_group_new_node $view_property_group_node
}

# 3. set-property nodes
set set_property_nodes [$dom_root selectNodes {//*[local-name()='set-property']}]
foreach set_property_node $set_property_nodes {
    # get requested info
    set identifier [$set_property_node getAttribute ref]
    set view [$set_property_node getAttribute view "value"]
    set property_of [$set_property_node getAttribute property-of "self"]

    # get property info
    db_1row property_info {
        select type,
        property_id,
        datatype,
        item_id as property_item_id
        from imsld_propertiesi
        where component_id = :component_item_id
        and identifier = :identifier
	limit 1
    }

    # get the value, depending on the property type. 
    # the only different case is when viewing the proprty in the context of the role
    set role_instance_id 0
    if { ![string eq $property_of "self"] ||
	 [string eq $type "locrole"] } {
        # find the role instance which the user belongs to
        set role_instance_id [imsld::roles::get_user_role_instance -run_id $run_id -role_id $role_id -user_id $owner_user_id]
        if { !$role_instance_id } {
            # runtime error... the user doesn't belong to any role instance
            ns_log notice "User does not belong to any role instance"
            continue
        }
    }
    
    db_1row get_property_value {
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
	and prop.property_id = :property_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :owner_user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :owner_user_id))
	and cr.revision_id = ins.instance_id
	and content_revision__is_live(ins.instance_id) = 't'
    }
    
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
    
    # Prepare replacement
    set form_node [$dom_doc createElement "form"]
    $form_node setAttribute name "set-properties"
    $form_node setAttribute enctype "multipart/form-data"
    set url_prefix [ns_conn url]
    regexp (.*)/ $url_prefix url_prefix
    $form_node setAttribute action "${url_prefix}properties-value-set"
    $form_node setAttribute method "post"
    if { [string eq $view "title-value"] } {
        $form_node appendChild [$dom_doc createTextNode "$title"] 
    }

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
    $owner_node setAttribute value "$owner_user_id"
    $form_node appendChild $owner_node

    # adding run_id
    set run_id_node [$dom_doc createElement "input"]
    $run_id_node setAttribute name "run_id"
    $run_id_node setAttribute type "hidden"
    $run_id_node setAttribute value "$run_id"
    $form_node appendChild $run_id_node

    if { [string eq $type "locrole"] } {
	# adding role_instance_id
	set role_instance_id_node [$dom_doc createElement "input"]
	$role_instance_id_node setAttribute name "role_instance_id"
	$role_instance_id_node setAttribute type "hidden"
	$role_instance_id_node setAttribute value "$role_instance_id"
	$form_node appendChild $role_instance_id_node
    }

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

    # done... add the form to the root
    set parent_node [$set_property_node parentNode]
    # first, replace property node with the form node
    $parent_node replaceChild $form_node $set_property_node
    # FIXME: tDOME apparently(??) adds automathically  the attribute xmlns when replacing a node...
    $form_node removeAttribute xmlns

    # level C: notifications
    set notified_users_list [list]
    foreach notification_node [$set_property_node selectNodes "*\[local-name()='notification'\]"] {
        set activity_id ""
        set subjectValue ""
        set subjectNode [$notification_node selectNodes {*[local-name()='subject']}]
        if { [llength $subjectNode] } {
            set subjectValue [$subjectNode text]
        }
        
        set larefNode [$notification_node selectNodes {*[local-name()='learning-activity-ref']}] 
        if { [llength $larefNode] } {
            set larefValue [$larefNode getAttribute ref ""]
            set activityIdentifier $larefValue
        }
        
        set sarefNode [$notification_node selectNodes {*[local-name()='support-activity-ref']}] 
        if { [llength $sarefNode] } {
            set sarefValue [$sarefNode getAttribute ref ""]
            set activityIdentifier $sarefValue
        }
        
        if { [info exists activityIdentifier] } {
            set activity_id [db_string get_activity_id {
                select owner_id
                from imsld_attribute_instances
                where identifier = :activityIdentifier
                and run_id = :run_id
                and user_id = :owner_user_id
            }]
        }
        
        foreach emailDataNode [$notification_node selectNodes {*[local-name()='email-data']}] {
            
            set emailPropertyRef [$emailDataNode getAttribute email-property-ref ""]
            set usernamePropertyRef [$emailDataNode getAttribute username-property-ref ""]
            set roleRef [[$emailDataNode selectNodes {*[local-name()='role-ref']}] getAttribute ref ""]
            set username ""
            set email_address ""
            
            if { ![empty_string_p $usernamePropertyRef] } {
                # get the username proprty value
                # NOTE: there is no specification for the format of the email property value
                #       so we assume it is a single username
                set username [imsld::runtime::property::property_value_get -run_id $run_id -user_id $owner_user_id -identifier $usernamePropertyRef]
            }
            
            if { ![empty_string_p $emailPropertyRef] } {
                # get the email proprty value
                # NOTE: there is no specification for the format of the email property value
                #       so we assume it is a single email address.
                #       we also send the notificaiton to the rest of the role members
                set email_address [imsld::runtime::property::property_value_get -run_id $run_id -user_id $owner_user_id -identifier $emailPropertyRef]
            }
            
            db_1row get_context_info {
                select role_id, ii.imsld_id
                from imsld_roles ir, imsld_componentsi ic, imsld_imsldsi ii, imsld_runs run
                where ir.identifier = :roleRef
                and ir.component_id = ic.item_id
                and ic.imsld_id = ii.item_id
                and ii.imsld_id = run.imsld_id
                and run.run_id = :run_id
            }
            
            set notified_users_list [imsld::do_notification -imsld_id $imsld_id \
                                         -run_id $run_id \
                                         -subject $subjectValue \
                                         -activity_id $activity_id \
                                         -username $username \
                                         -email_address $email_address \
                                         -role_id $role_id \
                                         -user_id $owner_user_id \
                                         -notified_users_list $notified_users_list]
        }
    }
}

# 4. set-property-group nodes
set set_property_group_nodes [$dom_root selectNodes {//*[local-name()='set-property-group']}]
foreach set_property_group_node $set_property_group_nodes {
    # get requested info
    set identifier [$set_property_group_node getAttribute ref]
    set view [$set_property_group_node getAttribute view "value"]
    set property_of [$set_property_group_node getAttribute property-of "self"]

    # prepare replacement
    set form_node [$dom_doc createElement "form"]
    $form_node setAttribute name "set-properties"
    $form_node setAttribute enctype "multipart/form-data"
    set url_prefix [ns_conn url]
    regexp (.*)/ $url_prefix url_prefix
    $form_node setAttribute action "${url_prefix}/properties-value-set"
    $form_node setAttribute method "post"

    # add group title (according to the spec)
    set group_title [$dom_doc createTextNode "$identifier"]
    $form_node appendChild $group_title
    $form_node appendChild [$dom_doc createElement "br"]

    # get property info
    db_1row group_property_info {
        select property_group_id,
        item_id as property_group_item_id
        from imsld_property_groupsi
        where component_id = :component_item_id
        and identifier = :identifier
    }

    # get the value, depending on the property type. 
    # the only different case is when viewing the proprty in the context of the role
    set role_instance_id 0
    if { ![string eq $property_of "self"] } {
        # find the role instance which the user belongs to
        set role_instance_id [imsld::roles::get_user_role_instance -run_id $run_id -role_id $role_id -user_id $owner_user_id]
        if { !$role_instance_id } {
            # runtime error... the user doesn't belong to any role instance
            ns_log notice "User does not belong to any role instance"
            continue
        }
    }
    
    foreach properties_in_group [db_list_of_lists properties_in_group {
        select ins.property_id,
	prop.item_id as property_item_id,
        prop.datatype,
        coalesce(ins.value, prop.initial_value) as value,
        coalesce(ins.title, ins.identifier) as title,
	content_revision__get_content(cr.revision_id) as content, 
	ins.instance_id,
	ins.object_id,
	ins.parent_id
        from imsld_property_instancesx ins,
	cr_revisions cr,
        acs_rels map,
	imsld_propertiesi prop
        where ins.property_id = prop.property_id
        and map.object_id_one = :property_group_item_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :owner_user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :owner_user_id))
        and map.object_id_two = prop.item_id
        and map.rel_type = 'imsld_gprop_prop_rel'
        and prop.component_id = :component_item_id
	and cr.revision_id = ins.instance_id
	and content_revision__is_live(ins.instance_id) = 't'
    }] {
        set property_id [lindex $properties_in_group 0]
        set property_item_id [lindex $properties_in_group 1]
        set datatype [lindex $properties_in_group 2]
        set value [lindex $properties_in_group 3]
        set title [lindex $properties_in_group 4]
        set content [lindex $properties_in_group 5]
        set instance_id [lindex $properties_in_group 6]
        set object_id [lindex $properties_in_group 7]
        set parent_id [lindex $properties_in_group 8]

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
		db_foreach restriction {
		    select restriction_type,
		    value as restriction_value
		    from imsld_restrictions
		    where property_id = :property_item_id
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
	if { [string eq $view "title-value"] } {
            $form_node appendChild [$dom_doc createTextNode "$title"] 
        }

	if { ![string eq "" $select_node] } {
	    $form_node appendChild $select_node
	} elseif { ![string eq "" $input_text_node] } {
	    $form_node appendChild $input_text_node
	} else {
	    $form_node appendChild $input_file_node
	}
	
        $form_node appendChild [$dom_doc createElement "br"]                
    }

    set parent_node [$set_property_group_node parentNode]

    # adding owner info
    set owner_node [$dom_doc createElement "input"]
    $owner_node setAttribute name "owner_id"
    $owner_node setAttribute type "hidden"
    $owner_node setAttribute value "$owner_user_id"
    $form_node appendChild $owner_node

    # adding run_id
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

    # finally, replace property node with the form node
    $parent_node replaceChild $form_node $set_property_group_node
    # FIXME: tDOME apparently adds automathically  the attribute xmlns when replacing a node...
    $form_node removeAttribute xmlns

    # level C: notifications
    foreach notification_node [$set_property_group_node selectNodes "*\[local-name()='notification'\]"] {
        set activity_id ""
        set subjectValue ""
        set subjectNode [$notification_node selectNodes {*[local-name()='subject']}]
        if { [llength $subjectNode] } {
            set subjectValue [$subjectNode text]
        }
        
        set larefNode [$notification_node selectNodes {*[local-name()='learning-activity-ref']}] 
        if { [llength $larefNode] } {
            set larefValue [$larefNode getAttribute ref ""]
            set activityIdentifier $larefValue
        }
        
        set sarefNode [$notification_node selectNodes {*[local-name()='support-activity-ref']}] 
        if { [llength $sarefNode] } {
            set sarefValue [$sarefNode getAttribute ref ""]
            set activityIdentifier $sarefValue
        }
        
        if { [info exists activityIdentifier] } {
            set activity_id [db_string get_activity_id {
                select owner_id
                from imsld_attribute_instances
                where identifier = :activityIdentifier
                and run_id = :run_id
                and user_id = :owner_user_id
            }]
        }
        
        foreach emailDataNode [$notification_node selectNodes {*[local-name()='email-data']}] {
            
            set emailPropertyRef [$emailDataNode getAttribute email-property-ref ""]
            set usernamePropertyRef [$emailDataNode getAttribute username-property-ref ""]
            set roleRef [[$emailDataNode selectNodes {*[local-name()='role-ref']}] getAttribute ref ""]
            set username ""
            set email_address ""
            
            if { ![empty_string_p $usernamePropertyRef] } {
                # get the username proprty value
                # NOTE: there is no specification for the format of the email property value
                #       so we assume it is a single username
                set username [imsld::runtime::property::property_value_get -run_id $run_id -user_id $owner_user_id -identifier $usernamePropertyRef]
            }
            
            if { ![empty_string_p $emailPropertyRef] } {
                # get the email proprty value
                # NOTE: there is no specification for the format of the email property value
                #       so we assume it is a single email address.
                #       we also send the notificaiton to the rest of the role members
                set email_address [imsld::runtime::property::property_value_get -run_id $run_id -user_id $owner_user_id -identifier $emailPropertyRef]
            }
            
            db_1row get_context_info {
                select role_id, ii.imsld_id
                from imsld_roles ir, imsld_componentsi ic, imsld_imsldsi ii, imsld_runs run
                where ir.identifier = :roleRef
                and ir.component_id = ic.item_id
                and ic.imsld_id = ii.item_id
                and ii.imsld_id = run.imsld_id
                and run.run_id = :run_id
            }
            
            imsld::do_notification -imsld_id $imsld_id \
                -run_id $run_id \
                -subject $subjectValue \
                -activity_id $activity_id \
                -username $username \
                -email_address $email_address \
                -role_id $role_id \
                -user_id $owner_user_id
        }
    }
}

# 6. class nodes
set class_nodes [$dom_root selectNodes {//*[@class]}]
foreach class_node $class_nodes {
    # get requested info
    set class_name_list [split [$class_node getAttribute class] " "]
    foreach class_name $class_name_list {
        # get class info
        if { [db_0or1row class_info {
            select is_visible_p,
            title,
            with_control_p
            from imsld_attribute_instances
            where run_id = :run_id
            and user_id = :owner_user_id
            and identifier = :class_name
            and type = 'class'
        }] } {
            if { [string eq $is_visible_p "f"] } {
                set style_value [$class_node getAttribute "style" ""]
                if { ![string eq style_value ""] } {
                    $class_node setAttribute "style" "display:none;"
                } else {
                    $class_node setAttribute "style" "${style_value}; display:none;"
                }
            }
	    if { [string eq $with_control_p "t"] } {
	        $class_node setAttribute "class" "[$class_node getAttribute class] withcontrol"
	    }
	    $class_node setAttribute title $title
        }
    }
}

set script [$dom_doc createElement script]
$script setAttribute type {text/javascript}
$script setAttribute src {/resources/imsld/imsldcontent.js}
set bodies [$dom_root selectNodes "*\[local-name()='body'\]"]
foreach body $bodies {
    $body appendChild $script
}
set fs_resource_info [db_0or1row get_fs_resource_info {
    select cr.revision_id as imsld_file_id,
    cpf.parent_id as parent_id
    from imsld_cp_filesx cpf,
    acs_rels ar, imsld_res_files_rels map, cr_revisions cr
    where ar.object_id_one = :resource_item_id
    and ar.object_id_two = cpf.item_id
    and cr.item_id = cpf.item_id
    and ar.rel_id = map.rel_id
    and content_revision__is_live(cr.revision_id) = 't'
    and map.displayable_p = 't'
}]

# It doesn't make sense to have a base attribute defined, since there could be
# multiple properties to be shown in the page, and therefore, the base URL is
# not so easy to compute.

set root_folder_id [fs::get_root_folder -package_id $fs_package_id]

set folder_path ""
set folder_path [db_exec_plsql get_folder_path {select content_item__get_path(:parent_id,:root_folder_id); }]
set file_url "[apm_package_url_from_id $fs_package_id]view/${folder_path}"

set head_node [$dom_root selectNodes {//*[local-name()='head']}]
if {$head_node eq ""} {
    set head_node [$dom_doc createElement "head"]
    $dom_root insertBefore $head_node [$dom_root firstChild]
}

if {![llength [$head_node selectNodes {/*[local-name()='base']}]]} {
    set base_node [$dom_doc createElement "base"]
    set base_prefix [ns_conn location]
    $base_node setAttribute href "$base_prefix/$file_url/"
    $head_node appendChild $base_node
}



set xmloutput {<?xml version="1.0" encoding="UTF-8"?>}
append xmloutput [$dom_root asXML]
ns_return 200 text/html $xmloutput
