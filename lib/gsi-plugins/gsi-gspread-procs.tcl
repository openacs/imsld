ad_library {
    Procedures of the gspread gsi plugin.
    
    @creation-date Apr 2009
    @author lfuente@it.uc3m.es
}

namespace eval imsld {}
namespace eval imsld::gsi {}

#each plugin with its own namespace. All plugins has the same public procedures.
namespace eval imsld::gsi::p_gspread {}

##########################################################
##########################################################
# google spreadsheet plugin
ad_proc -public imsld::gsi::p_gspread::send_check_request {
   functions
   permissions
} {
    
} {
    #fixme: this must be done with real requests to the service
    return [list \
                   [list \
                            [list "deploy" {}] \
                            [list "close" {}]] \
                   [list \
                            [list "write" "contribution" "user"] \
                            [list "read" "context" {}] ] ]
}
 


ad_proc -public imsld::gsi::p_gspread::get_external_credentials {
    -user_id
    -run_id
} {
    Returns the external credentials for a given user, in a given instance
} {
	ns_log Notice "user_id:$user_id, run_id:$run_id"
    return [db_string get_credentials {
               SELECT external_credentials 
               FROM imsld_gsi_p_gspread_usersmap
               WHERE user_id=:user_id and run_id=:run_id
           } -default "" ]
} 


ad_proc -public imsld::gsi::p_gspread::get_external_user {
    -user_id
    -run_id
} {
    Returns the external username for a given user, in a given instance
} {
    return [db_string get_username {
               SELECT external_user 
               FROM imsld_gsi_p_gspread_usersmap
               WHERE user_id=:user_id and run_id=:run_id
           } -default "" ]
} 

ad_proc -public imsld::gsi::p_gspread::initialize_user {
    -user_id 
    -run_id
} {
   Initializes a user in the external service mapping table. That is, insert an unmapped row 
} {
    db_dml isert_user {
        INSERT INTO imsld_gsi_p_gspread_usersmap VALUES (:user_id,:run_id,'void','void')
    }
} 

ad_proc -public imsld::gsi::p_gspread::map_user {
    -user_id
    -run_id
    -external_user
    -external_credentials
} {
    Do de mapping between a .LRN user and the externall user
} {
   if {![info exists external_user] && ![info exists external_credentials]} {
        return 
    } elseif {[info exists external_user] && ![info exists external_credentials]} {
        db_dml map_user {
            UPDATE imsld_gsi_p_gspread_usersmap
            SET external_user=:external_user
            WHERE user_id=:user_id and run_id=:run_id
        }
    } elseif {![info exists external_user] && [info exists external_credentials]} {
        db_dml map_user {
            UPDATE imsld_gsi_p_gspread_usersmap
            SET external_credentials=:external_credentials
            WHERE user_id=:user_id and run_id=:run_id
        }
    } else {
        db_dml map_user {
            UPDATE imsld_gsi_p_gspread_usersmap
            SET external_user=:external_user, 
                external_credentials=:external_credentials
            WHERE user_id=:user_id and run_id=:run_id
        }
    }
} 

