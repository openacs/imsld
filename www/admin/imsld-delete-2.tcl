# /packages/imsld/www/admin/imsld-delete-2.tcl

ad_page_contract {
    Deletes imsld
    
    @author jopez@galileo.edu
    @creation-date Nov 2005
    @cvs-id $Id$
} {
    imsld_id:integer,notnull
    return_url
    operation
} 

if { [string eq $operation "Yes, I'm sure"] } {
    db_transaction {

        db_dml delete_imsld {
            update cr_items 
            set live_revision = NULL
            where item_id = (select item_id from cr_items where live_revision = :imsld_id)
        }
    } on_error {
        ad_return_error "Error deletin IMS LD" "There was an error deleting the IMS LD $imsld_id. This is the error: <pre>$errmsg</pre>"
        ad_script_abort
    }
} 

db_release_unused_handles

ad_returnredirect $return_url
