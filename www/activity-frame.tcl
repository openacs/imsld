ad_page_contract {

    This is the frame that contains the associated URLs of an activity

    @author Eduardo Pérez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    run_id:integer,notnull
    activity_id:integer,notnull
}

set user_id [ad_conn user_id]

set supported_roles [db_list supported_roles_list { select iri.role_id 
                                             from imsld_rolesi iri, 
                                             acs_rels ar,  
                                             imsld_support_activitiesi isai 
                                             where iri.item_id=ar.object_id_two 
                                             and ar.rel_type='imsld_sa_role_rel' 
                                             and ar.object_id_one=isai.item_id 
                                             and isai.activity_id =:activity_id }]

if {[llength $supported_roles]} {
    set flag 1 
}
        
                                             
dom createDocument div doc
set dom_root [$doc documentElement]
$dom_root setAttribute class "tabber"

set activity_item_id [content::revision::item_id -revision_id $activity_id]
imsld::process_activity_as_ul -activity_item_id $activity_item_id -run_id $run_id -dom_doc $doc -dom_node $dom_root

set activities [$dom_root asXML] 

set page_title {}
set context [list]
