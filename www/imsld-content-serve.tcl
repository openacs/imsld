# packages/imsld/www/imsld-content-serve.tcl

ad_page_contract {
    Process an imsldcontent resource, changing the view and set properties tags with their respective HTML

    @creation-date Jun 2006
    @author jopez@inv.it.uc3m.s
    @cvs-id $Id$
} {
    run_id:integer,notnull
    {owner_user_id:integer ""}
    resource_item_id
    {role_id ""}
}

if { [string eq $owner_user_id ""] } {
    set owner_user_id [ad_conn user_id]
}

# get file info
db_1row get_info {
    select f.revision_id,
    f.item_id,
    f.file_name
    from imsld_cp_filesi f, acs_rels ar, imsld_res_files_rels map
    where ar.object_id_one = :resource_item_id
    and ar.object_id_two = f.item_id
    and ar.rel_id = map.rel_id
    and map.displayable_p = 't'
}

set xml_string [cr_write_content -string -revision_id $revision_id]

# context info
db_1row context_info {
    select ic.item_id as component_item_id,
    ii.imsld_id,
    rug.group_id as run_group_id
    from imsld_componentsi ic, imsld_imsldsi ii, imsld_runs ir, imsld_run_users_group_ext rug
    where ic.imsld_id = ii.item_id
    and content_revision__is_live(ii.imsld_id) = 't'
    and ii.imsld_id = ir.imsld_id
    and rug.run_id = ir.run_id
    and ir.run_id = :run_id
}

# Parser
# XML => DOM document
dom parse $xml_string dom_doc
# DOM document => DOM root
$dom_doc documentElement dom_root

# procedure:
# currently we only deliver properties of one user at the same time in one given role
# 1. replace the view-property tags with the property title(optional) and value
# 2. replace the view-property-group tags with the properties titles(optional) and value of all the referenced properties
# 3. replace the set-property tags with input fields depending on the property type
# 4. replace the set-groperty-group tags with one input field per each referenced property in the group 
# 5. if there was at least one set-property* tag, add a submit button (FIX ME: currently for each set-property* a new form is added)
# 6. for each class, check the visibility value in the database

