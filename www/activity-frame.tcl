# packages/imsld/www/activity-frame.tcl

ad_page_contract {

    This is the frame that contains the associated URLs of an activity

    @author Eduardo Pérez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    run_id:integer,notnull
    activity_id:integer,notnull
    {role_id ""}
    {supported_user_id ""}
    {user_id ""}
}

set user_id [expr { [string eq $user_id ""] ? [ad_conn user_id] : $user_id }]

set roles_template_p 0
db_1row context_info {
    select r.imsld_id,
    case
    when exists (select 1 from imsld_learning_activities where activity_id = :activity_id)
    then 'learning'
    when exists (select 1 from imsld_support_activities where activity_id = :activity_id)
    then 'support'
    when exists (select 1 from imsld_activity_structures where structure_id = :activity_id)
    then 'structure'
    end as activity_type
    from imsld_runs r
    where run_id = :run_id
}

# make sure the activity is marked as started for this user
db_dml mark_activity_started {
    insert into imsld_status_user (imsld_id,
                                   run_id,
                                   related_id,
                                   user_id,
                                   type,
                                   status_date,
                                   status) 
    (
     select :imsld_id,
     :run_id,
     :activity_id,
     :user_id,
     :activity_type,
     now(),
     'started'
     where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :activity_id and status = 'started')
     )
}

set activity_item_id [content::revision::item_id -revision_id $activity_id]

set referencer_structure_item_id ""

if { [string eq $activity_type "learning"] } {
    if { [string eq "" [db_string completion_restriction {select complete_act_id from imsld_learning_activities where activity_id = :activity_id}]] } {
	# the learning activity has been visited and doesn't have any completion restriction.
	# if it is referenced from an activity structure, verify if every referenced activity have been visted
	db_0or1row referenced_from_structure_p {
	    select ar.object_id_one as referencer_structure_item_id
	    from acs_rels ar
	    where ar.object_id_two = :activity_item_id
	}
    }
} elseif { [string eq $activity_type "support"] } {
    if { [string eq "" [db_string completion_restriction {select complete_act_id from imsld_support_activities where activity_id = :activity_id}]] } {
	# the learning activity has been visited and doesn't have any completion restriction.
	# if it is referenced from an activity structure, verify if every referenced activity have been visted
	db_0or1row referenced_from_structure_p {
	    select ar.object_id_one as referencer_structure_item_id
	    from acs_rels ar
	    where ar.object_id_two = :activity_item_id
	}
    }
}

if { ![string eq "" $referencer_structure_item_id] } {
    db_1row get_structure_info {
	select structure_id,
	number_to_select
	from imsld_activity_structuresi
	where item_id = :referencer_structure_item_id
	and content_revision__is_live(structure_id) = 't'
    }
    
    # if the structure hasn't been finished
    if { ![db_0or1row already_finished {
	select 1
	from imsld_status_user
	where related_id = :structure_id
	and user_id = :user_id
	and run_id = :run_id
	and status = 'finished'
    }] } {
	set mark_structure_finished_p 1
	set total_completed 0
	foreach referenced_activity [db_list_of_lists struct_referenced_activities {
	    select ar.object_id_two,
	    ar.rel_type
	    from acs_rels ar
	    where ar.object_id_one = :referencer_structure_item_id
	    order by ar.object_id_two
	}] {
	    set object_id_two [lindex $referenced_activity 0]
	    set rel_type [lindex $referenced_activity 1]
	    switch $rel_type {
		imsld_as_la_rel {
		    # if the activity doesn't have any completrion restriction 
		    # and it hasn't been started, cancel the completion of the structure
		    set referenced_activity_id [content::item::get_live_revision -item_id $object_id_two]
		    set la_completion_restriction [db_string la_completion_restriction {
			select complete_act_id
			from imsld_learning_activities
			where activity_id = :referenced_activity_id
		    }]
		    if { ([db_0or1row la_already_started_p {
			select 1
			from imsld_status_user
			where related_id = :referenced_activity_id
			and user_id = :user_id
			and run_id = :run_id
			and status = 'started'
		    }] && [string eq "" $la_completion_restriction]) \
			     || [db_0or1row la_already_finished {
				 select 1
				 from imsld_status_user
				 where related_id = :referenced_activity_id
				 and user_id = :user_id
				 and run_id = :run_id
				 and status = 'finished'
			     }] } {
			# the activity has been visited
			incr total_completed
		    } else {
			set mark_structure_finished_p 0
			break
		    }
		}
		imsld_as_sa_rel {
		    # if the activity doesn't have any completrion restriction 
		    # and it hasn't been started, cancel the completion of the structure
		    set referenced_activity_id [content::item::get_live_revision -item_id $object_id_two]
		    if { ([db_0or1row la_already_started_p {
			select 1
			from imsld_status_user
			where related_id = :referenced_activity_id
			and user_id = :user_id
			and run_id = :run_id
			and status = 'started'
		    }] && [string eq "" $sa_completion_restriction]) \
			     || [db_0or1row la_already_finished {
				 select 1
				 from imsld_status_user
				 where related_id = :referenced_activity_id
				 and user_id = :user_id
				 and run_id = :run_id
				 and status = 'finished'
			     }] } {
			# the activity has been visited
			incr total_completed
		    } else {
			set mark_structure_finished_p 0
			break
		    }
		} imsld_as_as_rel {
		    # if the referenced activity structure hasn't been finished, don't finish the activity structure
		    set structure_id [content::item::get_live_revision -item_id $object_id_two]
		    if { ![db_0or1row sa_already_finished_p {
			select 1
			from imsld_status_user
			where related_id = :referenced_activity_id
			and user_id = :user_id
			and run_id = :run_id
			and status = 'finished'
		    }] } {
			set mark_structure_finished_p 0
			break
		    } else {
			incr total_completed
		    }
		}
	    }
	}
	if { $mark_structure_finished_p || (![string eq $number_to_select ""] && ($total_completed >= $number_to_select)) } {
	    # mark the structure as finished

	    set role_part_id_list [imsld::get_role_part_from_activity -activity_type structure -leaf_id $referencer_structure_item_id]
	    foreach role_part_id $role_part_id_list {
	    db_1row context_info {
		select acts.act_id,
		plays.play_id
		from imsld_actsi acts, imsld_playsi plays, imsld_role_parts rp
		where rp.role_part_id = :role_part_id
		and rp.act_id = acts.item_id
		and acts.play_id = plays.item_id
	    }
		imsld::finish_component_element -imsld_id $imsld_id \
		-run_id $run_id \
		-play_id $play_id \
		-act_id $act_id \
		-role_part_id $role_part_id \
		-element_id $structure_id \
		-type structure \
		-user_id $user_id \
		-code_call
	    }
	}
    }
}

