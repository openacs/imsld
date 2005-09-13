# /packages/imsld/tcl/imsld-parse-procs.tcl

ad_library {
    Procedures in the imsld namespace for parsing xml files.
    
    @creation-date Jul 2005
    @author jopez@inv.it.uc3m.es
    @cvs-id $Id$
}

namespace eval imsld {}
namespace eval imsld::parse {}

ad_proc -public imsld::parse::find_manifest {
    -dir
    -file_name
} {
    Taken from the one with the same name in the LORS package.
    Find the manifest file (or other file) that contains
    the ims ld.
    if it finds it, then it returns the file location. Otherwise it 
    returns 0

    @param tmp_dir Temporary directory where the course is located
    @param file Manifest file
} {
    if { [file exist $dir/$file_name] } {
        return "$dir/$file_name"
    } else {
        return 0
    }
}

ad_proc -public imsld::parse::is_imsld {
    -tree:required
} {
    Checks it the given tree has the IMS LD extension and if the IMS LD comes in the organization.

    Returns a list (pair of values): 1 + empty if succeeded, 0 + error message otherwise.

    @param tree XML tree to analyze.
} {
    
    # Check the manifest attribute
    set man_attribute [$tree hasAttribute xmlns:imsld]

    # Check manifest organizations
    set organizations [$tree child all imscp:organizations]

    if { [llength $organizations] == 1 } {
        
        set imsld [$organizations child all imsld:learning-design]
        
        if { [llength $imsld] > 1 } {
            # There are more than one imsld in the organization, not supported
            return [list 0 "<#_ The manifest has more than one imsld:learning design. Right now this is not supported, sorry. #>"]
        }

    } else {
        # There are more than one organizations, or there is none. None of those cases supported, aborting
        return [list 0 "<#_ The manifest doesn't contain any organizations or there are more than one. None of those cases are supported in this version, sorry. #>"]
    }

    # After validating the cases above, we can say that this seems a well formed IMS LD
    return [list 1 {}]
}

ad_proc -public imsld::parse::expand_file {
    -upload_file:required
    -tmpfile:required
    {-dest_dir_base "imsld"}
} {
    Taken from the one with the same name in the LORS package.
    Extracts the contents of the file and puts them in the folder
    indicated by dest_dir. If empty, it will generate a tmp_dir for the extraction.

    Returns the name of the directory where the files where extracted.

    @param upload_file Path of the file to be extracted
    @param tmpfile Temporary file name
    @option dest_dir_base Destination directory where the files will be extracted
} {

    # Generate a random directory name
    if { [catch {set tmp_dir [file join [file dirname $tmpfile] [ns_mktemp "$dest_dir_base-XXXXXX"]]} errmsg] } {
        form set_error upload_file_form upload_file "<#_ There was an error generating the tmp_dir to unzip the file. #> $errmsg"
        return -code error "IMSLD::imsld::parse::expand_file: Error generating tmp directory: $errmsg"
    }

    # Create a temporary directory
    if { [catch {file mkdir $tmp_dir} errmsg] } {
        form set_error upload_file_form upload_file "<#_ There was an error creating the tmp_dir to unzip the file. #> $errmsg"
        return -code error "IMSLD::imsld::parse::expand_file: Error creating tmp directory: $errmsg"
    }

    set upload_file [string trim [string tolower $upload_file]]

    if { [regexp {(.tar.gz|.tgz)$} $upload_file] } { 
        set type tgz 
    } elseif { [regexp {.tar.z$} $upload_file] } { 
        set type tgZ 
    } elseif { [regexp {.tar$} $upload_file] } { 
        set type tar 
    } elseif { [regexp {(.tar.bz2|.tbz2)$} $upload_file] } { 
        set type tbz2 
    } elseif { [regexp {.zip$} $upload_file] } { 
        set type zip 
    } else { 
        set type "<#_ Uknown type #>" 
    } 
    
    switch $type {
        tar {
            set error_p [catch {exec tar --directory $tmp_dir -xvf $tmpfile} errmsg]
        }
        tgZ {
            set error_p [catch {exec tar --directory $tmp_dir -xZvf $tmpfile} errmsg]
        }
        tgz {
            set error_p [catch {exec tar --directory $tmp_dir -xzvf $tmpfile} errmsg]
        }
        tbz2 {
            set error_p [catch {exec tar --directory $tmp_dir -xjvf $tmpfile} errmsg]
        }
        zip {
            set error_p [catch {exec unzip -d $tmp_dir $tmpfile} errmsg]
            
            ## According to man unzip:
            # unzip exit status:
            #
            # 0      normal; no errors or warnings
            # detected.
            
            # 1 one or more warning errors were encountered, but process-
            #   ing  completed  successfully  anyway.  This includes zip-
            #   files where one or more files was skipped due  to  unsup-
            #   ported  compression  method or encryption with an unknown
            #   password.
            
            # Therefor it if it is 1, then it concluded successfully
            # but with warnings, so we switch it back to 0
            
            if { $error_p == 1 } {
                set error_p 0
            }
        }
        default {
            set error_p 1
            set errmsg "<#_ Could not determine whit what program uncompress the file $upload_file has. Aborting #>"
        }
    }
    
    if { $error_p } {
        imsld::parse::remove_dir -dir $tmp_dir
        ns_log Notice "IMSLD::imsld::parse::expand_file: extract type $type failed $errmsg"
        return -code error "IMSLD::imsld::parse::expand_file: extract type $type failed $errmsg"
    }
    return $tmp_dir
}

ad_proc -public imsld::parse::get_title {
    -node
    {-prefix ""}
} {
    Returns the tile of the given node or empty string if not found.

    @param node Node
    @option prefix Prefix for the "title"
    
} {
    set prefix [expr { [empty_string_p $prefix] ? "" : "${prefix}:" }]
    set titles_list [$node child all ${prefix}title]
    if { [llength $titles_list] } {
        imsld::parse::validate_multiplicity -tree $titles_list -multiplicity 1 -element_name title -equal
        return [imsld::parse::get_element_text -node $titles_list]
    } else {
        return ""
    }
}

ad_proc -public imsld::parse::get_element_text {
    -node
} {
    Returns the text of the given node

    @param node Node
    
} {
    return [$node text]
}

ad_proc -public imsld::parse::get_attribute {
    -node
    -attr_name
} {
    Taken from the one with the same name in the LORS package.
    Gets attributes for an specific element. Returns the attribute value if found, emtpy string otherwise
    
    @param node Node
    @param attr_name Attribute we want to fetch
} {
    if { [$node hasAttribute $attr_name] == 1 } {
        $node getAttribute $attr_name
    } else {
        return ""
    }
}

ad_proc -public imsld::parse::get_bool_attribute {
    -node
    -attr_name
    -default
} {
    Gets a boolean attribute for an specific element. Returns the tcl true or false value attribute value if found, -default otherwise.

    @param node Document
    @param attr_name Attribute we want to fetch
} {
    if { [$node hasAttribute $attr_name] == 1 } {
        return [imsld::parse::sql_boolean -bool [$node getAttribute $attr_name]]
    } else {
        return $default
    }
}

