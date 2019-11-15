# /packages/imsld/tcl/imsld-gsi-procs.tcl

ad_library {
    Procedures in the imsld gsi namespace.
    
    @creation-date Nov 2008
    @author lfuente@it.uc3m.es
}

namespace eval imsld {}
namespace eval imsld::gsi {}

ad_proc -public imsld::gsi::execute_conditional_actions { 
    -run_id
} { 
    Execute actions triggered by 'on-condition', whose condition evaluation is true.
} {
    set action_list [list]
    set temptative_actions [imsld::gsi::get_triggered_actions -trigger "on-condition-action" -run_id $run_id]

    foreach action $temptative_actions {
        db_1row get_condition_value {
           select tpv.gsi_trig_param_value as if_value
           from imsld_gsi_trig_param_values tpv,
                imsld_gsi_funct_usagei fu
           where fu.item_id=tpv.gsi_funct_usage_id
        }
        set document [dom parse $if_value]
        set if_node [$document documentElement]
        if {[imsld::expression::eval -run_id $run_id -expression $if_value]} {
            lappend action_list $action
        }
    }
    imsld::gsi::action_list_execute -run_id $run_id -actions $action_list
}

ad_proc -public imsld::gsi::get_services_in_run { 
    -run_id
} { 
    Return a list with all service_id that are in a given UoL (the one instantiated by the run_id)
} {
    set environments_in_run [db_list get_environments {
                                                    select ienv.item_id 
                                                    from imsld_componentsi ici, 
                                                         imsld_imsldsi iii, 
                                                         imsld_runs ir, 
                                                         imsld_environmentsi ienv 
                                                    where ienv.component_id=ici.item_id and 
                                                          ici.imsld_id=iii.item_id and 
                                                          iii.imsld_id=ir.imsld_id and 
                                                          ir.run_id=:run_id
    }]
    if {[llength $environments_in_run]} {
        return [db_list get_services_in_run "select gsi_service_id
                                             from imsld_gsi_services
                                             where environment_id in ([template::util::tcl_to_sql_list $environments_in_run])"]
    } else {
        return [list]
    }
}

ad_proc -public imsld::gsi::get_triggered_actions {
    -trigger:required
    -run_id
} { 
    Return a list with all actions triggered by the provided trigger.
    If run_id is given, the list is restricted to actions in this run.
} {
    set full_actions_list [db_list get_all_trigger_actions {
                select gfu.gsi_funct_usage_id 
                from imsld_gsi_funct_usage gfu, 
                     imsld_gsi_triggers gt 
                where gt.gsi_trigger_id=gfu.gsi_trigger_id and 
                      gt.trigger_type=:trigger
    }]
    if {[info exists run_id]} {
        set services_in_run [imsld::gsi::get_services_in_run -run_id $run_id]
        if {[llength $full_actions_list] && [llength $services_in_run]} {
            set actions_list [db_list get_matching_actions "
                select gsi_funct_usage_id 
                from imsld_gsi_funct_usage 
                where gsi_constraint_id in (select gsi_constraint_id 
                                            from imsld_gsi_services 
                                            where gsi_service_id in ([template::util::tcl_to_sql_list $services_in_run]))
                      and gsi_funct_usage_id in ([template::util::tcl_to_sql_list $full_actions_list])"]
        } else {
            set actions_list [list]
        }
        return $actions_list
    } else {
        return $full_actions_list
    }
}

ad_proc -public imsld::gsi::get_service_multiplicity { 
    -gservice_id
} { 
    Return a string with the multiplicity of a given service
} {

    return [db_string get_multiplicity {
                                        select c.multiplicity 
                                        from imsld_gsi_constraintsi c, 
                                             imsld_gsi_services s 
                                        where s.gsi_constraint_id=c.item_id 
                                              and s.gsi_service_id=:gservice_id
    } -default ""]
}

ad_proc -public imsld::gsi::get_service_startup_actions { 
    -gservice_id
} { 
    Return a list of lists containing all actions requested at startup for a given services. Each element in list contains a list
    with name, and a list of param_names param_values
} {
   #get usages from gservice where trigger is startup
    set usages [db_list get_usages {
                                    select fu.gsi_funct_usage_id
                                    from imsld_gsi_funct_usage fu,
                                         imsld_gsi_services serv,
                                         imsld_gsi_triggers trig
                                    where fu.gsi_constraint_id = serv.gsi_constraint_id and
                                          serv.gsi_service_id = :gservice_id and
                                          fu.gsi_trigger_id = trig.gsi_trigger_id and
                                          trig.trigger_type = 'startup-action'
    }]

    #get full data from these usages
    set full_data_list [list] 
    foreach usage_id $usages {
        #si es deploy o close, la lista es {deploy {} {}} o {close {} {}}
        set function_name [db_string get_function_name {
                        select fu.function_name
                        from imsld_gsi_funct_usage us, 
                             imsld_gsi_functions fu 
                        where us.gsi_function_id=fu.gsi_function_id and 
                              us.gsi_funct_usage_id=:usage_id;
        }]
        if {[string eq $function_name "deploy"] || [string eq $function_name "close"] } {
            lappend full_data_list [list $function_name {} {}] 
        } else {
        #si es set-value o modify-permissions, llevará parámetros, más de uno
        #la lista tendrá la forma: {set-values {name1 value1} {name2 value2} .... }
            set data_set [db_list_of_lists get_params {
                                    select param.param_name, 
                                           pvrel.gsi_param_value 
                                    from imsld_gsi_funct_usagei us, 
                                         imsld_gsi_functions fu, 
                                         imsld_gsi_par_val_rels pvrel, 
                                         imsld_gsi_function_params param 
                                    where fu.gsi_function_id=us.gsi_function_id and 
                                          pvrel.gsi_function_usage_id=us.item_id and 
                                          param.gsi_function_param_id=pvrel.gsi_function_param_id and 
                                          us.gsi_funct_usage_id=:usage_id
            }]
            set named_data_set [linsert $data_set 0 $function_name]
            lappend full_data_list $named_data_set 
        }
    }
    return $full_data_list
}

ad_proc -public imsld::gsi::get_group_from_role { 
    -gservice_id
    -role_id
} { 
    If found, returns the group_id in the mapping group-role in the given service. Otherwise, return empty string
} {
    return [db_string get_group_id {
        select iggi.gsi_group_id 
        from imsld_rolesi iri, 
             imsld_gsi_groupsi iggi, 
             acs_rels ar,
             imsld_gsi_servicesi igsi
        where iri.role_id=:role_id and 
              iri.item_id=ar.object_id_two and 
              ar.object_id_one=iggi.item_id and 
              igsi.item_id=iggi.gsi_service_id and
              igsi.gsi_service_id=:gservice_id
            } -default ""]
}

ad_proc -public imsld::gsi::get_group_permissions {
    -group_id
} {
    Return a list with all the permissions found for a given group. Each permission is a list with the form \{ actionType objectType ObjectOwner\}
} {
    return [db_list_of_lists get_group_permissions {
        select action, 
               data_type, 
               owner_id 
        from imsld_gsi_permissions 
        where holder_id=:group_id
    }]
}
ad_proc -public imsld::gsi::get_service_name { 
    -gservice_id
} { 
    If exists in database, returns the title of the service. Otherwise return the string \"Service link\"
} {
    return [db_string get_service_title {
        SELECT title 
        FROM imsld_gsi_servicesi
        WHERE gsi_service_id=:gservice_id
    } -default "Service link"]
}


ad_proc -public imsld::gsi::change_service_status {
    -gservice_id
    -run_id
    -status
} {
    @param gservice_id
    @param run_id
    @param status

    Changes the status of a service instance 
} {
    db_dml change_service_status {
        UPDATE imsld_gsi_service_status
        SET status=:status, last_modified=now()
        WHERE owner_id=:gservice_id and run_id=:run_id
    }
    return
}

ad_proc -public imsld::gsi::get_roles_in_group {
    -group_id:required
} {
    @param group_id
   The method returns all roles (user_id) in the group. 
} {
    return [db_list get_roles_id {
        select roles.role_id 
        from acs_rels ar, 
             imsld_gsi_groupsi g, 
             imsld_rolesi roles 
        where object_id_one=g.item_id and 
              ar.rel_type='imsld_gsi_groups_roles_rel' and 
              roles.item_id=ar.object_id_two and 
              g.gsi_group_id=group_id
    }]
}


ad_proc -public imsld::gsi::get_users_in_group {
    -group_id:required
} {
    @param group_id
   The method returns all members (user_id) in the group. 
} {
    set roles [imsld::gsi::get_roles_in_group -group_id $group_id]
    set all_users [list]
    foreach role $roles {
        set users_in_role [imsld::roles::get_users_in_role -role_id $role]
        lappend all_users $users_in_role
    }
    return $all_users
}


ad_proc -public imsld::gsi::get_service_status {
    -gservice_id
    -run_id
} {
    @param gservice_id
    @param run_id

    Returns the status of a service instance 
} {
    return [db_string get_service_status {
        SELECT status
        FROM imsld_gsi_service_status
        WHERE owner_id=:gservice_id and run_id=:run_id
    }]
}

ad_proc -public imsld::gsi::get_roles_in_service {
    -gservice_id
} { 
    Returns a list with the roles_id involved in the service
} {
    return [db_list get_roles {
        select r.role_id 
        from imsld_rolesi r, 
             acs_rels ar, 
             imsld_gsi_groupsi g, 
             imsld_gsi_servicesi s 
        where s.item_id=g.gsi_service_id and 
              ar.object_id_one=g.item_id and 
              ar.object_id_two=r.item_id}]
}

ad_proc -public imsld::gsi::get_users_in_service {
    -gservice_id
    -run_id
} { 
    Returns a list with the roles_id involved in the service
} {

    set roles_list [imsld::gsi::get_roles_in_service -gservice_id $gservice_id]
    set users_in_service [list]

    foreach role_id $roles_list {
        set tmp_list [concat $users_in_service [imsld::roles::get_users_in_role -role_id $role_id -run_id $run_id]]
        set users_in_service $tmp_list
    }

    return $users_in_service
}

ad_proc -public imsld::gsi::get_gservice_url {
    -user_id
    -run_id
    -gservice_id
} {
    Returns the service URL previously stored in the database
} {
    set out_list [db_list_of_lists get_gservice_url {
        select gsi_inst.url,
               gsi_inst.url_title
        from imsld_attribute_instances att,
             imsld_gsi_serv_instances gsi_inst  
        where att.run_id=:run_id and 
              att.owner_id=:gservice_id and 
              att.user_id=:user_id and 
              att.instance_id=gsi_inst.service_instance_id;
    }]

    return $out_list
}

ad_proc -public imsld::gsi::find_and_process_gsi_service_as_ul {
    -environment_id
    -user_id
    -run_id
    -dom_node
    -dom_doc
} {
    Fill an html list (in a dom tree) with the associated resources referenced from the given generic service.
    @param environment_id
    @param run_id
    @param dom_node
    @param dom_doc

    @return a list of all generic services included in the list 
} {
#TODO: hacer una query más completa
    set gservices_list [db_list gservices_in_environment {
        SELECT igs.gsi_service_id
        FROM imsld_gsi_services igs,
             imsld_environmentsi iei
        WHERE iei.environment_id=:environment_id and
              igs.environment_id=iei.item_id
    }]

    foreach gservice $gservices_list {
        set gservice_node_li [$dom_doc createElement li]
        set url_list [imsld::gsi::get_gservice_url -user_id $user_id -gservice_id $gservice -run_id $run_id]

        set ul_node [$dom_doc createElement ul]
        foreach url $url_list {
            set li_node [$dom_doc createElement li]
            set a_node [$dom_doc createElement a]
            $a_node setAttribute href "[lindex $url 0]"
            $a_node setAttribute target "content"
            set title_text [imsld::gsi::get_service_name -gservice_id $gservice]
            set gservice_title [$dom_doc createTextNode [lindex $url 1]]
            $a_node appendChild $gservice_title
            $li_node appendChild $a_node
            $ul_node appendChild $li_node
        }
        $gservice_node_li appendChild $ul_node
        
        $dom_node appendChild $gservice_node_li
    }
    return $gservices_list
}

ad_proc -public imsld::gsi::store_check_results {
    -service_response
    -gservice_id
    -run_id
} {
} {
    #insert the request (including the answer yet) in tables...
    set request_id [lindex $service_response 0]
    set function_response [lindex $service_response 1]
    set permissions_response [lindex $service_response 2]

    db_dml initialize_request {
        UPDATE imsld_gsi_service_requests
        SET function_response=:function_response, permissions_response=:permissions_response
        WHERE gsi_request_id=:request_id
    }
  
    return true
}

ad_proc -public imsld::gsi::get_request_response {
    -request_id
} {
    Returns a list with the response of a given request. Functions_response is in index 0, permissions in index 1
} {
    if { [db_0or1row get_request_response { 
            SELECT function_response, permissions_response
            FROM imsld_gsi_service_requests
            WHERE gsi_request_id=:request_id } ] 
    } {
        return [list $function_response $permissions_response]
    } else {
        return [list "" ""]
    }
}

ad_proc -public imsld::gsi::get_function_request_values {
    -gservice_id
} {
    Builds a list containing function requirements information of a given service.
} {
    set functions [list [list "deploy" {}] [list "close" {}]]
    return $functions
}

ad_proc -public imsld::gsi::get_permission_request_values {
    -gservice_id
} {
    Builds a list containing function requirements information of a given service.
} {
    set permissions [list [list "read" "contribution" "user"] [list "write" "context" {} ] ]
    return $permissions
}

ad_proc -public imsld::gsi::register_plugin {
    -plugin_string_id
    -plugin_URI
} {
    Fills the imsld_gsi_plugins table. Each time a plugin is installed, this procedure must be called to insert a new row. The plugin_string_id is used as short name for plugins, for folder names of procedure names.
        
    It can happen that a service retrieved from the registry uses a plugin that is not in the table. In this case, the plugin must be installed (otherwise, the service won't work properly).
} {
    db_dml insert_plugin {
        INSERT INTO imsld_gsi_plugins VALUES (:plugin_string_id,:plugin_URI);
    }
}

ad_proc -public imsld::gsi::get_plugin_identifier {
    -plugin_URI
} {
    Given a plugin_URI, returns its corresponding identifier or empty string if nothing found.
} {
    set return_value [db_string get_plugin_identifier {SELECT plugin_string_id FROM imsld_gsi_plugins where plugin_uri=:plugin_URI} -default  ""]
        return $return_value
}


ad_proc -public imsld::gsi::initialize_check_request {
    -gservice_id
    -plugin_URI
    -run_id
} { 
    Inserts a row in the imsld_gsi_service_requests table, without filling the response fields.
} {
    #check if the plugin is registered
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_URI]
    if {[string eq $plugin_string_id ""]} {
         ns_log Notice "no existe plugin, algo habrá que hacer"
        return
    }

    #get the serv_status_id
    set serv_status_id [db_string get_status_id {
        SELECT service_status_id
        FROM imsld_gsi_service_status
        WHERE owner_id=:gservice_id and run_id=:run_id
    }]

    #insert the request (if not exists) in tables...
    if { ![db_0or1row is_already_inserted {
        select 1 from imsld_gsi_service_requests where serv_status_id=:serv_status_id and plugin_URI=:plugin_URI
    }] } {
        set gsi_request_id [db_nextval acs_object_id_seq]
        db_dml initialize_request {
            INSERT 
            INTO imsld_gsi_service_requests 
            VALUES ( :gsi_request_id, :serv_status_id, :plugin_URI, '','', now() )
        }
    }
}

ad_proc -public imsld::gsi::get_roles_with_permissions {
    -gservice_id
    -data_type
    -action
} {
    Returns a list with all the roles that takes a pair of action-data_type permission in a given service
} {
    return [db_list  get_admin_role {
        select r.object_id
        from imsld_gsi_servicesi serv,
             acs_rels ar, 
             imsld_rolesi r, 
             imsld_gsi_groupsi g, 
             imsld_gsi_permissions p 
        where p.action=:action and 
              p.data_type=:data_type and 
              g.gsi_service_id=serv.item_id and 
              g.gsi_group_id=p.holder_id and 
              ar.object_id_one=g.item_id and 
              r.item_id=ar.object_id_two and 
              serv.gsi_service_id=:gservice_id
   }]
}







#methods that must be implemented by all plugins
#################################################


ad_proc -public imsld::gsi::send_check_request {
    -gservice_id
    -plugin_URI
    -run_id
} {
    Sends a check-request to the service, in order to ask for functionality support
    @param gservice_id "The service that needs to be configured"
    @param plugin_URI "The plugin that manages the request"
    @param run_id "since a service can request from several runs, the run_id provides identification completeness."

    @return a list of service capabilities 
} {
    #build parameters to check (functions and permissions)
    set request_functions [imsld::gsi::get_function_request_values -gservice_id $gservice_id]
    set request_permissions [imsld::gsi::get_permission_request_values -gservice_id $gservice_id]

    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_URI]

    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return [list]
    }
    set procedure_name "imsld::gsi::${plugin_namespace}::send_check_request \$request_functions \$request_permissions"

    #insert or replace row
    set serv_status_id [db_string get_status_id {
        SELECT service_status_id
        FROM imsld_gsi_service_status
        WHERE owner_id=:gservice_id and run_id=:run_id
    }]

    if {[db_0or1row is_already_requested {
            select gsi_request_id 
            from imsld_gsi_service_requests 
            where serv_status_id=:serv_status_id and 
                  plugin_uri=:plugin_URI
    }]} {
        #replace row
        db_dml update_request {
            UPDATE imsld_gsi_service_requests 
            SET last_modified=now(), 
                function_response='', 
                permissions_response=''
            WHERE plugin_uri=:plugin_URI and
                  serv_status_id=:serv_status_id
        }
    } else {
        #insert the request (no answer yet) in tables...
        set gsi_request_id [db_nextval acs_object_id_seq]
        db_dml initialize_request {
            INSERT 
            INTO imsld_gsi_service_requests 
            VALUES ( :gsi_request_id, :serv_status_id, :plugin_URI, '','', now() )
        }
    }

    #eval the procedure
    set plugin_response [eval $procedure_name]
    set composed_response [linsert $plugin_response 0 $gsi_request_id]

#composed_respose[0] = request identifier
#composed_respose[1] = functions response 
#composed_respose[2] = permissions response
    #return method response
    return $composed_response
}

