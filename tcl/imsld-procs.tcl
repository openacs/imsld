# /packages/imsld/tcl/imsld-procs.tcl

ad_library {
    Procedures in the imsld namespace.
    
    @creation-date Aug 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::map {}

ad_proc -public imsld::safe_url_name { 
    -name:required
} { 
    returns the filename replacing some characters
} {  
    regsub -all {[<>:\"|/@\\\#%&+\\ ,\?]} $name {_} name
    return $name
} 

ad_proc -public imsld::package_key { 
} { 
    returns the package_key of the IMS-LD package
} {  
    return imsld
} 

ad_proc -public imsld::object_type_image_path {
    -object_type
} { 
    returns the path to the image representing the given object_type in the
    imsld package
} { 
    set community_id [dotlrn_community::get_community_id]
    set imsld_package_id \
	[site_node_apm_integration::get_child_package_id \
	     -package_id [dotlrn_community::get_package_id $community_id] \
	     -package_key "[imsld::package_key]"]
    switch $object_type {
        forums_forum {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/forums.png"
        }
        as_assessments {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/assessment.png"
        }
        sessions {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/sessions.png"
        }
        send-mail {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/send-mail.png"
        }
        ims_manifest_object {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/lors.png"
        }
        url {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/url.png"
        }
        default {
            set image_path "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/file-storage.png"
        }
    }
    return $image_path
} 

ad_proc -public imsld::map::role_to_activity { 
    -run_id
    -activity_id
    -role_id
} { 
    @param run_id
    @param activity_id
    @param role_id
    
    @return The rel_id created
} {
    if { [db_0or1row existing_rel {
        select rel_id
        from imsld_runtime_activities_rels
        where run_id = :run_id
        and activity_id = :activity_id
        and role_id = :role_id
    }] } {
        return $rel_id
    }
    
    set rel_id [db_nextval acs_object_id_seq]
    db_dml insert_mapping {
        insert into imsld_runtime_activities_rels (rel_id, run_id, activity_id, role_id)
        select imsld_rar_seq.nextval, :run_id, :activity_id, :role_id from dual
    }
} 

ad_proc -public imsld::get_role_part_from_activity {
    -activity_type
    -leaf_id
} { 
    @return A the list of role_part_ids that reference the given activity_item_id (leaf_id)
} {
    switch $activity_type {
        learning {
            set role_part_list [list]
            set referncer_list [db_list la_directly_mapped { *SQL* }]
            if { [llength $referncer_list] } {
                set role_part_list [concat $role_part_list $referncer_list]
            }
            # check if the learning activity is referenced by some activity structures... digg more
            foreach la_structure_list [db_list_of_lists get_la_activity_structures { *SQL* }] {
                set stucture_id [lindex $la_structure_list 0]
                set leaf_id [lindex $la_structure_list 1]
                set referencer_list [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
                if { [llength $referencer_list] } {
                    set role_part_list [concat $role_part_list $referencer_list]
                }
            }
            return $role_part_list
        }
        support {
            set role_part_list [list]
            set referncer_list [db_list sa_directly_mapped { *SQL* }]
            if { [llength $referncer_list] } {
                set role_part_list [concat $role_part_list $referncer_list]
            }
            # check if the support activity is referenced by some activity structures... digg more
            foreach sa_structure_list [db_list_of_lists get_sa_activity_structures { *SQL* }] {
                set stucture_id [lindex $sa_structure_list 0]
                set leaf_id [lindex $sa_structure_list 1]
                set referencer_list [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
                if { [llength $referencer_list] } {
                    set role_part_list [concat $role_part_list $referencer_list]
                }
            }
            return $role_part_list
        }
        structure {
            set role_part_list [list]
            set referncer_list [db_list as_directly_mapped { *SQL* }]
            if { [llength $referncer_list] } {
                set role_part_list [concat $role_part_list $referncer_list]
            }
            # check if the activity structure is referenced by an activity structure... digg more
            foreach sa_structure_list [db_list_of_lists get_as_activity_structures { *SQL* }] {
                set stucture_id [lindex $sa_structure_list 0]
                set leaf_id [lindex $sa_structure_list 1] 
                set referencer_list [imsld::get_role_part_from_activity -activity_type structure -leaf_id $leaf_id]
                if { [llength $referencer_list] } {
                    set role_part_list [concat $role_part_list $referencer_list]
                } 
            }
            return $role_part_list
        }
    }
} 

ad_proc -public imsld::community_id_from_manifest_id {
    -manifest_id:required
} { 
    returns the community_id using the manifest_id to search for it
} {  
    return [db_string get_community_id {
        select dc.community_id
        from imsld_cp_manifestsi im, acs_objects ao, dotlrn_communities dc
        where im.object_package_id = ao.package_id
        and ao.context_id = dc.package_id
        and im.manifest_id = :manifest_id
    }]
} 

ad_proc -public imsld::sweep_expired_activities { 
} { 
    Sweeps the methods, plays, acts  and activities marking as finished the ones that already have been expired according with the value of time-limit.
} {
    ns_log notice "imsld::sweep_expired_activities Sweeping methods.."
    # 1. methods
    foreach referenced_method [db_list_of_lists possible_expired_method { *SQL* }] {
        set manifest_id [lindex $referenced_method 0]
        set imsld_id [lindex $referenced_method 1]
        set method_id [lindex $referenced_method 2]
        set run_id [lindex $referenced_method 3]
        set time_in_seconds [lindex $referenced_method 4]
        set creation_date [lindex $referenced_method 5]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the method has been expired, let's mark it as finished 
            db_foreach user_in_run { *SQL* } {
                imsld::mark_method_finished -imsld_id $imsld_id \
                    -run_id $run_id \
                    -method_id $method_id \
                    -user_id $user_id
            }
        }
    }
    ns_log notice "imsld::sweep_expired_activities Sweeping plays..."
    # 2. plays
    foreach referenced_play [db_list_of_lists possible_expired_plays { *SQL* }] {
        set manifest_id [lindex $referenced_play 0]
        set imsld_id [lindex $referenced_play 1]
        set play_id [lindex $referenced_play 2]
        set time_in_seconds [lindex $referenced_play 3]
        set creation_date [lindex $referenced_play 4]
        set run_id [lindex $referenced_play 5]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the play has been expired, let's mark it as finished 
            db_foreach user_in_run { *SQL* } {
                imsld::mark_play_finished -imsld_id $imsld_id \
                    -run_id $run_id \
                    -play_id $play_id \
                    -user_id $user_id
            }
            foreach condition_xml [db_list search_related_conditions {
                                                                select ici.condition_xml 
                                                                from imsld_conditionsi ici,
                                                                     acs_rels ar, 
                                                                     imsld_playsi ilai 
                                                                where ilai.item_id=ar.object_id_one 
                                                                      and ar.rel_type='imsld_ilm_cond_rel' 
                                                                      and ilai.play_id=:play_id
                                                                      and ici.item_id=ar.object_id_two
            }] { 
               dom parse $condition_xml document
               $document documentElement condition_node
               imsld::condition::execute -run_id $run_id -condition $condition_node
            }
            #role conditions, time conditions...
            imsld::condition::execute_time_role_conditions -run_id $run_id
        }
    }
    ns_log notice "imsld::sweep_expired_activities Sweeping acts..."
    # 3. acts
    foreach referenced_act [db_list_of_lists possible_expired_acts { *SQL* }] {
        set manifest_id [lindex $referenced_act 0]
        set imsld_id [lindex $referenced_act 1]
        set play_id [lindex $referenced_act 2]
        set act_id [lindex $referenced_act 3]
        set time_in_seconds [lindex $referenced_act 4]
        set creation_date [lindex $referenced_act 5]
        if { [db_0or1row compre_times {
            select 1
            where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
        }] } {
            # the act has been expired, let's mark it as finished 
            db_foreach user_in_run { *SQL* } {
                imsld::mark_act_finished -imsld_id $imsld_id \
                    -run_id $run_id \
                    -play_id $play_id \
                    -act_id $act_id \
                    -user_id $user_id
            }
            foreach condition_xml [db_list search_related_conditions {
                                                                select ici.condition_xml 
                                                                from imsld_conditionsi ici,
                                                                     acs_rels ar, 
                                                                     imsld_actsi ilai 
                                                                where ilai.item_id=ar.object_id_one 
                                                                      and ar.rel_type='imsld_ilm_cond_rel' 
                                                                      and ilai.act_id=:act_id
                                                                      and ici.item_id=ar.object_id_two
            }] { 
               dom parse $condition_xml document
               $document documentElement condition_node
               imsld::condition::execute -run_id $run_id -condition $condition_node
            }
            #role conditions, time conditions...
            imsld::condition::execute_time_role_conditions -run_id $run_id 
        }
    }
    ns_log notice "imsld::sweep_expired_activities Sweeping support activities..."
    # 4. support activities
    foreach referenced_sa [db_list_of_lists referenced_sas { *SQL* }] {
        set sa_item_id [lindex $referenced_sa 0]
        set activity_id [lindex $referenced_sa 1]
        set time_in_seconds [lindex $referenced_sa 2]
        set role_part_id_list [imsld::get_role_part_from_activity -activity_type support -leaf_id $sa_item_id]
        set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
        foreach role_part_id $role_part_id_list {
            foreach referencer_list [db_list_of_lists sa_referencer { *SQL* }] {
                set manifest_id [lindex $referencer_list 0]
                set role_part_id [lindex $referencer_list 1]
                set imsld_id [lindex $referencer_list 2]
                set play_id  [lindex $referencer_list 3]
                set act_id [lindex $referencer_list 4]
                set creation_date [lindex $referencer_list 5]
                set run_id [lindex $referencer_list 6]

                if { [db_0or1row compre_times {
                    select 1
                    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
                }] } {
                    # the act has been expired, let's mark it as finished 
                    db_foreach user_in_run { *SQL* } {
                        imsld::finish_component_element -imsld_id $imsld_id \
                            -run_id $run_id \
                            -play_id $play_id \
                            -act_id $act_id \
                            -role_part_id $role_part_id \
                            -element_id $activity_id \
                            -type support \
                            -user_id $user_id \
                            -code_call
                    }
                    foreach condition_xml [db_list search_related_conditions {
                                                                        select ici.condition_xml 
                                                                        from imsld_conditionsi ici,
                                                                             acs_rels ar, 
                                                                             imsld_support_activitiesi ilai 
                                                                        where ilai.item_id=ar.object_id_one 
                                                                              and ar.rel_type='imsld_ilm_cond_rel' 
                                                                              and ilai.activity_id=:activity_id
                                                                              and ici.item_id=ar.object_id_two
                    }] { 
                       dom parse $condition_xml document
                       $document documentElement condition_node
                       imsld::condition::execute -run_id $run_id -condition $condition_node
                    }
                    #role conditions, time conditions...
                    imsld::condition::execute_time_role_conditions -run_id $run_id
                }
            }
        }
    }
    ns_log notice "imsld::sweep_expired_activities Sweeping learning activities..."
    # 5. learning activities
    foreach referenced_la [db_list_of_lists referenced_las { *SQL* }] {
        set la_item_id [lindex $referenced_la 0]
        set activity_id [lindex $referenced_la 1]
        set time_in_seconds [lindex $referenced_la 2]
        set role_part_id_list [imsld::get_role_part_from_activity -activity_type learning -leaf_id $la_item_id]
        foreach role_part_id $role_part_id_list {
            foreach referencer_list [db_list_of_lists la_referencer { *SQL* }] {
                set manifest_id [lindex $referencer_list 0]
                set role_part_id [lindex $referencer_list 1]
                set imsld_id [lindex $referencer_list 2]
                set play_id  [lindex $referencer_list 3]
                set act_id [lindex $referencer_list 4]
                set creation_date [lindex $referencer_list 5]
                set run_id [lindex $referencer_list 6]

                if { [db_0or1row compre_times {
                    select 1
                    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
                }] } {
                    # the act has been expired, let's mark it as finished 
                    #                set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
                    db_foreach user_in_run { *SQL* } {
                        imsld::finish_component_element -imsld_id $imsld_id \
                            -run_id $run_id \
                            -play_id $play_id \
                            -act_id $act_id \
                            -role_part_id $role_part_id \
                            -element_id $activity_id \
                            -type learning \
                            -user_id $user_id \
                            -code_call
                    }
                    foreach condition_xml [db_list search_related_conditions {
                                                                        select ici.condition_xml 
                                                                        from imsld_conditionsi ici,
                                                                             acs_rels ar, 
                                                                             imsld_learning_activitiesi ilai 
                                                                        where ilai.item_id=ar.object_id_one 
                                                                              and ar.rel_type='imsld_ilm_cond_rel' 
                                                                              and ilai.activity_id=:activity_id
                                                                              and ici.item_id=ar.object_id_two
                    }] { 
                       dom parse $condition_xml document
                       $document documentElement condition_node
                       imsld::condition::execute -run_id $run_id -condition $condition_node
                    }
                    #role conditions, time conditions...
                    imsld::condition::execute_time_role_conditions -run_id $run_id
                }
            }
        }

    }
}

ad_proc -public imsld::finish_expired_activity {
    -activity_id:required
} { 
    Expire a given activity (method, play, act or learning/support
    activity). This is based on imsld::sweep_expired_activities but
    intended to be faster, callsed on a scheduled way.
} {
    set imsld_type [content::item::get_content_type -item_id $activity_id]

    switch $imsld_type {

	imsld_method {
	    ns_log notice "imsld::finish_expired_activity Sweeping methods.."
	    # 1. methods
	    if {[db_0or1row possible_expired_method { *SQL* }]} {
		if { [db_0or1row compre_times {
		    select 1
		    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
		}] } {
		    # the method has been expired, let's mark it as finished 
		    db_foreach user_in_run { *SQL* } {
			imsld::mark_method_finished -imsld_id $imsld_id \
			    -run_id $run_id \
			    -method_id $method_id \
			    -user_id $user_id
		    }
		}
	    }
	}

	imsld_play {
	    ns_log notice "imsld::finish_expired_activity Sweeping plays..."
	    # 2. plays
	    if {[db_0or1row possible_expired_play { *SQL* }]} {
		if { [db_0or1row compre_times {
		    select 1
		    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
		}] } {
		    # the play has been expired, let's mark it as finished 
		    db_foreach user_in_run { *SQL* } {
			imsld::mark_play_finished -imsld_id $imsld_id \
			    -run_id $run_id \
			    -play_id $play_id \
			    -user_id $user_id
		    }
		    foreach condition_xml [db_list search_related_conditions {
			select ici.condition_xml 
			from imsld_conditionsi ici,
			acs_rels ar, 
			imsld_playsi ilai 
			where ilai.item_id=ar.object_id_one 
			and ar.rel_type='imsld_ilm_cond_rel' 
			and ilai.play_id=:play_id
			and ici.item_id=ar.object_id_two
		    }] { 
			dom parse $condition_xml document
			$document documentElement condition_node
			imsld::condition::execute -run_id $run_id -condition $condition_node
		    }
		    #role conditions, time conditions...
		    imsld::condition::execute_time_role_conditions -run_id $run_id
		}
	    }
	}

	imsld_act {
	    ns_log notice "imsld::finish_expired_activity Sweeping acts..."
	    # 3. acts
	    if {[db_0or1row possible_expired_act { *SQL* }]} {
		if { [db_0or1row compre_times {
		    select 1
		    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
		}] } {
		    # the act has been expired, let's mark it as finished 
		    db_foreach user_in_run { *SQL* } {
			imsld::mark_act_finished -imsld_id $imsld_id \
			    -run_id $run_id \
			    -play_id $play_id \
			    -act_id $act_id \
			    -user_id $user_id
		    }
		    foreach condition_xml [db_list search_related_conditions {
			select ici.condition_xml 
			from imsld_conditionsi ici,
			acs_rels ar, 
			imsld_actsi ilai 
			where ilai.item_id=ar.object_id_one 
			and ar.rel_type='imsld_ilm_cond_rel' 
			and ilai.act_id=:act_id
			and ici.item_id=ar.object_id_two
		    }] { 
			dom parse $condition_xml document
			$document documentElement condition_node
			imsld::condition::execute -run_id $run_id -condition $condition_node
		    }
		    #role conditions, time conditions...
		    imsld::condition::execute_time_role_conditions -run_id $run_id 
		}
	    }
	}

	imsld_support_activity {
	    ns_log notice "imsld::finish_expired_activity Sweeping support activities..."
	    # 4. support activities
	    if {[db_0or1row referenced_sas { *SQL* }]} {
		set role_part_id_list [imsld::get_role_part_from_activity -activity_type support -leaf_id $sa_item_id]
		set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]
		foreach role_part_id $role_part_id_list {
		    foreach referencer_list [db_list_of_lists sa_referencer { *SQL* }] {
			set manifest_id [lindex $referencer_list 0]
			set role_part_id [lindex $referencer_list 1]
			set imsld_id [lindex $referencer_list 2]
			set play_id  [lindex $referencer_list 3]
			set act_id [lindex $referencer_list 4]
			set creation_date [lindex $referencer_list 5]
			set run_id [lindex $referencer_list 6]

			if { [db_0or1row compre_times {
			    select 1
			    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
			}] } {
			    # the act has been expired, let's mark it as finished 
			    db_foreach user_in_run { *SQL* } {
				imsld::finish_component_element -imsld_id $imsld_id \
				    -run_id $run_id \
				    -play_id $play_id \
				    -act_id $act_id \
				    -role_part_id $role_part_id \
				    -element_id $activity_id \
				    -type support \
				    -user_id $user_id \
				    -code_call
			    }
			    foreach condition_xml [db_list search_related_conditions {
				select ici.condition_xml 
				from imsld_conditionsi ici,
				acs_rels ar, 
				imsld_support_activitiesi ilai 
				where ilai.item_id=ar.object_id_one 
				and ar.rel_type='imsld_ilm_cond_rel' 
				and ilai.activity_id=:activity_id
				and ici.item_id=ar.object_id_two
			    }] { 
				dom parse $condition_xml document
				$document documentElement condition_node
				imsld::condition::execute -run_id $run_id -condition $condition_node
			    }
			    #role conditions, time conditions...
			    imsld::condition::execute_time_role_conditions -run_id $run_id
			}
		    }
		}
	    }
	}

	imsld_learning_activity {
	    ns_log notice "imsld::finish_expired_activity Sweeping learning activities..."
	    # 5. learning activities
	    if {[db_0or1row referenced_las { *SQL* }]} {
		set role_part_id_list [imsld::get_role_part_from_activity -activity_type learning -leaf_id $la_item_id]
		foreach role_part_id $role_part_id_list {
		    foreach referencer_list [db_list_of_lists la_referencer { *SQL* }] {
			set manifest_id [lindex $referencer_list 0]
			set role_part_id [lindex $referencer_list 1]
			set imsld_id [lindex $referencer_list 2]
			set play_id  [lindex $referencer_list 3]
			set act_id [lindex $referencer_list 4]
			set creation_date [lindex $referencer_list 5]
			set run_id [lindex $referencer_list 6]

			if { [db_0or1row compre_times {
			    select 1
			    where (extract(epoch from now()) - extract(epoch from timestamp :creation_date) - :time_in_seconds > 0)
			}] } {
			    # the act has been expired, let's mark it as finished 
			    #                set community_id [imsld::community_id_from_manifest_id -manifest_id $manifest_id]

			    db_foreach user_in_run { *SQL* } {
				imsld::finish_component_element -imsld_id $imsld_id \
				    -run_id $run_id \
				    -play_id $play_id \
				    -act_id $act_id \
				    -role_part_id $role_part_id \
				    -element_id $activity_id \
				    -type learning \
				    -user_id $user_id \
				    -code_call
			    }
			    foreach condition_xml [db_list search_related_conditions {
				select ici.condition_xml 
				from imsld_conditionsi ici,
				acs_rels ar, 
				imsld_learning_activitiesi ilai 
				where ilai.item_id=ar.object_id_one 
				and ar.rel_type='imsld_ilm_cond_rel' 
				and ilai.activity_id=:activity_id
				and ici.item_id=ar.object_id_two
			    }] { 
				dom parse $condition_xml document
				$document documentElement condition_node
				imsld::condition::execute -run_id $run_id -condition $condition_node
			    }
			    #role conditions, time conditions...
			    imsld::condition::execute_time_role_conditions -run_id $run_id
			}
			#end foreach
		    }
		}
	    }
	}

    }
    # end switch
}


ad_proc -public imsld::schedule_finish {
    -activity_id:required
    -time:required
    -store:boolean
} {
    Schedule and log the finish of a process
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-05-26
    
    @param activity_id
    @param time

    @return 
    
    @error 
} {

    set date [clock format $time -format "%D"]
    set today [clock format [clock seconds] -format "%D"]

    if { $date eq $today } {
	set hour [clock format $time -format "%H"]
	set minute [clock format $time -format "%M"]
	ad_schedule_proc -thread t -once t -schedule_proc ns_schedule_daily [list $hour $minute] \
	    imsld::finish_expired_activity -activity_id $activity_id
    }

    if { $store_p } {
	set due_date [clock format $time -format "%m-%d-%Y"]
	db_dml insert_scheduled_complete {
	    insert into imsld_scheduled_time_limits
	    (activity_id, time)
	    values
	    (:activity_id, :time)
	}
    }    
}


ad_proc -public imsld::daily_schedule {
} {   
    Re-schedule old finished activities that correspond to today
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-05-26
    
    @return 
    
    @error 
} {
    set initial [clock scan [clock format [clock seconds] -format "%D"]]
    set final [clock scan "23 hours 59 minutes 59 seconds" -base $initial]
    db_foreach select_time_limits {
	select activity_id, time
	from imsld_scheduled_time_limits
	where time between :initial and :final
    } {
	imsld::schedule_finish -activity_id $activity_id -time $time
    }    
}


ad_proc -public imsld::global_folder_id { 
    {-community_id ""}
} {
    Returns the global folder id where the global properties of type file are
    stored. 
    This folder is a subfolder of the dotlrn root folder and there must be only
    one in the .LRN installation
} {
    set community_id [expr { [empty_string_p $community_id] ? \
				 [dotlrn_community::get_community_id] : \
				 $community_id }]

    set dotlrn_root_folder_id [dotlrn_fs::get_dotlrn_root_folder_id]
    set global_folder_id [content::item::get_id \
			      -item_path "imsld_global_folder" \
			      -root_folder_id $dotlrn_root_folder_id \
			      -resolve_index f] 

    if { [empty_string_p $global_folder_id] } {
        db_transaction {
            set folder_name "imsld_global_folder"

            # checks for write permission on the parent folder
	    ad_require_permission $dotlrn_root_folder_id write

            # create the root cr dir

            set global_folder_id [imsld::cr::folder_new \
				      -parent_id $dotlrn_root_folder_id \
				      -folder_name $folder_name \
				      -folder_label "IMS-LD"]

            # PERMISSIONS FOR FILE-STORAGE

            # Before we go about anything else, lets just set permissions
            # straight. 
            # Disable folder permissions inheritance
            permission::toggle_inherit -object_id $global_folder_id
            
            # Set read permissions for community/class dotlrn_member_rel
            set party_id_member [dotlrn_community::get_rel_segment_id -community_id $community_id -rel_type dotlrn_member_rel]
            permission::grant -party_id $party_id_member -object_id $global_folder_id -privilege read
            
            # Set read permissions for community/class dotlrn_admin_rel
            set party_id_admin [dotlrn_community::get_rel_segment_id -community_id $community_id -rel_type dotlrn_admin_rel]
            permission::grant -party_id $party_id_admin -object_id $global_folder_id -privilege read
            
            # Set read permissions for *all* other professors  within .LRN
            # (so they can see the content)
            set party_id_professor [dotlrn::user::type::get_segment_id -type professor]
            permission::grant -party_id $party_id_professor -object_id $global_folder_id -privilege read
            
            # Set read permissions for *all* other admins within .LRN
            # (so they can see the content)
            set party_id_admins [dotlrn::user::type::get_segment_id -type admin]
            permission::grant -party_id $party_id_admins -object_id $global_folder_id -privilege read
        }
        # register content types
        content::folder::register_content_type -folder_id $global_folder_id \
            -content_type imsld_property_instance

        # allow subfolders inside our parent folder
        content::folder::register_content_type -folder_id $global_folder_id \
            -content_type content_folder
    }
    return $global_folder_id
}

ad_proc -public imsld::mark_role_part_finished { 
    -role_part_id:required
    -imsld_id:required
    -run_id:required
    -play_id:required
    -act_id:required
    {-user_id ""}
} { 
    mark the role_part as finished, as well as all the referenced activities
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::role_part_finished_p -run_id $run_id -role_part_id $role_part_id -user_id $user_id] } {
        return
    }
    db_1row role_part_info { *SQL* }

    # first, verify that the role part is marked as started
    if { ![db_0or1row marked_as_started { *SQL* }] } {
        db_dml mark_role_part_started { *SQL* }
    }
    db_dml insert_role_part { *SQL* }

    # mark as finished all the referenced activities
    db_1row role_part_activity {
        select case
        when learning_activity_id is not null
        then 'learning'
        when support_activity_id is not null
        then 'support'
        when activity_structure_id is not null
        then 'structure'
        else 'none'
        end as type,
        content_item__get_live_revision(coalesce(learning_activity_id,support_activity_id,activity_structure_id)) as activity_id,
        coalesce(learning_activity_id, support_activity_id, activity_structure_id) as activity_item_id
        from imsld_role_parts
        where role_part_id = :role_part_id
    }

    if { ![string eq $type "none"] } {
        imsld::finish_component_element -imsld_id $imsld_id \
            -run_id $run_id \
            -play_id $play_id \
            -act_id $act_id \
            -role_part_id $role_part_id \
            -element_id $activity_id \
            -type $type \
            -user_id $user_id \
            -code_call

        dom createDocument foo foo_doc
        set foo_node [$foo_doc documentElement]
        if { [string eq $type "learning"] } {
            set resources_activities_list [imsld::process_learning_activity_as_ul -run_id $run_id -activity_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
        } elseif { [string eq $type "support"] } {
            set resources_activities_list [imsld::process_support_activity_as_ul -run_id $run_id -activity_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
        } else {
            set resources_activities_list [imsld::process_activity_structure_as_ul -run_id $run_id -structure_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
        }
        #grant permissions for newly showed resources
        imsld::grant_permissions -resources_activities_list $resources_activities_list -user_id $user_id -run_id $run_id
    }

}

ad_proc -public imsld::mark_act_finished { 
    -act_id:required
    -imsld_id:required
    -run_id:required
    -play_id:required
    {-user_id ""}
} { 
    mark the act as finished, as well as all the referenced role_parts
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]

    if { [imsld::act_finished_p -run_id $run_id -act_id $act_id -user_id $user_id] } {
        return
    }
    db_1row act_info {
        select item_id as act_item_id
        from imsld_actsi
        where act_id = :act_id
    }

    db_dml insert_act { *SQL* }

    foreach referenced_role_part [db_list_of_lists referenced_role_part {
        select rp.role_part_id
        from imsld_role_parts rp, imsld_actsi ia
        where rp.act_id = ia.item_id
        and ia.act_id = :act_id
        and content_revision__is_live(rp.role_part_id) = 't'
    }] {
        set role_part_id [lindex $referenced_role_part 0]

        imsld::mark_role_part_finished -role_part_id $role_part_id \
            -act_id $act_id \
            -play_id $play_id \
            -imsld_id $imsld_id \
            -run_id $run_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_play_finished { 
    -play_id:required
    -imsld_id:required
    -run_id:required
    {-user_id ""}
} { 
    mark the play as finished. In this case there's only need to mark the play finished and not doing anything with the referenced acts, role_parts, etc.
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::play_finished_p -run_id $run_id -play_id $play_id -user_id $user_id] } {
        return
    }
    db_dml insert_play { *SQL* }
    foreach referenced_act [db_list_of_lists referenced_act {
        select ia.act_id
        from imsld_acts ia, imsld_playsi ip
        where ia.play_id = ip.item_id
        and ip.play_id = :play_id
        and content_revision__is_live(ia.act_id) = 't'
    }] {
        set act_id [lindex $referenced_act 0]
        imsld::mark_act_finished -act_id $act_id \
            -play_id $play_id \
            -imsld_id $imsld_id \
            -run_id $run_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_imsld_finished { 
    -imsld_id:required
    -run_id:required
    {-user_id ""}
} { 
    mark the unit of learning as finished
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::imsld_finished_p -imsld_id $imsld_id -run_id $run_id -user_id $user_id] } {
        return
    }
    db_dml insert_uol { *SQL* }

    foreach referenced_play [db_list_of_lists referenced_plays {
        select ip.play_id
        from imsld_plays ip, imsld_methodsi im, imsld_imsldsi ii
        where ip.method_id = im.item_id
        and im.imsld_id = ii.item_id
        and ii.imsld_id = :imsld_id
    }] {
        set play_id [lindex $referenced_play 0]
        imsld::mark_play_finished -play_id $play_id \
            -imsld_id $imsld_id \
            -run_id $run_id \
            -user_id $user_id
    }
}

ad_proc -public imsld::mark_method_finished { 
    -imsld_id:required
    -run_id:required
    -method_id:required
    {-user_id ""}
} { 
    mark the method as finished
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [imsld::method_finished_p -run_id $run_id -method_id $method_id -user_id $user_id] } {
        return
    }
    db_dml insert_method { *SQL* }

    foreach referenced_play [db_list_of_lists referenced_plays {
        select ip.play_id
        from imsld_plays ip, imsld_methodsi im
        where ip.method_id = im.item_id
        and im.method_id = :method_id
    }] {
        set play_id [lindex $referenced_play 0]
        imsld::mark_play_finished -play_id $play_id \
            -imsld_id $imsld_id \
            -run_id $run_id \
            -user_id $user_id
    }
}
ad_proc -public imsld::group_type_delete {
    -group_type:required
} {
    Deletes a group type (since the group_types does not have a delete proc)
} {
#select all groups of this type
set group_id_list [db_list select_groups {
                     select ao.object_id as group_id
                     from acs_objects ao
                     where ao.object_type= :group_type
                  }]
#delete all groups and drop group_type
         foreach group_id $group_id_list {
            group::delete $group_id
         }


         db_dml delete_group_type {delete from group_types where group_type=:group_type}
         db_exec_plsql drop_group_type {}
     

}
ad_proc -public imsld::rel_type_delete { 
    -rel_type:required
} { 
    Deletes a rel type (since the rel_types does not have a delete proc)
} {  

    db_1row select_type_info {
        select t.table_name 
        from acs_object_types t
        where t.object_type = :rel_type
    }
    set rel_id_list [db_list select_rel_ids {
        select r.rel_id
        from acs_rels r
        where r.rel_type = :rel_type
    }]
    
    # delete all relations and drop the relationship
    # type. 
    
    db_transaction {
        foreach rel_id $rel_id_list {
            relation_remove $rel_id
        }
        
        db_exec_plsql drop_relationship_type {
            BEGIN
            acs_rel_type.drop_type( rel_type  => :rel_type,
                                    cascade_p => 't' );
            END;
        }
    } on_error {
        ad_return_error "Error deleting relationship type" "We got the following error trying to delete this relationship type:<pre>$errmsg</pre>"
        ad_script_abort
    }
    # If we successfully dropped the relationship type, drop the table.
    # Note that we do this outside the transaction as it commits all
    # transactions anyway
    if { [db_table_exists $table_name] } {
        db_exec_plsql drop_type_table "drop table $table_name"
    }
} 

ad_proc -public imsld::item_revision_new {
    {-attributes ""}
    {-item_id ""}
    {-name ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -content_type
    -edit:boolean
    -parent_id
} {
    Creates a new revision of a content item, calling the cr functions. 
    If editing, only a new revision is created, otherwise an item is created
    too.

    @option attributes A list of lists of pairs of additional attributes and
    their values.
    @option title 
    @option name When given this parameter is to set the field name of the
    newly created item. This field is important for two reasons. First, in the
    absence of title in the corresponding cr_revision object, it is the string
    shown when the item is a file and is visible in the FS. Second, it is the
    ONLY name that appears when browsing the FS through WebDAV.
    @option package_id 
    @option user_id 
    @option creation_ip 
    @option creation_date 
    @option edit Are we editing the item?
    @param parent_id Identifier of the parent folder
} {

    set user_id \
	[expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [string eq "" $creation_ip] ? \
				[ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [string eq "" $creation_date] ? \
				  [dt_sysdate] : $creation_date }]
    set package_id [expr { [string eq "" $package_id] ? \
			       [ad_conn package_id] : $package_id }]

    if { [string eq $item_id ""] } {
        # create the item
	set item_id [db_nextval "acs_object_id_seq"]

	# Decide the name
	if { [string eq "" $name] } {
	    set name "${item_id}_content_type"
	} else {
	    # If the given name collides with another item, it needs to be
	    # modified as to make it unique (parent_id, name) is what it needs
	    # to be made unique
	    if { ![string eq "" [content::item::get_id_by_name \
				     -name $name -parent_id $parent_id]] } {
		set name "${name}.${item_id}"
	    }
	}

        set item_id [content::item::new -item_id $item_id \
                         -name $name \
                         -content_type $content_type \
                         -parent_id $parent_id \
                         -creation_user $user_id \
                         -creation_ip $creation_ip \
                         -context_id $package_id]
    }
    
    if { ![string eq "" $attributes] } {
        set revision_id [content::revision::new -item_id $item_id \
                             -title $title \
                             -content_type $content_type \
                             -creation_user $user_id \
                             -creation_ip $creation_ip \
                             -is_live "t" \
                             -attributes $attributes \
                             -package_id $package_id]
    } else {
        set revision_id [content::revision::new -item_id $item_id \
                             -title $title \
                             -content_type $content_type \
                             -creation_user $user_id \
                             -creation_ip $creation_ip \
                             -is_live "t" \
                             -package_id $package_id]
    }
    return $item_id
}

ad_proc -public imsld::do_notification {
    -imsld_id
    -run_id
    -subject
    -activity_id
    {-username ""}
    {-email_address ""}
    -role_id
    {-user_id ""}
    -notified_users_list
} {
    @param imsld_id
    @param run_id
    @param subject
    @option username
    @option email_address
    @param role_id
    @option user_id user_id of the one sending the notification
    @param notified_users_list list to keep track of the notified users

    @return the list of the notified users
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    
    # notifications according to the spec: "The implementation should ensure
    # that a user receives one notification only, even if the user is a member
    # of several roles targeted by the notification", that's why we use the
    # list notified_users_list and check before sending the notification.
    set community_id [dotlrn_community::get_community_id]
    set community_name [dotlrn_community::get_community_name $community_id]
    set community_url [ns_conn location][dotlrn_community::get_community_url $community_id]
    set imsld_title [content::revision::revision_name -revision_id $imsld_id]
    set imsld_url "[ns_conn location][lindex [site_node::get_url_from_object_id -object_id [ad_conn package_id]] 0]imsld-frameset?run_id=$run_id"
    set sender_name [party::name -party_id $user_id]
    set sender_email [party::email -party_id $user_id]

    if { [string eq "" $subject] } {
        set subject "[_ imsld.lt_community_name_imsld_]"
    }
    
    # get the activity type
    if { ![empty_string_p $activity_id] } {
        # get the activity_type
        if { [db_0or1row learning_activity_p { *SQL* }] } {
            set activity_type learning
            set where_clause [db_map learning_activity]
        } else {
            set activity_type support
            set where_clause [db_map support_activity]
        }
    }

    if { ![empty_string_p $email_address] && [util_email_valid_p $email_address] && ([lsearch -exact $notified_users_list $email_address] == -1) } {
        # Use this to build up extra mail headers        
        set extra_headers [ns_set new]
        
        # This should disable most auto-replies.
        ns_set put $extra_headers Precedence list

        set body_html "[_ imsld.lt_username_br__________]"

        acs_mail_lite::send -to_addr $email_address \
            -from_addr $sender_email \
            -subject $subject \
            -body $body_html \
            -mime_type "text/html" \
            -extraheaders $extra_headers

        lappend notified_users_list $email_address
    } else {
        # invalid mail!
        ns_log notice "imsld::do_notification: Not sending notification because the email is invalid!"
    }

    # if activity_id is not null:
    # add the activity to the rel imsld_run_time_activities_rel
    if { ![string eq "" $activity_id] && ![db_0or1row already_mapped { *SQL* }] } {
        # map the activity to the role
        # NOTE: this mappnig couldn't be done using acs_rels becuase we could map more than once the same activity with the same role,
        # with differnet context info (run_id), but that's not taken into account when creating the acs rel even tough if when creating the rel 
        # we indicate that the rel info is stored in other table....

        imsld::map::role_to_activity -run_id $run_id -activity_id $activity_id -role_id $role_id
    }
    # send a notification (email) to each user in the role
    foreach recipient_user_id [imsld::roles::get_users_in_role -role_id $role_id -run_id $run_id] {
        set recipient_email [party::email -party_id $recipient_user_id]
        if { [lsearch -exact $notified_users_list $email_address] == -1 } {
            set recepient_name [party::name -party_id $recipient_user_id] 
            set body_html "[_ imsld.lt_Dear_recepient_name_b]"
            # if activity_id is not null: 
            # 1. make it visible
            # 2. get the activity url in order to send it in the email
            if { ![empty_string_p $activity_id] } {
                # 1. make it visible
                db_dml make_activity_visible { *SQL* }
                # 2. get the activity url for the recipient user_id
                set activity_url [imsld::activity_url -run_id $run_id -activity_id $activity_id -user_id $recipient_user_id]
                set activity_title [content::revision::revision_name -revision_id $activity_id]
                append body_html "[_ imsld.lt_br___________________]"
            } else {
                append body_html "[_ imsld.lt_br____________________1]"
            }
            # Use this to build up extra mail headers        
            set extra_headers [ns_set new]
            
            # This should disable most auto-replies.
            ns_set put $extra_headers Precedence list

            acs_mail_lite::send -to_addr $recipient_email \
                -from_addr $sender_email \
                -subject $subject \
                -body $body_html \
                -mime_type "text/html" \
                -extraheaders $extra_headers

            lappend notified_users_list $recipient_email
        }
    }
    
    # log the notification
    db_dml log_notification { *SQL* }

    return $notified_users_list
}

ad_proc -public imsld::finish_component_element {
    -imsld_id
    -run_id
    {-play_id ""}
    {-act_id ""}
    {-role_part_id ""}
    -element_id
    -type
    -code_call:boolean
    {-user_id ""}
} {
    @param imsld_id
    @param run_id
    @option play_id
    @option act_id
    @option role_part_id
    @option element_id
    @option type
    @option code_call
    @option user_id

    Mark as finished the given component_id. This is done by adding a row in the table imsld_user_status.

    This function is called from a url, but it can also be called recursively
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { !$code_call_p } {
        # get the url to parse it and get the info
        set url [ns_conn url]
        regexp {finish-component-element-([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)-([a-z]+).imsld$} $url match imsld_id run_id play_id act_id role_part_id element_id type
    }
    if { ![db_0or1row marked_as_started { *SQL* }] } {
        # NOTE: this should not happen... UNLESS the activity is marked as
        # finished automatically
        db_dml mark_element_started { *SQL* }
    }
    # now that we have the necessary info, mark the finished element completed
    # and return
    db_dml insert_element_entry { *SQL* }

    switch $type {
        learning { 
            set table_name "imsld_learning_activities"
            set element_name "activity_id"
        }
        support { 
            set table_name "imsld_support_activities"
            set element_name "activity_id"
        }
        method { 
            set table_name "imsld_methods"
            set element_name "method_id"
        }
        play { 
            set table_name "imsld_plays"
            set element_name "play_id"
        }
        act { 
            set table_name "imsld_acts"
            set element_name "act_id"
        }
    }
   
    if { [info exists table_name] } {
        foreach condition_xml [db_list search_related_conditions ""] { 
           dom parse $condition_xml document
           $document documentElement condition_node
           imsld::condition::execute -run_id $run_id -condition $condition_node
        }
        #role conditions, time conditions...
        imsld::condition::execute_time_role_conditions -run_id $run_id

        #grant permissions to resources in activity
        if { [db_0or1row get_related_on_completion_id ""] } {
            # process feedback?
            if { [db_0or1row get_related_resource_id { *SQL* }] } {
                imsld::grant_permissions -resources_activities_list $related_resource -user_id $user_id -run_id $run_id
            }
            # process change_property_value?
            if { [db_0or1row get_related_change_prop_val {
                select change_property_value_xml
                from imsld_on_completioni
                where item_id = :related_on_completion
                and content_revision__is_live(on_completion_id) = 't'
                and change_property_value_xml is not null
            }] } {
                imsld::condition::eval_change_property_value -change_property_value_xml $change_property_value_xml -run_id $run_id
            }
            # notifications
            set notified_users_list [list]
            foreach notification_list [db_list_of_lists get_notifications { *SQL* }] {
                set subject [lindex $notification_list 0]
                set activity_id [content::item::get_live_revision -item_id [lindex $notification_list 1]]
                set notification_id [lindex $notification_list 2]
                set notification_item_id [lindex $notification_list 3]
                
                # send an email for each email-data associated to the notification
                foreach email_data [db_list_of_lists get_email_datas { *SQL* }] {
                    set role_id [lindex $email_data 0]
                    set mail_data [lindex $email_data 1]
                    set email_property_id [lindex $email_data 2]
                    set username_property_id [lindex $email_data 3]
                    
                    if { ![empty_string_p $username_property_id] } {
                        # get the username proprty value
                        # NOTE: there is no specification for the format of the email property value
                        #       so we assume it is a single username
                        db_1row get_username_property_id { *SQL* }
                        set username [imsld::runtime::property::property_value_get -run_id $run_id \
                                          -user_id $user_id \
                                          -property_id $property_id]
                    } else {
                        set username ""
                    }

                    if { ![empty_string_p $email_property_id] } {
                        # get the email proprty value
                        # NOTE: there is no specification for the format of the email property value
                        #       so we assume it is a single email address.
                        #       we also send the notificaiton to the rest of the role members
                        db_1row get_email_property_id { *SQL* }
                        set email_address [imsld::runtime::property::property_value_get -run_id $run_id \
                                               -user_id $user_id \
                                               -property_id $property_id]
                    } else {
                        set email_address ""
                    }

                    set notified_users_list [imsld::do_notification -imsld_id $imsld_id \
                                                 -run_id $run_id \
                                                 -subject $subject \
                                                 -activity_id $activity_id \
                                                 -username $username \
                                                 -email_address $email_address \
                                                 -role_id $role_id \
                                                 -user_id $user_id \
                                                 -notified_users_list $notified_users_list]
                }
            }
        }
    }

    if { [string eq $type "learning"] || [string eq $type "support"] || [string eq $type "structure"] } {
	# if the activity is referenced from an activity strucutre, that activity structure must be checked
	# in order to know if the structure must be also marked as completed
        foreach referencer_structure_list [db_list_of_lists referencer_structure { *SQL* }] {
            set structure_id [lindex $referencer_structure_list 0]
            set structure_item_id [lindex $referencer_structure_list 1]
            set number_to_select [lindex $referencer_structure_list 2]
	    set already_marked_p [db_0or1row not_marked {
		select 1
		from imsld_status_user
		where user_id = :user_id
		and run_id = :run_id
		and related_id = :structure_id
		and status = 'finished'
	    }]
	    if { ![imsld::structure_finished_p -structure_id $structure_id -run_id $run_id -user_id $user_id] || !$already_marked_p } { 
		# if this activity is part of an activity structure, let's check if the rest of referenced 
		# activities are finished too, so we can mark finished the activity structure as well
		set scturcture_finished_p 1
		set total_completed 0
		db_foreach referenced_activity {
		    select content_item__get_live_revision(ar.object_id_two) as activity_id
		    from acs_rels ar
		    where ar.object_id_one = :structure_item_id
		    and ar.rel_type in ('imsld_as_la_rel','imsld_as_sa_rel','imsld_as_as_rel')
		} {
		    if { ![db_string completed_p { *SQL* }] } {
			# there is at leas one no-completed activity, so we can't mark this activity structure yet
			set scturcture_finished_p 0
			continue
		    } else {
			incr total_completed
		    }
		}
		# If the structure has the flag number-to-select
		if { $scturcture_finished_p && (($number_to_select > 0 && ($total_completed >= $number_to_select)) || !$already_marked_p) } {
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

    if { [string eq $type "structure"] } {
	# mark as finished all the referenced activities
	foreach referenced_activities_list [db_list_of_lists referenced_activities {
	    select case when ar.rel_type = 'imsld_as_la_rel'
	    then 'learning'
	    when ar.rel_type = 'imsld_as_sa_rel'
	    then 'support'
	    when ar.rel_type = 'imsld_as_as_rel'
	    then 'structure'
	    end as ref_type,
	    content_item__get_live_revision(ar.object_id_two) as activity_id
	    from acs_rels ar, imsld_activity_structuresi ias
	    where ar.object_id_one = ias.item_id
	    and ias.structure_id = :element_id
	    and ar.rel_type in ('imsld_as_la_rel','imsld_as_sa_rel','imsld_as_as_rel')
	}] {
	    set ref_type [lindex $referenced_activities_list 0]
	    set activity_id [lindex $referenced_activities_list 1]
	    if { ![db_0or1row already_finished_p {
		select 1 
		from imsld_status_user
		where user_id = :user_id
		and status = 'finished'
		and run_id = :run_id
		and related_id = :activity_id
	    }] } {
		imsld::finish_component_element -imsld_id $imsld_id \
		    -run_id $run_id \
		    -play_id $play_id \
		    -act_id $act_id \
		    -role_part_id $role_part_id \
		    -element_id $activity_id \
		    -type $ref_type \
		    -user_id $user_id \
		    -code_call
	    }
	}
    }



    # we continue with A LOT of validations (in order to support the
    # when-xxx-finished tag of the spec
    # -- with xxx in (role_part,act,play)):
    # 1. let's see if the finished activity triggers the ending of the
    # role_part
    # 2. let's see if the finished role_part triggers the ending of the act
    # which references it.
    # 3. let's see if the finished act triggers the ending the play which
    # references it
    # 4. let's see if the finished play triggers the ending of the method which
    # references it.
    set role_part_id_list [imsld::get_role_part_from_activity -activity_type $type -leaf_id [db_string get_item_id { select item_id from cr_revisions where revision_id = :element_id}]]
    foreach role_part_id $role_part_id_list {
        db_1row context_info {
            select acts.act_id,
            plays.play_id
            from imsld_actsi acts, imsld_playsi plays, imsld_role_parts rp
            where rp.role_part_id = :role_part_id
            and rp.act_id = acts.item_id
            and acts.play_id = plays.item_id
        }

        if { [imsld::role_part_finished_p -run_id $run_id -role_part_id $role_part_id -user_id $user_id] && ![db_0or1row already_marked_p { *SQL* }] } { 
            # case number 1
            imsld::finish_component_element -imsld_id $imsld_id \
                -run_id $run_id \
                -play_id $play_id \
                -act_id $act_id \
                -role_part_id $role_part_id \
                -element_id $role_part_id \
                -type role-part \
                -user_id $user_id \
                -code_call

            db_1row get_role_part_info {
                select ii.imsld_id,
                ip.play_id,
                ip.item_id as play_item_id,
                ia.act_id,
                ia.item_id as act_item_id,
                ica.when_last_act_completed_p,
                im.method_id,
                im.item_id as method_item_id
                from imsld_imsldsi ii, imsld_actsi ia, imsld_role_parts irp, 
                imsld_methodsi im, imsld_playsi ip left outer join imsld_complete_actsi ica on (ip.complete_act_id = ica.item_id)
                where irp.role_part_id = :role_part_id
                and irp.act_id = ia.item_id
                and ia.play_id = ip.item_id
                and ip.method_id = im.item_id
                and im.imsld_id = ii.item_id
                and content_revision__is_live(ii.imsld_id) = 't';
            }
            set finish_by_trigger_p 1
            set completed_act_p 1 
            set rel_defined_p 0

            set user_roles_list [imsld::roles::get_user_roles -user_id $user_id -run_id $run_id]
            db_foreach referenced_role_part {
                select ar.object_id_two as role_part_item_id,
                rp.role_part_id
                from acs_rels ar, imsld_role_partsi rp
                where ar.object_id_one = :act_item_id
                and rp.item_id = ar.object_id_two
                and ar.rel_type = 'imsld_act_rp_completed_rel'
                and content_revision__is_live(rp.role_part_id) = 't'
            } {
                if { ![imsld::role_part_finished_p -run_id $run_id -role_part_id $role_part_id -user_id $user_id] } {
                    set completed_act_p 0
                    set finish_by_trigger_p 0
                }
            } if_no_rows {
                set finish_by_trigger_p 0
                # the act doesn't have any imsld_act_rp_completed_rel rel defined.
                set rel_defined_p 1
            }
            if { $rel_defined_p } {
                # check if all the role parts have been finished and mar the act as finished.
                db_foreach directly_referenced_role_part {
                    select irp.role_part_id
                    from imsld_role_parts irp
                    where irp.act_id = :act_item_id
                    and content_revision__is_live(irp.role_part_id) = 't'
                } {
                    if { ![imsld::role_part_finished_p -run_id $run_id -role_part_id $role_part_id -user_id $user_id] } {
                        set completed_act_p 0
                    }
                }
            }

            if { $completed_act_p } {            
                # case number 2
                if { $finish_by_trigger_p } {
                    #finsish the act for all involved users
                    set users_in_run [db_list get_users_in_run {
                        select gmm.member_id 
                        from group_member_map gmm,
                        imsld_run_users_group_ext iruge, 
                        acs_rels ar1 
                        where iruge.run_id=:run_id
                        and ar1.object_id_two=iruge.group_id 
                        and ar1.object_id_one=gmm.group_id 
                        group by member_id
                    }]
                    foreach user $users_in_run {
                        if { [imsld::user_participate_p -run_id $run_id -act_id $act_id -user_id $user]} {
                            imsld::mark_act_finished -act_id $act_id \
                                -play_id $play_id \
                                -imsld_id $imsld_id \
                                -run_id $run_id \
                                -user_id $user
                        }
                    }
                }

                imsld::mark_act_finished -act_id $act_id \
                    -play_id $play_id \
                    -imsld_id $imsld_id \
                    -run_id $run_id \
                    -user_id $user_id
                
                set completed_play_p 1
                db_foreach referenced_act {
                    select ia.act_id
                    from imsld_acts ia, imsld_playsi ip
                    where ia.play_id = :play_item_id
                    and ip.item_id = ia.play_id
                    and content_revision__is_live(ia.act_id) = 't'
                } {
                    if { ![imsld::act_finished_p -run_id $run_id -act_id $act_id -user_id $user_id] } {
                        set completed_play_p 0
                    }
                }
                if { $completed_play_p } {
                    # case number 3
                    imsld::mark_play_finished -play_id $play_id \
                        -imsld_id $imsld_id \
                        -run_id $run_id \
                        -user_id $user_id 
                    
                    set completed_unit_of_learning_p 1 
                    set rel_defined_p 0
                    db_foreach referenced_play {
                        select ip.play_id
                        from acs_rels ar, imsld_playsi ip
                        where ar.object_id_one = :method_item_id
                        and ip.item_id = ar.object_id_two
                        and ar.rel_type = 'imsld_mp_completed_rel'
                        and content_revision__is_live(ip.play_id) = 't'
                    } {
                        if { ![imsld::play_finished_p -run_id $run_id -play_id $play_id -user_id $user_id] } {
                            set completed_unit_of_learning_p 0
                        }
                    } if_no_rows {
                        # the uol doesn't have any imsld_mp_completed_rel rel defined.
                        set rel_defined_p 1
                    }
                    if { $rel_defined_p } {
                        # check if all the plays have been finished and mark the imsld as finished.
                        db_foreach directly_referenced_plays {
                            select ip.play_id
                            from imsld_plays ip
                            where ip.method_id = :method_item_id
                            and content_revision__is_live(ip.play_id) = 't'
                        } {
                            if { ![imsld::play_finished_p -run_id $run_id -play_id $play_id -user_id $user_id] } {
                                set completed_unit_of_learning_p 0
                            }
                        }
                    }
                    
                    if { $completed_unit_of_learning_p } {
                        # case number 4
                        imsld::mark_imsld_finished -imsld_id $imsld_id -run_id $run_id -user_id $user_id
                    }
                }
            }
        }
    }

    if { !$code_call_p } {
        set community_id [dotlrn_community::get_community_id]
        set imsld_package_id [site_node_apm_integration::get_child_package_id \
                                  -package_id [dotlrn_community::get_package_id $community_id] \
                                  -package_key "[imsld::package_key]"]
        ad_returnredirect "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/imsld-tree" -url { run_id }]"
    }
}

ad_proc -public imsld::structure_next_activity {
    -activity_structure_id:required
    {-environment_list ""}
    -imsld_id
    -run_id
    -role_part_id
    {-structures_info ""}
} { 
    @return The next learning or support activity (and the type) in the activity structure. 0 if there are none (which should never happen), the next activity type and the list of the structure names of the activity structures in the path of the returned activity
} {
    set user_id [ad_conn user_id]
    set min_sort_order ""
    set next_activity_id ""
    set next_activity_type ""
    # mark structure started
    if { ![db_0or1row already_marked {
        select 1 from imsld_status_user
        where run_id = :run_id 
        and user_id = :user_id 
        and related_id = :activity_structure_id 
        and status = 'started'
    }] } {
        db_dml mark_structure_started {
            insert into imsld_status_user (imsld_id,
                                           run_id,
                                           role_part_id,
                                           related_id,
                                           user_id,
                                           type,
                                           status_date,
                                           status) 
            (
             select :imsld_id,
             :run_id,
             :role_part_id,
             :activity_structure_id,
             :user_id,
             'structure',
             now(),
             'started'
             where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :activity_structure_id and status = 'started')
             )
        }
    
        set structures_info [concat $structures_info [db_list_of_lists get_structure_info {
            select 
            coalesce(title,identifier) as structure_name,
            item_id
            from imsld_activity_structuresi
            where structure_id = :activity_structure_id
        }]]
    }

    # get referenced activities
    foreach referenced_activity [db_list_of_lists struct_referenced_activities { *SQL* }] {
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        set rel_id [lindex $referenced_activity 2]
        switch $rel_type {
            imsld_as_la_rel {
                # find out if is the next one
                db_1row get_la_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_la_rels where rel_id = :rel_id
                }
                if { ![db_string completed_p_from_la { *SQL* }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $learning_activity_id
                    set next_activity_type learning
                }
            }
            imsld_as_sa_rel {
                # find out if is the next one
                db_1row get_sa_info {
                    select sort_order, 
                    activity_id as support_activity_id
                    from imsld_support_activitiesi
                    where item_id = :object_id_two
                    and content_revision__is_live(activity_id) = 't'
                }
                db_1row get_sort_order {
                    select sort_order from imsld_as_sa_rels where rel_id = :rel_id
                }
                if { ![db_string completed_p_from_sa { *SQL* }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $support_activity_id
                    set next_activity_type support
                }
            }
            imsld_as_as_rel {
                # recursive call?
                db_1row get_as_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_as_rels where rel_id = :rel_id
                }
                if { ![db_string completed_p { *SQL* }] && ( [string eq "" $min_sort_order] || $sort_order < $min_sort_order ) } {
                    set min_sort_order $sort_order
                    set next_activity_id $structure_id
                    set next_activity_type structure
                }
            }
            imsld_as_env_rel {
                dom createDocument foo foo_doc
                set foo_node [$foo_doc documentElement]
                if { [llength $environment_list] } {
                    set environment_list [concat [list $environment_list] [list [imsld::process_environment_as_ul -environment_item_id $object_id_two -run_id $run_id -dom_doc $foo_doc -dom_node $foo_node]]]
                } else {
                    set environment_list [imsld::process_environment_as_ul -environment_item_id $object_id_two -run_id $run_id -dom_doc $foo_doc -dom_node $foo_node]
                }
            }
        }
    } 

    if { [string eq $next_activity_type structure] } {
        set next_activity_list [imsld::structure_next_activity -activity_structure_id $next_activity_id -environment_list $environment_list -imsld_id $imsld_id -run_id $run_id -role_part_id $role_part_id -structures_info $structures_info]
        set next_activity_id [lindex $next_activity_list 0]
        set next_activity_type [lindex $next_activity_list 1]
        set environment_list [concat $environment_list [lindex $next_activity_list 2]]
        set structures_info [lindex $next_activity_list 3]
    }
    return [list $next_activity_id $next_activity_type $environment_list $structures_info]
} 

ad_proc -public imsld::structure_finished_p { 
    -structure_id:required
    -run_id
    {-user_id ""}
} { 
    @param structure_id
    @param run_id
    @option user_id
    
    @return 0 if the any activity referenced from the activity structure hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    
    set all_completed 1
    foreach referenced_activity [db_list_of_lists struct_referenced_activities {
        select ar.object_id_two,
        ar.rel_type
        from acs_rels ar, imsld_activity_structuresi ias
        where ar.object_id_one = ias.item_id
        and ias.structure_id = :structure_id
        order by ar.object_id_two
    }] {
        # get all the directly referenced activities (from the activity structure)
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        switch $rel_type {
            imsld_as_la_rel {
		set complete_act_id [db_string completion_restriction {
		    select complete_act_id 
		    from imsld_learning_activities
		    where activity_id = content_item__get_live_revision(:object_id_two)
		} -default ""]
		if { (![string eq [db_string finished_p {                    
		    select status from imsld_status_user 
                    where related_id = content_item__get_live_revision(:object_id_two) 
                    and user_id = :user_id 
                    and status = 'finished'
                    and run_id = :run_id
		} -default ""] "finished"] && ![string eq $complete_act_id ""]) \
			 || (![string eq [db_string started_p {
			     select status from imsld_status_user 
			     where related_id = content_item__get_live_revision(:object_id_two) 
			     and user_id = :user_id 
			     and status = 'started'
			     and run_id = :run_id
			 } -default ""] "started"] && [string eq $complete_act_id ""]) } {
		    set all_completed 0
		    break
		}
	    }
            imsld_as_sa_rel {
		set complete_act_id [db_string completion_restriction {
		    select complete_act_id 
		    from imsld_support_activities
		    where activity_id = content_item__get_live_revision(:object_id_two)
		} -default ""]
		
		if { (![string eq [db_string finished_p {                    
		    select status from imsld_status_user 
                    where related_id = content_item__get_live_revision(:object_id_two) 
                    and user_id = :user_id 
                    and status = 'finished'
                    and run_id = :run_id
		} -default ""] "finished"] && ![string eq $complete_act_id ""]) \
			 || (![string eq [db_string started_p {
			     select status from imsld_status_user 
			     where related_id = content_item__get_live_revision(:object_id_two) 
			     and user_id = :user_id 
			     and status = 'started'
			     and run_id = :run_id
			 } -default ""] "started"] && [string eq $complete_act_id ""]) } {
		    set all_completed 0
		    break
		}
            }
            imsld_as_as_rel {
		# the activity structure must be marked as finished
                if { ![db_0or1row completed_p {
                    select 1 from imsld_status_user 
                    where related_id = :structure_id 
                    and user_id = :user_id 
                    and status = 'finished'
                    and run_id = :run_id
                }] } {
                    set all_completed 0
		    break
                }
            }
        }
    }
    return $all_completed
}

ad_proc -public imsld::role_part_finished_p { 
    -role_part_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param role_part_id Role Part identifier
    @param run_id
    @option user_id
    
    @return 0 if the role part hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { [db_0or1row already_marked_p { *SQL* }] } {
        # simple case, already marked as finished
        return 1
    }

    db_1row get_role_part_activity {
        select case
        when learning_activity_id is not null
        then 'learning'
        when support_activity_id is not null
        then 'support'
        when activity_structure_id is not null
        then 'structure'
        else 'none'
        end as type,
        learning_activity_id,
        support_activity_id,
        activity_structure_id
        from imsld_role_parts
        where role_part_id = :role_part_id
    }
    # check if the referenced activities have been finished
    switch $type {
        learning {
            if { [db_string completed_from_la {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:learning_activity_id)
                and user_id = :user_id
                and run_id = :run_id
                and status = 'finished'
            }] } {
                return 1
            }
        }
        support {
            if { [db_string completed_from_sa {
                select count(*) from imsld_status_user
                where completed_id = content_item__get_live_revision(:support_activity_id)
                and user_id = :user_id
                and run_id = :run_id
                and status = 'finished'
            }] } {
                return 1
            }
        }
        structure {
            db_1row get_sa_info {
                select structure_id
                from imsld_activity_structuresi
                where item_id = :activity_structure_id
            }
            return [imsld::structure_finished_p -run_id $run_id -structure_id $structure_id -user_id $user_id]
        }
        none {
            return 1
        }
    }
    return 0
} 

ad_proc -public imsld::run_finished_p { 
    -run_id:required
    {-user_id "" }
} { 
    @param run_id
    @oprion user_id
    
    @return 0 if all the activities in the run hasn't been finished. 1 otherwise
} {
    #get users involved in test
    if {![string eq "" $user_id]} {
        set user_id [ad_conn user_id]
    } else {
        set user_id [db_list get_users_in_run {
            select gmm.member_id 
            from group_member_map gmm,
                 imsld_run_users_group_ext iruge, 
                 acs_rels ar1 
            where iruge.run_id=:run_id
                  and ar1.object_id_two=iruge.group_id 
                  and ar1.object_id_one=gmm.group_id 
            group by member_id
        }]
    }

    #get acts in run
    set acts_list [db_list get_acts_in_run {
        select iai.act_id,
               iai.item_id 
        from imsld_runs ir, 
             imsld_imsldsi iii,
             imsld_methodsi imi,
             imsld_playsi ipi,
             imsld_actsi iai 
        where ir.run_id=:run_id
              and iii.imsld_id=ir.imsld_id 
              and imi.imsld_id=iii.item_id 
              and imi.item_id=ipi.method_id 
              and iai.play_id=ipi.item_id
    }]
    set all_finished_p 1
    foreach act $acts_list {
        foreach user $user_id {
            if {![imsld::act_finished_p -run_id $run_id -act_id $act -user_id $user]} {
                if {[imsld::user_participate_p -run_id $run_id -act_id $act -user_id $user]} {
                    set all_finished_p 0
                }
            }
        }
    }
         
    return $all_finished_p
}

ad_proc -public imsld::user_participate_p { 
    -act_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param act_id
    @param run_id
    @option user_id
    
    @return 0 if the user does not participate in the act. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set involved_roles [db_list get_roles_in_act {
	select ir.role_id 
	from   imsld_role_parts irp, 
	       imsld_acts ia,
	       cr_items ca,
	       imsld_roles ir,
	       cr_items cr
	where ia.act_id = :act_id
	and   ia.act_id = ca.live_revision
	and   ca.item_id = irp.act_id
	and   irp.role_id = cr.item_id
	and   cr.live_revision = ir.role_id
    }]
    set involved_users [list]
    foreach role $involved_roles {
        set involved_users [concat $involved_users [imsld::roles::get_users_in_role -role_id $role -run_id $run_id ]]
    }
    if { [lsearch $involved_users $user_id] < 0 } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public imsld::act_finished_p { 
    -act_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param act_id
    @param run_id
    @oprion user_id
    
    @return 0 if the at hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row already_marked_p { *SQL* }]
} 

ad_proc -public imsld::play_finished_p { 
    -play_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param play_id
    @param run_id
    @option user_id
    
    @return 0 if the play hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row play_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :play_id
        and user_id = :user_id
        and run_id = :run_id
        and status = 'finished'
    }]
} 

ad_proc -public imsld::method_finished_p { 
    -method_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param method_id
    @param run_id
    @oprion user_id
    
    @return 0 if the method hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row method_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :method_id
        and user_id = :user_id
        and run_id = :run_id
        and status = 'finished'
    }]
} 

