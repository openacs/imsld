# 

ad_page_contract {
    
    Script to set permissions on the UoL resources (XoWiki)
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-10-16
    @arch-tag: 
    @cvs-id $Id$
} {
    run_id
    play_id
} -properties {
} -validate {
} -errors {
}

db_1row imsld_info {
    select imsld_id 
    from imsld_runs
    where run_id = :run_id
}

multirow create roles group_id name role_p

set involved_roles [imsld::roles::get_list_of_roles -imsld_id $imsld_id]
set role_names [imsld::roles::get_roles_names -roles_list $involved_roles]

set involved_users [list]
foreach role $involved_roles name $role_names {
    set role_id [lindex $role 0]
    multirow append roles $role_id $name t
    set involved_users [concat $involved_users [imsld::roles::get_users_in_role -role_id [lindex $role 0] -run_id $run_id]]

    set groups [imsld::roles::get_role_instances -role_id $role_id -run_id $run_id]
    foreach group_id $groups {
	set group_name [group::get_element -group_id $group_id -element group_name]
	multirow append roles $group_id $group_name f
    }
}

db_multirow acts select_acts {
select act_id, title as act_title, item_id as act_item_id
from imsld_actsi
where play_id = :play_id
}
