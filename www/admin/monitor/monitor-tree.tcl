ad_page_contract {
    @author jopez@inv.it.uc3m.es
    @creation-date Nov 2006
} {
    run_id:integer,notnull
}

# initialize variables
set page_title "[_ imsld.units-of-learning]"
set context ""
set community_id [dotlrn_community::get_community_id]
set cr_root_folder_id [imsld::cr::get_root_folder -community_id $community_id]
set user_id [ad_conn user_id]
set imsld_package_id [site_node_apm_integration::get_child_package_id \
                          -package_id [dotlrn_community::get_package_id $community_id] \
                          -package_key "[imsld::package_key]"]

set imsld_admin_url [export_vars -base "[lindex [site_node::get_url_from_object_id -object_id $imsld_package_id] 0]admin/"]

db_1row imslds_info {
    select imsld.item_id as imsld_item_id,
    imsld.imsld_id,
    coalesce(imsld.title, imsld.identifier) as imsld_title
    from imsld_imsldsi imsld, imsld_runs run
    where imsld.imsld_id = run.imsld_id
    and run.run_id = :run_id
} 

if { [db_string count_properties {
    select count(*)
    from imsld_property_instances
    where run_id = :run_id
    or run_id is null
    and content_revision__is_live(instance_id) = 't'
}] } {
    # there is at least one property
    dom createDocument ul props_doc
    set props_dom_root [$props_doc documentElement]
    $props_dom_root setAttribute class "mktree"
    set props_title_node [$props_doc createElement li]
    $props_title_node setAttribute class "liOpen"
    set text [$props_doc createTextNode "[_ imsld.Monitor_properties]"] 
    $props_title_node appendChild $text
    $props_dom_root appendChild $props_title_node
    
    set properties_node [$props_doc createElement ul]
    imsld::monitor::properties_tree -run_id $run_id \
        -dom_node $properties_node \
        -dom_doc $props_doc
    
    $props_title_node appendChild $properties_node
    
    set properties_tree [$props_dom_root asXML]
} else {
    set properties_tree ""
}

dom createDocument ul doc
set dom_root [$doc documentElement]
$dom_root setAttribute class "mktree"
set imsld_title_node [$doc createElement li]
$imsld_title_node setAttribute class "liOpen"
set text [$doc createTextNode "$imsld_title"] 
$imsld_title_node appendChild $text
$dom_root appendChild $imsld_title_node

set activities_node [$doc createElement ul]

imsld::monitor::activities_tree -run_id $run_id \
    -dom_node $activities_node \
    -dom_doc $doc

$imsld_title_node appendChild $activities_node
    
set html_tree [$dom_root asXML]

# runtime generated activities (notifications, level C)
if { [db_string generated_acitivties_p {
    select count(*)
    from imsld_runtime_activities_rels
    where run_id = :run_id
} -default 0] > 0 } {
    dom createDocument ul aux_doc
    set aux_dom_root [$aux_doc documentElement]
    $aux_dom_root setAttribute class "mktree"
    set aux_title_node [$aux_doc createElement li]
    $aux_title_node setAttribute class "liOpen"
    set text [$doc createTextNode "[_ imsld.Extra_Activities]"] 
    $aux_title_node appendChild $text
    $aux_dom_root appendChild $aux_title_node
    
    set aux_activities_node [$aux_doc createElement ul]
    imsld::monitor::runtime_assigned_activities_tree -run_id $run_id \
        -dom_node $aux_activities_node \
        -dom_doc $aux_doc
    
    $aux_title_node appendChild $aux_activities_node
    
    set aux_html_tree [$aux_dom_root asXML]
} else {
    set aux_html_tree ""
}

