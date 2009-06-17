package require http

namespace eval imsld::export::files {}

###############################################################################
# Call this function to copy files to temporal directory
###############################################################################
ad_proc -public imsld::export::files::copy_files {
  -resource_id:required
  -path:required
} {
  This proc is called to copy files of a given resource to a temporal directory
} {
  db_multirow get_file_ids get_file_ids {select object_id_two from acs_rels where object_id_one = cr_items.item_id and cr_items.latest_revision = :resource_id} {
    #Get href for each file returned in the get_files_ids query
    if {[db_0or1row get_file_href {select imsld_file_id, path_to_file, href, file_name from imsld_cp_files where imsld_file_id = cr_items.latest_revision and cr_items.item_id = :object_id_two}] == 1} {

      set inside_path ""
      set position [string last $file_name $path_to_file]
      if {$position > 0} {
        set inside_path ${inside_path}[string range $path_to_file 0 [expr $position-1]]
        file mkdir $path/$inside_path/
      }

      if {[fs_file_p [expr $imsld_file_id-1]] == 1} {
        set data [fs__datasource $imsld_file_id]
        set url [lindex $data [expr [lsearch $data content]+1]]
        #Copy file
        file copy -force $url "$path/${inside_path}/${file_name}"
      }
    }
  }
}


###############################################################################
# Call this function to change references in html labels
###############################################################################
ad_proc -public imsld::export::files::modify_links {
  -manifest_id:required
  -xo_page_id:required
  -path:required
} {
  This proc is called to change references in html labels for exporting the UoL
} {
  #Get page name
  db_1row get_page_name {select title from acs_objects where object_id=:xo_page_id}
  set page_title [string map {"%2f" "/"} $title]
  set page_name [string range $page_title [expr [string last "/" $page_title]+1] end]
##############################################
  #Change : for _ in case language is specified in name
  regsub -all {:} $page_name {_} page_name
  if {[string first "." $page_name] == -1} {
    set page_name ${page_name}.html
  }
##############################################

  #Get Xowiki page
  set file_data "[imsld::xowiki::page_content -item_id $xo_page_id]"

  #Get root path to files stored in xowiki
  #Get xowiki package url
  db_1row get_xowiki_package_id {select package_id, title from acs_objects where object_id=:xo_page_id}
  set xowiki_package_url [apm_package_url_from_id $package_id]

  #Parse Xowiki page
  set data_tree [dom parse -html $file_data]
  set root [$data_tree documentElement]


  #Call proc that changes href attribute in a labels
  imsld::export::files::modify_a -root $root -xowiki_package_url $xowiki_package_url
  imsld::export::files::modify_frame -root $root -xowiki_package_url $xowiki_package_url
  imsld::export::files::modify_css -root $root -xowiki_package_url $xowiki_package_url
  set resource_files_list [imsld::export::files::modify_img -root $root -xowiki_package_url $xowiki_package_url -xowiki_package_id $package_id -path $path]

  #Once we have changed the references of the file, then we copy the file
  #Write page file
  set new_file [open "${path}/$page_name" w]
  #Delete unnecessary code from page
  set data [$root asHTML]
  set pos [string last "content-chunk-footer" $data]
  if {$pos > 0} {set data [string range $data 0 [expr $pos-13]]}
  if {[string first "<html" $data] != 0} {set data "<html><body>${data}</body></html>"}
  puts $new_file $data
  close $new_file

  return $resource_files_list

}


