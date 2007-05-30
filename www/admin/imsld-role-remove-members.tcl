#/packages/imsld/www/admin/imsld-role-add-members.tcl

ad_page_contract {
    Remove members from an specified group
    
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
#only set required variables
   set temp_list [list]
   foreach member $members_list {

        if {[string eq "-1" [lsearch $user_id $member]]} {
            #remove user from list
            lappend temp_list $member
        }
   }
   ad_returnredirect [export_vars -base imsld-admin-roles {imsld_id run_id role group_instance {members_list $temp_list}}]


   

