# imsld/www/admin/run-new.tcl

ad_page_contract {

    Creates a new run for the given UoL (imsld_id)
    
    @author jopez@inv.it.uc3m.es
    @creation-date jul 2006
} {
    {return_url "index"}
    run_imsld_id:notnull
}

imsld::instance::instantiate_imsld -imsld_id $run_imsld_id -community_id [dotlrn_community::get_community_id]

ad_returnredirect $return_url