ad_proc -public imsld::parse::validate_multiplicity {
    -tree
    -multiplicity
    -element_name
    -equal:boolean
    -greather_than:boolean
    -lower_than:boolean
} {
    Validates the multiplicity of a given tree. It throws an error if the multiplicity is greather or equal than, lowher or equal than or not equal to the number especified in the multiplicity param.

    Only one vaidation can be done at the same time, and by default, equal is pefrormed.

    @param tree Document
    @param multiplicity Number of times the element can be repeated
    @param element_name Name of the element we are validating (in order to display a possible error message)
    @option equal If passed, the number of roots of the tree must be equal to multiplicity
    @option greather_than If passed, the number of roots of the tree must be greather or equal than multiplicity
    @option lower_than If passed, the number of roots of the tree must be lower or equal than multiplicity
} {
    if { [expr $equal_p + $greather_than_p + $lower_than_p] > 1 } {
        return -code error "IMSLD:imsld::parse::validate_multiplicity: <#_ More than one validation tried at the same time#>"
    }
    if { ![expr $equal_p + $greather_than_p + $lower_than_p] } {
        set equal_p 1
    }

    if { $equal_p } {
        if { [llength $tree] != $multiplicity } {
            ad_return_error "<#_ Error parsing file #>" "<#_ There must be exactly $multiplicity $element_name and there are [llength $tree]. This is not supported, sorry. #>"
            ad_script_abort
        }
    } elseif { $greather_than_p } {
        if { [llength $tree] < $multiplicity } {
            ad_return_error "<#_ Error parsing file #>" "<#_ There can't be less than $multiplicity $element_name and there are [llength $tree]. This is not supported, sorry. #>"
            ad_script_abort
        } 
    } else {
        if { [llength $tree] > $multiplicity } {
            ad_return_error "<#_ Error parsing file #>" "<#_ There can't greather than $multiplicity $element_name and there are [llength $tree]. This is not supported, sorry. #>"
            ad_script_abort
        } 
    }
}

ad_proc -public imsld::parse::remove_dir {
    -dir:required
} {
    Deletes the given directory.
    For instance, the tmp_dir used to extract the files and parse them.

    Returns 1 when succeded, 0 otherwise

    @param dir directory to be deleted.
} {
    if { [file exist $dir] } {
        if { [catch {exec rm -rf $dir} errmsg] } {
            return -code error "IMSLD:imsld::parse::remove_dir: <#_ There was an error trying to delete the dir $dir. #> $errmsg"
        }
    }

    return 1
}

ad_proc -public imsld::parse::sql_boolean {
    -bool:required
} {
    Convets a boolean string to its corresponding boolean value f or t. 

    @param bool The boolean value to convert
} {
    set result ""
    set value [string tolower $bool]

    switch $bool {
        0 -
        f -
        n -
        no -
        false {
            set result f
        }
        1 -
        t -
        y -
        yes -
        true {
            set result t
        }
        default {
            set result 0
            ns_log error "Invalid option in imsld::parse::sql_boolean - $bool"
        }
    }
    return $result 
}

ad_proc -public imsld::parse::get_folder_contents {
    -dir:required
    -type:required
} {
    Checks if the fs_dir has files or directories, nd returns the list of them in a list.

    @param dir File System directory
    @param type file or directory. If type is file it returns the list of files in the dir. If type is directory it returns the list of directories in the dir.
} {
    set return_list [list]
     foreach f [glob -no complain [file join $dir * ]] {
         if { [string eq $type [file type $f]] } {
             lappend return_list $f
         }
     }
    return $return_list
}

ad_proc -public imsld::parse::get_files_structure { 
    -tmp_dir:required
} {
    Returns a list of lists with the structure of the files that are being parsed which is used to find the files and subdirs in the parsing process.
    
    @param tmp_dir The dir where the files where uncompressed to.
} {
    if { [file exists $tmp_dir] } {
        set files_structure [list]
        
        # get all the directories and files under those dirs
        # dirx = directory loop
        set dirx [list $tmp_dir]

        # for each directory found..
        while { [llength $dirx] != 0 } {
            set dir [lindex $dirx 0]
            set dir_content [list]
                
            foreach subdirx [imsld::parse::get_folder_contents -dir $dir -type directory] {
                lappend dir_content [list [string tolower "$subdirx"] dir]
                lappend dirx $subdirx
            }
            foreach filex [imsld::parse::get_folder_contents -dir $dir -type file] {
                lappend dir_content [list [string tolower "$filex"] file 0]
            }
            lappend files_structure [list [list [string tolower $dir] 0] $dir_content]
            set dirx [lrange $dirx 1 [expr [llength $dirx] -1]]
        }
        return $files_structure
    }
}

ad_proc -public imsld::parse::initialize_folders { 
    -community_id:required
    -manifest_id:required
    {-manifest_identifier ""}
} {
    Initializes the cr folders where all the cr items of the manifest will be stored in, and sets the respective permissions. There are two folders for each imsld. One to store the files and show them in the fs, and the other to store the items..
    It won't create the files in the cr since not every file will be handled by the cr (some files may be handled by other packages).

    Returns a list of two elements, the firs one is the folder_id in the fs of the root folder for that manifest, and the ohter one is the folder_id where the cr items and revisions are stored.
    
    @param community_id The community_id that owns the folder.
    @option manifest_identifier The identifier of the manifest that is being parsed uset to create the label of the fs folder.
    @param manifest_id Id of the manifest being parsed.
} {
    if { ![empty_string_p $manifest_identifier] } {
        set folder_label $manifest_identifier
        # gets rid of the path and leaves the name of the directory
        regexp { ([^/\\]+)$ } $folder_label match folder_label
        # strips out spaces from the name
        regsub -all { +} $folder_label {_} folder_label
    } else {
        set folder_label "IMS-Learning-Design-Folder"
    }

    # Gets file-storage root folder_id
    set fs_package_id [site_node_apm_integration::get_child_package_id \
                           -package_id [dotlrn_community::get_package_id $community_id] \
                           -package_key "file-storage"]
    
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    

    set fs_folder_id [content::item::get_id -item_path "manifest_${manifest_id}" -root_folder_id $root_folder_id -resolve_index f] 
    set cr_folder_id [content::item::get_id -item_path "cr_manifest_${manifest_id}" -resolve_index f] 

    if { [empty_string_p $fs_folder_id] } {
        db_transaction {
            set folder_name "manifest_${manifest_id}"

            # checks for write permission on the parent folder
            ad_require_permission $root_folder_id write
            
            # create the root cr dir
            set fs_folder_id [imsld::cr::folder_new -parent_id $root_folder_id -folder_name $folder_name -folder_label $folder_label]
            
            # PERMISSIONS FOR FILE-STORAGE

            # Before we go about anything else, lets just set permissions straight.
            # Disable folder permissions inheritance
            permission::toggle_inherit -object_id $fs_folder_id
            
            # Set read permissions for community/class dotlrn_member_rel
            set party_id_member [dotlrn_community::get_rel_segment_id -community_id $community_id -rel_type dotlrn_member_rel]
            permission::grant -party_id $party_id_member -object_id $fs_folder_id -privilege read
            
            # Set read permissions for community/class dotlrn_admin_rel
            set party_id_admin [dotlrn_community::get_rel_segment_id -community_id $community_id -rel_type dotlrn_admin_rel]
            permission::grant -party_id $party_id_admin -object_id $fs_folder_id -privilege read
            
            # Set read permissions for *all* other professors  within .LRN
            # (so they can see the content)
            set party_id_professor [dotlrn::user::type::get_segment_id -type professor]
            permission::grant -party_id $party_id_professor -object_id $fs_folder_id -privilege read
            
            # Set read permissions for *all* other admins within .LRN
            # (so they can see the content)
            set party_id_admins [dotlrn::user::type::get_segment_id -type admin]
            permission::grant -party_id $party_id_admins -object_id $fs_folder_id -privilege read
        }
        # register content types
        content::folder::register_content_type -folder_id $fs_folder_id \
            -content_type imsld_cp_file

        # allow subfolders inside our parent test folder
        content::folder::register_content_type -folder_id $fs_folder_id \
            -content_type content_folder
    } 
    
    if { [empty_string_p $cr_folder_id] } {
        set folder_label "cr_${folder_label}"
        set folder_name "cr_manifest_${manifest_id}"
        # create the cr dir
        set cr_folder_id [imsld::cr::folder_new -folder_name $folder_name -folder_label $folder_label]
        
        # register content types
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_learning_object
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_imsld
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_learning_objective
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_prerequisite
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_item
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_component
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_role
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_learning_activity
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_support_activity
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_activity_structure
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_environment
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_send_mail_service
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_send_mail_data
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_conference_service
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_method
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_play
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_act
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_role_part
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_parameter
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_time_limit
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_on_completion
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_cp_manifest
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_cp_organization
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_cp_resource
        content::folder::register_content_type -folder_id $cr_folder_id -content_type imsld_cp_dependency
    }

    return [list $fs_folder_id $cr_folder_id]
}