ad_proc -public imsld::gsi::p_gspread::request_configured_instance {
    -user_id
    -run_id
    -gservice_id
    -external_user
    -external_credentials
} {
    Returns a list of lists with URL and title to access each facility in the service instance of a given user
} {
    set all_urls [list]
    #right now, urls are static. This fact must be changed, but, by now, let's define them statically
    set package_id [ad_conn package_id]
    set mount_point "[ad_conn location][apm_package_url_from_id $package_id]/gsi/gspread"
#in this plugin, user_id and external_credentials can be obtained in the following urls, it does not make
#sense to send them
    set configure_url [list "Configuration" "$mount_point/imsld-gspread-configure?run_id=$run_id&gservice_id=$gservice_id"]
    set form_url [list "Questionnaire" "$mount_point/imsld-gspread-view-form?run_id=$run_id&gservice_id=$gservice_id"]
    set spreadsheet_url [list "View Responses" "$mount_point/imsld-gspread-spreadsheet?run_id=$run_id&gservice_id=$gservice_id"]

    #urls are assigned depending on the permissions the user hold. Let's check them.

    #FIXME: only one role per user is supported by now. Must to be changed.
    #1- obtain user's role in this run
    set user_role [imsld::roles::get_user_roles -user_id $user_id -run_id $run_id]

    #2- obtain roles' group in this run
    #NOTE: only one group per role (see schema for details)
    set user_group [imsld::gsi::get_group_from_role -role_id $user_role -gservice_id $gservice_id]

    #3- obtain group's permissions
    set permissions_set [imsld::gsi::get_group_permissions -group_id $user_group]


    #4- assign urls depending on obtained permissions
    
    foreach permission $permissions_set {
        #4.1 about context
        if { [string eq [lindex $permission 1] "context"]} {
            switch [lindex $permission 0] {
                "admin" {
                    if {[lsearch $all_urls $configure_url] == "-1"} {lappend all_urls $configure_url } 
                    if {[lsearch $all_urls $form_url] == "-1"} {lappend all_urls $form_url } 
                    if {[lsearch $all_urls $spreadsheet_url] == "-1"} {lappend all_urls $spreadsheet_url } 
                }
                "write" {
                    if {[lsearch $all_urls $form_url] == "-1"} {lappend all_urls $form_url } 
                    if {[lsearch $all_urls $spreadsheet_url] == "-1"} {lappend all_urls $spreadsheet_url } 
                }
                "read" {
                    if {[lsearch $all_urls $form_url] == "-1"} {lappend all_urls $form_url } 
                }
            }
        } 

        #4.2 about contributtion
        if { [string eq [lindex $permission 1] "contribution"]} {
            switch [lindex $permission 0] {
                "admin" {
                    if {[lsearch $all_urls $form_url] == "-1"} {lappend all_urls $form_url } 
                    if {[lsearch $all_urls $spreadsheet_url] == "-1"} {lappend all_urls $spreadsheet_url } 
                }
                "write" {
                    if {[lsearch $all_urls $form_url] == "-1"} {lappend all_urls $form_url } 
                }
                "read" {
                    if {[lsearch $all_urls $spreadsheet_url] == "-1"} {lappend all_urls $spreadsheet_url } 
                }
            }
        } 
    }

    return $all_urls
} 

ad_proc -public imsld::gsi::p_gspread::action_list_execute {
    -run_id
    -gservice_id
    -actions
    -multiplicity
    {-external_user ""}
    {-external_credentials ""}
} {
    Perform all requested actions. The method receives a list with funct_usages to perform.
} {
    #TODO
    ns_log Notice "Voy a ejecutar las siguientes acciones: $actions"
}

