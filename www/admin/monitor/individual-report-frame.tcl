# packages/imsld/www/admin/monitor/individual-report-frame.tcl

ad_page_contract {

    Page used to display the individual report of a given user in the run

    @author jopez@inv.it.uc3m.es
    @creation-date Dic 2006
} -query {
    run_id:integer,notnull
    {member_id:integer ""}
}

set page_title "[_ imsld.Individual_Report]"
set context [list]
set frame_header "[_ imsld.This]: "

# Fetch the users that are active in the run
set users_in_run [imsld::runtime::users_in_run -run_id $run_id]

if { [llength $users_in_run] == 1 } {
    set member_id [lindex $users_in_run 0]
}

template::multirow create item_select item_id item_name

set select_name "member_id"
set select_id "users_in_run"
set post_text ""
set selected_item ""
set select_string ""
    
# If no member_id has been given, add the option pull-down menu
if { [string eq "" $member_id] } {
    set select_string "[_ imsld.Select]"
} else {
    # Set variable portrait_revision if user has portrait
    if { [db_0or1row get_member_portrait {
	select c.live_revision
	from acs_rels a, cr_items c
	where a.object_id_two = c.item_id
	and a.object_id_one = :member_id
	and a.rel_type = 'user_portrait_rel'}]} {
	
	set post_text "<img style=\"height: 100px; vertical-align: middle\" src=\"/shared/portrait-bits.tcl?user_id=$member_id\" alt=\"Portrait\"/>"
    }
}

foreach user_id_in_run $users_in_run {
    template::multirow append item_select $user_id_in_run \
	"[person::name -person_id $user_id_in_run]"
    
    if { $member_id == $user_id_in_run} {
	set selected_item $member_id
    }
}

set elements [list user_name \
                  [list label "[_ imsld.Activity_Name]" \
                       display_template \
		       {<a href="activity-frame?run_id=$run_id&type=@related_activities.type@&activity_id=@related_activities.related_id@" onclick="return loadContent('activity-frame?run_id=$run_id&type=@related_activities.type@&activity_id=@related_activities.related_id@')" title="[_ imsld.Activity_report]">@related_activities.activity_name@</a>}] \
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
                set activities_list \
		    [lreplace $activities_list \
			 [lsearch -regexp $activities_list $related_id] \
			 [lsearch -regexp $activities_list $related_id] \
			 [list $related_id \
			      [content::item::get_title \
				   -item_id \
				   [content::revision::item_id \
					-revision_id $related_id]] \
			      $type \
			      $status_date \
			      [lindex [lindex $activities_list \
					   [lsearch -regexp $activities_list \
						$related_id]] 4]]]
            }
            finished {
                set activities_list \
		    [lreplace $activities_list \
			 [lsearch -regexp $activities_list $related_id] \
			 [lsearch -regexp $activities_list $related_id] \
			 [list $related_id \
			      [content::item::get_title \
				   -item_id \
				   [content::revision::item_id \
					-revision_id $related_id]] \
			      $type \
			      [lindex [lindex $activities_list \
					   [lsearch -regexp $activities_list \
						$related_id]] 3] \
			      $status_date]]
            }
        } 
    } else {
        # just insert the element in the list
        switch $status {
            started {
                lappend activities_list \
                    [list $related_id \
                         [content::item::get_title \
			      -item_id [content::revision::item_id \
					    -revision_id $related_id]] \
                         $type \
                         $status_date \
                         {}]
            }
            finished {
                lappend activities_list \
                    [list $related_id \
                         [content::item::get_title \
			      -item_id [content::revision::item_id \
					    -revision_id $related_id]] \
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
