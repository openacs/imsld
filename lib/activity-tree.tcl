
multirow create activities activity_id type play_id act_id role_part_id

db_1row imslds_in_class {
    select imsld.item_id as imsld_item_id,
    imsld.imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title
    from imsld_imsldsi imsld, imsld_runs run
    where imsld.imsld_id = run.imsld_id
    and run.run_id = :run_id
} 

# start with the role parts
set imsld_package_id [ad_conn package_id]

set user_role_id [db_string current_role {
    select map.active_role_id as user_role_id
    from imsld_run_users_group_rels map,
    acs_rels ar,
    imsld_run_users_group_ext iruge
    where ar.rel_id = map.rel_id
    and ar.object_id_one = iruge.group_id
    and ar.object_id_two = :user_id
    and iruge.run_id = :run_id
}]
set active_acts_list [imsld::active_acts -run_id $run_id -user_id $user_id]

# get the referenced role parts
foreach role_part_list [db_list_of_lists referenced_role_parts { *SQL* }] {
    set type [lindex $role_part_list 0]
    set activity_id [lindex $role_part_list 1]
    set role_part_id [lindex $role_part_list 2]
    set act_id [lindex $role_part_list 3]
    set act_item_id [lindex $role_part_list 4]
    set play_id [lindex $role_part_list 5]

    if {$type ne {structure}} {
	multirow append activities $activity_id $type $play_id $act_id $role_part_id
    } else {
	set started_p [db_0or1row as_started_p { *SQL* }]
	if { $started_p } {
	    multirow append activities $activity_id $type $play_id $act_id $role_part_id
	}
    }
}
