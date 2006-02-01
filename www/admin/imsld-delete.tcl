# /packages/imsld/www/admin/imsld-delete.tcl

ad_page_contract {
    Deletes imsld
    
    @author jopez@galileo.edu
    @creation-date Nov 2005
    @cvs-id $Id$
} {
    imsld_id:integer,notnull
    return_url
} 

db_transaction {
    
    db_dml delete_imsld {
        update cr_items 
        set live_revision = NULL
        where item_id = (select item_id from cr_items where live_revision = :imsld_id)
    }
} on_error {
    ad_return_error "[_ imsld.lt_Error_deleting_IMS_LD]" "[_ imsld.lt_There_was_an_error_de]"
    ad_script_abort
}

db_release_unused_handles

ad_returnredirect $return_url