###############################################################################
# Call this function to change href attribute in anchor labels
###############################################################################
ad_proc -public imsld::export::files::modify_a {
  -root:required
  -xowiki_package_url:required
} {
  This proc is called to change href attribute in anchor labels
} {
  #Get all anchor elements
  set a_nodes [$root selectNodes //a]

  #Loop to work with all anchor nodes
  set num_elements [llength $a_nodes]
  for {set i 0} {$i<$num_elements} {incr i} {
    set a_href [[lindex $a_nodes $i] getAttribute href NONE]
    if {[string first "http://" $a_href] == 0 || [string first "https://" $a_href] == 0 || [string first "#" $a_href] == 0 || $a_href == "NONE"} {
      continue
    } else {
      #If the code reaches this point, it means that there is a local reference to another file
      #Check if a_href is a reference to a xowiki file
      if {[string first $xowiki_package_url $a_href] == 0} {
        #Build reference to export
        set a_href [string range $a_href [string length $xowiki_package_url] end]
        set a_href [string map {"%2f" "/"} $a_href]
        set a_href [string range $a_href [expr [string first "/" $a_href]+1] end]

       #Change href attribute value to write in it the new reference
       [lindex $a_nodes $i] setAttribute href $a_href
      }
      ##########################################################################################
      # May take into account other possibilities in an else block
      ##########################################################################################
    }
  }  
}


###############################################################################
# Call this function to change src attribute in frame labels
###############################################################################
ad_proc -public imsld::export::files::modify_frame {
  -root:required
  -xowiki_package_url:required
} {
  This proc is called to change src attribute in frame labels
} {
  #Get all frame elements
  set frame_nodes [$root selectNodes //frame]

  #Loop to work with all frame nodes
  set num_elements [llength $frame_nodes]
  for {set i 0} {$i<$num_elements} {incr i} {
    set frame_src [[lindex $frame_nodes $i] getAttribute src NONE]
    #If frame is inside same xowiki community then change src attribute
    if {[string first $xowiki_package_url $frame_src] == 0} {
      #Build reference to export
      set frame_src [string range $frame_src [string length $xowiki_package_url] end]
      set frame_src [string map {"%2f" "/"} $frame_src]
      set frame_src [string range $frame_src [expr [string first "/" $frame_src]+1] end]
      #Change src attribute value to write in it the new reference
      [lindex $frame_nodes $i] setAttribute src $frame_src
    }
    ##########################################################################################
    # May take into account other possibilities in an else block
    ##########################################################################################
  }
}


###############################################################################
# Call this function to change href attribute in link labels (for css)
###############################################################################
ad_proc -public imsld::export::files::modify_css {
  -root:required
  -xowiki_package_url:required
} {
  This proc is called to change href attribute in link labels that link to css files
} {
  #Get all frame elements
  set link_nodes [$root selectNodes //link]

  #Loop to work with all link nodes
  set num_elements [llength $link_nodes]
  for {set i 0} {$i<$num_elements} {incr i} {
    set link_type [[lindex $link_nodes $i] getAttribute type NONE]
    set link_href [[lindex $link_nodes $i] getAttribute href NONE]
    #Check that the link is of text/css type
    if {$link_type == "text/css"} {
      #If link is inside same xowiki community then change href attribute
      if {[string first $xowiki_package_url $link_href] == 0} {
        #Build reference to export
        set link_href [string range $link_href [string length $xowiki_package_url] end]
        set link_href [string map {"%2f" "/"} $link_href]
        set link_href [string range $link_href [expr [string first "/" $link_href]+1] end]
#########################################################################################
#########################################################################################
############          The following code has not been tested           ##################
#########################################################################################
#########################################################################################
        if {[string first "download/file/" $link_href] == 0} {
          set link_href [string range $link_href 14 end]
        }
        set file_title "file:$link_href"
        #Get id of the file where the css file is stored
        set content_item_id [string range [$xowiki_package_id resolve_page "$file_title" method] 2 end]

        db_1row get_file_id {select object_id from acs_objects where title=:file_title and object_type='::xowiki::File' and context_id=:content_item_id}

        #Get file and copy it to export folder
        set data [fs__datasource $object_id]
        #Get url of folder to copy file
        set url [lindex $data [expr [lsearch $data content]+1]]
        #Copy file
        set link_href [string range $link_href [expr [string first "/" $link_href]+1] end]
        if {[db_0or1row is_imsls_cp_file {select imsld_file_id from imsld_cp_files where path_to_file=:file_name}] == 1} {
          file copy -force $url "$path/$link_href"
        } else {
          set position [string last "/" $link_href]
          if {$position != -1} {
            #Delete file path from file name
            set link_href [string range [expr $position+1] end]
          }

          #Create folder to store resources if it doesn't exist
          set aux_folder_name "export_res"
          if {[file isdirectory "$path/$aux_folder_name"] == 0} {
            exec mkdir "$path/$aux_folder_name"
          }

          #Build new file path
          set link_href "${aux_folder_name}/$link_href"
          file copy -force $url "$path/$link_href"
        }
#########################################################################################
#########################################################################################
        #Change src attribute value to write in it the new reference
        [lindex $link_nodes $i] setAttribute href $link_href
      }
    }
    ##########################################################################################
    # May take into account other possibilities in an else block
    ##########################################################################################
  }
}


###############################################################################
# Call this function to change src attribute in img labels
###############################################################################
ad_proc -public imsld::export::files::modify_img {
  -root:required
  -xowiki_package_url:required
  -xowiki_package_id:required
  -path:required
} {
  This proc is called to change src attribute in img labels
} {
  #Get package_id
  set package_id [ad_conn package_id]
  #Store community path
  set community_path [apm_package_url_from_id $package_id]
  set community_path [string range $community_path 0 [expr [string last "/imsld" $community_path]-1]]
  set community_name [string range $community_path [expr [string last "/" $community_path]+1] end]

  set resource_files_list [list]

  #Get all image elements
  set image_nodes [$root selectNodes //img]

  #Loop to work with all image nodes
  set num_elements [llength $image_nodes]
  for {set i 0} {$i<$num_elements} {incr i} {
    set src [[lindex $image_nodes $i] getAttribute src NONE]
    if {$src != "NONE"} {
      #Check if image src is a xowiki file
      if {[string first $xowiki_package_url $src] == 0} {
        #Compute file name
        set position [string length $xowiki_package_url]
        set file_name [string range $src $position end]
        if {[string first "download/file/" $file_name] == 0} {
          set file_name [string range $file_name 14 end]
        }
        set file_name [string map {"%2f" "/"} $file_name]
        set file_title "file:$file_name"
        #Get id of the file where the image is stored
        set content_item_id [string range [$xowiki_package_id resolve_page "$file_title" method] 2 end]

        db_1row get_file_id {select object_id from acs_objects where title=:file_title and object_type='::xowiki::File' and context_id=:content_item_id}

        #Get file and copy it to export folder
        set data [fs__datasource $object_id]
        #Get url of folder to copy file
        set url [lindex $data [expr [lsearch $data content]+1]]
        #Copy file
        set file_name [string range $file_name [expr [string first "/" $file_name]+1] end]
        if {[db_0or1row is_imsls_cp_file {select imsld_file_id from imsld_cp_files where path_to_file=:file_name}] == 1} {
          file copy -force $url "$path/$file_name"
        } else {
          set position [string last "/" $file_name]
          if {$position != -1} {
            #Delete file path from file name
            set file_name [string range [expr $position+1] end]
          }

          #Create folder to store resources if it doesn't exist
          set aux_folder_name "export_res"
          if {[file isdirectory "$path/$aux_folder_name"] == 0} {
            exec mkdir "$path/$aux_folder_name"
          }

          #Build new file path
          set file_name "${aux_folder_name}/$file_name"
          file copy -force $url "$path/$file_name"
        }
        #Add file to resource file list
        lappend resource_files_list $file_name

        #Change src attribute value to write it in file to be exported
        [lindex $image_nodes $i] setAttribute src $file_name
      } else {
        #There is another case we have to compute. it is when the referenced file is stored in the same host
        # but it is not in the xowiki community of imsld (it may be stored in a different xowiki community or
        # in the file storage)

        #First check that the url is local
        if {[string first "http://" $src] != 0} {
          #Create folder to store resources if it doesn't exist
          set aux_folder_name "export_res"
          if {[file isdirectory "$path/$aux_folder_name"] == 0} {
            exec mkdir "$path/$aux_folder_name"
          }

          if {[string first "${community_path}/" $src] == 0} {
            set src [string range $src [expr [string length $community_path]+1] end]
            set type [string range $src 0 [expr [string first "/" $src]-1]]
            #If type == file-storage
            if {$type == "file-storage"} {
              set src [string range $src 13 end]
              #Here we can find to possibilities: view or download
              if {[string first "view" $src] == 0} {
                set src [string range $src 5 end]
                #Get file name
                set position [string last "/" $src]
                set file_name [string range $src [expr $position+1] end]
                set file_name "$aux_folder_name/$file_name"
                if {$position != -1} {
                  set file_path [string range $src 0 [expr $position-1]]
                } else {
                  set file_path ""
                }

                #Get file storage folder
                db_1row get_folder_id {select acs1.object_id from acs_objects acs1, acs_objects acs2, acs_objects acs3 where acs1.context_id = acs2.object_id and acs2.title='#file-storage.file-storage#' and acs2.context_id = acs3.object_id and acs3.object_type = 'apm_package' and acs3.context_id = dotlrn_communities.community_id and dotlrn_communities.community_key = :community_name}
                set folder_id $object_id
                if {$file_path != ""} {
                  set position [string first "/" $file_path]
                  if {$position == 0} {
                    set file_path [string range $file_path 1 end]
                    set position [string first "/" $file_path]
                  }
                  while {$position > 0} {
                    #Get folder key name
                    set folder_name [string range $file_path 0 [expr $position-1]]

                    #Get folder_id
                    db_1row get_folder_id {select folder_id from fs_folders where key=:folder_name and parent_id=:folder_id}

                    set file_path [string range $file_path [expr $position+1] end]
                    #Update loop variable
                    set position [string first "/" $file_path]
                  }
                }
                #Check that the file exist
                if {[db_0or1row get_file_id {select file_id, live_revision from fs_files where key=:file_name and parent_id=:folder_id}] == 1} {
                  #Copy file
                  if {[fs_file_p [expr $file_id]] == 1} {
                    set data [fs__datasource $live_revision]
                    set url [lindex $data [expr [lsearch $data content]+1]]
                    file copy -force $url "$path/$file_name"
                  }
                  #Add file to resource file list
                  lappend resource_files_list $file_name
                }
                #Change src attribute value to write it in file to be exported
                [lindex $image_nodes $i] setAttribute src "$file_name"

              } else {
                #If the url is download
                #Get file id
                set position [string last "file%5fid=" $src]
                if {$position > 0} {
                  set src [string range $src [expr $position+10] end]
                } else {
                  set position [string last "file_id=" $src]
                  if {$position > 0} {
                    set src [string range $src [expr $position+8] end]
                  }
                  #If none of the previous conditions is fullfill, then a new kind of local url
                  # not taken into account appears or there is an error in the computed url.
                }
                #Copy file
                if {[fs_file_p $src] == 1} {
                  #Get live revision and file name
                  db_1row get_live_revision {select live_revision, key from fs_files where file_id=:src}
                  set data [fs__datasource $live_revision]
                  set url [lindex $data [expr [lsearch $data content]+1]]
                  set file_name "$aux_folder_name/$key"
                  file copy -force $url "$path/$file_name"
                }

                #Add file to resource file list
                lappend resource_files_list $file_name

                #Change src attribute value to write it in file to be exported
                [lindex $image_nodes $i] setAttribute src "$file_name"
              }
            }
          } else {
            #This is the case when the resource is stored in a different community
            set src [string range $src 14 end]
            #Get community name
            set other_comm_name [string range $src 0 [expr [string first "/" $src]-1]]
            set src [string range $src [expr [string first "/" $src]+1] end]
            #Get storage type (file-storage or xowiki)
            set type [string range $src 0 [expr [string first "/" $src]-1]]
            set src [string range $src [expr [string first "/" $src]+1] end]
            if {$type == "file-storage"} {
              #Here we can find to possibilities: view or download
              if {[string first "view" $src] == 0} {
                set src [string range $src 5 end]
                #Get file name
                set position [string last "/" $src]
                set file_nam [string range $src [expr $position+1] end]
                set file_name "$aux_folder_name/$file_name"
                if {$position != -1} {
                  set file_path [string range $src 0 [expr $position-1]]
                } else {
                  set file_path ""
                }

                #Get file storage folder
                db_1row get_folder_id {select acs1.object_id from acs_objects acs1, acs_objects acs2, acs_objects acs3 where acs1.context_id = acs2.object_id and acs2.title='#file-storage.file-storage#' and acs2.context_id = acs3.object_id and acs3.object_type = 'apm_package' and acs3.context_id = dotlrn_communities.community_id and dotlrn_communities.community_key = :other_comm_name}
                set folder_id $object_id
                if {$file_path != ""} {
                  set position [string first "/" $file_path]
                  if {$position == 0} {
                    set file_path [string range $file_path 1 end]
                    set position [string first "/" $file_path]
                  }
                  while {$position > 0} {
                    #Get folder key name
                    set folder_name [string range $file_path 0 [expr $position-1]]

                    #Get folder_id
                    db_1row get_folder_id {select folder_id from fs_folders where key=:folder_name and parent_id=:folder_id}

                    set file_path [string range $file_path [expr $position+1] end]
                    #Update loop variable
                    set position [string first "/" $file_path]
                  }
                }
                #Check that the file exist
                if {[db_0or1row get_file_id {select file_id, live_revision from fs_files where key=:file_nam and parent_id=:folder_id}] == 1} {
                  #Copy file
                  if {[fs_file_p [expr $file_id]] == 1} {
                    set data [fs__datasource $live_revision]
                    set url [lindex $data [expr [lsearch $data content]+1]]
                    set file_name "$aux_folder_name/$file_nam"
                    file copy -force $url "$path/$file_name"
                  }
                  #Add file to resource file list
                  lappend resource_files_list $file_name
                }
                #Change src attribute value to write it in file to be exported
                [lindex $image_nodes $i] setAttribute src "$file_name"

              } else {
                #If the url is download
                #Get file id
                set position [string last "file%5fid=" $src]
                if {$position > 0} {
                  set src [string range $src [expr $position+10] end]
                } else {
                  set position [string last "file_id=" $src]
                  if {$position > 0} {
                    set src [string range $src [expr $position+8] end]
                  }
                }
                #Copy file
                if {[fs_file_p $src] == 1} {
                  #Get live revision and file name
                  db_1row get_live_revision {select live_revision, key from fs_files where file_id=:src}
                  set data [fs__datasource $live_revision]
                  set url [lindex $data [expr [lsearch $data content]+1]]
                  set file_name "$aux_folder_name/$key"
                  file copy -force $url "$path/$file_name"
                }

                #Add file to resource file list
                lappend resource_files_list $file_name

                #Change src attribute value to write it in file to be exported
                [lindex $image_nodes $i] setAttribute src "$file_name"
              }
            }
            #####################################################################
            # Here may be an else block for Xowiki in other communities
            #####################################################################
          }
        }
        #########################################################################
        # Here may be an else block for external urls
        # This case has not been considered for implementation.
        #########################################################################
      }
    }
  }
  return $resource_files_list
}


