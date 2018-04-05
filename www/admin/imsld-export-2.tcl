ad_page_contract {
    Export Uol
    
    @author cvalencia@inv.it.uc3m.es
    @creation-date Dec 2008
} {
    imsld_id:integer
    uol_name:nohtml
    include_all:nohtml
    manifest_id:integer
} 

#Check if the user who attempts to enter the page has admin privileges
set package_id [ad_conn package_id]
set admin_p [permission::permission_p -object_id $package_id \
  -privilege admin]

#Delete all files in tmp
exec rm -fr [acs_package_root_dir imsld]/www/tmp/

#Zip file name
if {$uol_name != ""} {
  set download_name "${uol_name}.zip"
} else {
  set download_name "exported_UoL.zip"
}
regsub -all { } $download_name {_} download_name

##########################
# Create imsmanifest.xml #
##########################

#Create tmp directory if it doesn't exist
if {[file isdirectory [acs_package_root_dir imsld]/www/tmp] == 0} {
  exec mkdir [acs_package_root_dir imsld]/www/tmp
}

#Create new temporal directory to store output
set in_path [ns_tmpnam]

set path [acs_package_root_dir imsld]/www$in_path

exec mkdir $path

#Open a new file to write imsmanifest.xml
set manifest [open "${path}/imsmanifest.xml" w]

#Create resource list with one element call NONE
set resource_list [list NONE]

#Write manifest document
set information [imsld::export::uol -run_imsld_id $imsld_id -resource_list $resource_list]

#Write manifest file
puts $manifest "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
puts $manifest $information

#Close imsmanifest.xml file
close $manifest



###################
# Create zip file #
###################

#Create output file
set out_file [file join ${path} ${download_name}]

#Get manifest_id
db_1row get_imsld_data {select organization_id, resource_handler from imsld_imslds where imsld_id = :imsld_id}
db_1row get_manifest_id {select manifest_id from imsld_cp_organizations where organization_id = cr_items.latest_revision and cr_items.item_id = :organization_id}

#Store imsld_id in a variable to use it later
set this_imsld $imsld_id

if {$resource_handler != "xowiki"} {
  #Get files and include them in our export directory
  db_multirow get_files get_files {select resource_id, href from imsld_cp_resources where manifest_id = :manifest_id} {
    #Create folders if necessary to create directory tree
    set inside_path ""
    set position [string last "/" $href]
    if {$position > 0 && [string first "http:" $href] == -1} {
      set inside_path [string range $href 0 [expr $position-1]]
      #file mkdir $path/$inside_path/
    }

    #If the resources is a link, it has no files to be copied
    if {[string first "http:" $href] == -1} {
      #Call proc to copy resource files to export temporal directory
      imsld::export::files::copy_files -resource_id $resource_id -path $path
    }
  }
  if {$include_all == "Yes"} {
    #Save additional files of the UoL which are not used in the player
    #Get imsld_id of next UoL
    if {[db_0or1row get_next_imsld {select organization_id from imsld_imslds where imsld_id > :this_imsld limit 1}] == 1} {
      set next_imsld $organization_id
      db_multirow get_files get_files_1 {} {
        #Create directories if necessary to complete the tree
        set inside_path ""
        set position [string last $file_name $path_to_file]
        if {$position > 0} {
          set inside_path ${inside_path}[string range $path_to_file 0 [expr $position-1]]
          file mkdir $path/$inside_path/
        }
        #Copy file
        if {[fs_file_p [expr $imsld_file_id-1]] == 1} {
          set data [fs__datasource $imsld_file_id]
          set url [lindex $data [expr [lsearch $data content]+1]]
          file copy -force $url "$path/${inside_path}${file_name}"
        }
      }
    } else {
      #If the UoL we are going to export is the last one stored, then copy all
      # files with id greater than imsld_id
      db_multirow get_files get_files_2 {} {
        #Create directories if necessary to complete the tree
        set inside_path ""
        set position [string last $file_name $path_to_file]
        if {$position > 0} {
          set inside_path ${inside_path}[string range $path_to_file 0 [expr $position-1]]
          file mkdir $path/$inside_path/
        }
        #Copy file
        if {[fs_file_p [expr $imsld_file_id-1]] == 1} {
          set data [fs__datasource $imsld_file_id]
          set url [lindex $data [expr [lsearch $data content]+1]]
          file copy -force $url "$path/${inside_path}${file_name}"
        }
      }
    }
  }
}

#Create zip archive
set cmd "zip -r '$out_file' *"
set copy "cp ${path}/imsmanifest.xml ./imsmanifest.xml"
with_catch errmsg {
  exec bash -c "cd '$path'; $cmd; cd -"
} {
  error $errmsg
}

##########################################################################
##########################################################################
##Return file download url
if {[string index $in_path 0] ne "/"} {
  ad_returnredirect "../${in_path}/${download_name}"
} else {
  ad_returnredirect "..${in_path}/${download_name}"
}
#set a [ns_http list]
#ns_returnredirect "${in_path}/${download_name}"
#ad_returnredirect "export_down"
#Remove temporary files and folder
#exec rm -fr $path
##########################################################################
##########################################################################
