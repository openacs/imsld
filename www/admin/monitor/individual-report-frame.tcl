# packages/imsld/www/admin/monitor/individual-report-frame.tcl

ad_page_contract {

    Page used to display the individual report of a given user in the run

    @author jopez@inv.it.uc3m.es
    @creation-date Dic 2006
} -query {
    run_id:integer,notnull
    member_id:integer,notnull
}

set page_title "[_ imsld.Individual_Report]"
set context [list]
set member_name [party::name -party_id $member_id]

set elements [list user_name \
                  [list label "[_ imsld.Activity_Name]" \
                       display_template {<a href="activity-frame?run_id=$run_id&type=@related_activities.type@&activity_id=@related_activities.related_id@">@related_activities.activity_name@</a>}] \
                  type \
                  [list label "[_ imsld.Activity_Type]"] \
                  started_time \
                  [list label "[_ imsld.Started_Date]"] \
                  finished_time \
                  [list label "[_ imsld.Finished_Date]"]]

template::multirow create related_activities related_id activity_name type started_time finished_time
set activities_list [list]
        
db_foreach related_resources {
    select stat.related_id,
    stat.role_id,
    stat.status,
    stat.type,
    to_char(stat.status_date,'MM/DD/YYYY HH24:MI:SS') as status_date
    from imsld_status_user stat
    where stat.user_id = :member_id
    and stat.run_id = :run_id
    and type in ('learning','support','structure')
    order by related_id, status desc
} {
    if { [lsearch -regexp $activities_list $related_id] != -1 } {
        # the elemen exists, replace the list element
        switch $status {
            started {
                set activities_list [lreplace $activities_list [lsearch -regexp $activities_list $related_id] [lsearch -regexp $activities_list $related_id] \
                                         [list $related_id \
                                              [content::item::get_title -item_id [content::revision::item_id -revision_id $related_id]] \
                                              $type \
                                              $status_date \
                                              [lindex [lindex $activities_list [lsearch -regexp $activities_list $related_id]] 4]]]
            }
            finished {
                set activities_list [lreplace $activities_list [lsearch -regexp $activities_list $related_id] [lsearch -regexp $activities_list $related_id] \
                                         [list $related_id \
                                              [content::item::get_title -item_id [content::revision::item_id -revision_id $related_id]] \
                                              $type \
                                              [lindex [lindex $activities_list [lsearch -regexp $activities_list $related_id]] 3] \
                                              $status_date]]
            }
        } 
    } else {
        # just insert the element in the list
        switch $status {
            started {
                lappend activities_list \
                    [list $related_id \
                         [content::item::get_title -item_id [content::revision::item_id -revision_id $related_id]] \
                         $type \
                         $status_date \
                         {}]
            }
            finished {
                lappend activities_list \
                    [list $related_id \
                         [content::item::get_title -item_id [content::revision::item_id -revision_id $related_id]] \
                         $type \
                         {} \
                         $status_date]
            }
        } 
    }
}

set activities_list [lsort -index 1 $activities_list]
foreach activity $activities_list {
    template::multirow append related_activities [lindex $activity 0] [lindex $activity 1] [lindex $activity 2] [lindex $activity 3] [lindex $activity 4]
}

template::list::create \
    -name activities \
    -multirow related_activities \
    -key related_id \
    -no_data "[_ imsld.No_info_was_found]" \
    -elements $elements