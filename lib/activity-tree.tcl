
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

    set completed_p [db_0or1row already_completed {
        select 1 from imsld_status_user 
        where related_id = :activity_id 
        and user_id = :user_id 
        and run_id = :run_id
        and status = 'finished'
    }]

    if {$type ne {structure}} {
        set visible_p [db_string get_visible {
            select attr.is_visible_p
            from imsld_attribute_instances attr
            where attr.owner_id = :activity_id
            and attr.run_id = :run_id
            and attr.user_id = :user_id
            and attr.type = 'isvisible'
        }]

        if { $visible_p && ($completed_p || [lsearch -exact $next_activity_id_list $activity_id] != -1)} {
            multirow append activities $activity_id $type $play_id $act_id $role_part_id
        }

    } else {

        set started_p [db_0or1row as_started_p { *SQL* }]
        set has_visible_child_p [imsld::runtime::activity_structure::has_visible_child_p \
                                     -run_id $run_id \
                                     -user_id $user_id \
                                     -structure_id $activity_id]
        if { $started_p && $has_visible_child_p } {
            multirow append activities $activity_id $type $play_id $act_id $role_part_id
        }
    }
}
