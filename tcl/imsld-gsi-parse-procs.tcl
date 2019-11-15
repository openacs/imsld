# /packages/imsld/tcl/imsld-gsi-parse.procs.tcl

ad_library {
    Procedures in the imsld namespace for parsing gsi based XML files.
    
    @creation-date Oct 2008
    @author lfuente@it.uc3m.es
}

namespace eval imsld {}
namespace eval imsld::gsi {}
namespace eval imsld::gsi::parse {}

ad_proc -public imsld::gsi::parse::parse_and_create_genericService {
    -service_node
    -parent_id
    -environment_id
    -manifest_id
    -manifest
    -resource_handler
    -tmp_dir
} {
    Parse a genericService and stores all the information in the database.

    Returns a list with the new gservice_ids (item_ids) created if there were no errors, or 0 and an explanation message if there was an error. 
    Generic services are just stored in the database, but no deployment is done in any sense.

    @param service_node service node to parse
} {
    upvar files_struct_list files_struct_list

    set gservice_info [list]

    set imsld_id [db_string get_imsld_from_manifest {
            select iii.item_id 
            from imsld_imsldsi iii, 
                 imsld_cp_organizationsi ico 
            where ico.manifest_id=:manifest_id and 
                  ico.item_id=iii.organization_id;
    }]

    set gservice_identifier [imsld::parse::get_attribute -node $service_node -attr_name identifier]

    set gservice_visibility [imsld::parse::get_attribute -node $service_node -attr_name isvisible]
    if { [ string eq $gservice_visibility "true"] } {
        set gservice_visibility "t"
    } elseif { [llength $gservice_visibility] } {
        set gservice_visibility "t"
    } else {
        set gservice_visibility "f"
    }

    set title_node [$service_node selectNodes "*\[local-name()='title'\]"]
    imsld::parse::validate_multiplicity -tree $title_node -multiplicity 1 -element_name "Title (genericService)" -lower_than
    if { [llength $title_node]} {
        set service_title [imsld::parse::get_element_text -node $title_node]
    } else {
        set service_title ""
    }

    set description_node [$service_node selectNodes "*\[local-name()='description'\]"]
    imsld::parse::validate_multiplicity -tree $description_node -multiplicity 1 -element_name "Description (genericService)" -lower_than
    if { [llength $description_node] } {
        set service_description [imsld::gsi::parse::parse_and_create_description -node $description_node]
    } else {
        set service_description ""
    }

    set tool_node [$service_node selectNodes "*\[local-name()='tool'\]"]
    imsld::parse::validate_multiplicity -tree $tool_node -multiplicity 1 -element_name "Tool (genericService)" -equal
    set tool_id [imsld::gsi::parse::parse_and_create_tool -node $tool_node -parent_id $parent_id]

    set constraints_node [$service_node selectNodes "*\[local-name()='constraints'\]"]
    imsld::parse::validate_multiplicity -tree $constraints_node -multiplicity 1 -element_name "Constraints (genericService)" -equal
    set constraints_id [imsld::gsi::parse::parse_and_create_constraints -node $constraints_node \
                                                                        -parent_id $parent_id \
                                                                        -manifest $manifest \
                                                                        -manifest_id $manifest_id \
                                                                        -tmp_dir $tmp_dir \
                                                                        -resource_handler $resource_handler]

    set gservice_id [imsld::item_revision_new -attributes [list [list description $service_description]  \
                                                            [list identifier  $gservice_identifier]  \
                                                            [list is_visible_p $gservice_visibility] \
                                                            [list gsi_tool_id  $tool_id]  \
                                                            [list environment_id $environment_id]  \
                                                            [list gsi_constraint_id $constraints_id]] \
                                        -content_type imsld_gsi_service \
                                        -title $service_title \
                                        -parent_id $parent_id ]

    set alternatives_node [$service_node selectNodes "*\[local-name()='alternatives'\]"]
    imsld::parse::validate_multiplicity -tree $alternatives_node -multiplicity 1 -element_name "Alternatives (genericService)" -lower_than
    set alternatives_id [imsld::gsi::parse::parse_and_create_alternatives -node $alternatives_node -gsi_service_id $gservice_id -parent_id $parent_id]

    set groups_node [$service_node selectNodes "*\[local-name()='groups'\]"]
    imsld::parse::validate_multiplicity -tree $groups_node -multiplicity 1 -element_name "Groups (genericService)" -equal
    set groups_id_list [imsld::gsi::parse::parse_and_create_groups -node $groups_node -parent_id $parent_id -gservice_id $gservice_id -imsld_id $imsld_id]

    #permissions (inside tools) require tool_id and group_id, so it is created now
    imsld::gsi::parse::parse_and_create_permissions -tool_node $tool_node -parent_id $parent_id -tool_id $tool_id -imsld_id $imsld_id -service_id $gservice_id

    return $gservice_info
} 