ad_proc -public imsld::gsi::p_gspread::perform_startup_actions {
    -run_id
    -gservice_id
    -startup_actions
    -multiplicity
    {-external_user ""}
    {-external_credentials ""}
} {
    Perform all startup actions. The method receives a list of lists with all the actions to perform.
    If this list is not received, can be calculated
} {
#the following if-else piece of code is to determine the case we have to handle, depending on startup actions.
    set permissions_switch "not-supported"
    if { ([llength $startup_actions] == 1) && ([string eq [lindex [lindex $startup_actions 0] 0] "deploy"]) } {
         #only deploy call requested
         set permissions_switch "empty-sheet"
    } elseif {([llength $startup_actions] == 2) && ([string eq [lindex [lindex $startup_actions 0] 0] "deploy"]) } {
         #let's check the second action
         if { [string eq [lindex [lindex $startup_actions 1] 0] "set-values"] && \
              [string eq [lindex [lindex [lindex $startup_actions 1] 1] 0] "mime-type"] && \
              [string eq [lindex [lindex [lindex $startup_actions 1] 1] 1] "text/csv"] } {
              #deploy call and set values for xls (ods?) file
              set permissions_switch "filled-sheet"
         }
    } elseif {([llength $startup_actions] == 3) && ([string eq [lindex [lindex $startup_actions 0] 0] "deploy"]) } {
         #let's check the second action
         if { [string eq [lindex [lindex $startup_actions 1] 0] "set-values"] && \
              [string eq [lindex [lindex [lindex $startup_actions 1] 1] 0] "mime-type"] && \
              [string eq [lindex [lindex [lindex $startup_actions 1] 1] 1] "text/csv"] } {
                 #let's check the third action
                 if { [string eq [lindex [lindex $startup_actions 2] 0] "set-values"] && \
                      [string eq [lindex [lindex [lindex $startup_actions 2] 1] 0] "mime-type"] && \
                      [string eq [lindex [lindex [lindex $startup_actions 2] 1] 1] "text/html"] } {
                      #deploy call and set values for xls (ods?) file
                      set permissions_switch "filled-sheet-with-form"
             }
         }
    }

#the service behaves depending on multiplicity
    switch $multiplicity {
        "one-for-all" {
            #get the first admin user (one user that can upload a file)
            #1.get a proper role (the first one, for example)
            set admin_role_list [imsld::gsi::get_roles_with_permissions -gservice_id $gservice_id \
                                                                        -action "admin" \
                                                                        -data_type "context"]
            set admin_role_id [lindex $admin_role_list 0]
            ns_log Notice "admin_role_id: $admin_role_id"
            #2.get someone in this role, the first one, for example
            set users_in_role [imsld::roles::get_users_in_role -role_id $admin_role_id -run_id $run_id]
            ns_log Notice "users in role: $users_in_role"
            set admin_user_id [lindex $users_in_role 0]

            switch $permissions_switch {
                "empty-sheet" {
                    imsld::gsi::p_gspread::init-remote-sheet -user_id $admin_user_id -run_id $run_id -gservice_id $gservice_id
                }
                "filled-sheet" {
                    imsld::gsi::p_gspread::init-remote-sheet -sheet_file_item [lindex [lindex [lindex $startup_actions 1] 2] 1] -user_id $admin_user_id -run_id $run_id -gservice_id $gservice_id
                }
                "filled-sheet-with-form" {
                    set spreadsheet_url [imsld::gsi::p_gspread::init-remote-sheet -sheet_file_item [lindex [lindex [lindex $startup_actions 1] 2] 1] \
                                                                                  -user_id $admin_user_id \
                                                                                  -run_id $run_id \
                                                                                  -gservice_id $gservice_id]
                    set form_url [imsld::gsi::p_gspread::init-form -run_id $run_id -form_file_item [lindex [lindex [lindex $startup_actions 2] 2] 1]]

                    imsld::gsi::p_gspread::set_spreadsheet_url -users_list [imsld::runtime::users_in_run -run_id $run_id] -run_id $run_id -spreadsheet_url $spreadsheet_url
                    imsld::gsi::p_gspread::set_form_url -users_list [imsld::runtime::users_in_run -run_id $run_id] -run_id $run_id -form_url $form_url
                }
            }
        }
        "one-per-role" {
            switch $permissions_switch {
                "empty-sheet" {}
                "filled-sheet" {}
                "filled-sheet-with-form" {}
            }
        }
        "one-per-person" {
            switch $permissions_switch {
                "empty-sheet" {}
                "filled-sheet" {}
                "filled-sheet-with-form" {}
            }
        }
    }
}


ad_proc -private imsld::gsi::p_gspread::init-form {
    {-form_file_item ""}
    -run_id
} {
    Fills the database with the proper value of a form, that will be handled during enactment
} {
    return [imsld::get_imsld_cp_file_id -run_id $run_id -identifier $form_file_item]
}

ad_proc -private imsld::gsi::p_gspread::set_form_url {
    -users_list
    -run_id
    -form_url
} {
    Stores in the database (gspread plugin datamodel) the corresponding form_url for a list of users in a run
} {
    foreach user $users_list {
        db_dml set_form_value {
            update imsld_gsi_p_gspread_usersmap
            set form_url=:form_url
            where user_id=:user and
                  run_id=:run_id
        }
    }
}


ad_proc -private imsld::gsi::p_gspread::set_formkey {
    -users_list
    -run_id
    -formkey
} {
    Stores in the database (gspread plugin datamodel) the corresponding formkey (complete url) for a list of users in a run
} {
    foreach user $users_list {
        db_dml set_formkey_value {
            update imsld_gsi_p_gspread_usersmap
            set formkey=:formkey
            where user_id=:user and
                  run_id=:run_id
        }
    }
}

