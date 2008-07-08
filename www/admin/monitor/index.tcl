# packages/imsld/www/admin/monitor/index.tcl

ad_page_contract {
    
    Display all tha activities for monitoring purposes

    @author jopez@inv.it.uc3m.es
    @creation-date Nov 06
    @cvs-id $Id$
} {
    run_id:integer,notnull
    {type ""}
} -properties {
} -validate {
} -errors {
}

set course_name "[db_string run_name {
	select obj.title 
        from acs_objects obj, imsld_runs ir
	where obj.object_id = ir.imsld_id
        and ir.run_id = :run_id}]"