ad_proc -public imsld::gsi::parse::parse_and_create_permissions {
    -tool_node 
    -parent_id 
    -tool_id 
    -imsld_id
    -service_id
} { 
} {
    set permissions [$tool_node selectNodes "*\[local-name()='permissions'\]/*\[local-name()='permission'\]"] 
    foreach permission $permissions {

        set holder [$permission selectNodes "*\[local-name()='holder'\]"]
        imsld::parse::validate_multiplicity -tree $holder -multiplicity 1 -element_name "holder (permission)" -equal
        set group_ref [$holder selectNodes "*\[local-name()='group-ref'\]"]
        imsld::parse::validate_multiplicity -tree $group_ref -multiplicity 1 -element_name "group-ref (holder)" -equal
        set group_ref_value [imsld::parse::get_attribute -node $group_ref -attr_name ref]
        set holder_id [db_string get_holder_from_ref {
            select gsi_group_id 
            from imsld_gsi_groups 
            where gsi_service_id=:service_id and 
                  identifier=:group_ref_value
        }]

        set action [$permission selectNodes "*\[local-name()='action'\]"]
        imsld::parse::validate_multiplicity -tree $action -multiplicity 1 -element_name "action (permission)" -equal
        set action [imsld::parse::get_attribute -node $action -attr_name type]

        set data [$permission selectNodes "*\[local-name()='data'\]"]
        imsld::parse::validate_multiplicity -tree $data -multiplicity 1 -element_name "data (permission)" -equal
        set datatype [imsld::parse::get_attribute -node $data -attr_name datatype]

        set group_ref [$data selectNodes "*\[local-name()='owner'\]/*\[local-name()='group-ref'\]"]
        imsld::parse::validate_multiplicity -tree $data -multiplicity 1 -element_name "group-ref (owner)" -equal
        set group_ref_value [imsld::parse::get_attribute -node $group_ref -attr_name ref]

        #owner_id can be null, with free interpretation (all users, platform default values, etc.)';
        set owner_id [db_string get_holder_from_ref {
            select gsi_group_id 
            from imsld_gsi_groups 
            where gsi_service_id=:service_id and 
                  identifier=:group_ref_value
        }]

        set permission_id [imsld::item_revision_new -attributes [list [list holder_id $holder_id]  \
                                                                      [list action $action]  \
                                                                      [list data_type $datatype]  \
                                                                      [list owner_id $owner_id]]  \
                                                    -content_type imsld_gsi_permission \
                                                    -parent_id $parent_id]

        relation_add imsld_gsi_tools_perm_rel $tool_id $permission_id
    }
    return
}
 

ad_proc -public imsld::gsi::parse::parse_and_create_description {
    -node
} {
    Parse a description node, as defined in gsi xml schema

    Returns a list with the new description info
    
    @param node node to parse
} {
    set description_item [$node selectNodes "*\[local-name()='item'\]"]
    imsld::parse::validate_multiplicity -tree $description_item -multiplicity 1 -element_name "Item (in description)" -equal
    
    set identifierref [imsld::parse::get_attribute -node $description_item -attr_name identifierref] 
    return [list $identifierref]
}


