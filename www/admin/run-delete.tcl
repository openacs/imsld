# /packages/imsld/www/admin/run-delete.tcl

ad_page_contract {
    Deletes imsld
    
    @author jopez@inv.it.uc3m.es
    @creation-date May 2006
    @cvs-id $Id$
} {
    run_id:integer,notnull
    return_url
} 

db_transaction {
    
    db_dml delete_run {
        update imsld_runs
        set status = 'deleted'
        where run_id = :run_id
    }
} on_error {
    ad_return_error "[_ imsld.lt_Error_deleting_Run_ru]" "[_ imsld.lt_There_was_an_error_de_1]"
    ad_script_abort
}

db_release_unused_handles

ad_returnredirect $return_url
