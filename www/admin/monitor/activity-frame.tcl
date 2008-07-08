# packages/imsld/www/admin/monitor/activity-frame.tcl

ad_page_contract {

    Page used to display the associated info of a given acitvity

    @author jopez@inv.it.uc3m.es
    @creation-date Nov 2006
} -query {
    run_id:integer,notnull
    {activity_id:integer ""}
    {learning_object_id:integer ""}
    {service_id:integer ""}
    type:notnull
    {years:integer 0}
    {months:integer 0}
    {days:integer 0}
    {hours:integer 0}
    {minutes:integer 0}
    {seconds:integer 0}
    {property:optional ""}
    {value:optional ""}
    {option ""}
} -validate {
    non_empty_id {
        if { [string eq "" $activity_id] && [string eq "" $learning_object_id] && [string eq "" $service_id] } {
            ad_complain "[_ imsld.lt_You_must_provide_an_a]"
        }
    }
}

set page_title "[_ imsld.lt_Monitoring_One_Activi]"
set context [list]

set elements [list portrait \
                  [list label "" \
                       display_template {<img style="height:75px;"
                  src="/shared/portrait-bits.tcl?user_id=@related_users.user_id@"
                  alt="No Portrait"/>}] \
                  user_name \
                  [list label "[_ imsld.Name]" \
                       display_template {<a href="individual-report-frame?run_id=${run_id}&member_id=@related_users.user_id@" onclick="return loadContent('individual-report-frame?run_id=${run_id}&member_id=@related_users.user_id@')" title="[_ imsld.lt_Users_individual_repo]">@related_users.user_name@</a>}] \
                  email \
                  [list label "[_ imsld.Email]"]]

