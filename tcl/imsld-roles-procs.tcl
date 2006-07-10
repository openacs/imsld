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
    -run_id:required
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

#get the run_users_group
    db_1row get_group_from_run {}
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
#map group with the run
    set club_id [dotlrn_community::get_community_id]
    relation_add imsld_roleinstance_run_rel $group_id $run_group_id 

#check for subroles
    set subroles_list [imsld::roles::get_subroles -role_id $role_id]

        if {[llength $subroles_list]} {
            foreach role $subroles_list {
                if {[string eq "t" [db_string get_create_new_p {}] ]} {
                    set sub_instance [imsld::roles::create_instance -role_id $role -parent_group_id $group_id -run_id $run_id]
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
    set counter 1
    set roles_names [list]
    foreach role_item_par $roles_list {

        set role_item [lindex $role_item_par 0]
        set depth [lindex $role_item_par 1]       

        db_1row get_role_name {}
        if {![string eq "" $name]} {
            set name "[string repeat "&nbsp;&nbsp;&nbsp;&nbsp;" $depth] $name"
            lappend roles_names $name
        } else {
            set name "role_$counter"
            set name "[string repeat "&nbsp;&nbsp;&nbsp;&nbsp;" $depth] $name"
            lappend roles_names $name
            set counter [expr $counter + 1]   
        }
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
    -run_id

} {
    @param roles_list the list of roles to get the name
} {
    if {[info exist run_id]} {
        set groups [db_list get_community_related_groups {}]
    } else {
        set groups [db_list get_related_groups {}]
    }
    return $groups 
}

ad_proc -private imsld::roles::get_user_role_instance {
    -role_id:required
    -run_id:required
    {-user_id ""}
} {
    @return the role_instance_id for that role_id which the user belongs to. 0 if the user doesn't belong to any role instance
} {
    if { [string eq $user_id ""] } {
        set user_id [ad_conn user_id]
    }
    
    set found_p 0
    foreach role_instance_id [imsld::roles::get_role_instances -role_id $role_id -run_id $run_id] {
        if { [group::member_p -user_id $user_id -group_id $role_instance_id] } {
            set found_p 1
            break
        }
    }

    if { !$found_p } {
        return 0
    }

    return $role_instance_id
}

ad_proc -private imsld::roles::get_parent_role_instance {
    -group_id
    -root_parent:boolean
} {
    @param group_id the role instance to get the parent from
} {
    if {[db_0or1row get_parent_role_instance {}]} {
        if {$root_parent} {
            set group_id $parent_group_id
            while {[db_0or1row get_parent_role_instance {}]} {
               set group_id $parent_group_id
            }
            return $parent_group_id
        } else {
            return $parent_group_id
        }
    } else {
        return 0
    }
}

ad_proc -private imsld::roles::get_parent_role {
    -role_id
    -root_parent:boolean
} {
    @param roles_list the list of roles to get the name
} {
    set role $role_id
    if {[db_0or1row get_parent_role {}]} {
        if {$root_parent} {
            set role $parent_role
            while {[db_0or1row get_parent_role {}]} {
               set role $parent_role 
            }
            return $parent_role
        } else {
            return $parent_role
        }
    } else {
        return 0
    }
}

ad_proc -private imsld::roles::get_mail_recipients {
    -role_destination_ref
    -role_source_id
    -run_id
} {
    Get the list of recipients of a send-mail service. Its called from a user belonging to a role into an specific imsld run and must get a list of users from the destination role.
} {

#FIX ME: when runs are supported, here may be included
    
#find relationship between source and destination.
#    set root_source_parent_role [imsld::roles::get_parent_role -role_id $role_source_id -root_parent]
    set root_destination_parent_role [imsld::roles::get_parent_role -role_id $role_destination_ref]

    set list_of_groups [imsld::roles::get_role_instances -role_id $role_destination_ref -run_id $run_id]
#    if { $root_source_parent_role == $root_destination_parent_role } {
       #get community_id
#        set group_id 
#
#       }
    set users_list [list]
    foreach group $list_of_groups {
        lappend users_list [group::get_members -group_id $group]
    }
    return $users_list
}
ad_proc -public imsld::roles::get_user_roles {
    -user_id
    -run_id 
} {
    Returns a list with all the roles_id from which the user are member. If run_id is given, restrict the list to the roles of the run.
} {
    set roles_list [list]
    if {[info exist run_id]} {
        set roles_list [db_list get_user_roles_list {}]
    } else {
        set roles_list [db_list get_raw_user_roles_list {}]
    }
    return $roles_list
}

ad_proc -public imsld::roles::get_users_in_role {
    -role_id:required
    -run_id 
} {
    Returns a list with all the users in a role. If run_id is given, restrict the list to the roles of the run.
} {

   if {[info exist run_id]} {
       set groups_list [db_list get_groups_in_run {
            select ar1.object_id_two as groups  
            from acs_rels ar1,
                 acs_rels ar2,
                 imsld_rolesi iri,
                 imsld_run_users_group_ext iruge2 
            where ar1.rel_type='imsld_role_group_rel' 
                  and ar1.object_id_one=iri.item_id 
                  and iri.role_id=:role_id
                  and ar2.object_id_one=ar1.object_id_two 
                  and ar2.rel_type='imsld_roleinstance_run_rel' 
                  and ar2.object_id_two=iruge2.group_id 
                  and iruge2.run_id=:run_id 
       }]
   } else {
       set groups_list [db_list get_groups_in_role {
           select ar.object_id_two 
           from acs_rels ar, 
                imsld_rolesi iri 
            where ar.rel_type='imsld_role_group_rel' 
                  and ar.object_id_one=iri.item_id 
                  and iri.role_id=:role_id 
       }]
   }

   set users_list [list]
   foreach group $groups_list {
        set users_in_group [db_list get_users_in_group {
           select member_id 
           from group_member_map 
           where group_id=:group
           group by member_id
        }]
        set users_list [concat $users_list $users_in_group]
   }
  return $users_list
}


ad_proc -public imsld::roles::get_role_id {
    -ref:required
    -run_id:required
} {
    Returns the role_id which has a given ref in a run, 0 if no matches found.
} {
    if{[db_0or1row select_role_id {
        select ar1.object_id_one as role_id
        from imsld_rolesi iri, 
             acs_rels ar1, 
             acs_rels ar2 
        where ar1.object_id_two=ar2.object_id_one 
              and ar1.rel_type='imsld_role_group_rel' 
              and ar2.rel_type='imsld_roleinstance_run_rel' 
              and ar2.object_id_two=:run_id
              and iri.item_id=ar1.object_id_one 
              and iri.identifier=:ref
        group by role_id;
    }]} {
        return $role_id
    } else {
        return 0
    }
}
