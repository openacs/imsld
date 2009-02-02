# 

ad_page_contract {
    
    Sets the propper resource permissions
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-11-22
    @arch-tag: 
    @cvs-id $Id$
} {
    object_id:integer,notnull
    role_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set form [ns_getform]
set privilege [ns_set get $form "privilege_${object_id}_${role_id}"]

set role_item_id [content::revision::item_id -revision_id $role_id]
set role_type [acs_object::get_element -object_id $role_id -element object_type]

set group_id_list [list]

if { $role_type eq "imsld_role" } {
    db_foreach select_group {
	select object_id_two
	from acs_rels
	where object_id_one = :role_item_id
	and rel_type = 'imsld_role_group_rel'
    } {
	lappend group_id_list $object_id_two
    }
} else {
    lappend group_id_list $role_item_id
}

foreach group_id $group_id_list {
    switch $privilege {
	none {
	    permission::revoke -party_id $group_id -object_id $object_id -privilege read
	    permission::revoke -party_id $group_id -object_id $object_id -privilege write
	}
	read {
	    permission::grant -party_id $group_id -object_id $object_id -privilege read
	    permission::revoke -party_id $group_id -object_id $object_id -privilege write
	}
	write {
	    permission::grant -party_id $group_id -object_id $object_id -privilege read
	    permission::grant -party_id $group_id -object_id $object_id -privilege write
	}
    }
}
