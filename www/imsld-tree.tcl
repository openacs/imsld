ad_page_contract {
    @author jopez@inv.it.uc3m.es
    @creation-date Mar 2006
} {
    run_id:integer,notnull
}

# initialize variables
set page_title "[_ imsld.units-of-learning]"
set context ""
set community_id [dotlrn_community::get_community_id]
set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]
set user_id [ad_conn user_id]

db_1row imslds_in_class {
    select imsld.item_id as imsld_item_id,
    imsld.imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title
    from imsld_imsldsi imsld, imsld_runs run
    where imsld.imsld_id = run.imsld_id
    and run.run_id = :run_id
} 

set user_message ""
set next_activity_id [imsld::get_next_activity_list -run_id $run_id -user_id $user_id]

set remaining_activities [llength [join $next_activity_id]] 

if {!$remaining_activities} {
        set all_finished [imsld::run_finished_p -run_id $run_id]
    if {$all_finished} {
        db_dml stop_run { 
            update imsld_runs 
            set status='stopped' 
            where run_id=:run_id
        }
    } else {
         set user_message "Please wait for other users ..."
    }
}
    set run_status [db_string get_run_status {
        select status
       from imsld_runs
        where run_id=:run_id
    }]

    if {[string eq "stopped" $run_status]} {
            set user_message "The course has been finished"
    }

dom createDocument ul doc
set dom_root [$doc documentElement]
$dom_root setAttribute class "mktree"
$dom_root setAttribute style "white-space: nowrap;"
set imsld_title_node [$doc createElement li]
$imsld_title_node setAttribute class "liOpen"
set text [$doc createTextNode "$imsld_title"] 
$imsld_title_node appendChild $text
$dom_root appendChild $imsld_title_node

set activities_node [$doc createElement ul]

imsld::generate_activities_tree -run_id $run_id \
    -user_id $user_id \
    -next_activity_id_list $next_activity_id \
    -dom_node $activities_node \
    -dom_doc $doc

$imsld_title_node appendChild $activities_node

set html_tree [$dom_root asXML]
