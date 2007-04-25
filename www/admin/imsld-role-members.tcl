# /packages/imsld/www/admin/imsld-role-members.tcl

ad_page_contract {
    Asign users assigned to an specified group
    
    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    role:optional
    {group_instance 0}
    imsld_id
    run_id
    members_list:optional
} 

#check conditions and set the database
set role_info [imsld::roles::get_role_info -role_id $role]

set max_persons [lindex $role_info 0]
if {[string eq "" $max_persons]} {set max_persons "No restricition"}

set min_persons [lindex $role_info 1]
if {[string eq "" $min_persons]} {set min_persons "No restricition"}

set match_persons_p [lindex $role_info 3]

set not_allowed [db_list other_subroles_members {}]

if {[string eq "t" $match_persons_p] && [llength $not_allowed]} {

} else {
    set not_allowed [list 0 0]
}

set group_title [group::title  -group_id $group_instance]

if {![string eq $group_instance "0"] && [db_0or1row has_role_parent_p {}]} {
    if {![info exist members_list]} {
        set members_list [db_list get_members_list_2 {}]
    }
    if {![llength $members_list]} {
       set members_list 0 
    }
    set not_members_list [db_list get_not_members_list_2 {}]

    if {![llength $not_members_list]} {
       set not_members_list 0 
    }
  
    
} else {
     if {![info exist members_list]} {
        set members_list [db_list get_members_list {}]
    }

    if {![llength $members_list]} {
       set members_list 0 
    }
    set community_id  [dotlrn_community::get_community_id]
    set not_members_list [db_list get_not_members_list {}]
    if {![llength $not_members_list]} {
       set not_members_list 0 
    }
   
}



if {![db_0or1row get_group_name {}]} {
    set group_name "No group selected"
#    set create_instance_url [export_vars -base imsld-create-instance {{imsld_id $imsld_id} {role $role}}]
    set create_instance_url imsld-create-instance 
    set bulk_actions "{Create new instance} $create_instance_url {Create a new instance of a role}"
    set bulk_actions_not "{Create new instance} $create_instance_url {Create a new instance of a role}"
    set bulk_action_export_vars "{imsld_id} {role} {run_id}"
} else {
    set bulk_actions "{<------} {imsld-role-remove-members} {Remove selected members from the group}"
    set bulk_actions_not "{------->} {imsld-role-add-members} {Add selected members to the group}"
                     
    set bulk_action_export_vars "{group_instance} {role} {imsld_id} {run_id} {members_list}"
}


template::list::create \
    -name asign_members \
    -multirow asign_members \
    -key user_id \
    -elements {
        username {
           label {User name}
        }
        type {
            label {User Type}
       }
    } \
    -bulk_actions "$bulk_actions"\
    -bulk_action_export_vars "$bulk_action_export_vars"

#set orderby [template::list::orderby_clause -orderby -name asign_members]
#if {[string equal $orderby ""]} {
#    set orderby " order by username asc"
#}

template::list::create \
    -name asign_not_members \
    -multirow asign_not_members \
    -key user_id \
    -elements {
        username {
           label {User name}
        }
        type {
            label {User Type}
       }
    } \
    -bulk_actions "$bulk_actions_not"\
    -bulk_action_export_vars "$bulk_action_export_vars"

db_multirow asign_members get_users_list {}
db_multirow asign_not_members get_not_users_list {}

ad_form -name confirm \
        -form {
            {submit:text(submit) {label "[_ imsld.Confirm_this_changes]"}}
        } \
        -action imsld-role-confirm \
        -export {imsld_id run_id role group_instance members_list}

