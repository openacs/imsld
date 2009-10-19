# /packages/imsld/www/admin/imsls-view-roles.tcl

ad_page_contract {
    Show the users asigned to roles when no further changes are possible
    
    @author lfuente@it.uc3m.es
    @creation-date Sep 2006
} {
    role:optional
    {group_instance 0}
    run_id
    members_list:optional
    {finishable 0}
} 

db_1row get_imsld_info { 
    select imsld_id
    from imsld_runs
    where run_id = :run_id
}


#get roles list
set roles_list [imsld::roles::get_list_of_roles -imsld_id $imsld_id]
set roles_list_names [imsld::roles::get_roles_names -roles_list $roles_list] 

set page_title "[_ imsld.View_Roles]"
set context [list $page_title]

set lista [list]
lappend lista [list "[_ imsld.Select_a_role]" 0]

for {set order 0} {$order < [llength $roles_list] } {incr order} {
    set lista_item [list [lindex $roles_list_names $order] [lindex [lindex $roles_list $order] 0]]
    lappend lista $lista_item
}

ad_form -name choose_role -action imsld-view-roles -export {imsld_id run_id} -show_required_p {0} -form {
                {role:integer(select)
                   {label "[_ imsld.Select_a_role_1]"} 
                   {options "$lista"}
                {html {onChange confirmValue(this.form)}}
               }
} -on_request {
     if {[info exists role]} {         
         set role $role
     }
}

if {![info exists role]} {
    set role 0
}
 
set subroles_list [imsld::roles::get_subroles -role_id $role]

if {![llength $subroles_list]} {
    set subroles_list 0
}
db_multirow -extend {rolelink} subroles_names get_subroles_names "
        SELECT object_title as rolename,
               role_id as child_id
        FROM imsld_rolesi
        WHERE role_id in ([join $subroles_list ","])
" {
set rolelink [export_vars -base imsld-view-roles {{role $child_id} run_id}]
}

set parent_role [lindex [db_list_of_lists get_parent_role {select iri.object_title, 
                                                 iri.role_id 
                                          from imsld_rolesi iri, 
                                               imsld_rolesi iri2 
                                          where iri2.role_id=:role
                                                and iri2.parent_role_id=iri.item_id
}] 0]

if {[llength $parent_role]} {
    set parent_role_name [lindex $parent_role 0]
    set parent_role_id [lindex $parent_role 1]
    set parent_role_link [export_vars -base imsld-view-roles { {role $parent_role_id} run_id }]
}


set groups_list [db_list get_groups_list {  select gr.group_id 
                                            from groups gr, 
                                                acs_rels ar1, 
                                                acs_rels ar2, 
                                                imsld_run_users_group_ext iruge, 
                                                imsld_rolesi iri 
                                            where ar1.rel_type='imsld_roleinstance_run_rel' 
                                                and ar1.object_id_one=gr.group_id 
                                                and ar1.object_id_two=iruge.group_id 
                                                and iruge.run_id=:run_id
                                                and iri.role_id=:role
                                                and iri.item_id=ar2.object_id_one 
                                                and ar2.rel_type='imsld_role_group_rel' 
                                                and ar2.object_id_two=gr.group_id
} ]

template::list::create \
    -name group_table \
    -multirow group_table \
    -elements {
        user_name {
            label {User Name}
        }
        user_email {
            label {e-mail}
        }
        group_name {
            label {Group}
        }
    }

if {![llength $groups_list]} {
    set groups_list "0"
}

db_multirow group_table get_users_in_group "select pn.party_name as user_name, 
                                                   u.username as user_email,
                                                   gn.group_name
                                            from party_names pn, 
                                                 users u, 
                                                 group_member_map gmm,
                                                 groups gn
                                            where gmm.member_id=u.user_id 
                                                  and gmm.group_id in ([join $groups_list ","])
                                                  and pn.party_id=gmm.member_id
                                                  and gn.group_id=gmm.group_id
                                             group by pn.party_name, u.username, gn.group_name" 