ad_proc -private imsld::gsi::p_gspread::get_form_url {
    -users_list
    -run_id
} {
    Return the form_url (link or file) that corresponds to a list of users in a run. The output is a list with one answer per user
} {
    set result_list [list]
    foreach user $users_list {
        set user_fu [db_string get_formkey_value {
                select form_url
                from imsld_gsi_p_gspread_usersmap
                where user_id=:user and
                      run_id=:run_id
            } -default ""]
        lappend result_list $user_fu
    }
    return $result_list
}

ad_proc -private imsld::gsi::p_gspread::get_formkey {
    -users_list
    -run_id
} {
    Return the formkey (complete url) that corresponds of a list of users in a run
} {
    set result_list [list]
    foreach user $users_list {
        set user_fk [db_string get_formkey_value {
                select formkey 
                from imsld_gsi_p_gspread_usersmap
                where user_id=:user and
                      run_id=:run_id
            } -default ""]
        lappend result_list $user_fk
    }
    return $result_list
}


ad_proc -private imsld::gsi::p_gspread::set_spreadsheet_url {
    -users_list
    -run_id
    -spreadsheet_url
} {
    Stores in the database (gspread plugin datamodel) the corresponding spreadsheet_url for a list of users in a run
} {
    foreach user $users_list {
        db_dml set_spreadseet_value {
            update imsld_gsi_p_gspread_usersmap
            set spreadsheet_url=:spreadsheet_url
            where user_id=:user and
                  run_id=:run_id
        }
    }
}

ad_proc -private imsld::gsi::p_gspread::get_spreadsheet_url {
    -users_list
    -run_id
} {
    Stores in the database (gspread plugin datamodel) the corresponding spreadsheet_url for a list of users in a run
} {
    set result_list [list]
    foreach user $users_list {
        set user_surl [db_string get_formkey_value {
                select spreadsheet_url 
                from imsld_gsi_p_gspread_usersmap
                where user_id=:user and
                      run_id=:run_id
        } -default ""]
        lappend result_list $user_surl
    }
    return $result_list
}



ad_proc -private imsld::gsi::p_gspread::init-remote-sheet {
    {-sheet_file_item ""}
    -user_id
    -run_id
    -gservice_id
} {
    Upload a spreadsheet file (xls file) to googledocs and returns its URL.
} {
    #FIXME: what happens with the file_item is empty?
    package require TclCurl

    set imsld_file_id [imsld::get_imsld_cp_file_id -run_id $run_id -identifier $sheet_file_item]

    #read the file
    set postData [cr_write_content -string -item_id $imsld_file_id]

    #choose filename
    set filename [db_string get_tool_name {
                                select t.title 
                                from imsld_gsi_toolsi t, 
                                     imsld_gsi_services s 
                                where s.gsi_tool_id=t.item_id and 
                                      s.gsi_service_id=:gservice_id
    } -default "From [util_current_location]" ]

    set token [imsld::gsi::p_gspread::get_external_credentials -user_id $user_id -run_id $run_id]
    #configure curl
    #init the handler. It performs the requests, needs to be configured
    set curlHandle [curl::init]

    $curlHandle configure -url "http://docs.google.com/feeds/documents/private/full"
    $curlHandle configure -headervar http_code -bodyvar html_code
    set httpHeaders ""
    lappend httpHeaders "Authorization: AuthSub token=\"$token\""
    lappend httpHeaders "Accept: text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2"
    lappend httpHeaders "User-Agent: Tcl http client package 2.5.3"
    lappend httpHeaders "Content-Type: text/csv"
    lappend httpHeaders "Connection: keep-alive"
    lappend httpHeaders "Slug: $filename"
    lappend httpHeaders "Content-Type: application/x-www-form-urlencoded"
    lappend httpHeaders "Accept-Encoding:"
    lappend httpHeaders "Accept-Language:"
    lappend httpHeaders "Accept-Charset:"
    lappend httpHeaders "Keep-Alive:"
    lappend httpHeaders "Referer:"
    lappend httpHeaders "Cookie:"
    lappend httpHeaders "Expect:"
    $curlHandle configure -postfields $postData
    $curlHandle configure -httpheader $httpHeaders

    ns_log Notice "trying to connect with token: $token"    


    #send-file    
    $curlHandle perform

    #parse response and return
    dom parse $html_code document
    $document documentElement root_node
    ns_log Notice "[$root_node asXML]"
    ns_log Notice "[$root_node nodeName]"
    
    set spreadsheet_node [$root_node selectNodes {*[local-name()='resourceId']}]
    if {[llength $spreadsheet_node]} {
        ns_log Notice "should be here..."
        set spreadsheet_id [lindex [split [$spreadsheet_node "text"] ':'] 1]
        set parsed_url "https://spreadsheets.google.com/ccc?key=$spreadsheet_id"
        return $parsed_url
    } else {
        ns_log Notice "there was a problem with the request, please try again."

        #we have to undo whatever is in the database

        #redirect to previous page 
        set package_id [ad_conn package_id]
        set mount_point "[ad_conn location][apm_package_url_from_id $package_id]admin/gsi/imsld-gsi-service-configure"
        ad_returnredirect [export_vars -base $mount_point {run_id gservice_id}]
        ad_script_abort
    }
}
##########################################################
##########################################################

