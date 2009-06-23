# ad_page_contract {
#
#    @author lfuente@it.uc3m.es
#    @creation-date dic 2008
#} {
#    gservice_id
#}

#FIXME: a sql query inside a procedure must build these values
set functions [imsld::gsi::get_function_request_values -gservice_id $gservice_id]
set permissions [imsld::gsi::get_permission_request_values -gservice_id $gservice_id]

template::multirow create requested_functions item
foreach function_item $functions {
    template::multirow append requested_functions $function_item
}

template::multirow create requested_permissions item
foreach perm_item $permissions {
    template::multirow append requested_permissions $perm_item
}