if { [string eq $type "learning"] || [string eq $type "support"] || [string eq $type "structure"] } {
    set frame_header "[_ imsld.lt_Users_who_have_starte] "

    # status directly recorded in the status table, get the info
    if { [string eq $type "structure"] } {
	db_1row activity_info {
	    select title as activity_title
	    from imsld_activity_structuresi
	    where structure_id = :activity_id
	}
    } elseif { [string eq $type "support"] } {
	db_1row activity_info {
	    select title as activity_title
	    from imsld_support_activitiesi
	    where activity_id = :activity_id
	}
    } else {
	db_1row activity_info {
	    select title as activity_title
	    from imsld_learning_activitiesi
	    where activity_id = :activity_id
	}
    }
    append frame_header " \"$activity_title\""

    template::multirow create related_users user_id user_name email role start_date finish_date
    lappend elements start_date \
        [list label "[_ imsld.Start_Date]"]
    lappend elements finish_date \
        [list label "[_ imsld.Finish_Date]"]

    set users_list [list]
    db_foreach related_user {
        select stat.user_id,
        stat.role_id,
        stat.status,
        to_char(stat.status_date,'MM/DD/YYYY HH24:MI:SS') as status_date,
        persons.last_name||', '||persons.first_names as user_name,
        parties.email
        from imsld_status_user stat,
        persons,
        parties
        where stat.user_id = persons.person_id
        and persons.person_id = parties.party_id
        and stat.run_id = :run_id
        and related_id = :activity_id
        order by user_id, status desc
    } {
        if { [lsearch -regexp $users_list $user_id] != -1 } {
            # the elemen exists, replace the list element
            switch $status {
                started {
                    set users_list [lreplace $users_list [lsearch -regexp $users_list $user_id] [lsearch -regexp $users_list $user_id] \
                                        [list $user_id \
                                             $user_name \
                                             $email \
                                             $role_id \
                                             $status_date \
                                             [lindex [lindex $users_list [lsearch -regexp $users_list $user_id]] 5]]]
                }
                finished {
                    set users_list [lreplace $users_list [lsearch -regexp $users_list $user_id] [lsearch -regexp $users_list $user_id] \
                                        [list $user_id \
                                             $user_name \
                                             $email \
                                             $role_id \
                                             [lindex [lindex $users_list [lsearch -regexp $users_list $user_id]] 4] \
                                             $status_date]]
                }
            } 
        } else {
            # just insert the element in the list
            switch $status {
                started {
                    lappend users_list \
                        [list $user_id \
                             $user_name \
                             $email \
                             $role_id \
                             $status_date \
                             {}]
                }
                finished {
                    lappend users_list \
                        [list $user_id \
                             $user_name \
                             $email \
                             $role_id \
                             {} \
                             $status_date]
                }
            } 
        }
    }
    foreach user $users_list {
        template::multirow append related_users [lindex $user 0] [lindex $user 1] [lindex $user 2] [lindex $user 3] [lindex $user 4] [lindex $user 5]
    }
} elseif { [string eq $type "learning_object"] } {
    # the environment has been viwed (finished) if the user have seen the
    # referenced resources
    set frame_header "[_ imsld.lt_Users_who_have_bviewe]"
    template::multirow create related_users user_name email user_id

    db_1row lo_info {
        select item_id as learning_object_item_id,
        environment_id as environment_item_id,
	title as lo_title
        from imsld_learning_objectsi
        where learning_object_id = :learning_object_id
    }
    append frame_header " \"$lo_title\""

    set item_list [db_list item_linear_list {
        select ii.imsld_item_id
        from imsld_items ii,
        cr_items cr,
        acs_rels ar
        where ar.object_id_one = :learning_object_item_id
        and ar.object_id_two = cr.item_id
        and cr.live_revision = ii.imsld_item_id}]
    
    foreach imsld_item_id $item_list {
        lappend related_resources [db_list resources_list {
            select cpr.resource_id
            from imsld_cp_resources cpr, imsld_items ii,
            acs_rels ar, cr_items cr1, cr_items cr2
            where ar.object_id_one = cr1.item_id
            and ar.object_id_two = cr2.item_id
            and cr1.live_revision = ii.imsld_item_id
            and cr2.live_revision = cpr.resource_id 
            and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                 or ii.imsld_item_id = :imsld_item_id)}]
    }

    # now that we have all the referenced resources in the learning object, get the users who have viwed them all
    foreach user_id [db_list get_visitors "
                select user_id
                from imsld_status_user
                where related_id in ([join $related_resources ","])
                and status = 'finished'
                and run_id = :run_id
                group by user_id
                having count(*) = [llength $related_resources]
            "] {
        template::multirow append related_users [person::name -person_id $user_id] [party::email -party_id $user_id] $user_id
    }

} elseif { [string eq $type "service"] } {
    # currently, we support there are three types of services: 1. conference,
    # 2. monitory and 3. send-mail the first two types have resources
    # associated whereas the last one doesn't and has to be treated as a
    # separate case
    set frame_header "[_ imsld.lt_Users_who_have_bat_le]"

    template::multirow create related_users user_name email user_id

    db_1row service_info {
        select service_type,
        environment_id as environment_item_id,
        item_id as service_item_id
        from imsld_servicesi
        where service_id = :service_id
    }
    
    switch $service_type {
        conference {
            append frame_header " [_ imsld.conference]"
            db_1row conference_info {
                select conf.conference_id,
                conf.conference_type,
                conf.imsld_item_id as imsld_item_item_id,
                cr.live_revision as imsld_item_id, 
                conf.title as conf_title
                from imsld_conference_servicesi conf, cr_items cr
                where conf.service_id = :service_item_id
                and cr.item_id = conf.imsld_item_id
                and content_revision__is_live(cr.live_revision) = 't'
            }
            append frame_header " \"$conf_title\""

            set related_resources [db_list conf_resources_list {
                select cpr.resource_id
                from imsld_cp_resourcesi cpr, imsld_itemsi ii,
                acs_rels ar
                where ar.object_id_one = ii.item_id
                and ar.object_id_two = cpr.item_id
                and content_revision__is_live(cpr.resource_id) = 't'
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)
            }]

            foreach user_id [db_list get_visitors "
                select user_id
                from imsld_status_user
                where related_id in ([join $related_resources ","])
                and status = 'finished'
                and run_id = :run_id
                group by user_id
                having count(*) = [llength $related_resources]
            "] {
                template::multirow append related_users [person::name -person_id $user_id] [party::email -party_id $user_id] $user_id
            }            
        } monitor {
            append frame_header "[_ imsld.monitor]"
            db_1row monitor_info {
                select ims.title as monitor_service_title,
                ims.monitor_id,
                ims.item_id as monitor_item_id,
                ims.self_p,
                ims.role_id,
                cr.live_revision as imsld_item_id
                from imsld_monitor_servicesi ims, cr_items cr
                where ims.service_id = :service_item_id
                and cr.item_id = ims.imsld_item_id
                and content_revision__is_live(cr.live_revision) = 't'
            }
            
            set related_resources [db_list conf_resources_list {
                select cpr.resource_id
                from imsld_cp_resourcesi cpr, imsld_itemsi ii,
                acs_rels ar
                where ar.object_id_one = ii.item_id
                and ar.object_id_two = cpr.item_id
                and content_revision__is_live(cpr.resource_id) = 't'
                and (imsld_tree_sortkey between tree_left((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     and tree_right((select imsld_tree_sortkey from imsld_items where imsld_item_id = :imsld_item_id))
                     or ii.imsld_item_id = :imsld_item_id)
            }]

            foreach user_id [db_list get_visitors "
                select user_id
                from imsld_status_user
                where related_id in ([join $related_resources ","])
                and status = 'finished'
                and run_id = :run_id
                group by user_id
                having count(*) = [llength $related_resources]
            "] {
                template::multirow append related_users [person::name -person_id $user_id] [party::email -party_id $user_id] $user_id
            }

        } send-mail {
            # 1. get the users associated to the run
            # 2. get the users IN the run who have sent a bulk-mail message
            append frame_header "[_ imsld.sendmail]"

            append frame_header "<br />[_ imsld.lt_This_is_a_special_cas]"
            
            db_foreach user_in_run {
                select gmm.member_id,
                ir.creation_date as run_creation_date
                from group_member_map gmm,
                imsld_run_users_group_ext iruge, 
                acs_rels ar1,
                imsld_runs ir
                where iruge.run_id=:run_id
                and iruge.run_id = ir.run_id
                and ar1.object_id_two=iruge.group_id 
                and ar1.object_id_one=gmm.group_id 
                order by member_id
            } {
                # NOTE: The bulk mail package has a bug when storing the send_date (it's stored in YYYY-MM-DD format, withot the hour)
                #       that's  why we have to do a little trick with the dates when comparing them, even though it's not 100% accurate
                if { [db_string user_sent_bulk_mail_p {
                    select count(*)
                    from acs_objects ao,
                    bulk_mail_messages bm
                    where ao.object_id = bm.bulk_mail_id
                    and creation_user = :member_id
                    and to_date(send_date,'YYYY-MM-DD') >= to_date(:run_creation_date,'YYYY-MM-DD')
                }] > 0 } {
                    template::multirow append related_users [person::name -person_id $member_id] [party::email -party_id $member_id] $member_id
                }
            }
        }
    }

}

template::list::create \
    -name related_users \
    -multirow related_users \
    -key user_id \
    -no_data "[_ imsld.No_info_was_found]" \
    -elements $elements \
    -filters { activity_id {} run_id {} type {} }


set complete_act_id ""
if { $type eq "learning" || $type eq "support" } {
    db_1row activity_info "
	select complete_act_id
	from imsld_${type}_activitiesi
	where activity_id = :activity_id
    "
}

foreach {time_in_seconds time_string user_choice_p when_prop_val_is_set_xml property_ref expression_value} [list "" "" "" "" "" ""] break

foreach unit {years months days hours minutes seconds} {
    set time($unit) ""
}

set d_enabled "disabled"
set p_enabled "disabled"

if { $complete_act_id ne "" } {
    db_0or1row complete_act {
	select aci.time_in_seconds, aci.time_string, aci.user_choice_p, aci.when_prop_val_is_set_xml
	from imsld_complete_actsi aci
	where aci.item_id = :complete_act_id
	and aci.complete_act_id = content_item__get_live_revision(:complete_act_id)
    } 
    
    if { $when_prop_val_is_set_xml ne "" } {
	dom parse $when_prop_val_is_set_xml document
	$document documentElement when_prop_val_is_set_root
	set wpv_is_node [$when_prop_val_is_set_root childNodes]
	
	set equal_value_p 0
	# get the property value
	set property_ref [$wpv_is_node selectNodes {*[local-name()='property-ref']}]
	if { [llength ${property_ref}] } {
	    set property_ref [${property_ref} getAttribute ref]
	}
	
	# get the value of the referenced exression
	set propertyvalueNode [$wpv_is_node selectNodes {*[local-name()='property-value']}]
	
	if { [llength ${propertyvalueNode}] } {
	    set propertyvalueChildNode [${propertyvalueNode} childNodes]
	    set nodeType [${propertyvalueChildNode} nodeType]
	    set expression_value [${propertyvalueNode} text]
	}	
	set p_enabled "enabled"
    }

    if { $time_string ne "" } {
	array set time [imsld::parse::convert_time_to_list -time $time_string]

	foreach key [array names time] {
	    set $key $time($key)
	}
	
	set d_enabled "enabled"
    }

    if {$option ne "property"} {
	set property ${property_ref}
	set value ${expression_value}
    }
} else {
    set option "none"
}

set properties [db_list_of_lists select_properties {
    select ip.object_title, ip.identifier
    from imsld_propertiesi ip, imsld_componentsi ic, imsld_imsldsi im, imsld_runs ir
    where ir.run_id = :run_id
    and ir.imsld_id = im.imsld_id
    and im.item_id = ic.imsld_id
    and ic.item_id = ip.component_id
    order by ip.identifier
}]


ad_form \
    -name complete \
    -export {run_id activity_id type} \
    -html { onsubmit "return submitForm(this)" } \
    -form {
	{ years:integer,optional
	    { label "Year" }
	    { html {size 2 $d_enabled $d_enabled} }
	}
	{ months:integer,optional
	    { label "Months" }
	    { html {size 2 $d_enabled $d_enabled} }
	}
	{ days:integer,optional
	    { label "Days" }
	    { html {size 2 $d_enabled $d_enabled} }
	}
	{ hours:integer,optional
	    { label "Hours" }
	    { html {size 2 $d_enabled $d_enabled} }
	    { value $time(hours) }
	}
	{ minutes:integer,optional
	    { label "Minutes" }
	    { html {size 2 $d_enabled $d_enabled} }
	}
	{ seconds:integer,optional
	    { label "Seconds" }
	    { html {size 2 $d_enabled $d_enabled} }
	}
	{ property:text(select),optional
	    { label "Property" }
	    { options $properties }
	    { html {$p_enabled $p_enabled} }
	    { value ${property_ref} }
	}
	{ value:text,optional
	    { label "Value" }
	    { html {$p_enabled $p_enabled} }
	    { value $expression_value }
	}
    } \
    -on_request {
	set option ""
	if { $complete_act_id eq "" } {
	    set option "none"
	} elseif { $user_choice_p eq "t" } {
	    set option "choice"
	} elseif { $time_in_seconds > 0 } {
	    set option "timelimit"
	} elseif { $when_prop_val_is_set_xml ne "" } {
	    set option "property"
	}
	
    } \
    -on_submit {
	set parent_id [content::item::get_parent_folder -item_id [content::revision::item_id -revision_id $activity_id]]
	set old_complete_act_id $complete_act_id
	switch $option {
	    "none" {
		set complete_act_id ""
	    }
	    "choice" {
		set complete_act_id [imsld::item_revision_new -attributes [list [list user_choice_p "t"]] \
					 -content_type imsld_complete_act \
					 -item_id $complete_act_id \
					 -parent_id $parent_id]
	    }
	    "timelimit" {
		set time_string [imsld::parse::convert_list_to_time \
				     -time [list years $years months $months days $days \
						hours $hours minutes $minutes seconds $seconds]]
		set time_in_seconds [imsld::parse::convert_time_to_seconds -time $time_string]
		set complete_act_id [imsld::item_revision_new -attributes [list [list time_in_seconds $time_in_seconds] \
									       [list time_string $time_string]] \
					 -content_type imsld_complete_act \
					 -item_id $complete_act_id \
					 -parent_id $parent_id]

		imsld::instance::schedule_complete_time_limit \
		    -run_id $run_id \
		    -activity_id [content::revision::item_id -revision_id $activity_id] \
		    -time_string $time_string

	    }
	    "property" {
		dom createDocument when-property-value-is-set doc
		set node [$doc documentElement]
		set wpvis [$doc createElement "imsld:when-property-value-is-set"]
		$wpvis setAttribute "xmlns:imsld" "http://www.imsglobal.org/xsd/imsld_v1p0"
		
		set pr [$doc createElement "imsld:property-ref"]
		$pr setAttribute ref $property
		$wpvis appendChild $pr
		set pv [$doc createElement "imsld:property-value"]
		set text [$doc createTextNode $value]
		$pv appendChild $text
		$wpvis appendChild $pv
		
		$node appendChild $wpvis
		set xml [$node asXML]

		set complete_act_id [imsld::item_revision_new -attributes [list [list when_prop_val_is_set_xml $xml]] \
					 -content_type imsld_complete_act \
					 -item_id $complete_act_id \
					 -parent_id $parent_id]
		
	    }
	}

	if {$old_complete_act_id ne $complete_act_id} {
	    if {$type eq "learning"} {
		db_1row select_learning_activity {
		    select identifier, component_id, activity_description_id, parameters, is_visible_p,
		    on_completion_id, learning_objective_id, prerequisite_id, title, context_id, item_id
		    from imsld_learning_activitiesi
		    where activity_id = :activity_id
		}		
		
		set learning_activity_id \
		    [imsld::item_revision_new -attributes [list [list identifier $identifier] \
							       [list component_id $component_id] \
							       [list activity_description_id $activity_description_id] \
							       [list parameters $parameters] \
							       [list is_visible_p $is_visible_p] \
							       [list complete_act_id $complete_act_id] \
							       [list on_completion_id $on_completion_id] \
							       [list learning_objective_id $learning_objective_id] \
							       [list prerequisite_id $prerequisite_id]] \
			 -content_type "imsld_learning_activity" \
			 -item_id $item_id \
			 -title $title \
			 -parent_id $parent_id]
	    } else {
		db_1row select_learning_activity {
		    select identifier, component_id, activity_description_id, parameters, is_visible_p,
		    on_completion_id, item_id, title
		    from imsld_support_activitiesi
		    where activity_id = :activity_id
		}
		
		set support_activity_id \
		    [imsld::item_revision_new -attributes [list [list identifier $identifier] \
							       [list component_id $component_id] \
							       [list activity_description_id $activity_description_id] \
							       [list parameters $parameters] \
							       [list is_visible_p $is_visible_p] \
							       [list complete_act_id $complete_act_id] \
							       [list on_completion_id $on_completion_id]] \
			 -content_type "imsld_support_activity" \
			 -item_id $item_id \
			 -title $title \
			 -parent_id $parent_id]
	    }
	}
	
    }