ad_proc -public imsld::gsi::parse::parse_and_create_groups {
    -node
    -parent_id
    -gservice_id
    -imsld_id
} {
    Parse a groups node, as defined in gsi xml schema

    Returns a list with all the groups identifiers found.
    
    @param node node to parse
} {
    set groups_info [list]

    set group_list [$node selectNodes "*\[local-name()='group'\]"]
    imsld::parse::validate_multiplicity -tree $group_list -multiplicity 1 -element_name "Group (genericService)" -greather_than

    foreach group $group_list {
        set group_identifier [imsld::parse::get_attribute -node $group -attr_name identifier]

        set group_id [imsld::item_revision_new -attributes [list [list gsi_service_id $gservice_id] \
                                                                 [list identifier $group_identifier]]\
                                            -content_type imsld_gsi_group \
                                            -parent_id $parent_id ]

        set roles_in_group [$group selectNodes "*\[local-name()='ld-role'\]"]
        imsld::parse::validate_multiplicity -tree $roles_in_group -multiplicity 1 -element_name "ld-role (genericService)" -greather_than

        foreach role $roles_in_group {
            set role_ref [$role getAttribute imsld:role-ref]
            #FIXME: this way of getting attributes only allow the "imsld" prefix. That is: mismanage the namespaces


            set role_id [db_string get_role_from_ref {
                select ir.item_id 
                from imsld_rolesi ir,
                     imsld_componentsi ic
                where ic.imsld_id=:imsld_id and
                      ic.item_id=ir.component_id and
                      ir.identifier=:role_ref
            } ]
#            imsld::roles::get_role_id -ref $role_ref -imsld_id $imsld_id
#            set role_id [db_string get_item_from_object {select item_id from imsld_rolesi where object_id=:role_id}]
            relation_add imsld_gsi_groups_roles_rel $group_id $role_id
        }

        lappend groups_info $group_id
    }

    return $groups_info
}

ad_proc -public imsld::gsi::parse::parse_and_create_tool {
    -node
    -parent_id
} {
    Parse a tool node, as defined in gsi xml schema

    Returns a list with all the constraints found.
    
    @param node node to parse
} {
    set tool_info [list]
    
    set title_node [$node selectNodes "*\[local-name()='title'\]"]
    imsld::parse::validate_multiplicity -tree $title_node -multiplicity 1 -element_name "Title (tool)" -lower_than
    if { [llength $title_node]} {
        set tool_title [imsld::parse::get_element_text -node $title_node]
    } else {
        set tool_title ""
    }

    set description_node [$node selectNodes "*\[local-name()='description'\]"]
    imsld::parse::validate_multiplicity -tree $description_node -multiplicity 1 -element_name "Description (tool)" -lower_than
    if { [llength $description_node] } {
        set tool_description [imsld::gsi::parse::parse_and_create_description -node $description_node]
    } else {
        set tool_description ""
    }

    set tool_id [imsld::item_revision_new -attributes [list [list description $tool_description]] \
                                        -content_type imsld_gsi_tool \
                                        -title $tool_title \
                                        -parent_id $parent_id ]



    set keywords_node [$node selectNodes "*\[local-name()='keywords'\]"]
    imsld::parse::validate_multiplicity -tree $keywords_node -multiplicity 1 -element_name "Keyword" -equal
    set keywords_ids [imsld::gsi::parse::parse_and_create_keywords -node $keywords_node -parent_id $parent_id -gsi_tool_id $tool_id]

    set functions_node [$node selectNodes "*\[local-name()='functions'\]"]
    imsld::parse::validate_multiplicity -tree $functions_node -multiplicity 1 -element_name "functions (tool)" -lower_than
    if { [llength $functions_node] } {
        lappend tool_info [imsld::gsi::parse::parse_and_create_functions -node $functions_node -tool_id $tool_id]
    } 

    #permissions will be created later (they require the service_id)
        
    return $tool_id
}

