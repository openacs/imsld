# packages/lorsm/www/delivery/index.tcl

ad_page_contract {
    
    Course Delivery Based on IMS Content Packaging Structure
    
    @author Eduardo Perez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-21
    @cvs-id $Id$
} {
    imsld_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set course_name ""