#the following method is done with the list returned by "send_check_request", it is not plugin business
#ad_proc -public imsld::gsi::store_service_response {
#    -gservice_id
#    -plugin_URI
#    -run_id


ad_proc -public imsld::gsi::request_configured_instance {
    -gservice_id
    -plugin_URI
    -run_id
    -user_id
} { 
    Once a service has been chosen and users mapped, request URL of a given user.
    @param gservice_id "The service that needs to be configured"
    @param plugin_URI "The plugin that manages the request"
    @param run_id "since a service can request from several runs, the run_id provides identification completeness."
    @param user_id "The user of the instance"

    @return The url of the instance.
} {
    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_URI]

    #check for correctness
    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return ""
    }

    #build and eval procedure name

    set procedure_name "imsld::gsi::${plugin_namespace}::request_configured_instance -run_id \$run_id -user_id \$user_id -gservice_id $gservice_id"
    set configured_instance [eval $procedure_name]

    return $configured_instance
}


#the following method is done with the URL returned by "request_configured_instance", it is not plugin business
#ad_proc -public imsld::gsi::store_configured_instance {
#    -gservice_id
#    -plugin_URI
#    -run_id

ad_proc -public imsld::gsi::get_external_user {
    -plugin_URI
    -run_id
    -user_id
} {
    Returns username from an external service that a given user is related to. If no user found, returns empty string
    This procedure just redirect to a proper plugin

    @param plugin_URI "The plugin that manages the request"
    @param run_id "since a service can request from several runs, the run_id provides identification completeness."
    @param user_id "The user of the instance"

} {
    set external_username ""

    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_URI]

    #check for correctness
    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return ""
    }

    #build and eval procedure name
    set procedure_name "imsld::gsi::${plugin_namespace}::get_external_user -run_id \$run_id -user_id \$user_id"
    set external_username [eval $procedure_name]

    return $external_username
}

