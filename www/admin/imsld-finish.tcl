ad_page_contract {
    Confirm changes and set a run as activeAsign users assigned to an specified group
    
    @author lfuente@it.uc3m.es
    @creation-date May 2006
} {
    imsld_id
    run_id
} 
#aqui tengo que poner la comprobación de que todo sea correcto (errores y warnings)

set roles_list_depth [imsld::roles::get_list_of_roles -imsld_id $imsld_id]


set roles_list [list]
foreach role $roles_list_depth {
    lappend roles_list [lindex $role 0]
}

set warnings [list]
set errors [list]
#para cada role, compruebo todas las condiciones
foreach role $roles_list {
    set role_info [imsld::roles::get_role_info -role_id $role]
    set max_persons [lindex $role_info 0]
    set min_persons [lindex $role_info 1]
    set match_persons_p [lindex $role_info 3]

 #para cada instancia del role, el maximo, minimo y demas es para cada grupo
    set role_groups [db_list get_groups_in_run {

       select ar1.object_id_two as groups  
       from acs_rels ar1,
            acs_rels ar2,
            imsld_rolesi iri,
            imsld_run_users_group_ext iruge2 
       where ar1.rel_type='imsld_role_group_rel' 
             and ar1.object_id_one=iri.item_id 
             and iri.role_id=:role
             and ar2.object_id_one=ar1.object_id_two 
             and ar2.rel_type='imsld_roleinstance_run_rel' 
             and ar2.object_id_two=iruge2.group_id 
             and iruge2.run_id=:run_id 
    }]
    if {![llength $role_groups]} {
        #warning, there's a role without instances
            lappend warnings "[llength $role_groups]WARNING: Role $role has no groups. Having a group is not mandatory, but may be you forgot assigning one...\<br\>"
             set warning_flag 1           
    } else {
    
         foreach group $role_groups {
            set members_list [db_list get_members_list {select member_id from group_member_map where group_id=:group group by member_id}]

            if {[llength $members_list] == 0} {
                lappend warnings "WARNING: Group $group in role $role has no members. A empty group is not forbiden, but may be you forgot assigning members...\<br\>"
                 set warning_flag 1           
            }
            #numero maximo
            if {![string eq "" $max_persons] && ([llength $members_list] > $max_persons)} {          
                #error porque hay demasiada gente
                lappend errors "ERROR: Group $group in role $role has too much members. Is must have no more than $max_persons. \<br\>Please go back and modify this.\<br\>"
                set error_flag 1
                
            }

            #numero minimo
            if { ![string eq "" $min_persons] && ([llength $members_list] < $min_persons)} {
                #error porque no hay gente suficiente en el grupo
                lappend errors "ERROR: Group $group in role $role has too much members. Is must have at least $min_persons. \<br\>Please go back and modify this.\<br\>"
                set error_flag 1
            }
            #match person   
            if {[string eq "t" $match_persons_p]} {
                #FIX ME: TERMINAR ESTA CONDICION
            }
        }  
    }

}
set back [export_vars -base imsld-admin-roles {run_id}]
set confirm [export_vars -base imsld-confirm-finish {imsld_id run_id}]
