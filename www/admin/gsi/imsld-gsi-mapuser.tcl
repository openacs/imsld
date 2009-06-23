#imsld-gsi-mapuser.tcl
ad_page_contract {
    @author lfuente@it.uc3m.es
    @creation-date dic 2008
} {
    return_url
    user_id
    run_id
    plugin_URI
    external_user:optional
    external_credentials:optional
}

#imsld::gsi::map_user
if {[info exists external_user] && [info exists external_credentials]} {
    imsld::gsi::map_user -user_id $user_id -run_id $run_id -external_user $external_user -external_credentials $external_credentials -plugin_URI $plugin_URI
} elseif {[info exists external_user] && ![info exists external_credentials]} {
    imsld::gsi::map_user -user_id $user_id -run_id $run_id -external_user $external_user -plugin_URI $plugin_URI
} elseif {![info exists external_user] && [info exists external_credentials]} {
    imsld::gsi::map_user -user_id $user_id -run_id $run_id -external_credentials $external_credentials -plugin_URI $plugin_URI
}

ad_returnredirect $return_url
