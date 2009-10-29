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
    -manifest_identifier
} {    
    
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-07-21
    
    @return 
    
    @error 
} {
    upvar files_struct_list files_struct_list

    # search the file and while doing so, create all the parent folders for that file (if they were not already creatd)
    set found_p 0
    
    # structx = directory loop, count_y and count_x are going to be used to update the files_structure_list
    set structx $files_struct_list
    set count_y 0
    while { [llength $structx] > 0 && $found_p == 0 } {
        # for each directory
        set dirx [lindex $structx 0]
        set count_x 0
        # search in the dir contents
        foreach contentsx [lindex $dirx 1] {
            if { [lsearch -exact [string tolower $contentsx] [string tolower $complete_path]] >= 0 && [string eq [lindex $contentsx 1] $type] } {
                # file found, see if the parent dir is created
                set found_p 1
                # have we already created this file?
                set found_id [lindex $contentsx 2]
                set parent_id [lindex [lindex $dirx 0] 1]
                break
            }
            incr count_x
        }
        if { !$found_p } {
            # proceed only if the file hasn't been found, since we will use the counter later
            incr count_y
            set structx [lrange $structx 1 [expr [llength $structx] -1]]
        }
    }

    set mime_type [cr_filename_to_mime_type $complete_path]

    set community_id [dotlrn_community::get_community_id]
    set xw_url "[dotlrn_community::get_community_url $community_id]xowiki/"

    array set node [site_node::get_from_url -url $xw_url]
    set package_id $node(package_id)
    
    ::xowiki::Package initialize -package_id $package_id -url $xw_url -user_id [ad_conn user_id]

    if { $mime_type eq "text/html" || $mime_type eq "text/xml" } {
	set file [open $complete_path]
	set content [read $file]
	close $file
	
	set content [imsld::xowiki::convert_syntax -content $content -manifest_identifier $manifest_identifier]
	regexp {<body[^<]*>(.*?)</body>} $content match content
	
	set page [$package_id resolve_page $file_name method]
	
	if {$page eq ""} {
	    set page [::xowiki::Page new \
			  -title $title \
			  -name $file_name \
			  -package_id $package_id \
			  -parent_id [$package_id folder_id] \
			  -destroy_on_cleanup \
			  -text [list $content $mime_type]]
	    $page initialize_loaded_object
	    $page save_new
	} else {
	    $page set text [list $content $mime_type]
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
    # update file structure
    if { $found_p } {
	set file_list [list $complete_path file [$page item_id]]
	set content_list [lreplace [lindex [lindex $files_struct_list $count_y] 1] $count_x $count_x $file_list]
	set dir_list [list [lindex [lindex $files_struct_list $count_y] 0] $content_list]
	set files_struct_list [lreplace $files_struct_list $count_y $count_y $dir_list]
    }

    return [$page item_id]
    
}


ad_proc -public imsld::xowiki::convert_syntax {
    -content:required
    -manifest_identifier:required
} {
    Gets a text and returns its convertion to XoWiki Syntax

    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2009-06-15
    
    @param content
    
    @return 
    
    @error 
} {
    
    # Here we assume that resources (URLs referenced by the SRC
    # attribute) will be a file in XoWiki, while links (URLs
    # referenced by the ALT attribute.

    if { [catch {dom parse $content document} errmsg] } {
	ns_log notice "imsld::xowiki::convert_syntax ERROR: Not a valid XML file, aborting parse process!"
	# the docuemnt is not an xml file, just return it
	return $content
    } 
    set root [$document documentElement]

    if { $root eq "" } {
	# Content is too generic, we cannot proceed
	return $content
    }

    # Since XoWiki will crop the IMS LD namespace, we need to include
    # it within each LD tag.
    set ld_tags [$root selectNodes -namespaces {imsld "http://www.imsglobal.org/xsd/imsld_v1p0"} //imsld:*]
    foreach ld_tag $ld_tags {
	$ld_tag setAttribute xmlns:[$ld_tag prefix] [$ld_tag namespaceURI]
    }

    # Changing links
    foreach link [$root selectNodes //a] {
	if { ![catch {set href [$link getAttribute href]}] } {
	    if { ![regexp {://} $href] } {
		regsub {^\./} $href "" href
		set href "$manifest_identifier/$href"
	    }
	    
	    set label [[$link firstChild] nodeValue]
	    
	    set wiki_text "\[\[$href|$label]]"

	    set parent [$link parentNode]
	    if { $parent eq "" } {
		set parent $root
	    }
	    $parent replaceChild [$document createTextNode $wiki_text] $link
	}
    }

    # Changing styles
    foreach style [$root selectNodes //a\[@type="text/css"\]] {
	if { ![catch {set href [$style getAttribute href]}] } {
	    if { ![regexp {://} $href] } {
		regsub {^\.?/} $href "" href
		set href "$manifest_identifier/$href"
		$style setAttribute href "download/file/$href"
	    }

	    set label [[$link firstChild] nodeValue]
	}
	
    }

    # Changing images
    foreach image [$root selectNodes //img] {
	if { ![catch {set src [$image getAttribute src]}] } {
	    if { ![regexp {://} $src] } {
		regsub {^\.?/} $src "" src
		ns_log notice $manifest_identifier
		set src "$manifest_identifier/$src"
	    }
	    
	    set wiki_text "\[\[image:$src]]"
	    set parent [$image parentNode]
	    if { $parent eq "" } {
		set parent $root
	    }

	    $parent replaceChild [$document createTextNode $wiki_text] $image
	}
    }

    set wiki_content [$root asXML]

    return $wiki_content    
}



ad_proc -public imsld::xowiki::page_content {
    -item_id
    -run_id
} {
        
    @author Derick Leony (derick@inv.it.uc3m.es)
    @creation-date 2008-07-31
    
    @param item_id

    @return 
    
    @error 
} {
    set page [::xowiki::Package instantiate_page_from_id -item_id $item_id]
    set result [$page render_content]

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
