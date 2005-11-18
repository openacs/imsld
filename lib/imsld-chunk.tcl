# imsld/lib/imsld-chunk.tcl

ad_page_contract {
    @author jopez@inv.it.uc3m.es
    @creation-date Sept 2005
    @cvs-id $Id$
}

set next_activity_list [imsld::next_activity -imsld_item_id $imsld_item_id -return_url [ad_conn url]]
set objectives_ul [lindex $next_activity_list 0]
set prerequisites_ul [lindex $next_activity_list 1]
set activity_name [lindex $next_activity_list 2]
set activity_urls [lindex $next_activity_list 3]
set completed_activities [lindex $next_activity_list 4]
set environment_ul [lindex $next_activity_list 5]