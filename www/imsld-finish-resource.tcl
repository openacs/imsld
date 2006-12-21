ad_page_contract {
    @author lfuente@it.uc3m.es
    @creation-date Jan 2006
} {
    file_url
    resource_item_id
    run_id
    owner_user_id:optional
}

# fedback, assessment nor imsldcontent have to be marked as finished
if { [db_0or1row not_fedbk_nor_assmnt { 
    select icr.resource_id
    from acs_rels ar,
    imsld_cp_resourcesi icr
    where ar.rel_type != 'imsld_feedback_rel'
    and icr.item_id = ar.object_id_two
    and ar.object_id_two = :resource_item_id
    and icr.type != 'imsqti_xmlv1p0'
    and icr.type != 'imsldcontent'
    limit 1
}] } {
    imsld::grant_permissions -resources_activities_list $resource_id -user_id [ad_conn user_id]
    imsld::finish_resource -resource_id $resource_id -run_id $run_id
} else {
    # mark the resource as finished just for monitoring purposes
    db_1row context_info {
        select imsld_id 
        from imsld_runs
        where run_id = :run_id
    }
    set user_id [ad_conn user_id]
    set resource_id [content::item::get_live_revision -item_id $resource_item_id]
    db_dml insert_completed_resource {
        insert into imsld_status_user (
                                       imsld_id,
                                       run_id,
                                       related_id,
                                       user_id,
                                       type,
                                       status_date,
                                       status
                                       )
        (
         select :imsld_id,
         :run_id,
         :resource_id,
         :user_id,
         'resource',
         now(),
         'finished'
         where not exists (select 1 from imsld_status_user where run_id = :run_id and user_id = :user_id and related_id = :resource_id and status = 'finished')
         )
    }
}

if { ![regexp {http://} $file_url] } {
    ad_returnredirect "[export_vars -base "$file_url" -url { file_url run_id resource_id resource_item_id owner_user_id }]"
} 
ad_returnredirect "[export_vars -base "$file_url"]"