ad_proc -public imsld::imsld_finished_p { 
    -imsld_id:required
    -run_id:required
    {-user_id ""}
} { 
    @param imsld_id
    @param run_id
    @option user_id
    
    @return 0 if the imsld hasn't been finished. 1 otherwise
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [db_0or1row imsld_marked_p {
        select 1 
        from imsld_status_user
        where completed_id = :imsld_id
        and user_id = :user_id
        and run_id = :run_id
        and status = 'finished'
    }]
} 

ad_proc -public imsld::class_visible_p { 
    -run_id:required
    -owner_id:required
    -class_name:required
    {-user_id ""}
} { 
    @param run_id
    @param owner_id
    @param class_name

    @return 1 if the class of the owner_id is currently visible in the run for a given user_id, 0 otherwise.
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    return [expr ![db_0or1row class_visible_p {
        select 1
        from imsld_attribute_instances
        where run_id = :run_id
        and type = 'class'
        and user_id = :user_id
        and identifier = :class_name
        and is_visible_p = 'f'
    }]]
}

ad_proc -public imsld::process_service_as_ul {
    -service_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
    {-user_id ""}
} { 
    @param service_item_id
    @param run_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return a html list (in a dom tree) of the associated resources referenced from the given service.
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set services_list [list]

    # get service info
    if { ![db_0or1row service_info { *SQL* }] } {
        # not visible, return
        return
    }

    switch $service_type {
        conference {
            db_1row get_conference_info { *SQL* }
            db_foreach serv_associated_items { *SQL* } {
                lappend resource_item_list $resource_item_id
                imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                    -run_id $run_id \
                    -dom_node $dom_node \
                    -dom_doc $dom_doc
                # replace the image with the conference name
                set img_nodes [$dom_node selectNodes {.//img}]
                foreach img_node $img_nodes {
                    set parent_node [$img_node parentNode]
                    set conf_title_node [$dom_doc createTextNode "$conf_title"]
                    $parent_node replaceChild $conf_title_node $img_node 
                }

            } if_no_rows {
                ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
            }
        }
        send-mail {
            # FIX ME: Currently only one send-mail-data is supported
            set resource_item_list [list]

            db_1row get_send_mail_info { *SQL* }
            set send_mail_node_li [$dom_doc createElement li]
            set a_node [$dom_doc createElement a]
            $a_node setAttribute href [export_vars -base "[dotlrn_community::get_community_url [dotlrn_community::get_community_id]]imsld/imsld-sendmail" {{send_mail_id $sendmail_id} {run_id $run_id}}]            
            set service_title [$dom_doc createTextNode "$send_mail_title"]
            $a_node appendChild $service_title
            $send_mail_node_li appendChild $a_node
            $dom_node appendChild $send_mail_node_li
        }
        monitor {
            set resource_item_list [list]
            set imsld_package_id [site_node_apm_integration::get_child_package_id \
                                      -package_id [dotlrn_community::get_package_id [dotlrn_community::get_community_id]] \
                                      -package_key "[imsld::package_key]"]
            db_1row monitor_service_info { *SQL* }
            db_foreach monitor_associated_items { *SQL* } {

                lappend resource_item_list $resource_item_id
                set monitor_node_li [$dom_doc createElement li]
                set a_node [$dom_doc createElement a]
                set file_url [export_vars -base "[dotlrn_community::get_community_url [dotlrn_community::get_community_id]]imsld/monitor-frame" { monitor_id }]
                $a_node setAttribute href [export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]
                set service_title [$dom_doc createTextNode "$monitor_service_title"]
                $a_node appendChild $service_title
                $monitor_node_li appendChild $a_node
                $dom_node appendChild $monitor_node_li
            } if_no_rows {
                ns_log debug "No monitor info"
            }
        }

        default {
            ad_return_error "the service type $service_type is not implemented... yet" "Sorry, that service type ($service_type) hasn't been implemented yet. But be patience, we are working on it =)"
            ad_script_abort
        }
    }
    
    #grant permissions for resources in service
    imsld::grant_permissions -resources_activities_list $resource_item_list -user_id [ad_conn user_id] -run_id $run_id

    if {[string eq "t" $resource_mode]} {
        return [list $services_list $resource_item_list]
    }
}

ad_proc -public imsld::process_environment_as_ul {
    -environment_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node:required
    -dom_doc:required
    {-user_id ""}
} { 
    @param environment_item_id
    @param run_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return a html list (in a dom tree) of the associated resources, files and environments referenced from the given environment.
} {  
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    # get environment info
    db_1row environment_info { *SQL* }

    set environment_node_li [$dom_doc createElement li]
    $environment_node_li setAttribute class "liOpen"
    set text [$dom_doc createTextNode "$environment_title"]
    $environment_node_li appendChild $text
    set environment_node [$dom_doc createElement ul]
    # FIX-ME: if the ul is empty, the browser show the ul incorrectly
    set text [$dom_doc createTextNode ""]    
    $environment_node appendChild $text

    set environment_learning_objects_list [list]
    foreach learning_objects_list [db_list_of_lists get_learning_object_info { *SQL* }] {
        set learning_object_item_id [lindex $learning_objects_list 0]
        set learning_object_id [lindex $learning_objects_list 1]
        set identifier [lindex $learning_objects_list 2]
        set lo_title [lindex $learning_objects_list 3]
        set class_name [lindex $learning_objects_list 4]
        if { ![imsld::class_visible_p -run_id $run_id -owner_id $learning_object_id -class_name $class_name] } {
            continue
        }
        # learning object item. get the files associated
        set linear_item_list [db_list_of_lists item_linear_list { *SQL* }]
        foreach imsld_item_id $linear_item_list {
            foreach environments_list [db_list_of_lists env_nested_associated_items { *SQL* }] {
                set resource_id [lindex $environments_list 0]
                set resource_item_id [lindex $environments_list 1]
                set resource_type [lindex $environments_list 2]
                if { [string eq "t" $resource_mode] } {
                    lappend resource_item_list $resource_item_id
                }

                #grant permissions to use the resource 
                imsld::grant_permissions -resources_activities_list $resource_item_id -user_id [ad_conn user_id] -run_id $run_id

                set one_learning_object_list [imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                                                  -run_id $run_id \
                                                  -dom_node $environment_node \
                                                  -dom_doc $dom_doc]

                # in order to behave like CopperCore, we decide to replace the images with the learning object title
                set img_nodes [$environment_node selectNodes {.//img}]
                foreach img_node $img_nodes {
                    set parent_node [$img_node parentNode]
                    set lo_title_node [$dom_doc createTextNode "$lo_title"]
                    $parent_node replaceChild $lo_title_node $img_node 
                }
                if { ![string eq "" $one_learning_object_list] } {
                    if { [string eq "t" $resource_mode] } { 
                     set environment_learning_objects_list [concat $environment_learning_objects_list \
                                                               [list $one_learning_object_list] \
                                                               $resource_item_list ]
                    } 
                }
            } 
        }
    }

    # services
    set environment_services_list [list]
    foreach services_list [db_list_of_lists get_service_info { *SQL* }] {
        set service_id [lindex $services_list 0]
        set service_item_id [lindex $services_list 1]
        set identifier [lindex $services_list 2]
        set service_type [lindex $services_list 3]
        set service_title [lindex $services_list 4]

        set class_name [lindex $services_list 5]
        if { ![imsld::class_visible_p -run_id $run_id -owner_id $service_id -class_name $class_name] } {
            continue
        }

        set environment_services_list [concat $environment_services_list \
                                           [list [imsld::process_service_as_ul -service_item_id $service_item_id \
                                                      -run_id $run_id \
                                                      -resource_mode $resource_mode \
                                                      -dom_node $environment_node \
                                                      -dom_doc $dom_doc]]]
        # in order to behave like CopperCore, we decide to replace the images with the service title
        set img_nodes [$environment_node selectNodes {.//img}]
        foreach img_node $img_nodes {
            set parent_node [$img_node parentNode]
            set lo_title_node [$dom_doc createTextNode "$service_title"]
            $parent_node replaceChild $lo_title_node $img_node 
        }
    }

    set nested_environment_list [list]
    # environments
    foreach nested_environment_item_id [db_list nested_environment { *SQL* }] {
        set one_nested_environment_list [imsld::process_environment_as_ul -environment_item_id $nested_environment_item_id \
                                             -run_id $run_id \
                                             -resource_mode $resource_mode \
                                             -dom_node $environment_node \
                                             -dom_doc $dom_doc]
        # the title is stored in [lindex $one_nested_environment_list 0], but is not returned for displaying porpouses
        set nested_environment_list [concat $nested_environment_list \
                                         [lindex $one_nested_environment_list 1] \
                                         [lindex $one_nested_environment_list 2] \
                                         [lindex $one_nested_environment_list 3]]
        regsub -all "{}" $nested_environment_list "" nested_environment_list
    }
    if { [string eq $resource_mode "t"] } {
        return [list $environment_title $environment_learning_objects_list $environment_services_list $nested_environment_list]
    } else {
        $environment_node_li appendChild $environment_node
        $dom_node appendChild $environment_node_li
    }
}

ad_proc -public imsld::process_learning_objective_as_ul {
    -run_id:required
    {-imsld_item_id ""}
    {-activity_item_id ""}
    {-resource_mode "f"}
    -dom_node
    -dom_doc
    {-user_id ""}
} {
    @param run_id
    @option imsld_item_id
    @option activity_item_id
    @option resource_mode
    @param dom_node
    @param dom_doc
    @param user_id

    @return a html list (ul, using tdom) with the objective title and the associated resources referenced from the learning objective of the given activity or ims-ld
} { 
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set learning_objective_item_id ""
    if { ![string eq "" $imsld_item_id] } {
        db_0or1row lo_id_from_imsld_item_id { *SQL* }
    } elseif { ![string eq "" $activity_item_id] } {
        db_0or1row lo_id_from_activity_item_id { *SQL* }
    } 

    if { [string eq "" $learning_objective_item_id] } {
        return -code error "IMSLD::imsld::process_learning_objective: Invalid call"
    }

    # get learning object info
    db_1row objective_info { *SQL* }

    # get the items associated with the learning objective
    set resource_item_list [list]
    set linear_item_list [db_list item_linear_list { *SQL* }]
    foreach imsld_item_id $linear_item_list {
        db_foreach lo_nested_associated_items { *SQL* } {
            if { [string eq "t" $resource_mode] } {
                lappend resource_item_list $resource_item_id
            }
            # add the associated files as items of the html list
            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $list_node
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }
    if { [string eq "t" $resource_mode] } {
        return [list $resource_item_list]
    } 
}

ad_proc -public imsld::process_prerequisite_as_ul {
    -run_id:required
    {-imsld_item_id ""}
    {-activity_item_id ""}
    {-resource_mode "f"}
    -dom_node
    -dom_doc
    {-user_id ""}
} {
    @param run_id
    @option imsld_item_id
    @option activity_item_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return a html list (using tdom) of the associated resources referenced from the prerequisite of the given ims-ld or activity
} { 
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set prerequisite_item_id ""
    if { ![string eq "" $imsld_item_id] } {
        db_0or1row lo_id_from_imsld_item_id { *SQL* }
    } elseif { ![string eq "" $activity_item_id] } {
        db_0or1row lo_id_from_activity_item_id { *SQL* }
    }

    if { [string eq "" $prerequisite_item_id] } {
        return -code error "IMSLD::imsld::process_prerequisite: Invalid call"
    }

    # get prerequisite info
    db_1row prerequisite_info { *SQL* }

    # get the items associated with the learning objective
    set linear_item_list [db_list item_linear_list { *SQL* }]
    foreach imsld_item_id $linear_item_list {
        db_foreach prereq_nested_associated_items { *SQL* } { 
            if { [string eq "t" $resource_mode] } { 
                lappend resource_item_list $resource_item_id
            }
            # add the associated files as items of the html list
            set one_prerequisite_ul [imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                                         -run_id $run_id \
                                         -dom_doc $dom_doc \
                                         -dom_node $dom_node]
        } if_no_rows {
            ns_log notice "[_ imsld.lt_li_desc_no_file_assoc]"
        }
    }
    if { [string eq "t" $resource_mode] } {
        return [list $prerequisite_title [list] $resource_item_list]
    } 
}

ad_proc -public imsld::process_feedback_as_ul {
    -run_id:required
    {-on_completion_item_id ""}
    -dom_node
    -dom_doc
    {-user_id ""}
} {
    @param run_id
    @option on_completion_item_id
    @param dom_node
    @param dom_doc

    @return a html list (using tdom) with the feedback title and the associated resources referenced from the given feedback (on_completion)
} { 
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set feedback_item_id ""
    # get on completion info
    db_1row feedback_info { *SQL* }

    # get the items associated with the feedback
    set linear_item_list [db_list item_linear_list { *SQL* }]
    foreach imsld_item_id $linear_item_list {
        db_foreach feedback_nested_associated_items { *SQL* } {
            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_node $dom_node \
                -dom_doc $dom_doc
        }
    }
}

ad_proc -public imsld::activity_url {
    -div:boolean
    -activity_id:required
    -run_id:required
    {-user_id ""}
} {
    @param activity_id
    @param run_id
    @option user_id

    @returns the url for the given activity
} {

    set user_id [expr { [string eq $user_id ""] ? [ad_conn user_id] : $user_id }]

    if { $div_p } {
	set url "activity-frame"
    } else {
	set url "imsld-divset"
    }

    return "[export_vars -base $url -url {activity_id run_id user_id}]"

}

ad_proc -public imsld::process_resource_as_ul {
    -resource_item_id
    -run_id
    {-community_id ""}
    -dom_node 
    -dom_doc
    -li_mode:boolean
    -monitor:boolean
    -plain:boolean
    {-user_id ""}} {
    @param resource_item_id
    @param run_id
    @option community_id
    @param dom_node
    @param dom_doc

    @return The html ul (using tdom) of the files associated to the given resource_id
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set community_id [expr { [string eq "" $community_id] ? "[dotlrn_community::get_community_id]" : $community_id }]
    set imsld_package_id [site_node_apm_integration::get_child_package_id \
                              -package_id [dotlrn_community::get_package_id $community_id] \
                              -package_key "[imsld::package_key]"]

    # Get file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    db_1row get_resource_info { *SQL* }
    
    if { ![string eq $resource_type "webcontent"] && ![string eq $acs_object_id ""] } {

        # if the resource type is not webcontent or has an associated object_id (special cases)...
        if { [db_0or1row is_cr_item { *SQL* }] } {
            db_1row get_cr_info { *SQL* } 
        } else {
            db_1row get_ao_info { *SQL* } 
        }
	set file_url [acs_sc::invoke -contract FtsContentProvider -operation url -impl $object_type -call_args [list $acs_object_id]]
        set a_node [$dom_doc createElement a]
        $a_node setAttribute href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]"
	$a_node setAttribute target "_blank"
	$a_node setAttribute onclick "return loadContent(this.href)"
	$a_node setAttribute title "$object_title"
	set img_node [$dom_doc createElement img]
	$img_node setAttribute src "[imsld::object_type_image_path -object_type $object_type]"
	$img_node setAttribute border "0"
	$img_node setAttribute alt "$object_title"
	$img_node setAttribute title "$object_title"
	$a_node appendChild $img_node
        if { $li_mode_p } {
            set file_node [$dom_doc createElement li]
            $file_node appendChild $a_node
            $dom_node appendChild $file_node
	    $a_node appendChild [$dom_doc createTextNode $object_title]
	    if { $monitor_p } {
		set choose_node [$dom_doc createElement a]
		$choose_node appendChild [$dom_doc createTextNode "Choose"]
		$file_node appendChild [$dom_doc createTextNode {[}]
		$file_node appendChild $choose_node
		$file_node appendChild [$dom_doc createTextNode {]}]
	    }
        } else {
            $dom_node appendChild $a_node
        }

    } elseif { [string eq $resource_type "imsldcontent"] } {

	db_1row get_imsld {
	    select i.imsld_id, i.resource_handler
	    from imsld_runs r, imsld_imslds i
	    where r.run_id = :run_id
	    and r.imsld_id = i.imsld_id
	}
     
	set associated_files_query "associated_files"
	if { $resource_handler eq "xowiki" } {
	    set associated_files_query "associated_xo_files"
	}

        foreach file_list [db_list_of_lists $associated_files_query { *SQL* }] {
	    if { $resource_handler eq "xowiki" } {
		set page_id [lindex $file_list 0]
		set file_name [lindex $file_list 1]
		set fs_file_url [export_vars -base [imsld::xowiki::page_url -item_id $page_id] {{template_file "/packages/imsld/lib/wiki-default"}}]
	    } else {
		set imsld_file_id [lindex $file_list 0]
		set file_name [lindex $file_list 1]
		set item_id [lindex $file_list 2]
		set parent_id [lindex $file_list 3]
		# get the fs file path
		set folder_path [db_exec_plsql get_folder_path { *SQL* }]
		db_0or1row get_fs_file_url { *SQL* }
		set fs_file_url $file_url
	    }

	    set file_url "imsld-content-serve"
            set a_node [$dom_doc createElement a]
            $a_node setAttribute href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]"
	    $a_node setAttribute target "_blank"
	    $a_node setAttribute title "$file_name"
	    $a_node setAttribute onclick "return loadContent(this.href)"
            set img_node [$dom_doc createElement img]
	    $img_node setAttribute src "[imsld::object_type_image_path -object_type file-storage]"
	    $img_node setAttribute border "0"
	    $img_node setAttribute alt "$file_name"
	    $img_node setAttribute title "$file_name"
	    $a_node appendChild $img_node
            if { $li_mode_p } {
                set file_node [$dom_doc createElement li]
                $file_node appendChild $a_node
                $dom_node appendChild $file_node
		$a_node appendChild [$dom_doc createTextNode $file_name]
		if { $monitor_p } {
		    set choose_node [$dom_doc createElement a]
		    $choose_node appendChild [$dom_doc createTextNode "Choose"]
		    $file_node appendChild [$dom_doc createTextNode {[}]
		    $file_node appendChild $choose_node
		    $file_node appendChild [$dom_doc createTextNode {]}]
		}
            } else {
                $dom_node appendChild $a_node
            }
        }

    } else {
        # is webcontent, let's get the associated files

	db_1row get_imsld {
	    select i.imsld_id, i.resource_handler
	    from imsld_runs r, imsld_imslds i
	    where r.run_id = :run_id
	    and r.imsld_id = i.imsld_id
	}
     
	set associated_files_query "associated_files"
	if { $resource_handler eq "xowiki" } {
	    set associated_files_query "associated_xo_files"
	}

        foreach file_list [db_list_of_lists $associated_files_query { *SQL* }] {
	    if { $resource_handler eq "xowiki" } {
		set page_id [lindex $file_list 0]
		set file_name [lindex $file_list 1]
		set file_url [export_vars -base [imsld::xowiki::page_url -item_id $page_id] {{template_file "/packages/imsld/lib/wiki-default"}}]
	    } else {
		set imsld_file_id [lindex $file_list 0]
		set file_name [lindex $file_list 1]
		set item_id [lindex $file_list 2]
		set parent_id [lindex $file_list 3]
		# get the fs file path
		set folder_path [db_exec_plsql get_folder_path { *SQL* }]
		set fs_file_url [db_1row get_fs_file_url { *SQL* }]
		set file_url "[apm_package_url_from_id $fs_package_id]view/${file_url}"
	    }
            set a_node [$dom_doc createElement a]
            $a_node setAttribute href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" {file_url $file_url resource_item_id $resource_item_id run_id $run_id}]"
	    $a_node setAttribute target "_blank"
	    $a_node setAttribute title "$file_name"
	    set img_node [$dom_doc createElement img]
	    $img_node setAttribute src "[imsld::object_type_image_path -object_type file-storage]"
	    $img_node setAttribute border "0"
	    $img_node setAttribute alt "$file_name"
	    $img_node setAttribute title "$file_name"
	    $a_node appendChild $img_node
            if { $li_mode_p } {
                set file_node [$dom_doc createElement li]
                $file_node appendChild $a_node
                $dom_node appendChild $file_node
		$a_node appendChild [$dom_doc createTextNode $file_name]
		if { $monitor_p } {
		    set choose_node [$dom_doc createElement a]
		    $choose_node appendChild [$dom_doc createTextNode "Choose"]
		    $file_node appendChild [$dom_doc createTextNode {[}]
		    $file_node appendChild $choose_node
		    $file_node appendChild [$dom_doc createTextNode {]}]
		}
            } else {
                $dom_node appendChild $a_node
            }
        }
        # get associated urls
	
        db_foreach associated_urls { *SQL* } {
            set a_node [$dom_doc createElement a]

	    $a_node setAttribute href "[export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]imsld-finish-resource" { {file_url "[export_vars -base $url]"} resource_item_id run_id}]"
	    $a_node setAttribute onclick "return loadContent(this.href)"
	    $a_node setAttribute target "_blank"
	    $a_node setAttribute title "$url"
            set img_node [$dom_doc createElement img]
	    $img_node setAttribute src "[imsld::object_type_image_path -object_type url]"
	    $img_node setAttribute border "0"
	    $img_node setAttribute alt "$url"
	    $img_node setAttribute title "$url"
	    $a_node appendChild $img_node
	    if { $li_mode_p } {
                set file_node [$dom_doc createElement li]
                $file_node appendChild $a_node
                $dom_node appendChild $file_node
		$a_node appendChild [$dom_doc createTextNode "$url"]
		if { $monitor_p } {
		    set choose_node [$dom_doc createElement a]
		    $choose_node appendChild [$dom_doc createTextNode "Choose"]
		    $choose_node setAttribute href {\#}
		    $file_node appendChild [$dom_doc createTextNode {[}]
		    $file_node appendChild $choose_node
		    $file_node appendChild [$dom_doc createTextNode {]}]
		}
            } else {
                $dom_node appendChild $a_node
            }
        }
    }
}

ad_proc -public imsld::process_activity_as_ul { 
    -activity_item_id:required
    -run_id:required
    -dom_node:required
    -dom_doc
    {-resource_mode "f"}
    {-user_id ""}
} {
    @param activity_item_id
    @param run_id
    @option resource_mode default f
    @param dom_node
    @param dom_doc
    @option user_id default ad_conn user_id

    @return The html list (activity_name, list of associated urls, using tdom) of the activity in the IMS-LD. 
    It only works whith the learning and support activities, since it will only return the objectives, prerequistes,
    associated resources but not the environments.
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    
    if { [db_0or1row is_imsld {
        select 1 from imsld_imsldsi where item_id = :activity_item_id
    }] } {
        imsld::process_imsld_as_ul -imsld_item_id $activity_item_id \
            -resource_mode $resource_mode \
            -dom_node $dom_node \
            -dom_doc $dom_doc
    } elseif { [db_0or1row is_learning {
        select 1 from imsld_learning_activitiesi where item_id = :activity_item_id
    }] } {
        imsld::process_learning_activity_as_ul -activity_item_id $activity_item_id \
            -run_id $run_id \
            -resource_mode $resource_mode \
            -dom_node $dom_node \
            -dom_doc $dom_doc

    } elseif { [db_0or1row is_support {
        select 1 from imsld_support_activitiesi where item_id = :activity_item_id
    }] } {
        imsld::process_support_activity_as_ul -activity_item_id $activity_item_id \
            -run_id $run_id \
            -resource_mode $resource_mode \
            -dom_node $dom_node \
            -dom_doc $dom_doc
        return
    } elseif { [db_0or1row is_structure {
        select 1 from imsld_activity_structuresi where item_id = :activity_item_id
    }] } {
        imsld::process_activity_structure_as_ul -structure_item_id $activity_item_id \
            -run_id $run_id \
            -resource_mode $resource_mode \
            -dom_node $dom_node \
            -dom_doc $dom_doc
    } else {
        return -code error "IMSLD::imsld::process_activity_as_ul: Invalid call"
    }
}

ad_proc -public imsld::process_activity_environments_as_ul {
    -activity_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
    {-user_id ""}
} {
    @param activity_item_id
    @param run_id
    @param rel_type
    @option resource_mode default f
    @param dom_node
    @param dom_doc
    
    @return The html list (using tdom) of resources (learning objects and services) associated to the activity's environment(s)
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    # get the rel_type
    if { [db_0or1row is_imsld {
        select 1 from imsld_imsldsi where item_id = :activity_item_id
    }] } {
        return ""
    } elseif { [db_0or1row is_learning {
        select 1 from imsld_learning_activitiesi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_la_env_rel
    } elseif { [db_0or1row is_support {
        select 1 from imsld_support_activitiesi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_sa_env_rel
    } elseif { [db_0or1row is_structure {
        select 1 from imsld_activity_structuresi where item_id = :activity_item_id
    }] } {
        set rel_type imsld_as_env_rel
    } else {
        return -code error "IMSLD::imsld::process_activity_environments_as_ul: Invalid call"
    }
    # get environments
    set environments_list [list]
    set associated_environments_list [db_list la_associated_environments {
        select ar.object_id_two as environment_item_id
        from acs_rels ar
        where ar.object_id_one = :activity_item_id
        and ar.rel_type = :rel_type
        order by ar.object_id_two
    }]
    foreach environment_item_id $associated_environments_list {
        imsld::process_environment_as_ul -environment_item_id $environment_item_id \
            -run_id $run_id \
            -dom_node $dom_node \
            -dom_doc $dom_doc
    }
}

ad_proc -public imsld::process_imsld_as_ul {
    -imsld_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
    {-user_id ""}
} {
    @param imsld_item_id
    @param run_id
    @option resource_mode default f
    
    @return The html list (using tdom) of the resources associated to the given imsld_id (objectives and prerequisites).
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    db_1row imsld_info {
        select prerequisite_id as prerequisite_item_id,
        learning_objective_id as learning_objective_item_id,
        imsld_id
        from imsld_imsldsi
        where item_id = :imsld_item_id
        and content_revision__is_live(imsld_id) = 't'
    }

    # prerequisites
    set prerequisites_node [$dom_doc createElement div]
    $prerequisites_node setAttribute class "tabbertab"
    set prerequisites_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Prerequisites]"]
    $prerequisites_head_node appendChild $text
    $prerequisites_node appendChild $prerequisites_head_node
    if { ![string eq "" $prerequisite_item_id] } {
        # add the prerequisite files as items of the list

        set prerequisites_list [imsld::process_prerequisite_as_ul -imsld_item_id $imsld_item_id \
                                    -run_id $run_id \
                                    -resource_mode $resource_mode \
                                    -dom_node $prerequisites_node \
                                    -dom_doc $dom_doc]

    }
    $dom_node appendChild $prerequisites_node

    # learning objectives
    set objectives_node [$dom_doc createElement div]
    $objectives_node setAttribute class "tabbertab"
    set objectives_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Objectives]"]
    $objectives_head_node appendChild $text
    $objectives_node appendChild $objectives_head_node
    if { ![string eq "" $learning_objective_item_id] } {
        # add the prerequisite files as items of the list

        set objectives_list [imsld::process_learning_objective_as_ul -imsld_item_id $imsld_item_id \
                                 -run_id $run_id \
                                 -resource_mode $resource_mode \
                                 -dom_node $objectives_node \
                                 -dom_doc $dom_doc]

    }
    $dom_node appendChild $objectives_node
    
    if { [string eq $resource_mode "t"] } {
        return [concat $prerequisites_list $objectives_list]
    }
}

ad_proc -public imsld::process_learning_activity_as_ul { 
    -activity_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
    {-user_id ""}
} {
    @param activity_item_id
    @param run_id
    @option resource_mode default f
    @param dom_node
    @param dom_doc
    
    @return The list (activity_name, list of associated urls, using tdom) of the activity in the IMS-LD.
} {
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    if { ![db_0or1row activity_info { *SQL* }] } {
        # is visible is false, do not show anything
        return
    }

    # get the items associated with the activity
    set description_node [$dom_doc createElement div]
    $description_node setAttribute class "tabbertab"
    set description_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Material]"]
    $description_head_node appendChild $text
    $description_node setAttribute style "display: none; float:left; "
    $description_node appendChild $description_head_node
    set linear_item_list [db_list item_linear_list { *SQL* }]

    set activity_items_list [list]
    foreach imsld_item_id $linear_item_list {
        foreach la_items_list [db_list_of_lists la_nested_associated_items { *SQL* }] {
            set resource_id [lindex $la_items_list 0]
            set resource_item_id [lindex $la_items_list 1]
            set resource_type [lindex $la_items_list 2]

            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $description_node

            if { [string eq "t" $resource_mode] } { 
                lappend activity_items_list $resource_item_id
            }
        }
    }
    if { [llength $linear_item_list ] > 0 } { 
	$dom_node appendChild $description_node 
    }

    # prerequisites
    set prerequisites_node [$dom_doc createElement div]
    $prerequisites_node setAttribute class "tabbertab"
    set prerequisites_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Prerequisites]"]
    $prerequisites_head_node appendChild $text
    $prerequisites_node appendChild $prerequisites_head_node
    set prerequisites_list [list]
    if { ![string eq "" $prerequisite_item_id] } {
        # add the prerequisite files as items of the list

        set prerequisites_list [imsld::process_prerequisite_as_ul -activity_item_id $activity_item_id \
                                    -run_id $run_id \
                                    -resource_mode $resource_mode \
                                    -dom_node $prerequisites_node \
                                    -dom_doc $dom_doc]

        $dom_node appendChild $prerequisites_node
    }

    # learning objectives
    set objectives_node [$dom_doc createElement div]
    $objectives_node setAttribute class "tabbertab"
    set objectives_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Objectives]"]
    $objectives_head_node appendChild $text
    $objectives_node appendChild $objectives_head_node
    set objectives_list [list]
    if { ![string eq "" $learning_objective_item_id] } {
        # add the prerequisite files as items of the list

        set objectives_list [imsld::process_learning_objective_as_ul -activity_item_id $activity_item_id \
                                 -run_id $run_id \
                                 -resource_mode $resource_mode \
                                 -dom_node $objectives_node \
                                 -dom_doc $dom_doc]

        $dom_node appendChild $objectives_node
    }

    # process feedback only if the activity is finished
    set feedback_node [$dom_doc createElement div]
    $feedback_node setAttribute class "tabbertab"
    set feedback_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Feedback]"]
    $feedback_head_node appendChild $text
    $feedback_node appendChild $feedback_head_node
    if { [db_0or1row completed_activity { *SQL* }] } {
        if { ![string eq "" $on_completion_item_id] && [db_string is_feedback { *SQL* }] > 0 } {
            # the feedback is not processed to ckeck if all the activity resources have been finished
            # so we don't need to store the result
            imsld::process_feedback_as_ul -on_completion_item_id $on_completion_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $feedback_node
            $dom_node appendChild $feedback_node
        }
    }

    if { [string eq "t" $resource_mode] } {
        # get environments
        set environments_list [list]
        set associated_environments_list [db_list la_associated_environments { *SQL* }]
        foreach environment_item_id $associated_environments_list {
            if { [llength $environments_list] } {
                set environments_list [concat [list $environments_list] \
                                           [list [imsld::process_environment_as_ul -environment_item_id $environment_item_id -resource_mode $resource_mode -run_id $run_id -dom_node $dom_node -dom_doc $dom_doc]]]
            } else {
                set environments_list [imsld::process_environment_as_ul -environment_item_id $environment_item_id -resource_mode $resource_mode -run_id $run_id -dom_node $dom_node -dom_doc $dom_doc]
            }
        }
        
        # put in order the environments_id(s)
        set environments_ids [concat [lindex [lindex $environments_list 1] [expr [llength [lindex $environments_list 1] ] - 1 ]] \
                                     [lindex [lindex $environments_list 2] [expr [llength [lindex $environments_list 2] ] - 1 ]]]

         return [list [lindex $prerequisites_list [expr [llength $prerequisites_list] - 1]] \
                      [lindex $objectives_list [expr [llength $objectives_list ] - 1]] \
                      $environments_ids \
                      [lindex $activity_items_list [expr [llength $activity_items_list ] - 1]]]
    }
}

ad_proc -public imsld::process_support_activity_as_ul { 
    -activity_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
    {-user_id ""}
} {
    @param activity_item_id
    @param run_id
    @option resource_mode
    @param dom_node
    @param dom_doc

    @return The list of items (resources, feedback, environments, using tdom) associated with the support activity
} {
     set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]

    if { ![db_0or1row activity_info { *SQL* }] } {
        # is visible is false do not show anything
        return
    }

    # get the items associated with the activity
    set description_node [$dom_doc createElement div]
    $description_node setAttribute class "tabbertab"
    set description_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Material]"]
    $description_head_node appendChild $text
    $description_node appendChild $description_head_node

    # process feedback only if the activity is finished
    set feedback_node [$dom_doc createElement div]
    $feedback_node setAttribute class "tabbertab"
    set feedback_head_node [$dom_doc createElement h2]
    set text [$dom_doc createTextNode "[_ imsld.Feedback]"]
    $feedback_head_node appendChild $text
    $feedback_node appendChild $feedback_head_node
    if { [db_0or1row completed_activity { *SQL* }] } {
        if { ![string eq "" $on_completion_item_id] } {
            # the feedback is not processed to ckeck if all the activity resources have been finished
            # so we don't need to store the result
            imsld::process_feedback_as_ul -on_completion_item_id $on_completion_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $feedback_node
            $dom_node appendChild $feedback_node
        }
    }

    if { [string eq "t" $resource_mode] } {
        # get environments
        set environments_list [list]
        set associated_environments_list [db_list sa_associated_environments { *SQL* }]
        foreach environment_item_id $associated_environments_list {
            if { [llength $environments_list] } {
                set environments_list [concat [list $environments_list] \
                                           [list [imsld::process_environment_as_ul -environment_item_id $environment_item_id -run_id $run_id -resource_mode $resource_mode -dom_node $dom_node -dom_doc $dom_doc]]]
            } else {
                set environments_list [imsld::process_environment_as_ul -environment_item_id $environment_item_id -run_id $run_id -resource_mode $resource_mode -dom_node $dom_node -dom_doc $dom_doc]
            }
        }

        # put in order the environments_id(s)
        set environments_ids [concat [lindex [lindex $environments_list 1] [expr [llength [lindex $environments_list 1] ] - 1 ]] \
                                     [lindex [lindex $environments_list 2] [expr [llength [lindex $environments_list 2] ] - 1 ]] ]

         return [list $environments_ids \
                      [lindex $activity_items_list [expr [llength $activity_items_list ] - 1]]]
    } 
}

ad_proc -public imsld::process_activity_structure_as_ul {
    -structure_item_id:required
    -run_id:required
    {-resource_mode "f"}
    -dom_node
    -dom_doc
    {-user_id ""}
} {
    @param structure_item_id
    @param run_id
    @option resource_mode
    @param dom_node
    @param dom_doc
    
    @return The html list (using tdom) of items (information) associated with the activity structure
} {
     set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id } ]
    # get the items associated with the activity
    set info_tab_node [$dom_doc createElement li]
    set text [$dom_doc createTextNode "[_ imsld.Information]"]
    $info_tab_node appendChild $text
    set info_node [$dom_doc createElement ul]
    # FIX-ME: if the ul is empty, the browser show the ul incorrectly
    set text [$dom_doc createTextNode ""]    
    $info_node appendChild $text
    
    set linear_item_list [db_list item_linear_list { *SQL* }]

    set resource_items_list [list]
    foreach imsld_item_id $linear_item_list {
        foreach la_items_list [db_list_of_lists as_nested_associated_items { *SQL* }] {
            set resource_id [lindex $la_items_list 0]
            set resource_item_id [lindex $la_items_list 1]
            set resource_type [lindex $la_items_list 2]
            if { [string eq "t" $resource_mode] } { 
                lappend resource_items_list $resource_item_id
            }
            
            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $info_node
        }
    }
    $info_tab_node appendChild $info_node
    $dom_node appendChild $info_tab_node
    if { [string eq "t" $resource_mode] } { 
        return $resource_items_list
    }
}

