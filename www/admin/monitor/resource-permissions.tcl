# 

ad_page_contract {
    
    Script to set permissions on the UoL resources (XoWiki)
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-10-16
    @arch-tag: 
    @cvs-id $Id$
} {
    run_id
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

set imsld_item_id [content::revision::item_id -revision_id $imsld_id]

multirow create objects object_id name
db_1row select_methods {
    select method_id, object_title as method_title, item_id as method_item_id
    from imsld_methodsi
    where imsld_id = :imsld_item_id
}

db_multirow plays select_plays {
    select play_id, title as play_title, item_id as play_item_id
    from imsld_playsi
    where method_id = :method_item_id
}

multirow append objects $method_id $method_title

db_foreach select_plays {
    select play_id, title as play_title, item_id as play_item_id
    from imsld_playsi
    where method_id = :method_item_id
} {
    set prefix [string repeat "&nbsp;" 2]
    multirow append objects $play_id "$prefix$play_title"

    set acts_list [db_list_of_lists select_acts {
	select act_id, title as act_title, item_id as act_item_id
	from imsld_actsi
	where play_id = :play_item_id
    }]
    foreach act_list $acts_list {    
	foreach {act_id act_title act_item_id} $act_list {}
	set prefix [string repeat "&nbsp;" 4]
	multirow append objects $act_id "$prefix$act_title"

	db_foreach select_role_part {
	    select role_part_id, title as role_part_title, item_id as role_part_item_id,
	    learning_activity_id, support_activity_id, activity_structure_id
	    from imsld_role_partsi
	    where act_id = :act_item_id
	} {
	    set prefix [string repeat "&nbsp;" 6]
	    multirow append objects $role_part_id "$prefix$role_part_title"

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

	    set prefix [string repeat "&nbsp;" 8]
	    multirow append objects $activity_id "$prefix$activity_title"

	}
    }
}