ad_proc -public imsld::gsi::parse::parse_and_create_keywords {
    -node
    -parent_id
    -gsi_tool_id
} {
    Parse a keywords node, as defined in gsi xml schema

    Returns a list with all the keywords found.

    @param node node to parse
} {
    set keywords_list [list]

    set keyword [$node selectNodes "*\[local-name()='keyword'\]"]
    imsld::parse::validate_multiplicity -tree $keyword -multiplicity 1 -element_name "keyword (keywords)" -greather_than

    foreach word $keyword {
        set keyword_value [imsld::parse::get_element_text -node $word]
        set keyword_id [imsld::item_revision_new -attributes [list [list value $keyword_value] ]\
                                        -content_type imsld_gsi_keyword \
                                        -parent_id $parent_id ]
        relation_add imsld_gsi_keywords_tools_rel $keyword_id $gsi_tool_id
        lappend keywords_list $keyword_id
    }
    return $keywords_list
}

ad_proc -public imsld::gsi::parse::get_function_id {
    -function_name
} {
    Returns the item_id of the function that responds to a given name, 0 if not found
} {
    return [db_string get_gsi_function_id {
                                    select gsi_function_id 
                                    from imsld_gsi_functions 
                                    where function_name=:function_name
    } -default "0"]
}

ad_proc -public imsld::gsi::parse::get_trigger_id {
    -trigger_name
} {
    Returns the item_id of the trigger that responds to a given name, 0 if not found
} {
    return [db_string get_gsi_trigger_id {
                                    select gsi_trigger_id 
                                    from imsld_gsi_triggers 
                                    where trigger_type=:trigger_name
    } -default "0"]
}

ad_proc -public imsld::gsi::parse::parse_and_create_functions {
    -node
    -tool_id
} {
    Parse a functions node, as defined in gsi xml schema

    Returns a list with the functions info.
    
    @param node node to parse
} {
    set functions_list [list]

    if { [llength [$node selectNodes "*\[local-name()='deploy'\]"] ] } {
        set function_id [imsld::gsi::parse::get_function_id -function_name "deploy"]
        db_dml set_relation {INSERT INTO imsld_gsi_tools_funct_rels VALUES (:function_id,:tool_id)}
    }
    if { [llength [$node selectNodes "*\[local-name()='close'\]"] ] } {
        set function_id [imsld::gsi::parse::get_function_id -function_name "close"]
        db_dml set_relation {INSERT INTO imsld_gsi_tools_funct_rels VALUES (:function_id,:tool_id)}
    }
    
    if { [llength [$node selectNodes "*\[local-name()='modify-permissions'\]"]] } {
        set function_id [imsld::gsi::parse::get_function_id -function_name "modify-permissions"]
        db_dml set_relation {INSERT INTO imsld_gsi_tools_funct_rels VALUES (:function_id,:tool_id)}
    }
    if { [llength [$node selectNodes "*\[local-name()='set-values'\]"]] } {
        set function_id [imsld::gsi::parse::get_function_id -function_name "set-values"]
        db_dml set_relation {INSERT INTO imsld_gsi_tools_funct_rels VALUES (:function_id,:tool_id)}
    }
    return
}