ad_proc -public imsld::generate_structure_activities_list {
    -imsld_id
    -run_id
    -structure_item_id
    -user_id
    -role_part_id
    -play_id
    -act_id
    {-next_activity_id_list ""}
    -dom_node
    -dom_doc
} {
    @param imsld_id
    @param run_id
    @param structure_item_id
    @param user_id
    @param role_part_id
    @param play_id
    @param act_id

    @return A list of lists of the activities referenced from the activity structure
} {
    set imsld_package_id [ad_conn package_id]
    # auxiliary list to store the activities
    set completed_list [list]
    # get the structure info
    db_1row structure_info { *SQL* }

    # if any of the referenced activities from the activity structure doesn't have a completion restriction
    # and the activity structure is of type "sequence", there wouldn't be a way to advance in the structure,
    # so, if this is the case, the structure is treated as of type "selection"
    set completion_restriction [imsld::structure_completion_resctriction_p -run_id $run_id -structure_item_id $structure_item_id]

    # get the referenced activities which are referenced from the structure
    foreach referenced_activity [db_list_of_lists struct_referenced_activities { *SQL* }] {
        # get all the directly referenced activities (from the activity structure)
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        set rel_id [lindex $referenced_activity 2]
        switch $rel_type {
            imsld_as_la_rel {
                # add the activiti to the TCL list
                db_1row get_learning_activity_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_la_rels where rel_id = :rel_id
                }
                set completed_p [db_0or1row completed_p { *SQL* }]
                set started_activity_p [db_0or1row already_started {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'started'
                }]
		set user_choice_p [db_string user_choice_p {select user_choice_p from imsld_complete_actsi where item_id = :complete_act_id and content_revision__is_live(complete_act_id) = 't'} -default "f"]
                # show the activity only if:
		# 0. the activity is visible
                # 1. it has been already completed
                # 2. if the structure-type is "selection"
		# 3. if the activity has no completion restriction
                # 4. if it is the next activity to be done (and structure-type is "sequence") 

                if { $completed_p || [string eq $complete_act_id ""] || [string eq $structure_type "selection"] || (([lsearch -exact $next_activity_id_list $activity_id] != -1) || !$completion_restriction) && [string eq $is_visible_p "t"] } {

		    if { !$started_activity_p && [string eq $is_visible_p "t"] } {
			set activity_node [$dom_doc createElement li]
			$activity_node setAttribute class "liOpen"
			set b_node [$dom_doc createElement b]
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute onclick "return loadContent('$div')"
			
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$b_node appendChild $a_node
			$activity_node appendChild $b_node
			
			set text [$dom_doc createTextNode " "]
			$activity_node appendChild $text
		    } else {
			# bold letters
			set activity_node [$dom_doc createElement li]
			$activity_node setAttribute class "liOpen"
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute onclick "return loadContent('$div')"

			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$activity_node appendChild $a_node
			
			set text [$dom_doc createTextNode " "]
			$activity_node appendChild $text
		    }

		    if { $completed_p } {

			if { ![string eq $complete_act_id ""] } {
			    # the activity is finished
			    set img_node [$dom_doc createElement img]
			    $img_node setAttribute src "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/completed.png"
			    $img_node setAttribute border "0"
			    $img_node setAttribute alt "[_ imsld.finished]"
			    $img_node setAttribute title "[_ imsld.finished]"
			    $activity_node appendChild $img_node
			}
		    } else {

			if { [string eq $user_choice_p "t"] } {
			    
			    # show the finish button
			    set input_node [$dom_doc createElement a]
			    $input_node setAttribute href "finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-learning.imsld"
			    $input_node setAttribute onclick "return loadTree(this.href)"
			    $input_node setAttribute class "finish"
			    $input_node setAttribute title "[_ imsld.finish_activity]"
			    set text [$dom_doc createTextNode "[_ imsld.finish]"]
			    $input_node appendChild $text
			    $activity_node appendChild $input_node
			}
		    }
		    imsld::generate_resources_tree -activity_item_id $activity_item_id -run_id $run_id -user_id $user_id -dom_node $activity_node -dom_doc $dom_doc
                    set completed_list [linsert $completed_list $sort_order [$activity_node asList]]
                }
            }
            imsld_as_sa_rel {
                # add the activiti to the TCL list
                db_1row get_support_activity_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_sa_rels where rel_id = :rel_id
                }
                set started_activity_p [db_0or1row already_started {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'started'
                }]
                set completed_p [db_0or1row completed_p { *SQL* }]
		set user_choice_p [db_string user_choice_p {select user_choice_p from imsld_complete_actsi where item_id = :complete_act_id and content_revision__is_live(complete_act_id) = 't'} -default "f"]

                # show the activity only if:
		# 0. the activity is visible
                # 1. it has been already completed
                # 2. if the structure-type is "selection"
                # 3. if it is the next activity to be done (and structure-type is "sequence") 
		# 4. if the activity has no completion restriction
                if { [string eq $is_visible_p "t"] && ($completed_p || [string eq $complete_act_id ""] || [string eq $structure_type "selection"] || (([lsearch -exact $next_activity_id_list $activity_id] != -1) || !$completion_restriction) && [string eq $is_visible_p "t"] } {

		    if { !$started_activity_p && [string eq $is_visible_p "t"] } {
			set activity_node [$dom_doc createElement li]
			$activity_node setAttribute class "liOpen"
			set b_node [$dom_doc createElement b]
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute onclick "return loadContent('$div')"


			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$b_node appendChild $a_node
			$activity_node appendChild $b_node
			
			set text [$dom_doc createTextNode " "]
			$activity_node appendChild $text

		    } else {
			# bold letters
			set activity_node [$dom_doc createElement li]
			$activity_node setAttribute class "liOpen"
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute onclick "return loadContent('$div')"

			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$activity_node appendChild $a_node
			
			set text [$dom_doc createTextNode " "]
			$activity_node appendChild $text
			
		    }

		    if { $completed_p } {
			if { ![string eq $complete_act_id ""] } {
			    # the activity is finished
			    set img_node [$dom_doc createElement img]
			    $img_node setAttribute src "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/completed.png"
			    $img_node setAttribute border "0"
			    $img_node setAttribute alt "[_ imsld.finished]"
			    $img_node setAttribute title "[_ imsld.finished]"
			    $activity_node appendChild $img_node
			}
		    } else {
			if { [string eq $user_choice_p "t"] } {
			    
			    # show the finish button
			    set input_node [$dom_doc createElement a]
			    $input_node setAttribute href "finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-support.imsld"
			    $input_node setAttribute onclick "return loadTree(this.href)"
			    $input_node setAttribute class "finish"
			    $input_node setAttribute title "[_ imsld.finish_activity]"
			    set text [$dom_doc createTextNode "[_ imsld.finish]"]
			    $input_node appendChild $text
			    $activity_node appendChild $input_node
			}
		    }
		    imsld::generate_resources_tree -activity_item_id $activity_item_id -run_id $run_id -user_id $user_id -dom_node $activity_node -dom_doc $dom_doc
                    set completed_list [linsert $completed_list $sort_order [$activity_node asList]]
                }
            }
            imsld_as_as_rel {
                # add the structure to the list only if:
                # 1. the structure has already been started or finished
                # 2. the referencer structure-type is "selection"
                # (if it is the next activity to be done then it should had been marked as started 
                #  in the "structure_next_activity" function. which is the case when structure-type is "sequence")
                db_1row get_activity_structure_info { *SQL* }
                db_1row get_sort_order {
                    select sort_order from imsld_as_as_rels where rel_id = :rel_id
                }
                set started_p [db_0or1row as_started_p { *SQL* }]
		set completed_p [db_0or1row as_completed_p { *SQL* }]


                if { $started_p || [string eq $structure_type "selection"] } {
		    if { $completed_p } {
			set structure_node [$dom_doc createElement li]
			$structure_node setAttribute class "liOpen"
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute onclick "return loadContent('$div');"
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$structure_node appendChild $a_node
		    } else {
			set structure_node [$dom_doc createElement li]
			$structure_node setAttribute class "liOpen"
			set b_node [$dom_doc createElement b]
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute onclick "return loadContent('$div');"
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$b_node appendChild $a_node
			$structure_node appendChild $b_node
		    }

                    set nested_activities_list [imsld::generate_structure_activities_list -imsld_id $imsld_id \
                                                    -run_id $run_id \
                                                    -structure_item_id $structure_item_id \
                                                    -user_id $user_id \
                                                    -next_activity_id_list $next_activity_id_list \
                                                    -role_part_id $role_part_id \
                                                    -play_id $play_id \
                                                    -act_id $act_id \
                                                    -dom_node $structure_node \
                                                    -dom_doc $dom_doc]
                    set ul_node [$dom_doc createElement ul]
                    foreach nested_activity $nested_activities_list {
                        $ul_node appendFromList $nested_activity
                    }
                    $structure_node appendChild $ul_node
                    set completed_list [linsert $completed_list $sort_order [$structure_node asList]]
                }
            }
        }
    }
    return $completed_list
}