ad_proc -public imsld::parse::parse_and_create_resource { 
    -manifest
    -manifest_id
    -resource_node
    -parent_id
    -tmp_dir
} {
    Parses an IMS-LD resource and stores all the information in the database, such as files, dependencies, etc

    Returns a list with the new resource_id created if there were no errors, or 0 and an error explanation.
    
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param resource_node Resource tree being parsed
    @param parent_id Parent folder ID
    @tmp_dir Temporary directory where the files were exctracted
} {
    upvar files_struct_list files_struct_list
    # now we proceed to get all the info of the resource
    set resource_type [imsld::parse::get_attribute -node $resource_node -attr_name type]
    set resource_href [imsld::parse::get_attribute -node $resource_node -attr_name href]
    set resource_identifier [imsld::parse::get_attribute -node $resource_node -attr_name identifier]
    set resource_id [imsld::cp::resource_new -manifest_id $manifest_id \
                         -identifier $resource_identifier \
                         -type $resource_type \
                         -href $resource_href \
                         -parent_id $parent_id]
    
    set found_p 0
    foreach filex [$resource_node child all imscp:file] {
        set filex_href [imsld::parse::get_attribute -node $filex -attr_name href]
        if { ![empty_string_p $resource_href] && [string eq $resource_href $filex_href] } {
            # check if the referenced file in the resource exists
            # if we finish with the files and the referenced one doesn't exist we raise an error
            set found_p 1
        }
        set filex_id [imsld::fs::file_new -href $filex_href \
                          -resource_id $resource_id \
                          -path_to_file $filex_href \
                          -type file \
                          -complete_path "${tmp_dir}/${filex_href}"]
        if { !$filex_id } {
            # an error ocurred when creating the file
            return [list 0 "<#_ The file $filex_href % was not created, it wasn't found in the manifest #>"]
        }
    }
    
    if { ![empty_string_p $resource_href] && !$found_p } {
        # we should have fond the referenced file, aborting
        return [list 0 "<#_ The resource %resource_identifier% has a reference to a non existing file (%resource_href%). #>"]
    }

    set resource_dependencies [$resource_node child all imscp:dependency]
    foreach dependency $resource_dependencies {
        set dependency_identifierref [imsld::parse::get_attribute -node $dependency -attr_name identifierref]
        set dependency_id [imsld::cp::dependency_new -resource_id $resource_id \
                               -identifierref $dependency]
        # look for the resource in the manifest and add it to the CR
        set resources [$manifest child all imscp:resources]
        
        # there must be at least one reource for the learning objective
        imsld::parse::validate_multiplicity -tree $resources -multiplicity 0 -element_name "resources (dependency)" -greather_than

        set resourcex [$resources find identifier $dependency_identifierref]
        # this resourcex must match with exactly one resource
        imsld::parse::validate_multiplicity -tree $resourcex -multiplicity 1 -element_name "resource ($dependency_identifierref) en $resourcex" -equal
        set dependency_resource_list [imsld::parse::parse_and_create_resource -resource_node $resourcex \
                                          -manifest $manifest \
                                          -manifest_id $manifest_id \
                                          -parent_id $parent_id \
                                          -tmp_dir $tmp_dir]
        if { ![lindex $dependency_resource_list 0] } {
            # return this value and let the user know there was an error (becuase if succeded, it does nothing here)
            return $dependency_resource_list
        }
    }
    return [list $resource_id {}]
}

ad_proc -public imsld::parse::parse_and_create_item { 
    -manifest
    -manifest_id
    -item_node
    -parent_id
    -tmp_dir
    {-parent_item_id ""}
} {
    Parse IMS-LD item node and stores all the information in the database, such as the resources, resources items, etc.

    Returns a list with the new imsld_item_id created if there were no errors, or 0 and an explanatio messge if there was an error.
    
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param item_node The item node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @option parent_item_id In case it's a nested item. Default null
} {
    upvar files_struct_list files_struct_list
    set item_title [imsld::parse::get_title -node $item_node -prefix imsld]
    set item_identifier [imsld::parse::get_attribute -node $item_node -attr_name identifier]
    set item_is_visible_p [imsld::parse::get_bool_attribute -node $item_node -attr_name isvisible -default t]
    set item_parameters [imsld::parse::get_attribute -node $item_node -attr_name parameters]
    set item_identifierref [imsld::parse::get_attribute -node $item_node -attr_name identifierref]
    set item_id [imsld::item_new -title $item_title \
                     -identifier $item_identifier \
                     -is_visible_p $item_is_visible_p \
                     -parameters $item_parameters \
                     -identifierref $item_identifierref \
                     -parent_id $parent_id \
                     -parent_item_id $parent_item_id]
    if { ![empty_string_p $item_identifierref] } {
        # look for the resource in the manifest and add it to the CR
        set resources [$manifest child all imscp:resources]
        
        # there must be at least one reource for the learning objective
        imsld::parse::validate_multiplicity -tree $resources -multiplicity 0 -element_name "resources (item)" -greather_than

        set resourcex [$resources find identifier $item_identifierref]
        # this resourcex must match with exactly one resource
        imsld::parse::validate_multiplicity -tree $resourcex -multiplicity 1 -element_name "resources ($item_identifierref)" -equal
        set resource_list [imsld::parse::parse_and_create_resource -resource_node $resourcex \
                               -manifest $manifest \
                               -manifest_id $manifest_id \
                               -parent_id $parent_id \
                               -tmp_dir $tmp_dir]
        set resource_id [lindex $resource_list 0]
        if { !$resource_id } {
            # return the error
            return $resource_list
        }
        # map item with resource
        relation_add imsld_item_res_rel $item_id $resource_id
    }
    
    # nested or sub items
    set nested_item_list [$item_node child all imsld:item]
    if { [llength $nested_item_list] } {
        foreach nested_item $nested_item_list {
            set nested_item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                                      -manifest_id $manifest_id \
                                      -item_node $information_item \
                                      -parent_id $parent_id \
                                      -tmp_dir $tmp_dir \
                                      -parent_item_id $item_id]
            
            set item_id [lindex $nested_item_list 0]
            if { !$nested_item_id } {
                # an error happened, abort and return the list whit the error
                return $nested_item_list
            }
        }
    }
    return $item_id
}