ad_proc -public imsld::gsi::get_external_credentials {
    -plugin_URI
    -run_id
    -user_id
} {
    Returns credentials from an external service that a given user is related to. If no user found, returns empty string
    This procedure just redirect to a proper plugin

    @param plugin_URI "The plugin that manages the request"
    @param run_id "since a service can request from several runs, the run_id provides identification completeness."
    @param user_id "The user of the instance"

} {
    set external_credentials ""

    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_URI]

    #check for correctness
    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return ""
    }

    #build and eval procedure name
    set procedure_name "imsld::gsi::${plugin_namespace}::get_external_credentials -run_id \$run_id -user_id \$user_id"
    set external_credentials [eval $procedure_name]

    return $external_credentials
}


ad_proc -public imsld::gsi::map_user {
    -plugin_URI
    -run_id
    -user_id
    -external_user
    -external_credentials
} {
    Map a user with a corresponding external service user. Additionally, a password is provided (OpenAuth is just a good idea today)
    @param plugin_URI "The plugin that manages the request"
    @param run_id "since a service can request from several runs, the run_id provides identification completeness."
    @param user_id "The user of the instance"
    @param external_user "The external user to do the mapping"
    @param external_credentials "If required, the external pass to access service"

    @return boolean
} {
    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_URI]

    #check for correctness
    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return ""
    }

    #build procedure name
    set procedure "imsld::gsi::${plugin_namespace}::map_user -run_id \$run_id -user_id \$user_id"
    #build parameters
    if {![info exists external_user] && ![info exists external_credentials]} {
        set parameters ""
    } elseif {[info exists external_user] && ![info exists external_credentials]} {
        set parameters "-external_user $external_user"
    } elseif {![info exists external_user] && [info exists external_credentials]} {
        set parameters "-external_credentials $external_credentials"
    } else {
        set parameters "-external_user $external_user -external_credentials $external_credentials"
    }

    set procedure_name [concat $procedure $parameters]
    eval $procedure_name

    return
}