ad_proc -public imsld::generate_activities_tree {
    -run_id:required
    -user_id
    {-next_activity_id_list ""}
    -dom_node
    -dom_doc
} {
    @param run_id
    @param user_id

    @return A list of lists of the activities 
} {
    db_1row imsld_info {
        select imsld_id 
        from imsld_runs
        where run_id = :run_id
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

        switch $type {
            learning {
                # add the learning activity to the tree
                db_1row get_learning_activity_info { *SQL* }
                set started_activity_p [db_0or1row already_started {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'started'
                }]
                set completed_activity_p [db_0or1row already_completed {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'finished'
                }]
		set user_choice_p [db_string user_choice_p {select user_choice_p from imsld_complete_actsi where item_id = :complete_act_id and content_revision__is_live(complete_act_id) = 't'} -default "f"]
                if { $completed_activity_p || ([lsearch -exact $next_activity_id_list $activity_id] != -1) || ([string eq $complete_act_id ""] && [string eq $is_visible_p "t"] && [lsearch -exact $active_acts_list $act_item_id] != -1) } {

		    if { !$started_activity_p && [string eq $is_visible_p "t"] } {
			# bold letters
			set activity_node [$dom_doc createElement li]
			$activity_node setAttribute class "liOpen"
			set b_node [$dom_doc createElement b]
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			$a_node setAttribute onclick "return loadContent('$div')"
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$b_node appendChild $a_node
			$activity_node appendChild $b_node
			
			set text [$dom_doc createTextNode " "]
			$activity_node appendChild $text
		    } else {
			# the activity has been started
			set activity_node [$dom_doc createElement li]
#			$activity_node setAttribute class "liOpen"
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			$a_node setAttribute onclick "return loadContent('$div')"
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$activity_node appendChild $a_node
			
			set text [$dom_doc createTextNode " "]
			$activity_node appendChild $text

		    }

		    if { $completed_activity_p } {

			if { ![string eq $complete_act_id ""] } {
			    # the activity is finished
			    set img_node [$dom_doc createElement img]
			    $img_node setAttribute src "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/completed.png"
			    $img_node setAttribute border "0"
			    $img_node setAttribute alt "[_ imsld.finished]"
			    $img_node setAttribute title "[_ imsld.finished]"
			    $activity_node appendChild $img_node
			}
		    } elseif { [string eq $is_visible_p "t"] } {

			if { [string eq $user_choice_p "t"] } {
			    
			    # show the finish button
			    set input_node [$dom_doc createElement a]
			    $input_node setAttribute href "finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-learning.imsld"
			    $input_node setAttribute onclick "return loadTree(this.href)"
			    $input_node setAttribute class "finish"
			    $input_node setAttribute title "[_ imsld.finish_activity]"
			    set text [$dom_doc createTextNode "[_ imsld.finish]"]
			    $input_node appendChild $text
			    $activity_node appendChild $input_node
			}
		    }

		    imsld::generate_resources_tree -activity_item_id $activity_item_id -run_id $run_id -user_id $user_id -dom_node $activity_node -dom_doc $dom_doc
                    $dom_node appendChild $activity_node
                }
            }
            support {
                # add the support activity to the tree
                db_1row get_support_activity_info { *SQL* }
                set started_activity_p [db_0or1row already_started {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'started'
                }]
                set completed_activity_p [db_0or1row already_completed {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'finished'
                }]
		set user_choice_p [db_string user_choice_p {select user_choice_p from imsld_complete_actsi where item_id = :complete_act_id and content_revision__is_live(complete_act_id) = 't'} -default "f"]

                if { $completed_activity_p || ([lsearch -exact $next_activity_id_list $activity_id] != -1) || ([string eq $complete_act_id ""] && [string eq $is_visible_p "t"] && [lsearch -exact $active_acts_list $act_item_id] != -1) } {
		    set activity_node [$dom_doc createElement li]
		    $activity_node setAttribute class "liOpen"
		    if { !$started_activity_p && [string eq $is_visible_p "t"] } {
			# bold letters
			set b_node [$dom_doc createElement b]
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			$a_node setAttribute onclick "return loadContent('$div')"
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$b_node appendChild $a_node
			$activity_node appendChild $b_node
			
			set text [$dom_doc createTextNode " "]
			$activity_node appendChild $text
		    } else {
			# bold letters
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			$a_node setAttribute onclick "return loadContent('$div')"
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$activity_node appendChild $a_node
			
			set text [$dom_doc createTextNode " "]
			$activity_node appendChild $text
		    }

		    if { $completed_activity_p } {

			if { ![string eq $complete_act_id ""] } {
			    # the activity is finished
			    set img_node [$dom_doc createElement img]
			    $img_node setAttribute src "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/completed.png"
			    $img_node setAttribute border "0"
			    $img_node setAttribute alt "[_ imsld.finished]"
			    $img_node setAttribute title "[_ imsld.finished]"
			    $activity_node appendChild $img_node
			}
		    } else {
			if { [string eq $user_choice_p "t"] } {
			    # show the finish button
			    set input_node [$dom_doc createElement a]
			    $input_node setAttribute href "finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-support.imsld"
			    $input_node setAttribute onclick "return loadTree(this.href)"
			    $input_node setAttribute class "finish"
			    $input_node setAttribute title "[_ imsld.finish_activity]"
			    set text [$dom_doc createTextNode "[_ imsld.finish]"]
			    $input_node appendChild $text
			    $activity_node appendChild $input_node
			}
		    }
                    $dom_node appendChild $activity_node
		    imsld::generate_resources_tree -activity_item_id $activity_item_id -run_id $run_id -user_id $user_id -dom_node $activity_node -dom_doc $dom_doc
                }
            }
            structure {
                # this is a special case since there are some conditions to check
                # in order to determine if the referenced activities have to be shown.
                # because of that the proc generate_structure_activities_list is called,
                # which returns a tcl list in tDOM format.
                
                # anyway, we add the structure to the tree only if:
                # 1. the structure has already been started or finished
                # 2. the referencer structure-type is "selection"
                # (if it is the next activity to be done then it should had been marked as started 
                #  in the "structure_next_activity" function. which is the case when structure-type is "sequence")
                db_1row get_activity_structure_info { *SQL* }
                set started_p [db_0or1row as_started_p { *SQL* }]
                set completed_p [db_0or1row as_completed_p { *SQL* }]
                if { $started_p } {
		    if { $completed_p } {
			set structure_node [$dom_doc createElement li]
			$structure_node setAttribute class "liOpen"
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $structure_id -run_id $run_id -user_id $user_id]
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			$a_node setAttribute onclick "return loadContent('$div')"
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$structure_node appendChild $a_node
		    } else {
			set structure_node [$dom_doc createElement li]
			$structure_node setAttribute class "liOpen"
			set b_node [$dom_doc createElement b]
			set a_node [$dom_doc createElement a]
			set href [imsld::activity_url -activity_id $structure_id -run_id $run_id -user_id $user_id]
			set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
			$a_node setAttribute href $href
			$a_node setAttribute onclick "return loadContent('$div')"
			set text [$dom_doc createTextNode "$activity_title"]
			$a_node appendChild $text
			$b_node appendChild $a_node
			$structure_node appendChild $b_node
		    }

                    set nested_list [imsld::generate_structure_activities_list -imsld_id $imsld_id \
                                         -run_id $run_id \
                                         -structure_item_id $structure_item_id \
                                         -user_id $user_id \
                                         -next_activity_id_list $next_activity_id_list \
                                         -role_part_id $role_part_id \
                                         -play_id $play_id \
                                         -act_id $act_id \
                                         -dom_doc $dom_doc \
                                         -dom_node $dom_node]
                    # the nested finished activities are returned as a tcl list in tDOM format
                    $structure_node appendFromList [list ul [list] [concat [list] $nested_list]]
                    $dom_node appendChild $structure_node
                }
            }
        }
    }
}


