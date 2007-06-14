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
set finishable 1

set return_url [export_vars -base imsld-admin-roles {role imsld_id run_id group_instance members_list}]
set return_url2 [export_vars -base imsld-admin-roles {role imsld_id run_id finishable}]


if {![string eq "-1" [lsearch $members_list 0]] } {
    set members_list [lreplace [lsort -integer -decreasing $members_list] end end]

}
if { ![string eq "" $min_persons] && ([llength $members_list] < $min_persons)} {
        set mensaje "<p>[_ imsld.lt_Number_of_members_doe]</p>
                       <a href=\"$return_url\" title=\"[_ imsld.Go_back]\">[_ imsld.Go_back]</a>"
        ad_return_complaint 1 $mensaje
        ad_script_abort
}

if {![string eq "" $max_persons] && ([llength $members_list] > $max_persons)} {
        set mensaje "<p>[_ imsld.lt_Number_of_members_exc]</p>
                       <a href=\"$return_url\" title=\"[_ imsld.Go_back]\">[_ imsld.Go_back]</a>"
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


        
        set mensaje "<p>[_ imsld.lt_Members_not_allowed_n]</p>
                     <p>[_ imsld.lt_Current_UoL_does_not_]</p>
                       <a href=\"$return_url\" title=\"[_ imsld.Go_back]\">[_ imsld.Go_back]</a>"
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
