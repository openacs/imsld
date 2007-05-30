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
} -validate {
    non_empty_id {
        if { [string eq "" $activity_id] && [string eq "" $learning_object_id] && [string eq "" $service_id] } {
            ad_complain "[_ imsld.lt_You_must_provide_an_a]"
        }
    }
}

set page_title "[_ imsld.lt_Monitoring_One_Activi]"
set context [list]

set elements [list user_name \
                  [list label "[_ imsld.Name]" \
                       display_template {<a href="individual-report-frame?run_id=${run_id}&member_id=@related_users.user_id@">@related_users.user_name@</a>}] \
                  email \
                  [list label "[_ imsld.Email]"]]

if { [string eq $type "learning"] || [string eq $type "support"] || [string eq $type "structure"] } {
    # status directly recorded in the status table, get the info
    set list_header "[_ imsld.lt_Users_who_have_starte]"
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
    # the environment has been viwed (finished) if the user have seen the referenced resources
    set list_header "[_ imsld.lt_Users_who_have_bviewe]"
    template::multirow create related_users user_name email user_id

    db_1row lo_info {
        select item_id as learning_object_item_id,
        environment_id as environment_item_id
        from imsld_learning_objectsi
        where learning_object_id = :learning_object_id
    }

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
    # currently, we support there are three types of services: 1. conference, 2. monitory and 3. send-mail
    # the first two types have resources associated whereas the last one doesn't and has to be treated as a separate case

    set list_header "[_ imsld.lt_Users_who_have_bat_le]"

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
            append list_header "[_ imsld.conference]"
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
            append list_header "[_ imsld.monitor]"
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
            append list_header "[_ imsld.sendmail]"

            append list_header "<br />[_ imsld.lt_This_is_a_special_cas]"
            
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


