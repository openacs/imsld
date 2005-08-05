# /packages/imsld/tcl/imsld-cr-procs.tcl

ad_library {
    Procedures in the imsld namespace that interact with the cr.
    
    @creation-date Aug 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::fs {}

ad_proc -public imsld::fs::file_new { 
    {-href ""}
    {-resource_id ""}
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
    Creates a file (file or directory) in the fs. If the type is file, the file is created with its attributes that are: href, resource_id, file_name, path_to_file and parent_id.

    All the parent dirs (lindex 0) of the corresponding file (path_to_file) that are found in the files_struct_list are created too (if they haven't been created yet). The file structure is the one created with the imsld::parse::get_files_structure proc.

    Returns the file_id of the created file.

    @option href File href
    @option resource_id Resource identifier of which the file belongs to.
    @param path_to_file Path to file
    @option file_name File name
    @param type File or dir
    @option parent_id Parent folder identifier
    @option title Title of the file.
    @option package_id package_id for the instance of IMS-LD
    @option user_id user that adds the file. [ad_conn user_id] used by default.
    @option creation_ip ip-address of the user that adds the file. [ad_conn peeraddr] used by default.
    @option creation_date Creation date of the file. [dt_sysdate] used by default.
    @option edit Are we editing the file?
    @param complete_path Complete path to file
} {
    upvar files_struct_list files_struct_list
    set user_id [expr { [empty_string_p $user_id] ? [ad_conn user_id] : $user_id }]
    set creation_ip [expr { [empty_string_p $creation_ip] ? [ad_conn peeraddr] : $creation_ip }]
    set creation_date [expr { [empty_string_p $creation_date] ? [dt_sysdate] : $creation_date }]
    set package_id [expr { [empty_string_p $package_id] ? [ad_conn package_id] : $package_id }]

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
            if { [lsearch -exact $contentsx [string tolower $complete_path]] >= 0 && [string eq [lindex $contentsx 1] $type] } {
                # file found, see if the parent dir is created
                set found_p 1
                set parent_id [lindex [lindex $dirx 0] 1]
                if { !$parent_id } {
                    # the dir hasn't been created
                    set parent_id [imsld::fs::file_new -path_to_file [lindex [lindex $dirx 0] 0] \
                                       -type dir \
                                       -complete_path [lindex [lindex $dirx 0] 0]]
                    # update file structure
                    set dirx_parent_list [list [lindex [lindex $dirx 0] 0] $parent_id]
                    set dirx [list $dirx_parent_list  [lindex $dirx 1]]
                    set files_struct_list [lreplace $files_struct_list $count_y $count_y $dirx]
                }
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
    if { $found_p } {
        set item_id [expr { [empty_string_p $item_id] ? [db_nextval "acs_object_id_seq"] : $item_id }]
        # create the file with the parent_id found
        switch $type {
            file {
                # insert file into the CR
                db_transaction {
                    if { [empty_string_p $file_name] } {
                        regexp {[^//\\]+$} $path_to_file file_name
                        set file_name [imsld::safe_url_name -name $file_name]
                    }
                    set mime_type [cr_filename_to_mime_type -create $file_name]
                    # database_p according to the file storage parameter
                    set fs_package_id [site_node_apm_integration::get_child_package_id \
                                           -package_id [dotlrn_community::get_package_id [dotlrn_community::get_community_id]] \
                                           -package_key "file-storage"]
                    set database_p [parameter::get -parameter "StoreFilesInDatabaseP" -package_id $fs_package_id]
                    if { !$database_p } {
                        set storage_type file
                    } else {
                        set storabe_tupe lob
                    }
                    set file_id [imsld::cr::file_new -file_name $file_name \
                                     -resource_id $resource_id \
                                     -path_to_file $path_to_file \
                                     -href $href \
                                     -parent_id $parent_id \
                                     -mime_type $mime_type \
                                     -storage_type $storage_type \
                                     -item_id $item_id \
                                     -user_id $user_id \
                                     -creation_date $creation_date \
                                     -package_id $package_id \
                                     -creation_ip $creation_ip]

                    set revision_id [content::item::get_live_revision -item_id $file_id]
                    set content_length [file size $complete_path]
                    
                    if { !$database_p } {
                        # create the new item
                        set filename [cr_create_content_file $file_id $revision_id $complete_path]
                        db_dml set_file_content {
                            update cr_revisions
                            set content = :filename,
                            mime_type = :mime_type,
                            content_length = :content_length
                            where revision_id = :revision_id}
                    } else {
                        # create the new item
                        db_dml lob_content "
                            update cr_revisions  
                            set lob = [set __lob_id [db_string get_lob_id "select empty_lob()"]] 
                            where revision_id = :revision_id" -blob_files [list $complete_path]
                        
                        # Unfortunately, we can only calculate the file size after the lob is uploaded 
                        db_dml lob_size {
                            update cr_revisions
                            set content_length = :content_length
                            where revision_id = :revision_id
                        }
                    }
                }
                # update file structure
                set file_list [list $complete_path file $file_id]
                set content_list [lreplace [lindex [lindex $files_struct_list $count_y] 1] $count_x $count_x $file_list]
                set dir_list [list [lindex [lindex $files_struct_list $count_y] 0] $content_list]
                set files_struct_list [lreplace $files_struct_list $count_y $count_y $dir_list]
            }
            dir {
                # create dir
                regexp {[^//\\]+$} $path_to_file folder_label
                set folder_label [imsld::safe_url_name -name $folder_label]
                set folder_name ${folder_label}_${item_id}
                set file_id [imsld::cr::folder_new -folder_id $item_id \
                                 -parent_id $parent_id \
                                 -folder_name $folder_name \
                                 -folder_label $folder_label]
            }
            default {
                return -code error "IMSLD::imsld::fs::file_new: Error searching file of type $type. Not valid type."
                ad_script_abort
            }
        }
        return $file_id
    } else {
        # no luck, the file doesn't exist
        return 0
    }
}
