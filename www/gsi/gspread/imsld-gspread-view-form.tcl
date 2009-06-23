ad_page_contract {
    Retrieves the html code from the form_url, modifies it and deliver to the end user.
} -query {
    run_id
    gservice_id
    user_id:optional
}

if { ![info exists user_id] } {
   set user_id [ad_conn user_id]
}

#three options: 
#1- there is no form
#2- the form is in a local file
#3- the form is in a url supported by TclCurl
#4- malformed

db_1row get_url {
    select form_url as form_url
    from imsld_gsi_p_gspread_usersmap
    where run_id=:run_id and user_id=:user_id
}

#first, there is no configurated form
if {[string eq $form_url ""]} {
    ad_returnredirect [export_vars -base "imsld-gspread-configure.tcl" {role_id gservice_id user_id run_id}]
    ad_script_abort
} else {

#get the form key, will be used later
    set formkey [imsld::gsi::p_gspread::get_formkey -users_list $user_id -run_id $run_id]

    if {[string is integer -strict $form_url] &&  \
        [db_0or1row is_form_in_a_file_p {
            select item_id as form_url,
                   imsld_file_id as object_id
            from imsld_cp_filesi
            where item_id=:form_url
    }]} {
    #second case, the form is a local file
        #read the file
        set formData [cr_write_content -string -item_id $form_url]


        #make proper changes
        #we need some previous steps to build the base value
        set fs_package_id [site_node_apm_integration::get_child_package_id \
                       -package_id [dotlrn_community::get_package_id \
                       [dotlrn_community::get_community_id]] \
                       -package_key "file-storage"]
        set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
        set folder_path ""
        set folder_path [db_exec_plsql get_folder_path {select content_item__get_path(:form_url,:root_folder_id); }]
        set file_url "[apm_package_url_from_id $fs_package_id]view/${folder_path}"
        set base_prefix [ns_conn location]
 
        set root_node [imsld::gsi::p_gspread::modify_formData -user_id $user_id \
                                                              -formData $formData \
                                                              -base "$base_prefix/$file_url" \
                                                              -formkey $formkey]
        #deliver to end user
        set deliverData [$root_node asHTML]
    
    } else {
    #third case, the form is an external URL
        #retrieve from URL
        package require TclCurl
        curl::transfer -url $form_url -bodyvar formData
        #make proper changes

        #FIXME: this base is not working very well :(
        set base $form_url
        set root_node [imsld::gsi::p_gspread::modify_formData -user_id $user_id \
                                                              -formData $formData \
                                                              -base $base \
                                                              -formkey $formkey]

        #deliver to end user
        set deliverData [$root_node asHTML]
    }
} 


