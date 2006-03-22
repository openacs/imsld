ad_page_contract {

    This is the frame that contains the associated URLs of an activity

    @author Eduardo Pérez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    activity_id:integer,notnull
}

set user_id [ad_conn user_id]

set activity_item_id [content::revision::item_id -revision_id $activity_id]
set activities_list [imsld::process_learning_activity -activity_item_id $activity_item_id]

set page_title {}
set context [list]