ad_proc -public imsld::gsi::initialize_user {
    -plugin_URI
    -run_id
    -user_id
} {
    Initializes a user mapping with a corresponding external service user
    @param plugin_URI "The plugin that manages the request"
    @param run_id "since a service can request from several runs, the run_id provides identification completeness."
    @param user_id "The user of the instance"

} {
    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_URI]

    #check for correctness
    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return ""
    }

    #build and eval procedure name
    set procedure_name "imsld::gsi::${plugin_namespace}::initialize_user -run_id \$run_id -user_id \$user_id"
    eval $procedure_name

    return
}



ad_proc -public imsld::gsi::perform_startup_actions {
    -plugin_URI
    -run_id
    -gservice_id
    -multiplicity
    -startup_actions
} {
    Perform the startup-actions of a given service. That is, deploy and (if required) set initial values. The meaning
    of each of these verbs depends on the handler plugin

    @param plugin_URI "The plugin that manages the request"
    @param run_id "since a service can request from several runs, the run_id provides identification completeness."
    @param gservice_id "The service_id to be configured"

} {
    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_URI]

    #check for correctness
    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return ""
    }
#    set startup_actions [imsld::gsi::get_service_startup_actions -gservice_id $gservice_id]
    #build and eval procedure name
    set procedure_name "imsld::gsi::${plugin_namespace}::perform_startup_actions -gservice_id \$gservice_id -run_id \$run_id -startup_actions \$startup_actions -multiplicity \$multiplicity"
    eval $procedure_name

    return
}

