# /packages/imsld/www/admin/imsld-delete-instance.tcl

ad_page_contract {
    Delete a instance of a role
    
    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    role
    imsld_id
    group_id
}


db_1row get_rel_id {}
relation_remove $rel_id
imsld::roles::delete_instance -group_id $group_id
ad_returnredirect [export_vars -base imsld-admin-roles {{role $role} {imsld_id $imsld_id} {group_instance 0}}]