ad_proc -public imsld::gsi::p_gspread::modify_formData {
   -formData:required
   -user_id:required
   -base
   -formkey:required
} {
    @param formData 
    @param user_id
    @param base

    Returns a dom node which is the result of the formData processing. The actions to perform are: 

    - modify form's action and set the target configured in imsld_gsi_p_gspread_usersmap
    - insert two new input values, with the user email and an origin mark
    - if base is set, insert a base element.
} {
    #first of all, obtain the root dom node
    set document [dom parse -html $formData]
    set root_node [$document documentElement]

    #only when form_url is given, modify the base attribute in the head
    if {[info exists base]} {
 
        #if head does not exist, create one
        set head_node [$root_node selectNodes {//*[local-name()='head']}]
        if {$head_node eq ""} {
            set head_node [$document createElement "head"]
            $root_node insertBefore $head_node [$root_node firstChild]
        }
        #if base does not exist, create one
        if {![llength [$head_node selectNodes {/*[local-name()='base']}]]} {
            set base_node [$document createElement "base"]
            $base_node setAttribute href "$base"
            $head_node insertBefore $base_node [$head_node firstChild]
        }
    }

    #now, we are going to modify the form
    set form_node [$root_node selectNodes {//*[local-name()='form']}]
    if {[llength $form_node] > 1 } {
        ns_log Notice "error, no puede haber más de un form en el fichero, no lo permito yo :)."
        ns_log Notice "Lo suyo sería escoger el primer form que tenga algún input del tipo entry.X.?????"
    } else {
       $form_node setAttribute action $formkey

       #we need to calculate the number of elems to submit, in order to include two new ones
       set all_elems_to_submit [$form_node selectNodes {//*/@name[starts-with(.,'entry.')]}]
       set next_submit_number [llength [lsort -unique $all_elems_to_submit]]

        #to include plugin mark and username in the answer
       acs_user::get -user_id $user_id -array userdata
       set inputname_node [$document createElement input]
       $inputname_node setAttribute name "entry.$next_submit_number.single"
       $inputname_node setAttribute value "$userdata(email)"
       $inputname_node setAttribute type "hidden"
       incr next_submit_number 1

       set inputplugin_node [$document createElement input]
       $inputplugin_node setAttribute name "entry.$next_submit_number.single"
       $inputplugin_node setAttribute value "gspreadplugin"
       $inputplugin_node setAttribute type "hidden"

       $form_node appendChild $inputname_node
       $form_node appendChild $inputplugin_node
    }
    #once changed, we return the root_node
    return $root_node
}

ad_proc -public imsld::gsi::p_gspread::get_external_value {
    -run_id:required
    -gservice_id:required
    -multiplicity:required
    -node:required
    -user_id:required
} {
    Returns a the value obtained form the external service.
} {
    package require TclCurl 
    #first of all, we need to unwrapp and parse the external-value node
    set node [$node childNodes]
    set request_type [$node nodeName]
    if {[string eq $request_type "custom-value"]} {
        set custom-tag [$node getAttribute custom-value-mark] 
    } elseif {[string eq $request_type "contribution-value"] | [string eq $request_type "context-value"]} {
        set owner [$node getAttribute owner]
        set position [expr [$node getAttribute position] +1 ]
    }

    #note about permissions: the request is done by the LD service itself, not by a particular user. This
    #means that all permissions are available here. That is, no matter the user permissions, the property
    #will be retrieved using the credentials of the instance admin.
    
    #the service behaves depending on multiplicity. Since each instance require an admin user to be in use, 
    #the first thing to do is to find one of the admin users, no matter who
    switch $multiplicity {
        "one-for-all" {
            #one instance for all users: we need the first admin we find
            set admin_role_list [imsld::gsi::get_roles_with_permissions -gservice_id $gservice_id \
                                                                        -action "admin" \
                                                                        -data_type "context"]
            set admin_role_id [lindex $admin_role_list 0]
            #2.get someone in this role, the first one, for example
            set users_in_role [imsld::roles::get_users_in_role -role_id $admin_role_id]
            set admin_user_id [lindex $users_in_role 0]

            #3. get this user credentials
            set admin_credentials [imsld::gsi::p_gspread::get_external_credentials -run_id $run_id -user_id $admin_user_id]
            
            #4. we need the service's URL
            set surl [imsld::gsi::p_gspread::get_spreadsheet_url -users_list $admin_user_id -run_id $run_id]
            #warning, this way of parsing the URL could be much more generic
            set feed_key [lindex [split $surl '='] 1]
            set feed_url "http://spreadsheets.google.com/feeds/worksheets/$feed_key/private/full"

            #5. Ready to ask the service. The request has always the same form
            set httpHeaders ""
            lappend httpHeaders "Authorization: AuthSub token=\"$admin_credentials\""

            curl::transfer -httpheader $httpHeaders -bodyvar feed_xml -url $feed_url
            set document [dom parse $feed_xml]
            set root_node [$document documentElement]
          
            switch $request_type {
                "contribution-value" {
                   #in contributions, this service only supports 'self' as owner, which means 
                   #that each one obtains his/her own value.
                   #let's obtain the identifier (the e-mail)
                   acs_user::get -user_id $user_id -array userdata
                   #the email is in "$userdata(email)"

                   #we have the worksheet feed. We need the cellsfeed
                   set cellfeedURL [[$root_node selectNodes {//*[local-name()='link' and contains(@rel,'cellsfeed')]}] getAttribute href]
                    
                   #ready to get cellsfeed
                   curl::transfer -httpheader $httpHeaders -bodyvar feed_xml -url $cellfeedURL

                   #we have all the data in feed_xml, lets retrieve what we were asked for
                    set document [dom parse $feed_xml]
                    set root_node [$document documentElement]
                    set condition "//*\[local-name()='cell' and @inputValue='$userdata(email)'\]"
                    set content_user_nodes [$root_node selectNodes $condition]
                    if {[llength $content_user_nodes]} {
                        set user_row [[lindex $content_user_nodes 0] getAttribute row]
                        set condition "//*\[local-name()='cell' and @row='$user_row' and @col='$position'\]"
                        set property_value_node [$root_node selectNodes $condition]
                        if {[llength $property_value_node]} {
                            set property_value "[$property_value_node text]"
                        } else {
                            set property_value ""
                        }
                    } else {
                        set property_value ""
                    }
                }
                "context-value" {set property_value "undo context"}
                "custom-value" {set property_value "undo custom"}
            }
        }
        "one-per-role" {
            #one instance for each (role/group). we need the first admin we find on each role
        }
        "one-per-person" {
            #each user must be admin of his own instance.
        } 
    }
    ns_log Notice "user_id: $user_id, request_type: $request_type, property_value: $property_value"
    ns_log Notice "[$node asXML]"
    return $property_value
}

