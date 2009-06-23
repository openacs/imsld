ad_page_contract {

    Presents the results of a registry search with the describing keywords for a given service
    
    @author lfuente@it.uc3m.es
    @creation-date nov 2008
} {
    {gservice_id}
    {run_id}
}

set return_addr [export_vars -base imsld-gsi-serviceslist {gservice_id run_id}]

#this is worth to be set as package parameter, but meanwhile...
set registry_address [parameter::get -parameter "GSIRegistryURL"]
set registry_port [parameter::get -parameter "GSIRegistryPort"]

set page_title "IMS LD Service search results"
set context [list "Search results"]
template::head::add_css -href "/resources/imsld/imsld.css" -media "screen" -order 0


#find service keywords: service->tool->keywords
set keywords_list [db_list find_service_keywords {
    select key.value 
    from imsld_gsi_services serv, 
         imsld_gsi_toolsi tool, 
         imsld_gsi_keywordsi key, 
         acs_rels ar 
    where serv.gsi_tool_id=tool.item_id and 
          key.item_id=ar.object_id_one and 
          tool.item_id=ar.object_id_two and 
          serv.gsi_service_id=:gservice_id;
}]

set keywords_string [join $keywords_list ","]


#lookup in the registry (open a socket and send a basic TCP package)
set fds [ns_sockopen -nonblock $registry_address $registry_port]
set rid [lindex $fds 0]
set wid [lindex $fds 1]
if [ns_sockcheck $wid] {
    set connected_p "t"
    imsld::gsi::change_service_status -gservice_id $gservice_id -run_id $run_id -status "not-configured"

    puts $wid "LOOKUP $keywords_string"
    flush $wid
    set results [read $rid]
    close $rid
    close $wid

    #present results (template::list::create)
    set services_list [list]
    set temp_list [split $results '\n']

    #create the multirow
    template::multirow create lookup_results_multirow name plugin description config_disp config_url

    foreach service $temp_list {

        set service_result [split $service '|']

        set name [lindex $service_result 0]
        set plugin_URI [lindex $service_result 1]
        set description [lindex $service_result 2]
        set config_disp "Try it"
        set config_url [export_vars -base "imsld-gsi-service-configure" {gservice_id run_id plugin_URI} ] 

        #add data in the multirow
        template::multirow append lookup_results_multirow $name $plugin_URI $description $config_disp $config_url
   }

    template::list::create \
        -name lookup_results \
        -multirow lookup_results_multirow \
        -key plugin \
        -elements {
            name {
                label "Service Name" 
            }
            description {
                label "Description" 
            }
            plugin_URI {
                label ""
                display_col config_disp
                link_url_col config_url
            }
        }
} else {
    set connected_p "f"
    imsld::gsi::change_service_status -gservice_id $gservice_id -run_id $run_id -status "not-found"
}