ad_proc -public imsld::gsi::action_list_execute {
    -plugin_URI
    -run_id
    -gservice_id
    -multiplicity
    -actions
} {
    Perform a list of actions in a given service. The meaning of the actions depends on the handler plugin

    @param plugin_URI "The plugin that manages the request"
    @param run_id "since a service can request from several runs, the run_id provides identification completeness."
    @param gservice_id "The service_id to be configured"

} {
    if {![info exists gservice_id]} {
        #FIXME:we can obtain gservice_id because all of them belongs to the same service, obviously there's only one service
        #what happens when more than a service appear?
        #just an idea (I have no time to think more on this): a db_list and a foreach can solve the problem
        db_1row get_service_id "select s.gsi_service_id as gservice_id
                                from imsld_gsi_services s,
                                     imsld_gsi_funct_usage fu
                                where s.gsi_constraint_id=fu.gsi_constraint_id and
                                      fu.gsi_funct_usage_id in ([template::util::tcl_to_sql_list $actions])
                                group by gservice_id"
    }

    if {![info exists multiplicity]} {
        db_1row get_service_multiplicity {
            select c.multiplicity as multiplicity 
            from imsld_gsi_services s, 
                 imsld_gsi_constraintsi c 
            where c.item_id=s.gsi_constraint_id and
                  s.gsi_service_id=:gservice_id
        }
    }

    if {![info exists plugin_URI]} {
        db_1row get_plugin_URI {
            select plugin_uri as plugin_URI 
            from imsld_gsi_service_status
            where owner_id=:gservice_id and
                  run_id=:run_id
        }
    }
    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_uri]

    #check for correctness
    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return ""
    }
    #build and eval procedure name
    set procedure_name "imsld::gsi::${plugin_namespace}::action_list_execute -gservice_id \$gservice_id -run_id \$run_id -actions \$actions -multiplicity \$multiplicity"
    eval $procedure_name
}


