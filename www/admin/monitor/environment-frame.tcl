ad_page_contract {

    This is the frame that contains the associated URLs of an environment

    @author Eduardo Pérez Ureta <eduardo.perez@uc3m.es>
    @creation-date 2006-03-03
} -query {
    activity_id:integer,notnull
    run_id:integer,notnull
}

set frame_header "[_ imsld.Context_info]"
set page_title $frame_header
set context [list]

dom createDocument ul doc
set dom_root [$doc documentElement]

# Create the ul element which will hold all the environment info
$dom_root setAttribute class "mktree"
$dom_root setAttribute style "white-space: nowrap;"

# Create the li nodes for each environment
# set activity_item_id [content::revision::item_id -revision_id
# $activity_id]
set activity_item_id $activity_id
imsld::monitor::activity_environments_tree -activity_item_id $activity_item_id \
    -run_id $run_id \
    -dom_node $dom_root \
    -dom_doc $doc

# Set the result only if it is not empty
if { [$dom_root hasChildNodes]} {
    # Set the result
    set environments [$dom_root asXML]   
}