ad_proc -public imsld::parse::parse_and_create_role { 
    -role_type
    -component_id
    -manifest
    -manifest_id
    -roles_node
    -parent_id
    -tmp_dir
    {-parent_role_id ""}
} {
    Parse IMS-LD role node and stores all the information in the database.

    Returns a list with the new role_id (item_id) created if there were no errors, or 0 and an explanatio messge if there was an error.
    
    @param role_type staff or learner
    @param component_id Component identifier which this role belongs to
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param roles_node The role node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @option parent_role_id Parent role identifier. Default to null
} {
    # get the info of the role node and create the respective role
    set role_create_new [imsld::parse::get_attribute -node $role -attr_name create-new]
    switch [string tolower $role_create_new] {
        allowed {
            set role_create_new_p t
        }
        not-allowed {
            set role_create_new_p f
        }
        default {
            set role_create_new_p t
        }
    }
    set role_href [imsld::parse::get_attribute -node $role -attr_name href]
    set role_identifier [imsld::parse::get_attribute -node $role -attr_name identifier]
    set role_match_persons [imsld::parse::get_attribute -node $role -attr_name identifier]
    switch [string tolower $role_match_persons] {
        exclusively-in-roles {
            set role_match_persons_p t
        }
        not-exclusively {
            set role_match_persons_p f
        }
        default {
            set role_match_persons_p f
        }
    }
    set role_max_persons [imsld::parse::get_attribute -node $role -attr_name max-persons]
    set role_min_persons [imsld::parse::get_attribute -node $role -attr_name min-persons]
    set role_title [imsld::parse::get_title -node $role -prefix imsld]
    
    # create the role
    set role_id [imsld::role_new -identifier $role_identifier \
                     -role_type $role_type \
                     -parent_role_id $parent_role_id \
                     -create_new_p $role_create_new_p \
                     -match_persons_p $role_match_persons_p \
                     -max_persons $role_max_persons \
                     -min_persons $role_min_persons \
                     -href $role_href \
                     -component_id $component_id \
                     -title $title]
    
    # continue with the role information and nested roles
    set role_information [$role child all imsld:information]
    if { [llength $role_information] } {
        # parse the item, create it and map it to the role
        set information_item [$role_information child all imsld:item]
        if { ![llength $information_item] } {
            return [list 0 "<#_ Information given but no item associated to it for the role %role_title% #>"]
        }

        set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                           -manifest_id $manifest_id \
                           -item_node $information_item \
                           -parent_id $parent_id \
                           -tmp_dir $tmp_dir]
        
        set item_id [lindex $item_list 0]
        if { !$item_id } {
            # an error happened, abort and return the list whit the error
            return $item_list
        }
        # map information item with the role
        relation_add imsld_role_item_rel $role_id $item_id
    }
    
    # nested roles
    set nested_role [$role child all "imsld:${role_type}"]
    if { [llength $nested_role] } {
        imsld::parse::parse_and_create_role -role_type $role_type \
            -manifest $manifest \
            -manifest_id $manifest_id \
            -parent_id $parent_id \
            -tmp_dir $tmp_dir \
            -roles_node $nested_role \
            -parent_role_id $role_id \
            -component_id $component_id
    }

    return $role_id
}

ad_proc -public imsld::parse::parse_and_create_learning_objective { 
    -learning_objective_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a learning objective and stores all the information in the database.

    Returns a list with the new learning_objective_id (item_id) created if there were no errors, or 0 and an explanatio messge if there was an error.
    
    @param learning_objective_node learning objective node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    # get learning objective info
    set learning_objective_title [imsld::parse::get_title -node $learning_objective_node -prefix imsld]
    set learning_objective_id [imsld::learning_objective_new -title $learning_objective_title \
                                   -parent_id $parent_id]
    
    # learning objective: imsld_items
    set learning_objective_items [$learning_objective_node child all imsld:item]
    if { [llength $learning_objective_items] } {
        foreach imsld_item $learning_objective_items {
            
            set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                               -manifest_id $manifest_id \
                               -item_node $imsld_item \
                               -parent_id $parent_id \
                               -tmp_dir $tmp_dir]
            
            set item_id [lindex $item_list 0]
            if { !$item_id } {
                # an error happened, abort and return the list whit the error
                return $item_list
            }
            # map item with the learning objective
            relation_add imsld_lo_item_rel $learning_objective_id $item_id
        } 
    }
    return $learning_objective_id
}

ad_proc -public imsld::parse::parse_and_create_prerequisite { 
    -prerequisite_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a prerequisite and stores all the information in the database.

    Returns a list with the new prerequisite_id (item_id) created if there were no errors, or 0 and an explanatio messge if there was an error.
    
    @param prerequisite_node prerequisite node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    # get prerequisite info
    set prerequisite_title [imsld::parse::get_title -node $prerequisite_node -prefix imsld]
    set prerequisite_id [imsld::prerequisite_new -title $prerequisite_title \
                                   -parent_id $parent_id]
    
    # prerequisite: imsld_items
    set prerequisite_items [$prerequisite_node child all imsld:item]
    if { [llength $prerequisite_items] } {
        foreach imsld_item $prerequisite_items {
            
            set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                               -manifest_id $manifest_id \
                               -item_node $imsld_item \
                               -parent_id $parent_id \
                               -tmp_dir $tmp_dir]
            
            set item_id [lindex $item_list 0]
            if { !$item_id } {
                # an error happened, abort and return the list whit the error
                return $item_list
            }
            # map item with the prerequisite
            relation_add imsld_lo_item_rel $prerequisite_id $item_id
        } 
    }
    return $prerequisite_id
}

ad_proc -public imsld::parse::parse_and_create_activity_description { 
    -activity_description_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a activity description and stores all the information in the database.

    Returns a list with the new activity_description_id (item_id) created if there were no errors, or 0 and an explanatio messge if there was an error.
    
    @param activity_description_node activity description node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    # get activity description info
    set activity_description_title [imsld::parse::get_title -node $activity_description_node -prefix imsld]
    set activity_description_id [imsld::activity_description_new -title $activity_description_title \
                                     -parent_id $parent_id]
    
    # activity description: imsld_items
    set activity_description_items [$activity_description_node child all imsld:item]
    if { [llength $activity_description_items] } {
        foreach imsld_item $activity_description_items {
            
            set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                               -manifest_id $manifest_id \
                               -item_node $imsld_item \
                               -parent_id $parent_id \
                               -tmp_dir $tmp_dir]
            
            set item_id [lindex $item_list 0]
            if { !$item_id } {
                # an error happened, abort and return the list whit the error
                return $item_list
            }
            # map item with the activity description
            relation_add imsld_actdesc_item_rel $activity_description_id $item_id
        } 
    }
    return $activity_description_id
}