set supported_roles [db_list supported_roles_list { select iri.role_id 
                                             from imsld_rolesi iri, 
                                             acs_rels ar,  
                                             imsld_support_activitiesi isai 
                                             where iri.item_id=ar.object_id_two 
                                             and ar.rel_type='imsld_sa_role_rel' 
                                             and ar.object_id_one=isai.item_id 
                                             and isai.activity_id =:activity_id }]

if {[llength $supported_roles]} {
    set roles_template_p 1 
}

if { !$roles_template_p } {

    dom createDocument div doc
    set dom_root [$doc documentElement]
    $dom_root setAttribute class "tabber"
    
    set activity_item_id [content::revision::item_id -revision_id $activity_id]
    imsld::process_activity_as_ul -activity_item_id $activity_item_id -run_id $run_id -dom_doc $doc -dom_node $dom_root
    
    if { ![string eq $activity_id ""] && [db_0or1row get_table_name {
        select 
        case 
        when exists (select 1 from imsld_learning_activities where activity_id=:activity_id) 
        then 'imsld_learning_activities' 
        when exists (select 1 from imsld_support_activities where activity_id=:activity_id) 
        then 'imsld_support_activities' 
        end as table_name 
        from dual
    }] && ![string eq "" $table_name] } {
        #grant permissions to resources in activity
        set resources_list [db_list get_resources_from_activity "
                        select ar2.object_id_two 
                        from $table_name ila,
                        acs_rels ar1,
                        acs_rels ar2 
                        where activity_id=:activity_id
                        and ar1.object_id_one=ila.activity_description_id 
                        and ar1.rel_type='imsld_actdesc_item_rel' 
                        and ar1.object_id_two=ar2.object_id_one 
                        and ar2.rel_type='imsld_item_res_rel'
    "]
        
        if {[string eq 'imsld_learning_activities' $table_name]} {
            
            set prerequisites_list [db_list get_prerequisites_list "
                           select ar2.object_id_two 
                           from acs_rels ar1, 
                                acs_rels ar2, 
                                $table_name tn 
                           where tn.activity_id=:activity_id 
                                 and ar1.object_id_one=tn.prerequisite_id 
                                 and ar1.rel_type='imsld_preq_item_rel' 
                                 and ar1.object_id_two=ar2.object_id_one 
                                 and ar2.rel_type='imsld_item_res_rel' 
        "]
            set objectives_list [db_list get_objectives_list "
                           select ar2.object_id_two 
                           from acs_rels ar1, 
                                acs_rels ar2, 
                                $table_name tn 
                           where tn.activity_id=:activity_id 
                                 and ar1.object_id_one=tn.learning_objective_id 
                                 and ar1.rel_type='imsld_lo_item_rel' 
                                 and ar1.object_id_two=ar2.object_id_one 
                                 and ar2.rel_type='imsld_item_res_rel'
        "]
        } else {
            set prerequisites_list [list]
            set objectives_list [list]
        }
        set resources_list [concat $resources_list [concat $prerequisites_list $objectives_list]]
        imsld::grant_permissions -resources_activities_list $resources_list -user_id $user_id -run_id $run_id
    }
    set activities [$dom_root asXML] 
} else {
    # a user has been selected to be supported
    # get the associated resource of the support activity
    db_1row activity_info {
        select ii.imsld_item_id
        from imsld_items ii, imsld_activity_descs sad, imsld_support_activities sa,
        cr_items cr1, cr_items cr2,
        acs_rels ar
        where sa.activity_id = :activity_id
        and sa.activity_description_id = cr1.item_id
        and cr1.live_revision = sad.description_id
        and ar.object_id_one = sa.activity_description_id
        and ar.object_id_two = cr2.item_id
        and cr2.live_revision = ii.imsld_item_id
    }
    
    db_1row support_activity_associated_item {
        select cpr.resource_id,
        cpr.item_id as resource_item_id,
        cpr.type as resource_type
        from imsld_cp_resourcesi cpr, imsld_itemsi ii,
        acs_rels ar
        where ar.object_id_one = ii.item_id
        and ar.object_id_two = cpr.item_id
        and content_revision__is_live(cpr.resource_id) = 't'
        and ii.imsld_item_id = :imsld_item_id
    }
    
    set activities [export_vars -base "imsld-content-serve" -url { run_id resource_item_id role_id {owner_user_id $supported_user_id} }]
}


set page_title {}
set context [list]
