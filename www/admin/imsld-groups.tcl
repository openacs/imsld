# /packages/imsld/www/admin/imsld-groups.tcl

ad_page_contract {
    Show the list of available groups and manage them
    
    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    imsld_id
    {group_instance 0}
    role:optional
}
set lista [list [list "Select a group..." 0]]
set lista_aux [lindex [db_list_of_lists get_groups_list {}] 0]
lappend lista $lista_aux


    set actions [list "Create new" [export_vars -base imsld-create-instance {imsld_id role}] "Create a new group"]

template::list::create \
    -name role_groups \
    -multirow role_groups \
    -key role_groups \
    -actions $actions \
    -elements {
        group_name {
           label {Group name}
           link_url_col {manage_roles}
        }
        delete {
            label {}
            display_template {@role_groups.delete;noquote@} 
        }
    }


db_multirow -extend { manage_roles delete } role_groups get_groups_list {} {
    set manage_roles [export_vars -base imsld-admin-roles {imsld_id role {group_instance $group_id}}]
    set delete "<a href=\"[export_vars -base "imsld-delete-instance" { imsld_id role group_id }]\"><img src=\"/resources/acs-subsite/Delete16.gif\" width=\"16\" height=\"16\" border=\"0\" alt=\"Delete\"></a>"
   
}