ad_proc -public imsld::gsi::get_external_value {
    -plugin_URI
    -run_id:required
    -gservice_id
    -multiplicity
    -node:required
    -user_id
} {
    Receive a node external-value dom node and a run_id and call the proper plugin to obtain the value from the service.
    The meaning of the attributes depends on the handler plugin
} {
    if {![info exists user_id]} {
        set user_id [ad_conn user_id]
    }
    if {![info exists gservice_id]} {
        #Given the serviceref, whe can obtain the service_id, since we also have the run_id
        #Note: there can be more than one service with the same identifier (form different UoLs),
        #      so the run_id is used to guarantee uniqueness
        set services_in_run [imsld::gsi::get_services_in_run -run_id $run_id]
        if {[llength $services_in_run]} {
            db_1row get_service_id "select gsi_service_id as gservice_id 
                                    from imsld_gsi_services 
                                    where identifier='assessment-service' and 
                                          gsi_service_id in ([template::util::tcl_to_sql_list $services_in_run])"
        }
    }

    if {![info exists multiplicity]} {
        db_1row get_service_multiplicity {
            select c.multiplicity as multiplicity 
            from imsld_gsi_services s, 
                 imsld_gsi_constraintsi c 
            where c.item_id=s.gsi_constraint_id and
                  s.gsi_service_id=:gservice_id
        }
    }

    if {![info exists plugin_URI]} {
        db_1row get_plugin_URI {
            select plugin_uri as plugin_URI 
            from imsld_gsi_service_status
            where owner_id=:gservice_id and
                  run_id=:run_id
        }
    } else {
        set plugin_uri $plugin_URI
    }
    
    #based on the plugin, build the name of the procedure to be called
    set plugin_namespace "p_"
    set plugin_string_id [imsld::gsi::get_plugin_identifier -plugin_URI $plugin_uri]

    #check for correctness
    if {![string eq $plugin_string_id ""]} {
        append plugin_namespace $plugin_string_id
    } else {
        ns_log Notice "no existe plugin, algo habrá que hacer"
        return ""
    }
    #build and eval procedure name
    set procedure_name "imsld::gsi::${plugin_namespace}::get_external_value -gservice_id \$gservice_id -run_id \$run_id -node \$node -multiplicity \$multiplicity -user_id $user_id"
    eval $procedure_name
} 
