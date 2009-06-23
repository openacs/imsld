 ad_page_contract {

    Use a proper plugin to configure a service
    @author lfuente@it.uc3m.es
    @creation-date dic 2008
} {
    gservice_id
    run_id
    {plugin_URI ""}
    gsi_request_id:optional
    {do_check_p "f"}
    {do_choose_p "f"}
    {do_map_p "f"}
    {do_configure_p "f"}
}
set page_title "IMS LD Service configuration"
set context [list "Service configuration"]
template::head::add_css -href "/resources/imsld/imsld.css" -media "screen" -order 0

#first, perform action (if requested)

if {[string eq $do_check_p "t"]} {
    #FIXME: ¿en un thread a parte?

#    ns_schedule_proc -thread -once 0 
    imsld::gsi::initialize_check_request -gservice_id $gservice_id -plugin_URI $plugin_URI -run_id $run_id
    
    util_background_exec -pass_vars {gservice_id plugin_URI run_id} -name "check_in_background" {
            ns_sleep 3
            set service_response [imsld::gsi::send_check_request -gservice_id $gservice_id -plugin_URI $plugin_URI -run_id $run_id]
            imsld::gsi::store_check_results -gservice_id $gservice_id -run_id $run_id -service_response $service_response
    } 

}
if {[string eq $do_choose_p "t"]} {
    set users_in_run [imsld::runtime::users_in_run -run_id $run_id] 
    foreach user_id $users_in_run {
        imsld::gsi::initialize_user -plugin_URI $plugin_URI -run_id $run_id -user_id $user_id
    }
    db_dml update_plugin {
        UPDATE imsld_gsi_service_status
        SET plugin_uri=:plugin_URI
        WHERE run_id=:run_id and owner_id=:gservice_id
    }
    imsld::gsi::change_service_status -gservice_id $gservice_id -run_id $run_id -status "chosen"
}
if {[string eq $do_map_p "t"]} {
    imsld::gsi::change_service_status -gservice_id $gservice_id -run_id $run_id -status "mapped"
}
if {[string eq $do_configure_p "t"]} {
    if { ![string eq [imsld::gsi::get_service_status -run_id $run_id -gservice_id $gservice_id] "configured"]} {
        set startup_actions [imsld::gsi::get_service_startup_actions -gservice_id $gservice_id]
        set multiplicity [imsld::gsi::get_service_multiplicity -gservice_id $gservice_id]

        imsld::gsi::perform_startup_actions -run_id $run_id \
                                            -gservice_id $gservice_id \
                                            -startup_actions $startup_actions \
                                            -plugin_URI $plugin_URI \
                                            -multiplicity $multiplicity

        if {![db_0or1row is_service_set {
            select 1 as ready
            from imsld_gsi_p_gspread_usersmap
            where run_id=:run_id
                  and spreadsheet_url is null
            group by ready
        }]} {
            set users_in_service [imsld::gsi::get_users_in_service -gservice_id $gservice_id -run_id $run_id] 
            foreach user_id $users_in_service {
                set service_URL [imsld::gsi::request_configured_instance -user_id $user_id -plugin_URI $plugin_URI -run_id $run_id -gservice_id $gservice_id]
                set instance_id [db_string get_instance_id {
                                               select att.instance_id 
                                               from imsld_attribute_instances att
                                               where att.run_id=:run_id and 
                                                     att.owner_id=:gservice_id and 
                                                     att.user_id=:user_id 
                }]
                foreach url_pair $service_URL {
                    set url [lindex $url_pair 1]
                    set url_title [lindex $url_pair 0]
                    db_dml insert_url {INSERT INTO imsld_gsi_serv_instances VALUES (:instance_id, :url, :url_title)}
                }
            }

            imsld::gsi::change_service_status -gservice_id $gservice_id -run_id $run_id -status "configured"

            #cuando todo esté en orden, hay que marcar el run como activo, pero sólo si no quedan más 
            #servicios por configurar
            set remaining_services_p [db_0or1row get_services_in_run { 
                select count(*)
                from imsld_gsi_service_status stat, 
                     imsld_gsi_servicesi serv, 
                     imsld_gsi_toolsi tools 
                where stat.run_id=:run_id and 
                      serv.gsi_tool_id=tools.item_id and 
                      stat.owner_id=serv.gsi_service_id and
                      stat.status!='configured';
            }]

            if {$remaining_services_p == 0} {
                db_dml set_run_active { 
                    update imsld_runs set status = 'active',
                    status_date = now()
                    where run_id=:run_id and imsld_id=:imsld_id
                }
            } else {
                db_dml set_run_waitingservices { 
                    update imsld_runs set status = 'waitingservices',
                    status_date = now()
                    where run_id=:run_id and imsld_id=:imsld_id
                }
            }

            db_dml set_run_active { 
                update imsld_runs set status = 'active',
                status_date = now()
                where run_id=:run_id
            }
        }
    }
}

