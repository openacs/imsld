ad_page_contract {
    @author jopez@inv.it.uc3m.es
    @creation-date Mar 2006
} {
    run_id:integer,notnull
    {current_role_id ""}
}

# initialize variables
set page_title "[_ imsld.units-of-learning]"
set context ""
set community_id [dotlrn_community::get_community_id]
set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]
set user_id [ad_conn user_id]
set community_url [dotlrn_community::get_community_url $community_id]

db_1row imslds_in_class {
    select imsld.item_id as imsld_item_id,
    imsld.imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title
    from imsld_imsldsi imsld, imsld_runs run
    where imsld.imsld_id = run.imsld_id
    and run.run_id = :run_id
} 

# current role information.
# the user must have an active role in the run
set possible_user_roles [imsld::roles::get_user_roles -user_id $user_id \
			     -run_id $run_id]
set possible_user_role_names [imsld::roles::get_roles_names \
				  -roles_list $possible_user_roles]
# remove &nbsp; added in the previous proc
regsub -all "&nbsp;" $possible_user_role_names "" $possible_user_role_names

# if there is only one role, set it
set current_role_id [expr { [llength $possible_user_roles] == 1 ? [lindex $possible_user_roles 0] : "$current_role_id" }]

if { ![empty_string_p $current_role_id] } {
    # a role has been selected, update in db
    db_dml update_current_role {
        update imsld_run_users_group_rels
        set active_role_id = :current_role_id
        where rel_id = (select ar.rel_id
                        from acs_rels ar, imsld_run_users_group_ext iruge
                        where ar.object_id_one = iruge.group_id
                        and ar.object_id_two = :user_id
                        and iruge.run_id = :run_id)
    }
}

if { ![db_0or1row get_current_role {
    select map.active_role_id as user_role_id
    from imsld_run_users_group_rels map,
    acs_rels ar,
    imsld_run_users_group_ext iruge
    where ar.rel_id = map.rel_id
    and ar.object_id_one = iruge.group_id
    and ar.object_id_two = :user_id
    and iruge.run_id = :run_id
    and map.active_role_id is not null
}] } {
    # no role have been selected, generate the first option
    set possible_user_roles [linsert $possible_user_roles 0 0]
    set possible_user_role_names [linsert $possible_user_role_names 0 "[_ imsld.Select_role]"]
    set user_role_id -1
}

template::multirow create possible_roles item_id item_name

foreach role $possible_user_roles {
    template::multirow append possible_roles \
	$role [lindex $possible_user_role_names \
		   [lsearch -exact $possible_user_roles $role]]
}

set user_message ""
set next_activity_id [imsld::get_next_activity_list -run_id $run_id -user_id $user_id]

set remaining_activities [llength [join $next_activity_id]] 

if {!$remaining_activities} {
    set all_finished [imsld::run_finished_p -run_id $run_id]
    if {$all_finished} {
        db_dml stop_run { 
            update imsld_runs 
            set status='stopped' 
            where run_id=:run_id
        }
    } else {
         set user_message "[_ imsld.lt_Please_wait_for_other]"
    }
}

set run_status [db_string get_run_status {
    select status
    from imsld_runs
    where run_id=:run_id
}]

if {[string eq "stopped" $run_status]} {
    set user_message "[_ imsld.lt_The_course_has_been_f]"
}

if { $user_role_id == -1 } {
    set aux_html_tree ""
} else {

    # runtime generated activities (notifications, level C)
    if { [db_string generated_activities_p { *SQL* } -default 0] > 0 } {
        dom createDocument ul aux_doc
        set aux_dom_root [$aux_doc documentElement]
        $aux_dom_root setAttribute class "mktree"
        set aux_title_node [$aux_doc createElement li]
        $aux_title_node setAttribute class "liOpen"
        set text [$aux_doc createTextNode "[_ imsld.Extra_Activities]"] 
        $aux_title_node appendChild $text
        $aux_dom_root appendChild $aux_title_node
        
        set aux_activities_node [$aux_doc createElement ul]
        imsld::generate_runtime_assigned_activities_tree -run_id $run_id \
            -user_id $user_id \
            -dom_node $aux_activities_node \
            -dom_doc $aux_doc
        
        $aux_title_node appendChild $aux_activities_node
        
        set aux_html_tree [$aux_dom_root asXML]

	$aux_doc delete
    } else {
        set aux_html_tree ""
    }
    
}

set select_string "[_ imsld.Select_role]"