#ad_proc -public imsld::gsi::parse::parse_and_create_permissions {
#    -node
#} {
#    Parse a permissions node, as defined in gsi xml schema
#
#    Returns a list with all the permissions info found.
#    
#    @param node node to parse
#} {
#    set permissions_list [list]
#    set permissions [$node selectNodes "*\[local-name()='permission'\]"]
#    imsld::parse::validate_multiplicity -tree $permissions -multiplicity 1 -element_name "permission (permissions)" -greather_than
#
#    foreach permission $permissions {
#        set permission_info [list]
#
#        set holder [$permission selectNodes "*\[local-name()='holder'\]"]
#        imsld::parse::validate_multiplicity -tree $holder -multiplicity 1 -element_name "holder (permission)" -equal
#        set holder_info [list]
#        #find group-ref elements
#        set group_refs [$holder selectNodes "*\[local-name()='group-ref'\]"]
#        imsld::parse::validate_multiplicity -tree $group_refs -multiplicity 1 -element_name "group-ref (holder)" -greather_than
#
#        foreach group $group_refs {
#            lappend holder_info [list [imsld::parse::get_attribute -node $group -attr_name ref]]
#        }
#        lappend permission_info $holder_info
#
#        set action [$permission selectNodes "*\[local-name()='action'\]"]
#        imsld::parse::validate_multiplicity -tree $action -multiplicity 1 -element_name "action (permission)" -equal
#        #find type attribute
#        lappend permission_info [imsld::parse::get_attribute -node $action -attr_name type]
#
#        set data [$permission selectNodes "*\[local-name()='data'\]"]
#        imsld::parse::validate_multiplicity -tree $data -multiplicity 1 -element_name "data (permission)" -equal
#        #find owner and type
#        set data_info [list]
#        lappend data_info [imsld::parse::get_attribute -node $data -attr_name datatype]
#        set group_refs [$data selectNodes "*\[local-name()='owner'\]/*\[local-name()='group-ref'\]"]
#        foreach group_ref_node $group_refs {
#            lappend data_info [list [imsld::parse::get_attribute -node $group_ref_node -attr_name ref]]
#        }
#        lappend permission_info $data_info
#
#
#
#        lappend permissions_list $permission_info
#
#    }
#
#    return $permissions_list
#}



ad_proc -public imsld::gsi::parse::parse_and_create_constraints {
    -node
    -parent_id
    -manifest
    -manifest_id
    -tmp_dir
    -resource_handler
} {
    Parse a constraints node, as defined in gsi xml schema

    Returns a list with all the constraints found.
    
    @param node node to parse
} {
    upvar files_struct_list files_struct_list

    set constraints_info [list]

    set life_span_node [$node selectNodes "*\[local-name()='life-span'\]"]
    imsld::parse::validate_multiplicity -tree $life_span_node -multiplicity 1 -element_name "life-span" -equal
    set start_node [$life_span_node selectNodes "*\[local-name()='start'\]"]
    imsld::parse::validate_multiplicity -tree $start_node -multiplicity 1 -element_name "start (in life-span)" -equal
    set start_value [list [imsld::parse::get_attribute -node $start_node -attr_name date]]
    set stop_node [$life_span_node selectNodes "*\[local-name()='stop'\]"]
    imsld::parse::validate_multiplicity -tree $stop_node -multiplicity 1 -element_name "stop (in life-span)" -lower_than
    if { [llength $stop_node] } {
        lappend stop_value [list [imsld::parse::get_attribute -node $stop_node -attr_name date]]
    } else {
        lappend stop_value ""
    }

    set multiplicity_node [$node selectNodes "*\[local-name()='multiplicity'\]"]
    imsld::parse::validate_multiplicity -tree $multiplicity_node -multiplicity 1 -element_name "multiplicity" -equal
    set multiplicity_value [imsld::parse::get_attribute -node $multiplicity_node -attr_name type]


    set constraints_id [imsld::item_revision_new -attributes [list [list start_date $start_value] \
                                                                   [list stop_date $stop_value]  \
                                                                   [list multiplicity $multiplicity_value]] \
                                        -content_type imsld_gsi_constraint \
                                        -parent_id $parent_id ]

    set triggers_node [$node selectNodes "*\[local-name()='triggers'\]"]
    imsld::parse::validate_multiplicity -tree $triggers_node -multiplicity 1 -element_name "triggers" -equal
    imsld::gsi::parse::parse_and_create_triggers -trigger_node $triggers_node \
                                                 -constraint_id $constraints_id \
                                                 -parent_id $parent_id \
                                                 -manifest $manifest \
                                                 -manifest_id $manifest_id \
                                                 -tmp_dir $tmp_dir \
                                                 -resource_handler $resource_handler

    return $constraints_id
}

