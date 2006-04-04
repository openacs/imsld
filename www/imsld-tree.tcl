ad_page_contract {
    @author jopez@inv.it.uc3m.es
    @creation-date Mar 2006
} {
    imsld_id:integer,notnull
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
    from imsld_imsldsi imsld
    where imsld.imsld_id = :imsld_id
} 

set next_activity_id [imsld::get_next_activity_list -imsld_item_id $imsld_item_id -user_id $user_id]

dom createDocument ul doc
set dom_root [$doc documentElement]
$dom_root setAttribute class "mktree"

set imsld_title_node [$doc createElement li]
$imsld_title_node setAttribute class "liOpen"
set text [$doc createTextNode "$imsld_title"] 
$imsld_title_node appendChild $text
$dom_root appendChild $imsld_title_node

set activities_node [$doc createElement ul]

imsld::generate_activities_tree -imsld_id $imsld_id \
    -user_id $user_id \
    -next_activity_id_list $next_activity_id \
    -dom_node $activities_node \
    -dom_doc $doc

$imsld_title_node appendChild $activities_node

set html_tree [$dom_root asXML]
