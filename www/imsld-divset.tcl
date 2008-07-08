# packages/imsld/www/imsld-frameset.tcl

ad_page_contract {
    
    Course Delivery Based on IMS Content Packaging Structure
    
    @author Eduardo Perez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-21
    @cvs-id $Id$
} {
    run_id:integer,notnull
    {activity_id:optional ""}
} -properties {
} -validate {
} -errors {
}

set course_name ""

set environment_src ""
set content_src ""

if { $activity_id ne ""} {
    set content_src [export_vars -base "activity-frame" {{run_id $run_id} {activity_id $activity_id}}]
    set environment_src [export_vars -base "environment-frame" {{run_id $run_id} {activity_id $activity_id}}]
}