ad_proc -public imsld::generate_resources_tree {
    -activity_item_id:required
    -run_id:required
    -user_id
    {-community_id ""}
    -dom_node
    -dom_doc
    -monitor:boolean
} {
    @param run_id
    @param user_id
    @param dom_node
    @param dom_doc
    @return Nothing, it appends the resources tree to the dom_node
    @error 
} {
    set list_node [$dom_doc createElement ul]
    set linear_item_list [db_list item_linear_list { *SQL* }]
    set has_items 0
    foreach imsld_item_id $linear_item_list {
        foreach sa_items_list [db_list_of_lists la_nested_associated_items { *SQL* }] {
	    set has_items 1
            set resource_id [lindex $sa_items_list 0]
            set resource_item_id [lindex $sa_items_list 1]
            set resource_type [lindex $sa_items_list 2]
#             if {[string eq "t" $resource_mode] } { 
#                 lappend sa_resource_item_list $resource_item_id
#             }
            
            imsld::process_resource_as_ul -resource_item_id $resource_item_id \
                -run_id $run_id \
                -dom_doc $dom_doc \
                -dom_node $list_node \
		-li_mode \
		-monitor=$monitor_p

#             if { [string eq "t" $resource_mode] } { 
#                 lappend activity_items_list $sa_resource_item_list
#             }
        }
    }
    if { $monitor_p } {
	set li_node [$dom_doc createElement li]
	set choose_node [$dom_doc createElement a]
	$choose_node appendChild [$dom_doc createTextNode "Add"]
	$choose_node setAttribute href {#}
	$li_node appendChild [$dom_doc createTextNode {[}]
	$li_node appendChild $choose_node
	$li_node appendChild [$dom_doc createTextNode {]}]
    }
    if { $has_items } { $dom_node appendChild $list_node }

#     set aux [$dom_doc createElement ul]
#     set aux2 [$dom_doc createElement li]
#     $aux appendChild $aux2
#     set aux3 [$dom_doc createTextNode "test"]
#     $aux2 appendChild $aux3
#     $dom_node appendChild $aux
}


ad_proc -public imsld::generate_runtime_assigned_activities_tree {
    -run_id:required
    -user_id
    -dom_node
    -dom_doc
} {
    @param run_id
    @param user_id
    @param dom_node
    @param dom_doc

    @return A list of lists of the activities 
} {
    # context info
    db_1row imsld_info { *SQL* }
    
    # 1. get the current role of the user
    # 2. get any related activities to the role with the rel imsld_run_time_activities_rel
    # 3. get the info of those activities (role_part_id, act_id, play_id) and generate the list
    #    NOTE: the activity will be shown only once, no matter from how many role parts it is referenced

    set user_role_id [db_string current_role { *SQL* }]
    set imsld_package_id [ad_conn package_id]

    # get the referenced activities to the role, assigned at runtime (notifications, level C)

    foreach activity_id [db_list runtime_activities { *SQL* } ] {
        # get the activity_type
        if { [db_0or1row learning_activity_p { *SQL* }] } {
            set activity_type learning
        } else {
            set activity_type support
        }
        set role_part_id [imsld::get_role_part_from_activity -activity_type $activity_type -leaf_id [content::revision::item_id -revision_id $activity_id]]
        
        # role_part context info
        db_1row role_part_context { *SQL* }

        switch $activity_type {
            learning {
                # add the learning activity to the tree
                db_1row get_learning_activity_info { *SQL* }
                set started_activity_p [db_0or1row already_started {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'started'
                }]
                set completed_activity_p [db_0or1row la_already_completed { *SQL* }]
		set user_choice_p [db_string user_choice_p {select user_choice_p from imsld_complete_actsi where item_id = :complete_act_id and content_revision__is_live(complete_act_id) = 't'} -default "f"]

		if { !$started_activity_p } {
		    set activity_node [$dom_doc createElement li]
		    $activity_node setAttribute class "liOpen"
		    set b_node [$dom_doc createElement b]
		    set a_node [$dom_doc createElement a]
		    set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
		    $a_node setAttribute href $href
		    set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
		    $a_node setAttribute onclick "return loadContent('$div')"
		    set text [$dom_doc createTextNode "$activity_title"]
		    $a_node appendChild $text
		    $b_node appendChild $a_node
		    $activity_node appendChild $b_node
		    
		    set text [$dom_doc createTextNode " "]
		    $activity_node appendChild $text
		} else {
		    # bold letters
		    set activity_node [$dom_doc createElement li]
		    $activity_node setAttribute class "liOpen"
		    set a_node [$dom_doc createElement a]
		    set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
		    $a_node setAttribute href $href
		    set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
		    $a_node setAttribute onclick "return loadContent('$div')"

		    set text [$dom_doc createTextNode "$activity_title"]
		    $a_node appendChild $text
		    $activity_node appendChild $a_node
		    
		    set text [$dom_doc createTextNode " "]
		    $activity_node appendChild $text
		}
		

		if { $completed_activity_p } {

		    if { [string eq $user_choice_p "t"] } {
			set img_node [$dom_doc createElement img]
			$img_node setAttribute src "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/completed.png"
			$img_node setAttribute border "0"
			$img_node setAttribute alt "[_ imsld.finished]"
			$img_node setAttribute title "[_ imsld.finished]"
			$activity_node appendChild $img_node
		  
		    }
		} else {

		    if { [string eq $user_choice_p "t"] } {
		    
			# show the button to finish the activity
			set input_node [$dom_doc createElement a]
			$input_node setAttribute href "finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-learning.imsld"
			$input_node setAttribute onclick "return loadTree(this.href)"
			$input_node setAttribute class "finish"
			$input_node setAttribute title "[_ imsld.finish_activity]"
			set text [$dom_doc createTextNode "[_ imsld.finish]"]
			$input_node appendChild $text
			$b_node appendChild $input_node 
		    
		    }
                }
                $dom_node appendChild $activity_node
            }
            support {
                # add the support activity to the tree
                db_1row get_support_activity_info { *SQL* }
                set started_activity_p [db_0or1row already_started {
                    select 1 from imsld_status_user 
                    where related_id = :activity_id 
                    and user_id = :user_id 
                    and run_id = :run_id
                    and status = 'started'
                }]
		set user_choice_p [db_string user_choice_p {select user_choice_p from imsld_complete_actsi where item_id = :complete_act_id and content_revision__is_live(complete_act_id) = 't'} -default "f"]
                set completed_activity_p [db_0or1row sa_already_completed { *SQL* }]

		if { !$started_activity_p } {
		    set activity_node [$dom_doc createElement li]
		    $activity_node setAttribute class "liOpen"
		    set b_node [$dom_doc createElement b]
		    set a_node [$dom_doc createElement a]
		    set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
		    set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
		    $a_node setAttribute href $href
		    $a_node setAttribute onclick "return loadContent('$div')"
		    set text [$dom_doc createTextNode "$activity_title"]
		    $a_node appendChild $text
		    $b_node appendChild $a_node
		    $activity_node appendChild $b_node
		    
		    set text [$dom_doc createTextNode " "]
		    $activity_node appendChild $text
		} else {
		    # bold letters
		    set activity_node [$dom_doc createElement li]
		    $activity_node setAttribute class "liOpen"
		    set a_node [$dom_doc createElement a]
		    set href [imsld::activity_url -activity_id $activity_id -run_id $run_id -user_id $user_id]
		    set div [imsld::activity_url -div -activity_id $activity_id -run_id $run_id -user_id $user_id]
		    $a_node setAttribute href $href
		    $a_node setAttribute onclick "return loadContent('$div')"
		    set text [$dom_doc createTextNode "$activity_title"]
		    $a_node appendChild $text
		    $activity_node appendChild $a_node
		    
		    set text [$dom_doc createTextNode " "]
		    $activity_node appendChild $text
		}
		
		if { $completed_activity_p } {

		    if { [string eq $user_choice_p "t"] } {
			set img_node [$dom_doc createElement img]
			$img_node setAttribute src "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]/resources/completed.png"
			$img_node setAttribute border "0"
			$img_node setAttribute alt "[_ imsld.finished]"
			$img_node setAttribute title "[_ imsld.finished]"
			$activity_node appendChild $img_node
		  
		    }
		} else {
		    if { [string eq $user_choice_p "t"] } {
		    
			# show the button to finish the activity
			set b_node [$dom_doc createElement b]
			set input_node [$dom_doc createElement a]
			$input_node setAttribute href "finish-component-element-${imsld_id}-${run_id}-${play_id}-${act_id}-${role_part_id}-${activity_id}-support.imsld"
			$input_node setAttribute onclick "return loadTree(this.href)"
			$input_node setAttribute class "finish"
			$input_node setAttribute title "[_ imsld.finish_activity]"
			set text [$dom_doc createTextNode "[_ imsld.finish]"]
			$input_node appendChild $text
			$b_node appendChild $input_node 
			$activity_node appendChild $b_node
		    
		    }
                }
                $dom_node appendChild $activity_node
		imsld::generate_resources_tree -activity_item_id $activity_item_id -run_id $run_id -user_id $user_id -dom_node $activity_node -dom_doc $dom_doc
            }
        }
    }
}

ad_proc -public imsld::structure_completion_resctriction_p { 
    -run_id:required
    -structure_item_id:required
} {
    @param run_id
    @param structure_item_id
    
    @return Returns 0 if any of the referenced activities from the structure_id doesn't have a completion restriction
} {

    foreach referenced_activity [db_list_of_lists struct_referenced_activities {
        select ar.object_id_two,
        ar.rel_type
        from acs_rels ar, imsld_activity_structuresi ias
        where ar.object_id_one = ias.item_id
        and ias.item_id = :structure_item_id
	and content_revision__is_live(ias.structure_id) = 't'
        order by ar.object_id_two
    }] {
        # get all the directly referenced activities (from the activity structure)
        set object_id_two [lindex $referenced_activity 0]
        set rel_type [lindex $referenced_activity 1]
        switch $rel_type {
            imsld_as_la_rel {
		if { [string eq "" [db_string la_completion_restriction {
		    select complete_act_id 
		    from imsld_learning_activitiesi
		    where item_id = :object_id_two
		    and content_revision__is_live(activity_id) = 't'
		}]] } {
		    # no restriction found, break
		    return 0
		}
	    }
            imsld_as_sa_rel {
		if { [string eq "" [db_string sa_completion_restriction {
		    select complete_act_id 
		    from imsld_support_activitiesi
		    where item_id = :object_id_two
		    and content_revision__is_live(activity_id) = 't'
		}]] } {
		    # no restriction found, break
		    return 0
		}
            }
            imsld_as_as_rel {
                # search recursively trough the referenced activities
                return [imsld::structure_completion_resctriction_p -run_id $run_id -structure_item_id $object_id_two]
            }
        }
    }
    # every referenced activity has a completion restriction
    return 1
}

ad_proc -public imsld::active_acts { 
    -run_id:required
    -user_id:required
    {-previous_list {}}
} {
    @param run_id
    @param user
    @param previous_list
    
    @return Returns the list of possible active acts for the user
} {
    set active_acts_list [list]

    set all_acts_list [db_list get_acts_in_run {
	select ia.act_id
	from imsld_runs ir, 
	imsld_imslds ii,
	cr_items ci,
	imsld_methods im,
	cr_items cm,
	imsld_plays ip,
	cr_items cp,
	imsld_acts ia 
	where ir.run_id = :run_id
	and ii.imsld_id = ir.imsld_id 
	and ii.imsld_id = ci.live_revision
	and ci.item_id = im.imsld_id 
	and im.method_id = cm.live_revision
	and cm.item_id = ip.method_id 
	and ip.play_id = cp.live_revision
	and cp.item_id = ia.play_id
	order by ip.sort_order, ia.sort_order
    }]
    set i 0
    set continue 1
    while { $i < [llength $all_acts_list] && $continue == 1 } {
	set act_in_run [lindex $all_acts_list $i]
	incr i
	# let's see if the user participates in the act
	if { [imsld::user_participate_p -run_id $run_id -act_id $act_in_run -user_id $user_id] \
		 && ![imsld::act_finished_p -run_id $run_id -act_id $act_in_run -user_id $user_id] } {
	    # let's see if the act doesn't have any completion restriction:
	    # 1. time-limit
	    # 2. when-property-is-set
	    # 3. when-condition-true
	    # 4. when role-part-is-completed
	    # 5. any referenced activity structure (which by default have a completion restriction)
	    set act_in_run_item_id [content::revision::item_id -revision_id $act_in_run] 

	    # 1. time-limit, 2. when-property-is-set, 3. when-condition-true: all the info is stored via complete_act_id in the acts table
		if { ![string eq "" [db_string complete_act_id {select complete_act_id from imsld_acts where act_id = :act_in_run}]] && [lsearch -exact $previous_list $act_in_run_item_id] == -1 } {
		# there is a completion restriction, stop here
		lappend active_acts_list $act_in_run_item_id
		break
	    }

	    # 4. when role-part-is-completed, 5. referenced activity structures
	    #    This is a special case, since if any of the activities referenced by the role part doesn't have a completion restriction
	    #    then the act has to be appended to the list
	    #    Note: The role parts that finish the act are mapped to the act via imsld_act_rp_completed_rel (acs_rels)

	    set role_parts_list [db_list related_role_parts {
		select item_id
		from imsld_role_partsi
		where act_id = :act_in_run_item_id
		and content_revision__is_live(role_part_id) = 't'
		order by sort_order
	    }]
	    foreach role_part_item_id $role_parts_list {
		# get all the activities in the role part and see if none has any compleion resctriction 

		db_1row get_role_part_activity {
		    select case
		    when learning_activity_id is not null
		    then 'learning'
		    when support_activity_id is not null
		    then 'support'
		    when activity_structure_id is not null
		    then 'structure'
		    else 'none'
		    end as type,
		    learning_activity_id,
		    support_activity_id,
		    activity_structure_id
		    from imsld_role_partsi
		    where item_id = :role_part_item_id
		    and content_revision__is_live(role_part_id) = 't'
		}
		set continue 0
		# check if the referenced activities have been finished
		switch $type {
		    learning {
			if { [string eq "" [db_string la_completion_restriction {
			    select complete_act_id 
			    from imsld_learning_activitiesi
			    where item_id = :learning_activity_id
			    and content_revision__is_live(activity_id) = 't'
			}]] } {
			    # activity without restriction found, 
			    # append the act to the list of active acts
			    set continue 1
			    break
			}
		    }
		    support {
			if { [string eq "" [db_string sa_completion_restriction {
			    select complete_act_id 
			    from imsld_support_activitiesi
			    where item_id = :support_activity_id
			    and content_revision__is_live(activity_id) = 't'
			}]] } {
			    # activity without restriction found, 
			    # append the act to the list of active acts
			    set continue 1
			    break
			}
		    }
		    structure {
			# every activity structure has a completion restriction (at leat, every activity must be visited)
			# so we can stop here
			set continue 0
			break
		    }
		}
	    }
	    # if we reached this point, the act must be shown
	    if { [lsearch -exact $previous_list $act_in_run_item_id] == -1 } {
		# add the act to the list only if it wasn't in the list already
		lappend active_acts_list $act_in_run_item_id
	    }
	}   
    }
    return [concat $previous_list $active_acts_list]
}

ad_proc -public imsld::get_next_activity_list { 
    -run_id:required
    {-user_id ""}
} {
    @param imsld_item_id
    @param run_id
    @option user_id default [ad_conn user_id]
    
    @return The list of next activity_ids of each role_part and play in the IMS-LD.
} {

    # get the imsld info
    db_1row get_ismld_info {
        select ii.imsld_id, ii.item_id as imsld_item_id
        from imsld_imsldsi ii, imsld_runs run
        where ii.imsld_id = run.imsld_id
        and run.run_id = :run_id
    }
    set user_id [expr { [string eq "" $user_id] ? [ad_conn user_id] : $user_id }]
    set next_act_item_id_list [list]

    # search trough each play
    foreach play_list [db_list_of_lists imsld_plays {
        select ip.play_id,
        ip.item_id
        from imsld_playsi ip, imsld_methodsi im
        where ip.method_id = im.item_id
        and im.imsld_id = :imsld_item_id
        and content_revision__is_live(ip.play_id) = 't'
    }] {
        set play_id [lindex $play_list 0]
        set play_item_id [lindex $play_list 1]
        # get the act_id of the last completed activity,
        # search for the last completed act in the play
        if { ![db_0or1row get_last_completed {
            select stat.related_id,
            stat.role_part_id,
            stat.type,
            stat.act_id
            from imsld_status_user stat
            where  run_id = :run_id
            and stat.play_id = :play_id
            and stat.type in ('learning','support','structure')
            order by stat.status_date desc
            limit 1
        }] } {
            # if there is no completed activity for the act, it hasn't been started yet. 
            # get the first act_id in which the user is involved and check if other users has finished previous acts
            #get first act, get acts in run
            set acts_list [db_list get_acts_in_run {
                select iai.act_id
                from imsld_runs ir, 
                     imsld_imsldsi iii,
                     imsld_methodsi imi,
                     imsld_playsi ipi,
                     imsld_actsi iai 
                where ir.run_id=:run_id
                      and iii.imsld_id=ir.imsld_id 
                      and imi.imsld_id=iii.item_id 
                      and imi.item_id=ipi.method_id 
                      and iai.play_id=ipi.item_id
                order by iai.sort_order
            }]
            
            set previous_acts [list]
            foreach act $acts_list {
                if {[imsld::user_participate_p -run_id $run_id -act_id $act -user_id $user_id]} {
                    set first_involved_act $act
                    set first_involved_act_item_id [db_string get_act_item_id {
                                                                             select item_id
                                                                             from imsld_actsi
                                                                             where act_id=:first_involved_act
                    }]
                    break
                } else {
                    lappend previous_acts $act
                }
            }
            
            set involved_roles [imsld::roles::get_list_of_roles -imsld_id $imsld_id]
            set involved_users [list]
            foreach role $involved_roles {
                set involved_users [concat $involved_users [imsld::roles::get_users_in_role -role_id [lindex $role 0] -run_id $run_id]]
            }

            set finish_flag 1
            foreach user [lsort -unique $involved_users] {
                foreach previous $previous_acts {
                    if {![imsld::act_finished_p -run_id $run_id -act_id $previous -user_id $user] } {
                        if {[imsld::user_participate_p -run_id $run_id -act_id $previous -user_id $user]} {
                        set finish_flag 0
                       }
                    }
                }
            }
            if {$finish_flag == 1 } {
                lappend next_act_item_id_list $first_involved_act_item_id
            }
            continue
        }

        if { ![imsld::act_finished_p -run_id $run_id -act_id $act_id -user_id $user_id] } {
            if {[imsld::user_participate_p -run_id $run_id -act_id $act_id -user_id $user_id]} {
                lappend next_act_item_id_list [content::revision::item_id -revision_id $act_id]
                continue
            }
        }
        # if we reached this point, we have to search for the next act in the play
        db_1row act_info {
            select sort_order as act_sort_order
            from imsld_acts
            where act_id = :act_id
        }

        if { [db_0or1row search_current_play {
            select ia.item_id as act_item_id
            from imsld_actsi ia
            where ia.play_id = :play_item_id
            and ia.sort_order = :act_sort_order + 1 
        }] } {
            # get the current play_id's sort_order and sarch in the next play in the current method_id
            set all_users_finished 1
            #the act is only showed as next activity when all users in roles has finished the previous act
            
            if {[db_0or1row get_last_act { select ia2.act_id as last_act_id from imsld_actsi ia1, imsld_acts ia2 where ia1.item_id=:act_item_id and ia2.sort_order=(ia1.sort_order -1) and ia1.play_id=ia2.play_id}]
                } {
                #get list of involved roles
                set roles_list [imsld::roles::get_list_of_roles -imsld_id $imsld_id]
                    
                #get list of involved users
                set users_list [list]
                foreach role $roles_list {
                    set users_in_role [imsld::roles::get_users_in_role -role_id [lindex $role 0] -run_id $run_id]
                    set users_list [concat $users_list $users_in_role]
                }

                #check if all has finished the act
                foreach user $users_list {
                    if {![imsld::act_finished_p -act_id $last_act_id -run_id $run_id -user_id $user]} {
                        if {[imsld::user_participate_p -run_id $run_id -act_id $last_act_id -user_id $user]} {
                            set all_users_finished 0
                        }
                    }
                }
            }

            if {$all_users_finished} {
                lappend next_act_item_id_list $act_item_id
            }
        }
    }

    # append to the list of "active acts" those which don't have any "completion" restrictions
    set next_act_item_id_list [imsld::active_acts -run_id $run_id -user_id $user_id -previous_list $next_act_item_id_list]

    # 1. for each act in the next_act_id_list
    # 1.2. for each role_part in the act
    # 1.2.1 find the next activity referenced by the role_part
    #       (learning_activity, support_activity, activity_structure)  
    # 1.2.1.1 if it is a learning or support activity, no problem, find the associated files and return the lists
    # 2.2.1.2 if it is an activity structure we have verify which activities are already completed and return the next
    #         activity in the activity structure, handling the case when the next activity is also an activity structure

    set user_roles_list [imsld::roles::get_user_roles -user_id $user_id -run_id $run_id]
    set next_activity_id_list [list]
    foreach act_item_id $next_act_item_id_list {
        foreach role_part_id [db_list act_role_parts "
            select irp.role_part_id 
                   from imsld_role_parts irp,
                   imsld_rolesi iri 
            where content_revision__is_live(irp.role_part_id)='t' 
                  and irp.act_id=:act_item_id 
                  and irp.role_id=iri.item_id 
                   and iri.role_id in ([join $user_roles_list ","])
        "] {
            db_1row get_role_part_activity {
                select case
                when learning_activity_id is not null
                then 'learning'
                when support_activity_id is not null
                then 'support'
                when activity_structure_id is not null
                then 'structure'
                else 'none'
                end as activity_type,
                case
                when learning_activity_id is not null
                then content_item__get_live_revision(learning_activity_id)
                when support_activity_id is not null
                then content_item__get_live_revision(support_activity_id)
                when activity_structure_id is not null
                then content_item__get_live_revision(activity_structure_id)
                else content_item__get_live_revision(environment_id)
                end as next_activity_id,
                environment_id as rp_environment_item_id
                from imsld_role_parts
                where role_part_id = :role_part_id
            }
            # activity structure
            if { [string eq $activity_type structure] } {
                # activity structure. we have to look for the next learning or support activity
                set activity_list [imsld::structure_next_activity -activity_structure_id $next_activity_id -imsld_id $imsld_id -run_id $run_id -role_part_id $role_part_id]
                set next_activity_id [lindex $activity_list 0]
            }
            lappend next_activity_id_list $next_activity_id
        }
    }
    # return the next_activity_id_list
    return $next_activity_id_list
        
}

ad_proc -public imsld::get_activity_from_environment { 
   -environment_item_id
   
} { 
    @return The a list of lists of the activity_id, activity_item_id and activity_type from which the environment is being referenced
} {
    set activities_list [list]
    foreach environment_list [db_list_of_lists get_env_info {
        select ar.object_id_one,
        ar.rel_type
        from acs_rels ar
        where ar.object_id_two = :environment_item_id
    }] {
        set object_id_one [lindex $environment_list 0]
        set rel_type [lindex $environment_list 1]
        # the enviroment may be referenced froma learning activity, support activity or from an enviroment!
        if { [string eq $rel_type imsld_la_env_rel] } {
            set activities_list [concat $activities_list [db_list_of_lists learning_env_ref {
                select la.activity_id,
                la.item_id,
                'learning'
                from imsld_learning_activitiesi la
                where la.item_id = :object_id_one
            }]]
        }
        if { [string eq $rel_type imsld_sa_env_rel] } {
            set activities_list [concat $activities_list [db_list_of_lists support_env_ref {
                select sa.activity_id,
                sa.item_id,
                'support'
                from imsld_support_activitiesi sa
                where sa.item_id = :object_id_one
            }]]
        }
        if { [string eq $rel_type imsld_env_env_rel] } {
            # the environment is referenced fron another environment.
            # we get the referencer environment and call this function again (recursivity is our friend =)
            # and besides, the environment may be referenced from more than one environment!
            set activities_list_nested [list]
            foreach referenced_environment [db_list_of_lists get_referencer_env_info {
                select ar.object_id_one as env_referencer_id
                from acs_rels ar
                where ar.object_id_two = :object_id_one
            }] {
                set referencer_env_item_id [lindex $referenced_environment 0]
                set activities_list_nested [concat $activities_list_nested [imsld::get_activity_from_environment -environment_item_id $referencer_env_item_id]]
            }
            set activities_list [concat $activities_list $$activities_list]
        }
    }
    return $activities_list
}

ad_proc -public imsld::get_activity_from_resource { 
   -resource_id
} { 
    @return The a list of lists of the activity_id, activity_item_id and activity_type from which the resource is being referenced
} {
    set activities_list [list]
    # find out the rel_type in order to know from which activity the resource is being referenced
    foreach object_list [db_list_of_lists directly_mapped_info {
        select ar.rel_type,
        ar.object_id_one
        from acs_rels ar, imsld_cp_resourcesi icr 
        where icr.resource_id = :resource_id 
        and ar.object_id_two = icr.item_id
    }] {
        set rel_type [lindex $object_list 0]
        set object_id_one [lindex $object_list 1]
        if { [string eq $rel_type imsld_item_res_rel] } {
            # get item info
            foreach nested_object_list [db_list_of_lists get_nested_info {
                select ar.rel_type as rel_type_nested,
                ar.object_id_one as object_id_nested
                from acs_rels ar
                where ar.object_id_two = :object_id_one
            }] {
                set rel_type_nested [lindex $nested_object_list 0]
                set object_id_nested [lindex $nested_object_list 1]
                if { [string eq $rel_type_nested imsld_preq_item_rel] } {
                    # get the learning_activity_id and return it
                    set activities_list [concat $activities_list [db_list_of_lists get_prereq_activity {
                        select la.activity_id,
                        la.item_id as activity_item_id,
                        'learning'
                        from imsld_learning_activitiesi la,
                        imsld_prerequisitesi prereq
                        where prereq.item_id = :object_id_nested
                        and la.prerequisite_id = prereq.item_id
                    }]]
                }
                if { [string eq $rel_type_nested imsld_lo_item_rel] } {
                    # get the learning_activity_id and return it
                        set activities_list [concat $activities_list [db_list_of_lists get_lobjective_activity {
                        select la.activity_id,
                        la.item_id as activity_item_id,
                        'learning'
                        from imsld_learning_activitiesi la,
                        imsld_learning_objectivesi lobjectives
                        where lobjectives.item_id = :object_id_nested
                        and la.learning_objective_id = lobjectives.item_id
                        }]]
                }
                if { [string eq $rel_type_nested imsld_actdesc_item_rel] } {
                    # get the learning or support activity and return it
                    if { [db_0or1row learning_activity_ref {
                        select la.activity_id,
                        la.item_id as activity_item_id,
                        'learning'
                        from imsld_learning_activitiesi la,
                        imsld_activity_descsi ades
                        where ades.item_id = :object_id_nested
                        and la.activity_description_id = ades.item_id
                    }] } {
                        set activities_list [concat $activities_list [list [list $activity_id $activity_item_id learning]]]
                    } else {
                        set activities_list [concat $activities_list [db_list_of_lists support_activity_ref {
                            select sa.activity_id,
                            sa.item_id as activity_item_id,
                            'support'
                            from imsld_support_activitiesi sa,
                            imsld_activity_descsi ades
                            where ades.item_id = :object_id_nested
                            and sa.activity_description_id = ades.item_id
                        }]]
                    }
                }
                if { [string eq $rel_type_nested imsld_as_info_i_rel] } {
                    # get the activity_structure_id and return it
                    set activities_list [concat $activities_list [db_list_of_lists activity_structure_ref {
                        select structure_id as activity_id,
                        item_id as activity_item_id,
                        'structure'
                        from imsld_activity_structuresi
                        where item_id = :object_id_nested
                    }]]
                }
                if { [string eq $rel_type_nested imsld_l_object_item_rel] } {
                    # item referenced from a learning object, which it's referenced fron an environment
                    # get the environment
                    db_1row get_env_lo_info {
                        select lo.environment_id as environment_item_id
                        from imsld_learning_objectsi lo
                        where lo.item_id = :object_id_nested
                    }
                    set activities_list [concat $activities_list [imsld::get_activity_from_environment -environment_item_id $environment_item_id]]
                }
            }
            # if we reached this point, the resource may be reference fron a conference service
            # which is referenced from an environment
            if { [db_0or1row get_env_serv_info {
                select serv.environment_id as environment_item_id
                from imsld_conference_servicesi ecs,
                imsld_servicesi serv
                where ecs.imsld_item_id = :object_id_one
                and ecs.service_id = serv.item_id
            }] } {
                set activities_list [concat $activities_list [imsld::get_activity_from_environment -environment_item_id $environment_item_id]]
            }
        }        
    }
    return $activities_list
}

ad_proc -public imsld::get_imsld_from_activity { 
   -activity_id
    -activity_type
} { 
    @return The imsld_id from which the activity is being used.
} {
    switch $activity_type {
        learning {
            db_1row get_imsld_from_la_activity { *SQL* }
        }
        support {
            db_1row get_imsld_from_sa_activity { *SQL* }
        }
        structure {
            db_1row get_imsld_from_as_activity { *SQL* }
        }
    }
    return $imsld_id
}

ad_proc -public imsld::get_resource_from_object {
    -object_id
} {
    <p>Get the object which is asociated with an acs_object_id</p>
    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
    db_1row get_resource {
        select resource_id
        from imsld_cp_resources
        where acs_object_id = :object_id
    }
    return $resource_id
}

ad_proc -public imsld::finish_resource {
    -resource_id
    -run_id
} {
    <p>Tag a resource as finished into an activity. Return true if success, false otherwise</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
    #look for the asociated activities
    set activities_list [imsld::get_activity_from_resource -resource_id $resource_id]
    # process each activity
    foreach activity_list $activities_list {
        if { !([llength $activity_list] == 3) } {
            # it's not refrenced from an activity, skip it
            break
        }
        # set the activity_id, activity_item_id and activity_type
        set activity_id [lindex $activity_list 0]
        set activity_item_id [lindex $activity_list 1]
        set activity_type [lindex $activity_list 2]

        #get info
        set role_part_id_list [imsld::get_role_part_from_activity -activity_type $activity_type -leaf_id $activity_item_id]
        set imsld_id [imsld::get_imsld_from_activity -activity_id $activity_id -activity_type $activity_type]
        set user_id [ad_conn user_id]
        
        #if not done yet, tag the resource as finished
        if { ![db_string check_completed_resource { *SQL* }] } {
            db_dml insert_completed_resource { *SQL* }
        }
        #find all the resouces in the same activity 

        dom createDocument foo foo_doc
        set foo_node [$foo_doc documentElement]
        switch $activity_type {
            learning {
                set first_resources_item_list [imsld::process_learning_activity_as_ul -run_id $run_id -activity_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
		set completion_restriction [db_string la_completion_restriction {
		    select complete_act_id 
		    from imsld_learning_activities
		    where activity_id = :activity_id 
		} -default ""]
            }
            support {
                set first_resources_item_list [imsld::process_support_activity_as_ul -run_id $run_id -activity_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
		set completion_restriction [db_string la_completion_restriction {
		    select complete_act_id 
		    from imsld_support_activities
		    where activity_id = :activity_id 
		} -default ""]
            }
            structure {
                set first_resources_item_list [imsld::process_activity_structure_as_ul -run_id $run_id -structure_item_id $activity_item_id -resource_mode "t" -dom_node $foo_node -dom_doc $foo_doc]
		set completion_restriction t
            }
        }

        #only the learning_activities must be finished
        set resources_item_list [lindex $first_resources_item_list 3]
        if { [llength $resources_item_list] == 0 } {
            set resources_item_list [lindex $first_resources_item_list 2]
        }
        
        set all_finished_p 1
        foreach resource_item_id $resources_item_list { 
            foreach res_id $resource_item_id {
                if { ![db_0or1row resource_finished_p {
                    select 1 
                    from imsld_status_user stat, imsld_cp_resourcesi icr
                    where icr.item_id = :res_id
                    and icr.resource_id = stat.related_id
                    and user_id = :user_id
                    and run_id = :run_id
                    and status = 'finished'
                }] } {
                    # if the resource is not in the imsld_status_user, then the resource is not finished
                    set all_finished_p 0
                    break
                }
            }
        }

        #if all are finished, tag the activity as finished
        if { $all_finished_p && ![db_0or1row already_finished { *SQL* }] && [string eq $completion_restriction ""] } {
            foreach role_part_id $role_part_id_list {
                db_1row context_info {
                    select acts.act_id,
                    plays.play_id
                    from imsld_actsi acts, imsld_playsi plays, imsld_role_parts rp
                    where rp.role_part_id = :role_part_id
                    and rp.act_id = acts.item_id
                    and acts.play_id = plays.item_id
                }
                imsld::finish_component_element -imsld_id $imsld_id  \
                    -run_id $run_id \
                    -play_id $play_id \
                    -act_id $act_id \
                    -role_part_id $role_part_id \
                    -element_id $activity_id \
                    -type $activity_type\
                    -code_call
            }
        }
    }
}

ad_proc -public imsld::get_property_item_id {
    -identifier:required
    -imsld_id
    -play_id
} {
    <p>Get the property_id from the property_identifier in a imsld_id</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {

if {[info exist play_id] & ![info exist imsld_id]} {
    set imsld_id [db_string get_imsld_id_from_play {
                                                    select iii.item_id 
                                                    from imsld_imsldsi iii, 
                                                         imsld_methodsi imi, 
                                                         imsld_plays ip 
                                                    where ip.method_id=imi.item_id 
                                                          and imi.imsld_id=iii.item_id 
                                                          and ip.play_id=:play_id
    }]
}

    return [db_string get_property_id {
        select ip.item_id 
        from imsld_propertiesi ip, 
        imsld_componentsi ici,
        imsld_imsldsi iii
        where ip.component_id = ici.item_id 
        and ici.imsld_id = iii.item_id
        and iii.item_id = :imsld_id
        and ip.identifier = :identifier
       }]
}

ad_proc -public imsld::grant_forum_permissions {
    -user_id
    -resource_item_id
    -run_id
} {
    <p>Grant permissions to forums related to an imsld package</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
    #get the forum object_id
    db_1row get_forum_object_id {select acs_object_id as forum_id
                                 from imsld_cp_resourcesi 
                                 where item_id=:resource_item_id
                                 }
#first, revoke all permissions
        permission::revoke -party_id $user_id -object_id $forum_id  -privilege "write"
        permission::revoke -party_id $user_id -object_id $forum_id  -privilege "create"
        permission::revoke -party_id $user_id -object_id $forum_id  -privilege "admin"
        permission::revoke -party_id $user_id -object_id $forum_id  -privilege "forum_moderate"


    #get the user active role
    db_1row get_active_role {
                            select iruns.active_role_id as active_role
                            from imsld_run_users_group_rels iruns,
                                 acs_rels ar,
                                 imsld_run_users_group_ext iruge 
                            where iruge.run_id=:run_id 
                                  and ar.object_id_one=iruge.group_id 
                                  and ar.object_id_two=:user_id 
                                  and ar.rel_type='imsld_run_users_group_rel' 
                                  and ar.rel_id=iruns.rel_id
    }

#get the permissions related to that role
    set manager_in_forum 0
    if {[db_0or1row is_manager {select iri.role_id as manager_role_id
                                from imsld_conference_services ics,
                                     acs_rels ar,
                                     imsld_rolesi iri
                                where ar.rel_type='imsld_item_res_rel'
                                      and ar.object_id_two=:resource_item_id
                                      and ics.imsld_item_id=ar.object_id_one
                                      and iri.item_id=ics.manager_id
                                      }]
    } {
        set manager_in_forum 1
        if {[string equal $manager_role_id $active_role ]} {
            permission::grant -party_id $user_id -object_id $forum_id  -privilege "admin"
        }
    }

#moderator
    if {[db_0or1row is_moderator {select ics.moderator_id 
                                from imsld_conference_services ics, 
                                     acs_rels ar,
                                     imsld_rolesi iri
                                where ics.imsld_item_id=ar.object_id_one
                                      and ar.rel_type='imsld_item_res_rel'
                                      and ar.object_id_two=:resource_item_id
                                      and iri.item_id=ics.moderator_id
                                      and iri.role_id=:active_role}]
    } {
        if {[string equal $manager_in_forum "0"]} {
             permission::grant -party_id $user_id -object_id $forum_id  -privilege "write" 
             set manager_in_forum 1
        }

        permission::grant -party_id $user_id -object_id $forum_id  -privilege "read"
        db_foreach get_existing_messages { select message_id from forums_messages where forum_id=:forum_id } {
            permission::grant -party_id $user_id -object_id $message_id -privilege "forum_moderate"
        }

    }

#participant
    if {[db_0or1row is_participant {select iroles.role_id as participant_id
                                    from acs_rels ar, 
                                         acs_rels ar2, 
                                         imsld_conference_servicesi ics,
                                         imsld_rolesi iroles
                                    where ar2.rel_type='imsld_item_res_rel' 
                                          and ar2.object_id_two=:resource_item_id
                                          and ar2.object_id_one=ics.imsld_item_id 
                                          and ics.item_id=ar.object_id_one 
                                          and ar.rel_type='imsld_conf_part_rel'
                                          and ar.object_id_two=iroles.item_id
                                          and iroles.role_id=:active_role}]
    } {
        permission::grant -party_id $user_id -object_id $forum_id  -privilege "read"
        permission::grant -party_id $user_id -object_id $forum_id  -privilege "create"
        if {[string equal $manager_in_forum "0"]} {
             permission::grant -party_id $user_id -object_id $forum_id  -privilege "admin" 
             set manager_in_forum 1
        }

        db_foreach get_existing_messages { select message_id from forums_messages where forum_id=:forum_id } {
            permission::grant -party_id $user_id -object_id $message_id -privilege "write"
        }
    }


#observer
    if {[db_0or1row is_observer {select iroles.role_id as observer_id
                                    from acs_rels ar, 
                                         acs_rels ar2, 
                                         imsld_conference_servicesi ics,
                                         imsld_rolesi iroles
                                    where ar2.rel_type='imsld_item_res_rel' 
                                          and ar2.object_id_two=:resource_item_id
                                          and ar2.object_id_one=ics.imsld_item_id 
                                          and ics.item_id=ar.object_id_one 
                                          and ar.rel_type='imsld_conf_obser_rel'
                                          and ar.object_id_two=iroles.item_id
                                          and iroles.role_id=:active_role}]
    } {
        permission::grant -party_id $user_id -object_id $forum_id  -privilege "read"
    }
}

ad_proc -public imsld::delete_run {
    -run_id:required
} {
    <p>Delete a run with all dependencies</p>
    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {

    db_dml delete_related_property_instances {
        select content_revision__delete(instance_id)
	from imsld_property_instances 
	where run_id=:run_id
    }
    db_dml delete_related_attribute_instances {
        delete from imsld_attribute_instances where run_id=:run_id
    }
    db_dml delete_related_status_user {
        delete from imsld_status_user where run_id=:run_id
    }
    db_dml delete_related_notification_history {
        delete from imsld_notifications_history where run_id=:run_id
    }

    db_dml delete_run {delete from imsld_runs where run_id=:run_id}
}

ad_proc -public imsld::delete_cr_item {
    -item_id:required
    -only_revisions:boolean
} {
    <p>Delete an item in cr_items if created by imsld</p>
    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
#we must search for dependencies before aplying content::item::delete
    set related_imsld_item_list [db_list_of_lists get_related_imsld_items {
        select cri.content_type, 
               crr.revision_id,
               aot.table_name,
               aot.id_column
        from cr_items cri,
             cr_revisions crr,
             acs_object_types aot
        where cri.item_id=:item_id
              and crr.item_id=cri.item_id
              and aot.object_type=cri.content_type
    }]
    
    foreach related_item $related_imsld_item_list {
            #delete all item_types
        db_dml delete_imsld_type "delete 
                                  from [lindex $related_item 2] 
                                  where [lindex $related_item 3] = [lindex $related_item 1]"
        content::revision::delete -revision_id [lindex $related_item 1]
    }

    set relations_list [db_list get_acs_relations {
        select rel_id from acs_rels where object_id_one=:item_id or object_id_two=:item_id
    }]
    foreach relation $relations_list {
        relation_remove $relation
    }
        
    if {!$only_revisions_p} {
         content::item::delete -item_id $item_id   
    }
    

        
}


ad_proc -public imsld::drop_imsld_package {
    -object_id:required
} {
    <p>Drop an imsld package</p>
    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
    #get related runs and drop them
    set run_id_list [db_list get_run_id_list {
                     select ir.run_id 
                     from acs_objects ao,
                          cr_items crr, 
                          cr_revisions crev,
                          imsld_runs ir 
                     where ao.context_id=:object_id
                          and crr.content_type='imsld_imsld' 
                          and crr.item_id=ao.object_id 
                          and crev.item_id=crr.item_id 
                          and ir.imsld_id=crev.revision_id
    } ]
    
    foreach run_id $run_id_list {
        imsld::delete_run -run_id $run_id
    }
    
    set related_objects_list  [db_list get_related_objects {select object_id as related_object_id
                                                      from acs_objects
                                                      where context_id=:object_id
                                                            and object_type='content_item'
                                                       }]
        foreach related_item $related_objects_list {        
            imsld::delete_cr_item -item_id $related_item -only_revisions
        }
        #to avoid conflicts, we first remove all revisions and then we remove the items themselves
        foreach related_item $related_objects_list {        
            imsld::delete_cr_item -item_id $related_item
        }
}

ad_proc -public imsld::grant_permissions {
    -resources_activities_list
    -user_id
    -run_id
} {
    <p>Grant permissions to imsld files related to imsld resources</p>

    @author Luis de la Fuente Valentín (lfuente@it.uc3m.es)
} {
        foreach the_resource_id [join $resources_activities_list] {

            if {![db_0or1row get_object_from_resource {}]} {
            
                set related_cr_items [db_list get_cr_item_from_resource {} ]
                
                foreach related_item $related_cr_items {
                    permission::grant -party_id $user_id -object_id $related_item  -privilege "read"
                }
            } else {
                if {[db_0or1row is_forum {}]} {
                    imsld::grant_forum_permissions -user_id $user_id -resource_item_id $the_resource_id -run_id $run_id
                } 
            }
   }
}


ad_register_proc GET /finish-component-element* imsld::finish_component_element
ad_register_proc POST /finish-component-element* imsld::finish_component_element
