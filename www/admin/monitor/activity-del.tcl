# 

ad_page_contract {
    
    Delete an activity from a UoL
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2009-02-13
    @arch-tag: /bin/bash: uuidgen: command not found
    @cvs-id $Id$
} {
    activity_id:integer,notnull
    run_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set item_id [content::revision::item_id -revision_id $activity_id]
content::item::unset_live_revision -item_id $item_id

ad_returnredirect [export_vars -base monitor-tree {run_id}]
