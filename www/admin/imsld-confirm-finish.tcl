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

#ojo!!!! poner aquí tema de permisos!!!
set conditions 1
if {$conditions == 1} {
    db_dml set_run_active { update imsld_runs set status='active' where run_id=:run_id and imsld_id=:imsld_id}
}

ad_returnredirect ..
