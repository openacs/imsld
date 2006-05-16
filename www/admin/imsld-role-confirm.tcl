#/packages/imsld/www/admin/imsld-role-add-members.tcl

ad_page_contract {
    Confirm membership changes made on role instances
    
    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    members_list
    group_instance
    role
    imsld_id
    run_id
} 

#check conditions and set the database
set role_info [imsld::roles::get_role_info -role_id $role]

set max_persons [lindex $role_info 0]
set min_persons [lindex $role_info 1]
set match_persons_p [lindex $role_info 3]

set return_url [export_vars -base imsld-admin-roles {role imsld_id run_id group_instance members_list}]
set return_url2 [export_vars -base imsld-admin-roles {role imsld_id run_id group_instance}]


if {![string eq "-1" [lsearch $members_list 0]] } {
    set members_list [lreplace [lsort -integer -decreasing $members_list] end end]

}
if { ![string eq "" $min_persons] && ([llength $members_list] < $min_persons)} {
        set mensaje "<p>Number of members does not reach the minimum allowed number of users for this role.
                       There must be at least $min_persons members.</p>
                       <a href=\"$return_url\">Go back</a>"
        ad_return_complaint 1 $mensaje
        ad_script_abort
}

if {![string eq "" $max_persons] && ([llength $members_list] > $max_persons)} {
        set mensaje "<p>Number of members exceded the allowed number for this role.
                       You must not select more than $max_persons members.</p>
                       <a href=\"$return_url\">Go back</a>"
        ad_return_complaint 1 $mensaje
        ad_script_abort
}

#FIXME: falta comprobar match_persons_p
if {[string eq "t" $match_persons_p]} {
    #get not-allowed users
    set not_allowed [db_list other_subroles_members {}]
        
    if {[llength $not_allowed]} {

        set not_allowed_name [list]
        foreach role_notallowed $not_allowed {
            lappend not_allowed_name [acs_user::get_element -user_id $role_notallowed -element name]
        }

        set parent_role [imsld::roles::get_parent_role -role_id $role]
        set parent_role_name [imsld::roles::get_roles_names -roles_list [list [list $parent_role 0]]]


        
        set mensaje "<p>Members $not_allowed_name are already members of other subroles of role $parent_role_name.</p>
                     <p>Current UoL does not allow to include them in more than one subroles of the role.</p>
                       <a href=\"$return_url\">Go back</a>"
        ad_return_complaint 1 $mensaje
        ad_script_abort
    }
}

set previous_members_list [group::get_members -group_id $group_instance]

foreach user $previous_members_list {
    if {[string eq "-1" [lsearch $members_list $user]]} {
        group::remove_member -user_id $user -group_id $group_instance
    }
}

foreach member $members_list {
    if {[string eq "-1" [lsearch $previous_members_list $member]]} {
        group::add_member -user_id $member -group_id $group_instance
    }
    
}
ad_returnredirect $return_url2
