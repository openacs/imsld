# 

ad_page_contract {
    
    Script to set permissions on the UoL resources (XoWiki)
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-10-16
    @arch-tag: 
    @cvs-id $Id$
} {
    run_id
    act_id
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

multirow create activities activity_id activity_title activity_item_id

db_foreach select_activitiess {
select role_part_id, title as role_part_title, item_id as role_part_item_id,
learning_activity_id, support_activity_id, activity_structure_id
from imsld_role_partsi
where act_id = :act_id
} {
    if { $learning_activity_id ne "" } {
	db_1row select_la {
	    select activity_id, title as activity_title, item_id as activity_item_id
	    from imsld_learning_activitiesi
	    where item_id = :learning_activity_id
	}
    } elseif { $support_activity_id ne ""} {
	db_1row select_sa {
	    select activity_id, title as activity_title, item_id as activity_item_id
	    from imsld_support_activitiesi
	    where item_id = :support_activity_id
	}
    } elseif { $activity_structure_id } {
	db_1row select_as {
	    select structure_id as activity_id, title as activity_title, item_id as activity_item_id
	    from imsld_activity_structuresi
	    where item_id = :activity_structure_id
	}
    }   
    multirow append activities $activity_id $activity_title $activity_item_id
}
