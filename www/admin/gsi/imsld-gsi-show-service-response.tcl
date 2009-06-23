##ad_page_contract {
#    @author lfuente@it.uc3m.es
#    @creation-date dic 2008
#} {
#    gservice_id
#    run_id
#    plugin_URI
#    gsi_request_id:optional
#}
if { ![info exists gsi_request_id] } {
    set gsi_request_id [db_string get_request_id {
        SELECT req.gsi_request_id 
        FROM imsld_gsi_service_requests req, 
             imsld_gsi_service_status stat 
        WHERE stat.service_status_id=req.serv_status_id and 
              stat.run_id=:run_id and 
              stat.owner_id=:gservice_id and 
              req.plugin_uri=:plugin_URI
    }]
}
set request_response [imsld::gsi::get_request_response -request_id $gsi_request_id]

set functions_response [lindex $request_response 0]
set permissions_response [lindex $request_response 1]

template::multirow create response_functions item
foreach function_item $functions_response {
template::multirow append response_functions $function_item
}

template::multirow create response_permissions item
foreach perm_item $permissions_response {
template::multirow append response_permissions $perm_item
}

