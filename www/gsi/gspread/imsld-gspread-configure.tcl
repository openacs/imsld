ad_page_contract {
    Allow the user to configure an external form.
} -query {
    run_id
    gservice_id
    user_id:optional
    formURL:optional
    formfile:optional
    formkey:optional
}

#FIXME: I have to perform corresponding actions
#check input parameters and perform corresponding actions
if { ![info exists user_id] } {
   set user_id [ad_conn user_id]
}

if {[info exists formURL]} {
    imsld::gsi::p_gspread::set_form_url -users_list $user_id -run_id $run_id -form_url $formURL
}

if {[info exists formfile]} {
    #insert the file in the proper fs folder (as cr_item, of course)
        #obtain the folder
        #read the file and create the item
    #obtain the cr.item_id
    #insert the item_id with set_form_url
}

if {[info exists formkey]} {
    #set the value in the corresponding place
    set actual_formurl [regsub -all "viewform" $formkey "formResponse"]
    #check the multiplicity of the service. The possible cases (and actions to perform) are:
    #
    # - one for all. The formkey is set to all users 
    # - one per role. The formkey is set to all users in the current role.
    # - one per person. The formke is set only to the user. Each user must be admin of his/her own instance.
    set multiplicity [imsld::gsi::get_service_multiplicity -gservice_id $gservice_id]
    switch $multiplicity {
        one-per-user {
            set users_list $user_id
        }
        one-per-role {
            #1- set active role
            set active_role [imsld::roles::get_active_role -run_id $run_id -user_id $user_id]
            #2- set group(s) of active role
            set group_id [imsld::gsi::get_group_from_role -gservice_id $gservice_id -role_id $active_role]
            #3- set users_list
            set users_list [imsld::gsi::get_users_in_group -group_id $group_id]
        }
        one-for-all {
            set users_list [imsld::gsi::get_users_in_service -run_id $run_id -gservice_id $gservice_id]
        }
    }
    imsld::gsi::p_gspread::set_formkey -users_list $users_list -run_id $run_id -formkey $actual_formurl
} else {
    db_1row get_formkey {
        select formkey as actual_formurl
        from imsld_gsi_p_gspread_usersmap
        where run_id=:run_id and user_id=:user_id
    }
}

#check the current configuration of the form

#FIXME: I have to check if the service is configured
set tmp_form_url [imsld::gsi::p_gspread::get_form_url -users_list $user_id -run_id $run_id]
#is form linked to a local file?
if {[string is integer -strict $tmp_form_url] &&  \
    [db_0or1row is_formfile_p {
        select 1
        from imsld_cp_filesi
        where item_id=:tmp_form_url
}]} {
    set form_already_set_p "t"
    set form_type "Local File"
    set access_to_form "$tmp_form_url"
} elseif {![string eq $tmp_form_url ""]} {
    #is form linket to a URL? (it is not a local file and the value is set)
    set form_already_set_p "t"
    set form_type "URL"
    set access_to_form "$tmp_form_url"
}

#is formkey already set?
if {![string eq $actual_formurl ""]} {
    set already_configured_p "t"
}
ad_form -name "set-formfile" \
        -html {enctype multipart/form-data} \
        -export {user_id gservice_id run_id} \
        -show_required_p {0} \
        -form { \
            {formfile:file }
        }

ad_form -name "set-formURL" \
        -html {enctype multipart/form-data} \
        -export {user_id gservice_id run_id} \
        -show_required_p {0} \
        -form { \
            {formURL:text {html {size 100}}}
        }

ad_form -name "set-formkey" \
        -html {enctype multipart/form-data} \
        -export {user_id gservice_id run_id} \
        -show_required_p {0} \
        -form { \
            {formkey:text {html {size 100}}}
        }
