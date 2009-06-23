ad_page_contract {

    Presents a list of external services to setup before running the UoL.
    
    @author lfuente@it.uc3m.es
    @creation-date nov 2008
} {
    {run_id}
}

set page_title "IMS LD Services in UoL"
set context [list "Services in UoL"]
template::head::add_css -href "/resources/imsld/imsld.css" -media "screen" -order 0

set action_disp ""
set action_url ""
set action_text ""

template::list::create \
        -name serviceslist \
        -multirow gservices_in_run \
        -key gservice_id \
        -elements {
            service_title {
                label "Name"
            }
            tool {
                label "Tool"
            }
            status {
                label "Status"
            }
            action_url {
                label "Action"
                display_col action_disp
                link_url_col action_url
                link_html {title "$action_disp"}
            }
        }

db_multirow -extend {action_url action_disp} gservices_in_run get_services_info { 
    select serv.gsi_service_id as gservice_id,
           serv.title as service_title,
           tools.gsi_tool_id,
           tools.title as tool,
           tools.description, 
           stat.status 
    from imsld_gsi_service_status stat, 
         imsld_gsi_servicesi serv, 
         imsld_gsi_toolsi tools 
    where stat.run_id=:run_id and 
          serv.gsi_tool_id=tools.item_id and 
          stat.owner_id=serv.gsi_service_id;
} {
    if {[string eq $status "not-configured"]} {
        set action_url [export_vars -base "imsld-gsi-service-search-results" {gservice_id $gservice_id run_id $run_id} ]
        set action_disp "Configure"
    } elseif {[string eq $status "not-found"]} {
        set action_url [export_vars -base "imsld-gsi-service-search-results" {gservice_id $gservice_id run_id $run_id} ] 
        set action_disp "Try again"
    } elseif {[string eq $status "chosen"] || [string eq $status "mapped"] } {
        set action_url [export_vars -base "imsld-gsi-service-configure" {gservice_id $gservice_id run_id $run_id} ] 
        set action_disp "View Progress"
    } elseif {[string eq $status "configured"]} {
        set action_url [export_vars -base "imsld-gsi-service-configure" {gservice_id $gservice_id run_id $run_id} ] 
        set action_disp "View configuration"
    }
}



