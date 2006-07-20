# packages/imsld/www/activity-frame.tcl

ad_page_contract {

    This is the frame that contains the associated URLs of an activity

    @author Eduardo Pérez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    run_id:integer,notnull
    activity_id:integer,notnull
}

set user_id [ad_conn user_id]
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
    if { [string eq "imsld_learning_activities" $table_name] } {
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
        set resources_list [concat $resources_list [concat $prerequisites_list $objectives_list]]
    }
    imsld::grant_permissions -resources_activities_list $resources_list -user_id $user_id      
}

set activities [$dom_root asXML] 

set page_title {}
set context [list]
