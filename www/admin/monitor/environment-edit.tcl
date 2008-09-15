# 

ad_page_contract {
    
    Adds/removes an URL from an environment
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-06-25
    @arch-tag: f613a6f2-6b3c-4bd2-a1a9-d4196126f6d8
    @cvs-id $Id$
} {
    activity_id:integer,notnull
    environment_id:integer,notnull
    run_id:integer,notnull
    {url ""}
    {title ""}
    {item_id 0}
}

if { $item_id } {
    content::item::unset_live_revision -item_id $item_id
}

if { $url ne "" } {

    set e_item_id [content::revision::item_id -revision_id $environment_id]
    ns_log notice $e_item_id
    set parent_id [content::item::get_parent_folder \
		       -item_id $e_item_id]

    set r_item_id [db_nextval "acs_object_id_seq"]
    set identifier "resource-grail-${r_item_id}"
    set item_name "${r_item_id}_[string tolower $identifier]"
    set content_type imsld_cp_resource
    set type "webcontent"

    set learning_object_id [imsld::item_revision_new -attributes [list [list is_visible_p "t"] \
                                                                      [list identifier "resource-grail-${r_item_id}"] \
                                                                      [list environment_id $e_item_id] \
								      [list type "webcontent"]] \
                                -content_type imsld_learning_object \
				-title $title \
                                -parent_id $parent_id]

    set item_id [imsld::item_revision_new -title $url \
                     -content_type imsld_item \
                     -attributes [list [list identifierref $identifier] \
                                      [list is_visible_p "t"]] \
		     -parent_id $parent_id]

    relation_add imsld_l_object_item_rel $learning_object_id $item_id
    
    set resource_id [imsld::cp::resource_new \
			 -manifest_id "" \
			 -item_id $r_item_id \
			 -identifier $identifier \
			 -type $type \
			 -href $url \
			 -parent_id $parent_id]

    # map item with resource
    relation_add imsld_item_res_rel $item_id $resource_id

    set link_id [content::extlink::new -url $url \
		     -parent_id $parent_id] 
   # map resource with file
    set extra_vars [util_list_to_ns_set [list displayable_p "t"]]
    relation_add -extra_vars $extra_vars imsld_res_files_rel $r_item_id $link_id

    set imsld_id [db_string select_imsld {
	select imsld_id
	from imsld_runs
	where run_id = :run_id
    }]

    set users_list [list]
    foreach role_id [imsld::roles::get_list_of_roles -imsld_id $imsld_id] {
	set users_list [concat $users_list [imsld::roles::get_users_in_role -role_id [lindex $role_id 0] -run_id $run_id]]
    }

    ns_log notice $users_list
    
    set rev_object_id [content::item::get_live_revision -item_id $learning_object_id]
    foreach user_id $users_list {
	# instantiating properties and activity attributes for the run
	db_foreach nested_associated_items {
	    select ii.imsld_item_id, ii.item_id,
	    coalesce(ii.is_visible_p, 't') as is_visible_p,
	    ii.identifier
	    from imsld_itemsi ii
	    where 
	    (imsld_tree_sortkey between 
	     tree_left((select imsld_tree_sortkey from 
			imsld_items where imsld_item_id = :rev_object_id))
	     and 
	     tree_right((select imsld_tree_sortkey from 
			 imsld_items where imsld_item_id = :rev_object_id))
	     or ii.imsld_item_id = :rev_object_id)
	} {
	    if { ![db_0or1row info_as_already_instantiated_p {
		select 1
		from imsld_attribute_instances
		where owner_id = :imsld_item_id
		and run_id = :run_id
		and user_id = :user_id
		and type = 'isvisible'
	    }] } {
		set instance_id \
		    [package_exec_plsql \
			 -var_list [list [list instance_id ""] \
					[list owner_id $imsld_item_id] \
					[list type "isvisible"] \
					[list identifier $identifier] \
					[list run_id $run_id] \
					[list user_id $user_id] \
					[list is_visible_p "t"] \
					[list title ""] \
					[list with_control_p ""]] \
			 imsld_attribute_instance new]
	    }
	}
	
    }
}
    

ad_returnredirect [export_vars -base "environment-frame" {activity_id environment_id run_id}]
