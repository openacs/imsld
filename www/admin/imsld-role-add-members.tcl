#/packages/imsld/www/admin/imsld-role-add-members.tcl

ad_page_contract {
    Assign users assigned to a specified group

    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    user_id:multiple
    members_list
    group_instance
    role
    imsld_id
    run_id
}

set page_title "[_ imsld.Add_Members]" 
set context "" 

#only set required variables
   foreach user $user_id {

        if {[string eq "-1" [lsearch $members_list $user]]} {
            #remove user from list
            lappend members_list $user

        }
   }
   ad_returnredirect [export_vars -base imsld-admin-roles {imsld_id run_id role group_instance members_list}]
