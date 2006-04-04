ad_page_contract {

    This is the frame that contains the associated URLs of an environment

    @author Eduardo P�rez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    activity_id:integer,notnull
}

set user_id [ad_conn user_id]

dom createDocument ul doc
set dom_root [$doc documentElement]

set environments_node_ul [$doc createElement ul]
$environments_node_ul setAttribute class "mktree"
set environments_node_li [$doc createElement li]
set text [$doc createTextNode "Environments"]
$environments_node_li appendChild $text
set environments_node [$doc createElement ul]
# FIX-ME: if the ul is empty, the browser shows the ul incorrectly   
set text [$doc createTextNode ""]
$environments_node appendChild $text

set activity_item_id [content::revision::item_id -revision_id $activity_id]

imsld::process_activity_environments_as_ul -activity_item_id $activity_item_id \
                                    -dom_node $environments_node \
                                    -dom_doc $doc

$environments_node_ul appendChild $environments_node_li
$environments_node_ul appendChild $environments_node
set environments [$environments_node_ul asXML]   

set page_title {}
set context [list]