ad_proc -public imsld::parse::parse_and_create_learning_object { 
    -learning_object_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a learning object and stores all the information in the database.

    Returns a list with the new learning_object_id (item_id) created if there were no errors, or 0 and an explanatio messge if there was an error.
    
    @param learning_object_node learning object node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    # get learning object info
    set learning_object_class [imsld::parse::get_attribute -node $learning_object_node -attr_name class]
    set identifier [imsld::parse::get_attribute -node $learning_object_node -attr_name identifier]
    set is_visible_p [imsld::parse::get_bool_attribute -node $learning_object_node -attr_name isvisible -default t]
    set parameters [imsld::parse::get_attribute -node $learning_object_node -attr_name parameters]
    set type [imsld::parse::get_attribute -node $learning_object_node -attr_name type]
    set title [imsld::parse::get_title -node $learning_object_node -prefix imsld]

    set learning_object_id [imsld::learning_object_new -class  $learning_object_class \
                                -identifier $identifier \
                                -is_visible_p $is_visible_p \
                                -parameters $parameters \
                                -type $type \
                                -title $title \
                                -parent_id $parent_id]

    # learning object: imsld_items
    set learning_object_item [$learning_object_node child all imsld:item]
    if { [llength $learning_object_item] } {
        imsld::parse::validate_multiplicity -tree $learning_object_node -multiplicity 1 -element_name item(learning-object) -equal
        set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                           -manifest_id $manifest_id \
                           -item_node $imsld_item \
                           -parent_id $parent_id \
                           -tmp_dir $tmp_dir]
        
        set item_id [lindex $item_list 0]
        if { !$item_id } {
            # an error happened, abort and return the list whit the error
            return $item_list
        }
        # map item with the learning_object
            relation_add imsld_lobject_item_rell $learning_object_id $item_id
    } 
    return $learning_object_id
}

ad_proc -public imsld::parse::parse_and_create_service { 
    -service_node
    -environment_id
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a service and stores all the information in the database.

    Returns a list with the new service_ids (item_ids) created if there were no errors, or 0 and an explanatio messge if there was an error. The service element can have conference or send-mail services (index service is currently not supported in .LRN), and they are created directly as a service, i.e. there is no table for storing the services, they are stored directly in the send-mail or conference tables.
    
    @param service_node service node to parse
    @param environment_id
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    # get service info
    set service_class [imsld::parse::get_attribute -node $service_node -attr_name class]
    set identifier [imsld::parse::get_attribute -node $service_node -attr_name identifier]
    set is_visible_p [imsld::parse::get_bool_attribute -node $service_node -attr_name isvisible -default t]
    set parameters [imsld::parse::get_attribute -node $service_node -attr_name parameters]
    
    set send_mail [$service_node child all imsld:send-mail]
    if { [llength $send_mail] } {
        # it's a send mail service, get the info and create the service
        imsld::parse::validate_multiplicity -tree $send_mail -multiplicity 1 -element_name send-mail -equal
        set select [imsld::parse::get_attribute -node $send_mail -attr_name select]
        expr { [string eq [string tolower $select] all-persons-in-role] ? [set recipients all-in-role] : [set recipients selection] }
        ns_log notice "!!!recipients es $recipients \n\n"
        set title [imsld::parse::get_title -node $send_mail -prefix imsld]
        # create the service
        set service_id [imsld::service_new -environment_id $environment_id \
                            -class $service_class \
                            -identifier $identifier \
                            -is_visible_p $is_visible_p \
                            -parameters $parameters \
                            -service_type send-mail \
                            -parent_id $parent_id]
        # create the send mail service
        set send_mail_id [imsld::send_mail_service_new -service_id $service_id \
                              -is_visible_p $is_visible_p \
                              -parameters $parameters \
                              -recipients $recipients \
                              -parent_id $parent_id \
                              -title $title]

        set email_data_list [$send_mail child all imsld:email-data]
        imsld::parse::validate_multiplicity -tree $email_data_list -multiplicity 1 -element_name email-data -greather_than
        foreach email_data $email_data_list {
            set role_ref [$email_data child all imsld:role-ref]
            imsld::parse::validate_multiplicity -tree $email_data -multiplicity 1 -element_name role-ref(email-data) -equal
            set ref [string tolower [imsld::parse::get_attribute -node $role_ref -attr_name ref]]
            if { ![db_0or1row get_role_id {select role_id from imsld_roles where identifier = :ref and content_revision__is_live(role_id) = 't' }] } {
                # there is no role with that identifier, return the error
                return [list 0 "<#_ There is no role with the identifier %ref% (referenced by an email data) #>"]
            }
            set email_data_id [imsld::email_data_new -send_mail_service_id $send_mail_id \
                                   -role_id $role_id \
                                   -mail_data {}]
        }
    }

    set conference [$service_node child all imsld:conference]
    if { [llength $conference] } {
        # it's a conference service, get the info an create the service
        imsld::parse::validate_multiplicity -tree $conference -multiplicity 1 -element_name conference -equal
        set conference_type [string tolower [imsld::parse::get_attribute -node $conference -attr_name conference-type]]
        set title [imsld::parse::get_title -node $conference -prefix imsld]
        
        # manager
        set manager [$conference child all imsld:manager]
        if { [llength $manager] } {
            imsld::parse::validate_multiplicity -tree $manager -multiplicity 1 -element_name conference-manager -equal
            set role_ref [string tolower [imsld::parse::get_attribute -node $manager -attr_name role-ref]]
            if { ![db_0or1row get_role_id {select role_id as manager_id from imsld_roles where identifier = :role_ref and content_revision__is_live(role_id) = 't' }] } {
                # there is no role with that identifier, return the error
                return [list 0 "<#_ There is no role with the identifier %ref% (referenced by: manager) #>"]
            }
        }

        # item
        set conference_item [$conference child all imsld:item]
        imsld::parse::validate_multiplicity -tree $conference_item -multiplicity 1 -element_name conference-item -equal
        set item_list [imsld::parse::parse_and_create_item -manifest $manifest \
                           -manifest_id $manifest_id \
                           -item_node $conference_item \
                           -parent_id $parent_id \
                           -tmp_dir $tmp_dir]
        
        set imsld_item_id [lindex $item_list 0]
        if { !$imsld_item_id } {
            # an error happened, abort and return the list whit the error
            return $item_list
        }

        # create the service
        set service_id [imsld::service_new -environment_id $environment_id \
                            -class $service_class \
                            -identifier $identifier \
                            -is_visible_p $is_visible_p \
                            -parameters $parameters \
                            -service_type conferencel \
                            -parent_id $parent_id]

        # create the conference service
        set conference_id [imsld::conference_service_new -service_id $service_id \ 
                              -manager_id $manager_id \
                              -conference_type $conference_type \
                              -imsld_item_id $imsld_item_id \
                              -parent_id $parent_id]

        # participants
        set participant_list [$conference child all imsld:participant]
        imsld::parse::validate_multiplicity -tree $participant_list -multiplicity 1 -element_name conference-participant -greather_than
        foreach participant $participant_list {
            set role_ref [string tolower [imsld::parse::get_attribute -node $participant -attr_name role-ref]]
            if { ![db_0or1row get_role_id {select role_id as participant_id from imsld_roles where identifier = :role_ref and content_revision__is_live(role_id) = 't' }] } {
                # there is no role with that identifier, return the error
                return [list 0 "<#_ There is no role with the identifier %ref% (referenced by: participant) #>"]
            }
            # map conference with participant role
            relation_add imsld_conf_part_rel $conference_id $participant_id
        }

        # observer
        set observer_list [$conference child all imsld:observer]
        if { [llength $observer_list] } {
            foreach observer $observer_list {
                set role_ref [string tolower [imsld::parse::get_attribute -node $observer -attr_name role-ref]]
                if { ![db_0or1row get_role_id {select role_id as observer_id from imsld_roles where identifier = :role_ref and content_revision__is_live(role_id) = 't' }] } {
                    # there is no role with that identifier, return the error
                    return [list 0 "<#_ There is no role with the identifier %ref% (referenced by: observer) #>"]
                }
                # map conference with observer role
                relation_add imsld_conf_obser_rel $conference_id $observer_id
            }
        }

        # moderator
        set moderator_list [$conference child all imsld:moderator]
        if { [llength $moderator_list] } {
            foreach moderator $moderator_list {
                set role_ref [string tolower [imsld::parse::get_attribute -node $moderator -attr_name role-ref]]
                if { ![db_0or1row get_role_id {select role_id as moderator_id from imsld_roles where identifier = :role_ref and content_revision__is_live(role_id) = 't' }] } {
                    # there is no role with that identifier, return the error
                    return [list 0 "<#_ There is no role with the identifier %ref% (referenced by: moderator) #>"]
                }
                # map conference with moderator role
                relation_add imsld_conf_moder_rel $conference_id $moderator_id
            }
        }        
    }

    # index service (not supported)
    set index_search [$service_node child all imsld:index-search]
    if { [llength $index_search] } {
        ns_log error "Index-search service not supported"
        return [list 0 "<#_ Index search service not supported #>"]
    }
    return $service_id
}

