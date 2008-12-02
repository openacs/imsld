# 

ad_page_contract {
    
    Import role members from file
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-09-18
    @arch-tag: b829df3b-3282-4044-988e-a2947bd238ab
    @cvs-id $Id$
} {
    role_url:trim,notnull
    run_id:integer,notnull
}

array set response [ad_httpget -url $role_url]

if { $response(status) != 200 } {
    ad_return_complaint 1 "The provided URL could not be reached"
    ad_script_abort
}

set content $response(page)

set doc [dom parse $content]
set root [$doc documentElement]

set role_node_list [$root selectNodes {role-root}]

set role_node ""
if {[llength $role_node_list] != 1} {
    ad_return_complaint 1 "There must be only one 'role-root' node in the XML."
    ad_script_abort
}

set role_node [lindex $role_node_list 0]

db_1row select_imsld_info { *SQL* }

set imsldi_id [content::revision::item_id -revision_id $imsld_id]

array set groups [imsld::roles::create_groups_from_dom -node $role_node -run_id $run_id -imsld_id $imsldi_id]

foreach node [$root selectNodes {role-population/user}] {
    set id [$node getAttribute {identifier}]
    set user_id [party::get_by_email -email $id]
    if { $user_id eq "" } {
	continue
    }
    foreach group_node [$node selectNodes {role-occurrence-ref}] {
	set group [$group_node getAttribute {ref}]
	set group_id $groups($group)
	while { 1 } {
	    group::add_member -user_id $user_id -group_id $group_id	    
	    if { ![db_0or1row select_parent_group { *SQL* }] } {
		break
	    }
	}

    }
}

ad_returnredirect [export_vars -base imsld-finish {run_id imsld_id}]
