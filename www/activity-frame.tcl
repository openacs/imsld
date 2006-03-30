ad_page_contract {

    This is the frame that contains the associated URLs of an activity

    @author Eduardo Pérez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    activity_id:integer,notnull
}

set user_id [ad_conn user_id]

dom createDocument ul doc
set dom_root [$doc documentElement]

set activity_item_id [content::revision::item_id -revision_id $activity_id]
imsld::process_activity_as_ul -activity_item_id $activity_item_id -dom_doc $doc -dom_node $dom_root

set activities_list [$dom_root asXML] 

set page_title {}
set context [list]