ad_proc -public imsld::gsi::parse::parse_and_create_triggers {
    -trigger_node
    -parent_id
    -constraint_id
    -manifest
    -manifest_id
    -tmp_dir
    -resource_handler
} {
    Parse a triggers node, as defined in gsi xml schema

    Returns a list with all the info.
    
    @param node node to parse
} {

    upvar files_struct_list files_struct_list

#all child nodes,only element nodes
    set child_nodes [$trigger_node childNodes]
    foreach node $child_nodes {
       if { [string eq "ELEMENT_NODE" [$node nodeType] ] } {
           imsld::parse::validate_multiplicity -tree $node -multiplicity 1 -element_name "action (triggers)" -lower_than
# this line made sense when the type was an attribute
#           set type [imsld::parse::get_attribute -node $node -attr_name type]
            #the type is the subelement whose name matches in functions table. 
            #All other childs are trigger params, so they are ignored
           set all_trigger_childs [$node childNodes]
           foreach child_element $all_trigger_childs {
                set tmp_function_id [imsld::gsi::parse::get_function_id -function_name [$child_element nodeName]]
                if { ![string eq $tmp_function_id 0] } {
                   set function_id $tmp_function_id
                   set parameters [imsld::gsi::parse::get_function_parameter_values -action_node $child_element \
                                                                                    -manifest $manifest \
                                                                                    -manifest_id $manifest_id \
                                                                                    -parent_id $parent_id \
                                                                                    -tmp_dir $tmp_dir \
                                                                                    -resource_handler $resource_handler]
                }
           }
#           type [[$node childNodes] nodeName]
#           set function_id [imsld::gsi::parse::get_function_id -function_name $type]
           set trigger_id [imsld::gsi::parse::get_trigger_id -trigger_name [$node nodeName]]


           set usage_set_id [imsld::item_revision_new -attributes [list \
                                                                      [list gsi_constraint_id $constraint_id] \
                                                                      [list gsi_trigger_id $trigger_id]  \
                                                                      [list gsi_function_id $function_id]] \
                                                      -content_type imsld_gsi_funct_usage \
                                                      -parent_id $parent_id ]

           #I have to obtain trigger parameters here and store them in the database.
           imsld::gsi::parse::parse_and_create_trigger_params -node $node \
                                                              -trigger_id $trigger_id \
                                                              -usage_set_id $usage_set_id


           foreach pair $parameters {
               set param_name [lindex $pair 0]
               set param_id [db_string get_param_id_form_param_name {
                                        select gsi_function_param_id as param_id 
                                        from imsld_gsi_function_params 
                                        where param_name=:param_name}]
               set value [lindex $pair 1]
               db_dml insert_param_value {INSERT INTO imsld_gsi_par_val_rels VALUES (:param_id,:value,:usage_set_id)}
           }
       }
    }
}

ad_proc -public imsld::gsi::parse::parse_and_create_trigger_params {
    -node
    -trigger_id
    -usage_set_id
} {
    Parse a trigger node and look for parameters inside triggers. If found, they are stored in the database
} {
    #1- let's check if root node has attributes
    set attributes [$node attributes]
    set trigger_name [$node localName]
    foreach attrib_name $attributes {
        #search the corresponding param_id. Both param_name and trigger_name must match
        db_1row get_param_id {
                                select tp.gsi_trigger_param_id as param_id
                                from imsld_gsi_trigger_params tp
                                where tp.gsi_param_name=:attrib_name and
                                      tp.gsi_trigger_id=:trigger_id
        }
        set attrib_value [$node getAttribute $attrib_name]
        
        #now we can insert in the database
        set param_val_id [db_nextval acs_object_id_seq]
        db_dml insert_param_value {
                INSERT INTO imsld_gsi_trig_param_values VALUES ( :param_val_id, :param_id, :attrib_value, :usage_set_id);
        }
    }

    #2- check child elements. Only those whose name is in imsld_gsi_trigger_params table are interesting here
    set trigger_childs [$node childNodes]
    foreach childElement $trigger_childs {
        set param_name [$childElement localName]
        if {[db_0or1row is_trigger_param_p {
                                        select t.trigger_type, 
                                               tp.gsi_trigger_param_id as param_id
                                        from imsld_gsi_triggers t, 
                                             imsld_gsi_trigger_params tp 
                                        where t.gsi_trigger_id=tp.gsi_trigger_id and 
                                              tp.gsi_param_name=:param_name;
        }]} {
           switch $trigger_type {
                "on-condition-action" {
                    set param_value [$childElement asXML]
                }
                default {}
           }
            #now we can insert in the database
            set param_val_id [db_nextval acs_object_id_seq]
            db_dml insert_param_value {
                    INSERT INTO imsld_gsi_trig_param_values VALUES ( :param_val_id, :param_id, :param_value, :usage_set_id);
            }
        }
    }
}

