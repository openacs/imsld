ad_page_contract {
    Export Uol stored in xowiki

    @author cvalencia@inv.it.uc3m.es
    @creation-date Mayo 2009
} {
    imsld_id:integer
}

#Check if the user who attempts to enter the page has admin priviledges
set package_id [ad_conn package_id]
set admin_p [permission::permission_p -object_id $package_id \
  -privilege admin]

#Delete all files in tmp
exec rm -fr [acs_package_root_dir imsld]/www/tmp/

#Get UoL name
db_1row get_imsld_identifier {select title from cr_revisions where revision_id = :imsld_id}
if {$title == ""} {
  set uol_name "exported_uol"
} else {
  set uol_name $title
}

#Zip file name
if {$uol_name != ""} {
  set download_name "${uol_name}.zip"
} else {
  set download_name "exported_UoL.zip"
}
regsub -all { } $download_name {_} download_name

#We need the manifest_id
db_1row get_manifest {select manifest_id from imsld_cp_organizations, cr_items cr1 where organization_id = cr1.latest_revision and cr1.item_id = imsld_imslds.organization_id and imsld_imslds.imsld_id = :imsld_id}


###################################
# Parse xowiki pages to get files #
###################################

#Create tmp directory if it doesn't exist
if {[file isdirectory [acs_package_root_dir imsld]/www/tmp] == 0} {
  exec mkdir [acs_package_root_dir imsld]/www/tmp
}

#Create new temporal directory to store output
set in_path [ns_tmpnam]
set path [acs_package_root_dir imsld]/www$in_path
exec mkdir $path

#Declare list to store additional resources
set resource_list [list]

set last_file ""
db_multirow get_xowiki_pages get_xowiki_pages {select cr3.name, cr3.item_id, cr3.content_type from acs_rels, cr_items cr1, cr_items cr3 where object_id_one = cr1.item_id and imsld_cp_resources.resource_id = cr1.latest_revision and imsld_cp_resources.manifest_id = :manifest_id and object_id_two = cr3.item_id and (cr3.content_type = '::xowiki::File' or cr3.content_type = '::xowiki::Page')} {
  #Avoid repiting rows
  if {$last_file == $name} {continue} else {
    set last_file $name
  }

  #Don't know what to do with links yet
  if {[string first "link" $name] == 0} {continue}

  if {$content_type == "::xowiki::Page"} {
    #Get resource href
    set resource_href [string range $name [expr [string first "/" $name]+1] [expr [string last "/" $name]]]
##########################################
    db_1row get_page_name {select title from acs_objects where object_id=:item_id}

    set page_title [string map {"%2f" "/"} $title]
    set page_name [string range $page_title [expr [string last "/" $page_title]+1] end]

    #Change : for _ in case language is specified in name
    regsub -all {:} $page_name {_} page_name
    if {[string first "." $page_name] == -1} {
      set page_name ${page_name}.html
    }
    set resource_href ${resource_href}$page_name
#    db_1row get_page_name {select title from acs_objects where object_id=:xo_page_id}
##########################################
    set resource_files_list [imsld::export::files::modify_links -manifest_id $manifest_id -xo_page_id $item_id -path $path]
    #Store new files with href of associated resource in the resource_list
    if {[llength $resource_files_list] > 0} {
      lappend resource_list $resource_href $resource_files_list
    }
  } elseif {$content_type == "::xowiki::File"} {
    #Create new directories if necessary (from subdirectory path)
    file mkdir $path[string range $name [string first "/" $name] [string last "/" $name]]
    if {[db_0or1row get_file_id {select object_id from acs_objects o, cr_revisions r, cr_items i where o.title=:name and o.object_type='::xowiki::File' and o.context_id=:item_id and o.object_id = r.revision_id and r.item_id = i.item_id and r.revision_id = i.live_revision}] == 1} {
      #Get file and copy it to export folder
      set data [fs__datasource $object_id]
      #Get url of folder to copy file
      set url [lindex $data [expr [lsearch $data content]+1]]
      #Get file name from xowiki file identifier
      set file_name [string range $name [expr [string first "/" $name]+1] end]
      #Copy file
      file copy -force $url "$path/$file_name"
    }
  }
}


##########################
# Create imsmanifest.xml #
##########################

#Open a new file to write imsmanifest.xml
set manifest [open "${path}/imsmanifest.xml" w]

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

set download_name [ad_urlencode $download_name]
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
