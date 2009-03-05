
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

# get the referenced role parts
foreach role_part_list [db_list_of_lists referenced_role_parts { *SQL* }] {
    set type [lindex $role_part_list 0]
    set activity_id [lindex $role_part_list 1]
    set role_part_id [lindex $role_part_list 2]
    set act_id [lindex $role_part_list 3]
    set play_id [lindex $role_part_list 4]

    multirow append activities $activity_id $type $play_id $act_id $role_part_id
}