ad_proc -public imsld::parse::parse_and_create_environment { 
    -environment_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a environment and stores all the information in the database.

    Returns a list with the new environment_id (item_id) created if there were no errors, or 0 and an explanatio messge if there was an error.
    
    @param environment_node environment node to parse
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
} {
    # get environment info
    set identifier [imsld::parse::get_attribute -node $environment_node -attr_name identifier]
    set title [imsld::parse::get_title -node $environment_node -prefix imsld]
    
    # environment: learning object
    set learning_object [$environment_node child all imsld:learning_object]
    imsld::parse::validate_multiplicity -tree $learning_object -multiplicity 1 -element_name learning-object -equal
    set learning_object_list [imsld::parse::parse_and_create_learning_object -learning_object_node $learning_object \
                                  -manifest_id $manifest_id \
                                  -item_node $imsld_item \
                                  -parent_id $parent_id \
                                  -tmp_dir $tmp_dir]

    set learning_object_id [lindex $learning_object_list 0]
    if { !$learning_object_id } {
        # there is an error, abort and return the list with the error
        return $learning_object_list
    }

    # create the environment
    set environment_id [imsld::environment_new -component_id $component_id \
                            -identifier $identifier \
                            -learning_object_id $learning_object_id \
                            -parent_id $parent_id]

    # environment: service
    set service [$environment_node child all imsld:service]
    imsld::parse::validate_multiplicity -tree $service -multiplicity 1 -element_name service(environment) -equal
    set service_list [imsld::parse::parse_and_create_service -service_node $service \
                          -environment_id $environment_id \
                          -manifest_id $manifest_id \
                          -item_node $imsld_item \
                          -parent_id $parent_id \
                          -tmp_dir $tmp_dir]
    set service_id [lindex $service_list 0]
    if { !$service_id } {
        # there is an error, abort and return the list with the error
        return $service_list
    }

    # environment: environment ref
    set environment_ref_list [$environment_node child all imsld:environment-ref]
    if { [llength $environment_ref_list] } {
        foreach environment_ref $environment_ref_list {
            set ref [string tolower [imsld::parse::get_attribute -node $environment_ref -attr_name ref]]
            # we have to search for the referenced environment and there are two cases:
            # 1. the referenced environment has been created: get the id from the database and do the mappings
            # 2. the referenced environment hasn't been created: invoke the parse_and_create_environment proc,
            #    but first verify that the environment exists in the manifest
            if { [db_0or1row get_env_id {select environment_id as refrenced_env_id from imsld_environments where identifier = :ref and content_revision__is_live(environment_id) = 't'}] } {
                # case one, just do the mappings
                relation_add imsld_env_env_rel $environment_id $refrenced_env_id
            } else {
                # case two, first verify that the referenced environment exists
                set environments [[[[$manifest child all imscp:organizations] child all imsld:learning-design] child all imsld:components] child all imsld:environments]

                set found_p 0
                foreach referenced_environment $environments {
                    set referenced_identifier [string tolower [imsld::parse::get_attribute -node $referenced_environment -attr_name identifier]]
                    if { [string eq $ref $referenced_identifier] } {
                        set found_p 1
                    }
                }
                if { $found_p } {
                        # ok, let's create the environment
                    set environment_ref_list [imsld::parse::parse_and_create_environment -environment_node $environment \
                                                  -manifest_id $manifest_id \
                                                  -item_node $imsld_item \
                                                  -parent_id $parent_id \
                                                  -tmp_dir $tmp_dir]
                    set environment_ref_id [lindex $environment_ref_list 0]
                    if { !$environment_ref_id } {
                        # there is an error, abort and return the list with the error
                        return $environment_ref_list
                    }
                    # finally, do the mappings
                    relation_add imsld_env_env_rel $environment_id $environment_ref_id
                } else {
                    # error, return
                    return [list 0 "<#_ Referenced environment %referenced_identifier% does not exist #>"]
                }
            }
        }
    }
    return $environment_id
}

