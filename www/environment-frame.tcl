ad_page_contract {

    This is the frame that contains the associated URLs of an environment

    @author Eduardo Pérez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    activity_id:integer,notnull
    run_id:integer,notnull
}

set user_id [ad_conn user_id]

dom createDocument ul doc
set dom_root [$doc documentElement]

#set environments_node_ul [$doc createElement ul]
set environments_node_li [$doc createElement li]
set text [$doc createTextNode "[_ imsld.Context_info]"]
$environments_node_li appendChild $text
set environments_node [$doc createElement ul]
$environments_node setAttribute class "mktree"

# FIX-ME: if the ul is empty, the browser shows the ul incorrectly   
set text [$doc createTextNode ""]
$environments_node appendChild $text

set activity_item_id [content::revision::item_id -revision_id $activity_id]

imsld::process_activity_environments_as_ul -activity_item_id $activity_item_id \
    -run_id $run_id \
    -dom_node $environments_node \
    -dom_doc $doc
$dom_root appendChild $environments_node_li

set environments_node_li [$doc createElement li]
$environments_node_li setAttribute class "liOpen"

$environments_node_li appendChild $environments_node
$dom_root appendChild $environments_node_li

set environments [$dom_root asXML]   

set page_title {}
set context [list]