# 1. view-property nodes
set view_property_nodes [$dom_root selectNodes {//*[local-name()='view-property']}]
foreach view_property_node $view_property_nodes {
    # get requested info
    set identifier [$view_property_node getAttribute ref]
    set view [$view_property_node getAttribute view "value"]
    set property_of [$view_property_node getAttribute property-of "self"]

    # get property info
    db_1row property_info {
        select type,
        property_id
        from imsld_properties
        where component_id = :component_item_id
        and identifier = :identifier
    }

    # get the value, depending on the property type. 
    # the only different case is when viewing the proprty in the context of the role
    set role_instance_id 0
    # get property info
    db_1row property_info {
        select type,
        property_id
        from imsld_properties
        where component_id = :component_item_id
        and identifier = :identifier
    }

    if { ![string eq $property_of "self"] } {
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
        coalesce(ins.value, prop.initial_value) as value,
        prop.title
        from imsld_propertiesi prop,
        imsld_property_instances ins
        where prop.property_id = ins.property_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :owner_user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :owner_user_id))
        and prop.property_id = :property_id
    }

    # prepare replacement
    if { [string eq $view "value"] } {
        # display only the value
        set view_property_new_node [$dom_doc createTextNode "$value"]
    } else {
        # its a value-title reference, display both
        set view_property_new_node [$dom_doc createTextNode "$title: $value"]
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
        prop.title,
        prop.identifier
        from imsld_propertiesi prop,
        imsld_property_instances ins,
        acs_rels map
        where prop.property_id = ins.property_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :owner_user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :owner_user_id))
        and map.object_id_one = :property_group_item_id
        and map.object_id_two = prop.item_id
        and map.rel_type = 'imsld_gprop_prop_rel'
        and prop.component_id = :component_item_id
    } {
        # prepare replacement
        if { [string eq $view "value"] } {
            # display only the value
            set view_property_new_node [$dom_doc createTextNode "$value"]
        } else {
            # its a value-title reference, display both
            set view_property_new_node [$dom_doc createTextNode "$title: $value"]
        }
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

    db_1row get_property_value {
        select ins.property_id,
        prop.datatype,
        coalesce(ins.value, prop.initial_value) as value,
        prop.title,
        ins.instance_id
        from imsld_propertiesi prop,
        imsld_property_instances ins
        where prop.property_id = ins.property_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :owner_user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :owner_user_id))
        and prop.property_id = :property_id
    }

    # get the restrictions and translate them to HTML
    # currently, in HTML we can only deal with the restriction types: length, 
    # maxlength, enumeration and totaldigits. 
    # the rest are checked after submission
    set restriction_nodes [list]
    set input_text_node ""
    set select_node ""
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

    # prepare replacement
    set form_node [$dom_doc createElement "form"]
    $form_node setAttribute name "set-properties"
    $form_node setAttribute action "properties-value-set"
    $form_node setAttribute method "get"

    if { [string eq $view "title-value"] } {
        $form_node appendChild [$dom_doc createTextNode "$title"] 
    }

    if { ![string eq "" $select_node] } {
        $form_node appendChild $select_node
    } 

    if { ![string eq "" $input_text_node] } {
        $form_node appendChild $input_text_node
    } 

    # adding owner info
    set owner_node [$dom_doc createElement "input"]
    $owner_node setAttribute name "owner_id"
    $owner_node setAttribute type "hidden"
    $owner_node setAttribute value "$owner_user_id"
    $form_node appendChild $owner_node

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
    # FIXME: tDOME apparently adds automathically  the attribute xmlns when replacing a node...
    $form_node removeAttribute xmlns
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
    $form_node setAttribute action "properties-value-set"
    $form_node setAttribute method "get"

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
        prop.title,
        prop.identifier,
        ins.instance_id
        from imsld_propertiesi prop,
        imsld_property_instances ins,
        acs_rels map
        where prop.property_id = ins.property_id
        and ((prop.type = 'global')
             or (prop.type = 'loc' and ins.run_id = :run_id)
             or (prop.type = 'locpers' and ins.run_id = :run_id and ins.party_id = :owner_user_id)
             or (prop.type = 'locrole' and ins.run_id = :run_id and ins.party_id = :role_instance_id)
             or (prop.type = 'globpers' and ins.party_id = :owner_user_id))
        and map.object_id_one = :property_group_item_id
        and map.object_id_two = prop.item_id
        and map.rel_type = 'imsld_gprop_prop_rel'
        and prop.component_id = :component_item_id
    }] {
        set property_id [lindex $properties_in_group 0]
        set property_item_id [lindex $properties_in_group 1]
        set datatype [lindex $properties_in_group 2]
        set value [lindex $properties_in_group 3]
        set title [lindex $properties_in_group 4]
        set identifier [lindex $properties_in_group 5]
        set instance_id [lindex $properties_in_group 6]
        # get the restrictions and translate them to HTML
        # currently, in HTML we can only deal with the restriction types: length, 
        # maxlength, enumeration and totaldigits. 
        # the rest are checked after submission
        set input_text_node ""
        set select_node ""
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

        if { [string eq $view "title-value"] } {
            $form_node appendChild [$dom_doc createTextNode "$identifier"] 
        }

        if { ![string eq "" $select_node] } {
            $form_node appendChild $select_node
        } 

        if { ![string eq "" $input_text_node] } {
            $form_node appendChild $input_text_node
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
            and user_id = :user_id
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

set xmloutput {<?xml version="1.0" encoding="UTF-8"?>}
append xmloutput [$dom_root asXML]

ns_return 200 text/html $xmloutput