ad_proc -public imsld::parse::parse_and_create_learning_activity { 
    -component_id
    -activity_node
    -manifest
    -manifest_id
    -parent_id
    -tmp_dir
} {
    Parse a learning activity and stores all the information in the database.

    Returns a list with the new activity_id (item_id) created if there were no errors, or 0 and an explanatio messge if there was an error.
    
    @param role_type staff or learner
    @param component_id Component identifier which this role belongs to
    @param manifest Manifest tree
    @param manifest_id Manifest ID or the manifest being parsed
    @param roles_node The role node to parse 
    @param parent_id Parent folder ID
    @param tmp_dir Temporary directory where the files were exctracted
    @option parent_role_id Parent role identifier. Default to null
} {
    # get the info of the learning activity and create it
    set identifier [imsld::parse::get_attribute -node $activity_node -attr_name identifier]
    set is_visible_p [imsld::parse::get_bool_attribute -tree $activity_node -attr_name isvisible -default t]
    set parameters [imsld::parse::get_attribute -node $activity_node -attr_name parameters]
    set title [imsld::parse::get_title -node $activity_node -prefix imsld]
    
    # Learning Activity: Learning Objectives (which are really an imsld_item that can have resource associated.)
    set learning_objectives [$activity_node child all imsld:learning-objectives]
    if { [llength $learning_objectives] } {
        imsld::parse::validate_multiplicity -tree $learning_objectives -multiplicity 1 -element_name learning-objectives(learning-activity) -equal
        set learning_objective_list [imsld::parse::parse_and_create_learning_objective -learning_objective_node $learning_objectives \
                                         -manifest_id $manifest_id \
                                         -item_node $imsld_item \
                                         -parent_id $parent_id \
                                         -tmp_dir $tmp_dir]
        
        set learning_objective_id [lindex $learning_objective_list 0]
        if { !$learning_objective_id } {
            # there is an error, abort and return the list with the error
            return $learning_objective_list
        }
    } else {
        set learning_objective_id ""
    }
    
    # Learning Activity: Prerequisites (which are really an imsld_item that can have resource associated.)
    set prerequisites [$activity_node child all imsld:prerequisites] 
    if { [llength $prerequisites] } {
        imsld::parse::validate_multiplicity -tree $prerequisites -multiplicity 1 -element_name prerequisites(learning-activity) -equal
        set prerequisite_list [imsld::parse::parse_and_create_perequiste -prerequisite_node $prerequisites \
                                   -manifest_id $manifest_id \
                                   -item_node $imsld_item \
                                   -parent_id $parent_id \
                                   -tmp_dir $tmp_dir]

        set prerequisite_id [lindex $prerequisite_list 0]
        if { !$prerequisite_id } {
            # there is an error, abort and return the list with the error
            return $prerequisite_list
        }
    } else {
        set prerequisite_id ""
    }

    # Learning Activity: Complete Activity
    # If the learning activity has a "user choice" node, the learner decides when the activity is completed
    # otherwise, the activity ends when "time-limit" is complete.
    # When this element does not occur, the activity is set to 'completed' by default.
    
    set complete_activity [$activity_node child all imsld:complete-activity]
    set user_choice_p f
    set time_limit_id ""
    if { [llength $complete_activity] } {
        imsld::parse::validate_multiplicity -tree $complete_activity -multiplicity 1 -element_name complete-activity(learning-activity) -equal
        
        # Learning Activity: Complete Activity: User Choice
        set user_choice [$complete_activity child all imsld:user-choice]
        if { [llength $user_choice] } {
            imsld::parse::validate_multiplicity -tree $user_choice -multiplicity 1 -element_name user-choice(learning-activity) -equal
            # that's it, the learner decides when the activity is completed
            set user_choice_p t
        }

        # Learning Activity: Complete Activity: Time Limit
        set time_limit [$complete_activity child all imsld:time-limit]
        if { [llength $time_limit] } {
            imsld::parse::validate_multiplicity -tree $time_limit -multiplicity 1 -element_name time-limit(learning-activity) -equal
            set time_amount [imsld::parse::get_element_text -node $time_limit]
            set time_limit_id [imsld::time_limit_new -time_in_seconds $time_amount]
        }
    }

    # Learning Activity: On completion
    set on_completion [$activity_node child all imsld:on-completion]
    set on_completion_id ""
    if { [llength $on_completion] } {
        set feedback_desc [$on_completion child all imsld:feedback-description]
        if { [llength $feedback_desc] } {
            imsld::parse::validate_multiplicity -tree $feedback_desc -multiplicity 1 -element_name feedback(learning-activity) -equal
            set feedback_title [imsld::parse::get_title -node $feedback_desc -prefix imsld]
            set on_completion_id [imsld::on_completion_new -feedback_title $feedback_title]
            set feedback_items [$feedback_desc child all imsld:item]
            foreach feedback_item $feedback_items {
                set item_list [imsld::parse_and_create_item -manifest $manifest \
                                   -manifest_id $manifest_id \
                                   -item_node $feedback_item \
                                   -parent_id $parent_id \
                                   -tmp_dir $tmp_dir]
                set item_id [lindex $item_list 0]
                if { !$item_id } {
                    # an error happened, abort and return the list whit the error
                    return $item_list
                }
                # map item with the learning objective
                relation_add imsld_feedback_rel $on_completion_id $item_id
            }
        }
    }

    # crete learning activity
    set learning_activity_id [imsld::learning_activity_new -identifier $identifier \
                                  -component_id $component_id \
                                  -parameters $parameters \
                                  -is_visible_p $is_visible_p \
                                  -user_choice_p $user_choice_p \
                                  -time_limit_id $time_limit_id \
                                  -on_completion_id $on_completion_id \
                                  -learning_objective_id $learning_objective_id \
                                  -prerequisite_id $prerequisite_id \
                                  -title $title]
    
    # Learning Activity: Environments
    set environment_refs [$activity_node child all imsld:environment-ref]
    if { [llength $environment_refs] } {
        foreach environment_ref_node $environment_refs {
            # the environments have been already parsed by now, 
            # so the referenced environment has to be in the database.
            # If not found, return the error
            set environment_ref [string tolower [imsld::parse::get_attribute -node $environment_ref_node -attr_name ref]]
            if { ![db_0or1row get_environment_id {select environment_id from imsld_environments where identifier = :environment_ref}] } {
                # error, referenced environment does not exist
                return [list 0 "<#_ Referenced environment (%environment_ref%) in learning activity does not exist. #>"]
            }

            # map environment with learning-activity
            relation_add imsld_la_env_rel $learning_activity_id $environment_id
        }
    }


}

