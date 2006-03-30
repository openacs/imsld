# /packages/imsld/tcl/imsld-cp-procs.tcl

ad_library {
    Procedures in the imsld namespace that have to do with Roles Management
    
    @creation-date Mar 2006
    @author lfuente@inv.it.uc3m.es
}

namespace eval imsld {}
namespace eval imsld::roles {}

 # IMS CP database transaction functions

ad_proc -public imsld::roles::create_instance {
    -role_id:required
    -parent_group_id
} {
    Create a instance of a role (a party) for the role and for all the subroles with the "create-new" attribute set to true.    
    @param role_id identifier of the role to be instanciated
} {
    db_1row get_role_name {} 
    set role_name [join [list imsld $role_type $role_id] "_"]
    set names_counter [db_string name_already_exist {}]
    set role_name [join [list $role_name $names_counter] "_"]
    set user_id [ad_conn user_id] 
    set peeraddr [ad_conn peeraddr]

#create the party
    db_transaction {
        set group_id [db_exec_plsql create_new_group {}]
    }

#map role with group
    set rel_id [relation_add imsld_role_group_rel $role_item_id $group_id]
#map group with his parent (composition_rel)
    if {[info exist parent_group_id] } {
        relation_add composition_rel $parent_group_id $group_id
    }

#check for subroles
    set subroles_list [imsld::roles::get_subroles -role_id $role_id]

        if {[llength $subroles_list]} {
            foreach role $subroles_list {
                if {[string eq "t" [db_string get_create_new_p {}] ]} {
                    set sub_instance [imsld::roles::create_instance -role_id $role -parent_group_id $group_id]
                }
            }
        }
    return $group_id
}

ad_proc -public imsld::roles::delete_instance {
    -group_id
} {
    @param group_id identifier of the group instance to be deleted
} {
   set children_list [db_list check_children {}]

   foreach group_to_remove $children_list {
       db_exec_plsql delete_group {}
   }
   set group_to_remove $group_id
       db_exec_plsql delete_group {}
}




ad_proc -public imsld::roles::get_subroles {
    -role_id
} {
    @param role_id identifier of the role to be explored
} {
   set role_list [db_list get_subroles_list {}]
   return $role_list
}

ad_proc -public imsld::roles::get_depth {
    -role_id
    {-depth "0"}
} {
    @param role_id the role to calcule depth
} {
    if {[db_0or1row has_parent {}]} {
        incr depth
        imsld::roles::get_depth -role_id $parent_role_id -depth $depth
    } else {
        return $depth
    }
}

ad_proc -public imsld::roles::get_list_of_roles {
    -imsld_id:required
} {
    @param imsld_id identifier of the imsld from wich roles will be searched
} {
   set main_roles [db_list roles_list {}]
   set roles_list [list]
   foreach role $main_roles {
       set depth [imsld::roles::get_depth -role_id $role]
       lappend roles_list [list $role $depth]

   }
   return $roles_list
}

ad_proc -public imsld::roles::get_roles_names {
    -roles_list
} {
    @param roles_list the list of roles to get the name
} {

    set roles_names [list]
    foreach role_item_par $roles_list {

        set role_item [lindex $role_item_par 0]
        set depth [lindex $role_item_par 1]       

        db_1row get_role_name {}
        set name "[string repeat "&nbsp;&nbsp;&nbsp;&nbsp;" $depth] $name"
        lappend roles_names $name
    }
    return $roles_names
}


ad_proc -private imsld::roles::get_role_info {
    -role_id
} {
    @param roles_id the role from which the info is obtained
} {
    db_1row get_imsld_role_info {}
    return [list $max_persons $min_persons $create_new_p $match_persons_p] 
}

ad_proc -private imsld::roles::get_role_instances {
    -role_id
} {
    @param roles_list the list of roles to get the name
} {
    db_1row get_related_groups {}
    return $groups 
}

ad_proc -private imsld::roles::get_parent_role {
    -role_id
} {
    @param roles_list the list of roles to get the name
} {
    db_1row get_parent_role {}
    return $parent_role
}


