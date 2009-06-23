# ad_page_contract {
#    @author lfuente@it.uc3m.es
#    @creation-date dic 2008
#} {
#    gservice_id
#    run_id
#    plugin_URI:optional
#    {mapped_p "f"}
#} 
if {![info exists mapped_p]} {
    set mapped_p "f"
}
if {[string eq $mapped_p "t"]} {
    set mapped 0
    set to_map 1
} else {
    set mapped 1
    set to_map 0
}

set users_in_run [imsld::runtime::users_in_run -run_id $run_id]
template::multirow create users_in_run user_id username external_user user_form external_credentials credentials_form get_token
foreach user $users_in_run {
    set username [acs_user::get_element -user_id $user -element name]
    set external_user [imsld::gsi::get_external_user -user_id $user -plugin_URI $plugin_URI -run_id $run_id]
    set external_credentials [imsld::gsi::get_external_credentials -user_id $user -plugin_URI $plugin_URI -run_id $run_id]
#CAUTION!! building HTML code inside tcl files!! It brokes some design rules, but is the only way to include a form as column in a template::list 
#######
    set user_form "<form name=\"ext_user_form\" action=\"imsld-gsi-mapuser\" method=\"get\">\n
                   <input type=\"text\" name=\"external_user\" value=\"$external_user\">\n
                   <input type=\"hidden\" name=\"user_id\" value=\"$user\">\n
                   <input type=\"hidden\" name=\"run_id\" value=\"$run_id\">\n
                   <input type=\"hidden\" name=\"plugin_URI\" value=\"$plugin_URI\">\n
                   <input type=\"hidden\" name=\"return_url\" value=\"imsld-gsi-service-configure?run_id=$run_id&gservice_id=$gservice_id\">\n
                   <input type=\"submit\" value=\"OK\">\n
                   </form>"
    set credentials_form "<form name=\"ext_credentials_form\" action=\"imsld-gsi-mapuser\" method=\"get\">\n
                   <input type=\"password\" name=\"external_credentials\" value=\"$external_credentials\">\n
                   <input type=\"hidden\" name=\"user_id\" value=\"$user\">\n
                   <input type=\"hidden\" name=\"run_id\" value=\"$run_id\">\n
                   <input type=\"hidden\" name=\"plugin_URI\" value=\"$plugin_URI\">\n
                   <input type=\"hidden\" name=\"return_url\" value=\"imsld-gsi-service-configure?run_id=$run_id&gservice_id=$gservice_id\">\n
                   <input type=\"submit\" value=\"OK\">\n
                   </form>"

set package_id [ad_conn package_id]
set package_mount_point [apm_package_url_from_id $package_id]

ns_log Notice "user: $user"
set next_params "%3Frun_id%3D$run_id%26user_id%3D$user%26gservice_id%3D$gservice_id%26plugin_URI%3D$plugin_URI"
set next_value "[util_current_location]/$package_mount_point/admin/gsi/imsld-gsi-handle-token$next_params"
set token_url "https://www.google.com/accounts/AuthSubRequest?scope=http://docs.google.com/feeds/ http://spreadsheets.google.com/feeds/&session=1&secure=0&next=$next_value"
set get_token_url "<a href=\"$token_url\">Try this user</a>"
#######
#######

    template::multirow append users_in_run $user $username $external_user $user_form $external_credentials $credentials_form $token_url 
ns_log Notice "get_token_url: $get_token_url"
}

template::list::create \
    -name users_in_run \
    -multirow users_in_run \
    -key user_id \
    -elements {
        username {
            label "Username"
        }
        external_user {
            label "Username in service"
            hide_p $mapped
        }
        user_form {
            label "Username in service"
            display_template $user_form
            hide_p $to_map
        }
        external_credentials {
            label "Credentials in service"
            hide_p $mapped
        }
        credentials_form {
            label "Credentials in service"
            display_template $credentials_form
            hide_p $to_map
        }
        get_token {
            label "Auto-fill"
            link_url_col get_token
            display_template "Try this user"
            hide_p $to_map
        }
    }


