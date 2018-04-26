# packages/imsld/www/monitor-frame.tcl

ad_page_contract {

    This is the frame user to display the monitor service

    @author jopez@inv.it.uc3m.es
    @creation-date Abr 2006
    @cvs-id $Id$
} -query {
    run_id:integer,notnull
    monitor_id:integer,notnull
    {monitoring_user_id ""}
    {role_id ""}
}

set user_id [ad_conn user_id]

if { $role_id ne "" } {
    db_1row monitor_service_info { *SQL* }
} else {
    db_1row monitor_service_info_no_role_id { *SQL* }
}



template::multirow create users_in_role role_user_id user_name
set monitoring_user_name "[_ imsld.None]"

if { [string eq $self_p "f"] } {
    # display the list of users in order to chose one of them
    set role_instances [imsld::roles::get_role_instances -role_id $role_id -run_id $run_id]
    set users_in_instances {}
    foreach instance $role_instances {
        set users_in_instances [concat $users_in_instances [group::get_members -group_id $instance]]
    }
    lsort -unique $users_in_instances
    foreach role_user_id $users_in_instances {
        set user_name [person::name -person_id $role_user_id]
        template::multirow append users_in_role $role_user_id $user_name 
    }
} else {
    set monitoring_user_id $user_id
}

if { ![string eq $monitoring_user_id ""] } {
    # a user has been selected, display the name
    set monitoring_user_name [person::name -person_id $monitoring_user_id]

    # get the associated resource of the monitor service
    db_1row monitor_associated_item { *SQL* }
    
    set monitor_service_url [export_vars -base "imsld-content-serve" -url { run_id resource_item_id role_id {owner_user_id $monitoring_user_id} }]
} else {
    # no user has been selected...
    set monitor_service_url ""
}

set page_title {}
set context {}
