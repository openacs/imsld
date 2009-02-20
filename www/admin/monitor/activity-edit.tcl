# 

ad_page_contract {
    
    Edit the activity title
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2009-02-13
    @arch-tag: /bin/bash: uuidgen: command not found
    @cvs-id $Id$
} {
    activity_id:integer,notnull
    run_id:integer,notnull
    title:notnull
} -properties {
} -validate {
} -errors {
}

#set item_id [content::revision::item_id -revision_id $activity_id]
# content::revision::new -item_id $item_id -title $title

db_dml update_title {
    update cr_revisions
    set title = :title
    where revision_id = :activity_id
}

ad_returnredirect [export_vars -base monitor-tree {run_id}]