ad_proc -public imsld::gsi::parse::get_function_parameter_values {
    -action_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
    -resource_handler
} {
} {

    upvar files_struct_list files_struct_list

    set param_value_list [list]
#    set actual_action_node [$action_node childNodes]
#    set action_type [$actual_action_node nodeName]
    set action_type [$action_node nodeName]
    switch $action_type { 
        "set-values" {
#           set mime_type_value [imsld::parse::get_attribute -node $actual_action_node -attr_name mime-type]
           set mime_type_value [imsld::parse::get_attribute -node $action_node -attr_name mime-type]
           lappend param_value_list [list "mime-type" $mime_type_value] 
#           set item_node [$actual_action_node selectNodes "*\[local-name()='item'\]" ]
           set item_node [$action_node selectNodes "*\[local-name()='item'\]" ]
           if { [llength $item_node] } {
            set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                                                               -manifest_id $manifest_id \
                                                               -item_node $item_node \
                                                               -parent_id $parent_id \
                                                               -tmp_dir $tmp_dir \
                                                               -resource_handler $resource_handler ]

               lappend param_value_list [list "item" [imsld::parse::get_attribute -node $item_node -attr_name identifierref]] 
           }
        }
        "modify-permissions" {
            lappend param_value_list [list "permission-ref" [imsld::parse::get_attribute -node $actual_action_node -attr_name permission-ref]]
        }
        "deploy" -
        "close"  -
        default { }
    }
    return $param_value_list
}

ad_proc -public imsld::gsi::parse::parse_and_create_alternatives {
    -node
    -gsi_service_id
    -parent_id
} {
    Parse an alterntatives node, as defined in gsi xml schema

    Returns a list with all the alternative identifiers found.
    
    @param node node to parse
} {

    set alternatives_list [list]
    set sort_order 1

    set alt_services_list [$node selectNodes "*\[local-name()='service-ref'\]"]
    if { [llength $alt_services_list] } {
        foreach alternative_service $alt_services_list {
            set reference [imsld::parse::get_attribute -node $alternative_service -attr_name ref]
            set alt_id [imsld::item_revision_new -attributes [list [list alternative_order $sort_order] \
                                                                   [list service_ref $reference] \
                                                                   [list gsi_service_id $gsi_service_id]] \
                                                        -content_type imsld_gsi_alternative \
                                                        -parent_id $parent_id ]
            set sort_order [expr $sort_order + 1]
            lappend alternatives_list $alt_id
        }
    }

    set alt_lo_list [$node selectNodes "*\[local-name()='learning-object-ref'\]"]
    if { [llength $alt_lo_list] } {
        foreach alternative_lo $alt_lo_list {
            set reference [imsld::parse::get_attribute -node $alternative_lo -attr_name identifierref]
            set alt_id [imsld::item_revision_new -attributes [list [list alternative_order $sort_order] \
                                                                   [list learning_object_ref $reference] \
                                                                   [list gsi_service_id $gsi_service_id]] \
                                                        -content_type imsld_gsi_alternative \
                                                        -parent_id $parent_id ]
            set sort_order [expr $sort_order + 1]
            lappend alternatives_list $alt_id
        }
    }

    return $alternatives_list
}

