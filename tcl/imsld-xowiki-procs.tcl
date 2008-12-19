# /packages/imsld/tcl/imsld-xowiki-procs.tcl

ad_library {
    
    Procedures to interact with XoWiki.
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-07-21
    @arch-tag: 876d6655-8af7-4df1-a6a8-9051cf4dda27
    @cvs-id $Id$
}

namespace eval ::imsld {}
namespace eval ::imsld::xowiki {}


ad_proc -public imsld::xowiki::file_new {
    {-href ""}
    -path_to_file
    {-file_name ""}
    -type:required
    {-parent_id ""}
    {-item_id ""}
    {-title ""}
    {-package_id ""}
    {-user_id ""}
    {-creation_ip ""}
    {-creation_date ""}
    -edit:boolean
    -complete_path
} {    
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-07-21
    
    @return 
    
    @error 
} {

    set mime_type [cr_filename_to_mime_type $complete_path]

    set community_id [dotlrn_community::get_community_id]
    set xw_url "[dotlrn_community::get_community_url $community_id]xowiki/"

    array set node [site_node::get_from_url -url $xw_url]
    set package_id $node(package_id)
    
    ::xowiki::Package initialize -package_id $package_id -url $xw_url -user_id [ad_conn user_id]

    if { [string match "text/*" $mime_type] } {
	set file [open $complete_path]
	set content [read $file]
	close $file
	
	regexp {<body[^<]*>(.*?)</body>} $content match content
	
	set page [$package_id resolve_page $file_name method]
	
	if {$page eq ""} {
	    set page [::xowiki::Page new \
			  -title $title \
			  -name $file_name \
			  -package_id $package_id \
			  -parent_id [$package_id folder_id] \
			  -destroy_on_cleanup \
			  -text $content]
	    $page set_content [string trim [$page text] " \n"]
	    $page initialize_loaded_object
	    $page save_new
	} else {
	    $page set text $content
	    $page set_content [string trim [$page text] " \n"]
	    $page save
	}	
    } else {
	set page [$package_id resolve_page "file:$file_name" method]
	
	if {$page eq ""} {
	    set page [::xowiki::File new \
			  -title $title \
			  -name "file:${file_name}" \
			  -package_id $package_id \
			  -parent_id [$package_id folder_id] \
			  -destroy_on_cleanup \
			  -mime_type $mime_type
		      ]
	    $page initialize_loaded_object
	    $page set import_file $complete_path
	    $page save_new
	} else {
	    $page set import_file $complete_path
	    $page save
	}
    }

    return [$page item_id]
    
}


ad_proc -public imsld::xowiki::page_content {
    -item_id
} {
        
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-07-31
    
    @param item_id

    @return 
    
    @error 
} {
    set page [::xowiki::Package instantiate_page_from_id -item_id $item_id]
    set result [$page render]

    return $result
}


ad_proc -public imsld::xowiki::page_url {
    -item_id
} {
        
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-07-31
    
    @param item_id

    @return 
    
    @error 
} {
    set page [::xowiki::Package instantiate_page_from_id -item_id $item_id]

    $page volatile
    return [::[$page package_id] url] 
}


ad_proc -public imsld::xowiki::page_list {
} {        
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-12-19
    
    @return 
    
    @error 
} {
    set community_id [dotlrn_community::get_community_id]
    set xw_url "[dotlrn_community::get_community_url $community_id]xowiki/"
    
    array set node [site_node::get_from_url -url $xw_url]
    set xowiki_package_id $node(package_id)
    ::xowiki::Package initialize -package_id $xowiki_package_id -url $xw_url -user_id [ad_conn user_id]
    
    set page_list [list]
    db_foreach select_pages \
	[::xowiki::Page instance_select_query \
	     -folder_id [::$xowiki_package_id folder_id] \
	     -with_subtypes true \
	     -select_attributes {name page_id} \
	     -from_clause ", xowiki_page P" \
	     -where_clause "P.page_id = bt.revision_id" \
	     -orderby "ci.name"] \
	{
	    if {[regexp {^::[0-9]} $name]} continue
	    lappend page_list [list $name $item_id]
	}

    return $page_list
}
