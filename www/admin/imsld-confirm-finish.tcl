ad_page_contract {
    Confirm changes and set a run as activeAsign users assigned to an specified group
    
    @author lfuente@it.uc3m.es
    @creation-date May 2006
} {
    imsld_id
    run_id
} 


# instantiating properties and activity attributes for the run
imsld::instance::instantiate_properties -run_id $run_id
imsld::instance::instantiate_activity_attributes -run_id $run_id
# NOTE: we should verify the permissions here
set conditions 1
if {$conditions == 1} {
    db_dml set_run_active { 
        update imsld_runs set status = 'active',
        status_date = now()
        where run_id=:run_id and imsld_id=:imsld_id
    }
}

# excecute all conditions for all users

set users_list [list]
foreach role_id [imsld::roles::get_list_of_roles -imsld_id $imsld_id] {
   set users_list [concat $users_list [imsld::roles::get_users_in_role -role_id [lindex $role_id 0] -run_id $run_id]]
}
   
foreach user_id $users_list {
    imsld::condition::execute_all -run_id $run_id -user_id $user_id
}


ad_returnredirect .
