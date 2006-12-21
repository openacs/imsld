# packages/imsld/www/admin/monitor/index.tcl

ad_page_contract {
    
    Display all tha activities for monitoring purposes

    @author jopez@inv.it.uc3m.es
    @creation-date Nov 06
    @cvs-id $Id$
} {
    run_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set course_name ""
