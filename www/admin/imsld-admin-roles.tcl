# /packages/imsld/www/admin/imsls-admin-roles.tcl

ad_page_contract {
    Admin the users assigned to a role
    
    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    role:optional
    {group_instance 0}
    imsld_id
    members_list:optional
} 

#get roles list
set roles_list [imsld::roles::get_list_of_roles -imsld_id $imsld_id]
set roles_list_names [imsld::roles::get_roles_names -roles_list $roles_list] 

set lista [list]
lappend lista [list "Select a role..." 0]

for {set order 0} {$order < [llength $roles_list] } {incr order} {
    set lista_item [list [lindex $roles_list_names $order] [lindex [lindex $roles_list $order] 0]]
    lappend lista $lista_item
}

ad_form -name choose_role -action imsld-admin-roles -export {imsld_id} -form {
               {role:integer(select) {label "Select a role"} 
               {options "$lista"} 
               }
} -on_request {
     if {[info exists role]} {
         set role $role
     }
}

if {![info exists role]} {
    set role 0
}
