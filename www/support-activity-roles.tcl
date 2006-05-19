ad_page_contract {

       Here is placed information about roles and users in support activities
           
}

db_multirow role_info get_multirow_role_info "select title as role_name, role_id
                                              from imsld_rolesi
                                              where role_id in ([join $supported_roles ","]) "  

set community_id [dotlrn_community::get_community_id]
set supported_role_instances [list]

foreach role $supported_roles {
    set supported_instances_temp [imsld::roles::get_role_instances -role_id $role -run_id $run_id]
        lappend supported_role_instances $supported_instances_temp
}

set users_in_role [list]
    set counter 0
foreach instances_group $supported_role_instances {
    set users_in_instance [list]
    foreach instance $instances_group {
        set users_in_instance [concat $users_in_instance [group::get_members -group_id $instance]]
    }
    lappend users_in_role $users_in_instance
    db_multirow -append -extend {role_id username} supported_users_in_role  remove_repeated "select gmm.member_id
                                                        from group_member_map gmm
                                                        where gmm.member_id in ([join $users_in_instance ","]) group by gmm.member_id" { 

        set role_id [lindex $supported_roles $counter]
        set username [join [db_list_of_lists get_user_name "select first_names, last_name from dotlrn_users where user_id=$member_id"]]

    }
        set counter [expr $counter + 1]

   
}

set lista [template::util::multirow_to_list supported_users_in_role]
ns_log Notice "lista generada: $lista"