ad_proc -public imsld::parse::parse_and_create_imsld_manifest { 
    -xmlfile:required
    -manifest_id:required
    {-community_id ""}
    -tmp_dir:required
} {
    Parse a XML IMS LD file and store all the information found in the database, such as the manifest, the organization, the imsld with its components, method, activities, etc.

    Returns the new manifest_id created if there was no errors. Otherwise it returns 0.
    
    @param xmlfile The file to parse. This file must be compliant with the IMS LD spec
    @param manifest_id The manifest_id that is being created
    @option community_id community_id of the community where the manifest and its contents will be created. Default value is
    @param tmp_dir tmp dir where the files were extracted to
} {
    set community_id [expr { [empty_string_p $community_id] ? [dotlrn_community::get_community_id] : $community_id }]

    # get the files structure
    set files_struct_list [imsld::parse::get_files_structure -tmp_dir $tmp_dir]

	# Parser
	# XML => DOM document
	dom parse [::tDOM::xmlReadFile $xmlfile] document

	# DOM document => DOM root
	$document documentElement manifest

    # manifest
    set manifest_identifier [imsld::parse::get_attribute -node $manifest -attr_name identifier]
    set manifest_version [imsld::parse::get_attribute -node $manifest -attr_name version]

    # initialize folders
    set folders_list [imsld::parse::initialize_folders -community_id $community_id \
                          -manifest_id $manifest_id \
                          -manifest_identifier $manifest_identifier]
    set fs_folder_id [lindex $folders_list 0]
    set cr_folder_id [lindex $folders_list 1]
    
    # update file structure
    set dir_parent_list [list [lindex [lindex [lindex $files_struct_list 0] 0] 0] $fs_folder_id]
    set dir_list [list $dir_parent_list [lindex [lindex $files_struct_list 0] 1]]
    set files_struct_list [lreplace $files_struct_list 0 0 $dir_list]

    set manifest_id [imsld::cp::manifest_new -item_id $manifest_id \
                         -identifier $manifest_identifier \
                         -version $manifest_version \
                         -parent_id $cr_folder_id]

    # organizaiton
    set organizations [$manifest child all imscp:organizations]
    set organization_id [imsld::cp::organization_new -manifest_id $manifest_id]

    # IMS-LD
    set imsld [$organizations child all imsld:learning-design]
    set imsld_title [imsld::parse::get_title -node $imsld -prefix imsld]
    set imsld_identifier [imsld::parse::get_attribute -node $imsld -attr_name identifier]
    set imsld_level [imsld::parse::get_attribute -node $imsld -attr_name level]
    set imsld_level [expr { [empty_string_p $imsld_level] ? "" : [string tolower $imsld_level] }]
    set imsld_version [imsld::parse::get_attribute -node $imsld -attr_name version]
    set imsld_sequence_p [imsld::parse::get_bool_attribute -node $imsld -attr_name sequence_used -default f]

    # IMS-LD: Learning Objectives (which are really an imsld_item that can have resource associated.)
    set learning_objectives [$imsld child all imsld:learning-objectives]
    if { [llength $learning_objectives] } {
        imsld::parse::validate_multiplicity -tree $learning_objectives -multiplicity 1 -element_name learning-objectives(ims-ld) -equal
        set learning_objective_list [imsld::parse::parse_and_create_learning_objective -learning_objective_node $learning_objectives \
                                         -manifest_id $manifest_id \
                                         -item_node $imsld_item \
                                         -parent_id $cr_folder_id \
                                         -tmp_dir $tmp_dir]

        set learning_objective_id [lindex $learning_objective_list 0]
        if { !$learning_objective_id } {
            # there is an error, abort and return the list with the error
            return $learning_objective_list
        }
    } else {
        set learning_objective_id ""
    }

    # IMS-LD: Prerequisites (which are really an imsld_item that can have resource associated.)
    set prerequisites [$imsld child all imsld:prerequisites] 
    if { [llength $learning_objectives] } {
        imsld::parse::validate_multiplicity -tree $prerequisites -multiplicity 1 -element_name prerequisites(ims-ld) -equal
        set prerequisite_list [imsld::parse::parse_and_create_perequiste -prerequisite_node $prerequisites \
                                   -manifest_id $manifest_id \
                                   -item_node $imsld_item \
                                   -parent_id $cr_folder_id \
                                   -tmp_dir $tmp_dir]

        set prerequisite_id [lindex $prerequiste_list 0]
        if { !$prerequisite_id } {
            # there is an error, abort and return the list with the error
            return $prerequisite_list
        }
    } else {
        set prerequisite_id ""
    }

    # now that we have all the necessary information, let's create the imsld
    set imsld_id [imsld::imsld_new -identifier $imsld_identifier \
                      -title $imsld_title \
                      -level $imsld_level \
                      -version $imsld_version \
                      -sequence_p $imsld_sequence_p \
                      -parent_id $cr_folder_id \
                      -learning_objectives $learning_objective_id \
                      -prerequisite_id $prerequisite_id]

    # Components
    set components [$imsld child all imsld:components]
    imsld::parse::validate_multiplicity -tree $components -multiplicity 1 -element_name components -equal
    set component_id [imsld::component_new -imsld_id $imsld_id \
                          -parent_id $cr_folder_id]

    # Components: Roles
    set roles [$components child all imsld:roles]

    # Components: Roles: Learners    
    set learner_list [$roles child all imsld:learner]
    imsld::parse::validate_multiplicity -tree $learner_list -multiplicity 1 -element_name components -greather_than

    foreach learner $learner_list {
        imsld::parse::parse_and_create_role -role_type learner \
            -manifest $manifest \
            -manifest_id $manifest_id \
            -parent_id $cr_folder_id \
            -tmp_dir $tmp_dir \
            -roles_node $learner \
            -component_id $component_id
    }

    # Components: Roles: Staff
    set staff_list [$roles child all imsld:staff]
    if { [llength $staff_list] } {
        foreach staff $staff_list {
            imsld::parse::parse_and_create_role -role_type staff \
                -manifest $manifest \
                -manifest_id $manifest_id \
                -parent_id $cr_folder_id \
                -tmp_dir $tmp_dir \
                -roles_node $staff \
                -component_id $component_id
        }
    }

    # Components: Environments
    # The environments are parsed now, and not the activities, because the activities may reference
    # the environments so they have to be in the database already.

    set environment_component [$components child all imsld:environments]
    if { [llength $environment_component] } {
        imsld::parse::validate_multiplicity -tree $environment_component -multiplicity 1 -element_name environments -equal
        set environments [$environment_component child all imsld:environment]
        imsld::parse::validate_multiplicity -tree $environments -multiplicity 1 -element_name environments -greather than
        foreach environment $environments {
            imsld::parse::parse_and_create_environment -environment_node $environment \
                -manifest_id $manifest_id \
                -item_node $imsld_item \
                -parent_id $parent_id \
                -tmp_dir $tmp_dir
        }
    }
    

    # Componetns: Activities
    set activities [$components child all imsld:activities]
    if { [llength $activities] } {
        imsld::parse::validate_multiplicity -tree $activities -multiplicity 1 -element_name components -equal

        # Componets: Activities: Learning Activities
        set learning_activities [$activities child all imsld:learning-activity]
        imsld::parse::validate_multiplicity -tree $learning_activities -multiplicity 1 -element_name learning-activities -greather_than
        
        foreach learning_activity $learning_atcivities {
            imsld::parse::parse_and_create_learning_activity -component_id $component_id \
                -activity_node $learning_activity \
                -manifest $manifest \
                -manifest_id $manifest_id \
                -parent_id $cr_folder_id \
                -tmp_dir $tmp_dir
        }

        set support_activities [$activities child all imsld:support-activity]
        set activity_structures [$activities child all imsld:activity-structure]
    }

    # Method
    set methods [$imsld child all imsld:method]
    imsld::parse::validate_multiplicity -tree $methods -multiplicity 1 -element_name methods -equal
    
    # Method: Play
#     set plays [$methods child all imsld:play]
#     imsld::parse::validate_multiplicity -tree $plays -multiplicity 1 -element_name plays -equal

#     # Method: Acts
#     set acts [$plays child all imsld:act]
#     imsld::parse::validate_multiplicity -tree $acts -multiplicity 0 -element_name acts -greather_than

    return [list $manifest_id {}]
}




