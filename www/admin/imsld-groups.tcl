# /packages/imsld/www/admin/imsld-groups.tcl

ad_page_contract {
    Show the list of available groups and manage them
    
    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    imsld_id
    run_id
    {group_instance 0}
    role:optional
}
set lista [list [list "[_ imsld.Select_a_group]" 0]]
set lista_aux [lindex [db_list_of_lists get_groups_list {}] 0]
lappend lista $lista_aux


set actions [list "[_ imsld.New_group]" [export_vars -base imsld-create-instance {imsld_id run_id role lista}] "[_ imsld.Create_a_new_group]"]

template::list::create \
    -name role_groups \
    -multirow role_groups \
    -key role_groups \
    -pass_properties { imsld_id run_id role } \
    -actions $actions \
    -elements {
        group_name {
           label {[_ imsld.Group_name]}
           link_url_col {manage_roles}
        }
        delete {
            label {}
            display_template {<a href="imsld-delete-instance?imsld_id=@imsld_id@&run_id=@run_id@&role=@role@&group_id=@role_groups.group_id@" title="[_ imsld.Delete]"><img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0" alt="[_ imsld.Delete]" title="[_ imsld.Delete]"></a>} 
        }
    }

db_multirow -extend { manage_roles delete } role_groups get_groups_list {} {
    set manage_roles [export_vars -base imsld-admin-roles {imsld_id run_id role {group_instance $group_id}}]
}