#second, choose state
set service_status [imsld::gsi::get_service_status -run_id $run_id -gservice_id $gservice_id]
if { [string eq $service_status "not-configured"] } {
    if {[db_0or1row get_request_id {
        select req.gsi_request_id 
        from imsld_gsi_service_status stat, 
             imsld_gsi_service_requests req 
        where req.serv_status_id=stat.service_status_id and 
              stat.run_id=:run_id and 
              stat.owner_id=:gservice_id and 
              req.plugin_URI=:plugin_URI
    }]} {
       set state "checked"
    } else {
       set state "unchecked"
    }
} elseif { [string eq $service_status "chosen"] } {
    set state "chosen"
} elseif {[string eq $service_status "mapped"]} {
    set state "mapped"
} elseif { [string eq $service_status "configured"] } {
    set state "configured"
} else {
    #you cannot be here...
}



#then go to this state
switch $state {
    unchecked {
        set check_button [export_vars -base "imsld-gsi-service-configure" {plugin_URI gservice_id run_id {do_check_p "t"}}]
        set back_button [export_vars -base "imsld-gsi-service-search-results" {gservice_id run_id}]
    }
    checked {
        set refresh_button [export_vars -base "imsld-gsi-service-configure" {plugin_URI gservice_id run_id}]
        set choose_button [export_vars -base "imsld-gsi-service-configure" {plugin_URI gservice_id run_id {do_choose_p "t"}}]
        set back_button [export_vars -base "imsld-gsi-service-search-results" {gservice_id run_id}]
    }
    chosen {
        set plugin_URI [db_string get_status_plugin {
            select plugin_uri 
            from imsld_gsi_service_status 
            where run_id =:run_id and 
                  owner_id=:gservice_id
        } ]
        set map_button [export_vars -base "imsld-gsi-service-configure" {plugin_URI gservice_id run_id {do_map_p "t"}}]
    }
    mapped {
        set plugin_URI [db_string get_status_plugin {
            select plugin_uri 
            from imsld_gsi_service_status 
            where run_id =:run_id and 
                  owner_id=:gservice_id
        } ]
        set configure_button [export_vars -base "imsld-gsi-service-configure" {plugin_URI gservice_id run_id {do_configure_p "t"}}]
    }
    configured {
        set plugin_URI [db_string get_status_plugin {
            select plugin_uri 
            from imsld_gsi_service_status 
            where run_id =:run_id and 
                  owner_id=:gservice_id
        } ]

        set still_waiting_p "t"
        if {![db_0or1row is_still_waiting_p {
            SELECT 1 as nothing 
            FROM imsld_attribute_instances att, 
                 imsld_gsi_serv_instances serv 
            WHERE att.instance_id=serv.service_instance_id and 
                  att.owner_id=:gservice_id and 
                  att.run_id=:run_id and 
                  url='' 
            GROUP BY nothing;
        }] } {
            set still_waiting_p "f"
        }
    }
}


