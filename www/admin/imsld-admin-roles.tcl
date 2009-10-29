# /packages/imsld/www/admin/imsls-admin-roles.tcl

ad_page_contract {
    Admin the users assigned to a role
    
    @author lfuente@it.uc3m.es
    @creation-date Mar 2006
} {
    role:optional
    {group_instance 0}
    run_id
    members_list:optional
    {finishable 0}
} 

set page_title "[_ imsld.Admin_roles]" 
set context [list $page_title] 

#check if the run is waiting
if { [db_0or1row get_run_status {
    select run_id
    from imsld_runs
    where run_id=:run_id and status='active'
}] } {
    ad_returnredirect .
}


db_1row get_imsld_info { 
    select imsld_id
    from imsld_runs
    where run_id = :run_id
}


#get roles list
set roles_list [imsld::roles::get_list_of_roles -imsld_id $imsld_id]
set roles_list_names [imsld::roles::get_roles_names -roles_list $roles_list] 


set lista [list]
lappend lista [list "[_ imsld.Select_a_role]..." 0]

for {set order 0} {$order < [llength $roles_list] } {incr order} {
    set lista_item [list [lindex $roles_list_names $order] [lindex [lindex $roles_list $order] 0]]
    lappend lista $lista_item
}

ad_form -name choose_role -action imsld-admin-roles -export {imsld_id run_id} -show_required_p {0} -form {
                {role:integer(select)
		    {label "[_ imsld.Select_a_role]"} 
                   {options "$lista"}
                {html {onChange confirmValue(this.form)}}
               }
} -on_request {
     if {[info exists role]} {         
         set role $role
     }
}

ad_form -name upload_role -action imsld-import-roles -export {imsld_id run_id} -show_required_p {0} -form {
    {role_url:text
	{label "[_ imsld.Import_members_from_a_URL]"} 
    }
}

if {![info exists role]} {
    set role 0
}

ad_form -name finish_management \
    -form {
	{submit:text(submit) {label "[_ imsld.lt_Finish_role_managemen]"}}
    } \
    -action imsld-finish \
    -export {imsld_id run_id}

