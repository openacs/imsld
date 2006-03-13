ad_page_contract {
    @author jopez@inv.it.uc3m.es
    @creation-date Mar 2006
} {
}

# initialize variables
set page_title "[_ imsld.Unist_of_Learning]"
set context ""
set community_id [dotlrn_community::get_community_id]
set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]
set user_id [ad_conn user_id]

# Add the dhtml tree javascript to the HEAD.
global dotlrn_master__header_stuff
append dotlrn_master__header_stuff {
    <script src="/resources/acs-templating/mktree.js" language="javascript"></SCRIPT>
    <link rel="stylesheet" href="/resources/acs-templating/mktree.css" media="all">
}

db_1row imslds_in_class {
    select imsld.item_id as imsld_item_id,
    imsld.imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title
    from imsld_cp_manifestsx icm, imsld_cp_organizationsi ico, imsld_imsldsi imsld, cr_items cr
    where content_revision__is_live(imsld.imsld_id) = 't'
    and icm.parent_id = cr.item_id
    and cr.parent_id = :cr_root_folder_id
    and ico.manifest_id = icm.item_id
    and imsld.organization_id = ico.item_id
} 

set next_activity_id [imsld::get_next_activity -imsld_item_id $imsld_item_id -user_id $user_id -community_id $community_id]

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
    -next_activity_id $next_activity_id \
    -dom_node $activities_node \
    -dom_doc $doc

$imsld_title_node appendChild $activities_node

set html_tree [$dom_root asXML]
