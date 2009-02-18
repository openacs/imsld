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
